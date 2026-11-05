class_name MotionMask
extends RefCounted
## Máscara de influência: peso 0..1 por posição longitudinal, tempo local e identificador de elemento (§5.4).
## A seleção por ramo fica na camada (MotionLayer.branches).

var u_from: float = 0.0
var u_to: float = 1.0
## Largura do degradê (em u) que se estende para FORA da faixa [u_from, u_to]. 0 = corte seco.
var feather: float = 0.0
var invert: bool = false

var time_enabled: bool = false
var t_from: float = 0.0
var t_to: float = 0.0
var t_feather: float = 0.0

## Vazio = todos os elementos.
var elements: PackedInt64Array = PackedInt64Array()


func weight(s: MotionSample, local_time: float) -> float:
	var w := _window(s.u, u_from, u_to, feather)
	if time_enabled:
		w *= _window(local_time, t_from, t_to, t_feather)
	if invert:
		w = 1.0 - w
	if not elements.is_empty() and not (s.element_id in elements):
		w = 0.0
	return w


static func _window(x: float, a: float, b: float, f: float) -> float:
	if f <= 0.0:
		return 1.0 if (x >= a and x <= b) else 0.0
	return smoothstep(a - f, a, x) * (1.0 - smoothstep(b, b + f, x))


func validate(layer_id: StringName) -> Array[MotionDiagnostic]:
	var out: Array[MotionDiagnostic] = []
	if not (is_finite(u_from) and is_finite(u_to) and is_finite(feather)) or u_from > u_to or feather < 0.0:
		out.append(MotionDiagnostic.error(&"mask_range", "máscara espacial inválida (u_from <= u_to, feather >= 0, finitos)", layer_id))
	if time_enabled and (not (is_finite(t_from) and is_finite(t_to) and is_finite(t_feather)) or t_from > t_to or t_feather < 0.0):
		out.append(MotionDiagnostic.error(&"mask_range", "máscara temporal inválida (t_from <= t_to, feather >= 0, finitos)", layer_id))
	return out
