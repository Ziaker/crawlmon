class_name MotionCatalog
extends RefCounted
## Registro de comportamentos (§15). A V1 é o conjunto fechado M01–M20 (D-046); a Etapa 2 os registra.

const V1_IDS: Array[StringName] = [
	&"M01", &"M02", &"M03", &"M04", &"M05", &"M06", &"M07", &"M08", &"M09", &"M10",
	&"M11", &"M12", &"M13", &"M14", &"M15", &"M16", &"M17", &"M18", &"M19", &"M20",
]

var _behaviors: Dictionary = {}


## Devolve diagnósticos; vazio = registrado.
func register(b: MotionBehavior) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	if b.id == &"":
		out.append(MotionDiagnostic.error(&"cat_empty_id", "comportamento sem id"))
	elif _behaviors.has(b.id):
		out.append(MotionDiagnostic.error(&"cat_duplicate", "id já registrado: %s" % b.id))
	if b.accepted_operations.is_empty():
		out.append(MotionDiagnostic.error(&"cat_no_ops", "comportamento %s não declara operações aceitas" % b.id))
	if out.is_empty():
		_behaviors[b.id] = b
	return out


func has(id: StringName) -> bool:
	return _behaviors.has(id)


func get_behavior(id: StringName) -> MotionBehavior:
	return _behaviors.get(id) as MotionBehavior


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in _behaviors.keys():
		out.append(k)
	return out


func missing_v1() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in V1_IDS:
		if not _behaviors.has(id):
			out.append(id)
	return out
