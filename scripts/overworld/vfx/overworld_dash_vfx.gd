class_name OverworldDashVfx
extends Node3D
## D-1100: VFX do avanço de ataque no overworld 3D (speedlines, rastro no chão
## e poeira com alpha reduzido).
##
## API para o lab 3D (Agente C):
##   vfx.setup(actor, target)
##   vfx.begin_dash(advantage)   # EncounterRules.Advantage (0/1/2)
##   vfx.tick(delta)             # todo tick físico, enquanto durar o avanço
##   vfx.finish()                # quando o avanço termina (acerto, erro ou fim)
##   vfx.clear()                 # remove tudo na hora (troca de cena, K.O., etc.)
##
## Regras:
## - D-235: nada depende de nome, espécie, time, is_player, lado ou coordenada
##   fixa. O eixo vem de actor→target reais; altura/raio vêm da AABB do modelo
##   do ator. Ator e alvo podem ser quaisquer Nodes3D; o mesmo efeito funciona
##   com o inimigo atacando e/ou com a câmera do outro lado.
## - D-1100: cor por variante do encontro: branco = contato normal (0),
##   azul = jogador atacou primeiro (1), vermelho = inimigo atacou primeiro (2).
##   A cor vale para speedlines e rastro; a poeira continua neutra.
## - gl_compatibility: só malhas unshaded/aditivas e CPUParticles3D. Sem trail,
##   sem decal, sem sub-emitter, sem shader.
## - O rastro é ancorado por raycast no chão real (máscara 1 por padrão) e a
##   4 cm acima dele; se o raycast falha, o segmento é cortado.
## - Poeira: alpha 0,22 (≈52% do FootDust 0,42 do lab), só durante o avanço.
##   Se o lab já tem um FootDust próprio, chame set_run_dust(_player_dust) para
##   o componente reduzir o alpha dele SÓ durante o avanço e restaurar no fim.
## - Nada fica na cena: finish() desliga emissores e clear() libera tudo; há um
##   limite de segurança de 0,9 s de avanço e 0,55 s de fade (sem restos < 2 s).
##
## Não edita o lab, o GameState, a transição nem a batalha.

const SpeedlinesScript := preload("res://scripts/overworld/vfx/overworld_dash_speedlines.gd")
const GroundTrailScript := preload("res://scripts/overworld/vfx/overworld_dash_ground_trail.gd")
const DustScript := preload("res://scripts/overworld/vfx/overworld_dash_dust.gd")

const ADVANTAGE_NORMAL := 0
const ADVANTAGE_PLAYER_FIRST := 1
const ADVANTAGE_ENEMY_FIRST := 2

const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_PLAYER_FIRST := Color(0.18, 0.52, 1.0, 1.0)
const COLOR_ENEMY_FIRST := Color(1.0, 0.18, 0.12, 1.0)

const DUST_ALPHA := 0.22
const TRAIL_SAMPLE_DISTANCE := 0.04
const TRAIL_SURFACE_OFFSET := 0.04
const MAX_ACTIVE_TIME := 0.9
const FADE_OUT_TIME := 0.55
## D-1127: speedlines follow the actor only for the first 40 ms of the dash.
const ATTACH_TIME := 0.04

## Máscara de colisão do chão. O lab usa a layer 1 para o mundo.
@export var ground_mask: int = 1

var actor: Node3D
var target: Node3D
var advantage: int = ADVANTAGE_NORMAL
var active := false

var _color := COLOR_NORMAL
var _dir := Vector3.RIGHT
var _body_center_y := 0.55
var _body_height := 1.1
var _body_radius := 0.3
var _elapsed := 0.0
var _speed := 0.0
var _prev_actor_pos := Vector3.ZERO
var _last_trail_pos := Vector3.ZERO
var _trail_link := true
var _ground_valid := false
var _ground_point := Vector3.ZERO
var _ground_y := 0.0
var _finishing := false
var _finish_elapsed := 0.0
## D-1173: planned advance duration (controller); 0.10 s is the default.
var _dash_duration := 0.10
var _slide_time := 0.0  ## D-1189

var _speedlines: SpeedlinesScript
var _trail: GroundTrailScript
var _dust: DustScript

var _run_dust: CPUParticles3D
var _run_dust_color := Color.WHITE
var _run_dust_saved := false


func _ready() -> void:
	# O componente é autônomo: se alguém o adicionar como filho do ator, ele
	# ainda trabalha em coordenadas de mundo.
	top_level = true


