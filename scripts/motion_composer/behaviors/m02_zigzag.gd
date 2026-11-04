class_name MotionM02Zigzag
extends MotionBehavior
## M02 Zigue-zague — deslocamento lateral triangular ao longo de +Z (OFFSET).
## `smoothing` 0 = vértices vivos (triangular); 1 = senóide.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M02"
	display_name = "Zigue-zague"
	description = "Alterna deslocamentos laterais durante a progressão (amplitude, frequência espacial, suavização dos vértices, fase)."
	group = &"trajetorias"
	kind = MotionTypes.Kind.MODIFIER
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_float(&"amplitude", 0.1, 0.0, 5.0, "m"),
		MotionParam.make_float(&"frequency", 4.0, 0.0, 100.0, "ciclos/m"),
		MotionParam.make_float(&"phase_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_float(&"smoothing", 0.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"axis_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_float(&"speed", 0.0, -50.0, 50.0, "ciclos/s"),
	]


## Onda triangular em [-1, 1] com zero em fase 0 e picos em 0,25 / 0,75 (mesma convenção do seno).
static func triangle(phase_cycles: float) -> float:
	return 4.0 * absf(fposmod(phase_cycles - 0.25, 1.0) - 0.5) - 1.0


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var amp := float(p["amplitude"])
	var freq := float(p["frequency"])
	var ph := float(p["phase_deg"]) / 360.0 - float(p["speed"]) * lt
	var sm := float(p["smoothing"])
	var dir := MotionProfile.lateral(float(p["axis_deg"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var phi := freq * s.position.z + ph
		var wv := lerpf(triangle(phi), sin(TAU * phi), sm)
		c.position = dir * (amp * wv)
		out.append(c)
	return out
