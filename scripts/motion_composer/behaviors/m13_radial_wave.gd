class_name MotionM13RadialWave
extends MotionBehavior
## M13 Onda radial — frente que se expande de um centro sobre o plano perpendicular a `plane_normal`.
## Saída desloca ao longo da normal (OFFSET) e/ou multiplica a intensidade (MULTIPLY_ATTRIBUTE).
## Velocidade e alcance são puramente visuais (§3 grupo D).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M13"
	display_name = "Onda radial"
	description = "Propaga uma frente de influência a partir de um centro sobre um plano ou domínio espacial definido."
	group = &"propagacao"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET, Op.MULTIPLY_ATTRIBUTE]
	params = [
		MotionParam.make_vec3(&"center", Vector3.ZERO, -20.0, 20.0, "m"),
		MotionParam.make_vec3(&"plane_normal", Vector3(0, 0, 1), -1.0, 1.0, ""),
		MotionParam.make_float(&"speed", 1.0, 0.0, 50.0, "m/s"),
		MotionParam.make_float(&"width", 0.1, 0.005, 5.0, "m"),
		MotionParam.make_float(&"amplitude", 0.1, 0.0, 5.0, "m"),
		MotionParam.make_float(&"intensity_gain", 0.0, 0.0, 10.0, ""),
		MotionParam.make_float(&"range", 2.0, 0.05, 50.0, "m"),
		MotionParam.make_float(&"dissipation", 1.0, 0.0, 8.0, "expoente"),
		MotionParam.make_float(&"ripples", 0.0, 0.0, 20.0, "ciclos"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var center: Vector3 = p["center"]
	var n := MotionProfile.safe_axis(p["plane_normal"])
	var front := float(p["speed"]) * lt
	var width := float(p["width"])
	var amp := float(p["amplitude"])
	var gain := float(p["intensity_gain"])
	var rng := float(p["range"])
	var ripples := float(p["ripples"])
	var fade := pow(1.0 - clampf(front / rng, 0.0, 1.0), float(p["dissipation"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var v := s.position - center
		var d := (v - n * v.dot(n)).length()
		var prof := 0.0
		if d <= rng:
			var x := (d - front) / width
			prof = exp(-x * x) * fade
			if ripples > 0.0:
				prof *= cos(TAU * ripples * x)
		c.position = n * (amp * prof)
		c.intensity = 1.0 + gain * prof
		c.width = 1.0
		c.opacity = 1.0
		out.append(c)
	return out
