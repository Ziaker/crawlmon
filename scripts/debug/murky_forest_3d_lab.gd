extends "res://scripts/debug/third_person_3d_lab.gd"
## Lab 3D da Murky Forest (D-1027/D-1028).
##
## Herda o lab de terceira pessoa (câmera, aliados, Slime, navmesh, porta) e
## troca o cenário de pedra por uma reconstrução low-poly 3D do bioma
## `murky_forest` do PMD, com toon em tudo no overworld e um mini-mapa
## top-down renderizado num SubViewport.
##
## Escala do teste (D-1028): 1 unidade = 1 m; célula 3 m; corredor 6 m;
## parede 4,2 m; copa 5,5 m. Não é a escala final do jogo.

const FOREST_VIGNETTE := preload("res://shaders/vignette.gdshader")
const FOREST_WALL_HEIGHT := 4.2
const MINIMAP_SIZE := 256
const MINIMAP_DISPLAY_SIZE := 112
const MINIMAP_WORLD_SIZE := 20.0

var _rng := RandomNumberGenerator.new()
var _minimap_viewport: SubViewport
var _minimap_camera: Camera3D
var _minimap_rect: TextureRect
var _marker_root: Control
var _marker_texture: ImageTexture
var _minimap_markers: Array[Dictionary] = []
var _hud_badges: Array[Dictionary] = []


func _ready() -> void:
	super()
	_rng.seed = 20261109
	_apply_toon(self)
	_set_actor_layers()
	if _camera != null:
		# A camada 5 é só do mapa do mini-mapa; a câmera principal não a vê.
		_camera.cull_mask = 0xFFFFFFFF & ~(1 << 4)
	_build_minimap()
	_build_hud_badges()


func _process(delta: float) -> void:
	super(delta)
	_update_hud_badges()


func _physics_process(delta: float) -> void:
	super(delta)
	_update_minimap()


# --- Environment -------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.012, 0.030)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.32, 0.50)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.055, 0.035, 0.085)
	env.fog_density = 0.018
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Lua verde-pálida: fria, mas não azul, para manter a paleta do bioma.
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	moon.light_color = Color(0.66, 0.86, 0.72)
	moon.light_energy = 0.60
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40.0
	add_child(moon)

	# Preenchimento quente no centro do L.
	var fill := OmniLight3D.new()
	fill.position = Vector3(8.0, 3.4, -10.0)
	fill.light_color = Color(1.0, 0.58, 0.30)
	fill.light_energy = 1.1
	fill.omni_range = 17.0
	add_child(fill)


# --- Forest room -------------------------------------------------------------

func _build_room() -> void:
	var floor_mat := _toon_mat(Color(0.19, 0.11, 0.22))
	var wall_mat := _toon_mat(Color(0.075, 0.145, 0.135))
	var trunk_mat := _toon_mat(Color(0.10, 0.065, 0.055))

	# Piso em L (mesma colisão do lab: a navmesh e a IA continuam valendo).
	_box(Vector3(8.0, 0.4, 20.0), Vector3(0.0, -0.2, -4.0), floor_mat)
	_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -10.0), floor_mat)
	# Paredes externas do L, agora com 4,2 m.
	_box(Vector3(8.5, FOREST_WALL_HEIGHT, 0.5), Vector3(0.0, FOREST_WALL_HEIGHT * 0.5, 6.25), wall_mat)
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 20.0), Vector3(-4.25, FOREST_WALL_HEIGHT * 0.5, -4.0), wall_mat)
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 12.0), Vector3(4.25, FOREST_WALL_HEIGHT * 0.5, 0.0), wall_mat)
	_box(Vector3(22.5, FOREST_WALL_HEIGHT, 0.5), Vector3(7.0, FOREST_WALL_HEIGHT * 0.5, -14.25), wall_mat)
	_box(Vector3(14.5, FOREST_WALL_HEIGHT, 0.5), Vector3(11.0, FOREST_WALL_HEIGHT * 0.5, -5.75), wall_mat)
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, -10.0), wall_mat)
	# Pilares: colisão igual, visual de tronco.
	for p in [
		Vector2(-3.0, -2.0), Vector2(3.0, -7.0),
		Vector2(7.0, -13.0), Vector2(13.0, -7.0),
	]:
		_box(Vector3(0.55, FOREST_WALL_HEIGHT, 0.55),
			Vector3(p.x, FOREST_WALL_HEIGHT * 0.5, p.y), trunk_mat)

	_build_canopy()
	_build_foliage()
	_build_forest_lights()
	_build_minimap_map()


