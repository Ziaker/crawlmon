extends "res://scripts/debug/third_person_3d_lab.gd"
## Crawlmon 3D hub prototype (isolated single scene).
##
## Reuses the third-person camera, followers, shadows and toon look of the
## overworld labs (D-1023/D-1028) and builds a compact ~28 m x 26 m Central
## Plaza with an Expedition Gate, a Guild Hall and two marked expansion plots.
##
## No game rule is invented here: no prices, economy, healing, save/load,
## expedition start or campaign progression. The gate panel, nature roll preview
## and guild Standby Roster are read-only prototypes.
##
## CLI (after `--`): --player=<species_id> --leader=<species_id> --party
##                  --lighting=<dusk|day|night> --weather=<auto|clear|rain|storm>
##                  --scenario=<id> --summary-json --shot=<path> --screenshot=<path>
##                  --view=<id> --quit
## Hotkeys: [1] Followers · [F6] Swap Leader · [F7] Lighting · [E/Z] Interact
## Scenarios: HUB_BOOT HUB_NAVIGATION HUB_INTERACTION HUB_GATE HUB_GUILD
##            HUB_CAMERA HUB_STATE HUB_LIVING HUB_ATMOSPHERE

const NPC_PROMPT := preload("res://scripts/debug/overworld_prompt.gd")
const NPC_HUD := preload("res://scripts/debug/dialogue_hud_styles.gd")
const NAMEPLATE := preload("res://scripts/debug/floating_nameplate.gd")
const STATE_ICON := preload("res://scripts/debug/overworld_state_icon.gd")
const PORTRAIT_ICON := preload("res://scripts/ui/portrait_icon.gd")
const STATUS_SCREEN := preload("res://scripts/ui/status_screen.gd")
const NATURE_DATA := preload("res://scripts/data/nature_data.gd")
const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameViewModals = preload("res://scripts/ui/pre_game/pre_game_view_modals.gd")
const WALL_SHADER := preload("res://shaders/wall_palisade_blend.gdshader")
const ICON_ALERT := preload("res://assets/ui/overworld_icons/state_alert.png")
const ICON_QUESTION := preload("res://assets/ui/overworld_icons/state_question.png")
const ICON_TALKED := preload("res://assets/ui/overworld_icons/state_talked.png")
const WALL_TEXTURES := {
	"stone": preload("res://assets/textures/walls/murky_wall_mossy_stone.png"),
	"slate": preload("res://assets/textures/walls/murky_wall_slate_cracks.png"),
	"bark": preload("res://assets/textures/walls/murky_wall_bark_roots.png"),
	"palisade": preload("res://assets/textures/walls/murky_wall_root_palisade.png"),
}

const PLAYABLE_LEADERS := ["abra", "pancham", "gible", "dqt_slime", "dqt_orc", "dqt_cyclops"]
const LIGHTING_MODES := ["dusk", "day", "night"]

## Lab heights (metres). Not game rules (D-1023).
const HUB_HEIGHTS := {
	"abra": 1.0,
	"pancham": 0.7,
	"gible": 0.85,
	"dqt_slime": 0.90,
	"dqt_orc": 2.1,
	"dqt_cyclops": 2.2,
	"bulbasaur": 0.78,
	"pikachu": 0.72,
	"squirtle": 0.72,
	"charmander": 0.78,
	"eevee": 0.62,
	"dqt_healslime": 1.15,
}
const HUB_NAMES := {
	"abra": "ABRA",
	"pancham": "PANCHAM",
	"gible": "GIBLE",
	"dqt_slime": "SLIME",
	"dqt_orc": "ORC",
	"dqt_cyclops": "CYCLOPS",
	"bulbasaur": "BULBASAUR",
	"pikachu": "PIKACHU",
	"squirtle": "SQUIRTLE",
	"charmander": "CHARMANDER",
	"eevee": "EEVEE",
	"dqt_healslime": "HEAL SLIME",
}

const PLAYER_START := Vector3(0.0, 0.0, 4.0)
const PLAZA_HALF_X := 14.0
const PLAZA_HALF_Z := 13.0
const PLAZA_WALL_HEIGHT := 3.2

const GATE_POS := Vector3(0.0, 0.0, -11.0)
const BOARD_POS := Vector3(-3.2, 0.0, -9.5)
const GUILD_POS := Vector3(-10.5, 0.0, -2.0)
const PLOT_EAST := Vector3(10.5, 0.0, -2.0)
const PLOT_SOUTHEAST := Vector3(8.0, 0.0, 6.5)

const GATE_RADIUS := 3.0
const GUILD_RADIUS := 3.0
const PLOT_RADIUS := 2.8
const NPC_RADIUS := 2.4
const NPC_COLLISION_LAYER := 1 << 4
const MINIMAP_MASK := 1 << 4
const MINIMAP_SIZE := 124
const MINIMAP_DISPLAY_SIZE := 124
const MINIMAP_WORLD_SIZE := 32.0

const GATE_LINES := [
	"MURKY FOREST — 5 FLOORS (AUTHORIZED)",
	"LIMESTONE CAVERN — LOCKED — PROTOTYPE",
	"TEMPORAL SPIRE — LOCKED — PROTOTYPE",
]

const GUILD_OPTIONS := [
	"INSPECT ACTIVE PARTY (STATUS SCREEN)",
	"STANDBY ROSTER & SERVICES [DEMO PREVIEW]",
	"CLOSE",
]

const HUB_NPC_SPECS := [
	{
		"id": "bulbasaur", "role": "SCOUT", "pos": Vector3(-4.0, 0.0, -3.0),
		"yaw": 0.45, "icon": "question", "patrol": true,
		"line": "[PROTOTYPE] Central Plaza links the north Expedition Gate, west Guild Hall, and two eastern expansion plots.",
	},
	{
		"id": "pikachu", "role": "GUILD CLERK", "pos": Vector3(-7.2, 0.0, -4.5),
		"yaw": 0.85, "icon": "alert", "patrol": false,
		"line": "[PROTOTYPE] Step up to the Guild Desk to open the Guild Hall menu or inspect your active party StatusScreen.",
	},
	{
		"id": "squirtle", "role": "GATE WARDEN", "pos": Vector3(3.4, 0.0, -8.8),
		"yaw": -0.45, "icon": "alert", "patrol": false,
		"line": "[PROTOTYPE] Murky Forest (5 floors) is the authorized gate route. Expedition Nature is rolled only on departure (R18-Q4).",
	},
	{
		"id": "charmander", "role": "EXPLORER", "pos": Vector3(4.0, 0.0, -3.0),
		"yaw": -0.60, "icon": "question", "patrol": true,
		"line": "[PROTOTYPE] Eastern Plots A and B are empty on purpose. Inspect either marker to preview reserved expansion areas.",
	},
	{
		"id": "eevee", "role": "CHRONICLER", "pos": Vector3(2.8, 0.0, 3.2),
		"yaw": -2.40, "icon": "question", "patrol": true,
		"line": "[PROTOTYPE] Press 1 for party followers, F6 to cycle all 6 playable leaders, and F7 to switch lighting presets.",
	},
	{
		"id": "dqt_healslime", "role": "CARETAKER", "pos": Vector3(-4.8, 0.0, 4.4),
		"yaw": 2.30, "icon": "question", "patrol": true,
		"line": "[PROTOTYPE] Dusk, Day, and Night presets retune skylights without full-screen flashes (D-418).",
	},
]

const LIGHTING_PRESETS := {
	"dusk": {
		"label": "WARM DUSK SANCTUARY",
		"bg": Color(0.036, 0.026, 0.028),
		"ambient": Color(0.32, 0.24, 0.22),
		"ambient_e": 0.48,
		"fog": Color(0.09, 0.06, 0.05),
		"fog_d": 0.011,
		"dir": Color(0.95, 0.72, 0.52),
		"dir_e": 0.34,
		"lamp_mult": 1.0,
		"spot_mult": 1.0,
	},
	"day": {
		"label": "OVERCAST DAYLIGHT",
		"bg": Color(0.18, 0.20, 0.22),
		"ambient": Color(0.56, 0.52, 0.46),
		"ambient_e": 0.86,
		"fog": Color(0.22, 0.21, 0.19),
		"fog_d": 0.005,
		"dir": Color(1.0, 0.94, 0.82),
		"dir_e": 0.92,
		"lamp_mult": 0.45,
		"spot_mult": 1.35,
	},
	"night": {
		"label": "VELVET NIGHT",
		"bg": Color(0.018, 0.014, 0.020),
		"ambient": Color(0.18, 0.14, 0.16),
		"ambient_e": 0.26,
		"fog": Color(0.04, 0.03, 0.04),
		"fog_d": 0.015,
		"dir": Color(0.76, 0.56, 0.44),
		"dir_e": 0.16,
		"lamp_mult": 1.35,
		"spot_mult": 0.70,
	},
}

@export_enum("auto", "clear", "rain", "storm") var weather_mode := "auto"
@export_enum("dusk", "day", "night") var lighting_mode := "dusk"

var _args: Dictionary = {}
var _scenario := ""
var _view := ""
var _checks: Array[Dictionary] = []
var _scenario_done := false
var _run_started_ms := 0
var _shot_path := ""
var _arrival: HubArrivalCutscene = null
var _ui_layer: CanvasLayer
var _panel_layer: CanvasLayer
var _help_layer: CanvasLayer
var _minimap_layer: CanvasLayer
var _minimap_viewport: SubViewport
var _minimap_camera: Camera3D
var _minimap_rect: TextureRect
var _marker_root: Control
var _minimap_markers: Array[Dictionary] = []
var _npc_prompt: Control
var _npc_hud: Control
var _status: StatusScreen
var _gate_panel: Control
var _gate_row_boxes: Array[PanelContainer] = []
var _gate_row_labels: Array[Label] = []
var _gate_row_buttons: Array[Button] = []
var _gate_index := 0
var _gate_open := false
var _gate_leader_name_lbl: Label
var _gate_leader_portrait: TextureRect
var _gate_nature_lbl: Label
var _gate_brief_lbl: Label
var _preview_nature_index := 0
var _guild_panel: Control
var _guild_row_boxes: Array[PanelContainer] = []
var _guild_row_labels: Array[Button] = []
var _guild_detail_lbl: Label
var _guild_index := 0
var _guild_open := false
var _status_open := false
var _ui_open := false
var _npc_talking := false
var _npc_target: Dictionary = {}
var _active_target_id := ""
var _active_target_kind := ""
var _npcs: Array[Dictionary] = []
var _name_labels: Array[Dictionary] = []
var _state_icons: Array[Dictionary] = []
var _foliage_fade: Array[Dictionary] = []
var _plot_markers: Array[Node3D] = []
var _lighting_lamps: Array[Dictionary] = []
var _gate_root: Node3D
var _guild_root: Node3D
var _party_for_status: Array[Combatant] = []
var _demo_party: Array[Combatant] = []
var _auto_nav_target := Vector3.INF
var _last_interact := false
var _last_z := false
var _hud_help_mode_label: Label
var _rng := RandomNumberGenerator.new()
# Dynamic atmosphere state (structural hooks only; no game rules).
var _atmo_time := 0.0
var _wind_strength := 0.35
var _wind_dir := Vector2(0.85, 0.52).normalized()
var _rain_intensity := 0.25
var _clarity := 0.85
var _cavern_fill_light: DirectionalLight3D
var _world_env_ref: WorldEnvironment
var _skylight_spots: Array[Dictionary] = []
var _shaft_mats: Array[ShaderMaterial] = []
var _wind_mats: Array[ShaderMaterial] = []
var _wet_mats: Array[ShaderMaterial] = []
var _rain_particles: Node = null
var _splash_particles: Node = null
var _wind_particles: Node = null


func _ready() -> void:
	_rng.randomize()
	_parse_cli()
	if str(_args.get("seed", "")).is_valid_int():
		_rng.seed = int(str(_args["seed"]))
	elif _scenario != "" or _view != "":
		_rng.seed = 20261114
	if _args.has("party"):
		start_party = true
	_resolve_player_species()
	super()
	if _camera != null:
		_camera.cull_mask = 0xFFFFFFFF & ~MINIMAP_MASK
	_build_npcs()
	_apply_toon_to_actor(player)
	for f in _followers:
		_apply_toon_to_actor(f["node"])
	_build_minimap_map()
	_build_minimap()
	_build_ui()
	_build_hud_help()
	_build_demo_party()
	_apply_lighting_preset(lighting_mode)
	_sync_hud_visibility()
	set_process_unhandled_input(true)
	_start_arrival_cutscene()
	if _scenario != "" or _view != "" or _args.has("quit"):
		_run_async()


func _process(delta: float) -> void:
	super(delta)
	_update_atmosphere(delta)
	_update_foliage_fade(delta)
	_update_name_labels()
	_update_state_icons(delta)
	_update_minimap()
	_sync_hud_visibility()


# --- CLI ---------------------------------------------------------------------

func _parse_cli() -> void:
	var all: Array[String] = []
	all.append_array(OS.get_cmdline_args())
	all.append_array(OS.get_cmdline_user_args())
	for a in all:
		if not a.begins_with("--"):
			continue
		var kv := a.substr(2).split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	_scenario = str(_args.get("scenario", "")).to_upper()
	_view = str(_args.get("view", ""))
	_shot_path = str(_args.get("shot", _args.get("screenshot", "")))
	var w := str(_args.get("weather", "auto")).to_lower()
	if w in ["auto", "clear", "rain", "storm"]:
		weather_mode = w
	var l := str(_args.get("lighting", "dusk")).to_lower()
	if LIGHTING_PRESETS.has(l):
		lighting_mode = l


func _resolve_player_species() -> void:
	var cli := str(_args.get("leader", _args.get("player", "")))
	if cli != "":
		player_species = cli.to_lower()
	elif GameState.party.size() > 0:
		var key := GameState.species_key(GameState.party[0])
		if HUB_HEIGHTS.has(key):
			player_species = key
	player_species = player_species.to_lower()
	if not HUB_HEIGHTS.has(player_species):
		player_species = "abra"
	player_model_id = player_species


# --- Environment & Lighting Presets (H1; zero full-screen flash D-418) -------

