class_name MotionM24CurlNoise
extends MotionBehavior
## M24 Turbulência coerente (V1.2, D-323): variação orgânica CONTÍNUA e sem divergência. O deslocamento é o rotacional de
## um potencial vetorial analítico (senos e cossenos com fases derivadas da semente), então as amostras vizinhas
## fluem juntas em redemoinhos suaves, ao contrário do M07 (ruído independente por ponto). OFFSET, sem estado.

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M24"
	display_name = "Turbulência coerente"
	description = "Fluxo orgânico suave e sem divergência (escala, intensidade, frequência temporal, semente)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_float(&"scale", 1.0, 0.05, 20.0, "m"),
		MotionParam.make_float(&"intensity", 0.2, 0.0, 5.0, "m"),
		MotionParam.make_float(&"time_hz", 0.5, 0.0, 10.0, "Hz"),
		MotionParam.make_int(&"seed", 0, 0, 1000000, ""),
	]


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var k := TAU / float(p["scale"])
	var amp := float(p["intensity"])
	var sd := ctx.seed + int(p["seed"])
	var w := TAU * float(p["time_hz"]) * lt
	var ph: Array[float] = []
	for i in 6:
		ph.append(MotionHash.float01(sd, i, 0, 24) * TAU)
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var q := s.position
		# A = (sin(k y + p0) cos(k z + p1 + w), sin(k z + p2) cos(k x + p3 + w), sin(k x + p4) cos(k y + p5 + w)); v = curl A
		var ax_dy := k * cos(k * q.y + ph[0]) * cos(k * q.z + ph[1] + w)
		var ax_dz := -k * sin(k * q.y + ph[0]) * sin(k * q.z + ph[1] + w)
		var ay_dz := k * cos(k * q.z + ph[2]) * cos(k * q.x + ph[3] + w)
		var ay_dx := -k * sin(k * q.z + ph[2]) * sin(k * q.x + ph[3] + w)
		var az_dx := k * cos(k * q.x + ph[4]) * cos(k * q.y + ph[5] + w)
		var az_dy := -k * sin(k * q.x + ph[4]) * sin(k * q.y + ph[5] + w)
		var v := Vector3(az_dy - ay_dz, ax_dz - az_dx, ay_dx - ax_dy)
		c.position = v * (amp / k)
		out.append(c)
	return out
