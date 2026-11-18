class_name ShellDropMath
extends RefCounted
## Chances de drop dos Cascos (D-1285, D-1286): prata = 7 + LUK, ouro = 3 + LUK / 2,
## bronze = 50 fixo, sem arredondar nem limitar. Taxas em
## res://data/economy/shell_drop_rates.json, lidas uma vez e guardadas em cache.
## Quais moedas são elegíveis e o sorteio conjunto delas não é decidido aqui.

const RATES_PATH := "res://data/economy/shell_drop_rates.json"
const ROLL_SCALE := 100.0

static var _rates: Dictionary = {}
static var _rates_loaded := false


static func silver_chance_pct(leader_luk: float) -> float:
	return _chance_pct("silver", leader_luk)


static func gold_chance_pct(leader_luk: float) -> float:
	return _chance_pct("gold", leader_luk)


static func roll_silver(rng: RandomNumberGenerator, leader_luk: float) -> bool:
	return rng.randf() * ROLL_SCALE < silver_chance_pct(leader_luk)


static func roll_gold(rng: RandomNumberGenerator, leader_luk: float) -> bool:
	return rng.randf() * ROLL_SCALE < gold_chance_pct(leader_luk)


static func bronze_chance_pct(leader_luk: float) -> float:
	return _chance_pct("bronze", leader_luk)


static func roll_bronze(rng: RandomNumberGenerator, leader_luk: float) -> bool:
	return rng.randf() * ROLL_SCALE < bronze_chance_pct(leader_luk)


## D-1309: quantas moedas caem por sucesso de sorteio = nivel do inimigo derrotado / divisor do tipo
## (Bronze 2, Silver 3, Golden 4), arredondado para baixo e no minimo 1.
static func quantity(coin: String, enemy_level: int) -> int:
	var rates := _load_rates()
	if not rates.has(coin):
		push_error("ShellDropMath: moeda '%s' ausente em %s" % [coin, RATES_PATH])
		return 0
	var divisor := maxi(int((rates[coin] as Dictionary).get("level_divisor", 1)), 1)
	return maxi(enemy_level / divisor, 1)


static func _chance_pct(coin: String, leader_luk: float) -> float:
	var rates := _load_rates()
	if not rates.has(coin):
		push_error("ShellDropMath: moeda '%s' ausente em %s" % [coin, RATES_PATH])
		return 0.0
	var entry: Dictionary = rates[coin]
	var base_pct := float(entry.get("base_pct", 0.0))
	var per_luk_pct := float(entry.get("per_luk_pct", 0.0))
	return base_pct + per_luk_pct * leader_luk


static func _load_rates() -> Dictionary:
	if _rates_loaded:
		return _rates
	_rates_loaded = true
	if not FileAccess.file_exists(RATES_PATH):
		push_error("ShellDropMath: arquivo de taxas não encontrado: %s" % RATES_PATH)
		return _rates
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RATES_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ShellDropMath: JSON inválido em %s" % RATES_PATH)
		return _rates
	_rates = parsed
	return _rates
