extends SceneTree
## D-1285, D-1286: testes puros do ShellDropResolver (sem combate, GameState ou UI).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/shell_drop_resolver_test.gd -- --stdout-trace
## Sem --stdout-trace imprime so o resumo.

const Resolver := preload("res://scripts/economy/shell_drop_resolver.gd")
const SEQ_SEED := 4242
const SEQ_ENEMIES := 200
const STAT_SEED := 20261117
const STAT_ENEMIES := 100000
const GLOBAL_SEED := 7
const GLOBAL_ENEMIES := 100
const OWN_SEED := 99
const COINS := ["bronze", "silver", "gold"]

var _trace := false
var _tests := 0
var _failed := 0
var _test_name := ""
var _test_fails := 0
var _test_msgs: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_trace = "--stdout-trace" in args
	_test_outcomes_inelegiveis()
	_test_uma_vez_por_inimigo()
	_test_varios_inimigos()
	_test_repetibilidade()
	_test_frequencias()
	_test_tres_moedas_juntas()
	_test_rng_global_intacto()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)

func _test_outcomes_inelegiveis() -> void:
	_begin("outcomes_inelegiveis")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEQ_SEED
	var resolved: Dictionary = {}
	for outcome in ["flee", "recruit", "defeat"]:
		var before := rng.state
		var result := Resolver.resolve("enemy_%s" % outcome, outcome, 20.0, rng, resolved)
		_ok(result["ok"] == true, "%s: ok deveria ser true" % outcome)
		_ok(result["granted"] == false, "%s: nao deveria conceder drop" % outcome)
		_ok(result["reason"] == "ineligible_outcome", "%s: reason '%s'" % [outcome, result["reason"]])
		_assert_no_hits(outcome, result)
		_ok(rng.state == before, "%s: consumiu o rng (%d != %d)" % [outcome, rng.state, before])
		_ok(resolved.is_empty(), "%s: marcou resolved: %s" % [outcome, resolved])
	_end()

func _test_uma_vez_por_inimigo() -> void:
	_begin("uma_vez_por_inimigo")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEQ_SEED + 1
	var resolved: Dictionary = {}
	var first := Resolver.resolve("enemy_a", "victory", 20.0, rng, resolved)
	_ok(first["granted"] == true, "primeira chamada deveria conceder")
	_ok(resolved.has("enemy_a"), "primeira chamada deveria marcar resolved")
	var before := rng.state
	var size_before := resolved.size()
	var second := Resolver.resolve("enemy_a", "victory", 49.0, rng, resolved)
	_ok(second["ok"] == true, "segunda chamada: ok deveria ser true")
	_ok(second["granted"] == false, "segunda chamada nao deveria conceder")
	_ok(second["reason"] == "already_resolved", "segunda chamada: reason '%s'" % second["reason"])
	_assert_no_hits("segunda chamada", second)
	_ok(rng.state == before, "segunda chamada consumiu o rng")
	_ok(resolved.size() == size_before, "segunda chamada alterou resolved")
	before = rng.state
	var empty := Resolver.resolve("", "victory", 20.0, rng, resolved)
	_ok(empty["ok"] == false, "uid vazio: ok deveria ser false")
	_ok(empty["granted"] == false, "uid vazio nao deveria conceder")
	_ok(empty["reason"] == "invalid_enemy", "uid vazio: reason '%s'" % empty["reason"])
	_assert_no_hits("uid vazio", empty)
	_ok(rng.state == before, "uid vazio consumiu o rng")
	_ok(resolved.size() == size_before, "uid vazio alterou resolved")
	_end()

func _test_varios_inimigos() -> void:
	_begin("varios_inimigos")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEQ_SEED + 2
	var resolved: Dictionary = {}
	var grants: Dictionary = {}
	var uids: Array[String] = []
	for i in 5:
		uids.append("enemy_%d" % i)
	for uid in uids:
		for attempt in 3:
			var result := Resolver.resolve(uid, "victory", 49.0, rng, resolved)
			_ok(result["ok"] == true, "%s chamada %d: ok deveria ser true" % [uid, attempt])
			if result["granted"] == true:
				grants[uid] = int(grants.get(uid, 0)) + 1
	_ok(resolved.size() == 5, "esperava 5 chaves em resolved, obtido %d" % resolved.size())
	for uid in uids:
		_ok(resolved.has(uid), "resolved sem %s" % uid)
		_ok(int(grants.get(uid, 0)) == 1, "%s concedeu %d vezes (esperado 1)" % [uid, int(grants.get(uid, 0))])
	_end()