func _build_environment() -> void:
	var preset: Dictionary = LIGHTING_PRESETS.get(lighting_mode, LIGHTING_PRESETS["dusk"])
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = preset["bg"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = preset["ambient"]
	env.ambient_light_energy = float(preset["ambient_e"])
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.02
	env.fog_enabled = true
	env.fog_light_color = preset["fog"]
	env.fog_density = float(preset["fog_d"])
	env.glow_enabled = true
	env.glow_intensity = 0.42
	env.glow_bloom = 0.06
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 1.02
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_world_env_ref = we

	# Subtle angled fill so cavern walls and silhouettes stay legible.
	var cavern_fill := DirectionalLight3D.new()
	cavern_fill.rotation_degrees = Vector3(-58.0, -40.0, 0.0)
	cavern_fill.light_color = preset["dir"]
	cavern_fill.light_energy = float(preset["dir_e"])
	cavern_fill.shadow_enabled = true
	cavern_fill.shadow_opacity = 0.65
	cavern_fill.directional_shadow_max_distance = 46.0
	add_child(cavern_fill)
	_cavern_fill_light = cavern_fill

	# Warm local bounce around the main landmarks (no blue lights; D-1023).
	for data in [
		[Vector3(-9.2, 2.8, -2.0), Color(1.0, 0.68, 0.36), 0.58, 10.0],
		[Vector3(0.0, 3.0, -10.2), Color(1.0, 0.64, 0.30), 0.62, 10.5],
	]:
		var lamp := OmniLight3D.new()
		lamp.position = data[0]
		lamp.light_color = data[1]
		lamp.light_energy = float(data[2])
		lamp.omni_range = float(data[3])
		add_child(lamp)
		_lighting_lamps.append({"light": lamp, "base": float(data[2])})


func _apply_lighting_preset(mode: String) -> void:
	var key := mode.to_lower()
	if not LIGHTING_PRESETS.has(key):
		key = "dusk"
	lighting_mode = key
	var preset: Dictionary = LIGHTING_PRESETS[key]
	if _world_env_ref != null and is_instance_valid(_world_env_ref) and _world_env_ref.environment != null:
		var env := _world_env_ref.environment
		env.background_color = preset["bg"]
		env.ambient_light_color = preset["ambient"]
		env.ambient_light_energy = float(preset["ambient_e"])
		env.fog_light_color = preset["fog"]
		env.fog_density = float(preset["fog_d"])
	if _cavern_fill_light != null and is_instance_valid(_cavern_fill_light):
		_cavern_fill_light.light_color = preset["dir"]
		_cavern_fill_light.light_energy = float(preset["dir_e"]) * _clarity
	var lamp_mult := float(preset["lamp_mult"])
	for entry in _lighting_lamps:
		var lamp := entry.get("light") as OmniLight3D
		if lamp != null and is_instance_valid(lamp):
			lamp.light_energy = float(entry.get("base", 0.5)) * lamp_mult
	var spot_mult := float(preset["spot_mult"])
	for entry in _skylight_spots:
		var spot := entry.get("light") as SpotLight3D
		if spot != null and is_instance_valid(spot):
			spot.light_energy = float(entry.get("base_energy", 0.0)) * spot_mult * _clarity
	_refresh_hud_help_label()


func _cycle_lighting() -> void:
	var idx := LIGHTING_MODES.find(lighting_mode)
	var next: String = str(LIGHTING_MODES[(idx + 1) % LIGHTING_MODES.size()])
	_apply_lighting_preset(next)


func _refresh_hud_help_label() -> void:
	if _hud_help_mode_label == null or not is_instance_valid(_hud_help_mode_label):
		return
	var preset: Dictionary = LIGHTING_PRESETS.get(lighting_mode, LIGHTING_PRESETS["dusk"])
	var leader_name := str(HUB_NAMES.get(player_model_id, player_model_id.to_upper()))
	_hud_help_mode_label.text = "LEADER: %s  |  LIGHT: %s  |  PARTY: %s" % [
		leader_name, str(preset.get("label", lighting_mode.to_upper())), "ON" if _party_visible else "SOLO"
	]


func _update_atmosphere(delta: float) -> void:
	_atmo_time += delta
	var preset: Dictionary = LIGHTING_PRESETS.get(lighting_mode, LIGHTING_PRESETS["dusk"])
	var wind := _wind_strength
	var rain := _rain_intensity
	var clarity := _clarity
	match weather_mode:
		"clear":
			wind = 0.25 + 0.1 * sin(_atmo_time * 0.7)
			rain = 0.0
			clarity = 1.05 + 0.08 * sin(_atmo_time * 0.4)
		"rain":
			wind = 0.55 + 0.18 * sin(_atmo_time * 1.1)
			rain = 0.75
			clarity = 0.62 + 0.10 * sin(_atmo_time * 0.5)
		"storm":
			wind = 0.90 + 0.25 * sin(_atmo_time * 1.8)
			rain = 1.0
			clarity = 0.42 + 0.12 * sin(_atmo_time * 0.8)
		_:
			var burst := 0.5 + 0.5 * sin(_atmo_time * 0.18)
			rain = lerpf(0.0, 0.85, clampf(burst * 1.15, 0.0, 1.0))
			wind = lerpf(0.22, 0.85, 0.5 + 0.5 * sin(_atmo_time * 0.23 + 1.1))
			clarity = lerpf(0.50, 1.08, 0.5 + 0.5 * sin(_atmo_time * 0.16 - 0.6))
	_wind_strength = clampf(wind, 0.0, 1.2)
	_rain_intensity = clampf(rain, 0.0, 1.0)
	_clarity = clampf(clarity, 0.0, 1.2)
	var k := clampf((_clarity - 0.35) / 0.8, 0.0, 1.0)
	if _cavern_fill_light != null and is_instance_valid(_cavern_fill_light):
		_cavern_fill_light.light_energy = float(preset["dir_e"]) * _clarity
	if _world_env_ref != null and is_instance_valid(_world_env_ref) and _world_env_ref.environment != null:
		var env := _world_env_ref.environment
		env.ambient_light_energy = float(preset["ambient_e"]) * lerpf(0.65, 1.12, k)
		env.fog_density = float(preset["fog_d"]) * lerpf(1.35, 0.78, k) + 0.008 * _rain_intensity
	var spot_mult := float(preset["spot_mult"])
	for entry in _skylight_spots:
		var light := entry.get("light") as SpotLight3D
		if light != null and is_instance_valid(light):
			light.light_energy = float(entry.get("base_energy", 0.0)) * spot_mult * _clarity
	for mat in _shaft_mats:
		if mat != null:
			mat.set_shader_parameter("intensity", 0.10 * spot_mult * _clarity)
	for mat in _wind_mats:
		if mat != null:
			mat.set_shader_parameter("wind_strength", _wind_strength)
			mat.set_shader_parameter("wind_dir", _wind_dir)
	for mat in _wet_mats:
		if mat != null:
			mat.set_shader_parameter("rain_intensity", _rain_intensity)
			mat.set_shader_parameter("clarity", _clarity)
	if _rain_particles is CPUParticles3D:
		(_rain_particles as CPUParticles3D).gravity = Vector3(_wind_dir.x * _wind_strength * 5.2, -18.0, _wind_dir.y * _wind_strength * 5.2)
	if _wind_particles is CPUParticles3D:
		(_wind_particles as CPUParticles3D).gravity = Vector3(_wind_dir.x * (2.5 + _wind_strength * 5.5), -0.15, _wind_dir.y * (2.5 + _wind_strength * 5.5))
	_set_particles_scale(_rain_particles, _rain_intensity)
	_set_particles_scale(_splash_particles, _rain_intensity)
	_set_particles_scale(_wind_particles, _wind_strength)


func _set_particles_scale(node: Node, factor: float) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is GPUParticles3D:
		var gpu := node as GPUParticles3D
		gpu.emitting = factor > 0.03
		gpu.amount_ratio = clampf(factor, 0.05, 1.0)
	elif node is CPUParticles3D:
		var cpu := node as CPUParticles3D
		cpu.emitting = factor > 0.03
		cpu.speed_scale = lerpf(0.55, 1.15, clampf(factor, 0.0, 1.0))


# --- Navigation --------------------------------------------------------------

func _build_navigation() -> void:
	var nav := NavigationMesh.new()
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	nav.agent_radius = 0.45
	nav.agent_height = 2.2
	nav.agent_max_climb = 0.3
	nav.agent_max_slope = 45.0
	nav.set_vertices(PackedVector3Array([
		Vector3(-12.6, NAV_Y, 12.0),
		Vector3(12.6, NAV_Y, 12.0),
		Vector3(12.6, NAV_Y, -12.0),
		Vector3(-12.6, NAV_Y, -12.0),
	]))
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "Navigation"
	_nav_region.navigation_mesh = nav
	add_child(_nav_region)


# --- Plaza -------------------------------------------------------------------

func _toon_mat(color: Color, emission := Color(0, 0, 0, 1), energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = 0.90
	mat.metallic = 0.0
	mat.rim_enabled = true
	mat.rim = 0.18
	mat.rim_tint = 0.35
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = energy
	return mat


func _apply_toon_to_actor(root: Node) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var inst := mi as MeshInstance3D
		if inst.mesh == null:
			continue
		if inst.material_override is BaseMaterial3D:
			var over := inst.material_override as BaseMaterial3D
			if over.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			var dup := over.duplicate(true) as BaseMaterial3D
			dup.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			dup.specular_mode = BaseMaterial3D.SPECULAR_TOON
			dup.rim_enabled = true
			dup.rim = 0.18
			dup.rim_tint = 0.35
			inst.material_override = dup
			continue
		for i in inst.mesh.get_surface_count():
			var mat := inst.get_active_material(i)
			if not (mat is BaseMaterial3D):
				continue
			var base := mat as BaseMaterial3D
			if base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				continue
			var dup2 := base.duplicate(true) as BaseMaterial3D
			dup2.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			dup2.specular_mode = BaseMaterial3D.SPECULAR_TOON
			dup2.rim_enabled = true
			dup2.rim = 0.18
			dup2.rim_tint = 0.35
			inst.set_surface_override_material(i, dup2)


func _wall_shader_mat(
	own_key: String, a_key: String, b_key: String,
	corner_a := Vector4.ZERO, corner_b := Vector4.ZERO,
	base_col := Color(0.24, 0.19, 0.17, 1.0)
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WALL_SHADER
	mat.set_shader_parameter("tex_own", WALL_TEXTURES.get(own_key, WALL_TEXTURES["stone"]))
	mat.set_shader_parameter("tex_a", WALL_TEXTURES.get(a_key, WALL_TEXTURES["slate"]))
	mat.set_shader_parameter("tex_b", WALL_TEXTURES.get(b_key, WALL_TEXTURES["bark"]))
	mat.set_shader_parameter("base_color", base_col)
	mat.set_shader_parameter("strength", 0.58)
	mat.set_shader_parameter("tile", 0.24)
	mat.set_shader_parameter("corner_width", 1.8)
	mat.set_shader_parameter("corner_a", corner_a)
	mat.set_shader_parameter("corner_b", corner_b)
	return mat


func _register_fade_mesh(mi: MeshInstance3D, radius: float) -> void:
	if mi == null:
		return
	var mat := mi.material_override as StandardMaterial3D
	if mat == null:
		return
	var dup := mat.duplicate() as StandardMaterial3D
	dup.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mi.material_override = dup
	_foliage_fade.append({"mesh": mi, "mat": dup, "radius": radius})


func _update_foliage_fade(delta: float) -> void:
	if _camera == null or player == null:
		return
	var cam := _camera.global_position
	var target := player.global_position + Vector3(0.0, 1.0, 0.0)
	var seg := target - cam
	var seg_len2 := maxf(seg.length_squared(), 0.001)
	for entry in _foliage_fade:
		var mesh := entry.get("mesh") as MeshInstance3D
		var mat := entry.get("mat") as StandardMaterial3D
		if mesh == null or not is_instance_valid(mesh) or mat == null:
			continue
		var pos := mesh.global_position
		var t := clampf((pos - cam).dot(seg) / seg_len2, 0.0, 1.0)
		var closest := cam + seg * t
		var occlude := t > 0.02 and t < 0.98 \
			and pos.distance_to(cam) < 4.5 \
			and pos.distance_to(closest) < float(entry.get("radius", 1.0)) + 0.35
		var target_a := 0.24 if occlude else 1.0
		var col := mat.albedo_color
		col.a = lerpf(col.a, target_a, clampf(delta * 8.0, 0.0, 1.0))
		mat.albedo_color = col
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if col.a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED


var _cached_hub_noise: NoiseTexture2D = null


func _hub_noise_tex() -> NoiseTexture2D:
	if _cached_hub_noise != null:
		return _cached_hub_noise
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.045
	fn.fractal_octaves = 3
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.noise = fn
	_cached_hub_noise = nt
	return nt


func _plaza_floor_shader(base_color: Color, tile_scale: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec3 base_color : source_color = vec3(0.42, 0.35, 0.30);
uniform sampler2D stone_noise : repeat_enable;
uniform float tile_scale = 1.65;
uniform float rain_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float clarity : hint_range(0.2, 1.4) = 0.85;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wp = v_world_pos.xz;
	vec2 tile_uv = wp / tile_scale;
	vec2 cell = floor(tile_uv);
	vec2 f = fract(tile_uv);
	float jitter = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	float mortar = smoothstep(0.0, 0.055, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
	float grain = texture(stone_noise, wp * 0.11).r;
	vec3 stone_col = base_color * (0.86 + 0.22 * jitter) * (0.88 + 0.24 * grain);
	stone_col = mix(base_color * 0.48, stone_col, mortar);

	// Puddles pool naturally under the three cavern skylight openings.
	float d1 = length(wp - vec2(0.0, 1.0)) / 4.4;
	float d2 = length(wp - vec2(0.0, -5.8)) / 2.6;
	float d3 = length(wp - vec2(-6.2, -1.8)) / 2.8;
	float sky_mask = clamp(1.0 - min(d1, min(d2, d3)), 0.0, 1.0);
	float puddle_n = texture(stone_noise, wp * 0.08 + vec2(0.31, 0.17)).r;
	float puddle = smoothstep(0.38, 0.62, puddle_n * 0.7 + sky_mask * 0.55) * rain_intensity;

	// Concentric raindrop ripples in wet puddles.
	vec2 r_cell = floor(wp * 1.4);
	vec2 r_f = fract(wp * 1.4) - 0.5;
	float r_phase = fract(TIME * 1.45 + fract(sin(dot(r_cell, vec2(41.3, 289.1))) * 19341.2));
	float r_dist = length(r_f);
	float ripple = sin((r_dist - r_phase * 0.48) * 38.0) * exp(-r_dist * 6.0) * (1.0 - r_phase) * puddle;

	ALBEDO = mix(stone_col, stone_col * 0.62 + vec3(0.05, 0.04, 0.03) * clarity, puddle * 0.72);
	ROUGHNESS = mix(0.86, 0.10, puddle);
	SPECULAR = mix(0.18, 0.90, puddle);
	EMISSION = vec3(0.95, 0.74, 0.42) * max(ripple, 0.0) * 0.28 * clarity;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("base_color", base_color)
	mat.set_shader_parameter("stone_noise", _hub_noise_tex())
	mat.set_shader_parameter("tile_scale", tile_scale)
	mat.set_shader_parameter("rain_intensity", _rain_intensity)
	mat.set_shader_parameter("clarity", _clarity)
	_wet_mats.append(mat)
	return mat


func _foliage_wind_shader(base_color: Color, sway_scale := 0.14) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec3 base_color : source_color = vec3(0.18, 0.40, 0.28);
uniform float wind_strength : hint_range(0.0, 1.5) = 0.35;
uniform vec2 wind_dir = vec2(0.85, 0.52);
uniform float sway_scale = 0.14;

varying vec3 v_world_pos;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = clamp(VERTEX.y + 0.5, 0.0, 2.5);
	float gust = sin(TIME * (1.8 + wind_strength * 2.2) + wp.x * 0.55 + wp.z * 0.45);
	float flutter = 0.25 * cos(TIME * 4.3 + wp.x * 1.9 - wp.z * 1.3);
	vec2 disp = normalize(wind_dir + vec2(0.001)) * (gust + flutter) * wind_strength * sway_scale * h;
	VERTEX.x += disp.x;
	VERTEX.z += disp.y;
	v_world_pos = wp;
}

void fragment() {
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.2);
	ALBEDO = base_color;
	ROUGHNESS = 0.78;
	EMISSION = vec3(0.32, 0.26, 0.14) * rim * 0.25;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("base_color", base_color)
	mat.set_shader_parameter("wind_strength", _wind_strength)
	mat.set_shader_parameter("wind_dir", _wind_dir)
	mat.set_shader_parameter("sway_scale", sway_scale)
	_wind_mats.append(mat)
	return mat


func _build_room() -> void:
	var ground := _plaza_floor_shader(Color(0.28, 0.22, 0.19), 2.4)
	var plaza := _plaza_floor_shader(Color(0.45, 0.38, 0.32), 1.55)
	var paver := _plaza_floor_shader(Color(0.38, 0.32, 0.27), 1.20)
	var trim := _toon_mat(Color(0.20, 0.17, 0.16), Color(0.85, 0.55, 0.28), 0.35)
	var stone := _toon_mat(Color(0.36, 0.31, 0.27))
	var dark := _toon_mat(Color(0.16, 0.14, 0.14))

	# Base ground and the raised central plaza slab.
	_box(Vector3(PLAZA_HALF_X * 2.0 + 2.0, 0.4, PLAZA_HALF_Z * 2.0 + 2.0), Vector3(0.0, -0.2, 0.0), ground)
	_box(Vector3(12.0, 0.10, 10.0), Vector3(0.0, 0.05, 1.0), plaza, false)
	# Plaza trim lines and a central medallion.
	for i in 5:
		_box(Vector3(11.2, 0.02, 0.10), Vector3(0.0, 0.105, -3.6 + float(i) * 2.3), trim, false)
	var medallion := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 2.2
	cyl.height = 0.04
	cyl.radial_segments = 8
	medallion.mesh = cyl
	medallion.position = Vector3(0.0, 0.11, 1.0)
	medallion.material_override = trim
	add_child(medallion)

	# Cardinal stone walkways leading from Central Plaza to Gate, Guild, and Plots A/B.
	for pz in [-4.8, -6.4, -8.0, -9.5]:
		_box(Vector3(2.4, 0.05, 1.25), Vector3(0.0, 0.025, pz), paver, false)
	for px in [-6.8, -8.2]:
		_box(Vector3(1.25, 0.05, 2.2), Vector3(px, 0.025, -2.0), paver, false)
	for px in [6.8, 8.2]:
		_box(Vector3(1.25, 0.05, 1.8), Vector3(px, 0.025, -2.0), paver, false)
	_box(Vector3(1.4, 0.05, 1.4), Vector3(6.2, 0.025, 4.6), paver, false)

	# Perimeter walls with triplanar palisade blend shader (D-1118); north center left open for Gate.
	var wall_specs := [
		[Vector3(0.5, PLAZA_WALL_HEIGHT, PLAZA_HALF_Z * 2.0), Vector3(-PLAZA_HALF_X - 0.25, PLAZA_WALL_HEIGHT * 0.5, 0.0),
			"stone", "palisade", "bark", Vector4(-PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(-PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0)],
		[Vector3(0.5, PLAZA_WALL_HEIGHT, PLAZA_HALF_Z * 2.0), Vector3(PLAZA_HALF_X + 0.25, PLAZA_WALL_HEIGHT * 0.5, 0.0),
			"stone", "palisade", "slate", Vector4(PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0)],
		[Vector3(PLAZA_HALF_X * 2.0 + 1.0, PLAZA_WALL_HEIGHT, 0.5), Vector3(0.0, PLAZA_WALL_HEIGHT * 0.5, PLAZA_HALF_Z + 0.25),
			"palisade", "bark", "stone", Vector4(-PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0), Vector4(PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0)],
		[Vector3(11.0, PLAZA_WALL_HEIGHT, 0.5), Vector3(-8.5, PLAZA_WALL_HEIGHT * 0.5, -PLAZA_HALF_Z - 0.25),
			"slate", "stone", "bark", Vector4(-PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(-3.0, -PLAZA_HALF_Z, 0.0, 0.8)],
		[Vector3(11.0, PLAZA_WALL_HEIGHT, 0.5), Vector3(8.5, PLAZA_WALL_HEIGHT * 0.5, -PLAZA_HALF_Z - 0.25),
			"slate", "stone", "bark", Vector4(PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(3.0, -PLAZA_HALF_Z, 0.0, 0.8)],
	]
	for wspec in wall_specs:
		var wmi := _box(wspec[0], wspec[1], stone)
		wmi.material_override = _wall_shader_mat(wspec[2], wspec[3], wspec[4], wspec[5], wspec[6])

	# Octagonal corner chamfer bastions framing the ~28m x 26m walled plaza (H1).
	for cpos in [
		Vector3(-PLAZA_HALF_X + 0.8, 0.0, -PLAZA_HALF_Z + 0.8),
		Vector3(PLAZA_HALF_X - 0.8, 0.0, -PLAZA_HALF_Z + 0.8),
		Vector3(-PLAZA_HALF_X + 0.8, 0.0, PLAZA_HALF_Z - 0.8),
		Vector3(PLAZA_HALF_X - 0.8, 0.0, PLAZA_HALF_Z - 0.8),
	]:
		var bastion := StaticBody3D.new()
		bastion.position = Vector3(cpos.x, (PLAZA_WALL_HEIGHT + 0.6) * 0.5, cpos.z)
		var col_shape := CollisionShape3D.new()
		var cyl_col := CylinderShape3D.new()
		cyl_col.radius = 1.75
		cyl_col.height = PLAZA_WALL_HEIGHT + 0.6
		col_shape.shape = cyl_col
		bastion.add_child(col_shape)
		var bmi := MeshInstance3D.new()
		var bmesh := CylinderMesh.new()
		bmesh.top_radius = 1.75
		bmesh.bottom_radius = 1.95
		bmesh.height = PLAZA_WALL_HEIGHT + 0.6
		bmesh.radial_segments = 8
		bmi.mesh = bmesh
		bmi.material_override = _wall_shader_mat("bark", "stone", "slate", Vector4.ZERO, Vector4.ZERO, Color(0.22, 0.18, 0.16, 1.0))
		bastion.add_child(bmi)
		add_child(bastion)

	# Lamp posts and benches around the plaza.
	for p in [
		Vector3(-6.2, 0.0, 4.6), Vector3(6.2, 0.0, 4.6),
		Vector3(-6.2, 0.0, -4.6), Vector3(6.2, 0.0, -4.6),
	]:
		_box(Vector3(0.22, 2.6, 0.22), p + Vector3(0.0, 1.3, 0.0), dark)
		var bulb := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.24
		sph.height = 0.48
		sph.radial_segments = 8
		sph.rings = 4
		bulb.mesh = sph
		bulb.position = p + Vector3(0.0, 2.7, 0.0)
		bulb.material_override = _toon_mat(Color(1.0, 0.78, 0.42), Color(1.0, 0.68, 0.34), 1.6)
		add_child(bulb)
		var light := OmniLight3D.new()
		light.position = p + Vector3(0.0, 2.7, 0.0)
		light.light_color = Color(1.0, 0.70, 0.38)
		light.light_energy = 0.55
		light.omni_range = 5.0
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.55)

	for b in [Vector3(-8.0, 0.0, 4.2), Vector3(8.0, 0.0, 4.2)]:
		_box(Vector3(2.0, 0.42, 0.60), b + Vector3(0.0, 0.21, 0.0), stone)
		_box(Vector3(2.0, 0.10, 0.60), b + Vector3(0.0, 0.47, 0.0), trim, false)

	# Planters framing the plaza.
	for p in [
		Vector3(-11.5, 0.0, 7.5), Vector3(11.5, 0.0, 7.5),
		Vector3(-11.5, 0.0, -9.0), Vector3(11.5, 0.0, -9.0),
	]:
		_box(Vector3(1.4, 0.55, 1.4), p + Vector3(0.0, 0.275, 0.0), stone)
		for k in 3:
			var leaf := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.45
			s.height = 0.7
			s.radial_segments = 6
			s.rings = 3
			leaf.mesh = s
			leaf.position = p + Vector3(
				-0.25 + 0.25 * float(k), 0.85 + 0.08 * float(k), 0.12 * float(k - 1))
			leaf.material_override = _foliage_wind_shader(Color(0.18, 0.42, 0.30), 0.16)
			add_child(leaf)
			_register_fade_mesh(leaf, 0.6)

	# Stylized perimeter trees & stone buttresses to frame the settlement against the sky.
	var trunk_mat := _toon_mat(Color(0.24, 0.17, 0.13))
	var canopy_a := _foliage_wind_shader(Color(0.16, 0.34, 0.24), 0.18)
	var canopy_b := _foliage_wind_shader(Color(0.22, 0.40, 0.26), 0.22)
	for tpos in [
		Vector3(-13.4, 0.0, -11.5), Vector3(-7.0, 0.0, -12.6),
		Vector3(7.0, 0.0, -12.6), Vector3(13.4, 0.0, -11.5),
		Vector3(13.4, 0.0, 2.2), Vector3(-13.4, 0.0, 9.8), Vector3(13.4, 0.0, 10.2),
	]:
		_box(Vector3(0.55, 3.6, 0.55), tpos + Vector3(0.0, 1.8, 0.0), trunk_mat, false)
		for ci in 3:
			var c_mesh := MeshInstance3D.new()
			var cs := SphereMesh.new()
			cs.radius = 1.35 - 0.18 * float(ci)
			cs.height = 2.0 - 0.2 * float(ci)
			cs.radial_segments = 7
			cs.rings = 4
			c_mesh.mesh = cs
			c_mesh.position = tpos + Vector3(
				(-0.5 + 0.5 * float(ci)), 3.9 + 0.55 * float(ci % 2), -0.2 + 0.25 * float(ci))
			c_mesh.material_override = canopy_a if (ci % 2 == 0) else canopy_b
			add_child(c_mesh)
			_register_fade_mesh(c_mesh, cs.radius + 0.25)

	_build_cavern_ceiling()
	_build_atmosphere_particles()


func _light_shaft_shader() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec3 beam_color : source_color = vec3(0.95, 0.68, 0.34);
uniform float intensity = 0.10;

void fragment() {
	float v_fade = smoothstep(0.0, 0.25, UV.y) * (1.0 - smoothstep(0.65, 1.0, UV.y));
	float fresnel = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.4);
	float streaks = 0.82 + 0.18 * sin(UV.x * 25.1327 + TIME * 0.45);
	float alpha = v_fade * fresnel * streaks * intensity;
	ALBEDO = beam_color;
	ALPHA = clamp(alpha, 0.0, 0.24);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat


func _build_cavern_ceiling() -> void:
	# Subterranean cavern vault above y = 7.4 m (non-colliding so camera is never blocked).
	var rock_dark := _toon_mat(Color(0.11, 0.08, 0.08))
	var rock_mid := _toon_mat(Color(0.16, 0.12, 0.11))
	var sky_glow := _toon_mat(Color(0.98, 0.78, 0.46), Color(1.0, 0.74, 0.38), 2.1)
	var shaft_mat := _light_shaft_shader()
	if not _shaft_mats.has(shaft_mat):
		_shaft_mats.append(shaft_mat)

	# Perimeter rock buttresses breaking up the flat outer walls.
	for rx in [-13.7, 13.7]:
		for rz in [-9.5, -3.5, 2.5, 8.5]:
			_box(Vector3(1.1, 7.6, 1.8), Vector3(rx, 3.8, rz), rock_mid, false)
	for rz in [-12.8, 12.8]:
		for rx in [-10.0, -5.0, 5.0, 10.0]:
			_box(Vector3(1.8, 7.6, 1.1), Vector3(rx, 3.8, rz), rock_mid, false)

	# Ceiling slabs arranged around three skylight shafts (central, gate, guild).
	var slabs := [
		[Vector3(30.0, 0.9, 6.0), Vector3(0.0, 9.2, 10.2)],
		[Vector3(30.0, 0.9, 4.2), Vector3(0.0, 9.2, -11.4)],
		[Vector3(8.5, 0.9, 18.0), Vector3(-11.8, 9.2, -1.0)],
		[Vector3(10.5, 0.9, 18.0), Vector3(10.2, 9.2, -1.0)],
		[Vector3(10.0, 0.9, 4.4), Vector3(0.0, 9.2, -3.3)],
		[Vector3(4.5, 0.9, 6.0), Vector3(-5.0, 9.2, 4.2)],
		[Vector3(4.5, 0.9, 6.0), Vector3(4.6, 9.2, 4.2)],
	]
	for s in slabs:
		_box(s[0], s[1], rock_dark, false)

	# Hanging stalactites around the perimeter vault (all above y = 6.6 m).
	for st in [
		Vector3(-11.5, 7.8, -10.0), Vector3(-7.5, 8.0, -10.5), Vector3(7.8, 7.9, -10.4),
		Vector3(11.6, 7.7, -9.8), Vector3(-11.8, 7.8, 6.5), Vector3(11.8, 7.7, 6.8),
		Vector3(6.2, 8.1, 9.5), Vector3(-6.2, 8.0, 9.6), Vector3(8.5, 7.9, -2.5),
	]:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.72
		cm.bottom_radius = 0.08
		cm.height = 2.4
		cm.radial_segments = 6
		cone.mesh = cm
		cone.position = st
		cone.material_override = rock_mid
		add_child(cone)

	# Three skylight holes casting pools of warm light into the dark cavern.
	var shafts := [
		{"pos": Vector3(0.0, 0.0, 1.0), "top_r": 2.3, "bot_r": 4.2, "energy": 3.4, "angle": 36.0, "dust": true},
		{"pos": Vector3(0.0, 0.0, -5.8), "top_r": 1.25, "bot_r": 2.2, "energy": 2.4, "angle": 32.0, "dust": false},
		{"pos": Vector3(-6.2, 0.0, -1.8), "top_r": 1.35, "bot_r": 2.6, "energy": 2.1, "angle": 28.0, "dust": false},
	]
	for sh in shafts:
		var p: Vector3 = sh["pos"]
		var top_r: float = sh["top_r"]
		var bot_r: float = sh["bot_r"]

		# Emissive sky aperture disk at the ceiling opening.
		var hole := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = top_r
		hm.bottom_radius = top_r
		hm.height = 0.16
		hm.radial_segments = 10
		hole.mesh = hm
		hole.position = Vector3(p.x, 9.15, p.z)
		hole.material_override = sky_glow
		add_child(hole)

		# Rocky collar framing the hole.
		for k in 6:
			var ang := TAU * float(k) / 6.0
			_box(Vector3(1.1, 0.55, 0.65),
				Vector3(p.x + cos(ang) * (top_r + 0.35), 8.85, p.z + sin(ang) * (top_r + 0.35)),
				rock_mid, false)

		# Volumetric-style light beam cone.
		var beam := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = top_r * 0.92
		bm.bottom_radius = bot_r
		bm.height = 9.0
		bm.radial_segments = 14
		beam.mesh = bm
		beam.position = Vector3(p.x, 4.5, p.z)
		beam.material_override = shaft_mat
		add_child(beam)

		# Focused downward SpotLight3D illuminating the cavern floor.
		var spot := SpotLight3D.new()
		spot.position = Vector3(p.x, 9.0, p.z)
		spot.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		spot.light_color = Color(1.0, 0.78, 0.46)
		spot.light_energy = float(sh["energy"])
		spot.spot_range = 14.5
		spot.spot_angle = float(sh["angle"])
		spot.spot_attenuation = 0.85
		spot.shadow_enabled = true
		add_child(spot)
		_skylight_spots.append({"light": spot, "base_energy": float(sh["energy"])})

		if sh["dust"]:
			var dust := CPUParticles3D.new()
			dust.position = Vector3(p.x, 3.6, p.z)
			dust.amount = 28
			dust.lifetime = 4.5
			dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			dust.emission_box_extents = Vector3(2.8, 2.8, 2.8)
			dust.gravity = Vector3(0.0, -0.06, 0.0)
			dust.initial_velocity_min = 0.05
			dust.initial_velocity_max = 0.18
			dust.scale_amount_min = 0.03
			dust.scale_amount_max = 0.07
			var qm := QuadMesh.new()
			qm.size = Vector2(0.10, 0.10)
			var pm := StandardMaterial3D.new()
			pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			pm.albedo_color = Color(1.0, 0.85, 0.52, 0.55)
			qm.material = pm
			dust.mesh = qm
			add_child(dust)


func _wind_ribbon_shader() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform sampler2D noise_tex : repeat_enable;
uniform float wind_strength : hint_range(0.0, 1.5) = 0.35;
uniform vec2 wind_dir = vec2(0.85, 0.52);

void vertex() {
	float wave = sin(TIME * (1.8 + wind_strength * 2.4) + VERTEX.x * 0.9) * 0.18 * wind_strength;
	VERTEX.y += wave;
	VERTEX.z += cos(TIME * 1.4 + VERTEX.x * 0.6) * 0.10 * wind_strength;
}

void fragment() {
	float edge_x = smoothstep(0.0, 0.22, UV.x) * (1.0 - smoothstep(0.78, 1.0, UV.x));
	float edge_y = sin(UV.y * 3.14159);
	vec2 uv = vec2(UV.x * 1.6 - TIME * (0.28 + wind_strength * 0.55), UV.y * 0.5 + TIME * 0.04);
	float wisp = smoothstep(0.42, 0.85, texture(noise_tex, uv).r);
	float alpha = edge_x * edge_y * wisp * clamp(0.07 + wind_strength * 0.11, 0.0, 0.22);
	ALBEDO = vec3(0.96, 0.84, 0.62);
	ALPHA = alpha;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("noise_tex", _hub_noise_tex())
	mat.set_shader_parameter("wind_strength", _wind_strength)
	mat.set_shader_parameter("wind_dir", _wind_dir)
	_wind_mats.append(mat)
	return mat


func _ground_mist_shader() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D noise_tex : repeat_enable;
uniform float wind_strength : hint_range(0.0, 1.5) = 0.35;
uniform vec2 wind_dir = vec2(0.85, 0.52);
uniform float rain_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float clarity : hint_range(0.2, 1.4) = 0.85;

void fragment() {
	vec2 drift = normalize(wind_dir + vec2(0.001)) * TIME * (0.025 + wind_strength * 0.045);
	float n1 = texture(noise_tex, UV * 2.2 - drift).r;
	float n2 = texture(noise_tex, UV * 4.1 - drift * 1.6 + vec2(0.37, 0.19)).r;
	float mist = smoothstep(0.36, 0.82, n1 * 0.65 + n2 * 0.35);
	float radial = 1.0 - smoothstep(0.25, 0.50, length(UV - vec2(0.5)));
	float density = (0.055 + rain_intensity * 0.065) * clamp(1.3 - clarity * 0.35, 0.45, 1.15);
	ALBEDO = mix(vec3(0.58, 0.46, 0.38), vec3(0.86, 0.70, 0.52), clamp(clarity * 0.65, 0.0, 1.0));
	ALPHA = mist * radial * density;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("noise_tex", _hub_noise_tex())
	mat.set_shader_parameter("wind_strength", _wind_strength)
	mat.set_shader_parameter("wind_dir", _wind_dir)
	mat.set_shader_parameter("rain_intensity", _rain_intensity)
	mat.set_shader_parameter("clarity", _clarity)
	_wind_mats.append(mat)
	_wet_mats.append(mat)
	return mat


func _build_atmosphere_particles() -> void:
	# Swaying expedition banners flanking the Gate and Guild Hall.
	var banner_mat := _foliage_wind_shader(Color(0.76, 0.28, 0.18), 0.34)
	var pole_mat := _toon_mat(Color(0.24, 0.18, 0.14))
	for bpos in [
		Vector3(-2.6, 0.0, -10.4), Vector3(2.6, 0.0, -10.4),
		Vector3(-8.8, 0.0, -4.6), Vector3(-8.8, 0.0, 0.6),
	]:
		_box(Vector3(0.10, 3.2, 0.10), bpos + Vector3(0.0, 1.6, 0.0), pole_mat, false)
		var cloth := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 1.45, 0.05)
		bm.subdivide_height = 6
		cloth.mesh = bm
		cloth.position = bpos + Vector3(0.0, 2.25, 0.08)
		cloth.material_override = banner_mat
		add_child(cloth)

	# Delicate rain drizzle pouring through the central cavern skylight.
	var rain := CPUParticles3D.new()
	rain.name = "SkylightRain"
	rain.position = Vector3(0.0, 8.6, 1.0)
	rain.amount = 64
	rain.lifetime = 0.60
	rain.preprocess = 0.4
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(3.2, 0.25, 3.2)
	rain.gravity = Vector3(1.8, -18.0, 1.1)
	rain.initial_velocity_min = 4.5
	rain.initial_velocity_max = 7.0
	rain.direction = Vector3(0.0, -1.0, 0.0)
	rain.spread = 3.0
	var rq := QuadMesh.new()
	rq.size = Vector2(0.007, 0.20)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(1.0, 0.88, 0.68, 0.22)
	rq.material = rm
	rain.mesh = rq
	add_child(rain)
	_rain_particles = rain

	# Subtle floor rain splash droplets under the skylight.
	var splash := CPUParticles3D.new()
	splash.name = "RainSplashes"
	splash.position = Vector3(0.0, 0.14, 1.0)
	splash.amount = 24
	splash.lifetime = 0.34
	splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	splash.emission_box_extents = Vector3(3.0, 0.02, 3.0)
	splash.gravity = Vector3.ZERO
	splash.initial_velocity_min = 0.0
	splash.initial_velocity_max = 0.0
	splash.scale_amount_min = 0.35
	splash.scale_amount_max = 0.70
	var sq := CylinderMesh.new()
	sq.top_radius = 0.04
	sq.bottom_radius = 0.05
	sq.height = 0.01
	sq.radial_segments = 8
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(1.0, 0.86, 0.64, 0.16)
	sq.material = sm
	splash.mesh = sq
	add_child(splash)
	_splash_particles = splash

	# Flowing wind ribbons & drifting cavern ground mist shaders (no square pixels).
	var wind_ribbon_mat := _wind_ribbon_shader()
	for r_spec in [
		{"pos": Vector3(-1.5, 1.7, -1.0), "size": Vector2(12.0, 0.55), "yaw": 0.42},
		{"pos": Vector3(2.2, 2.6, 2.5), "size": Vector2(10.5, 0.45), "yaw": 0.55},
		{"pos": Vector3(-3.0, 2.2, -5.8), "size": Vector2(9.5, 0.42), "yaw": 0.35},
		{"pos": Vector3(3.8, 1.4, -3.5), "size": Vector2(10.0, 0.48), "yaw": 0.48},
	]:
		var rmi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = r_spec["size"]
		pm.subdivide_width = 16
		pm.subdivide_depth = 2
		rmi.mesh = pm
		rmi.position = r_spec["pos"]
		rmi.rotation.y = float(r_spec["yaw"])
		rmi.rotation.x = 0.28
		rmi.material_override = wind_ribbon_mat
		add_child(rmi)

	var mist_mat := _ground_mist_shader()
	for my in [0.24, 0.52]:
		var mmi := MeshInstance3D.new()
		var mpm := PlaneMesh.new()
		mpm.size = Vector2(26.0, 24.0)
		mmi.mesh = mpm
		mmi.position = Vector3(0.0, my, 0.0)
		mmi.material_override = mist_mat
		add_child(mmi)
	_wind_particles = null

	# Rising warm embers over the four plaza lamp posts.
	for p in [
		Vector3(-6.2, 3.0, 4.6), Vector3(6.2, 3.0, 4.6),
		Vector3(-6.2, 3.0, -4.6), Vector3(6.2, 3.0, -4.6),
	]:
		var emb := CPUParticles3D.new()
		emb.position = p
		emb.amount = 10
		emb.lifetime = 1.6
		emb.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		emb.emission_sphere_radius = 0.20
		emb.gravity = Vector3(0.25, 0.55, 0.15)
		emb.initial_velocity_min = 0.08
		emb.initial_velocity_max = 0.22
		emb.scale_amount_min = 0.025
		emb.scale_amount_max = 0.05
		var eq := QuadMesh.new()
		eq.size = Vector2(0.08, 0.08)
		var em := StandardMaterial3D.new()
		em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		em.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		em.albedo_color = Color(1.0, 0.68, 0.28, 0.72)
		eq.material = em
		emb.mesh = eq
		add_child(emb)


func _gate_portal_shader() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	// Elliptical radial distance fitting the 3.82 x 4.04 archway.
	float r = length(uv * vec2(1.05, 0.92));
	float angle = atan(uv.y, uv.x);

	// Dual counter-rotating spiral energy streams.
	float s1 = sin(r * 12.0 - TIME * 2.4 + angle * 3.0 + sin(TIME * 0.9 + r * 4.0) * 0.8);
	float s2 = cos(r * 16.0 - TIME * 3.1 - angle * 2.0);
	float stream = smoothstep(0.15, 0.85, s1 * 0.6 + s2 * 0.4);

	// Glowing inner vortex core + arched frame falloff.
	float arch_mask = (1.0 - smoothstep(0.72, 1.02, abs(uv.x))) * (1.0 - smoothstep(0.76, 1.02, abs(uv.y)));
	float core = exp(-r * 2.1);
	float ring = exp(-pow((r - 0.58) * 5.2, 2.0));

	vec3 void_col = vec3(0.05, 0.03, 0.04);
	vec3 amber_mid = vec3(0.72, 0.34, 0.10);
	vec3 gold_bright = vec3(1.00, 0.78, 0.32);

	vec3 col = mix(void_col, amber_mid, clamp(arch_mask * (0.45 + stream * 0.55), 0.0, 1.0));
	col = mix(col, gold_bright, clamp((core * 0.85 + ring * 0.55 + stream * 0.35) * arch_mask, 0.0, 1.0));
	ALBEDO = col;
	EMISSION = col * 0.85;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat


func _build_exit() -> void:
	_gate_root = Node3D.new()
	_gate_root.name = "ExpeditionGate"
	add_child(_gate_root)
	var stone := _toon_mat(Color(0.40, 0.34, 0.29))
	var trim_stone := _toon_mat(Color(0.28, 0.23, 0.20))
	var gold := _toon_mat(Color(0.72, 0.52, 0.22), Color(1.0, 0.62, 0.24), 0.9)
	# Stepped stone plinth and arch at the north edge.
	_box(Vector3(6.6, 0.22, 2.0), GATE_POS + Vector3(0.0, 0.11, 0.2), trim_stone, false)
	for x in [-2.4, 2.4]:
		var pillar := _box(Vector3(0.95, 5.0, 0.95), GATE_POS + Vector3(x, 2.5, 0.0), stone)
		pillar.name = "GatePillar"
		_register_fade_mesh(pillar, 0.9)
		_box(Vector3(1.22, 0.42, 1.22), GATE_POS + Vector3(x, 0.21, 0.0), trim_stone, false)
		_box(Vector3(1.25, 0.42, 1.25), GATE_POS + Vector3(x, 5.1, 0.0), gold, false)
	_box(Vector3(6.4, 0.85, 1.05), GATE_POS + Vector3(0.0, 4.7, 0.0), stone)
	_box(Vector3(2.2, 0.55, 1.15), GATE_POS + Vector3(0.0, 5.32, 0.0), gold, false)
	var portal_quad := MeshInstance3D.new()
	var pqm := QuadMesh.new()
	pqm.size = Vector2(3.82, 4.04)
	portal_quad.mesh = pqm
	portal_quad.position = GATE_POS + Vector3(0.0, 2.24, 0.05)
	portal_quad.material_override = _gate_portal_shader()
	add_child(portal_quad)
	var gate_light := OmniLight3D.new()
	gate_light.position = GATE_POS + Vector3(0.0, 2.2, 1.4)
	gate_light.light_color = Color(1.0, 0.66, 0.30)
	gate_light.light_energy = 0.90
	gate_light.omni_range = 6.5
	add_child(gate_light)
	_lighting_lamps.append({"light": gate_light, "base": 0.90})

	# Expedition board / totem (the interactive landmark).
	var board := Node3D.new()
	board.name = "ExpeditionBoard"
	board.position = BOARD_POS
	add_child(board)
	_box(Vector3(0.28, 2.0, 0.28), BOARD_POS + Vector3(0.0, 1.0, 0.0), _toon_mat(Color(0.22, 0.17, 0.14)))
	_box(Vector3(1.30, 1.10, 0.14), BOARD_POS + Vector3(0.0, 2.05, 0.0), _toon_mat(Color(0.10, 0.12, 0.14)))
	_box(Vector3(1.10, 0.90, 0.04), BOARD_POS + Vector3(0.0, 2.05, 0.09),
		_toon_mat(Color(0.80, 0.72, 0.55), Color(0.95, 0.80, 0.45), 0.45), false)
	var tag := Label3D.new()
	tag.name = "BoardTag"
	tag.text = "EXPEDITION GATE"
	tag.font_size = 32
	tag.modulate = Color(1.0, 0.88, 0.56)
	tag.outline_size = 6
	tag.outline_modulate = Color(0.04, 0.04, 0.04, 0.92)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = BOARD_POS + Vector3(0.0, 3.05, 0.0)
	tag.no_depth_test = false
	add_child(tag)

	# Guild Hall (west facade + open counter).
	_guild_root = Node3D.new()
	_guild_root.name = "GuildHall"
	add_child(_guild_root)
	var guild_mat := _toon_mat(Color(0.30, 0.24, 0.21))
	var roof := _toon_mat(Color(0.24, 0.16, 0.14))
	var wood := _toon_mat(Color(0.44, 0.31, 0.20))
	# Back hall, warm recessed alcove and a chunky open counter/desk.
	_box(Vector3(3.6, 4.4, 7.0), Vector3(-12.6, 2.2, -2.0), guild_mat)
	_box(Vector3(3.8, 0.55, 7.4), Vector3(-12.6, 4.55, -2.0), roof)
	_box(Vector3(0.30, 2.4, 1.8), Vector3(-10.72, 1.2, -2.0),
		_toon_mat(Color(0.26, 0.16, 0.10), Color(0.85, 0.52, 0.22), 0.38), false)
	_box(Vector3(1.55, 1.05, 5.0), Vector3(-10.55, 0.525, -2.0), wood)
	_box(Vector3(1.95, 0.16, 5.4), Vector3(-10.55, 1.13, -2.0), _toon_mat(Color(0.64, 0.48, 0.26)), false)
	for z in [-4.2, 0.2]:
		_box(Vector3(0.24, 3.2, 0.24), Vector3(-9.55, 1.6, z), _toon_mat(Color(0.28, 0.20, 0.14)))
	_box(Vector3(2.6, 0.22, 5.4), Vector3(-10.15, 3.15, -2.0), roof, false)
	_box(Vector3(0.14, 0.52, 2.2), Vector3(-9.48, 2.95, -2.0),
		_toon_mat(Color(0.14, 0.18, 0.16), Color(0.84, 0.98, 0.40), 0.25), false)
	# Papers and a small ledger on the counter.
	_box(Vector3(0.45, 0.04, 0.6), Vector3(-10.5, 1.23, -3.2), _toon_mat(Color(0.86, 0.80, 0.62)), false)
	_box(Vector3(0.40, 0.10, 0.55), Vector3(-10.5, 1.26, -1.1), _toon_mat(Color(0.30, 0.16, 0.12)), false)
	var guild_tag := Label3D.new()
	guild_tag.name = "GuildTag"
	guild_tag.text = "GUILD HALL"
	guild_tag.font_size = 34
	guild_tag.modulate = Color(1.0, 0.88, 0.58)
	guild_tag.outline_size = 6
	guild_tag.outline_modulate = Color(0.04, 0.04, 0.04, 0.92)
	guild_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	guild_tag.position = Vector3(-9.35, 3.68, -2.0)
	guild_tag.no_depth_test = false
	add_child(guild_tag)
	var guild_light := OmniLight3D.new()
	guild_light.position = Vector3(-9.4, 2.3, -2.0)
	guild_light.light_color = Color(1.0, 0.72, 0.42)
	guild_light.light_energy = 0.55
	guild_light.omni_range = 5.0
	add_child(guild_light)
	_lighting_lamps.append({"light": guild_light, "base": 0.55})

	# Two clearly marked, empty expansion plots (no shop/heal signs).
	_plot_markers.clear()
	_plot_markers.append(_build_plot(PLOT_EAST, "PLOT A"))
	_plot_markers.append(_build_plot(PLOT_SOUTHEAST, "PLOT B"))


func _build_plot(center: Vector3, label: String) -> Node3D:
	var pad := _toon_mat(Color(0.34, 0.29, 0.25))
	var border := _toon_mat(Color(0.52, 0.46, 0.40))
	_box(Vector3(4.2, 0.28, 4.2), center + Vector3(0.0, 0.14, 0.0), pad, false)
	for d in [
		Vector3(0.0, 0.10, 2.15), Vector3(0.0, 0.10, -2.15),
		Vector3(2.15, 0.10, 0.0), Vector3(-2.15, 0.10, 0.0),
	]:
		_box(Vector3(4.3, 0.22, 0.22) if absf(d.z) > 0.1 else Vector3(0.22, 0.22, 4.3),
			center + d + Vector3(0.0, 0.11, 0.0), border)
	for corner in [
		Vector3(-1.8, 0.0, -1.8), Vector3(1.8, 0.0, -1.8),
		Vector3(-1.8, 0.0, 1.8), Vector3(1.8, 0.0, 1.8),
	]:
		_box(Vector3(0.12, 0.9, 0.12), center + corner + Vector3(0.0, 0.45, 0.0),
			_toon_mat(Color(0.46, 0.38, 0.26)))
	var anchor := Node3D.new()
	anchor.name = label.replace(" ", "")
	anchor.position = center
	add_child(anchor)
	var tag := Label3D.new()
	tag.text = label
	tag.font_size = 38
	tag.modulate = Color(0.92, 0.86, 0.68)
	tag.outline_size = 6
	tag.outline_modulate = Color(0.04, 0.04, 0.04, 0.92)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0.0, 1.55, 0.0)
	tag.no_depth_test = false
	anchor.add_child(tag)
	return anchor


# --- Player ------------------------------------------------------------------

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = PLAYER_START
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_snap_length = 0.3
	var height := float(HUB_HEIGHTS.get(player_species, 1.0))
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = clampf(height * 0.28, 0.2, 0.45)
	capsule.height = maxf(height, capsule.radius * 2.0 + 0.05)
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	player.add_child(shape)
	add_child(player)
	player_yaw = PI
	player.rotation.y = player_yaw

	player_model = _make_model(player_species, height)
	player.add_child(player_model)
	player_ap = _anim_player(player_model)
	player_height = height
	player_model_id = player_species
	_play(player_ap, "idle")
	_add_blob_shadow(player, clampf(height * 0.9, 0.7, 1.9), clampf(height * 0.62, 0.45, 1.25))

	var rim := OmniLight3D.new()
	rim.position = Vector3(0.0, height + 0.5, 1.0)
	rim.light_color = Color(1.0, 0.82, 0.60)
	rim.light_energy = 0.45
	rim.omni_range = 3.5
	player.add_child(rim)
	_player_dust = _add_footstep_dust(player)

	_camera = Camera3D.new()
	_camera.fov = CAM_FOV
	_camera.near = 0.05
	_camera.far = 120.0
	_camera.current = true
	_cam_probe.radius = 0.18
	add_child(_camera)
	_update_camera(0.0)


## Rebuilds the controlled leader model/capsule (F6, DebugPartySelector, HUB_CAMERA).
func _set_player_species(id: String) -> void:
	id = id.to_lower()
	if not HUB_HEIGHTS.has(id):
		return
	if player_model != null and is_instance_valid(player_model):
		player_model.queue_free()
	player_species = id
	player_height = float(HUB_HEIGHTS[id])
	player_model_id = id
	player_model = _make_model(id, player_height)
	player.add_child(player_model)
	player_ap = _anim_player(player_model)
	for child in player.get_children():
		var shape_node := child as CollisionShape3D
		if shape_node == null:
			continue
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule == null:
			continue
		capsule.radius = clampf(player_height * 0.28, 0.2, 0.45)
		capsule.height = maxf(player_height, capsule.radius * 2.0 + 0.05)
		shape_node.position.y = capsule.height * 0.5
		break
	_play(player_ap, "idle")
	_apply_toon_to_actor(player)
	_sync_demo_party_leader(id)
	_refresh_hud_help_label()
	_refresh_gate_leader_strip()


func _build_enemy() -> void:
	# The hub has no enemies: ambient NPCs only.
	pass


# --- Ambient NPCs (H2) -------------------------------------------------------

func _build_npcs() -> void:
	for spec in HUB_NPC_SPECS:
		_spawn_npc_spec(spec)


func _spawn_npc(id: String, pos: Vector3, line: String) -> void:
	_spawn_npc_spec({"id": id, "role": "NPC", "pos": pos, "yaw": PI, "icon": "question", "patrol": true, "line": line})


func _spawn_npc_spec(spec: Dictionary) -> void:
	var id := str(spec.get("id", "bulbasaur"))
	var pos: Vector3 = spec.get("pos", Vector3.ZERO)
	var line := str(spec.get("line", ""))
	var role := str(spec.get("role", "NPC"))
	var base_yaw := float(spec.get("yaw", PI))
	var icon_kind := str(spec.get("icon", "question"))
	var patrol_enabled := bool(spec.get("patrol", true))
	var height := float(HUB_HEIGHTS.get(id, 1.0))

	var body := StaticBody3D.new()
	body.name = "Npc_%s" % id
	body.position = pos
	body.rotation.y = base_yaw
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

	var model := _make_model(id, height)
	body.add_child(model)
	_add_blob_shadow(body, clampf(height * 0.85, 0.6, 1.1), clampf(height * 0.62, 0.5, 0.9))
	var ap := _anim_player(model)
	_play_idle(ap)
	_apply_toon_to_actor(body)

	var top := _actor_visual_top(body)
	var plate := NAMEPLATE.new()
	plate.display_name = str(HUB_NAMES.get(id, id.to_upper()))
	plate.role_text = role
	plate.style_id = "unit_card"
	plate.position = Vector3(0.0, top + 0.45, 0.0)
	body.add_child(plate)
	_name_labels.append({"node": plate, "owner": body})

	var icon_entry := _add_npc_state_icon(body, plate, icon_kind, top)
	var wps: Array[Vector3] = []
	if patrol_enabled:
		wps = _npc_waypoints(pos, _npcs.size())
	else:
		wps.append(pos)

	_npcs.append({
		"node": body,
		"model": model,
		"ap": ap,
		"id": id,
		"role": role,
		"name": str(HUB_NAMES.get(id, id.to_upper())),
		"height": height,
		"dialogue": line,
		"base_yaw": base_yaw,
		"plate": plate,
		"icon_entry": icon_entry,
		"talked": false,
		"home_pos": pos,
		"waypoints": wps,
		"wp_idx": 0,
		"state": "idle",
		"pause_timer": 0.6 + float(_npcs.size()) * 0.4,
		"walk_speed": 1.25 if patrol_enabled else 0.0,
		"breath_phase": float(_npcs.size()) * 2.1,
		"greet_timer": 0.0,
		"greeted": false,
	})


func _add_npc_state_icon(body: Node3D, plate: Node3D, icon_kind: String, top: float) -> Dictionary:
	var tex: Texture2D = ICON_ALERT if icon_kind == "alert" else ICON_QUESTION
	var tint := Color(1.0, 0.86, 0.28) if icon_kind == "alert" else Color(0.94, 0.96, 0.88)
	var icon := STATE_ICON.new()
	icon.name = "StateIcon"
	icon.setup(tex, tint)
	var start_y := top + 1.15
	icon.position = Vector3(0.0, start_y, 0.0)
	body.add_child(icon)
	var entry := {
		"sprite": icon,
		"plate": plate,
		"base_y": start_y,
		"base_scale": clampf(top / 1.25, 0.48, 0.88),
		"phase": _rng.randf_range(0.0, TAU),
		"pop": 0.0,
	}
	_state_icons.append(entry)
	return entry


func _update_state_icons(delta: float) -> void:
	for i in range(_state_icons.size() - 1, -1, -1):
		var entry := _state_icons[i]
		var icon := entry.get("sprite") as Node3D
		if icon == null or not is_instance_valid(icon):
			_state_icons.remove_at(i)
			continue
		var pop := maxf(0.0, float(entry.get("pop", 0.0)) - delta * 4.0)
		entry["pop"] = pop
		var dist := 9.0
		if _camera != null:
			dist = _camera.global_position.distance_to(icon.global_position)
		var s := (1.0 + pop * 0.32) * clampf(0.50 + dist / 18.0, 0.45, 0.95)
		var total := s * float(entry.get("base_scale", 0.72))
		icon.scale = Vector3(total, total, total)
		var base := float(entry.get("base_y", 1.5))
		var plate := entry.get("plate") as Node3D
		if plate != null and is_instance_valid(plate) and plate.has_method("card_top_local"):
			base = float(plate.card_top_local()) + 0.46 * total + 0.10
			entry["base_y"] = base
		icon.position.y = base + sin(_atmo_time * 2.4 + float(entry.get("phase", 0.0))) * 0.04 + pop * 0.12


func _actor_visual_top(body: Node3D) -> float:
	var top := 0.0
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var box := mi.global_transform * mi.mesh.get_aabb()
		top = maxf(top, box.position.y + box.size.y - body.global_position.y)
	return maxf(top, 0.4)


func _update_name_labels() -> void:
	if _camera == null:
		return
	for entry in _name_labels:
		var tag := entry.get("node") as Node3D
		var owner := entry["owner"] as Node3D
		if tag == null or not is_instance_valid(tag) or owner == null or not is_instance_valid(owner):
			continue
		var dist := _camera.global_position.distance_to(tag.global_position)
		var s := clampf(0.42 + (dist - 4.0) * 0.010, 0.34, 0.54)
		if tag.has_method("set_distance_scale"):
			tag.set_distance_scale(s)
		else:
			tag.scale = Vector3(s, s, s)


func _freeze_npc_patrol() -> bool:
	return _scenario in ["HUB_BOOT", "HUB_INTERACTION", "HUB_STATE"]


func _npc_waypoints(home: Vector3, idx: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var forbidden := [GATE_POS, GUILD_POS, PLAYER_START, BOARD_POS, PLOT_EAST]
	for k in 4:
		var ang := float(idx) * 1.7 + TAU * float(k) / 4.0
		var p := home + Vector3(cos(ang), 0.0, sin(ang)) * 1.6
		p.x = clampf(p.x, -PLAZA_HALF_X + 1.5, PLAZA_HALF_X - 1.5)
		p.z = clampf(p.z, -PLAZA_HALF_Z + 1.5, PLAZA_HALF_Z - 1.5)
		var clear := true
		for f in forbidden:
			if Vector2(p.x - f.x, p.z - f.z).length() < 2.6:
				clear = false
				break
		if clear:
			out.append(p)
	if out.is_empty():
		out.append(home)
	return out


func _update_npc_life(delta: float) -> void:
	var ppos := player.global_position
	for npc in _npcs:
		var body: Node3D = npc["node"]
		if not is_instance_valid(body):
			continue
		var model := npc.get("model") as Node3D
		var ap := npc.get("ap") as AnimationPlayer
		var breath := float(npc.get("breath_phase", 0.0))
		var hop := 0.0
		var gt := float(npc.get("greet_timer", 0.0))
		if gt > 0.0:
			gt = maxf(gt - delta, 0.0)
			npc["greet_timer"] = gt
			hop = sin((1.0 - gt / 0.45) * PI) * 0.12
		if model != null:
			model.scale.y = 1.0 + 0.025 * sin(_atmo_time * 2.6 + breath)
			model.position.y = hop
		var to := ppos - body.global_position
		to.y = 0.0
		var dist := to.length()
		var talking: bool = _npc_talking and _npc_target.get("node") == body
		if talking or (dist < 4.2 and dist > 0.001):
			npc["state"] = "greet"
			if dist > 0.001:
				body.rotation.y = lerp_angle(body.rotation.y, atan2(to.x, to.z),
					clampf(delta * 5.0, 0.0, 1.0))
			if not bool(npc.get("greeted", false)):
				npc["greeted"] = true
				npc["greet_timer"] = 0.45
			_play_idle(ap)
			continue
		npc["greeted"] = false
		var yaw := float(npc.get("base_yaw", 0.0))
		var waypoints: Array = npc.get("waypoints", [])
		if _freeze_npc_patrol() or waypoints.size() <= 1:
			npc["state"] = "idle"
			body.rotation.y = lerp_angle(body.rotation.y, yaw, clampf(delta * 2.5, 0.0, 1.0))
			_play_idle(ap)
			continue
		if str(npc.get("state", "idle")) == "idle":
			npc["pause_timer"] = float(npc.get("pause_timer", 0.0)) - delta
			body.rotation.y = yaw + 0.35 * sin(_atmo_time * 0.8 + breath)
			if model != null:
				model.position.y = 0.0
			_play_idle(ap)
			if float(npc["pause_timer"]) <= 0.0:
				npc["state"] = "walk"
			continue
		var wp: Vector3 = waypoints[int(npc.get("wp_idx", 0)) % waypoints.size()]
		var step := wp - body.global_position
		step.y = 0.0
		if step.length() < 0.18:
			npc["wp_idx"] = (int(npc.get("wp_idx", 0)) + 1) % waypoints.size()
			npc["state"] = "idle"
			npc["pause_timer"] = 0.9 + 0.35 * sin(_atmo_time * 0.7 + breath)
			_play_idle(ap)
			continue
		var dir := step.normalized()
		body.global_position += dir * float(npc.get("walk_speed", 1.25)) * delta
		body.rotation.y = lerp_angle(body.rotation.y, atan2(dir.x, dir.z),
			clampf(delta * 7.0, 0.0, 1.0))
		if ap != null and ap.has_animation("walk"):
			_play(ap, "walk")
		elif ap != null and ap.has_animation("run"):
			_play(ap, "run")
		else:
			_play_idle(ap)
		if model != null:
			model.position.y = absf(sin(_atmo_time * 8.0)) * 0.04


# --- Interaction (H3 weighted proximity + facing cone) -------------------------

func _targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for npc in _npcs:
		out.append({
			"kind": "npc", "id": str(npc["id"]), "name": str(npc["name"]),
			"action": "TALK", "pos": (npc["node"] as Node3D).global_position,
			"radius": NPC_RADIUS, "npc": npc,
		})
	out.append({
		"kind": "gate", "id": "gate", "name": "EXPEDITION GATE",
		"action": "OPEN", "pos": BOARD_POS, "radius": GATE_RADIUS, "npc": {},
	})
	out.append({
		"kind": "guild", "id": "guild", "name": "GUILD HALL DESK",
		"action": "OPEN", "pos": GUILD_POS + Vector3(1.3, 0.0, 0.0),
		"radius": GUILD_RADIUS, "npc": {},
	})
	out.append({
		"kind": "plot", "id": "plot_a", "name": "EXPANSION PLOT A",
		"action": "INSPECT", "pos": PLOT_EAST, "radius": PLOT_RADIUS,
		"npc": {}, "marker": _plot_markers[0] if _plot_markers.size() > 0 else null,
	})
	out.append({
		"kind": "plot", "id": "plot_b", "name": "EXPANSION PLOT B",
		"action": "INSPECT", "pos": PLOT_SOUTHEAST, "radius": PLOT_RADIUS,
		"npc": {}, "marker": _plot_markers[1] if _plot_markers.size() > 1 else null,
	})
	return out


func _nearest_target() -> Dictionary:
	var best: Dictionary = {}
	var best_score := INF
	var forward := Vector2(sin(player_yaw), cos(player_yaw))
	for t in _targets():
		var pos: Vector3 = t["pos"]
		var delta_xz := Vector2(pos.x - player.global_position.x, pos.z - player.global_position.z)
		var d := delta_xz.length()
		if d > float(t["radius"]):
			continue
		var dot := forward.dot(delta_xz / d) if d > 0.05 else 1.0
		var score := d - maxf(dot, -0.25) * 0.45
		if score < best_score:
			best = t
			best_score = score
	return best


func _update_npcs(delta: float) -> void:
	_update_npc_life(delta)
	if _ui_open or _npc_talking:
		_active_target_id = ""
		_active_target_kind = ""
		if _npc_prompt != null:
			_npc_prompt.hide_prompt()
		return
	var target := _nearest_target()
	var interact := Input.is_action_pressed("lab_interact")
	var z_now := Input.is_physical_key_pressed(KEY_Z)
	var just := (interact and not _last_interact) or (z_now and not _last_z)
	_last_interact = interact
	_last_z = z_now

	if target.is_empty():
		_active_target_id = ""
		_active_target_kind = ""
		if _npc_prompt != null:
			_npc_prompt.hide_prompt()
		return
	_active_target_id = str(target["id"])
	_active_target_kind = str(target["kind"])
	if _npc_prompt != null:
		_npc_prompt.show_prompt(str(target["name"]), str(target["action"]), false, "E")
	if just:
		_activate_target(target)


func _activate_target(target: Dictionary) -> void:
	match str(target["kind"]):
		"npc":
			_open_npc_dialogue(target["npc"] as Dictionary)
		"gate":
			_open_gate()
		"guild":
			_open_guild()
		"plot":
			_open_plot_dialogue(target)


func _interact_with_active() -> bool:
	var target := _nearest_target()
	if target.is_empty():
		return false
	_active_target_id = str(target["id"])
	_active_target_kind = str(target["kind"])
	_activate_target(target)
	return true


# --- Minimap (H4; SubViewport D-1064) -----------------------------------------

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
	mi.layers = MINIMAP_MASK
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_minimap_map() -> void:
	var floor_col := Color(0.18, 0.15, 0.14)
	var plaza_col := Color(0.29, 0.25, 0.22)
	var wall_col := Color(0.10, 0.08, 0.09)
	_minimap_box(Vector3(PLAZA_HALF_X * 2.0 + 2.0, 0.4, PLAZA_HALF_Z * 2.0 + 2.0), Vector3(0.0, -0.2, 0.0), floor_col)
	_minimap_box(Vector3(12.0, 0.2, 10.0), Vector3(0.0, 0.05, 1.0), plaza_col)
	_minimap_box(Vector3(2.4, 0.2, 7.0), Vector3(0.0, 0.06, -6.5), plaza_col)
	_minimap_box(Vector3(0.7, PLAZA_WALL_HEIGHT, PLAZA_HALF_Z * 2.0), Vector3(-PLAZA_HALF_X - 0.25, 1.6, 0.0), wall_col)
	_minimap_box(Vector3(0.7, PLAZA_WALL_HEIGHT, PLAZA_HALF_Z * 2.0), Vector3(PLAZA_HALF_X + 0.25, 1.6, 0.0), wall_col)
	_minimap_box(Vector3(PLAZA_HALF_X * 2.0 + 1.0, PLAZA_WALL_HEIGHT, 0.7), Vector3(0.0, 1.6, PLAZA_HALF_Z + 0.25), wall_col)
	_minimap_box(Vector3(11.0, PLAZA_WALL_HEIGHT, 0.7), Vector3(-8.5, 1.6, -PLAZA_HALF_Z - 0.25), wall_col)
	_minimap_box(Vector3(11.0, PLAZA_WALL_HEIGHT, 0.7), Vector3(8.5, 1.6, -PLAZA_HALF_Z - 0.25), wall_col)
	for cpos in [
		Vector3(-PLAZA_HALF_X + 0.8, 1.6, -PLAZA_HALF_Z + 0.8),
		Vector3(PLAZA_HALF_X - 0.8, 1.6, -PLAZA_HALF_Z + 0.8),
		Vector3(-PLAZA_HALF_X + 0.8, 1.6, PLAZA_HALF_Z - 0.8),
		Vector3(PLAZA_HALF_X - 0.8, 1.6, PLAZA_HALF_Z - 0.8),
	]:
		_minimap_box(Vector3(3.1, PLAZA_WALL_HEIGHT, 3.1), cpos, wall_col)
	_minimap_box(Vector3(4.2, 0.3, 1.2), GATE_POS + Vector3(0.0, 0.15, 0.0), Color(0.95, 0.68, 0.25))
	_minimap_box(Vector3(3.6, 1.0, 7.0), Vector3(-11.8, 0.5, -2.0), Color(0.55, 0.82, 0.32))
	_minimap_box(Vector3(4.2, 0.25, 4.2), PLOT_EAST + Vector3(0.0, 0.12, 0.0), Color(0.42, 0.36, 0.30))
	_minimap_box(Vector3(4.2, 0.25, 4.2), PLOT_SOUTHEAST + Vector3(0.0, 0.12, 0.0), Color(0.42, 0.36, 0.30))


func _build_minimap() -> void:
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
	_minimap_camera.cull_mask = MINIMAP_MASK
	_minimap_camera.current = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0
	_minimap_camera.environment = env
	_minimap_camera.position = Vector3(0.0, 30.0, 0.0)
	_minimap_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_minimap_viewport.add_child(_minimap_camera)

	_minimap_layer = CanvasLayer.new()
	_minimap_layer.name = "MinimapHud"
	_minimap_layer.layer = 15
	_minimap_layer.add_to_group("overworld_hud")
	add_child(_minimap_layer)

	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	holder.offset_left = -152.0
	holder.offset_top = 12.0
	holder.offset_right = -14.0
	holder.offset_bottom = 162.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap_layer.add_child(holder)

	var frame := PanelContainer.new()
	frame.position = Vector2.ZERO
	frame.size = Vector2(138, 150)
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.05, 0.07, 0.10, 0.90)
	fs.border_color = Color(0.84, 0.98, 0.40, 0.95)
	fs.border_width_left = 3
	fs.border_width_top = 3
	fs.border_width_right = 3
	fs.border_width_bottom = 3
	fs.content_margin_left = 6
	fs.content_margin_right = 6
	fs.content_margin_top = 4
	fs.content_margin_bottom = 6
	frame.add_theme_stylebox_override("panel", fs)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(vb)

	var cap := Label.new()
	cap.text = "PLAZA MAP"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 11)
	cap.add_theme_color_override("font_color", Color(0.84, 0.98, 0.40))
	vb.add_child(cap)

	var box := Control.new()
	box.custom_minimum_size = Vector2(MINIMAP_DISPLAY_SIZE, MINIMAP_DISPLAY_SIZE)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(box)

	_minimap_rect = TextureRect.new()
	_minimap_rect.texture = _minimap_viewport.get_texture()
	_minimap_rect.position = Vector2.ZERO
	_minimap_rect.size = Vector2(MINIMAP_DISPLAY_SIZE, MINIMAP_DISPLAY_SIZE)
	_minimap_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_minimap_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_minimap_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_minimap_rect)

	_marker_root = Control.new()
	_marker_root.position = Vector2.ZERO
	_marker_root.size = Vector2(MINIMAP_DISPLAY_SIZE, MINIMAP_DISPLAY_SIZE)
	_marker_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_marker_root)

	_add_minimap_marker(player, Color(0.28, 0.62, 1.0, 1.0), "player")
	for f in _followers:
		_add_minimap_marker(f["node"], Color(0.45, 0.78, 1.0, 1.0), "ally")
	for node in get_tree().get_nodes_in_group("minimap_npc"):
		if node is Node3D:
			_add_minimap_marker(node as Node3D, Color(1.0, 1.0, 1.0, 1.0), "npc")


func _add_minimap_marker(node: Node3D, color: Color, kind: String) -> void:
	var dot_size := 10.0 if kind == "player" else (7.0 if kind == "ally" else 8.0)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(dot_size, dot_size)
	dot.size = Vector2(dot_size, dot_size)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.03, 0.03, 0.04, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(dot_size * 0.5))
	dot.add_theme_stylebox_override("panel", style)
	dot.z_index = 4 if kind == "player" else (3 if kind == "ally" else 2)
	_marker_root.add_child(dot)
	_minimap_markers.append({"rect": dot, "node": node, "kind": kind, "size": dot_size})


func _update_minimap() -> void:
	if _minimap_camera == null or _marker_root == null or player == null:
		return
	_minimap_camera.global_position = Vector3(player.global_position.x * 0.35, 30.0, player.global_position.z * 0.35)
	var vp := Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	var rect_size := _marker_root.size
	for m in _minimap_markers:
		var rect: Control = m["rect"]
		var node: Node3D = m["node"]
		var show := is_instance_valid(node)
		if show and m["kind"] == "ally" and not _party_visible:
			show = false
		if show:
			var view := _minimap_camera.unproject_position(node.global_position + Vector3(0.0, 0.7, 0.0))
			var pos := Vector2(view.x / vp.x, view.y / vp.y) * rect_size
			if pos.x < 0.0 or pos.y < 0.0 or pos.x > rect_size.x or pos.y > rect_size.y:
				show = false
			else:
				rect.position = pos - Vector2(m["size"], m["size"]) * 0.5
		rect.visible = show


# --- UI & Neo-Brutalist Modals (H4, H5, C8, D-1165) --------------------------

func _sync_hud_visibility() -> void:
	var show_hud := not (_gate_open or _guild_open or _status_open or _npc_talking)
	if _arrival != null and is_instance_valid(_arrival):
		show_hud = false
	get_tree().set_group("overworld_hud", "visible", show_hud)


# --- Arrival cutscene hooks (prototype, inert without a transition node) -----

func _start_arrival_cutscene() -> void:
	var transition := get_tree().get_first_node_in_group("nature_hub_transition")
	if transition == null or not transition.has_method("notify_hub_ready"):
		return
	if player == null:
		return
	player.global_position = Vector3(0.0, player.global_position.y, 0.0)
	player.velocity = Vector3.ZERO
	player.rotation.y = player_yaw
	_cam_yaw = player_yaw
	_cam_smooth_ready = false
	_arrival = HubArrivalCutscene.attach(self, transition)
	transition.notify_hub_ready(self)
	_sync_hud_visibility()


func _end_arrival() -> void:
	_arrival = null
	_sync_hud_visibility()


func _build_ui() -> void:
	# D-1165: _ui_layer and _panel_layer stay outside "overworld_hud" so opening
	# StatusScreen or modals hides _help_layer/_minimap_layer without hiding modals.
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "HubUi"
	_ui_layer.layer = 22
	add_child(_ui_layer)

	_npc_hud = NPC_HUD.new()
	_npc_hud.name = "NpcDialogue"
	_ui_layer.add_child(_npc_hud)
	_npc_hud.setup(2)
	_npc_hud.close()

	_npc_prompt = NPC_PROMPT.new()
	_npc_prompt.name = "InteractPrompt"
	_ui_layer.add_child(_npc_prompt)
	_npc_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_npc_prompt.offset_left = -200.0
	_npc_prompt.offset_top = -72.0
	_npc_prompt.offset_right = 200.0
	_npc_prompt.offset_bottom = -12.0
	_npc_prompt.visible = false

	_panel_layer = CanvasLayer.new()
	_panel_layer.name = "HubPanels"
	_panel_layer.layer = 30
	add_child(_panel_layer)

	_status = STATUS_SCREEN.new()
	_status.name = "GuildStatus"
	_panel_layer.add_child(_status)
	_status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status.closed.connect(_on_status_closed)

	_build_gate_panel()
	_build_guild_panel()


func _build_hud() -> void:
	pass


func _build_hud_help() -> void:
	_help_layer = CanvasLayer.new()
	_help_layer.name = "HubHelpLayer"
	_help_layer.layer = 20
	_help_layer.add_to_group("overworld_hud")
	var box := PanelContainer.new()
	box.position = Vector2(16, 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.10, 0.86)
	sb.border_color = Color(0.84, 0.98, 0.40, 0.95)
	sb.border_width_left = 4
	sb.content_margin_left = 12
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", sb)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	box.add_child(vbox)

	var label := Label.new()
	label.name = "HubHelp"
	label.text = "CRAWLMON 3D HUB // CENTRAL PLAZA"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.84, 0.98, 0.40))
	vbox.add_child(label)

	_hud_help_mode_label = Label.new()
	_hud_help_mode_label.name = "HubModeSummary"
	_hud_help_mode_label.add_theme_font_size_override("font_size", 12)
	_hud_help_mode_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.56))
	vbox.add_child(_hud_help_mode_label)
	_refresh_hud_help_label()

	var help := Label.new()
	help.text = "W/S/Arrows: move · A/D or Right Mouse: camera · E/Z: interact · 1: party · F6: leader · F7: light · Esc: quit"
	help.add_theme_font_size_override("font_size", 11)
	help.add_theme_color_override("font_color", Color(0.92, 0.90, 0.82))
	vbox.add_child(help)
	_help_layer.add_child(box)
	add_child(_help_layer)


