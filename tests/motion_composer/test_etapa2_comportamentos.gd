extends SceneTree
## Motion Composer V1 — Etapa 2: testes de M01–M13 (D-172).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa2_comportamentos.gd
## Cada comportamento: parâmetros válidos, limites do domínio, ausência de NaN, repetibilidade,
## resposta à intensidade, pausa, independência da representação e identidade distinguível.

const Op := MotionTypes.Op

const ENTRIES := [
	[&"M01", Op.REPLACE], [&"M02", Op.OFFSET], [&"M03", Op.OFFSET], [&"M04", Op.REPLACE],
	[&"M05", Op.OFFSET], [&"M06", Op.OFFSET], [&"M07", Op.OFFSET], [&"M08", Op.DEFORM],
	[&"M09", Op.DEFORM], [&"M10", Op.DEFORM], [&"M11", Op.DEFORM], [&"M12", Op.OFFSET],
	[&"M13", Op.OFFSET],
]
const TIME_VARYING: Array[StringName] = [&"M04", &"M07", &"M12", &"M13"]

var _fails: int = 0
var _checks: int = 0
var _cat: MotionCatalog


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func near(a: float, b: float, eps: float = 1e-3) -> bool:
	return absf(a - b) <= eps


func vnear(a: Vector3, b: Vector3, eps: float = 1e-3) -> bool:
	return a.distance_to(b) <= eps


func helix_base(radius: float = 0.3, growth: float = 0.0) -> Array:
	return [[&"M01", Op.REPLACE, {"radius": radius, "radius_growth": growth, "pitch": 0.5, "turns": 2.0}]]


## layers: [[id, op, params, intensity?], ...] — avalia e devolve o resultado.
func eval_layers(layers: Array, t: float = 0.0, n: int = 65, seed_v: int = 7) -> MotionResult:
	var c := MotionComposition.new()
	c.id = &"t"
	c.sample_count = n
	c.seed = seed_v
	var i := 0
	for spec in layers:
		var l := MotionLayer.new()
		l.id = StringName("L%d" % i)
		l.behavior_id = spec[0]
		l.op = spec[1]
		l.params = spec[2]
		if spec.size() > 3:
			l.intensity = spec[3]
		c.add_layer(l)
		i += 1
	return c.evaluate(_cat, c.make_context(t))


func run(bid: StringName, op: int, params: Dictionary = {}, base: Array = [], t: float = 0.0, n: int = 65, intensity: float = 1.0) -> MotionResult:
	var layers: Array = base.duplicate()
	layers.append([bid, op, params, intensity])
	return eval_layers(layers, t, n)


func base_only(base: Array, t: float = 0.0, n: int = 65) -> MotionResult:
	return eval_layers(base, t, n)


func finite_ok(r: MotionResult) -> bool:
	if r.has_errors():
		return false
	for s in r.samples:
		if not s.is_finite_sample():
			return false
	return true


func max_pos_diff(a: MotionResult, b: MotionResult) -> float:
	var m := 0.0
	for i in a.samples.size():
		m = maxf(m, a.samples[i].position.distance_to(b.samples[i].position))
	return m


func ang(v: Vector3) -> float:
	return atan2(v.y, v.x)


func wrap_angle(a: float) -> float:
	return wrapf(a, -PI, PI)


func extreme_params(b: MotionBehavior, high: bool) -> Dictionary:
	var d := {}
	for p in b.params:
		match p.kind:
			MotionParam.Kind.FLOAT:
				d[String(p.name)] = p.max_value if high else p.min_value
			MotionParam.Kind.INT:
				d[String(p.name)] = int(p.max_value if high else p.min_value)
			MotionParam.Kind.BOOL:
				d[String(p.name)] = high
			MotionParam.Kind.VECTOR3:
				d[String(p.name)] = Vector3.ONE * (p.max_value if high else p.min_value)
	return d


# --------------------------------------------------------------------------------------
func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 2: M01–M13 (D-172)")
	print("=================================================================")
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_cat = MotionCatalog.new()
	var reg := MotionBehaviors.register_all(_cat)
	ok(reg.is_empty(), "register_all registra sem diagnóstico")

	t_catalog()
	t_generic()
	t_distinct()
	t_m01()
	t_m02()
	t_m03()
	t_m04()
	t_m05()
	t_m06()
	t_m07()
	t_m08()
	t_m09()
	t_m10()
	t_m11()
	t_m12()
	t_m13()
	t_composition_recipe_part()

	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("\n-- Independência de representação --")
	ok(nodes_after == nodes_before, "nenhum comportamento cria nós (saída é dado puro)")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


# --------------------------------------------------------------------------------------
func t_catalog() -> void:
	print("\n-- Catálogo: metadados --")
	var present := 0
	var meta_ok := true
	for e in ENTRIES:
		var b := _cat.get_behavior(e[0])
		if b == null:
			meta_ok = false
			continue
		present += 1
		if b.version != 1 or b.display_name == "" or b.description == "" or b.group == &"" or b.params.is_empty() or not (e[1] in b.accepted_operations):
			meta_ok = false
	ok(present == 13, "M01–M13 registrados")
	ok(meta_ok, "id, versão, nome, descrição, grupo, parâmetros e operação declarados")
	var miss := _cat.missing_v1()
	ok(miss.size() == 7 and miss[0] == &"M14" and miss[6] == &"M20", "faltam exatamente M14–M20 (sete)")
	ok(not _cat.register(MotionM01Helix.new()).is_empty(), "registrar M01 duas vezes é recusado")


