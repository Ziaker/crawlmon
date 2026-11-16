extends Node
## Shared state between the 2D exploration and the 3D battle scenes:
## party, inventory, settings, and which encounters are already defeated.
## Also registers the game's input actions (Z confirm, X menu, C settings, Space evade).

const EXPLORATION := "res://scenes/exploration.tscn"
const BATTLE := "res://scenes/battle.tscn"
## D-1208: pre-game v3 and the campaign cycle (Hub 3D <-> 3D expedition).
const PRE_GAME := "res://scenes/pre_game.tscn"
const HUB_3D := "res://scenes/hub_3d_lab.tscn"
const MURKY_FOREST_3D := "res://scenes/debug/murky_forest_3d_lab.tscn"
const DungeonGen = preload("res://scripts/dungeon/dungeon_generator.gd")
const DebugPartySelectorClass = preload("res://scripts/ui/debug_party_selector.gd")
## Preloaded (not the global class name) so the autoload parses even before the class cache knows the new script.
const ExpeditionRosterClass = preload("res://scripts/progression/expedition_roster.gd")
const RespectStateClass = preload("res://scripts/progression/respect_state.gd")
const RESPECT_LOG_MAX := 32
## Baseline non-held stock for a fresh expedition (R25-Q4/R31-Q1).
const INITIAL_INVENTORY := {"potion": 3, "amulet": 1, "charm": 1}

var player_pos := Vector2.INF  ## INF = use the map's spawn point.
var encounter_id := ""
## D-1100/D-1101: encounter variant and the 3D return point. return_scene == ""
## keeps the 2D path returning to EXPLORATION, exactly as before.
var encounter_advantage: int = EncounterRules.Advantage.NORMAL
var return_scene := ""
var return_pos_3d := Vector3.ZERO
var return_yaw := 0.0
var defeated: Array[String] = []
var in_battle := false
var transition: EncounterShatterTransition  ## D-1172: replaces the old EncounterTransition (kept in the repo, unused)
var party: Array[Combatant] = []
## Debug/test tool: global E selector for choosing which party member is controlled.
var debug_party_selector: CanvasLayer
## D-981: species whose elements the player has discovered (a weakness hit). Session only (no save yet).
var discovered_species: Dictionary = {}
## D-1208: campaign/expedition cycle (pre-game -> Hub 3D -> Murky Forest 3D).
## `expedition_origin_scene` is the scene that launched the expedition (HUB_3D for
## the gate flow), so the defeat/exit handlers know where to send the player back.
var expedition_origin_scene := ""
var active_campaign_started := false
var last_expedition_nature_id := ""
## D-1219: the Nature (and the individual offsets, D-132) stay with the character until it is lost
## (defeat/game over). Keyed by species_key. Memory only: there is no save file yet.
var character_natures: Dictionary = {}
## D-1233: active / substitute / stationed members by individual identity. Data only; `party` stays the source of truth for the active team.
var roster: ExpeditionRosterClass = ExpeditionRosterClass.new()
## D-1231/D-1235: Respect of the Travelers group (one value for the group, not per character). Memory only: there is no save file yet.
var respect: RespectStateClass = RespectStateClass.new()
## Last RESPECT_LOG_MAX Respect events, newest last (debug/telemetry; not a log of every action).
var respect_log: Array[Dictionary] = []


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
	if debug_party_selector == null:
		debug_party_selector = DebugPartySelectorClass.new()
		debug_party_selector.name = "DebugPartySelector"
		add_child(debug_party_selector)
	if "--battle" in OS.get_cmdline_user_args():  # godot --path . -- --battle
		_debug_battle.call_deferred()
	var args := OS.get_cmdline_user_args()
	# D-1208: fast CLI entry points for tests (< 10 s, D-1204).
	if "--hub" in args:
		_change_scene_deferred(HUB_3D)
	elif "--forest" in args:
		_change_scene_deferred(MURKY_FOREST_3D)


## Debug: F9 jumps straight into a battle (from anywhere) or restarts the current one.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_debug_battle()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		# D-1208: F10 opens the Hub 3D (pre-game v3 campaign hub).
		Engine.time_scale = 1.0
		get_tree().paused = false
		get_tree().change_scene_to_file(HUB_3D)


## D-1208: one deferred scene swap shared by the CLI shortcuts and the HUD actions.
func _change_scene_deferred(path: String) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)


