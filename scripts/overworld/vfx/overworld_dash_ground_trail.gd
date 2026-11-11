class_name OverworldDashGroundTrail
extends MeshInstance3D
## D-1100: rastro no chão do avanço de ataque no overworld.
##
## Fita construída com os pontos de chão medidos por raycast no componente
## principal. Cada ponto guarda a altura real do chão; a fita é desenhada a
## 4 cm acima dele. Nada é interpolado no ar: se o raycast falha, o segmento
## é cortado (link=false) em vez de ligar dois pontos por cima do vazio.
##
## Duas camadas no mesmo ImmediateMesh: um halo largo e um núcleo estreito.
## Material unshaded + aditivo + vertex color (gl_compatibility), sem decal,
## sem trail, sem sub-emitter. O alpha por vértice faz o fade ao longo da fita.

const MAX_POINTS := 96
const MAX_AGE := 1.40
const SURFACE_OFFSET := 0.04
const FADE_OUT_TIME := 0.36

var _points: Array[Dictionary] = []
var _mesh := ImmediateMesh.new()
var _mat_glow: StandardMaterial3D
var _mat_core: StandardMaterial3D
var _color := Color.WHITE
var _base_width := 0.28
var _fade := 1.0
var _fading := false
var _active := false


func setup_mesh() -> void:
	material_override = null
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	custom_aabb = AABB(Vector3(-12, -1, -12), Vector3(24, 4, 24))
	if _mat_glow == null:
		_mat_glow = _make_material(true)
		_mat_core = _make_material(false)


func begin(p_color: Color, base_width: float) -> void:
	setup_mesh()
	_color = p_color
	_base_width = clampf(base_width, 0.08, 0.34)
	_points.clear()
	_fade = 1.0
	_fading = false
	_active = true
	_mesh.clear_surfaces()
	visible = false


## ground_point: ponto do chão (já com o offset de 4 cm). ground_y: altura do
## chão medida pelo raycast. linked: se este ponto liga ao anterior.
func add_point(ground_point: Vector3, ground_y: float, linked: bool) -> void:
	if not _active:
		return
	if not _points.is_empty():
		var last: Dictionary = _points[_points.size() - 1]
		if (last["pos"] as Vector3).distance_to(ground_point) < 0.025:
			return
	_points.append({
		"pos": ground_point,
		"ground_y": ground_y,
		"age": 0.0,
		"link": linked,
	})
	while _points.size() > MAX_POINTS:
		_points.pop_front()


func tick(delta: float) -> void:
	if not _active:
		return
	for p in _points:
		p["age"] = float(p["age"]) + delta
	while not _points.is_empty() and float(_points[0]["age"]) > MAX_AGE:
		_points.pop_front()
	if _fading:
		_fade = maxf(0.0, _fade - delta / FADE_OUT_TIME)
		if _fade <= 0.001:
			_points.clear()
			_active = false
	_rebuild()


func begin_fade() -> void:
	_fading = true


func stop_adding() -> void:
	_active = false


func finish_now() -> void:
	_points.clear()
	_fading = false
	_fade = 0.0
	_active = false
	if is_instance_valid(_mesh):
		_mesh.clear_surfaces()
	visible = false


func clear() -> void:
	finish_now()


func point_count() -> int:
	return _points.size()


## Maior distância entre um ponto desenhado e o chão medido por raycast.
## Serve de gate contra "rastro no ar".
func max_above_ground() -> float:
	var m := 0.0
	for p in _points:
		var above := absf((p["pos"] as Vector3).y - float(p["ground_y"]))
		m = maxf(m, above)
	return m


func get_debug_state() -> Dictionary:
	var head := Vector3.ZERO
	var tail := Vector3.ZERO
	var span := 0.0
	if not _points.is_empty():
		head = _points[_points.size() - 1]["pos"]
		tail = _points[0]["pos"]
		span = Vector2(head.x - tail.x, head.z - tail.z).length()
	return {
		"points": _points.size(),
		"max_above_ground": max_above_ground(),
		"fade": _fade,
		"fading": _fading,
		"head": head,
		"tail": tail,
		"span": span,
	}