func t_generic() -> void:
	print("\n-- Contrato comum aos 13 --")
	var all_valid := true
	var all_finite := true
	var all_repeat := true
	var all_intensity := true
	var all_pause := true
	var all_ids := true
	var all_extremes := true
	var bad := ""
	for e in ENTRIES:
		var bid: StringName = e[0]
		var op: int = e[1]
		var gen: bool = bid == &"M01" or bid == &"M04"
		var base: Array = [] if gen else helix_base()
		var b := _cat.get_behavior(bid)

		var r := run(bid, op, {}, base, 0.45)
		if r.has_errors() or r.samples.size() != 65:
			all_valid = false
			bad += " valid:" + String(bid)
		if not finite_ok(r):
			all_finite = false

		var r2 := run(bid, op, {}, base, 0.45)
		if max_pos_diff(r, r2) != 0.0:
			all_repeat = false
			bad += " repeat:" + String(bid)

		# intensidade: 0,5 = ponto médio entre a entrada e o efeito pleno
		var in0 := base_only(base, 0.45) if not base.is_empty() else base_only([], 0.45)
		var half := run(bid, op, {}, base, 0.45, 65, 0.5)
		var worst := 0.0
		for i in 65:
			var mid := (in0.samples[i].position + r.samples[i].position) * 0.5
			worst = maxf(worst, half.samples[i].position.distance_to(mid))
		if worst > 1e-4:
			all_intensity = false
			bad += " intens:" + String(bid)

		# pausa: mesmo instante, mesmo resultado; ids de elemento não mudam com o tempo
		var ra := run(bid, op, {}, base, 0.31)
		var rb := run(bid, op, {}, base, 0.31)
		if max_pos_diff(ra, rb) != 0.0:
			all_pause = false
		var rc := run(bid, op, {}, base, 1.7)
		for i in 65:
			if ra.samples[i].element_id != rc.samples[i].element_id:
				all_ids = false

		# limites do domínio (todos no mínimo / todos no máximo), em dois instantes
		for high in [false, true]:
			for tt in [0.37, 29.0]:
				var rx := run(bid, op, extreme_params(b, high), base, tt)
				if not finite_ok(rx):
					all_extremes = false
					bad += " ext(%s,%s):%s" % [high, tt, String(bid)]
					if rx.has_errors():
						bad += " " + str(rx.diagnostics[0])
	ok(all_valid, "parâmetros padrão avaliam sem erro (65 amostras)")
	ok(all_finite, "nenhum valor não finito com os padrões")
	ok(all_extremes, "nenhum valor não finito com todos os parâmetros no mínimo e no máximo do domínio")
	ok(all_repeat, "repetibilidade: mesma entrada, resultado idêntico")
	ok(all_intensity, "intensidade 0,5 = ponto médio entre entrada e efeito pleno")
	ok(all_pause, "pausa: mesmo instante, mesmo resultado")
	ok(all_ids, "ids de elemento independem do tempo")
	if bad != "":
		print("    detalhe:", bad)

	var varying_ok := true
	var static_ok := true
	for e in ENTRIES:
		var gen: bool = e[0] == &"M01" or e[0] == &"M04"
		var base: Array = [] if gen else helix_base()
		var d := max_pos_diff(run(e[0], e[1], {}, base, 0.3), run(e[0], e[1], {}, base, 0.6))
		if e[0] in TIME_VARYING:
			varying_ok = varying_ok and d > 1e-4
		else:
			static_ok = static_ok and d == 0.0
	ok(varying_ok, "M04, M07, M12, M13 evoluem no tempo com os padrões")
	ok(static_ok, "os demais são estáticos com os padrões (tempo só entra se o parâmetro de tempo for usado)")


func t_distinct() -> void:
	print("\n-- Identidade distinguível entre os 13 --")
	var sigs := {}
	for e in ENTRIES:
		sigs[e[0]] = run(e[0], e[1], {}, helix_base(), 0.45)
	var min_d := INF
	var worst_pair := ""
	var ids: Array = sigs.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var d := max_pos_diff(sigs[ids[i]], sigs[ids[j]])
			if d < min_d:
				min_d = d
				worst_pair = "%s×%s" % [ids[i], ids[j]]
	ok(min_d > 1e-3, "78 pares com assinaturas espaciais distintas sobre a mesma entrada (menor diferença %.4f em %s)" % [min_d, worst_pair])


