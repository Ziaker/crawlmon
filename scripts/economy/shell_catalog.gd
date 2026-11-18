class_name ShellCatalog
extends RefCounted
## Precos da loja do Hub (D-1300): cada item tem uma moeda e um preco, sem conversao entre
## moedas (D-1285). Precos em res://data/economy/shell_prices.json, lidos uma vez e guardados
## em cache. Entrada com moeda desconhecida, preco ou quantidade invalidos e ignorada.

const ShellWalletClass = preload("res://scripts/economy/shell_wallet.gd")
const PRICES_PATH := "res://data/economy/shell_prices.json"

static var _prices: Dictionary = {}
static var _prices_loaded := false


static func has_offer(item_id: String) -> bool:
	return not offer_for(item_id).is_empty()


static func offer_for(item_id: String) -> Dictionary:
	var prices := _load_prices()
	if not prices.has(item_id):
		return {}
	var entry: Variant = prices[item_id]
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = entry
	var coin := _coin_from_name(String(d.get("coin", "")))
	if coin < 0:
		return {}
	var price_v: Variant = d.get("price")
	if typeof(price_v) != TYPE_FLOAT and typeof(price_v) != TYPE_INT:
		return {}
	var price := int(price_v)
	if price < 0:
		return {}
	var quantity_v: Variant = d.get("quantity", 1)
	if typeof(quantity_v) != TYPE_FLOAT and typeof(quantity_v) != TYPE_INT:
		return {}
	var quantity := int(quantity_v)
	if quantity <= 0:
		return {}
	return {"item_id": item_id, "quantity": quantity, "coin": coin, "price": price}


static func offer_ids() -> Array:
	var out: Array = []
	for item_id in _load_prices().keys():
		if not offer_for(String(item_id)).is_empty():
			out.append(item_id)
	return out


static func _coin_from_name(name: String) -> int:
	match name:
		"bronze":
			return ShellWalletClass.Coin.BRONZE
		"silver":
			return ShellWalletClass.Coin.SILVER
		"gold":
			return ShellWalletClass.Coin.GOLD
	return -1


static func _load_prices() -> Dictionary:
	if _prices_loaded:
		return _prices
	_prices_loaded = true
	if not FileAccess.file_exists(PRICES_PATH):
		push_error("ShellCatalog: arquivo de precos nao encontrado: %s" % PRICES_PATH)
		return _prices
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRICES_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ShellCatalog: JSON invalido em %s" % PRICES_PATH)
		return _prices
	_prices = parsed
	return _prices