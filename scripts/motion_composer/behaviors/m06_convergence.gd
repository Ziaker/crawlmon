class_name MotionM06Convergence
extends MotionBehavior
## M06 Convergência — campo analítico que aproxima as amostras de um ponto-alvo (OFFSET).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M06"
	display_name = "Convergência"
	description = "Aproxima elementos de uma posição de destino (ponto-alvo, intensidade de atração, curva de aproximação, alcance)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_vec3(&"target", Vector3(0, 0, 0.5), -20.0, 20.0, "m"),
		MotionParam.make_float(&"strength", 1.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"reach", 2.0, 0.01, 50.0, "m"),
		MotionParam.make_float(&"curve", 1.0, 0.1, 8.0, "expoente"),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var target: Vector3 = p["target"]
	var strength := float(p["strength"])
	var reach := float(p["reach"])
	var curve := float(p["curve"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var to_target := target - s.position
		var w := pow(1.0 - clampf(to_target.length() / reach, 0.0, 1.0), curve)
		c.position = to_target * (strength * w * tr)
		out.append(c)
	return out
