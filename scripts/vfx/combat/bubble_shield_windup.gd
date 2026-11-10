class_name BubbleShieldWindup
extends RefCounted
## Wind-up do Bubble Shield: uma coroa de papel em volta de CADA aliado, com
## raio próprio (1,12x o raio do corpo), painéis em camadas, fitas mágicas em
## contra-movimento e confete. Permanece durante a formação e se desfaz em 1,45 s.

const WINDUP := 0.7
const RELEASE_SECONDS := 1.45
const SPIN := 0.85

var fx
var target: Combatant
var model: Node3D
var root: Node3D
var center: Vector3
var radius: float
var paper_scale := 1.0
var paper_top := 1.0

var panels: Array = []
var ribbons: Array = []
var shards: Array = []
var base_ring: MeshInstance3D
var base_ring_mat: StandardMaterial3D

var age := 0.0
var time := 0.0
var releasing := false
var release_t := 0.0
var done := false


func _init(p_fx: FxBubbleShield, p_target: Combatant) -> void:
	fx = p_fx
	target = p_target
	model = fx.model_of(target)
	center = _ground_of_model()
	radius = _radius_of_model()
	paper_scale = clampf(radius / 2.4, 0.45, 1.5) * 0.9
	paper_top = maxf(0.80, radius * 0.90)
	root = Node3D.new()
	root.name = "BubbleShieldWindup"
	root.position = Vector3(center.x, 0.015, center.z)
	root.scale = Vector3.ONE * 0.22
	fx.root.add_child(root)
	_build_base_ring()
	_build_panels()
	_build_ribbons()
	_build_shards()


func _ground_of_model() -> Vector3:
	if model != null and is_instance_valid(model):
		var anchor: Vector3 = fx.body_anchor(model)
		return Vector3(anchor.x, 0.0, anchor.z)
	return Vector3.ZERO


func _radius_of_model() -> float:
	if model != null and is_instance_valid(model):
		var env := FxBubbleShield.body_envelope(model)
		return maxf(1.15, float(env["radius"]) * 1.12)
	return 1.15


func _build_base_ring() -> void:
	base_ring = MeshInstance3D.new()
	base_ring.name = "PaperBaseRing"
	base_ring.mesh = FxBubbleShield.ring_mesh(radius - 0.20, radius + 0.05, 96)
	base_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	base_ring_mat = StandardMaterial3D.new()
	base_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	base_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	base_ring_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	base_ring_mat.albedo_color = Color("1450a8")
	base_ring_mat.albedo_color.a = 0.26
	base_ring.material_override = base_ring_mat
	root.add_child(base_ring)


