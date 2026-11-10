class_name Element
extends RefCounted
## Elements used by skills and weaknesses.

enum Type { FISICO, FOGO, AGUA_GELO, RAIO, PSIQUICO, VENENO, SOM, TERRA, VENTO, LUZ, TREVAS, MYSTIC }

const NAMES := {
	Type.FISICO: "Physical",
	Type.FOGO: "Fire",
	Type.AGUA_GELO: "Water/Ice",
	Type.RAIO: "Electric",
	Type.PSIQUICO: "Psychic",
	Type.VENENO: "Poison",
	Type.SOM: "Sound",
	Type.TERRA: "Earth",
	Type.VENTO: "Wind",
	Type.LUZ: "Light",
	Type.TREVAS: "Dark",
	Type.MYSTIC: "Mystic",
}


static func name_of(type: Type) -> String:
	return NAMES[type]
