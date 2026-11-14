class_name PostCombatFlow
extends RefCounted
## Non-visual logic of the new post-combat flow (D-1192, prototype D-1185).
## Order: XP for everyone -> one LV step per member that leveled -> new Moves -> back to the map.
## No drawing and no character/side rules (D-235); the only identity check is the party leader (D-401).

const MAX_MOVES := 8  ## R38-Q5: the eight Move slots; the basic attack is not counted.
const STAT_NAMES: Array[String] = ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]

## Tests and captures may inject: species_id (String) -> { level (int) -> Array of move ids }.
## Empty means "read the real learnset" from CharacterCatalog (today empty for every species).
static var learnset_override: Dictionary = {}


## Concedes victory XP and returns one summary per party member (D-399, D-402).
## Dead members get a zero summary; alive members follow battle_scene.gd::_trigger_victory_flow step 3.
## Snapshots are taken BEFORE add_experience so the LV card can show the old maximums and stats.
static func grant_xp(party: Array, total_xp: int) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for member in party:
		if member == null:
			continue
		var c := member as Combatant
		if c == null:
			continue

		var old_stats := _effective_stats(c)
		var old_max_hp := c.max_hp
		var old_max_mp := c.max_mp
		var old_level := c.level
		var is_leader := c.is_party_leader()
		var xp_required_old := CrawlmonAttributeMath.get_xp_for_level_transition(old_level)

		var summary: Dictionary
		if c.is_alive():
			summary = c.add_experience(total_xp)
			summary["is_alive"] = true
		else:
			summary = {
				"is_alive": false,
				"old_level": old_level,
				"new_level": c.level,
				"levels_gained": 0,
				"points_gained": 0,
				"old_xp": c.xp,
				"current_xp": c.xp,
				"xp_required": CrawlmonAttributeMath.get_xp_for_level_transition(c.level),
				"transitions": [],
			}

		summary["combatant"] = c
		summary["is_leader"] = is_leader
		summary["old_max_hp"] = old_max_hp
		summary["old_max_mp"] = old_max_mp
		summary["new_max_hp"] = c.max_hp
		summary["new_max_mp"] = c.max_mp
		summary["old_stats"] = old_stats
		summary["xp_required_old"] = xp_required_old
		summaries.append(summary)
	return summaries


## Learnset Moves granted exactly at `level`, skipping the ones the combatant already knows.
static func moves_learned_at(c: Combatant, level: int) -> Array[StringName]:
	var out: Array[StringName] = []
	if c == null:
		return out
	var learnset := _learnset_for(c)
	var raw: Variant = learnset.get(level, [])
	if not (raw is Array):
		return out
	for entry in (raw as Array):
		var move_id := StringName(str(entry))
		if move_id == &"":
			continue
		if _knows_move(c, move_id):
			continue
		out.append(move_id)
	return out


## Exactly the prototype start() order:
## [{"kind":"xp"}] + one {"kind":"lv","index":i} per member that leveled (party order)
## + for each of those, one {"kind":"move","index":i,"level":l,"move_id":id} per learned Move.
static func build_steps(summaries: Array) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	steps.append({"kind": "xp"})
	for i in summaries.size():
		var level_entry: Dictionary = summaries[i]
		if int(level_entry.get("levels_gained", 0)) > 0:
			steps.append({"kind": "lv", "index": i})
	for i in summaries.size():
		var move_entry: Dictionary = summaries[i]
		if int(move_entry.get("levels_gained", 0)) <= 0:
			continue
		var c := move_entry.get("combatant", null) as Combatant
		if c == null:
			continue
		var from_level := int(move_entry.get("old_level", c.level))
		var to_level := int(move_entry.get("new_level", c.level))
		for level in range(from_level + 1, to_level + 1):
			var lv := int(level)
			for move_id in moves_learned_at(c, lv):
				steps.append({"kind": "move", "index": i, "level": lv, "move_id": move_id})
	return steps


## With a free slot the Move goes in the next empty one and its index is returned; -1 when full.
static func learn_into_free_slot(c: Combatant, move_id: StringName) -> int:
	if c == null or c.skills.size() >= MAX_MOVES:
		return -1
	var skill := Skill.from_id(move_id)
	if skill == null:
		return -1
	c.skills.append(skill)
	return c.skills.size() - 1


## Replaces `slot` with the new Move and returns the id that was forgotten ("" if invalid).
static func forget_and_learn(c: Combatant, slot: int, move_id: StringName) -> StringName:
	if c == null or slot < 0 or slot >= c.skills.size():
		return &""
	var new_skill := Skill.from_id(move_id)
	if new_skill == null:
		return &""
	var forgotten := move_id_of(c.skills[slot])
	c.skills[slot] = new_skill
	return forgotten


## Same body as level_up_modal.gd::_try_confirm without the UI: all points must be allocated (D-401).
static func apply_leader_allocation(c: Combatant, alloc: Dictionary) -> void:
	if c == null:
		return
	var total := 0
	for stat in STAT_NAMES:
		var delta := int(alloc.get(stat, 0))
		if delta > 0:
			total += delta
	if total != c.distributable_points:
		return
	for stat in STAT_NAMES:
		var delta := int(alloc.get(stat, 0))
		if delta > 0:
			c.progression_points[stat] = int(c.progression_points.get(stat, 0)) + delta
	c.distributable_points = maxi(0, c.distributable_points - total)
	c.sync_effective_stats()
	c.update_resource_maximums()


## Stable id of a Move, taken from its catalog definition when it has one.
static func move_id_of(s: Skill) -> StringName:
	if s == null:
		return &""
	if s.data != null:
		return s.data.id
	return StringName(BattleSpace.move_id(s.display_name))


## Points an ally would distribute automatically. Allies are NOT allocated here:
## the code has no rule for it (D-394/D-1192 open question), only the pending count.
static func ally_points_pending(summary: Dictionary) -> int:
	if bool(summary.get("is_leader", false)):
		return 0
	return int(summary.get("points_gained", 0))


static func _effective_stats(c: Combatant) -> Dictionary:
	var out: Dictionary = {}
	for stat in STAT_NAMES:
		out[stat] = c.get_effective_stat(stat)
	return out


static func _learnset_for(c: Combatant) -> Dictionary:
	var species := String(c.species_id)
	if learnset_override.has(species):
		var injected: Variant = learnset_override[species]
		if injected is Dictionary:
			return injected as Dictionary
		return {}
	var data := CharacterCatalog.get_character(StringName(c.species_id))
	if data == null or data.loadout == null:
		return {}
	return data.loadout.learnset


static func _knows_move(c: Combatant, move_id: StringName) -> bool:
	for skill in c.skills:
		if skill != null and move_id_of(skill) == move_id:
			return true
	return false
