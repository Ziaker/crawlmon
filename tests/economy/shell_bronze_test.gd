extends SceneTree
## D-1286: testes puros do sorteio de Bronze de ShellDropMath (sem combate, GameState ou UI).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/shell_bronze_test.gd -- --stdout-trace
## Sem --stdout-trace imprime so o resumo.

const DropMath := preload("res://scripts/economy/shell_drop_math.gd")
const TOL := 1e-9
const SEQ_SEED := 4242
const SEQ_ROLLS := 1000
const STAT_SEED := 20261119
const STAT_ROLLS := 200000
const STAT_MIN_PCT := 49.5
const STAT_MAX_PCT := 50.5
const GLOBAL_SEED := 7
const GLOBAL_ROLLS := 100
const OWN_SEED := 99

var _trace := false
var _tests := 0
var _failed := 0
var _test_name := ""
var _test_fails := 0
var _test_msgs: Array[String] = []



func _initialize() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_trace = "--stdout-trace" in args
	_test_chance_fixa()
	_test_repetibilidade()
	_test_consumo_de_um_randf()
	_test_estatistica()
	_test_rng_global_intacto()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)


func _test_chance_fixa() -> void:
	_begin("chance_fixa")
	for luk in [0.0, 1.0, 20.0, 49.0]:
		_check_near("bronze LUK %s" % luk, DropMath.bronze_chance_pct(luk), 50.0)
	_end()



func _test_repetibilidade() -> void:
	_begin("repetibilidade")
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = SEQ_SEED
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = SEQ_SEED
	var seq_a := _roll_sequence(rng_a, SEQ_ROLLS)
	var seq_b := _roll_sequence(rng_b, SEQ_ROLLS)
	var diverged := -1
	for i in seq_a.size():
		if seq_a[i] != seq_b[i]:
			diverged = i
			break
	_ok(diverged == -1, "mesma seed divergiu no roll %d" % diverged)
	_end()



func _test_consumo_de_um_randf() -> void:
	_begin("consome_um_randf")
	var single := RandomNumberGenerator.new()
	single.seed = SEQ_SEED
	DropMath.roll_bronze(single, 20.0)
	var reference := RandomNumberGenerator.new()
	reference.seed = SEQ_SEED
	reference.randf()
	_ok(single.state == reference.state,
		"roll_bronze consumiu mais de um randf(): state %d != %d" % [single.state, reference.state])
	_end()


func _test_estatistica() -> void:
	_begin("estatistica")
	var pct := _frequency(STAT_SEED, STAT_ROLLS, 20.0)
	_ok(pct >= STAT_MIN_PCT and pct <= STAT_MAX_PCT,
		"bronze LUK 20: %.4f%% fora de [%s, %s]" % [pct, STAT_MIN_PCT, STAT_MAX_PCT])
	_end()



func _test_rng_global_intacto() -> void:
	_begin("rng_global_intacto")
	seed(GLOBAL_SEED)
	var before := randi()
	seed(GLOBAL_SEED)
	var own := RandomNumberGenerator.new()
	own.seed = OWN_SEED
	for i in GLOBAL_ROLLS:
		DropMath.roll_bronze(own, 20.0)
	var after := randi()
	_ok(before == after, "os rolls de bronze alteraram o RNG global: %d != %d" % [before, after])
	_end()



func _roll_sequence(rng: RandomNumberGenerator, count: int) -> Array[bool]:
	var out: Array[bool] = []
	for i in count:
		out.append(DropMath.roll_bronze(rng, 20.0))
	return out



func _frequency(rng_seed: int, rolls: int, luk: float) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var hits := 0
	for i in rolls:
		if DropMath.roll_bronze(rng, luk):
			hits += 1
	return 100.0 * float(hits) / float(rolls)



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