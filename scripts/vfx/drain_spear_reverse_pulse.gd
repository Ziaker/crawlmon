class_name DrainSpearReversePulse
extends Node3D
## D-1021 (Badge Steal): the stolen energy is born as a CIRCLE of small energy shards around the contact, opening for
## 0.35 s (each shard rides an expanding ring, turning with it), then every shard bends and homes onto the attacker.
## Each shard is an animated flipbook head (lightning sheet, cyan) with a fading streak behind it. Built from the
## impact point and the attacker's live body centre (D-235): no character, team or side.

const VfxLib = preload("res://scripts/combat/vfx_lib.gd")
const FB_SHADER := preload("res://shaders/flipbook.gdshader")
const COUNT := 24
const OPEN_T := 0.35  ## creator: the circle expands for 0.35 s before going to the attacker
const RING_R := 1.9  ## m, circle radius at the end of the opening
const SPIN := 1.2  ## rad/s the circle turns while it opens
const HOME_MIN := 0.40
const HOME_MAX := 0.60  ## s each shard takes to reach the attacker (staggered)
const HEAD_SIZE := 0.42
const TAIL := 0.07
const WIDTH := 0.05
const COL := Color(0.35, 0.85, 1.0)
const HEAD := Color(0.8, 0.97, 1.0)

var _t := 0.0
var _contact := Vector3.ZERO
var _center_fn: Callable
var _streaks: MeshInstance3D
var _heads: Array[MeshInstance3D] = []
var _homes: Array[float] = []
var _ax_u := Vector3.RIGHT
var _ax_v := Vector3.UP
var _hist: Array = []  ## per shard: recent positions


func spawn(contact: Vector3, center_fn: Callable) -> void:
	_contact = contact
	_center_fn = center_fn
	top_level = true
	# The circle lies in the plane facing the attacker (perpendicular to target -> attacker).
	var axis := _center() - contact
	axis = axis.normalized() if axis.length() > 0.01 else Vector3.FORWARD
	_ax_u = axis.cross(Vector3.UP)
	_ax_u = _ax_u.normalized() if _ax_u.length() > 0.01 else Vector3.RIGHT
	_ax_v = _ax_u.cross(axis).normalized()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in COUNT:
		_homes.append(rng.randf_range(HOME_MIN, HOME_MAX))
		_hist.append([])
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		mi.mesh = q
		var m := ShaderMaterial.new()
		m.shader = FB_SHADER
		m.set_shader_parameter("sheet_tex", VfxLib.flipbook_tex("lightning"))
		m.set_shader_parameter("color", COL)
		m.set_shader_parameter("energy", 3.2)
		m.set_shader_parameter("h_frames", 4)
		m.set_shader_parameter("v_frames", 4)
		m.set_shader_parameter("roll_rad", rng.randf() * TAU)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3.ONE * HEAD_SIZE * rng.randf_range(0.7, 1.2)
		add_child(mi)
		_heads.append(mi)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.vertex_color_use_as_albedo = true
	sm.no_depth_test = true
	_streaks = MeshInstance3D.new()
	_streaks.mesh = ImmediateMesh.new()
	_streaks.material_override = sm
	_streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_streaks)
	_t = 0.0


func _center() -> Vector3:
	if _center_fn.is_valid():
		var c = _center_fn.call()
		if c is Vector3:
			return c
	return _contact


func _ring_point(i: int, t: float) -> Vector3:
	var k := clampf(t / OPEN_T, 0.0, 1.0)
	k = 1.0 - pow(1.0 - k, 3.0)
	var a := TAU * float(i) / float(COUNT) + SPIN * t
	return _contact + (_ax_u * cos(a) + _ax_v * sin(a)) * RING_R * k


func _pos(i: int, att: Vector3) -> Vector3:
	if _t <= OPEN_T:
		return _ring_point(i, _t)
	var u := clampf((_t - OPEN_T) / _homes[i], 0.0, 1.0)
	u = u * u  # accelerates into the attacker
	var start := _ring_point(i, OPEN_T)
	var bend := start + (start - _contact).normalized() * 0.8 + Vector3.UP * 0.5
	var v := 1.0 - u
	return start * v * v + bend * 2.0 * v * u + att * u * u


func _process(delta: float) -> void:
	_t += delta
	var att := _center()
	var cam := get_viewport().get_camera_3d()
	var vp := cam.global_position if cam != null else Vector3(0, 3, 8)
	var im := _streaks.mesh as ImmediateMesh
	im.clear_surfaces()
	var started := false
	var alive := false
	for i in COUNT:
		var done := _t > OPEN_T + _homes[i]
		_heads[i].visible = not done
		if done:
			continue
		alive = true
		var p := _pos(i, att)
		_heads[i].global_position = p
		var m := _heads[i].material_override as ShaderMaterial
		m.set_shader_parameter("progress", fmod(_t * 2.5 + float(i) * 0.13, 1.0))  # the shard flickers through its sheet
		var h: Array = _hist[i]
		h.append([_t, p])
		while h.size() > 0 and _t - float(h[0][0]) > TAIL:
			h.pop_front()
		if h.size() >= 2:
			if not started:
				im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				started = true
			for j in range(h.size() - 1):
				var a: Vector3 = h[j][1]
				var b: Vector3 = h[j + 1][1]
				if a.distance_to(b) < 0.0005:
					continue
				var w := (b - a).cross(vp - b).normalized() * WIDTH
				var ka := float(j) / float(h.size())
				var kb := float(j + 1) / float(h.size())
				for vtx in [[a + w * ka, Color(COL, 0.6 * ka)], [a - w * ka, Color(COL, 0.6 * ka)], [b - w * kb, Color(HEAD, 0.9 * kb)],
						[a + w * ka, Color(COL, 0.6 * ka)], [b - w * kb, Color(HEAD, 0.9 * kb)], [b + w * kb, Color(HEAD, 0.9 * kb)]]:
					im.surface_set_color(vtx[1])
					im.surface_add_vertex(vtx[0])
	if started:
		im.surface_end()
	if not alive:
		queue_free()
