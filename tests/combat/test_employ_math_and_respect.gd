extends SceneTree
## D-1230/D-1231: unit tests for EmployMath and RespectState (pure data, no combat).

const EmployMath = preload("res://scripts/progression/employ_math.gd")
const RespectState = preload("res://scripts/progression/respect_state.gd")

func _init() -> void:
	print("[TEST] Iniciando suite: test_employ_math_and_respect.gd")
	var success := true

	success = success and _test_power()
	success = success and _test_force_single_member()
	success = success and _test_force_many_members()
	success = success and _test_attributes_over_100()
	success = success and _test_level_component()
	success = success and _test_respect_component()
	success = success and _test_rhythm_bonus()
	success = success and _test_full_case()
	success = success and _test_upper_clamp()
	success = success and _test_lower_clamp()
	success = success and _test_force_division_guard()
	success = success and _test_needs_roll()
	success = success and _test_resolve()
	success = success and _test_respect_start()
	success = success and _test_challenging_limit()
	success = success and _test_boss_feats()
	success = success and _test_tactical_feat()
	success = success and _test_zero_events()
	success = success and _test_defeat_floor()
	success = success and _test_respect_ceiling()
	success = success and _test_expedition_keeps_value_and_feats()

	if success:
		print("EMPLOY_MATH_AND_RESPECT_TEST_PASS")
		quit(0)
	else:
		push_error("[TEST FAILURE] Um ou mais testes falharam.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
	return cond


func _test_power() -> bool:
	var ok := true
	ok = _assert_test(is_equal_approx(EmployMath.power(7.0, 3.0), 7.0), "power(7,3) = 7") and ok
	ok = _assert_test(is_equal_approx(EmployMath.power(3.0, 7.0), 7.0), "power(3,7) = 7") and ok
	ok = _assert_test(is_equal_approx(EmployMath.power(250.0, 120.0), 250.0), "power(250,120) = 250, sem cap em 100") and ok
	return ok


func _test_force_single_member() -> bool:
	var ok := true
	var members := [[10.0, 10.0]]
	var result := EmployMath.breakdown(members, 10.0, 4.0, 10, 10, 50.0, [])
	ok = _assert_test(is_equal_approx(EmployMath.joint_power(members), 10.0), "A de um membro = 10") and ok
	ok = _assert_test(is_equal_approx(float(result["A"]), 10.0), "breakdown A = 10") and ok
	ok = _assert_test(is_equal_approx(float(result["E"]), 10.0), "breakdown E = 10") and ok
	ok = _assert_test(is_equal_approx(float(result["F"]), 22.5), "breakdown F = 22.5") and ok
	ok = _assert_test(is_equal_approx(float(result["N"]), 0.0), "breakdown N = 0") and ok
	ok = _assert_test(is_equal_approx(float(result["R"]), 0.0), "breakdown R = 0") and ok
	ok = _assert_test(is_equal_approx(float(result["B"]), 0.0), "breakdown B = 0") and ok
	ok = _assert_test(is_equal_approx(EmployMath.chance(members, 10.0, 4.0, 10, 10, 50.0, []), 22.5), "P = 22.5") and ok
	return ok


func _test_force_many_members() -> bool:
	var ok := true
	var two := [[10.0, 2.0], [3.0, 10.0]]
	ok = _assert_test(is_equal_approx(EmployMath.joint_power(two), 20.0), "A de dois membros = 20") and ok
	ok = _assert_test(is_equal_approx(EmployMath.force_component(EmployMath.joint_power(two), 10.0), 30.0), "F de dois membros = 30.0") and ok
	var three := [[10.0, 1.0], [10.0, 1.0], [10.0, 1.0]]
	ok = _assert_test(is_equal_approx(EmployMath.force_component(EmployMath.joint_power(three), 10.0), 33.75), "F de três membros = 33.75") and ok
	return ok


func _test_attributes_over_100() -> bool:
	var ok := true
	var members := [[500.0, 1.0]]
	ok = _assert_test(is_equal_approx(EmployMath.joint_power(members), 500.0), "A = 500 sem cap em 100") and ok
	ok = _assert_test(is_equal_approx(EmployMath.force_component(500.0, EmployMath.power(100.0, 20.0)), 37.5), "F = 37.5 contra poder 100") and ok
	return ok


func _test_level_component() -> bool:
	var ok := true
	ok = _assert_test(is_equal_approx(EmployMath.level_component(5, 5), 0.0), "níveis iguais = 0") and ok
	ok = _assert_test(is_equal_approx(EmployMath.level_component(8, 5), 6.0), "(8,5) = 6") and ok
	ok = _assert_test(is_equal_approx(EmployMath.level_component(20, 5), 20.0), "(20,5) = 20 no teto") and ok
	ok = _assert_test(is_equal_approx(EmployMath.level_component(5, 20), -20.0), "(5,20) = -20 no piso") and ok
	ok = _assert_test(is_equal_approx(EmployMath.level_component(15, 5), 20.0), "(15,5) = 20 no teto") and ok
	ok = _assert_test(is_equal_approx(EmployMath.level_component(4, 5), -2.0), "(4,5) = -2") and ok
	return ok


func _test_respect_component() -> bool:
	var ok := true
	ok = _assert_test(is_equal_approx(EmployMath.respect_component(0.0), -8.0), "respeito 0 = -8") and ok
	ok = _assert_test(is_equal_approx(EmployMath.respect_component(50.0), 0.0), "respeito 50 = 0") and ok
	ok = _assert_test(is_equal_approx(EmployMath.respect_component(100.0), 8.0), "respeito 100 = 8") and ok
	return ok


func _test_rhythm_bonus() -> bool:
	var ok := true
	var perfect := [EmployMath.NOTE_PERFECT_BONUS, EmployMath.NOTE_PERFECT_BONUS, EmployMath.NOTE_PERFECT_BONUS]
	ok = _assert_test(is_equal_approx(EmployMath.rhythm_bonus([5.0, 10.0]), 15.0), "[5,10] = 15") and ok
	ok = _assert_test(is_equal_approx(EmployMath.rhythm_bonus(perfect), 30.0), "três PERFECT = 30") and ok
	ok = _assert_test(is_equal_approx(EmployMath.rhythm_bonus([]), 0.0), "sem notas = 0") and ok
	return ok


func _test_full_case() -> bool:
	var ok := true
	var members := [[10.0, 1.0], [10.0, 1.0], [10.0, 1.0]]
	var p := EmployMath.chance(members, 10.0, 1.0, 8, 5, 100.0, [10.0, 5.0, 10.0])
	ok = _assert_test(is_equal_approx(p, 72.75), "caso completo = 72.75") and ok
	return ok


func _test_upper_clamp() -> bool:
	var ok := true
	var members := [[1000.0, 1.0]]
	var result := EmployMath.breakdown(members, 1.0, 1.0, 30, 1, 100.0, [10.0, 10.0, 10.0])
	ok = _assert_test(is_equal_approx(float(result["P"]), 100.0), "P travado em 100") and ok
	ok = _assert_test(float(result["raw"]) > 100.0, "raw acima de 100") and ok
	return ok


func _test_lower_clamp() -> bool:
	var ok := true
	var members := [[1.0, 1.0]]
	var result := EmployMath.breakdown(members, 1000.0, 1.0, 1, 30, 0.0, [])
	ok = _assert_test(is_equal_approx(float(result["P"]), 0.0), "P travado em 0") and ok
	ok = _assert_test(float(result["raw"]) < 0.0, "raw abaixo de 0") and ok
	return ok


func _test_force_division_guard() -> bool:
	var ok := true
	ok = _assert_test(is_equal_approx(EmployMath.force_component(0.0, 0.0), 0.0), "A + E = 0 devolve 0") and ok
	return ok


func _test_needs_roll() -> bool:
	var ok := true
	ok = _assert_test(not EmployMath.needs_roll(0.0), "P = 0 não precisa de rolagem") and ok
	ok = _assert_test(not EmployMath.needs_roll(100.0), "P = 100 não precisa de rolagem") and ok
	ok = _assert_test(EmployMath.needs_roll(0.01), "P = 0.01 precisa de rolagem") and ok
	ok = _assert_test(EmployMath.needs_roll(99.99), "P = 99.99 precisa de rolagem") and ok
	ok = _assert_test(EmployMath.needs_roll(50.0), "P = 50 precisa de rolagem") and ok
	return ok


func _test_resolve() -> bool:
	var ok := true
	ok = _assert_test(EmployMath.resolve(100.0, 99.999), "P = 100 sempre acerta") and ok
	ok = _assert_test(not EmployMath.resolve(0.0, 0.0), "P = 0 sempre falha") and ok
	ok = _assert_test(EmployMath.resolve(50.0, 49.9), "49.9 < 50 acerta") and ok
	ok = _assert_test(not EmployMath.resolve(50.0, 50.0), "50.0 não é < 50") and ok
	ok = _assert_test(not EmployMath.resolve(50.0, 75.0), "75.0 não é < 50") and ok
	return ok


func _test_respect_start() -> bool:
	var ok := true
	var state := RespectState.new()
	ok = _assert_test(state.value == 50, "Respeito começa em 50") and ok
	ok = _assert_test(state.feats().is_empty(), "sem feitos no início") and ok
	ok = _assert_test(state.challenging_rewards_left() == 3, "três recompensas desafiadoras por expedição") and ok
	return ok


func _test_challenging_limit() -> bool:
	var ok := true
	var state := RespectState.new()
	var deltas := []
	for i in range(4):
		deltas.append(state.apply(RespectState.Event.CHALLENGING_ENCOUNTER_WIN))
	ok = _assert_test(deltas[0] == 2 and deltas[1] == 2 and deltas[2] == 2 and deltas[3] == 0, "quatro vitórias desafiadoras pagam 2,2,2,0") and ok
	ok = _assert_test(state.value == 56, "valor 56 após três recompensas") and ok
	state.begin_expedition()
	ok = _assert_test(state.apply(RespectState.Event.CHALLENGING_ENCOUNTER_WIN) == 2, "nova expedição paga 2 de novo na quinta") and ok
	ok = _assert_test(state.value == 58, "valor 58") and ok
	return ok


func _test_boss_feats() -> bool:
	var ok := true
	var state := RespectState.new()
	ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "boss_a") == 6, "primeira vitória no boss_a paga 6") and ok
	ok = _assert_test(state.value == 56, "valor 56") and ok
	ok = _assert_test(state.has_feat("boss_a"), "boss_a registrado") and ok
	ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "boss_a") == 0, "boss_a repetido paga 0") and ok
	ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "boss_b") == 6, "boss_b paga 6") and ok
	ok = _assert_test(state.value == 62, "valor 62") and ok
	ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "") == 0, "id vazio paga 0") and ok
	ok = _assert_test(state.value == 62, "valor continua 62") and ok
	ok = _assert_test(state.has_feat("boss_b"), "boss_b registrado") and ok
	ok = _assert_test(not state.has_feat("boss_c"), "boss_c não registrado") and ok
	return ok


