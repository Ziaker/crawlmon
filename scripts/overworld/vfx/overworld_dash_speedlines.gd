class_name OverworldDashSpeedlines
extends Node3D
## D-1100: speedlines 3D do avanço de ataque no overworld.
##
## Linhas curtas em malhas 3D (diamantes finos com ponta), ancoradas no ator
## real. O nó pai copia a posição global do ator a cada tick; os offsets são
## medidos do corpo do ator (altura/raio), nunca de nome, time, is_player ou
## lado (D-235). A cor vem da variante do encontro.
##
## Renderer alvo: gl_compatibility. Não usa trails, decals nem sub-emitters.
## Material unshaded + aditivo, com depth test ligado (linha não atravessa
## parede). O fade é por material (um material por streak), sem shader extra.

const POOL_SIZE := 56
const INITIAL_STREAKS := 34
const SPAWN_INTERVAL := 0.018
const LIFE_MIN := 0.20
const LIFE_MAX := 0.36
const FADE_IN_TIME := 0.030

var _pool: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _active := false
var _emitting := false
var _color := Color.WHITE
var _dir := Vector3.RIGHT
var _side := Vector3.FORWARD
var _up := Vector3.UP
var _body_center_y := 0.55
var _body_height := 1.1
var _body_radius := 0.3
var _spawn_accum := 0.0
var _alpha_scale := 0.80
var _streak_mesh: ArrayMesh
var _node_origin := Vector3.ZERO
var _emitter_origin := Vector3.ZERO


func _ready() -> void:
	# D-1120: as linhas vivem no mundo; o componente pai pode acompanhar o ator,
	# mas este nó não pode herdar esse movimento.
	top_level = true


func setup_pool() -> void:
	if not _pool.is_empty():
		return
	top_level = true
	_streak_mesh = _make_streak_mesh()
	_rng.seed = 20261110
	for i in POOL_SIZE:
		var mi := MeshInstance3D.new()
		mi.name = "Streak%02d" % i
		mi.mesh = _streak_mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.disable_receive_shadows = true
		mat.albedo_color = Color(1, 1, 1, 0)
		mi.material_override = mat
		add_child(mi)
		_pool.append({
			"node": mi,
			"mat": mat,
			"age": 0.0,
			"life": 0.0,
			"active": false,
			"base": Vector3.ZERO,
			"basis": Basis(),
			"speed_factor": 0.0,
		})


## direction: eixo ator->alvo (mundo, horizontal). body_center_y: altura do
## centro do corpo em relação à base do ator. body_radius: raio horizontal.
## world_origin: posição do ator no início do dash; o nó fica ancorado aí e só
## os novos spawns acompanham o ator (D-1120).
func begin(p_color: Color, direction: Vector3, body_center_y: float, body_radius: float, body_height: float, world_origin: Vector3 = Vector3.ZERO) -> void:
	setup_pool()
	_active = true
	_emitting = true
	_color = p_color
	_dir = direction.normalized() if direction.length_squared() > 0.0001 else Vector3.RIGHT
	_body_center_y = maxf(body_center_y, 0.1)
	_body_height = maxf(body_height, 0.2)
	_body_radius = maxf(body_radius, 0.08)
	_node_origin = world_origin
	_emitter_origin = world_origin
	if is_inside_tree():
		global_position = world_origin
	else:
		position = world_origin
	# Base ortonormal com X = direção do avanço.
	var up_ref := Vector3.UP
	if absf(_dir.dot(up_ref)) > 0.95:
		up_ref = Vector3.FORWARD
	_side = _dir.cross(up_ref).normalized()
	_up = _side.cross(_dir).normalized()
	_alpha_scale = 0.95 if p_color.get_luminance() < 0.85 else 0.82
	for s in _pool:
		_deactivate(s)
	# Semente fixa: o mesmo avanço gera o mesmo desenho; a vista espelhada
	# reflete o padrão em vez de sortear outro.
	_rng.seed = 20261110
	for i in INITIAL_STREAKS:
		_spawn_one(i, true)
	_spawn_accum = 0.0


## D-1127: presas ao ator só nos primeiros milésimos; atualiza a origem do nó
## enquanto o VFX ainda está no attach. Depois disso, o nó fica no mundo.
func set_node_origin(pos: Vector3) -> void:
	_node_origin = pos
	if is_inside_tree():
		global_position = pos
	else:
		position = pos


## D-1120: o emissor acompanha o ator só para os novos spawns; as linhas já
## nascidas continuam no ponto do mundo onde nasceram.
func set_emitter_origin(pos: Vector3) -> void:
	_emitter_origin = pos


func tick(delta: float, speed: float, still_emitting: bool) -> void:
	if not _active:
		return
	_emitting = still_emitting
	if _emitting:
		_spawn_accum += delta
		while _spawn_accum >= SPAWN_INTERVAL:
			_spawn_accum -= SPAWN_INTERVAL
			var slot := _find_free_slot()
			if slot < 0:
				break
			_spawn_one(slot, false)
	for s in _pool:
		if not bool(s["active"]):
			continue
		s["age"] = float(s["age"]) + delta
		var age: float = float(s["age"])
		var life: float = maxf(float(s["life"]), 0.001)
		if age >= life:
			_deactivate(s)
			continue
		var t := age / life
		var fade_in := clampf(age / FADE_IN_TIME, 0.0, 1.0)
		var alpha := fade_in * pow(1.0 - t, 0.65) * _alpha_scale
		var mat := s["mat"] as StandardMaterial3D
		mat.albedo_color = Color(_color.r, _color.g, _color.b, alpha)
		var mi := s["node"] as MeshInstance3D
		var base: Vector3 = s["base"]
		# A linha escorrega para trás, estica no nascimento e gira em torno do
		# próprio eixo; sem isso ela fica parada no ar (D-1119).
		mi.position = base - _dir * (clampf(speed, 0.0, 12.0) * age * float(s["speed_factor"]))
		var stretch := lerpf(1.60, 0.50, t)
		var shrink := 1.0 - 0.10 * t
		var b := (s["basis"] as Basis).rotated(_dir, float(s.get("spin", 0.0)) * age)
		mi.basis = Basis(b.x * stretch, b.y * shrink, b.z * shrink)


