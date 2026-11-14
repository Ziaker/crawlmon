extends SceneTree
## Unit test de LÓGICA PURA (sem cena, sem renderização, sem timer) para as fórmulas
## de dano como scripts/combat/damage_math.gd as produz hoje.
## Decisões aplicáveis: D-1152, D-1153, D-1157, D-1158, D-1140, D-1142, D-1161.
## Roda com: godot --headless --path . --script res://tests/battle/unit/test_unit_damage_math.gd

var _failures := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] " + msg)
	else:
		_failures += 1
		print("  [FAIL] " + msg)


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


func _skill(p_power: float, p_kind: Skill.Kind, p_element: Element.Type, p_magical: bool) -> Skill:
	var s := Skill.new("Golden Move", p_power, 2, p_element, p_kind)
	s.damage_type = MoveData.DamageType.MAGICAL if p_magical else MoveData.DamageType.PHYSICAL
	return s


func _move_data(s: Skill) -> MoveData:
	var md := MoveData.new()
	md.id = &"golden_move"
	md.display_name = s.display_name
	md.damage_type = s.damage_type
	md.element = s.element
	md.power = s.power
	return md


func _hit(atk: Combatant, tgt: Combatant, s: Skill, roll := 1) -> Dictionary:
	var battle := Battle.new()
	battle.debug_roll = roll
	return battle._hit(atk, tgt, s.power, s.element, s.display_name, false, false, {"move_data": _move_data(s)})


func _case(label: String, atk: Combatant, tgt: Combatant, s: Skill, expected_info: int, expected_delta: int, roll := 1) -> void:
	var before := tgt.hp
	var info := _hit(atk, tgt, s, roll)
	_check(int(info.get("dmg", -1)) == expected_info, "%s: info.dmg=%d (esperado %d)" % [label, int(info.get("dmg", -1)), expected_info])
	_check(before - tgt.hp == expected_delta, "%s: HP perdido=%d (esperado %d)" % [label, before - tgt.hp, expected_delta])