func _test_repetibilidade() -> void:
	_begin("repetibilidade")
	var seq_a := _resolve_sequence(SEQ_SEED + 3, 20.0, SEQ_ENEMIES)
	var seq_b := _resolve_sequence(SEQ_SEED + 3, 20.0, SEQ_ENEMIES)
	var diverged := -1
	for i in seq_a.size():
		if not _same_hits(seq_a[i], seq_b[i]):
			diverged = i
			break
	_ok(diverged == -1, "mesma seed divergiu no inimigo %d" % diverged)
	_end()


func _test_frequencias() -> void:
	_begin("frequencias")
	var luk_0 := _statistics(STAT_SEED, 0.0, STAT_ENEMIES)
	_ok_in_range("LUK 0 prata", luk_0["silver"], 6.5, 7.5)
	_ok_in_range("LUK 0 ouro", luk_0["gold"], 2.5, 3.5)
	_ok_in_range("LUK 0 bronze", luk_0["bronze"], 49.0, 51.0)
	_ok(luk_0["resolved"] == STAT_ENEMIES, "LUK 0: resolved com %d chaves, esperado %d" % [luk_0["resolved"], STAT_ENEMIES])
	var luk_20 := _statistics(STAT_SEED, 20.0, STAT_ENEMIES)
	_ok_in_range("LUK 20 prata", luk_20["silver"], 26.0, 28.0)
	_ok_in_range("LUK 20 ouro", luk_20["gold"], 12.5, 13.5)
	_ok(luk_20["resolved"] == STAT_ENEMIES, "LUK 20: resolved com %d chaves, esperado %d" % [luk_20["resolved"], STAT_ENEMIES])
	var luk_49 := _statistics(STAT_SEED, 49.0, STAT_ENEMIES)
	_ok_in_range("LUK 49 prata", luk_49["silver"], 55.0, 57.0)
	_ok_in_range("LUK 49 ouro", luk_49["gold"], 27.0, 28.0)
	_ok(luk_49["resolved"] == STAT_ENEMIES, "LUK 49: resolved com %d chaves, esperado %d" % [luk_49["resolved"], STAT_ENEMIES])
	_end()

func _test_tres_moedas_juntas() -> void:
	_begin("tres_moedas_juntas")
	var stats := _statistics(STAT_SEED, 49.0, STAT_ENEMIES)
	_ok(stats["all_three"] >= 1,
		"LUK 49: nenhum inimigo com bronze+prata+ouro juntos em %d" % STAT_ENEMIES)
	_end()


func _test_rng_global_intacto() -> void:
	_begin("rng_global_intacto")
	seed(GLOBAL_SEED)
	var before := randi()
	seed(GLOBAL_SEED)
	var own := RandomNumberGenerator.new()
	own.seed = OWN_SEED
	var resolved: Dictionary = {}
	for i in GLOBAL_ENEMIES:
		Resolver.resolve("enemy_%d" % i, "victory", 20.0, own, resolved)
	var after := randi()
	_ok(before == after, "os resolves alteraram o RNG global: %d != %d" % [before, after])
	_end()

func _resolve_sequence(rng_seed: int, luk: float, enemies: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var resolved: Dictionary = {}
	var out: Array = []
	for i in enemies:
		var result := Resolver.resolve("enemy_%d" % i, "victory", luk, rng, resolved)
		out.append(result["hits"])
	return out


func _statistics(rng_seed: int, luk: float, enemies: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var resolved: Dictionary = {}
	var counts := {"bronze": 0, "silver": 0, "gold": 0}
	var all_three := 0
	for i in enemies:
		var result := Resolver.resolve("enemy_%d" % i, "victory", luk, rng, resolved)
		if result["granted"] != true:
			continue
		var h: Dictionary = result["hits"]
		for coin in COINS:
			if h[coin] == true:
				counts[coin] = int(counts[coin]) + 1
		if h["bronze"] and h["silver"] and h["gold"]:
			all_three += 1
	return {
		"bronze": 100.0 * float(counts["bronze"]) / float(enemies),
		"silver": 100.0 * float(counts["silver"]) / float(enemies),
		"gold": 100.0 * float(counts["gold"]) / float(enemies),
		"resolved": resolved.size(),
		"all_three": all_three,
	}

func _same_hits(a: Dictionary, b: Dictionary) -> bool:
	for coin in COINS:
		if a[coin] != b[coin]:
			return false
	return true


func _assert_no_hits(label: String, result: Dictionary) -> void:
	var h: Dictionary = result["hits"]
	for coin in COINS:
		_ok(h[coin] == false, "%s: hit '%s' deveria ser false" % [label, coin])


func _ok_in_range(label: String, got: float, min_value: float, max_value: float) -> void:
	_ok(got >= min_value and got <= max_value,
		"%s: %.4f%% fora de [%s, %s]" % [label, got, min_value, max_value])

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