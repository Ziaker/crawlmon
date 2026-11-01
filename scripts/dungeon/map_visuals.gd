extends Node2D
## Procedural dungeon look for the ASCII map in exploration.gd: stone floor and
## brick walls (with a front face), decor, wall torches with flickering
## shadow-casting lights, a light carried by the player, blob shadows and
## animated enemy markers. Added as a child in exploration.tscn; it reads MAP,
## enemies, player and npcs from its parent.

const TILE := 48
const AMBIENT := Color(0.24, 0.24, 0.36)
const TORCH_COLOR := Color(1.0, 0.68, 0.32)
const FLOOR_BASE := Color(0.30, 0.28, 0.33)
const CAP_BASE := Color(0.42, 0.42, 0.52)
const FACE_BASE := Color(0.36, 0.34, 0.44)

var _parent: Node2D
var _map: Array = []
var _floors: Array[ImageTexture] = []
var _cap: ImageTexture
var _face: ImageTexture
var _glow: GradientTexture2D
var _torches: Array[Dictionary] = []  ## {light, pos, phase}
var _enemy_lights: Dictionary = {}  ## enemy id -> PointLight2D
var _player_light: PointLight2D
var _time := 0.0


func _ready() -> void:
	_parent = get_parent()
	_map = _parent.get_script().get_script_constant_map()["MAP"]
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in 3:
		_floors.append(_make_tile(FLOOR_BASE.lightened(i * 0.03), "floor", i + 1))
	_cap = _make_tile(CAP_BASE, "cap", 10)
	_face = _make_tile(FACE_BASE, "face", 11)
	_glow = _make_glow()
	var mod := CanvasModulate.new()
	mod.color = AMBIENT
	add_child(mod)
	_build_walls_lights()


func _process(delta: float) -> void:
	_time += delta
	for t in _torches:
		var light: PointLight2D = t["light"]
		var phase: float = t["phase"]
		light.energy = 1.15 + 0.12 * sin(_time * 9.0 + phase) + 0.08 * sin(_time * 23.0 + phase * 2.0)
	_attach_dynamic_lights()
	queue_redraw()


# --- Setup -------------------------------------------------------------------

func _build_walls_lights() -> void:
	for y in _map.size():
		for x in _map[y].length():
			if not _is_wall(x, y):
				continue
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			var occ := LightOccluder2D.new()
			var poly := OccluderPolygon2D.new()
			var h := TILE * 0.5 - 2.0
			poly.polygon = PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
			occ.occluder = poly
			occ.position = center
			add_child(occ)
			if not _is_wall(x, y + 1) and (x * 5 + y * 3) % 4 == 0:
				_add_torch(center)


func _add_torch(wall_center: Vector2) -> void:
	var light := PointLight2D.new()
	light.texture = _glow
	light.texture_scale = 1.7
	light.color = TORCH_COLOR
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.position = wall_center + Vector2(0, TILE * 0.5 + 8.0)
	add_child(light)
	_torches.append({"light": light, "pos": wall_center + Vector2(0, TILE * 0.5 - 14.0), "phase": randf() * TAU})


## The player and the enemies appear after this node's _ready, so their lights
## are attached lazily.
func _attach_dynamic_lights() -> void:
	var player: Node2D = _parent.get("player")
	if _player_light == null and player != null:
		_player_light = PointLight2D.new()
		_player_light.texture = _glow
		_player_light.texture_scale = 1.3
		_player_light.color = Color(0.9, 0.95, 1.0)
		_player_light.energy = 0.9
		player.add_child(_player_light)
		for child in player.get_children():  # Keep the camera inside the map.
			if child is Camera2D:
				child.limit_left = 0
				child.limit_top = 0
				child.limit_right = _map[0].length() * TILE
				child.limit_bottom = _map.size() * TILE
	var enemies: Dictionary = _parent.get("enemies")
	if enemies == null:
		return
	for id in enemies:
		if not _enemy_lights.has(id):
			var light := PointLight2D.new()
			light.texture = _glow
			light.texture_scale = 0.6
			light.color = Color(1.0, 0.25, 0.3)
			light.energy = 0.6
			light.position = enemies[id]
			add_child(light)
			_enemy_lights[id] = light
	for id in _enemy_lights.keys():
		if not enemies.has(id):
			_enemy_lights[id].queue_free()
			_enemy_lights.erase(id)


func _make_glow() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color.BLACK)
	g.add_point(0.45, Color(0.4, 0.4, 0.4))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex


func _make_tile(base: Color, kind: String, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	for y in TILE:
		for x in TILE:
			var n := rng.randf_range(-0.04, 0.04)
			var c := Color(base.r + n, base.g + n, base.b + n)
			match kind:
				"floor":
					if x % 24 == 0 or y % 24 == 0:
						c = c.darkened(0.35)
					elif x % 24 == 1 or y % 24 == 1:
						c = c.lightened(0.08)
				"cap":
					if x < 2 or y < 2 or x >= TILE - 2 or y >= TILE - 2:
						c = c.darkened(0.3)
				"face":
					var offset := ((y / 12) % 2) * 12
					if y % 12 == 0 or (x + offset) % 24 == 0:
						c = c.darkened(0.4)
					if y > TILE - 10:
						c = c.darkened(float(y - (TILE - 10)) / 10.0 * 0.5)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# --- Drawing -----------------------------------------------------------------

func _is_wall(x: int, y: int) -> bool:
	if y < 0 or y >= _map.size() or x < 0 or x >= _map[y].length():
		return true
	return _map[y][x] == "#"


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663))


