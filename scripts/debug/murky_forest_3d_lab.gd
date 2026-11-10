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
const NPC_DATA := preload("res://scripts/dungeon/npc_data.gd")
const NPC_PROMPT := preload("res://scripts/debug/overworld_prompt.gd")
const NPC_HUD := preload("res://scripts/debug/dialogue_hud_styles.gd")
const ALLY_DIALOGUE := preload("res://scripts/dungeon/ally_dialogue.gd")
const ALLY_BANNER := preload("res://scripts/debug/ally_banner.gd")
const NAMEPLATE := preload("res://scripts/debug/floating_nameplate.gd")
const STATE_ICON := preload("res://scripts/debug/overworld_state_icon.gd")
const MARKER_RING_SHADER := preload("res://shaders/overworld_marker_ring.gdshader")
const WALL_SHADER := preload("res://shaders/wall_palisade_blend.gdshader")
const ICON_ANGER := preload("res://assets/ui/overworld_icons/state_anger.png")
const ICON_SWEAT := preload("res://assets/ui/overworld_icons/state_sweat.png")
const ICON_ALERT := preload("res://assets/ui/overworld_icons/state_alert.png")
const ICON_QUESTION := preload("res://assets/ui/overworld_icons/state_question.png")
const ICON_TALKED := preload("res://assets/ui/overworld_icons/state_talked.png")
const FOLLOWER_NAMES := {"pancham": "PANCHAM", "dqt_orc": "ORC"}
const FOREST_WALL_HEIGHT := 4.2
const MINIMAP_SIZE := 256
const MINIMAP_DISPLAY_SIZE := 112
const MINIMAP_WORLD_SIZE := 20.0
const NPC_LOOK_RADIUS := 3.8
const NPC_INTERACT_RADIUS := 2.4
const NPC_COLLISION_LAYER := 1 << 4  ## 16: o jogador colide; o raio da câmera (mask 1) ignora.

## D-1063: o NPC é sólido para o jogador, mas não puxa a câmera (D-1023).

## Pool de 10 NPCs 3D (D-1063): 5 Pokémon Stage-1 + 5 monstros básicos do DQT.
const NPC_POOL: Array[Dictionary] = [
	{"id": "bulbasaur", "name": "BULBASAUR", "height": 0.78, "has_quest": true},
	{"id": "charmander", "name": "CHARMANDER", "height": 0.85},
	{"id": "squirtle", "name": "SQUIRTLE", "height": 0.80},
	{"id": "pikachu", "name": "PIKACHU", "height": 0.72},
	{"id": "eevee", "name": "EEVEE", "height": 0.70},
	{"id": "dqt_dracky", "name": "DRACKY", "height": 0.95},
	{"id": "dqt_healslime", "name": "HEAL SLIME", "height": 1.15},
	{"id": "dqt_sabrecub", "name": "SABRECUB", "height": 0.85},
	{"id": "dqt_platypunk", "name": "PLATYPUNK", "height": 0.95},
	{"id": "dqt_fungi", "name": "FUNGHOUL", "height": 0.95},
]

## 3 posições laterais no corredor em L (não obstruem o caminho nem a patrulha).
const NPC_SLOTS: Array[Dictionary] = [
	{"pos": Vector3(-2.6, 0.0, -4.2), "yaw": PI * 0.35},
	{"pos": Vector3(2.5, 0.0, -9.8), "yaw": -PI * 0.35},
	{"pos": Vector3(8.2, 0.0, -7.2), "yaw": 0.0},
]

## D-1096: estilo das placas de nome na linguagem dos cards/HUDs.
## F6 alterna no lab para comparação.
@export_enum("unit_card", "move_strip", "expedition") var name_style := "unit_card"

var _rng := RandomNumberGenerator.new()
var _foliage_fade: Array[Dictionary] = []
var _marker_rings: Array[Dictionary] = []
var _state_icons: Array[Dictionary] = []
var _name_labels: Array[Dictionary] = []
var _npc_prompt: Control
var _npc_hud: Control
var _dialogue_banners: Array[Control] = []
var _battle_hud: Node
var _dialogue_stage := 0
var _dialogue_reactions: Array[Dictionary] = []
var _enemy_marker_root: Node3D
var _enemy_icon_entry: Dictionary = {}
var _enemy_ring_entry: Dictionary = {}
## D-1093: retratos usam o ícone estabelecido (face crop/portrait), não a arte
## inteira. O Bulbasaur usa a opção B final, com 0,03 para a esquerda.
var PORTRAIT_FACE_REGIONS := {
	"abra": Rect2(300.0 / 851.0, 120.0 / 851.0, 320.0 / 851.0, 360.0 / 851.0),
	"pancham": Rect2(300.0 / 1261.0, 40.0 / 1261.0, 680.0 / 1261.0, 760.0 / 1261.0),
	"gible": Rect2(30.0 / 762.0, 100.0 / 762.0, 490.0 / 762.0, 560.0 / 762.0),
	"bulbasaur": Rect2(0.03, 0.04, 0.78, 0.78),
}
var _minimap_viewport: SubViewport
var _minimap_camera: Camera3D
var _minimap_rect: TextureRect
var _marker_root: Control
var _minimap_markers: Array[Dictionary] = []
var _hud_badges: Array[Dictionary] = []
var _enemy_alert: PanelContainer
var _npcs: Array[Dictionary] = []
var _npc_offset := 0
var _npc_talking := false
var _npc_talk_target: Dictionary = {}
var _npc_dialogue_panel: PanelContainer
var _npc_dialogue_title: Label
var _npc_dialogue_text: Label
var _interact_prev := false


func _ready() -> void:
	# D-1086: o Slime deste lab é o protótipo Medroso (D-310/D-315).
	enable_threat_demo = true
	super()
	# D-1063: os NPCs são sólidos para o jogador (layer 16), mas o raio da
	# câmera usa a máscara 1 e continua ignorando os NPCs (D-1023).
	player.collision_mask |= NPC_COLLISION_LAYER
	_rng.seed = 20261109
	_build_npcs()
	_apply_toon(self)
	_set_actor_layers()
	_add_world_markers()
	if _camera != null:
		# A camada 5 é só do mapa do mini-mapa; a câmera principal não a vê.
		_camera.cull_mask = 0xFFFFFFFF & ~(1 << 4)
	_build_minimap()
	_build_hud_badges()
	_build_npc_dialogue_ui()


func _process(delta: float) -> void:
	super(delta)
	_update_enemy_marker()
	_update_marker_rings(delta)
	_update_name_labels()
	_update_state_icons(delta)
	_update_talking_labels()
	_update_foliage_fade(delta)
	_update_hud_badges()


func _physics_process(delta: float) -> void:
	super(delta)
	_update_npcs(delta)
	_update_minimap()


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_2:
			cycle_npcs((_npc_offset + 3) % NPC_POOL.size())
		elif key == KEY_F6:
			_cycle_name_style()


