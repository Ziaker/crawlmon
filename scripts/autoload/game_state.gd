extends Node
## Shared state between the 2D exploration and the 3D battle scenes:
## party, inventory, settings, and which encounters are already defeated.
## Also registers the game's input actions (Z confirm, X menu, C settings, Space evade).

const EXPLORATION := "res://scenes/exploration.tscn"
const BATTLE := "res://scenes/battle.tscn"

var player_pos := Vector2.INF  ## INF = use the map's spawn point.
var encounter_id := ""
var defeated: Array[String] = []
var in_battle := false
var party: Array[Combatant] = []
var inventory: Dictionary = {"potion": 3, "amulet": 1, "charm": 1}


func _ready() -> void:
	_register_key("confirm", KEY_Z)
	_register_key("menu", KEY_X)
	_register_key("settings", KEY_C)
	_register_key("evade", KEY_SPACE)
	_build_party()


func start_battle(id: String, pos: Vector2) -> void:
	encounter_id = id
	player_pos = pos
	in_battle = true
	get_tree().change_scene_to_file.call_deferred(BATTLE)


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
	var hero := Combatant.new("Herói", 40, 8, 0.45, true)
	hero.inventory = inventory  # The leader uses the shared party inventory.
	hero.weaknesses.assign([Element.Type.FOGO])
	hero.skills.assign([
		Skill.new("Golpe Forte", 1.5),
		Skill.new("Corte Giratório", 1.2),
		Skill.new("Estocada", 1.3),
		Skill.new("Investida", 1.8, 3),
	])
	var mage := Combatant.new("Mago", 28, 11, 0.4, true)
	mage.weaknesses.assign([Element.Type.FISICO])
	mage.skills.assign([
		Skill.new("Bola de Fogo", 1.6, 2, Element.Type.FOGO),
		Skill.new("Raio", 1.4, 2, Element.Type.RAIO),
		Skill.new("Gelo", 1.2, 2, Element.Type.AGUA_GELO),
		Skill.new("Meteoro", 2.2, 3, Element.Type.TERRA),
	])
	party.assign([hero, mage])
