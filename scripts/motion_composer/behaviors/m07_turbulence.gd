class_name MotionM07Turbulence
extends MotionBehavior
## M07 Turbulência — ruído de valor 3D + tempo, determinístico (hash inteiro), sem estado (OFFSET).
## Cada componente do deslocamento está em [-intensidade, +intensidade].

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M07"
	display_name = "Turbulência"
	description = "Introduz perturbações espaciais contínuas e não uniformes (escala espacial, intensidade, frequência temporal, semente)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_float(&"scale", 0.5, 0.01, 20.0, "m"),
		MotionParam.make_float(&"intensity", 0.1, 0.0, 5.0, "m"),
		MotionParam.make_float(&"time_hz", 1.0, 0.0, 30.0, "Hz"),
		MotionParam.make_int(&"seed", 0, 0, 1000000, ""),
	]


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var inv_scale := 1.0 / float(p["scale"])
	var amp := float(p["intensity"])
	var sd := ctx.seed + int(p["seed"])
	var tc := lt * float(p["time_hz"])
	var it0 := floori(tc)
	var ft := tc - float(it0)
	ft = ft * ft * (3.0 - 2.0 * ft)
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var q := s.position * inv_scale
		var ix := floori(q.x)
		var iy := floori(q.y)
		var iz := floori(q.z)
		var fx := q.x - float(ix)
		var fy := q.y - float(iy)
		var fz := q.z - float(iz)
		fx = fx * fx * (3.0 - 2.0 * fx)
		fy = fy * fy * (3.0 - 2.0 * fy)
		fz = fz * fz * (3.0 - 2.0 * fz)
		var acc := Vector3.ZERO
		for dt in 2:
			var wt := ft if dt == 1 else 1.0 - ft
			for dz in 2:
				var wz := fz if dz == 1 else 1.0 - fz
				for dy in 2:
					var wy := fy if dy == 1 else 1.0 - fy
					for dx in 2:
						var wx := fx if dx == 1 else 1.0 - fx
						var h := MotionHash.mix(sd, ix + dx, iy + dy, ((iz + dz) & 0xFFFF) | (((it0 + dt) & 0xFFFF) << 16))
						var v := Vector3(float(h & 1023), float((h >> 10) & 1023), float((h >> 20) & 1023)) * (2.0 / 1023.0) - Vector3.ONE
						acc += v * (wt * wz * wy * wx)
		c.position = acc * amp
		out.append(c)
	return out
