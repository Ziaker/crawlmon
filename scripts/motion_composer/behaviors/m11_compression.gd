class_name MotionM11Compression
extends MotionBehavior
## M11 Compressão — concentra a região em direção ao seu centro (extremidades preservadas) e,
## opcionalmente, estreita a seção transversal (`radial`) (DEFORM). Monotônico para strength < 1.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M11"
	display_name = "Compressão"
	description = "Reduz a extensão ou concentração espacial das regiões selecionadas."
	group = &"deformacoes"
	kind = MotionTypes.Kind.MODIFIER
	accepted_operations = [Op.DEFORM, Op.REPLACE]
	params = [MotionParam.make_float(&"strength", 0.6, 0.0, 0.95, "")]
	params.append_array(MotionProfile.region_params(0.5, 0.4, 0.2))
	params.append(MotionParam.make_float(&"radial", 0.0, 0.0, 1.0, ""))
	params.append(MotionParam.make_float(&"reference_length", 1.0, 0.01, 100.0, "m"))


func apply(samples: Array[MotionSample], p: Dictionary, _ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var k := float(p["strength"])
	var radial := float(p["radial"])
	var center := float(p["center"])
	var extent := float(p["extent"])
	var soft := float(p["softness"])
	var zc := center * float(p["reference_length"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var w := MotionProfile.window(s.u, center, extent, soft) * tr
		if w > 0.0:
			if k > 0.0:
				c.position.z = zc + (s.position.z - zc) * (1.0 - k * w)
			if radial > 0.0:
				var sc := 1.0 - radial * w
				c.position.x = s.position.x * sc
				c.position.y = s.position.y * sc
		out.append(c)
	return out
