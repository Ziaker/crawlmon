extends SceneTree
## D-1229/D-1257: unit tests for EmployRhythm (pure logic, injected clock) and its
## integration with Battle.employ_chance().

const EmployRhythm = preload("res://scripts/progression/employ_rhythm.gd")


func _init() -> void:
	print("[TEST] Starting suite: test_employ_rhythm.gd")
	var success := true

	success = success and _test_note_count()
	success = success and _test_grade_borders()
	success = success and _test_press_borders()
	success = success and _test_miss_after_window()
	success = success and _test_nearest_note()
	success = success and _test_press_outside_window()
	success = success and _test_bonuses_and_total()
	success = success and _test_finished_and_summary()
	success = success and _test_battle_integration()

	if success:
		print("EMPLOY_RHYTHM_TEST_PASS")
		quit(0)
	else:
		push_error("[TEST FAILURE] One or more EmployRhythm tests failed.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
	return cond


func _test_note_count() -> bool:
	var ok := true
	var expected := [1, 1, 2, 3, 3, 3]
	for members in range(0, 6):
		ok = _assert_test(EmployRhythm.note_count(members) == expected[members],
			"note_count(%d) = %d" % [members, expected[members]]) and ok
	return ok


func _test_grade_borders() -> bool:
	var ok := true
	ok = _assert_test(EmployRhythm.grade_for(59.0) == "perfect", "59 ms is perfect") and ok
	ok = _assert_test(EmployRhythm.grade_for(60.0) == "perfect", "60 ms is perfect") and ok
	ok = _assert_test(EmployRhythm.grade_for(61.0) == "good", "61 ms is good") and ok
	ok = _assert_test(EmployRhythm.grade_for(129.0) == "good", "129 ms is good") and ok
	ok = _assert_test(EmployRhythm.grade_for(130.0) == "good", "130 ms is good") and ok
	ok = _assert_test(EmployRhythm.grade_for(131.0) == "", "131 ms is outside the window") and ok
	return ok

func _test_press_borders() -> bool:
	var ok := true
	var rhythm := EmployRhythm.new()
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.grades() == ["pending"], "setup starts every note as pending") and ok
	ok = _assert_test(rhythm.press(1059.0)["grade"] == "perfect", "59 ms early is perfect") and ok
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.press(1060.0)["grade"] == "perfect", "60 ms late is perfect") and ok
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.press(1061.0)["grade"] == "good", "61 ms late is good") and ok
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.press(1129.0)["grade"] == "good", "129 ms late is good") and ok
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.press(1130.0)["grade"] == "good", "130 ms late is good") and ok
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.press(1131.0).is_empty(), "131 ms late hits nothing") and ok
	var hit := rhythm.press(1000.0)
	ok = _assert_test(int(hit.get("note", -1)) == 0, "press reports the note index") and ok
	ok = _assert_test(is_equal_approx(float(hit.get("delta_ms", 0.0)), 0.0), "press reports delta_ms") and ok
	return ok


func _test_miss_after_window() -> bool:
	var ok := true
	var rhythm := EmployRhythm.new()
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.update(1129.0).is_empty(), "1129 ms does not miss yet") and ok
	ok = _assert_test(rhythm.update(1130.0).is_empty(), "130 ms is still inside the window") and ok
	ok = _assert_test(rhythm.grades() == ["pending"], "the note is still pending at 130 ms") and ok
	ok = _assert_test(rhythm.update(1131.0) == [0], "131 ms marks the note as missed") and ok
	ok = _assert_test(rhythm.grades() == ["miss"], "the miss is stored") and ok
	ok = _assert_test(rhythm.is_finished(), "no pending note is left") and ok
	ok = _assert_test(is_equal_approx(rhythm.total_bonus(), 0.0), "a miss pays 0 pp") and ok
	return ok