func setup(p_actor: Node3D, p_target: Node3D) -> void:
	clear()
	actor = p_actor
	target = p_target
	top_level = true
	_ensure_children()
	_measure_actor()
	_speedlines.setup_pool()
	_trail.setup_mesh()
	_dust.setup_emitters()
	visible = true


## D-1173: the controller knows the real advance duration; the dust uses it to
## keep the walking puffs only through the first half of the dash.
func set_dash_duration(seconds: float) -> void:
	_dash_duration = maxf(seconds, 0.0)


## D-1189: length of the braking tail at the end of the advance (little dust).
func set_slide_time(seconds: float) -> void:
	_slide_time = maxf(seconds, 0.0)


## advantage: EncounterRules.Advantage (0 normal, 1 jogador primeiro,
## 2 inimigo primeiro). Qualquer outro valor cai no branco.
func begin_dash(p_advantage: int) -> void:
	if actor == null or not is_instance_valid(actor):
		push_warning("OverworldDashVfx.begin_dash sem ator válido; efeito ignorado.")
		return
	if active or _finishing:
		clear()
	_ensure_children()
	_measure_actor()
	advantage = p_advantage
	_color = color_for_advantage(advantage)
	_dir = _dash_direction()
	_follow_actor()
	_prev_actor_pos = actor.global_position
	_last_trail_pos = actor.global_position
	_elapsed = 0.0
	_speed = 0.0
	_finishing = false
	_finish_elapsed = 0.0
	_trail_link = true
	active = true
	visible = true

	_speedlines.begin(_color, _dir, _body_center_y, _body_radius, _body_height, actor.global_position)
	_trail.begin(_color, clampf(_body_radius * 0.7, 0.10, 0.34))
	if is_instance_valid(_dust):
		_dust.set_dash_duration(_dash_duration)
		_dust.set_slide_time(_slide_time)

	var ground := _query_ground()
	_ground_valid = bool(ground["valid"])
	if _ground_valid:
		_ground_point = ground["point"]
		_ground_y = float(ground["ground_y"])
		_trail.add_point(_ground_point, _ground_y, false)
		_dust.begin(_ground_point, _dir)
	else:
		_ground_point = actor.global_position
		_ground_y = actor.global_position.y
		_dust.begin(_ground_point, _dir)
	_reduce_run_dust()


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if not is_inside_tree():
		return
	if _finishing:
		_finish_elapsed += delta
		_tick_children(delta, false)
		if _finish_elapsed >= FADE_OUT_TIME:
			clear()
		return
	if not active:
		return
	if actor == null or not is_instance_valid(actor):
		finish()
		return

	_follow_actor()
	var now := actor.global_position
	_speed = now.distance_to(_prev_actor_pos) / delta
	_prev_actor_pos = now
	_elapsed += delta
	# D-1127: as linhas ficam presas ao ator só nos primeiros 0,04 s; depois, o
	# nó fica no mundo e o ator continua.
	if _elapsed <= ATTACH_TIME and is_instance_valid(_speedlines):
		_speedlines.set_node_origin(now)
	# D-1120: só os novos spawns acompanham o ator; as linhas já nascidas ficam
	# no ponto do mundo onde nasceram.
	if is_instance_valid(_speedlines):
		_speedlines.set_emitter_origin(now)

	var ground := _query_ground()
	if bool(ground["valid"]):
		_ground_valid = true
		_ground_point = ground["point"]
		_ground_y = float(ground["ground_y"])
		_dust.follow_ground(_ground_point)
	_sample_trail()

	_tick_children(delta, true)
	if _elapsed >= MAX_ACTIVE_TIME:
		finish()


func finish() -> void:
	# D-1120: o dash termina no contato; speedlines, rastro e poeira não
	# continuam durante a janela de impacto.
	if not active:
		return
	clear()


func clear() -> void:
	active = false
	_finishing = false
	_finish_elapsed = 0.0
	_elapsed = 0.0
	_speed = 0.0
	_restore_run_dust()
	if is_instance_valid(_speedlines):
		_speedlines.clear()
		_detach_and_free(_speedlines)
	if is_instance_valid(_trail):
		_trail.clear()
		_detach_and_free(_trail)
	if is_instance_valid(_dust):
		_dust.clear()
		_detach_and_free(_dust)
	_speedlines = null
	_trail = null
	_dust = null


