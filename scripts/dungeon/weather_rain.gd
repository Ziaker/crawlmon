class_name WeatherRain
extends Node2D
## Chuva 2D de ambiente (D-386): gotas em espaço de mundo e respingos nas
## células de chão perto do jogador. Puramente visual, fora do Motion Composer
## (D-383). Usa CPUParticles2D porque o projeto é GL Compatibility.

signal finished

const TILE := 48
const FADE := 2.0

var _map: Array[String] = []
var _player: Node2D
var _drops: CPUParticles2D
var _splashes: CPUParticles2D
var _splash_timer := 0.0
var _active := false


func setup(map: Array[String], player: Node2D) -> void:
	_map = map
	_player = player


func start(duration: float) -> void:
	_active = true
	_drops = _make_drops()
	_splashes = _make_splashes()
	add_child(_drops)
	add_child(_splashes)
	_drops.modulate = Color(1, 1, 1, 0)
	_splashes.modulate = Color(1, 1, 1, 0)
	_update_emitters()
	_update_splash_points()
	_drops.emitting = true
	_splashes.emitting = true

	var tween := create_tween()
	tween.tween_property(_drops, "modulate:a", 1.0, FADE)
	tween.parallel().tween_property(_splashes, "modulate:a", 1.0, FADE)
	tween.tween_interval(maxf(duration - FADE * 2.0, 0.1))
	tween.tween_property(_drops, "modulate:a", 0.0, FADE)
	tween.parallel().tween_property(_splashes, "modulate:a", 0.0, FADE)
	tween.finished.connect(_finish)


func _process(delta: float) -> void:
	if not _active:
		return
	_update_emitters()
	_splash_timer -= delta
	if _splash_timer <= 0.0:
		_splash_timer = 0.25
		_update_splash_points()


func _update_emitters() -> void:
	if _player == null:
		return
	_drops.position = _player.position + Vector2(0, -180)
	_splashes.position = _player.position


## Os respingos nascem nas células de chão perto do jogador; paredes ficam fora.
func _update_splash_points() -> void:
	if _player == null or _map.is_empty():
		return
	var center := Vector2i(int(_player.position.x / TILE), int(_player.position.y / TILE))
	var points := PackedVector2Array()
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			if dx * dx + dy * dy > 30:
				continue
			var cell := center + Vector2i(dx, dy)
			if cell.y < 0 or cell.y >= _map.size():
				continue
			if cell.x < 0 or cell.x >= _map[cell.y].length():
				continue
			if _map[cell.y][cell.x] == "#":
				continue
			points.append(Vector2((cell.x + 0.5) * TILE, (cell.y + 0.5) * TILE) - _player.position)
	_splashes.emission_points = points


func _make_drops() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Drops"
	p.amount = 220
	p.lifetime = 0.85
	p.one_shot = false
	p.explosiveness = 0.0
	p.randomness = 0.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(320, 8)
	p.direction = Vector2(0, 1)
	p.spread = 2.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 260
	p.initial_velocity_max = 380
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.1
	p.color = Color(0.62, 0.78, 1.0, 0.78)
	p.texture = _drop_texture()
	p.local_coords = false
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.z_index = 95
	return p


func _make_splashes() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Splashes"
	p.amount = 90
	p.lifetime = 0.32
	p.one_shot = false
	p.explosiveness = 0.15
	p.randomness = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.gravity = Vector2(0, 240)
	p.initial_velocity_min = 20
	p.initial_velocity_max = 60
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.8
	p.color = Color(0.78, 0.90, 1.0, 0.85)
	p.texture = _splash_texture()
	p.local_coords = false
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.z_index = 94
	return p


func _drop_texture() -> Texture2D:
	var img := Image.create(2, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 12:
		var a := 0.15 + 0.65 * (float(y) / 11.0)
		img.set_pixel(0, y, Color(0.62, 0.78, 1.0, a))
		img.set_pixel(1, y, Color(0.62, 0.78, 1.0, a * 0.7))
	return ImageTexture.create_from_image(img)


func _splash_texture() -> Texture2D:
	var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(3, 3)
	for y in 7:
		for x in 7:
			var d := Vector2(x, y).distance_to(center)
			if d <= 3.0 and d >= 1.6:
				var a := clampf(1.0 - absf(d - 2.3) / 1.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.78, 0.90, 1.0, a))
	return ImageTexture.create_from_image(img)


func _finish() -> void:
	_active = false
	if is_instance_valid(_drops):
		_drops.emitting = false
	if is_instance_valid(_splashes):
		_splashes.emitting = false
	finished.emit()
	queue_free()
