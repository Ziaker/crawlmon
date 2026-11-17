class_name ShellWallet
extends RefCounted
## Saldos separados dos Cascos (D-1285): bronze, prata e ouro nunca se convertem.
## Cada moeda tem o seu próprio saldo, começa em zero e só muda na moeda pedida.

enum Coin { BRONZE, SILVER, GOLD }

var _balances: Dictionary = {
	Coin.BRONZE: 0,
	Coin.SILVER: 0,
	Coin.GOLD: 0,
}


func balance(coin: int) -> int:
	if not _balances.has(coin):
		return 0
	return int(_balances[coin])


func can_afford(coin: int, amount: int) -> bool:
	if amount <= 0:
		return false
	return balance(coin) >= amount


func credit(coin: int, amount: int) -> bool:
	if amount <= 0 or not _balances.has(coin):
		return false
	_balances[coin] = balance(coin) + amount
	return true


func debit(coin: int, amount: int) -> bool:
	if amount <= 0 or not _balances.has(coin):
		return false
	if balance(coin) < amount:
		return false
	_balances[coin] = balance(coin) - amount
	return true


func snapshot() -> Dictionary:
	return {
		"bronze": balance(Coin.BRONZE),
		"silver": balance(Coin.SILVER),
		"gold": balance(Coin.GOLD),
	}


func restore(d: Dictionary) -> void:
	for coin in _balances:
		_balances[coin] = 0
	_balances[Coin.BRONZE] = maxi(0, int(d.get("bronze", 0)))
	_balances[Coin.SILVER] = maxi(0, int(d.get("silver", 0)))
	_balances[Coin.GOLD] = maxi(0, int(d.get("gold", 0)))
