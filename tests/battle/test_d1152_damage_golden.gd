extends SceneTree
## D-1152 / Fase 0 do plano de dano: congela o comportamento atual do pipeline
## antes de qualquer refatoração. Não altera o jogo; só mede.
##
## Convenção: `info.dmg` é o dano que o `_hit` devolve (antes de `take_damage`
## aplicar `def_buff`); `delta` é o HP realmente perdido depois de `take_damage`.

var _f := 0

func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c:
		_f += 1


func _attacker(p_attack := 10, p_mag := 10) -> Combatant:
	var c := Combatant.new("Attacker", 999, p_attack, 0.5, true, p_mag)
	c.str = p_attack
	c.mag = p_mag
	c.luk = 0
	return c


func _target(p_hp := 999) -> Combatant:
	var c := Combatant.new("Target", p_hp, 0, 0.5, false, 0)
	c.str = 0
	c.mag = 0
	c.vit = 0
	c.wis = 0
	c.agi = 0
	c.luk = 0
	return c


func _skill(power: float, kind: Skill.Kind, element: Element.Type, magical: bool) -> Skill:
	var s := Skill.new("Golden Move", power, 2, element, kind)
	s.damage_type = MoveData.DamageType.MAGICAL if magical else MoveData.DamageType.PHYSICAL
	return s


func _move_data(s: Skill) -> MoveData:
	var md := MoveData.new()
	md.id = &"golden_move"
	md.display_name = s.display_name
	md.damage_type = s.damage_type
	md.element = s.element
	md.power = s.power
	return md


func _hit(battle: Battle, atk: Combatant, tgt: Combatant, s: Skill, roll := 1) -> Dictionary:
	battle.debug_roll = roll
	return battle._hit(atk, tgt, s.power, s.element, s.display_name, false, false, {"move_data": _move_data(s)})


func _case(label: String, atk: Combatant, tgt: Combatant, s: Skill, expected_info: int, expected_delta: int, roll := 1) -> void:
	var before := tgt.hp
	var info := _hit(Battle.new(), atk, tgt, s, roll)
	var delta := before - tgt.hp
	ok(int(info.get("dmg", -1)) == expected_info, "%s: info.dmg=%d (esperado %d)" % [label, int(info.get("dmg", -1)), expected_info])
	ok(delta == expected_delta, "%s: HP perdido=%d (esperado %d)" % [label, delta, expected_delta])


