extends SceneTree
## Headless verification for D-1223: automatic ally stat progression by combat proficiency,
## Nature, Tactics, 10-level milestones, max HP/MP recalculation, PostCombatFlow summaries,
## and D-235 symmetry.

var _failures: int = 0


func _init() -> void:
	print("[TEST] Starting D-1223 ally proficiency suite...")
	_test_proficiency_per_action_type()
	_test_zero_actions_nature_tactics_and_tiebreak()
	_test_milestone_level_10_non_monostat()
	_test_vit_wis_updates_max_hp_mp_on_level_up()
	_test_battle_hooks_and_d235_symmetry()
	_test_post_combat_flow_and_ui_no_double_add()
	if _failures > 0:
		printerr("[FAIL] D-1223 suite failed with %d assertion(s)." % _failures)
		quit(1)
	else:
		print("[PASS] D-1223 suite passed all assertions.")
		quit(0)


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		printerr("  [ASSERT FAIL] %s" % msg)


func _make_unit(unit_name: String, leader_flag: bool, nat: String) -> Combatant:
	var c := Combatant.new(unit_name, 40, 3, 1.0, leader_flag)
	c.species_id = "pancham"
	c.nature_id = nat
	c.innate_stats = {"STR": 3, "MAG": 2, "VIT": 3, "WIS": 2, "AGI": 2, "LUK": 3}
	c.progression_points = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
	c.proficiency_points = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
	c.level = 1
	c.xp = 0
	c.sync_effective_stats()
	c.update_resource_maximums()
	c.hp = c.max_hp
	c.mp = c.max_mp
	return c


func _test_proficiency_per_action_type() -> void:
	print("  -> Testing per-action proficiency winners...")
	for stat in ["STR", "MAG", "WIS", "VIT", "AGI", "LUK"]:
		var ally := _make_unit("Aliado_" + stat, false, "hardy")
		ally.record_proficiency(stat, 6)
		var res := ally.add_experience(100)
		_ok(int(res.get("levels_gained", 0)) >= 1, "ally leveled up for " + stat)
		var alloc: Dictionary = res.get("auto_alloc", {})
		_ok(int(alloc.get(stat, 0)) >= 1, "expected auto_alloc in %s, got %s" % [stat, str(alloc)])
		_ok(int(ally.proficiency_points.get(stat, -1)) == 0, "winner proficiency reset for " + stat)


func _test_zero_actions_nature_tactics_and_tiebreak() -> void:
	print("  -> Testing 0-action fallback to Nature, Tactics and tie-break...")
	# Modest gives +3 MAG -> +6 score on MAG even with 0 actions.
	var modest := _make_unit("ModestAlly", false, "modest")
	var res_mod := modest.add_experience(100)
	_ok(int((res_mod.get("auto_alloc", {}) as Dictionary).get("MAG", 0)) >= 1, "Modest 0-action picks MAG")
	_ok(String(res_mod.get("auto_reason", "")).begins_with("Nature"), "0-action reason mentions Nature")

	# Hardy has no positive mod; equal innate_stats tie-breaks by AUTO_STAT_ORDER (STR first),
	# unless Tactics boosts another stat (+1) or innate_stats has a unique peak.
	var hardy := _make_unit("HardyAlly", false, "hardy")
	hardy.innate_stats = {"STR": 2, "MAG": 2, "VIT": 2, "WIS": 5, "AGI": 2, "LUK": 2}
	hardy.sync_effective_stats()
	var res_hardy := hardy.add_experience(100)
	_ok(int((res_hardy.get("auto_alloc", {}) as Dictionary).get("WIS", 0)) >= 1, "Hardy 0-action picks highest innate stat WIS")

	# Equal innate_stats + Hardy -> deterministic canonical order -> STR.
	var tie_unit := _make_unit("TieAlly", false, "hardy")
	tie_unit.innate_stats = {"STR": 2, "MAG": 2, "VIT": 2, "WIS": 2, "AGI": 2, "LUK": 2}
	tie_unit.act_policy = Combatant.Act.HOLD
	tie_unit.sync_effective_stats()
	var res_tie := tie_unit.add_experience(100)
	_ok(int((res_tie.get("auto_alloc", {}) as Dictionary).get("STR", 0)) >= 1, "Hardy +2 on STR innate wins over +1 HOLD")


