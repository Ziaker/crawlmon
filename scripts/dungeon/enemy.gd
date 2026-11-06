class_name DungeonEnemy
extends Node2D
## Visible dungeon enemy (GDD R8-Q5 / R9-Q3): patrols around its home tile and
## chases the player after detecting them, using AStarGrid2D for cardinal
## pathfinding. Contact starts the 3D battle; exploration.gd decides whether
## the touch is accepted (grace period, dialogue, already in a battle).
##
## The visual is still the procedural marker from the prototype, now owned by
## the enemy node so it can move, y-sort and carry its own light.

signal touched(enemy: DungeonEnemy)

const TILE := 48
const SPEED_PATROL := 42.0
const SPEED_CHASE := 105.0
const DETECT_RADIUS := 6.5 * TILE  ## Needs line of sight.
const HEAR_RADIUS := 3.0 * TILE  ## Proximity only; lets chases round corners.
const LOSE_RADIUS := 9.0 * TILE
const CONTACT_RADIUS := 26.0
const REPATH_INTERVAL := 0.35
const PATROL_RADIUS := 4
const GIVE_UP_SECONDS := 4.0

var id := ""
var home := Vector2.ZERO
## Optional predicate from exploration.gd; when it returns false the enemy
## freezes (used while a dialogue is open).
var can_act: Callable = Callable()
## Aliados que também iniciam batalha por contato (R37-Q1).
var followers: Array[Node2D] = []

var _grid: Array[String] = []
var _astar: AStarGrid2D
var _player: Node2D
var _home_cell := Vector2i.ZERO
var _path := PackedVector2Array()
var _path_i := 0
var _wait := 0.0
var _alert := false
var _lost := 0.0
var _repath := 0.0
var _chase_cell := Vector2i(-1, -1)
var _time := 0.0
var _phase := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_id: String, cell: Vector2i, grid: Array[String], astar: AStarGrid2D, player: Node2D) -> void:
	id = p_id
	_grid = grid
	_astar = astar
	_player = player
	_home_cell = cell
	home = _cell_center(cell)
	position = home
	_rng.seed = hash(id)
	_phase = _rng.randf() * TAU
	_wait = _rng.randf_range(0.2, 1.4)


func _ready() -> void:
	var light := PointLight2D.new()
	light.texture = _make_glow()
	light.texture_scale = 0.6
	light.color = Color(1.0, 0.25, 0.3)
	light.energy = 0.6
	add_child(light)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _player == null:
		return
	if can_act.is_valid() and not can_act.call():
		return
	_update_alert(delta)
	if _alert:
		_chase(delta)
	else:
		_patrol(delta)
	_check_contact()


# --- Behaviour ---------------------------------------------------------------

func _update_alert(delta: float) -> void:
	var pcell := _cell_of(_player.position)
	var dist := position.distance_to(_player.position)
	# Sight reaches far but is blocked by walls; hearing is short and ignores
	# walls, so a nearby enemy still rounds the corner after the player.
	var sees := dist <= DETECT_RADIUS and _has_los(_cell(), pcell)
	var hears := dist <= HEAR_RADIUS
	if sees or hears:
		_alert = true
		_lost = 0.0
	elif _alert:
		_lost += delta
		if dist > LOSE_RADIUS or _lost > GIVE_UP_SECONDS:
			_alert = false
			_lost = 0.0
			_path = PackedVector2Array()
			_wait = 0.4


func _chase(delta: float) -> void:
	_repath -= delta
	var pcell := _cell_of(_player.position)
	if pcell != _chase_cell or (_path.is_empty() and _repath <= 0.0):
		_chase_cell = pcell
		_repath = REPATH_INTERVAL
		_path_to(pcell)
	_move_along(delta, SPEED_CHASE)


