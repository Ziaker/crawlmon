extends SceneTree

func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — TESTES DE AÇÕES COM 1 ATB (D-040)")
	print("=================================================================")

	var b := Battle.new()

	var player := Combatant.new("Abra", 32, 10, 0.5, true)
	player.skills.clear()
	# Inicialmente só tem golpe de 2 ATB
	player.skills.append(Skill.new("Bite", 1.2, 2, Element.Type.TREVAS, Skill.Kind.MELEE, false, false, false, 1.2))

	var enemy := Combatant.new("Gible", 38, 9, 0.42, false)
	enemy.skills.clear()
	enemy.skills.append(Skill.new("Bite", 1.2, 2, Element.Type.TREVAS, Skill.Kind.MELEE, false, false, false, 1.2))

	var party: Array[Combatant] = [player]
	var foes: Array[Combatant] = [enemy]
	b.start(party, foes)

	# 1. Com apenas golpes de 2 ATB: custo mínimo deve ser 2.0
	assert(Battle.min_skill_cost(player) == 2.0, "Custo mínimo inicial deve ser 2.0")
	player.atb = 1.0
	assert(not player.can_pay(Battle.min_skill_cost(player)), "Com 1 ATB e sem golpes de 1 ATB, can_pay deve ser false")
	print("  [PASS] Com apenas golpes de 2 ATB, jogador com 1 ATB não pode lutar.")

	# 2. Adiciona golpe de 1 ATB (ex: Sand Attack ou Rakunda)
	var sand_attack := Skill.new("Sand Attack", 0.0, 1, Element.Type.TERRA, Skill.Kind.PROJECTILE, true, false, false, 0.75)
	player.skills.append(sand_attack)

	assert(Battle.min_skill_cost(player) == 1.0, "Custo mínimo agora deve ser 1.0")
	assert(player.can_pay(Battle.min_skill_cost(player)), "Com 1 ATB e golpe de 1 ATB, can_pay deve ser true")
	print("  [PASS] Custo mínimo com golpe de 1 ATB passa a ser 1.0, permitindo agir com 1 ATB.")

	# 3. Execução da habilidade de 1 ATB
	var used := b.use_skill(player, sand_attack, enemy)
	assert(used, "b.use_skill deve ter sucesso com 1 ATB")
	assert(is_equal_approx(player.atb, 0.0), "ATB deve ser consumido em 1.0 bloco, restando 0.0")
	print("  [PASS] Golpe de 1 ATB executado com sucesso e 1 bloco de ATB consumido.")

	# 4. Burst mode
	player.atb = 0.0
	player.burst = 1
	assert(Battle.min_skill_cost(player) == 0.0, "Em Burst, custo mínimo deve ser 0.0")
	assert(player.can_pay(Battle.min_skill_cost(player)), "Em Burst, can_pay deve ser true mesmo com 0 ATB")
	print("  [PASS] Em Burst, custo mínimo é 0.0 permitindo ação grátis.")
	player.burst = 0

	# 5. Validação da IA (D-021)
	enemy.skills.append(Skill.new("Rakunda", 0.0, 1, Element.Type.TREVAS, Skill.Kind.STATUS, false, false, false, 0.5))
	enemy.act_policy = Combatant.Act.SKILL
	enemy.atb = 1.0
	assert(Battle.min_skill_cost(enemy) == 1.0, "Inimigo com Rakunda deve ter custo mínimo 1.0")
	assert(enemy.can_pay(Battle.min_skill_cost(enemy)), "Inimigo com 1 ATB deve poder pagar seu golpe de 1 ATB")

	var sk := b._pick_skill(enemy)
	assert(sk != null and sk.cost == 1, "IA deve escolher o golpe de 1 ATB quando possui 1 ATB")
	print("  [PASS] IA com 1 ATB escolhe e executa seu golpe de 1 ATB (simetria D-021).")

	print("\n=== TODOS OS TESTES D-040 PASSARAM COM SUCESSO (100%) ===\n")
	quit()
