class_name WarCryVfx
extends Node3D
## D-1106 (direction C, revised by the creator): a megaphone cone of fast rings.
## The tip is at the caster's mouth; the rings travel toward the opponents, grow with
## the cone and lose opacity over time. Hand-built (D-1030); all anchors come from the
## real caster, the real enemies and the camera (D-235).

const WHITE := Color("fffdf6")
const CREAM := Color("f0ebde")
const ASH := Color("9c968a")
const DURATION := 1.20  ## Impact-start effect: the cone fades at 0.90 s; the rest ends well before this.
const RELEASE_TIME := 0.0  ## Starts at the Move's impact, so the shout leaves with the animation.
const TRAVEL_TIME := 0.38
const STAGGER := 0.03
const RING_COUNT := 7
const TIP_R := 0.10
const RING_SHADER := preload("res://shaders/war_cry_ring.gdshader")
const CONE_SHADER := preload("res://shaders/war_cry_cone.gdshader")
const DISTORT_SHADER := preload("res://shaders/war_cry_distort.gdshader")
const WAVE_TEX := preload("res://assets/vfx/war_cry_wave_tex.png")

var fx: BattleFx
var caster: Combatant
var mouth := Vector3.ZERO
var forward := Vector3.FORWARD
var body_h := 1.6
var _axis := Vector3.FORWARD
var _length := 10.0
var _far_r := 3.0
var _t := 0.0
var _core: MeshInstance3D
var _cone: MeshInstance3D
var _cone_mat: ShaderMaterial
var _rings: Array[Dictionary] = []
var _distort_layer: CanvasLayer
var _distort_mat: ShaderMaterial


static func start(p_fx: BattleFx, inc: Incoming) -> WarCryVfx:
	var v := WarCryVfx.new()
	v.name = "WarCryVfx"
	v.fx = p_fx
	v.caster = inc.attacker
	p_fx.add_child(v)
	v._build()
	return v


func _build() -> void:
	var model: Node3D = fx._models.get(caster)
	var head := Vector3.ZERO
	var yaw := caster.yaw
	forward = Vector3(sin(yaw), 0.0, cos(yaw)).normalized()
	if model != null:
		var sk := _skeleton(model)
		var hb := _head_bone(sk)
		if sk != null and hb >= 0:
			head = sk.global_transform * sk.get_bone_global_pose(hb).origin
		else:
			head = model.global_position + Vector3.UP * 1.6
		body_h = maxf(1.0, head.y - model.global_position.y + 0.3)
	else:
		head = fx.rest_pos(caster) + Vector3.UP * 1.6
	mouth = head + forward * (body_h * 0.10) + Vector3.DOWN * (body_h * 0.06)
	_compute_cone()
	if RELEASE_TIME > 0.0:
		_build_windup()
	_build_distortion()
	set_process(true)
	_run()


func _run() -> void:
	if RELEASE_TIME <= 0.0:
		_release()
		return
	await get_tree().create_timer(RELEASE_TIME, false).timeout
	_release()


func _compute_cone() -> void:
	var foes: Array[Combatant] = fx.battle.enemies if caster.is_player else fx.battle.party
	var living: Array[Combatant] = []
	for foe in foes:
		if foe != null and foe.is_alive():
			living.append(foe)
	if living.is_empty():
		_axis = forward
		_length = 10.0
		_far_r = 3.2
		return
	var center := Vector3.ZERO
	for foe in living:
		center += foe.pos
	center /= float(living.size())
	var flat := Vector3(center.x - mouth.x, 0.0, center.z - mouth.z)
	if flat.length_squared() < 0.001:
		flat = forward
	_axis = flat.normalized()
	var max_d := 0.0
	var spread := 0.0
	var max_ratio := 0.0
	for foe in living:
		var d := Vector3(foe.pos.x - mouth.x, 0.0, foe.pos.z - mouth.z)
		var dist := d.length()
		max_d = maxf(max_d, dist)
		spread = maxf(spread, Vector2(foe.pos.x - center.x, foe.pos.z - center.z).length())
		if dist > 0.5:
			var lat := absf(d.x * _axis.z - d.z * _axis.x)
			max_ratio = maxf(max_ratio, lat / dist)
	_length = clampf(max_d + 2.0, 6.0, 28.0)
	# Cover every enemy laterally, with a generous minimum fan (Elden Ring roar).
	_far_r = maxf(maxf(spread + 2.0, max_ratio * _length + 1.5), _length * 0.65)
	_far_r = clampf(_far_r, 3.0, 30.0)


