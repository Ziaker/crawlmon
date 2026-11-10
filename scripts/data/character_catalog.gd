class_name CharacterCatalog
extends Resource
## Catálogo explícito de personagens (D-1079). Carregado por caminho fixo.

const DEFAULT_PATH := "res://content/catalogs/character_catalog.tres"

@export var characters: Array[CharacterData] = []

static var _cached: CharacterCatalog = null


static func load_default() -> CharacterCatalog:
	if _cached == null and ResourceLoader.exists(DEFAULT_PATH):
		_cached = load(DEFAULT_PATH) as CharacterCatalog
	return _cached


static func get_character(character_id: StringName) -> CharacterData:
	var catalog := load_default()
	return catalog.find_character(character_id) if catalog != null else null


static func all_characters() -> Array[CharacterData]:
	var catalog := load_default()
	if catalog == null:
		var empty: Array[CharacterData] = []
		return empty
	# Definitions are shared and read-only (D-1079); callers get a copy so they
	# cannot mutate the catalog through the returned array.
	return catalog.characters.duplicate()


func find_character(character_id: StringName) -> CharacterData:
	for character in characters:
		if character != null and character.id == character_id:
			return character
	return null


func has_character(character_id: StringName) -> bool:
	return find_character(character_id) != null