func _nature_preview_text() -> String:
	var ids: Array[String] = NATURE_DATA.get_all_nature_ids()
	if ids.is_empty():
		return "HARDY · PURE DISCIPLINE (UNALTERED STAT BASELINE)"
	var nid := ids[posmod(_preview_nature_index, ids.size())]
	var nd: Dictionary = NATURE_DATA.get_nature(nid)
	var nname := str(nd.get("name", nid)).to_upper()
	if nid in ["hardy", "docile"]:
		return "%s · PURE DISCIPLINE (UNALTERED STAT BASELINE)" % nname
	var mods: Dictionary = nd.get("mods", {})
	var parts: Array[String] = []
	for stat_key in ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]:
		var val := int(mods.get(stat_key, 0))
		if val != 0:
			parts.append("%+d %s" % [val, stat_key])
	return "%s (%s)" % [nname, ", ".join(parts)]


func _roll_gate_nature_preview() -> void:
	var ids: Array[String] = NATURE_DATA.get_all_nature_ids()
	if ids.size() <= 1:
		return
	_preview_nature_index = posmod(_preview_nature_index + 1 + _rng.randi_range(0, ids.size() - 2), ids.size())
	if _gate_nature_lbl != null:
		_gate_nature_lbl.text = "EXPEDITION NATURE PREVIEW (R18-Q4): %s" % _nature_preview_text()


