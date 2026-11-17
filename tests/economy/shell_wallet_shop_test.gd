extends SceneTree
## D-1285: testes puros de ShellWallet e ShellShop (sem GameState, UI, preços, catálogo
## ou conversão entre moedas).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/shell_wallet_shop_test.gd -- --stdout-trace
## Sem --stdout-trace imprime só o resumo.

const Wallet := preload("res://scripts/economy/shell_wallet.gd")
const Shop := preload("res://scripts/economy/shell_shop.gd")

var _trace := false
var _tests := 0
var _failed := 0
var _test_name := ""
var _test_fails := 0
var _test_msgs: Array[String] = []
var _held_ids: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_trace = "--stdout-trace" in args
	_test_saldos_iniciais()
	_test_credito_debito_separados()
	_test_debito_insuficiente()
	_test_snapshot_restore()
	_test_oferta_invalida()
	_test_compra_ok()
	_test_saldo_insuficiente()
	_test_moeda_errada()
	_test_inventario_cheio()
	_test_held_ignora_capacidade()
	_test_compra_repetida()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)


func _test_saldos_iniciais() -> void:
	_begin("saldos_iniciais")
	var wallet := Wallet.new()
	for coin in [Wallet.Coin.BRONZE, Wallet.Coin.SILVER, Wallet.Coin.GOLD]:
		_eq_int("saldo da moeda %d" % int(coin), wallet.balance(int(coin)), 0)
	_ok(wallet.snapshot() == {"bronze": 0, "silver": 0, "gold": 0},
		"snapshot inicial: %s" % [wallet.snapshot()])
	_end()


func _test_credito_debito_separados() -> void:
	_begin("credito_debito_separados")
	var wallet := Wallet.new()
	_ok(wallet.credit(Wallet.Coin.SILVER, 5), "credit de prata recusado")
	_eq_int("bronze após credit de prata", wallet.balance(Wallet.Coin.BRONZE), 0)
	_eq_int("ouro após credit de prata", wallet.balance(Wallet.Coin.GOLD), 0)
	_eq_int("prata após credit de prata", wallet.balance(Wallet.Coin.SILVER), 5)
	_ok(wallet.credit(Wallet.Coin.GOLD, 2), "credit de ouro recusado")
	_eq_int("prata após credit de ouro", wallet.balance(Wallet.Coin.SILVER), 5)
	_eq_int("bronze após credit de ouro", wallet.balance(Wallet.Coin.BRONZE), 0)
	_ok(wallet.debit(Wallet.Coin.SILVER, 3), "debit de prata recusado")
	_eq_int("prata após debit", wallet.balance(Wallet.Coin.SILVER), 2)
	_eq_int("bronze intacto após debit", wallet.balance(Wallet.Coin.BRONZE), 0)
	_eq_int("ouro intacto após debit", wallet.balance(Wallet.Coin.GOLD), 2)
	_ok(not wallet.credit(Wallet.Coin.BRONZE, 0), "credit de 0 aceito")
	_ok(not wallet.credit(Wallet.Coin.BRONZE, -4), "credit negativo aceito")
	_ok(not wallet.debit(Wallet.Coin.GOLD, 0), "debit de 0 aceito")
	_ok(not wallet.debit(Wallet.Coin.GOLD, -1), "debit negativo aceito")
	_eq_int("ouro após recusas", wallet.balance(Wallet.Coin.GOLD), 2)
	_end()


func _test_debito_insuficiente() -> void:
	_begin("debito_insuficiente")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 4)
	wallet.credit(Wallet.Coin.GOLD, 9)
	var before := wallet.snapshot()
	_ok(not wallet.debit(Wallet.Coin.BRONZE, 5), "debit acima do saldo de bronze aceito")
	_ok(wallet.snapshot() == before, "carteira mudou: %s -> %s" % [before, wallet.snapshot()])
	_ok(wallet.can_afford(Wallet.Coin.BRONZE, 4), "can_afford negou saldo exato")
	_ok(not wallet.can_afford(Wallet.Coin.BRONZE, 5), "can_afford aceitou acima do saldo")
	_ok(not wallet.can_afford(Wallet.Coin.SILVER, 1), "can_afford usou outra moeda")
	_end()


