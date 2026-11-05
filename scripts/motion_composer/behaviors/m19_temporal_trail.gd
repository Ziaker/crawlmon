class_name MotionM19TemporalTrail
extends MotionBehavior
## M19 Rastro temporal — continuidade histórica: para cada elemento, amostras do próprio estado em
## instantes anteriores, igualmente espaçadas até `duration`, formando um fluxo contínuo (um ramo por
## elemento, ordenável por `age`). Largura, intensidade e opacidade variam com a idade. Operação PERSIST.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M19"
	display_name = "Rastro temporal"
	description = "Representa posições anteriores de um movimento, com idade e propriedades visuais controláveis (duração, intervalo, intensidade, tamanho, transparência, referência espacial)."
	group = &"persistencia"
	kind = MotionTypes.Kind.HISTORICAL
	needs_history = true
	accepted_operations = [Op.PERSIST]
	params = [
		MotionParam.make_float(&"duration", 0.5, 0.05, 5.0, "s"),
		MotionParam.make_float(&"sample_interval", 0.05, 0.005, 0.5, "s"),
		MotionParam.make_int(&"max_samples", 256, 1, 1024, ""),
		MotionParam.make_float(&"fade_curve", 1.0, 0.1, 8.0, "expoente"),
		MotionParam.make_float(&"width_start", 1.0, 0.0, 4.0, ""),
		MotionParam.make_float(&"width_end", 0.0, 0.0, 4.0, ""),
		MotionParam.make_float(&"intensity_end", 1.0, 0.0, 4.0, ""),
		MotionParam.make_bool(&"world_space", false),
	]


static func sample_count(p: Dictionary) -> int:
	return clampi(roundi(float(p["duration"]) / float(p["sample_interval"])), 1, int(p["max_samples"]))


func output_count(n_in: int, p: Dictionary) -> int:
	return n_in * sample_count(p)


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, _lt: float, lid: StringName) -> Array[MotionSample]:
	var n := sample_count(p)
	var dur := float(p["duration"])
	var dt := dur / float(n)
	var curve := float(p["fade_curve"])
	var w0 := float(p["width_start"])
	var w1 := float(p["width_end"])
	var i1 := float(p["intensity_end"])
	var world := bool(p["world_space"])
	var streams := {}
	var rels := {}
	for j in range(1, n + 1):
		var tp := ctx.time - dt * float(j)
		streams[j] = MotionHistory.stream_at(ctx, tp)
		rels[j] = MotionHistory.relative(ctx, tp, world)
	var out: Array[MotionSample] = []
	for s in samples:
		for j in range(1, n + 1):
			var age := dt * float(j)
			var hs: MotionSample = (streams[j] as Dictionary).get(s.element_id)
			var c: MotionSample
			if hs == null:
				c = MotionHistory.hidden_copy(s)
			else:
				c = MotionHistory.place(hs, rels[j], world)
				var f := age / dur
				c.width = hs.width * lerpf(w0, w1, f)
				c.intensity = hs.intensity * lerpf(1.0, i1, f)
				c.opacity = hs.opacity * pow(maxf(0.0, 1.0 - f), curve)
			c.element_id = MotionSample.derive_id(s.element_id, lid, j, ctx.seed)
			c.branch = MotionSample.branch_path(s.branch, lid, 0)
			c.age = age
			out.append(c)
	return out