func _build_panels() -> void:
	for i in 10:
		var a := (float(i) / 10.0) * TAU
		var rad := radius * 0.92
		var panel := Node3D.new()
		panel.name = "PaperPanel%d" % i
		panel.position = Vector3(cos(a) * rad, 0.0, sin(a) * rad)
		panel.rotation.y = PI * 0.5 - a
		panel.set_meta("base_angle", a)
		panel.set_meta("base_rot_y", panel.rotation.y)
		panel.set_meta("phase", float(i) * 1.7)
		root.add_child(panel)

		var line_color := Color("04152b")
		var line_mat := _flat_mat(line_color, 0.45, 2)
		var mats: Array = [{"mat": line_mat, "color": line_color, "base": 0.45}]
		var base_h := (1.32 + 0.16 * sin(float(i) * 1.55 + 0.4)) * paper_scale

		var layers := [
			{
				"color": FxBubbleShield.PAPER_COLORS[0],
				"w": 1.55 * paper_scale, "h": base_h * 1.18,
				"x": -0.04 * paper_scale, "y": 0.0, "z": 0.0,
			},
			{
				"color": FxBubbleShield.PAPER_COLORS[1],
				"w": 1.34 * paper_scale, "h": base_h,
				"x": 0.03 * paper_scale, "y": 0.030 * paper_scale, "z": 0.014 * paper_scale,
			},
		]
		for cfg in layers:
			var points := _paper_wave_points(float(cfg["w"]), float(cfg["h"]))
			var mat := _flat_mat(cfg["color"], 1.0, 0)
			mats.append({"mat": mat, "color": cfg["color"], "base": 1.0})
			var layer := MeshInstance3D.new()
			layer.name = "PaperLayer"
			layer.mesh = FxBubbleShield.paper_mesh(points)
			layer.material_override = mat
			layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			layer.position = Vector3(float(cfg["x"]), float(cfg["y"]), float(cfg["z"]))
			var outline := MeshInstance3D.new()
			outline.name = "PaperOutline"
			outline.mesh = FxBubbleShield.outline_mesh(points, 0.002)
			outline.material_override = line_mat
			outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			layer.add_child(outline)
			panel.add_child(layer)

		var foam_color := FxBubbleShield.SHELL_WHITE
		var foam_mat := _flat_mat(foam_color, 1.0, 1)
		mats.append({"mat": foam_mat, "color": foam_color, "base": 1.0})
		var curls := [
			{"r": 0.31 * paper_scale, "w": 0.085 * paper_scale, "x": 0.12 * paper_scale,
				"y": base_h * 0.76, "rot": -0.15, "start": 0.15, "end": 2.7},
			{"r": 0.22 * paper_scale, "w": 0.070 * paper_scale, "x": -0.19 * paper_scale,
				"y": base_h * 0.84, "rot": 0.45, "start": 0.25, "end": 2.4},
		]
		for c in curls:
			var curl_points := _paper_curl_points(float(c["r"]), float(c["w"]), float(c["start"]), float(c["end"]))
			var curl := MeshInstance3D.new()
			curl.name = "FoamCurl"
			curl.mesh = FxBubbleShield.paper_mesh(curl_points)
			curl.material_override = foam_mat
			curl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			curl.position = Vector3(float(c["x"]), float(c["y"]), 0.030)
			curl.rotation.z = float(c["rot"])
			var curl_outline := MeshInstance3D.new()
			curl_outline.mesh = FxBubbleShield.outline_mesh(curl_points, 0.002)
			curl_outline.material_override = line_mat
			curl_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			curl.add_child(curl_outline)
			panel.add_child(curl)

		var foam_radius := 0.062 * paper_scale
		for k in 3:
			var foam := MeshInstance3D.new()
			foam.name = "FoamBubble"
			foam.mesh = FxBubbleShield.circle_mesh(foam_radius, 10)
			foam.material_override = foam_mat
			foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			foam.position = Vector3(
				(-0.22 + float(k) * 0.16) * paper_scale,
				base_h * 0.83 + 0.04 * sin(float(k) * 2.0 + float(i)),
				0.034 * paper_scale
			)
			foam.scale = Vector3.ONE * (0.55 + float(k % 2) * 0.30)
			panel.add_child(foam)

		panels.append({
			"node": panel,
			"base_angle": a,
			"base_rot_y": panel.rotation.y,
			"phase": float(i) * 1.7,
			"mats": mats,
		})


func _build_ribbons() -> void:
	_add_ribbon(0.12, 1.65, 0.40 * paper_scale, 0.10, paper_top, 0.2,
		FxBubbleShield.SHELL_COLOR_A, FxBubbleShield.SHELL_COLOR_C, FxBubbleShield.SHELL_WHITE,
		0.82, -1.15, 2.4, 0.10)
	_add_ribbon(0.02, 2.35, 0.22 * paper_scale, 0.15, paper_top * 0.82, 2.4,
		FxBubbleShield.SHELL_COLOR_B, FxBubbleShield.SHELL_COLOR_D, FxBubbleShield.SHELL_WHITE,
		0.62, -1.45, 3.0, 0.08)
	_add_ribbon(0.22, 3.0, 0.14 * paper_scale, 0.20, paper_top * 0.65, 4.5,
		FxBubbleShield.SHELL_COLOR_A, FxBubbleShield.SHELL_COLOR_B, FxBubbleShield.SHELL_COLOR_D,
		0.45, -0.90, 3.4, 0.07)


