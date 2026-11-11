extends SceneTree
var _f := 0
func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c: _f += 1

func _init() -> void:
	# D-1142: formula curve.
	ok(is_equal_approx(CrawlmonAttributeMath.magic_mitigation_multiplier(0), 1.0), "WIS 0 = no reduction")
	ok(is_equal_approx(CrawlmonAttributeMath.magic_mitigation_multiplier(10), 0.5), "WIS 10 = half")
	ok(CrawlmonAttributeMath.mitigate_magic_damage(10, 10) == 5, "10 damage / WIS 10 = 5")
	ok(CrawlmonAttributeMath.mitigate_magic_damage(1, 100) == 1, "magic damage never reaches 0")

	var rng := RandomNumberGenerator.new()
	rng.seed = 1142
	var abra := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest", "rng": rng})
	var target := Combatant.new("Dummy", 9999, 0, 0.5, false)
	target.place(Vector3.ZERO, 0.0)
	var confusion := Skill.from_id(&"confusao")
	var tackle := Skill.from_id(&"tackle")

	target.wis = 0
	var magic_no_wis := Battle.estimate_damage(abra, target, confusion)
	target.wis = 10
	var magic_half := Battle.estimate_damage(abra, target, confusion)
	ok(magic_half == maxi(1, roundi(float(magic_no_wis) * 0.5)),
		"Confusion vs WIS 10 is half of WIS 0 (%d -> %d)" % [magic_no_wis, magic_half])

	target.wis = 0
	var phys_no_wis := Battle.estimate_damage(abra, target, tackle)
	target.wis = 10
	var phys_wis := Battle.estimate_damage(abra, target, tackle)
	ok(phys_wis == phys_no_wis, "WIS does not change physical damage")

	# Drain Spear already subtracts WIS in its own 5 + MAG - WIS formula; it must not be reduced twice.
	var drain := Skill.from_id(&"drain_spear")
	target.wis = 10
	ok(Battle.estimate_damage(abra, target, drain) == maxi(1, 5 + abra.mag - 10),
		"Drain Spear keeps its own 5 + MAG - WIS, without double mitigation")

	# The real hit path must match the estimate.
	var battle := Battle.new()
	battle.debug_roll = 1
	target.hp = 9999
	target.wis = 10
	var expected := Battle.estimate_damage(abra, target, confusion)
	var real := battle._hit(abra, target, confusion.power, confusion.element, confusion.display_name, false, false, {"move_data": confusion.data})
	ok(int(real.get("dmg", 0)) == expected, "Confusion _hit matches the WIS-mitigated estimate (%d)" % expected)

	print("D1142_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
