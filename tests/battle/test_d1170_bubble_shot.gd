extends SceneTree
## D-1170: Bubble Shot — magical Water projectile, 100% MAG, 2 ATB / 3 MP,
## 0.7 s wind-up, single target, no extra effect.
## Run: godot --headless --path . --script res://tests/battle/test_d1170_bubble_shot.gd
var _f := 0


func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c:
		_f += 1


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1170
	var slime := EnemyFactory.create_enemy("dqt_slime", rng, "hardy")
	var abra := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest", "rng": rng})

	var bubble := Skill.from_id(&"bubble_shot")
	ok(bubble != null, "Bubble Shot exists in the catalog")
	ok(bubble.cost == 2, "2 ATB (%d)" % bubble.cost)
	ok(bubble.mp_cost == 3, "3 MP (%d)" % bubble.mp_cost)
	ok(is_equal_approx(bubble.windup, 0.7), "0.7 s wind-up (%s)" % str(bubble.windup))
	ok(is_equal_approx(bubble.power, 1.0), "100%% power (%s)" % str(bubble.power))
	ok(bubble.kind == Skill.Kind.PROJECTILE, "Projectile")
	ok(bubble.element == Element.Type.AGUA_GELO, "Water element")
	ok(bubble.is_magical(), "Magical (scales with MAG)")
	ok(bubble.type_icon_name() == "magical", "Type icon is Magical")
	ok(not bubble.is_aoe and not bubble.is_friendly, "Single enemy target")
	ok(bubble.data != null and bubble.data.tags.is_empty(), "No extra-effect tags")
	for text in [bubble.data.effect_line_text, bubble.data.description_text, bubble.data.mechanics_text,
			bubble.data.visual_text, bubble.data.tactical_text, bubble.data.short_effect_text]:
		ok(text.to_lower().find("ice") == -1 and text.to_lower().find("frost") == -1,
			"No ice wording (D-397): %s" % text.left(40))

	# Real hit path: MAG x 1.0, no WIS.
	var dummy := Combatant.new("Dummy", 9999, 0, 0.5, false)
	dummy.place(Vector3.ZERO, 0.0)
	dummy.wis = 0
	var battle := Battle.new()
	battle.debug_roll = 1
	var expected := maxi(1, roundi(float(slime.mag) * 1.0))
	ok(Battle.estimate_damage(slime, dummy, bubble) == expected, "Estimate uses MAG x 1.0 (%d)" % expected)
	var hit := battle._hit(slime, dummy, bubble.power, bubble.element, bubble.display_name, false, false, {"move_data": bubble.data})
	ok(int(hit.get("dmg", 0)) == expected, "Hit uses MAG x 1.0 (%d)" % int(hit.get("dmg", 0)))
	ok(dummy.stun_timer <= 0.0, "No STUN applied")

	# D-1142: WIS mitigates it like any magical Move.
	dummy.wis = 10
	var mitigated := maxi(1, roundi(float(expected) * 10.0 / 20.0))
	ok(Battle.estimate_damage(slime, dummy, bubble) == mitigated, "WIS 10 halves it (%d)" % mitigated)

	# ATK buffs are physical only (D-1140).
	dummy.wis = 0
	slime.buff_stat("attack", 2)
	ok(Battle.estimate_damage(slime, dummy, bubble) == expected, "+2 ATK does not change it")

	# Any caster (D-235).
	var expected_abra := maxi(1, roundi(float(abra.mag) * 1.0))
	ok(Battle.estimate_damage(abra, dummy, bubble) == expected_abra, "Another caster uses its own MAG (%d)" % expected_abra)

	print("D1170_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