func _build_canopy() -> void:
	# Copa escura; fica na camada 10, fora do mini-mapa, e não projeta sombra.
	var dark := _toon_mat(Color(0.045, 0.035, 0.075))
	var canopy := _box(Vector3(30.0, 0.3, 30.0), Vector3(7.0, 5.6, -4.0), dark, false)
	canopy.layers = 1 << 9
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Aglomerados de folhas penduradas na copa.
	for i in 26:
		var x := _rng.randf_range(-3.5, 17.5)
		var z := _rng.randf_range(-13.5, 5.5)
		var pos := Vector3(x, _rng.randf_range(4.55, 5.15), z)
		_foliage(pos, _rng.randf_range(0.55, 1.05), _leaf_color(), 1 << 9)


func _build_foliage() -> void:
	# Parede oeste e leste da sala norte.
	for z in range(-5, 7, 2):
		for side in [-1, 1]:
			var x: float = side * 3.85
			for k in 2:
				var pos := Vector3(x + side * 0.22,
					_rng.randf_range(0.8, 3.4) + k * 0.5,
					z + _rng.randf_range(-0.45, 0.45))
				_foliage(pos, _rng.randf_range(0.45, 0.85), _leaf_color(), 1 << 8)
	# Parede norte da sala.
	for x in range(-3, 4, 2):
		_foliage(Vector3(x + _rng.randf_range(-0.3, 0.3),
			_rng.randf_range(1.0, 3.3), 5.83), _rng.randf_range(0.55, 0.95), _leaf_color(), 1 << 8)
	# Paredes do corredor leste-oeste.
	for x in range(4, 18, 2):
		for z in [-5.95, -14.05]:
			var sign_z := 1.0 if z > -6.5 else -1.0
			_foliage(Vector3(x + _rng.randf_range(-0.4, 0.4),
				_rng.randf_range(0.9, 3.5), z + sign_z * 0.18),
				_rng.randf_range(0.5, 0.9), _leaf_color(), 1 << 8)
	# Topo das paredes: arbustos grandes.
	for i in 34:
		var on_north_room := i % 3 == 0
		var pos: Vector3
		if on_north_room:
			var side := -1.0 if i % 2 == 0 else 1.0
			pos = Vector3(side * 3.8, _rng.randf_range(3.9, 4.45), _rng.randf_range(-5.5, 5.5))
		else:
			var z := -5.95 if i % 2 == 0 else -14.05
			pos = Vector3(_rng.randf_range(4.0, 17.5), _rng.randf_range(3.9, 4.45), z)
		_foliage(pos, _rng.randf_range(0.65, 1.15), _leaf_color(), 1 << 9)
	# Folhas no chão (não bloqueiam o caminho).
	for i in 120:
		var x := _rng.randf_range(-3.6, 3.6)
		var z := _rng.randf_range(-5.8, 5.5)
		if i % 2 == 1:
			x = _rng.randf_range(4.0, 17.3)
			z = _rng.randf_range(-13.4, -6.6)
		_leaf_patch(Vector3(x, 0.02, z), _rng.randf_range(0.0, TAU), _ground_color())
	# Pedras, cogumelos, samambaias e raízes, longe do caminho do jogador.
	for i in 12:
		var pos := Vector3(_rng.randf_range(-2.8, 2.8), 0.08, _rng.randf_range(-5.0, 4.5))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(5.0, 16.5), 0.08, _rng.randf_range(-12.5, -7.5))
		if _near_path(pos):
			continue
		_stone(pos, _rng.randf_range(0.22, 0.50))
	for i in 20:
		var pos := Vector3(_rng.randf_range(-3.4, 3.4), 0.0, _rng.randf_range(-5.2, 5.2))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(4.5, 17.0), 0.0, _rng.randf_range(-12.8, -7.0))
		if _near_path(pos):
			continue
		_mushroom(pos, _mushroom_color(), _glow_color(), i % 5 == 0)
	for i in 26:
		var pos := Vector3(_rng.randf_range(-3.5, 3.5), 0.0, _rng.randf_range(-5.4, 5.4))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(4.2, 17.2), 0.0, _rng.randf_range(-13.2, -6.8))
		if _near_path(pos):
			continue
		_fern(pos, _rng.randf_range(0.5, 0.9), _fern_color())
	for i in 14:
		var pos := Vector3(_rng.randf_range(-3.6, 3.6), 0.0, _rng.randf_range(-5.6, 5.4))
		if i % 2 == 1:
			pos = Vector3(_rng.randf_range(4.2, 17.2), 0.0, _rng.randf_range(-13.3, -6.7))
		if _near_path(pos):
			continue
		_root(pos, _rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.6))
	_build_fireflies()