func _draw() -> void:
	for y in _map.size():
		for x in _map[y].length():
			var rect := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			if _is_wall(x, y):
				draw_texture_rect(_face if not _is_wall(x, y + 1) else _cap, rect, false)
			else:
				draw_texture_rect(_floors[_hash(x, y) % _floors.size()], rect, false)
				if _is_wall(x, y - 1):
					draw_rect(Rect2(rect.position, Vector2(TILE, 12)), Color(0, 0, 0, 0.35))
				if _is_wall(x - 1, y):
					draw_rect(Rect2(rect.position, Vector2(6, TILE)), Color(0, 0, 0, 0.25))
				if _map[y][x] == "." and _hash(x, y) % 9 == 0:
					_draw_decor(rect.get_center(), _hash(x, y) / 9)
	for t in _torches:
		_draw_torch(t["pos"], t["phase"])
	var player: Node2D = _parent.get("player")
	if player != null:
		_blob(player.position + Vector2(0, 14), 13.0, 5.0)
	var npcs: Array = _parent.get("npcs") if _parent.get("npcs") != null else []
	for npc in npcs:
		_blob(npc.position + Vector2(0, 14), 13.0, 5.0)
	var enemies: Dictionary = _parent.get("enemies")
	if enemies != null:
		for id in enemies:
			_draw_enemy(enemies[id], id.hash(), player)


func _draw_decor(c: Vector2, variant: int) -> void:
	var off := Vector2((variant % 7) - 3, ((variant / 7) % 7) - 3) * 4.0
	var p := c + off
	match variant % 4:
		0:  # crack
			draw_polyline(PackedVector2Array([p + Vector2(-10, -4), p + Vector2(-3, 1), p + Vector2(2, -3), p + Vector2(9, 3)]), Color(0.1, 0.09, 0.12), 1.5)
		1:  # bones
			draw_line(p + Vector2(-7, -3), p + Vector2(7, 3), Color(0.85, 0.82, 0.72), 2.0)
			draw_line(p + Vector2(-7, 3), p + Vector2(7, -3), Color(0.85, 0.82, 0.72), 2.0)
			draw_circle(p + Vector2(0, -6), 3.5, Color(0.88, 0.85, 0.75))
		2:  # rubble
			draw_circle(p + Vector2(-5, 2), 3.0, Color(0.45, 0.44, 0.5))
			draw_circle(p + Vector2(3, -2), 4.0, Color(0.38, 0.37, 0.43))
			draw_circle(p + Vector2(6, 5), 2.0, Color(0.5, 0.49, 0.55))
		3:  # puddle
			_ellipse(p, 12.0, 6.0, Color(0.25, 0.4, 0.6, 0.55))
			_ellipse(p + Vector2(-3, -1), 4.0, 1.5, Color(0.7, 0.85, 1.0, 0.5))


func _draw_torch(p: Vector2, phase: float) -> void:
	draw_rect(Rect2(p + Vector2(-2, 6), Vector2(4, 10)), Color(0.3, 0.2, 0.12))
	var h := 14.0 + 3.0 * sin(_time * 12.0 + phase)
	var sway := 1.5 * sin(_time * 7.0 + phase)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 6), p + Vector2(5, 6), p + Vector2(sway, 6 - h)]), Color(1.0, 0.45, 0.1))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 6), p + Vector2(3, 6), p + Vector2(sway, 6 - h * 0.6)]), Color(1.0, 0.9, 0.4))


func _draw_enemy(c: Vector2, seed_hash: int, player: Node2D) -> void:
	var phase := float(seed_hash % 100)
	var bob := sin(_time * 3.0 + phase) * 2.0
	_blob(c + Vector2(0, 14), 14.0, 5.0)
	var pulse := 0.25 + 0.15 * sin(_time * 4.0 + phase)
	draw_arc(c, 20.0 + 2.0 * sin(_time * 4.0 + phase), 0.0, TAU, 24, Color(1.0, 0.2, 0.3, pulse), 2.0)
	var body := c + Vector2(0, bob)
	_ellipse(body + Vector2(0, 2), 14.0, 11.0, Color(0.8, 0.22, 0.3))
	_ellipse(body + Vector2(-4, -3), 5.0, 3.0, Color(1.0, 0.6, 0.6, 0.6))
	draw_circle(body + Vector2(-5, 0), 3.0, Color.WHITE)
	draw_circle(body + Vector2(5, 0), 3.0, Color.WHITE)
	draw_circle(body + Vector2(-5, 1), 1.4, Color.BLACK)
	draw_circle(body + Vector2(5, 1), 1.4, Color.BLACK)
	draw_line(body + Vector2(-9, -5), body + Vector2(-2, -3), Color(0.3, 0.05, 0.1), 2.0)
	draw_line(body + Vector2(9, -5), body + Vector2(2, -3), Color(0.3, 0.05, 0.1), 2.0)
	if player != null and player.position.distance_to(c) < 90.0:
		draw_string(ThemeDB.fallback_font, body + Vector2(-5, -22), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 26, Color(1.0, 0.9, 0.2))


func _blob(pos: Vector2, rx: float, ry: float) -> void:
	_ellipse(pos, rx, ry, Color(0, 0, 0, 0.4))


func _ellipse(pos: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(rx, ry))
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
