class_name ShellDropFx
extends Node3D
## D-1286/D-1309: quando um inimigo derrotado deixa Cascos, eles voam em arco e caem no chao;
## o brilho (bronze, prata, dourado) vem do ShellCoin e identifica o tipo. Sem fisica do motor:
## o movimento e balistico e fica aqui, so para a apresentacao. O credito no saldo nao depende
## deste no (acontece na vitoria, em Battle/BattleScene).
## Valores de TESTE (escala, altura do arco, quicadas): o criador ainda nao os definiu.

const ShellCoinClass = preload("res://scripts/exploration/shell_coin.gd")

const COIN_SCALE := 0.32          ## m de diametro: o mesmo do ShellCoin (nao aumentar; so brilho)
const GRAVITY := 22.0
const LAUNCH_UP_MIN := 12.0       ## subida: forca bem aleatoria entre MIN e MAX
const LAUNCH_UP_MAX := 26.0
const LAUNCH_SIDE_MIN := 1.5
const LAUNCH_SIDE_MAX := 8.0
const FALL_GRAVITY_MIN := 1.8   ## na descida a gravidade e multiplicada por um fator aleatorio MIN..MAX
const FALL_GRAVITY_MAX := 3.2
const BOUNCE_KEEP := 0.35
const SIDE_KEEP := 0.6
const MAX_BOUNCES := 2
const SETTLE_RATE := 14.0
const COLLECT_TIME := 0.5
const MAX_PER_TYPE := 12         ## limite de moedas visuais por tipo na batalha (pedido do criador)
const AURA_SIZE := 1.8           ## m: aura luminosa (nao e a moeda; a moeda segue com o tamanho original)
const AURA_PER_METER := 0.14
const AURA_MAX := 6.0
const AURA_AIR := 2.4            ## intensidade da aura no ar
const AURA_REST := 2.0           ## intensidade media da aura no chao (pulsa)
const AURA_SHADER_CODE := """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float intensity = 1.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float core = pow(clamp(1.0 - d, 0.0, 1.0), 3.0);
	float halo = pow(clamp(1.0 - d, 0.0, 1.0), 1.4) * 0.35;
	ALBEDO = mix(tint.rgb, vec3(1.0), core * 0.6) * intensity;
	ALPHA = clamp(core + halo, 0.0, 1.0);
}
"""
const HALO_SCALE := 4.0          ## tamanho do halo luminoso no chao (a moeda continua do tamanho original)
const TRAIL_SPARK := 0.22        ## tamanho de cada faisca do rastro (efeito, nao a moeda)
const GROUND_BOOST := 5.0        ## forca do halo no chao (a 37 m da camera o original nao se le)
const REST_FLASH := 1.0          ## brilho da moeda parada (0 a 1)
const REST_PULSE := 0.5

signal collected_all

var floor_y := 0.0
var coin_scale := COIN_SCALE
var _pieces: Array[Dictionary] = []


## `counts` = {bronze, silver, gold}: quantas moedas de cada tipo (bool conta como 0 ou 1). Sai uma moeda
## por unidade. `shown` guarda quantas de cada tipo ja foram mostradas na batalha: passou de MAX_PER_TYPE
## (12), esse tipo para de gerar moedas visuais (o saldo continua sendo creditado inteiro); os outros
## tipos seguem gerando ate o proprio limite.
static func burst(parent: Node, origin: Vector3, p_floor_y: float, counts: Dictionary, shown: Dictionary = {}, p_scale := -1.0) -> ShellDropFx:
	if p_scale <= 0.0:
		p_scale = COIN_SCALE  # tamanho original da moeda (ShellCoin); so o brilho cresce, nao a moeda
	var fx := ShellDropFx.new()
	fx.name = "ShellDropFx"
	fx.floor_y = p_floor_y
	fx.coin_scale = p_scale
	parent.add_child(fx)
	var denoms: Array[int] = []
	for k in ["bronze", "silver", "gold"]:
		var want := int(counts.get(k, 0))
		var room := maxi(MAX_PER_TYPE - int(shown.get(k, 0)), 0)
		var n := mini(want, room)
		shown[k] = int(shown.get(k, 0)) + n
		for _i in n:
			denoms.append(_denom_of(k))
	var base := randf() * TAU
	for i in denoms.size():
		var ang := base + TAU * float(i) / float(maxi(denoms.size(), 1)) + randf_range(-0.35, 0.35)
		fx._add_piece(denoms[i], origin, ang)
	return fx


static func _denom_of(key: String) -> int:
	if key == "silver":
		return ShellCoinClass.Denom.SILVER
	if key == "gold":
		return ShellCoinClass.Denom.GOLD
	return ShellCoinClass.Denom.BRONZE


func piece_count() -> int:
	return _pieces.size()


func _add_piece(denom: int, origin: Vector3, ang: float) -> void:
	var coin := ShellCoinClass.spawn(self, denom, origin, floor_y, coin_scale)
	# So apresentacao: sem fisica do motor, sem coleta por proximidade.
	coin.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	coin.freeze = true
	coin.collision_layer = 0
	coin.collision_mask = 0
	coin.set_physics_process(false)
	coin.call("_flash", 1.0)  # brilho no ar; no chao continua pulsando
	var glow := coin.get("_glow") as MeshInstance3D  # halo no chao mais forte para ler a distancia da camera
	if glow != null and glow.material_override is ShaderMaterial:
		glow.scale = Vector3.ONE * HALO_SCALE
		(glow.material_override as ShaderMaterial).set_shader_parameter("strength", float(ShellCoinClass.GROUND[denom]) * GROUND_BOOST)
	var trail := _make_trail(ShellCoinClass.TINT[denom])
	coin.add_child(trail)
	var aura := _make_aura(ShellCoinClass.TINT[denom])
	coin.add_child(aura)
	var side := randf_range(LAUNCH_SIDE_MIN, LAUNCH_SIDE_MAX)
	_pieces.append({
		"coin": coin,
		"vel": Vector3(cos(ang) * side, randf_range(LAUNCH_UP_MIN, LAUNCH_UP_MAX), sin(ang) * side),
		"spin": Vector3(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0), randf_range(-14.0, 14.0)),
		"fall": randf_range(FALL_GRAVITY_MIN, FALL_GRAVITY_MAX),
		"bounces": 0,
		"rest": false,
		"collecting": false,
		"t": randf() * TAU,
		"trail": trail,
		"aura": aura,
	})


