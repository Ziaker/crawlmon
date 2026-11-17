extends SceneTree
## D-1253 item 4 / D-1285: uma compra feita no Hub chega a expedicao seguinte.
## O kit gratuito e os itens held continuam com o comportamento atual; so os
## consumiveis COMPRADOS e nao usados sobrevivem ao reset.
##   Godot_v4.7.2-stable_win64_console.exe --headless --script res://tests/economy/inventory_purchase_test.gd -- --stdout-trace

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
	_test_compra_entra_no_inventario()
	_test_compra_sobrevive_ao_reset()
	_test_reset_duas_vezes_nao_duplica()
	_test_consumo_gasta_kit_antes_das_compras()
	_test_consumo_pelo_combatant_reconcilia_no_reset()
	_test_consumo_total_pelo_combatant_apaga_compras()
	_test_compra_recusada_nao_altera_nada()
	_test_held_do_kit_nao_duplica()
	_test_nova_campanha_limpa_compras_e_carteira()
	var ok := _failed == 0
	print("[ECON] ", JSON.stringify({"ev": "summary", "ok": ok, "tests": _tests, "failed": _failed}))
	quit(0 if ok else 1)


## Compra (potion, qty 2, bronze, 7 com saldo 10) entra no inventario e em purchased_items.
func _test_compra_entra_no_inventario() -> void:
	_begin("compra_entra_no_inventario")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	_eq_int("saldo de bronze", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 3)
	_eq_int("inventario potion", _gs.item_count("potion"), 5)
	_eq_int("purchased_count potion", _gs.purchased_count("potion"), 2)
	_ok(not _gs.purchased_items.has("amulet"), "held amulet entrou em purchased_items")
	_end()


## Depois do reset: a compra continua e o kit gratuito esta restaurado.
func _test_compra_sobrevive_ao_reset() -> void:
	_begin("compra_sobrevive_ao_reset")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	# item achado na expedicao (nao comprado) continua sendo perdido no reset
	_gs.inventory["super_potion"] = 2
	_gs.reset_expedition_inventory()
	_eq_int("potion apos reset (3 do kit + 2 comprados)", _gs.item_count("potion"), 5)
	_eq_int("purchased_count apos reset", _gs.purchased_count("potion"), 2)
	_eq_int("amulet do kit", _gs.item_count("amulet"), 1)
	_eq_int("charm do kit", _gs.item_count("charm"), 1)
	_eq_int("super_potion achado na expedicao", _gs.item_count("super_potion"), 0)
	_end()


## Reset duas vezes seguidas nao duplica nada.
func _test_reset_duas_vezes_nao_duplica() -> void:
	_begin("reset_duas_vezes_nao_duplica")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	_gs.reset_expedition_inventory()
	var after_first: Dictionary = _gs.inventory.duplicate(true)
	_gs.reset_expedition_inventory()
	_ok(after_first == _gs.inventory, "inventario mudou no segundo reset: %s -> %s" % [after_first, _gs.inventory])
	_eq_int("potion apos dois resets", _gs.item_count("potion"), 5)
	_eq_int("purchased_count apos dois resets", _gs.purchased_count("potion"), 2)
	_end()


## Consumir 4 potions (3 gratuitas + 1 comprada) deixa purchased_count == 1.
func _test_consumo_gasta_kit_antes_das_compras() -> void:
	_begin("consumo_gasta_kit_antes_das_compras")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	_eq_int("potion antes de consumir", _gs.item_count("potion"), 5)
	for _i in range(3):
		_gs.remove_item("potion")
	_eq_int("potion apos gastar o kit", _gs.item_count("potion"), 2)
	_eq_int("purchased_count apos gastar o kit", _gs.purchased_count("potion"), 2)
	_gs.remove_item("potion")
	_eq_int("potion apos gastar 1 comprada", _gs.item_count("potion"), 1)
	_eq_int("purchased_count apos gastar 1 comprada", _gs.purchased_count("potion"), 1)
	_gs.reset_expedition_inventory()
	_eq_int("potion apos reset (3 do kit + 1 comprada)", _gs.item_count("potion"), 4)
	_eq_int("purchased_count apos reset", _gs.purchased_count("potion"), 1)
	_end()


## O Combatant (Battle.use_item) consome o MESMO Dictionary do GameState sem passar por
## GameState.remove_item: o reset tem de reconciliar purchased_items antes de reconstruir.
## 3 do kit + 2 compradas = 5; consumir 4 pelo Combatant deixa 1, entao o reset devolve 3 + 1 = 4.
func _test_consumo_pelo_combatant_reconcilia_no_reset() -> void:
	_begin("consumo_pelo_combatant_reconcilia_no_reset")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	_eq_int("potion antes de consumir", _gs.item_count("potion"), 5)
	for _i in range(4):
		_gs.party[0].remove_item("potion")
	_eq_int("potion apos 4 consumos pelo Combatant", _gs.item_count("potion"), 1)
	_gs.reset_expedition_inventory()
	_eq_int("potion apos reset (3 do kit + 1 comprada restante)", _gs.item_count("potion"), 4)
	_eq_int("purchased_count apos reset", _gs.purchased_count("potion"), 1)
	_end()