func _build_windup() -> void:
	var size := clampf(body_h * 0.32, 0.35, 0.9)
	var core := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	core.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = VfxLib.glow_tex()
	mat.albedo_color = Color(1.0, 0.16, 0.08, 0.0)
	core.material_override = mat
	core.position = mouth
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.add_child(core)
	_core = core
	var tw := core.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.95, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(core, "scale", Vector3.ONE * 1.18, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# A thin ring at the mouth contracts to the tip during the wind-up.
	var air := _torus(0.985, 1.0, WHITE, WHITE, 1.4, 0.85, 0.35, 3.0)
	air.position = mouth
	air.transform.basis = _basis_y(_axis)
	air.scale = Vector3.ONE * maxf(0.55, body_h * 0.35)
	fx.add_child(air)
	var air_tw := air.create_tween().set_parallel(true)
	air_tw.tween_property(air, "scale", Vector3.ONE * 0.14, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	air_tw.tween_method(func(v: float) -> void: (air.material_override as ShaderMaterial).set_shader_parameter("alpha", v), 0.85, 0.0, 0.26)
	air_tw.chain().tween_callback(air.queue_free)

	var feet := Vector3(fx.rest_pos(caster).x, 0.05, fx.rest_pos(caster).z)
	VfxLib.burst(fx, feet, {
		"tex": VfxLib.smoke_tex(), "additive": false, "amount": 14, "life": 0.75,
		"direction": Vector3.UP, "spread": 75.0, "speed": Vector2(1.0, 3.2),
		"size": Vector2(body_h * 0.10, body_h * 0.24), "end_scale": 0.25,
		"gravity": Vector3(0.0, 0.6, 0.0), "radius": body_h * 0.22,
		"ramp": VfxLib.ramp([Color("b8a58a", 0.55), Color("8c7b66", 0.25), Color(0, 0, 0, 0)], [0.0, 0.45, 1.0])
	})
	VfxLib.burst(fx, feet, {
		"tex": VfxLib.glow_tex(), "additive": true, "amount": 6, "life": 0.55,
		"direction": Vector3.UP, "spread": 60.0, "speed": Vector2(2.0, 4.0),
		"size": Vector2(0.06, 0.14), "end_scale": 0.1,
		"gravity": Vector3(0.0, -6.0, 0.0), "radius": body_h * 0.3,
		"ramp": VfxLib.ramp([WHITE, CREAM, Color(0, 0, 0, 0)], [0.0, 0.4, 1.0])
	})


func _release() -> void:
	if _core != null and is_instance_valid(_core):
		VfxLib.flash_star(fx, mouth, WHITE, clampf(body_h * 0.7, 1.0, 2.6), 0.14)
		var core_tw := _core.create_tween()
		core_tw.tween_property(_core, "scale", Vector3.ONE * 2.2, 0.10)
		core_tw.parallel().tween_property((_core.material_override as StandardMaterial3D), "albedo_color:a", 0.0, 0.14)
		core_tw.chain().tween_callback(_core.queue_free)

	_spawn_cone()
	# Final4 order: the rings leave in a short staggered volley and then fade with distance.
	for i in RING_COUNT:
		_spawn_ring(RELEASE_TIME + float(i) * STAGGER)

	# Speed lines inside the megaphone, pointing at the opponents.
	VfxLib.burst(fx, mouth, {
		"tex": VfxLib.spark_tex(), "additive": true, "amount": 18, "life": 0.36,
		"direction": _axis, "spread": 14.0, "speed": Vector2(11.0, 20.0),
		"size": Vector2(0.08, 0.20), "end_scale": 0.1, "align_y": true,
		"quad": Vector2(0.06, 0.36),
		"ramp": VfxLib.ramp([WHITE, CREAM, Color(0, 0, 0, 0)], [0.0, 0.35, 1.0])
	})
	# Pale ash/white embers carried by the shout.
	VfxLib.burst(fx, mouth, {
		"tex": VfxLib.glow_tex(), "additive": true, "amount": 20, "life": 0.55,
		"direction": _axis, "spread": 26.0, "speed": Vector2(6.0, 15.0),
		"size": Vector2(0.04, 0.12), "end_scale": 0.1,
		"gravity": Vector3(0.0, -1.5, 0.0),
		"ramp": VfxLib.ramp([WHITE, ASH, Color(0, 0, 0, 0)], [0.0, 0.35, 1.0])
	})
	var far := mouth + _axis * _length
	VfxLib.burst(fx, Vector3(far.x, 0.06, far.z), {
		"tex": VfxLib.smoke_tex(), "additive": false, "amount": 16, "life": 0.9,
		"direction": Vector3.UP, "spread": 80.0, "speed": Vector2(1.0, 4.0),
		"size": Vector2(0.2, 0.5), "end_scale": 0.2,
		"gravity": Vector3(0.0, 0.3, 0.0), "radius": 2.0,
		"ramp": VfxLib.ramp([Color("b8a58a", 0.5), Color("8c7b66", 0.2), Color(0, 0, 0, 0)], [0.0, 0.45, 1.0])
	})

	_distort()


func _spawn_cone() -> void:
	var cm := CylinderMesh.new()
	cm.bottom_radius = TIP_R
	cm.top_radius = _far_r
	cm.height = _length
	cm.radial_segments = 48
	cm.rings = 1
	cm.cap_bottom = false
	cm.cap_top = false
	_cone = MeshInstance3D.new()
	_cone.name = "WarCryCone"
	_cone.mesh = cm
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cone_mat = ShaderMaterial.new()
	_cone_mat.shader = CONE_SHADER
	_cone_mat.set_shader_parameter("color", WHITE)
	_cone_mat.set_shader_parameter("core", CREAM)
	_cone_mat.set_shader_parameter("alpha", 0.22)
	_cone_mat.set_shader_parameter("energy", 1.35)
	_cone_mat.set_shader_parameter("wave_tex", WAVE_TEX)
	_cone.material_override = _cone_mat
	_cone.transform = Transform3D(_basis_y(_axis), mouth + _axis * (_length * 0.5))
	add_child(_cone)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _cone_mat.set_shader_parameter("alpha", v), 0.16, 0.0, 0.90)
	tw.tween_callback(_cone.queue_free)


func _spawn_ring(start: float) -> void:
	var mi := _torus(0.90, 1.0, WHITE, CREAM, 2.2, 0.35, 0.35, randf() * 10.0)
	mi.name = "WarCryRing"
	mi.transform = Transform3D(_basis_y(_axis), mouth)
	mi.scale = Vector3.ONE * TIP_R
	mi.visible = false
	add_child(mi)
	_rings.append({"node": mi, "start": start})


func _process(delta: float) -> void:
	_t += delta
	if _cone_mat != null and is_instance_valid(_cone_mat):
		_cone_mat.set_shader_parameter("time", _t)
	for ring in _rings:
		var mi: MeshInstance3D = ring["node"]
		if mi == null or not is_instance_valid(mi):
			continue
		var p := (_t - float(ring["start"])) / TRAVEL_TIME
		if p < 0.0 or p >= 1.0:
			mi.visible = false
			continue
		# Final4 distance fade, but starting at 35% opacity (creator): the farther the
		# white ring travels from the caster, the more opacity it loses.
		var alpha := 0.35 * pow(maxf(0.0, 1.0 - p), 2.5)
		if alpha <= 0.01:
			mi.visible = false
			continue
		mi.visible = true
		mi.position = mouth + _axis * (_length * p)
		var r := lerpf(TIP_R, _far_r, p)
		mi.scale = Vector3.ONE * r
		(mi.material_override as ShaderMaterial).set_shader_parameter("alpha", alpha)
	if _t >= DURATION:
		queue_free()


func _torus(inner: float, outer: float, col: Color, core: Color, energy: float, alpha: float, noise: float, seed: float) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 48
	tm.ring_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter("ring_color", col)
	mat.set_shader_parameter("core_color", core)
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("alpha", alpha)
	mat.set_shader_parameter("noise_amount", noise)
	mat.set_shader_parameter("seed", seed)
	mi.material_override = mat
	return mi


func _basis_y(y: Vector3) -> Basis:
	var yy := y.normalized()
	var xx := yy.cross(Vector3.UP)
	if xx.length_squared() < 0.001:
		xx = yy.cross(Vector3.RIGHT)
	xx = xx.normalized()
	var zz := xx.cross(yy).normalized()
	return Basis(xx, yy, zz)


func _build_distortion() -> void:
	_distort_layer = CanvasLayer.new()
	_distort_layer.name = "WarCryDistortion"
	_distort_layer.layer = 0
	add_child(_distort_layer)
	var rect := ColorRect.new()
	rect.name = "WarCryDistortionRect"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_distort_mat = ShaderMaterial.new()
	_distort_mat.shader = DISTORT_SHADER
	_distort_mat.set_shader_parameter("amount", 0.0)
	_distort_mat.set_shader_parameter("blur", 4.0)
	_distort_mat.set_shader_parameter("strength", 0.006)
	rect.material = _distort_mat
	_distort_layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _distort() -> void:
	if _distort_mat == null:
		return
	var cam := fx.get_viewport().get_camera_3d()
	if cam != null and not cam.is_position_behind(mouth):
		var screen := cam.unproject_position(mouth)
		var size := fx.get_viewport().get_visible_rect().size
		_distort_mat.set_shader_parameter("center", Vector2(
			clampf(screen.x / maxf(size.x, 1.0), 0.0, 1.0),
			clampf(screen.y / maxf(size.y, 1.0), 0.0, 1.0)))
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _distort_mat.set_shader_parameter("amount", v), 0.0, 0.85, 0.10)
	tw.tween_method(func(v: float) -> void: _distort_mat.set_shader_parameter("amount", v), 0.85, 0.0, 0.22)
	tw.tween_callback(_distort_layer.queue_free)