func _near_path(pos: Vector3) -> bool:
	if pos.x > -1.7 and pos.x < 1.7 and pos.z > -6.2 and pos.z < 5.5:
		return true
	if pos.z > -11.3 and pos.z < -7.5 and pos.x > 3.7:
		return true
	return false


func _build_forest_lights() -> void:
	# Cogumelos luminosos e vaga-lumes; sem azul, só verde/teal e âmbar.
	for p in [Vector3(-3.2, 2.2, -4.5), Vector3(3.2, 2.0, 1.0),
			Vector3(6.5, 2.2, -12.8), Vector3(15.5, 2.2, -7.2)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color(0.35, 0.95, 0.55)
		light.light_energy = 0.55
		light.omni_range = 4.5
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.55)


func _build_fireflies() -> void:
	for p in [Vector3(0.0, 1.7, -3.0), Vector3(10.0, 1.9, -10.0), Vector3(5.0, 1.6, 3.0)]:
		var quad := QuadMesh.new()
		quad.size = Vector2(0.09, 0.09)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.albedo_color = Color(1.0, 0.72, 0.30, 0.9)
		var particles := CPUParticles3D.new()
		particles.position = p
		particles.amount = 14
		particles.lifetime = 5.0
		particles.emitting = true
		particles.local_coords = false
		particles.mesh = quad
		particles.material_override = mat
		particles.direction = Vector3.UP
		particles.spread = 180.0
		particles.gravity = Vector3.ZERO
		particles.initial_velocity_min = 0.05
		particles.initial_velocity_max = 0.25
		particles.scale_amount_min = 0.7
		particles.scale_amount_max = 1.4
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 4.0
		particles.layers = 1 << 8
		add_child(particles)


