extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 2: representação Fitas (D-044, D-305).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_fitas.gd
## Testa a geometria das fitas como dado puro (agrupamento, ordem, base estável, atributos).

const Op := MotionTypes.Op
const HELIX := {"radius": 0.3, "pitch": 0.5, "turns": 1.0, "spin_deg_s": 360.0}

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


func near(a: float, b: float, eps: float = 1e-5) -> bool:
	return absf(a - b) <= eps


func vnear(a: Vector3, b: Vector3, eps: float = 1e-5) -> bool:
	return a.distance_to(b) <= eps


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


func build(extra: Array, n: int = 16) -> MotionComposition:
	var c := MotionComposition.new()
	c.sample_count = n
	c.seed = 7
	c.add_layer(make_layer(&"L0", &"M01", Op.REPLACE, HELIX))
	var i := 1
	for e in extra:
		c.add_layer(make_layer(StringName("L%d" % i), e[0], e[1], e[2]))
		i += 1
	return c


func samples_at(c: MotionComposition, t: float) -> Array[MotionSample]:
	return c.evaluate(_cat, c.make_context(t)).samples


func mk(u: float, pos: Vector3, branch: String = "root", age: float = 0.0, id: int = 0) -> MotionSample:
	var s := MotionSample.make_rest(u, id, 1.0)
	s.position = pos
	s.branch = branch
	s.age = age
	s.element_id = id
	return s


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 2): FITAS (D-305)")
	print("=================================================================")
	_cat = MotionCatalog.new()
	MotionBehaviors.register_all(_cat)
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	t_strips()
	t_geometry()
	t_frame()
	t_attributes()
	t_view()
	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "o construtor de fitas não cria nós")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


# --------------------------------------------------------------------------------------
func t_strips() -> void:
	print("\n-- Agrupamento e ordem das fitas --")
	var flow := MotionRibbonBuilder.strips(samples_at(build([]), 1.0))
	ok(flow.size() == 1 and flow[0].size() == 16, "fluxo simples: 1 fita de 16 pontos")
	var asc := true
	for i in range(1, flow[0].size()):
		if flow[0][i].u < flow[0][i - 1].u:
			asc = false
	ok(asc, "fita de estado ordenada por u")

	var trail := MotionRibbonBuilder.strips(samples_at(build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05}]]), 1.0))
	ok(trail.size() == 1 + 16, "hélice + rastro: a fita do fluxo + 1 fita de rastro por elemento (17)")
	var history_strips := []
	for st in trail:
		if st.size() == 11:
			history_strips.append(st)
	ok(history_strips.size() == 16, "cada rastro tem 11 pontos: a cabeça atual + 10 idades")
	var by_age := true
	var head_ok := true
	for st in history_strips:
		if st[0].age != 0.0:
			head_ok = false
		for i in range(1, st.size()):
			if st[i].age <= st[i - 1].age:
				by_age = false
	ok(by_age, "rastro ordenado por idade crescente")
	ok(head_ok, "a cabeça do rastro é a amostra atual do mesmo elemento (a fita não tem vão)")
	var same_u := true
	for st in history_strips:
		for p in st:
			if not near(p.u, st[0].u, 1e-9):
				same_u = false
	ok(same_u, "todos os pontos de um rastro pertencem ao mesmo elemento")

	var br := MotionRibbonBuilder.strips(samples_at(build([[&"M14", Op.BRANCH, {"branches": 3}]]), 1.0))
	ok(br.size() == 3 and br[0].size() == 16, "bifurcação em 3: 3 fitas, uma por ramo")

	var ai := MotionRibbonBuilder.strips(samples_at(build([[&"M20", Op.PERSIST, {"count": 4, "interval": 0.1}]]), 1.0))
	ok(ai.size() == 1 + 4, "pós-imagem: a fita do fluxo + uma fita por estado discreto (5)")
	var ai_ok := true
	for st in ai:
		for p in st:
			if not near(p.age, st[0].age, 1e-9):
				ai_ok = false
	ok(ai_ok, "cada fita de pós-imagem tem uma única idade (estado discreto)")
	# a ordem de entrada não importa: as fitas se ordenam sozinhas
	var shuffled: Array[MotionSample] = []
	var all_s := samples_at(build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05}]]), 1.0)
	for i in range(all_s.size() - 1, -1, -1):
		shuffled.append(all_s[i])
	var rs := MotionRibbonBuilder.strips(shuffled)
	var ord_ok := rs.size() == 17
	for st in rs:
		for i in range(1, st.size()):
			if st[i].age == 0.0 and st[i - 1].age == 0.0:
				ord_ok = ord_ok and st[i].u >= st[i - 1].u
			else:
				ord_ok = ord_ok and st[i].age > st[i - 1].age
	ok(ord_ok, "entrada em ordem inversa: fita de estado ordenada por u e rastros por idade")
	ok(MotionRibbonBuilder.strips([]).is_empty(), "sem amostras, sem fitas")
	ok(MotionRibbonBuilder.strips([mk(0.0, Vector3.ZERO)]).is_empty(), "uma amostra sozinha não forma fita")
	var a := MotionRibbonBuilder.strips(samples_at(build([[&"M19", Op.PERSIST, {}]]), 1.0))
	var b := MotionRibbonBuilder.strips(samples_at(build([[&"M19", Op.PERSIST, {}]]), 1.0))
	var same := a.size() == b.size()
	for i in a.size():
		for j in a[i].size():
			if a[i][j].element_id != b[i][j].element_id:
				same = false
	ok(same, "agrupamento determinístico")