func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _points.size() < 2:
		visible = false
		return
	visible = true
	var n := _points.size()
	var perps: Array[Vector3] = []
	perps.resize(n)
	var aabb := AABB(_points[0]["pos"], Vector3.ZERO)
	for i in n:
		var pos: Vector3 = _points[i]["pos"]
		aabb = aabb.expand(pos)
		var prev: Vector3 = _points[maxi(i - 1, 0)]["pos"]
		var next: Vector3 = _points[mini(i + 1, n - 1)]["pos"]
		var tangent := next - prev
		tangent.y = 0.0
		var perp := Vector3.RIGHT
		if tangent.length_squared() > 0.000001:
			perp = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		perps[i] = perp
	custom_aabb = AABB(aabb.position - Vector3(1.0, 0.5, 1.0), aabb.size + Vector3(2.0, 1.5, 2.0))
	var head_pos: Vector3 = _points[n - 1]["pos"]
	_build_surface(_mat_glow, perps, 1.8, 0.50, false, head_pos)
	_build_surface(_mat_core, perps, 1.0, 1.0, false, head_pos)


func _build_surface(mat: StandardMaterial3D, perps: Array[Vector3], width_mult: float, alpha_mult: float, whiten: bool, head_pos: Vector3) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	var base := _color.lerp(Color.WHITE, 0.36) if whiten else _color
	for i in range(1, _points.size()):
		if not bool(_points[i]["link"]):
			continue
		var p0: Dictionary = _points[i - 1]
		var p1: Dictionary = _points[i]
		var a0 := _point_alpha(p0)
		var a1 := _point_alpha(p1)
		if a0 <= 0.001 and a1 <= 0.001:
			continue
		var pa: Vector3 = p0["pos"]
		var pb: Vector3 = p1["pos"]
		var wa := _point_width(p0, width_mult, head_pos)
		var wb := _point_width(p1, width_mult, head_pos)
		var la := pa - perps[i - 1] * wa
		var ra := pa + perps[i - 1] * wa
		var lb := pb - perps[i] * wb
		var rb := pb + perps[i] * wb
		_mesh.surface_set_color(Color(base.r, base.g, base.b, a0 * alpha_mult))
		_mesh.surface_add_vertex(la)
		_mesh.surface_set_color(Color(base.r, base.g, base.b, a0 * alpha_mult))
		_mesh.surface_add_vertex(ra)
		_mesh.surface_set_color(Color(base.r, base.g, base.b, a1 * alpha_mult))
		_mesh.surface_add_vertex(lb)
		_mesh.surface_set_color(Color(base.r, base.g, base.b, a0 * alpha_mult))
		_mesh.surface_add_vertex(ra)
		_mesh.surface_set_color(Color(base.r, base.g, base.b, a1 * alpha_mult))
		_mesh.surface_add_vertex(rb)
		_mesh.surface_set_color(Color(base.r, base.g, base.b, a1 * alpha_mult))
		_mesh.surface_add_vertex(lb)
	_mesh.surface_end()


func _point_alpha(p: Dictionary) -> float:
	var t := clampf(float(p["age"]) / MAX_AGE, 0.0, 1.0)
	return pow(1.0 - t, 0.70) * _fade


func _point_width(p: Dictionary, mult: float, head_pos: Vector3) -> float:
	var pos: Vector3 = p["pos"]
	var dx := pos.x - head_pos.x
	var dz := pos.z - head_pos.z
	var dist := sqrt(dx * dx + dz * dz)
	var taper := clampf(1.0 - dist / 3.2, 0.06, 1.0)
	var t := clampf(float(p["age"]) / MAX_AGE, 0.0, 1.0)
	var age_taper := 0.55 + 0.45 * (1.0 - t)
	# _base_width é a largura TOTAL do núcleo na cabeça; a fita usa metade
	# para cada lado. O halo é 2× o núcleo.
	return _base_width * mult * 0.5 * taper * age_taper


func _make_material(is_glow: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.disable_receive_shadows = true
	mat.albedo_color = Color(1, 1, 1, 1)
	if is_glow:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.render_priority = 1
	return mat