func _add_ribbon(offset: float, turns: float, width: float, y0: float, y1: float,
		phase: float, color_a: Color, color_b: Color, foam: Color,
		alpha: float, speed: float, flow_speed: float, wave: float) -> void:
	var group := Node3D.new()
	group.name = "MagicPaper"
	root.add_child(group)
	var mat := ShaderMaterial.new()
	mat.shader = FxBubbleShield.PaperShader
	mat.set_shader_parameter("time", 0.0)
	mat.set_shader_parameter("alpha", alpha)
	mat.set_shader_parameter("root_rot", 0.0)
	mat.set_shader_parameter("cam_az", PI * 0.5)
	mat.set_shader_parameter("speed", flow_speed)
	mat.set_shader_parameter("wave", wave)
	mat.set_shader_parameter("color_a", color_a)
	mat.set_shader_parameter("color_b", color_b)
	mat.set_shader_parameter("foam", foam)
	var mesh := MeshInstance3D.new()
	mesh.mesh = FxBubbleShield.helix_mesh(radius + offset, turns, width, y0, y1, phase, 96)
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	group.add_child(mesh)
	ribbons.append({"group": group, "mat": mat, "speed": speed, "base": alpha})


func _build_shards() -> void:
	var shard_scale := maxf(0.7, paper_scale)
	for i in 16:
		var a := (float(i) / 16.0) * TAU
		var rad := radius + 0.02 + float(i % 4) * 0.12
		var y := (0.12 + float(i % 6) * 0.18) * shard_scale
		var w := (0.14 + float(i % 3) * 0.05) * shard_scale
		var h := (0.22 + float(i % 4) * 0.05) * shard_scale
		var color: Color = FxBubbleShield.PAPER_COLORS[i % FxBubbleShield.PAPER_COLORS.size()]
		var mat := _flat_mat(color, 0.72, 1)
		var mi := MeshInstance3D.new()
		mi.name = "PaperConfetti"
		var quad := QuadMesh.new()
		quad.size = Vector2(w, h)
		mi.mesh = quad
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(cos(a) * rad, y, sin(a) * rad)
		mi.rotation = Vector3(randf() * TAU, -a + PI * 0.5, randf() * TAU)
		root.add_child(mi)
		shards.append({
			"node": mi, "mat": mat, "color": color, "base_op": 0.72,
			"angle": a, "radius": rad, "base_y": y, "phase": float(i) * 1.3,
		})