static func impact(p_fx: BattleFx, _target: Combatant, pos: Vector3) -> void:
	# D-1106: War Cry-specific white pulses around the interrupted character, 0.35 s.
	VfxLib.flash_star(p_fx, pos, WHITE, 2.0, 0.12)
	for i in 2:
		var size := 4.0 + float(i) * 1.8
		var ring := VfxLib.animated_quad(p_fx, Vector2(size, size), "ring", {"color": WHITE, "energy": 4.0 - float(i) * 0.5}, 0.35)
		ring.position = pos
		p_fx._face_camera(ring)
	var ground := VfxLib.animated_quad(p_fx, Vector2(5.5, 5.5), "ring", {"color": WHITE, "energy": 3.0}, 0.35)
	ground.position = Vector3(pos.x, 0.06, pos.z)
	ground.rotation_degrees = Vector3(-90, 0, 0)
	_pulse_ring(p_fx, pos, pos.y, 3.4, 0.35)
	_pulse_ring(p_fx, pos, maxf(0.20, pos.y - 0.55), 2.6, 0.35)
	VfxLib.burst(p_fx, pos, {
		"tex": VfxLib.spark_tex(), "additive": true, "amount": 10, "life": 0.30,
		"direction": Vector3.UP, "spread": 180.0, "speed": Vector2(4.0, 9.0),
		"size": Vector2(0.05, 0.14), "end_scale": 0.1,
		"ramp": VfxLib.ramp([WHITE, CREAM, Color(0, 0, 0, 0)], [0.0, 0.35, 1.0])
	})


