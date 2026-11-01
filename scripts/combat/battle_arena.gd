class_name BattleArena
extends Node3D
## Battle arena: a rectangular tiled platform floating in a teal void, framed by
## a glowing rim, grid lines, aligned ruin pillars, a gate wall behind the
## enemies, distant silhouettes, floating debris, light shafts and drifting
## dust. All procedural placeholders.

const HALF_W := 22.0
const FRONT_Z := 14.0
const BACK_Z := -70.0
const TEAL := Color("62d8e7")
const CORAL := Color("ff624f")
const GOLD := Color("f7cb78")

var _rng := RandomNumberGenerator.new()
var _stone: StandardMaterial3D
var _dark: StandardMaterial3D


func _ready() -> void:
	_rng.seed = 11
	_stone = _mat(Color(0.11, 0.17, 0.21), 0.95)
	_dark = _mat(Color(0.06, 0.1, 0.14), 0.95)
	_add_environment()
	_add_floor()
	_add_rim_and_grid()
	_add_pillar_rows()
	_add_gate_wall()
	_add_skyline()
	_add_debris()
	_add_light_shafts()
	_add_dust()


# --- Environment and lights --------------------------------------------------

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
	env.glow_intensity = 0.4
	env.glow_bloom = 0.02
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
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
	_add_omni(Vector3(6.0, 6.0, -24.0), Color("ff9a73"), 2.0, 22.0)   # enemy warm rim
	_add_omni(Vector3(-14.0, 4.0, -62.0), CORAL, 2.5, 20.0)           # gate braziers
	_add_omni(Vector3(14.0, 4.0, -62.0), CORAL, 2.5, 20.0)