func _leaf_color() -> Color:
	var colors := [
		Color(0.10, 0.42, 0.34),
		Color(0.16, 0.55, 0.35),
		Color(0.08, 0.30, 0.26),
		Color(0.28, 0.18, 0.42),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _ground_color() -> Color:
	var colors := [
		Color(0.24, 0.14, 0.26),
		Color(0.17, 0.10, 0.20),
		Color(0.13, 0.20, 0.19),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _mushroom_color() -> Color:
	var colors := [
		Color(0.25, 0.55, 0.38),
		Color(0.38, 0.22, 0.45),
		Color(0.45, 0.30, 0.18),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _glow_color() -> Color:
	var colors := [
		Color(0.30, 1.0, 0.55),
		Color(0.75, 0.95, 0.72),
		Color(1.0, 0.65, 0.25),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


func _fern_color() -> Color:
	var colors := [
		Color(0.10, 0.40, 0.25),
		Color(0.16, 0.50, 0.28),
		Color(0.08, 0.30, 0.22),
	]
	return colors[_rng.randi_range(0, colors.size() - 1)]


# --- Forest meshes -----------------------------------------------------------

func _toon_mat(color: Color, emission := Color(0, 0, 0, 1), emission_energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = 0.92
	mat.metallic = 0.0
	mat.rim_enabled = true
	mat.rim = 0.22
	mat.rim_tint = 0.35
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


func _foliage(pos: Vector3, radius: float, color: Color, layer: int) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.position = pos
	mi.scale = Vector3(
		_rng.randf_range(0.9, 1.25),
		_rng.randf_range(0.65, 0.95),
		_rng.randf_range(0.9, 1.25))
	mi.rotation.y = _rng.randf_range(0.0, TAU)
	mi.material_override = _toon_mat(color)
	mi.layers = layer
	add_child(mi)
	# Clumps menores por cima: quebra a leitura de "pedra" e vira folhagem.
	for k in 2:
		var clump := SphereMesh.new()
		clump.radius = radius * _rng.randf_range(0.35, 0.55)
		clump.height = clump.radius * 1.6
		clump.radial_segments = 5
		clump.rings = 2
		var leaf := MeshInstance3D.new()
		leaf.mesh = clump
		leaf.position = pos + Vector3(
			_rng.randf_range(-radius * 0.7, radius * 0.7),
			_rng.randf_range(radius * 0.35, radius * 0.9),
			_rng.randf_range(-radius * 0.7, radius * 0.7))
		leaf.rotation.y = _rng.randf_range(0.0, TAU)
		leaf.scale = Vector3(1.0, 0.72, 1.0)
		leaf.material_override = _toon_mat(color.lightened(0.16))
		leaf.layers = layer
		add_child(leaf)


func _leaf_patch(pos: Vector3, rot: float, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(_rng.randf_range(0.18, 0.4), 0.02, _rng.randf_range(0.12, 0.28))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = rot
	mi.material_override = _toon_mat(color)
	mi.layers = 1 << 8
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _stone(pos: Vector3, radius: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.2
	mesh.radial_segments = 5
	mesh.rings = 2
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = Vector3(1.0, 0.55, 0.85)
	mi.material_override = _toon_mat(Color(0.16, 0.14, 0.17))
	mi.layers = 1 << 8
	add_child(mi)


func _mushroom(pos: Vector3, cap_color: Color, glow: Color, light_on: bool) -> void:
	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.10
	cyl.height = _rng.randf_range(0.26, 0.46)
	cyl.radial_segments = 5
	stem.mesh = cyl
	stem.position = pos + Vector3(0.0, cyl.height * 0.5, 0.0)
	stem.material_override = _toon_mat(Color(0.32, 0.24, 0.18))
	stem.layers = 1 << 8
	add_child(stem)

	var cap := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _rng.randf_range(0.13, 0.23)
	sphere.height = sphere.radius * 1.2
	sphere.radial_segments = 6
	sphere.rings = 2
	cap.mesh = sphere
	cap.position = pos + Vector3(0.0, cyl.height + sphere.radius * 0.35, 0.0)
	cap.scale = Vector3(1.0, 0.55, 1.0)
	cap.material_override = _toon_mat(cap_color, glow, 1.4 if light_on else 0.0)
	cap.layers = 1 << 8
	add_child(cap)

	if light_on:
		var light := OmniLight3D.new()
		light.position = cap.position + Vector3(0.0, 0.25, 0.0)
		light.light_color = glow
		light.light_energy = 0.65
		light.omni_range = 3.2
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.65)


func _fern(pos: Vector3, scale: float, color: Color) -> void:
	for i in 5:
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.05, 0.75, 0.02)
		blade.mesh = mesh
		blade.position = pos + Vector3(0.0, 0.34 * scale, 0.0)
		blade.rotation = Vector3(
			deg_to_rad(_rng.randf_range(-28.0, -10.0)),
			deg_to_rad(float(i) * 72.0 + _rng.randf_range(-10.0, 10.0)),
			0.0)
		blade.scale = Vector3(scale, scale, scale)
		blade.material_override = _toon_mat(color)
		blade.layers = 1 << 8
		add_child(blade)


func _root(pos: Vector3, rot: float, length: float) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.14
	mesh.height = length
	mesh.radial_segments = 5
	mi.mesh = mesh
	mi.position = pos + Vector3(0.0, 0.16, 0.0)
	mi.rotation = Vector3(0.0, rot, deg_to_rad(_rng.randf_range(-12.0, 12.0)))
	mi.material_override = _toon_mat(Color(0.12, 0.08, 0.06))
	mi.layers = 1 << 8
	add_child(mi)


# --- Exit --------------------------------------------------------------------

func _build_exit() -> void:
	var gate_mat := _toon_mat(Color(0.10, 0.55, 0.28), Color(0.15, 0.85, 0.35), 1.1)
	var gate_a := _box(Vector3(0.3, 3.4, 0.3), Vector3(17.7, 1.7, -11.4), gate_mat, false)
	var gate_b := _box(Vector3(0.3, 3.4, 0.3), Vector3(17.7, 1.7, -8.6), gate_mat, false)
	var gate_top := _box(Vector3(0.3, 0.3, 3.2), Vector3(17.7, 3.4, -10.0), gate_mat, false)
	var dark := _box(Vector3(0.15, 2.8, 2.6), Vector3(17.85, 1.4, -10.0), _toon_mat(Color(0.01, 0.02, 0.015)), false)
	for mi in [gate_a, gate_b, gate_top, dark]:
		mi.layers = 1 << 8
	var exit_light := OmniLight3D.new()
	exit_light.position = Vector3(17.2, 1.8, -10.0)
	exit_light.light_color = Color(0.35, 1.0, 0.55)
	exit_light.light_energy = 0.65
	exit_light.omni_range = 4.5
	add_child(exit_light)
	# Trepadeiras Verdes no portal.
	for i in 8:
		var side := -1.0 if i % 2 == 0 else 1.0
		_foliage(Vector3(17.55, _rng.randf_range(1.0, 3.2), -10.0 + side * _rng.randf_range(0.9, 1.7)),
			_rng.randf_range(0.22, 0.38), _leaf_color(), 1 << 8)
	var tag := Label3D.new()
	tag.text = "SAÍDA"
	tag.font_size = 46
	tag.modulate = Color(0.55, 1.0, 0.62)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(17.5, 3.9, -10.0)
	tag.no_depth_test = false
	tag.layers = 1 << 8
	add_child(tag)


# --- Vignette / HUD ----------------------------------------------------------

func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = FOREST_VIGNETTE
	mat.set_shader_parameter("tint", Color(0.02, 0.012, 0.035, 1.0))
	mat.set_shader_parameter("strength", 0.34)
	mat.set_shader_parameter("softness", 0.58)
	mat.set_shader_parameter("dither_strength", 0.006)
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var label := Label.new()
	label.text = "Lab 3D — Murky Forest (SMT III + toon)\nWASD/setas: andar e virar · Q/E ou botão direito: câmera · 1: aliados · Esc: sair"
	label.position = Vector2(20, 16)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.70, 0.95, 0.72))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)

	_door_prompt = Label.new()
	_door_prompt.text = ""
	_door_prompt.position = Vector2(520, 660)
	_door_prompt.add_theme_font_size_override("font_size", 22)
	_door_prompt.add_theme_color_override("font_color", Color(0.75, 1.0, 0.70))
	_door_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_door_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_door_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_door_prompt.visible = false
	layer.add_child(_door_prompt)
	add_child(layer)


# --- Minimap -----------------------------------------------------------------

func _build_minimap_map() -> void:
	# Cópias chapadas do piso/paredes/pilares na camada 5: só o mini-mapa vê.
	var floor_col := Color(0.42, 0.27, 0.50)
	var wall_col := Color(0.10, 0.26, 0.23)
	var trunk_col := Color(0.16, 0.12, 0.18)
	_minimap_box(Vector3(8.0, 0.4, 20.0), Vector3(0.0, -0.2, -4.0), floor_col)
	_minimap_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -10.0), floor_col)
	for data in [
		[Vector3(8.5, FOREST_WALL_HEIGHT, 0.5), Vector3(0.0, FOREST_WALL_HEIGHT * 0.5, 6.25)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 20.0), Vector3(-4.25, FOREST_WALL_HEIGHT * 0.5, -4.0)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 12.0), Vector3(4.25, FOREST_WALL_HEIGHT * 0.5, 0.0)],
		[Vector3(22.5, FOREST_WALL_HEIGHT, 0.5), Vector3(7.0, FOREST_WALL_HEIGHT * 0.5, -14.25)],
		[Vector3(14.5, FOREST_WALL_HEIGHT, 0.5), Vector3(11.0, FOREST_WALL_HEIGHT * 0.5, -5.75)],
		[Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, -10.0)],
	]:
		_minimap_box(data[0], data[1], wall_col)
	for p in [
		Vector2(-3.0, -2.0), Vector2(3.0, -7.0),
		Vector2(7.0, -13.0), Vector2(13.0, -7.0),
	]:
		_minimap_box(Vector3(0.55, FOREST_WALL_HEIGHT, 0.55),
			Vector3(p.x, FOREST_WALL_HEIGHT * 0.5, p.y), trunk_col)
	# Saída verde no mapa.
	_minimap_box(Vector3(0.7, 0.2, 3.0), Vector3(17.7, 0.1, -10.0), Color(0.25, 1.0, 0.45))


