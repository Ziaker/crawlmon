extends SceneTree
## D-1285: testes puros de ShellDropMath (sem combate, GameState ou UI).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/shell_drop_math_test.gd -- --stdout-trace
## Sem --stdout-trace imprime só o resumo.

const DropMath := preload("res://scripts/economy/shell_drop_math.gd")
const TOL := 1e-9
const STAT_ROLLS := 200000
const STAT_SEED := 20261117

var _trace := false
var _tests := 0
var _failed := 0
var _test_name := ""
var _test_fails := 0
var _test_msgs: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_trace = "--stdout-trace" in args
	_test_chances_exatas()
	_test_repetibilidade()
	_test_rng_global_intacto()
	_test_estatistica()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)


func _test_chances_exatas() -> void:
	_begin("chances_exatas")
	var casos := [
		{"luk": 0.0, "silver": 7.0, "gold": 3.0},
		{"luk": 1.0, "silver": 8.0, "gold": 3.5},
		{"luk": 20.0, "silver": 27.0, "gold": 13.0},
		{"luk": 49.0, "silver": 56.0, "gold": 27.5},
	]
	for caso in casos:
		var luk := float(caso["luk"])
		_check_near("prata LUK %s" % luk, DropMath.silver_chance_pct(luk), float(caso["silver"]))
		_check_near("ouro LUK %s" % luk, DropMath.gold_chance_pct(luk), float(caso["gold"]))
	_end()


func _test_repetibilidade() -> void:
	_begin("repetibilidade")
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 4242
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 4242
	var seq_a := _roll_silver_sequence(rng_a, 1000, 20.0)
	var seq_b := _roll_silver_sequence(rng_b, 1000, 20.0)
	var diverged := -1
	for i in seq_a.size():
		if seq_a[i] != seq_b[i]:
			diverged = i
			break
	_ok(diverged == -1, "mesma seed divergiu no roll %d" % diverged)

	var single := RandomNumberGenerator.new()
	single.seed = 4242
	DropMath.roll_silver(single, 20.0)
	var reference := RandomNumberGenerator.new()
	reference.seed = 4242
	reference.randf()
	_ok(single.state == reference.state, "roll_silver consumiu mais de um randf()")

	var gold_single := RandomNumberGenerator.new()
	gold_single.seed = 777
	var gold_reference := RandomNumberGenerator.new()
	gold_reference.seed = 777
	DropMath.roll_gold(gold_single, 49.0)
	gold_reference.randf()
	_ok(gold_single.state == gold_reference.state, "roll_gold consumiu mais de um randf()")
	_end()


func _test_rng_global_intacto() -> void:
	_begin("rng_global_intacto")
	seed(7)
	var before := randi()
	seed(7)
	var own := RandomNumberGenerator.new()
	own.seed = 99
	for i in 100:
		DropMath.roll_silver(own, 20.0)
	var after := randi()
	_ok(before == after, "os rolls alteraram o RNG global: %d != %d" % [before, after])
	_end()


func _test_estatistica() -> void:
	_begin("estatistica")
	var silver_pct := _frequency(STAT_SEED, STAT_ROLLS, 20.0, true)
	_ok(silver_pct >= 26.5 and silver_pct <= 27.5,
		"prata LUK 20: %.4f%% fora de [26.5, 27.5]" % silver_pct)
	var gold_pct := _frequency(STAT_SEED + 1, STAT_ROLLS, 49.0, false)
	_ok(gold_pct >= 27.0 and gold_pct <= 28.0,
		"ouro LUK 49: %.4f%% fora de [27.0, 28.0]" % gold_pct)
	_end()


func _frequency(rng_seed: int, rolls: int, luk: float, is_silver: bool) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var hits := 0
	for i in rolls:
		var hit := DropMath.roll_silver(rng, luk) if is_silver else DropMath.roll_gold(rng, luk)
		if hit:
			hits += 1
	return 100.0 * float(hits) / float(rolls)


func _roll_silver_sequence(rng: RandomNumberGenerator, count: int, luk: float) -> Array[bool]:
	var out: Array[bool] = []
	for i in count:
		out.append(DropMath.roll_silver(rng, luk))
	return out


func _check_near(label: String, got: float, expected: float) -> void:
	var diff := absf(got - expected)
	_ok(diff < TOL, "%s: esperado %s, obtido %s (diff %s)" % [label, expected, got, diff])


func _begin(test_name: String) -> void:
	_test_name = test_name
	_test_fails = 0
	_test_msgs.clear()
	_tests += 1


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_test_fails += 1
		_test_msgs.append(msg)


func _end() -> void:
	var ok := _test_fails == 0
	if not ok:
		_failed += 1
	if _trace:
		print("[ECON] ", JSON.stringify({
			"ev": "test",
			"name": _test_name,
			"ok": ok,
			"asserts_failed": _test_fails,
			"fail": _test_msgs,
		}))
