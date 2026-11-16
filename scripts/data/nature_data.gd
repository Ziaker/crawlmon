class_name NatureData
extends RefCounted
## Catalogo oficial das 8 Natures iniciais do Crawlmon (D-393).
## Cada Nature possui modificadores inteiros flat que somam exatamente zero,
## alem de parametros de modulacao de IA em combate.

const NATURES: Dictionary = {
	"hardy": {
		"name": "Hardy",
		"mods": {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0},
		"atb_reserve_bias": 0.0,
		"aggression_mult": 1.0,
	},
	"docile": {
		"name": "Docile",
		"mods": {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0},
		"atb_reserve_bias": 0.5,
		"aggression_mult": 0.8,
	},
	"brave": {
		"name": "Brave",
		"mods": {"STR": 2, "MAG": 0, "VIT": 1, "WIS": 0, "AGI": -3, "LUK": 0},
		"atb_reserve_bias": -1.0,
		"aggression_mult": 1.3,
	},
	"timid": {
		"name": "Timid",
		"mods": {"STR": -3, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 2, "LUK": 1},
		"atb_reserve_bias": 1.0,
		"aggression_mult": 0.7,
	},
	"modest": {
		"name": "Modest",
		"mods": {"STR": -2, "MAG": 3, "VIT": 0, "WIS": 0, "AGI": -1, "LUK": 0},
		"atb_reserve_bias": 0.0,
		"aggression_mult": 1.0,
	},
	"calm": {
		"name": "Calm",
		"mods": {"STR": -3, "MAG": 0, "VIT": 1, "WIS": 2, "AGI": 0, "LUK": 0},
		"atb_reserve_bias": 0.5,
		"aggression_mult": 0.8,
	},
	"jolly": {
		"name": "Jolly",
		"mods": {"STR": 0, "MAG": -3, "VIT": 0, "WIS": 0, "AGI": 2, "LUK": 1},
		"atb_reserve_bias": 0.0,
		"aggression_mult": 1.1,
	},
	"adamant": {
		"name": "Adamant",
		"mods": {"STR": 3, "MAG": -2, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": -1},
		"atb_reserve_bias": -0.5,
		"aggression_mult": 1.4,
	},
	# D-1216: dez Natures novas, cada uma com exatamente 3 status (rolos da roleta, D-1215).
	"bold": {
		"name": "Bold",
		"mods": {"STR": -2, "MAG": 0, "VIT": 3, "WIS": 0, "AGI": -1, "LUK": 0},
		"atb_reserve_bias": 0.5,
		"aggression_mult": 0.8,
	},
	"impish": {
		"name": "Impish",
		"mods": {"STR": 0, "MAG": -3, "VIT": 2, "WIS": 0, "AGI": 0, "LUK": 1},
		"atb_reserve_bias": 0.0,
		"aggression_mult": 1.1,
	},
	"relaxed": {
		"name": "Relaxed",
		"mods": {"STR": 0, "MAG": 0, "VIT": 2, "WIS": 1, "AGI": -3, "LUK": 0},
		"atb_reserve_bias": 1.0,
		"aggression_mult": 0.7,
	},
	"hasty": {
		"name": "Hasty",
		"mods": {"STR": 0, "MAG": 0, "VIT": -2, "WIS": -1, "AGI": 3, "LUK": 0},
		"atb_reserve_bias": -1.0,
		"aggression_mult": 1.3,
	},
	"naive": {
		"name": "Naive",
		"mods": {"STR": 1, "MAG": 0, "VIT": 0, "WIS": -3, "AGI": 2, "LUK": 0},
		"atb_reserve_bias": -0.5,
		"aggression_mult": 1.2,
	},
	"rash": {
		"name": "Rash",
		"mods": {"STR": 0, "MAG": 2, "VIT": 0, "WIS": -3, "AGI": 1, "LUK": 0},
		"atb_reserve_bias": -1.0,
		"aggression_mult": 1.4,
	},
	"quiet": {
		"name": "Quiet",
		"mods": {"STR": 0, "MAG": 2, "VIT": 0, "WIS": 1, "AGI": -3, "LUK": 0},
		"atb_reserve_bias": 1.0,
		"aggression_mult": 0.9,
	},
	"careful": {
		"name": "Careful",
		"mods": {"STR": 0, "MAG": -2, "VIT": 0, "WIS": 3, "AGI": 0, "LUK": -1},
		"atb_reserve_bias": 0.5,
		"aggression_mult": 0.7,
	},
	"lonely": {
		"name": "Lonely",
		"mods": {"STR": 3, "MAG": 0, "VIT": -2, "WIS": -1, "AGI": 0, "LUK": 0},
		"atb_reserve_bias": -0.5,
		"aggression_mult": 1.3,
	},
	"quirky": {
		"name": "Quirky",
		"mods": {"STR": -1, "MAG": 0, "VIT": -2, "WIS": 0, "AGI": 0, "LUK": 3},
		"atb_reserve_bias": 0.0,
		"aggression_mult": 1.0,
	},
}


## As 8 Natures iniciais (D-393). Sorteios que nao sao a roleta (inimigos e aliados criados pela
## CharacterFactory, D-405) continuam neste conjunto ate o criador decidir o pool deles (D-1219 ambiguidade 4).
const INITIAL_IDS: Array[String] = ["hardy", "docile", "brave", "timid", "modest", "calm", "jolly", "adamant"]

## Retorna a definicao da Nature pelo ID; caso nao exista, retorna "hardy" como fallback seguro.
static func get_nature(id: String) -> Dictionary:
	return NATURES.get(id.to_lower(), NATURES["hardy"])


## Lista dos IDs de todas as 18 Natures canônicas (D-1216).
static func get_all_nature_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in NATURES.keys():
		ids.append(str(k))
	return ids