func _test_tactical_feat() -> bool:
	var ok := true
	var state := RespectState.new()
	ok = _assert_test(state.apply(RespectState.Event.TACTICAL_CHALLENGE, "tc_1") == 3, "desafio tático paga 3") and ok
	ok = _assert_test(state.value == 53, "valor 53") and ok
	ok = _assert_test(state.apply(RespectState.Event.TACTICAL_CHALLENGE, "tc_1") == 0, "desafio tático repetido paga 0") and ok
	ok = _assert_test(state.value == 53, "valor continua 53") and ok
	return ok


func _test_zero_events() -> bool:
	var ok := true
	var state := RespectState.new()
	var events := [
		RespectState.Event.STRATEGIC_RETREAT,
		RespectState.Event.EMPLOY_FAILURE,
		RespectState.Event.EMPLOY_SUCCESS,
		RespectState.Event.WEAK_ENEMY_REPEAT,
	]
	for event in events:
		ok = _assert_test(state.apply(event) == 0, "evento neutro paga 0") and ok
	ok = _assert_test(state.value == 50, "valor inalterado") and ok
	ok = _assert_test(state.feats().is_empty(), "nenhum feito registrado") and ok
	return ok


func _test_defeat_floor() -> bool:
	var ok := true
	var state := RespectState.new()
	var deltas := []
	for i in range(30):
		deltas.append(state.apply(RespectState.Event.EXPEDITION_DEFEAT))
	ok = _assert_test(state.value == 0, "trinta derrotas chegam a 0") and ok
	ok = _assert_test(deltas[24] == -2, "a 25ª derrota ainda paga -2") and ok
	ok = _assert_test(deltas[29] == 0, "as últimas derrotas pagam 0") and ok
	return ok


