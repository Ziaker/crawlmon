class_name MotionM10Stretch
extends MotionBehavior
## M10 Alongamento — a região [centro ± extensão/2] ganha comprimento (fator ≥ 1) e o restante
## do eixo é empurrado (DEFORM). Monotônico: nunca dobra a trajetória.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M10"
	display_name = "Alongamento"
	description = "Aumenta a extensão de regiões determinadas, com distribuição espacial configurável."
	group = &"deformacoes"
	kind = MotionTypes.Kind.MODIFIER
	accepted_operations = [Op.DEFORM, Op.REPLACE]
	params = [
		MotionParam.make_float(&"factor", 2.0, 1.0, 10.0, ""),
		MotionParam.make_float(&"center", 0.5, 0.0, 1.0, "u"),
		MotionParam.make_float(&"extent", 0.5, 0.0, 1.0, "u"),
		MotionParam.make_float(&"reference_length", 1.0, 0.01, 100.0, "m"),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var center := float(p["center"])
	var extent := float(p["extent"])
	var gain := (float(p["factor"]) - 1.0) * tr * extent * float(p["reference_length"])
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		if gain != 0.0:
			c.position.z = s.position.z + gain * MotionProfile.ramp(s.u, center, extent)
		out.append(c)
	return out