func _minimap_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mi.material_override = mat
	mi.layers = 1 << 4
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_minimap() -> void:
	_marker_texture = _make_marker_texture()
	_minimap_viewport = SubViewport.new()
	_minimap_viewport.size = Vector2i(MINIMAP_SIZE, MINIMAP_SIZE)
	_minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_minimap_viewport.own_world_3d = false
	add_child(_minimap_viewport)
	_minimap_viewport.world_3d = get_world_3d()

	_minimap_camera = Camera3D.new()
	_minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_minimap_camera.size = MINIMAP_WORLD_SIZE
	_minimap_camera.near = 0.1
	_minimap_camera.far = 60.0
	_minimap_camera.cull_mask = 1 << 4
	_minimap_camera.current = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.008, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_minimap_camera.environment = env
	_minimap_camera.position = Vector3(0.0, 30.0, 0.0)
	_minimap_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_minimap_viewport.add_child(_minimap_camera)

	var layer := CanvasLayer.new()
	layer.layer = 15
	var border := ColorRect.new()
	border.color = Color(0.48, 0.40, 0.22, 0.95)
	border.position = Vector2(1150, 12)
	border.size = Vector2(120, 120)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(border)
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.008, 0.02, 1.0)
	bg.position = Vector2(1152, 14)
	bg.size = Vector2(116, 116)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)
	_minimap_rect = TextureRect.new()
	_minimap_rect.texture = _minimap_viewport.get_texture()
	_minimap_rect.position = Vector2(1154, 16)
	_minimap_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_minimap_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_minimap_rect.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	_minimap_rect.scale = Vector2(
		float(MINIMAP_DISPLAY_SIZE) / float(MINIMAP_SIZE),
		float(MINIMAP_DISPLAY_SIZE) / float(MINIMAP_SIZE))
	_minimap_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_minimap_rect)
	_marker_root = Control.new()
	_marker_root.position = Vector2(1154, 16)
	_marker_root.size = Vector2(MINIMAP_DISPLAY_SIZE, MINIMAP_DISPLAY_SIZE)
	_marker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_marker_root)
	add_child(layer)

	_add_minimap_marker(player, Color(0.25, 1.0, 0.45, 1.0), 9.0, "player")
	for f in _followers:
		_add_minimap_marker(f["node"], Color(0.25, 1.0, 0.45, 1.0), 6.0, "ally")
	if _enemy_body != null:
		_add_minimap_marker(_enemy_body, Color(1.0, 0.22, 0.18, 1.0), 8.0, "enemy")
	for node in get_tree().get_nodes_in_group("minimap_npc"):
		if node is Node3D:
			_add_minimap_marker(node, Color(1.0, 1.0, 1.0, 1.0), 8.0, "npc")


