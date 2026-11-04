class_name MotionM03Serpentine
extends MotionBehavior
## M03 Serpentina — deslocamento lateral senoidal contínuo, com curvatura parabólica opcional (OFFSET).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M03"
	display_name = "Serpentina"
	description = "Cria deslocamento lateral contínuo e ondulatório ao longo de uma direção (amplitude, comprimento de onda, fase, curvatura)."
	group = &"trajetorias"
	kind = MotionTypes.Kind.MODIFIER
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_float(&"amplitude", 0.1, 0.0, 5.0, "m"),
		MotionParam.make_float(&"wavelength", 0.5, 0.05, 20.0, "m"),
		MotionParam.make_float(&"phase_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_float(&"curvature", 0.0, -10.0, 10.0, "1/m"),
		MotionParam.make_float(&"axis_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_float(&"speed", 0.0, -50.0, 50.0, "m/s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var amp := float(p["amplitude"])
	var wl := float(p["wavelength"])
	var ph := deg_to_rad(float(p["phase_deg"]))
	var curv := float(p["curvature"])
	var shift := float(p["speed"]) * lt
	var dir := MotionProfile.lateral(float(p["axis_deg"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var z := s.position.z
		c.position = dir * (amp * sin(TAU * (z - shift) / wl + ph) + 0.5 * curv * z * z)
		out.append(c)
	return out
