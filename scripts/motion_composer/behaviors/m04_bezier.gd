class_name MotionM04Bezier
extends MotionBehavior
## M04 Bézier dinâmica — gerador: curva cúbica cujos pontos de controle internos derivam no tempo.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M04"
	display_name = "Bézier dinâmica"
	description = "Avalia uma trajetória com pontos de controle modificáveis ao longo do tempo (pontos, progressão, variação temporal)."
	group = &"trajetorias"
	kind = MotionTypes.Kind.GENERATOR
	accepted_operations = [Op.REPLACE]
	params = [
		MotionParam.make_vec3(&"p0", Vector3(0, 0, 0), -20.0, 20.0, "m"),
		MotionParam.make_vec3(&"p1", Vector3(0.3, 0, 0.33), -20.0, 20.0, "m"),
		MotionParam.make_vec3(&"p2", Vector3(-0.3, 0, 0.66), -20.0, 20.0, "m"),
		MotionParam.make_vec3(&"p3", Vector3(0, 0, 1), -20.0, 20.0, "m"),
		MotionParam.make_float(&"progress", 1.0, 0.0, 1.0, ""),
		MotionParam.make_vec3(&"drift1", Vector3(0, 0.1, 0), -5.0, 5.0, "m"),
		MotionParam.make_vec3(&"drift2", Vector3(0, -0.1, 0), -5.0, 5.0, "m"),
		MotionParam.make_float(&"drift_hz", 0.5, 0.0, 30.0, "Hz"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var k := sin(TAU * float(p["drift_hz"]) * lt)
	var p0: Vector3 = p["p0"]
	var p1: Vector3 = (p["p1"] as Vector3) + (p["drift1"] as Vector3) * k
	var p2: Vector3 = (p["p2"] as Vector3) + (p["drift2"] as Vector3) * k
	var p3: Vector3 = p["p3"]
	var prog := float(p["progress"])
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var t := s.u * prog
		var m := 1.0 - t
		var pos := m * m * m * p0 + 3.0 * m * m * t * p1 + 3.0 * m * t * t * p2 + t * t * t * p3
		var tan := 3.0 * (m * m * (p1 - p0) + 2.0 * m * t * (p2 - p1) + t * t * (p3 - p2))
		c.basis = MotionProfile.basis_from_tangent(tan)
		c.position = pos + c.basis * Vector3(s.rest.x, s.rest.y, 0.0)
		out.append(c)
	return out
