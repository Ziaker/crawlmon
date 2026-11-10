extends Node
## Shared state between the 2D exploration and the 3D battle scenes:
## party, inventory, settings, and which encounters are already defeated.
## Also registers the game's input actions (Z confirm, X menu, C settings, Space evade).

const EXPLORATION := "res://scenes/exploration.tscn"
const BATTLE := "res://scenes/battle.tscn"
const DungeonGen = preload("res://scripts/dungeon/dungeon_generator.gd")
## Baseline non-held stock for a fresh expedition (R25-Q4/R31-Q1).
const INITIAL_INVENTORY := {"potion": 3, "amulet": 1, "charm": 1}

var player_pos := Vector2.INF  ## INF = use the map's spawn point.
var encounter_id := ""
var defeated: Array[String] = []
var in_battle := false
var transition: EncounterTransition
var party: Array[Combatant] = []
## D-981: species whose elements the player has discovered (a weakness hit). Session only (no save yet).
var discovered_species: Dictionary = {}


static func species_key(c: Combatant) -> String:
	return c.species_id.to_lower() if c.species_id != "" else c.name.to_lower()


## D-981: the elements of `c` are known when the same species is on the team or one of its weaknesses was found.
func elements_known(c: Combatant, team: Array = []) -> bool:
	var key := species_key(c)
	if discovered_species.has(key):
		return true
	for m in (team + party):
		if m != null and m != c and species_key(m) == key:
			return true
	return false
var inventory: Dictionary = INITIAL_INVENTORY.duplicate()

## QoL: dialogue typewriter speed (characters per second).
const TEXT_SPEED_NAMES := ["Lento", "Normal", "Rápido"]
const TEXT_SPEED_VALUES := [28.0, 46.0, 80.0]
var text_speed := 1


func text_speed_name() -> String:
	return TEXT_SPEED_NAMES[clampi(text_speed, 0, TEXT_SPEED_NAMES.size() - 1)]


func text_speed_value() -> float:
	return float(TEXT_SPEED_VALUES[clampi(text_speed, 0, TEXT_SPEED_VALUES.size() - 1)])


func cycle_text_speed(step: int) -> void:
	text_speed = posmod(text_speed + step, TEXT_SPEED_NAMES.size())

## Current exploration floor. The layout is cached so leaving to a battle and
## coming back does not regenerate it (GDD R9-Q2).
var dungeon_seed := 0
var dungeon_layout: Array[String] = []
## Visual floor counter and stable biome seed for the 5-floor tileset cycle
## (D-317/D-346). The real 5-floor expedition (D-316) does not exist yet.
var visual_floor := 0
var biome_seed := 0
var visual_biome := ""
## Fog of war: one byte per tile (1 = already explored). Kept here so the map
## memory survives the trip to a battle and back.
var dungeon_explored := PackedByteArray()
## Consumable pickups already collected on the current floor, keyed by "x,y".
## Kept so leaving to a battle and coming back does not respawn them (D-033).
var dungeon_items_collected: Array[String] = []

func _ready() -> void:
	_register_key("confirm", KEY_Z)
	_register_key("menu", KEY_X)
	_register_key("settings", KEY_C)
	_register_key("evade", KEY_SPACE)
	_register_key("guard", KEY_SHIFT)  ## D-272: Guard hotkey.
	_register_key("new_dungeon", KEY_R)  ## Debug: regenerate the exploration floor.
	_build_party()
	if "--battle" in OS.get_cmdline_user_args():  # godot --path . -- --battle
		_debug_battle.call_deferred()


