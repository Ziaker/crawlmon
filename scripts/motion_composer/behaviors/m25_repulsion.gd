class_name MotionM25Repulsion
extends MotionBehavior
## M25 Repulsão (V1.2, D-323): afasta as amostras de um ponto (expansão de energia), par do M06 Convergência (que só atrai).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M25"
	display_name = "Repulsão"
	description = "Afasta elementos de um ponto (centro, intensidade, curva, alcance)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_vec3(&"center", Vector3(0, 0, 0.5), -20.0, 20.0, "m"),
		MotionParam.make_float(&"strength", 1.0, 0.0, 10.0, "m"),
		MotionParam.make_float(&"reach", 2.0, 0.01, 50.0, "m"),
		MotionParam.make_float(&"curve", 1.0, 0.1, 8.0, "expoente"),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var center: Vector3 = p["center"]
	var strength := float(p["strength"])
	var reach := float(p["reach"])
	var curve := float(p["curve"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var away := s.position - center
		var d := away.length()
		var w := pow(1.0 - clampf(d / reach, 0.0, 1.0), curve)
		c.position = (away / d if d > 1e-6 else Vector3.BACK) * (strength * w * tr)
		out.append(c)
	return out
