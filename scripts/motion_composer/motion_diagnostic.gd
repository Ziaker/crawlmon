class_name MotionDiagnostic
extends RefCounted
## Mensagem de validação/avaliação. Operações incompatíveis geram diagnóstico, nunca conversão silenciosa (§5.2).

var severity: int = MotionTypes.Severity.ERROR
var code: StringName = &""
var message: String = ""
var layer_id: StringName = &""


static func error(p_code: StringName, p_message: String, p_layer_id: StringName = &"") -> MotionDiagnostic:
	var d := MotionDiagnostic.new()
	d.severity = MotionTypes.Severity.ERROR
	d.code = p_code
	d.message = p_message
	d.layer_id = p_layer_id
	return d


static func warning(p_code: StringName, p_message: String, p_layer_id: StringName = &"") -> MotionDiagnostic:
	var d := error(p_code, p_message, p_layer_id)
	d.severity = MotionTypes.Severity.WARNING
	return d


func is_error() -> bool:
	return severity == MotionTypes.Severity.ERROR


func _to_string() -> String:
	return "[%s] %s%s" % [code, ("(%s) " % layer_id) if layer_id != &"" else "", message]
