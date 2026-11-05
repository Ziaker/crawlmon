class_name MotionM09Bend
extends MotionBehavior
## M09 Curvatura — gira cada ponto em torno de um eixo no plano XY (pela origem) com ângulo que
## cresce suavemente ao longo da região: a trajetória reta vira um arco (DEFORM).
## Convenção: plane_deg 0 -> eixo +X (dobra para -Y); 90 -> eixo +Y (dobra para +X).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M09"
	display_name = "Curvatura"
	description = "Deforma progressivamente o eixo ou a estrutura espacial de um efeito."
	group = &"deformacoes"
	kind = MotionTypes.Kind.MODIFIER
	accepted_operations = [Op.DEFORM, Op.REPLACE]
	params = [
		MotionParam.make_float(&"amount_deg", 90.0, -720.0, 720.0, "deg"),
		MotionParam.make_float(&"plane_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_float(&"center", 0.5, 0.0, 1.0, "u"),
		MotionParam.make_float(&"extent", 1.0, 0.0, 1.0, "u"),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var amount := deg_to_rad(float(p["amount_deg"]))
	var axis := MotionProfile.lateral(float(p["plane_deg"]))
	var center := float(p["center"])
	var extent := float(p["extent"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var a := amount * MotionProfile.ramp(s.u, center, extent) * tr
		if a != 0.0:
			c.position = s.position.rotated(axis, a)
			c.basis = Basis(axis, a) * s.basis
		out.append(c)
	return out
