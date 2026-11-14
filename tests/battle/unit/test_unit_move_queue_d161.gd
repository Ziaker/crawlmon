extends SceneTree
## Unit test de LÓGICA PURA da fila de Moves de uma vaga (D-161): a vaga, o Move
## que começa (started) e o Move descartado (lost), usando Battle.request_skill/_run_queued.
## Decisões aplicáveis: D-161, D-1146, D-1150, D-1154.
## Roda com: godot --headless --path . --script res://tests/battle/unit/test_unit_move_queue_d161.gd

var _failures := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] " + msg)
	else:
		_failures += 1
		print("  [FAIL] " + msg)


func _status_skill(p_name: String) -> Skill:
	var s := Skill.new(p_name, 0.0, 2, Element.Type.FISICO, Skill.Kind.STATUS)
	s.mp_cost = 0
	return s


func _dummy_pause(foe: Combatant, leader: Combatant) -> Incoming:
	var inc := Incoming.new()
	inc.attacker = foe
	inc.target = leader
	inc.kind = Skill.Kind.STATUS
	return inc


func _initialize() -> void:
	print("=================================================================")
	print("   CRAWMON — UNIT: FILA DE MOVE DE UMA VAGA (D-161)")
	print("=================================================================")

	# --- vaga: escolher durante a pausa de status, uma posição só, sem pagar ---
	var b1 := Battle.new()
	var leader1 := Combatant.new("Líder", 100, 10, 0.5, true)
	var foe1 := Combatant.new("Inimigo", 100, 10, 0.5, false)
	b1.start([leader1], [foe1])
	leader1.mp = 20
	var skill_a := _status_skill("Fila A")
	var skill_b := _status_skill("Fila B")
	var atb_before := leader1.atb
	b1._status_pause = _dummy_pause(foe1, leader1)
	_check(b1.request_skill(leader1, skill_a, foe1), "request_skill guarda o Move na vaga durante a pausa de status")
	_check(leader1.queued_skill == skill_a and leader1.queued_target == foe1, "vaga: Move e alvo guardados")
	_check(is_equal_approx(leader1.atb, atb_before), "vaga: nada é pago ao escolher (paga ao executar)")
	_check(b1.request_skill(leader1, skill_b, foe1) and leader1.queued_skill == skill_b, "vaga única: escolher outro substitui o anterior")
	_check(is_equal_approx(leader1.atb, atb_before), "substituir na vaga também não cobra")

	# --- started: quando a pausa acaba, o Move guardado começa e paga 2 ATB ---
	var telegraphed := [0]
	b1.attack_telegraphed.connect(func(_inc) -> void: telegraphed[0] += 1)
	b1._status_pause = null
	b1._run_queued()
	_check(leader1.queued_skill == null, "started: a vaga esvazia quando o Move começa")
	_check(b1.incoming.size() == 1 and b1.incoming[0].label == "Fila B", "started: o Move guardado virou o ataque atual")
	_check(telegraphed[0] == 1, "started: o ataque foi anunciado uma vez")
	_check(is_equal_approx(leader1.atb, atb_before - 2.0), "started: o custo de 2 blocos é pago na execução")

	# --- lost: sem ATB na hora de executar, a vaga é descartada ---
	var b2 := Battle.new()
	var leader2 := Combatant.new("Líder", 100, 10, 0.5, true)
	var foe2 := Combatant.new("Inimigo", 100, 10, 0.5, false)
	b2.start([leader2], [foe2])
	leader2.mp = 20
	var lost_skill := _status_skill("Fila Perdida")
	b2._status_pause = _dummy_pause(foe2, leader2)
	b2.request_skill(leader2, lost_skill, foe2)
	leader2.atb = 0.0
	leader2.burst = 0
	b2._status_pause = null
	var telegraphed2 := [0]
	b2.attack_telegraphed.connect(func(_inc) -> void: telegraphed2[0] += 1)
	b2._run_queued()
	_check(leader2.queued_skill == null, "lost: a vaga é descartada quando falta ATB na execução")
	_check(b2.incoming.is_empty(), "lost: nenhum ataque começou")
	_check(telegraphed2[0] == 0, "lost: nada foi anunciado")
	_check(is_equal_approx(leader2.atb, 0.0), "lost: nada é cobrado")

	# --- lost: alvo morto antes da execução também descarta a vaga ---
	var b3 := Battle.new()
	var leader3 := Combatant.new("Líder", 100, 10, 0.5, true)
	var foe3 := Combatant.new("Inimigo", 100, 10, 0.5, false)
	b3.start([leader3], [foe3])
	leader3.mp = 20
	var dead_target_skill := _status_skill("Fila Alvo Morto")
	b3._status_pause = _dummy_pause(foe3, leader3)
	b3.request_skill(leader3, dead_target_skill, foe3)
	foe3.hp = 0
	b3._status_pause = null
	b3._run_queued()
	_check(leader3.queued_skill == null, "lost: alvo morto descarta a vaga")
	_check(b3.incoming.is_empty(), "lost: nenhum ataque começa contra alvo morto")

	print("=================================================================")
	if _failures == 0:
		print("MOVE_QUEUE_D161_UNIT_TEST_PASS")
	else:
		print("MOVE_QUEUE_D161_UNIT_TEST_FAIL (%d falhas)" % _failures)
	print("=================================================================")
	quit(1 if _failures > 0 else 0)