func _patrol(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	if _path_i >= _path.size():
		_path_to(_pick_patrol_target())
		if _path.is_empty():
			_wait = 1.0
			return
	_move_along(delta, SPEED_PATROL)
	if _path_i >= _path.size():
		_wait = _rng.randf_range(0.6, 2.0)


func _pick_patrol_target() -> Vector2i:
	for _i in 16:
		var cell := _home_cell + Vector2i(
			_rng.randi_range(-PATROL_RADIUS, PATROL_RADIUS),
			_rng.randi_range(-PATROL_RADIUS, PATROL_RADIUS))
		if cell != _cell() and _walkable(cell):
			return cell
	return _home_cell


func _check_contact() -> void:
	if position.distance_to(_player.position) <= CONTACT_RADIUS:
		touched.emit(self)
		return
	for follower in followers:
		if is_instance_valid(follower) and position.distance_to(follower.position) <= CONTACT_RADIUS:
			touched.emit(self)
			return


# --- Movement ----------------------------------------------------------------

func _move_along(delta: float, speed: float) -> void:
	if _path_i >= _path.size():
		return
	var target: Vector2 = _path[_path_i]
	var to := target - position
	var step := speed * delta
	if to.length() <= step:
		position = target
		_path_i += 1
	else:
		position += to.normalized() * step


func _path_to(cell: Vector2i) -> void:
	_path = PackedVector2Array()
	_path_i = 0
	if _astar == null or not _walkable(cell):
		return
	var from := _cell()
	if from == cell:
		return
	var ids: Array = _astar.get_id_path(from, cell)
	# Skip the first cell: the enemy is already standing in it.
	for i in range(1, ids.size()):
		_path.append(_cell_center(ids[i]))


# --- Grid helpers ------------------------------------------------------------

func _walkable(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= _grid.size() or cell.x < 0 or cell.x >= _grid[cell.y].length():
		return false
	if _grid[cell.y][cell.x] == "#":
		return false
	return _astar == null or not _astar.is_point_solid(cell)


func _has_los(a: Vector2i, b: Vector2i) -> bool:
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var x := a.x
	var y := a.y
	while true:
		var blocked := (x != a.x or y != a.y) and (x != b.x or y != b.y)
		if blocked and not _walkable(Vector2i(x, y)):
			return false
		if x == b.x and y == b.y:
			return true
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return true


func _cell() -> Vector2i:
	return _cell_of(position)


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(p.x / TILE), int(p.y / TILE))


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2(TILE, TILE) * 0.5


# --- Drawing -----------------------------------------------------------------

func _draw() -> void:
	var bob := sin(_time * 3.0 + _phase) * 2.0
	_blob(Vector2(0, 14), 14.0, 5.0)
	var pulse := 0.25 + 0.15 * sin(_time * 4.0 + _phase)
	draw_arc(Vector2.ZERO, 20.0 + 2.0 * sin(_time * 4.0 + _phase), 0.0, TAU, 24, Color(1.0, 0.2, 0.3, pulse), 2.0)
	var body := Vector2(0, bob)
	_ellipse(body + Vector2(0, 2), 14.0, 11.0, Color(0.8, 0.22, 0.3))
	_ellipse(body + Vector2(-4, -3), 5.0, 3.0, Color(1.0, 0.6, 0.6, 0.6))
	draw_circle(body + Vector2(-5, 0), 3.0, Color.WHITE)
	draw_circle(body + Vector2(5, 0), 3.0, Color.WHITE)
	draw_circle(body + Vector2(-5, 1), 1.4, Color.BLACK)
	draw_circle(body + Vector2(5, 1), 1.4, Color.BLACK)
	draw_line(body + Vector2(-9, -5), body + Vector2(-2, -3), Color(0.3, 0.05, 0.1), 2.0)
	draw_line(body + Vector2(9, -5), body + Vector2(2, -3), Color(0.3, 0.05, 0.1), 2.0)
	if _alert:
		draw_string(ThemeDB.fallback_font, body + Vector2(-5, -22), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 26, Color(1.0, 0.9, 0.2))


func _blob(pos: Vector2, rx: float, ry: float) -> void:
	_ellipse(pos, rx, ry, Color(0, 0, 0, 0.4))


func _ellipse(pos: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(rx, ry))
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
