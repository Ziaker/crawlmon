extends SceneTree
## D-1300 item 3: testes da migração de GameState.shell_balance para o saldo Bronze da carteira.
## Nao toca em user://progress.json (nunca chama save_progress).
##   Godot_v4.7.2-stable_win64_console.exe --headless \
##     --script res://tests/economy/shell_balance_migration_test.gd -- --stdout-trace

const Wallet := preload("res://scripts/economy/shell_wallet.gd")
const KIT := {"potion": 3, "amulet": 1, "charm": 1}

var _trace := false
var _tests := 0
var _failed := 0
var _test_name := ""
var _test_fails := 0
var _test_msgs: Array[String] = []
var _gs: Variant


func _initialize() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_trace = "--stdout-trace" in args
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_gs = root.get_node_or_null("/root/GameState")
	if _gs == null:
		_failed = 1
		print("[ECON] ", JSON.stringify({"ev": "summary", "ok": false, "tests": 0, "failed": 1, "error": "autoload GameState ausente"}))
		quit(1)
		return
	_test_add_shells_soma_bronze()
	_test_setter_leva_o_bronze()
	_test_add_shells_negativo_clampa()
	_test_prata_e_ouro_intactos()
	_test_buy_item_ok()
	_test_buy_item_sem_saldo()
	_test_buy_item_sem_oferta()
	_test_nova_campanha_zera_bronze()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)

## add_shells(10) chega ao saldo Bronze da carteira e a propriedade le o mesmo valor.
func _test_add_shells_soma_bronze() -> void:
	_begin("add_shells_soma_bronze")
	_fresh()
	_gs.add_shells(10)
	_eq_int("carteira bronze", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 10)
	_eq_int("shell_balance", int(_gs.shell_balance), 10)
	_gs.add_shells(5)
	_eq_int("carteira bronze apos +5", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 15)
	_eq_int("shell_balance apos +5", int(_gs.shell_balance), 15)
	_end()


## Atribuir shell_balance leva o saldo Bronze ao valor novo, mantendo prata e ouro.
func _test_setter_leva_o_bronze() -> void:
	_begin("setter_leva_o_bronze")
	_fresh()
	_gs.shell_balance = 5
	_eq_int("carteira bronze", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 5)
	_eq_int("shell_balance", int(_gs.shell_balance), 5)
	_gs.shell_balance = 12
	_eq_int("carteira bronze apos 12", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 12)
	_gs.shell_balance = 0
	_eq_int("carteira bronze apos 0", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 0)
	_end()


## add_shells(-100) nunca deixa o Bronze abaixo de zero.
func _test_add_shells_negativo_clampa() -> void:
	_begin("add_shells_negativo_clampa")
	_fresh()
	_gs.add_shells(10)
	_gs.add_shells(-100)
	_eq_int("carteira bronze", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 0)
	_eq_int("shell_balance", int(_gs.shell_balance), 0)
	_gs.shell_balance = -7
	_eq_int("carteira bronze apos setter negativo", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 0)
	_end()


## A migracao so toca no Bronze: prata e ouro continuam como estavam.
func _test_prata_e_ouro_intactos() -> void:
	_begin("prata_e_ouro_intactos")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.SILVER, 4)
	_gs.shell_wallet.credit(Wallet.Coin.GOLD, 9)
	_gs.add_shells(10)
	_gs.shell_balance = 3
	_gs.add_shells(-50)
	_eq_int("bronze", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 0)
	_eq_int("prata", _gs.shell_wallet.balance(Wallet.Coin.SILVER), 4)
	_eq_int("ouro", _gs.shell_wallet.balance(Wallet.Coin.GOLD), 9)
	_end()