# --------------------------------------------------------------------------------------
func t_m01() -> void:
	print("\n-- M01 Espiral helicoidal --")
	var p := {"radius": 0.4, "radius_growth": 0.2, "pitch": 0.5, "turns": 3.0, "phase_deg": 30.0}
	var r := run(&"M01", Op.REPLACE, p)
	var s := r.samples[32]  # u = 0.5
	var radial := Vector2(s.position.x, s.position.y).length()
	ok(near(radial, 0.4 + 0.2 * 0.5), "distância ao eixo = raio + evolução do raio (%.4f)" % radial)
	ok(near(s.position.z, 0.5 * 0.5 * 3.0), "avanço axial = passo × voltas × u")
	var e := r.samples[64]
	var th := TAU * 3.0 + deg_to_rad(30.0)
	ok(vnear(Vector3(e.position.x, e.position.y, 0), Vector3(0.6 * cos(th), 0.6 * sin(th), 0)), "fase e número de voltas")
	var rm := run(&"M01", Op.REPLACE, {"radius": 0.4, "pitch": 0.5, "turns": 3.0, "direction": -1})
	var rp := run(&"M01", Op.REPLACE, {"radius": 0.4, "pitch": 0.5, "turns": 3.0, "direction": 1})
	ok(near(rm.samples[10].position.y, -rp.samples[10].position.y) and near(rm.samples[10].position.x, rp.samples[10].position.x), "sentido -1 espelha a hélice")
	var rs0 := run(&"M01", Op.REPLACE, {"radius": 0.4, "spin_deg_s": 360.0}, [], 0.0)
	var rs1 := run(&"M01", Op.REPLACE, {"radius": 0.4, "spin_deg_s": 360.0}, [], 0.25)
	ok(near(wrap_angle(ang(rs1.samples[10].position) - ang(rs0.samples[10].position)), PI / 2.0), "rotação temporal: 360°/s por 0,25 s = 90°")
	var r3 := run(&"M01", Op.REPLACE, p, [], 0.0, 101)
	var tg := r3.samples[30].basis.z
	var th3 := TAU * 3.0 * 0.3 + deg_to_rad(30.0)
	var an := Vector3(0.2 * cos(th3) - 0.4 * 0.0 - (0.4 + 0.2 * 0.3) * TAU * 3.0 * sin(th3), 0.2 * sin(th3) + (0.4 + 0.2 * 0.3) * TAU * 3.0 * cos(th3), 1.5).normalized()
	ok(tg.is_normalized() and tg.dot(an) > 0.9999, "tangente (basis.z) coincide com a derivada analítica")
	var rz := run(&"M01", Op.REPLACE, {"radius": 0.0, "radius_growth": 0.0, "pitch": 0.0, "turns": 0.0})
	ok(finite_ok(rz), "hélice degenerada (raio, passo e voltas 0) não gera NaN")


func t_m02() -> void:
	print("\n-- M02 Zigue-zague --")
	var r := run(&"M02", Op.OFFSET, {"amplitude": 0.1, "frequency": 4.0})
	ok(near(r.samples[0].position.x, 0.0) and near(r.samples[4].position.x, 0.1) and near(r.samples[12].position.x, -0.1), "vértices alternam +amplitude / −amplitude")
	ok(near(r.samples[2].position.x, 0.05), "trechos retos: onda triangular (0,05 a meio caminho do vértice)")
	ok(near(r.samples[20].position.x, r.samples[4].position.x), "periódico em 1/frequência (0,25 m)")
	var rs := run(&"M02", Op.OFFSET, {"amplitude": 0.1, "frequency": 4.0, "smoothing": 1.0})
	ok(near(rs.samples[4].position.x, 0.1) and near(rs.samples[2].position.x, 0.1 * sin(TAU * 0.125)), "suavização 1 = senóide; vértices arredondados")
	var rh := run(&"M02", Op.OFFSET, {"amplitude": 0.1, "frequency": 4.0, "smoothing": 0.5})
	ok(near(rh.samples[2].position.x, 0.5 * 0.05 + 0.5 * 0.1 * sin(TAU * 0.125)), "suavização intermediária mistura as duas ondas")
	var ra := run(&"M02", Op.OFFSET, {"amplitude": 0.1, "frequency": 4.0, "axis_deg": 90.0})
	ok(near(ra.samples[4].position.y, 0.1) and near(ra.samples[4].position.x, 0.0, 1e-6), "direção lateral configurável")
	var rp := run(&"M02", Op.OFFSET, {"amplitude": 0.1, "frequency": 4.0, "phase_deg": 90.0})
	ok(near(rp.samples[0].position.x, 0.1), "fase desloca a onda")
	var rv := run(&"M02", Op.OFFSET, {"amplitude": 0.1, "frequency": 4.0, "speed": 1.0}, [], 0.25)
	ok(near(rv.samples[4].position.x, r.samples[0].position.x) , "velocidade: a onda percorre o eixo (0,25 ciclo em 0,25 s)")


func t_m03() -> void:
	print("\n-- M03 Serpentina --")
	var r := run(&"M03", Op.OFFSET, {"amplitude": 0.1, "wavelength": 0.5})
	ok(near(r.samples[8].position.x, 0.1) and near(r.samples[0].position.x, 0.0) and near(r.samples[16].position.x, 0.0, 1e-6), "senóide: pico em λ/4, zero em λ/2")
	ok(near(r.samples[40].position.x, r.samples[8].position.x), "periódica em λ")
	var rc := run(&"M03", Op.OFFSET, {"amplitude": 0.0, "wavelength": 0.5, "curvature": 2.0})
	ok(near(rc.samples[64].position.x, 1.0) and near(rc.samples[32].position.x, 0.25), "curvatura: deslocamento parabólico ½·κ·z²")
	var rv := run(&"M03", Op.OFFSET, {"amplitude": 0.1, "wavelength": 0.5, "speed": 1.0}, [], 0.25)
	ok(near(rv.samples[8].position.x, -0.1), "propagação: meia λ em 0,25 s com 1 m/s")
	var rph := run(&"M03", Op.OFFSET, {"amplitude": 0.1, "wavelength": 0.5, "phase_deg": 90.0})
	ok(near(rph.samples[0].position.x, 0.1), "fase")
	var z := run(&"M02", Op.OFFSET, {"amplitude": 0.1, "frequency": 4.0})
	ok(max_pos_diff(z, run(&"M03", Op.OFFSET, {"amplitude": 0.1, "wavelength": 0.25})) > 0.01, "serpentina ≠ zigue-zague com mesma amplitude e período")