# --- Environment -------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.012, 0.030)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.32, 0.50)
	env.ambient_light_energy = 0.95
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.88
	env.fog_enabled = true
	env.fog_light_color = Color(0.055, 0.035, 0.085)
	env.fog_density = 0.022
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.02
	# D-1083: menos contraste/saturação no 3D, sem mexer no HUD.
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.98
	env.adjustment_contrast = 0.82
	env.adjustment_saturation = 0.88
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Lua verde-pálida: fria, mas não azul, para manter a paleta do bioma.
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	moon.light_color = Color(0.66, 0.86, 0.72)
	moon.light_energy = 0.45
	moon.shadow_enabled = true
	moon.shadow_opacity = 0.55
	moon.directional_shadow_max_distance = 40.0
	add_child(moon)

	# Preenchimento quente no centro do L.
	var fill := OmniLight3D.new()
	fill.position = Vector3(8.0, 3.4, -10.0)
	fill.light_color = Color(1.0, 0.58, 0.30)
	fill.light_energy = 0.85
	fill.omni_range = 17.0
	add_child(fill)

	# D-1077/D-1083: preenchimento frio no início e no corredor, mais discreto.
	for data in [
		[Vector3(0.0, 3.0, -2.0), Color(0.55, 0.78, 0.75), 0.32, 9.0],
		[Vector3(0.0, 2.8, -8.8), Color(0.62, 0.80, 0.92), 0.22, 7.0],
	]:
		var light := OmniLight3D.new()
		light.position = data[0]
		light.light_color = data[1]
		light.light_energy = data[2]
		light.omni_range = data[3]
		add_child(light)


# --- Forest room -------------------------------------------------------------

## D-1116/D-1118: paliçada base + 5 variações, uma por parede, em ordem
## sorteada, com crossfade nos cantos e 60% de textura sobre a cor antiga.
const WALL_TEXTURE_PATHS := [
	"res://assets/textures/walls/murky_wall_root_palisade.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v1.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v2.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v3.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v4.png",
	"res://assets/textures/walls/murky_wall_root_palisade_v5.png",
]
## Vizinhas de cada parede nos dois cantos internos.
const WALL_NEIGHBORS := [
	[1, 2], [0, 3], [0, 4], [1, 5], [2, 5], [3, 4],
]
## Canto interno (x, z) de cada ponta de cada parede.
const WALL_CORNERS := [
	[Vector2(-4.0, 6.0), Vector2(4.0, 6.0)],
	[Vector2(-4.0, 6.0), Vector2(-4.0, -14.0)],
	[Vector2(4.0, 6.0), Vector2(4.0, -6.0)],
	[Vector2(-4.0, -14.0), Vector2(18.0, -14.0)],
	[Vector2(4.0, -6.0), Vector2(18.0, -6.0)],
	[Vector2(18.0, -14.0), Vector2(18.0, -6.0)],
]


func _wall_materials() -> Array[ShaderMaterial]:
	var texs: Array[Texture2D] = []
	for path in WALL_TEXTURE_PATHS:
		texs.append(load(path) as Texture2D)
	texs.shuffle()
	var mats: Array[ShaderMaterial] = []
	for i in texs.size():
		mats.append(_wall_material(i, texs))
	return mats


func _wall_material(index: int, texs: Array[Texture2D]) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WALL_SHADER
	mat.set_shader_parameter("tex_own", texs[index])
	mat.set_shader_parameter("tex_a", texs[int(WALL_NEIGHBORS[index][0])])
	mat.set_shader_parameter("tex_b", texs[int(WALL_NEIGHBORS[index][1])])
	var ca: Vector2 = WALL_CORNERS[index][0]
	var cb: Vector2 = WALL_CORNERS[index][1]
	mat.set_shader_parameter("corner_a", Vector4(ca.x, ca.y, 0.0, 1.0))
	mat.set_shader_parameter("corner_b", Vector4(cb.x, cb.y, 0.0, 1.0))
	mat.set_shader_parameter("corner_width", 2.0)
	mat.set_shader_parameter("tile", 0.20)
	mat.set_shader_parameter("strength", 0.40)
	mat.set_shader_parameter("base_color", Color(0.075, 0.145, 0.135, 1.0))
	return mat


func _build_room() -> void:
	var floor_mat := _toon_mat(Color(0.19, 0.11, 0.22))
	var wall_mats := _wall_materials()
	var trunk_mat := _toon_mat(Color(0.10, 0.065, 0.055))

	# Piso em L (mesma colisão do lab: a navmesh e a IA continuam valendo).
	_box(Vector3(8.0, 0.4, 20.0), Vector3(0.0, -0.2, -4.0), floor_mat)
	_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -10.0), floor_mat)
	# Paredes externas do L, agora com 4,2 m.
	_box(Vector3(8.5, FOREST_WALL_HEIGHT, 0.5), Vector3(0.0, FOREST_WALL_HEIGHT * 0.5, 6.25), wall_mats[0])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 20.0), Vector3(-4.25, FOREST_WALL_HEIGHT * 0.5, -4.0), wall_mats[1])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 12.0), Vector3(4.25, FOREST_WALL_HEIGHT * 0.5, 0.0), wall_mats[2])
	_box(Vector3(22.5, FOREST_WALL_HEIGHT, 0.5), Vector3(7.0, FOREST_WALL_HEIGHT * 0.5, -14.25), wall_mats[3])
	_box(Vector3(14.5, FOREST_WALL_HEIGHT, 0.5), Vector3(11.0, FOREST_WALL_HEIGHT * 0.5, -5.75), wall_mats[4])
	_box(Vector3(0.5, FOREST_WALL_HEIGHT, 8.0), Vector3(18.25, FOREST_WALL_HEIGHT * 0.5, -10.0), wall_mats[5])
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
			var x: float = side * 3.98
			for k in 2:
				var pos := Vector3(x + side * 0.14,
					_rng.randf_range(0.8, 3.4) + k * 0.5,
					z + _rng.randf_range(-0.45, 0.45))
				_foliage(pos, _rng.randf_range(0.35, 0.65), _leaf_color(), 1 << 8)
	# Parede norte da sala.
	for x in range(-3, 4, 2):
		_foliage(Vector3(x + _rng.randf_range(-0.3, 0.3),
			_rng.randf_range(1.0, 3.3), 5.92), _rng.randf_range(0.45, 0.75), _leaf_color(), 1 << 8)
	# Paredes do corredor leste-oeste.
	for x in range(4, 18, 2):
		for z in [-5.95, -14.05]:
			var sign_z := 1.0 if z > -6.5 else -1.0
			_foliage(Vector3(x + _rng.randf_range(-0.4, 0.4),
				_rng.randf_range(0.9, 3.5), z + sign_z * 0.12),
				_rng.randf_range(0.4, 0.7), _leaf_color(), 1 << 8)
	# Topo das paredes: arbustos grandes.
	for i in 34:
		var on_north_room := i % 3 == 0
		var pos: Vector3
		if on_north_room:
			var side := -1.0 if i % 2 == 0 else 1.0
			pos = Vector3(side * 4.0, _rng.randf_range(3.9, 4.45), _rng.randf_range(-5.5, 5.5))
		else:
			var z := -5.95 if i % 2 == 0 else -14.05
			pos = Vector3(_rng.randf_range(4.0, 17.5), _rng.randf_range(3.9, 4.45), z)
		_foliage(pos, _rng.randf_range(0.5, 0.9), _leaf_color(), 1 << 9)
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
	_build_vertical_foliage()
	_build_fireflies()


