class_name MotionM23Gravity
extends MotionBehavior
## M23 Gravidade visual (V1.2, D-323): queda de gotas e detritos, d = ½ g t² na direção `direction` (OFFSET analítico).
## Decorativa: nunca decide colisão nem acerto (D-019). Cada elemento cai com uma fração determinística de g (`spread`).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M23"
	display_name = "Gravidade visual"
	description = "Queda decorativa de gotas e detritos (direção, aceleração, dispersão, início)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_vec3(&"direction", Vector3(0, -1, 0), -1.0, 1.0, ""),
		MotionParam.make_float(&"gravity", 9.8, 0.0, 100.0, "m/s²"),
		MotionParam.make_float(&"spread", 0.25, 0.0, 1.0, ""),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var dir := MotionProfile.safe_axis(p["direction"], Vector3.DOWN)
	var g := float(p["gravity"])
	var spread := float(p["spread"])
	var t := maxf(lt - float(p["t_start"]), 0.0)
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var rnd := MotionHash.float01(ctx.seed, s.element_id & 0xFFFFFFFF, s.element_id >> 32, 23)
		c.position = dir * (0.5 * g * (1.0 - spread * rnd) * t * t)
		out.append(c)
	return out
