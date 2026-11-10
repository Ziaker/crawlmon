extends RefCounted
## Resolve o ícone opcional de um Move (D-1079, Fase 3).
## O caminho é fixo por `move_id`; não há varredura de pasta em runtime.
## Sem `icon.svg`, devolve null e a UI mantém o ícone de tipo/alcance atual.

static var _cache: Dictionary = {}


static func for_move(move_id: StringName) -> Texture2D:
	var key := StringName(move_id)
	if _cache.has(key):
		return _cache[key]
	var path := "res://content/moves/%s/icon.svg" % key
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[key] = tex
	return tex


static func clear_cache() -> void:
	_cache.clear()