func t_geometry() -> void:
	print("\n-- Geometria --")
	var s := samples_at(build([]), 1.0)
	var g := MotionRibbonBuilder.build(s, 0.05)
	ok(g["vertices"].size() == 2 * 16 and g["colors"].size() == 32 and g["uvs"].size() == 32, "2 vértices, 1 cor e 1 UV por ponto")
	ok(g["indices"].size() == 3 * 2 * 15 and g["triangle_count"] == 30, "2 triângulos por segmento (15 segmentos)")
	ok(g["strip_count"] == 1, "uma fita")
	var in_range := true
	for i in g["indices"]:
		if i < 0 or i >= g["vertices"].size():
			in_range = false
	ok(in_range, "índices dentro do intervalo")
	ok(near(g["uvs"][0].x, 0.0) and near(g["uvs"][30].x, 1.0) and g["uvs"][0].y == 0.0 and g["uvs"][1].y == 1.0, "UV: x = progresso ao longo da fita, y = 0/1 através")
	var box: AABB = g["aabb"]
	var inside := true
	for v in g["vertices"]:
		if not box.grow(1e-4).has_point(v):
			inside = false
	ok(inside, "a AABB engloba todos os vértices (limites de visibilidade acompanham a deformação)")
	var g2 := MotionRibbonBuilder.build(s, 0.05)
	ok(g["vertices"] == g2["vertices"] and g["indices"] == g2["indices"] and g["colors"] == g2["colors"], "mesma entrada, mesma geometria")
	ok(MotionRibbonBuilder.build([], 0.05)["vertices"].is_empty(), "sem amostras, geometria vazia")

	# antes do nascimento: segmentos com as duas pontas ocultas são omitidos
	var c := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05}]])
	var early := MotionRibbonBuilder.build(samples_at(c, 0.2), 0.05)
	var late := MotionRibbonBuilder.build(samples_at(c, 1.0), 0.05)
	ok(early["triangle_count"] < late["triangle_count"], "histórico anterior ao nascimento não gera triângulos (%d < %d)" % [early["triangle_count"], late["triangle_count"]])
	# o último segmento do rastro (opacidade chega a 0) ainda é desenhado: a ponta some por alfa, não é cortada
	var tail: int = late["triangle_count"]
	ok(tail == 2 * 15 + 16 * 2 * 10, "rastro completo: 15 segmentos do fluxo + 16 rastros de 10 segmentos (%d triângulos)" % tail)


