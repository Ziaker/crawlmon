class_name MotionM20Afterimage
extends MotionBehavior
## M20 Pós-imagem — estados visuais discretos em instantes anteriores (`count` cópias a cada `interval`),
## cada uma um ramo identificável, com desaparecimento em degraus e escala própria. Operação PERSIST.
## Diferença obrigatória de M19: estados discretos (ramos separados, atributos do estado preservados),
## não um fluxo contínuo que afina com a idade.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M20"
	display_name = "Pós-imagem"
	description = "Representa estados visuais anteriores em instantes discretos, com defasagem temporal e desaparecimento progressivo (quantidade, intervalo, intensidade, tamanho, transparência, referência espacial)."
	group = &"persistencia"
	kind = MotionTypes.Kind.HISTORICAL
	needs_history = true
	accepted_operations = [Op.PERSIST]
	params = [
		MotionParam.make_int(&"count", 4, 1, 16, ""),
		MotionParam.make_float(&"interval", 0.1, 0.01, 2.0, "s"),
		MotionParam.make_float(&"fade", 0.8, 0.0, 1.0, ""),
		MotionParam.make_float(&"intensity_fade", 0.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"scale", 1.0, 0.1, 2.0, ""),
		MotionParam.make_bool(&"world_space", false),
	]


func output_count(n_in: int, p: Dictionary) -> int:
	return n_in * int(p["count"])


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, _lt: float, lid: StringName) -> Array[MotionSample]:
	var n := int(p["count"])
	var interval := float(p["interval"])
	var fade := float(p["fade"])
	var ifade := float(p["intensity_fade"])
	var scl := float(p["scale"])
	var world := bool(p["world_space"])
	var streams := {}
	var rels := {}
	for k in range(1, n + 1):
		var tp := ctx.time - interval * float(k)
		streams[k] = MotionHistory.stream_at(ctx, tp)
		rels[k] = MotionHistory.relative(ctx, tp, world)
	var out: Array[MotionSample] = []
	for s in samples:
		for k in range(1, n + 1):
			var age := interval * float(k)
			var hs: MotionSample = (streams[k] as Dictionary).get(s.element_id)
			var c: MotionSample
			if hs == null:
				c = MotionHistory.hidden_copy(s)
			else:
				c = MotionHistory.place(hs, rels[k], world)
				var step := float(k) / float(n + 1)
				c.width = hs.width * pow(scl, float(k))
				c.intensity = hs.intensity * (1.0 - ifade * step)
				c.opacity = hs.opacity * (1.0 - fade * step)
			c.element_id = MotionSample.derive_id(s.element_id, lid, k, ctx.seed)
			c.branch = MotionSample.branch_path(s.branch, lid, k - 1)
			c.age = age
			out.append(c)
	return out
