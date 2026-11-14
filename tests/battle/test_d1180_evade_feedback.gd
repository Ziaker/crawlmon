extends SceneTree
## D-1180: a late press while the Dread is lit is valid, and a valid Evade clears any
## leftover WHIFF/fall from an early press. Runs with:
## godot --headless --path . --script res://tests/battle/test_d1180_evade_feedback.gd

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _fake(a: Combatant, t: Combatant, phase_time: float) -> Incoming:
	var inc := Incoming.new()
	inc.attacker = a
	inc.target = t
	inc.label = "Teste"
	inc.kind = Skill.Kind.MELEE
	inc.motion = "melee"
	inc.resolved = true
	inc.phase = Incoming.Phase.STRIKE
	inc.impact_phase = Incoming.Phase.STRIKE
	inc.plan = [[Incoming.Phase.STRIKE, 0.5]]
	inc.plan_i = 0
	inc.phase_time = phase_time
	return inc


func _run() -> void:
	print("=================================================================")
	print("   CRAWMON — DODGE TARDIO E WHIFF LIMPO (D-1180)")
	print("=================================================================")
	var b := Battle.new()
	var leader := Combatant.new("Líder", 100, 10, 0.5, true)
	var foe := Combatant.new("Inimigo", 100, 10, 0.5, false)
	b.start([leader], [foe])
	leader.atb = 5.0
	leader.mp = 20
	var late := _fake(foe, leader, 0.35)  # left = 0.15 s before contact
	_expect(late.can_evade_now(), "Aperto tardio com o Dread aceso ainda é válido")
	var close := _fake(foe, leader, 0.45)  # left = 0.05 s
	_expect(not close.can_evade_now(), "Aperto quase no contato ainda é fora da janela")

	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	bs.set_meta("vfx_room", true)
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	await create_timer(1.5, true, false, true).timeout
	var actor: Combatant = bs.leader
	var fx: BattleFx = bs.fx
	var m: Node3D = fx._models[actor]
	var base_x := m.rotation.x
	fx.fx_dodge.mistimed(actor, null)
	await create_timer(0.15, true, false, true).timeout
	_expect(fx.fx_dodge._whiff_labels.has(actor), "O WHIFF nasce no erro inicial")
	_expect(fx.fx_dodge._falling.has(actor), "O corpo começa a cair no erro inicial")
	var inc := _fake(battle.enemies[0], actor, 0.3)
	fx.fx_dodge.manual_evade(actor, inc)
	await process_frame
	_expect(not fx.fx_dodge._whiff_labels.has(actor), "O Evade válido limpa o WHIFF antigo")
	_expect(not fx.fx_dodge._falling.has(actor), "O Evade válido devolve o corpo ao eixo")
	_expect(is_equal_approx(m.rotation.x, base_x), "O corpo não fica deitado depois do Evade válido")
	_expect(fx.fx_dodge.last_whiff.is_empty(), "A auditoria de WHIFF também é limpa")
	await create_timer(0.8, true, false, true).timeout
	_expect(is_equal_approx(m.rotation.x, base_x), "A rotina antiga não deita o corpo de novo")
	bs.free()
	print("=================================================================")
	if failures == 0:
		print("D1180_EVADE_FEEDBACK_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
