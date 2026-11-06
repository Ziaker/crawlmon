class_name BiomeSelector
extends RefCounted
## Picks a tileset profile for the current floor (D-317/D-346).
##
## The pool currently has all 16 Sky profiles. D-317 changes the biome on the
## 5th floor: floors 1-4 use step 0, floor 5 uses step 1, 10 uses step 2.
## The seed is stable for the campaign so a defeat/retry keeps the same look.

const POOL_PATH := "res://assets/pmd/dungeons/sky/atlas/biome_pool.json"
const FALLBACK_NAME := "temporal_tower"
const FALLBACK_PROFILE := "res://assets/pmd/dungeons/sky/atlas/temporal_tower_profile.json"


static func profiles() -> Array:
	if not FileAccess.file_exists(POOL_PATH):
		return []
	var file := FileAccess.open(POOL_PATH, FileAccess.READ)
	if file == null:
		return []
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return []
	var list: Variant = data.get("profiles", [])
	return list if list is Array else []


static func pick(floor_number: int, seed_value: int) -> Dictionary:
	var entries := profiles()
	if entries.is_empty():
		return {"name": FALLBACK_NAME, "profile": FALLBACK_PROFILE}

	# floor 5 -> step 1; floors 1-4 -> step 0.
	var step := maxi(0, floor_number / 5)
	# Floors 1-4 keep the approved fortress look (D-312: the current visual is
	# the fortress). The first change happens on floor 5, as D-317 asks.
	if step == 0:
		return {"name": FALLBACK_NAME, "profile": FALLBACK_PROFILE}
	return entries[_index_for_step(step, seed_value, entries)]


## Deterministic per step, with no repeat from the previous step. The same
## step always returns the same biome, so floors 6-9 keep the floor-5 biome.
static func _index_for_step(step: int, seed_value: int, entries: Array) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed_value) ^ (step * 7919)
	var index := rng.randi_range(0, entries.size() - 1)
	var previous := _fallback_index(entries) if step == 1 else _index_for_step(step - 1, seed_value, entries)
	if entries.size() > 1 and index == previous:
		index = (index + 1) % entries.size()
	return index


static func _fallback_index(entries: Array) -> int:
	for index in entries.size():
		if str(entries[index].get("name", "")) == FALLBACK_NAME:
			return index
	return -1