func _refresh_gate_leader_strip() -> void:
	if _gate_leader_name_lbl != null:
		_gate_leader_name_lbl.text = "ACTIVE LEADER: %s  (HEIGHT %.2fm)" % [
			str(HUB_NAMES.get(player_model_id, player_model_id.to_upper())),
			float(HUB_HEIGHTS.get(player_model_id, 1.0)),
		]
	if _gate_leader_portrait != null:
		_gate_leader_portrait.texture = _portrait_for_species(player_model_id)


func _build_gate_panel() -> void:
	_gate_panel = Control.new()
	_gate_panel.name = "GatePanel"
	_gate_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gate_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_gate_panel.visible = false
	_panel_layer.add_child(_gate_panel)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.05, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_gate_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gate_panel.add_child(center)

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(880, 560)
	center.add_child(holder)

	var shadow := ColorRect.new()
	shadow.position = Vector2(10, 10)
	shadow.size = Vector2(880, 560)
	shadow.color = Color(0.0, 0.0, 0.0, 0.82)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shadow)

	var frame := PanelContainer.new()
	frame.size = Vector2(880, 560)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.095, 0.135, 0.98)
	style.border_color = Color(0.94, 0.93, 0.88, 0.98)
	style.set_border_width_all(4)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	frame.add_theme_stylebox_override("panel", style)
	holder.add_child(frame)

	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Courier New"])
	mono.font_weight = 700

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	frame.add_child(root_box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_box.add_child(header)

	var title := Label.new()
	title.text = "EXPEDITION GATE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", mono)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.84, 0.98, 0.40))
	header.add_child(title)

	var badge := PanelContainer.new()
	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color(0.84, 0.98, 0.40)
	b_style.content_margin_left = 10
	b_style.content_margin_right = 10
	b_style.content_margin_top = 4
	b_style.content_margin_bottom = 4
	badge.add_theme_stylebox_override("panel", b_style)
	var b_lbl := Label.new()
	b_lbl.text = "NEW EXPEDITION (C8) // PROTOTYPE"
	b_lbl.add_theme_font_override("font", mono)
	b_lbl.add_theme_font_size_override("font_size", 13)
	b_lbl.add_theme_color_override("font_color", Color(0.06, 0.15, 0.22))
	badge.add_child(b_lbl)
	header.add_child(badge)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 3)
	rule.color = Color(0.84, 0.98, 0.40, 0.9)
	root_box.add_child(rule)

	var c8_lbl := Label.new()
	c8_lbl.text = "CONTRACT (C8): Title [NEW GAME / CONTINUE] handle save slots · Hub Gate dispatches [NEW EXPEDITION] only."
	c8_lbl.add_theme_font_override("font", mono)
	c8_lbl.add_theme_font_size_override("font_size", 12)
	c8_lbl.add_theme_color_override("font_color", Color(0.70, 0.84, 0.90))
	root_box.add_child(c8_lbl)

	# Portrait strip (active leader + clickable quick-switch among all 6 leaders).
	var roster_strip := PanelContainer.new()
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.08, 0.13, 0.19, 0.92)
	rs.border_width_left = 4
	rs.border_color = Color(0.84, 0.98, 0.40, 0.8)
	rs.content_margin_left = 10
	rs.content_margin_right = 10
	rs.content_margin_top = 6
	rs.content_margin_bottom = 6
	roster_strip.add_theme_stylebox_override("panel", rs)
	root_box.add_child(roster_strip)

	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 10)
	roster_strip.add_child(rrow)

	_gate_leader_portrait = TextureRect.new()
	_gate_leader_portrait.custom_minimum_size = Vector2(46, 46)
	_gate_leader_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gate_leader_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rrow.add_child(_gate_leader_portrait)

	_gate_leader_name_lbl = Label.new()
	_gate_leader_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gate_leader_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gate_leader_name_lbl.add_theme_font_override("font", mono)
	_gate_leader_name_lbl.add_theme_font_size_override("font_size", 15)
	_gate_leader_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.88))
	rrow.add_child(_gate_leader_name_lbl)

	for sid in PLAYABLE_LEADERS:
		var chip := Button.new()
		chip.custom_minimum_size = Vector2(36, 36)
		chip.tooltip_text = "Switch leader to %s" % str(HUB_NAMES.get(sid, sid.to_upper()))
		chip.icon = _portrait_for_species(sid)
		chip.expand_icon = true
		chip.pressed.connect(_set_player_species.bind(sid))
		rrow.add_child(chip)
	_refresh_gate_leader_strip()

	var slot_label := Label.new()
	slot_label.text = "LOCATION / STATUS"
	slot_label.add_theme_font_override("font", mono)
	slot_label.add_theme_font_size_override("font_size", 13)
	slot_label.add_theme_color_override("font_color", Color(0.64, 0.74, 0.80))
	root_box.add_child(slot_label)

	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 6)
	list_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(list_box)

	for i in GATE_LINES.size():
		var rbox := PanelContainer.new()
		var rstyle := StyleBoxFlat.new()
		rstyle.bg_color = Color(0.08, 0.14, 0.20, 0.85)
		rstyle.border_width_left = 4
		rstyle.border_color = Color(0.35, 0.42, 0.48, 0.7)
		rstyle.content_margin_left = 10
		rstyle.content_margin_right = 10
		rstyle.content_margin_top = 4
		rstyle.content_margin_bottom = 4
		rbox.add_theme_stylebox_override("panel", rstyle)
		var btn := Button.new()
		btn.text = GATE_LINES[i]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		btn.add_theme_font_override("font", mono)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func() -> void:
			_gate_index = i
			_gate_refresh_rows()
			_gate_confirm()
		)
		rbox.add_child(btn)
		list_box.add_child(rbox)
		_gate_row_boxes.append(rbox)
		_gate_row_buttons.append(btn)

	# Nature Preview (R18-Q4) + First Expedition Briefing row.
	var meta_box := HBoxContainer.new()
	meta_box.add_theme_constant_override("separation", 10)
	root_box.add_child(meta_box)

	_gate_nature_lbl = Label.new()
	_gate_nature_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gate_nature_lbl.text = "EXPEDITION NATURE PREVIEW (R18-Q4): %s" % _nature_preview_text()
	_gate_nature_lbl.add_theme_font_override("font", mono)
	_gate_nature_lbl.add_theme_font_size_override("font_size", 13)
	_gate_nature_lbl.add_theme_color_override("font_color", Color(0.84, 0.98, 0.40))
	meta_box.add_child(_gate_nature_lbl)

	var roll_btn := Button.new()
	roll_btn.text = "[R] ROLL NATURE PREVIEW [DEBUG]"
	roll_btn.add_theme_font_override("font", mono)
	roll_btn.add_theme_font_size_override("font_size", 12)
	roll_btn.pressed.connect(_roll_gate_nature_preview)
	meta_box.add_child(roll_btn)

	_gate_brief_lbl = Label.new()
	_gate_brief_lbl.text = "FIRST EXPEDITION BRIEFING: 3D Exploration -> Preemptive Tackle Strike -> ATB Turn Combat."
	_gate_brief_lbl.add_theme_font_override("font", mono)
	_gate_brief_lbl.add_theme_font_size_override("font_size", 13)
	_gate_brief_lbl.add_theme_color_override("font_color", Color(0.82, 0.88, 0.92))
	root_box.add_child(_gate_brief_lbl)

	var note := Label.new()
	note.name = "GateNote"
	note.text = "Read-only Gate prototype. No expedition is started and GameState is not changed."
	note.add_theme_font_override("font", mono)
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.94, 0.77, 0.49))
	root_box.add_child(note)

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 12)
	root_box.add_child(footer_row)

	var footer := Label.new()
	footer.name = "GateFooter"
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.text = "[UP/DOWN] SELECT    [Z] BRIEF    [R] NATURE PREVIEW    [X/ESC] CLOSE"
	footer.add_theme_font_override("font", mono)
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.84, 0.88, 0.90))
	footer_row.add_child(footer)

	var brief_btn := Button.new()
	brief_btn.text = "BRIEF"
	brief_btn.pressed.connect(_gate_confirm)
	footer_row.add_child(brief_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.pressed.connect(_close_gate)
	footer_row.add_child(close_btn)
	_gate_refresh_rows()


func _gate_refresh_rows() -> void:
	for i in _gate_row_buttons.size():
		var selected := i == _gate_index
		_gate_row_buttons[i].text = ("▸ " if selected else "  ") + str(GATE_LINES[i])
		_gate_row_buttons[i].add_theme_color_override("font_color",
			Color(0.96, 0.98, 0.88) if selected else Color(0.62, 0.68, 0.72))
		if i < _gate_row_boxes.size():
			var sb := _gate_row_boxes[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if sb != null:
				sb.bg_color = Color(0.11, 0.21, 0.28, 0.98) if selected else Color(0.07, 0.12, 0.18, 0.78)
				sb.border_color = Color(0.84, 0.98, 0.40) if selected else Color(0.28, 0.36, 0.42, 0.65)
				_gate_row_boxes[i].add_theme_stylebox_override("panel", sb)


func _gate_nav(step: int) -> void:
	_gate_index = posmod(_gate_index + step, GATE_LINES.size())
	_gate_refresh_rows()


func _gate_confirm() -> void:
	if _gate_row_buttons.is_empty():
		return
	if _gate_index == 0:
		_enter_murky_forest_expedition()  # D-1219: no roulette at the gate; the character keeps its Nature.
		return
	var note := _gate_panel.find_child("GateNote", true, false) as Label
	if note != null:
		note.text = "BRIEFING UNAVAILABLE IN THIS PROTOTYPE — %s" % str(GATE_LINES[_gate_index])


## D-1219: the gate has no Nature roulette. The leader keeps the Nature decided after the
## character selection (GameState.character_natures); `--nature=` still forces one for debug.
func _enter_murky_forest_expedition() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("roll_expedition_nature_and_prepare"):
		gs.call("roll_expedition_nature_and_prepare", str(_args.get("nature", "")))
		_close_gate()
		get_tree().change_scene_to_file(str(gs.get("MURKY_FOREST_3D")))


func _open_gate() -> void:
	if _ui_open:
		return
	_gate_open = true
	_ui_open = true
	_refresh_gate_leader_strip()
	_gate_panel.visible = true
	if _npc_prompt != null:
		_npc_prompt.hide_prompt()
	_sync_hud_visibility()
	print("[HUB] gate panel open")


func _close_gate() -> void:
	_gate_open = false
	_gate_panel.visible = false
	_ui_open = false
	_sync_hud_visibility()


func _build_guild_panel() -> void:
	_guild_panel = Control.new()
	_guild_panel.name = "GuildPanel"
	_guild_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guild_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_guild_panel.visible = false
	_panel_layer.add_child(_guild_panel)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.05, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_guild_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guild_panel.add_child(center)

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(760, 440)
	center.add_child(holder)

	var shadow := ColorRect.new()
	shadow.position = Vector2(10, 10)
	shadow.size = Vector2(760, 440)
	shadow.color = Color(0.0, 0.0, 0.0, 0.82)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shadow)

	var frame := PanelContainer.new()
	frame.size = Vector2(760, 440)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.095, 0.135, 0.98)
	style.border_color = Color(0.94, 0.93, 0.88, 0.98)
	style.set_border_width_all(4)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	frame.add_theme_stylebox_override("panel", style)
	holder.add_child(frame)

	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Courier New"])
	mono.font_weight = 700

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	frame.add_child(vb)

	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var title := Label.new()
	title.text = "GUILD HALL // TACTICAL DESK"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", mono)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.84, 0.98, 0.40))
	hdr.add_child(title)

	var gbadge := Label.new()
	gbadge.text = "GUILD // PROTOTYPE"
	gbadge.add_theme_font_override("font", mono)
	gbadge.add_theme_font_size_override("font_size", 14)
	gbadge.add_theme_color_override("font_color", Color(0.94, 0.77, 0.49))
	hdr.add_child(gbadge)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 3)
	rule.color = Color(0.84, 0.98, 0.40, 0.9)
	vb.add_child(rule)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(list)

	for i in GUILD_OPTIONS.size():
		var rbox := PanelContainer.new()
		var rstyle := StyleBoxFlat.new()
		rstyle.bg_color = Color(0.08, 0.14, 0.20, 0.85)
		rstyle.border_width_left = 4
		rstyle.border_color = Color(0.35, 0.42, 0.48, 0.7)
		rstyle.content_margin_left = 12
		rstyle.content_margin_right = 12
		rstyle.content_margin_top = 8
		rstyle.content_margin_bottom = 8
		rbox.add_theme_stylebox_override("panel", rstyle)
		var btn := Button.new()
		btn.text = GUILD_OPTIONS[i]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		btn.add_theme_font_override("font", mono)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func() -> void:
			_guild_index = i
			_guild_refresh_rows()
			_guild_confirm()
		)
		rbox.add_child(btn)
		list.add_child(rbox)
		_guild_row_boxes.append(rbox)
		_guild_row_labels.append(btn)

	_guild_detail_lbl = Label.new()
	_guild_detail_lbl.name = "GuildDetail"
	_guild_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_guild_detail_lbl.text = "[PROTOTYPE] Choose Inspect Active Party to open StatusScreen, or preview future Standby Roster options."
	_guild_detail_lbl.add_theme_font_override("font", mono)
	_guild_detail_lbl.add_theme_font_size_override("font_size", 14)
	_guild_detail_lbl.add_theme_color_override("font_color", Color(0.94, 0.77, 0.49))
	vb.add_child(_guild_detail_lbl)

	var footer := Label.new()
	footer.text = "[UP/DOWN] SELECT    [Z/ENTER] CONFIRM    [X/ESC] CLOSE"
	footer.add_theme_font_override("font", mono)
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.84, 0.88, 0.90))
	vb.add_child(footer)
	_guild_refresh_rows()


