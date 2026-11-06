extends SceneTree
## D-282: in its idle after a melee strike a character does not hop home while another melee attack
## is striking it (no teleport at the impact); it is released at the impact, and may Evade/Guard.
##   godot --headless --path . --script res://tests/battle/test_d282_prison.gd

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


## A1 attacks E 0.7 s after E started a Tackle at A2, so A1 strikes while E is idle after its own hit.
func _world() -> Dictionary:
	var battle := Battle.new()
	var a1 := _mk("A1", true, Vector3(0, 0, 0), PI)
	var a2 := _mk("A2", true, Vector3(8, 0, 0), PI)
	var e := _mk("E", false, Vector3(0, 0, -30), 0.0)
	var party: Array[Combatant] = [a1, a2]
	var foes: Array[Combatant] = [e]
	battle.start(party, foes)
	for c in party + foes:
		c.atb = 6.0
	battle.debug_roll = 1
	return {"b": battle, "a1": a1, "a2": a2, "e": e}


func _run() -> void:
	seed(9)
	_test_held_until_impact()
	_test_evade_while_held()
	print("D282_TEST_" + ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)


func _test_held_until_impact() -> void:
	var w := _world()
	var b: Battle = w["b"]
	var a1: Combatant = w["a1"]
	var e: Combatant = w["e"]
	b.use_skill(e, _tackle(), w["a2"])
	var impact_t := [-1.0]
	var hop_t := [-1.0]
	var peak := 0.0
	var pa := a1.pos
	var t := 0.0
	var started := false
	var held_seen := false
	while t < 9.0:
		if not started and t >= 0.7:
			b.use_skill(a1, _tackle(), e)
			started = true
		b._process(DT)
		if b.is_held(e):
			held_seen = true
		for inc in b._returning:
			if inc.attacker == e and inc.phase == Incoming.Phase.RETURN and inc.phase_time > inc.hold + 0.01 and hop_t[0] < 0.0 and not inc.interrupted:
				hop_t[0] = t
		for inc in b._returning:
			if inc.attacker == a1 and inc.impacted and impact_t[0] < 0.0:
				impact_t[0] = t
		peak = maxf(peak, (a1.pos - pa).length() / DT)
		pa = a1.pos
		t += DT
	_expect(held_seen, "o alvo fica preso no idle enquanto o outro golpeia")
	_expect(peak < 60.0, "sem teleporte do atacante no impacto (pico %.0f u/s)" % peak)
	_expect(impact_t[0] > 0.0 and (hop_t[0] < 0.0 or hop_t[0] >= impact_t[0] - 0.05), "o alvo só pula depois do impacto do outro (impacto %.2f, pulo %.2f)" % [impact_t[0], hop_t[0]])
	_expect(a1.hp == a1.max_hp and e.hp < e.max_hp, "o golpe do outro acerta o alvo preso")
	_expect(e.pos.distance_to(e.stand_pos()) < 0.01 and a1.pos.distance_to(a1.stand_pos()) < 0.01, "os dois voltam à origem")


func _test_evade_while_held() -> void:
	var w := _world()
	var b: Battle = w["b"]
	var a1: Combatant = w["a1"]
	var e: Combatant = w["e"]
	b.use_skill(e, _tackle(), w["a2"])
	var t := 0.0
	var started := false
	var evaded := false
	while t < 9.0:
		if not started and t >= 0.7:
			b.use_skill(a1, _tackle(), e)
			started = true
		b._process(DT)
		if not evaded and b.is_held(e):
			var inc := b.find_evadable(e)
			if inc != null and b.try_evade(e, inc):
				evaded = true
		t += DT
	_expect(evaded, "preso, o alvo consegue usar Evade manual")
	_expect(e.hp == e.max_hp, "o golpe desviado não acerta")
