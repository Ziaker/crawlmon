extends SceneTree
## Suite de testes unitarios automatizados para geracao de encontros de inimigos (D-405, D-390, D-392, D-393, D-399).

const EnemyFactory = preload("res://scripts/combat/enemy_factory.gd")
const CharacterCatalog = preload("res://scripts/data/character_catalog.gd")
const Combatant = preload("res://scripts/combat/combatant.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const Element = preload("res://scripts/data/element.gd")
const NatureData = preload("res://scripts/data/nature_data.gd")

func _init() -> void:
	print("[TEST] Iniciando suite: test_enemy_encounter_generation.gd")
	var success := true

	success = success and _test_species_15_points_conservation()
	success = success and _test_anti_hitkill_hp_and_mp()
	success = success and _test_species_skills_weaknesses_and_traits()
	success = success and _test_party_size_distribution_10000_trials()
	success = success and _test_species_pool_coverage_and_duplicates()
	success = success and _test_xp_reward_baseline()

	if success:
		print("[TEST SUCCESS] Todos os testes de encontros passaram com 100% de sucesso!")
		quit(0)
	else:
		push_error("[TEST FAILURE] Um ou mais testes de encontros falharam.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
		return false
	return true


func _test_species_15_points_conservation() -> bool:
	print("  -> Testando conservacao de 15 pontos base para todas as 6 especies...")
	for sp in EnemyFactory.ENEMY_SPECIES_POOL:
		var raw_stats: Dictionary = CharacterCatalog.get_character(StringName(sp)).raw_stats
		var base_stats := CrawlmonAttributeMath.convert_species_stats_to_15_points(raw_stats)
		var total_base := 0
		for attr in CrawlmonAttributeMath.ATTRIBUTES:
			total_base += int(base_stats[attr])
		if not _assert_test(total_base == 15, "Especie %s: soma dos atributos base deu %d em vez de 15" % [sp, total_base]):
			return false

		# Gera a entidade e testa os atributos inatos e efetivos
		var enemy := EnemyFactory.create_enemy(sp)
		if not _assert_test(enemy != null, "Falha ao criar inimigo da especie: " + sp):
			return false
		if not _assert_test(not enemy.is_player, "Inimigo nao deve ter is_player = true"):
			return false
		for attr in CrawlmonAttributeMath.ATTRIBUTES:
			var innate_val := int(enemy.innate_stats[attr])
			if not _assert_test(innate_val >= 1, "Atributo inato %s de %s abaixo do piso 1: %d" % [attr, sp, innate_val]):
				return false
	return true


func _test_anti_hitkill_hp_and_mp() -> bool:
	print("  -> Testando formulas de HP anti-hitkill e MP maximo...")
	for sp in EnemyFactory.ENEMY_SPECIES_POOL:
		var enemy := EnemyFactory.create_enemy(sp)
		var expected_hp := 25 + 10 * enemy.level + 2 * enemy.vit
		var expected_mp := 10 + 2 * enemy.wis + enemy.level
		if sp == "abra":
			expected_mp = maxi(expected_mp, 20) # D-413: MP minimo do abra em 20
		if not _assert_test(enemy.max_hp == expected_hp, "HP de %s incorreto: %d (esperado %d)" % [sp, enemy.max_hp, expected_hp]):
			return false
		if not _assert_test(enemy.hp == enemy.max_hp, "HP atual de %s nao inicializado no maximo" % sp):
			return false
		if not _assert_test(enemy.max_mp == expected_mp, "MP maximo de %s incorreto: %d (esperado %d)" % [sp, enemy.max_mp, expected_mp]):
			return false
		if not _assert_test(enemy.mp == enemy.max_mp, "MP atual de %s nao inicializado no maximo" % sp):
			return false
	return true


func _test_species_skills_weaknesses_and_traits() -> bool:
	print("  -> Testando integridade de Skills, Fraquezas e Traços especificos...")
	# 1. Slime
	var slime := EnemyFactory.create_enemy("dqt_slime")
	if not _assert_test(slime.weaknesses == [Element.Type.FOGO], "Slime deve ter fraqueza FOGO"):
		return false
	var slime_skill_names := slime.skills.map(func(s): return s.display_name)
	if not _assert_test("Tackle" in slime_skill_names and "Bubble Shot" in slime_skill_names and "Heal" in slime_skill_names,
		"Slime nao possui o conjunto esperado de skills: " + str(slime_skill_names)):
		return false

	# 2. Orc
	var orc := EnemyFactory.create_enemy("dqt_orc")
	if not _assert_test(orc.weaknesses == [Element.Type.RAIO], "Orc deve ter fraqueza RAIO"):
		return false
	if not _assert_test(is_equal_approx(orc.travel_extra, 0.45), "Orc deve ter travel_extra = 0.45"):
		return false
	var orc_skill_names := orc.skills.map(func(s): return s.display_name)
	if not _assert_test("Spear Thrust" in orc_skill_names and "Drain Spear" in orc_skill_names and "Javelin Throw" in orc_skill_names and "War Cry" in orc_skill_names,
		"Orc nao possui o conjunto esperado de skills: " + str(orc_skill_names)):
		return false

	# 3. Cyclops
	var cyclops := EnemyFactory.create_enemy("dqt_cyclops")
	if not _assert_test(cyclops.weaknesses == [Element.Type.PSIQUICO], "Cyclops deve ter fraqueza PSIQUICO"):
		return false
	if not _assert_test(is_equal_approx(cyclops.travel_extra, 0.8), "Cyclops deve ter travel_extra = 0.8"):
		return false
	var cyclops_skill_names := cyclops.skills.map(func(s): return s.display_name)
	if not _assert_test("Boulder Smash" in cyclops_skill_names and "Rock Throw" in cyclops_skill_names and "Glare" in cyclops_skill_names,
		"Cyclops nao possui o conjunto esperado de skills: " + str(cyclops_skill_names)):
		return false

	# 4. Abra
	var abra := EnemyFactory.create_enemy("abra")
	if not _assert_test(abra.weaknesses == [Element.Type.TREVAS, Element.Type.SOM], "Abra deve ter fraquezas TREVAS e SOM"):
		return false
	var abra_skill_names := abra.skills.map(func(s): return s.display_name)
	if not _assert_test("Confusion" in abra_skill_names and "Psybeam" in abra_skill_names and "Megido" in abra_skill_names,
		"Abra nao possui o conjunto esperado de skills: " + str(abra_skill_names)):
		return false

	# 5. Pancham
	var pancham := EnemyFactory.create_enemy("pancham")
	if not _assert_test(pancham.weaknesses == [Element.Type.PSIQUICO, Element.Type.VENTO], "Pancham deve ter fraquezas PSIQUICO e VENTO"):
		return false
	var pancham_skill_names := pancham.skills.map(func(s): return s.display_name)
	if not _assert_test("Mach Punch" in pancham_skill_names and "Brick Break" in pancham_skill_names and "Hassou Tobi" in pancham_skill_names,
		"Pancham nao possui o conjunto esperado de skills: " + str(pancham_skill_names)):
		return false

	# 6. Gible
	var gible := EnemyFactory.create_enemy("gible")
	if not _assert_test(gible.weaknesses == [Element.Type.AGUA_GELO], "Gible deve ter fraqueza AGUA_GELO"):
		return false
	var gible_skill_names := gible.skills.map(func(s): return s.display_name)
	if not _assert_test("Bite" in gible_skill_names and "Dragon Rage" in gible_skill_names and "Titanomachia" in gible_skill_names,
		"Gible nao possui o conjunto esperado de skills: " + str(gible_skill_names)):
		return false

	return true


func _test_party_size_distribution_10000_trials() -> bool:
	print("  -> Testando distribuicao estocastica de tamanhos de grupo (10.000 ensaios Monte Carlo)...")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts := {1: 0, 2: 0, 3: 0}
	var total := 10000

	for i in total:
		var sz := EnemyFactory.roll_party_size(rng)
		counts[sz] = counts.get(sz, 0) + 1

	var p1 := float(counts[1]) / float(total)
	var p2 := float(counts[2]) / float(total)
	var p3 := float(counts[3]) / float(total)

	print("     Resultados obtidos: Solo=%.2f%% (alvo 55%%), Dupla=%.2f%% (alvo 30%%), Trio=%.2f%% (alvo 15%%)" % [
		p1 * 100.0, p2 * 100.0, p3 * 100.0
	])

	# Margens estatisticas seguras para 10.000 amostras (3 sigma < 1.5%)
	if not _assert_test(p1 >= 0.53 and p1 <= 0.57, "Taxa de solo fora da margem esperada: " + str(p1)):
		return false
	if not _assert_test(p2 >= 0.28 and p2 <= 0.32, "Taxa de dupla fora da margem esperada: " + str(p2)):
		return false
	if not _assert_test(p3 >= 0.13 and p3 <= 0.17, "Taxa de trio fora da margem esperada: " + str(p3)):
		return false

	return true


func _test_species_pool_coverage_and_duplicates() -> bool:
	print("  -> Testando cobertura da pool de 6 especies e presenca de duplicatas...")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9999
	var seen_species: Dictionary = {}
	var has_duplicate_in_group := false

	for i in 500:
		var encounter := EnemyFactory.roll_encounter(rng)
		if not _assert_test(encounter.size() >= 1 and encounter.size() <= 3, "Tamanho de encontro invalido: %d" % encounter.size()):
			return false

		var species_in_this_group: Array[String] = []
		for e in encounter:
			seen_species[e.species_id] = true
			if e.species_id in species_in_this_group:
				has_duplicate_in_group = true
			species_in_this_group.append(e.species_id)

	for sp in EnemyFactory.ENEMY_SPECIES_POOL:
		if not _assert_test(seen_species.has(sp), "Especie %s nunca foi sorteada nos encontros!" % sp):
			return false

	if not _assert_test(has_duplicate_in_group, "Nenhuma duplicata observada em 500 encontros (duplicatas devem ser permitidas)"):
		return false

	return true


func _test_xp_reward_baseline() -> bool:
	print("  -> Testando base_experience = 30 em todas as especies...")
	for sp in EnemyFactory.ENEMY_SPECIES_POOL:
		var enemy := EnemyFactory.create_enemy(sp)
		if not _assert_test(enemy.base_experience == 30, "base_experience de %s incorreto: %d (esperado 30)" % [sp, enemy.base_experience]):
			return false
	return true
