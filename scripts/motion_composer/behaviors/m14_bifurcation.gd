class_name MotionM14Bifurcation
extends MotionBehavior
## M14 Bifurcação — separa o fluxo em N ramos identificáveis (BRANCH). Cada ramo recebe caminho
## "pai/camada.índice" e id derivado (estáveis). Afastamento lateral a partir de `split_u`:
## distância·tanh(tan(ângulo)·Δz/distância)·intensidade, distribuído a 360°/N a partir de `phase_deg`.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M14"
	display_name = "Bifurcação"
	description = "Separa um fluxo de origem em múltiplos percursos identificáveis (ramos, ponto de separação, ângulo, distância, intensidade, duração)."
	group = &"composicao_espacial"
	kind = MotionTypes.Kind.TOPOLOGY
	accepted_operations = [Op.BRANCH]
	params = [
		MotionParam.make_int(&"branches", 3, 1, 16, ""),
		MotionParam.make_float(&"split_u", 0.4, 0.0, 1.0, "u"),
		MotionParam.make_float(&"angle_deg", 30.0, 0.0, 89.0, "deg"),
		MotionParam.make_float(&"distance", 0.5, 0.001, 20.0, "m"),
		MotionParam.make_float(&"intensity", 1.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"phase_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_float(&"reference_length", 1.0, 0.01, 100.0, "m"),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


func output_count(n_in: int, p: Dictionary) -> int:
	return n_in * int(p["branches"])


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, lid: StringName) -> Array[MotionSample]:
	var n := int(p["branches"])
	var split := float(p["split_u"])
	var slope := tan(deg_to_rad(float(p["angle_deg"])))
	var dist := float(p["distance"])
	var inten := float(p["intensity"])
	var phase := deg_to_rad(float(p["phase_deg"]))
	var length := float(p["reference_length"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var lateral := dist * tanh(slope * maxf(0.0, s.u - split) * length / dist) * inten * tr
		for i in n:
			var c := s.duplicate_sample()
			c.branch = MotionSample.branch_path(s.branch, lid, i)
			c.element_id = MotionSample.derive_id(s.element_id, lid, i, ctx.seed)
			if lateral != 0.0:
				var a := phase + TAU * float(i) / float(n)
				c.position = s.position + Vector3(cos(a), sin(a), 0.0) * lateral
			out.append(c)
	return out