func _test_nearest_note() -> bool:
	var ok := true
	var rhythm := EmployRhythm.new()
	rhythm.setup([1000.0, 1100.0])
	var hit := rhythm.press(1090.0)
	ok = _assert_test(int(hit.get("note", -1)) == 1, "the closest note wins") and ok
	ok = _assert_test(hit["grade"] == "perfect", "-10 ms is perfect") and ok
	ok = _assert_test(rhythm.grades() == ["pending", "perfect"], "only the hit note changed") and ok
	hit = rhythm.press(1010.0)
	ok = _assert_test(int(hit.get("note", -1)) == 0, "the remaining note is hit") and ok
	ok = _assert_test(rhythm.is_finished(), "both notes are resolved") and ok
	return ok


func _test_press_outside_window() -> bool:
	var ok := true
	var rhythm := EmployRhythm.new()
	rhythm.setup([1000.0])
	ok = _assert_test(rhythm.press(1200.0).is_empty(), "a late press outside every window returns {}") and ok
	ok = _assert_test(rhythm.press(800.0).is_empty(), "an early press outside the window returns {}") and ok
	ok = _assert_test(rhythm.grades() == ["pending"], "ignored presses keep the note pending") and ok
	return ok


func _test_bonuses_and_total() -> bool:
	var ok := true
	var rhythm := EmployRhythm.new()
	rhythm.setup([1000.0, 1300.0, 1600.0])
	rhythm.press(1000.0)
	rhythm.press(1370.0)
	rhythm.update(1800.0)
	ok = _assert_test(rhythm.grades() == ["perfect", "good", "miss"], "perfect + good + miss") and ok
	ok = _assert_test(rhythm.bonuses() == [10.0, 5.0, 0.0], "bonuses are 10/5/0 in note order") and ok
	ok = _assert_test(is_equal_approx(rhythm.total_bonus(), 15.0), "total is 15 pp") and ok
	return ok

func _test_finished_and_summary() -> bool:
	var ok := true
	var rhythm := EmployRhythm.new()
	rhythm.setup([1000.0, 1300.0, 1600.0])
	ok = _assert_test(not rhythm.is_finished(), "a pending note means not finished") and ok
	rhythm.press(1300.0)
	ok = _assert_test(rhythm.grades() == ["pending", "perfect", "pending"], "the middle note is hit") and ok
	rhythm.press(1600.0)
	rhythm.press(1000.0)
	ok = _assert_test(rhythm.is_finished(), "all notes are resolved") and ok
	var summary := rhythm.summary()
	ok = _assert_test(summary["grades"] == ["perfect", "perfect", "perfect"], "summary grades") and ok
	ok = _assert_test(summary["bonuses"] == [10.0, 10.0, 10.0], "summary bonuses") and ok
	ok = _assert_test(is_equal_approx(float(summary["total_pp"]), 30.0), "summary total_pp") and ok
	return ok


func _test_battle_integration() -> bool:
	var ok := true
	var battle := Battle.new()
	var ally := Combatant.new("Hero", 40, 3, 1.0, true)
	var foe := Combatant.new("Foe", 40, 3, 1.0, false)
	for c in [ally, foe]:
		c.str = 10
		c.mag = 10
		c.level = 5
	var party_arr: Array[Combatant] = [ally]
	var enemy_arr: Array[Combatant] = [foe]
	battle.start(party_arr, enemy_arr)

	var without := battle.employ_chance(ally, foe)
	var with_rhythm := battle.employ_chance(ally, foe, [10.0, 5.0, 0.0])
	ok = _assert_test(is_equal_approx(float(without["rhythm_pp"]), 0.0), "no bonus means rhythm_pp 0") and ok
	ok = _assert_test(is_equal_approx(float(with_rhythm["rhythm_pp"]), 15.0), "rhythm_pp sums the notes") and ok
	ok = _assert_test(with_rhythm["note_bonuses"] == [10.0, 5.0, 0.0], "note_bonuses are returned") and ok
	ok = _assert_test(float(without["P"]) > 0.0 and float(without["P"]) < 100.0, "the no-bonus chance is not clamped") and ok
	var delta: float = float(with_rhythm["P"]) - float(without["P"])
	ok = _assert_test(is_equal_approx(delta, 15.0), "the bonus raises P by exactly 15 pp") and ok
	battle.free()
	return ok