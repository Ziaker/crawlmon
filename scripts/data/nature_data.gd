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
		"mods": {"STR": 2, "MAG": 0, "VIT": 1, "WIS": -1, "AGI": -2, "LUK": 0},
		"atb_reserve_bias": -1.0,
		"aggression_mult": 1.3,
	},
	"timid": {
		"name": "Timid",
		"mods": {"STR": -2, "MAG": 0, "VIT": -1, "WIS": 0, "AGI": 2, "LUK": 1},
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
		"mods": {"STR": -2, "MAG": 0, "VIT": 1, "WIS": 2, "AGI": 0, "LUK": -1},
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
		"mods": {"STR": 3, "MAG": -3, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0},
		"atb_reserve_bias": -0.5,
		"aggression_mult": 1.4,
	},
}


## Retorna a definicao da Nature pelo ID; caso nao exista, retorna "hardy" como fallback seguro.
static func get_nature(id: String) -> Dictionary:
	return NATURES.get(id.to_lower(), NATURES["hardy"])


## Lista dos IDs de todas as 8 Natures canônicas.
static func get_all_nature_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in NATURES.keys():
		ids.append(str(k))
	return ids
