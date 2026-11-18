extends SceneTree
## D-1309: limite de 12 moedas visuais por tipo (pedido do criador).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/shell_drop_fx_test.gd -- --stdout-trace

const Fx := preload("res://scripts/combat/shell_drop_fx.gd")

var _trace := false
var _tests := 0
var _failed := 0
var _fails := 0
var _msgs: Array[String] = []


func _initialize() -> void:
	_trace = "--stdout-trace" in OS.get_cmdline_args() + OS.get_cmdline_user_args()
	var root3 := Node3D.new()
	root.add_child(root3)
	_run("uma_moeda_por_unidade", func() -> void:
		var shown := {}
		var fx = Fx.burst(root3, Vector3.ZERO, 0.0, {"bronze": 3, "silver": 2, "gold": 1}, shown)
		_ok(fx.piece_count() == 6, "pecas %d" % fx.piece_count())
		_ok(shown == {"bronze": 3, "silver": 2, "gold": 1}, "shown %s" % shown))
	_run("bool_conta_como_uma", func() -> void:
		var shown := {}
		var fx = Fx.burst(root3, Vector3.ZERO, 0.0, {"bronze": true, "silver": false, "gold": true}, shown)
		_ok(fx.piece_count() == 2, "pecas %d" % fx.piece_count()))
	_run("limite_12_por_tipo", func() -> void:
		var shown := {}
		var a = Fx.burst(root3, Vector3.ZERO, 0.0, {"bronze": 8, "silver": 5, "gold": 0}, shown)
		_ok(a.piece_count() == 13, "primeira: %d" % a.piece_count())
		var b = Fx.burst(root3, Vector3.ZERO, 0.0, {"bronze": 8, "silver": 5, "gold": 0}, shown)
		_ok(b.piece_count() == 9, "segunda: bronze +4 e prata +5, deu %d" % b.piece_count())
		_ok(int(shown["bronze"]) == 12 and int(shown["silver"]) == 10, "shown %s" % shown)
		var c = Fx.burst(root3, Vector3.ZERO, 0.0, {"bronze": 3, "silver": 0, "gold": 0}, shown)
		_ok(c.piece_count() == 0, "bronze acima de 12 nao gera: %d" % c.piece_count())
		var d = Fx.burst(root3, Vector3.ZERO, 0.0, {"bronze": 3, "silver": 5, "gold": 0}, shown)
		_ok(d.piece_count() == 2, "prata segue ate 12 (10 + 2) com bronze cheio: %d" % d.piece_count()))
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)


func _run(name: String, body: Callable) -> void:
	_fails = 0
	_msgs = []
	body.call()
	_tests += 1
	if _fails > 0:
		_failed += 1
	if _trace:
		print("[ECON] ", JSON.stringify({"ev": "test", "name": name, "ok": _fails == 0, "asserts_failed": _fails, "fail": _msgs}))


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		_msgs.append(msg)
