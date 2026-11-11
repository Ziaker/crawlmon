class_name BubbleShieldVisual
extends RefCounted
## Uma bolha de Bubble Shield, escalada ao envelope do personagem. Porte fiel do
## ShieldA do protótipo aprovado: casco liso + concha facetada, refração, ondas,
## espuma, gotas internas, splash no lado da câmera, ruptura e expiração.

const SPAWN_SECONDS := 0.95
const BREAK_SECONDS := 0.62
const EXPIRE_SECONDS := 1.35
const FADE_SECONDS := 0.35
const FORM_FADE_SECONDS := 0.25
const WIDTH_SCALE := 1.15  ## D-1108: 15% a mais só no diâmetro horizontal (X/Z); a altura não muda.

var fx
var target: Combatant
var model: Node3D
var root: Node3D

var center: Vector3
var base_radius: float
var radius: float
var _base_scale := 1.0
var _scale_ratio := 1.0

var shell: MeshInstance3D
var facets: MeshInstance3D
var shell_mat: ShaderMaterial
var facet_mat: ShaderMaterial
var wave_root: Node3D
var wave_mats: Array[ShaderMaterial] = []
var drops: Array = []
var mote: CPUParticles3D
var release_stream: CPUParticles3D

var age := 0.0
var spawn_t := 0.0
var spawning := true
var breaking := false
var expiring := false
var fading := false
var done := false
var form_fade := 1.0
var flash := 0.0
var hit_strength := 0.0
var hit_age := 0.0
var hit_pulse := 0.0
var break_t := 0.0
var expire_t := 0.0
var fade_t := 0.0
var break_burst_done := false
var expire_burst_done := false
var shell_opacity := 1.0
var facet_opacity := 0.42


func _init(p_fx: FxBubbleShield, p_target: Combatant, p_model: Node3D) -> void:
	fx = p_fx
	target = p_target
	model = p_model
	var env := FxBubbleShield.body_envelope(model)
	center = env["center"]
	base_radius = float(env["radius"])
	radius = base_radius
	_base_scale = maxf(model.global_transform.basis.get_scale().y, 0.001)
	root = Node3D.new()
	root.name = "BubbleShield"
	fx.root.add_child(root)
	root.global_position = center
	_build_shell()
	_build_waves()
	_build_drops()
	_build_motes()
	_build_release_stream()
	_update_transform(0.0)