## D-1077: vinhas, galhos e clumps médios ancorados nas paredes/árvores.
func _build_vertical_foliage() -> void:
	var vine_tops := [
		Vector3(-3.95, 4.5, -4.0), Vector3(3.95, 4.5, 1.5),
		Vector3(-3.95, 4.5, 3.0), Vector3(3.95, 4.5, -5.0),
		Vector3(6.0, 4.5, -5.9), Vector3(10.0, 4.5, -5.9),
		Vector3(14.0, 4.5, -5.9), Vector3(7.0, 4.5, -14.1),
		Vector3(11.0, 4.5, -14.1), Vector3(15.0, 4.5, -14.1),
	]
	for i in vine_tops.size():
		_vine(vine_tops[i], 1.6 + float(i % 3) * 0.35)
	var branches := [
		{"pos": Vector3(-3.0, 3.2, -2.0), "dir": Vector3(1.0, 0.0, 0.0), "len": 1.3},
		{"pos": Vector3(3.0, 3.0, -7.0), "dir": Vector3(-1.0, 0.0, 0.0), "len": 1.2},
		{"pos": Vector3(7.0, 3.1, -13.0), "dir": Vector3(0.0, 0.0, 1.0), "len": 1.4},
		{"pos": Vector3(13.0, 3.0, -7.0), "dir": Vector3(0.0, 0.0, -1.0), "len": 1.3},
	]
	for b in branches:
		_branch(b["pos"], b["dir"], float(b["len"]))
	# Clumps médios nas paredes, menores, preenchendo a altura.
	for i in 12:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * 3.98
		var z := _rng.randf_range(-5.2, 5.0)
		_foliage(Vector3(x, _rng.randf_range(2.5, 3.5), z),
			_rng.randf_range(0.25, 0.42), _leaf_color(), 1 << 8)


func _vine(top: Vector3, length: float) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.04
	mesh.height = length
	mesh.radial_segments = 5
	mi.mesh = mesh
	mi.position = top + Vector3(0.0, -length * 0.5, 0.0)
	mi.material_override = _toon_mat(Color(0.10, 0.16, 0.10))
	mi.layers = 1 << 8
	add_child(mi)
	for k in 3:
		var off := Vector3(_rng.randf_range(-0.14, 0.14), 0.0, _rng.randf_range(-0.14, 0.14))
		_foliage(top + off + Vector3(0.0, -length * (0.35 + 0.2 * float(k)), 0.0),
			_rng.randf_range(0.18, 0.30), _leaf_color(), 1 << 8)


func _branch(base: Vector3, dir: Vector3, length: float) -> void:
	var d := dir.normalized()
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.065
	mesh.height = length
	mesh.radial_segments = 5
	mi.mesh = mesh
	mi.position = base + d * (length * 0.5)
	if absf(d.x) > 0.5:
		mi.rotation.z = PI * 0.5 * signf(d.x)
	else:
		mi.rotation.x = -PI * 0.5 * signf(d.z)
	mi.material_override = _toon_mat(Color(0.10, 0.07, 0.05))
	mi.layers = 1 << 8
	add_child(mi)
	_foliage(base + d * length, _rng.randf_range(0.32, 0.48), _leaf_color(), 1 << 8)


func _near_path(pos: Vector3) -> bool:
	for slot in NPC_SLOTS:
		var spos: Vector3 = slot["pos"]
		if Vector2(pos.x - spos.x, pos.z - spos.z).length() < 1.1:
			return true
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
		light.light_energy = 0.40
		light.omni_range = 4.5
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.40)

	# D-1077/D-1083: aproximação quente da saída, mais discreta.
	var approach := OmniLight3D.new()
	approach.position = Vector3(13.5, 2.2, -10.0)
	approach.light_color = Color(1.0, 0.68, 0.38)
	approach.light_energy = 0.30
	approach.omni_range = 6.0
	add_child(approach)


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
	var mat := _toon_mat(color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 1.0
	mi.material_override = mat
	mi.layers = layer
	add_child(mi)
	_foliage_fade.append({
		"mesh": mi,
		"mat": mat,
		"radius": radius * maxf(maxf(mi.scale.x, mi.scale.y), mi.scale.z),
	})
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
		var leaf_mat := _toon_mat(color.lightened(0.16))
		leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		leaf_mat.albedo_color.a = 1.0
		leaf.material_override = leaf_mat
		leaf.layers = layer
		add_child(leaf)
		_foliage_fade.append({
			"mesh": leaf,
			"mat": leaf_mat,
			"radius": clump.radius * 1.1,
		})


## D-1077: some suavemente com folhas que ficam entre a câmera e o jogador.
func _update_foliage_fade(delta: float) -> void:
	if _camera == null or player == null:
		return
	var cam := _camera.global_position
	var target := player.global_position + Vector3(0.0, 1.0, 0.0)
	var seg := target - cam
	var seg_len2 := maxf(seg.length_squared(), 0.001)
	for entry in _foliage_fade:
		var mesh := entry["mesh"] as MeshInstance3D
		if mesh == null or not is_instance_valid(mesh):
			continue
		var mat := entry["mat"] as StandardMaterial3D
		if mat == null:
			continue
		var pos := mesh.global_position
		var t := clampf((pos - cam).dot(seg) / seg_len2, 0.0, 1.0)
		var closest := cam + seg * t
		var occlude := t > 0.02 and t < 0.98 \
			and pos.distance_to(cam) < 3.6 \
			and pos.distance_to(closest) < float(entry["radius"]) + 0.35
		var target_a := 0.22 if occlude else 1.0
		var col := mat.albedo_color
		col.a = lerpf(col.a, target_a, clampf(delta * 8.0, 0.0, 1.0))
		mat.albedo_color = col


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
		light.light_energy = 0.45
		light.omni_range = 3.2
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.45)


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
	exit_light.light_energy = 0.45
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
	label.text = "Lab 3D — Murky Forest (SMT III + toon)\nSetas/W/S: andar · A/D ou botão direito: câmera · 1: aliados · 2: trocar NPCs · F6: estilo do nome · Z/E: falar/saída · Esc: sair"
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


# --- NPCs (D-1063) -----------------------------------------------------------

