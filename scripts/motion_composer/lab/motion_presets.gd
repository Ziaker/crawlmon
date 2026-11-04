class_name MotionPresets
extends RefCounted
## Presets do laboratório (D-045, §10.5, §19.6): JSON UTF-8 versionado numa pasta fixa. Nunca executa
## código: só dados. Todo o arquivo é validado antes de substituir a composição aberta; erro = nada muda.
## Pasta e formato são propostas do agente (§19.6), não decisões do criador.

const DIR := "user://motion_composer/presets"
const FORMAT := "crawlmon.motion_composer.preset"
const VERSION := 1
const NAME_MAX := 64

## Só para testes: substitui a pasta fixa.
static var dir_override: String = ""


static func dir() -> String:
	return DIR if dir_override == "" else dir_override


# ------------------------------------------------------------------ serialização
static func to_dict(c: MotionComposition, catalog: MotionCatalog) -> Dictionary:
	var layers: Array = []
	for l in c.layers:
		var b := catalog.get_behavior(l.behavior_id)
		var params := {}
		for k in l.params.keys():
			params[String(k)] = _encode(l.params[k])
		layers.append({
			"id": String(l.id),
			"behavior": String(l.behavior_id),
			"behavior_version": b.version if b != null else 0,
			"enabled": l.enabled,
			"op": MotionTypes.Op.keys()[l.op],
			"space": MotionTypes.Space.keys()[l.space],
			"branches": Array(l.branches),
			"intensity": l.intensity,
			"time_offset": l.time_offset,
			"active_from": l.active_from,
			"active_to": l.active_to,
			"params": params,
			"mask": {
				"u_from": l.mask.u_from, "u_to": l.mask.u_to, "feather": l.mask.feather, "invert": l.mask.invert,
				"time_enabled": l.mask.time_enabled, "t_from": l.mask.t_from, "t_to": l.mask.t_to,
				"t_feather": l.mask.t_feather, "elements": Array(l.mask.elements),
			},
		})
	return {
		"format": FORMAT,
		"version": VERSION,
		"composition": {
			"id": String(c.id), "base_length": c.base_length, "sample_count": c.sample_count,
			"duration": c.duration, "seed": c.seed, "max_samples": c.max_samples, "history_start": c.history_start,
		},
		"layers": layers,
	}


static func to_json(c: MotionComposition, catalog: MotionCatalog) -> String:
	return JSON.stringify(to_dict(c, catalog), "\t", true, true)


static func _encode(v: Variant) -> Variant:
	if typeof(v) == TYPE_VECTOR3:
		var vv: Vector3 = v
		return {"x": vv.x, "y": vv.y, "z": vv.z}
	return v


## Resultado: {"composition": MotionComposition | null, "diagnostics": Array[MotionDiagnostic]}.
static func from_json(text: String, catalog: MotionCatalog) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return _fail("preset_parse", "JSON inválido (linha %d): %s" % [json.get_error_line(), json.get_error_message()])
	if typeof(json.data) != TYPE_DICTIONARY:
		return _fail("preset_format", "a raiz do preset deve ser um objeto")
	return from_dict(json.data, catalog)


static func from_dict(d: Dictionary, catalog: MotionCatalog) -> Dictionary:
	var diags: Array[MotionDiagnostic] = []
	if d.get("format") != FORMAT:
		return _fail("preset_format", "formato desconhecido (esperado '%s')" % FORMAT)
	if typeof(d.get("version")) not in [TYPE_FLOAT, TYPE_INT] or int(d["version"]) != VERSION:
		return _fail("preset_version", "versão do preset não suportada: %s (suportada: %d)" % [d.get("version"), VERSION])
	var cd: Variant = d.get("composition")
	var ld: Variant = d.get("layers")
	if typeof(cd) != TYPE_DICTIONARY or typeof(ld) != TYPE_ARRAY:
		return _fail("preset_format", "faltam 'composition' ou 'layers'")

	var c := MotionComposition.new()
	c.id = StringName(str(cd.get("id", "")))
	c.base_length = _num(cd, "base_length", c.base_length, diags)
	c.sample_count = _int(cd, "sample_count", c.sample_count, diags)
	c.duration = _num(cd, "duration", c.duration, diags)
	c.seed = _int(cd, "seed", c.seed, diags)
	c.max_samples = _int(cd, "max_samples", c.max_samples, diags)
	c.history_start = _num(cd, "history_start", c.history_start, diags)

	for entry in ld:
		if typeof(entry) != TYPE_DICTIONARY:
			diags.append(MotionDiagnostic.error(&"preset_layer", "camada inválida (não é um objeto)"))
			continue
		var l := _decode_layer(entry, catalog, diags)
		if l != null:
			if not c.add_layer(l):
				diags.append(MotionDiagnostic.error(&"layer_id_duplicate", "id de camada duplicado: %s" % l.id, l.id))
	for diag in c.validate(catalog):
		diags.append(diag)
	for diag in diags:
		if diag.is_error():
			return {"composition": null, "diagnostics": diags}
	c.revision = 0
	return {"composition": c, "diagnostics": diags}