func fade_out(duration: float = 0.18) -> void:
	if not _active:
		return
	_emitting = false
	for s in _pool:
		if bool(s["active"]):
			s["life"] = minf(float(s["life"]), float(s["age"]) + maxf(duration, 0.02))


func finish_now() -> void:
	for s in _pool:
		_deactivate(s)
	_active = false
	_emitting = false


func clear() -> void:
	finish_now()


func active_count() -> int:
	var n := 0
	for s in _pool:
		if bool(s["active"]):
			n += 1
	return n


func visible_count() -> int:
	var n := 0
	for s in _pool:
		if bool(s["active"]) and (s["node"] as MeshInstance3D).visible:
			n += 1
	return n


func get_debug_state() -> Dictionary:
	return {
		"pool": _pool.size(),
		"active": active_count(),
		"color": _color,
		"direction": _dir,
	}


## D-1119: amostra do transform local das linhas ativas, para o teste provar
## que elas deslizam e mudam de comprimento (não ficam paradas no ar).
func get_streak_snapshot() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in _pool:
		if not bool(s["active"]):
			continue
		var mi := s["node"] as MeshInstance3D
		if mi == null or not mi.visible:
			continue
		out.append({
			"name": String(mi.name),
			"pos": mi.position,
			"length": mi.basis.x.length(),
			"width": mi.basis.y.length(),
		})
	return out


func _spawn_one(index: int, initial: bool) -> void:
	if index < 0 or index >= _pool.size():
		return
	var s: Dictionary = _pool[index]
	if bool(s["active"]):
		return
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _body_radius * _rng.randf_range(1.05, 1.80) + 0.05
	var height_offset := _rng.randf_range(-0.34, 0.38) * _body_height
	var h := clampf(_body_center_y + height_offset, 0.12, _body_height * 0.98)
	var radial := _side * cos(angle) * radius + _up * sin(angle) * radius
	var length := _rng.randf_range(0.20, 0.45) * _body_height
	var width := _rng.randf_range(0.018, 0.040) * _body_height
	if initial:
		length *= 1.08
	var wake := _rng.randf() < 0.50
	if wake:
		# Cauda curta atrás do corpo, para ler a direção do avanço.
		length *= 1.30
		h = clampf(h, 0.18, _body_height * 0.85)
	# Roll em torno do eixo do avanço: a malha em cruz tem duas faces, então a
	# linha aparece de qualquer lado/câmera, sem billboard (D-235).
	var roll := _rng.randf_range(0.0, TAU)
	var y_axis := _up * cos(roll) + _side * sin(roll)
	var z_axis := _side * cos(roll) - _up * sin(roll)
	var basis := Basis(_dir * length, y_axis * width, z_axis * width)
	# Nasce à frente e escorrega para trás atravessando o corpo (D-1119).
	var emitter_offset := _emitter_origin - _node_origin
	var pos := emitter_offset + Vector3(radial.x, h + radial.y, radial.z) + _dir * (_body_height * _rng.randf_range(0.04, 0.26))
	if wake:
		pos -= _dir * (_body_height * _rng.randf_range(0.10, 0.40))
	var mi := s["node"] as MeshInstance3D
	mi.transform = Transform3D(basis, pos)
	mi.visible = true
	s["active"] = true
	s["age"] = 0.0
	s["life"] = _rng.randf_range(LIFE_MIN, LIFE_MAX)
	s["base"] = pos
	s["basis"] = basis
	s["speed_factor"] = _rng.randf_range(0.55, 1.55)
	s["spin"] = _rng.randf_range(-3.2, 3.2)
	var mat := s["mat"] as StandardMaterial3D
	mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.0)


func _deactivate(s: Dictionary) -> void:
	s["active"] = false
	s["age"] = 0.0
	s["life"] = 0.0
	var mi := s["node"] as MeshInstance3D
	if is_instance_valid(mi):
		mi.visible = false
	var mat := s["mat"] as StandardMaterial3D
	if mat != null:
		mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.0)


func _find_free_slot() -> int:
	for i in _pool.size():
		if not bool(_pool[i]["active"]):
			return i
	return -1


## Diamante alongado em cruz: duas faces perpendiculares, para a linha não
## desaparecer de perfil em nenhuma câmera (D-235). Ponta fina atrás, largura
## máxima perto de 35% e ponta fina na frente. A malha é compartilhada; o
## tamanho vem do basis de cada nó.
func _make_streak_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		# Face XY.
		Vector3(-0.55, 0.0, 0.0),
		Vector3(-0.05, 0.5, 0.0),
		Vector3(0.45, 0.0, 0.0),
		Vector3(-0.05, -0.5, 0.0),
		# Face XZ (cruzada).
		Vector3(-0.55, 0.0, 0.0),
		Vector3(-0.05, 0.0, 0.5),
		Vector3(0.45, 0.0, 0.0),
		Vector3(-0.05, 0.0, -0.5),
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([
		0, 1, 2, 0, 2, 3,
		4, 5, 6, 4, 6, 7,
	])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
