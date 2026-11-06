class_name MotionM21Flow
extends MotionBehavior
## M21 Fluxo direcional (V1.2, D-323): empurra as amostras numa direção, com o centro organizado e as bordas turbulentas
## (jato, rajada, chuva de fragmentos). Campo analítico, sem estado (OFFSET). A região de influência é um cilindro em
## torno do eixo (centro, direção): dentro de `core_radius` o fluxo é limpo; de `core_radius` a `radius` ele cai e
## ganha ruído de borda (`edge_noise`).

const Op := MotionTypes.Op


func _init() -> void:
	id = &"M21"
	display_name = "Fluxo direcional"
	description = "Empurra as amostras numa direção; centro organizado, bordas turbulentas (direção, distância, raio, raio do núcleo, ruído de borda)."
	group = &"campos"
	kind = MotionTypes.Kind.FIELD
	accepted_operations = [Op.OFFSET]
	params = [
		MotionParam.make_vec3(&"direction", Vector3(0, 0, 1), -1.0, 1.0, ""),
		MotionParam.make_vec3(&"center", Vector3.ZERO, -50.0, 50.0, "m"),
		MotionParam.make_float(&"distance", 1.0, -50.0, 50.0, "m"),
		MotionParam.make_float(&"radius", 0.0, 0.0, 50.0, "m"),
		MotionParam.make_float(&"core_radius", 0.0, 0.0, 50.0, "m"),
		MotionParam.make_float(&"edge_noise", 0.0, 0.0, 5.0, "m"),
		MotionParam.make_int(&"seed", 0, 0, 1000000, ""),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


func apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, _lid: StringName) -> Array[MotionSample]:
	var dir := MotionProfile.safe_axis(p["direction"])
	var center: Vector3 = p["center"]
	var dist := float(p["distance"])
	var radius := float(p["radius"])
	var core := minf(float(p["core_radius"]), radius if radius > 0.0 else INF)
	var edge := float(p["edge_noise"])
	var sd := ctx.seed + int(p["seed"])
	var tr := MotionProfile.time_ramp(lt, float(p["t_start"]), float(p["t_duration"]))
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var rel := s.position - center
		var radial := rel - dir * rel.dot(dir)
		var d := radial.length()
		var w := 1.0
		if radius > 0.0:
			w = 1.0 - smoothstep(core, radius, d)
		var off := dir * (dist * w * tr)
		if edge > 0.0 and radius > 0.0:
			var edge_w := smoothstep(core, radius, d) * w * 4.0  # peaks inside the falloff band, zero at both ends
			var h := MotionHash.mix(sd, s.element_id & 0xFFFFFFFF, s.element_id >> 32, int(floor(lt * 6.0)))
			var rnd := Vector3(float(h & 1023), float((h >> 10) & 1023), float((h >> 20) & 1023)) * (2.0 / 1023.0) - Vector3.ONE
			off += (rnd - dir * rnd.dot(dir)) * (edge * edge_w * tr)
		c.position = off
		out.append(c)
	return out