func t_m04() -> void:
	print("\n-- M04 Bézier dinâmica --")
	var P0 := Vector3(0, 0, 0)
	var P1 := Vector3(0.3, 0.2, 0.3)
	var P2 := Vector3(-0.3, 0.1, 0.7)
	var P3 := Vector3(0, 0, 1)
	var p := {"p0": P0, "p1": P1, "p2": P2, "p3": P3, "drift1": Vector3.ZERO, "drift2": Vector3.ZERO}
	var r := run(&"M04", Op.REPLACE, p)
	ok(vnear(r.samples[0].position, P0) and vnear(r.samples[64].position, P3), "extremos nos pontos p0 e p3")
	ok(vnear(r.samples[32].position, (P0 + 3.0 * P1 + 3.0 * P2 + P3) / 8.0), "ponto médio = B(0,5)")
	var pp := p.duplicate()
	pp["progress"] = 0.5
	var rh := run(&"M04", Op.REPLACE, pp)
	ok(vnear(rh.samples[64].position, (P0 + 3.0 * P1 + 3.0 * P2 + P3) / 8.0), "progressão 0,5: a curva é percorrida só até metade")
	var pd := p.duplicate()
	pd["drift1"] = Vector3(0, 0.2, 0)
	pd["drift2"] = Vector3(0, -0.2, 0)
	pd["drift_hz"] = 0.5
	var r0 := run(&"M04", Op.REPLACE, pd, [], 0.0)
	var r1 := run(&"M04", Op.REPLACE, pd, [], 0.5)
	ok(vnear(r0.samples[32].position, r.samples[32].position), "variação temporal nula no instante 0 (sen 0)")
	ok(vnear(r1.samples[32].position - r0.samples[32].position, (3.0 / 8.0) * (pd["drift1"] + pd["drift2"])), "pontos de controle derivam no tempo (B(0,5) desloca 3/8·(d1+d2))")
	ok(vnear(r1.samples[0].position, P0) and vnear(r1.samples[64].position, P3), "extremos permanecem fixos durante a deriva")
	var tg := r.samples[0].basis.z
	ok(tg.dot((P1 - P0).normalized()) > 0.9999, "tangente inicial aponta para p1")
	var rd := run(&"M04", Op.REPLACE, {"p0": Vector3.ONE, "p1": Vector3.ONE, "p2": Vector3.ONE, "p3": Vector3.ONE})
	ok(finite_ok(rd), "curva degenerada (todos os pontos iguais) não gera NaN")


func t_m05() -> void:
	print("\n-- M05 Vórtice --")
	var base := helix_base(0.3)
	var b0 := base_only(base)
	var r := run(&"M05", Op.OFFSET, {"center": Vector3.ZERO, "angular_deg": 90.0, "radius": 1.0, "falloff": 2.0}, base)
	var a := b0.samples[10].position
	var b := r.samples[10].position
	ok(near(Vector2(a.x, a.y).length(), Vector2(b.x, b.y).length()) and near(a.z, b.z), "circulação: preserva a distância ao eixo e a altura")
	var w := pow(1.0 - 0.3, 2.0)
	ok(near(wrap_angle(ang(b) - ang(a)), deg_to_rad(90.0) * w, 2e-3), "ângulo = ângulo_máx × (1 − d/R)^decaimento (%.1f°)" % rad_to_deg(wrap_angle(ang(b) - ang(a))))
	var rf := run(&"M05", Op.OFFSET, {"center": Vector3.ZERO, "angular_deg": 90.0, "radius": 0.2}, base)
	ok(max_pos_diff(rf, b0) == 0.0, "fora do raio de influência: nenhuma alteração")
	var line := run(&"M05", Op.OFFSET, {"center": Vector3(0, 0, 0.5), "angular_deg": 180.0, "radius": 1.0})
	ok(max_pos_diff(line, base_only([])) < 1e-6, "pontos sobre o eixo não se movem")
	var rt0 := run(&"M05", Op.OFFSET, {"angular_deg": 0.0, "angular_speed_deg_s": 90.0, "radius": 1.0}, base, 0.0)
	var rt1 := run(&"M05", Op.OFFSET, {"angular_deg": 0.0, "angular_speed_deg_s": 90.0, "radius": 1.0}, base, 1.0)
	ok(max_pos_diff(rt0, b0) == 0.0 and max_pos_diff(rt1, b0) > 0.01, "velocidade angular: circulação cresce com o tempo")
	var rax := run(&"M05", Op.OFFSET, {"axis": Vector3(1, 0, 0), "center": Vector3.ZERO, "angular_deg": 90.0, "radius": 5.0}, base)
	ok(near(a.x, r.samples[10].position.x, 0.5) and max_pos_diff(rax, r) > 0.01, "eixo configurável")
	var rz := run(&"M05", Op.OFFSET, {"axis": Vector3.ZERO, "angular_deg": 90.0}, base)
	ok(finite_ok(rz), "eixo nulo não gera NaN")


