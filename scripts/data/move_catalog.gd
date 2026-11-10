class_name MoveCatalog
extends Resource
## Catálogo explícito de Moves (D-1079). Gerado em tempo de edição e carregado
## por caminho fixo; não faz varredura de pasta em runtime.

const DEFAULT_PATH := "res://content/catalogs/move_catalog.tres"

@export var moves: Array[MoveData] = []

static var _cached: MoveCatalog = null


static func load_default() -> MoveCatalog:
	if _cached == null and ResourceLoader.exists(DEFAULT_PATH):
		_cached = load(DEFAULT_PATH) as MoveCatalog
	return _cached


static func get_move(move_id: StringName) -> MoveData:
	var catalog := load_default()
	return catalog.find_move(move_id) if catalog != null else null


static func all_moves() -> Array[MoveData]:
	var catalog := load_default()
	if catalog == null:
		var empty: Array[MoveData] = []
		return empty
	# Definitions are shared and read-only (D-1079); callers get a copy so they
	# cannot mutate the catalog through the returned array.
	return catalog.moves.duplicate()


func find_move(move_id: StringName) -> MoveData:
	for move in moves:
		if move != null and move.id == move_id:
			return move
	return null


func has_move(move_id: StringName) -> bool:
	return find_move(move_id) != null
