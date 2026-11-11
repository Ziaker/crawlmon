class_name EncounterRules
extends RefCounted
## D-1100/D-1101: pure encounter rules shared by the overworld lab, the
## transition and the battle. No scene, VFX, character or team assumptions
## (D-235): the only inputs are the two advances and their hits.

enum Advantage { NORMAL, PLAYER_FIRST, ENEMY_FIRST }

const ATB_MAX := 5.0


## D-1100: both advances hitting at the same instant is a normal contact.
## A hit only counts when that side actually attacked.
static func resolve(player_attack: bool, player_hit: bool, enemy_attack: bool, enemy_hit: bool) -> int:
	var player_connected := player_attack and player_hit
	var enemy_connected := enemy_attack and enemy_hit
	if player_connected and enemy_connected:
		return Advantage.NORMAL
	if player_connected:
		return Advantage.PLAYER_FIRST
	if enemy_connected:
		return Advantage.ENEMY_FIRST
	return Advantage.NORMAL


## D-1101: the winning side starts with +1 normal ATB block and the losing side
## with -1, in every combatant, clamped to 0..5. The `extra` field (blocks above
## five) is never used or touched by this rule.
static func apply_atb(party: Array, enemies: Array, advantage: int) -> void:
	match advantage:
		Advantage.PLAYER_FIRST:
			_shift_atb(party, 1)
			_shift_atb(enemies, -1)
		Advantage.ENEMY_FIRST:
			_shift_atb(enemies, 1)
			_shift_atb(party, -1)
		_:
			pass  # NORMAL (or any unknown value): no change.


static func _shift_atb(units: Array, amount: int) -> void:
	for unit in units:
		if unit == null:
			continue
		unit.atb = clampf(unit.atb + amount, 0.0, ATB_MAX)
