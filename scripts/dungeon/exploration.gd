extends Node2D
## Top-down 2D dungeon map built from an ASCII grid.
## '#' wall, '.' floor, 'P' player spawn, 'E' enemy encounter, 'N' friendly NPC,
## 'I' consumable item pickup.

const DungeonNPCClass = preload("res://scripts/dungeon/npc.gd")
const DungeonEnemyClass = preload("res://scripts/dungeon/enemy.gd")
const DungeonPickupClass = preload("res://scripts/dungeon/pickup.gd")
const FogOfWarClass = preload("res://scripts/dungeon/fog_of_war.gd")
const DialogueBoxClass = preload("res://scripts/ui/dialogue_box.gd")
const NPCData = preload("res://scripts/dungeon/npc_data.gd")

const TILE := 48

## Encounters stay dormant for a moment after returning from battle, so the
## player is not dragged straight back into the fight they just left.
const POST_BATTLE_GRACE := 1.25

var player: CharacterBody2D
var enemies: Dictionary = {}  ## id -> DungeonEnemy
var fog: Node2D
var entities: Node2D  ## Y-sorted container for the player, enemies and NPCs.
var _map: Array[String] = []
var npcs: Array[Node2D] = []
var dialogue_box: CanvasLayer
var _battle_started := false
var _grace := 0.0


func _ready() -> void:
	# Generates the floor once; revisiting it (after a battle) reuses the cache.
	GameState.ensure_dungeon()
	_map = GameState.dungeon_layout
	$Visuals.setup(_map)
	
	# Cria a caixa de diálogo do mapa
	dialogue_box = DialogueBoxClass.new()
	add_child(dialogue_box)

	# Entidades ficam num container Y-sorted próprio, para que a névoa (criada
	# depois dele) seja desenhada por cima de jogador, inimigos e NPCs.
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	
	var spawn := Vector2(TILE * 1.5, TILE * 1.5)
	var npc_spots: Array[Vector2] = []
	var enemy_cells: Dictionary = {}  ## id -> Vector2i
	var item_spots: Array[Dictionary] = []  ## {id, pos}
	
	for y in _map.size():
		for x in _map[y].length():
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			match _map[y][x]:
				"#":
					_add_wall(center)
				"P":
					spawn = center
				"E":
					var id := "%d,%d" % [x, y]
					if not GameState.defeated.has(id):
						enemy_cells[id] = Vector2i(x, y)
				"N":
					npc_spots.append(center)
				"I":
					var item_id := "%d,%d" % [x, y]
					if not GameState.dungeon_items_collected.has(item_id):
						item_spots.append({"id": item_id, "pos": center})
					
	# Cria o jogador
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/dungeon/player.gd"))
	player.position = _resolve_spawn(spawn)
	entities.add_child(player)
	
	# Cria os NPCs com sprites aleatórios e ícones respectivos
	_spawn_npcs(npc_spots)
	# Inimigos precisam do jogador e de um AStarGrid2D já montado.
	_spawn_enemies(enemy_cells)
	_spawn_items(item_spots)
	# Névoa por último: fica acima do mapa, inimigos e NPCs.
	fog = FogOfWarClass.new()
	add_child(fog)
	fog.setup(_map, player, GameState)
	
	# Coming back from a battle: give the player time to walk away.
	if GameState.player_pos != Vector2.INF:
		_grace = POST_BATTLE_GRACE


func _process(delta: float) -> void:
	if _grace > 0.0:
		_grace = maxf(_grace - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("new_dungeon"):
		return
	if dialogue_box != null and "is_open" in dialogue_box and dialogue_box.is_open:
		return
	get_viewport().set_input_as_handled()
	GameState.new_dungeon()
	get_tree().reload_current_scene.call_deferred()


## Uses the position saved when the battle started, unless it is now inside a
## wall (e.g. the map changed), in which case the map's spawn point is used.
func _resolve_spawn(fallback: Vector2) -> Vector2:
	var wanted: Vector2 = GameState.player_pos if GameState.player_pos != Vector2.INF else fallback
	return fallback if _is_wall_at(wanted) else wanted


func _is_wall_at(p: Vector2) -> bool:
	var tx := int(p.x / TILE)
	var ty := int(p.y / TILE)
	if ty < 0 or ty >= _map.size() or tx < 0 or tx >= _map[ty].length():
		return true
	return _map[ty][tx] == "#"


func _spawn_npcs(spots: Array[Vector2]) -> void:
	var pool: Array[Dictionary] = NPCData.CANDIDATES.duplicate()
	pool.shuffle()
	var dialogue_pool: Array[String] = NPCData.DIALOGUES.duplicate()
	dialogue_pool.shuffle()
	
	for i in spots.size():
		var pos: Vector2 = spots[i]
		var candidate_data: Dictionary = pool[i % pool.size()]
		var chosen_dialogue: String = dialogue_pool[i % dialogue_pool.size()]
		
		var npc := DungeonNPCClass.new()
		npc.position = pos
		npc.setup(candidate_data, chosen_dialogue, dialogue_box, player)
		entities.add_child(npc)
		npcs.append(npc)


func _add_wall(center: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _spawn_enemies(cells: Dictionary) -> void:
	if cells.is_empty():
		return
	var astar := _build_astar()
	for id in cells:
		var enemy := DungeonEnemyClass.new()
		enemy.setup(id, cells[id], _map, astar, player)
		enemy.can_act = func() -> bool:
			return dialogue_box == null or not ("is_open" in dialogue_box and dialogue_box.is_open)
		enemy.touched.connect(_on_enemy_touched)
		entities.add_child(enemy)
		enemies[id] = enemy


func _spawn_items(spots: Array[Dictionary]) -> void:
	for spot in spots:
		var item_id: String = spot["id"]
		var pos: Vector2 = spot["pos"]
		var pickup = DungeonPickupClass.new()
		pickup.position = pos
		pickup.setup(item_id, player)
		pickup.collected.connect(_on_item_collected)
		entities.add_child(pickup)


## Coleta automática (D-033): soma a Poção ao inventário e registra no GameState
## para ela não reaparecer ao voltar de uma batalha.
func _on_item_collected(pickup) -> void:
	if not GameState.add_item(DungeonPickupClass.ITEM_ID):
		return
	GameState.dungeon_items_collected.append(pickup.id)


## Cardinal pathfinding grid: walls and NPCs are solid, everything else is
## walkable. Shared by every enemy on the floor.
func _build_astar() -> AStarGrid2D:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, _map[0].length(), _map.size())
	astar.cell_size = Vector2(TILE, TILE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in _map.size():
		for x in _map[y].length():
			if _map[y][x] == "#" or _map[y][x] == "N":
				astar.set_point_solid(Vector2i(x, y), true)
	return astar


func _on_enemy_touched(enemy: DungeonEnemy) -> void:
	if _battle_started or _grace > 0.0:
		return
	if dialogue_box != null and "is_open" in dialogue_box and dialogue_box.is_open:
		return
	_battle_started = true
	GameState.start_battle(enemy.id, player.position)


func _draw() -> void:
	for y in _map.size():
		for x in _map[y].length():
			var rect := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			draw_rect(rect, Color(0.35, 0.35, 0.42) if _map[y][x] == "#" else Color(0.14, 0.13, 0.16))