func _initialize() -> void:
	print("=================================================================")
	print("   CRAWMON — UNIT: FÓRMULAS DE DANO (D-1152 / D-1153)")
	print("=================================================================")

	# --- DamageMath puro: ofensa, afinidade, crítico, passos ---
	_check(DamageMath.offense(10, 1.0, 1.0, false, 1.0) == 10, "offense neutro: 10 × 1,0 = 10")
	_check(DamageMath.offense(10, 1.0, DamageMath.WEAKNESS_MULT, false, 1.0) == 15, "offense WEAK 1,5x: 10 × 1,5 = 15")
	_check(DamageMath.offense(10, 1.0, Affinity.RESIST_MULT, false, 1.0) == 5, "offense RESIST 0,5x: 10 × 0,5 = 5")
	_check(DamageMath.offense(10, 1.0, 1.0, true, 1.0) == 20, "offense crítico 2x: 10 × 2 = 20")
	_check(DamageMath.offense(10, 1.4, 1.0, false, 1.0) == 14, "offense mágico: 10 × 1,4 = 14")
	_check(DamageMath.offense(1, 0.1, 0.5, false, 1.0) == 1, "offense mínimo 1: round(0,05) → 1")
	_check(is_equal_approx(DamageMath.step_multiplier(2, 0), 1.2), "passos: atacante +2 = 1,2")
	_check(is_equal_approx(DamageMath.step_multiplier(0, -2), 0.8), "passos: alvo -2 = 0,8")

	# --- Afinidade: só NEUTRAL, WEAK e RESIST valem (D-1161) ---
	_check(is_equal_approx(DamageMath.affinity_multiplier(Affinity.Type.NEUTRAL), 1.0), "afinidade NEUTRAL = 1,0")
	_check(is_equal_approx(DamageMath.affinity_multiplier(Affinity.Type.WEAK), 1.5), "afinidade WEAK = 1,5")
	_check(is_equal_approx(DamageMath.affinity_multiplier(Affinity.Type.RESIST), 0.5), "afinidade RESIST = 0,5")
	_check(is_equal_approx(DamageMath.affinity_multiplier(Affinity.Type.NULL), 1.0), "afinidade NULL = 1,0 (reservada, D-1161)")
	_check(is_equal_approx(DamageMath.affinity_multiplier(Affinity.Type.REPEL), 1.0), "afinidade REPEL = 1,0 (reservada, D-1161)")
	_check(is_equal_approx(DamageMath.affinity_multiplier(Affinity.Type.DRAIN), 1.0), "afinidade DRAIN = 1,0 (reservada, D-1161)")

	# --- WIS, Guard, Defense, mínimo e Drain (D-1142 / D-1153) ---
	_check(DamageMath.mitigate_magic(14, 10) == 7, "WIS 10 corta o mágico pela metade: 14 → 7")
	_check(DamageMath.mitigate_magic(14, 2) == 12, "WIS 2: 14 × 10/12 = 11,67 → 12")
	_check(DamageMath.mitigate_magic(1, 100) == 1, "WIS 100 no dano 1: 0,09 → mínimo 1")
	_check(DamageMath.apply_guard(10) == 5, "Guard: 10 → 5")
	_check(DamageMath.apply_guard(5) == 3, "Guard arredonda para cima: 2,5 → 3")
	_check(DamageMath.apply_guard(1) == 1, "Guard mínimo 1: 0,5 → 1")
	_check(DamageMath.apply_defense(10, 2) == 7, "def_buff +2: round(10/1,5) = 7")
	_check(DamageMath.apply_defense(10, -2) == 15, "def_buff -2: round(10 × 1,5) = 15")
	_check(DamageMath.apply_defense(1, 5, true) == 1, "def_buff +5 no dano 1: mínimo 1")
	_check(DamageMath.apply_defense(1, 5, false) == 0, "def_buff +5 no dano 1, min_one=false: 0 (IA)")
	_check(DamageMath.final_damage(2, 5, true) == 2, "dano fixo (Burn): ignora def_buff")
	_check(DamageMath.drain(5, 10, 3) == 12, "Drain: 5 + MAG 10 - WIS 3 = 12")
	_check(DamageMath.drain(5, 0, 10) == 1, "Drain mínimo 1")
	_check(DamageMath.base_damage(10, 1.4) == 14, "base_damage UI: 10 × 1,4 = 14")
	_check(DamageMath.base_damage(1, 0.1, false) == 0, "base_damage UI sem mínimo: 0,1 → 0")

	# --- Integração via Battle._hit: números exatos de hoje ---
	_case("Físico neutro", _attacker(10, 10), _target(), _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 10, 10)

	var weak_t := _target()
	weak_t.weaknesses = [Element.Type.FISICO] as Array[Element.Type]
	var weak_before := weak_t.hp
	var weak_info := _hit(_attacker(10, 10), weak_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false))
	_check(int(weak_info.get("dmg", -1)) == 15, "Físico WEAK: info.dmg=15")
	_check(weak_before - weak_t.hp == 15, "Físico WEAK: HP perdido=15")
	_check(int(weak_info.get("affinity", -1)) == Affinity.Type.WEAK and is_equal_approx(float(weak_info.get("affinity_mult", 0.0)), 1.5), "WEAK: telemetria affinity/affinity_mult")

	var resist_t := _target()
	resist_t.affinities[Element.Type.FISICO] = Affinity.Type.RESIST
	var resist_before := resist_t.hp
	var resist_info := _hit(_attacker(10, 10), resist_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false))
	_check(int(resist_info.get("dmg", -1)) == 5, "Físico RESIST: info.dmg=5")
	_check(resist_before - resist_t.hp == 5, "Físico RESIST: HP perdido=5")
	_check(int(resist_info.get("affinity", -1)) == Affinity.Type.RESIST and is_equal_approx(float(resist_info.get("affinity_mult", 0.0)), 0.5), "RESIST: telemetria affinity/affinity_mult")

	_case("Físico crítico (roll 3)", _attacker(10, 10), _target(), _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 20, 20, 3)

	var guard_t := _target()
	guard_t.guard_timer = 2.0
	var guard_before := guard_t.hp
	var guard_info := _hit(_attacker(10, 10), guard_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false))
	_check(int(guard_info.get("dmg", -1)) == 5, "Guard: info.dmg=5 (10 × 0,5 arredondado para cima)")
	_check(guard_before - guard_t.hp == 5, "Guard: HP perdido=5")
	_check(String(guard_info.get("guard", "")) == "absorbed", "Guard: marcado como absorbed")

	var armor_t := _target()
	armor_t.armor_timer = 2.0
	var armor_before := armor_t.hp
	var armor_info := _hit(_attacker(10, 10), armor_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false))
	_check(int(armor_info.get("dmg", -1)) == 10, "ARMOR: dano normal 10")
	_check(armor_before - armor_t.hp == 10, "ARMOR: HP perdido=10")
	_check(String(armor_info.get("armor", "")) == "hit", "ARMOR: marcado como hit")
	_check(armor_info.get("interrupted", true) == false, "ARMOR: sem interrupção")

	var wis10_t := _target()
	wis10_t.wis = 10
	_case("Mágico WIS 10", _attacker(10, 10), wis10_t, _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 7, 7)

	var wis2_t := _target()
	wis2_t.wis = 2
	_case("Mágico WIS 2", _attacker(10, 10), wis2_t, _skill(1.4, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 12, 12)

	var wis100_t := _target()
	wis100_t.wis = 100
	_case("Mínimo 1 contra WIS 100", _attacker(10, 1), wis100_t, _skill(1.0, Skill.Kind.PROJECTILE, Element.Type.PSIQUICO, true), 1, 1)

	# D-1152: info.dmg é pré-def_buff; a HUD pode divergir do HP perdido (não é bug novo).
	var def_up_t := _target()
	def_up_t.def_buff = 2
	_case("Físico def_buff +2 (info pré-defesa)", _attacker(10, 10), def_up_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 10, 7)

	var def_down_t := _target()
	def_down_t.def_buff = -2
	_case("Físico def_buff -2 (info pré-defesa)", _attacker(10, 10), def_down_t, _skill(1.0, Skill.Kind.MELEE, Element.Type.FISICO, false), 10, 15)

	print("=================================================================")
	if _failures == 0:
		print("DAMAGE_MATH_UNIT_TEST_PASS")
	else:
		print("DAMAGE_MATH_UNIT_TEST_FAIL (%d falhas)" % _failures)
	print("=================================================================")
	quit(1 if _failures > 0 else 0)
