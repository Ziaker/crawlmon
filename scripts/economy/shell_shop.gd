class_name ShellShop
extends RefCounted
## Compra atômica da loja do Hub (D-1285): cada categoria só é paga com a sua moeda,
## sem conversão entre moedas. Tudo é validado antes de mexer na carteira ou no inventário.


static func purchase(wallet: ShellWallet, inventory: Dictionary, capacity: int, is_held: Callable, offer: Dictionary, pay_coin: int) -> Dictionary:
	if _invalid_offer(offer):
		return _refuse("invalid_offer")
	var item_id := String(offer["item_id"])
	var quantity := int(offer["quantity"])
	var coin := int(offer["coin"])
	var price := int(offer["price"])
	if pay_coin != coin:
		return _refuse("wrong_currency")
	if wallet.balance(pay_coin) < price:
		return _refuse("insufficient_funds")
	var held: bool = is_held.call(item_id)
	if not held and _unheld_total(inventory, is_held) + quantity > capacity:
		return _refuse("inventory_full")
	if price > 0 and not wallet.debit(pay_coin, price):
		return _refuse("insufficient_funds")
	inventory[item_id] = int(inventory.get(item_id, 0)) + quantity
	return {
		"ok": true,
		"item_id": item_id,
		"quantity": quantity,
		"coin": pay_coin,
		"price": price,
		"balance_after": wallet.balance(pay_coin),
	}


static func _invalid_offer(offer: Dictionary) -> bool:
	for key in ["item_id", "quantity", "coin", "price"]:
		if not offer.has(key):
			return true
	var item_id: Variant = offer["item_id"]
	if typeof(item_id) != TYPE_STRING and typeof(item_id) != TYPE_STRING_NAME:
		return true
	if String(item_id).is_empty():
		return true
	var quantity: Variant = offer["quantity"]
	if typeof(quantity) != TYPE_INT or int(quantity) <= 0:
		return true
	var price: Variant = offer["price"]
	if typeof(price) != TYPE_INT or int(price) < 0:
		return true
	return not _valid_coin(offer["coin"])


static func _valid_coin(coin: Variant) -> bool:
	if typeof(coin) != TYPE_INT:
		return false
	if coin == ShellWallet.Coin.BRONZE:
		return true
	if coin == ShellWallet.Coin.SILVER:
		return true
	return coin == ShellWallet.Coin.GOLD


static func _unheld_total(inventory: Dictionary, is_held: Callable) -> int:
	var total := 0
	for item_id in inventory:
		if is_held.call(String(item_id)):
			continue
		total += int(inventory[item_id])
	return total


static func _refuse(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