func t_m06() -> void:
	print("\n-- M06 Convergência --")
	var tgt := Vector3(0, 0, 0.5)
	var r := run(&"M06", Op.OFFSET, {"target": tgt, "strength": 1.0, "reach": 2.0})
	var z64 := r.samples[64].position.z
	ok(near(z64, 1.0 - 0.5 * 0.75), "aproxima do alvo: d=0,5, alcance 2 → fração 0,75 (z=%.4f)" % z64)
	ok(near(r.samples[32].position.z, 0.5), "o alvo não se move")
	var rr := run(&"M06", Op.OFFSET, {"target": tgt, "reach": 0.4})
	ok(near(rr.samples[64].position.z, 1.0) and near(rr.samples[0].position.z, 0.0), "fora do alcance: nada acontece")
	var rs := run(&"M06", Op.OFFSET, {"target": tgt, "strength": 0.5, "reach": 2.0})
	ok(near(rs.samples[64].position.z, 1.0 - 0.5 * 0.75 * 0.5), "intensidade de atração escala o deslocamento")
	var rc := run(&"M06", Op.OFFSET, {"target": tgt, "reach": 2.0, "curve": 2.0})
	ok(near(rc.samples[64].position.z, 1.0 - 0.5 * 0.75 * 0.75), "curva de aproximação (expoente 2)")
	var ra := run(&"M06", Op.OFFSET, {"target": tgt, "reach": 2.0, "t_start": 1.0, "t_duration": 0.0}, [], 0.5)
	var rb := run(&"M06", Op.OFFSET, {"target": tgt, "reach": 2.0, "t_start": 1.0, "t_duration": 0.0}, [], 1.5)
	ok(near(ra.samples[64].position.z, 1.0) and near(rb.samples[64].position.z, z64), "início temporal")
	var rd := run(&"M06", Op.OFFSET, {"target": tgt, "reach": 2.0, "t_start": 0.0, "t_duration": 2.0}, [], 1.0)
	ok(near(rd.samples[64].position.z, 1.0 - 0.5 * 0.75 * 0.5), "duração: a meio da transição, metade do efeito")


func t_m07() -> void:
	print("\n-- M07 Turbulência --")
	var p := {"scale": 0.5, "intensity": 0.2, "time_hz": 1.0}
	var r := run(&"M07", Op.OFFSET, p, [], 0.3, 1025)
	var mx := 0.0
	var bounded := true
	var diff := 0.0
	for i in r.samples.size():
		var d := r.samples[i].position - Vector3(0, 0, float(i) / 1024.0)
		mx = maxf(mx, d.length())
		if absf(d.x) > 0.2001 or absf(d.y) > 0.2001 or absf(d.z) > 0.2001:
			bounded = false
		if i > 0:
			var dp := r.samples[i].position - r.samples[i - 1].position - Vector3(0, 0, 1.0 / 1024.0)
			diff = maxf(diff, dp.length())
	ok(bounded, "cada componente limitada pela intensidade")
	ok(mx > 0.06, "campo não trivial (deslocamento máx. %.3f)" % mx)
	ok(diff < 0.004, "contínuo no espaço: vizinhos próximos recebem deslocamentos próximos (salto máx. %.5f)" % diff)
	var r2 := run(&"M07", Op.OFFSET, p, [], 0.3, 1025)
	ok(max_pos_diff(r, r2) == 0.0, "mesma semente, mesmo campo")
	var rs := run(&"M07", Op.OFFSET, {"scale": 0.5, "intensity": 0.2, "time_hz": 1.0, "seed": 5}, [], 0.3, 1025)
	ok(max_pos_diff(r, rs) > 0.01, "semente do parâmetro altera o campo")
	var other := eval_layers([[&"M07", Op.OFFSET, p]], 0.3, 1025, 99)
	ok(max_pos_diff(r, other) > 0.01, "semente da composição altera o campo")
	var rf0 := run(&"M07", Op.OFFSET, {"scale": 0.5, "intensity": 0.2, "time_hz": 0.0}, [], 0.0)
	var rf1 := run(&"M07", Op.OFFSET, {"scale": 0.5, "intensity": 0.2, "time_hz": 0.0}, [], 3.0)
	ok(max_pos_diff(rf0, rf1) == 0.0, "frequência temporal 0: campo estático")
	var rt1 := run(&"M07", Op.OFFSET, p, [], 0.3)
	var rt2 := run(&"M07", Op.OFFSET, p, [], 0.3001)
	ok(max_pos_diff(rt1, rt2) < 0.002, "contínuo no tempo")
	var ri := run(&"M07", Op.OFFSET, {"scale": 0.5, "intensity": 0.0, "time_hz": 1.0}, [], 0.3)
	ok(max_pos_diff(ri, base_only([], 0.3)) == 0.0, "intensidade 0 = sem efeito")
	var rl := run(&"M07", Op.OFFSET, p, [], 1000.0)
	ok(finite_ok(rl), "tempos grandes não degradam")


