extends SceneTree
## D-285: the AI raises its Guard near the impact, so the shield is up when the hit lands.
## D-286: a target that moves during the strike is reached by a capped slide, never a jump.
##   godot --headless --path . --script res://tests/battle/test_d285_d286.gd

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


func _bullet() -> Skill:
	return Skill.new("Fire Bullet", 1.0, 1, Element.Type.FOGO, Skill.Kind.PROJECTILE, false, false, false, 0.5)


func _run() -> void:
	seed(21)
	_test_ai_guard_timing()
	_test_target_pushed()
	print("D285_D286_TEST_" + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)


func _test_ai_guard_timing() -> void:
	var started := 0
	var blocked := 0
	for i in 40:
		var b := Battle.new()
		var a := _mk("A", true, Vector3(0, 0, 0), PI)
		var party_extra := _mk("P2", true, Vector3(8, 0, 0), PI)
		var e := _mk("E", false, Vector3(0, 0, -30), 0.0)
		e.react_policy = Combatant.React.EVADE
		var party: Array[Combatant] = [party_extra, a]  # the leader is party[0]: the AI never plays for it
		var foes: Array[Combatant] = [e]
		b.start(party, foes)
		for c in party + foes:
			c.atb = 6.0
		b.debug_roll = 1
		var info := [0, 0]
		b.guard_started.connect(func(_c: Combatant) -> void: info[0] += 1)
		b.guard_ended.connect(func(_c: Combatant, reason: String) -> void:
			if reason == "hit":
				info[1] += 1)
		b.use_skill(a, _tackle(), e)
		var t := 0.0
		while t < 8.0:
			b._process(DT)
			t += DT
		started += info[0]
		blocked += info[1]
		b.free()
	_expect(started > 0, "a IA levanta o Guard em alguns ataques (%d de 40)" % started)
	_expect(started == blocked, "todo Guard da IA está de pé quando o golpe chega (%d de %d bloqueiam)" % [blocked, started])


func _test_target_pushed() -> void:
	var b := Battle.new()
	var a1 := _mk("A1", true, Vector3(0, 0, 0), PI)
	var a2 := _mk("A2", true, Vector3(8, 0, 0), PI)
	var e := _mk("E", false, Vector3(0, 0, -30), 0.0)
	var party: Array[Combatant] = [a1, a2]
	var foes: Array[Combatant] = [e]
	b.start(party, foes)
	for c in party + foes:
		c.atb = 6.0
	b.debug_roll = 1
	b.use_skill(a1, _tackle(), e)
	var peak := 0.0
	var pa := a1.pos
	var shot := false
	var t := 0.0
	while t < 9.0:
		if not shot and t >= 1.9:
			b.use_skill(a2, _bullet(), e)  # pushes E back while A1 waits to strike
			shot = true
		b._process(DT)
		var striking := false  # (the hop home after the hit is fast by design; only the way in and the strike count)
		for inc in b._landing:
			if inc.attacker == a1:
				striking = true
		if striking:
			peak = maxf(peak, (a1.pos - pa).length() / DT)
		pa = a1.pos
		t += DT
	_expect(peak < 60.0, "alvo empurrado no meio do golpe: o atacante não teleporta (pico %.0f u/s)" % peak)
	_expect(e.hp < e.max_hp, "o golpe ainda acerta")