## Debug: F9 jumps straight into a battle (from anywhere) or restarts the current one.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_debug_battle()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		# Debug: isolated hub test at 24 px (D-328).
		Engine.time_scale = 1.0
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/hub_test.tscn")


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
func new_dungeon(seed_value := 0, advance_floor := true) -> void:
	dungeon_seed = seed_value if seed_value != 0 else randi()
	if biome_seed == 0:
		biome_seed = dungeon_seed
	if advance_floor:
		visual_floor += 1
	dungeon_layout = DungeonGen.generate(dungeon_seed)
	dungeon_explored.clear()
	dungeon_items_collected.clear()
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
	else:
		# R23-Q3/R33-Q1: defeat ends the current expedition. The next attempt is a
		# new expedition from floor 1 (D-316/D-317), with a fresh layout and biome.
		# There is no hub/campaign scene yet (D-324), so the player respawns at the
		# map's P spawn. XP/levels are preserved on the same Combatant objects (R32-Q3).
		revive_party()
		reset_expedition_inventory()
		visual_floor = 1
		biome_seed = 0  # new_dungeon rolls a new seed and adopts it for the biome.
		new_dungeon(0, false)
	encounter_id = ""
	in_battle = false
	get_tree().change_scene_to_file.call_deferred(EXPLORATION)


## R23-Q3/R33-Q1: all active party members return at full HP for the new attempt.
func revive_party() -> void:
	for member in party:
		member.revive_full()


## R25-Q4/R31-Q1: non-held items from the expedition are lost, while held items
## stay with their Pokémon (equipped) or in the bag (unequipped). The baseline
## consumables are restored for the new attempt.
func reset_expedition_inventory() -> void:
	var held_in_bag: Dictionary = {}
	for id in inventory:
		var item := Item.get_item(id)
		if item != null and item.kind == Item.Kind.HELD:
			held_in_bag[id] = int(inventory[id])
	var equipped: Dictionary = {}
	for member in party:
		if member.held_item_id != "":
			equipped[member.held_item_id] = int(equipped.get(member.held_item_id, 0)) + 1
	inventory.clear()
	for id in INITIAL_INVENTORY:
		var item := Item.get_item(id)
		if item == null or item.kind != Item.Kind.HELD:
			inventory[id] = int(INITIAL_INVENTORY[id])
	inventory.merge(held_in_bag, true)
	# Restore the baseline held items only when they are neither equipped nor
	# already in the bag, so a held Amulet/Talisman is never duplicated.
	for id in INITIAL_INVENTORY:
		var item := Item.get_item(id)
		if item == null or item.kind != Item.Kind.HELD:
			continue
		if not inventory.has(id) and not equipped.has(id):
			inventory[id] = int(INITIAL_INVENTORY[id])


func item_count(id: String) -> int:
	return inventory.get(id, 0)


## Non-held items carried by the active party (R35-Q3). Held items stay in the
## same dictionary while unequipped, but they do not count against capacity.
func total_item_count() -> int:
	var total := 0
	for id in inventory:
		var item := Item.get_item(id)
		if item != null and item.kind == Item.Kind.HELD:
			continue
		total += int(inventory[id])
	return total


## R35-Q3: 10 non-held items per active party member (20 with two, 30 with three).
func max_inventory_capacity() -> int:
	return party.size() * 10


func is_inventory_full() -> bool:
	return total_item_count() >= max_inventory_capacity()


## Whether a new item fits. Held items are outside the capacity rule (R35-Q3).
func can_add_item(id: String) -> bool:
	var item := Item.get_item(id)
	if item != null and item.kind == Item.Kind.HELD:
		return true
	return not is_inventory_full()


## Adds one item if capacity allows. Held items are outside the capacity rule
## (R35-Q3); returns false when a non-held item does not fit.
func add_item(id: String) -> bool:
	if not can_add_item(id):
		return false
	inventory[id] = item_count(id) + 1
	return true


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
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# D-1079: a ficha de Abra/Pancham vive em content/characters/.
	var abra := CharacterFactory.create("abra", {
		"is_player": true,
		"forced_nature": "modest",
		"rng": rng,
		"inventory": inventory,  # The leader uses the shared party inventory.
	})
	var pancham := CharacterFactory.create("pancham", {
		"is_player": true,
		"forced_nature": "brave",
		"rng": rng,
		"act_policy": Combatant.Act.SKILL,  # Allies start out using their moves and dodging (D-168).
		"react_policy": Combatant.React.EVADE,
	})
	party.assign([abra, pancham])
