extends SceneTree
## D-1168: with two dodgeable attacks, the one whose Dread is lit must win the press.
## Runs with: godot --headless --path . --script res://tests/battle/test_d1165_dread_target.gd

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _fake(a: Combatant, t: Combatant, phase: int, resolved: bool, phase_time: float) -> Incoming:
	var inc := Incoming.new()
	inc.attacker = a
	inc.target = t
	inc.label = "Teste"
	inc.kind = Skill.Kind.MELEE
	inc.motion = "melee"
	inc.resolved = resolved
	inc.phase = phase
	inc.impact_phase = Incoming.Phase.STRIKE
	inc.plan = [[Incoming.Phase.STRIKE, 1.0]]
	inc.plan_i = 0
	inc.phase_time = phase_time
	return inc


func _run() -> void:
	print("=================================================================")
	print("   CRAWMON — DREAD ESCOLHE O ATAQUE CERTO (D-1168)")
	print("=================================================================")
	var b := Battle.new()
	var leader := Combatant.new("Líder", 100, 10, 0.5, true)
	var e1 := Combatant.new("Inimigo 1", 100, 10, 0.5, false)
	var e2 := Combatant.new("Inimigo 2", 100, 10, 0.5, false)
	b.start([leader], [e1, e2])
	leader.atb = 5.0
	leader.mp = 20
	var windup := _fake(e1, leader, Incoming.Phase.WINDUP, false, 0.0)
	var dread := _fake(e2, leader, Incoming.Phase.STRIKE, true, 0.5)
	b.incoming.append(windup)
	b._landing.append(dread)
	_expect(windup.can_dodge_now(), "O ataque em wind-up é aceito pelo botão (D-1006)")
	_expect(dread.can_evade_now(), "O segundo ataque está na janela do Dread")
	var found := b.find_evadable(leader)
	_expect(found == dread, "O Evade escolhe o ataque com Dread, não o wind-up anterior")
	var evaded := [0]
	var mistimed := [0]
	b.manual_evaded.connect(func(_a, _i) -> void: evaded[0] += 1)
	b.evade_mistimed.connect(func(_a, _i) -> void: mistimed[0] += 1)
	var ok := b.try_evade(leader, found)
	_expect(ok and dread.dodged and dread.evade_tried, "O Evade no Dread é válido")
	_expect(evaded[0] == 1 and mistimed[0] == 0, "Não houve WHIFF")
	var ally := Combatant.new("Aliado", 100, 10, 0.5, true)
	var against_ally := _fake(e1, ally, Incoming.Phase.WINDUP, false, 0.0)
	var against_leader := _fake(e2, leader, Incoming.Phase.WINDUP, false, 0.0)
	_expect(not FxEvadeFlash.targets_leader(against_ally, leader), "Dread não acende em ataque mirando só o aliado")
	_expect(FxEvadeFlash.targets_leader(against_leader, leader), "Dread acende no ataque mirando o líder")
	var aoe := _fake(e1, ally, Incoming.Phase.WINDUP, false, 0.0)
	aoe.is_aoe = true
	_expect(FxEvadeFlash.targets_leader(aoe, leader), "Dread acende em área que também atinge o líder")
	print("=================================================================")
	if failures == 0:
		print("D1168_DREAD_TARGET_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
