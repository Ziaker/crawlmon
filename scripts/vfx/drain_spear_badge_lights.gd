class_name DrainSpearBadgeLights
extends Node3D
## move_drain_spear: the eight blue lights of the Badge Steal. They leave the impact
## point in eight different arcs, reach a static ring above the attacker (where the old
## crown was), stay there without orbiting, and fade slowly. No character, team or side
## is read: everything comes from the impact point and the attacker's body centre.

const VfxLib = preload("res://scripts/combat/vfx_lib.gd")
const COUNT := 8
const TRAVEL := 0.75  ## D-1014: the chains need time to read (was 0.30)
const STRETCH := 0.18  ## D-1014: the 8 threads shoot out from the target to the attacker
const SEGS := 24
const WAVE := 0.35  ## m, sideways ripple of each thread
const HOLD := 1.60
const FADE := 0.80
const RING_RADIUS := 1.45
const RING_HEIGHT := 2.00
const SIZE := 0.90

var _t := 0.0
var _starts: Array[Vector3] = []
var _ctrls: Array[Vector3] = []
var _ends: Array[Vector3] = []
var _lights: Array[MeshInstance3D] = []
var _mat: StandardMaterial3D
var _core_mat: StandardMaterial3D
var _center_fn: Callable
var _side1 := Vector3.RIGHT
var _side2 := Vector3.BACK
var _angles: Array[float] = []
var _chain: MeshInstance3D  ## D-1014: the 8 energy threads
var _chain_mat: StandardMaterial3D


