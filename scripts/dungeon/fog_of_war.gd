extends Node2D
## Per-tile fog of war for the ASCII floor (GDD R8-Q2).
##
## Unexplored tiles are fully black, tiles the player has already visited stay
## dimmed ("memory"), and tiles inside the player's line of sight are clear.
## Visibility is recomputed only when the player steps into a new tile.
##
## The explored set is stored on a state object (GameState) passed by
## exploration.gd, so leaving to a battle and coming back does not reset what
## the player already uncovered.
##
## Drawn above the map, enemies and NPCs: it is a child of exploration.tscn's
## root with a high z_index, and light_mask = 0 so torches cannot brighten it.

const TILE := 48
const RADIUS := 7.5  ## Tiles of sight.
const EXPLORED_ALPHA := 0.78
const FOG_COLOR := Color(0, 0, 0, 1)

var _map: Array[String] = []
var _player: Node2D
var _state: Object
var _w := 0
var _h := 0
var _explored := PackedByteArray()
var _visible := PackedByteArray()
var _img: Image
var _tex: ImageTexture
var _last_cell := Vector2i(-1, -1)


func _ready() -> void:
	z_index = 100
	light_mask = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Called by exploration.gd after the player exists. `state` is GameState (or
## anything exposing `dungeon_explored`); it may be null in isolated tests.
func setup(grid: Array[String], player: Node2D, state: Object = null) -> void:
	_map = grid
	_player = player
	_state = state
	_h = grid.size()
	_w = 0 if _h == 0 else grid[0].length()
	if _w == 0 or _h == 0:
		return
	_visible.resize(_w * _h)
	_visible.fill(0)

	# Reuse the explored set cached in the state object when the floor is the same.
	var cached = _state.get("dungeon_explored") if _state != null else null
	if cached is PackedByteArray and cached.size() == _w * _h:
		_explored = cached
	else:
		_explored.resize(_w * _h)
		_explored.fill(0)

	_img = Image.create(_w, _h, false, Image.FORMAT_RGBA8)
	_img.fill(FOG_COLOR)
	_tex = ImageTexture.create_from_image(_img)
	_refresh()
	queue_redraw()


func _process(_delta: float) -> void:
	if _player == null or _map.is_empty():
		return
	var cell := _cell_of(_player.position)
	if cell != _last_cell:
		_refresh()


func _draw() -> void:
	if _tex == null:
		return
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, Vector2(_w, _h) * TILE), false)


# --- Visibility --------------------------------------------------------------

func _refresh() -> void:
	_last_cell = _cell_of(_player.position)
	_visible.fill(0)
	var r := int(ceil(RADIUS))
	var r2 := RADIUS * RADIUS
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r2:
				continue
			var cell := _last_cell + Vector2i(dx, dy)
			if not _in_bounds(cell):
				continue
			if not _has_los(_last_cell, cell):
				continue
			var i := cell.y * _w + cell.x
			_visible[i] = 1
			_explored[i] = 1
	if _state != null:
		_state.set("dungeon_explored", _explored)
	_rebuild_texture()


func _rebuild_texture() -> void:
	for y in _h:
		for x in _w:
			var i := y * _w + x
			var alpha := 0.0 if _visible[i] == 1 else (EXPLORED_ALPHA if _explored[i] == 1 else 1.0)
			_img.set_pixel(x, y, Color(FOG_COLOR, alpha))
	_tex.update(_img)


## Bresenham walk: a wall between the player and the target blocks the view, but
## the wall itself is still visible (so wall faces show up on the map).
func _has_los(a: Vector2i, b: Vector2i) -> bool:
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var x := a.x
	var y := a.y
	while x != b.x or y != b.y:
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
		if x == b.x and y == b.y:
			break
		if _is_wall(Vector2i(x, y)):
			return false
	return true


func _in_bounds(cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < _h and cell.x >= 0 and cell.x < _w


func _is_wall(cell: Vector2i) -> bool:
	if not _in_bounds(cell):
		return true
	return _map[cell.y][cell.x] == "#"


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(p.x / TILE), int(p.y / TILE))
