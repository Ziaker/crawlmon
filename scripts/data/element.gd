class_name Element
extends RefCounted
## Elements used by skills and weaknesses.

enum Type { FISICO, FOGO, AGUA_GELO, RAIO, PSIQUICO, VENENO, SOM, TERRA, VENTO, LUZ, TREVAS }

const NAMES := {
	Type.FISICO: "Físico",
	Type.FOGO: "Fogo",
	Type.AGUA_GELO: "Água/Gelo",
	Type.RAIO: "Raio",
	Type.PSIQUICO: "Psíquico",
	Type.VENENO: "Veneno",
	Type.SOM: "Som",
	Type.TERRA: "Terra",
	Type.VENTO: "Vento",
	Type.LUZ: "Luz",
	Type.TREVAS: "Trevas",
}


static func name_of(type: Type) -> String:
	return NAMES[type]
