extends SceneTree
## D-1200: single-ally target (Heal), ally choice by the AI, and the dual-target structure
## (target2 in Incoming, queue, snapshot). No dual-target move exists yet: the test uses a
## throwaway Skill built in code. Both sides are exercised (D-235): player team and enemy team.
## Run with: godot --headless --path . --script res://tests/battle/test_d1200_ally_and_dual_target.gd

var failures := 0


class StrFocusBehavior extends MoveBehavior:
	func ai_ally_focus() -> StringName:
		return &"str"


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _run() -> void:
	print("=== D-1200: alvo aliado unico, IA de aliado e estrutura de alvo duplo ===")
	_test_heal_data()
	for mirrored in [false, true]:
		print("-- lado %s" % ("espelhado (time inimigo cura)" if mirrored else "normal (time do jogador cura)"))
		_test_heal_one_ally(mirrored)
		_test_heal_falls_back_to_self(mirrored)
		_test_ai_ally_pick(mirrored)
		_test_ai_plan_targets_ally(mirrored)
		_test_dual_structure(mirrored)
	print("=================================================================")
	if failures == 0:
		print("D1200_ALLY_AND_DUAL_TARGET_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	quit(1 if failures > 0 else 0)


## Two teams; `mirrored` puts the caster's team in `enemies` (is_player follows the team).
func _make(mirrored: bool, caster_mag := 5) -> Dictionary:
	var b := Battle.new()
	var caster := Combatant.new("Caster", 100, 10, 0.5, not mirrored, caster_mag)
	var big := Combatant.new("BigAlly", 200, 10, 0.5, not mirrored)  # different max HP
	var small := Combatant.new("SmallAlly", 40, 10, 0.5, not mirrored)
	var foe := Combatant.new("Foe", 1000, 1, 0.5, mirrored)
	for c in [caster, big, small, foe]:
		c.max_mp = 30
		c.mp = 30
	var mine: Array[Combatant] = [caster, big, small]
	var theirs: Array[Combatant] = [foe]
	if mirrored:
		b.start(theirs, mine)
	else:
		b.start(mine, theirs)
	for c in [caster, big, small, foe]:
		c.atb = 5.0
	return {"b": b, "caster": caster, "big": big, "small": small, "foe": foe}


func _heal_skill() -> Skill:
	return Skill.from_id(&"heal")


func _run_until(b: Battle, cond: Callable, max_steps := 200) -> bool:
	for i in max_steps:
		b._process(0.05)
		if cond.call():
			return true
	return false


func _test_heal_data() -> void:
	var sk := _heal_skill()
	_expect(sk != null and sk.target_mode == MoveData.TargetMode.SINGLE_ALLY, "Heal: target_mode = SINGLE_ALLY")
	_expect(sk != null and not sk.is_aoe and sk.is_friendly, "Heal: nao e mais AoE e continua friendly")
	_expect(sk != null and sk.data != null and sk.data.behavior_script != null, "Heal: comportamento registrado")
	_expect(Skill.from_id(&"media").target_mode == MoveData.TargetMode.AUTO, "Media continua de grupo (AUTO)")


func _test_heal_one_ally(mirrored: bool) -> void:
	var w := _make(mirrored, 7)
	var b: Battle = w["b"]
	var caster: Combatant = w["caster"]
	var big: Combatant = w["big"]
	var small: Combatant = w["small"]
	big.hp = 50
	small.hp = 10
	caster.hp = 60
	var ok := b.use_skill(caster, _heal_skill(), small)
	_expect(ok, "Heal: o aliado escolhido e aceito")
	var done := _run_until(b, func() -> bool: return small.hp > 10)
	_expect(done, "Heal: o aliado escolhido foi curado")
	_expect(small.hp == 10 + 10 + 7, "Heal: cura 10 + MAG (HP %d, esperado %d)" % [small.hp, 27])
	_expect(big.hp == 50 and caster.hp == 60, "Heal: os outros aliados nao mudam")


func _test_heal_falls_back_to_self(mirrored: bool) -> void:
	var w := _make(mirrored)
	var b: Battle = w["b"]
	b.use_skill(w["caster"], _heal_skill(), w["foe"])
	_expect(b.incoming.back().target == w["caster"], "Heal em inimigo: cai no lancador (nunca cura o adversario)")
	var w2 := _make(mirrored)
	w2["big"].hp = 0
	w2["b"].use_skill(w2["caster"], _heal_skill(), w2["big"])
	_expect(w2["b"].incoming.back().target == w2["caster"], "Heal em aliado morto: cai no lancador")
	_expect(w2["b"].same_team(w2["caster"], w2["small"]) and not w2["b"].same_team(w2["caster"], w2["foe"]),
		"same_team le as listas do Battle")


func _test_ai_ally_pick(mirrored: bool) -> void:
	var w := _make(mirrored)
	var b: Battle = w["b"]
	var caster: Combatant = w["caster"]
	var big: Combatant = w["big"]
	var small: Combatant = w["small"]
	var ai: BattleAI = b._ai
	var heal := _heal_skill()
	big.hp = 120  # 60% HP, 80 missing in absolute HP
	small.hp = 20  # 50% HP, only 20 missing in absolute HP
	_expect(ai.pick_ally_target(caster, heal) == small, "IA cura o de menor % de HP, nao o de maior HP absoluto")
	big.hp = 100  # 50%
	small.hp = 20  # 50%
	caster.hp = 50  # 50%
	_expect(ai.pick_ally_target(caster, heal) == caster, "IA: empate = o proprio lancador")
	caster.hp = caster.max_hp
	big.hp = big.max_hp
	small.hp = int(small.max_hp * 0.9)
	_expect(ai.pick_ally_target(caster, heal) == caster, "IA: ninguem abaixo do minimo = o proprio lancador")
	_expect(ai.score_move(caster, heal, caster) <= 0.0, "IA: Heal sem ferido vale 0")
	big.hp = 0
	small.hp = 5
	_expect(ai.pick_ally_target(caster, heal) == small, "IA ignora aliado morto")
	_expect(StrFocusBehavior.new().ai_ally_focus() == &"str", "foco 'str' e declaravel por um comportamento")


func _test_ai_plan_targets_ally(mirrored: bool) -> void:
	var w := _make(mirrored)
	var b: Battle = w["b"]
	var caster: Combatant = w["caster"]
	var small: Combatant = w["small"]
	small.hp = 8
	caster.skills = [_heal_skill()]
	caster.act_policy = Combatant.Act.SKILL
	var plan: Dictionary = b._ai._new_plan(caster)
	_expect(not plan.is_empty() and plan["skill"].display_name == "Heal" and plan["target"] == small,
		"IA: o plano do Heal mira o aliado ferido")
	b._ai._perform(caster, plan["skill"], plan["target"])
	_expect(not b.incoming.is_empty() and b.incoming.back().target == small and b.incoming.back().label == "Heal",
		"IA: o Heal sai no aliado escolhido (antes ia sempre em si mesma)")
	_expect(b.same_team(caster, b.incoming.back().target), "IA: o alvo do Heal e do mesmo time")


func _test_dual_structure(mirrored: bool) -> void:
	var w := _make(mirrored)
	var b: Battle = w["b"]
	var caster: Combatant = w["caster"]
	var ally: Combatant = w["small"]
	var foe: Combatant = w["foe"]
	var dual := Skill.new("DualTest", 1.0, 2, Element.Type.FISICO, Skill.Kind.CAST)
	dual.mp_cost = 0
	dual.target_mode = MoveData.TargetMode.DUAL
	_expect(not b.use_skill(caster, dual, foe, null), "Dual sem segundo alvo e recusado")
	var dead := Combatant.new("Dead", 10, 1, 0.5, true)
	dead.hp = 0
	_expect(not b.use_skill(caster, dual, foe, dead), "Dual com segundo alvo morto e recusado")
	_expect(b.use_skill(caster, dual, foe, ally), "Dual aceita primario e secundario vivos")
	var inc: Incoming = b.incoming.back()
	_expect(inc.target == foe and inc.target2 == ally, "Incoming guarda target (primario) e target2 (secundario)")
	_expect(b.is_in_action(ally), "o segundo alvo conta como 'em acao'")
	_expect(b.request_skill(caster, dual, ally, foe), "Dual fica na fila com o ator ocupado")
	_expect(caster.queued_target == ally and caster.queued_target2 == foe, "fila guarda target e target2")
	var snap := caster.save_state()
	caster.queued_target2 = null
	caster.restore_state(snap)
	_expect(caster.queued_target2 == foe, "save/restore_state preservam queued_target2")
	b._clear_queued(caster)
	_expect(caster.queued_target2 == null, "limpar a vaga limpa queued_target2")
	var w2 := _make(mirrored)
	w2["b"].use_skill(w2["caster"], Skill.basic(), w2["foe"], w2["small"])
	_expect(w2["b"].incoming.back().target2 == null, "Move comum ignora target2")
	# lados declarados pelo Move (D-1200): primario ENEMY + secundario ALLY, e o inverso
	var w3 := _make(mirrored)
	var forge := Skill.new("DualSides", 1.0, 2, Element.Type.FISICO, Skill.Kind.CAST)
	forge.mp_cost = 0
	forge.target_mode = MoveData.TargetMode.DUAL
	forge.primary_side = MoveData.TargetSide.ENEMY
	forge.secondary_side = MoveData.TargetSide.ALLY
	_expect(not w3["b"].use_skill(w3["caster"], forge, w3["small"], w3["foe"]), "ENEMY+ALLY: primario aliado e recusado")
	_expect(w3["b"].use_skill(w3["caster"], forge, w3["foe"], w3["small"]), "ENEMY+ALLY: inimigo primario e aliado secundario aceitos")
	var w4 := _make(mirrored)
	forge.primary_side = MoveData.TargetSide.ALLY
	forge.secondary_side = MoveData.TargetSide.ENEMY
	_expect(not w4["b"].use_skill(w4["caster"], forge, w4["foe"], w4["small"]), "ALLY+ENEMY: primario inimigo e recusado")
	_expect(w4["b"].use_skill(w4["caster"], forge, w4["small"], w4["foe"]), "ALLY+ENEMY: aliado primario e inimigo secundario aceitos (o proprio lancador tambem conta como aliado)")
	var w5 := _make(mirrored)
	_expect(w5["b"].side_allows(w5["caster"], w5["caster"], MoveData.TargetSide.ALLY) and not w5["b"].side_allows(w5["caster"], w5["caster"], MoveData.TargetSide.ENEMY), "o lancador e aliado de si mesmo")
