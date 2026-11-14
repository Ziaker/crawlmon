extends SceneTree
## Unit test de LÓGICA PURA para o custo do Evade e a porta find_evadable/try_evade.
## Decisões aplicáveis: D-006, D-027, D-1014, D-1180.
## Roda com: godot --headless --path . --script res://tests/battle/unit/test_unit_evade_cost.gd

var _failures := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] " + msg)
	else:
		_failures += 1
		print("  [FAIL] " + msg)


func _evadable(foe: Combatant, target: Combatant, phase_time := 0.35) -> Incoming:
	var inc := Incoming.new()
	inc.attacker = foe
	inc.target = target
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


func _own_run(actor: Combatant, foe: Combatant) -> Incoming:
	var inc := Incoming.new()
	inc.attacker = actor
	inc.target = foe
	inc.label = "Corrida"
	inc.kind = Skill.Kind.MELEE
	inc.motion = "melee"
	inc.resolved = true
	inc.phase = Incoming.Phase.TRAVEL
	inc.plan = [[Incoming.Phase.TRAVEL, 1.0]]
	inc.plan_i = 0
	inc.phase_time = 0.2
	return inc


func _evade_case(atb_value: float, should_work: bool) -> void:
	var b := Battle.new()
	var actor := Combatant.new("Alvo", 100, 10, 0.5, true)
	var foe := Combatant.new("Inimigo", 100, 10, 0.5, false)
	actor.atb = atb_value
	actor.extra = 0.0
	var inc := _evadable(foe, actor)
	b._landing.append(inc)
	var found := b.find_evadable(actor)
	_check((found == inc) == should_work, "ATB %.1f × custo 3: find_evadable %s" % [atb_value, "acha" if should_work else "não acha"])
	var worked := b.try_evade(actor, inc)
	_check(worked == should_work, "ATB %.1f: try_evade devolve %s" % [atb_value, str(should_work)])
	if should_work:
		_check(is_equal_approx(actor.atb, atb_value - 3.0) and is_equal_approx(actor.extra, 0.0), "ATB %.1f → gasta 3, sobra %.1f" % [atb_value, atb_value - 3.0])
		_check(inc.dodged and inc.evade_tried, "ATB %.1f: o ataque foi desviado" % atb_value)
		_check(actor.burst == 1, "ATB %.1f: Evade perfeito dá 1 Burst" % atb_value)
	else:
		_check(is_equal_approx(actor.atb, atb_value), "ATB %.1f: nada é gasto quando falta ATB" % atb_value)
		_check(not inc.dodged and not inc.evade_tried, "ATB %.1f: o ataque não foi desviado" % atb_value)


func _initialize() -> void:
	print("=================================================================")
	print("   CRAWMON — UNIT: CUSTO DO EVADE (D-006 / D-027)")
	print("=================================================================")

	# --- Custo: 3 parado, 2 durante a corrida do próprio melee ---
	var b := Battle.new()
	var actor := Combatant.new("Alvo", 100, 10, 0.5, true)
	var foe := Combatant.new("Inimigo", 100, 10, 0.5, false)
	_check(is_equal_approx(b.evade_cost(actor), 3.0), "parado: custo 3 ATB")
	var run := _own_run(actor, foe)
	b._landing.append(run)
	_check(is_equal_approx(b.evade_cost(actor), 2.0), "na corrida do próprio melee: custo 2 ATB")
	b._landing.erase(run)
	_check(is_equal_approx(b.evade_cost(actor), 3.0), "de volta a parado: custo 3 ATB")

	# --- find_evadable / try_evade abaixo, igual e acima do custo ---
	_evade_case(2.0, false)
	_evade_case(3.0, true)
	_evade_case(4.0, true)

	print("=================================================================")
	if _failures == 0:
		print("EVADE_COST_UNIT_TEST_PASS")
	else:
		print("EVADE_COST_UNIT_TEST_FAIL (%d falhas)" % _failures)
	print("=================================================================")
	quit(1 if _failures > 0 else 0)
