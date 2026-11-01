class_name VfxLib
extends RefCounted
## Building blocks for battle effects: procedural soft textures, additive
## billboard particles, shader quads (slash, ring, streak), hologram
## afterimages, hit-flash overlays and model outlines.

static var _tex: Dictionary = {}
static var _shaders: Dictionary = {}


# --- Textures ----------------------------------------------------------------

static func glow_tex() -> ImageTexture:
	if not _tex.has("glow"):
		var n := 64
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var r := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / (n * 0.5)
				var a := pow(clampf(1.0 - r, 0.0, 1.0), 2.2)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_tex["glow"] = ImageTexture.create_from_image(img)
	return _tex["glow"]


## Four-point star with a hot center: impact flashes.
static func star_tex() -> ImageTexture:
	if not _tex.has("star"):
		var n := 128
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var p := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5) / (n * 0.5)
				var r := p.length()
				var center := pow(clampf(1.0 - r, 0.0, 1.0), 3.0)
				var beam_h := exp(-absf(p.y) * 22.0) * clampf(1.0 - absf(p.x), 0.0, 1.0)
				var beam_v := exp(-absf(p.x) * 22.0) * clampf(1.0 - absf(p.y), 0.0, 1.0)
				var d1 := (p.x + p.y) * 0.7071
				var d2 := (p.x - p.y) * 0.7071
				var diag := (exp(-absf(d2) * 30.0) + exp(-absf(d1) * 30.0)) * 0.35 * clampf(1.0 - r, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, clampf(center * 1.4 + beam_h + beam_v + diag, 0.0, 1.0)))
		_tex["star"] = ImageTexture.create_from_image(img)
	return _tex["star"]


## Thin streak, bright in the middle: sparks aligned to their velocity.
static func spark_tex() -> ImageTexture:
	if not _tex.has("spark"):
		var w := 16
		var h := 64
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var px := absf((x + 0.5) / w - 0.5) * 2.0
				var py := (y + 0.5) / h
				var a := pow(clampf(1.0 - px, 0.0, 1.0), 2.0) * pow(sin(py * PI), 0.8)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_tex["spark"] = ImageTexture.create_from_image(img)
	return _tex["spark"]


## Soft noisy puff for smoke, dust and fire bodies.
static func smoke_tex() -> ImageTexture:
	if not _tex.has("smoke"):
		var n := 64
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.07
		noise.fractal_octaves = 3
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var r := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / (n * 0.5)
				var v := noise.get_noise_2d(x, y) * 0.5 + 0.5
				var a := clampf(1.0 - r, 0.0, 1.0)
				a = pow(a, 1.2) * clampf(v * 1.6, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_tex["smoke"] = ImageTexture.create_from_image(img)
	return _tex["smoke"]


# --- Materials ---------------------------------------------------------------

static func shader(name: String) -> Shader:
	if not _shaders.has(name):
		_shaders[name] = load("res://shaders/%s.gdshader" % name)
	return _shaders[name]


static func shader_mat(name: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(name)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


static func particle_mat(tex: Texture2D, additive := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m


static func ramp(colors: Array, offsets: Array = []) -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	if offsets.is_empty():
		var offs := PackedFloat32Array()
		for i in colors.size():
			offs.append(float(i) / maxf(colors.size() - 1, 1))
		g.offsets = offs
	else:
		g.offsets = PackedFloat32Array(offsets)
	return g


# --- Particles ---------------------------------------------------------------

## One-shot burst of textured billboards. Options (all optional):
## tex, additive, amount, life, speed (Vector2 min/max), spread, dir, gravity,
## size (Vector2 min/max), end_scale, ramp (Gradient), radius (emission sphere),
## damping, radial_accel, align_y (stretch along velocity), quad (Vector2).
static func burst(parent: Node, pos: Vector3, o: Dictionary) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = o.get("quad", Vector2.ONE)
	quad.material = particle_mat(o.get("tex", glow_tex()), o.get("additive", true))
	p.mesh = quad
	p.amount = o.get("amount", 20)
	p.lifetime = o.get("life", 0.6)
	p.one_shot = true
	p.explosiveness = o.get("explosiveness", 1.0)
	p.direction = o.get("dir", Vector3.UP)
	p.spread = o.get("spread", 180.0)
	var speed: Vector2 = o.get("speed", Vector2(2.0, 5.0))
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = o.get("gravity", Vector3.ZERO)
	p.damping_min = o.get("damping", 0.0)
	p.damping_max = o.get("damping", 0.0)
	p.radial_accel_min = o.get("radial_accel", 0.0)
	p.radial_accel_max = o.get("radial_accel", 0.0)
	var size: Vector2 = o.get("size", Vector2(0.3, 0.6))
	p.scale_amount_min = size.x
	p.scale_amount_max = size.y
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, o.get("end_scale", 0.0)))
	p.scale_amount_curve = curve
	p.color_ramp = o.get("ramp", ramp([Color.WHITE, Color(1, 1, 1, 0)]))
	p.particle_flag_align_y = o.get("align_y", false)
	var radius: float = o.get("radius", 0.0)
	if radius > 0.0:
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = radius
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free)
	return p


