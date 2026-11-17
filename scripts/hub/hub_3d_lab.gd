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
##            HUB_CAMERA HUB_STATE HUB_LIVING HUB_ATMOSPHERE HUB_PORTAL_CYCLE

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
const MARKER_RING_SHADER := preload("res://shaders/overworld_marker_ring.gdshader")
const ICON_ALERT := preload("res://assets/ui/overworld_icons/state_alert.png")
const ICON_QUESTION := preload("res://assets/ui/overworld_icons/state_question.png")
const ICON_TALKED := preload("res://assets/ui/overworld_icons/state_talked.png")
const WALL_TEXTURES := {
	"stone": preload("res://assets/textures/walls/murky_wall_mossy_stone.png"),
	"slate": preload("res://assets/textures/walls/murky_wall_slate_cracks.png"),
	"bark": preload("res://assets/textures/walls/murky_wall_bark_roots.png"),
	"palisade": preload("res://assets/textures/walls/murky_wall_root_palisade.png"),
	"palisade_v1": preload("res://assets/textures/walls/murky_wall_root_palisade_v1.png"),
	"palisade_v2": preload("res://assets/textures/walls/murky_wall_root_palisade_v2.png"),
	"palisade_v3": preload("res://assets/textures/walls/murky_wall_root_palisade_v3.png"),
	"palisade_v4": preload("res://assets/textures/walls/murky_wall_root_palisade_v4.png"),
	"palisade_v5": preload("res://assets/textures/walls/murky_wall_root_palisade_v5.png"),
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
	"dqt_dracky": 0.95,
	"dqt_sabrecub": 0.85,
	"dqt_platypunk": 0.95,
	"dqt_fungi": 0.95,
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
	"dqt_dracky": "DRACKY",
	"dqt_sabrecub": "SABRECUB",
	"dqt_platypunk": "PLATYPUNK",
	"dqt_fungi": "FUNGHOUL",
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

const PORTAL_ENTRY_POS := Vector3(0.0, 0.0, -9.2)
const PORTAL_VORTEX_POS := Vector3(0.0, 0.0, -10.85)
const PORTAL_EXIT_LAND_POS := Vector3(0.0, 0.0, -8.2)

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
		"portal_eligible": false,
		"line": "[PROTOTYPE] Step up to the Guild Desk to open the Guild Hall menu or inspect your active party StatusScreen.",
	},
	{
		"id": "squirtle", "role": "GATE WARDEN", "pos": Vector3(3.4, 0.0, -8.8),
		"yaw": -0.45, "icon": "alert", "patrol": false,
		"portal_eligible": false,
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
	{
		"id": "dqt_dracky", "role": "NIGHT SCOUT", "pos": Vector3(6.8, 0.0, -5.8),
		"yaw": -2.2, "icon": "question", "patrol": true, "portal_eligible": true,
		"line": "[PROTÓTIPO] Night Scout faz a ronda da praça após o crepúsculo.",
	},
	{
		"id": "dqt_sabrecub", "role": "STRIKER", "pos": Vector3(-6.2, 0.0, 7.6),
		"yaw": 2.4, "icon": "question", "patrol": true, "portal_eligible": true,
		"line": "[PROTÓTIPO] Striker patrulha o calçadão oeste antes da incursão.",
	},
	{
		"id": "dqt_platypunk", "role": "FORAGER", "pos": Vector3(6.4, 0.0, 2.4),
		"yaw": -1.4, "icon": "question", "patrol": true, "portal_eligible": true,
		"line": "[PROTÓTIPO] Forager confere os suprimentos perto dos lotes leste.",
	},
	{
		"id": "dqt_fungi", "role": "SPORE KEEPER", "pos": Vector3(4.2, 0.0, 8.2),
		"yaw": -2.8, "icon": "question", "patrol": true, "portal_eligible": true,
		"line": "[PROTÓTIPO] Spore Keeper cuida dos canteiros ao sul da praça.",
	},
]
const TRAVELER_SLOTS := [{"pos": Vector3(-4.2, 0.0, 8.2), "yaw": 2.5}, {"pos": Vector3(5.6, 0.0, -5.6), "yaw": -2.2}]