func _add_minimap_marker(node: Node3D, color: Color, size: float, kind: String) -> void:
	var marker := TextureRect.new()
	marker.texture = _marker_texture
	marker.modulate = color
	marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.custom_minimum_size = Vector2(size, size)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker_root.add_child(marker)
	marker.size = Vector2(size, size)
	_minimap_markers.append({
		"node": node,
		"rect": marker,
		"size": size,
		"kind": kind,
	})


func _build_hud_badges() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(14, 76)
	vbox.size = Vector2(250, 240)
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vbox)
	# HP demo: o lab não tem combate; a HUD final deve ler GameState.party.
	var badges := [
		["ABRA", 86, 100, false],
		["PANCHAM", 100, 100, true],
		["ORC", 46, 100, true],
	]
	for data in badges:
		vbox.add_child(_make_hud_badge(str(data[0]), int(data[1]), int(data[2]), bool(data[3])))
	add_child(layer)


func _make_hud_badge(character_name: String, hp: int, max_hp: int, is_ally: bool) -> PanelContainer:
	var ratio := float(hp) / float(max_hp)
	var color := _hp_color(ratio)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 56)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.025, 0.02, 0.88)
	style.border_color = Color(0.55, 0.45, 0.22, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var accent := ColorRect.new()
	accent.color = color
	accent.custom_minimum_size = Vector2(4, 42)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = character_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(hp_row)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = float(max_hp)
	bar.value = float(hp)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(140, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.07, 0.055, 0.045, 0.95)
	bar_bg.corner_radius_top_left = 2
	bar_bg.corner_radius_top_right = 2
	bar_bg.corner_radius_bottom_left = 2
	bar_bg.corner_radius_bottom_right = 2
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = color
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", bar_bg)
	bar.add_theme_stylebox_override("fill", bar_fill)
	hp_row.add_child(bar)
	var hp_label := Label.new()
	hp_label.text = "%d / %d" % [hp, max_hp]
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.78, 0.75, 0.66))
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(hp_label)

	_hud_badges.append({
		"panel": panel,
		"bar": bar,
		"hp_label": hp_label,
		"ally": is_ally,
	})
	return panel