func _process(delta: float) -> void:
	for p in _pieces:
		var coin := p["coin"] as ShellCoin
		if coin == null or not is_instance_valid(coin) or bool(p["collecting"]):
			continue
		if bool(p["rest"]):
			coin.rotation.x = lerp_angle(coin.rotation.x, 0.0, minf(1.0, SETTLE_RATE * delta))
			coin.rotation.z = lerp_angle(coin.rotation.z, 0.0, minf(1.0, SETTLE_RATE * delta))
			p["t"] = float(p["t"]) + delta
			coin.call("_flash", REST_FLASH + REST_PULSE * sin(float(p["t"]) * 4.0))  # segue brilhando no chao
			_update_aura(p, coin, AURA_REST * (1.0 + 0.35 * sin(float(p["t"]) * 4.0)))
			continue
		_update_aura(p, coin, AURA_AIR)
		var vel: Vector3 = p["vel"]
		vel.y -= GRAVITY * (float(p["fall"]) if vel.y < 0.0 else 1.0) * delta
		coin.global_position += vel * delta
		coin.rotation += (p["spin"] as Vector3) * delta
		var rest_y := floor_y + coin_scale * 0.06
		if coin.global_position.y <= rest_y and vel.y < 0.0:
			coin.global_position.y = rest_y
			if int(p["bounces"]) < MAX_BOUNCES and absf(vel.y) > 2.5:
				vel.y = -vel.y * BOUNCE_KEEP
				vel.x *= SIDE_KEEP
				vel.z *= SIDE_KEEP
				p["bounces"] = int(p["bounces"]) + 1
				p["spin"] = (p["spin"] as Vector3) * 0.5
			else:
				p["rest"] = true
				var tr := p["trail"] as CPUParticles3D
				if tr != null and is_instance_valid(tr):
					tr.emitting = false
				vel = Vector3.ZERO
				p["spin"] = Vector3.ZERO
		p["vel"] = vel


func _make_aura(col: Color) -> MeshInstance3D:
	var q := QuadMesh.new()
	var size := AURA_SIZE
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null:
		size = clampf(cam.global_position.distance_to(global_position) * AURA_PER_METER, AURA_SIZE, AURA_MAX)  # so a aura cresce com a distancia; a moeda nao
	q.size = Vector2.ONE * size
	var m := MeshInstance3D.new()
	m.mesh = q
	m.top_level = true
	m.sorting_offset = 2.0
	var sh := Shader.new()
	sh.code = AURA_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("tint", col)
	mat.set_shader_parameter("intensity", AURA_AIR)
	m.material_override = mat
	return m


## Rastro luminoso que acompanha a moeda no ar (aditivo, na cor do tipo).
func _make_trail(col: Color) -> CPUParticles3D:
	var t := CPUParticles3D.new()
	t.amount = 36
	t.lifetime = 0.7
	t.local_coords = false
	t.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	t.emission_sphere_radius = 0.12
	t.gravity = Vector3.ZERO
	t.initial_velocity_max = 0.4
	t.mesh = ShellCoinClass._spark_mesh(TRAIL_SPARK, col)
	t.scale_amount_curve = ShellCoinClass._fade_curve()
	return t


## D-1309: a vitoria confirmada leva os Cascos ate `target` (o saldo ja foi creditado pelo jogo).
func collect_to(target: Vector3) -> void:
	var pending := 0
	for p in _pieces:
		var coin := p["coin"] as ShellCoin
		if coin == null or not is_instance_valid(coin):
			continue
		p["collecting"] = true
		pending += 1
		var from := coin.global_position
		var mid := (from + target) * 0.5 + Vector3(0.0, 1.8, 0.0)
		var tw := create_tween()
		tw.tween_method(_collect_step.bind(coin, from, mid, target), 0.0, 1.0, COLLECT_TIME).set_ease(Tween.EASE_IN)
		tw.tween_callback(coin.queue_free)
	if pending == 0:
		collected_all.emit()
		queue_free()
		return
	get_tree().create_timer(COLLECT_TIME + 0.05).timeout.connect(func() -> void:
		collected_all.emit()
		queue_free())


func _update_aura(p: Dictionary, coin: Node3D, intensity: float) -> void:
	var a := p["aura"] as MeshInstance3D
	if a == null or not is_instance_valid(a):
		return
	a.global_position = coin.global_position
	(a.material_override as ShaderMaterial).set_shader_parameter("intensity", intensity)


func _collect_step(k: float, coin: ShellCoin, from: Vector3, mid: Vector3, target: Vector3) -> void:
	if not is_instance_valid(coin):
		return
	coin.global_position = from.lerp(mid, k).lerp(mid.lerp(target, k), k)
	coin.scale = Vector3.ONE * (1.0 - 0.7 * k)


## Derrota ou fim sem coleta: some sem creditar.
func vanish() -> void:
	queue_free()
