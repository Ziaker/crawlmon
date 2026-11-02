extends Node
## Shared state between the 2D exploration and the 3D battle scenes:
## party, inventory, settings, and which encounters are already defeated.
## Also registers the game's input actions (Z confirm, X menu, C settings, Space evade).

const EXPLORATION := "res://scenes/exploration.tscn"
const BATTLE := "res://scenes/battle.tscn"
const DungeonGen = preload("res://scripts/dungeon/dungeon_generator.gd")

var player_pos := Vector2.INF  ## INF = use the map's spawn point.
var encounter_id := ""
var defeated: Array[String] = []
var in_battle := false
var transition: EncounterTransition
var party: Array[Combatant] = []
var inventory: Dictionary = {"potion": 3, "amulet": 1, "charm": 1}

## Current exploration floor. The layout is cached so leaving to a battle and
## coming back does not regenerate it (GDD R9-Q2).
var dungeon_seed := 0
var dungeon_layout: Array[String] = []
## Fog of war: one byte per tile (1 = already explored). Kept here so the map
## memory survives the trip to a battle and back.
var dungeon_explored := PackedByteArray()


func _ready() -> void:
	_register_key("confirm", KEY_Z)
	_register_key("menu", KEY_X)
	_register_key("settings", KEY_C)
	_register_key("evade", KEY_SPACE)
	_register_key("new_dungeon", KEY_R)  ## Debug: regenerate the exploration floor.
	_build_party()
	if "--battle" in OS.get_cmdline_user_args():  # godot --path . -- --battle
		_debug_battle.call_deferred()


## Debug: F9 jumps straight into a battle (from anywhere) or restarts the current one.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_debug_battle()


func _debug_battle() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if in_battle and get_tree().current_scene != null and get_tree().current_scene.scene_file_path == BATTLE:
		get_tree().reload_current_scene()
	else:
		in_battle = true
		encounter_id = "debug"
		get_tree().change_scene_to_file(BATTLE)


## Generates the floor once and keeps it for the rest of the exploration.
func ensure_dungeon() -> void:
	if dungeon_layout.is_empty():
		new_dungeon(dungeon_seed)


## Starts a brand-new exploration. Pass 0 to roll a random seed; the chosen
## seed is kept in dungeon_seed so the layout can be reproduced.
func new_dungeon(seed_value := 0) -> void:
	dungeon_seed = seed_value if seed_value != 0 else randi()
	dungeon_layout = DungeonGen.generate(dungeon_seed)
	dungeon_explored.clear()
	defeated.clear()
	player_pos = Vector2.INF


func start_battle(id: String, pos: Vector2) -> void:
	encounter_id = id
	player_pos = pos
	in_battle = true
	_transition().play_to(BATTLE)


## Encounter transition overlay, created on first use and kept under the root.
func _transition() -> EncounterTransition:
	if transition == null:
		transition = EncounterTransition.new()
		get_tree().root.add_child(transition)
	return transition


func end_battle(player_won: bool) -> void:
	if player_won:
		defeated.append(encounter_id)
	encounter_id = ""
	in_battle = false
	get_tree().change_scene_to_file.call_deferred(EXPLORATION)


func item_count(id: String) -> int:
	return inventory.get(id, 0)


func add_item(id: String) -> void:
	inventory[id] = item_count(id) + 1


func remove_item(id: String) -> void:
	if item_count(id) <= 1:
		inventory.erase(id)
	else:
		inventory[id] -= 1


## Inventory entries of the given kind, as Items (count via item_count()).
func items_of_kind(kind: Item.Kind) -> Array[Item]:
	var result: Array[Item] = []
	for id in inventory:
		var item := Item.get_item(id)
		if item != null and item.kind == kind:
			result.append(item)
	return result


func _register_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _build_party() -> void:
	var abra := Combatant.new("Abra", 32, 12, 0.50, true)
	abra.inventory = inventory  # The leader uses the shared party inventory.
	abra.weaknesses.assign([Element.Type.TREVAS, Element.Type.SOM])
	abra.skills.assign([
		Skill.new("Confusão", 1.4, 2, Element.Type.PSIQUICO),
		Skill.new("Raio Psíquico", 1.7, 3, Element.Type.PSIQUICO),
		Skill.new("Onda de Choque", 1.3, 2, Element.Type.RAIO),
		Skill.new("Teleporte Rápido", 1.1, 1, Element.Type.PSIQUICO),
	])
	var pancham := Combatant.new("Pancham", 45, 10, 0.45, true)
	pancham.weaknesses.assign([Element.Type.PSIQUICO, Element.Type.VENTO])
	pancham.skills.assign([
		Skill.new("Soco Rápido", 1.2),
		Skill.new("Golpe de Caratê", 1.5, 2, Element.Type.FISICO),
		Skill.new("Quebra de Telha", 1.8, 3, Element.Type.FISICO),
		Skill.new("Provocação", 1.1, 1, Element.Type.TREVAS),
	])
	party.assign([abra, pancham])
