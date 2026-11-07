class_name WeatherController
extends Node
## Clima visual da exploração (D-381/D-382/D-383).
##
## Só visual: não altera movimento, combate, colisão, câmera, geração, raio de
## visão, LOS nem o explorado. É uma camada 2D de ambiente, fora do Motion
## Composer. Neblina e chuva implementadas; calor/neve/cinza e distorção
## temporal entram depois, na ordem de D-362.
##
## A rolagem é determinística por andar: 20% de chance (1 em 5), no máximo um
## evento por andar. O evento começa no início do andar e dura 20–40 s.

const BiomeVisuals := preload("res://scripts/dungeon/biome_visuals.gd")
const WeatherRainClass := preload("res://scripts/dungeon/weather_rain.gd")

const CHANCE := 0.20
const DURATION_MIN := 20.0
const DURATION_MAX := 40.0
const FADE := 2.0
const START_DELAY := 0.8

const MIST_BIOMES := [
	"murky_forest", "spacial_cliffs", "7th_station_pass", "icicle_forest",
	"vast_ice_mountain", "vast_ice_mountain_peak", "temporal_spire", "temporal_tower",
]
const HEAT_BIOMES := [
	"barren_valley", "dark_wasteland", "deep_boulder_quarry",
	"deep_limestone_cavern", "limestone_cavern",
]
const RAIN_BIOMES := [
	"4th_station_pass", "murky_forest", "spacial_cliffs", "temporal_spire",
]
const SNOW_BIOMES := [
	"dark_ice_mountain", "dark_ice_mountain_peak", "vast_ice_mountain",
	"vast_ice_mountain_peak", "icicle_forest",
]
const TEMPORAL_BIOMES := ["temporal_tower", "temporal_spire"]

## Debug/captura: "mist" ou "rain" força o clima, ignorando a rolagem e o bioma.
static var debug_force := ""
## Debug/captura: true desliga o clima para a captura "antes".
static var debug_disable := false
## Debug/vídeo: duração fixa do evento (0 = usa 20–40 s).
static var debug_duration := 0.0
## Andares que já mostraram o evento nesta execução (seed + andar).
static var _played: Dictionary = {}

var _state: Object
var _fog: Node2D
var _map: Array[String] = []
var _player: Node2D
var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _heat_layer: CanvasLayer
var _heat_rect: ColorRect
var _heat_mat: ShaderMaterial
var _heat_dust: CPUParticles2D
var _event_type := ""
var _active := false
var _pending_key := ""
var _pending_biome := ""
var _pending_seed := 0
var _pending_floor := 0


func setup(state: Object, fog: Node2D, map: Array[String], player: Node2D) -> void:
	_state = state
	_fog = fog
	_map = map
	_player = player
	_resolve_and_start()


func get_active_weather() -> String:
	return _event_type if _active else ""


func is_active() -> bool:
	return _active


func _process(_delta: float) -> void:
	if _heat_dust != null and is_instance_valid(_heat_dust) and _player != null:
		_heat_dust.position = _player.position


func _resolve_and_start() -> void:
	if debug_disable:
		return
	if _state == null:
		return
	var biome := str(_state.get("visual_biome"))
	var seed_value := int(_state.get("dungeon_seed"))
	var floor_value := int(_state.get("visual_floor"))
	var key := "%d:%d" % [seed_value, floor_value]

	if debug_force != "":
		_event_type = debug_force
	else:
		if _played.has(key):
			return
		if not roll_for(seed_value, floor_value):
			return
		_event_type = weather_for(biome, seed_value, floor_value)
		if _event_type != "mist" and _event_type != "rain" and _event_type != "heat":
			# Neve/cinza/distorção ainda não implementados.
			return

	if _event_type != "mist" and _event_type != "rain" and _event_type != "heat":
		return

	_pending_key = key
	_pending_biome = biome
	_pending_seed = seed_value
	_pending_floor = floor_value
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = START_DELAY
	timer.timeout.connect(_on_start_delay)
	add_child(timer)
	timer.start()


func _on_start_delay() -> void:
	if debug_force == "":
		_played[_pending_key] = true
	if _event_type == "rain":
		_start_rain(_pending_seed, _pending_floor)
	elif _event_type == "heat":
		_start_heat(_pending_seed, _pending_floor)
	else:
		_start_mist(_pending_biome, _pending_seed, _pending_floor)