func _build_npcs() -> void:
	# Sorteia/exibe 3 NPCs no corredor (misturando Pokémon Stage-1 e DQT básicos).
	var default_indices: Array[int] = [0, 5, 3] # Bulbasaur, Dracky, Pikachu no início; KEY_2 gira todos os 10.
	for slot_i in NPC_SLOTS.size():
		var pool_idx: int = default_indices[slot_i] if _npc_offset == 0 else ((_npc_offset + slot_i) % NPC_POOL.size())
		_spawn_npc_at_slot(slot_i, pool_idx)


func _spawn_npc_at_slot(slot_i: int, pool_idx: int) -> void:
	var slot: Dictionary = NPC_SLOTS[slot_i]
	var data: Dictionary = NPC_POOL[pool_idx]
	var model_id := str(data["id"])
	var npc_name := str(data["name"])
	var height := float(data["height"])
	var pos: Vector3 = slot["pos"]
	var base_yaw := float(slot["yaw"])

	var body := StaticBody3D.new()
	body.name = "Npc_%s" % model_id
	body.position = pos
	body.rotation.y = base_yaw
	# Layer 16 (bit 4): sólida para o jogador (máscara 1|16); o raio da câmera
	# usa a máscara 1 e ignora os NPCs (D-1023).
	body.collision_layer = NPC_COLLISION_LAYER
	body.collision_mask = 0
	body.add_to_group("minimap_npc")

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = clampf(height * 0.30, 0.22, 0.42)
	capsule.height = maxf(height, capsule.radius * 2.0 + 0.05)
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	body.add_child(shape)
	add_child(body)

	var model := _make_model(model_id, height)
	body.add_child(model)
	_add_blob_shadow(body, clampf(height * 0.85, 0.65, 1.1), clampf(height * 0.65, 0.50, 0.90))
	var ap := _anim_player(model)
	_play_idle(ap)

	var top_y := height
	if model_id == "dqt_dracky":
		top_y = height * 1.48

	# D-1094: placa de nome (Paper/terminal/comic) em vez do Label3D solto.
	var tag := _spawn_nameplate(body, npc_name, "NPC", top_y + 0.65)

	var dlg_idx := (pool_idx * 3 + slot_i) % NPC_DATA.DIALOGUES.size()
	_npcs.append({
		"node": body,
		"model": model,
		"ap": ap,
		"id": model_id,
		"name": npc_name,
		"height": height,
		"base_yaw": base_yaw,
		"dialogue": NPC_DATA.DIALOGUES[dlg_idx],
		"pool_idx": pool_idx,
		"has_quest": bool(data.get("has_quest", false)),
		"talked": false,
		"tag": tag,
	})


# --- D-1086: círculos no chão, ícones de estado e nomes dos aliados --------

func _add_world_markers() -> void:
	for npc in _npcs:
		_decorate_npc(npc)
	for f in _followers:
		var body: Node3D = f["node"]
		var height := float(f["height"])
		_add_ground_ring(body, clampf(height * 0.55, 0.42, 0.95), Color(0.22, 0.48, 1.0, 0.65), "ally")
		_add_ally_talking(f)
	if _enemy_body != null:
		_enemy_marker_root = Node3D.new()
		_enemy_marker_root.name = "EnemyMarkers"
		add_child(_enemy_marker_root)
		_add_ground_ring(_enemy_marker_root, 0.45, Color(1.0, 0.72, 0.15, 0.70), "enemy")
		_enemy_ring_entry = _marker_rings.back()
		_enemy_icon_entry = _add_state_icon(_enemy_marker_root, Vector3(0.0, 1.05, 0.0))
		var enemy_name := "SLIME"
		for child in _enemy_body.get_children():
			if child is Label3D:
				enemy_name = (child as Label3D).text
				(child as Label3D).visible = false
				break
		var enemy_tag := _spawn_nameplate(_enemy_body, enemy_name, "ENEMY", 2.2)
		_name_labels.append({"node": enemy_tag, "owner": _enemy_body})
		_enemy_icon_entry["plate"] = enemy_tag

func _decorate_npc(npc: Dictionary) -> void:
	if npc.has("icon_entry"):
		var old_sprite = npc["icon_entry"].get("sprite")
		if is_instance_valid(old_sprite):
			return
	var body: Node3D = npc["node"]
	var height := float(npc["height"])
	var top_y := height
	if str(npc["id"]) == "dqt_dracky":
		top_y = height * 1.48
	_add_ground_ring(body, clampf(height * 0.75, 0.45, 0.85), Color(1.0, 1.0, 1.0, 0.68), "npc")
	# D-1105: a posição final é dinâmica (acima da placa); este é só o inicial.
	npc["icon_entry"] = _add_state_icon(body, Vector3(0.0, top_y + 1.75, 0.0))
	if npc.has("tag") and is_instance_valid(npc["tag"]):
		npc["icon_entry"]["plate"] = npc["tag"]
	var talking := Label3D.new()
	talking.text = "..."
	talking.font_size = 48
	talking.modulate = Color(1.0, 0.86, 0.45)
	talking.outline_size = 6
	talking.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	talking.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	talking.no_depth_test = false
	talking.position = Vector3(0.0, top_y + 1.65, 0.0)
	talking.layers = 1 << 6
	talking.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	talking.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talking.visible = false
	body.add_child(talking)
	npc["talking_label"] = talking
	npc["icon_entry"]["talk"] = talking
	if npc.has("tag") and is_instance_valid(npc["tag"]):
		_name_labels.append({"node": npc["tag"], "owner": body})
	_update_npc_icon(npc)

