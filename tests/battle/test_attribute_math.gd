extends SceneTree
## Headless entry point: godot --headless --path . --script res://tests/battle/test_attribute_math.gd
## Mathematics only. Does NOT verify combat integration, species data or gameplay.
const Rules = preload("res://scripts/combat/crawlmon_attribute_math.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_counts := {-3: 1, -2: 2, -1: 3, 0: 4, 1: 3, 2: 2, 3: 1}
	var counts := {-3: 0, -2: 0, -1: 0, 0: 0, 1: 0, 2: 0, 3: 0}
	for ticket in range(16):
		counts[Rules.individual_offset_from_ticket(ticket)] += 1
	assert(counts == expected_counts, "Triangular distribution must be 1:2:3:4:3:2:1")

	var rng := RandomNumberGenerator.new()
	rng.seed = 123456
	var individual: Dictionary = Rules.roll_individual_offsets(rng)
	assert(individual.size() == 6)
	for key in Rules.ATTRIBUTES:
		assert(individual.has(key))
		assert(individual[key] >= -3 and individual[key] <= 3)
	var base := {"STR": 99, "MAG": 40, "VIT": 40, "SPI": 40, "AGI": 40, "LUK": 40}
	var offsets := {"STR": 3, "MAG": 0, "VIT": -2, "SPI": 1, "AGI": -3, "LUK": 2}
	var stats: Dictionary = Rules.apply_individual_offsets(base, offsets)
	assert(stats["STR"] == 102, "No upper cap at 100 (D-139)")
	assert(stats["AGI"] == 37)

	assert(is_equal_approx(Rules.critical_chance(70, 40), 0.40))
	assert(is_equal_approx(Rules.critical_chance(0, 40), 0.0))
	assert(is_equal_approx(Rules.critical_chance(150, 0), 1.0))
	assert(is_equal_approx(Rules.status_application_chance(0.50, 7, 10), 0.47))
	assert(is_equal_approx(Rules.status_application_chance(0.98, 70, 40), 1.0))
	assert(is_equal_approx(Rules.status_application_chance(0.01, 0, 40), 0.0))

	assert(is_equal_approx(Rules.automatic_dodge_chance(40, 40), 0.10))
	assert(is_equal_approx(Rules.automatic_dodge_chance(40, 70), 0.275))
	assert(is_equal_approx(Rules.automatic_dodge_chance(70, 40), 0.0))
	assert(is_equal_approx(Rules.automatic_dodge_chance(40, 45), 0.15))
	assert(is_equal_approx(Rules.automatic_dodge_chance(45, 40), 0.05))
	assert(is_equal_approx(Rules.automatic_dodge_chance(40, 65), 0.2625))

	var slow: float = Rules.natural_atb_increment(1.0, 25.0, 50.0, 1.0)
	var fast: float = Rules.natural_atb_increment(1.0, 50.0, 50.0, 1.0)
	assert(is_equal_approx(slow * 2.0, fast), "Double AGI halves the time")
	assert(is_equal_approx(Rules.natural_atb_increment(1.0, -10.0, 50.0, 1.0), 0.02))

	print("ATTRIBUTE_MATH_TESTS_PASS — mathematical rules only")
	quit(0)
