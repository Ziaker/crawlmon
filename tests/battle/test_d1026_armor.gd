extends SceneTree
## D-1026: Armored Bulk (10 MP, 1 ATB, SELF, instant wind-up, engine paused 1,5 s) e a badge ARMOR (8 s; o primeiro
## contato de Move é sofrido sem interrupção, sem efeito de contato e sem knockback; Guard tem prioridade; Burn não a gasta).
## Roda com: godot --headless --path . --script res://tests/battle/test_d1026_armor.gd


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — TESTES DA ARMOR (D-1026)")
	print("=================================================================")

	var b := Battle.new()
	var hero := Combatant.new("Orc", 100, 10, 0.45, true)
	hero.max_mp = 20
	hero.mp = 20
	var bulk := Skill.new("Armored Bulk", 0.0, 1, Element.Type.TERRA, Skill.Kind.STATUS, false, false, true, 0.0)
	hero.skills.append(bulk)
	var foe := Combatant.new("Cyclops", 100, 10, 0.42, false)
	foe.max_mp = 20
	foe.mp = 20
	var party: Array[Combatant] = [hero]
	var foes: Array[Combatant] = [foe]
	b.start(party, foes)
	b.debug_roll = 1
	var states: Array[String] = []
	b.armor_changed.connect(func(_c: Combatant, s: String) -> void: states.append(s))

	# 1. Ficha: 10 MP, 1 ATB, elemento Terra, STATUS, wind-up instantâneo.
	assert(bulk.mp_cost == 10, "Armored Bulk custa 10 MP")
	assert(bulk.cost == 1 and bulk.kind == Skill.Kind.STATUS and bulk.element == Element.Type.TERRA)
	assert(bulk.windup == 0.0, "Wind-up instantâneo")
	print("  [PASS] Ficha: 10 MP, 1 ATB, STATUS, TERRA, wind-up instantâneo.")

	# 2. Uso: SELF mesmo mirando o inimigo, paga MP e ATB, pausa o motor 1,5 s, concede 8 s de ARMOR.
	hero.atb = 3.0
	assert(b.use_skill(hero, bulk, foe), "O Move começa")
	assert(is_equal_approx(hero.atb, 2.0) and hero.mp == 10, "Paga 1 ATB e 10 MP")
	var inc := b.incoming[0]
	assert(inc.target == hero, "SELF: o alvo é o próprio usuário")
	var paused := 0.0
	var guard_loop := 0
	while b._status_pause != null and guard_loop < 4000:
		b._process(0.01)
		paused += 0.01
		guard_loop += 1
	assert(hero.is_armored(), "O usuário ganhou a ARMOR")
	assert(paused >= 1.45 and paused <= 1.75, "Motor pausado por ~1,5 s (medido %.2f)" % paused)
	assert(is_equal_approx(hero.armor_timer, 8.0), "ARMOR com 8 s (a pausa não conta)")
	print("  [PASS] SELF, 1 ATB + 10 MP, pausa de %.2f s e ARMOR de 8 s." % paused)

	# 3. Recast: soma 8 s ao que resta, a badge não empilha; custa de novo.
	b._process(0.5)
	assert(is_equal_approx(hero.armor_timer, 7.5))
	hero.atb = 3.0
	assert(b.use_skill(hero, bulk, hero), "Recast com ARMOR ativa é permitido e custa de novo")
	assert(hero.mp == 0)
	while b._status_pause != null:
		b._process(0.01)
	assert(is_equal_approx(hero.armor_timer, 15.5), "Recast soma +8 s ao tempo restante (7,5 + 8)")
	print("  [PASS] Recast soma +8 s ao que resta e cobra de novo.")

	# 4. Contato: dano normal, sem interrupção, a badge some.
	hero.armor_timer = 8.0
	hero.set_hp_instant(100)
	var info := b._hit(foe, hero, 1.0, Element.Type.FISICO, "Tackle")
	assert(int(info["dmg"]) == 10, "O dano é normal")
	assert(info["armor"] == "hit" and not hero.is_armored(), "A badge é destruída")
	assert(info["guard"] == "" and info["interrupted"] == false, "Sem interrupção")
	assert(states.has("hit"))
	var again := b._hit(foe, hero, 1.0, Element.Type.FISICO, "Tackle")
	assert(again["armor"] == "", "Sem badge, o contato é normal")
	print("  [PASS] O primeiro contato causa dano normal, sem interrupção, e destrói a badge.")

	# 5. Efeito de contato anulado (Electric Beam: STUN de 4 s com chance; força a chance com LUK enorme).
	foe.luk = 1000
	hero.luk = 1
	hero.armor_timer = 8.0
	hero.stun_timer = 0.0
	var stunned := 0
	for i in 40:
		hero.set_hp_instant(100)
		hero.armor_timer = 8.0
		hero.stun_timer = 0.0
		b._hit(foe, hero, 1.0, Element.Type.RAIO, "Electric Beam")
		if hero.is_stunned():
			stunned += 1
	assert(stunned == 0, "Armor anula o STUN de contato")
	var stunned_no_armor := 0
	for i in 40:
		hero.set_hp_instant(100)
		hero.stun_timer = 0.0
		b._hit(foe, hero, 1.0, Element.Type.RAIO, "Electric Beam")
		if hero.is_stunned():
			stunned_no_armor += 1
	assert(stunned_no_armor > 0, "Sem Armor o STUN acontece (controle do teste)")
	print("  [PASS] ARMOR anula o STUN de contato (controle sem ARMOR: %d/40)." % stunned_no_armor)

	# 6. Guard tem prioridade: não gasta a badge, que continua contando durante o Guard.
	hero.stun_timer = 0.0
	hero.set_hp_instant(100)
	hero.armor_timer = 8.0
	hero.atb = 3.0
	assert(b.use_guard(hero))
	info = b._hit(foe, hero, 1.0, Element.Type.FISICO, "Tackle")
	assert(info["guard"] == "absorbed" and info["armor"] == "", "Guard absorve e não gasta a ARMOR")
	assert(hero.is_armored(), "A ARMOR continua depois do contato com Guard")
	hero.armor_timer = 8.0
	hero.atb = 3.0
	assert(b.use_guard(hero))
	hero.tick_armor(1.0)
	assert(is_equal_approx(hero.armor_timer, 7.0), "A duração continua a diminuir durante o Guard")
	hero.end_guard("hit")
	print("  [PASS] Guard tem prioridade e a ARMOR segue contando.")

	# 7. Burn não gasta a ARMOR.
	hero.armor_timer = 8.0
	hero.apply_burn()
	b._tick_burn(hero, 1.0)
	assert(hero.is_armored(), "Dano de status não destrói a ARMOR")
	hero.clear_burn()
	print("  [PASS] Burn não destrói a ARMOR.")

	# 8. Expira em 8 s e o fim da batalha limpa.
	hero.armor_timer = 0.3
	states.clear()
	hero.tick_armor(0.5)
	assert(not hero.is_armored() and states == ["expired"], "Expira")
	hero.armor_timer = 5.0
	foe.hp = 0
	b._check_end()
	assert(not hero.is_armored(), "O fim da batalha limpa a ARMOR")
	print("  [PASS] A ARMOR expira e é limpa no fim da batalha.")

	print("\n=== TODOS OS TESTES D-1026 PASSARAM ===\n")
	quit()
