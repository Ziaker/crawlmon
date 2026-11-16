extends SceneTree
## D-1233/D-1234: unit tests for ExpeditionRoster (data only, no GameState autoload).

const Combatant = preload("res://scripts/combat/combatant.gd")
const Roster = preload("res://scripts/progression/expedition_roster.gd")

func _init() -> void:
	print("[TEST] Iniciando suite: test_expedition_roster.gd")
	var success := true

	success = success and _test_register_identity()
	success = success and _test_same_species_distinct_identity()
	success = success and _test_capacity()
	success = success and _test_move()
	success = success and _test_swap()
	success = success and _test_sync_active()
	success = success and _test_validate_problems()
	success = success and _test_employ_state()
	success = success and _test_recruited_in_battle()
	success = success and _test_participation()

	if success:
		print("EXPEDITION_ROSTER_TEST_PASS")
		quit(0)
	else:
		push_error("[TEST FAILURE] Um ou mais testes falharam.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
	return cond


func _fighter(p_name: String) -> Combatant:
	return Combatant.new(p_name, 20, 5, 1.0, true)


func _same_strings(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if String(a[i]) != String(b[i]):
			return false
	return true


func _test_register_identity() -> bool:
	var r := Roster.new()
	var a := _fighter("A")
	var b := _fighter("B")
	var uid_a := r.register(a, Roster.Place.ACTIVE)
	var uid_b := r.register(b, Roster.Place.ACTIVE)
	var ok := _assert_test(uid_a != "" and uid_b != "", "register gives non-empty uids")
	ok = ok and _assert_test(uid_a != uid_b, "register gives distinct uids")
	ok = ok and _assert_test(a.uid == uid_a and b.uid == uid_b, "combatants receive their uid")
	ok = ok and _assert_test(r.register(a, Roster.Place.ACTIVE) == uid_a, "same instance returns its uid")
	ok = ok and _assert_test(r.count(Roster.Place.ACTIVE) == 2, "registering twice does not duplicate")
	ok = ok and _assert_test(r.register(null, Roster.Place.ACTIVE) == "", "null register returns empty")
	ok = ok and _assert_test(r.validate().is_empty(), "roster is consistent")
	return ok


func _test_same_species_distinct_identity() -> bool:
	var r := Roster.new()
	var a := _fighter("Abra")
	a.species_id = "abra"
	var b := _fighter("Abra")
	b.species_id = "abra"
	var uid_a := r.register(a, Roster.Place.ACTIVE)
	var uid_b := r.register(b, Roster.Place.ACTIVE)
	var ok := _assert_test(uid_a != "", "first Abra registered")
	ok = ok and _assert_test(uid_b != "", "second Abra registered")
	ok = ok and _assert_test(uid_a != uid_b, "same species and name still get distinct uids")
	ok = ok and _assert_test(r.count(Roster.Place.ACTIVE) == 2, "both Abras are active")
	return ok


func _test_capacity() -> bool:
	var r := Roster.new()
	var ok := true
	for i in range(Roster.MAX_ACTIVE):
		ok = ok and _assert_test(r.register(_fighter("A%d" % i), Roster.Place.ACTIVE) != "", "active %d registered" % i)
	ok = ok and _assert_test(r.capacity_left(Roster.Place.ACTIVE) == 0, "ACTIVE has no room")
	var fourth := _fighter("Fourth")
	ok = ok and _assert_test(r.register(fourth, Roster.Place.ACTIVE) == "", "4th ACTIVE is rejected")
	ok = ok and _assert_test(fourth.uid == "", "rejected ACTIVE keeps an empty uid")
	ok = ok and _assert_test(r.count(Roster.Place.ACTIVE) == Roster.MAX_ACTIVE, "ACTIVE count unchanged")

	for i in range(Roster.MAX_SUBSTITUTES):
		ok = ok and _assert_test(r.register(_fighter("S%d" % i), Roster.Place.SUBSTITUTE) != "", "substitute %d registered" % i)
	ok = ok and _assert_test(r.capacity_left(Roster.Place.SUBSTITUTE) == 0, "SUBSTITUTE has no room")
	ok = ok and _assert_test(r.register(_fighter("S3"), Roster.Place.SUBSTITUTE) == "", "3rd SUBSTITUTE is rejected")

	for i in range(10):
		ok = ok and _assert_test(r.register(_fighter("St%d" % i), Roster.Place.STATIONED) != "", "stationed %d registered" % i)
	ok = ok and _assert_test(r.count(Roster.Place.STATIONED) == 10, "STATIONED accepts 10")
	ok = ok and _assert_test(r.capacity_left(Roster.Place.STATIONED) > 10, "STATIONED capacity is not capped")
	ok = ok and _assert_test(r.validate().is_empty(), "roster is consistent after capacity checks")
	return ok


func _test_move() -> bool:
	var r := Roster.new()
	var a := _fighter("A")
	var uid := r.register(a, Roster.Place.ACTIVE)
	var ok := _assert_test(r.move(uid, Roster.Place.STATIONED, {"map": "guild", "slot": 2}), "move to STATIONED")
	ok = ok and _assert_test(r.place_of(uid) == Roster.Place.STATIONED, "place is STATIONED")
	var info := r.station_info(uid)
	ok = ok and _assert_test(String(info.get("map", "")) == "guild" and int(info.get("slot", -1)) == 2, "station info stored")
	ok = ok and _assert_test(not r.move(uid, Roster.Place.STATIONED), "moving to the same place is false")
	ok = ok and _assert_test(not r.move("missing", Roster.Place.ACTIVE), "moving an unknown uid is false")
	ok = ok and _assert_test(r.move(uid, Roster.Place.ACTIVE), "move back to ACTIVE")
	ok = ok and _assert_test(r.station_info(uid).is_empty(), "station info erased when leaving STATIONED")

	r.register(_fighter("B"), Roster.Place.ACTIVE)
	r.register(_fighter("C"), Roster.Place.ACTIVE)
	var s := _fighter("S")
	var uid_s := r.register(s, Roster.Place.STATIONED)
	ok = ok and _assert_test(not r.move(uid_s, Roster.Place.ACTIVE), "moving to a full destination is false")
	ok = ok and _assert_test(r.place_of(uid_s) == Roster.Place.STATIONED, "full destination changes nothing")
	ok = ok and _assert_test(r.validate().is_empty(), "roster is consistent after moves")
	return ok


func _test_swap() -> bool:
	var r := Roster.new()
	var a := _fighter("A")
	var b := _fighter("B")
	var c := _fighter("C")
	var uid_a := r.register(a, Roster.Place.ACTIVE)
	var uid_b := r.register(b, Roster.Place.ACTIVE)
	var uid_c := r.register(c, Roster.Place.SUBSTITUTE)
	var ok := _assert_test(r.swap(uid_a, uid_c), "ACTIVE <-> SUBSTITUTE swap")
	ok = ok and _assert_test(r.place_of(uid_a) == Roster.Place.SUBSTITUTE, "first uid is now SUBSTITUTE")
	ok = ok and _assert_test(r.place_of(uid_c) == Roster.Place.ACTIVE, "second uid is now ACTIVE")
	ok = ok and _assert_test(a.uid == uid_a and c.uid == uid_c, "swap never changes uids")
	ok = ok and _assert_test(_same_strings(r.uids(Roster.Place.ACTIVE), [uid_c, uid_b]), "ACTIVE keeps the exchanged position")
	ok = ok and _assert_test(r.swap(uid_c, uid_b), "swap inside ACTIVE")
	ok = ok and _assert_test(_same_strings(r.uids(Roster.Place.ACTIVE), [uid_b, uid_c]), "ACTIVE order positions exchanged")
	ok = ok and _assert_test(not r.swap(uid_a, uid_a), "swap with itself is false")
	ok = ok and _assert_test(not r.swap(uid_a, "missing"), "swap with an unknown uid is false")
	ok = ok and _assert_test(a.uid == uid_a and b.uid == uid_b and c.uid == uid_c, "uids unchanged after every swap")
	ok = ok and _assert_test(r.validate().is_empty(), "roster is consistent after swaps")
	return ok


func _test_sync_active() -> bool:
	var r := Roster.new()
	var a := _fighter("A")
	var b := _fighter("B")
	r.sync_active([a, b])
	var uid_a := a.uid
	var uid_b := b.uid
	var ok := _assert_test(uid_a != "" and uid_b != "", "sync assigns uids")
	ok = ok and _assert_test(_same_strings(r.uids(Roster.Place.ACTIVE), [uid_a, uid_b]), "ACTIVE mirrors the party order")

	r.sync_active([b, a])
	ok = ok and _assert_test(a.uid == uid_a and b.uid == uid_b, "reordering the party keeps every uid")
	ok = ok and _assert_test(_same_strings(r.uids(Roster.Place.ACTIVE), [uid_b, uid_a]), "ACTIVE follows the new party order")

	var d := _fighter("D")
	r.sync_active([b, a, d])
	var uid_d := d.uid
	ok = ok and _assert_test(uid_d != "" and uid_d != uid_a and uid_d != uid_b, "new party member gets a new uid")

	r.sync_active([d])
	ok = ok and _assert_test(r.place_of(uid_d) == Roster.Place.ACTIVE, "kept member stays ACTIVE")
	ok = ok and _assert_test(r.place_of(uid_a) == Roster.Place.SUBSTITUTE, "removed member goes to SUBSTITUTE")
	ok = ok and _assert_test(r.place_of(uid_b) == Roster.Place.SUBSTITUTE, "second removed member goes to SUBSTITUTE")
	ok = ok and _assert_test(r.count(Roster.Place.SUBSTITUTE) == Roster.MAX_SUBSTITUTES, "SUBSTITUTE is full")

	var e := _fighter("E")
	r.sync_active([e])
	ok = ok and _assert_test(r.place_of(uid_d) == Roster.Place.STATIONED, "removed member with a full SUBSTITUTE is STATIONED")
	ok = ok and _assert_test(r.station_info(uid_d).is_empty(), "STATIONED fallback has empty info")
	ok = ok and _assert_test(r.place_of(uid_a) == Roster.Place.SUBSTITUTE, "earlier substitutes are untouched")
	ok = ok and _assert_test(r.validate().is_empty(), "roster is consistent after sync_active")

	# A substitute promoted in the same sync frees its room before the leaving member is placed.
	var r2 := Roster.new()
	var p1 := _fighter("P1")
	var s1 := _fighter("S1")
	var s2 := _fighter("S2")
	r2.register(p1, Roster.Place.ACTIVE)
	r2.register(s1, Roster.Place.SUBSTITUTE)
	r2.register(s2, Roster.Place.SUBSTITUTE)
	r2.sync_active([s1])
	ok = ok and _assert_test(r2.place_of(s1.uid) == Roster.Place.ACTIVE, "promoted substitute is ACTIVE")
	ok = ok and _assert_test(r2.place_of(p1.uid) == Roster.Place.SUBSTITUTE, "leaving member takes the freed SUBSTITUTE room")
	ok = ok and _assert_test(r2.validate().is_empty(), "roster is consistent after a promote+demote sync")
	return ok


func _test_validate_problems() -> bool:
	var r := Roster.new()
	var a := _fighter("A")
	var b := _fighter("B")
	var uid_a := r.register(a, Roster.Place.ACTIVE)
	r.register(b, Roster.Place.SUBSTITUTE)
	var ok := _assert_test(r.validate().is_empty(), "clean roster has no problems")

	var substitutes: Array = r._order[Roster.Place.SUBSTITUTE]
	substitutes.append(uid_a)
	var problems := r.validate()
	ok = ok and _assert_test(not problems.is_empty(), "a uid in two orders is reported")
	substitutes.erase(uid_a)
	ok = ok and _assert_test(r.validate().is_empty(), "roster is clean again after removing the duplicate")

	var overflow := Roster.new()
	var party: Array = []
	for i in range(Roster.MAX_ACTIVE + 1):
		party.append(_fighter("P%d" % i))
	overflow.sync_active(party)
	problems = overflow.validate()
	ok = ok and _assert_test(not problems.is_empty(), "ACTIVE over MAX_ACTIVE is reported")
	var mentions_active := false
	for problem in problems:
		if "ACTIVE" in String(problem):
			mentions_active = true
	ok = ok and _assert_test(mentions_active, "the overflow problem mentions ACTIVE")
	return ok


func _test_employ_state() -> bool:
	var r := Roster.new()
	r.register(_fighter("A"), Roster.Place.ACTIVE)
	var ok := _assert_test(not r.can_attempt_employ(), "Employ is blocked before a battle")
	r.begin_battle(0.0)
	ok = ok and _assert_test(r.can_attempt_employ(), "Employ is allowed inside a battle")
	r.mark_employ_failed()
	ok = ok and _assert_test(not r.can_attempt_employ(), "Employ is blocked after a failure")
	r.begin_battle(0.0)
	ok = ok and _assert_test(r.can_attempt_employ(), "a new battle reopens Employ")
	r.end_battle()
	ok = ok and _assert_test(not r.can_attempt_employ(), "a closed battle blocks Employ")
	return ok


func _test_recruited_in_battle() -> bool:
	var r := Roster.new()
	var a := _fighter("A")
	var uid_a := r.register(a, Roster.Place.ACTIVE)
	var b := _fighter("B")
	var uid_b := r.register(b, Roster.Place.SUBSTITUTE)
	r.begin_battle()
	r.mark_recruited_in_battle(uid_a)
	r.mark_recruited_in_battle(uid_a)
	r.mark_recruited_in_battle(uid_b)
	r.mark_recruited_in_battle("missing")
	var ok := _assert_test(_same_strings(r.recruited_in_battle(), [uid_a, uid_b]), "recruited list is unique and in order")
	r.begin_battle()
	ok = ok and _assert_test(r.recruited_in_battle().is_empty(), "begin_battle resets the recruited list")
	return ok


func _test_participation() -> bool:
	var r := Roster.new()
	var a := _fighter("A")
	var b := _fighter("B")
	var c := _fighter("C")
	var uid_a := r.register(a, Roster.Place.ACTIVE)
	var uid_b := r.register(b, Roster.Place.ACTIVE)
	var uid_c := r.register(c, Roster.Place.SUBSTITUTE)
	r.begin_battle(0.0)
	var ok := _assert_test(r.participation(uid_a).size() == 1, "begin_battle records an enter for actives")
	var first := r.participation(uid_a)[0] as Dictionary
	ok = ok and _assert_test(String(first.get("event", "")) == "enter" and float(first.get("t", -1.0)) == 0.0, "enter event carries event and time")
	ok = ok and _assert_test(r.participation(uid_c).is_empty(), "a substitute has no participation yet")

	r.note_leave(uid_a, 1.5)
	r.note_enter(uid_c, 2.0)
	r.note_leave(uid_a, 2.5)
	r.note_enter("missing", 3.0)
	ok = ok and _assert_test(r.participation(uid_a).size() == 3, "leave and enter events are appended")
	ok = ok and _assert_test(_same_strings(r.participants(), [uid_a, uid_b, uid_c]), "participants are in first-enter order")
	ok = ok and _assert_test(r.participation("missing").is_empty(), "an unknown uid has no participation")

	r.swap(uid_c, uid_b)
	ok = ok and _assert_test(r.participation(uid_c).size() == 1, "participation follows the uid after a swap")
	ok = ok and _assert_test(String((r.participation(uid_c)[0] as Dictionary).get("event", "")) == "enter", "the swapped member keeps its own event")

	r.end_battle()
	var before := r.participation(uid_b).size()
	r.note_enter(uid_b, 9.0)
	ok = ok and _assert_test(r.participation(uid_b).size() == before, "a closed battle ignores new notes")
	return ok