func _add_ground_ring(parent: Node3D, radius: float, color: Color, kind: String = "") -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.6, radius * 2.6)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(0.0, 0.025, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = MARKER_RING_SHADER
	mat.set_shader_parameter("ring_color", color)
	mat.set_shader_parameter("inner_radius", 0.80)
	mat.set_shader_parameter("outer_radius", 0.95)
	mat.set_shader_parameter("softness", 0.04)
	mi.material_override = mat
	parent.add_child(mi)
	_marker_rings.append({
		"mesh": mi,
		"mat": mat,
		"owner": parent,
		"kind": kind,
		"phase": _rng.randf_range(0.0, TAU),
	})


func _add_state_icon(parent: Node3D, pos: Vector3) -> Dictionary:
	# D-1098/D-1105: ícone 3D extrudado, 1,00 m; a posição final é acima da placa.
	var icon = STATE_ICON.new()
	icon.name = "StateIcon"
	icon.setup(ICON_QUESTION, Color.WHITE)
	icon.position = pos
	parent.add_child(icon)
	var entry := {
		"sprite": icon,
		"base_y": pos.y,
		"phase": _rng.randf_range(0.0, TAU),
		"state": "",
		"pop": 0.0,
		"owner": parent,
	}
	_state_icons.append(entry)
	return entry

func _add_ally_name(f: Dictionary) -> void:
	var body: Node3D = f["node"]
	var height := float(f["height"])
	var model_id := str(f.get("model_id", ""))
	var display := str(FOLLOWER_NAMES.get(model_id, model_id.to_upper()))
	var tag := _spawn_nameplate(body, display, "ALLY", height + 0.65)
	_name_labels.append({"node": tag, "owner": body})


func _add_ally_talking(f: Dictionary) -> void:
	var body: Node3D = f["node"]
	var height := float(f["height"])
	var talk := Label3D.new()
	talk.text = "..."
	talk.font_size = 48
	talk.modulate = Color(1.0, 0.86, 0.45)
	talk.outline_size = 6
	talk.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	talk.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	talk.no_depth_test = false
	talk.position = Vector3(0.0, height + 1.65, 0.0)
	talk.layers = 1 << 6
	talk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	talk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talk.visible = false
	body.add_child(talk)
	f["talking_label"] = talk


func _update_enemy_marker() -> void:
	if _enemy_marker_root == null or _enemy_body == null:
		return
	if not is_instance_valid(_enemy_body):
		return
	_enemy_marker_root.global_position = _enemy_body.global_position
	_enemy_marker_root.visible = _enemy_body.visible
	_update_enemy_icon()
	_update_enemy_ring_color()


func _update_marker_rings(_delta: float) -> void:
	if _camera == null:
		return
	for i in range(_marker_rings.size() - 1, -1, -1):
		var entry := _marker_rings[i]
		var owner := entry["owner"] as Node3D
		var mesh := entry["mesh"] as MeshInstance3D
		if owner == null or not is_instance_valid(owner) or mesh == null or not is_instance_valid(mesh):
			_marker_rings.remove_at(i)
			continue
		var dist := _camera.global_position.distance_to(owner.global_position)
		mesh.visible = dist > 1.4
		if not mesh.visible:
			continue
		if str(entry.get("kind", "")) == "ally" and player != null:
			var to_owner := owner.global_position - player.global_position
			var to_cam := _camera.global_position - player.global_position
			if to_owner.length_squared() > 0.001 and to_cam.length_squared() > 0.001:
				var ang := rad_to_deg(acos(clampf(
					to_owner.normalized().dot(to_cam.normalized()), -1.0, 1.0)))
				if ang < 50.0:
					mesh.visible = false
					continue
		var fade := clampf(1.0 - (dist - 7.0) / 11.0, 0.22, 1.0)
		var pulse := 0.88 + 0.12 * sin(_time * 2.1 + float(entry["phase"]))
		var mat := entry["mat"] as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("alpha", fade * pulse)


func _update_state_icons(delta: float) -> void:
	for i in range(_state_icons.size() - 1, -1, -1):
		var entry := _state_icons[i]
		var icon := entry["sprite"] as Node3D
		if icon == null or not is_instance_valid(icon):
			_state_icons.remove_at(i)
			continue
		var pop := maxf(0.0, float(entry["pop"]) - delta * 4.0)
		entry["pop"] = pop
		var dist := 9.0
		if _camera != null:
			dist = _camera.global_position.distance_to(icon.global_position)
		# D-1098: ícones 3D ficam maiores também a média distância.
		var s := (1.0 + pop * 0.35) * clampf(0.55 + dist / 16.0, 0.55, 1.15)
		icon.scale = Vector3(s, s, s)
		var base := float(entry["base_y"])
		# D-1105: o ícone fica sempre acima do card atual; se o NPC fala,
		# fica acima do "..." também para não cobri-lo.
		var plate := entry.get("plate") as Node3D
		if plate != null and is_instance_valid(plate) and plate.has_method("card_top_local"):
			var top := float(plate.card_top_local())
			var min_bottom := top + 0.08
			var talk := entry.get("talk") as Node3D
			if talk != null and is_instance_valid(talk) and talk.visible:
				min_bottom = maxf(min_bottom, talk.position.y + 0.14)
			var mesh: Mesh = icon._front.mesh
			if mesh != null:
				var aabb := mesh.get_aabb()
				base = min_bottom - aabb.position.y * s
				entry["base_y"] = base
		icon.position.y = base \
			+ sin(_time * 2.4 + float(entry["phase"])) * 0.045 + pop * 0.15

func _update_name_labels() -> void:
	if _camera == null:
		return
	for i in range(_name_labels.size() - 1, -1, -1):
		var entry := _name_labels[i]
		var tag := entry.get("node") as Node3D
		var owner := entry["owner"] as Node3D
		if tag == null or not is_instance_valid(tag) or owner == null or not is_instance_valid(owner):
			_name_labels.remove_at(i)
			continue
		var dist := _camera.global_position.distance_to(tag.global_position)
		# D-1105: o card encolhe com a distância; a 9 m a tela fica na
		# metade do tamanho de 4 m. A base de 40% está no estilo do card.
		var s := clampf(0.5 + (dist - 4.0) * 0.0125, 0.4, 0.7)
		if tag.has_method("set_distance_scale"):
			tag.set_distance_scale(s)
		else:
			tag.scale = Vector3(s, s, s)

func _spawn_nameplate(parent: Node3D, text: String, role: String, y: float) -> Node3D:
	var plate = NAMEPLATE.new()
	plate.display_name = text
	plate.role_text = role
	plate.style_id = name_style
	plate.position = Vector3(0.0, y, 0.0)
	parent.add_child(plate)
	return plate as Node3D


## D-1094: troca o estilo das placas em tempo real (F6 no lab e captura A/B/C).
func set_name_style(style: String) -> void:
	if not ["unit_card", "move_strip", "expedition"].has(style):
		return
	name_style = style
	for entry in _name_labels:
		var node = entry.get("node")
		if node != null and is_instance_valid(node) and node.has_method("set_style"):
			node.set_style(style)


func _cycle_name_style() -> void:
	var order := ["unit_card", "move_strip", "expedition"]
	var idx := order.find(name_style)
	set_name_style(order[(idx + 1) % order.size()])


func _set_icon(entry: Dictionary, state: String, texture: Texture2D, tint: Color) -> void:
	if str(entry.get("state", "")) == state:
		return
	entry["state"] = state
	var icon = entry["sprite"]
	if icon == null:
		return
	if icon.has_method("set_state"):
		icon.set_state(texture, tint)
	entry["pop"] = 0.28


func _update_npc_icon(npc: Dictionary) -> void:
	var entry: Dictionary = npc.get("icon_entry", {})
	if entry.is_empty():
		return
	if bool(npc.get("talked", false)):
		_set_icon(entry, "talked", ICON_TALKED, Color(0.75, 1.0, 0.78))
	elif bool(npc.get("has_quest", false)):
		_set_icon(entry, "quest", ICON_QUESTION, Color(1.0, 0.82, 0.22))
	else:
		_set_icon(entry, "question", ICON_QUESTION, Color.WHITE)


func _update_talking_labels() -> void:
	var active_label: Label3D = null
	if _npc_talking and not _npc_talk_target.is_empty():
		if _dialogue_stage == 0:
			var label = _npc_talk_target.get("talking_label")
			if label is Label3D:
				active_label = label
		elif _dialogue_stage > 0 and _dialogue_stage <= _dialogue_reactions.size():
			var reaction: Dictionary = _dialogue_reactions[_dialogue_stage - 1]
			var label = reaction.get("talking_label")
			if label is Label3D:
				active_label = label
	for npc in _npcs:
		if npc.has("talking_label") and is_instance_valid(npc["talking_label"]):
			npc["talking_label"].visible = false
	for f in _followers:
		if f.has("talking_label") and is_instance_valid(f["talking_label"]):
			f["talking_label"].visible = false
	if active_label != null and is_instance_valid(active_label):
		active_label.visible = true
		var phase := int(_time * 3.0) % 3
		active_label.text = ".".repeat(phase + 1)


func _build_ally_reactions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _npc_talk_target.is_empty():
		return out
	var line_idx := int(_npc_talk_target.get("pool_idx", 0))
	for f in _followers:
		var model_id := str(f.get("model_id", ""))
		var nature := "hardy"
		if model_id == "pancham":
			nature = "brave"
		elif model_id == "dqt_orc":
			nature = "orc"
		var display := str(FOLLOWER_NAMES.get(model_id, model_id.to_upper()))
		var tint := Color(0.08, 0.08, 0.10)
		if model_id == "dqt_orc":
			tint = Color(0.18, 0.30, 0.16)
		out.append({
			"name": display,
			"text": ALLY_DIALOGUE.get_line(nature, line_idx),
			"portrait": _portrait_for_speaker(display),
			"tint": tint,
			"talking_label": f.get("talking_label"),
		})
	return out


func _show_dialogue_stage() -> void:
	if _npc_hud == null or _npc_talk_target.is_empty():
		return
	if _dialogue_stage == 0:
		var has_more := not _dialogue_reactions.is_empty()
		_npc_hud.open(str(_npc_talk_target["name"]), str(_npc_talk_target["dialogue"]),
			"NEXT" if has_more else "CLOSE")
		_npc_hud.set_portrait(_portrait_for_speaker(str(_npc_talk_target["name"])))
	else:
		if _dialogue_stage > _dialogue_reactions.size():
			return
		var reaction: Dictionary = _dialogue_reactions[_dialogue_stage - 1]
		var has_more := _dialogue_stage < _dialogue_reactions.size()
		if _dialogue_stage - 1 < _dialogue_banners.size():
			var banner: Control = _dialogue_banners[_dialogue_stage - 1]
			if banner != null:
				banner.open(str(reaction["name"]), str(reaction["text"]),
					reaction.get("portrait") as Texture2D,
					reaction.get("tint", Color(0.14, 0.23, 0.15)))
		_npc_hud.set_next_text("NEXT" if has_more else "CLOSE")
	_update_talking_labels()


func _npc_portrait(npc_name: String) -> Texture2D:
	return _portrait_for_speaker(npc_name)


func _circular_portrait(tex: Texture2D, region: Rect2) -> Texture2D:
	# D-1093: o recorte já sai circular; o AtlasTexture + shader de máscara
	# desalinhava e deixava o quadrado vazar do medalhão.
	var img := tex.get_image()
	if img == null:
		return tex
	var full := Rect2i(Vector2i.ZERO, img.get_size())
	var px := Rect2i(
		int(region.position.x * img.get_width()),
		int(region.position.y * img.get_height()),
		int(region.size.x * img.get_width()),
		int(region.size.y * img.get_height()))
	px = px.intersection(full)
	if px.size.x < 2 or px.size.y < 2:
		return tex
	var face := img.get_region(px)
	face.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	# D-1095: o fundo do medalhão é cozido em dourado e o RGB de fora do
	# círculo também fica dourado. Antes o transparente era preto e a borda
	# da máscara puxava a "borda interna marrom" entre o fundo e o retrato.
	var brown := Color(92.0 / 255.0, 60.0 / 255.0, 30.0 / 255.0, 1.0)
	var canvas := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
	canvas.fill(brown)
	canvas.blend_rect(face, Rect2i(0, 0, 256, 256), Vector2i.ZERO)
	var center := Vector2(127.5, 127.5)
	var radius := 124.0
	for y in 256:
		for x in 256:
			var d := Vector2(float(x), float(y)).distance_to(center)
			var a := clampf((radius - d) / 1.5, 0.0, 1.0)
			if a >= 0.999:
				continue
			var c := canvas.get_pixel(x, y)
			c.a = a
			canvas.set_pixel(x, y, c)
	return ImageTexture.create_from_image(canvas)


func _portrait_for_speaker(speaker: String) -> Texture2D:
	var key := speaker.to_lower()
	# D-1095: ícone fechado do Bulbasaur, já mascarado e com o fundo do medalhão.
	var baked := "res://assets/ui/portraits/%s.png" % key
	if ResourceLoader.exists(baked):
		return load(baked) as Texture2D
	var sugimori := "res://sugimori/por_nome/%s.png" % key
	if ResourceLoader.exists(sugimori):
		var tex := load(sugimori) as Texture2D
		if tex == null:
			return null
		if PORTRAIT_FACE_REGIONS.has(key):
			return _circular_portrait(tex, PORTRAIT_FACE_REGIONS[key])
		return tex
	var portrait := "res://personagens/portraits/%s.png" % key
	if ResourceLoader.exists(portrait):
		return load(portrait) as Texture2D
	return null


func _update_enemy_ring_color() -> void:
	if _enemy_ring_entry.is_empty():
		return
	var mesh := _enemy_ring_entry.get("mesh") as MeshInstance3D
	if mesh == null or not is_instance_valid(mesh):
		return
	var mat := _enemy_ring_entry.get("mat") as ShaderMaterial
	if mat == null:
		return
	var wants_talk := false
	if _enemy_body != null and is_instance_valid(_enemy_body):
		wants_talk = bool(_enemy_body.get_meta("wants_to_talk", false))
	var color: Color
	if _enemy_alert_timer > 0.0:
		color = Color(1.0, 0.82, 0.15, 0.85)  # alerta (!)
	elif wants_talk or _enemy_state == EnemyState.FLEE:
		color = Color(0.22, 0.48, 1.0, 0.78)  # fugindo ou quer conversar
	elif _enemy_state == EnemyState.CHASE:
		color = Color(0.95, 0.15, 0.15, 0.80)  # indo atrás de você
	elif _enemy_state == EnemyState.SEARCH:
		color = Color(1.0, 0.82, 0.15, 0.85)  # procurando
	else:
		color = Color(1.0, 0.62, 0.15, 0.45)  # patrulha/return: âmbar
	mat.set_shader_parameter("ring_color", color)


func _update_enemy_icon() -> void:
	if _enemy_icon_entry.is_empty():
		return
	var sprite := _enemy_icon_entry["sprite"] as Sprite3D
	if sprite == null:
		return
	var state := "none"
	var tex: Texture2D = null
	var tint := Color.WHITE
	if _enemy_alert_timer > 0.0:
		state = "alert"
		tex = ICON_ALERT
		tint = Color(1.0, 0.85, 0.25)
	elif _enemy_state == EnemyState.CHASE:
		state = "anger"
		tex = ICON_ANGER
		tint = Color(1.0, 0.45, 0.35)
	elif _enemy_state == EnemyState.FLEE:
		state = "sweat"
		tex = ICON_SWEAT
		tint = Color(0.55, 0.85, 1.0)
	elif _enemy_state == EnemyState.SEARCH:
		state = "search"
		tex = ICON_QUESTION
		tint = Color(1.0, 0.45, 0.45)
	if tex == null:
		sprite.visible = false
		_enemy_icon_entry["state"] = "none"
		return
	sprite.visible = true
	_set_icon(_enemy_icon_entry, state, tex, tint)


func cycle_npcs(new_offset: int) -> void:
	_npc_offset = posmod(new_offset, NPC_POOL.size())
	if _npc_prompt != null:
		_npc_prompt.hide_prompt()
	_close_npc_dialogue()
	for npc in _npcs:
		var node: Node3D = npc["node"]
		if is_instance_valid(node):
			node.queue_free()
	_npcs.clear()
	# Remove marcadores antigos de NPC no mini-mapa.
	for i in range(_minimap_markers.size() - 1, -1, -1):
		if _minimap_markers[i]["kind"] == "npc":
			var rect: Control = _minimap_markers[i]["rect"]
			if is_instance_valid(rect):
				rect.queue_free()
			_minimap_markers.remove_at(i)
	for slot_i in NPC_SLOTS.size():
		var pool_idx := (_npc_offset + slot_i) % NPC_POOL.size()
		_spawn_npc_at_slot(slot_i, pool_idx)
	for npc in _npcs:
		var node: Node3D = npc["node"]
		_apply_toon(node)
		_set_layers(node, 1 << 6)
		_decorate_npc(npc)
		if _marker_root != null:
			_add_minimap_marker(node, Color(1.0, 1.0, 1.0, 1.0), "npc")


func _build_npc_dialogue_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 22
	_npc_dialogue_panel = PanelContainer.new()
	_npc_dialogue_panel.position = Vector2(260, 540)
	_npc_dialogue_panel.custom_minimum_size = Vector2(760, 108)
	_npc_dialogue_panel.visible = false
	_npc_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.04, 0.92)
	style.border_color = Color(0.65, 0.88, 0.68, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_npc_dialogue_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_dialogue_panel.add_child(vbox)

	_npc_dialogue_title = Label.new()
	_npc_dialogue_title.text = "NPC"
	_npc_dialogue_title.add_theme_font_size_override("font_size", 17)
	_npc_dialogue_title.add_theme_color_override("font_color", Color(0.75, 1.0, 0.72))
	_npc_dialogue_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_npc_dialogue_title)

	_npc_dialogue_text = Label.new()
	_npc_dialogue_text.text = ""
	_npc_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_npc_dialogue_text.custom_minimum_size = Vector2(720, 52)
	_npc_dialogue_text.add_theme_font_size_override("font_size", 15)
	_npc_dialogue_text.add_theme_color_override("font_color", Color(0.95, 0.94, 0.88))
	_npc_dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_npc_dialogue_text)

	layer.add_child(_npc_dialogue_panel)

	# D-1085: prompt torto [Z] TALK, separado do prompt da porta.
	_npc_prompt = NPC_PROMPT.new()
	layer.add_child(_npc_prompt)
	_npc_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_npc_prompt.offset_left = -190.0
	_npc_prompt.offset_top = -68.0
	_npc_prompt.offset_right = 190.0
	_npc_prompt.offset_bottom = -10.0
	_npc_prompt.visible = false

	# D-1090: HUD C (Paper/RPG) no diálogo real; A/B ficam no lab de protótipos.
	_npc_hud = NPC_HUD.new()
	layer.add_child(_npc_hud)
	_npc_hud.setup(2)
	_npc_hud.close()

	# D-1092: uma faixa lateral por aliado, acima do card do NPC.
	_battle_hud = get_node_or_null("ExplorationBattleHud")
	for i in _followers.size():
		var banner = ALLY_BANNER.new()
		banner.name = "AllyBanner%d" % i
		layer.add_child(banner)
		banner.setup(i)
		banner.close()
		_dialogue_banners.append(banner)
	add_child(layer)


