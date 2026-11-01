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
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.5, 0.58)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.1, 0.14)
	env.fog_density = 0.018
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 25, 0)
	sun.light_color = Color(0.75, 0.9, 1.0)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


func _add_floor() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = FLOOR_SIZE
	mesh.mesh = plane
	mesh.position = Vector3(0, 0, FLOOR_CENTER_Z)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _tile_texture()
	mat.uv1_scale = Vector3(FLOOR_SIZE.x / 4.0, FLOOR_SIZE.y / 4.0, 1.0)
	mat.roughness = 0.9
	mesh.material_override = mat
	add_child(mesh)


func _tile_texture() -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in size:
		for x in size:
			var base := Color(0.13, 0.21, 0.26) if (x < size / 2) == (y < size / 2) else Color(0.16, 0.26, 0.31)
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
	stone.albedo_color = Color(0.13, 0.19, 0.24)
	stone.roughness = 0.95
	var tip := StandardMaterial3D.new()
	tip.albedo_color = Color(0.9, 0.75, 0.4)
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
