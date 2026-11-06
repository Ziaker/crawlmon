class_name AbraPops
extends RefCounted
## Layered one-shot effects for Abra's moves (D-170), built the way the Godot VFX skill asks:
## flash -> energy body (shader mesh) -> shockwave rings -> streaks and sparks -> aftermath.
## Colours are saturated and fully opaque where it matters (Compatibility renderer: no HDR).

const VIOLET := Color("b666ff")
const MAGENTA := Color("e056fd")
const PINK := Color("ff66b2")
const RUBY := Color("ff1744")
const YELLOW := Color("ffea00")
const ORANGE := Color("ff8a00")


## Shader energy column on a cylinder (local Y up). mode 0: swell and thin out; 1: starts full and collapses upward.
static func column(fx: Node3D, ground: Vector3, radius: float, height: float, c1: Color, c2: Color, dur: float, mode := 0, energy := 1.6, delay := 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.55
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := VfxLib.shader_mat("abra_column", {"color": c1, "color2": c2, "progress": 0.0, "energy": energy, "mode": mode})
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = ground + Vector3(0, height * 0.5, 0)
	mi.visible = delay <= 0.0
	fx.add_child(mi)
	var tw := mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
		tw.tween_callback(func() -> void: mi.visible = true)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 0.0, 1.0, dur)
	tw.tween_callback(mi.queue_free)
	return mi


## Flat expanding shockwave ring on the floor (the project's `ring` shader).
static func floor_ring(fx: Node3D, ground: Vector3, size: float, color: Color, dur: float, delay := 0.0, energy := 3.0) -> void:
	if delay > 0.0:
		fx.get_tree().create_timer(delay, false).timeout.connect(func() -> void:
			if is_instance_valid(fx):
				floor_ring(fx, ground, size, color, dur, 0.0, energy))
		return
	var q := VfxLib.animated_quad(fx, Vector2(size, size), "ring", {"color": color, "energy": energy}, dur)
	q.position = ground + Vector3(0, 0.07, 0)
	q.rotation_degrees = Vector3(-90, 0, 0)


## Vertical speed streaks (90 degrees up), purple and bright, rising and fading.
static func streaks_up(fx: Node3D, ground: Vector3, count: int, color: Color, spread: float, dur: float, energy := 3.0, rise := 3.2) -> void:
	var cam_p := Vector3(0, 3, 8)
	if fx is BattleFx:
		cam_p = (fx as BattleFx)._cam_pos()
	var yaw := atan2(cam_p.x - ground.x, cam_p.z - ground.z)
	for i in count:
		var length := randf_range(2.0, 4.8)
		var width := randf_range(0.12, 0.30)
		var life := dur * randf_range(0.7, 1.15)
		var q := VfxLib.animated_quad(fx, Vector2(width, length), "streak", {"color": color.lerp(Color.WHITE, randf() * 0.25), "energy": energy}, life)
		var start := ground + Vector3(randf_range(-spread, spread), randf_range(0.2, 1.6) + length * 0.5, randf_range(-spread, spread) * 0.5)
		q.position = start
		q.rotation.y = yaw
		var tw := q.create_tween()
		tw.tween_property(q, "position:y", start.y + rise * randf_range(0.7, 1.3), life).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


## Streaking sparks that shoot straight up.
static func sparks_up(fx: Node3D, pos: Vector3, color: Color, amount := 46, speed := Vector2(6.0, 15.0)) -> void:
	VfxLib.burst(fx, pos, {"tex": VfxLib.spark_tex(), "quad": Vector2(0.22, 1.1), "align_y": true, "amount": amount, "life": 0.55, "speed": speed,
		"dir": Vector3.UP, "spread": 28.0, "gravity": Vector3(0, -4.0, 0), "size": Vector2(0.5, 1.0), "end_scale": 0.2, "radius": 0.5,
		"ramp": VfxLib.ramp([Color.WHITE, color, Color(color, 0.0)], [0.0, 0.3, 1.0])})


## Vanish / appear mark of the Teleport: flash, energy column, rings, rising streaks, sparks and a fading ghost.
static func teleport_pop(fx: Node3D, ground: Vector3, vanishing: bool, model: Node3D = null) -> void:
	VfxLib.flash_star(fx, ground + Vector3(0, 1.1, 0), Color("e9c6ff"), 4.0, 0.14)
	VfxLib.flash_star(fx, ground + Vector3(0, 1.1, 0), VIOLET, 8.0, 0.30)
	column(fx, ground, 1.15, 6.5, VIOLET, MAGENTA, 0.42, 1 if vanishing else 0, 1.3)
	column(fx, ground, 0.55, 8.0, Color("d9a8ff"), PINK, 0.36, 1 if vanishing else 0, 1.3)
	floor_ring(fx, ground, 8.0, VIOLET, 0.55)
	floor_ring(fx, ground, 12.0, PINK, 0.65, 0.07)
	streaks_up(fx, ground, 18, VIOLET, 1.1, 0.5)
	sparks_up(fx, ground + Vector3(0, 0.3, 0), MAGENTA)
	if vanishing and model != null and is_instance_valid(model):
		VfxLib.ghost(fx, model, VIOLET, 0.4)
