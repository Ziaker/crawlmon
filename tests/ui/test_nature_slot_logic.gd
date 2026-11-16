extends SceneTree
## Contract tests for NatureSlotLogic (D-1215, D-1216, D-1217). Logic only:
## nothing is drawn. Run headless with
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/ui/test_nature_slot_logic.gd

const SlotLogic = preload("res://scripts/ui/pre_game/nature_slot_logic.gd")
const Catalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")

const START_POSITIONS: Array[float] = [0.0, 3.7, 40.2]
const SAMPLE_COUNT := 200
const MONOTONIC_EPSILON := 0.000001

var failures := 0


func _init() -> void:
	print("[TEST] NatureSlotLogic suite (D-1215, D-1216, D-1217)")
	_test_symbol_table()
	_test_reel_plan_reaches_locked_result()
	_test_skip_equals_natural()
	_test_spot_checks()
	if failures == 0:
		print("NATURE_SLOT_LOGIC_TEST_PASS")
		quit(0)
	else:
		print("NATURE_SLOT_LOGIC_TEST_FAIL (%d)" % failures)
		quit(1)


func ok(condition: bool, message: String) -> void:
	if condition:
		print("  [PASS] ", message)
	else:
		failures += 1
		print("  [FAIL] ", message)


func _test_symbol_table() -> void:
	print("  -> symbols_for / all_symbols")
	var strip := SlotLogic.all_symbols()
	ok(strip.size() > 1, "all_symbols() tem mais de um simbolo")
	ok(strip[strip.size() - 1] == "NONE", "all_symbols() termina em NONE")
	ok(_strip_ordered(strip), "all_symbols() ordenado por STAT_ORDER e valor DESC")
	for nature_id in Catalog.NATURE_ORDER:
		var symbols := SlotLogic.symbols_for(nature_id)
		ok(symbols.size() == 3, "%s: 3 simbolos" % nature_id)
		var symbols_ok := true
		var stats: Dictionary = {}
		for symbol in symbols:
			if not strip.has(symbol) or SlotLogic.symbol_index(symbol) < 0:
				symbols_ok = false
			if SlotLogic.symbol_kind(symbol) != _kind_of(symbol):
				symbols_ok = false
			if symbol != "NONE":
				stats[symbol.split(" ")[0]] = true
		ok(symbols_ok, "%s: simbolos na strip com kind correto" % nature_id)
		if Catalog.PURE_NATURES.has(nature_id):
			ok(symbols == _triple("NONE", "NONE", "NONE"), "%s: pura mostra NONE x3" % nature_id)
		else:
			ok(stats.size() == 3, "%s: 3 status distintos" % nature_id)
			ok(not symbols.has("NONE"), "%s: nao mostra NONE" % nature_id)
func _test_reel_plan_reaches_locked_result() -> void:
	print("  -> reel_plan / shown_symbols_at / position_at")
	for nature_id in Catalog.NATURE_ORDER:
		var expected := SlotLogic.symbols_for(nature_id)
		var reach_ok := true
		var end_ok := true
		var monotonic_ok := true
		for start in START_POSITIONS:
			var starts: Array[float] = [start, start, start]
			var plan := SlotLogic.reel_plan(nature_id, starts)
			if plan.size() != 3:
				reach_ok = false
				continue
			var ends: Array[float] = []
			for i in 3:
				var reel: Dictionary = plan[i]
				ends.append(float(reel["end_pos"]))
				if not _lands_on_end(reel):
					end_ok = false
				if not _monotonic(reel):
					monotonic_ok = false
			if SlotLogic.shown_symbols_at(ends) != expected:
				reach_ok = false
				print("    [DATA] %s start=%.1f shown=%s expected=%s" % [
					nature_id, start, str(SlotLogic.shown_symbols_at(ends)), str(expected)
				])
		ok(reach_ok, "%s: os 3 rolos chegam em symbols_for() nas 3 posicoes iniciais" % nature_id)
		ok(end_ok, "%s: position_at(elapsed >= dur) == end_pos nos 3 rolos" % nature_id)
		ok(monotonic_ok, "%s: position_at monotono (200 amostras, 3 rolos)" % nature_id)