static func _decode_layer(e: Dictionary, catalog: MotionCatalog, diags: Array[MotionDiagnostic]) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = StringName(str(e.get("id", "")))
	l.behavior_id = StringName(str(e.get("behavior", "")))
	var b := catalog.get_behavior(l.behavior_id)
	if b == null:
		diags.append(MotionDiagnostic.error(&"preset_behavior", "comportamento ausente no catálogo: '%s'" % l.behavior_id, l.id))
		return null
	if int(e.get("behavior_version", b.version)) != b.version:
		diags.append(MotionDiagnostic.error(&"preset_behavior_version",
			"%s: preset usa a versão %s, o catálogo tem %d (migração necessária)" % [b.id, e.get("behavior_version"), b.version], l.id))
	l.enabled = bool(e.get("enabled", true))
	var opn := str(e.get("op", ""))
	if not MotionTypes.Op.has(opn):
		diags.append(MotionDiagnostic.error(&"preset_op", "operação desconhecida: '%s'" % opn, l.id))
	else:
		l.op = MotionTypes.Op[opn]
	var spn := str(e.get("space", "LOCAL"))
	if not MotionTypes.Space.has(spn):
		diags.append(MotionDiagnostic.error(&"preset_space", "espaço desconhecido: '%s'" % spn, l.id))
	else:
		l.space = MotionTypes.Space[spn]
	var br := PackedStringArray()
	for x in e.get("branches", []):
		br.append(str(x))
	l.branches = br
	l.intensity = _num(e, "intensity", l.intensity, diags)
	l.time_offset = _num(e, "time_offset", l.time_offset, diags)
	l.active_from = _num(e, "active_from", l.active_from, diags)
	l.active_to = _num(e, "active_to", l.active_to, diags)
	var pd: Variant = e.get("params", {})
	if typeof(pd) != TYPE_DICTIONARY:
		diags.append(MotionDiagnostic.error(&"preset_params", "'params' deve ser um objeto", l.id))
	else:
		for k in pd.keys():
			var p := b.find_param(str(k))
			if p == null:
				diags.append(MotionDiagnostic.error(&"param_unknown", "parâmetro desconhecido '%s' em %s" % [k, b.id], l.id))
				continue
			var v: Variant = _decode_param(p, pd[k])
			if v == null:
				diags.append(MotionDiagnostic.error(&"preset_param_type", "valor inválido para '%s': %s" % [k, pd[k]], l.id))
			else:
				l.params[str(k)] = v
	var md: Variant = e.get("mask", {})
	if typeof(md) == TYPE_DICTIONARY:
		l.mask.u_from = _num(md, "u_from", l.mask.u_from, diags)
		l.mask.u_to = _num(md, "u_to", l.mask.u_to, diags)
		l.mask.feather = _num(md, "feather", l.mask.feather, diags)
		l.mask.invert = bool(md.get("invert", false))
		l.mask.time_enabled = bool(md.get("time_enabled", false))
		l.mask.t_from = _num(md, "t_from", l.mask.t_from, diags)
		l.mask.t_to = _num(md, "t_to", l.mask.t_to, diags)
		l.mask.t_feather = _num(md, "t_feather", l.mask.t_feather, diags)
		var els := PackedInt64Array()
		for x in md.get("elements", []):
			els.append(int(x))
		l.mask.elements = els
	return l


