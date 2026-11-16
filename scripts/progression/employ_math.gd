class_name EmployMath
extends RefCounted
## D-1230: pure math for the Employ chance. No combat, no HUD, no autoload.
## Deterministic part only: the caller owns the random roll (see needs_roll/resolve).

const FORCE_WEIGHT := 45.0
const LEVEL_STEP := 2.0
const LEVEL_CAP := 20.0
const RESPECT_STEP := 0.16
const RESPECT_NEUTRAL := 50.0
const NOTE_GOOD_BONUS := 5.0
const NOTE_PERFECT_BONUS := 10.0


## Highest of STR and MAG. No cap: attributes above 100 are used as they are.
static func power(str_value: float, mag_value: float) -> float:
	return maxf(str_value, mag_value)


## Sum of power() over every member. `members` is an Array of [str, mag] pairs.
static func joint_power(members: Array) -> float:
	var total := 0.0
	for member in members:
		total += power(float(member[0]), float(member[1]))
	return total


## F = 45 * A / (A + E). The only guard is the division: A + E <= 0 returns 0.0.
static func force_component(joint: float, enemy_power: float) -> float:
	var combined := joint + enemy_power
	if combined <= 0.0:
		return 0.0
	return FORCE_WEIGHT * joint / combined


## N = clamp(2 * (level_traveler - level_enemy), -20, 20).
static func level_component(level_traveler: int, level_enemy: int) -> float:
	return clampf(LEVEL_STEP * float(level_traveler - level_enemy), -LEVEL_CAP, LEVEL_CAP)


## R = 0.16 * (respect - 50). Does not clamp: RespectState keeps respect in 0..100.
static func respect_component(respect: float) -> float:
	return RESPECT_STEP * (respect - RESPECT_NEUTRAL)


## B = plain sum of the note bonuses, exactly as given.
static func rhythm_bonus(note_bonuses: Array) -> float:
	var total := 0.0
	for bonus in note_bonuses:
		total += float(bonus)
	return total


## P = clamp(F + N + R + B, 0, 100), float and not rounded.
static func chance(members: Array, enemy_str: float, enemy_mag: float, level_traveler: int, level_enemy: int, respect: float, note_bonuses: Array) -> float:
	return float(breakdown(members, enemy_str, enemy_mag, level_traveler, level_enemy, respect, note_bonuses)["P"])


## Every intermediate of chance(), for debug and telemetry.
## "raw" is F + N + R + B before the clamp; "P" is the clamped result.
static func breakdown(members: Array, enemy_str: float, enemy_mag: float, level_traveler: int, level_enemy: int, respect: float, note_bonuses: Array) -> Dictionary:
	var joint := joint_power(members)
	var enemy_power := power(enemy_str, enemy_mag)
	var force := force_component(joint, enemy_power)
	var level := level_component(level_traveler, level_enemy)
	var respect_part := respect_component(respect)
	var rhythm := rhythm_bonus(note_bonuses)
	var raw := force + level + respect_part + rhythm
	return {
		"A": joint,
		"E": enemy_power,
		"F": force,
		"N": level,
		"R": respect_part,
		"B": rhythm,
		"raw": raw,
		"P": clampf(raw, 0.0, 100.0),
	}


## False when the outcome is already decided and no roll is needed.
static func needs_roll(p: float) -> bool:
	return p > 0.0 and p < 100.0


## Deterministic resolution with an external roll expected in [0, 100).
static func resolve(p: float, roll_0_100: float) -> bool:
	if p >= 100.0:
		return true
	if p <= 0.0:
		return false
	return roll_0_100 < p