## Rolagem determinística: 20% por andar (1 em 5).
static func roll_for(seed_value: int, floor_value: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = _hash_seed(seed_value, floor_value, 11)
	return rng.randf() < CHANCE


## Tipo de clima do bioma. Biomas com mais de um tipo (ex.: murky_forest tem
## neblina e chuva) escolhem deterministicamente entre eles.
static func weather_for(biome: String, seed_value: int, floor_value: int) -> String:
	var options: Array[String] = []
	if MIST_BIOMES.has(biome):
		options.append("mist")
	if HEAT_BIOMES.has(biome):
		options.append("heat")
	if RAIN_BIOMES.has(biome):
		options.append("rain")
	if SNOW_BIOMES.has(biome):
		options.append("snow")
	if biome == "dark_wasteland":
		options.append("ash")
	if TEMPORAL_BIOMES.has(biome):
		options.append("temporal")
	if options.is_empty():
		return ""
	var idx := _hash_seed(seed_value, floor_value, 23) % options.size()
	return options[idx]


static func _hash_seed(seed_value: int, floor_value: int, salt: int) -> int:
	var h := seed_value * 73856093 ^ floor_value * 19349663 ^ salt * 83492791
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7FFFFFFF


func _duration_for(seed_value: int, floor_value: int) -> float:
	if debug_duration > 0.0:
		return maxf(debug_duration, FADE * 2.0 + 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = _hash_seed(seed_value, floor_value, 37)
	return rng.randf_range(DURATION_MIN, DURATION_MAX)


func _start_mist(biome: String, seed_value: int, floor_value: int) -> void:
	if _active:
		return
	_active = true

	_layer = CanvasLayer.new()
	_layer.name = "WeatherLayer"
	_layer.layer = 1
	add_child(_layer)

	_rect = ColorRect.new()
	_rect.name = "Mist"
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.light_mask = 0
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/weather_mist.gdshader") as Shader
	_mat.set_shader_parameter("mist", 0.0)
	_mat.set_shader_parameter("mist_color", _mist_color(biome))
	_mat.set_shader_parameter("max_alpha", 0.40)
	_mat.set_shader_parameter("density", 0.85)
	_mat.set_shader_parameter("drift", 0.006)
	_mat.set_shader_parameter("noise_scale", 1.7)
	_mat.set_shader_parameter("edge_mist", 0.75)
	_mat.set_shader_parameter("noise_tex", _noise_texture())
	_rect.material = _mat
	_layer.add_child(_rect)

	var duration := _duration_for(seed_value, floor_value)
	var hold := maxf(duration - FADE * 2.0, 0.1)
	var tween := create_tween()
	tween.tween_property(_mat, "shader_parameter/mist", 1.0, FADE)
	tween.tween_interval(hold)
	tween.tween_property(_mat, "shader_parameter/mist", 0.0, FADE)
	tween.finished.connect(_on_mist_finished)


func _mist_color(biome: String) -> Color:
	var base := BiomeVisuals.ambient(biome)
	return base.lerp(Color(0.82, 0.86, 0.90), 0.60)


func _noise_texture() -> Texture2D:
	if _fog != null:
		var fog_mat := _fog.material as ShaderMaterial
		if fog_mat != null:
			var noise = fog_mat.get_shader_parameter("noise_tex")
			if noise is Texture2D:
				return noise as Texture2D
	var fast := FastNoiseLite.new()
	fast.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fast.frequency = 0.035
	fast.fractal_octaves = 3
	fast.seed = 7
	var tex := NoiseTexture2D.new()
	tex.noise = fast
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	return tex


func _on_mist_finished() -> void:
	_active = false
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_rect = null
	_mat = null


func _start_rain(seed_value: int, floor_value: int) -> void:
	if _active:
		return
	_active = true
	var rain = WeatherRainClass.new()
	rain.setup(_map, _player)
	rain.finished.connect(_on_rain_finished)
	add_child(rain)
	rain.start(_duration_for(seed_value, floor_value))


func _on_rain_finished() -> void:
	_active = false


func _start_heat(seed_value: int, floor_value: int) -> void:
	if _active:
		return
	_active = true

	_heat_layer = CanvasLayer.new()
	_heat_layer.name = "HeatLayer"
	_heat_layer.layer = 1
	add_child(_heat_layer)

	_heat_rect = ColorRect.new()
	_heat_rect.name = "Heat"
	_heat_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_heat_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heat_rect.light_mask = 0
	_heat_mat = ShaderMaterial.new()
	_heat_mat.shader = load("res://shaders/weather_heat.gdshader") as Shader
	_heat_mat.set_shader_parameter("amount", 0.0)
	_heat_rect.material = _heat_mat
	_heat_layer.add_child(_heat_rect)

	_heat_dust = _make_heat_dust()
	if _player != null:
		_heat_dust.position = _player.position
	_heat_dust.modulate = Color(1, 1, 1, 0)
	add_child(_heat_dust)
	_heat_dust.emitting = true

	var duration := _duration_for(seed_value, floor_value)
	var hold := maxf(duration - FADE * 2.0, 0.1)
	var tween := create_tween()
	tween.tween_property(_heat_mat, "shader_parameter/amount", 1.0, FADE)
	tween.parallel().tween_property(_heat_dust, "modulate:a", 1.0, FADE)
	tween.tween_interval(hold)
	tween.tween_property(_heat_mat, "shader_parameter/amount", 0.0, FADE)
	tween.parallel().tween_property(_heat_dust, "modulate:a", 0.0, FADE)
	tween.finished.connect(_on_heat_finished)


func _make_heat_dust() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "HeatDust"
	p.amount = 32
	p.lifetime = 3.2
	p.one_shot = false
	p.explosiveness = 0.0
	p.randomness = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(300, 80)
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2(0, -8)
	p.initial_velocity_min = 8
	p.initial_velocity_max = 22
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1
	p.color = Color(1.0, 0.78, 0.45, 0.55)
	p.texture = _heat_dust_texture()
	p.local_coords = false
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.z_index = 96
	return p


func _heat_dust_texture() -> Texture2D:
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(1.0, 0.85, 0.55, 1.0))
	img.set_pixel(0, 1, Color(1.0, 0.85, 0.55, 0.35))
	img.set_pixel(2, 1, Color(1.0, 0.85, 0.55, 0.35))
	img.set_pixel(1, 0, Color(1.0, 0.85, 0.55, 0.35))
	img.set_pixel(1, 2, Color(1.0, 0.85, 0.55, 0.35))
	return ImageTexture.create_from_image(img)


func _on_heat_finished() -> void:
	_active = false
	if is_instance_valid(_heat_layer):
		_heat_layer.queue_free()
	if is_instance_valid(_heat_dust):
		_heat_dust.queue_free()
	_heat_layer = null
	_heat_rect = null
	_heat_mat = null
	_heat_dust = null
