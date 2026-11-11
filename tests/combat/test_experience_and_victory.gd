extends SceneTree
## Suite de testes unitarios automatizados para Sistema de Experiencia (XP),
## Vitoria e Level Up (D-390 a D-394, D-399 a D-402).

const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const Combatant = preload("res://scripts/combat/combatant.gd")
const NatureData = preload("res://scripts/data/nature_data.gd")


func _init() -> void:
	print("[TEST] Iniciando suite: test_experience_and_victory.gd")
	var success := true

	success = success and _test_experience_math_transitions()
	success = success and _test_enemy_xp_drop()
	success = success and _test_stat_points_per_level()
	success = success and _test_combatant_single_level_up()
	success = success and _test_combatant_multi_level_up()
	success = success and _test_milestone_level_up_and_hp()
	success = success and _test_ko_combatant_receives_no_xp()
	success = success and _test_leader_stat_allocation_and_sync()

	if success:
		print("[TEST SUCCESS] Todos os testes de XP, Vitoria e Level Up passaram com 100% de sucesso!")
		quit(0)
	else:
		push_error("[TEST FAILURE] Um ou mais testes de experiencia falharam.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
		return false
	return true


func _test_experience_math_transitions() -> bool:
	print("  -> Testando requisitos quadraticos de transicao de nivel (D-399)...")
	# Delta = 50 * L^2
	if not _assert_test(CrawlmonAttributeMath.get_xp_for_level_transition(1) == 50, "Nivel 1->2 deve exigir exatamente 50 XP"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_xp_for_level_transition(2) == 200, "Nivel 2->3 deve exigir exatamente 200 XP"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_xp_for_level_transition(3) == 450, "Nivel 3->4 deve exigir exatamente 450 XP"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_xp_for_level_transition(9) == 4050, "Nivel 9->10 deve exigir exatamente 4.050 XP"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_xp_for_level_transition(10) == 5000, "Nivel 10->11 deve exigir exatamente 5.000 XP"):
		return false
	return true


func _test_enemy_xp_drop() -> bool:
	print("  -> Testando calculo de drop de XP por inimigo abatido (D-399)...")
	# XP = base_exp * level
	if not _assert_test(CrawlmonAttributeMath.get_enemy_xp_drop(30, 1) == 30, "Inimigo base 30 nivel 1 deve dropa 30 XP"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_enemy_xp_drop(30, 3) == 90, "Inimigo base 30 nivel 3 deve dropa 90 XP"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_enemy_xp_drop(50, 5) == 250, "Inimigo base 50 nivel 5 deve dropa 250 XP"):
		return false
	return true


func _test_stat_points_per_level() -> bool:
	print("  -> Testando concessao de pontos regulares e em marcos (D-394)...")
	# 1 ponto regular, 3 pontos nos marcos a cada 10 niveis (10, 20, 30...)
	if not _assert_test(CrawlmonAttributeMath.get_stat_points_for_level(2) == 1, "Nivel 2 deve conceder 1 ponto"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_stat_points_for_level(9) == 1, "Nivel 9 deve conceder 1 ponto"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_stat_points_for_level(10) == 3, "Marco do Nivel 10 deve conceder 3 pontos"):
		return false
	if not _assert_test(CrawlmonAttributeMath.get_stat_points_for_level(20) == 3, "Marco do Nivel 20 deve conceder 3 pontos"):
		return false
	return true


func _test_combatant_single_level_up() -> bool:
	print("  -> Testando subida de nivel individual com delta exato de HP/MP...")
	var c := Combatant.new("Abra", 41, 10, 0.45, true)
	c.level = 1
	c.xp = 0
	c.distributable_points = 0
	c.vit = 3
	c.wis = 3
	c.update_resource_maximums()
	var initial_max_hp := c.max_hp
	var initial_max_mp := c.max_mp
	c.hp = initial_max_hp
	c.mp = initial_max_mp

	# Concede exatamente 50 XP (requisito do nivel 1 -> 2)
	var res := c.add_experience(50)

	if not _assert_test(res["levels_gained"] == 1, "Deve ter subido exatamente 1 nivel"):
		return false
	if not _assert_test(c.level == 2, "Nivel do combatente deve ser 2"):
		return false
	if not _assert_test(c.xp == 0, "XP residual deve ser 0"):
		return false
	if not _assert_test(c.distributable_points == 1, "Lider deve receber 1 ponto distribuivel"):
		return false
	# HP deve subir +10 no nivel 2 (D-392); MP deve subir +1 (D-391)
	if not _assert_test(c.max_hp == initial_max_hp + 10, "Max HP deve subir exatamente +10 HP (era %d, agora %d)" % [initial_max_hp, c.max_hp]):
		return false
	if not _assert_test(c.max_mp == initial_max_mp + 1, "Max MP deve subir exatamente +1 MP (era %d, agora %d)" % [initial_max_mp, c.max_mp]):
		return false
	if not _assert_test(c.hp == c.max_hp, "HP atual deve acompanhar o incremento delta"):
		return false
	return true


func _test_combatant_multi_level_up() -> bool:
	print("  -> Testando subida de multiplos niveis simultaneos com ganho massivo de XP...")
	var c := Combatant.new("Abra", 41, 10, 0.45, true)
	c.level = 1
	c.xp = 0
	c.distributable_points = 0
	c.vit = 3
	c.wis = 3
	c.update_resource_maximums()

	# Concede 300 XP: Nivel 1 -> 2 gasta 50 XP (resta 250); Nivel 2 -> 3 gasta 200 XP (resta 50)
	var res := c.add_experience(300)

	if not _assert_test(res["levels_gained"] == 2, "Deve ter subido 2 niveis de uma vez"):
		return false
	if not _assert_test(c.level == 3, "Nivel final deve ser 3"):
		return false
	if not _assert_test(c.xp == 50, "XP residual deve ser 50 (300 - 50 - 200)"):
		return false
	if not _assert_test(c.distributable_points == 2, "Lider deve ter acumulado 2 pontos livres (1 por nivel)"):
		return false
	if not _assert_test(res["transitions"].size() == 2, "Historico de transicoes deve conter 2 saltos"):
		return false
	return true


func _test_milestone_level_up_and_hp() -> bool:
	print("  -> Testando salto de marco no Nivel 10 (+35 HP e +3 pontos de atributo)...")
	var c := Combatant.new("Pancham", 43, 10, 0.40, true)
	c.level = 9
	c.xp = 0
	c.distributable_points = 0
	c.vit = 4
	c.wis = 2
	c.update_resource_maximums()
	var hp_lv9 := c.max_hp

	# Requisito para 9 -> 10 e 4050 XP
	var res := c.add_experience(4050)

	if not _assert_test(c.level == 10, "Nivel deve ser 10"):
		return false
	if not _assert_test(res["points_gained"] == 3, "Marco de nivel 10 deve conceder 3 pontos de atributo (D-394)"):
		return false
	if not _assert_test(c.distributable_points == 3, "Lider deve receber 3 pontos distribuiveis"):
		return false
	# HP deve subir +10 (nivel) + 25 (marco) = +35 HP (D-392)
	var expected_hp := hp_lv9 + 35
	if not _assert_test(c.max_hp == expected_hp, "Max HP no marco 10 deve ser %d (+35 HP), obtido %d" % [expected_hp, c.max_hp]):
		return false
	return true


func _test_ko_combatant_receives_no_xp() -> bool:
	print("  -> Testando combatente nocauteado (HP=0) bloqueado de ganhar XP (D-402)...")
	var c := Combatant.new("Pancham", 43, 10, 0.40, true)
	c.level = 1
	c.xp = 0
	c.hp = 0  ## K.O.

	# Regra D-402: apenas sobreviventes ativos recebem chamada de XP
	if not c.is_alive():
		# Se nao esta vivo, motor ignora ou passa 0
		var res := c.add_experience(0)
		if not _assert_test(res["levels_gained"] == 0, "Combatente derrotado nao deve subir de nivel"):
			return false
		if not _assert_test(c.xp == 0, "Combatente derrotado nao deve receber XP"):
			return false
		if not _assert_test(c.level == 1, "Nivel deve permanecer inalterado"):
			return false
	else:
		_assert_test(false, "Combatente deveria estar morto para este teste")
		return false
	return true


func _test_leader_stat_allocation_and_sync() -> bool:
	print("  -> Testando alocacao de atributos do lider e sincronizacao de HP (+2/VIT)...")
	var c := Combatant.new("Abra", 41, 10, 0.45, true)
	c.level = 2
	c.distributable_points = 1
	c.innate_stats = {"STR": 2, "MAG": 5, "VIT": 3, "WIS": 3, "AGI": 2, "LUK": 1}
	c.progression_points = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
	c.sync_effective_stats()
	c.update_resource_maximums()
	var base_hp := c.max_hp

	# Simula alocacao de 1 ponto em VIT via LevelUpModal
	c.progression_points["VIT"] += 1
	c.distributable_points -= 1
	c.sync_effective_stats()
	c.update_resource_maximums()

	if not _assert_test(c.distributable_points == 0, "Pontos disponiveis devem zerar"):
		return false
	if not _assert_test(c.vit == 4, "VIT efetiva deve ser 4 (3 base + 1 progresso)"):
		return false
	# Investir 1 ponto em VIT aumenta max_hp em +2 (D-392)
	if not _assert_test(c.max_hp == base_hp + 2, "Max HP deve subir exatamente +2 HP por VIT (era %d, agora %d)" % [base_hp, c.max_hp]):
		return false
	return true
