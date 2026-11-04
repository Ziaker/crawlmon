class_name MotionM05Vortex
extends MotionBehavior
## M05 Vórtice — campo analítico de circulação em torno de um eixo (OFFSET). Sem integração numérica.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M05"
	display_name = "Vórtice"
	description = "Induz circulação ao redor de um eixo ou núcleo (centro, intensidade angular, raio de influência, decaimento)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_vec3(&"center", Vector3(0, 0, 0.5), -20.0, 20.0, "m"),
		MotionParam.make_vec3(&"axis", Vector3(0, 0, 1), -1.0, 1.0, ""),
		MotionParam.make_float(&"angular_deg", 90.0, -720.0, 720.0, "deg"),
		MotionParam.make_float(&"angular_speed_deg_s", 0.0, -3600.0, 3600.0, "deg/s"),
		MotionParam.make_float(&"radius", 1.0, 0.01, 20.0, "m"),
		MotionParam.make_float(&"falloff", 2.0, 0.1, 8.0, "expoente"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var center: Vector3 = p["center"]
	var axis := MotionProfile.safe_axis(p["axis"])
	var radius := float(p["radius"])
	var falloff := float(p["falloff"])
	var angle := deg_to_rad(float(p["angular_deg"]) + float(p["angular_speed_deg_s"]) * lt)
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var v := s.position - center
		var perp := v - axis * v.dot(axis)
		var d := perp.length()
		var w := pow(1.0 - clampf(d / radius, 0.0, 1.0), falloff)
		var a := angle * w
		if w > 0.0 and a != 0.0 and d > 0.0:
			c.position = perp.rotated(axis, a) - perp
		else:
			c.position = Vector3.ZERO
		out.append(c)
	return out