func t_m08() -> void:
	print("\n-- M08 Torção progressiva --")
	var base := helix_base(0.3)
	var b0 := base_only(base)
	var r := run(&"M08", Op.DEFORM, {"amount_deg": 90.0}, base)
	var a := b0.samples[20].position
	var b := r.samples[20].position
	ok(near(Vector2(a.x, a.y).length(), Vector2(b.x, b.y).length()) and near(a.z, b.z), "gira em torno do eixo: raio e altura preservados")
	ok(near(wrap_angle(ang(b) - ang(a)), PI / 2.0), "quantidade de torção aplicada no platô")
	var rw := run(&"M08", Op.DEFORM, {"amount_deg": 90.0, "center": 0.75, "extent": 0.5}, base)
	ok(vnear(rw.samples[10].position, b0.samples[10].position) and not vnear(rw.samples[56].position, b0.samples[56].position), "só a metade final é torcida")
	var rs := run(&"M08", Op.DEFORM, {"amount_deg": 90.0, "center": 0.75, "extent": 0.5, "softness": 0.2}, base)
	var mid := rs.samples[28].position
	ok(not vnear(mid, b0.samples[28].position) and not vnear(mid, rw.samples[28].position), "suavidade cria transição gradual na borda da região")
	var rt := run(&"M08", Op.DEFORM, {"amount_deg": 90.0, "t_start": 1.0, "t_duration": 1.0}, base, 1.5)
	ok(near(wrap_angle(ang(rt.samples[20].position) - ang(a)), PI / 4.0, 2e-3), "duração temporal: metade do caminho = metade da torção")
	var rb := run(&"M08", Op.DEFORM, {"amount_deg": 90.0, "t_start": 1.0, "t_duration": 1.0}, base, 0.5)
	ok(max_pos_diff(rb, b0) == 0.0, "antes do início temporal: nada")
	var rp := run(&"M08", Op.DEFORM, {"amount_deg": 90.0, "front_speed": 1.0, "front_width": 0.1}, base, 0.5)
	ok(near(wrap_angle(ang(rp.samples[19].position) - ang(b0.samples[19].position)), PI / 2.0, 1e-3), "propagação: atrás da frente (u=0,3) já torceu")
	ok(vnear(rp.samples[45].position, b0.samples[45].position), "propagação: à frente da frente (u=0,7) ainda não")
	var line := run(&"M08", Op.DEFORM, {"amount_deg": 360.0})
	ok(max_pos_diff(line, base_only([])) < 1e-6, "sobre o eixo a torção não altera os pontos (precisa de entrada fora do eixo)")


func t_m09() -> void:
	print("\n-- M09 Curvatura --")
	var b0 := base_only([])
	var r := run(&"M09", Op.DEFORM, {"amount_deg": 90.0})
	ok(vnear(r.samples[64].position, Vector3(0, -1, 0), 2e-3), "ponta final dobra 90° ao redor de X")
	var preserved := true
	for i in 65:
		if not near(r.samples[i].position.length(), b0.samples[i].position.length(), 1e-4):
			preserved = false
	ok(preserved, "rotação: distância à origem preservada")
	ok(vnear(r.samples[32].position, Vector3(0, -0.5 * sin(PI / 4.0), 0.5 * cos(PI / 4.0))), "curvatura progressiva: u=0,5 gira 45° (rampa suave)")
	var rp := run(&"M09", Op.DEFORM, {"amount_deg": 90.0, "plane_deg": 90.0})
	ok(vnear(rp.samples[64].position, Vector3(1, 0, 0), 2e-3), "plano de curvatura configurável")
	var r0 := run(&"M09", Op.DEFORM, {"amount_deg": 0.0})
	ok(max_pos_diff(r0, b0) == 0.0, "quantidade 0 = identidade")
	var rr := run(&"M09", Op.DEFORM, {"amount_deg": 90.0, "center": 0.75, "extent": 0.5})
	ok(vnear(rr.samples[10].position, b0.samples[10].position) and not vnear(rr.samples[60].position, b0.samples[60].position), "região de influência: parte inicial reta")
	ok(r.samples[64].basis.z.dot(Vector3(0, -1, 0)) > 0.99, "a base acompanha a curvatura")


func t_m10() -> void:
	print("\n-- M10 Alongamento --")
	var b0 := base_only([])
	var r := run(&"M10", Op.DEFORM, {"factor": 2.0, "center": 0.5, "extent": 0.5, "reference_length": 1.0})
	ok(vnear(r.samples[8].position, b0.samples[8].position), "antes da região: sem alteração")
	ok(near(r.samples[64].position.z, 1.5) and near(r.samples[60].position.z, b0.samples[60].position.z + 0.25 * 2.0), "depois da região: deslocado por (f−1)·extensão·L")
	var mono := true
	for i in range(1, 65):
		if r.samples[i].position.z <= r.samples[i - 1].position.z:
			mono = false
	ok(mono, "monotônico: o alongamento nunca dobra a trajetória")
	var inside := r.samples[32].position.z
	ok(near(inside, 0.75, 1e-3), "centro da região: metade do deslocamento total (z=%.4f)" % inside)
	var r1 := run(&"M10", Op.DEFORM, {"factor": 1.0})
	ok(max_pos_diff(r1, b0) == 0.0, "fator 1 = identidade")
	var rt := run(&"M10", Op.DEFORM, {"factor": 2.0, "center": 0.5, "extent": 0.5, "t_start": 1.0, "t_duration": 1.0}, [], 1.5)
	ok(near(rt.samples[64].position.z, 1.0 + 0.25), "duração temporal: meio fator no meio da transição")
	var rl := run(&"M10", Op.DEFORM, {"factor": 2.0, "center": 0.5, "extent": 0.5, "reference_length": 2.0})
	ok(near(rl.samples[64].position.z, 1.0 + 0.5 * 2.0), "comprimento de referência escala o deslocamento")