func _build_shell() -> void:
	var shell_r := base_radius * 1.02
	var sphere := SphereMesh.new()
	sphere.radius = shell_r
	sphere.height = shell_r * 2.0
	sphere.radial_segments = 72
	sphere.rings = 54
	shell = MeshInstance3D.new()
	shell.name = "SoapShell"
	shell.mesh = sphere
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell_mat = ShaderMaterial.new()
	shell_mat.shader = FxBubbleShield.ShellShader
	shell_mat.render_priority = 0
	shell_mat.set_shader_parameter("time", 0.0)
	shell_mat.set_shader_parameter("opacity", 1.0)
	shell_mat.set_shader_parameter("hit_flash", 0.0)
	shell_mat.set_shader_parameter("hit_dir", Vector3(0, 0, 1))
	shell_mat.set_shader_parameter("hit_age", 0.0)
	shell_mat.set_shader_parameter("hit_strength", 0.0)
	shell_mat.set_shader_parameter("wave_amp", 0.016)
	shell_mat.set_shader_parameter("depletion", 0.0)
	shell_mat.set_shader_parameter("base_alpha", 0.06)
	shell_mat.set_shader_parameter("form", -0.03)
	shell_mat.set_shader_parameter("form_active", 1.0)
	shell_mat.set_shader_parameter("radius", shell_r)
	shell_mat.set_shader_parameter("color_a", FxBubbleShield.SHELL_COLOR_A)
	shell_mat.set_shader_parameter("color_b", FxBubbleShield.SHELL_COLOR_B)
	shell_mat.set_shader_parameter("color_c", FxBubbleShield.SHELL_COLOR_C)
	shell_mat.set_shader_parameter("color_d", FxBubbleShield.SHELL_COLOR_D)
	shell_mat.set_shader_parameter("refract_amount", 0.65)
	shell.material_override = shell_mat
	root.add_child(shell)

	var facet_r := base_radius * 1.035
	facets = MeshInstance3D.new()
	facets.name = "FacetShell"
	facets.mesh = FxBubbleShield.ico_sphere_mesh(facet_r, 3)
	facets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	facet_mat = ShaderMaterial.new()
	facet_mat.shader = FxBubbleShield.FacetShader
	facet_mat.render_priority = 1
	facet_mat.set_shader_parameter("time", 0.0)
	facet_mat.set_shader_parameter("opacity", 0.42)
	facet_mat.set_shader_parameter("hit_flash", 0.0)
	facet_mat.set_shader_parameter("freeze", 0.35)
	facet_mat.set_shader_parameter("hit_dir", Vector3(0, 0, 1))
	facet_mat.set_shader_parameter("hit_age", 0.0)
	facet_mat.set_shader_parameter("hit_strength", 0.0)
	facet_mat.set_shader_parameter("form", -0.03)
	facet_mat.set_shader_parameter("form_active", 1.0)
	facet_mat.set_shader_parameter("radius", facet_r)
	facet_mat.set_shader_parameter("tint", FxBubbleShield.SHELL_COLOR_C)
	facet_mat.set_shader_parameter("color_a", FxBubbleShield.SHELL_COLOR_A)
	facet_mat.set_shader_parameter("color_b", FxBubbleShield.SHELL_COLOR_B)
	facet_mat.set_shader_parameter("color_c", FxBubbleShield.SHELL_COLOR_C)
	facet_mat.set_shader_parameter("color_d", FxBubbleShield.SHELL_COLOR_D)
	facet_mat.set_shader_parameter("refract_amount", 0.55)
	facets.material_override = facet_mat
	root.add_child(facets)


func _build_waves() -> void:
	wave_root = Node3D.new()
	wave_root.name = "FormationWaves"
	wave_root.position.y = -center.y
	root.add_child(wave_root)
	var wave_top := center.y + base_radius * 0.98
	for i in 2:
		var mat := ShaderMaterial.new()
		mat.shader = FxBubbleShield.WaterShader
		mat.set_shader_parameter("time", 0.0)
		mat.set_shader_parameter("alpha", 0.0)
		mat.set_shader_parameter("reveal", 1.0)
		mat.set_shader_parameter("root_rot", 0.0)
		mat.set_shader_parameter("cam_az", 0.0)
		mat.set_shader_parameter("color_a", FxBubbleShield.SHELL_COLOR_A)
		mat.set_shader_parameter("color_b", FxBubbleShield.SHELL_COLOR_D)
		mat.set_shader_parameter("speed", 2.6 + float(i) * 0.4)
		mat.set_shader_parameter("amp", 0.035)
		var mesh := MeshInstance3D.new()
		mesh.mesh = FxBubbleShield.helix_mesh(
			base_radius * (0.92 + float(i) * 0.06),
			2.0 + float(i) * 0.35,
			0.18 - float(i) * 0.06,
			0.04,
			wave_top,
			float(i) * PI,
			96
		)
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wave_root.add_child(mesh)
		wave_mats.append(mat)


func _build_drops() -> void:
	for i in 9:
		var mi := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * (base_radius * 0.075)
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.albedo_texture = FxBubbleShield.drop_texture()
		mat.albedo_color = FxBubbleShield.SHELL_COLOR_D
		mat.albedo_color.a = 0.0
		mat.render_priority = 2
		mi.material_override = mat
		root.add_child(mi)
		drops.append({
			"node": mi, "mat": mat,
			"angle": randf() * TAU,
			"y": base_radius * (0.75 - float(i) * 0.16),
			"speed": 0.10 + randf() * 0.10,
			"sway": 0.25 + randf() * 0.35,
			"phase": randf() * TAU,
		})


