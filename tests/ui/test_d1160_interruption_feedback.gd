extends SceneTree
## D-1160: only a real interruption destroys the AttackTag. A manual Evade, an automatic
## dodge and a hit during the return are not interruptions (D-104/D-106); battle-end
## cleanup is not either. Runs with:
## godot --headless --path . --script res://tests/ui/test_d1160_interruption_feedback.gd

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _run() -> void:
	print("=================================================================")
	print("   CRAWMON — INTERRUPÇÃO VISUAL SÓ REAL (D-1160)")
	print("=================================================================")
	_test_hud_predicate()
	_test_real_interruptions()
	_test_non_interruptions()
	await _test_hud_cleanup()
	print("=================================================================")
	if failures == 0:
		print("D1160_INTERRUPTION_FEEDBACK_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)


func _bare_battle() -> Battle:
	var b := Battle.new()
	var a := Combatant.new("Atacante", 100, 10, 0.5, true)
	var e := Combatant.new("Alvo", 100, 10, 0.5, false)
	b.start([a], [e])
	a.atb = 5.0
	a.mp = 20
	e.atb = 5.0
	e.mp = 20
	return b


func _first_incoming(b: Battle, c: Combatant) -> Incoming:
	for inc in b.incoming:
		if inc.attacker == c:
			return inc
	return null


func _fake_landing(a: Combatant, e: Combatant) -> Incoming:
	var inc := Incoming.new()
	inc.attacker = a
	inc.target = e
	inc.label = "Teste"
	inc.kind = Skill.Kind.MELEE
	inc.resolved = true
	inc.motion = "melee"
	inc.phase = Incoming.Phase.TRAVEL
	inc.plan = [[Incoming.Phase.TRAVEL, 1.0], [Incoming.Phase.STRIKE, 0.5]]
	inc.plan_i = 0
	inc.impact_phase = Incoming.Phase.STRIKE
	return inc


func _test_hud_predicate() -> void:
	var inc := Incoming.new()
	_expect(not BattleHud.shows_interruption_feedback(inc), "Ação normal não destrói o cartão")
	inc.dodged = true
	_expect(not BattleHud.shows_interruption_feedback(inc), "Evade manual (dodged) não é interrupção")
	inc.dodged = false
	inc.auto_dodged = true
	_expect(not BattleHud.shows_interruption_feedback(inc), "Desvio automático não é interrupção")
	inc.auto_dodged = false
	inc.interrupted = true
	_expect(not BattleHud.shows_interruption_feedback(inc), "`interrupted` mecânico sozinho não destrói o cartão")
	inc.interruption_feedback = true
	_expect(BattleHud.shows_interruption_feedback(inc), "Interrupção real (interruption_feedback) destrói o cartão")
	_expect(not BattleHud.shows_interruption_feedback(null), "Nulo não destrói cartão")


func _test_real_interruptions() -> void:
	# War Cry cancels the wind-up.
	var b := _bare_battle()
	var a: Combatant = b.party[0]
	var e: Combatant = b.enemies[0]
	_expect(b.use_skill(a, Skill.basic(), e), "Ataque começou o wind-up")
	var inc := _first_incoming(b, a)
	_expect(b.interrupt_windup_of(a, e) and inc.interrupted and inc.interruption_feedback,
		"War Cry marca interrupção real")

	# A hit cancels the wind-up.
	b = _bare_battle()
	a = b.party[0]
	e = b.enemies[0]
	b.use_skill(a, Skill.basic(), e)
	inc = _first_incoming(b, a)
	_expect(b._interrupt_attacks_of(a, e, 1.0) and inc.interrupted and inc.interruption_feedback,
		"Hit no wind-up marca interrupção real")

	# A hit stops the travel before the impact.
	b = _bare_battle()
	a = b.party[0]
	e = b.enemies[0]
	inc = _fake_landing(a, e)
	b._landing.append(inc)
	_expect(b._interrupt_attacks_of(a, e, 1.0) and inc.interrupted and inc.interruption_feedback,
		"Hit no trajeto marca interrupção real")

	# A clash stops both runs that are not aimed at each other.
	b = _bare_battle()
	a = b.party[0]
	e = b.enemies[0]
	a.pos = Vector3(-1, 0, 0)
	e.pos = Vector3(1, 0, 0)
	var ia := _fake_landing(a, e)
	var ib := _fake_landing(e, a)
	ib.target = Combatant.new("Outro", 100, 10, 0.5, true)
	b._clash(ia, ib)
	_expect(ia.interruption_feedback and ib.interruption_feedback,
		"Choque marca interrupção real nos dois corredores")


func _test_non_interruptions() -> void:
	# A hit during the return does not interrupt the action (it already hit).
	var b := _bare_battle()
	var a: Combatant = b.party[0]
	var e: Combatant = b.enemies[0]
	var inc := _fake_landing(a, e)
	inc.impacted = true
	inc.phase = Incoming.Phase.RETURN
	inc.plan = [[Incoming.Phase.RETURN, 0.5]]
	inc.plan_i = 0
	b._returning.append(inc)
	b._interrupt_attacks_of(a, e, 1.0)
	_expect(inc.interrupted and not inc.interruption_feedback,
		"Hit no retorno não aparece como interrupção")

	# Battle-end cleanup stops the run home but is not an interruption on screen.
	b = _bare_battle()
	a = b.party[0]
	e = b.enemies[0]
	inc = _fake_landing(a, e)
	b._landing.append(inc)
	e.hp = 0
	b._check_end()
	_expect(not b.running and inc.interrupted and not inc.interruption_feedback,
		"Fim de batalha não aparece como interrupção")

	# Evade cancelling its own run is a miss, not an interruption (D-104/D-106).
	b = _bare_battle()
	a = b.party[0]
	e = b.enemies[0]
	inc = _fake_landing(a, e)
	b._landing.append(inc)
	b._evade._cancel_run_home(inc)
	_expect(inc.interrupted and not inc.interruption_feedback,
		"Evade cancelando a própria corrida não aparece como interrupção")


func _test_hud_cleanup() -> void:
	var b := _bare_battle()
	var hud := BattleHud.new()
	var camera := Camera3D.new()
	var director := BattleCamera.new()
	root.add_child(camera)
	root.add_child(director)
	root.add_child(hud)
	hud.setup(b, b.party, b.enemies, camera, {}, director)
	hud.set_process(false)
	var a: Combatant = b.party[0]
	var e: Combatant = b.enemies[0]

	var dodged := _fake_tag_inc(a, e)
	dodged.dodged = true
	var tag_dodged := _tag_for(hud, dodged)
	hud._sync_incoming()
	_expect(tag_dodged.leaving and not tag_dodged.broken,
		"HUD: cartão de Evade manual sai normalmente (sem INTERRUPTED)")

	var auto := _fake_tag_inc(a, e)
	auto.auto_dodged = true
	var tag_auto := _tag_for(hud, auto)
	hud._sync_incoming()
	_expect(tag_auto.leaving and not tag_auto.broken,
		"HUD: cartão de desvio automático sai normalmente (sem INTERRUPTED)")

	var interrupted := _fake_tag_inc(a, e)
	interrupted.interrupted = true
	var tag_interrupted := _tag_for(hud, interrupted)
	hud._sync_incoming()
	_expect(tag_interrupted.leaving and not tag_interrupted.broken,
		"HUD: `interrupted` mecânico não destrói o cartão")

	var real := _fake_tag_inc(a, e)
	real.interruption_feedback = true
	var tag_real := _tag_for(hud, real)
	hud._sync_incoming()
	_expect(tag_real.broken and not tag_real.visible,
		"HUD: interrupção real destrói o cartão")

	await process_frame
	hud.queue_free()
	camera.queue_free()
	director.queue_free()
	await process_frame


func _fake_tag_inc(a: Combatant, e: Combatant) -> Incoming:
	var inc := Incoming.new()
	inc.attacker = a
	inc.target = e
	inc.label = "Teste"
	inc.kind = Skill.Kind.MELEE
	return inc


func _tag_for(hud: BattleHud, inc: Incoming) -> BattleHud.AttackTag:
	var tag := BattleHud.AttackTag.new()
	tag.inc = inc
	tag.hud = hud
	tag.size = Vector2(180, 66)
	tag.visible = true
	hud.add_child(tag)
	hud._inc_tags[inc] = tag
	return tag