func is_active() -> bool:
	return active


func get_effect_color() -> Color:
	return _color


func color_for_advantage(p_advantage: int) -> Color:
	match p_advantage:
		ADVANTAGE_PLAYER_FIRST:
			return COLOR_PLAYER_FIRST
		ADVANTAGE_ENEMY_FIRST:
			return COLOR_ENEMY_FIRST
		_:
			return COLOR_NORMAL


## Liga o FootDust de corrida do lab. Durante o avanço o alpha dele cai para
## no máximo 0,22 (DUST_ALPHA); no finish()/clear() o valor original volta.
func set_run_dust(p_dust: CPUParticles3D) -> void:
	if p_dust == _run_dust:
		return
	_restore_run_dust()
	_run_dust = p_dust


## Congela poeira/partículas para os quadros de análise (frames estáticos para
## overdraw e diff). Não altera o movimento de speedlines/rastro, que só andam
## quando tick() é chamado.
func set_analysis_freeze(frozen: bool) -> void:
	if is_instance_valid(_dust):
		_dust.set_frozen(frozen)


func get_debug_state() -> Dictionary:
	var sl: Dictionary = _speedlines.get_debug_state() if is_instance_valid(_speedlines) else {}
	var tr: Dictionary = _trail.get_debug_state() if is_instance_valid(_trail) else {}
	var du: Dictionary = _dust.get_debug_state() if is_instance_valid(_dust) else {}
	return {
		"active": active,
		"finishing": _finishing,
		"advantage": advantage,
		"color": _color,
		"direction": _dir,
		"actor_pos": actor.global_position if actor != null and is_instance_valid(actor) else Vector3.ZERO,
		"body_height": _body_height,
		"body_radius": _body_radius,
		"speedlines": sl,
		"trail": tr,
		"dust": du,
		"children": get_child_count(),
		"run_dust_alpha": _current_run_dust_alpha(),
	}


## D-1119: repassa a amostra de movimento das speedlines para os testes.
func get_streak_snapshot() -> Array[Dictionary]:
	if is_instance_valid(_speedlines):
		return _speedlines.get_streak_snapshot()
	return []


func _ensure_children() -> void:
	if not is_instance_valid(_speedlines):
		_speedlines = SpeedlinesScript.new()
		_speedlines.name = "DashSpeedlines"
		# As linhas são de espaço de mundo; top_level impede que o componente,
		# que acompanha o ator, arraste as linhas já nascidas (D-1120).
		_speedlines.top_level = true
		add_child(_speedlines)
		_speedlines.setup_pool()
	if not is_instance_valid(_trail):
		_trail = GroundTrailScript.new()
		_trail.name = "DashGroundTrail"
		# A fita é construída em coordenadas de mundo e não pode acompanhar o
		# ator; top_level evita herdar a posição do componente.
		_trail.top_level = true
		add_child(_trail)
		_trail.setup_mesh()
	if not is_instance_valid(_dust):
		_dust = DustScript.new()
		_dust.name = "DashDust"
		_dust.top_level = true
		add_child(_dust)
		_dust.setup_emitters()


func _measure_actor() -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var world_box := AABB()
	var first := true
	var meshes: Array[Node] = actor.find_children("*", "MeshInstance3D", true, false)
	if actor is MeshInstance3D:
		meshes.append(actor)
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		if mi.has_meta("dash_vfx_ignore_measure") or _is_own_descendant(mi):
			continue
		var box: AABB = mi.global_transform * mi.mesh.get_aabb()
		# Sombras blob do lab (QuadMesh deitado) não são corpo.
		if mi.mesh is QuadMesh and box.size.y < 0.06:
			continue
		world_box = box if first else world_box.merge(box)
		first = false
	if first:
		# Sem malha visível (dummy/placeholder): medidas seguras.
		_body_height = 1.1
		_body_radius = 0.3
		_body_center_y = 0.55
		return
	var local_box: AABB = actor.global_transform.affine_inverse() * world_box
	_body_height = clampf(local_box.size.y, 0.3, 4.0)
	_body_radius = clampf(maxf(local_box.size.x, local_box.size.z) * 0.5, 0.1, 1.4)
	_body_center_y = clampf(local_box.get_center().y, 0.15, _body_height)


func _is_own_descendant(node: Node) -> bool:
	var n: Node = node
	while n != null:
		if n == self:
			return true
		n = n.get_parent()
	return false


