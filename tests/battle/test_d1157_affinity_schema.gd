extends SceneTree
## D-1157 / Fase 2: schema de afinidade com só WEAK ativo.
## A tabela existe, mas o comportamento de dano continua idêntico ao D-1152.

var _f := 0

func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c:
		_f += 1


func _physical_fire() -> Skill:
	var s := Skill.new("Golden Fire", 1.0, 2, Element.Type.FOGO, Skill.Kind.MELEE)
	s.damage_type = MoveData.DamageType.PHYSICAL
	return s


func _init() -> void:
	ok(Affinity.damage_multiplier(Affinity.Type.NEUTRAL) == 1.0, "Neutral = 1.0")
	ok(Affinity.damage_multiplier(Affinity.Type.WEAK) == 1.5, "Weak = 1.5")
	ok(Affinity.damage_multiplier(Affinity.Type.RESIST) == 0.5, "Resist = 0.5")
	ok(Affinity.damage_multiplier(Affinity.Type.NULL) == 1.0, "Null is reserved (1.0)")
	ok(Affinity.damage_multiplier(Affinity.Type.REPEL) == 1.0, "Repel is reserved (1.0)")
	ok(Affinity.damage_multiplier(Affinity.Type.DRAIN) == 1.0, "Drain is reserved (1.0)")
	ok(Affinity.name_of(Affinity.Type.WEAK) == "Weak", "name_of Weak")

	var rng := RandomNumberGenerator.new()
	rng.seed = 1157
	var abra := CharacterFactory.create("abra", {"is_player": true, "forced_nature": "modest", "rng": rng})
	var slime := EnemyFactory.create_enemy("dqt_slime", rng, "hardy")
	ok(abra.affinities.has(Element.Type.TREVAS) and int(abra.affinities[Element.Type.TREVAS]) == Affinity.Type.WEAK,
		"Abra affinities: Dark = WEAK")
	ok(abra.affinities.has(Element.Type.SOM) and int(abra.affinities[Element.Type.SOM]) == Affinity.Type.WEAK,
		"Abra affinities: Sound = WEAK")
	ok(abra.is_weak_to(Element.Type.TREVAS), "Abra is weak to Dark")
	ok(abra.is_weak_to(Element.Type.SOM), "Abra is weak to Sound")
	ok(not abra.is_weak_to(Element.Type.FOGO), "Abra is not weak to Fire")
	ok(slime.is_weak_to(Element.Type.FOGO), "Slime is weak to Fire")

	# Non-WEAK schema entries are readable and now RESIST is active.
	var schema := Combatant.new("Schema", 100, 10, 0.5, true)
	schema.affinities[Element.Type.FOGO] = Affinity.Type.RESIST
	ok(schema.affinity_for(Element.Type.FOGO) == Affinity.Type.RESIST, "Resist entry is stored in the table")
	ok(not schema.is_weak_to(Element.Type.FOGO), "Resist is not Weak")

	# Explicit NEUTRAL cancels a legacy weakness; explicit WEAK works without the legacy list.
	var explicit_neutral := Combatant.new("NeutralEntry", 100, 10, 0.5, true)
	explicit_neutral.weaknesses = [Element.Type.FOGO] as Array[Element.Type]
	explicit_neutral.affinities[Element.Type.FOGO] = Affinity.Type.NEUTRAL
	ok(not explicit_neutral.is_weak_to(Element.Type.FOGO), "Explicit NEUTRAL beats legacy weakness")
	var explicit_weak := Combatant.new("WeakEntry", 100, 10, 0.5, true)
	explicit_weak.affinities[Element.Type.FOGO] = Affinity.Type.WEAK
	ok(explicit_weak.is_weak_to(Element.Type.FOGO), "Explicit WEAK works without legacy list")

	# Legacy/manual Combatants that only set weaknesses still work in Phase 2.
	var manual := Combatant.new("Manual", 100, 10, 0.5, true)
	manual.weaknesses = [Element.Type.FOGO] as Array[Element.Type]
	ok(manual.is_weak_to(Element.Type.FOGO), "Legacy weaknesses fallback still works")

	# Damage parity: WEAK is still 1.5x, through the affinity table.
	var atk := Combatant.new("Attacker", 999, 10, 0.5, true)
	atk.str = 10
	atk.luk = 0
	var fire := _physical_fire()
	var neutral := Combatant.new("Neutral", 999, 0, 0.5, false)
	var neutral_dmg := Battle.estimate_damage(atk, neutral, fire)
	var slime_dmg := Battle.estimate_damage(atk, slime, fire)
	ok(neutral_dmg == 10, "Neutral physical fire = 10")
	ok(slime_dmg == 15, "Slime weak to Fire = 15 (1.5x)")

	var resist := Combatant.new("Resist", 999, 0, 0.5, false)
	resist.affinities[Element.Type.FOGO] = Affinity.Type.RESIST
	ok(Battle.estimate_damage(atk, resist, fire) == 5, "Resist physical fire = 5 (0.5x)")
	var resist_battle := Battle.new()
	resist_battle.debug_roll = 1
	var resist_before := resist.hp
	var resist_info := resist_battle._hit(atk, resist, fire.power, fire.element, fire.display_name, false, false, {"move_data": _md(fire)})
	ok(not bool(resist_info.get("weak", true)), "Resist is not Weak")
	ok(int(resist_info.get("dmg", -1)) == 5, "Resist _hit damage = 5")
	ok(resist_before - resist.hp == 5, "Resist _hit HP loss = 5")
	ok(int(resist_info.get("affinity", -1)) == Affinity.Type.RESIST, "Resist info.affinity is RESIST")
	ok(is_equal_approx(float(resist_info.get("affinity_mult", 0.0)), 0.5), "Resist info.affinity_mult = 0.5")

	# D-1161: CharacterFactory ignores explicit NULL/REPEL data.
	var cd := CharacterData.new()
	cd.id = &"reserved_test"
	cd.affinities = {Element.Type.FOGO: Affinity.Type.NULL, Element.Type.RAIO: Affinity.Type.REPEL, Element.Type.AGUA_GELO: Affinity.Type.DRAIN}
	var reserved := Combatant.new("Reserved", 100, 10, 0.5, true)
	CharacterFactory._apply_affinities(reserved, cd)
	ok(not reserved.affinities.has(Element.Type.FOGO), "NULL is ignored by the factory")
	ok(not reserved.affinities.has(Element.Type.RAIO), "REPEL is ignored by the factory")
	ok(not reserved.affinities.has(Element.Type.AGUA_GELO), "DRAIN is ignored by the factory")

	var battle := Battle.new()
	battle.debug_roll = 1
	var before := slime.hp
	var info := battle._hit(atk, slime, fire.power, fire.element, fire.display_name, false, false, {"move_data": _md(fire)})
	ok(bool(info.get("weak", false)), "_hit reports weak from the affinity table")
	ok(int(info.get("dmg", -1)) == 15, "_hit damage uses the affinity multiplier")
	ok(before - slime.hp == 15, "_hit HP loss matches")

	print("D1157_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)


func _md(s: Skill) -> MoveData:
	var md := MoveData.new()
	md.id = &"golden_fire"
	md.display_name = s.display_name
	md.damage_type = s.damage_type
	md.element = s.element
	md.power = s.power
	return md
