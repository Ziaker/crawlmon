class_name MotionProfile
extends RefCounted
## Auxiliares compartilhados pelos comportamentos: regiões de influência, rampas temporais e bases locais.
## Convenções (propostas do agente, D-172): `u` é a coordenada longitudinal de repouso (0..1);
## regiões são [centro ± extensão/2] em `u`, com borda suave de largura `softness`.


## Parâmetros comuns de deformação (§3, grupo C): posição, extensão, curva (suavidade), início e duração.
static func region_params(center: float = 0.5, extent: float = 1.0, softness: float = 0.0) -> Array[MotionParam]:
	return [
		MotionParam.make_float(&"center", center, 0.0, 1.0, "u"),
		MotionParam.make_float(&"extent", extent, 0.0, 1.0, "u"),
		MotionParam.make_float(&"softness", softness, 0.0, 1.0, "u"),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 0.0, 0.0, 60.0, "s"),
	]


## Peso 1 dentro de [centro ± extensão/2], caindo suavemente a 0 ao longo de `softness` fora dela.
static func window(u: float, center: float, extent: float, softness: float) -> float:
	var d := absf(u - center)
	var half := extent * 0.5
	if softness <= 0.0:
		return 1.0 if d <= half else 0.0
	return 1.0 - smoothstep(half, half + softness, d)


## Rampa acumulada 0 -> 1 através da região (usada onde o efeito se acumula ao longo do eixo).
static func ramp(u: float, center: float, extent: float) -> float:
	if extent <= 0.0:
		return 1.0 if u >= center else 0.0
	return smoothstep(center - extent * 0.5, center + extent * 0.5, u)


## Progressão temporal da transformação: 0 antes de `start`, 1 após `start + duration`.
static func time_ramp(local_time: float, start: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0 if local_time >= start else 0.0
	return smoothstep(0.0, 1.0, (local_time - start) / duration)


## Base com basis.z = tangente. Tangente quase nula -> identidade.
static func basis_from_tangent(t: Vector3, hint: Vector3 = Vector3.UP) -> Basis:
	var l := t.length()
	if l < 1e-9:
		return Basis.IDENTITY
	var z := t / l
	var up := hint if absf(z.dot(hint)) < 0.999 else Vector3.RIGHT
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	return Basis(x, y, z)


static func safe_axis(v: Vector3, fallback: Vector3 = Vector3.BACK) -> Vector3:
	return v.normalized() if v.length() > 1e-6 else fallback


static func lateral(axis_deg: float) -> Vector3:
	var a := deg_to_rad(axis_deg)
	return Vector3(cos(a), sin(a), 0.0)


## Parâmetros comuns de M17/M18 (grupo G): direção de propagação, duração, curva, largura da transição,
## irregularidade determinística e canais afetados.
## direction: 0 = do início (u=0) ao fim; 1 = do fim ao início; 2 = do centro para as bordas.
static func envelope_params() -> Array[MotionParam]:
	return [
		MotionParam.make_int(&"direction", 0, 0, 2, ""),
		MotionParam.make_float(&"t_start", 0.0, -60.0, 60.0, "s"),
		MotionParam.make_float(&"t_duration", 1.0, 0.01, 60.0, "s"),
		MotionParam.make_float(&"curve", 1.0, 0.1, 8.0, "expoente"),
		MotionParam.make_float(&"width", 0.15, 0.0, 1.0, "u"),
		MotionParam.make_float(&"jitter", 0.0, 0.0, 1.0, ""),
		MotionParam.make_bool(&"affect_visibility", true),
		MotionParam.make_bool(&"affect_width", true),
		MotionParam.make_bool(&"affect_intensity", false),
		MotionParam.make_bool(&"affect_opacity", false),
	]


## Cobertura 0..1 de uma varredura: 1 = já alcançado pela frente. `e` = progresso com curva aplicada.
static func sweep(u: float, e: float, width: float, direction: int, jitter: float, rnd: float) -> float:
	if e <= 0.0:
		return 0.0
	if e >= 1.0:
		return 1.0
	var x := u
	if direction == 1:
		x = 1.0 - u
	elif direction == 2:
		x = absf(u - 0.5) * 2.0
	if jitter > 0.0:
		x += jitter * (rnd - 0.5) * width
	if width <= 0.0:
		return 1.0 if x < e else 0.0
	var front := e * (1.0 + width)
	return 1.0 - smoothstep(front - width, front, x)


## Implementação compartilhada de M17 (dissolve=false) e M18 (dissolve=true).
static func envelope_apply(samples: Array[MotionSample], p: Dictionary, ctx: MotionContext, lt: float, dissolve: bool) -> Array[MotionSample]:
	var prog := clampf((lt - float(p["t_start"])) / float(p["t_duration"]), 0.0, 1.0)
	var e := pow(prog, float(p["curve"]))
	var width := float(p["width"])
	var direction := int(p["direction"])
	var jitter := float(p["jitter"])
	var a_vis := bool(p["affect_visibility"])
	var a_w := bool(p["affect_width"])
	var a_i := bool(p["affect_intensity"])
	var a_o := bool(p["affect_opacity"])
	var out: Array[MotionSample] = []
	for s in samples:
		var c := s.duplicate_sample()
		var rnd := 0.5
		if jitter > 0.0:
			rnd = MotionHash.float01(ctx.seed, s.element_id & 0xFFFFFFFF, s.element_id >> 32, 11)
		var g := sweep(s.u, e, width, direction, jitter, rnd)
		if dissolve:
			g = 1.0 - g
		c.visible = (g > 0.001) if a_vis else true
		c.width = g if a_w else 1.0
		c.intensity = g if a_i else 1.0
		c.opacity = g if a_o else 1.0
		out.append(c)
	return out