func t_frame() -> void:
	print("\n-- Base estável (§19.4) --")
	# linha reta ao longo de +Z com basis.x = +X: o lado é constante
	var line: Array[MotionSample] = []
	for i in 6:
		line.append(mk(float(i) / 5.0, Vector3(0, 0, float(i) * 0.2), "root", 0.0, i))
	var g := MotionRibbonBuilder.build(line, 0.1)
	var side_ok := true
	for i in 6:
		var d: Vector3 = g["vertices"][2 * i + 1] - g["vertices"][2 * i]
		if not vnear(d, Vector3(0.1, 0, 0), 1e-5):
			side_ok = false
	ok(side_ok, "trajetória reta: a largura fica constante e alinhada à base da primeira amostra")

	# inversão de 180°: sem NaN, largura preservada, lado perpendicular à tangente local
	var rev: Array[MotionSample] = []
	var pts := [Vector3(0, 0, 0), Vector3(0, 0, 0.5), Vector3(0, 0, 1.0), Vector3(0, 0, 0.5), Vector3(0, 0, 0.0)]
	for i in pts.size():
		rev.append(mk(float(i) / 4.0, pts[i], "root", 0.0, i))
	var gr := MotionRibbonBuilder.build(rev, 0.1)
	var finite := true
	var width_ok := true
	for i in pts.size():
		var l: Vector3 = gr["vertices"][2 * i]
		var r: Vector3 = gr["vertices"][2 * i + 1]
		if not (l.is_finite() and r.is_finite()):
			finite = false
		elif not near(l.distance_to(r), 0.1, 1e-4):
			width_ok = false
	ok(finite and width_ok, "inversão brusca de direção (180°): geometria finita e largura preservada")

	# pontos coincidentes (tangente nula) reaproveitam a tangente anterior
	var dup: Array[MotionSample] = []
	for i in 5:
		dup.append(mk(float(i) / 4.0, Vector3(0, 0, 0.0 if i < 3 else float(i - 2) * 0.3), "root", 0.0, i))
	var gd := MotionRibbonBuilder.build(dup, 0.1)
	var ok_dup: bool = not gd["vertices"].is_empty()
	for v in gd["vertices"]:
		if not v.is_finite():
			ok_dup = false
	ok(ok_dup, "pontos coincidentes (tangente quase nula) não geram NaN")
	var allsame: Array[MotionSample] = []
	for i in 4:
		allsame.append(mk(float(i) / 3.0, Vector3(1, 1, 1), "root", 0.0, i))
	ok(MotionRibbonBuilder.build(allsame, 0.1)["vertices"].is_empty(), "fita degenerada (todos os pontos iguais) é descartada")

	# hélice: lado sempre perpendicular à tangente, comprimento da seção constante
	var hel := samples_at(build([], 64), 0.5)
	var gh := MotionRibbonBuilder.build(hel, 0.04)
	var perp := true
	for i in range(1, 63):
		var t: Vector3 = (hel[i + 1].position - hel[i - 1].position).normalized()
		var side: Vector3 = (gh["vertices"][2 * i + 1] - gh["vertices"][2 * i]).normalized()
		if absf(t.dot(side)) > 0.02:
			perp = false
	ok(perp, "hélice: o lado da fita é perpendicular à tangente em todos os pontos")
	var continuous := true
	for i in range(1, 64):
		var s0: Vector3 = (gh["vertices"][2 * i - 1] - gh["vertices"][2 * i - 2]).normalized()
		var s1: Vector3 = (gh["vertices"][2 * i + 1] - gh["vertices"][2 * i]).normalized()
		if s0.dot(s1) < 0.9:
			continuous = false
	ok(continuous, "hélice: a base gira sem saltos entre pontos vizinhos (sem torção bruta)")


