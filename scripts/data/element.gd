class_name Element
extends RefCounted
## Elements used by skills and weaknesses.

enum Type { FISICO, FOGO, AGUA_GELO, RAIO, PSIQUICO, VENENO, SOM, TERRA, VENTO, LUZ, TREVAS, MYSTIC }

const NAMES := {
	Type.FISICO: "Neutral",  # D-397/D-440: Neutral replaces Physical (internal id FISICO kept: .tres data uses it)
	Type.FOGO: "Fire",
	Type.AGUA_GELO: "Water",  # D-397: Water only (Ice does not exist)
	Type.RAIO: "Electric",
	Type.PSIQUICO: "Psychic",
	Type.VENENO: "Nature",  # D-396: Nature replaces Poison (internal id VENENO kept)
	Type.SOM: "Sound",
	Type.TERRA: "Earth",
	Type.VENTO: "Wind",
	Type.LUZ: "Light",
	Type.TREVAS: "Dark",
	Type.MYSTIC: "Mystic",
}


static func name_of(type: Type) -> String:
	return NAMES[type]