const LIGHTING_PRESETS := {
	"dusk": {
		"label": "WARM DUSK SANCTUARY",
		"bg": Color(0.025, 0.019, 0.022),
		"ambient": Color(0.28, 0.21, 0.20),
		"ambient_e": 0.35,
		"fog": Color(0.07, 0.048, 0.042),
		"fog_d": 0.012,
		"dir": Color(0.92, 0.68, 0.48),
		"dir_e": 0.25,
		"lamp_mult": 1.05,
		"spot_mult": 0.72,
	},
	"day": {
		"label": "OVERCAST DAYLIGHT",
		"bg": Color(0.15, 0.17, 0.19),
		"ambient": Color(0.50, 0.46, 0.42),
		"ambient_e": 0.68,
		"fog": Color(0.19, 0.18, 0.17),
		"fog_d": 0.006,
		"dir": Color(0.98, 0.92, 0.80),
		"dir_e": 0.74,
		"lamp_mult": 0.42,
		"spot_mult": 1.18,
	},
	"night": {
		"label": "VELVET NIGHT",
		"bg": Color(0.014, 0.012, 0.018),
		"ambient": Color(0.17, 0.14, 0.18),
		"ambient_e": 0.20,
		"fog": Color(0.036, 0.028, 0.038),
		"fog_d": 0.015,
		"dir": Color(0.76, 0.56, 0.46),
		"dir_e": 0.14,
		"lamp_mult": 1.35,
		"spot_mult": 0.60,
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
var _portal_entries_count := 0
var _portal_exits_count := 0
var _last_portal_pulse: Dictionary = {}
var _portal_quad_mat: ShaderMaterial
var _portal_pulse_val := 0.0
var _portal_ring_fx: Array[Dictionary] = []
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
	_sync_followers_to_party()
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
	if _arrival == null:
		_maybe_open_ally_choice()  # D-1260: no arrival cutscene (e.g. --hub): offer right away
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
	env.tonemap_exposure = 0.93
	env.fog_enabled = true
	env.fog_light_color = preset["fog"]
	env.fog_density = float(preset["fog_d"])
	env.glow_enabled = true
	env.glow_intensity = 0.38
	env.glow_bloom = 0.05
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.96
	env.adjustment_contrast = 0.96
	env.adjustment_saturation = 0.95
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
	cavern_fill.shadow_opacity = 0.55
	cavern_fill.directional_shadow_max_distance = 46.0
	add_child(cavern_fill)
	_cavern_fill_light = cavern_fill

	# Warm local bounce around the main landmarks (no blue lights; D-1023).
	for data in [
		[Vector3(-9.2, 2.8, -2.0), Color(1.0, 0.66, 0.34), 0.32, 7.8],
		[Vector3(0.0, 3.0, -10.2), Color(1.0, 0.62, 0.28), 0.34, 8.0],
		[Vector3(8.8, 2.6, 2.4), Color(1.0, 0.68, 0.36), 0.30, 7.2],
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
	_update_portal_fx(delta)


func _soft_orb_particle_shader(tint: Color, additive := false) -> ShaderMaterial:
	var blend_mode := "blend_add" if additive else "blend_mix"
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, %s, depth_draw_never, cull_disabled;

uniform vec4 orb_color : source_color = vec4(1.0, 0.85, 0.55, 0.55);

void vertex() {
	vec3 sc = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * sc.x,
		INV_VIEW_MATRIX[1] * sc.y,
		INV_VIEW_MATRIX[2] * sc.z,
		MODEL_MATRIX[3]
	);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float core = exp(-d * d * 7.2) * (1.0 - smoothstep(0.65, 1.0, d));
	ALBEDO = orb_color.rgb;
	ALPHA = clamp(core * orb_color.a, 0.0, 1.0);
}
""" % blend_mode
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("orb_color", tint)
	return mat


func _update_portal_fx(delta: float) -> void:
	if _portal_pulse_val > 0.0:
		_portal_pulse_val = maxf(0.0, _portal_pulse_val - delta * 1.9)
		if _portal_quad_mat != null:
			_portal_quad_mat.set_shader_parameter("pulse_boost", _portal_pulse_val)
	for i in range(_portal_ring_fx.size() - 1, -1, -1):
		var fx: Dictionary = _portal_ring_fx[i]
		var mesh := fx.get("mesh") as MeshInstance3D
		if mesh == null or not is_instance_valid(mesh):
			_portal_ring_fx.remove_at(i)
			continue
		var age := float(fx.get("age", 0.0)) + delta
		var dur := float(fx.get("dur", 0.55))
		if age >= dur:
			mesh.queue_free()
			_portal_ring_fx.remove_at(i)
			continue
		fx["age"] = age
		var u := clampf(age / dur, 0.0, 1.0)
		var s := lerpf(0.6, 2.35, 1.0 - pow(1.0 - u, 2.0))
		mesh.scale = Vector3(s, s, 1.0)
		var mat := fx.get("mat") as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("alpha", (1.0 - u) * 0.85)


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
	var ground := _plaza_floor_shader(Color(0.24, 0.19, 0.16), 2.4)
	var plaza := _plaza_floor_shader(Color(0.37, 0.30, 0.26), 1.55)
	var paver := _plaza_floor_shader(Color(0.32, 0.26, 0.22), 1.20)
	var trim := _toon_mat(Color(0.18, 0.15, 0.14), Color(0.82, 0.50, 0.24), 0.28)
	var bronze := _toon_mat(Color(0.46, 0.34, 0.20), Color(0.88, 0.56, 0.22), 0.18)
	var stone := _toon_mat(Color(0.29, 0.25, 0.22))
	var dark := _toon_mat(Color(0.14, 0.12, 0.12))

	# Base ground and the raised central plaza slab.
	_box(Vector3(PLAZA_HALF_X * 2.0 + 2.0, 0.4, PLAZA_HALF_Z * 2.0 + 2.0), Vector3(0.0, -0.2, 0.0), ground)
	_box(Vector3(12.0, 0.10, 10.0), Vector3(0.0, 0.05, 1.0), plaza, false)
	# Plaza trim lines and stepped dark-stone/bronze central medallion (top <= 0.132m for D-1237).
	for i in 5:
		_box(Vector3(11.2, 0.02, 0.10), Vector3(0.0, 0.105, -3.6 + float(i) * 2.3), trim, false)
	var med_specs := [
		[2.50, 0.022, 0.105, dark],
		[2.16, 0.026, 0.111, trim],
		[1.56, 0.024, 0.116, bronze],
		[1.12, 0.022, 0.120, dark],
	]
	for ms in med_specs:
		var m_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = float(ms[0])
		cyl.bottom_radius = float(ms[0]) + 0.06
		cyl.height = float(ms[1])
		cyl.radial_segments = 16
		m_mesh.mesh = cyl
		m_mesh.position = Vector3(0.0, float(ms[2]), 1.0)
		m_mesh.material_override = ms[3]
		add_child(m_mesh)
	for c_dir in [Vector3(0, 0, 1.9), Vector3(0, 0, -1.9), Vector3(1.9, 0, 0), Vector3(-1.9, 0, 0)]:
		var tick_sz := Vector3(0.16, 0.02, 0.48) if absf(c_dir.z) > 0.1 else Vector3(0.48, 0.02, 0.16)
		_box(tick_sz, Vector3(0.0, 0.118, 1.0) + c_dir, bronze, false)

	# Cardinal stone walkways with low dark-stone curbs to Gate, Guild, and Plots A/B.
	for pz in [-4.8, -6.4, -8.0, -9.5]:
		_box(Vector3(2.4, 0.05, 1.25), Vector3(0.0, 0.025, pz), paver, false)
		for cx in [-1.32, 1.32]:
			_box(Vector3(0.16, 0.07, 1.32), Vector3(cx, 0.035, pz), dark, false)
	for px in [-6.8, -8.2]:
		_box(Vector3(1.25, 0.05, 2.2), Vector3(px, 0.025, -2.0), paver, false)
		for cz in [-3.2, -0.8]:
			_box(Vector3(1.32, 0.07, 0.16), Vector3(px, 0.035, cz), dark, false)
	for px in [6.8, 8.2]:
		_box(Vector3(1.25, 0.05, 1.8), Vector3(px, 0.025, -2.0), paver, false)
		for cz in [-3.0, -1.0]:
			_box(Vector3(1.32, 0.07, 0.16), Vector3(px, 0.035, cz), dark, false)
	_box(Vector3(1.4, 0.05, 1.4), Vector3(6.2, 0.025, 4.6), paver, false)

	# Perimeter walls with all 6 palisade variations blended cleanly (D-1116).
	var wall_specs := [
		[Vector3(0.5, PLAZA_WALL_HEIGHT, PLAZA_HALF_Z * 2.0), Vector3(-PLAZA_HALF_X - 0.25, PLAZA_WALL_HEIGHT * 0.5, 0.0),
			"palisade_v1", "palisade", "bark", Vector4(-PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(-PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0)],
		[Vector3(0.5, PLAZA_WALL_HEIGHT, PLAZA_HALF_Z * 2.0), Vector3(PLAZA_HALF_X + 0.25, PLAZA_WALL_HEIGHT * 0.5, 0.0),
			"palisade_v2", "palisade_v3", "slate", Vector4(PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0)],
		[Vector3(PLAZA_HALF_X * 2.0 + 1.0, PLAZA_WALL_HEIGHT, 0.5), Vector3(0.0, PLAZA_WALL_HEIGHT * 0.5, PLAZA_HALF_Z + 0.25),
			"palisade_v4", "bark", "stone", Vector4(-PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0), Vector4(PLAZA_HALF_X, PLAZA_HALF_Z, 0.0, 1.0)],
		[Vector3(11.0, PLAZA_WALL_HEIGHT, 0.5), Vector3(-8.5, PLAZA_WALL_HEIGHT * 0.5, -PLAZA_HALF_Z - 0.25),
			"palisade_v5", "stone", "palisade", Vector4(-PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(-3.0, -PLAZA_HALF_Z, 0.0, 0.8)],
		[Vector3(11.0, PLAZA_WALL_HEIGHT, 0.5), Vector3(8.5, PLAZA_WALL_HEIGHT * 0.5, -PLAZA_HALF_Z - 0.25),
			"palisade_v3", "slate", "palisade_v1", Vector4(PLAZA_HALF_X, -PLAZA_HALF_Z, 0.0, 1.0), Vector4(3.0, -PLAZA_HALF_Z, 0.0, 0.8)],
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
		bmi.material_override = _wall_shader_mat("bark", "palisade_v4", "slate", Vector4.ZERO, Vector4.ZERO, Color(0.20, 0.16, 0.15, 1.0))
		bastion.add_child(bmi)
		add_child(bastion)

	# Detailed lamp posts (stone plinth, bracket, lantern cage) and benches with backrests.
	var metal := _toon_mat(Color(0.11, 0.11, 0.12))
	var lamp_wood := _toon_mat(Color(0.28, 0.19, 0.13))
	for p in [
		Vector3(-6.2, 0.0, 4.6), Vector3(6.2, 0.0, 4.6),
		Vector3(-6.2, 0.0, -4.6), Vector3(6.2, 0.0, -4.6),
	]:
		_box(Vector3(0.46, 0.30, 0.46), p + Vector3(0.0, 0.15, 0.0), stone)
		_box(Vector3(0.20, 2.55, 0.20), p + Vector3(0.0, 1.55, 0.0), metal)
		_box(Vector3(0.56, 0.10, 0.56), p + Vector3(0.0, 2.88, 0.0), metal, false)
		_box(Vector3(0.42, 0.08, 0.42), p + Vector3(0.0, 2.42, 0.0), metal, false)
		for cx in [-0.18, 0.18]:
			for cz in [-0.18, 0.18]:
				_box(Vector3(0.05, 0.44, 0.05), p + Vector3(cx, 2.65, cz), metal, false)
		var bulb := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.17
		sph.height = 0.34
		sph.radial_segments = 8
		sph.rings = 4
		bulb.mesh = sph
		bulb.position = p + Vector3(0.0, 2.66, 0.0)
		bulb.material_override = _toon_mat(Color(1.0, 0.78, 0.42), Color(1.0, 0.66, 0.30), 1.65)
		add_child(bulb)
		var light := OmniLight3D.new()
		light.position = p + Vector3(0.0, 2.68, 0.0)
		light.light_color = Color(1.0, 0.70, 0.36)
		light.light_energy = 0.58
		light.omni_range = 5.4
		add_child(light)
		_torches.append(light)
		_torch_base.append(0.58)

	for b in [Vector3(-8.0, 0.0, 4.2), Vector3(8.0, 0.0, 4.2)]:
		_box(Vector3(2.0, 0.34, 0.58), b + Vector3(0.0, 0.17, 0.0), stone)
		_box(Vector3(2.06, 0.10, 0.62), b + Vector3(0.0, 0.40, 0.0), lamp_wood, false)
		_box(Vector3(1.94, 0.32, 0.10), b + Vector3(0.0, 0.66, 0.25), lamp_wood, false)
		for ax in [-0.90, 0.90]:
			_box(Vector3(0.14, 0.36, 0.56), b + Vector3(ax, 0.54, 0.0), stone, false)

	# Planters framing the plaza.
	for p in [
		Vector3(-11.5, 0.0, 7.5), Vector3(11.5, 0.0, 7.5),
		Vector3(-11.5, 0.0, -9.0), Vector3(11.5, 0.0, -9.0),
	]:
		_box(Vector3(1.4, 0.55, 1.4), p + Vector3(0.0, 0.275, 0.0), stone)
		_box(Vector3(1.52, 0.10, 1.52), p + Vector3(0.0, 0.55, 0.0), dark, false)
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
			leaf.material_override = _foliage_wind_shader(Color(0.16, 0.38, 0.28), 0.16)
			add_child(leaf)
			_register_fade_mesh(leaf, 0.6)

	# Perimeter trees with tapered trunks, angled branches, and multi-cluster canopies.
	var trunk_mat := _toon_mat(Color(0.20, 0.14, 0.11))
	var canopy_a := _foliage_wind_shader(Color(0.14, 0.30, 0.22), 0.18)
	var canopy_b := _foliage_wind_shader(Color(0.19, 0.36, 0.24), 0.22)
	for tpos in [
		Vector3(-13.4, 0.0, -11.5), Vector3(-7.0, 0.0, -12.6),
		Vector3(7.0, 0.0, -12.6), Vector3(13.4, 0.0, -11.5),
		Vector3(13.4, 0.0, 2.2), Vector3(-13.4, 0.0, 9.8), Vector3(13.4, 0.0, 10.2),
	]:
		var trunk := MeshInstance3D.new()
		var tcyl := CylinderMesh.new()
		tcyl.top_radius = 0.22
		tcyl.bottom_radius = 0.38
		tcyl.height = 3.8
		tcyl.radial_segments = 7
		trunk.mesh = tcyl
		trunk.position = tpos + Vector3(0.0, 1.9, 0.0)
		trunk.material_override = trunk_mat
		add_child(trunk)
		_register_fade_mesh(trunk, 0.45)
		for bi in 2:
			var br := _box(Vector3(0.18, 1.35, 0.18), tpos + Vector3(-0.35 + 0.7 * float(bi), 3.1, 0.15 * float(bi)), trunk_mat, false)
			br.rotation.z = 0.45 if bi == 0 else -0.42
			br.rotation.x = 0.18 * float(1 - bi * 2)
		for ci in 4:
			var c_mesh := MeshInstance3D.new()
			var cs := SphereMesh.new()
			cs.radius = 1.35 - 0.16 * float(ci)
			cs.height = 1.95 - 0.18 * float(ci)
			cs.radial_segments = 7
			cs.rings = 4
			c_mesh.mesh = cs
			c_mesh.position = tpos + Vector3(
				(-0.55 + 0.42 * float(ci)), 3.85 + 0.48 * float(ci % 2), -0.25 + 0.22 * float(ci))
			c_mesh.material_override = canopy_a if (ci % 2 == 0) else canopy_b
			add_child(c_mesh)
			_register_fade_mesh(c_mesh, cs.radius + 0.25)

	_build_cavern_details()
	_build_cavern_ceiling()
	_build_atmosphere_particles()


func _build_cavern_details() -> void:
	# Hanging vines, exposed roots, ferns, boulders, and discrete cavern mushrooms.
	var vine_mat := _foliage_wind_shader(Color(0.14, 0.28, 0.18), 0.26)
	var fern_mat := _foliage_wind_shader(Color(0.18, 0.36, 0.22), 0.14)
	var root_mat := _toon_mat(Color(0.22, 0.16, 0.12))
	var moss_rock := _toon_mat(Color(0.22, 0.20, 0.18))
	var mush_stem := _toon_mat(Color(0.56, 0.50, 0.42))
	var mush_cap := _toon_mat(Color(0.28, 0.46, 0.36), Color(0.52, 0.82, 0.50), 0.45)

	for vp in [
		Vector3(-13.1, 4.1, -7.2), Vector3(-13.1, 4.3, 3.8), Vector3(-13.1, 3.9, 9.2),
		Vector3(13.1, 4.2, -6.5), Vector3(13.1, 3.9, 5.4), Vector3(13.1, 4.4, 9.5),
		Vector3(-9.5, 4.2, -12.1), Vector3(9.5, 4.1, -12.1), Vector3(-4.5, 4.3, 12.1), Vector3(5.2, 4.0, 12.1),
	]:
		var vlen := 1.45 + 0.35 * sin(vp.x + vp.z)
		var vmi := _box(Vector3(0.09, vlen, 0.09), vp - Vector3(0.0, vlen * 0.5, 0.0), vine_mat, false)
		vmi.rotation.z = 0.08 * cos(vp.z)

	for rp in [
		Vector3(-12.2, 0.18, -11.4), Vector3(12.2, 0.18, -11.4),
		Vector3(-12.2, 0.18, 11.2), Vector3(12.2, 0.18, 11.2),
	]:
		for k in 2:
			var rmi := _box(Vector3(0.22, 0.22, 1.35), rp + Vector3(0.35 * float(k), 0.0, 0.35 * float(1 - k)), root_mat, false)
			rmi.rotation.y = 0.65 * float(k) - 0.32
			rmi.rotation.x = 0.22

	for bp in [
		Vector3(-12.4, 0.28, 6.2), Vector3(-11.8, 0.22, 10.6), Vector3(12.4, 0.30, -8.2),
		Vector3(12.1, 0.24, 9.6), Vector3(-6.8, 0.22, 11.4), Vector3(6.6, 0.24, 11.4),
	]:
		_box(Vector3(0.75, 0.48, 0.65), bp, moss_rock, false)
		_box(Vector3(0.45, 0.32, 0.42), bp + Vector3(0.42, -0.06, 0.22), moss_rock, false)
		for fi in 3:
			var frond := _box(Vector3(0.14, 0.42, 0.04), bp + Vector3(-0.2 + 0.2 * float(fi), 0.28, 0.38), fern_mat, false)
			frond.rotation.x = 0.48
			frond.rotation.y = -0.35 + 0.35 * float(fi)

	for mp in [
		Vector3(-11.4, 0.0, 8.6), Vector3(11.3, 0.0, 8.8),
		Vector3(-10.8, 0.0, -9.6), Vector3(10.8, 0.0, -9.8),
		Vector3(-12.3, 0.0, 2.4), Vector3(12.2, 0.0, 3.8),
	]:
		for mi_idx in 2:
			var off := Vector3(0.22 * float(mi_idx), 0.0, -0.18 * float(mi_idx))
			var h := 0.24 if mi_idx == 0 else 0.16
			_box(Vector3(0.06, h, 0.06), mp + off + Vector3(0.0, h * 0.5, 0.0), mush_stem, false)
			var cap := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.04
			cm.bottom_radius = 0.16 if mi_idx == 0 else 0.11
			cm.height = 0.10
			cm.radial_segments = 8
			cap.mesh = cm
			cap.position = mp + off + Vector3(0.0, h + 0.04, 0.0)
			cap.material_override = mush_cap
			add_child(cap)
			_register_fade_mesh(cap, 0.3)


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
		{"pos": Vector3(0.0, 0.0, 1.0), "top_r": 2.3, "bot_r": 4.2, "energy": 1.95, "angle": 28.0, "dust": true},
		{"pos": Vector3(0.0, 0.0, -5.8), "top_r": 1.25, "bot_r": 2.2, "energy": 1.35, "angle": 25.0, "dust": false},
		{"pos": Vector3(-6.2, 0.0, -1.8), "top_r": 1.35, "bot_r": 2.6, "energy": 1.20, "angle": 25.0, "dust": false},
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
			dust.scale_amount_min = 0.04
			dust.scale_amount_max = 0.09
			var qm := QuadMesh.new()
			qm.size = Vector2(0.09, 0.09)
			qm.material = _soft_orb_particle_shader(Color(1.0, 0.85, 0.52, 0.50), false)
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

	# Rising warm embers over the four plaza lamp posts (soft circular orbs).
	var ember_mat := _soft_orb_particle_shader(Color(1.0, 0.68, 0.28, 0.78), true)
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
		emb.scale_amount_min = 0.04
		emb.scale_amount_max = 0.08
		var eq := QuadMesh.new()
		eq.size = Vector2(0.08, 0.08)
		eq.material = ember_mat
		emb.mesh = eq
		add_child(emb)

	# Quiet warm firefly motes drifting near perimeter planters.
	var firefly_mat := _soft_orb_particle_shader(Color(0.84, 0.96, 0.48, 0.68), true)
	for fp in [Vector3(-11.4, 1.4, 7.6), Vector3(11.4, 1.4, 7.6), Vector3(-11.4, 1.4, -8.8), Vector3(11.4, 1.4, -8.8)]:
		var ff := CPUParticles3D.new()
		ff.position = fp
		ff.amount = 6
		ff.lifetime = 3.2
		ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		ff.emission_sphere_radius = 1.2
		ff.gravity = Vector3(0.0, 0.04, 0.0)
		ff.initial_velocity_min = 0.06
		ff.initial_velocity_max = 0.16
		ff.scale_amount_min = 0.045
		ff.scale_amount_max = 0.09
		var fq := QuadMesh.new()
		fq.size = Vector2(0.09, 0.09)
		fq.material = firefly_mat
		ff.mesh = fq
		add_child(ff)


func _gate_portal_shader() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float pulse_boost : hint_range(0.0, 2.0) = 0.0;

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
	float core = exp(-r * (2.1 - pulse_boost * 0.55));
	float ring = exp(-pow((r - 0.58) * 5.2, 2.0));

	vec3 void_col = vec3(0.04, 0.025, 0.035);
	vec3 amber_mid = vec3(0.72, 0.34, 0.10);
	vec3 gold_bright = vec3(1.00, 0.78, 0.32);

	vec3 col = mix(void_col, amber_mid, clamp(arch_mask * (0.45 + stream * 0.55 + pulse_boost * 0.25), 0.0, 1.0));
	col = mix(col, gold_bright, clamp((core * (0.85 + pulse_boost * 0.45) + ring * (0.55 + pulse_boost * 0.50) + stream * 0.35) * arch_mask, 0.0, 1.0));
	ALBEDO = col;
	EMISSION = col * (0.88 + pulse_boost * 0.72);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("pulse_boost", 0.0)
	_portal_quad_mat = mat
	return mat


func _build_exit() -> void:
	_gate_root = Node3D.new()
	_gate_root.name = "ExpeditionGate"
	add_child(_gate_root)
	var stone := _toon_mat(Color(0.32, 0.27, 0.24))
	var trim_stone := _toon_mat(Color(0.22, 0.18, 0.16))
	var gold := _toon_mat(Color(0.68, 0.48, 0.20), Color(0.95, 0.58, 0.22), 0.72)
	var coal_mat := _toon_mat(Color(0.26, 0.10, 0.05), Color(1.0, 0.44, 0.12), 1.45)
	var ember_mat := _soft_orb_particle_shader(Color(1.0, 0.58, 0.20, 0.80), true)

	# Stepped stone plinth, carved pillars, rune keystone, and flanking braziers at the north edge.
	_box(Vector3(7.0, 0.20, 2.2), GATE_POS + Vector3(0.0, 0.10, 0.25), trim_stone, false)
	_box(Vector3(5.8, 0.14, 1.6), GATE_POS + Vector3(0.0, 0.27, 0.15), stone, false)
	for x in [-2.4, 2.4]:
		var pillar := _box(Vector3(0.95, 5.0, 0.95), GATE_POS + Vector3(x, 2.5, 0.0), stone)
		pillar.name = "GatePillar"
		_register_fade_mesh(pillar, 0.9)
		_box(Vector3(1.26, 0.42, 1.26), GATE_POS + Vector3(x, 0.21, 0.0), trim_stone, false)
		_box(Vector3(1.12, 0.24, 1.12), GATE_POS + Vector3(x, 0.54, 0.0), stone, false)
		_box(Vector3(1.16, 0.18, 1.16), GATE_POS + Vector3(x, 4.78, 0.0), trim_stone, false)
		_box(Vector3(1.30, 0.40, 1.30), GATE_POS + Vector3(x, 5.12, 0.0), gold, false)
		for ry in [1.4, 2.6, 3.8]:
			_box(Vector3(1.02, 0.12, 1.02), GATE_POS + Vector3(x, ry, 0.0), trim_stone, false)
	_box(Vector3(6.4, 0.85, 1.05), GATE_POS + Vector3(0.0, 4.7, 0.0), stone)
	_box(Vector3(6.8, 0.22, 1.24), GATE_POS + Vector3(0.0, 5.16, 0.0), trim_stone, false)
	_box(Vector3(2.2, 0.55, 1.15), GATE_POS + Vector3(0.0, 5.36, 0.0), gold, false)
	_box(Vector3(0.75, 0.72, 1.16), GATE_POS + Vector3(0.0, 4.65, 0.02), trim_stone, false)
	_box(Vector3(0.42, 0.42, 1.18), GATE_POS + Vector3(0.0, 4.65, 0.03), gold, false)

	for bx in [-3.45, 3.45]:
		var bp := GATE_POS + Vector3(bx, 0.0, 1.15)
		_box(Vector3(0.68, 0.22, 0.68), bp + Vector3(0.0, 0.11, 0.0), trim_stone, false)
		_box(Vector3(0.46, 0.62, 0.46), bp + Vector3(0.0, 0.52, 0.0), stone, false)
		_box(Vector3(0.72, 0.20, 0.72), bp + Vector3(0.0, 0.92, 0.0), trim_stone, false)
		_box(Vector3(0.50, 0.14, 0.50), bp + Vector3(0.0, 1.04, 0.0), coal_mat, false)
		var brazier_l := OmniLight3D.new()
		brazier_l.position = bp + Vector3(0.0, 1.35, 0.0)
		brazier_l.light_color = Color(1.0, 0.58, 0.22)
		brazier_l.light_energy = 0.42
		brazier_l.omni_range = 4.8
		add_child(brazier_l)
		_torches.append(brazier_l)
		_torch_base.append(0.42)
		var b_emb := CPUParticles3D.new()
		b_emb.position = bp + Vector3(0.0, 1.18, 0.0)
		b_emb.amount = 10
		b_emb.lifetime = 1.2
		b_emb.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		b_emb.emission_sphere_radius = 0.18
		b_emb.gravity = Vector3(0.0, 0.9, 0.0)
		b_emb.initial_velocity_min = 0.15
		b_emb.initial_velocity_max = 0.35
		b_emb.scale_amount_min = 0.04
		b_emb.scale_amount_max = 0.08
		var beq := QuadMesh.new()
		beq.size = Vector2(0.09, 0.09)
		beq.material = ember_mat
		b_emb.mesh = beq
		add_child(b_emb)

	var portal_quad := MeshInstance3D.new()
	var pqm := QuadMesh.new()
	pqm.size = Vector2(3.82, 4.04)
	portal_quad.mesh = pqm
	portal_quad.position = GATE_POS + Vector3(0.0, 2.24, 0.05)
	portal_quad.material_override = _gate_portal_shader()
	add_child(portal_quad)
	var gate_light := OmniLight3D.new()
	gate_light.position = GATE_POS + Vector3(0.0, 2.2, 1.4)
	gate_light.light_color = Color(1.0, 0.64, 0.28)
	gate_light.light_energy = 0.78
	gate_light.omni_range = 6.2
	add_child(gate_light)
	_lighting_lamps.append({"light": gate_light, "base": 0.78})

	# Expedition board / totem (detailed frame, pediment, quest slips, and warm sconce).
	var board := Node3D.new()
	board.name = "ExpeditionBoard"
	board.position = BOARD_POS
	add_child(board)
	_box(Vector3(0.46, 0.26, 0.46), BOARD_POS + Vector3(0.0, 0.13, 0.0), trim_stone, false)
	_box(Vector3(0.28, 2.0, 0.28), BOARD_POS + Vector3(0.0, 1.0, 0.0), _toon_mat(Color(0.20, 0.15, 0.12)))
	_box(Vector3(1.42, 1.18, 0.16), BOARD_POS + Vector3(0.0, 2.05, 0.0), _toon_mat(Color(0.11, 0.12, 0.14)))
	_box(Vector3(1.56, 0.18, 0.26), BOARD_POS + Vector3(0.0, 2.68, 0.02), _toon_mat(Color(0.26, 0.18, 0.13)), false)
	_box(Vector3(1.14, 0.90, 0.04), BOARD_POS + Vector3(0.0, 2.04, 0.09),
		_toon_mat(Color(0.32, 0.23, 0.16)), false)
	for slip in [
		[Vector3(-0.30, 2.22, 0.12), Vector2(0.34, 0.36), Color(0.84, 0.76, 0.56)],
		[Vector3(0.22, 2.16, 0.12), Vector2(0.38, 0.42), Color(0.78, 0.68, 0.48)],
		[Vector3(-0.14, 1.82, 0.12), Vector2(0.42, 0.28), Color(0.86, 0.78, 0.58)],
	]:
		var ssz: Vector2 = slip[1]
		_box(Vector3(ssz.x, ssz.y, 0.03), BOARD_POS + slip[0], _toon_mat(slip[2]), false)
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

	# Guild Hall (west facade + open counter + barrels, crates, hanging lanterns, rug).
	_guild_root = Node3D.new()
	_guild_root.name = "GuildHall"
	add_child(_guild_root)
	var guild_mat := _toon_mat(Color(0.26, 0.21, 0.18))
	var roof := _toon_mat(Color(0.20, 0.14, 0.12))
	var wood := _toon_mat(Color(0.38, 0.27, 0.18))
	var crate_wood := _toon_mat(Color(0.46, 0.34, 0.21))
	var rug_mat := _toon_mat(Color(0.48, 0.18, 0.14))
	var rug_trim := _toon_mat(Color(0.72, 0.54, 0.24))
	var lantern_glow := _toon_mat(Color(1.0, 0.80, 0.44), Color(1.0, 0.66, 0.28), 1.55)
	# Back hall, warm recessed alcove and a chunky open counter/desk.
	_box(Vector3(3.6, 4.4, 7.0), Vector3(-12.6, 2.2, -2.0), guild_mat)
	_box(Vector3(3.8, 0.55, 7.4), Vector3(-12.6, 4.55, -2.0), roof)
	_box(Vector3(0.30, 2.4, 1.8), Vector3(-10.72, 1.2, -2.0),
		_toon_mat(Color(0.26, 0.16, 0.10), Color(0.85, 0.52, 0.22), 0.32), false)
	_box(Vector3(1.55, 1.05, 5.0), Vector3(-10.55, 0.525, -2.0), wood)
	_box(Vector3(1.95, 0.16, 5.4), Vector3(-10.55, 1.13, -2.0), _toon_mat(Color(0.54, 0.40, 0.22)), false)
	for z in [-4.2, 0.2]:
		_box(Vector3(0.24, 3.2, 0.24), Vector3(-9.55, 1.6, z), _toon_mat(Color(0.24, 0.17, 0.12)))
		_box(Vector3(0.18, 0.28, 0.18), Vector3(-9.42, 2.75, z), lantern_glow, false)
	_box(Vector3(2.6, 0.22, 5.4), Vector3(-10.15, 3.15, -2.0), roof, false)
	_box(Vector3(0.14, 0.52, 2.2), Vector3(-9.48, 2.95, -2.0),
		_toon_mat(Color(0.14, 0.18, 0.16), Color(0.84, 0.98, 0.40), 0.25), false)
	# Entry rug in front of Guild desk (non-colliding, flat).
	_box(Vector3(1.8, 0.02, 3.4), Vector3(-8.45, 0.015, -2.0), rug_trim, false)
	_box(Vector3(1.5, 0.024, 3.0), Vector3(-8.45, 0.020, -2.0), rug_mat, false)
	# Barrels (with dark iron hoops) & crates tucked under Guild eaves (outside walking lanes).
	var hoop_mat := _toon_mat(Color(0.12, 0.12, 0.14))
	for bpos in [Vector3(-10.55, 0.34, -5.0), Vector3(-10.10, 0.34, 0.95)]:
		var barrel := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = 0.28
		bc.bottom_radius = 0.28
		bc.height = 0.68
		bc.radial_segments = 10
		barrel.mesh = bc
		barrel.position = bpos
		barrel.material_override = wood
		add_child(barrel)
		for hy in [-0.18, 0.18]:
			var hoop := MeshInstance3D.new()
			var hc := CylinderMesh.new()
			hc.top_radius = 0.295
			hc.bottom_radius = 0.295
			hc.height = 0.06
			hc.radial_segments = 10
			hoop.mesh = hc
			hoop.position = bpos + Vector3(0.0, hy, 0.0)
			hoop.material_override = hoop_mat
			add_child(hoop)
	_box(Vector3(0.68, 0.64, 0.68), Vector3(-10.55, 0.32, 1.55), crate_wood, false)
	_box(Vector3(0.50, 0.48, 0.50), Vector3(-10.55, 0.88, 1.52), crate_wood, false)
	# Framed quest board & timber shelf inside the Guild alcove wall.
	_box(Vector3(0.08, 1.15, 1.65), Vector3(-10.68, 2.05, -2.0), _toon_mat(Color(0.24, 0.16, 0.11)), false)
	_box(Vector3(0.06, 0.95, 1.45), Vector3(-10.64, 2.05, -2.0), _toon_mat(Color(0.36, 0.26, 0.17)), false)
	for g_slip in [
		[Vector3(-10.60, 2.22, -2.42), 0.34, 0.32, Color(0.84, 0.76, 0.56)],
		[Vector3(-10.60, 2.15, -1.92), 0.38, 0.36, Color(0.76, 0.66, 0.46)],
		[Vector3(-10.60, 1.92, -1.52), 0.30, 0.30, Color(0.88, 0.80, 0.60)],
	]:
		_box(Vector3(0.03, float(g_slip[1]), float(g_slip[2])), g_slip[0], _toon_mat(g_slip[3]), false)
	_box(Vector3(0.32, 0.08, 1.55), Vector3(-10.60, 1.45, -3.55), crate_wood, false)
	_box(Vector3(0.14, 0.22, 0.14), Vector3(-10.58, 1.60, -3.85), _toon_mat(Color(0.26, 0.52, 0.38), Color(0.42, 0.80, 0.55), 0.35), false)
	_box(Vector3(0.16, 0.16, 0.24), Vector3(-10.58, 1.57, -3.25), _toon_mat(Color(0.78, 0.70, 0.52)), false)
	# Papers, mug, and ledger on the counter.
	_box(Vector3(0.45, 0.04, 0.6), Vector3(-10.5, 1.23, -3.2), _toon_mat(Color(0.80, 0.74, 0.56)), false)
	_box(Vector3(0.40, 0.10, 0.55), Vector3(-10.5, 1.26, -1.1), _toon_mat(Color(0.28, 0.14, 0.10)), false)
	_box(Vector3(0.14, 0.16, 0.14), Vector3(-10.42, 1.29, -2.4), _toon_mat(Color(0.58, 0.44, 0.26)), false)
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
	guild_light.light_energy = 0.48
	guild_light.omni_range = 4.8
	add_child(guild_light)
	_lighting_lamps.append({"light": guild_light, "base": 0.48})

	# Two clearly marked, empty expansion plots (no shop/heal signs).
	_plot_markers.clear()
	_plot_markers.append(_build_plot(PLOT_EAST, "PLOT A"))
	_plot_markers.append(_build_plot(PLOT_SOUTHEAST, "PLOT B"))


func _build_plot(center: Vector3, label: String) -> Node3D:
	var pad := _toon_mat(Color(0.28, 0.24, 0.20))
	var border := _toon_mat(Color(0.44, 0.39, 0.34))
	var rope := _toon_mat(Color(0.62, 0.48, 0.28))
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
		_box(Vector3(0.14, 0.95, 0.14), center + corner + Vector3(0.0, 0.475, 0.0),
			_toon_mat(Color(0.38, 0.30, 0.20)))
		_box(Vector3(0.20, 0.10, 0.20), center + corner + Vector3(0.0, 0.96, 0.0), rope, false)
	# Perimeter survey rope rails between corner stakes (north, south, east edges).
	_box(Vector3(3.6, 0.05, 0.05), center + Vector3(0.0, 0.72, -1.8), rope, false)
	_box(Vector3(3.6, 0.05, 0.05), center + Vector3(0.0, 0.72, 1.8), rope, false)
	_box(Vector3(0.05, 0.05, 3.6), center + Vector3(1.8, 0.72, 0.0), rope, false)
	_box(Vector3(0.05, 0.05, 3.6), center + Vector3(-1.8, 0.72, 0.0), rope, false)
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
	_sync_dynamic_travelers()
	_refresh_hud_help_label()
	_refresh_gate_leader_strip()


func _build_enemy() -> void:
	# The hub has no enemies: ambient NPCs only.
	pass


# --- Ambient NPCs (H2) -------------------------------------------------------

func _build_npcs() -> void:
	for spec in HUB_NPC_SPECS:
		_spawn_npc_spec(spec)
	var travelers := _pick_dynamic_travelers()
	for i in travelers.size():
		var slot: Dictionary = TRAVELER_SLOTS[i]
		_spawn_npc_spec({
			"id": travelers[i],
			"role": "TRAVELER",
			"pos": slot["pos"],
			"yaw": slot["yaw"],
			"icon": "question",
			"patrol": true,
			"portal_eligible": true,
			"is_dynamic_traveler": true,
			"traveler_slot": i,
			"line": "[PROTÓTIPO] Outro viajante descansando na praça antes do portal.",
		})


func _pick_dynamic_travelers() -> Array[String]:
	var available: Array[String] = []
	for leader in PLAYABLE_LEADERS:
		if leader == player_model_id:
			continue
		var used := false
		for follower in _followers:
			if String(follower.get("model_id", "")) == leader:
				used = true
				break
		if not used:
			available.append(leader)
	var picked: Array[String] = []
	while picked.size() < 2 and not available.is_empty():
		var index := _rng.randi_range(0, available.size() - 1)
		picked.append(available[index])
		available.remove_at(index)
	return picked


func _sync_dynamic_travelers() -> void:
	var travelers := _pick_dynamic_travelers()
	for npc in _npcs:
		if not bool(npc.get("is_dynamic_traveler", false)):
			continue
		var slot := int(npc.get("traveler_slot", 0))
		if slot >= travelers.size():
			continue
		var new_id: String = travelers[slot]
		if String(npc.get("id", "")) == new_id:
			continue
		var body: Node3D = npc.get("node")
		if body == null:
			continue
		var new_h: float = float(HUB_HEIGHTS.get(new_id, 0.9))
		var old_model: Node = npc.get("model")
		if old_model != null:
			body.remove_child(old_model)
			old_model.queue_free()
		var new_model: Node3D = _make_model(new_id, new_h)
		new_model.name = new_id
		body.add_child(new_model)
		_apply_toon_to_actor(body)
		var new_ap = _anim_player(new_model)
		npc["model"] = new_model
		npc["ap"] = new_ap
		npc["id"] = new_id
		npc["name"] = HUB_NAMES.get(new_id, new_id.to_upper())
		npc["height"] = new_h
		body.name = "Npc_%s" % new_id
		for child in body.get_children():
			if child is CollisionShape3D:
				var cap := child.shape as CapsuleShape3D
				if cap != null:
					cap.radius = clampf(new_h * 0.30, 0.22, 0.42)
					cap.height = maxf(new_h, cap.radius * 2.0 + 0.05)
					child.position.y = cap.height * 0.5
		var top: float = _actor_visual_top(body)
		var ring_node := body.get_node_or_null("NpcGroundRing") as MeshInstance3D
		if ring_node != null and ring_node.mesh is PlaneMesh:
			var r_size := clampf(new_h * 0.92, 0.80, 1.70)
			(ring_node.mesh as PlaneMesh).size = Vector2(r_size, r_size)
		var plate = npc.get("plate")
		if plate != null:
			plate.display_name = npc["name"]
			plate.position.y = top + 0.45
			plate.set_style(plate.style_id)
		var icon_entry: Dictionary = npc.get("icon_entry", {})
		icon_entry["base_scale"] = clampf(top / 1.25, 0.48, 0.88)
		icon_entry["base_y"] = top + 1.15
		if icon_entry.get("sprite") is Node3D:
			var sprite: Node3D = icon_entry["sprite"]
			sprite.position.y = top + 1.15
		if str(npc.get("state", "")) != "away_in_portal":
			new_model.scale = Vector3.ONE
			_play_idle(new_ap)


func _add_npc_ground_ring(body: Node3D, height: float) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "NpcGroundRing"
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := PlaneMesh.new()
	var r_size := clampf(height * 0.92, 0.80, 1.70)
	pm.size = Vector2(r_size, r_size)
	ring.mesh = pm
	ring.position = Vector3(0.0, 0.028, 0.0)
	var mat := ShaderMaterial.new()
	mat.shader = MARKER_RING_SHADER
	mat.set_shader_parameter("ring_color", Color(1.0, 1.0, 1.0, 0.68))
	mat.set_shader_parameter("inner_radius", 0.85)
	mat.set_shader_parameter("outer_radius", 0.93)
	mat.set_shader_parameter("softness", 0.04)
	mat.set_shader_parameter("alpha", 0.68)
	ring.material_override = mat
	body.add_child(ring)


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
	_add_npc_ground_ring(body, height)
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
		"portal_eligible": bool(spec.get("portal_eligible", patrol_enabled)),
		"portal_timer": _rng.randf_range(14.0, 24.0),
		"portal_phase_t": 0.0,
		"away_duration": 0.0,
		"is_dynamic_traveler": bool(spec.get("is_dynamic_traveler", false)),
		"traveler_slot": int(spec.get("traveler_slot", -1)),
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
	var candidates: Array[Vector3] = [
		BOARD_POS + Vector3(0.9, 0.0, 1.5),
		GUILD_POS + Vector3(2.8, 0.0, 0.8),
		PLOT_EAST + Vector3(-2.6, 0.0, 0.6),
		PLOT_SOUTHEAST + Vector3(-2.5, 0.0, -0.6),
	]
	for k in 4:
		var ang := float(idx) * 1.7 + TAU * float(k) / 4.0
		candidates.append(home + Vector3(cos(ang), 0.0, sin(ang)) * 1.6)
	var forbidden := [GATE_POS, GUILD_POS, PLOT_EAST, PLOT_SOUTHEAST]
	var out: Array[Vector3] = []
	for p in candidates:
		p.x = clampf(p.x, -PLAZA_HALF_X + 1.8, PLAZA_HALF_X - 1.8)
		p.z = clampf(p.z, -PLAZA_HALF_Z + 1.8, PLAZA_HALF_Z - 1.8)
		var clear := true
		for f in forbidden:
			if Vector2(p.x - f.x, p.z - f.z).length() < 2.2:
				clear = false
				break
		if clear:
			out.append(p)
	if out.is_empty():
		out.append(home)
	var rotated: Array[Vector3] = []
	for i in out.size():
		rotated.append(out[(i + idx) % out.size()])
	return rotated


func _active_portal_travelers() -> int:
	var count := 0
	for npc in _npcs:
		if bool(npc.get("portal_eligible", false)) and str(npc.get("state", "")) in ["to_portal", "entering_portal", "exiting_portal"]:
			count += 1
	return count


func _set_npc_portal_active(npc: Dictionary, active_in_world: bool) -> void:
	var body := npc.get("node") as Node3D
	if is_instance_valid(body):
		body.visible = active_in_world
		body.collision_layer = NPC_COLLISION_LAYER if active_in_world else 0
	var sprite = (npc.get("icon_entry", {}) as Dictionary).get("sprite")
	if sprite is Node3D and is_instance_valid(sprite):
		sprite.visible = active_in_world


func _on_portal_pulse(kind: String, world_pos: Vector3) -> void:
	_last_portal_pulse = {"kind": kind, "pos": world_pos, "t": _atmo_time}
	_portal_pulse_val = 1.0
	if _portal_quad_mat != null:
		_portal_quad_mat.set_shader_parameter("pulse_boost", _portal_pulse_val)
	if not is_inside_tree() or _scenario == "HUB_PORTAL_CYCLE":
		return
	var ring := MeshInstance3D.new()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.4, 1.4)
	ring.mesh = pm
	ring.rotation.x = PI * 0.5
	ring.position = Vector3(world_pos.x, 1.35, world_pos.z + 0.15)
	var mat := ShaderMaterial.new()
	mat.shader = MARKER_RING_SHADER
	var tint := Color(1.0, 0.76, 0.30, 0.92) if kind == "enter" else Color(1.0, 0.90, 0.48, 0.95)
	mat.set_shader_parameter("ring_color", tint)
	mat.set_shader_parameter("inner_radius", 0.68)
	mat.set_shader_parameter("outer_radius", 0.96)
	mat.set_shader_parameter("softness", 0.08)
	mat.set_shader_parameter("alpha", 0.85)
	ring.material_override = mat
	add_child(ring)
	_portal_ring_fx.append({"mesh": ring, "mat": mat, "age": 0.0, "dur": 0.55})


func _nearest_visible_neighbor(from_body: Node3D, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_dist := max_dist
	for npc in _npcs:
		var other := npc.get("node") as Node3D
		if other == null or other == from_body or not is_instance_valid(other) or not other.visible:
			continue
		var d := from_body.global_position.distance_to(other.global_position)
		if d < best_dist:
			best_dist = d
			best = other
	return best


func _update_npc_portal(npc: Dictionary, body: Node3D, model: Node3D, ap: AnimationPlayer, delta: float) -> bool:
	var state := str(npc.get("state", ""))
	if state == "away_in_portal":
		npc["away_duration"] = float(npc.get("away_duration", 0.0)) - delta
		if float(npc["away_duration"]) <= 0.0:
			body.global_position = PORTAL_VORTEX_POS
			body.rotation.y = 0.0
			if model != null:
				model.scale = Vector3.ZERO
			_set_npc_portal_active(npc, true)
			_on_portal_pulse("exit", PORTAL_VORTEX_POS)
			_portal_exits_count += 1
			npc["state"] = "exiting_portal"
			npc["portal_phase_t"] = 0.0
		return true
	if state == "entering_portal":
		npc["portal_phase_t"] = float(npc.get("portal_phase_t", 0.0)) + delta
		var t := float(npc["portal_phase_t"])
		if t < 0.40:
			body.rotation.y = PI
			_play_idle(ap)
		else:
			var shrink := clampf((t - 0.40) / 0.55, 0.0, 1.0)
			body.global_position = PORTAL_ENTRY_POS.lerp(PORTAL_VORTEX_POS, shrink)
			if model != null:
				model.scale = Vector3.ONE * lerpf(1.0, 0.0, shrink)
		if t >= 0.95:
			_portal_entries_count += 1
			npc["state"] = "away_in_portal"
			npc["away_duration"] = _rng.randf_range(8.0, 14.0)
			_set_npc_portal_active(npc, false)
		return true
	if state == "exiting_portal":
		npc["portal_phase_t"] = float(npc.get("portal_phase_t", 0.0)) + delta
		var t := float(npc["portal_phase_t"])
		var grow := clampf(t / 0.65, 0.0, 1.0)
		body.global_position = PORTAL_VORTEX_POS.lerp(PORTAL_EXIT_LAND_POS, grow)
		body.rotation.y = 0.0
		if model != null:
			model.scale = Vector3.ONE * lerpf(0.0, 1.0, grow)
		if ap != null and ap.has_animation("run"):
			_play(ap, "run")
		elif ap != null and ap.has_animation("walk"):
			_play(ap, "walk")
		else:
			_play_idle(ap)
		if t >= 0.65:
			if model != null:
				model.scale = Vector3.ONE
			npc["portal_timer"] = _rng.randf_range(14.0, 24.0)
			npc["state"] = "walk"
		return true
	if state == "to_portal":
		var step_to := PORTAL_ENTRY_POS - body.global_position
		step_to.y = 0.0
		if step_to.length() <= 0.25:
			npc["state"] = "entering_portal"
			npc["portal_phase_t"] = 0.0
			_on_portal_pulse("enter", PORTAL_VORTEX_POS)
		else:
			var speed := maxf(float(npc.get("walk_speed", 1.25)), 1.45) * delta
			body.global_position += step_to.normalized() * speed
			body.rotation.y = lerp_angle(body.rotation.y, atan2(step_to.x, step_to.z), 0.15)
			if ap != null and ap.has_animation("walk"):
				_play(ap, "walk")
			else:
				_play_idle(ap)
		return true
	return false


func _update_npc_life(delta: float) -> void:
	var ppos := player.global_position
	for npc in _npcs:
		var body: Node3D = npc["node"]
		if not is_instance_valid(body):
			continue
		var model := npc.get("model") as Node3D
		var ap := npc.get("ap") as AnimationPlayer
		if _update_npc_portal(npc, body, model, ap, delta):
			continue
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
			var neighbor := _nearest_visible_neighbor(body, 3.4)
			if neighbor != null:
				var to_n := neighbor.global_position - body.global_position
				to_n.y = 0.0
				body.rotation.y = lerp_angle(body.rotation.y, atan2(to_n.x, to_n.z), 0.08)
			if not _freeze_npc_patrol() and bool(npc.get("portal_eligible", false)) and not talking and dist >= 3.0:
				npc["portal_timer"] = float(npc.get("portal_timer", 0.0)) - delta
				if float(npc["portal_timer"]) <= 0.0 and _active_portal_travelers() < 2:
					npc["state"] = "to_portal"
					npc["portal_phase_t"] = 0.0
					continue
			if float(npc["pause_timer"]) <= 0.0:
				npc["state"] = "walk"
			continue
		if not _freeze_npc_patrol() and bool(npc.get("portal_eligible", false)) and not talking and dist >= 3.0:
			npc["portal_timer"] = float(npc.get("portal_timer", 0.0)) - delta
			if float(npc["portal_timer"]) <= 0.0 and _active_portal_travelers() < 2:
				npc["state"] = "to_portal"
				npc["portal_phase_t"] = 0.0
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
		if str(npc.get("state", "")) == "away_in_portal":
			continue
		var t_body := npc.get("node") as Node3D
		if t_body == null or not t_body.visible:
			continue
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
		var show := is_instance_valid(node) and node.visible
		if show and m["kind"] == "npc":
			var mnpc: Dictionary = m.get("npc", {})
			if str(mnpc.get("state", "")) == "away_in_portal":
				show = false
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
	await _arrival.warm_up()  # still under the loading screen: no hitch after it
	if not is_instance_valid(transition):
		return
	transition.notify_hub_ready(self)
	_sync_hud_visibility()


func _end_arrival() -> void:
	_arrival = null
	_sync_hud_visibility()
	_maybe_open_ally_choice()  # D-1260


## D-1260: opens the ally choice once, right after arriving in the Hub on a new campaign. The
## offer lives in GameState (`ally_choice_pending`), so re-entering the Hub never reopens it.
## The choice screen itself (visual) is pending the creator's approval: until it exists this only
## reports the offer; `apply_ally_choice` is the single entry point the screen will call.
func _maybe_open_ally_choice() -> void:
	if not GameState.ally_choice_pending:
		return
	if "--stdout-trace" in OS.get_cmdline_user_args():
		print("ALLY_OFFER_JSON: " + JSON.stringify({"offered": GameState.ally_choice_candidates}))


## D-1260: confirms the ally in GameState and makes it a visible Hub follower (any species, D-235).
func apply_ally_choice(species: String) -> bool:
	if not GameState.choose_ally(species):
		return false
	_sync_followers_to_party()
	_party_for_status = GameState.party
	return true


## D-1260: Hub followers mirror GameState.party[1..] (none for a leader-only party). Without a
## campaign party (debug lab) the lab's own demo followers stay untouched.
func _sync_followers_to_party() -> void:
	if GameState.party.is_empty():
		return
	for f in _followers:
		if is_instance_valid(f["node"]):
			(f["node"] as Node).queue_free()
	_followers.clear()
	if _marker_root != null:
		for i in range(_minimap_markers.size() - 1, -1, -1):
			if _minimap_markers[i]["kind"] == "ally":
				(_minimap_markers[i]["rect"] as Node).queue_free()
				_minimap_markers.remove_at(i)
	var slot := 0
	for i in range(1, GameState.party.size()):
		var sid := GameState.species_key(GameState.party[i])
		if not HEIGHTS.has(sid):
			continue
		var side := -0.9 if slot % 2 == 0 else 1.7
		_add_follower(sid, side, 1.3 + 0.7 * slot, Vector3(side, 0.0, 1.3 + 0.7 * slot))
		_apply_toon_to_actor(_followers[-1]["node"])
		if _marker_root != null:
			_add_minimap_marker(_followers[-1]["node"], Color(0.45, 0.78, 1.0, 1.0), "ally")
		slot += 1
	if GameState.active_campaign_started and not _followers.is_empty():
		# A real campaign's ally accompanies the leader in the Hub (D-1260).
		_party_visible = true
		_cam_pitch = PARTY_CAM_PITCH
		for f in _followers:
			(f["node"] as Node3D).visible = true


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
	var fungi_icon := "res://sugimori/dqt/0038_obakekinoko/icone_MonsterIcon_0038_d25f8ed185df1883.png"
	if tex == null and key == "dqt_fungi" and ResourceLoader.exists(fungi_icon):
		tex = load(fungi_icon)
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
	var driving := dir.length_squared() > 0.01
	_play_move(player_ap, driving)
	if driving:
		if _apply_gait(player_ap, player_model, Vector2(player.velocity.x, player.velocity.z).length()) < 0.0:
			player_ap.speed_scale = 1.0
	elif player_ap != null:
		player_ap.speed_scale = 1.0
		_apply_ground_lift(player_ap, player_model, "idle")


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
		"HUB_PORTAL_CYCLE":
			await _scenario_portal_cycle()
		"HUB_ATMOSPHERE":
			await _scenario_atmosphere()
		"HUB_ALLY_CHOICE":
			await _scenario_ally_choice()
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
	_check("npc_count", _npcs.size() == HUB_NPC_SPECS.size() + 2, "%d" % _npcs.size())
	var dynamic_travelers_distinct: Array[String] = []
	for npc in _npcs:
		if bool(npc.get("is_dynamic_traveler", false)):
			var npc_id := str(npc.get("id", ""))
			if not dynamic_travelers_distinct.has(npc_id):
				dynamic_travelers_distinct.append(npc_id)
	var forbidden_traveler_ids: Array[String] = [str(player_model_id)]
	for follower in _followers:
		forbidden_traveler_ids.append(str(follower.get("model_id", "")))
	var travelers_distinct_ok := dynamic_travelers_distinct.size() == 2
	for traveler_id in dynamic_travelers_distinct:
		if forbidden_traveler_ids.has(traveler_id):
			travelers_distinct_ok = false
	_check("dynamic_travelers_distinct", travelers_distinct_ok, "%d" % dynamic_travelers_distinct.size())
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


## D-1260: new campaign = leader only; 3 distinct candidates (never the leader); choosing one makes a
## 2-member party and one Hub follower; the offer never reopens. Runs for all 6 leaders (D-235).
func _scenario_ally_choice() -> void:
	for leader in PLAYABLE_LEADERS:
		GameState.start_new_campaign(leader)
		var tag := str(leader)
		_check("%s_party_is_leader_only" % tag, GameState.party.size() == 1 and GameState.species_key(GameState.party[0]) == leader,
			"party=%d" % GameState.party.size())
		var cands: Array[String] = GameState.ally_choice_candidates
		var distinct := true
		for c in cands:
			if c == leader or cands.count(c) != 1 or not PLAYABLE_LEADERS.has(c):
				distinct = false
		_check("%s_three_distinct_candidates" % tag, GameState.ally_choice_pending and cands.size() == 3 and distinct, str(cands))
		_set_player_species(leader)
		_sync_followers_to_party()
		_check("%s_no_follower_before_choice" % tag, _followers.is_empty(), "%d" % _followers.size())
		_check("%s_reject_not_offered" % tag, not apply_ally_choice(leader), "leader refused")
		var pick: String = cands[_rng.randi_range(0, cands.size() - 1)]
		_check("%s_choose_ok" % tag, apply_ally_choice(pick), pick)
		await _frames(1)
		_check("%s_party_of_two" % tag, GameState.party.size() == 2 and GameState.species_key(GameState.party[1]) == pick)
		_check("%s_one_hub_follower" % tag, _followers.size() == 1 and str(_followers[0]["model_id"]) == pick and _party_visible)
		_check("%s_no_reopen" % tag, not GameState.ally_choice_pending and not apply_ally_choice(cands[0]))
		_sync_followers_to_party()  # re-entering the Hub keeps the ally and does not offer again
		_check("%s_reentry_keeps_ally" % tag, _followers.size() == 1 and not GameState.ally_choice_pending)


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


func _scenario_portal_cycle() -> void:
	var t0 := Time.get_ticks_msec()
	var eligible: Array[Dictionary] = []
	var first_traveler: Dictionary = {}
	var first_nontraveler: Dictionary = {}
	for npc in _npcs:
		if bool(npc.get("is_dynamic_traveler", false)):
			if first_traveler.is_empty():
				first_traveler = npc
		elif bool(npc.get("portal_eligible", false)) and first_nontraveler.is_empty():
			first_nontraveler = npc
	if not first_nontraveler.is_empty():
		eligible.append(first_nontraveler)
	if not first_traveler.is_empty():
		eligible.append(first_traveler)
	if eligible.size() < 2:
		eligible.clear()
		for npc in _npcs:
			if bool(npc.get("portal_eligible", false)):
				eligible.append(npc)
				if eligible.size() == 2:
					break
	_check("portal_cycle_pool", eligible.size() >= 2, "%d" % eligible.size())
	for idx in mini(2, eligible.size()):
		var npc: Dictionary = eligible[idx]
		var body := npc.get("node") as Node3D
		var model := npc.get("model") as Node3D
		if body == null:
			continue
		body.global_position = PORTAL_ENTRY_POS + Vector3(0.0, 0.0, 0.30)
		body.rotation.y = 0.0
		if model != null:
			model.scale = Vector3.ONE
		_set_npc_portal_active(npc, true)
		npc["state"] = "to_portal"
		npc["portal_phase_t"] = 0.0
		for _k in 25:
			_update_npc_life(0.1)
			_update_minimap()
			if str(npc.get("state", "")) == "away_in_portal":
				break
		_check("portal_enter_%d" % idx, str(npc.get("state", "")) == "away_in_portal",
			str(npc.get("state", "")))
		_check("portal_hidden_%d" % idx, not body.visible)
		_check("portal_collision_off_%d" % idx, body.collision_layer == 0)
		_check("portal_target_hidden_%d" % idx, not _target_has_npc(npc))
		_check("portal_marker_hidden_%d" % idx, not _minimap_marker_visible(body))
		_check("portal_entries_%d" % idx, _portal_entries_count >= idx + 1, "%d" % _portal_entries_count)
		_check("portal_pulse_enter_%d" % idx, str(_last_portal_pulse.get("kind", "")) == "enter",
			str(_last_portal_pulse.get("kind", "")))
		npc["away_duration"] = 0.05
		for _k in 15:
			_update_npc_life(0.1)
			_update_minimap()
			if str(npc.get("state", "")) == "walk":
				break
		_check("portal_exit_%d" % idx, str(npc.get("state", "")) == "walk",
			str(npc.get("state", "")))
		_check("portal_visible_%d" % idx, body.visible)
		_check("portal_collision_on_%d" % idx, body.collision_layer == NPC_COLLISION_LAYER)
		_check("portal_target_shown_%d" % idx, _target_has_npc(npc))
		_check("portal_marker_shown_%d" % idx, _minimap_marker_visible(body))
		_check("portal_scale_%d" % idx, model != null and model.scale.is_equal_approx(Vector3.ONE))
		_check("portal_exits_%d" % idx, _portal_exits_count >= idx + 1, "%d" % _portal_exits_count)
		_check("portal_pulse_exit_%d" % idx, str(_last_portal_pulse.get("kind", "")) == "exit",
			str(_last_portal_pulse.get("kind", "")))
	_set_player_species("pancham")
	var traveler_ids: Array[String] = []
	for npc in _npcs:
		if bool(npc.get("is_dynamic_traveler", false)):
			var npc_id := str(npc.get("id", ""))
			if not traveler_ids.has(npc_id):
				traveler_ids.append(npc_id)
	var forbidden: Array[String] = [str(player_model_id)]
	for follower in _followers:
		forbidden.append(str(follower.get("model_id", "")))
	var travelers_ok := traveler_ids.size() == 2
	for traveler_id in traveler_ids:
		if forbidden.has(traveler_id):
			travelers_ok = false
	_check("traveler_f6_synced", travelers_ok, "%d" % traveler_ids.size())
	_check("portal_cycle_fast", (Time.get_ticks_msec() - t0) < 10000,
		"%d" % (Time.get_ticks_msec() - t0))


func _target_has_npc(npc: Dictionary) -> bool:
	var body := npc.get("node") as Node3D
	for target in _targets():
		if target.get("npc", null) == npc:
			return true
		if body != null and target.get("body", null) == body:
			return true
	return false


func _minimap_marker_visible(node: Node3D) -> bool:
	for m in _minimap_markers:
		if m.get("node") == node:
			return is_instance_valid(m.get("rect")) and m["rect"].visible
	return false
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
		"portal_pulse":
			await _teleport(Vector3(0.0, 0.0, -4.5), PI)
			_cam_yaw = PI
			await _frames(4)
			for npc in _npcs:
				if bool(npc.get("portal_eligible", false)) and not bool(npc.get("is_dynamic_traveler", false)):
					var nb := npc["node"] as Node3D
					nb.global_position = PORTAL_ENTRY_POS + Vector3(0.0, 0.0, 0.35)
					npc["state"] = "to_portal"
					npc["portal_phase_t"] = 0.0
					break
			await _frames(46)
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