func _build_motes() -> void:
	mote = CPUParticles3D.new()
	mote.name = "BubbleMotes"
	mote.amount = 24
	mote.lifetime = 1.4
	mote.one_shot = false
	mote.explosiveness = 0.0
	mote.local_coords = true
	mote.preprocess = 0.7
	mote.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mote.emission_sphere_radius = base_radius * 0.82
	mote.direction = Vector3.UP
	mote.spread = 180.0
	mote.initial_velocity_min = 0.05
	mote.initial_velocity_max = 0.3
	mote.gravity = Vector3(0, 0.25, 0)
	mote.scale_amount_min = 0.05
	mote.scale_amount_max = 0.12
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.65))
	curve.add_point(Vector2(0.5, 1.35))
	curve.add_point(Vector2(1.0, 0.86))
	mote.scale_amount_curve = curve
	var ca := Color(0.18, 0.43, 0.78)
	ca.a = 0.0
	var cb := Color(0.56, 0.91, 1.0)
	cb.a = 1.0
	var ce := cb
	ce.a = 0.0
	mote.color_ramp = VfxLib.ramp([ca, cb, ce], [0.0, 0.08, 1.0])
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = VfxLib.particle_mat(FxBubbleShield.bubble_texture(), true)
	mote.mesh = quad
	mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mote.emitting = true
	root.add_child(mote)


func _build_release_stream() -> void:
	release_stream = CPUParticles3D.new()
	release_stream.name = "ReleaseStream"
	release_stream.position = Vector3(0, -center.y + 0.05, 0)
	release_stream.amount = 18
	release_stream.lifetime = 0.85
	release_stream.one_shot = false
	release_stream.explosiveness = 0.0
	release_stream.local_coords = true
	release_stream.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	release_stream.emission_sphere_radius = 0.28
	release_stream.direction = Vector3.UP
	release_stream.spread = 42.0
	release_stream.initial_velocity_min = 0.7
	release_stream.initial_velocity_max = 1.7
	release_stream.gravity = Vector3(0, -0.6, 0)
	release_stream.scale_amount_min = 0.04
	release_stream.scale_amount_max = 0.12
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.65))
	curve.add_point(Vector2(0.5, 1.35))
	curve.add_point(Vector2(1.0, 0.86))
	release_stream.scale_amount_curve = curve
	var ca := Color(0.8, 1.0, 1.0)
	ca.a = 0.0
	var cb := Color(0.4, 0.9, 1.0)
	cb.a = 1.0
	var ce := cb
	ce.a = 0.0
	release_stream.color_ramp = VfxLib.ramp([ca, cb, ce], [0.0, 0.08, 1.0])
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = VfxLib.particle_mat(FxBubbleShield.bubble_texture(), true)
	release_stream.mesh = quad
	release_stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	release_stream.emitting = true
	root.add_child(release_stream)


# --- Update ------------------------------------------------------------------

