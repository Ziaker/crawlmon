class_name DqtTestParty
extends RefCounted
## Temporary crossover roster: one Slime, one spear Orc and one Cyclops.
## Built only for the `--dqt` / `--dqt-mirror` battle tests; never replaces
## GameState.party, so exploration keeps its Pokemon sprites.
##
## D-1079/D-1080: the canonical species data lives in `content/characters/`.
## The HP/attack/speed/MP values below are test-only overrides and are not the
## character sheet.

static var enabled := false


static func build(is_player := true, inventory := {}) -> Array[Combatant]:
	var slime := CharacterFactory.create("dqt_slime", {
		"is_player": is_player,
		"test_bare": true,
		"max_hp": 34,
		"attack": 9,
		"speed": 0.55,
		"max_mp": 20,
	})
	if is_player:
		slime.inventory = inventory

	var orc := CharacterFactory.create("dqt_orc", {
		"is_player": is_player,
		"test_bare": true,
		"max_hp": 52,
		"attack": 13,
		"speed": 0.45,
		"max_mp": 20,
	})
	if is_player:
		orc.inventory = inventory

	var cyclops := CharacterFactory.create("dqt_cyclops", {
		"is_player": is_player,
		"test_bare": true,
		"max_hp": 64,
		"attack": 16,
		"speed": 0.35,
		"max_mp": 20,
	})

	# The spear Orc is the player-controlled leader in the DQT battle so the Move is
	# reachable in the real Fight menu.
	var out: Array[Combatant] = [orc, slime, cyclops]
	return out