## D-1208 (NEW GAME): fresh campaign with the chosen protagonist as party[0] plus
## one complementary ally (Pancham, or Abra when the leader is Pancham), so the
## duo stays calibrated (D-1207 C1). The leader shares the party inventory.
func start_new_campaign(leader_species: String) -> void:
	leader_species = leader_species.to_lower()
	if leader_species == "":
		leader_species = "abra"
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var leader := CharacterFactory.create(leader_species, {
		"is_player": true,
		"rng": rng,
		"inventory": inventory,
	})
	var ally_id := "pancham" if leader_species != "pancham" else "abra"
	var ally := CharacterFactory.create(ally_id, {
		"is_player": true,
		"rng": rng,
		"act_policy": Combatant.Act.SKILL,
		"react_policy": Combatant.React.EVADE,
	})
	party.assign([leader, ally])
	active_campaign_started = true
	last_expedition_nature_id = ""
	expedition_origin_scene = ""
	defeated.clear()
	respect = RespectStateClass.new()  # D-1231: a new campaign starts at 50.
	respect_log.clear()
	reset_expedition_inventory()


## D-1231: applies one Respect event to the group and returns the delta really applied.
## `source` says where it came from ("expedition_defeat", "retreat", a test...). With `--stdout-trace`
## it prints one `RESPECT_JSON: {...}` line (documented in docs/TELEMETRIA.md).
func apply_respect(event: int, source: String, feat_id: String = "") -> int:
	var delta: int = respect.apply(event, feat_id)
	var entry := {"event": String(RespectStateClass.Event.keys()[event]), "source": source, "feat_id": feat_id, "delta": delta, "value": respect.value, "challenging_left": respect.challenging_rewards_left()}
	respect_log.append(entry)
	while respect_log.size() > RESPECT_LOG_MAX:
		respect_log.pop_front()
	if "--stdout-trace" in OS.get_cmdline_user_args():
		print("RESPECT_JSON: " + JSON.stringify(entry))
	return delta


## D-1233: the roster with ACTIVE synced from `party`.
func get_roster() -> ExpeditionRosterClass:
	roster.sync_active(party)
	return roster


func has_character_nature(species: String) -> bool:
	return character_natures.has(species.to_lower())


func get_character_nature(species: String) -> Dictionary:
	return (character_natures.get(species.to_lower(), {}) as Dictionary).duplicate(true)


func set_character_nature(species: String, nature_id: String, offsets: Dictionary) -> void:
	character_natures[species.to_lower()] = {"nature_id": nature_id.to_lower(), "offsets": offsets.duplicate(true)}


## D-1219: losing the character erases its Nature; the next selection rolls again.
func clear_character_nature(species: String) -> void:
	character_natures.erase(species.to_lower())


## D-1219 (replaces the per-expedition roll of D-1208/D-316): applies the leader's fixed Nature and
## offsets to the party leader and resets HP/MP, stock and the defeated list. `forced_nature_id`
## (roulette result or debug) wins and is stored for the character; with none, the stored Nature is
## used (the roulette is skipped); with neither, a Nature is drawn once and stored.
## Allies keep their own Nature (the leader's Nature is no longer copied to them).
## Returns {"nature_id", "nature", "offsets"}.
func roll_expedition_nature_and_prepare(forced_nature_id: String = "", forced_offsets: Dictionary = {}) -> Dictionary:
	if party.is_empty():
		_build_party()
	var leader: Combatant = party[0]
	var key := species_key(leader)
	var stored: Dictionary = get_character_nature(key)
	var nat_id := forced_nature_id.to_lower()
	var offsets: Dictionary = forced_offsets.duplicate(true)
	if not NatureData.NATURES.has(nat_id):
		if not stored.is_empty() and NatureData.NATURES.has(str(stored.get("nature_id", ""))):
			nat_id = str(stored["nature_id"])
			if offsets.is_empty() and stored.get("offsets") is Dictionary:
				offsets = (stored["offsets"] as Dictionary).duplicate(true)
		else:
			var ids := NatureData.get_all_nature_ids()
			nat_id = ids[randi_range(0, ids.size() - 1)]
	elif offsets.is_empty() and not stored.is_empty() and str(stored.get("nature_id", "")) == nat_id and stored.get("offsets") is Dictionary:
		offsets = (stored["offsets"] as Dictionary).duplicate(true)
	if offsets.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		offsets = CrawlmonAttributeMath.roll_individual_offsets(rng)
	last_expedition_nature_id = nat_id
	set_character_nature(key, nat_id, offsets)
	var data := CharacterCatalog.get_character(StringName(key))
	if data != null:
		var base_stats := CrawlmonAttributeMath.convert_species_stats_to_15_points(data.raw_stats)
		var nature_mods: Dictionary = NatureData.get_nature(nat_id)["mods"]
		leader.nature_id = nat_id
		leader.individual_offsets = offsets
		leader.innate_stats = CrawlmonAttributeMath.consolidate_innate_attributes(base_stats, offsets, nature_mods)
		leader.sync_effective_stats()
		leader.update_resource_maximums()
		leader.base_attack = leader.str
	revive_party()
	reset_expedition_inventory()
	defeated.clear()
	expedition_origin_scene = HUB_3D
	respect.begin_expedition()  # D-1231: the 3 challenging-encounter rewards are per expedition.
	return {"nature_id": nat_id, "nature": NatureData.get_nature(nat_id), "offsets": offsets}