func _flat_mat(color: Color, alpha: float, priority: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.render_priority = priority
	return mat


# --- Update ------------------------------------------------------------------

func update(delta: float) -> void:
	if done:
		return
	age += delta
	time += delta
	if model != null and is_instance_valid(model):
		var anchor: Vector3 = fx.body_anchor(model)
		center = Vector3(anchor.x, 0.0, anchor.z)
		root.position = Vector3(center.x, 0.015, center.z)
	var cam_az := _camera_azimuth()
	var fade := 0.0
	var rel := 1.0
	if not releasing:
		var k := clampf(age / WINDUP, 0.0, 1.0)
		var e := _ease_out_cubic(k)
		root.rotation.y += delta * SPIN
		root.scale = Vector3.ONE * (0.22 + 0.78 * e)
		fade = 0.25 + 0.75 * e
		if k >= 1.0:
			release()
	else:
		release_t += delta
		var rt := clampf(release_t / RELEASE_SECONDS, 0.0, 1.0)
		root.rotation.y += delta * SPIN * 1.7
		root.scale = Vector3.ONE * (1.02 + rt * 0.12)
		fade = 1.0 - rt
		rel = maxf(0.0, 1.0 - rt)
		if rt >= 1.0:
			finish()
			return

	if base_ring_mat != null:
		base_ring_mat.albedo_color = Color(
			base_ring_mat.albedo_color.r, base_ring_mat.albedo_color.g,
			base_ring_mat.albedo_color.b, 0.26 * fade
		)

	for p in panels:
		var panel: Node3D = p["node"]
		var phase := float(p["phase"])
		panel.position.y = sin(time * 2.2 + phase) * 0.075
		panel.rotation.y = float(p["base_rot_y"]) + sin(time * 1.5 + phase) * 0.06
		panel.rotation.x = cos(time * 1.9 + phase) * 0.05
		panel.rotation.z = sin(time * 1.7 + phase * 0.7) * 0.04
		panel.scale = Vector3(
			(1.0 + sin(time * 1.8 + phase * 1.3) * 0.03) * rel,
			(1.0 + sin(time * 2.7 + phase) * 0.045) * rel,
			1.0
		)
		var world_a := float(p["base_angle"]) + root.rotation.y
		var front := maxf(0.0, cos(world_a - cam_az))
		var factor := 1.0 - 0.78 * front
		for m in p["mats"]:
			var mat: StandardMaterial3D = m["mat"]
			var base_color: Color = m["color"]
			mat.albedo_color = Color(
				base_color.r, base_color.g, base_color.b,
				float(m["base"]) * factor * fade
			)

	for r in ribbons:
		var group: Node3D = r["group"]
		var mat: ShaderMaterial = r["mat"]
		group.rotation.y += delta * float(r["speed"])
		mat.set_shader_parameter("time", float(mat.get_shader_parameter("time")) + delta)
		mat.set_shader_parameter("root_rot", root.rotation.y + group.rotation.y)
		mat.set_shader_parameter("cam_az", cam_az)
		mat.set_shader_parameter("alpha", float(r["base"]) * fade)

	for s in shards:
		var mi: MeshInstance3D = s["node"]
		s["angle"] = float(s["angle"]) - delta * 1.5
		var a := float(s["angle"])
		mi.position.x = cos(a) * float(s["radius"])
		mi.position.z = sin(a) * float(s["radius"])
		mi.position.y = float(s["base_y"]) + sin(time * 2.4 + float(s["phase"])) * 0.08
		mi.rotation.y = -a + PI * 0.5
		mi.rotation.x = sin(time * 1.7 + float(s["phase"])) * 0.5
		mi.rotation.z = time * 0.8 + float(s["phase"])
		var world_a := a + root.rotation.y
		var front := maxf(0.0, cos(world_a - cam_az))
		var factor := 1.0 - 0.70 * front
		var mat: StandardMaterial3D = s["mat"]
		var c: Color = s["color"]
		mat.albedo_color = Color(c.r, c.g, c.b, float(s["base_op"]) * factor * fade)


func _camera_azimuth() -> float:
	var cam: Vector3 = fx.camera_position()
	return atan2(cam.z - center.z, cam.x - center.x)


func release() -> void:
	if releasing:
		return
	releasing = true
	release_t = 0.0


func free_now() -> void:
	if done:
		return
	done = true
	if root != null and is_instance_valid(root):
		root.queue_free()
	if fx != null:
		fx._windup_done(self)


func finish() -> void:
	free_now()


# --- Formas ------------------------------------------------------------------

static func _paper_wave_points(w: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(-w * 0.5, 0.0))
	_append_quad(pts, Vector2(-w * 0.5, 0.0), Vector2(-w * 0.46, h * 0.24), Vector2(-w * 0.32, h * 0.52), 10)
	_append_quad(pts, Vector2(-w * 0.32, h * 0.52), Vector2(-w * 0.18, h * 0.80), Vector2(w * 0.02, h * 0.86), 10)
	_append_quad(pts, Vector2(w * 0.02, h * 0.86), Vector2(w * 0.22, h * 0.92), Vector2(w * 0.30, h * 0.70), 10)
	_append_quad(pts, Vector2(w * 0.30, h * 0.70), Vector2(w * 0.36, h * 0.50), Vector2(w * 0.26, h * 0.34), 10)
	_append_quad(pts, Vector2(w * 0.26, h * 0.34), Vector2(w * 0.20, h * 0.22), Vector2(w * 0.32, h * 0.12), 10)
	_append_quad(pts, Vector2(w * 0.32, h * 0.12), Vector2(w * 0.42, h * 0.04), Vector2(w * 0.5, 0.0), 10)
	return pts


static func _append_quad(out: PackedVector2Array, p0: Vector2, c: Vector2, p1: Vector2, steps: int) -> void:
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var a := p0.lerp(c, t)
		var b := c.lerp(p1, t)
		out.append(a.lerp(b, t))


static func _paper_curl_points(radius: float, width: float, start: float, end: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 14
	for i in range(steps + 1):
		var a := lerpf(start, end, float(i) / float(steps))
		pts.append(Vector2(cos(a) * radius, sin(a) * radius))
	for i in range(steps + 1):
		var a := lerpf(end, start, float(i) / float(steps))
		pts.append(Vector2(cos(a) * (radius - width), sin(a) * (radius - width)))
	return pts


static func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)
