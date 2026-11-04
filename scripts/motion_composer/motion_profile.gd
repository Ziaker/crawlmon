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
