class_name MotionM16DirectionalBurst
extends MotionBehavior
## M16 Explosão direcional — expansão rápida e orientada a partir de uma região de origem.
## Cada elemento recebe, de forma determinística (hash do id + semente), uma direção dentro de um cone
## e um fator de alcance entre 50% e 100%. Só desenho: não cria impactos nem altera resultado lógico.
## OFFSET: `position` = deslocamento. MULTIPLY_ATTRIBUTE: opacidade cai até 1 − dissipate.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M16"
	display_name = "Explosão direcional"
	description = "Expansão rápida e orientada de elementos a partir de uma região de origem (direção, abertura, distância, distribuição, perfil temporal, dissipação)."
	group = &"impacto"
	kind = MotionTypes.Kind.MODIFIER
	accepted_operations = [Op.OFFSET, Op.MULTIPLY_ATTRIBUTE]
	params = [
		MotionParam.make_vec3(&"direction", Vector3(0, 0, 1), -1.0, 1.0, ""),
		MotionParam.make_float(&"cone_deg", 45.0, 0.0, 180.0, "deg"),
		MotionParam.make_float(&"distance", 1.0, 0.0, 20.0, "m"),
		MotionParam.make_float(&"distribution", 1.0, 0.1, 8.0, "expoente"),
		MotionParam.make_vec3(&"origin", Vector3.ZERO, -20.0, 20.0, "m"),
		MotionParam.make_float(&"radial", 0.0, 0.0, 1.0, ""),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.5, 0.01, 60.0, "s"),
		MotionParam.make_float(&"curve", 2.0, 0.1, 8.0, "expoente"),
		MotionParam.make_float(&"dissipate", 1.0, 0.0, 1.0, ""),
	]


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var axis := MotionProfile.safe_axis(p["direction"])
	var frame := MotionProfile.basis_from_tangent(axis)
	var cone := deg_to_rad(float(p["cone_deg"]))
	var dist := float(p["distance"])
	var distribution := float(p["distribution"])
	var origin: Vector3 = p["origin"]
	var radial := float(p["radial"])
	var prog := clampf((lt - float(p["t_start"])) / float(p["t_duration"]), 0.0, 1.0)
	var e := 1.0 - pow(1.0 - prog, float(p["curve"]))
	var dissipate := float(p["dissipate"])
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var lo := s.element_id & 0xFFFFFFFF
		var hi := s.element_id >> 32
		var az := TAU * MotionHash.float01(ctx.seed, lo, hi, 1)
		var pol := cone * pow(MotionHash.float01(ctx.seed, lo, hi, 2), distribution)
		var reach := 0.5 + 0.5 * MotionHash.float01(ctx.seed, lo, hi, 3)
		var dir := axis * cos(pol) + (frame.x * cos(az) + frame.y * sin(az)) * sin(pol)
		if radial > 0.0:
			var away := MotionProfile.safe_axis(s.position - origin, dir)
			dir = MotionProfile.safe_axis(dir.lerp(away, radial), dir)
		c.position = dir * (dist * reach * e)
		c.intensity = 1.0
		c.width = 1.0
		c.opacity = 1.0 - dissipate * e
		out.append(c)
	return out
