extends Node2D
## Top-down 2D dungeon map built from an ASCII grid.
## '#' wall, '.' floor, 'P' player spawn, 'E' enemy encounter.

const TILE := 48
const MAP: Array[String] = [
	"##############",
	"#P.....#.....#",
	"#..##..#..E..#",
	"#..#E.....#..#",
	"#..#..###.#..#",
	"#.....#E..#..#",
	"##############",
]

var player: CharacterBody2D
var enemies: Dictionary = {}  ## id -> cell center
var _triggered := false


func _ready() -> void:
	var spawn := Vector2(TILE * 1.5, TILE * 1.5)
	for y in MAP.size():
		for x in MAP[y].length():
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			match MAP[y][x]:
				"#":
					_add_wall(center)
				"P":
					spawn = center
				"E":
					var id := "%d,%d" % [x, y]
					if not GameState.defeated.has(id):
						enemies[id] = center
						_add_enemy_trigger(id, center)
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/dungeon/player.gd"))
	player.position = spawn if GameState.player_pos == Vector2.INF else GameState.player_pos
	add_child(player)


func _add_wall(center: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _add_enemy_trigger(id: String, center: Vector2) -> void:
	var area := Area2D.new()
	area.position = center
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body == player and not _triggered:
			_triggered = true
			GameState.start_battle(id, player.position)
	)
	add_child(area)


func _draw() -> void:
	for y in MAP.size():
		for x in MAP[y].length():
			var rect := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			draw_rect(rect, Color(0.35, 0.35, 0.42) if MAP[y][x] == "#" else Color(0.14, 0.13, 0.16))
	for center in enemies.values():
		draw_circle(center, 14.0, Color(0.85, 0.25, 0.25))