func _test_snapshot_restore() -> void:
	_begin("snapshot_restore")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 3)
	wallet.credit(Wallet.Coin.SILVER, 8)
	wallet.credit(Wallet.Coin.GOLD, 13)
	var saved := wallet.snapshot()
	wallet.restore({"bronze": 0, "silver": 0, "gold": 0})
	_ok(wallet.snapshot() == {"bronze": 0, "silver": 0, "gold": 0},
		"restore não zerou: %s" % [wallet.snapshot()])
	wallet.restore(saved)
	_ok(wallet.snapshot() == saved, "roundtrip do snapshot: %s != %s" % [wallet.snapshot(), saved])
	_end()


func _test_oferta_invalida() -> void:
	_begin("oferta_invalida")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 50)
	var inventory := {"potion": 1}
	_expect_refusal("item_id vazio", wallet, inventory, 10,
		{"item_id": "", "quantity": 1, "coin": Wallet.Coin.BRONZE, "price": 1},
		Wallet.Coin.BRONZE, "invalid_offer")
	_expect_refusal("quantity 0", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 0, "coin": Wallet.Coin.BRONZE, "price": 1},
		Wallet.Coin.BRONZE, "invalid_offer")
	_expect_refusal("quantity negativa", wallet, inventory, 10,
		{"item_id": "potion", "quantity": -2, "coin": Wallet.Coin.BRONZE, "price": 1},
		Wallet.Coin.BRONZE, "invalid_offer")
	_expect_refusal("price negativo", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 1, "coin": Wallet.Coin.BRONZE, "price": -1},
		Wallet.Coin.BRONZE, "invalid_offer")
	_expect_refusal("moeda inválida", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 1, "coin": 99, "price": 1},
		Wallet.Coin.BRONZE, "invalid_offer")
	_expect_refusal("oferta sem price", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 1, "coin": Wallet.Coin.BRONZE},
		Wallet.Coin.BRONZE, "invalid_offer")
	_end()


func _test_compra_ok() -> void:
	_begin("compra_ok")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 10)
	var inventory := {"potion": 1, "herb": 2}
	var res := Shop.purchase(wallet, inventory, 10, Callable(self, "_is_held"),
		{"item_id": "potion", "quantity": 2, "coin": Wallet.Coin.BRONZE, "price": 7},
		Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	_eq_int("saldo de bronze", wallet.balance(Wallet.Coin.BRONZE), 3)
	_eq_int("inventário potion", int(inventory.get("potion", -1)), 3)
	_eq_int("inventário herb", int(inventory.get("herb", -1)), 2)
	_eq_str("item_id da resposta", str(res.get("item_id", "")), "potion")
	_eq_int("quantity da resposta", int(res.get("quantity", -1)), 2)
	_eq_int("coin da resposta", int(res.get("coin", -1)), Wallet.Coin.BRONZE)
	_eq_int("price da resposta", int(res.get("price", -1)), 7)
	_eq_int("balance_after da resposta", int(res.get("balance_after", -1)), 3)
	_end()


func _test_saldo_insuficiente() -> void:
	_begin("saldo_insuficiente")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 6)
	var inventory := {"herb": 1}
	_expect_refusal("preço 7 com saldo 6", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 2, "coin": Wallet.Coin.BRONZE, "price": 7},
		Wallet.Coin.BRONZE, "insufficient_funds")
	wallet.credit(Wallet.Coin.GOLD, 99)
	_expect_refusal("ouro não paga bronze", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 2, "coin": Wallet.Coin.BRONZE, "price": 7},
		Wallet.Coin.BRONZE, "insufficient_funds")
	_end()


func _test_moeda_errada() -> void:
	_begin("moeda_errada")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 100)
	wallet.credit(Wallet.Coin.SILVER, 100)
	var inventory := {}
	_expect_refusal("oferta em bronze paga com prata", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 2, "coin": Wallet.Coin.BRONZE, "price": 7},
		Wallet.Coin.SILVER, "wrong_currency")
	_end()


