class_name FxSandAttack
extends RefCounted
## Sand Attack (tiro_areia), opção A do HTML "dust shaders unificados" (D-1196).
##
## O `Battle`/`Incoming` continua dono do relógio (D-019): este módulo só lê as fases, o tempo
## e as casas do atacante e do alvo. Os efeitos são os do HTML:
##   castSandAttack (2775-2784): anel de nuvens e véu nos pés do atacante em t=0; em t=0,06 s o
##   jato direcional, as estações de areia e a saraivada de pedras (o mesmo instante em que o
##   projétil `tiro_areia` nasce, no início do TRAVEL);
##   spawnTargetBlindingSandstormStatus (2593-2597, variante "sirocco"): véu e dois anéis de
##   nuvens no alvo, apenas quando a areia realmente acerta.
## Nada depende de personagem, time, lado ou coordenada fixa (D-235): casa do atacante, casa do
## alvo e altura medida dos modelos. Nada aqui é mecânica: dano, cegueira, tempos e esquiva
## continuam no MoveBehavior e no Battle.

const Phase = Incoming.Phase
const MOVE_ID := "tiro_areia"
const DUST_FX := preload("res://scripts/vfx/combat/dust/dust_fx.gd")
const GROUND := preload("res://scripts/vfx/combat/dust/dust_fx_ground.gd")
const MATERIALS := preload("res://scripts/vfx/combat/dust/dust_materials.gd")

const PARTICLES := preload("res://scripts/vfx/combat/dust/dust_particles.gd")
const DUST_STEP := 0.09  ## intervalo entre as emissões de poeira do anel em movimento (escolha da IA)
const SLASH_SHADER := preload("res://shaders/dust_slash.gdshader")
const SLASH_SWEEP := 0.35  ## tempo da varredura do corte (criador)
const SLASH_LIFE := 0.7  ## tempo que cada ponto leva para se dissipar (escolha da IA)
const SLASH_TILT := 20.0  ## graus de inclinação na diagonal (criador)
const SLASH_WIDTH := 0.49  ## largura máxima da faixa, em alturas do corpo (escolha da IA)
const SLASH_TURN := 540.0  ## graus do arco ao redor do corpo, centrado na frente (escolha da IA)
const SLASH_RISE := 0.0  ## sem subida: corte horizontal (criador)
const SLASH_Y := 0.6  ## altura do corte em alturas do corpo (escolha da IA)
const SLASH_RADIUS := 1.05  ## raio da hélice em alturas do corpo (escolha da IA)
const SLASH_DRIFT := 1.5  ## quanto a dissipação avança para a frente, em alturas do corpo (escolha da IA)
const SPIN_TURNS := 1.0  ## giro completo do atacante durante o corte (criador)
const SLASH_AHEAD := 0.0  ## o corte percorre o redor do personagem
const STRIP_SHADER := preload("res://shaders/dust_wind_strip.gdshader")
const STRIP_WIDTH := 3.0  ## metros (escolha da IA)
const STRIP_LIFE := 0.64  ## s que cada ponto do rastro leva para sumir (escolha da IA)
const TRAVEL_TIME := 0.92  ## o anel e o véu do release viajam com o jato (mesma duração)
const JET_DELAY := 0.06  ## HTML 2780: scheduleAfter(60).
const BODY_FALLBACK_H := 1.6  ## usado só quando o corpo do modelo não pode ser medido

var fx: BattleFx
var _spins: Array = []  ## {model, base, t}
var _slashes: Array = []  ## {node, mat, t}
var _strips: Array = []  ## {node, mat, t}
var _movers: Array = []  ## {node, from, to, t}
var _active: Dictionary = {}  ## Incoming -> {jet: bool, start: Vector3, jet_origin: Vector3, target_eye: Vector3}


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


static func is_sand_attack(inc) -> bool:
	return inc != null and (String(inc.move_id) == MOVE_ID or BattleFx.normalize_move_id(String(inc.label)) == MOVE_ID)