func update(delta: float) -> void:
	if done:
		return
	age += delta
	_update_transform(delta)

	shell_mat.set_shader_parameter("time", float(shell_mat.get_shader_parameter("time")) + delta)
	facet_mat.set_shader_parameter("time", float(facet_mat.get_shader_parameter("time")) + delta)
	hit_age += delta
	hit_strength = maxf(0.0, hit_strength - delta * 1.8)
	flash = maxf(0.0, flash - delta * 2.8)
	shell_mat.set_shader_parameter("hit_age", hit_age)
	shell_mat.set_shader_parameter("hit_strength", hit_strength)
	shell_mat.set_shader_parameter("hit_flash", flash)
	facet_mat.set_shader_parameter("hit_age", hit_age)
	facet_mat.set_shader_parameter("hit_strength", hit_strength)
	facet_mat.set_shader_parameter("hit_flash", flash)

	shell.rotation.y += delta * 0.05
	facets.rotation.y -= delta * 0.035
	facets.rotation.x += delta * 0.008
	var pulse := 1.0 + sin(age * 1.6) * 0.008
	facets.scale = Vector3.ONE * pulse

	_update_drops(delta)
	_update_spawn(delta)

	hit_pulse = maxf(0.0, hit_pulse - delta * 4.0)
	var effect_scale := 1.0
	if not spawning and not expiring and not breaking and not fading:
		effect_scale = 1.0 + sin(hit_pulse * PI) * 0.055

	if breaking:
		break_t += delta
		var t := clampf(break_t / BREAK_SECONDS, 0.0, 1.0)
		var swell := _ease_out_cubic(clampf(t / 0.28, 0.0, 1.0))
		root.rotation.y += delta * 3.0
		effect_scale = 1.0 + swell * 0.40
		shell_opacity = 1.0 - _smoothstep(0.22, 0.40, t)
		facet_opacity = 0.42 * (1.0 - _smoothstep(0.12, 0.28, t))
		if not break_burst_done and t >= 0.06:
			break_burst_done = true
			_break_burst()
		if t >= 1.0:
			finish()
			return
	elif expiring:
		expire_t += delta
		var t := clampf(expire_t / EXPIRE_SECONDS, 0.0, 1.0)
		root.rotation.y += delta * (0.35 + t * 1.8)
		var pre := _ease_out_cubic(clampf(t / 0.36, 0.0, 1.0))
		var post := _ease_out_cubic(clampf((t - 0.36) / 0.45, 0.0, 1.0))
		effect_scale = 1.0 + pre * 0.30 + post * 0.35
		shell_opacity = 1.0 - _smoothstep(0.36, 0.52, t)
		facet_opacity = 0.42 * (1.0 - _smoothstep(0.30, 0.45, t))
		if not expire_burst_done and t >= 0.18:
			expire_burst_done = true
			_expire_burst()
		if t >= 1.0:
			finish()
			return
	elif fading:
		fade_t += delta
		var t := clampf(fade_t / FADE_SECONDS, 0.0, 1.0)
		shell_opacity = 1.0 - t
		facet_opacity = 0.42 * (1.0 - t)
		if t >= 1.0:
			finish()
			return

	shell_mat.set_shader_parameter("opacity", shell_opacity)
	facet_mat.set_shader_parameter("opacity", facet_opacity)
	var s := _scale_ratio * effect_scale
	root.scale = Vector3(s * WIDTH_SCALE, s, s * WIDTH_SCALE)


func _update_transform(delta: float) -> void:
	if is_instance_valid(model):
		var sc := model.global_transform.basis.get_scale().y
		_scale_ratio = clampf(sc / _base_scale, 0.5, 2.5)
		radius = base_radius * _scale_ratio
		if not breaking:
			var anchor: Vector3 = fx.body_anchor(model)
			center = Vector3(anchor.x, maxf(anchor.y, radius), anchor.z)
	root.global_position = center
	root.scale = Vector3(_scale_ratio * WIDTH_SCALE, _scale_ratio, _scale_ratio * WIDTH_SCALE)
	if release_stream != null and release_stream.position.y != -center.y + 0.05:
		release_stream.position.y = -center.y + 0.05
	if wave_root != null and wave_root.position.y != -center.y:
		wave_root.position.y = -center.y