func _test_inventario_cheio() -> void:
	_begin("inventario_cheio")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 100)
	var inventory := {"a": 2, "b": 3, "c": 4}
	_expect_refusal("9 + 2 acima da capacidade 10", wallet, inventory, 10,
		{"item_id": "potion", "quantity": 2, "coin": Wallet.Coin.BRONZE, "price": 5},
		Wallet.Coin.BRONZE, "inventory_full")
	var res := Shop.purchase(wallet, inventory, 10, Callable(self, "_is_held"),
		{"item_id": "potion", "quantity": 1, "coin": Wallet.Coin.BRONZE, "price": 5},
		Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "9 + 1 deveria caber: %s" % [res])
	_eq_int("inventário potion", int(inventory.get("potion", -1)), 1)
	_eq_int("saldo de bronze", wallet.balance(Wallet.Coin.BRONZE), 95)
	_end()


func _test_held_ignora_capacidade() -> void:
	_begin("held_ignora_capacidade")
	_held_ids.append("keepsake")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 100)
	var inventory := {"potion": 1, "keepsake": 9}
	var res := Shop.purchase(wallet, inventory, 2, Callable(self, "_is_held"),
		{"item_id": "potion", "quantity": 1, "coin": Wallet.Coin.BRONZE, "price": 4},
		Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "held contou para a capacidade: %s" % [res])
	_eq_int("inventário potion", int(inventory["potion"]), 2)
	var held_res := Shop.purchase(wallet, inventory, 2, Callable(self, "_is_held"),
		{"item_id": "keepsake", "quantity": 3, "coin": Wallet.Coin.BRONZE, "price": 4},
		Wallet.Coin.BRONZE)
	_ok(bool(held_res.get("ok", false)), "item held barrado pela capacidade: %s" % [held_res])
	_eq_int("inventário keepsake", int(inventory["keepsake"]), 12)
	_end()


func _test_compra_repetida() -> void:
	_begin("compra_repetida")
	var wallet := Wallet.new()
	wallet.credit(Wallet.Coin.BRONZE, 10)
	var inventory := {}
	var offer := {"item_id": "potion", "quantity": 2, "coin": Wallet.Coin.BRONZE, "price": 3}
	var first := Shop.purchase(wallet, inventory, 10, Callable(self, "_is_held"), offer, Wallet.Coin.BRONZE)
	_ok(bool(first.get("ok", false)), "primeira compra recusada: %s" % [first])
	_eq_int("saldo após primeira", wallet.balance(Wallet.Coin.BRONZE), 7)
	_eq_int("inventário após primeira", int(inventory.get("potion", -1)), 2)
	var second := Shop.purchase(wallet, inventory, 10, Callable(self, "_is_held"), offer, Wallet.Coin.BRONZE)
	_ok(bool(second.get("ok", false)), "segunda compra recusada: %s" % [second])
	_eq_int("saldo após segunda", wallet.balance(Wallet.Coin.BRONZE), 4)
	_eq_int("inventário após segunda", int(inventory.get("potion", -1)), 4)
	_eq_int("balance_after da segunda", int(second.get("balance_after", -1)), 4)
	_end()


func _expect_refusal(label: String, wallet: Wallet, inventory: Dictionary, capacity: int, offer: Dictionary, pay_coin: int, reason: String) -> void:
	var wallet_before := wallet.snapshot()
	var inventory_before := inventory.duplicate(true)
	var result := Shop.purchase(wallet, inventory, capacity, Callable(self, "_is_held"), offer, pay_coin)
	_ok(not bool(result.get("ok", true)), "%s: compra aceita: %s" % [label, result])
	_eq_str("%s: reason" % label, str(result.get("reason", "")), reason)
	_ok(wallet.snapshot() == wallet_before,
		"%s: carteira mudou %s -> %s" % [label, wallet_before, wallet.snapshot()])
	_ok(inventory == inventory_before,
		"%s: inventário mudou %s -> %s" % [label, inventory_before, inventory])


func _is_held(item_id: String) -> bool:
	return item_id in _held_ids


func _eq_int(label: String, got: int, expected: int) -> void:
	_ok(got == expected, "%s: esperado %d, obtido %d" % [label, expected, got])


func _eq_str(label: String, got: String, expected: String) -> void:
	_ok(got == expected, "%s: esperado '%s', obtido '%s'" % [label, expected, got])


func _begin(test_name: String) -> void:
	_test_name = test_name
	_test_fails = 0
	_test_msgs.clear()
	_held_ids.clear()
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