## Início do release: o mesmo instante em que o projétil `tiro_areia` nasce (entrada do TRAVEL).
## HTML 2775-2777: anel de 7 nuvens e véu translúcido + anel de choque nos pés do atacante.
func start(inc) -> void:
	if not is_sand_attack(inc) or _active.has(inc):
		return
	var a: Combatant = inc.attacker
	var t: Combatant = inc.target
	if a == null or t == null:
		return
	var a_home: Vector3 = fx._home.get(a, a.rest_pos())
	var t_home: Vector3 = fx._home.get(t, t.rest_pos())
	var start_pos := _ground(a_home)
	var end_pos := _ground(t_home)
	var height := _body_height(fx._models.get(a))
	var target_height := _body_height(fx._models.get(t))
	# D-235: o eixo e as medidas saem do atacante e do alvo reais, nunca de um lado fixo.
	var forward := Vector3(end_pos.x - start_pos.x, 0.0, end_pos.z - start_pos.z)
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD
	var radius := 0.45 * height
	var jet_origin := start_pos + Vector3(0.0, height * 0.34, 0.0) + forward * radius * 0.85
	var target_eye := end_pos + Vector3(0.0, target_height * 0.65, 0.0)
	_active[inc] = {"attacker_model": fx._models.get(a), "height": height, "jet": false, "start": start_pos, "jet_origin": jet_origin, "target_eye": target_eye}
	var palette: Dictionary = MATERIALS.PALETTE_SILICA_SAND
	var ring: Node3D = DUST_FX.cloud_ring(fx, start_pos, 7, 0.76, 0.84, 0.95, 0.0, palette, false)
	var veil: Node3D = DUST_FX.veil_and_shock_ring(fx, start_pos, 0.95, 1.45, 0.95, 0.0, palette)
	_spawn_strip(start_pos, end_pos)
	for n in [ring, veil]:
		_movers.append({"node": n, "from": start_pos, "to": end_pos, "t": 0.0, "dust": n == ring, "next": 0.0})


## HTML 2780-2784: 0,06 s depois do release o jato de poeira sai em direção aos olhos, com pedras.
## O atraso usa `phase_time` (relógio do Battle), então a pausa de status também o congela.
func process(delta: float) -> void:
	_move_release(delta)
	for inc in _active.keys().duplicate():
		var st: Dictionary = _active[inc]
		var a: Combatant = inc.attacker
		if a == null or inc.phase == Phase.DONE or inc.interrupted or inc.phase == Phase.STAGGER:
			_active.erase(inc)
			continue
		if bool(st["jet"]):
			continue
		if inc.phase != Phase.STRIKE and inc.phase != Phase.TRAVEL:
			_active.erase(inc)  # a janela do release fechou antes do atraso: não solta o jato depois do impacto
			continue
		# O release nasce assim que o wind-up acaba (fase STRIKE), sem esperar o TRAVEL; o atraso de 0,06 s do
		# jato conta o tempo de jogo da própria fase (a pausa de status o congela).
		var pt := float(inc.phase_time)
		if int(st.get("last_phase", -1)) == int(inc.phase):
			st["elapsed"] = float(st.get("elapsed", 0.0)) + maxf(pt - float(st.get("last_pt", 0.0)), 0.0)
		st["last_phase"] = int(inc.phase)
		st["last_pt"] = pt
		if float(st.get("elapsed", 0.0)) >= JET_DELAY:
			_fire_jet(st)