func _update_spawn(delta: float) -> void:
	if spawning:
		spawn_t += delta
		var t := clampf(spawn_t / SPAWN_SECONDS, 0.0, 1.0)
		var form := -0.03 + 1.03 * _smoothstep(0.0, 1.0, t)
		shell_mat.set_shader_parameter("form", form)
		shell_mat.set_shader_parameter("form_active", 1.0)
		facet_mat.set_shader_parameter("form", form)
		facet_mat.set_shader_parameter("form_active", 1.0)
		wave_root.rotation.y += delta * 2.6
		wave_root.scale.y = maxf(0.02, form)
		var cam_az := _camera_azimuth()
		var wave_fade := 1.0 - _smoothstep(0.55, 1.0, t)
		for i in wave_mats.size():
			var mat := wave_mats[i]
			mat.set_shader_parameter("time", float(mat.get_shader_parameter("time")) + delta)
			mat.set_shader_parameter("root_rot", wave_root.rotation.y)
			mat.set_shader_parameter("cam_az", cam_az)
			mat.set_shader_parameter("alpha", (0.8 if i == 0 else 0.55) * wave_fade)
		if release_stream != null:
			release_stream.emitting = spawn_t < 0.72
		if t >= 1.0:
			spawning = false
			wave_root.visible = false
			if release_stream != null:
				release_stream.emitting = false
	elif form_fade > 0.0:
		form_fade = maxf(0.0, form_fade - delta / FORM_FADE_SECONDS)
		shell_mat.set_shader_parameter("form_active", form_fade)
		facet_mat.set_shader_parameter("form_active", form_fade)


func _update_drops(delta: float) -> void:
	var visible := 0.0
	if not (breaking or fading or (expiring and expire_burst_done)):
		visible = _smoothstep(0.60, 1.0, spawn_t) if spawning else 1.0
	for d in drops:
		d["y"] = float(d["y"]) - delta * float(d["speed"])
		d["angle"] = float(d["angle"]) + delta * float(d["sway"])
		if float(d["y"]) < -base_radius * 0.85:
			d["y"] = base_radius * 0.75
			d["angle"] = randf() * TAU
		var y := float(d["y"])
		var rr := sqrt(maxf(0.0, base_radius * base_radius - y * y)) * 0.88
		var node: MeshInstance3D = d["node"]
		node.position = Vector3(cos(float(d["angle"])) * rr, y, sin(float(d["angle"])) * rr)
		var mat: StandardMaterial3D = d["mat"]
		mat.albedo_color.a = visible * (0.30 + 0.16 * sin(age * 3.0 + float(d["phase"])))


func _camera_azimuth() -> float:
	var cam: Vector3 = fx.camera_position()
	return atan2(cam.z - center.z, cam.x - center.x)


# --- Impacto / fim -----------------------------------------------------------

func hit() -> void:
	if done:
		return
	var hit_radius := radius * WIDTH_SCALE
	var point: Vector3 = fx.camera_hit_point(center, hit_radius)
	var local_dir: Vector3 = root.to_local(point).normalized()
	flash = 0.25
	hit_pulse = 1.0
	hit_age = 0.0
	hit_strength = 0.85
	shell_mat.set_shader_parameter("hit_flash", flash)
	shell_mat.set_shader_parameter("hit_dir", local_dir)
	shell_mat.set_shader_parameter("hit_age", hit_age)
	shell_mat.set_shader_parameter("hit_strength", hit_strength)
	facet_mat.set_shader_parameter("hit_flash", flash)
	facet_mat.set_shader_parameter("hit_dir", local_dir)
	facet_mat.set_shader_parameter("hit_age", hit_age)
	facet_mat.set_shader_parameter("hit_strength", hit_strength)

	var world_dir: Vector3 = (point - center).normalized()
	fx.flash(point, Color("2f8fd0"), 0.16, 0.12)
	fx.impact_splash(center, hit_radius, point, world_dir, 14)
	fx.facet_shards(center, hit_radius, "hit", 6, point)
	var bubble_tex := FxBubbleShield.bubble_texture()
	var drop_tex := FxBubbleShield.drop_texture()
	var spark_tex := FxBubbleShield.spark_texture()
	fx.burst(bubble_tex, point, 44, Color(0.45, 0.85, 1.0), Color(0.15, 0.50, 1.0),
		0.8, 2.8, 0.05, 0.16, 0.3, 0.9, 0.08, 0.6)
	fx.burst(drop_tex, point, 28, Color(0.50, 0.88, 1.0), Color(0.15, 0.55, 1.0),
		1.0, 3.0, 0.04, 0.12, 0.25, 0.7, 0.05, 0.35)
	fx.burst(spark_tex, point, 18, Color(0.55, 0.90, 1.0), Color(0.20, 0.60, 1.0),
		0.9, 3.0, 0.04, 0.10, 0.25, 0.7, 0.05, 0.4)