func _test_skip_equals_natural() -> void:
	print("  -> SKIP / reduce-motion == animacao natural")
	for nature_id in Catalog.NATURE_ORDER:
		var starts: Array[float] = [7.5, 19.25, 2.0]
		var plan := SlotLogic.reel_plan(nature_id, starts)
		var skip_positions: Array[float] = []
		var natural_positions: Array[float] = []
		for i in 3:
			var reel: Dictionary = plan[i]
			skip_positions.append(float(reel["end_pos"]))
			natural_positions.append(SlotLogic.position_at(
				reel["start_pos"], reel["end_pos"], reel["dur_ms"], reel["flat_ms"], reel["tease"], float(reel["dur_ms"])
			))
		var skip_shown := SlotLogic.shown_symbols_at(skip_positions)
		var natural_shown := SlotLogic.shown_symbols_at(natural_positions)
		ok(skip_shown == natural_shown, "%s: SKIP == animacao natural" % nature_id)
		ok(skip_shown == SlotLogic.final_symbols(nature_id), "%s: SKIP == resultado travado" % nature_id)
func _test_spot_checks() -> void:
	print("  -> literais do prototipo")
	ok(SlotLogic.symbols_for("brave") == _triple("STR +2", "VIT +1", "AGI -3"),
		"brave -> STR +2, VIT +1, AGI -3")
	ok(SlotLogic.symbols_for("adamant") == _triple("STR +3", "LUK -1", "MAG -2"),
		"adamant -> STR +3, LUK -1, MAG -2 (valor DESC)")
	ok(SlotLogic.symbols_for("hardy") == _triple("NONE", "NONE", "NONE"),
		"hardy -> NONE x3")
	ok(SlotLogic.final_symbols("docile") == _triple("NONE", "NONE", "NONE"),
		"docile -> NONE x3")
	ok(SlotLogic.TIMING_STOP_MS == _floats(1800.0, 2600.0, 4300.0), "TIMING_STOP_MS")
	ok(SlotLogic.TIMING_FLAT_MS == _floats(700.0, 900.0, 1100.0), "TIMING_FLAT_MS")
	ok(SlotLogic.TIMING_REVEAL_MS == 300.0
		and SlotLogic.TIMING_SETTLE_MS == 700.0
		and SlotLogic.TIMING_EXIT_MS == 700.0, "TIMING reveal/settle/exit")


func _lands_on_end(reel: Dictionary) -> bool:
	for elapsed in [float(reel["dur_ms"]), float(reel["dur_ms"]) + 500.0]:
		var position := SlotLogic.position_at(
			reel["start_pos"], reel["end_pos"], reel["dur_ms"], reel["flat_ms"], reel["tease"], elapsed
		)
		if position != float(reel["end_pos"]):
			print("    [DATA] reel end mismatch at %.1f ms: %.4f != %.4f" % [
				elapsed, position, float(reel["end_pos"])
			])
			return false
	return true

func _monotonic(reel: Dictionary) -> bool:
	var previous := float(reel["start_pos"])
	var dur := float(reel["dur_ms"])
	for i in range(1, SAMPLE_COUNT + 1):
		var position := SlotLogic.position_at(
			reel["start_pos"], reel["end_pos"], reel["dur_ms"], reel["flat_ms"], reel["tease"],
			dur * float(i) / float(SAMPLE_COUNT)
		)
		if position < previous - MONOTONIC_EPSILON:
			return false
		previous = position
	return true


func _strip_ordered(strip: Array[String]) -> bool:
	var stat_order: Array[String] = Catalog.STAT_ORDER
	for i in range(1, strip.size() - 1):
		var left := strip[i - 1].split(" ")
		var right := strip[i].split(" ")
		var li := stat_order.find(left[0])
		var ri := stat_order.find(right[0])
		if li > ri or (li == ri and int(left[1]) < int(right[1])):
			return false
	return true


func _kind_of(symbol: String) -> String:
	if symbol == "NONE":
		return "none"
	return "pos" if symbol.contains("+") else "neg"


func _triple(a: String, b: String, c: String) -> Array[String]:
	var out: Array[String] = [a, b, c]
	return out


func _floats(a: float, b: float, c: float) -> Array[float]:
	var out: Array[float] = [a, b, c]
	return out
