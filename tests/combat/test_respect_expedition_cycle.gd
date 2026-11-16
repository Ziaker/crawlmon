extends SceneTree
## D-1231/D-1235: Phase 3 — Respect wired into GameState (group, memory only).

const RespectState = preload("res://scripts/progression/respect_state.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[TEST] Iniciando suite: test_respect_expedition_cycle.gd")
	var gs: Object = root.get_node("GameState")
	var success := true

	success = _assert_test(gs.respect.value == 50, "Respect deve começar em 50") and success
	success = _assert_test(gs.respect_log.is_empty(), "respect_log deve começar vazio") and success

	var defect_delta: int = gs.apply_respect(RespectState.Event.EXPEDITION_DEFEAT, "test")
	success = _assert_test(defect_delta == -2, "EXPEDITION_DEFEAT deve aplicar -2") and success
	success = _assert_test(gs.respect.value == 48, "valor deve ir para 48 após a derrota") and success
	success = _assert_test(gs.respect_log.size() == 1, "respect_log deve ter 1 entrada") and success
	var defeat_entry: Dictionary = gs.respect_log.back()
	success = _assert_test(str(defeat_entry.get("event", "")) == "EXPEDITION_DEFEAT", "evento registrado deve ser EXPEDITION_DEFEAT") and success
	success = _assert_test(str(defeat_entry.get("source", "")) == "test", "source deve ser test") and success
	success = _assert_test(int(defeat_entry.get("delta", 0)) == -2, "delta registrado deve ser -2") and success
	success = _assert_test(int(defeat_entry.get("value", 0)) == 48, "value registrado deve ser 48") and success

	var d1: int = gs.apply_respect(RespectState.Event.CHALLENGING_ENCOUNTER_WIN, "test")
	var d2: int = gs.apply_respect(RespectState.Event.CHALLENGING_ENCOUNTER_WIN, "test")
	var d3: int = gs.apply_respect(RespectState.Event.CHALLENGING_ENCOUNTER_WIN, "test")
	var d4: int = gs.apply_respect(RespectState.Event.CHALLENGING_ENCOUNTER_WIN, "test")
	success = _assert_test(d1 == 2 and d2 == 2 and d3 == 2, "as 3 primeiras vitórias desafiadoras valem +2") and success
	success = _assert_test(d4 == 0, "a 4ª vitória desafiadora não rende nada") and success
	success = _assert_test(gs.respect.value == 54, "valor deve ir para 54") and success

	gs.roll_expedition_nature_and_prepare()
	success = _assert_test(gs.respect.challenging_rewards_left() == 3, "nova expedição recomeça com 3 recompensas desafiadoras") and success
	success = _assert_test(gs.respect.value == 54, "begin_expedition não altera o valor") and success
	success = _assert_test(gs.expedition_origin_scene == gs.HUB_3D, "origem deve ser o Hub 3D") and success

	gs.return_to_hub_from_expedition()
	success = _assert_test(gs.respect.value == 54, "retirada não altera o valor") and success
	var retreat_entry: Dictionary = gs.respect_log.back()
	success = _assert_test(str(retreat_entry.get("event", "")) == "STRATEGIC_RETREAT", "retirada registra STRATEGIC_RETREAT") and success
	success = _assert_test(int(retreat_entry.get("delta", -1)) == 0, "retirada tem delta 0") and success
	success = _assert_test(gs.expedition_origin_scene == "", "retirada limpa a origem") and success

	var log_size_before: int = gs.respect_log.size()
	gs.return_to_hub_from_expedition()
	success = _assert_test(gs.respect_log.size() == log_size_before, "sem expedição ativa, retirada não registra entrada") and success

	gs.expedition_origin_scene = gs.HUB_3D
	gs.encounter_id = "test"
	var value_before_defeat: int = gs.respect.value
	gs.end_battle(false)
	success = _assert_test(gs.respect.value == value_before_defeat - 2, "derrota definitiva aplica -2 pelo fluxo real") and success
	var defeat_path_entry: Dictionary = gs.respect_log.back()
	success = _assert_test(str(defeat_path_entry.get("event", "")) == "EXPEDITION_DEFEAT", "fluxo real registra EXPEDITION_DEFEAT") and success
	success = _assert_test(str(defeat_path_entry.get("source", "")) == "expedition_defeat", "source deve ser expedition_defeat") and success

	for _i in range(40):
		gs.apply_respect(RespectState.Event.STRATEGIC_RETREAT, "cap")
	success = _assert_test(gs.respect_log.size() == 32, "respect_log deve ser limitado a 32 entradas") and success

	gs.start_new_campaign("abra")
	success = _assert_test(gs.respect.value == 50, "nova campanha recomeça o Respeito em 50") and success
	success = _assert_test(gs.respect_log.is_empty(), "nova campanha limpa o respect_log") and success

	if success:
		print("RESPECT_EXPEDITION_CYCLE_TEST_PASS")
		quit(0)
	else:
		push_error("[TEST FAILURE] Um ou mais testes falharam.")
		quit(1)


func _assert_test(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("ASSERTION FAILED: " + msg)
	return cond