func _close_npc_dialogue() -> void:
	_npc_talking = false
	_dialogue_stage = 0
	_dialogue_reactions.clear()
	if _npc_dialogue_panel != null:
		_npc_dialogue_panel.visible = false
	if _npc_hud != null:
		_npc_hud.close()
	for banner in _dialogue_banners:
		if banner != null:
			banner.close()
	clear_dialogue_focus()
	if _battle_hud != null:
		_battle_hud.set_dialogue_open(false)
	_update_talking_labels()


func _update_npcs(delta: float) -> void:
	if player == null:
		return
	var nearest_npc: Dictionary = {}
	var nearest_dist := INF
	for npc in _npcs:
		var body: Node3D = npc["node"]
		if not is_instance_valid(body):
			continue
		_update_npc_icon(npc)
		var talking_now: bool = _npc_talking and _dialogue_stage == 0 and _npc_talk_target.get("node") == body
		if npc.has("talking_label") and is_instance_valid(npc["talking_label"]):
			npc["talking_label"].visible = talking_now
		var icon_sprite = npc.get("icon_entry", {}).get("sprite")
		if icon_sprite != null and is_instance_valid(icon_sprite):
			icon_sprite.visible = not talking_now
		_play_idle(npc["ap"])
		var to_player := player.global_position - body.global_position
		to_player.y = 0.0
		var dist := to_player.length()
		if dist < NPC_LOOK_RADIUS and dist > 0.05:
			var target_yaw := atan2(to_player.x, to_player.z)
			body.rotation.y = lerp_angle(body.rotation.y, target_yaw, clampf(delta * 6.5, 0.0, 1.0))
		else:
			body.rotation.y = lerp_angle(body.rotation.y, float(npc["base_yaw"]), clampf(delta * 3.0, 0.0, 1.0))
		if dist < NPC_INTERACT_RADIUS and dist < nearest_dist:
			nearest_dist = dist
			nearest_npc = npc

	var interact_now := Input.is_action_pressed("lab_interact")
	var interact_just := interact_now and not _interact_prev
	_interact_prev = interact_now

	if nearest_npc.is_empty():
		if _npc_prompt != null:
			_npc_prompt.hide_prompt()
		_close_npc_dialogue()
		return

	# Jogador perto de um NPC: prompt [Z] TALK; a porta tem o prompt dela.
	if _door_near or _npc_talking:
		if _npc_prompt != null:
			_npc_prompt.hide_prompt()
	elif _npc_prompt != null:
		_npc_prompt.show_prompt(str(nearest_npc["name"]), "TALK")
	if interact_just and not _door_near:
		if _npc_talking and _npc_talk_target.get("node") == nearest_npc.get("node"):
			if _npc_hud != null and _npc_hud.is_typing():
				_npc_hud.finish_typing()
			elif _dialogue_stage < _dialogue_reactions.size():
				_dialogue_stage += 1
				_show_dialogue_stage()
			else:
				_close_npc_dialogue()
		else:
			_npc_talking = true
			_npc_talk_target = nearest_npc
			nearest_npc["talked"] = true
			_update_npc_icon(nearest_npc)
			_dialogue_stage = 0
			_dialogue_reactions = _build_ally_reactions()
			_show_dialogue_stage()
			set_dialogue_focus(nearest_npc["node"] as Node3D)
			if _battle_hud != null:
				_battle_hud.set_dialogue_open(true)


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
	# Os marcadores são bolinhas de UI (sem textura): azul, branco e vermelho.
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

	_add_minimap_marker(player, Color(0.25, 0.55, 1.0, 1.0), "player")
	for f in _followers:
		_add_minimap_marker(f["node"], Color(0.25, 0.55, 1.0, 1.0), "ally")
	if _enemy_body != null:
		_add_minimap_marker(_enemy_body, Color(1.0, 0.22, 0.18, 1.0), "enemy")
	for node in get_tree().get_nodes_in_group("minimap_npc"):
		if node is Node3D:
			_add_minimap_marker(node, Color(1.0, 1.0, 1.0, 1.0), "npc")


