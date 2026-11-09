extends Node2D
## Top-down 2D dungeon map built from an ASCII grid.
## '#' wall, '.' floor, 'P' player spawn, 'E' enemy encounter, 'N' friendly NPC,
## 'I' consumable item pickup.

const DungeonNPCClass = preload("res://scripts/dungeon/npc.gd")
const DungeonEnemyClass = preload("res://scripts/dungeon/enemy.gd")
const DungeonFollowerClass = preload("res://scripts/dungeon/follower.gd")
const DungeonFollower3DClass = preload("res://scripts/dungeon/dungeon_follower_3d.gd")
const Model3DViewClass = preload("res://scripts/dungeon/model_3d_view.gd")
const DungeonPickupClass = preload("res://scripts/dungeon/pickup.gd")
const FogOfWarClass = preload("res://scripts/dungeon/fog_of_war.gd")
const DialogueBoxClass = preload("res://scripts/ui/dialogue_box.gd")
const NPCData = preload("res://scripts/dungeon/npc_data.gd")
const BiomeSelectorScript = preload("res://scripts/dungeon/biome_selector.gd")
const WeatherControllerClass = preload("res://scripts/dungeon/weather_controller.gd")

const TILE := 48

## Encounters stay dormant for a moment after returning from battle, so the
## player is not dragged straight back into the fight they just left.
const POST_BATTLE_GRACE := 1.25

var player: CharacterBody2D
var followers: Array[Node2D] = []  ## Aliados ativos atrás do protagonista.
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
	var biome := BiomeSelectorScript.pick(GameState.visual_floor, GameState.biome_seed)
	GameState.visual_biome = str(biome.get("name", BiomeSelectorScript.FALLBACK_NAME))
	$Visuals.setup(_map, str(biome.get("profile", BiomeSelectorScript.FALLBACK_PROFILE)), GameState.dungeon_seed)
	
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
	if not GameState.party.is_empty():
		player.set("species_id", GameState.party[0].species_id)
	entities.add_child(player)
	_spawn_followers()
	_spawn_3d_follower()
	# D-1016: Abra, Pancham e o Orc usam os GLBs com o estilo pixel; sem o
	# asset local, cada um continua com o sprite 2D.
	_attach_model_views()
	
	# Cria os NPCs com sprites aleatórios e ícones respectivos
	_spawn_npcs(npc_spots)
	# Inimigos precisam do jogador e de um AStarGrid2D já montado.
	_spawn_enemies(enemy_cells)
	_spawn_items(item_spots)
	# Névoa por último: fica acima do mapa, inimigos e NPCs.
	fog = FogOfWarClass.new()
	add_child(fog)
	fog.setup(_map, player, GameState)

	# Clima visual (D-381/D-382/D-383): camada 2D de ambiente, sem Motion
	# Composer. Entra antes da vinheta para ficar abaixo dela e da UI.
	var weather = WeatherControllerClass.new()
	weather.name = "Weather"
	add_child(weather)
	weather.setup(GameState, fog, _map, player)

	# Vinheta suave de tela; fica abaixo do diálogo (layer 15) e dos menus (10).
	var vignette := CanvasLayer.new()
	vignette.name = "Vignette"
	vignette.layer = 1
	var vignette_rect := ColorRect.new()
	vignette_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_mat := ShaderMaterial.new()
	vignette_mat.shader = load("res://shaders/vignette.gdshader")
	vignette_rect.material = vignette_mat
	vignette.add_child(vignette_rect)
	add_child(vignette)

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


func _spawn_followers() -> void:
	if GameState.party.size() <= 1:
		return
	for i in range(1, GameState.party.size()):
		var member: Combatant = GameState.party[i]
		if member.species_id == "":
			continue
		var follower = DungeonFollowerClass.new()
		follower.setup(member.species_id, player)
		follower.position = _follower_spawn(player.position)
		entities.add_child(follower)
		followers.append(follower)


## D-389: DQT Orc 3D atrás do último aliado 2D (Pancham), só no overworld.
## Entra em `entities` para o Y-sort, mas não em `followers`: é visual, não é
## alvo de inimigo, não entra em batalha, party, colisão nem regra.
func _spawn_3d_follower() -> void:
	if not DungeonFollower3DClass.can_spawn("dqt_orc"):
		return
	var leader: Node2D = player
	if not followers.is_empty():
		leader = followers[-1]
	var orc = DungeonFollower3DClass.new()
	orc.setup("dqt_orc", leader)
	orc.position = _follower_spawn(leader.position)
	entities.add_child(orc)


## D-1016: anexa a vista 3D ao jogador e aos aliados que têm GLB. O sprite 2D
## do nó é escondido pela própria vista; sem o asset, nada muda.
func _attach_model_views() -> void:
	_attach_model_view(player, str(player.get("species_id")))
	for follower in followers:
		_attach_model_view(follower, str(follower.get("species_id")))
	# A elipse escura já desenhada pelo MapVisuals some sob quem tem modelo;
	# força o redraw.
	$Visuals.queue_redraw()


func _attach_model_view(target: Node2D, model_id: String) -> void:
	if target == null or model_id == "" or not Model3DViewClass.has_model(model_id):
		return
	target.set_meta("model_3d", model_id)
	var view = Model3DViewClass.new()
	view.setup(model_id, Model3DViewClass.pixel_height_for(model_id))
	target.add_child(view)


## O gap da fila atrás do líder; se estiver bloqueado, tenta as outras direções.
func _follower_spawn(origin: Vector2) -> Vector2:
	var gap := float(DungeonFollowerClass.TRAIL_GAP)
	for offset in [Vector2(0, gap), Vector2(0, -gap), Vector2(-gap, 0), Vector2(gap, 0)]:
		if not _is_wall_at(origin + offset):
			return origin + offset
	return origin


func _spawn_enemies(cells: Dictionary) -> void:
	if cells.is_empty():
		return
	var astar := _build_astar()
	for id in cells:
		var enemy := DungeonEnemyClass.new()
		enemy.setup(id, cells[id], _map, astar, player)
		enemy.followers = followers
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
		pickup.blocked.connect(_on_item_blocked)
		entities.add_child(pickup)


## Coleta automática (D-033): soma a Poção ao inventário e registra no GameState
## para ela não reaparecer ao voltar de uma batalha. QoL: every pickup answers.
func _on_item_collected(pickup) -> void:
	if not GameState.add_item(DungeonPickupClass.ITEM_ID):
		Menus.toast("Inventário cheio — libere um slot", Color("ff8a72"), 2.4)
		return
	GameState.dungeon_items_collected.append(pickup.id)
	var item := Item.get_item(DungeonPickupClass.ITEM_ID)
	var item_name := item.display_name if item != null else "Item"
	Menus.toast("%s +1   ·   %d/%d" % [item_name, GameState.total_item_count(), GameState.max_inventory_capacity()], Color("d7fd6a"), 2.0)


func _on_item_blocked(_pickup) -> void:
	Menus.toast("Inventário cheio — libere um slot", Color("ff8a72"), 2.4)


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
