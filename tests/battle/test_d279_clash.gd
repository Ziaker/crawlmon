extends SceneTree
## D-279: two opposing runners that meet clash (bump hop). Mutual (A->B and B->A): both strike from
## there; different targets: both give up and go home; runners of the same team never clash.
##   godot --headless --path . --script res://tests/battle/test_d279_clash.gd

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


func _tackle() -> Skill:
	return Skill.new("Tackle", 1.0, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.5)


func _world() -> Dictionary:
	var battle := Battle.new()
	var a1 := _mk("A1", true, Vector3(0, 0, 0), PI)
	var a2 := _mk("A2", true, Vector3(2, 0, 0), PI)
	var e1 := _mk("E1", false, Vector3(0, 0, -30), 0.0)
	var e2 := _mk("E2", false, Vector3(2, 0, -30), 0.0)
	var party: Array[Combatant] = [a1, a2]
	var foes: Array[Combatant] = [e1, e2]
	battle.start(party, foes)
	for c in party + foes:
		c.atb = 6.0
	battle.debug_roll = 1
	return {"b": battle, "a1": a1, "a2": a2, "e1": e1, "e2": e2}


func _run() -> void:
	seed(5)
	_test_mutual()
	_test_different_targets()
	_test_same_team()
	print("D279_TEST_" + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)


func _test_mutual() -> void:
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a1"]
	var e: Combatant = w["e1"]
	var clashes := [0, false]
	b.attack_clashed.connect(func(_x, _y, _p, mutual: bool) -> void:
		clashes[0] += 1
		clashes[1] = mutual)
	b.use_skill(a, _tackle(), e)
	b.use_skill(e, _tackle(), a)
	var peak := 0.0
	var sep_after := 0.0
	var pa := a.pos
	var pe := e.pos
	var t := 0.0
	while t < 8.0:
		b._process(DT)
		if clashes[0] > 0:
			peak = maxf(peak, maxf((a.pos - pa).length(), (e.pos - pe).length()) / DT)
			sep_after = maxf(sep_after, a.pos.distance_to(e.pos))
		pa = a.pos
		pe = e.pos
		t += DT
	_expect(clashes[0] == 1 and clashes[1], "o choque recíproco acontece uma vez (%d)" % clashes[0])
	_expect(sep_after > 5.5, "depois do choque os dois se afastam (separação máx. %.1f)" % sep_after)
	_expect(peak < 60.0, "sem arrancos depois do choque (pico %.0f u/s)" % peak)
	_expect(e.hp < e.max_hp or a.hp < a.max_hp, "os golpes saem depois do pulinho")
	_expect(a.pos.distance_to(a.stand_pos()) < 0.01 and e.pos.distance_to(e.stand_pos()) < 0.01, "os dois voltam à origem")


func _test_different_targets() -> void:
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a1"]
	var e: Combatant = w["e1"]
	var a2: Combatant = w["a2"]
	var e2: Combatant = w["e2"]
	var clashes := [0, true]
	b.attack_clashed.connect(func(_x, _y, _p, mutual: bool) -> void:
		clashes[0] += 1
		clashes[1] = mutual)
	b.use_skill(a, _tackle(), e2)  # A1 -> E2 and E1 -> A2: they cross
	b.use_skill(e, _tackle(), a2)
	var t := 0.0
	while t < 8.0:
		b._process(DT)
		t += DT
	_expect(clashes[0] >= 1 and not clashes[1], "o cruzamento de alvos distintos também é choque")
	_expect(e2.hp == e2.max_hp and a2.hp == a2.max_hp, "ninguém é atingido: os dois cancelam")
	_expect(a.pos.distance_to(a.stand_pos()) < 0.01 and e.pos.distance_to(e.stand_pos()) < 0.01, "os dois voltam à origem")


func _test_same_team() -> void:
	var w := _world()
	var b: Battle = w["b"]
	var clashes := [0]
	b.attack_clashed.connect(func(_x, _y, _p, _m: bool) -> void: clashes[0] += 1)
	b.use_skill(w["a1"], _tackle(), w["e1"])
	b.use_skill(w["a2"], _tackle(), w["e1"])
	var t := 0.0
	while t < 8.0:
		b._process(DT)
		t += DT
	_expect(clashes[0] == 0, "aliados correndo no mesmo alvo não se chocam")
