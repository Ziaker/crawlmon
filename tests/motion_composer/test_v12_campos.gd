extends SceneTree
## Motion Composer V1.2 (D-323): campos de movimento M21-M25 (fluxo, arrasto, gravidade visual, turbulência coerente, repulsão).
## godot --headless --path . --script res://tests/motion_composer/test_v12_campos.gd

var _fails := 0
var _checks := 0
var _cat: MotionCatalog


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func _init() -> void:
	_cat = MotionCatalog.new()
	ok(MotionBehaviors.register_all(_cat).is_empty(), "V1 (M01-M18) registra sem diagnóstico")
	ok(MotionBehaviors.register_v12(_cat).is_empty(), "V1.2 (M21-M25) registra sem diagnóstico")
	ok(_cat.missing_v1().size() == 2, "o conjunto fechado V1 não mudou: faltam só M19 e M20")
	for id in [&"M21", &"M22", &"M23", &"M24", &"M25"]:
		var b := _cat.get_behavior(id)
		ok(b != null and b.kind == MotionTypes.Kind.FIELD and b.accepted_operations == [MotionTypes.Op.OFFSET], "%s é um campo OFFSET" % id)
	_test_drag()
	_test_gravity()
	_test_curl()
	_test_flow()
	_test_repulsion()
	_test_through_composition()
	print("%d verificações, %d falhas" % [_checks, _fails])
	if _fails == 0:
		print("MC_V12_CAMPOS_PASS")
	quit(1 if _fails > 0 else 0)


func _ctx(t := 0.0, seed_v := 5) -> MotionContext:
	var c := MotionComposition.new()
	c.seed = seed_v
	c.duration = 3.0
	return c.make_context(t)


func _samples(n: int, positions := []) -> Array[MotionSample]:
	var out: Array[MotionSample] = []
	for i in n:
		var s := MotionSample.make_rest(float(i) / float(maxi(n - 1, 1)), i, 1.0)
		if i < positions.size():
			s.position = positions[i]
		out.append(s)
	return out


func _apply(b: MotionBehavior, params: Dictionary, samples: Array[MotionSample], t := 0.0) -> Array[MotionSample]:
	return b.apply(samples, params, _ctx(t), t, &"L")


func _test_drag() -> void:
	var b := _cat.get_behavior(&"M22")
	var p := {"direction": Vector3(0, 0, 1), "speed": 6.0, "drag": 3.0, "spread": 0.0, "t_start": 0.0}
	var d0 := _apply(b, p, _samples(3), 0.0)[0].position
	var d1 := _apply(b, p, _samples(3), 0.5)[0].position
	var d2 := _apply(b, p, _samples(3), 5.0)[0].position
	ok(d0.length() < 1e-6, "arrasto: nada se move antes de t_start")
	ok(d1.z > 0.0 and d2.z > d1.z, "arrasto: avança sempre")
	ok(absf(d2.z - 6.0 / 3.0 * (1.0 - exp(-15.0))) < 1e-4, "arrasto: valor analítico v0(1-e^-kt)/k")
	ok(d2.z <= 6.0 / 3.0 + 1e-6, "arrasto: nunca passa do limite v0/k (freia)")
	var ps := p.duplicate()
	ps["spread"] = 0.5
	var a := _apply(b, ps, _samples(20), 5.0)
	var lo := INF
	var hi := -INF
	for s in a:
		lo = minf(lo, s.position.z)
		hi = maxf(hi, s.position.z)
	ok(hi - lo > 0.05 and lo >= 1.0 - 1e-6, "arrasto: dispersão por elemento, no intervalo [(1-spread)v0/k, v0/k]")
	var again := _apply(b, ps, _samples(20), 5.0)
	var same := true
	for i in 20:
		same = same and a[i].position == again[i].position
	ok(same, "arrasto: determinístico (mesma semente, mesmo resultado)")


func _test_gravity() -> void:
	var b := _cat.get_behavior(&"M23")
	var p := {"direction": Vector3(0, -1, 0), "gravity": 10.0, "spread": 0.0, "t_start": 0.0}
	var s1 := _apply(b, p, _samples(2), 1.0)[0].position
	ok(s1.is_equal_approx(Vector3(0, -5, 0)), "gravidade: ½·g·t² = 5 m para baixo em 1 s (%s)" % str(s1))
	var s2 := _apply(b, p, _samples(2), 2.0)[0].position
	ok(absf(s2.y / s1.y - 4.0) < 1e-4, "gravidade: a queda cresce com o quadrado do tempo")
	ok(_apply(b, p, _samples(2), -1.0)[0].position.length() < 1e-6, "gravidade: tempo negativo não sobe")