func _guild_refresh_rows() -> void:
	for i in _guild_row_labels.size():
		var selected := i == _guild_index
		var btn := _guild_row_labels[i]
		if btn != null:
			btn.text = ("▸ " if selected else "  ") + str(GUILD_OPTIONS[i])
			btn.add_theme_color_override("font_color",
				Color(0.96, 0.98, 0.88) if selected else Color(0.62, 0.68, 0.72))
		if i < _guild_row_boxes.size():
			var sb := _guild_row_boxes[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if sb != null:
				sb.bg_color = Color(0.11, 0.21, 0.28, 0.98) if selected else Color(0.07, 0.12, 0.18, 0.78)
				sb.border_color = Color(0.84, 0.98, 0.40) if selected else Color(0.28, 0.36, 0.42, 0.65)
				_guild_row_boxes[i].add_theme_stylebox_override("panel", sb)


func _guild_nav(step: int) -> void:
	_guild_index = posmod(_guild_index + step, GUILD_OPTIONS.size())
	_guild_refresh_rows()


func _guild_confirm() -> void:
	match _guild_index:
		0:
			_open_status_from_guild()
		1:
			if _guild_detail_lbl != null:
				_guild_detail_lbl.text = "[DEMO PREVIEW] Standby Roster & Guild Services are reserved for campaign progression in v2. No shop, heal, or save state is altered here."
		_:
			_close_guild()


func _open_guild() -> void:
	if _ui_open:
		return
	_guild_index = 0
	_guild_refresh_rows()
	_guild_open = true
	_ui_open = true
	_guild_panel.visible = true
	if _npc_prompt != null:
		_npc_prompt.hide_prompt()
	_sync_hud_visibility()
	print("[HUB] guild menu open")


func _open_status_from_guild() -> void:
	_guild_open = false
	_guild_panel.visible = false
	_status_open = true
	_ui_open = true
	if _party_for_status.is_empty():
		_build_demo_party()
	_status.open(_party_for_status, 0)
	_sync_hud_visibility()
	print("[HUB] guild status open, party=", _party_for_status.size())


func _close_guild() -> void:
	_guild_open = false
	_guild_panel.visible = false
	_status_open = false
	_status.visible = false
	_ui_open = false
	_sync_hud_visibility()


func _on_status_closed() -> void:
	_status_open = false
	_ui_open = false
	_sync_hud_visibility()


func _close_ui() -> void:
	if _gate_open:
		_close_gate()
	elif _guild_open or _status_open:
		_close_guild()
	elif _npc_talking:
		_close_npc_dialogue()


func _open_npc_dialogue(npc: Dictionary) -> void:
	if npc.is_empty() or (_ui_open and not _npc_talking):
		return
	_npc_talking = true
	_npc_target = npc
	_ui_open = false
	if _npc_prompt != null:
		_npc_prompt.hide_prompt()
	npc["talked"] = true
	var icon_entry: Dictionary = npc.get("icon_entry", {})
	var sicon := icon_entry.get("sprite") as Node
	if sicon != null and is_instance_valid(sicon) and sicon.has_method("set_state"):
		sicon.set_state(ICON_TALKED, Color(0.55, 0.95, 0.62))
		icon_entry["pop"] = 1.0
	_npc_hud.open(str(npc["name"]), str(npc["dialogue"]), "CLOSE")
	_npc_hud.set_portrait(_portrait_for(npc))
	set_dialogue_focus(npc["node"] as Node3D)
	_sync_hud_visibility()
	print("[HUB] dialogue open: ", npc["name"])


func _open_plot_dialogue(target: Dictionary) -> void:
	if _ui_open and not _npc_talking:
		return
	_npc_talking = true
	_npc_target = target
	_ui_open = false
	if _npc_prompt != null:
		_npc_prompt.hide_prompt()
	_npc_hud.open(
		str(target["name"]),
		"[PROTOTYPE] %s is clear and reserved for future base facilities. Nothing is built or sold in Hub v1." % str(target["name"]),
		"CLOSE"
	)
	_npc_hud.set_portrait(null)
	var marker := target.get("marker") as Node3D
	if marker != null:
		set_dialogue_focus(marker)
	_sync_hud_visibility()
	print("[HUB] plot inspected: ", target["name"])


func _close_npc_dialogue() -> void:
	_npc_talking = false
	_npc_target = {}
	if _npc_hud != null:
		_npc_hud.close()
	clear_dialogue_focus()
	_sync_hud_visibility()
	print("[HUB] dialogue closed")


func _portrait_for_species(id: String) -> Texture2D:
	var key := id.to_lower()
	var tex: Texture2D = PORTRAIT_ICON.get_icon(key)
	if tex == null and key.begins_with("dqt_"):
		tex = PORTRAIT_ICON.get_icon(key.substr(4))
	if tex == null and key == "dqt_healslime":
		tex = PORTRAIT_ICON.get_icon("slime")
	return tex


func _portrait_for(npc: Dictionary) -> Texture2D:
	return _portrait_for_species(str(npc.get("id", "")))


func _sync_demo_party_leader(id: String) -> void:
	if GameState.party.size() > 0 or _demo_party.is_empty():
		return
	_demo_party[0] = CharacterFactory.create(id, {"is_player": true})
	_party_for_status = _demo_party


func _build_demo_party() -> void:
	if GameState.party.size() > 0:
		_party_for_status = GameState.party
		return
	var lead := player_species if PLAYABLE_LEADERS.has(player_species) else "abra"
	_demo_party.clear()
	_demo_party.append(CharacterFactory.create(lead, {"is_player": true}))
	for mate in ["pancham", "gible", "dqt_slime"]:
		if mate != lead and _demo_party.size() < 3:
			_demo_party.append(CharacterFactory.create(mate, {"is_player": true}))
	_party_for_status = _demo_party


# --- Input / DebugPartySelector / Physics (F6, F7, 1, D-413) -----------------

func _cycle_leader() -> void:
	var idx := PLAYABLE_LEADERS.find(player_model_id)
	var next: String = str(PLAYABLE_LEADERS[(idx + 1) % PLAYABLE_LEADERS.size()])
	_set_player_species(next)


func debug_party_selector_blocked() -> bool:
	return _ui_open or _npc_talking or _active_target_kind != "" or not _nearest_target().is_empty()


func debug_party_selector_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for sid in PLAYABLE_LEADERS:
		entries.append({
			"name": str(HUB_NAMES.get(sid, sid.to_upper())),
			"species": sid,
			"leader": sid == player_model_id,
		})
	return entries


func debug_swap_party(index: int) -> Dictionary:
	if index < 0 or index >= PLAYABLE_LEADERS.size():
		return {"ok": false, "message": "Invalid leader index."}
	var sid := str(PLAYABLE_LEADERS[index])
	if sid == player_model_id:
		return {"ok": false, "message": "Already active leader."}
	_set_player_species(sid)
	var leader_name := str(HUB_NAMES.get(sid, sid.to_upper()))
	return {"ok": true, "message": "Leader: %s" % leader_name}


func _unhandled_input(event: InputEvent) -> void:
	if _arrival != null and is_instance_valid(_arrival):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_F6 and not _ui_open and not _npc_talking:
			_cycle_leader()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_F7 and not _ui_open and not _npc_talking:
			_cycle_lighting()
			get_viewport().set_input_as_handled()
			return
		if _gate_open:
			if key == KEY_ESCAPE or key == KEY_X:
				_close_gate()
			elif key == KEY_UP or key == KEY_W:
				_gate_nav(-1)
			elif key == KEY_DOWN or key == KEY_S:
				_gate_nav(1)
			elif key == KEY_R:
				_roll_gate_nature_preview()
			elif key == KEY_Z or key == KEY_ENTER:
				_gate_confirm()
			get_viewport().set_input_as_handled()
			return
		if _guild_open:
			if key == KEY_ESCAPE or key == KEY_X:
				_close_guild()
			elif key == KEY_UP or key == KEY_W:
				_guild_nav(-1)
			elif key == KEY_DOWN or key == KEY_S:
				_guild_nav(1)
			elif key == KEY_Z or key == KEY_ENTER:
				_guild_confirm()
			get_viewport().set_input_as_handled()
			return
		if _status_open:
			if key == KEY_ESCAPE or key == KEY_X:
				_close_guild()
				get_viewport().set_input_as_handled()
				return
			if _status == null or not _status.visible:
				_status_open = false
				_ui_open = false
				_sync_hud_visibility()
				return
		if _npc_talking:
			if key == KEY_ESCAPE or key == KEY_X:
				_close_npc_dialogue()
				get_viewport().set_input_as_handled()
				return
			if key == KEY_Z or key == KEY_E or key == KEY_ENTER:
				if _npc_hud != null and _npc_hud.is_typing():
					_npc_hud.finish_typing()
				else:
					_close_npc_dialogue()
				get_viewport().set_input_as_handled()
				return
		if _ui_open:
			return
		if key == KEY_ESCAPE:
			get_tree().quit()
			return
	super(event)
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_1:
		_refresh_hud_help_label()


func _physics_process(delta: float) -> void:
	if _arrival != null and is_instance_valid(_arrival):
		_arrival.apply(delta)
		_play_move(player_ap, false)
		return
	if _ui_open:
		if player != null:
			player.velocity = Vector3.ZERO
			player.move_and_slide()
			player.rotation.y = player_yaw
		if _player_dust != null:
			_player_dust.emitting = false
		if _npc_prompt != null:
			_npc_prompt.hide_prompt()
		_update_camera(delta)
		_update_followers(delta)
		_play_move(player_ap, false)
		return
	if _auto_nav_target != Vector3.INF:
		_drive_step(delta)
		return
	super(delta)
	_update_npcs(delta)


func _drive_step(delta: float) -> void:
	var to := _auto_nav_target - player.global_position
	to.y = 0.0
	var dir := Vector3.ZERO
	if to.length() > 0.05:
		dir = to.normalized()
	player.velocity = dir * SPEED
	player.move_and_slide()
	if dir.length_squared() > 0.001:
		player_yaw = lerp_angle(player_yaw, atan2(dir.x, dir.z), clampf(delta * TURN_RATE, 0.0, 1.0))
	player.rotation.y = player_yaw
	if _player_dust != null:
		_player_dust.emitting = dir.length_squared() > 0.01
	_update_camera(delta)
	_update_followers(delta)
	_update_enemy(delta)
	_update_npcs(delta)
	_play_move(player_ap, dir.length_squared() > 0.01)


# --- Debug scenarios (D-1204) ------------------------------------------------

func _run_async() -> void:
	_run_started_ms = Time.get_ticks_msec()
	await get_tree().process_frame
	if _view != "":
		await _run_view(_view)
		return
	if _scenario == "" and _args.has("quit"):
		await _frames(2)
		_check("hub_boot_quit", true, "direct --quit")
		_finish()
		return
	match _scenario:
		"HUB_BOOT":
			await _scenario_boot()
		"HUB_NAVIGATION":
			await _scenario_navigation()
		"HUB_INTERACTION":
			await _scenario_interaction()
		"HUB_GATE":
			await _scenario_gate()
		"HUB_GATE_EXPEDITION":
			await _scenario_gate_expedition()
		"HUB_GUILD":
			await _scenario_guild()
		"HUB_CAMERA":
			await _scenario_camera()
		"HUB_STATE":
			await _scenario_state()
		"HUB_LIVING":
			await _scenario_living()
		"HUB_ATMOSPHERE":
			await _scenario_atmosphere()
		_:
			_check("scenario_known", false, "unknown scenario '%s'" % _scenario)
	_finish()


func _check(name: String, ok: bool, detail := "") -> void:
	_checks.append({"name": name, "ok": ok, "detail": detail})
	print("[HUB] %s: %s %s" % [name, "OK" if ok else "FAIL", detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _teleport(pos: Vector3, yaw := PI) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player_yaw = yaw
	player.rotation.y = yaw
	_cam_yaw = yaw
	_cam_smooth_ready = false
	await get_tree().physics_frame


func _drive_to(target: Vector3, timeout: float) -> bool:
	_auto_nav_target = target
	var t := 0.0
	var step := 1.0 / float(maxi(1, Engine.physics_ticks_per_second))
	while t < timeout:
		await get_tree().physics_frame
		t += step
		if Vector2(player.global_position.x - target.x,
				player.global_position.z - target.z).length() < 0.6:
			break
	_auto_nav_target = Vector3.INF
	return Vector2(player.global_position.x - target.x,
		player.global_position.z - target.z).length() < 1.0


func _camera_inside_wall() -> bool:
	if _camera == null:
		return true
	var probe := SphereShape3D.new()
	probe.radius = 0.12
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var exclude: Array[RID] = [player.get_rid()]
	for f in _followers:
		exclude.append((f["node"] as CollisionObject3D).get_rid())
	query.exclude = exclude
	query.transform = Transform3D(Basis(), _camera.global_position)
	return not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _scenario_boot() -> void:
	await _frames(4)
	_check("player_exists", player != null and is_instance_valid(player))
	_check("player_species", player_model_id == player_species,
		"expected=%s got=%s" % [player_species, player_model_id])
	_check("player_height", absf(player_height - float(HUB_HEIGHTS[player_species])) < 0.01,
		"%.2f" % player_height)
	_check("navigation", _nav_region != null and _nav_region.navigation_mesh != null)
	_check("gate_built", _gate_root != null and is_instance_valid(_gate_root))
	_check("guild_built", _guild_root != null and is_instance_valid(_guild_root))
	_check("npc_count", _npcs.size() == HUB_NPC_SPECS.size(), "%d" % _npcs.size())
	_check("prompt_built", _npc_prompt != null)
	_check("dialogue_hud_built", _npc_hud != null)
	_check("status_built", _status != null)
	_check("gate_panel_built", _gate_panel != null)
	_check("guild_panel_built", _guild_panel != null)
	_check("minimap_built", _minimap_viewport != null and _minimap_camera != null and _minimap_layer != null)
	_check("hud_layer_isolated", _ui_layer != null and _panel_layer != null
		and not _ui_layer.is_in_group("overworld_hud")
		and not _panel_layer.is_in_group("overworld_hud"))
	_check("party_flag", _party_visible == _args.has("party"),
		"visible=%s" % str(_party_visible))
	_check("lighting_mode_valid", LIGHTING_PRESETS.has(lighting_mode), lighting_mode)


func _scenario_navigation() -> void:
	await _teleport(PLAYER_START)
	var start := player.global_position
	var a := await _drive_to(Vector3(0.0, 0.0, -7.0), 4.0)
	var b := await _drive_to(Vector3(7.0, 0.0, -7.0), 4.0)
	var travelled := Vector2(player.global_position.x - start.x,
		player.global_position.z - start.z).length()
	_check("reached_north", a, "pos=%s" % str(player.global_position))
	_check("reached_east", b, "pos=%s" % str(player.global_position))
	_check("travelled", travelled > 12.0, "%.1f m" % travelled)
	_check("camera_free", not _camera_inside_wall())
	_check("on_floor", absf(player.global_position.y) < 0.4, "y=%.2f" % player.global_position.y)


func _scenario_interaction() -> void:
	if _npcs.is_empty():
		_check("npc_available", false)
		return
	var npc: Dictionary = _npcs[0]
	var npc_pos: Vector3 = (npc["node"] as Node3D).global_position
	await _teleport(npc_pos + Vector3(0.0, 0.0, 1.6))
	await _frames(4)
	_check("prompt_visible", _npc_prompt != null and _npc_prompt.visible)
	_check("active_target_npc", _active_target_kind == "npc" and _active_target_id == str(npc["id"]),
		"active=%s/%s" % [_active_target_kind, _active_target_id])
	var opened := _interact_with_active()
	await _frames(3)
	_check("interaction_activated", opened)
	_check("dialogue_visible", _npc_hud != null and _npc_hud.visible)
	_check("dialogue_focus", _dialogue_active)
	_check("npc_marked_talked", bool(npc.get("talked", false)))
	_check("hud_hidden_dialogue", _help_layer != null and not _help_layer.visible)
	_close_npc_dialogue()
	await _frames(3)
	_check("dialogue_closed", _npc_hud != null and not _npc_hud.visible)
	_check("movement_restored", not _ui_open and _help_layer.visible)

	# Verify Plot A interactive probe (H3).
	await _teleport(PLOT_EAST + Vector3(-2.1, 0.0, 0.0), PI * 0.5)
	await _frames(4)
	_check("plot_a_targeted", _active_target_kind == "plot" and _active_target_id == "plot_a",
		"active=%s/%s" % [_active_target_kind, _active_target_id])
	var plot_ok := _interact_with_active()
	await _frames(2)
	_check("plot_a_opened", plot_ok and _npc_hud.visible)
	_close_npc_dialogue()
	await _frames(2)


func _scenario_gate() -> void:
	var started_ms := Time.get_ticks_msec()
	await _teleport(BOARD_POS + Vector3(0.0, 0.0, 1.8))
	await _frames(4)
	_check("gate_targeted", _active_target_kind == "gate",
		"active=%s" % _active_target_kind)
	var opened := _interact_with_active()
	await _frames(2)
	_check("gate_opened", opened and _gate_open and _gate_panel.visible)
	_check("gate_authorized_line", str(GATE_LINES[0]).contains("AUTHORIZED"))
	_check("gate_locked_slots", str(GATE_LINES[1]).contains("LOCKED")
		and str(GATE_LINES[2]).contains("LOCKED"))
	_check("gate_portrait_loaded", _gate_leader_portrait != null and _gate_leader_portrait.texture != null)
	var before_nature := _gate_nature_lbl.text if _gate_nature_lbl != null else ""
	_roll_gate_nature_preview()
	var after_nature := _gate_nature_lbl.text if _gate_nature_lbl != null else ""
	_check("gate_nature_preview_rolls", before_nature != after_nature)
	_gate_nav(1)
	_check("gate_navigation", _gate_index == 1, "index=%d" % _gate_index)
	_gate_confirm()
	var note := _gate_panel.find_child("GateNote", true, false) as Label
	_check("gate_brief", note != null and note.text.contains("BRIEFING"))
	_close_gate()
	await _frames(2)
	_check("gate_closed_movement", not _ui_open and not _gate_panel.visible)
	_check("gate_budget_10s", Time.get_ticks_msec() - started_ms < 10000, "%dms" % (Time.get_ticks_msec() - started_ms))


func _scenario_gate_expedition() -> void:
	var started_ms := Time.get_ticks_msec()
	await _teleport(BOARD_POS + Vector3(0.0, 0.0, 1.8))
	await _frames(4)
	_interact_with_active()
	await _frames(2)
	_gate_index = 0
	# D-1219: confirming the gate now changes scene directly, so the scenario calls GameState itself.
	await _frames(2)
	var gs := get_node_or_null("/root/GameState")
	_check("gamestate_present", gs != null)
	if gs != null and gs.has_method("roll_expedition_nature_and_prepare"):
		_check("gate_has_no_roulette", not has_method("_open_gate_roulette"))
		var info: Dictionary = gs.call("roll_expedition_nature_and_prepare", str(_args.get("nature", "")))
		var locked := str(info.get("nature_id", ""))
		var party: Array = gs.get("party")
		_check("expedition_nature_applied", locked != "" and str(gs.get("last_expedition_nature_id")) == locked)
		_check("expedition_origin_hub", str(gs.get("expedition_origin_scene")) == str(gs.get("HUB_3D")))
		_check("party_nature_synced", party.size() > 0 and str(party[0].get("nature_id")) == locked)
		var again: Dictionary = gs.call("roll_expedition_nature_and_prepare", "")
		_check("nature_fixed_between_expeditions", str(again.get("nature_id", "")) == locked)
	_close_gate()
	await _frames(2)
	_check("gate_expedition_budget_10s", Time.get_ticks_msec() - started_ms < 10000, "%dms" % (Time.get_ticks_msec() - started_ms))


func _scenario_guild() -> void:
	await _teleport(GUILD_POS + Vector3(2.6, 0.0, 0.0))
	await _frames(4)
	_check("guild_targeted", _active_target_kind == "guild",
		"active=%s" % _active_target_kind)
	var opened := _interact_with_active()
	await _frames(2)
	_check("guild_menu_opened", opened and _guild_open and _guild_panel.visible)
	_check("guild_hides_overworld_hud", _minimap_layer != null and not _minimap_layer.visible)
	_guild_nav(1)
	_guild_confirm()
	await _frames(1)
	_check("guild_demo_preview", _guild_detail_lbl != null and _guild_detail_lbl.text.contains("DEMO PREVIEW"))
	_guild_nav(-1)
	_guild_confirm()
	await _frames(2)
	_check("guild_opened", _status_open and _status.visible and _panel_layer.visible)
	_check("guild_party", _party_for_status.size() > 0, "%d" % _party_for_status.size())
	_check("status_hides_overworld_hud", _minimap_layer != null and not _minimap_layer.visible)
	_close_guild()
	await _frames(2)
	_check("guild_closed_movement", not _ui_open and not _status.visible and not _guild_panel.visible)
	_check("hud_restored_after_guild", _minimap_layer != null and _minimap_layer.visible)


func _scenario_camera() -> void:
	for id in PLAYABLE_LEADERS:
		_set_player_species(id)
		await _teleport(PLAYER_START)
		await _frames(8)
		var dist := _camera.global_position.distance_to(player.global_position)
		var inside := _camera_inside_wall()
		_check("camera_%s" % id, not inside and dist > 1.0,
			"height=%.2f cam_dist=%.2f inside_wall=%s" % [player_height, dist, str(inside)])
	# Wall proximity: the Cyclops with its back to the south wall, so the
	# camera has to retract instead of sitting inside the facade.
	_set_player_species("dqt_cyclops")
	await _teleport(Vector3(0.0, 0.0, 12.1), PI)
	await _frames(24)
	var near_wall_ok := not _camera_inside_wall()
	var above := _camera.global_position.y > 0.25
	_check("camera_wall_proximity", near_wall_ok and above,
		"cam=%s y=%.2f" % [str(_camera.global_position), _camera.global_position.y])


func _scenario_state() -> void:
	await _teleport(PLAYER_START)
	# Warm-up: StatusScreen allocates its portrait/slot rects lazily on the
	# first open. Measure after that so the check compares steady state.
	await _state_cycle()
	var before_nodes := _count_nodes(_ui_layer) + _count_nodes(_panel_layer)
	var before_npcs := _npcs.size()
	for cycle in 3:
		await _state_cycle()
	await _frames(4)
	var after_nodes := _count_nodes(_ui_layer) + _count_nodes(_panel_layer)
	_check("no_duplicate_nodes", before_nodes == after_nodes,
		"before=%d after=%d" % [before_nodes, after_nodes])
	_check("no_duplicate_npcs", _npcs.size() == before_npcs, "%d" % _npcs.size())
	_check("single_status", _count_named(_panel_layer, "GuildStatus") == 1,
		"%d" % _count_named(_panel_layer, "GuildStatus"))
	_check("single_gate_panel", _count_named(_panel_layer, "GatePanel") == 1,
		"%d" % _count_named(_panel_layer, "GatePanel"))
	_check("single_guild_panel", _count_named(_panel_layer, "GuildPanel") == 1,
		"%d" % _count_named(_panel_layer, "GuildPanel"))
	_check("single_dialogue", _count_named(_ui_layer, "NpcDialogue") == 1,
		"%d" % _count_named(_ui_layer, "NpcDialogue"))
	_check("single_prompt", _count_named(_ui_layer, "InteractPrompt") == 1,
		"%d" % _count_named(_ui_layer, "InteractPrompt"))
	_check("no_stuck_ui", not _ui_open and not _gate_open and not _guild_open and not _status_open and not _npc_talking)
	_check("prompt_hidden", _npc_prompt != null and not _npc_prompt.visible)
	_check("dialogue_focus_cleared", not _dialogue_active)


func _scenario_living() -> void:
	if _npcs.is_empty():
		_check("npc_available", false)
		return
	await _teleport(Vector3(0.0, 0.0, 10.0))
	await _frames(2)
	var npc: Dictionary = _npcs[0]
	var body := npc["node"] as Node3D
	var start := body.global_position
	await _frames(90)
	var moved := Vector2(body.global_position.x - start.x,
		body.global_position.z - start.z).length()
	_check("npc_patrol_moved", moved > 0.25, "%.2f m" % moved)
	await _teleport(body.global_position + Vector3(0.0, 0.0, 1.8))
	await _frames(25)
	var to := player.global_position - body.global_position
	to.y = 0.0
	var forward := Vector3(sin(body.rotation.y), 0.0, cos(body.rotation.y))
	var dot := forward.dot(to.normalized()) if to.length() > 0.001 else 0.0
	_check("npc_faces_player", dot > 0.75, "dot=%.2f" % dot)
	_check("npc_paused_patrol", str(npc.get("state", "")) == "greet",
		str(npc.get("state", "")))


func _scenario_atmosphere() -> void:
	weather_mode = "clear"
	await _frames(5)
	var clear_rain := _rain_intensity
	var clear_wind := _wind_strength
	var clear_clarity := _clarity
	var clear_spot := _max_spot_energy()
	weather_mode = "storm"
	await _frames(5)
	_check("atmo_storm_rain", _rain_intensity > clear_rain + 0.2,
		"clear=%.2f storm=%.2f" % [clear_rain, _rain_intensity])
	_check("atmo_storm_wind", _wind_strength > clear_wind + 0.1,
		"clear=%.2f storm=%.2f" % [clear_wind, _wind_strength])
	_check("atmo_clear_clarity", clear_clarity > _clarity + 0.1,
		"clear=%.2f storm=%.2f" % [clear_clarity, _clarity])
	var storm_spot := _max_spot_energy()
	_check("atmo_skylight_reacts", clear_spot > 0.0 and storm_spot < clear_spot,
		"clear=%.2f storm=%.2f" % [clear_spot, storm_spot])
	weather_mode = "clear"
	_apply_lighting_preset("day")
	await _frames(2)
	var day_env_e := _world_env_ref.environment.ambient_light_energy
	_apply_lighting_preset("night")
	await _frames(2)
	var night_env_e := _world_env_ref.environment.ambient_light_energy
	_check("lighting_presets_differ", day_env_e > night_env_e + 0.25,
		"day=%.2f night=%.2f" % [day_env_e, night_env_e])
	_apply_lighting_preset("dusk")
	weather_mode = "auto"
	await _frames(5)
	_check("atmo_auto_running", _atmo_time > 0.0, "t=%.2f" % _atmo_time)


func _max_spot_energy() -> float:
	var top := 0.0
	for entry in _skylight_spots:
		var light := entry.get("light") as SpotLight3D
		if light != null and is_instance_valid(light):
			top = maxf(top, light.light_energy)
	return top


func _state_cycle() -> void:
	_open_gate()
	await _frames(2)
	_close_gate()
	await _frames(1)
	_open_guild()
	await _frames(2)
	_open_status_from_guild()
	await _frames(2)
	_close_guild()
	await _frames(1)
	if not _npcs.is_empty():
		_open_npc_dialogue(_npcs[0])
		await _frames(2)
		_close_npc_dialogue()
		await _frames(1)


func _count_named(root: Node, node_name: String) -> int:
	var total := 1 if root.name == node_name else 0
	for child in root.get_children():
		total += _count_named(child, node_name)
	return total


func _count_nodes(root: Node) -> int:
	var total := 1
	for child in root.get_children():
		total += _count_nodes(child)
	return total


# --- Screenshots -------------------------------------------------------------

func _run_view(id: String) -> void:
	match id:
		"overview":
			await _teleport(Vector3(0.0, 0.0, 6.5), PI)
			_cam_yaw = PI
			await _frames(14)
		"gate":
			await _teleport(Vector3(0.0, 0.0, -4.5), PI)
			_cam_yaw = PI
			await _frames(14)
		"guild":
			await _teleport(Vector3(-7.4, 0.0, -2.0), -PI * 0.5)
			_cam_yaw = -PI * 0.5
			await _frames(16)
		"npc_dialogue":
			if not _npcs.is_empty():
				var npc: Dictionary = _npcs[0]
				var pos: Vector3 = (npc["node"] as Node3D).global_position
				await _teleport(pos + Vector3(0.0, 0.0, 1.6))
				await _frames(4)
				_open_npc_dialogue(npc)
				_npc_hud.finish_typing()
			await _frames(40)
		"gate_panel":
			await _teleport(BOARD_POS + Vector3(0.0, 0.0, 1.8))
			await _frames(4)
			_open_gate()
			await _frames(8)
		"guild_panel":
			await _teleport(GUILD_POS + Vector3(2.6, 0.0, 0.0))
			await _frames(4)
			_open_guild()
			await _frames(8)
		"expansion_plots":
			await _teleport(Vector3(3.0, 0.0, 6.5), PI * 0.5)
			_cam_yaw = PI * 0.5
			await _frames(16)
		_:
			_check("view_known", false, "unknown view '%s'" % id)
	await _frames(4)
	_check("view_done", true, id)
	_finish()


func _capture() -> void:
	if _shot_path == "" or DisplayServer.get_name() == "headless":
		return
	var path := _shot_path
	if path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("[HUB] shot: ", path)


func _finish() -> void:
	if _scenario_done:
		return
	_scenario_done = true
	_capture()
	if _scenario != "" and _run_started_ms > 0:
		var elapsed_ms := Time.get_ticks_msec() - _run_started_ms
		_check("scenario_budget_10s", elapsed_ms < 10000, "%dms" % elapsed_ms)
	var ok := true
	for c in _checks:
		if not bool(c["ok"]):
			ok = false
		if not bool(c["ok"]):
			print("[HUB] FAILED CHECK: ", c["name"], " ", c["detail"])
	var out := {
		"scenario": _scenario,
		"view": _view,
		"ok": ok,
		"player": player_model_id,
		"player_height": player_height,
		"lighting": lighting_mode,
		"party_visible": _party_visible,
		"npcs": _npcs.size(),
		"checks": _checks,
	}
	print("HUB_SUMMARY " + JSON.stringify(out))
	if _args.has("summary-json"):
		print("HUB_SUMMARY_JSON:" + JSON.stringify(out))
	if _args.has("quit") or _scenario != "" or _view != "":
		get_tree().quit(0 if ok else 1)