func _test_milestone_level_10_non_monostat() -> void:
	print("  -> Testing milestone level 10 (3 points) one-by-one without mono-stat...")
	var ally := _make_unit("MilestoneAlly", false, "hardy")
	ally.level = 9
	ally.proficiency_points = {"STR": 6, "MAG": 0, "VIT": 4, "WIS": 0, "AGI": 4, "LUK": 0}
	var req := CrawlmonAttributeMath.get_xp_for_level_transition(9)
	var res := ally.add_experience(req)
	_ok(int(res.get("new_level", 0)) == 10, "reached level 10")
	var alloc: Dictionary = res.get("auto_alloc", {})
	var total := 0
	for k in alloc:
		total += int(alloc[k])
	_ok(total == 3, "milestone level 10 allocated 3 points, got %d (%s)" % [total, str(alloc)])
	_ok(int(alloc.get("STR", 0)) == 1 and int(alloc.get("VIT", 0)) == 1 and int(alloc.get("AGI", 0)) == 1,
		"expected +1 STR, +1 VIT, +1 AGI on milestone, got %s" % str(alloc))


func _test_vit_wis_updates_max_hp_mp_on_level_up() -> void:
	print("  -> Testing VIT/WIS allocation updates max_hp/max_mp immediately...")
	var ally := _make_unit("TankAlly", false, "bold")  # Bold: +3 VIT
	ally.proficiency_points["VIT"] = 9
	var old_hp := ally.max_hp
	var req := CrawlmonAttributeMath.get_xp_for_level_transition(1)
	ally.add_experience(req)
	var expected_hp := CrawlmonAttributeMath.calculate_max_hp(2, ally.vit)
	_ok(ally.max_hp == expected_hp and ally.max_hp > old_hp,
		"max_hp (%d) matches calculate_max_hp(2, vit=%d) = %d" % [ally.max_hp, ally.vit, expected_hp])


func _test_battle_hooks_and_d235_symmetry() -> void:
	print("  -> Testing Battle proficiency hooks and D-235 symmetry...")
	var b := Battle.new()
	var a := _make_unit("A", false, "hardy")
	var foe := _make_unit("Foe", false, "hardy")
	var party_arr: Array[Combatant] = [a]
	var enemy_arr: Array[Combatant] = [foe]
	b.start(party_arr, enemy_arr)

	# Guard -> +3 VIT
	a.atb = 5.0
	_ok(b.use_guard(a), "guard succeeds")
	_ok(int(a.proficiency_points["VIT"]) == 3, "guard recorded +3 VIT")

	# Direct damage -> +1 VIT on target; bounce -> 0
	b._hit(foe, a, 1.0, Element.Type.FISICO, "Tackle", false, false, {})
	_ok(int(a.proficiency_points["VIT"]) == 4, "direct hit recorded +1 VIT on target")
	b._hit(foe, a, 1.0, Element.Type.FISICO, "Bounce", false, false, {"bounce": true})
	_ok(int(a.proficiency_points["VIT"]) == 4, "bounce did NOT record extra VIT")

	# Auto-dodge -> +3 AGI on target
	b._hit(foe, a, 1.0, Element.Type.FISICO, "Tackle", false, true, {})
	_ok(int(a.proficiency_points["AGI"]) == 3, "auto_dodged recorded +3 AGI")

	# Crit -> +2 LUK on attacker
	b.debug_roll = 3
	b._hit(a, foe, 1.0, Element.Type.FISICO, "Tackle", false, false, {})
	_ok(int(a.proficiency_points["LUK"]) == 2, "crit recorded +2 LUK")
	b.debug_roll = 0

	# Status move -> +3 WIS on attacker
	var inc := Incoming.new()
	inc.attacker = a
	inc.target = a
	inc.kind = Skill.Kind.STATUS
	inc.label = "Heal"
	b._execute_status_move(inc)
	_ok(int(a.proficiency_points["WIS"]) == 3, "status move recorded +3 WIS")

	# step() must NOT record proficiency
	var agi_before := int(a.proficiency_points["AGI"])
	a.atb = 5.0
	b.step(a, 1)
	_ok(int(a.proficiency_points["AGI"]) == agi_before, "step() must not record AGI proficiency")
	b.free()


func _test_post_combat_flow_and_ui_no_double_add() -> void:
	print("  -> Testing PostCombatFlow summary and PostCombatScreen display parity...")
	var leader := _make_unit("Abra", true, "modest")
	var ally := _make_unit("Pancham", false, "brave")
	ally.proficiency_points["STR"] = 6
	var old_str := ally.get_effective_stat("STR")
	var req := CrawlmonAttributeMath.get_xp_for_level_transition(1)
	var summaries := PostCombatFlow.grant_xp([leader, ally], req)
	_ok(summaries.size() == 2, "two summaries returned")
	var ally_sm: Dictionary = summaries[1]
	_ok(int((ally_sm.get("auto_alloc", {}) as Dictionary).get("STR", 0)) == 1, "ally summary has auto_alloc STR: 1")
	_ok(String(ally_sm.get("auto_reason", "")) != "", "ally summary has auto_reason")
	_ok(int((ally_sm.get("old_stats", {}) as Dictionary).get("STR", 0)) == old_str, "old_stats preserved pre-allocation STR")
	_ok(ally.get_effective_stat("STR") == old_str + 1, "ally effective STR incremented by exactly 1")
