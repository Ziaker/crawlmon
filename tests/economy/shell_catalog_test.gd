extends SceneTree
## D-1309: testes puros do ShellCatalog (sem GameState, UI ou combate).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/shell_catalog_test.gd -- --stdout-trace
## Sem --stdout-trace imprime so o resumo.

const Catalog := preload("res://scripts/economy/shell_catalog.gd")
const Wallet := preload("res://scripts/economy/shell_wallet.gd")

var _trace := false
var _tests := 0
var _failed := 0
var _test_name := ""
var _test_fails := 0
var _test_msgs: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_trace = "--stdout-trace" in args
	_test_potion()
	_test_super_potion()
	_test_item_sem_preco()
	_test_moeda_e_int_do_enum()
	_test_ids()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)


func _test_potion() -> void:
	_begin("potion")
	var offer: Dictionary = Catalog.offer_for("potion")
	_ok(not offer.is_empty(), "potion sem oferta")
	_eq_str("item_id", str(offer.get("item_id", "")), "potion")
	_eq_int("quantity", int(offer.get("quantity", -1)), 1)
	_eq_int("coin", int(offer.get("coin", -1)), Wallet.Coin.BRONZE)
	_eq_int("price", int(offer.get("price", -1)), 10)
	_ok(Catalog.has_offer("potion"), "has_offer negou potion")
	_end()


func _test_super_potion() -> void:
	_begin("super_potion")
	var offer: Dictionary = Catalog.offer_for("super_potion")
	_ok(not offer.is_empty(), "super_potion sem oferta")
	_eq_str("item_id", str(offer.get("item_id", "")), "super_potion")
	_eq_int("quantity", int(offer.get("quantity", -1)), 1)
	_eq_int("coin", int(offer.get("coin", -1)), Wallet.Coin.BRONZE)
	_eq_int("price", int(offer.get("price", -1)), 25)
	_ok(Catalog.has_offer("super_potion"), "has_offer negou super_potion")
	_end()

func _test_item_sem_preco() -> void:
	_begin("item_sem_preco")
	for item_id in ["revive", "sitrus_berry", "lum_berry", "elixir", "amulet", "charm", ""]:
		_ok(Catalog.offer_for(item_id).is_empty(), "offer_for('%s') deveria ser vazio" % item_id)
		_ok(not Catalog.has_offer(item_id), "has_offer('%s') deveria ser false" % item_id)
	_end()


func _test_moeda_e_int_do_enum() -> void:
	_begin("moeda_e_int_do_enum")
	var offer: Dictionary = Catalog.offer_for("potion")
	var coin: Variant = offer.get("coin")
	_ok(typeof(coin) == TYPE_INT, "coin nao e int (tipo %d)" % typeof(coin))
	_ok(int(coin) == Wallet.Coin.BRONZE, "coin nao e o int do enum BRONZE: %s" % [coin])
	_end()


func _test_ids() -> void:
	_begin("ids")
	var ids: Array = Catalog.offer_ids()
	_ok(ids.size() == 2, "esperava 2 itens com preco, obtido %d: %s" % [ids.size(), ids])
	for item_id in ["potion", "super_potion"]:
		_ok(item_id in ids, "offer_ids sem %s" % item_id)
	_end()


func _eq_int(label: String, got: int, expected: int) -> void:
	_ok(got == expected, "%s: esperado %d, obtido %d" % [label, expected, got])


func _eq_str(label: String, got: String, expected: String) -> void:
	_ok(got == expected, "%s: esperado '%s', obtido '%s'" % [label, expected, got])


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