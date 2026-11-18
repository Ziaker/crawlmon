extends SceneTree
## D-1285, D-1286, D-1309: sorteio de Cascos ligado ao combate (Battle real, sem UI).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/battle_shell_drop_test.gd -- --stdout-trace

const DropMath := preload("res://scripts/economy/shell_drop_math.gd")
const SEED := 20261118
const ENEMIES := 400

var _trace := false
var _tests := 0
var _failed := 0
var _name := ""
var _fails := 0
var _msgs: Array[String] = []


func _initialize() -> void:
	_trace = "--stdout-trace" in OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_test_sorteio_igual_a_formula()
	_test_luk_do_lider()
	_test_uma_vez_por_inimigo()
	_test_derrota_nao_gera_drop()
	_test_sinal_so_com_drop()
	_test_quantidade_pelo_nivel()
	_test_rng_global_intacto()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)


func _arena(luk: int, n_enemies: int, enemy_level := 1) -> Dictionary:
	var battle := Battle.new()
	var leader := Combatant.new("Leader", 100, 10, 0.5, true)
	leader.luk = luk
	var party: Array[Combatant] = [leader]
	var foes: Array[Combatant] = []
	for i in n_enemies:
		var f := Combatant.new("Foe%d" % i, 100, 10, 0.5, false)
		f.level = enemy_level
		foes.append(f)
	battle.start(party, foes)
	battle.shell_rng.seed = SEED
	return {"battle": battle, "leader": leader, "foes": foes}


func _kill(c: Combatant) -> void:
	c.take_damage(c.hp + 1000, true)


func _expected(luk: float, n: int, level := 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var t := {"bronze": 0, "silver": 0, "gold": 0}
	for i in n:
		if DropMath.roll_bronze(rng, luk):
			t["bronze"] += DropMath.quantity("bronze", level)
		if DropMath.roll_silver(rng, luk):
			t["silver"] += DropMath.quantity("silver", level)
		if DropMath.roll_gold(rng, luk):
			t["gold"] += DropMath.quantity("gold", level)
	return t


func _test_sorteio_igual_a_formula() -> void:
	_begin("sorteio_igual_a_formula")
	var a := _arena(20, ENEMIES)
	for f in a["foes"]:
		_kill(f)
	var got: Dictionary = a["battle"].shell_drop_totals()
	var want := _expected(20.0, ENEMIES)
	_ok(got == want, "got %s want %s" % [got, want])
	_ok(int(got["bronze"]) > 0 and int(got["silver"]) > 0 and int(got["gold"]) > 0, "esperava as tres moedas em %d inimigos: %s" % [ENEMIES, got])
	_end()


func _test_luk_do_lider() -> void:
	_begin("luk_do_lider")
	var lo := _arena(0, ENEMIES)
	var hi := _arena(49, ENEMIES)
	for f in lo["foes"]:
		_kill(f)
	for f in hi["foes"]:
		_kill(f)
	var tl: Dictionary = lo["battle"].shell_drop_totals()
	var th: Dictionary = hi["battle"].shell_drop_totals()
	_ok(tl == _expected(0.0, ENEMIES), "LUK 0: %s" % tl)
	_ok(th == _expected(49.0, ENEMIES), "LUK 49: %s" % th)
	_ok(int(th["silver"]) > int(tl["silver"]), "LUK maior deveria dar mais prata: %d vs %d" % [th["silver"], tl["silver"]])
	_end()


func _test_uma_vez_por_inimigo() -> void:
	_begin("uma_vez_por_inimigo")
	var a := _arena(20, 3)
	var foe: Combatant = a["foes"][0]
	_kill(foe)
	var once: Dictionary = a["battle"].shell_drop_totals()
	foe.died.emit(foe)
	foe.died.emit(foe)
	_ok(a["battle"].shell_drop_totals() == once, "died repetido nao deve sortear de novo")
	_end()


func _test_derrota_nao_gera_drop() -> void:
	_begin("derrota_nao_gera_drop")
	var a := _arena(20, 5)
	for i in 3:
		_kill(a["foes"][i])
	_ok(int(a["battle"].shell_drop_totals()["bronze"]) + int(a["battle"].shell_drop_totals()["silver"]) > 0, "esperava algum drop antes da derrota (seed fixa)")
	_kill(a["leader"])
	a["battle"]._check_end()
	var t: Dictionary = a["battle"].shell_drop_totals()
	_ok(t == {"bronze": 0, "silver": 0, "gold": 0}, "derrota deveria zerar os drops: %s" % t)
	_end()


func _test_sinal_so_com_drop() -> void:
	_begin("sinal_so_com_drop")
	var a := _arena(20, 200)
	var seen := [0, 0]  # [sinais, inimigos sem sinal]
	var battle: Battle = a["battle"]
	battle.shell_drop_rolled.connect(func(_e: Combatant, hits: Dictionary) -> void:
		seen[0] += 1
		if int(hits["bronze"]) + int(hits["silver"]) + int(hits["gold"]) == 0:
			seen[1] += 1)
	for f in a["foes"]:
		_kill(f)
	_ok(seen[0] > 0, "nenhum sinal emitido")
	_ok(seen[0] < 200, "todo inimigo emitiu sinal, mas bronze e 50%%: %d" % seen[0])
	_ok(seen[1] == 0, "sinal sem nenhuma moeda: %d" % seen[1])
	_end()


func _test_quantidade_pelo_nivel() -> void:
	_begin("quantidade_pelo_nivel")
	# D-1309: nivel / divisor (Bronze 2, Silver 3, Golden 4), para baixo, minimo 1.
	for case in [[1, 1, 1, 1], [5, 2, 1, 1], [8, 4, 2, 2], [12, 6, 4, 3], [40, 20, 13, 10]]:
		var lv: int = case[0]
		_ok(DropMath.quantity("bronze", lv) == case[1], "bronze nivel %d: %d" % [lv, DropMath.quantity("bronze", lv)])
		_ok(DropMath.quantity("silver", lv) == case[2], "silver nivel %d: %d" % [lv, DropMath.quantity("silver", lv)])
		_ok(DropMath.quantity("gold", lv) == case[3], "gold nivel %d: %d" % [lv, DropMath.quantity("gold", lv)])
	var a := _arena(20, 300, 12)
	for f in a["foes"]:
		_kill(f)
	_ok(a["battle"].shell_drop_totals() == _expected(20.0, 300, 12), "totais com nivel 12: %s" % a["battle"].shell_drop_totals())
	_end()


func _test_rng_global_intacto() -> void:
	_begin("rng_global_intacto")
	seed(123)
	var expect_a := randf()
	var expect_b := randf()
	seed(123)
	var a := _arena(20, 20)
	for f in a["foes"]:
		_kill(f)
	_ok(is_equal_approx(randf(), expect_a), "sorteio consumiu o RNG global (1)")
	_ok(is_equal_approx(randf(), expect_b), "sorteio consumiu o RNG global (2)")
	_end()


func _begin(n: String) -> void:
	_name = n
	_fails = 0
	_msgs = []


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		_msgs.append(msg)


func _end() -> void:
	_tests += 1
	if _fails > 0:
		_failed += 1
	if _trace:
		print("[ECON] ", JSON.stringify({"ev": "test", "name": _name, "ok": _fails == 0, "asserts_failed": _fails, "fail": _msgs}))