func t_m11() -> void:
	print("\n-- M11 Compressão --")
	var b0 := base_only([])
	var p := {"strength": 0.6, "center": 0.5, "extent": 0.4, "softness": 0.2, "reference_length": 1.0}
	var r := run(&"M11", Op.DEFORM, p)
	ok(vnear(r.samples[0].position, b0.samples[0].position) and vnear(r.samples[64].position, b0.samples[64].position), "extremidades preservadas")
	ok(vnear(r.samples[32].position, b0.samples[32].position), "o centro da região não se move")
	var inside := r.samples[40].position.z
	ok(absf(inside - 0.5) < absf(b0.samples[40].position.z - 0.5), "pontos da região se concentram em direção ao centro")
	ok(near(inside, 0.5 + (40.0 / 64.0 - 0.5) * 0.4, 1e-3), "platô: distância ao centro × (1 − k)")
	var u51 := 51.0 / 64.0
	var w51 := 1.0 - smoothstep(0.2, 0.4, absf(u51 - 0.5))
	ok(near(r.samples[51].position.z, 0.5 + (u51 - 0.5) * (1.0 - 0.6 * w51), 1e-4), "borda suave: a força cai gradualmente fora do platô (w=%.3f)" % w51)
	var strong := p.duplicate()
	strong["strength"] = 0.95
	var rs := run(&"M11", Op.DEFORM, strong)
	var mono := true
	for i in range(1, 65):
		if rs.samples[i].position.z <= rs.samples[i - 1].position.z:
			mono = false
	ok(mono, "monotônico mesmo com força 0,95 (sem dobras)")
	var r0 := run(&"M11", Op.DEFORM, {"strength": 0.0, "radial": 0.0})
	ok(max_pos_diff(r0, b0) == 0.0, "força 0 e radial 0 = identidade")
	var helix := helix_base(0.3)
	var hb := base_only(helix)
	var rr := run(&"M11", Op.DEFORM, {"strength": 0.0, "radial": 1.0, "center": 0.5, "extent": 0.2, "softness": 0.0}, helix)
	var c := rr.samples[32].position
	ok(near(Vector2(c.x, c.y).length(), 0.0, 1e-5) and near(c.z, hb.samples[32].position.z), "compressão radial colapsa a seção transversal no núcleo")
	ok(near(Vector2(rr.samples[0].position.x, rr.samples[0].position.y).length(), 0.3), "fora da região a seção transversal é preservada")
	var rt := run(&"M11", Op.DEFORM, {"strength": 0.6, "center": 0.5, "extent": 0.4, "softness": 0.2, "t_start": 1.0, "t_duration": 1.0}, [], 0.5)
	ok(max_pos_diff(rt, b0) == 0.0, "antes do início temporal: nada")


func t_m12() -> void:
	print("\n-- M12 Pulso viajante --")
	var p := {"speed": 0.5, "start": 0.0, "width": 0.1, "amplitude": 1.0, "thickness_gain": 0.5, "tail": 3.0}
	var r0 := run(&"M12", Op.MULTIPLY_ATTRIBUTE, p, [], 0.4)
	var r1 := run(&"M12", Op.MULTIPLY_ATTRIBUTE, p, [], 1.2)
	var i0 := _argmax_intensity(r0)
	var i1 := _argmax_intensity(r1)
	ok(abs(i0 - 0.2 * 64.0) <= 1.0, "pico em start + velocidade·t (u=0,2 → amostra %d)" % i0)
	ok(abs(i1 - 0.6 * 64.0) <= 1.0, "o pico viaja ao longo do percurso (u=0,6 → amostra %d)" % i1)
	ok(near(r0.samples[i0].intensity, 2.0, 0.05) and near(r0.samples[i0].width, 1.5, 0.03), "amplitude: intensidade 1+A, espessura 1+ganho")
	ok(r0.samples[60].intensity < 1.001 and r0.samples[60].intensity >= 1.0, "longe do pulso: valor neutro")
	var back := r0.samples[i0 - 6].intensity - 1.0
	var ahead := r0.samples[i0 + 6].intensity - 1.0
	ok(back > ahead * 2.0, "perfil de dissipação assimétrico: cauda atrás é maior que a frente")
	var rd := run(&"M12", Op.OFFSET, {"speed": 0.0, "start": 0.5, "width": 0.1, "displace": 0.2}, [], 0.0)
	ok(near(rd.samples[32].position.x, 0.2) and near(rd.samples[60].position.x, 0.0, 1e-3), "deslocamento lateral opcional no pico")
	var ra := run(&"M12", Op.MULTIPLY_ATTRIBUTE, {"amplitude": 0.0}, [], 0.4)
	ok(near(ra.samples[i0].intensity, 1.0, 1e-6) and near(ra.samples[i0].width, 1.5, 0.03), "amplitude 0: intensidade neutra (a espessura segue o próprio ganho)")
	var rl := run(&"M12", Op.MULTIPLY_ATTRIBUTE, {"speed": 1.0, "start": 0.0, "width": 0.05, "loop": true}, [], 1.3)
	ok(abs(_argmax_intensity(rl) - 0.3 * 64.0) <= 1.0, "laço: o pulso reaparece em u = fposmod(c, 1)")
	var rn := run(&"M12", Op.MULTIPLY_ATTRIBUTE, {"speed": 1.0, "start": 0.0, "width": 0.05, "loop": false}, [], 1.3)
	ok(rn.samples[_argmax_intensity(rn)].intensity < 1.6, "sem laço: o pulso sai do percurso")
	var rr := run(&"M12", Op.MULTIPLY_ATTRIBUTE, {"speed": 0.0, "start": 0.5, "width": 0.2, "ripples": 2.0}, [], 0.0)
	var neg := false
	for s in rr.samples:
		if s.intensity < 1.0:
			neg = true
	ok(neg, "frequência (ondulações) produz lóbulos negativos")