## `center_fn` returns the attacker's live body centre, so the ring lands on the player
## after the return run instead of freezing where he stood when the blow landed.
func spawn(contact: Vector3, center_fn: Callable, count := COUNT) -> void:
	var n := maxi(count, 1)
	_center_fn = center_fn
	var player_center := _center(contact)
	var axis := player_center - contact
	var dir := axis.normalized() if axis.length() > 0.01 else Vector3.FORWARD
	var side1 := dir.cross(Vector3.UP)
	side1 = side1.normalized() if side1.length() > 0.01 else Vector3.RIGHT
	# side1 is horizontal, so cross it with UP (not with dir) to keep the ring flat.
	var side2 := side1.cross(Vector3.UP).normalized()
	if side2.length() < 0.01:
		side2 = Vector3.BACK
	_side1 = side1
	_side2 = side2
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat.albedo_texture = VfxLib.glow_tex()
	_mat.albedo_color = Color(0.14, 0.50, 1.0, 1.0)
	_mat.no_depth_test = true
	_core_mat = StandardMaterial3D.new()
	_core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_core_mat.albedo_color = Color(0.32, 0.70, 1.0, 1.0)
	_core_mat.emission_enabled = true
	_core_mat.emission = Color(0.14, 0.44, 1.0)
	_core_mat.emission_energy_multiplier = 1.8
	_core_mat.no_depth_test = true
	for i in n:
		var ang := TAU * float(i) / float(n)
		var ring := player_center + Vector3.UP * RING_HEIGHT + side1 * cos(ang) * RING_RADIUS + side2 * sin(ang) * RING_RADIUS
		# The control point sends each light on a different side before it converges on the ring.
		var ctrl := contact.lerp(ring, 0.5) + side1 * cos(ang) * 2.4 + side2 * sin(ang) * 2.4 + Vector3.UP * 0.7
		_starts.append(contact)
		_ctrls.append(ctrl)
		_ends.append(ring)
		_angles.append(ang)
		var mi := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(SIZE, SIZE)
		mi.mesh = quad
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.global_position = contact
		var core := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.10
		sphere.height = 0.20
		sphere.radial_segments = 8
		sphere.rings = 4
		core.mesh = sphere
		core.material_override = _core_mat
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(core)
		add_child(mi)
		_lights.append(mi)
	# D-1014 ("2 Correntes"): eight thin rippling threads stretched between the target and the attacker.
	_chain_mat = StandardMaterial3D.new()
	_chain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_chain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_chain_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_chain_mat.vertex_color_use_as_albedo = true
	_chain_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_chain_mat.no_depth_test = true
	_chain = MeshInstance3D.new()
	_chain.mesh = ImmediateMesh.new()
	_chain.material_override = _chain_mat
	_chain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chain.top_level = true
	add_child(_chain)
	_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / TRAVEL, 0.0, 1.0)
	var alpha := 1.0
	if _t > TRAVEL + HOLD:
		alpha = 1.0 - clampf((_t - (TRAVEL + HOLD)) / FADE, 0.0, 1.0)
	var center := _center(_starts[0] if not _starts.is_empty() else Vector3.ZERO)
	# D-1014: the threads shoot out (STRETCH), then reel in: each light is pulled along its thread from the target to
	# the ring, the thread's slack shrinking behind it, and the ring snaps shut when they arrive.
	var reel := clampf((_t - STRETCH) / maxf(TRAVEL - STRETCH, 0.01), 0.0, 1.0)
	reel = reel * reel * (3.0 - 2.0 * reel)
	var shoot := clampf(_t / STRETCH, 0.0, 1.0)
	var im := _chain.mesh as ImmediateMesh
	im.clear_surfaces()
	var cam := get_viewport().get_camera_3d()
	var view_pos := cam.global_position if cam != null else Vector3(0, 3, 8)
	var drew := false
	for i in _lights.size():
		var ring := center + Vector3.UP * RING_HEIGHT + _side1 * cos(_angles[i]) * RING_RADIUS + _side2 * sin(_angles[i]) * RING_RADIUS
		var p := _bezier(_starts[i], _ctrls[i], ring, reel)
		_lights[i].global_position = p
		# The thread: from the light back to the target end while it is being reeled, rippling and thinning.
		if reel < 1.0 and alpha > 0.01:
			if not drew:
				im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				drew = true
			var prev := Vector3.ZERO
			# Shoot: the thread grows from the target to the attacker. Reel: it spans from the light to the attacker.
			var a_u := 0.0 if shoot < 1.0 else reel
			var b_u := shoot
			for sgi in SEGS + 1:
				var u := float(sgi) / float(SEGS)
				var q := _bezier(_starts[i], _ctrls[i], ring, lerpf(a_u, b_u, u))
				var amp := WAVE * sin(u * PI) * (1.0 - reel)
				var side := (_side1 * cos(_angles[i] + 1.57) + _side2 * sin(_angles[i] + 1.57))
				q += side * sin(u * 9.0 - _t * 18.0 + float(i)) * amp
				if sgi > 0:
					var d := (q - prev)
					var w := d.cross(view_pos - q).normalized() * 0.035 * (1.0 - reel * 0.6)
					var c0 := Color(0.25, 0.65, 1.0, 0.9 * alpha)
					var c1 := Color(0.6, 0.85, 1.0, 0.9 * alpha)
					for v in [[prev + w, c0], [prev - w, c0], [q - w, c1], [prev + w, c0], [q - w, c1], [q + w, c1]]:
						im.surface_set_color(v[1])
						im.surface_add_vertex(v[0])
				prev = q
	if drew:
		im.surface_end()
	for i in _lights.size():
		var pop := clampf(_t / 0.12, 0.0, 1.0)
		if _t >= TRAVEL and _t < TRAVEL + 0.12:
			pop *= 1.0 + 0.6 * sin((_t - TRAVEL) / 0.12 * PI)  # D-1014: the ring snaps shut
		var pulse := 0.92 + 0.08 * sin(_t * 14.0 + float(i) * 0.7)
		_lights[i].scale = Vector3.ONE * pop * pulse
		_lights[i].visible = alpha > 0.01
	if _mat != null:
		var col := _mat.albedo_color
		col.a = alpha
		_mat.albedo_color = col
	if _core_mat != null:
		var core_col := _core_mat.albedo_color
		core_col.a = alpha
		_core_mat.albedo_color = core_col
		_core_mat.emission_energy_multiplier = 3.0 * alpha
	if _t >= TRAVEL + HOLD + FADE:
		queue_free()


func _center(fallback: Vector3) -> Vector3:
	if _center_fn.is_valid():
		var c = _center_fn.call()
		if c is Vector3:
			return c
	return fallback


static func _bezier(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)
