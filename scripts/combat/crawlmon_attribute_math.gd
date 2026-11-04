class_name CrawlmonAttributeMath
extends RefCounted
## Approved, parameterized rules only. Not wired into Combatant, Battle or Skill.
## D-131, D-132, D-139, D-143, D-144, D-146, D-147,
## D-150..D-153, D-156, D-163, D-164, D-170.

const ATTRIBUTES: Array[String] = ["STR", "MAG", "VIT", "SPI", "AGI", "LUK"]


## A single independent draw, with integer outcomes -3..+3 and weights 1:2:3:4:3:2:1.
static func individual_offset_from_ticket(ticket: int) -> int:
	assert(ticket >= 0 and ticket < 16, "Triangular ticket must be in [0, 15]")
	if ticket == 0:
		return -3
	if ticket <= 2:
		return -2
	if ticket <= 5:
		return -1
	if ticket <= 9:
		return 0
	if ticket <= 12:
		return 1
	if ticket <= 14:
		return 2
	return 3


## Call once when an individual is created, then persist the returned Dictionary.
## This function does not create/specify an RNG seed or persistence format.
static func roll_individual_offsets(rng: RandomNumberGenerator) -> Dictionary:
	var offsets: Dictionary = {}
	for attribute in ATTRIBUTES:
		offsets[attribute] = individual_offset_from_ticket(rng.randi_range(0, 15))
	return offsets


## No upper cap of 100; lower bound 1 preserved (D-139).
## Base values and the individual's offsets must come from authoritative, persisted data.
static func apply_individual_offsets(base: Dictionary, offsets: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for attribute in ATTRIBUTES:
		assert(base.has(attribute), "Missing species attribute: " + attribute)
		assert(offsets.has(attribute), "Missing persisted individual offset: " + attribute)
		var offset: int = int(offsets[attribute])
		assert(offset >= -3 and offset <= 3, "Individual offset out of range")
		result[attribute] = maxi(1, int(base[attribute]) + offset)
	return result


## A probability between 0 and 1. Read both effective LUK values at event resolution.
## D-150 and D-151: 10% + one percentage point per point of attacker-target LUK.
static func critical_chance(attacker_luk: int, target_luk: int) -> float:
	return clampf(0.10 + float(attacker_luk - target_luk) * 0.01, 0.0, 1.0)


## D-146 and D-143: only call when a Move *declares* a probabilistic effect.
## Guaranteed effects must NOT pass through a probability roll (D-134).
static func status_application_chance(base_chance: float, applier_luk: int, target_luk: int) -> float:
	assert(base_chance >= 0.0 and base_chance <= 1.0, "Declared base chance must be in [0, 1]")
	return clampf(base_chance + float(applier_luk - target_luk) * 0.01, 0.0, 1.0)


## D-152 and D-153: positive or negative LUK difference, symmetric diminishing
## marginal gains. First 10 points: 1pp each; next 10: 0.5pp; next: 0.25pp, etc.
## A closed form avoids unbounded loops when permanent attributes exceed 100.
static func automatic_dodge_chance(attacker_luk: int, defender_luk: int) -> float:
	var difference: int = defender_luk - attacker_luk
	var magnitude: int = absi(difference)
	var completed_bands: int = floori(float(magnitude) / 10.0)
	var remainder: int = magnitude % 10
	var band_rate: float = pow(0.5, completed_bands)
	var correction_pp: float = 20.0 * (1.0 - band_rate) + float(remainder) * band_rate
	var sign_factor := -1.0 if difference < 0 else 1.0
	return clampf(0.10 + sign_factor * correction_pp * 0.01, 0.0, 1.0)


## D-163, D-164, D-170: AGI read once per natural-ATB tick, floor 1 for
## this calculation only. Reference AGI and reference regeneration rate MUST be
## passed in: they are not approved or measured (D-169, D-190).
## Do not call while ATB regeneration is paused/locked.
static func natural_atb_increment(delta: float, effective_agi: float, reference_agi: float, reference_blocks_per_second: float) -> float:
	assert(delta >= 0.0, "Delta must be nonnegative")
	assert(reference_agi > 0.0, "ATB reference AGI is not yet calibrated")
	assert(reference_blocks_per_second > 0.0, "Reference ATB rate must be positive")
	return delta * reference_blocks_per_second * (maxf(effective_agi, 1.0) / reference_agi)