## null = inválido. Restaura o tipo pelo descritor do parâmetro (JSON só tem float).
static func _decode_param(p: MotionParam, v: Variant) -> Variant:
	match p.kind:
		MotionParam.Kind.FLOAT:
			if typeof(v) in [TYPE_FLOAT, TYPE_INT]:
				return float(v)
		MotionParam.Kind.INT:
			if typeof(v) in [TYPE_FLOAT, TYPE_INT] and is_equal_approx(float(v), roundf(float(v))):
				return int(v)
		MotionParam.Kind.BOOL:
			if typeof(v) == TYPE_BOOL:
				return v
		MotionParam.Kind.VECTOR3:
			if typeof(v) == TYPE_DICTIONARY and v.has("x") and v.has("y") and v.has("z"):
				return Vector3(float(v["x"]), float(v["y"]), float(v["z"]))
	return null


static func _num(d: Dictionary, k: String, fallback: float, diags: Array[MotionDiagnostic]) -> float:
	if not d.has(k):
		return fallback
	if typeof(d[k]) not in [TYPE_FLOAT, TYPE_INT]:
		diags.append(MotionDiagnostic.error(&"preset_field", "'%s' deve ser número" % k))
		return fallback
	return float(d[k])


static func _int(d: Dictionary, k: String, fallback: int, diags: Array[MotionDiagnostic]) -> int:
	if not d.has(k):
		return fallback
	if typeof(d[k]) not in [TYPE_FLOAT, TYPE_INT] or not is_equal_approx(float(d[k]), roundf(float(d[k]))):
		diags.append(MotionDiagnostic.error(&"preset_field", "'%s' deve ser inteiro" % k))
		return fallback
	return int(d[k])


static func _fail(code: String, msg: String) -> Dictionary:
	var diags: Array[MotionDiagnostic] = [MotionDiagnostic.error(StringName(code), msg)]
	return {"composition": null, "diagnostics": diags}


# ------------------------------------------------------------------ pasta fixa
## Só letras, números, '_' e '-', até 64 caracteres: nada sai da pasta fixa.
static func valid_name(n: String) -> bool:
	if n.is_empty() or n.length() > NAME_MAX:
		return false
	for ch in n:
		var ok_ch := (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == "_" or ch == "-"
		if not ok_ch:
			return false
	return true


static func path_for(n: String) -> String:
	return dir().path_join(n + ".json")


## Grava por arquivo temporário e renomeia só após sucesso. Devolve diagnósticos (vazio = ok).
static func save(n: String, c: MotionComposition, catalog: MotionCatalog) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	if not valid_name(n):
		out.append(MotionDiagnostic.error(&"preset_name", "nome inválido: use letras, números, '_' e '-' (até %d)" % NAME_MAX))
		return out
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir()))
	if err != OK:
		out.append(MotionDiagnostic.error(&"preset_io", "não foi possível criar a pasta (%s)" % error_string(err)))
		return out
	var tmp := path_for(n) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		out.append(MotionDiagnostic.error(&"preset_io", "não foi possível escrever (%s)" % error_string(FileAccess.get_open_error())))
		return out
	var okw := f.store_string(to_json(c, catalog))
	f.close()
	if not okw:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		out.append(MotionDiagnostic.error(&"preset_io", "falha ao gravar o arquivo temporário"))
		return out
	var dest := ProjectSettings.globalize_path(path_for(n))
	if FileAccess.file_exists(path_for(n)):
		DirAccess.remove_absolute(dest)
	err = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), dest)
	if err != OK:
		out.append(MotionDiagnostic.error(&"preset_io", "falha ao concluir a gravação (%s)" % error_string(err)))
	return out


static func load_preset(n: String, catalog: MotionCatalog) -> Dictionary:
	if not valid_name(n):
		return _fail("preset_name", "nome inválido")
	var p := path_for(n)
	if not FileAccess.file_exists(p):
		return _fail("preset_io", "preset não encontrado: %s" % n)
	return from_json(FileAccess.get_file_as_string(p), catalog)


static func list_names() -> PackedStringArray:
	var out := PackedStringArray()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir())):
		return out
	for f in DirAccess.get_files_at(dir()):
		if f.ends_with(".json") and valid_name(f.get_basename()):
			out.append(f.get_basename())
	out.sort()
	return out
