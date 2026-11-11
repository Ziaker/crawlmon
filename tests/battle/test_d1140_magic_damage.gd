extends SceneTree
var _f := 0
func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c: _f += 1
func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1132
	var abra := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest", "rng": rng})
	var pancham := CharacterFactory.create("pancham", {"is_player": true, "forced_nature": "brave", "rng": rng})
	var slime := EnemyFactory.create_enemy("dqt_slime", rng, "hardy")
	slime.wis = 0  # D-1142 covers WIS mitigation; this test isolates the MAG scaling.

	for move_id in [&"confusao", &"raio_psiquico", &"onda_choque", &"teleporte_rapido", &"megido"]:
		var skill := Skill.from_id(move_id)
		ok(skill != null and skill.is_magical(), "Move '%s' is magical" % move_id)
	var tackle := Skill.from_id(&"tackle")
	ok(tackle != null and not tackle.is_magical(), "Tackle is physical")
	var media := Skill.from_id(&"media")
	ok(media != null and Battle.estimate_damage(abra, slime, media) == 0, "Media is not a damage move (estimate 0)")

	var confusion := Skill.from_id(&"confusao")
	var expected_magic := maxi(1, roundi(float(abra.mag) * confusion.power))
	ok(Battle.estimate_damage(abra, slime, confusion) == expected_magic,
		"Confusion estimate uses MAG (%d)" % expected_magic)
	var battle := Battle.new()
	battle.debug_roll = 1
	var hit := battle._hit(abra, slime, confusion.power, confusion.element, "Confusion", false, false, {"move_data": confusion.data})
	ok(int(hit.get("dmg", 0)) == expected_magic, "Confusion hit uses MAG (%d)" % int(hit.get("dmg", 0)))

	# D-1140: each of Abra's five damaging Moves must use MAG in the real hit path,
	# including Teleport (MELEE) and Shock Wave (CAST), which the old kind heuristic missed.
	var dummy := Combatant.new("Dummy", 9999, 0, 0.5, false)
	dummy.place(Vector3.ZERO, 0.0)
	for move_id in [&"confusao", &"raio_psiquico", &"onda_choque", &"teleporte_rapido", &"megido"]:
		var sk := Skill.from_id(move_id)
		var expected := Battle.estimate_damage(abra, dummy, sk)
		var real := battle._hit(abra, dummy, sk.power, sk.element, sk.display_name, false, false, {"move_data": sk.data})
		ok(int(real.get("dmg", 0)) == expected,
			"%s hit uses MAG (%d)" % [sk.display_name, int(real.get("dmg", 0))])

	var expected_physical := maxi(1, roundi(float(pancham.attack) * tackle.power))
	ok(Battle.estimate_damage(pancham, slime, tackle) == expected_physical,
		"Pancham's physical estimate uses attack (%d)" % expected_physical)

	abra.buff_stat("attack", 2)
	ok(Battle.estimate_damage(abra, slime, confusion) == expected_magic,
		"+2 ATK does not change the magic estimate")

	print("D1140_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
