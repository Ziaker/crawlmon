extends Node2D
## Procedural dungeon look for the ASCII map in exploration.gd.
##
## Static geometry (floor, walls, decor) lives in two TileMapLayers backed by a
## TileSet built at runtime from generated atlas images, so nothing is redrawn
## per frame. Wall tiles also carry the light occlusion polygon, which replaces
## the old per-wall LightOccluder2D nodes.
##
## What is still drawn every frame is only the animated part: torches and the
## blob shadows under the player and NPCs.

const TILE := 48
const MAX_TORCHES := 12  ## Cap on shadow-casting lights for big procedural floors.
const AMBIENT := Color(0.24, 0.24, 0.36)
const TORCH_COLOR := Color(1.0, 0.68, 0.32)
const FLOOR_BASE := Color(0.30, 0.28, 0.33)
const CAP_BASE := Color(0.42, 0.42, 0.52)
const FACE_BASE := Color(0.36, 0.34, 0.44)

## Atlas layout. Row 0 holds floor tiles (3 variants x 2x2 edge shadows) and the
## two wall tiles; row 1 holds the decor stamps.
const FLOOR_VARIANTS := 3
const WALL_CAP := Vector2i(12, 0)
const WALL_FACE := Vector2i(13, 0)
const DECOR_VARIANTS := 4
const ATLAS_COLS := 14
const ATLAS_ROWS := 2

var _parent: Node2D
var _map: Array = []
var _glow: GradientTexture2D
var _torches: Array[Dictionary] = []  ## {light, pos, phase}
var _player_light: PointLight2D
var _camera_fitted := false
var _time := 0.0
var _floor_layer: TileMapLayer
var _decor_layer: TileMapLayer
var _source_id := -1


func _ready() -> void:
	_parent = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow = _make_glow()
	var mod := CanvasModulate.new()
	mod.color = AMBIENT
	add_child(mod)


## Called by exploration.gd once the floor has been generated (this node's
## _ready runs before the parent's, so the grid is not available there).
func setup(grid: Array[String]) -> void:
	_map = grid
	_build_tiles()
	_build_torches()
	queue_redraw()


func _process(delta: float) -> void:
	if _map.is_empty():
		return
	_time += delta
	for t in _torches:
		var light: PointLight2D = t["light"]
		var phase: float = t["phase"]
		light.energy = 1.15 + 0.12 * sin(_time * 9.0 + phase) + 0.08 * sin(_time * 23.0 + phase * 2.0)
	_attach_dynamic_lights()
	queue_redraw()


# --- Tiles -------------------------------------------------------------------

## Builds the atlas, the TileSet and both layers, then fills every cell.
func _build_tiles() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_occlusion_layer()

	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(_make_atlas())
	src.texture_region_size = Vector2i(TILE, TILE)
	for row in ATLAS_ROWS:
		for col in ATLAS_COLS:
			src.create_tile(Vector2i(col, row))
	_source_id = tileset.add_source(src)

	# Wall tiles block light. The polygon is centred on the tile.
	var h := TILE * 0.5 - 2.0
	var wall_poly := OccluderPolygon2D.new()
	wall_poly.polygon = PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	for coord in [WALL_CAP, WALL_FACE]:
		var data := src.get_tile_data(coord, 0)
		data.set_occluder_polygons_count(0, 1)
		data.set_occluder_polygon(0, 0, wall_poly)

	_floor_layer = _make_layer("Floor", tileset)
	_decor_layer = _make_layer("Decor", tileset)
	_fill_cells()