## O anel de nuvens e o véu do release saem dos pés do atacante e viajam até o alvo com a areia.
func _move_release(delta: float) -> void:
	for i in range(_spins.size() - 1, -1, -1):
		var sp: Dictionary = _spins[i]
		var m = sp["model"]
		if m == null or not is_instance_valid(m):
			_spins.remove_at(i)
			continue
		sp["t"] = float(sp["t"]) + delta
		var u := clampf(float(sp["t"]) / SLASH_SWEEP, 0.0, 1.0)
		var eased := u * u * (3.0 - 2.0 * u)
		(m as Node3D).rotation.y = float(sp["base"]) + TAU * SPIN_TURNS * eased
		if u >= 1.0:
			(m as Node3D).rotation.y = float(sp["base"])
			_spins.remove_at(i)
	for i in range(_slashes.size() - 1, -1, -1):
		var sl: Dictionary = _slashes[i]
		var snode = sl["node"]
		if snode == null or not is_instance_valid(snode):
			_slashes.remove_at(i)
			continue
		sl["t"] = float(sl["t"]) + delta
		var smat: ShaderMaterial = sl["mat"]
		smat.set_shader_parameter("u_age", sl["t"])
		var u := float(sl["t"]) / (SLASH_SWEEP + SLASH_LIFE)
		if u >= 1.0:
			(snode as Node).queue_free()
			_slashes.remove_at(i)
	for i in range(_strips.size() - 1, -1, -1):
		var st: Dictionary = _strips[i]
		var node = st["node"]
		if node == null or not is_instance_valid(node):
			_strips.remove_at(i)
			continue
		st["t"] = float(st["t"]) + delta
		(st["mat"] as ShaderMaterial).set_shader_parameter("u_age", st["t"])
		if float(st["t"]) > TRAVEL_TIME + STRIP_LIFE:
			(node as Node).queue_free()
			_strips.remove_at(i)
	for i in range(_movers.size() - 1, -1, -1):
		var m: Dictionary = _movers[i]
		var n = m["node"]
		if n == null or not is_instance_valid(n):
			_movers.remove_at(i)
			continue
		m["t"] = float(m["t"]) + delta
		var u := clampf(float(m["t"]) / TRAVEL_TIME, 0.0, 1.0)
		(n as Node3D).position = (m["from"] as Vector3).lerp(m["to"] as Vector3, u)
		if bool(m["dust"]) and float(m["t"]) >= float(m["next"]) and u < 0.75:
			m["next"] = float(m["t"]) + DUST_STEP  # poeira solta do anel: nasce ao longo do caminho, junto com a areia
			PARTICLES.spawn_dig_dust(fx, (n as Node3D).position, 0.84 * 0.45, 0.45)
		if u >= 1.0:
			_movers.remove_at(i)


## Faixa plana de vento no chão, do atacante ao alvo, com opacidade que cai ao longo do trajeto.
func _spawn_strip(from: Vector3, to: Vector3) -> void:
	var d := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if d.length() < 0.5:
		return
	var plane := PlaneMesh.new()
	plane.size = Vector2(STRIP_WIDTH, d.length())
	var mi := MeshInstance3D.new()
	mi.name = "SandWindStrip"
	mi.mesh = plane
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = STRIP_SHADER
	mat.render_priority = 8  # desenha depois do piso translúcido
	mat.set_shader_parameter("u_travel", TRAVEL_TIME)
	mat.set_shader_parameter("u_life", STRIP_LIFE)
	mi.material_override = mat
	fx.add_child(mi)
	mi.position = Vector3((from.x + to.x) * 0.5, 0.12, (from.z + to.z) * 0.5)
	mi.rotation.y = atan2(d.x, d.z)
	_strips.append({"node": mi, "mat": mat, "t": 0.0})