## buy_item("potion") com 30 Bronze: paga 10, entra no inventario e em purchased_items.
func _test_buy_item_ok() -> void:
	_begin("buy_item_ok")
	_fresh()
	_gs.add_shells(30)
	var res: Dictionary = _gs.buy_item("potion")
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	_eq_str("item_id da resposta", str(res.get("item_id", "")), "potion")
	_eq_int("quantity da resposta", int(res.get("quantity", -1)), 1)
	_eq_int("coin da resposta", int(res.get("coin", -1)), Wallet.Coin.BRONZE)
	_eq_int("price da resposta", int(res.get("price", -1)), 10)
	_eq_int("saldo bronze", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 20)
	_eq_int("shell_balance", int(_gs.shell_balance), 20)
	_eq_int("inventario potion (3 do kit + 1)", _gs.item_count("potion"), 4)
	_eq_int("purchased_count potion", _gs.purchased_count("potion"), 1)
	_end()


## buy_item("potion") com 9 Bronze: recusado por saldo insuficiente, nada muda.
func _test_buy_item_sem_saldo() -> void:
	_begin("buy_item_sem_saldo")
	_fresh()
	_gs.add_shells(9)
	var wallet_before: Dictionary = _gs.shell_wallet.snapshot()
	var inventory_before: Dictionary = _gs.inventory.duplicate(true)
	var res: Dictionary = _gs.buy_item("potion")
	_ok(not bool(res.get("ok", true)), "saldo 9 pagando 10 foi aceito: %s" % [res])
	_eq_str("reason", str(res.get("reason", "")), "insufficient_funds")
	_ok(_gs.shell_wallet.snapshot() == wallet_before, "carteira mudou: %s -> %s" % [wallet_before, _gs.shell_wallet.snapshot()])
	_ok(_gs.inventory == inventory_before, "inventario mudou: %s -> %s" % [inventory_before, _gs.inventory])
	_eq_int("purchased_count potion", _gs.purchased_count("potion"), 0)
	_end()


## Item sem preco no catalogo nao e vendido: no_offer.
func _test_buy_item_sem_oferta() -> void:
	_begin("buy_item_sem_oferta")
	_fresh()
	_gs.add_shells(100)
	var wallet_before: Dictionary = _gs.shell_wallet.snapshot()
	var inventory_before: Dictionary = _gs.inventory.duplicate(true)
	var res: Dictionary = _gs.buy_item("revive")
	_ok(not bool(res.get("ok", true)), "revive foi vendido: %s" % [res])
	_eq_str("reason", str(res.get("reason", "")), "no_offer")
	_ok(_gs.shell_wallet.snapshot() == wallet_before, "carteira mudou: %s -> %s" % [wallet_before, _gs.shell_wallet.snapshot()])
	_ok(_gs.inventory == inventory_before, "inventario mudou: %s -> %s" % [inventory_before, _gs.inventory])
	_end()

## Nova campanha recria a carteira (saldo inicial zero, D-1285), zerando o Bronze.
func _test_nova_campanha_zera_bronze() -> void:
	_begin("nova_campanha_zera_bronze")
	_fresh()
	_gs.add_shells(40)
	_gs.shell_wallet.credit(Wallet.Coin.SILVER, 5)
	if CharacterCatalog.get_character(StringName("abra")) == null:
		_ok(false, "CharacterCatalog sem abra: nova campanha nao pode ser exercitada de verdade")
		_end()
		return
	_gs.start_new_campaign("abra")
	_eq_int("bronze apos nova campanha", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 0)
	_eq_int("shell_balance apos nova campanha", int(_gs.shell_balance), 0)
	_eq_int("prata apos nova campanha", _gs.shell_wallet.balance(Wallet.Coin.SILVER), 0)
	_end()


## Estado limpo: 1 membro (capacidade 10), kit gratuito restaurado, sem compras e carteira vazia.
func _fresh() -> void:
	var member := Combatant.new("Test", 10, 5, 5.0, true)
	_gs.party.assign([member])
	_gs.inventory = KIT.duplicate()
	# O lider real compartilha o Dictionary do GameState (CharacterFactory.create).
	member.inventory = _gs.inventory
	_gs.purchased_items.clear()
	_gs.shell_wallet = Wallet.new()


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