## D-1208: the Hub 3D exit door ends the expedition and returns to the Hub.
## XP, levels and items are preserved; only the one-shot battle return clears.
func return_to_hub_from_expedition() -> void:
	if expedition_origin_scene != "":
		apply_respect(RespectStateClass.Event.STRATEGIC_RETREAT, "retreat")  # D-1231: retreat = 0.
	encounter_id = ""
	in_battle = false
	_clear_return_point()
	expedition_origin_scene = ""
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(HUB_3D)

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
	return_scene = ""
	return_pos_3d = Vector3.ZERO
	return_yaw = 0.0
	encounter_advantage = EncounterRules.Advantage.NORMAL
	_transition().play_to(BATTLE)


## D-1100: starts a battle from the 3D lab and remembers the exact spot/direction
## to return to. The transition reads the variant (white/blue/red).
func start_battle_3d(id: String, scene_path: String, pos: Vector3, yaw: float, advantage: int) -> void:
	encounter_id = id
	return_scene = scene_path
	return_pos_3d = pos
	return_yaw = yaw
	encounter_advantage = advantage
	in_battle = true
	_transition().play_to(BATTLE, advantage, _screen_uv_of(pos + Vector3.UP))


## Encounter transition overlay, created on first use and kept under the root.
func _transition() -> EncounterShatterTransition:
	if transition == null:
		transition = EncounterShatterTransition.new()
		get_tree().root.add_child(transition)
	return transition


## D-1172: where a world point sits on screen (0..1 from the top-left), for the
## transition's shockwave centre. Screen centre when there is no 3D camera.
func _screen_uv_of(world_pos: Vector3) -> Vector2:
	var vp := get_viewport()
	var cam := vp.get_camera_3d() if vp != null else null
	if cam == null or cam.is_position_behind(world_pos):
		return Vector2(0.5, 0.5)
	var view := vp.get_visible_rect().size
	if view.x <= 0.0 or view.y <= 0.0:
		return Vector2(0.5, 0.5)
	return cam.unproject_position(world_pos) / view


func end_battle(player_won: bool) -> void:
	var returning_to_3d := return_scene != ""
	if player_won:
		defeated.append(encounter_id)
	else:
		# D-1219: defeat = game over of the character; its Nature is erased (new roulette next time).
		if not party.is_empty():
			clear_character_nature(species_key(party[0]))
		# D-1208: a defeat inside an expedition launched from the Hub 3D never goes
		# back to the 2D exploration. The party is revived, the expedition stock and
		# the defeated list are reset, and the player returns to the Hub 3D.
		if not player_won and expedition_origin_scene == HUB_3D:
			apply_respect(RespectStateClass.Event.EXPEDITION_DEFEAT, "expedition_defeat")  # D-1231: definitive defeat = -2.
			revive_party()
			reset_expedition_inventory()
			defeated.clear()
			expedition_origin_scene = ""
			encounter_id = ""
			in_battle = false
			get_tree().change_scene_to_file.call_deferred(HUB_3D)
			await get_tree().scene_changed
			_clear_return_point()
			return
		# R23-Q3/R33-Q1: defeat ends the current expedition. The next attempt is a
		# new expedition from floor 1 (D-316/D-317), with a fresh layout and biome.
		# There is no hub/campaign scene yet (D-324), so the player respawns at the
		# map's P spawn. XP/levels are preserved on the same Combatant objects (R32-Q3).
		# D-1106: coming from the 3D lab, defeat returns there without resetting the 2D expedition.
		revive_party()
		if not returning_to_3d:
			reset_expedition_inventory()
			visual_floor = 1
			biome_seed = 0  # new_dungeon rolls a new seed and adopts it for the biome.
			new_dungeon(0, false)
	encounter_id = ""
	in_battle = false
	var target := return_scene if return_scene != "" else EXPLORATION
	get_tree().change_scene_to_file.call_deferred(target)
	if returning_to_3d:
		# The lab reads the return point in _ready; clear it only after the new scene is up.
		await get_tree().scene_changed
	_clear_return_point()


## D-1100/D-1101: the return point and the advantage are one-shot.
func _clear_return_point() -> void:
	return_scene = ""
	return_pos_3d = Vector3.ZERO
	return_yaw = 0.0
	encounter_advantage = EncounterRules.Advantage.NORMAL


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