func _init() -> void:
	# --- Físico: base, fraqueza, crítico, passos, defesa ---
	_case("Físico neutro", _attacker(10, 10), _target(), _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 10, 10)

	var weak_t := _target()
	weak_t.weaknesses = [Element.Type.FISICO] as Array[Element.Type]
	_case("Físico fraqueza", _attacker(10, 10), weak_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 15, 15)

	var resist_t := _target()
	resist_t.affinities[Element.Type.FISICO] = Affinity.Type.RESIST
	_case("Físico resist", _attacker(10, 10), resist_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 5, 5)

	_case("Físico crítico", _attacker(10, 10), _target(), _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 20, 20, 3)

	var atk_front := _attacker(10, 10)
	atk_front.pos_step = 2
	_case("Físico +2 passos", atk_front, _target(), _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 12, 12)

	var tgt_back := _target()
	tgt_back.pos_step = -2
	_case("Físico alvo -2 passos", _attacker(10, 10), tgt_back, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 8, 8)

	var tgt_def_up := _target()
	tgt_def_up.def_buff = 2
	_case("Físico def_buff +2", _attacker(10, 10), tgt_def_up, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 10, 7)

	var tgt_def_down := _target()
	tgt_def_down.def_buff = -2
	_case("Físico def_buff -2", _attacker(10, 10), tgt_def_down, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 10, 15)

	# --- Mágico: base MAG, WIS, ordem com fraqueza/crítico ---
	_case("Mágico neutro", _attacker(10, 10), _target(), _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 14, 14)

	var tgt_wis10 := _target()
	tgt_wis10.wis = 10
	_case("Mágico WIS 10", _attacker(10, 10), tgt_wis10, _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 7, 7)

	var tgt_wis2 := _target()
	tgt_wis2.wis = 2
	_case("Mágico WIS 2", _attacker(10, 10), tgt_wis2, _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 12, 12)

	var tgt_weak_wis2 := _target()
	tgt_weak_wis2.wis = 2
	tgt_weak_wis2.weaknesses = [Element.Type.PSIQUICO] as Array[Element.Type]
	_case("Mágico fraqueza + WIS 2", _attacker(10, 10), tgt_weak_wis2, _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 18, 18)

	var tgt_crit_wis2 := _target()
	tgt_crit_wis2.wis = 2
	_case("Mágico crítico + WIS 2", _attacker(10, 10), tgt_crit_wis2, _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 23, 23, 3)

	# --- Guard, ARMOR, escudo ---
	var tgt_guard := _target()
	tgt_guard.guard_timer = 2.0
	_case("Guard", _attacker(10, 10), tgt_guard, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 5, 5)

	var battle_armor := Battle.new()
	var tgt_armor := _target()
	tgt_armor.armor_timer = 2.0
	var armor_info := _hit(battle_armor, _attacker(10, 10), tgt_armor, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false))
	ok(int(armor_info.get("dmg", -1)) == 10, "ARMOR: dano normal (10)")
	ok(armor_info.get("armor", "") == "hit", "ARMOR: marcado como hit")
	ok(armor_info.get("interrupted", true) == false, "ARMOR: sem interrupção")

	var battle_shield := Battle.new()
	var tgt_shield := _target()
	tgt_shield.apply_shield(6, 10.0)
	var before_shield := tgt_shield.hp
	var shield_info := _hit(battle_shield, _attacker(10, 10), tgt_shield, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false))
	ok(int(shield_info.get("dmg", -1)) == 4, "Escudo: info.dmg pós-escudo = 4")
	ok(before_shield - tgt_shield.hp == 4, "Escudo: HP perdido = 4")
	ok(tgt_shield.shield_hp == 0 and tgt_shield.shield_timer == 0.0, "Escudo: quebrou")

	# --- Drain Spear: fórmula própria 5 + MAG - WIS, sem WIS duplicada ---
	var drain := Skill.from_id(&"drain_spear")
	var battle_drain := Battle.new()
	var tgt_drain := _target()
	tgt_drain.wis = 3
	tgt_drain.def_buff = 5  # bypass_def deve ignorar
	var before_drain := tgt_drain.hp
	var drain_info := battle_drain._hit(_attacker(10, 10), tgt_drain, drain.power, drain.element, drain.display_name, false, false, {"magic_flat": 5, "bypass_def": true, "move_data": drain.data})
	ok(int(drain_info.get("dmg", -1)) == 12, "Drain Spear: 5 + 10 MAG - 3 WIS = 12")
	ok(before_drain - tgt_drain.hp == 12, "Drain Spear: bypass_def aplicado (HP -12)")

	# --- Burn: dano fixo, ignora def_buff ---
	var tgt_burn := _target()
	tgt_burn.def_buff = 5
	var before_burn := tgt_burn.hp
	tgt_burn.take_damage(2, true)
	ok(before_burn - tgt_burn.hp == 2, "Burn: 2 fixo, ignora def_buff")

	# --- Status: 0 ---
	var status := Skill.new("Golden Status", 0.0, 2, Element.Type.LUZ, Skill.Kind.STATUS)
	ok(Battle.estimate_damage(_attacker(10, 10), _target(), status) == 0, "Status: estimativa 0")

	# --- Mínimo 1 e arredondamento ---
	var tgt_wis100 := _target()
	tgt_wis100.wis = 100
	var tiny_atk := _attacker(10, 1)
	ok(Battle.estimate_damage(tiny_atk, tgt_wis100, _skill(1.0, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true)) == 1, "Mínimo 1 contra WIS 100")

	var tgt_wis10_round := _target()
	tgt_wis10_round.wis = 10
	ok(Battle.estimate_damage(_attacker(10, 5), tgt_wis10_round, _skill(1.0, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true)) == 3, "Arredondamento: 5 × 0,5 = 2,5 → 3")

	# --- Paridade estimate vs _hit (sem def_buff) ---
	var tgt_parity := _target()
	tgt_parity.wis = 2
	var magic := _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true)
	var estimate := Battle.estimate_damage(_attacker(10, 10), tgt_parity, magic)
	var before_parity := tgt_parity.hp
	var parity_info := _hit(Battle.new(), _attacker(10, 10), tgt_parity, magic)
	ok(int(parity_info.get("dmg", -1)) == estimate, "estimate e _hit batem sem def_buff (%d)" % estimate)
	ok(before_parity - tgt_parity.hp == estimate, "HP perdido bate com estimate sem def_buff (%d)" % estimate)

	# --- IA: preserva o piso 0 antigo contra DEF muito alta ---
	ok(DamageMath.final_damage(1, 5, false, false) == 0, "IA: 1 de dano contra DEF +5 prevê 0 (sem mínimo)")
	var ai := BattleAI.new(Battle.new())
	var ai_atk := _attacker(10, 10)
	var ai_tgt := _target()
	ai_tgt.def_buff = 5
	var ai_skill := _skill(0.1, Skill.Kind.MELEE, Element.Type.FISICO, false)
	ok(ai._damage_to(ai_atk, ai_skill, ai_tgt) == 0, "IA: _damage_to preserva 0 contra DEF +5")

	print("D1152_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