func _dash_direction() -> Vector3:
	if target != null and is_instance_valid(target):
		var d := target.global_position - actor.global_position
		d.y = 0.0
		if d.length_squared() > 0.0025:
			return d.normalized()
	# Alvo no mesmo ponto: usa a frente do próprio ator (os modelos do projeto
	# olham para +Z). Não é lado fixo: é derivado do transform atual.
	var forward := actor.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		return forward.normalized()
	return Vector3.FORWARD


func _follow_actor() -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if is_inside_tree():
		global_position = actor.global_position
	else:
		position = actor.global_position


func _tick_children(delta: float, emitting: bool) -> void:
	if is_instance_valid(_speedlines):
		_speedlines.tick(delta, _speed, emitting)
	if is_instance_valid(_trail):
		_trail.tick(delta)
	if is_instance_valid(_dust):
		_dust.tick(delta)


func _sample_trail() -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var moved := actor.global_position - _last_trail_pos
	moved.y = 0.0
	if moved.length() < TRAIL_SAMPLE_DISTANCE:
		return
	_last_trail_pos = actor.global_position
	var ground := _query_ground()
	if not bool(ground["valid"]):
		# Não liga o próximo ponto ao último: nada de fita no ar.
		_trail_link = false
		return
	_trail.add_point(ground["point"], float(ground["ground_y"]), _trail_link)
	_trail_link = true


func _query_ground() -> Dictionary:
	var result := {
		"valid": false,
		"point": Vector3.ZERO,
		"ground_y": 0.0,
		"normal": Vector3.UP,
	}
	if actor == null or not is_instance_valid(actor) or not is_inside_tree():
		return result
	var from := actor.global_position + Vector3.UP * (_body_height + 0.45)
	var to := from + Vector3.DOWN * (_body_height + 1.4)
	var query := PhysicsRayQueryParameters3D.create(from, to, ground_mask)
	var exclude: Array[RID] = []
	if actor is CollisionObject3D:
		exclude.append((actor as CollisionObject3D).get_rid())
	if target != null and is_instance_valid(target) and target is CollisionObject3D:
		exclude.append((target as CollisionObject3D).get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return result
	var normal: Vector3 = hit.get("normal", Vector3.UP)
	if normal.y < 0.55:
		# Parede/teto: não é chão; melhor cortar o rastro do que flutuar.
		return result
	var pos: Vector3 = hit["position"]
	result["valid"] = true
	result["ground_y"] = pos.y
	result["point"] = pos + Vector3.UP * TRAIL_SURFACE_OFFSET
	result["normal"] = normal
	return result


func _reduce_run_dust() -> void:
	if _run_dust == null or not is_instance_valid(_run_dust):
		return
	# D-1173: the walk dust now carries the combat recipe and exposes a peak
	# alpha setter. The material path stays for plain CPUParticles3D probes.
	if _run_dust.has_method("set_alpha_multiplier") and _run_dust.has_method("get_alpha_multiplier"):
		if not _run_dust_saved:
			_run_dust_color = Color(1.0, 1.0, 1.0, float(_run_dust.call("get_alpha_multiplier")))
			_run_dust_saved = true
		_run_dust.call("set_alpha_multiplier", DUST_ALPHA)
		return
	var mat := _run_dust.material_override as StandardMaterial3D
	if mat == null:
		return
	if not _run_dust_saved:
		_run_dust_color = mat.albedo_color
		_run_dust_saved = true
	var c := _run_dust_color
	c.a = minf(c.a, DUST_ALPHA)
	mat.albedo_color = c


func _restore_run_dust() -> void:
	if not _run_dust_saved:
		return
	if _run_dust != null and is_instance_valid(_run_dust):
		if _run_dust.has_method("set_alpha_multiplier"):
			_run_dust.call("set_alpha_multiplier", _run_dust_color.a)
		else:
			var mat := _run_dust.material_override as StandardMaterial3D
			if mat != null:
				mat.albedo_color = _run_dust_color
	_run_dust_saved = false


func _current_run_dust_alpha() -> float:
	if _run_dust != null and is_instance_valid(_run_dust):
		if _run_dust.has_method("get_alpha_multiplier"):
			return float(_run_dust.call("get_alpha_multiplier"))
		var mat := _run_dust.material_override as StandardMaterial3D
		if mat != null:
			return float(mat.albedo_color.a)
	return -1.0


func _detach_and_free(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
