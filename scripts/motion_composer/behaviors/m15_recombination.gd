class_name MotionM15Recombination
extends MotionBehavior
## M15 Recombinação — aproxima os ramos selecionados do centroide comum (MERGE), mantendo as identidades
## (ids e caminhos). Amostras com a mesma (u, rest) formam um grupo; o peso é smoothstep(merge_start, merge_end, u).
## A intensidade/largura são divididas entre os ramos do grupo (soma preservada com redução 1).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M15"
	display_name = "Recombinação"
	description = "Conduz fluxos distintos a uma região comum, produzindo convergência espacial e eventual unificação visual."
	group = &"composicao_espacial"
	kind = MotionTypes.Kind.TOPOLOGY
	accepted_operations = [Op.MERGE]
	params = [
		MotionParam.make_float(&"merge_start", 0.6, 0.0, 1.0, "u"),
		MotionParam.make_float(&"merge_end", 0.9, 0.0, 1.0, "u"),
		MotionParam.make_float(&"strength", 1.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"intensity_reduction", 1.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"width_reduction", 0.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var a := minf(float(p["merge_start"]), float(p["merge_end"]))
	var b := maxf(float(p["merge_start"]), float(p["merge_end"]))
	var strength := float(p["strength"])
	var ired := float(p["intensity_reduction"])
	var wred := float(p["width_reduction"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var sums := {}
	var counts := {}
	for s in samples:
		var key := Vector3(s.u, s.rest.x, s.rest.y)
		sums[key] = (sums.get(key, Vector3.ZERO) as Vector3) + s.position
		counts[key] = int(counts.get(key, 0)) + 1
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var key := Vector3(s.u, s.rest.x, s.rest.y)
		var n := int(counts[key])
		var w := (smoothstep(a, b, s.u) if b > a else (1.0 if s.u >= a else 0.0)) * strength * tr
		if w > 0.0 and n > 1:
			c.position = s.position.lerp((sums[key] as Vector3) / float(n), w)
			var share := 1.0 - w * (1.0 - 1.0 / float(n))
			c.intensity = s.intensity * (1.0 - ired * (1.0 - share))
			c.width = s.width * (1.0 - wred * (1.0 - share))
		out.append(c)
	return out
