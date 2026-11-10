class_name CharacterData
extends Resource
## Ficha canônica de um personagem (D-1079/D-1080).
##
## Guarda apenas definição: stats brutos, fraquezas, leque base de Moves,
## inventário inicial, traços de IA e perfil de modelo. Valores de uma party de
## teste não entram aqui; eles são overrides explícitos da própria party.

@export var id: StringName = &""
@export var display_name: String = ""
@export var species_id: String = ""

# Parâmetros iniciais do Combatant. O HP/MP final continua sendo recalculado
# pelas fórmulas D-391/D-392; estes valores são a base antes do recálculo.
@export var hp: int = 39
@export var attack: int = 9
@export var speed: float = 0.425

@export var raw_stats: Dictionary = {}
@export var weaknesses: Array[int] = []
@export var nature_id: String = ""
@export var loadout: CharacterLoadout = null
@export var travel_extra: float = 0.0
@export var act_policy: int = 0
@export var react_policy: int = 0
@export var base_experience: int = 30
@export var model_profile: CharacterModelProfile = null


func has_skill(move_id: StringName) -> bool:
	return loadout != null and move_id in loadout.skills


func skill_ids() -> Array[StringName]:
	if loadout == null:
		var empty: Array[StringName] = []
		return empty
	# The loaded Resource is shared and read-only (D-1079); return a copy.
	return loadout.skills.duplicate()


func inventory() -> Dictionary:
	return loadout.inventory.duplicate(true) if loadout != null else {}


func model_profile_dict() -> Dictionary:
	return model_profile.profile.duplicate(true) if model_profile != null else {}