func _test_curl() -> void:
	var b := _cat.get_behavior(&"M24")
	var p := {"scale": 1.3, "intensity": 0.4, "time_hz": 0.7, "seed": 3}
	var h := 1e-3
	var worst := 0.0
	var mag := 0.0
	for i in 12:
		var q := Vector3(0.3 + 0.37 * i, -0.2 + 0.21 * i, 0.5 - 0.11 * i)
		var pts: Array = [q, q + Vector3(h, 0, 0), q - Vector3(h, 0, 0), q + Vector3(0, h, 0), q - Vector3(0, h, 0), q + Vector3(0, 0, h), q - Vector3(0, 0, h)]
		var r := _apply(b, p, _samples(7, pts), 0.9)
		var div := (r[1].position.x - r[2].position.x + r[3].position.y - r[4].position.y + r[5].position.z - r[6].position.z) / (2.0 * h)
		worst = maxf(worst, absf(div))
		mag = maxf(mag, r[0].position.length())
	ok(worst < 1e-3, "turbulência coerente: divergência ≈ 0 (pior %.6f)" % worst)
	ok(mag > 0.05, "turbulência coerente: o deslocamento existe (%.3f m)" % mag)
	ok(mag <= 0.4 * 3.0, "turbulência coerente: limitada pela intensidade (%.3f)" % mag)
	# coerência: pontos vizinhos se movem quase igual (ao contrário do ruído por ponto)
	var near_pts: Array = [Vector3(0.2, 0.1, 0.0), Vector3(0.21, 0.1, 0.0)]
	var rr := _apply(b, p, _samples(2, near_pts), 0.4)
	ok(rr[0].position.distance_to(rr[1].position) < 0.05, "turbulência coerente: vizinhos fluem juntos")
	var z := _apply(b, {"scale": 1.0, "intensity": 0.0, "time_hz": 0.5, "seed": 0}, _samples(4, [Vector3.ONE]), 1.0)
	ok(z[0].position.length() < 1e-9, "turbulência coerente: intensidade 0 é neutra")


func _test_flow() -> void:
	var b := _cat.get_behavior(&"M21")
	var p := {"direction": Vector3(0, 0, 1), "center": Vector3.ZERO, "distance": 2.0, "radius": 1.0, "core_radius": 0.3, "edge_noise": 0.5, "seed": 0, "t_start": 0.0, "t_duration": 0.0}
	var pts: Array = [Vector3(0, 0, 0), Vector3(0.1, 0, 0), Vector3(0.65, 0, 0), Vector3(2.0, 0, 0)]
	var r := _apply(b, p, _samples(4, pts), 1.0)
	ok(r[0].position.is_equal_approx(Vector3(0, 0, 2)), "fluxo: no eixo o fluxo é limpo e vale a distância toda")
	ok(r[1].position.is_equal_approx(Vector3(0, 0, 2)), "fluxo: dentro do núcleo não há ruído de borda")
	ok(r[2].position.z < 2.0 and r[2].position.z > 0.0, "fluxo: na borda o fluxo cai")
	ok(r[2].position.x != 0.0 or r[2].position.y != 0.0, "fluxo: a borda ganha ruído lateral")
	ok(r[3].position.length() < 1e-6, "fluxo: fora do raio nada se move")
	var nodir := _apply(b, {"direction": Vector3.ZERO, "center": Vector3.ZERO, "distance": 1.0, "radius": 0.0, "core_radius": 0.0, "edge_noise": 0.0, "seed": 0, "t_start": 0.0, "t_duration": 0.0}, _samples(2), 1.0)
	ok(nodir[0].position.is_finite(), "fluxo: direção nula não gera NaN")


func _test_repulsion() -> void:
	var b := _cat.get_behavior(&"M25")
	var p := {"center": Vector3.ZERO, "strength": 1.0, "reach": 2.0, "curve": 1.0, "t_start": 0.0, "t_duration": 0.0}
	var r := _apply(b, p, _samples(3, [Vector3(1, 0, 0), Vector3(5, 0, 0), Vector3(0, 0, 0)]), 1.0)
	ok(r[0].position.x > 0.0 and absf(r[0].position.y) < 1e-6, "repulsão: afasta do centro")
	ok(r[1].position.length() < 1e-6, "repulsão: fora do alcance nada acontece")
	ok(r[2].position.is_finite(), "repulsão: no centro exato não gera NaN")
	ok(_apply(b, p, _samples(1, [Vector3(1, 0, 0)]), 1.0)[0].position.length() > _apply(b, p, _samples(1, [Vector3(1.8, 0, 0)]), 1.0)[0].position.length(), "repulsão: mais forte perto do centro")


## Pelo compositor de verdade: ordem de camadas, soma por OFFSET e repetibilidade.
func _test_through_composition() -> void:
	var c := MotionComposition.new()
	c.id = &"v12"
	c.sample_count = 20
	c.seed = 9
	for spec in [[&"M22", {"direction": Vector3(0, 0, 1), "speed": 4.0, "drag": 2.0, "spread": 0.2, "t_start": 0.0}], [&"M23", {"direction": Vector3(0, -1, 0), "gravity": 9.8, "spread": 0.2, "t_start": 0.0}], [&"M24", {"scale": 1.0, "intensity": 0.2, "time_hz": 0.5, "seed": 1}]]:
		var l := MotionLayer.new()
		l.id = StringName("L" + String(spec[0]))
		l.behavior_id = spec[0]
		l.op = MotionTypes.Op.OFFSET
		l.params = spec[1]
		c.add_layer(l)
	var r1 := c.evaluate(_cat, c.make_context(0.8))
	var r2 := c.evaluate(_cat, c.make_context(0.8))
	ok(not r1.has_errors() and r1.samples.size() == 20, "composição M22+M23+M24: sem erros, 20 amostras")
	var same := true
	for i in r1.samples.size():
		same = same and r1.samples[i].position == r2.samples[i].position and r1.samples[i].position.is_finite()
	ok(same, "composição de campos: repetível e finita")