## Corte de vento do release: faixa larga amarela que sai do chão, na frente do atacante, e sobe em
## arco horizontal ao redor do corpo em SLASH_SWEEP junto com o disparo. Eixo inclinado SLASH_TILT graus.
func _spawn_slash(start_pos: Vector3, target_eye: Vector3, height: float) -> void:
	var fwd := Vector3(target_eye.x - start_pos.x, 0.0, target_eye.z - start_pos.z)
	fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
	var side := Vector3.UP.cross(fwd).normalized()
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var n := 48
	var turn := deg_to_rad(SLASH_TURN)
	for i in range(n + 1):
		var f := float(i) / float(n)
		var ang := PI * 0.5 - turn * 0.5 + f * turn
		var c := Vector3(cos(ang) * SLASH_RADIUS, SLASH_Y + f * SLASH_RISE, sin(ang) * SLASH_RADIUS) * height
		var w := SLASH_WIDTH * pow(sin(PI * clampf(f, 0.02, 0.98)), 0.7) * 0.5 * height
		var along := Vector3(-sin(ang), 0.0, cos(ang))
		var across := Vector3(cos(ang), 0.0, sin(ang)).cross(along).normalized()
		verts.append(c - across * w)
		verts.append(c + across * w)
		uvs.append(Vector2(1.0 - f, 0.0))  # varredura começa pela ponta de baixo
		uvs.append(Vector2(1.0 - f, 1.0))
	for i in range(n):
		var o := i * 2
		idx.append_array([o, o + 1, o + 2, o + 1, o + 3, o + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "SandSlash"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SLASH_SHADER
	mat.render_priority = 9
	mat.set_shader_parameter("u_sweep", SLASH_SWEEP)
	mat.set_shader_parameter("u_drift", SLASH_DRIFT * height)
	mat.set_shader_parameter("u_life", SLASH_LIFE)
	mi.material_override = mat
	fx.add_child(mi)
	var tilt := Basis(fwd, deg_to_rad(SLASH_TILT))
	mi.global_transform = Transform3D(tilt * Basis(side, Vector3.UP, fwd), start_pos + fwd * height * SLASH_AHEAD)
	_slashes.append({"node": mi, "mat": mat, "t": 0.0})


## Giro completo do atacante durante a varredura do corte (o relógio é o do Battle via process()).
func _start_spin(model) -> void:
	if model == null or not is_instance_valid(model):
		return
	for sp in _spins:
		if sp["model"] == model:
			return
	_spins.append({"model": model, "base": (model as Node3D).rotation.y, "t": 0.0})


func _fire_jet(st: Dictionary) -> void:
	st["jet"] = true
	var start_pos: Vector3 = st["start"]
	var jet_origin: Vector3 = st["jet_origin"]
	var target_eye: Vector3 = st["target_eye"]
	var cone: Node3D = DUST_FX.directional_kick_cone(fx, jet_origin, target_eye)
	_movers.append({"node": cone, "from": jet_origin, "to": target_eye, "t": 0.0, "dust": false, "next": 0.0})  # os arcos dourados do release viajam com a areia
	_spawn_slash(start_pos, target_eye, float(st["height"]))
	_start_spin(st.get("attacker_model"))
	DUST_FX.sand_jet_stations(fx, jet_origin, target_eye)
	DustParticles.spawn_sand_jet(fx, jet_origin, target_eye, 0.92)
	GROUND.boulder_barrage(fx, start_pos, 4, Vector2(4.5, 8.8), Vector2(0.09, 0.16), 0.78, 0.0)


## O alvo foi realmente atingido: `BattleFx.play_hit` recebe o status do SandAttack com evaded=false.
## HTML 2593-2597 (variante "sirocco"), com tScale = 1.0 fixo (como o impacto do Dig, D-1196).
func on_hit(attacker: Combatant, target: Combatant, info: Dictionary) -> void:
	if attacker == null or target == null:
		return
	if BattleFx.normalize_move_id(String(info.get("skill_name", ""))) != MOVE_ID:
		return
	if not bool(info.get("status", false)) or bool(info.get("evaded", false)):
		return  # esquiva, auto-dodge, alvo intangível ou atacante cego que errou
	var t_home: Vector3 = fx._home.get(target, target.rest_pos())
	var pos := _ground(t_home)
	var height := _body_height(fx._models.get(target))
	var palette: Dictionary = MATERIALS.PALETTE_SILICA_SAND
	DUST_FX.veil_and_shock_ring(fx, pos, 1.28, 2.85, 1.55, 0.0, palette)
	DUST_FX.cloud_ring(fx, pos, 8, 0.85, 0.92, 1.45, 0.0, palette)
	DUST_FX.cloud_ring(fx, pos + Vector3(0.0, height * 0.68 * 0.72, 0.0), 7, 0.75, 0.82, 1.40, 0.06, palette)


## Nada é criado aqui diretamente: os drivers de poeira e pedras se liberam sozinhos.
## Cancelar só impede o jato atrasado de nascer (o que já foi criado termina sua própria vida).
func cancel(inc) -> void:
	_active.erase(inc)


func clear_all() -> void:
	_active.clear()
	for sp in _spins:
		if is_instance_valid(sp["model"]):
			(sp["model"] as Node3D).rotation.y = float(sp["base"])
	_spins.clear()
	for sl in _slashes:
		if is_instance_valid(sl["node"]):
			(sl["node"] as Node).queue_free()
	_slashes.clear()
	for st in _strips:
		if is_instance_valid(st["node"]):
			(st["node"] as Node).queue_free()
	_strips.clear()
	_movers.clear()


func _ground(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## D-235: altura real do corpo (caixa em espaço de mundo), a mesma medida de FxArmor e MP.
func _body_height(m: Node3D) -> float:
	if m == null or not is_instance_valid(m) or fx.fx_armor == null:
		return BODY_FALLBACK_H
	var box: AABB = fx.fx_armor.body_box_of(m)
	return box.size.y if box.size.y > 0.1 else BODY_FALLBACK_H
