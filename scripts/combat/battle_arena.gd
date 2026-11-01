class_name BattleArena
extends Node3D
## Placeholder battle arena: a tiled floor stretching away from the camera,
## obelisks along both sides, fog, and cool lighting. All procedural.

const FLOOR_SIZE := Vector2(90.0, 110.0)
const FLOOR_CENTER_Z := -30.0


func _ready() -> void:
	_add_environment()
	_add_floor()
	_add_pillars()


func _add_environment() -> void:
	# Teal haze like the V9 prototype: a lighter band at the horizon fading to
	# dark navy overhead, with distant objects dissolving into the fog.
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("142538")
	sky_mat.sky_horizon_color = Color("3d5d6e")
	sky_mat.sky_curve = 0.18
	sky_mat.ground_horizon_color = Color("2c4655")
	sky_mat.ground_bottom_color = Color("0a1624")
	sky_mat.ground_curve = 0.12
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("5f8796")
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.75
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color("2f4b5c")
	env.fog_density = 0.016
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.04
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# Soft cool key from above-front, then colored rim lights per team.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -20, 0)
	key.light_color = Color("c9e2ea")
	key.light_energy = 0.45
	key.shadow_enabled = true
	key.shadow_blur = 2.0
	key.directional_shadow_max_distance = 60.0
	add_child(key)
	_add_omni(Vector3(-5.0, 6.0, 9.0), Color("62d8e7"), 0.55, 22.0)   # hero cyan rim
	_add_omni(Vector3(8.0, 5.0, 7.0), Color("b6a3fe"), 0.45, 18.0)    # ally violet rim
	_add_omni(Vector3(6.0, 6.0, -24.0), Color("ff9a73"), 2.0, 22.0)  # enemy warm rim


func _add_omni(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	add_child(light)


func _add_floor() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = FLOOR_SIZE
	mesh.mesh = plane
	mesh.position = Vector3(0, 0, FLOOR_CENTER_Z)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _tile_texture()
	mat.uv1_scale = Vector3(FLOOR_SIZE.x / 4.0, FLOOR_SIZE.y / 4.0, 1.0)
	mat.roughness = 0.8
	mat.metallic_specular = 0.25
	mesh.material_override = mat
	add_child(mesh)


func _tile_texture() -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in size:
		for x in size:
			var base := Color(0.15, 0.23, 0.28) if (x < size / 2) == (y < size / 2) else Color(0.19, 0.285, 0.33)
			var n := rng.randf_range(-0.015, 0.015)
			var c := Color(base.r + n, base.g + n, base.b + n)
			if x < 2 or y < 2:
				c = c.darkened(0.45)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _add_pillars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.11, 0.17, 0.21)
	stone.roughness = 0.95
	var tip := StandardMaterial3D.new()
	tip.albedo_color = Color(0.97, 0.8, 0.47)
	tip.emission_enabled = true
	tip.emission = Color(0.97, 0.8, 0.47)
	tip.emission_energy_multiplier = 1.5
	var z := 12.0
	while z > -70.0:
		for side in [-1.0, 1.0]:
			var x: float = side * rng.randf_range(11.0, 22.0)
			var h := rng.randf_range(5.0, 9.0)
			var body := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.8, h, 1.8)
			body.mesh = box
			body.material_override = stone
			body.position = Vector3(x, h * 0.5, z + rng.randf_range(-2.0, 2.0))
			body.rotation.y = rng.randf_range(-0.3, 0.3)
			add_child(body)
			var cap := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 1.2
			cone.height = 1.8
			cap.mesh = cone
			cap.material_override = stone
			cap.position = Vector3(0, h * 0.5 + 0.9, 0)
			body.add_child(cap)
			var gem := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.18
			sphere.height = 0.36
			gem.mesh = sphere
			gem.material_override = tip
			gem.position = Vector3(0, h * 0.5 + 1.9, 0)
			body.add_child(gem)
		z -= rng.randf_range(7.0, 11.0)
