class_name MotionParam
extends RefCounted
## Descritor de parâmetro editável: nome, tipo, unidade e domínio válido (§4.1).
## Ângulos são expressos em graus na API e convertidos dentro do avaliador (§19.2).

enum Kind { FLOAT, INT, BOOL, VECTOR3 }

var name: StringName = &""
var kind: int = Kind.FLOAT
var unit: String = ""
var min_value: float = -INF
var max_value: float = INF
var default_value: Variant = 0.0


static func make_float(p_name: StringName, p_default: float, p_min: float, p_max: float, p_unit: String = "") -> MotionParam:
	return _make(p_name, Kind.FLOAT, p_default, p_min, p_max, p_unit)


static func make_int(p_name: StringName, p_default: int, p_min: int, p_max: int, p_unit: String = "") -> MotionParam:
	return _make(p_name, Kind.INT, p_default, float(p_min), float(p_max), p_unit)


static func make_bool(p_name: StringName, p_default: bool) -> MotionParam:
	return _make(p_name, Kind.BOOL, p_default, 0.0, 1.0, "")


static func make_vec3(p_name: StringName, p_default: Vector3, p_min: float, p_max: float, p_unit: String = "") -> MotionParam:
	return _make(p_name, Kind.VECTOR3, p_default, p_min, p_max, p_unit)


static func _make(p_name: StringName, p_kind: int, p_default: Variant, p_min: float, p_max: float, p_unit: String) -> MotionParam:
	var p := MotionParam.new()
	p.name = p_name
	p.kind = p_kind
	p.default_value = p_default
	p.min_value = p_min
	p.max_value = p_max
	p.unit = p_unit
	return p


## Retorna "" se válido; senão, o motivo.
func check(value: Variant) -> String:
	match kind:
		Kind.FLOAT:
			if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
				return "'%s' espera número" % name
			return _check_scalar(float(value))
		Kind.INT:
			if typeof(value) != TYPE_INT:
				return "'%s' espera inteiro" % name
			return _check_scalar(float(value))
		Kind.BOOL:
			if typeof(value) != TYPE_BOOL:
				return "'%s' espera booleano" % name
			return ""
		Kind.VECTOR3:
			if typeof(value) != TYPE_VECTOR3:
				return "'%s' espera Vector3" % name
			var v: Vector3 = value
			for c in [v.x, v.y, v.z]:
				var m := _check_scalar(c)
				if m != "":
					return m
			return ""
	return "tipo de parâmetro desconhecido"


func _check_scalar(x: float) -> String:
	if not is_finite(x):
		return "'%s' não é finito" % name
	if x < min_value or x > max_value:
		return "'%s' = %s fora do domínio [%s, %s]%s" % [name, x, min_value, max_value, (" " + unit) if unit != "" else ""]
	return ""
