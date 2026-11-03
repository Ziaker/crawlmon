class_name DungeonGenerator
extends RefCounted
## Seeded rooms-and-corridors dungeon generator (GDD R7-Q5 / R8-Q3 / R8-Q4).
## Returns an ASCII grid with the same legend the exploration scene parses:
## '#' wall, '.' floor, 'P' player spawn, 'E' enemy encounter, 'N' friendly NPC,
## 'I' consumable item pickup (D-033).
##
## The same seed, rules and generator version always produce the same layout.
## The caller (GameState) is responsible for caching the result, so revisiting
## the floor does not regenerate it (GDD R9-Q2).

const WALL := 0
const FLOOR := 1
const SPAWN := 2
const ENEMY := 3
const NPC := 4
const ITEM := 5
const CHARS := ["#", ".", "P", "E", "N", "I"]

const MIN_ROOMS := 7
const MAX_ROOMS := 11
const ROOM_MIN := Vector2i(4, 4)
const ROOM_MAX := Vector2i(9, 7)
const PLACE_ATTEMPTS := 160
const NPC_COUNT := Vector2i(2, 3)
const ENEMY_COUNT := Vector2i(4, 6)
const ITEM_COUNT := Vector2i(2, 4)
const ITEM_MIN_SPAWN_DISTANCE := 8.0  ## Tiles; keeps pickups away from the start.

var _rng := RandomNumberGenerator.new()
var _w := 0
var _h := 0
var _cells: Array = []  ## rows of Array[int] (mutable, unlike PackedByteArray)


static func generate(seed_value: int, width := 40, height := 26) -> Array[String]:
	var gen := DungeonGenerator.new()
	return gen._build(seed_value, width, height)


func _build(seed_value: int, width: int, height: int) -> Array[String]:
	_rng.seed = seed_value
	_w = maxi(width, 24)
	_h = maxi(height, 18)
	_cells = []
	for _y in _h:
		var row: Array = []
		row.resize(_w)
		row.fill(WALL)
		_cells.append(row)

	var rooms := _place_rooms()
	_connect_rooms(rooms)
	_place_markers(rooms)
	return _to_rows()


# --- Rooms -------------------------------------------------------------------

func _place_rooms() -> Array[Rect2i]:
	var rooms: Array[Rect2i] = []
	var target := _rng.randi_range(MIN_ROOMS, MAX_ROOMS)
	for _attempt in PLACE_ATTEMPTS:
		if rooms.size() >= target:
			break
		var size := Vector2i(
			_rng.randi_range(ROOM_MIN.x, ROOM_MAX.x),
			_rng.randi_range(ROOM_MIN.y, ROOM_MAX.y))
		var pos := Vector2i(
			_rng.randi_range(2, _w - size.x - 3),
			_rng.randi_range(2, _h - size.y - 3))
		var room := Rect2i(pos, size)
		var overlaps := false
		for other in rooms:
			# One tile of padding keeps corridors readable between rooms.
			if room.grow(1).intersects(other):
				overlaps = true
				break
		if overlaps:
			continue
		rooms.append(room)
		_carve_rect(room)

	if rooms.is_empty():
		var fallback := Rect2i(Vector2i(3, 3), Vector2i(mini(12, _w - 6), mini(9, _h - 6)))
		rooms.append(fallback)
		_carve_rect(fallback)
	return rooms


func _carve_rect(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			_cells[y][x] = FLOOR


# --- Corridors ---------------------------------------------------------------

## Connects consecutive rooms with L-shaped corridors. Because every room is
## linked to the previous one, the whole floor is reachable from the spawn.
func _connect_rooms(rooms: Array[Rect2i]) -> void:
	for i in range(1, rooms.size()):
		var a := rooms[i - 1].get_center()
		var b := rooms[i].get_center()
		if _rng.randf() < 0.5:
			_carve_h(a.x, b.x, a.y)
			_carve_v(a.y, b.y, b.x)
		else:
			_carve_v(a.y, b.y, a.x)
			_carve_h(a.x, b.x, b.y)


func _carve_h(x0: int, x1: int, y: int) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		_cells[y][x] = FLOOR


func _carve_v(y0: int, y1: int, x: int) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		_cells[y][x] = FLOOR


# --- Markers -----------------------------------------------------------------

func _place_markers(rooms: Array[Rect2i]) -> void:
	if rooms.is_empty():
		return
	var spawn := rooms[0].get_center()
	_cells[spawn.y][spawn.x] = SPAWN

	# One marker per room centre, excluding the spawn room.
	var candidates: Array[Vector2i] = []
	for i in range(1, rooms.size()):
		candidates.append(rooms[i].get_center())
	_shuffle(candidates)

	var npc_total := mini(_rng.randi_range(NPC_COUNT.x, NPC_COUNT.y), candidates.size())
	var enemy_total := mini(
		_rng.randi_range(ENEMY_COUNT.x, ENEMY_COUNT.y),
		maxi(candidates.size() - npc_total, 0))
	for i in npc_total:
		_cells[candidates[i].y][candidates[i].x] = NPC
	for i in range(npc_total, npc_total + enemy_total):
		_cells[candidates[i].y][candidates[i].x] = ENEMY
	_place_items(rooms, spawn)


## Poções coletáveis (D-033): 2 a 4 por andar, em tiles de chão livres de salas
## fora da sala do spawn. Roda depois dos NPCs/inimigos, então nunca ocupa o
## tile deles, e usa a RNG da seed para a posição ser reproduzível.
func _place_items(rooms: Array[Rect2i], spawn: Vector2i) -> void:
	var total := _rng.randi_range(ITEM_COUNT.x, ITEM_COUNT.y)
	var candidates: Array[Vector2i] = []
	for i in range(1, rooms.size()):
		var room := rooms[i]
		for y in range(room.position.y, room.position.y + room.size.y):
			for x in range(room.position.x, room.position.x + room.size.x):
				if _cells[y][x] != FLOOR:
					continue
				if _distance_to_spawn(Vector2i(x, y), spawn) < ITEM_MIN_SPAWN_DISTANCE:
					continue
				candidates.append(Vector2i(x, y))
	# Degenerate floor (single room): fall back to any far enough floor tile.
	if candidates.is_empty():
		for y in _h:
			for x in _w:
				if _cells[y][x] == FLOOR and _distance_to_spawn(Vector2i(x, y), spawn) >= ITEM_MIN_SPAWN_DISTANCE:
					candidates.append(Vector2i(x, y))
	_shuffle(candidates)
	for i in mini(total, candidates.size()):
		var cell := candidates[i]
		_cells[cell.y][cell.x] = ITEM


func _distance_to_spawn(cell: Vector2i, spawn: Vector2i) -> float:
	return Vector2(cell - spawn).length()


## Seeded Fisher-Yates (Array.shuffle() would use the global RNG).
func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp


func _to_rows() -> Array[String]:
	var rows: Array[String] = []
	for y in _h:
		var line := ""
		for x in _w:
			line += CHARS[_cells[y][x]]
		rows.append(line)
	return rows