static func _pulse_ring(p_fx: BattleFx, pos: Vector3, y: float, radius: float, duration: float) -> void:
	var tm := TorusMesh.new()
	tm.inner_radius = 0.94
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter("ring_color", WHITE)
	mat.set_shader_parameter("core_color", CREAM)
	mat.set_shader_parameter("energy", 2.6)
	mat.set_shader_parameter("alpha", 0.95)
	mat.set_shader_parameter("noise_amount", 0.20)
	mat.set_shader_parameter("seed", randf() * 10.0)
	mi.material_override = mat
	mi.position = Vector3(pos.x, y, pos.z)
	mi.scale = Vector3.ONE * 0.25
	p_fx.add_child(mi)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("alpha", v), 0.95, 0.0, duration)
	tw.chain().tween_callback(mi.queue_free)


func _skeleton(model: Node3D) -> Skeleton3D:
	var found := model.find_children("*", "Skeleton3D", true, false)
	return found[0] as Skeleton3D if not found.is_empty() else null


func _head_bone(sk: Skeleton3D) -> int:
	if sk == null:
		return -1
	for i in sk.get_bone_count():
		var n := sk.get_bone_name(i).to_lower()
		if n == "head" or n.ends_with("_head") or n == "j_kao":
			return i
	return -1
