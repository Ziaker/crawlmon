class_name MotionM22Drag
extends MotionBehavior
## M22 Arrasto (V1.2, D-323): redução gradual de velocidade. Deslocamento líquido de uma amostra lançada com `speed` e
## freada por `drag`: d(t) = v0 (1 - exp(-k t)) / k (OFFSET analítico, sem integrar quadro a quadro). Cada elemento
## recebe uma fração determinística da velocidade (`spread`) para a nuvem não andar em bloco.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M22"
	display_name = "Arrasto"
	description = "Lança as amostras e as freia gradualmente (direção, velocidade inicial, arrasto, dispersão de velocidade)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_vec3(&"direction", Vector3(0, 0, 1), -1.0, 1.0, ""),
		MotionParam.make_float(&"speed", 4.0, 0.0, 100.0, "m/s"),
		MotionParam.make_float(&"drag", 3.0, 0.01, 50.0, "1/s"),
		MotionParam.make_float(&"spread", 0.3, 0.0, 1.0, ""),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var dir := MotionProfile.safe_axis(p["direction"])
	var v0 := float(p["speed"])
	var k := float(p["drag"])
	var spread := float(p["spread"])
	var t := maxf(lt - float(p["t_start"]), 0.0)
	var travel := (1.0 - exp(-k * t)) / k
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var rnd := MotionHash.float01(ctx.seed, s.element_id & 0xFFFFFFFF, s.element_id >> 32, 22)
		c.position = dir * (v0 * (1.0 - spread * rnd) * travel)
		out.append(c)
	return out
