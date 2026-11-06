class_name RollingHpOdometer
extends RefCounted
## D-048 archived by D-347 (2026-11-06).
##
## The creator asked to remove the Mother 3 / EarthBound rolling-HP odometer from the active game
## and keep it for later. This file is the archived math: it is NOT referenced by the battle. When
## the system returns, `Combatant` can gain `target_hp`/`rolling_hp` again and call these helpers.
##
## Original rules (D-048):
## - Only the player's monsters roll; enemies take damage instantly.
## - Non-fatal damage updates the target and the shown value drains at max_hp / 3.0 per second,
##   respecting Engine.time_scale because the caller passes the scaled delta.
## - Fatal damage (damage >= current HP) is immediate, with no rolling.
## - Healing updates the target and the odometer rolls up smoothly.
## - On victory, pending damage is cancelled (the battle freezes the targets at the current HP).

const DRAIN_SECONDS := 3.0


static func drain_speed(max_hp: int) -> float:
	return maxf(float(max_hp) / DRAIN_SECONDS, 5.0)


## Target HP after damage. Fatal damage goes straight to 0; non-fatal damage leaves at least 1.
static func target_after_damage(current_hp: int, damage: int) -> int:
	if damage >= current_hp:
		return 0
	return maxi(current_hp - damage, 1)


## Target HP after a heal, capped at max_hp.
static func target_after_heal(target_hp: int, amount: int, max_hp: int) -> int:
	return mini(target_hp + amount, max_hp)


## One scaled tick of the odometer toward `target_hp`.
static func tick(rolling_hp: float, target_hp: int, max_hp: int, delta: float) -> float:
	return move_toward(rolling_hp, float(target_hp), drain_speed(max_hp) * delta)