func _hp_color(ratio: float) -> Color:
	if ratio <= 0.25:
		return Color(0.90, 0.25, 0.20)
	if ratio <= 0.50:
		return Color(0.95, 0.75, 0.20)
	return Color(0.25, 0.90, 0.40)


func _update_hud_badges() -> void:
	for badge in _hud_badges:
		if bool(badge["ally"]):
			(badge["panel"] as Control).visible = _party_visible


func _update_minimap() -> void:
	if _minimap_camera == null or _minimap_rect == null or player == null:
		return
	_minimap_camera.global_position = player.global_position + Vector3(0.0, 30.0, 0.0)
	var vp := Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	var rect_size := _marker_root.size
	for m in _minimap_markers:
		var rect: TextureRect = m["rect"]
		var node: Node3D = m["node"]
		var show := is_instance_valid(node)
		if show and m["kind"] == "ally" and not _party_visible:
			show = false
		if show:
			var world := node.global_position + Vector3(0.0, 0.7, 0.0)
			var view := _minimap_camera.unproject_position(world)
			var pos := Vector2(view.x / vp.x, view.y / vp.y) * rect_size
			if pos.x < 0.0 or pos.y < 0.0 or pos.x > rect_size.x or pos.y > rect_size.y:
				show = false
			else:
				rect.position = pos - Vector2(m["size"], m["size"]) * 0.5
		rect.visible = show


func _make_marker_texture() -> ImageTexture:
	var rows := [
		"....#......#....",
		"....#......#....",
		"....##....##....",
		"...##########...",
		"..############..",
		".##############.",
		"##...######...##",
		"##...######...##",
		"....########....",
		"...##########...",
		"...##########...",
		"..###..##..###..",
		".###........###.",
		"###..........###",
		"###..........###",
		"................",
	]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in mini(row.length(), 16):
			if row[x] == "#":
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)


# --- Toon and render layers --------------------------------------------------

func _apply_toon(root: Node) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mi as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		if mesh_instance.material_override is BaseMaterial3D:
			var over := mesh_instance.material_override as BaseMaterial3D
			if over.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			var dup := over.duplicate(true) as BaseMaterial3D
			dup.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			dup.specular_mode = BaseMaterial3D.SPECULAR_TOON
			dup.rim_enabled = true
			dup.rim = 0.22
			dup.rim_tint = 0.35
			mesh_instance.material_override = dup
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var mat := mesh_instance.get_active_material(i)
			if not (mat is BaseMaterial3D):
				continue
			var base := mat as BaseMaterial3D
			if base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			var dup := base.duplicate(true) as BaseMaterial3D
			dup.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			dup.specular_mode = BaseMaterial3D.SPECULAR_TOON
			dup.rim_enabled = true
			dup.rim = 0.22
			dup.rim_tint = 0.35
			mesh_instance.set_surface_override_material(i, dup)


func _set_actor_layers() -> void:
	_set_layers(player, 1 << 1)
	for f in _followers:
		_set_layers(f["node"], 1 << 2)
	if _enemy_body != null:
		_set_layers(_enemy_body, 1 << 3)


func _set_layers(root: Node, layer: int) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = layer
	for particles in root.find_children("*", "CPUParticles3D", true, false):
		(particles as CPUParticles3D).layers = layer
	for label in root.find_children("*", "Label3D", true, false):
		(label as Label3D).layers = layer