func _argmax_intensity(r: MotionResult) -> int:
	var best := 0
	for i in r.samples.size():
		if r.samples[i].intensity > r.samples[best].intensity:
			best = i
	return best


func t_m13() -> void:
	print("\n-- M13 Onda radial --")
	var base := helix_base(0.0, 0.8)  # raio cresce de 0 a 0,8 ao longo do percurso
	var b0 := base_only(base)
	var p := {"speed": 1.0, "width": 0.05, "amplitude": 0.1, "range": 2.0}
	var r := run(&"M13", Op.OFFSET, p, base, 0.4)
	var best := 0
	for i in 65:
		if absf(r.samples[i].position.z - b0.samples[i].position.z) > absf(r.samples[best].position.z - b0.samples[best].position.z):
			best = i
	ok(abs(best - 32) <= 1, "o pico fica na frente da onda: raio 0,4 = amostra 32 (obtido %d)" % best)
	ok(near(r.samples[32].position.z - b0.samples[32].position.z, 0.1 * (1.0 - 0.4 / 2.0), 1e-3), "amplitude × dissipação linear até o alcance (0,08)")
	ok(near(r.samples[5].position.z, b0.samples[5].position.z, 1e-3) and near(r.samples[60].position.z, b0.samples[60].position.z, 1e-3), "antes e depois da frente: sem alteração")
	var rf := run(&"M13", Op.OFFSET, p, base, 2.5)
	ok(max_pos_diff(rf, b0) == 0.0, "além do alcance: onda dissipada")
	var rd := run(&"M13", Op.OFFSET, {"speed": 1.0, "width": 0.05, "amplitude": 0.1, "range": 2.0, "dissipation": 0.0}, base, 0.4)
	ok(near(rd.samples[32].position.z - b0.samples[32].position.z, 0.1, 1e-3), "dissipação 0: amplitude constante")
	var rg := run(&"M13", Op.MULTIPLY_ATTRIBUTE, {"speed": 1.0, "width": 0.05, "amplitude": 0.0, "intensity_gain": 2.0, "range": 2.0, "dissipation": 0.0}, base, 0.4)
	ok(near(rg.samples[32].intensity, 3.0, 1e-3) and near(rg.samples[5].intensity, 1.0, 1e-3), "ganho de intensidade na frente")
	var rn := run(&"M13", Op.OFFSET, {"speed": 1.0, "width": 0.05, "amplitude": 0.1, "range": 2.0, "plane_normal": Vector3(1, 0, 0)}, base, 0.4)
	var mdx := 0.0
	var mdz := 0.0
	for i in 65:
		mdx = maxf(mdx, absf(rn.samples[i].position.x - b0.samples[i].position.x))
		mdz = maxf(mdz, absf(rn.samples[i].position.z - b0.samples[i].position.z))
	ok(mdx > 0.02 and mdz < 1e-6, "normal do plano configurável: deslocamento só ao longo da normal (máx. dx=%.3f)" % mdx)
	var rz := run(&"M13", Op.OFFSET, {"plane_normal": Vector3.ZERO}, base, 0.4)
	ok(finite_ok(rz), "normal nula não gera NaN")
	var rr := run(&"M13", Op.OFFSET, {"speed": 1.0, "width": 0.1, "amplitude": 0.1, "range": 2.0, "ripples": 1.0}, base, 0.4)
	var neg := false
	for i in 65:
		if (rr.samples[i].position.z - b0.samples[i].position.z) < -1e-4:
			neg = true
	ok(neg, "ondulações (frequência) produzem lóbulos de sinal oposto")


func t_composition_recipe_part() -> void:
	print("\n-- Composição: combinar comportamentos da Etapa 2 --")
	# hélice → torção → turbulência → vórtice, tudo pela biblioteca, sem trajetória manual
	var layers := [
		[&"M01", Op.REPLACE, {"radius": 0.25, "pitch": 0.5, "turns": 3.0}],
		[&"M08", Op.DEFORM, {"amount_deg": 180.0, "front_speed": 1.0}],
		[&"M07", Op.OFFSET, {"intensity": 0.05, "scale": 0.3}],
		[&"M05", Op.OFFSET, {"center": Vector3(0, 0, 0.75), "angular_deg": 45.0, "radius": 1.0}],
	]
	var r := eval_layers(layers, 0.6)
	ok(finite_ok(r) and r.samples.size() == 65, "quatro comportamentos encadeados avaliam sem erro")
	var swapped := [layers[0], layers[2], layers[1], layers[3]]
	ok(max_pos_diff(r, eval_layers(swapped, 0.6)) > 1e-3, "trocar a ordem (torção ↔ turbulência) muda o resultado")
	ok(max_pos_diff(r, eval_layers(layers, 0.6)) == 0.0, "composição reproduzível")