func _add_omni(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	add_child(light)


# --- Floor, rim and grid -----------------------------------------------------

func _add_floor() -> void:
	var depth := FRONT_Z - BACK_Z
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_W * 2.0, depth)
	mesh.mesh = plane
	mesh.position = Vector3(0, 0, (FRONT_Z + BACK_Z) * 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _tile_texture()
	mat.uv1_scale = Vector3(HALF_W * 2.0 / 4.0, depth / 4.0, 1.0)
	mat.roughness = 0.8
	mat.metallic_specular = 0.25
	mesh.material_override = mat
	add_child(mesh)
	# Thick underside so the platform reads as a slab floating in the void.
	var slab := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(HALF_W * 2.0, 3.0, depth)
	slab.mesh = box
	slab.material_override = _dark
	slab.position = Vector3(0, -1.55, (FRONT_Z + BACK_Z) * 0.5)
	add_child(slab)


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


func _add_rim_and_grid() -> void:
	var depth := FRONT_Z - BACK_Z
	var mid_z := (FRONT_Z + BACK_Z) * 0.5
	var glow := _emissive(TEAL, 1.4)
	# Side rims and back rim: low raised border with a glowing top strip.
	for side in [-1.0, 1.0]:
		_box(Vector3(1.0, 0.9, depth), Vector3(side * (HALF_W + 0.5), 0.45, mid_z), _stone)
		_box(Vector3(0.18, 0.06, depth), Vector3(side * (HALF_W + 0.1), 0.93, mid_z), glow)
	_box(Vector3(HALF_W * 2.0 + 2.0, 0.9, 1.0), Vector3(0, 0.45, BACK_Z - 0.5), _stone)
	_box(Vector3(HALF_W * 2.0, 0.06, 0.18), Vector3(0, 0.93, BACK_Z - 0.1), glow)
	# Faint grid lines on the floor, every 8 units.
	var line := _emissive(TEAL, 0.45)
	var z := BACK_Z + 8.0
	while z < FRONT_Z:
		_box(Vector3(HALF_W * 2.0, 0.02, 0.07), Vector3(0, 0.02, z), line)
		z += 8.0
	var x := -HALF_W + 8.0
	while x < HALF_W:
		_box(Vector3(0.07, 0.02, depth), Vector3(x, 0.02, mid_z), line)
		x += 8.0


# --- Ruins -------------------------------------------------------------------

## Pillars in straight rows along both sides, aligned to the grid; some broken.
func _add_pillar_rows() -> void:
	var z := FRONT_Z - 4.0
	var i := 0
	while z > BACK_Z + 6.0:
		for side in [-1.0, 1.0]:
			var h := 6.0 + float((i * 3) % 4) * 1.5
			var broken := (i + (1 if side > 0 else 0)) % 4 == 0
			_pillar(Vector3(side * (HALF_W - 3.0), 0, z), h * (0.55 if broken else 1.0), not broken)
		z -= 8.0
		i += 1


func _pillar(pos: Vector3, h: float, capped: bool) -> void:
	var body := _box(Vector3(1.8, h, 1.8), pos + Vector3(0, h * 0.5, 0), _stone)
	_box(Vector3(2.2, 0.4, 2.2), pos + Vector3(0, 0.2, 0), _dark)  # base
	if capped:
		var cap := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.2
		cone.height = 1.8
		cap.mesh = cone
		cap.material_override = _stone
		cap.position = Vector3(0, h * 0.5 + 0.9, 0)
		body.add_child(cap)
		var gem := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.2
		sphere.height = 0.4
		gem.mesh = sphere
		gem.material_override = _emissive(GOLD, 2.0)
		gem.position = Vector3(0, h * 0.5 + 1.95, 0)
		body.add_child(gem)
	else:
		for k in 3:  # rubble at the foot of a broken pillar
			_box(Vector3(0.7, 0.5, 0.6), pos + Vector3(_rng.randf_range(-1.8, 1.8), 0.25, _rng.randf_range(-1.5, 1.5)), _stone).rotation.y = _rng.randf() * TAU


## A gate behind the enemies: two pylons, a lintel, glowing slits and braziers.
func _add_gate_wall() -> void:
	var z := BACK_Z - 3.0
	_box(Vector3(HALF_W * 2.0 + 14.0, 18.0, 3.0), Vector3(0, 9.0, z), _stone)
	_box(Vector3(11.0, 13.0, 3.4), Vector3(0, 6.5, z + 0.4), _dark)  # recessed doorway
	for side in [-1.0, 1.0]:
		_box(Vector3(4.0, 22.0, 4.0), Vector3(side * 8.0, 11.0, z + 1.5), _stone)
		_box(Vector3(0.4, 6.0, 0.3), Vector3(side * 14.0, 9.0, z + 1.7), _emissive(CORAL, 1.8))
		_box(Vector3(1.4, 1.0, 1.4), Vector3(side * 14.0, 0.5, BACK_Z + 4.0), _stone)  # brazier base
		_box(Vector3(0.7, 0.9, 0.7), Vector3(side * 14.0, 1.4, BACK_Z + 4.0), _emissive(CORAL, 2.5))
	_box(Vector3(17.0, 2.0, 3.6), Vector3(0, 14.2, z + 0.8), _stone)  # lintel
	_box(Vector3(9.0, 0.3, 0.3), Vector3(0, 13.1, z + 2.7), _emissive(TEAL, 1.6))


## Tall silhouettes beyond the platform that dissolve into the fog.
func _add_skyline() -> void:
	for i in 22:
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Vector3(side * _rng.randf_range(32.0, 70.0), 0, _rng.randf_range(BACK_Z - 20.0, FRONT_Z + 10.0))
		var h := _rng.randf_range(14.0, 42.0)
		_box(Vector3(_rng.randf_range(3.0, 7.0), h, _rng.randf_range(3.0, 7.0)), pos + Vector3(0, h * 0.5 - 6.0, 0), _dark)


func _add_debris() -> void:
	for i in 26:
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Vector3(side * _rng.randf_range(HALF_W + 3.0, HALF_W + 18.0), _rng.randf_range(1.0, 12.0), _rng.randf_range(BACK_Z, FRONT_Z))
		var s := _rng.randf_range(0.5, 1.8)
		var rock := _box(Vector3(s, s * 0.7, s * 1.2), pos, _stone)
		rock.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)


## Faint additive shafts of light falling from the sky.
func _add_light_shafts() -> void:
	var shaft_mat := StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.55, 0.85, 0.9, 0.012)
	shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for spot in [Vector2(-16, -26), Vector2(17, -34), Vector2(-12, -46), Vector2(13, -56)]:
		var cone := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.5
		mesh.bottom_radius = 2.4
		mesh.height = 34.0
		mesh.radial_segments = 16
		cone.mesh = mesh
		cone.material_override = shaft_mat
		cone.position = Vector3(spot.x, 17.0, spot.y)
		cone.rotation_degrees = Vector3(0, 0, 8.0)
		add_child(cone)


## Slow drifting motes; the only moving thing in the arena.
func _add_dust() -> void:
	var p := CPUParticles3D.new()
	p.amount = 160
	p.lifetime = 12.0
	p.preprocess = 12.0
	p.position = Vector3(0, 5.0, -28.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(HALF_W, 5.0, 45.0)
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.gravity = Vector3.ZERO
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	mesh.radial_segments = 4
	mesh.rings = 2
	mesh.material = _emissive(Color(0.7, 0.95, 1.0), 1.0)
	p.mesh = mesh
	add_child(p)


# --- Helpers -----------------------------------------------------------------

func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _box(size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = material
	mi.position = pos
	add_child(mi)
	return mi