## Continuous trail emitter (world-space particles) to parent under a moving node.
static func trail(owner_node: Node3D, o: Dictionary) -> CPUParticles3D:
	var p := burst(owner_node, Vector3.ZERO, o)
	p.one_shot = false
	p.explosiveness = 0.0
	p.local_coords = false
	p.emitting = true
	return p


# --- Shader quads ---------------------------------------------------------------

## Quad with a shader material; `progress` is tweened 0..1 then it is freed.
static func animated_quad(parent: Node, size: Vector2, shader_name: String, params: Dictionary, duration: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var mat := shader_mat(shader_name, params)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var tw := mi.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 0.0, 1.0, duration)
	tw.tween_callback(mi.queue_free)
	return mi


## Billboard star flash that pops and fades.
static func flash_star(parent: Node, pos: Vector3, color: Color, size: float, life := 0.22) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = star_tex()
	mat.albedo_color = Color(color.r * 1.6, color.g * 1.6, color.b * 1.6, 1.0)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.position = pos
	mi.scale = Vector3.ONE * 0.4
	parent.add_child(mi)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 1.1, life).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, life).set_delay(life * 0.35)
	tw.chain().tween_callback(mi.queue_free)


# --- Model helpers ---------------------------------------------------------------

static func meshes_of(model: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for n in model.find_children("*", "MeshInstance3D", true, false):
		out.append(n as MeshInstance3D)
	return out


## Adds an inverted-hull outline to every surface of a model's meshes.
static func outline_model(model: Node, width := 0.0016, color := Color(0.02, 0.04, 0.08)) -> void:
	var line := shader_mat("outline", {"color": color, "width": width})
	for mi in meshes_of(model):
		if mi.name == "BurstRing" or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			if src is BaseMaterial3D:
				var mat := (src as BaseMaterial3D).duplicate() as BaseMaterial3D
				mat.next_pass = line
				mi.set_surface_override_material(i, mat)


## Returns the ShaderMaterial used as overlay so the caller can tween `amount`.
static func ensure_flash(model: Node) -> ShaderMaterial:
	if model.has_meta("flash_mat"):
		return model.get_meta("flash_mat")
	var mat := shader_mat("flash", {"amount": 0.0})
	for mi in meshes_of(model):
		if mi.name != "BurstRing":
			mi.material_overlay = mat
	model.set_meta("flash_mat", mat)
	return mat


## Hologram copy of a model fading out in place (afterimage).
static func ghost(parent: Node, model: Node3D, color: Color, life: float) -> Node3D:
	var copy := model.duplicate() as Node3D
	for ap in copy.find_children("*", "AnimationPlayer", true, false):
		(ap as AnimationPlayer).stop()
	copy.set_meta("anim_player", null)
	copy.visible = true
	parent.add_child(copy)
	copy.global_transform = model.global_transform
	var mat := shader_mat("ghost", {"color": color, "alpha": 0.9})
	for mi in meshes_of(copy):
		if mi.name == "BurstRing":
			mi.visible = false
			continue
		mi.material_override = mat
		mi.material_overlay = null
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tw := copy.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("alpha", v), 0.9, 0.0, life)
	tw.tween_callback(copy.queue_free)
	return copy