func t_attributes() -> void:
	print("\n-- Atributos por ponto --")
	var s: Array[MotionSample] = []
	for i in 4:
		var p := mk(float(i) / 3.0, Vector3(0, 0, float(i) * 0.3), "root", 0.0, i)
		p.width = [1.0, 0.5, 0.0, 2.0][i]
		p.opacity = [1.0, 0.5, 0.0, 1.0][i]
		p.intensity = [1.0, 0.5, 1.0, 1.0][i]
		s.append(p)
	var g := MotionRibbonBuilder.build(s, 0.1)
	var w0: float = g["vertices"][0].distance_to(g["vertices"][1])
	var w1: float = g["vertices"][2].distance_to(g["vertices"][3])
	var w2: float = g["vertices"][4].distance_to(g["vertices"][5])
	var w3: float = g["vertices"][6].distance_to(g["vertices"][7])
	ok(near(w0, 0.1) and near(w1, 0.05) and near(w2, 0.0) and near(w3, 0.2), "largura = largura-base × largura da amostra (afinar até zero e engrossar)")
	ok(near(g["colors"][0].a, 1.0) and near(g["colors"][2].a, 0.5) and near(g["colors"][4].a, 0.0), "alfa do vértice = opacidade da amostra")
	var c0: Color = g["colors"][0]
	var c1: Color = g["colors"][2]
	ok(near(c1.r, c0.r * 0.5, 1e-4), "brilho do vértice proporcional à intensidade")
	ok(g["colors"][0] == g["colors"][1], "os dois lados do mesmo ponto têm a mesma cor")
	var branches := MotionRibbonBuilder.build(samples_at(build([[&"M14", Op.BRANCH, {"branches": 3}]]), 1.0), 0.05)
	var distinct := {}
	for i in range(0, branches["colors"].size(), 32):
		distinct[(branches["colors"][i] as Color).to_html(false)] = true
	ok(distinct.size() == 3, "cada ramo tem a sua cor (3)")
	var inv: Array[MotionSample] = [mk(0.0, Vector3.ZERO, "root", 0.0, 0), mk(1.0, Vector3(0, 0, 1), "root", 0.0, 1)]
	inv[1].visible = false
	var ginv := MotionRibbonBuilder.build(inv, 0.1)
	ok(near(ginv["colors"][0].a, 1.0) and near(ginv["colors"][2].a, 0.0), "amostra invisível vira alfa 0 no vértice, mesmo com opacidade 1")
	var hidden := mk(0.0, Vector3.ZERO, "root", 0.0, 0)
	hidden.visible = false
	var p2 := mk(1.0, Vector3(0, 0, 1), "root", 0.0, 1)
	p2.visible = false
	var gh := MotionRibbonBuilder.build([hidden, p2] as Array[MotionSample], 0.1)
	ok(gh["triangle_count"] == 0, "pontos invisíveis não geram triângulos")


func t_view() -> void:
	print("\n-- Representação (nó + shader) --")
	var view := MotionRibbonsView.new()
	root.add_child(view)
	view.show_samples(samples_at(build([[&"M19", Op.PERSIST, {}]]), 1.0))
	ok(view.triangle_count > 0 and view.strip_count == 17, "a vista mostra 17 fitas (%d triângulos)" % view.triangle_count)
	var mi := view.get_child(0) as MeshInstance3D
	var mat := mi.material_override as ShaderMaterial
	ok(mi != null and mat != null and mat.shader != null and mat.shader.resource_path.ends_with(".gdshader") and mat.shader.code.contains("shader_type spatial"), "usa MeshInstance3D com ArrayMesh e ShaderMaterial .gdshader (spatial), sem HTML")
	ok(mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).get_surface_count() == 1, "uma superfície única reconstruída por quadro")
	ok(mi.custom_aabb.size.length() > 0.0, "AABB própria definida (a fita não some por corte de visibilidade)")
	view.show_samples([] as Array[MotionSample])
	ok(view.triangle_count == 0 and (mi.mesh as ArrayMesh).get_surface_count() == 0, "sem amostras, a malha é esvaziada")
	var t0 := Time.get_ticks_usec()
	var big := samples_at(build([[&"M19", Op.PERSIST, {}]], 64), 1.0)
	for i in 20:
		MotionRibbonBuilder.build(big, 0.03)
	print("  [INFO] construção das fitas (%d amostras): %.2f ms por quadro (GDScript, headless)" % [big.size(), float(Time.get_ticks_usec() - t0) / 20.0 / 1000.0])
	view.queue_free()
