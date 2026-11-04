class_name MotionM08Twist
extends MotionBehavior
## M08 Torção progressiva — gira (x, y) em torno de +Z com ângulo variável ao longo de `u`,
## com início/duração temporais e frente de propagação opcional (DEFORM).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M08"
	display_name = "Torção progressiva"
	description = "Aplica rotação variável ao longo do comprimento, com propagação temporal da torção."
	group = &"deformacoes"
	kind = MotionTypes.Kind.MODIFIER
	accepted_operations = [Op.DEFORM, Op.REPLACE]
	params = [MotionParam.make_float(&"amount_deg", 90.0, -1440.0, 1440.0, "deg")]
	params.append_array(MotionProfile.region_params())
	params.append(MotionParam.make_float(&"front_speed", 0.0, 0.0, 50.0, "u/s"))
	params.append(MotionParam.make_float(&"front_width", 0.1, 0.001, 1.0, "u"))


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var amount := deg_to_rad(float(p["amount_deg"]))
	var center := float(p["center"])
	var extent := float(p["extent"])
	var soft := float(p["softness"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var speed := float(p["front_speed"])
	var fw := float(p["front_width"])
	var front := speed * lt
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var w := MotionProfile.window(s.u, center, extent, soft) * tr
		if speed > 0.0:
			w *= 1.0 - smoothstep(front - fw, front, s.u)
		var a := amount * w
		if a != 0.0:
			var cs := cos(a)
			var sn := sin(a)
			c.position = Vector3(s.position.x * cs - s.position.y * sn, s.position.x * sn + s.position.y * cs, s.position.z)
			c.basis = Basis(Vector3.BACK, a) * s.basis
		out.append(c)
	return out