func break_shield() -> void:
	if done or breaking or expiring or fading:
		return
	breaking = true
	break_t = 0.0
	break_burst_done = false
	shell_opacity = 1.0
	facet_opacity = 0.42
	if mote != null:
		mote.emitting = false
	if release_stream != null:
		release_stream.emitting = false


func expire() -> void:
	if done or expiring or breaking or fading:
		return
	expiring = true
	expire_t = 0.0
	expire_burst_done = false
	if mote != null:
		mote.emitting = false
	if release_stream != null:
		release_stream.emitting = false


func fade_out() -> void:
	if done or fading:
		return
	fading = true
	fade_t = 0.0
	if mote != null:
		mote.emitting = false
	if release_stream != null:
		release_stream.emitting = false


func free_now() -> void:
	if done:
		return
	done = true
	if root != null and is_instance_valid(root):
		root.queue_free()
	if fx != null:
		fx._visual_done(self)


func finish() -> void:
	free_now()


func _break_burst() -> void:
	fx.flash(center + Vector3.UP * (radius * 0.10), Color("6fc8ff"), 0.65, 0.16)
	fx.water_debris(center, radius, 70)
	fx.facet_shards(center, radius, "break", 38)
	var shard_tex := FxBubbleShield.shard_texture()
	var drop_tex := FxBubbleShield.drop_texture()
	var spark_tex := FxBubbleShield.spark_texture()
	fx.burst(shard_tex, center, 70, Color(0.7, 0.95, 1.0), Color(0.35, 0.70, 1.0),
		2.0, 6.0, 0.06, 0.18, 0.4, 1.1, radius * 0.55, 0.6, true)
	fx.burst(drop_tex, center, 55, Color(0.65, 0.95, 1.0), Color(0.25, 0.65, 1.0),
		1.5, 4.5, 0.05, 0.16, 0.4, 1.2, radius * 0.55, 0.8, true)
	fx.burst(spark_tex, center, 32, Color(0.75, 0.98, 1.0), Color(0.35, 0.75, 1.0),
		1.0, 4.0, 0.05, 0.12, 0.25, 0.8, radius * 0.5, 0.4, true)


func _expire_burst() -> void:
	fx.flash(center + Vector3.UP * (radius * 0.06), Color("4fa8ff"), 0.42, 0.24)
	fx.water_debris(center, radius, 92)
	fx.facet_shards(center, radius, "expire", 46)
	var drop_tex := FxBubbleShield.drop_texture()
	var bubble_tex := FxBubbleShield.bubble_texture()
	var spark_tex := FxBubbleShield.spark_texture()
	fx.burst(drop_tex, center, 90, Color(0.6, 0.92, 1.0), Color(0.22, 0.62, 1.0),
		1.0, 3.6, 0.05, 0.16, 0.5, 1.5, radius * 0.65, 0.9, true)
	fx.burst(bubble_tex, center, 60, Color(0.65, 0.95, 1.0), Color(0.28, 0.68, 1.0),
		0.8, 2.8, 0.05, 0.17, 0.5, 1.4, radius * 0.7, 0.7, true)
	fx.burst(spark_tex, center, 40, Color(0.75, 0.98, 1.0), Color(0.35, 0.75, 1.0),
		0.8, 3.2, 0.05, 0.13, 0.35, 1.0, radius * 0.6, 0.45, true)


# --- Matemática --------------------------------------------------------------

static func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / maxf(edge1 - edge0, 0.00001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)