func _test_respect_ceiling() -> bool:
	var ok := true
	var state := RespectState.new()
	for i in range(8):
		ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "boss_%d" % i) == 6, "chefe distinto paga 6") and ok
	ok = _assert_test(state.value == 98, "valor 98 após oito chefes distintos") and ok
	ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "boss_8") == 2, "de 98 um chefe paga só 2") and ok
	ok = _assert_test(state.value == 100, "valor 100") and ok
	ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "boss_9") == 0, "em 100 um chefe paga 0") and ok
	ok = _assert_test(state.value == 100, "valor continua 100") and ok
	ok = _assert_test(state.challenging_rewards_left() == 3, "três recompensas disponíveis") and ok
	ok = _assert_test(state.apply(RespectState.Event.CHALLENGING_ENCOUNTER_WIN) == 0, "desafiadora em 100 paga 0") and ok
	ok = _assert_test(state.challenging_rewards_left() == 2, "mas consome uma das três recompensas") and ok
	ok = _assert_test(state.value == 100, "valor continua 100") and ok
	return ok


func _test_expedition_keeps_value_and_feats() -> bool:
	var ok := true
	var state := RespectState.new()
	ok = _assert_test(state.apply(RespectState.Event.IMPORTANT_BOSS_FIRST_WIN, "boss_a") == 6, "chefe paga 6") and ok
	ok = _assert_test(state.apply(RespectState.Event.CHALLENGING_ENCOUNTER_WIN) == 2, "desafiadora paga 2") and ok
	state.begin_expedition()
	ok = _assert_test(state.value == 58, "valor sobrevive ao begin_expedition") and ok
	ok = _assert_test(state.has_feat("boss_a"), "feito sobrevive ao begin_expedition") and ok
	ok = _assert_test(state.challenging_rewards_left() == 3, "contador de recompensas volta a 3") and ok
	return ok
