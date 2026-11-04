class_name MotionM12TravelingPulse
extends MotionBehavior
## M12 Pulso viajante — concentração que percorre o percurso (coordenada `u`) com perfil assimétrico:
## frente curta e cauda longa. Saída multiplica intensidade/espessura (MULTIPLY_ATTRIBUTE) e/ou
## desloca lateralmente (OFFSET). A velocidade é puramente visual (§3 grupo D).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M12"
	display_name = "Pulso viajante"
	description = "Desloca uma concentração de intensidade ou deformação ao longo de um percurso."
	group = &"propagacao"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET, Op.MULTIPLY_ATTRIBUTE]
	params = [
		MotionParam.make_float(&"speed", 0.5, -20.0, 20.0, "u/s"),
		MotionParam.make_float(&"start", 0.0, -2.0, 2.0, "u"),
		MotionParam.make_float(&"width", 0.1, 0.005, 1.0, "u"),
		MotionParam.make_float(&"amplitude", 1.0, 0.0, 10.0, ""),
		MotionParam.make_float(&"thickness_gain", 0.5, 0.0, 10.0, ""),
		MotionParam.make_float(&"displace", 0.1, -5.0, 5.0, "m"),
		MotionParam.make_float(&"axis_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_float(&"tail", 3.0, 0.1, 20.0, "razão"),
		MotionParam.make_float(&"ripples", 0.0, 0.0, 20.0, "ciclos"),
		MotionParam.make_bool(&"loop", false),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var c0 := float(p["start"]) + float(p["speed"]) * lt
	if bool(p["loop"]):
		c0 = fposmod(c0, 1.0)
	var width := float(p["width"])
	var tail := float(p["tail"])
	var ripples := float(p["ripples"])
	var amp := float(p["amplitude"])
	var thick := float(p["thickness_gain"])
	var disp := MotionProfile.lateral(float(p["axis_deg"])) * float(p["displace"])
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var d := s.u - c0
		var x := d / width if d >= 0.0 else -d / (width * tail)
		var prof := exp(-x * x)
		if ripples > 0.0:
			prof *= cos(TAU * ripples * d / width)
		c.intensity = 1.0 + amp * prof
		c.width = 1.0 + thick * prof
		c.opacity = 1.0
		c.position = disp * prof
		out.append(c)
	return out