## Layers draw behind this node's own _draw, so torches and shadows stay on top.
func _make_layer(layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	layer.show_behind_parent = true
	add_child(layer)
	return layer


func _fill_cells() -> void:
	for y in _map.size():
		for x in _map[y].length():
			var cell := Vector2i(x, y)
			if _is_wall(x, y):
				var wall := WALL_FACE if not _is_wall(x, y + 1) else WALL_CAP
				_floor_layer.set_cell(cell, _source_id, wall)
				continue
			_floor_layer.set_cell(cell, _source_id, _floor_coord(x, y))
			if _map[y][x] == "." and _hash(x, y) % 9 == 0:
				var variant := (_hash(x, y) / 9) % DECOR_VARIANTS
				_decor_layer.set_cell(cell, _source_id, Vector2i(variant, 1))


## Floor atlas index: 3 texture variants crossed with the two baked edge
## shadows, so floor next to a wall keeps the old depth cue.
func _floor_coord(x: int, y: int) -> Vector2i:
	var variant := _hash(x, y) % FLOOR_VARIANTS
	var top := 1 if _is_wall(x, y - 1) else 0
	var left := 2 if _is_wall(x - 1, y) else 0
	return Vector2i(variant * 4 + top + left, 0)


func _make_atlas() -> Image:
	var atlas := Image.create(TILE * ATLAS_COLS, TILE * ATLAS_ROWS, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	for variant in FLOOR_VARIANTS:
		for edges in 4:
			var top := (edges & 1) != 0
			var left := (edges & 2) != 0
			var base := FLOOR_BASE.lightened(variant * 0.03)
			var img := _make_tile_image(base, "floor", variant + 1, top, left)
			atlas.blit_rect(img, Rect2i(0, 0, TILE, TILE), Vector2i(variant * 4 + edges, 0))
	atlas.blit_rect(_make_tile_image(CAP_BASE, "cap", 10), Rect2i(0, 0, TILE, TILE), WALL_CAP * TILE)
	atlas.blit_rect(_make_tile_image(FACE_BASE, "face", 11), Rect2i(0, 0, TILE, TILE), WALL_FACE * TILE)
	for variant in DECOR_VARIANTS:
		var decor := _make_decor_image(variant)
		atlas.blend_rect(decor, Rect2i(0, 0, TILE, TILE), Vector2i(variant, 1) * TILE)
	return atlas


func _make_tile_image(base: Color, kind: String, seed_value: int, top_shadow := false, left_shadow := false) -> Image:
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
					# Edge shadows are baked here instead of being drawn on top.
					if top_shadow and y < 12:
						c = c.lerp(Color.BLACK, 0.35)
					if left_shadow and x < 6:
						c = c.lerp(Color.BLACK, 0.25)
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
	return img


# --- Decor stamps ------------------------------------------------------------

## Bakes the old draw_* decor shapes into a transparent tile.
func _make_decor_image(variant: int) -> Image:
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var jitter := Vector2((variant % 3) - 1, ((variant / 3) % 3) - 1) * 3.0
	var p := Vector2(TILE, TILE) * 0.5 + jitter
	match variant % 4:
		0:  # crack
			_img_polyline(img, PackedVector2Array([
				p + Vector2(-10, -4), p + Vector2(-3, 1), p + Vector2(2, -3), p + Vector2(9, 3)]),
				Color(0.1, 0.09, 0.12), 1.5)
		1:  # bones
			_img_line(img, p + Vector2(-7, -3), p + Vector2(7, 3), Color(0.85, 0.82, 0.72), 2.0)
			_img_line(img, p + Vector2(-7, 3), p + Vector2(7, -3), Color(0.85, 0.82, 0.72), 2.0)
			_img_circle(img, p + Vector2(0, -6), 3.5, Color(0.88, 0.85, 0.75))
		2:  # rubble
			_img_circle(img, p + Vector2(-5, 2), 3.0, Color(0.45, 0.44, 0.5))
			_img_circle(img, p + Vector2(3, -2), 4.0, Color(0.38, 0.37, 0.43))
			_img_circle(img, p + Vector2(6, 5), 2.0, Color(0.5, 0.49, 0.55))
		3:  # puddle
			_img_ellipse(img, p, 12.0, 6.0, Color(0.25, 0.4, 0.6, 0.55))
			_img_ellipse(img, p + Vector2(-3, -1), 4.0, 1.5, Color(0.7, 0.85, 1.0, 0.5))
	return img


func _img_polyline(img: Image, points: PackedVector2Array, color: Color, thickness: float) -> void:
	for i in range(1, points.size()):
		_img_line(img, points[i - 1], points[i], color, thickness)


func _img_line(img: Image, a: Vector2, b: Vector2, color: Color, thickness: float) -> void:
	var steps := maxi(1, int(ceil(a.distance_to(b))))
	for i in steps + 1:
		_img_dot(img, a.lerp(b, float(i) / steps), color, thickness)


func _img_dot(img: Image, p: Vector2, color: Color, thickness: float) -> void:
	var half := int(ceil(thickness * 0.5))
	var cx := int(round(p.x))
	var cy := int(round(p.y))
	for dy in range(-half, half + 1):
		for dx in range(-half, half + 1):
			_img_blend(img, cx + dx, cy + dy, color)


func _img_circle(img: Image, c: Vector2, r: float, color: Color) -> void:
	_img_ellipse(img, c, r, r, color)


func _img_ellipse(img: Image, c: Vector2, rx: float, ry: float, color: Color) -> void:
	for y in range(int(c.y - ry), int(c.y + ry) + 1):
		for x in range(int(c.x - rx), int(c.x + rx) + 1):
			var dx := (x - c.x) / rx
			var dy := (y - c.y) / ry
			if dx * dx + dy * dy <= 1.0:
				_img_blend(img, x, y, color)


func _img_blend(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var base := img.get_pixel(x, y)
	var a := color.a
	img.set_pixel(x, y, Color(
		base.r * (1.0 - a) + color.r * a,
		base.g * (1.0 - a) + color.g * a,
		base.b * (1.0 - a) + color.b * a,
		maxf(base.a, a)))


# --- Lights ------------------------------------------------------------------

func _build_torches() -> void:
	var torch_spots: Array[Vector2] = []
	for y in _map.size():
		for x in _map[y].length():
			if _is_wall(x, y) and not _is_wall(x, y + 1):
				torch_spots.append(Vector2(x + 0.5, y + 0.5) * TILE)
	# A procedural floor has far more wall fronts than the old hand-made map;
	# keep a spread-out subset so the lights stay cheap and readable.
	var step := maxi(1, int(ceil(float(torch_spots.size()) / MAX_TORCHES)))
	for i in range(0, torch_spots.size(), step):
		_add_torch(torch_spots[i])


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


## The player appears after this node's _ready, so its light is attached lazily.
## Enemies own their own lights (scripts/dungeon/enemy.gd).
func _attach_dynamic_lights() -> void:
	var player: Node2D = _parent.get("player")
	if player == null:
		return
	if _player_light == null:
		_player_light = PointLight2D.new()
		_player_light.texture = _glow
		_player_light.texture_scale = 1.3
		_player_light.color = Color(0.9, 0.95, 1.0)
		_player_light.energy = 0.9
		player.add_child(_player_light)
	if not _camera_fitted:
		_fit_camera(player)
		_camera_fitted = true


## Keeps the camera inside the map, but only on axes where the map is actually
## bigger than the screen. Limits smaller than the viewport make Godot clamp the
## camera to an invalid rectangle, which is what froze the vertical scroll.
## On the axes that fit, both limits collapse to the map centre.
func _fit_camera(player: Node2D) -> void:
	var cam: Camera2D = null
	for child in player.get_children():
		if child is Camera2D:
			cam = child
			break
	if cam == null:
		return
	var map_size := Vector2(_map[0].length(), _map.size()) * TILE
	var view := get_viewport_rect().size / cam.zoom
	if map_size.x > view.x:
		cam.limit_left = 0
		cam.limit_right = int(map_size.x)
	else:
		cam.limit_left = int(map_size.x * 0.5)
		cam.limit_right = int(map_size.x * 0.5)
	if map_size.y > view.y:
		cam.limit_top = 0
		cam.limit_bottom = int(map_size.y)
	else:
		cam.limit_top = int(map_size.y * 0.5)
		cam.limit_bottom = int(map_size.y * 0.5)
	cam.reset_smoothing()


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


# --- Drawing -----------------------------------------------------------------

func _is_wall(x: int, y: int) -> bool:
	if y < 0 or y >= _map.size() or x < 0 or x >= _map[y].length():
		return true
	return _map[y][x] == "#"


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663))


func _draw() -> void:
	for t in _torches:
		_draw_torch(t["pos"], t["phase"])
	var player: Node2D = _parent.get("player")
	if player != null:
		_blob(player.position + Vector2(0, 14), 13.0, 5.0)
	var npcs: Array = _parent.get("npcs") if _parent.get("npcs") != null else []
	for npc in npcs:
		_blob(npc.position + Vector2(0, 14), 13.0, 5.0)


func _draw_torch(p: Vector2, phase: float) -> void:
	draw_rect(Rect2(p + Vector2(-2, 6), Vector2(4, 10)), Color(0.3, 0.2, 0.12))
	var h := 14.0 + 3.0 * sin(_time * 12.0 + phase)
	var sway := 1.5 * sin(_time * 7.0 + phase)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 6), p + Vector2(5, 6), p + Vector2(sway, 6 - h)]), Color(1.0, 0.45, 0.1))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 6), p + Vector2(3, 6), p + Vector2(sway, 6 - h * 0.6)]), Color(1.0, 0.9, 0.4))


func _blob(pos: Vector2, rx: float, ry: float) -> void:
	_ellipse(pos, rx, ry, Color(0, 0, 0, 0.4))


func _ellipse(pos: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(rx, ry))
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
