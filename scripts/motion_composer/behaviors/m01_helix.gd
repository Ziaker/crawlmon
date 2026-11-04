class_name MotionM01Helix
extends MotionBehavior
## M01 Espiral helicoidal — gerador. Substitui a trajetória por uma hélice em torno de +Z.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M01"
	display_name = "Espiral helicoidal"
	description = "Desloca amostras em torno de um eixo com avanço axial (raio, passo, voltas, fase, sentido, evolução do raio)."
	group = &"trajetorias"
	kind = MotionTypes.Kind.GENERATOR
	accepted_operations = [Op.REPLACE]
	params = [
		MotionParam.make_float(&"radius", 0.25, 0.0, 10.0, "m"),
		MotionParam.make_float(&"radius_growth", 0.0, -10.0, 10.0, "m"),
		MotionParam.make_float(&"pitch", 0.5, 0.0, 10.0, "m/volta"),
		MotionParam.make_float(&"turns", 3.0, 0.0, 50.0, "voltas"),
		MotionParam.make_float(&"phase_deg", 0.0, -360.0, 360.0, "deg"),
		MotionParam.make_int(&"direction", 1, -1, 1, ""),
		MotionParam.make_float(&"spin_deg_s", 0.0, -3600.0, 3600.0, "deg/s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var r0 := float(p["radius"])
	var growth := float(p["radius_growth"])
	var pitch := float(p["pitch"])
	var turns := float(p["turns"])
	var dir := -1.0 if int(p["direction"]) < 0 else 1.0
	var total := TAU * turns * dir
	var offset := deg_to_rad(float(p["phase_deg"])) + deg_to_rad(float(p["spin_deg_s"])) * lt
	var length := pitch * turns
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var r := maxf(0.0, r0 + growth * s.u)
		var th := total * s.u + offset
		var cth := cos(th)
		var sth := sin(th)
		var tangent := Vector3(growth * cth - r * total * sth, growth * sth + r * total * cth, length)
		c.basis = MotionProfile.basis_from_tangent(tangent)
		c.position = Vector3(r * cth, r * sth, s.u * length) + c.basis * Vector3(s.rest.x, s.rest.y, 0.0)
		out.append(c)
	return out