func _add_minimap_marker(node: Node3D, color: Color, kind: String) -> void:
	var dot_size := 10.0
	match kind:
		"player":
			dot_size = 12.0
		"ally":
			dot_size = 8.0
		"npc":
			dot_size = 10.0
		_:
			dot_size = 10.0
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(dot_size, dot_size)
	dot.size = Vector2(dot_size, dot_size)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.02, 0.01, 0.02, 0.90)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var radius := int(dot_size * 0.5)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	dot.add_theme_stylebox_override("panel", style)
	match kind:
		"player":
			dot.z_index = 4
		"ally":
			dot.z_index = 3
		"npc":
			dot.z_index = 2
		_:
			dot.z_index = 1
	_marker_root.add_child(dot)
	dot.size = Vector2(dot_size, dot_size)
	_minimap_markers.append({
		"node": node,
		"rect": dot,
		"size": dot_size,
		"kind": kind,
	})


func _build_hud_badges() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(14, 76)
	vbox.size = Vector2(250, 260)
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vbox)
	# HP/MP demo: o lab não tem combate; a HUD final deve ler GameState.party.
	var badges := [
		["ABRA", 86, 100, 14, 20, false],
		["PANCHAM", 100, 100, 10, 20, true],
		["ORC", 46, 100, 8, 20, true],
	]
	for data in badges:
		vbox.add_child(_make_hud_badge(str(data[0]), int(data[1]), int(data[2]), int(data[3]), int(data[4]), bool(data[5])))
	_build_enemy_alert(layer)
	add_child(layer)