## Consumir as 5 pelo Combatant zera as compras: o reset devolve so o kit gratuito.
func _test_consumo_total_pelo_combatant_apaga_compras() -> void:
	_begin("consumo_total_pelo_combatant_apaga_compras")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	for _i in range(5):
		_gs.party[0].remove_item("potion")
	_eq_int("potion apos 5 consumos pelo Combatant", _gs.item_count("potion"), 0)
	_gs.reset_expedition_inventory()
	_eq_int("potion apos reset (so o kit)", _gs.item_count("potion"), 3)
	_eq_int("purchased_count apos reset", _gs.purchased_count("potion"), 0)
	_ok(not _gs.purchased_items.has("potion"), "potion continuou em purchased_items")
	_end()


## Compra recusada (saldo insuficiente, moeda errada) nao altera nada.
func _test_compra_recusada_nao_altera_nada() -> void:
	_begin("compra_recusada_nao_altera_nada")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 6)
	_gs.shell_wallet.credit(Wallet.Coin.GOLD, 50)
	var wallet_before: Dictionary = _gs.shell_wallet.snapshot()
	var inventory_before: Dictionary = _gs.inventory.duplicate(true)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(not bool(res.get("ok", true)), "saldo 6 pagando 7 foi aceito: %s" % [res])
	_eq_str("reason saldo insuficiente", str(res.get("reason", "")), "insufficient_funds")
	_eq_int("purchased_count potion", _gs.purchased_count("potion"), 0)
	_ok(_gs.shell_wallet.snapshot() == wallet_before, "carteira mudou: %s -> %s" % [wallet_before, _gs.shell_wallet.snapshot()])
	_ok(_gs.inventory == inventory_before, "inventario mudou: %s -> %s" % [inventory_before, _gs.inventory])
	var wrong: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.GOLD)
	_ok(not bool(wrong.get("ok", true)), "moeda errada foi aceita: %s" % [wrong])
	_eq_str("reason moeda errada", str(wrong.get("reason", "")), "wrong_currency")
	_eq_int("purchased_count potion apos moeda errada", _gs.purchased_count("potion"), 0)
	_ok(_gs.shell_wallet.snapshot() == wallet_before, "carteira mudou na moeda errada: %s" % [_gs.shell_wallet.snapshot()])
	_ok(_gs.inventory == inventory_before, "inventario mudou na moeda errada: %s" % [_gs.inventory])
	_end()


## Itens held do kit (amulet, charm) nao duplicam apos reset; held comprado nao entra em purchased_items.
func _test_held_do_kit_nao_duplica() -> void:
	_begin("held_do_kit_nao_duplica")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	_gs.reset_expedition_inventory()
	var res: Dictionary = _gs.buy(_offer("amulet", 1, Wallet.Coin.BRONZE, 4), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra de held recusada: %s" % [res])
	_eq_int("amulet comprado no inventario", _gs.item_count("amulet"), 2)
	_ok(not _gs.purchased_items.has("amulet"), "held comprado entrou em purchased_items")
	_gs.reset_expedition_inventory()
	_eq_int("amulet apos 1 reset", _gs.item_count("amulet"), 2)
	_eq_int("charm apos 1 reset", _gs.item_count("charm"), 1)
	_gs.reset_expedition_inventory()
	_eq_int("amulet apos 2 resets", _gs.item_count("amulet"), 2)
	_eq_int("charm apos 2 resets", _gs.item_count("charm"), 1)
	_end()


## Nova campanha limpa purchased_items e zera a carteira.
func _test_nova_campanha_limpa_compras_e_carteira() -> void:
	_begin("nova_campanha_limpa_compras_e_carteira")
	_fresh()
	_gs.shell_wallet.credit(Wallet.Coin.BRONZE, 10)
	var res: Dictionary = _gs.buy(_offer("potion", 2, Wallet.Coin.BRONZE, 7), Wallet.Coin.BRONZE)
	_ok(bool(res.get("ok", false)), "compra recusada: %s" % [res])
	_eq_int("purchased_count antes da campanha", _gs.purchased_count("potion"), 2)
	if CharacterCatalog.get_character(StringName("abra")) == null:
		_ok(false, "CharacterCatalog sem abra: nova campanha nao pode ser exercitada de verdade")
		_end()
		return
	_gs.start_new_campaign("abra")
	_eq_int("purchased_count apos nova campanha", _gs.purchased_count("potion"), 0)
	_ok(not _gs.purchased_items.has("potion"), "purchased_items nao foi limpo")
	_eq_int("carteira bronze apos nova campanha", _gs.shell_wallet.balance(Wallet.Coin.BRONZE), 0)
	_eq_int("carteira prata apos nova campanha", _gs.shell_wallet.balance(Wallet.Coin.SILVER), 0)
	_eq_int("carteira ouro apos nova campanha", _gs.shell_wallet.balance(Wallet.Coin.GOLD), 0)
	_eq_int("potion apos nova campanha", _gs.item_count("potion"), 3)
	_eq_int("amulet apos nova campanha", _gs.item_count("amulet"), 1)
	_eq_int("charm apos nova campanha", _gs.item_count("charm"), 1)
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


func _offer(item_id: String, quantity: int, coin: int, price: int) -> Dictionary:
	return {"item_id": item_id, "quantity": quantity, "coin": coin, "price": price}


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
