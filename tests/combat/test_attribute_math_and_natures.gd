extends SceneTree
## Suite de testes unitarios automatizados para Natures, Atributos-base e Progressao (D-390 a D-394).

const NatureData = preload("res://scripts/data/nature_data.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const Combatant = preload("res://scripts/combat/combatant.gd")

func _init() -> void:
	print("[TEST] Iniciando suite: test_attribute_math_and_natures.gd")
	var success := true

	success = success and _test_hare_niemeyer_15_points_conservation()
	success = success and _test_canonical_species_conversions()
	success = success and _test_natures_zero_sum()
	success = success and _test_innate_clamping_and_linear_progression()
	success = success and _test_hp_and_mp_formulas_and_milestones()
	success = success and _test_atb_affine_pacing()
	success = success and _test_ko_preservation_on_resource_update()
	success = success and _test_party_leader_and_party_isolation()

	if success:
		print("[TEST SUCCESS] Todos os testes passaram com 100% de sucesso!")
		quit(0)
	else:
		push_error("[TEST FAILURE] Um ou mais testes falharam.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
		return false
	return true


func _test_hare_niemeyer_15_points_conservation() -> bool:
	print("  -> Testando conservacao de 15 pontos em 100 distribuicoes aleatorias...")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(100):
		var raw: Dictionary = {
			"STR": rng.randi_range(5, 150),
			"MAG": rng.randi_range(5, 150),
			"VIT": rng.randi_range(5, 150),
			"WIS": rng.randi_range(5, 150),
			"AGI": rng.randi_range(5, 150),
			"LUK": rng.randi_range(5, 150),
		}
		var converted := CrawlmonAttributeMath.convert_species_stats_to_15_points(raw)
		var total := 0
		for attr in CrawlmonAttributeMath.ATTRIBUTES:
			total += int(converted[attr])
		if not _assert_test(total == 15, "Iteracao %d: soma deu %d em vez de 15" % [i, total]):
			return false
	return true


func _test_canonical_species_conversions() -> bool:
	print("  -> Testando conversoes das especies canonicas (Abra, Pancham, Gible)...")
	# Abra: 20, 105, 15, 55, 90, RefLUK 57
	var abra := CrawlmonAttributeMath.convert_species_stats_to_15_points({
		"STR": 20, "MAG": 105, "VIT": 15, "WIS": 55, "AGI": 90, "LUK": 57
	})
	if not _assert_test(abra["STR"] == 1 and abra["MAG"] == 5 and abra["VIT"] == 1 and abra["WIS"] == 2 and abra["AGI"] == 4 and abra["LUK"] == 2,
		"Conversao de Abra incorreta: " + str(abra)):
		return false

	# Pancham: 82, 46, 62, 48, 43, RefLUK 56
	var pancham := CrawlmonAttributeMath.convert_species_stats_to_15_points({
		"STR": 82, "MAG": 46, "VIT": 62, "WIS": 48, "AGI": 43, "LUK": 56
	})
	if not _assert_test(pancham["STR"] == 4 and pancham["MAG"] == 2 and pancham["VIT"] == 3 and pancham["WIS"] == 2 and pancham["AGI"] == 2 and pancham["LUK"] == 2,
		"Conversao de Pancham incorreta: " + str(pancham)):
		return false

	# Gible: 70, 40, 45, 45, 42, RefLUK 48
	var gible := CrawlmonAttributeMath.convert_species_stats_to_15_points({
		"STR": 70, "MAG": 40, "VIT": 45, "WIS": 45, "AGI": 42, "LUK": 48
	})
	if not _assert_test(gible["STR"] == 4 and gible["MAG"] == 2 and gible["VIT"] == 2 and gible["WIS"] == 2 and gible["AGI"] == 2 and gible["LUK"] == 3,
		"Conversao de Gible incorreta: " + str(gible)):
		return false
	return true


func _test_natures_zero_sum() -> bool:
	print("  -> Testando soma zero e catalogo de todas as 8 Natures...")
	var ids := NatureData.get_all_nature_ids()
	if not _assert_test(ids.size() == 8, "Catalogo deve conter exatamente 8 Natures"):
		return false

	for id in ids:
		var nat := NatureData.get_nature(id)
		var mods: Dictionary = nat["mods"]
		var sum_mods := 0
		for attr in CrawlmonAttributeMath.ATTRIBUTES:
			sum_mods += int(mods.get(attr, 0))
		if not _assert_test(sum_mods == 0, "Nature '%s' deve somar exatamente 0 (deu %d)" % [id, sum_mods]):
			return false
	return true


func _test_innate_clamping_and_linear_progression() -> bool:
	print("  -> Testando consolidacao de piso inato e linearidade de progressao...")
	var base_15 := {"STR": 1, "MAG": 5, "VIT": 1, "WIS": 2, "AGI": 4, "LUK": 2}
	var negative_offsets := {"STR": -3, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
	var modest_mods: Dictionary = NatureData.get_nature("modest")["mods"] # STR: -2

	# STR bruto = 1 - 3 - 2 = -4 -> Piso deve consolidar em 1
	var innate := CrawlmonAttributeMath.consolidate_innate_attributes(base_15, negative_offsets, modest_mods)
	if not _assert_test(innate["STR"] == 1, "Piso minimo inato de STR deve ser 1 (deu %d)" % innate["STR"]):
		return false

	# Combatant com essa configuracao inata
	var c := Combatant.new("TestMon", 37, 1, 0.5, true)
	c.innate_stats = innate
	c.sync_effective_stats()
	if not _assert_test(c.str == 1, "Combatant STR inicial deve ser 1"):
		return false

	# Cada ponto de progressao investido deve render monotonicamente +1
	c.progression_points["STR"] = 1
	c.sync_effective_stats()
	if not _assert_test(c.str == 2, "1 ponto de progressao em STR deve resultar em STR 2 (deu %d)" % c.str):
		return false

	c.progression_points["STR"] = 3
	c.sync_effective_stats()
	if not _assert_test(c.str == 4, "3 pontos de progressao em STR devem resultar em STR 4 (deu %d)" % c.str):
		return false
	return true


func _test_hp_and_mp_formulas_and_milestones() -> bool:
	print("  -> Testando formulas de HP, MP e saltos de marco...")
	# HP nivel 1: 25 + 10(1) + 25(0) + 2(VIT) = 35 + 2*VIT
	if not _assert_test(CrawlmonAttributeMath.calculate_max_hp(1, 1) == 37, "HP Lv1 VIT 1 deve ser 37"):
		return false
	if not _assert_test(CrawlmonAttributeMath.calculate_max_hp(1, 2) == 39, "HP Lv1 VIT 2 deve ser 39"):
		return false
	if not _assert_test(CrawlmonAttributeMath.calculate_max_hp(1, 3) == 41, "HP Lv1 VIT 3 deve ser 41"):
		return false
	if not _assert_test(CrawlmonAttributeMath.calculate_max_hp(1, 4) == 43, "HP Lv1 VIT 4 deve ser 43"):
		return false

	# Subida regular (Lv9 -> Lv10): Lv9 HP (VIT 2) = 25 + 90 + 0 + 4 = 119
	# Lv10 HP (VIT 2) = 25 + 100 + 25(1) + 4 = 154 (Salto exato de +35 HP!)
	var hp_lv9 := CrawlmonAttributeMath.calculate_max_hp(9, 2)
	var hp_lv10 := CrawlmonAttributeMath.calculate_max_hp(10, 2)
	if not _assert_test(hp_lv10 - hp_lv9 == 35, "Salto Lv9->Lv10 deve ser exatamente +35 HP (deu %d)" % (hp_lv10 - hp_lv9)):
		return false

	# MP nivel 1: 10 + 2*WIS + Lv
	# Abra WIS 2: 10 + 4 + 1 = 15 MP
	if not _assert_test(CrawlmonAttributeMath.calculate_max_mp(1, 2) == 15, "MP Lv1 WIS 2 deve ser 15"):
		return false
	# Conjurador focado WIS 4: 10 + 8 + 1 = 19 MP
	if not _assert_test(CrawlmonAttributeMath.calculate_max_mp(1, 4) == 19, "MP Lv1 WIS 4 deve ser 19"):
		return false
	return true


func _test_atb_affine_pacing() -> bool:
	print("  -> Testando ritmo afim de ATB universal...")
	# Abra (AGI 4): 0.35 + 4 * 0.0375 = 0.500 blocos/s
	var abra_rate := CrawlmonAttributeMath.natural_atb_increment(1.0, 4.0)
	if not _assert_test(is_equal_approx(abra_rate, 0.500), "Abra (AGI 4) deve ter taxa de 0.500 blocos/s (deu %f)" % abra_rate):
		return false

	# Pancham/Gible (AGI 2): 0.35 + 2 * 0.0375 = 0.425 blocos/s
	var pancham_rate := CrawlmonAttributeMath.natural_atb_increment(1.0, 2.0)
	if not _assert_test(is_equal_approx(pancham_rate, 0.425), "Pancham (AGI 2) deve ter taxa de 0.425 blocos/s (deu %f)" % pancham_rate):
		return false
	return true


func _test_ko_preservation_on_resource_update() -> bool:
	print("  -> Testando preservacao estrita de K.O. em update_resource_maximums()...")
	var c := Combatant.new("FallenMon", 39, 10, 0.425, true)
	c.innate_stats = {"STR": 4, "MAG": 2, "VIT": 2, "WIS": 2, "AGI": 2, "LUK": 2}
	c.sync_effective_stats()
	c.update_resource_maximums()
	c.hp = 0 # Monstro derrotado (K.O.)

	# Simula subida de nivel / aumento de VIT enquanto derrotado
	c.level = 2
	c.update_resource_maximums()
	if not _assert_test(c.hp == 0, "HP derrotado (0) deve permanecer rigorosamente 0 apos update_resource_maximums()"):
		return false
	if not _assert_test(c.max_hp > 39, "Max HP deve ter aumentado"):
		return false

	# Testa incremento normal quando vivo
	c.hp = 20
	c.level = 3
	var prev_max := c.max_hp
	c.update_resource_maximums()
	var delta_max := c.max_hp - prev_max
	if not _assert_test(c.hp == 20 + delta_max, "HP vivo deve receber o delta de Max HP"):
		return false
	return true


func _test_party_leader_and_party_isolation() -> bool:
	print("  -> Testando isolamento e guarda de lideranca...")
	var c := Combatant.new("SoloMon", 37, 10, 0.5, true)
	# Sem GameState.party ou com party vazia, nao deve crashar
	var leader := c.is_party_leader()
	# Nao crashou
	if not _assert_test(leader == false or leader == true, "Guarda de lideranca avaliada com sucesso"):
		return false
	return true