func _build_enemy_alert(layer: CanvasLayer) -> void:
	_enemy_alert = PanelContainer.new()
	_enemy_alert.custom_minimum_size = Vector2(42, 42)
	_enemy_alert.position = Vector2(760, 16)
	_enemy_alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_alert.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.02, 0.02, 0.88)
	style.border_color = Color(1.0, 0.25, 0.18, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_enemy_alert.add_theme_stylebox_override("panel", style)
	var bang := Label.new()
	bang.text = "!"
	bang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bang.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bang.add_theme_font_size_override("font_size", 26)
	bang.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	bang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_alert.add_child(bang)
	layer.add_child(_enemy_alert)


func _make_hud_badge(character_name: String, hp: int, max_hp: int, mp: int, max_mp: int, is_ally: bool) -> PanelContainer:
	var ratio := float(hp) / float(max_hp)
	var color := _hp_color(ratio)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 70)
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
	accent.custom_minimum_size = Vector2(4, 56)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 1)
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
	bar.custom_minimum_size = Vector2(140, 9)
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

	var mp_row := HBoxContainer.new()
	mp_row.add_theme_constant_override("separation", 6)
	mp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(mp_row)
	var mp_color := Color(0.35, 0.65, 1.0)
	var mp_bar := ProgressBar.new()
	mp_bar.min_value = 0.0
	mp_bar.max_value = float(max_mp)
	mp_bar.value = float(mp)
	mp_bar.show_percentage = false
	mp_bar.custom_minimum_size = Vector2(140, 7)
	mp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mp_bg := StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.05, 0.06, 0.09, 0.95)
	mp_bg.corner_radius_top_left = 2
	mp_bg.corner_radius_top_right = 2
	mp_bg.corner_radius_bottom_left = 2
	mp_bg.corner_radius_bottom_right = 2
	var mp_fill := StyleBoxFlat.new()
	mp_fill.bg_color = mp_color
	mp_fill.corner_radius_top_left = 2
	mp_fill.corner_radius_top_right = 2
	mp_fill.corner_radius_bottom_left = 2
	mp_fill.corner_radius_bottom_right = 2
	mp_bar.add_theme_stylebox_override("background", mp_bg)
	mp_bar.add_theme_stylebox_override("fill", mp_fill)
	mp_row.add_child(mp_bar)
	var mp_label := Label.new()
	mp_label.text = "%d / %d" % [mp, max_mp]
	mp_label.add_theme_font_size_override("font_size", 9)
	mp_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.92))
	mp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_row.add_child(mp_label)

	_hud_badges.append({
		"panel": panel,
		"bar": bar,
		"hp_label": hp_label,
		"mp_bar": mp_bar,
		"mp_label": mp_label,
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
	if _enemy_alert != null:
		_enemy_alert.visible = _enemy_state == EnemyState.CHASE
		if _enemy_alert.visible:
			_enemy_alert.modulate.a = 0.72 + 0.28 * sin(_time * 6.0)


func _update_minimap() -> void:
	if _minimap_camera == null or _minimap_rect == null or player == null:
		return
	_minimap_camera.global_position = player.global_position + Vector3(0.0, 30.0, 0.0)
	var vp := Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	var rect_size := _marker_root.size
	for m in _minimap_markers:
		var rect: Control = m["rect"]
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
	for npc in _npcs:
		_set_layers(npc["node"], 1 << 6)


func _set_layers(root: Node, layer: int) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = layer
	for particles in root.find_children("*", "CPUParticles3D", true, false):
		(particles as CPUParticles3D).layers = layer
	for label in root.find_children("*", "Label3D", true, false):
		(label as Label3D).layers = layer
