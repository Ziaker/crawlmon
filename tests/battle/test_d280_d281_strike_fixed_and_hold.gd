extends SceneTree
## D-280: the strike path is fixed (two attackers striking at once never drag each other).
## D-281: the five 1.5 s melee moves wait 0.7 s at the target before hopping back; others keep 0.2 s.
##   godot --headless --path . --script res://tests/battle/test_d280_d281_strike_fixed_and_hold.gd

const DT := 1.0 / 60.0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		failures += 1


func _mk(n: String, player: bool, p: Vector3, yaw: float) -> Combatant:
	var c := Combatant.new(n, 100, 10, 0.5, player)
	c.place(p, yaw)
	c.act_policy = Combatant.Act.HOLD
	c.react_policy = Combatant.React.NONE
	c.clips = {"attack": 1.7}
	return c


func _run() -> void:
	seed(7)
	_test_no_drag()
	for name in ["Tackle", "Brick Break", "Dragon Claw", "Hassou Tobi", "Titanomachia"]:
		_test_hold(name, 0.7)
	for name in ["Karate Chop", "Mach Punch"]:
		_test_hold(name, 0.2)
	print("D280_D281_TEST_" + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)


func _skill(name: String) -> Skill:
	var wind := {"Tackle": 1.5, "Brick Break": 1.5, "Dragon Claw": 1.5, "Hassou Tobi": 1.5, "Titanomachia": 1.5, "Karate Chop": 1.0, "Mach Punch": 0.2}
	return Skill.new(name, 1.0, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, wind[name])


func _test_hold(move: String, expected: float) -> void:
	var battle := Battle.new()
	var a := _mk("A", true, Vector3(0, 0, 0), PI)
	var b := _mk("B", false, Vector3(0, 0, -30), 0.0)
	var party: Array[Combatant] = [a]
	var foes: Array[Combatant] = [b]
	battle.start(party, foes)
	a.atb = 6.0
	battle.debug_roll = 1
	battle.use_skill(a, _skill(move), b)
	var t := 0.0
	var inc: Incoming = null
	while t < 8.0:
		battle._process(DT)
		if inc == null and not battle._landing.is_empty():
			inc = battle._landing[0]
		t += DT
	_expect(inc != null and absf(inc.hold - expected) < 0.001, "%s espera %.1f s no alvo (hold=%s)" % [move, expected, str(inc.hold) if inc else "?"])


func _test_no_drag() -> void:
	var battle := Battle.new()
	var a := _mk("A", true, Vector3(0, 0, 0), PI)
	var b := _mk("B", false, Vector3(0, 0, -30), 0.0)
	var party: Array[Combatant] = [a]
	var foes: Array[Combatant] = [b]
	battle.start(party, foes)
	a.atb = 6.0
	b.atb = 6.0
	battle.debug_roll = 1
	battle.use_skill(a, _skill("Tackle"), b)
	var started_b := false
	var t := 0.0
	var mid_first := Vector3.ZERO
	var mid_last := Vector3.ZERO
	var seen := false
	while t < 7.0:
		if not started_b and t >= 0.5:
			battle.use_skill(b, _skill("Tackle"), a)
			started_b = true
		battle._process(DT)
		# Both striking at once: the pair must not travel together (before any hit lands).
		var striking := true
		for inc in battle._landing:
			striking = striking and inc.phase == Incoming.Phase.STRIKE
		if battle._landing.size() == 2 and striking:
			mid_last = (a.pos + b.pos) * 0.5
			if not seen:
				seen = true
				mid_first = mid_last
		t += DT
	var drift := mid_first.distance_to(mid_last)
	_expect(seen and drift < 1.0, "dois golpes ao mesmo tempo não se arrastam (deriva do par %.2f un; antes: ~8)" % drift)
