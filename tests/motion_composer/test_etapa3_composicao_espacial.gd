extends SceneTree
## Motion Composer V1 — Etapa 3: bifurcação, recombinação, ordem, máscaras e defasagens (D-303).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa3_composicao_espacial.gd

const Op := MotionTypes.Op

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


func vnear(a: Vector3, b: Vector3, eps: float = 1e-4) -> bool:
	return a.distance_to(b) <= eps


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}, offset: float = 0.0) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	l.time_offset = offset
	return l


## specs: [[bid, op, params], ...] — camadas "L0", "L1", ...
func eval_specs(specs: Array, t: float = 0.0, n: int = 65, seed_v: int = 7) -> MotionResult:
	var c := MotionComposition.new()
	c.id = &"t"
	c.sample_count = n
	c.seed = seed_v
	var i := 0
	for s in specs:
		c.add_layer(make_layer(StringName("L%d" % i), s[0], s[1], s[2]))
		i += 1
	return c.evaluate(_cat, c.make_context(t))


func finite_ok(r: MotionResult) -> bool:
	if r.has_errors():
		return false
	for s in r.samples:
		if not s.is_finite_sample():
			return false
	return true


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


func ids_of(r: MotionResult) -> Array:
	var out := []
	for s in r.samples:
		out.append(s.element_id)
	return out


func same_result(a: MotionResult, b: MotionResult) -> bool:
	if a.samples.size() != b.samples.size():
		return false
	for i in a.samples.size():
		var x := a.samples[i]
		var y := b.samples[i]
		if x.position != y.position or x.width != y.width or x.intensity != y.intensity or x.element_id != y.element_id or x.branch != y.branch or x.visible != y.visible:
			return false
	return true


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 3: M14, M15 + COMPOSIÇÃO (D-303)")
	print("=================================================================")
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_cat = MotionCatalog.new()
	ok(MotionBehaviors.register_all(_cat).is_empty(), "register_all registra M01–M18 sem diagnóstico")

	t_catalog()
	t_inplace()
	t_m14()
	t_m15()
	t_order_masks_offsets()
	t_guards()
	t_recipe()

	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "nenhum comportamento cria nós")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


# --------------------------------------------------------------------------------------
func t_catalog() -> void:
	print("\n-- Catálogo --")
	var a := _cat.get_behavior(&"M14")
	var b := _cat.get_behavior(&"M15")
	ok(a != null and b != null and a.kind == MotionTypes.Kind.TOPOLOGY and b.kind == MotionTypes.Kind.TOPOLOGY, "M14 e M15 registrados como TOPOLOGY")
	ok(a.accepted_operations == [Op.BRANCH] and b.accepted_operations == [Op.MERGE], "M14 aceita BRANCH; M15 aceita MERGE")
	ok(_cat.missing_v1().is_empty(), "catálogo V1 completo (%s)" % [_cat.missing_v1()])
	ok(a.output_count(10, a.resolve_params({})) == 30 and b.output_count(10, b.resolve_params({})) == 10, "output_count: M14 multiplica pela quantidade; M15 preserva")
	var c := MotionComposition.new()
	c.add_layer(make_layer(&"X", &"M14", Op.REPLACE))
	ok(not c.validate(_cat).is_empty(), "M14 recusa REPLACE")


func t_inplace() -> void:
	print("\n-- Refinamento do compositor: topologia de mesma contagem preserva a ordem --")
	var r := eval_specs([[&"M14", Op.BRANCH, {"branches": 1, "distance": 0.2}]])
	var base := eval_specs([])
	ok(r.samples.size() == 65 and ids_of(r) != ids_of(base), "um ramo: mesma contagem, ids derivados")
	var in_order := true
	for i in 65:
		if r.samples[i].u != base.samples[i].u:
			in_order = false
	ok(in_order, "um ramo: a ordem das amostras (por u) é preservada")
	ok(r.samples[10].branch == "root/L0.0", "um ramo recebe o caminho 'root/L0.0'")


# --------------------------------------------------------------------------------------
func t_m14() -> void:
	print("\n-- M14 Bifurcação --")
	var p := {"branches": 3, "split_u": 0.4, "angle_deg": 45.0, "distance": 0.5}
	var r := eval_specs([[&"M14", Op.BRANCH, p]])
	var base := eval_specs([])
	ok(not r.has_errors() and r.samples.size() == 195, "3 ramos: 65 × 3 amostras")
	var uniq := {}
	var branches := {}
	for s in r.samples:
		uniq[s.element_id] = true
		branches[s.branch] = true
	ok(uniq.size() == 195, "ids de elemento únicos")
	ok(branches.size() == 3 and branches.has("root/L0.0") and branches.has("root/L0.2"), "caminhos de ramo estáveis (camada.índice)")

	# antes do ponto de separação todos os ramos coincidem com a entrada
	var same_before := true
	for k in 20:  # u <= 0.3125
		for i in 3:
			if r.samples[k * 3 + i].position != base.samples[k].position:
				same_before = false
	ok(same_before, "antes do ponto de separação os ramos coincidem com o fluxo de origem")

	# depois: abertura limitada por tanh e distribuição uniforme em torno do eixo
	var k_end := 64
	var lat_expect := 0.5 * tanh(tan(deg_to_rad(45.0)) * 0.6 / 0.5)
	var ok_lat := true
	var a0 := r.samples[k_end * 3].position - base.samples[k_end].position
	for i in 3:
		var d := r.samples[k_end * 3 + i].position - base.samples[k_end].position
		if not near(Vector2(d.x, d.y).length(), lat_expect, 1e-4) or absf(d.z) > 1e-6:
			ok_lat = false
	ok(ok_lat, "afastamento lateral = distância·tanh(tan(ângulo)·Δz/distância) (%.4f)" % lat_expect)
	var a1 := r.samples[k_end * 3 + 1].position - base.samples[k_end].position
	ok(near(rad_to_deg(Vector2(a0.x, a0.y).angle_to(Vector2(a1.x, a1.y))), 120.0, 0.01), "3 ramos a 120° entre si")
	var sum := Vector3.ZERO
	for i in 3:
		sum += r.samples[k_end * 3 + i].position - base.samples[k_end].position
	ok(sum.length() < 1e-5, "o centroide dos ramos permanece no fluxo de origem")
	var k_small := 26  # u=0.40625
	var d_small := r.samples[k_small * 3].position - base.samples[k_small].position
	ok(near(d_small.length(), 0.5 * tanh(0.00625 / 0.5), 1e-5), "perto do ponto de separação o afastamento é ≈ tan(ângulo)·Δz")

	var r0 := eval_specs([[&"M14", Op.BRANCH, {"branches": 3, "angle_deg": 0.0}]])
	var zero := true
	for k in 65:
		for i in 3:
			if r0.samples[k * 3 + i].position != base.samples[k].position:
				zero = false
	ok(zero, "ângulo 0: ramos coincidentes (mas identificados)")

	var ri := eval_specs([[&"M14", Op.BRANCH, {"branches": 3, "split_u": 0.4, "angle_deg": 45.0, "distance": 0.5, "intensity": 0.5}]])
	ok(near((ri.samples[k_end * 3].position - base.samples[k_end].position).length(), lat_expect * 0.5, 1e-4), "intensidade escala a abertura")

	var rp := eval_specs([[&"M14", Op.BRANCH, {"branches": 3, "split_u": 0.4, "angle_deg": 45.0, "distance": 0.5, "phase_deg": 90.0}]])
	var dp := rp.samples[k_end * 3].position - base.samples[k_end].position
	ok(near(dp.x, 0.0, 1e-5) and dp.y > 0.0, "fase gira a distribuição (ramo 0 em +Y com 90°)")

	var r2 := eval_specs([[&"M14", Op.BRANCH, {"branches": 2, "split_u": 0.4, "angle_deg": 45.0, "distance": 0.5}]])
	var o0 := r2.samples[k_end * 2].position - base.samples[k_end].position
	var o1 := r2.samples[k_end * 2 + 1].position - base.samples[k_end].position
	ok(vnear(o0, -o1, 1e-5), "2 ramos opostos")

	var rt := eval_specs([[&"M14", Op.BRANCH, {"branches": 3, "split_u": 0.4, "angle_deg": 45.0, "distance": 0.5, "t_start": 1.0, "t_duration": 1.0}]], 1.5)
	ok(near((rt.samples[k_end * 3].position - base.samples[k_end].position).length(), lat_expect * 0.5, 1e-4), "abertura temporal: metade no meio da transição")
	var rt0 := eval_specs([[&"M14", Op.BRANCH, {"branches": 3, "t_start": 1.0, "t_duration": 1.0}]], 0.5)
	ok(rt0.samples.size() == 195 and rt0.samples[k_end * 3].position == base.samples[k_end].position, "antes do início temporal os ramos já existem, fechados")

	var nested := eval_specs([[&"M14", Op.BRANCH, {"branches": 3}], [&"M14", Op.BRANCH, {"branches": 2}]])
	var has_path := false
	for s in nested.samples:
		if s.branch == "root/L0.2/L1.1":
			has_path = true
	ok(nested.samples.size() == 390 and has_path, "bifurcação aninhada: 65 × 3 × 2 e caminho 'root/L0.2/L1.1'")

	# a segunda bifurcação só nos filhos do ramo 1
	var c := MotionComposition.new()
	c.sample_count = 17
	c.add_layer(make_layer(&"A", &"M14", Op.BRANCH, {"branches": 3}))
	var lb := make_layer(&"B", &"M14", Op.BRANCH, {"branches": 2})
	lb.branches = PackedStringArray(["root/A.1"])
	c.add_layer(lb)
	var rs := c.evaluate(_cat, c.make_context(0.0))
	var cnt1 := 0
	var cnt0 := 0
	for s in rs.samples:
		if s.branch.begins_with("root/A.1/"):
			cnt1 += 1
		elif s.branch == "root/A.0":
			cnt0 += 1
	ok(rs.samples.size() == 17 * 4 and cnt1 == 34 and cnt0 == 17, "seleção por ramo: só os filhos de root/A.1 se dividem (17×(1+1+2))")

	var a1_ids := ids_of(eval_specs([[&"M14", Op.BRANCH, {"branches": 3}]], 0.2))
	var a2_ids := ids_of(eval_specs([[&"M14", Op.BRANCH, {"branches": 3}]], 2.9))
	ok(a1_ids == a2_ids, "ids estáveis no tempo")
	var rr := eval_specs([[&"M14", Op.BRANCH, p]], 0.3)
	ok(same_result(rr, eval_specs([[&"M14", Op.BRANCH, p]], 0.3)), "repetibilidade")

	var b := _cat.get_behavior(&"M14")
	var ext := true
	for high in [false, true]:
		for tt in [0.37, 29.0]:
			var re := eval_specs([[&"M14", Op.BRANCH, extreme_params(b, high)]], tt)
			if not finite_ok(re):
				ext = false
	ok(ext, "domínio no mínimo e no máximo: nenhum valor não finito")


func t_m15() -> void:
	print("\n-- M15 Recombinação --")
	var bp := {"branches": 3, "split_u": 0.4, "angle_deg": 45.0, "distance": 0.5}
	var before := eval_specs([[&"M14", Op.BRANCH, bp]])
	var base := eval_specs([])
	var mp := {"merge_start": 0.6, "merge_end": 0.9}
	var r := eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, mp]])
	ok(not r.has_errors() and r.samples.size() == 195, "recombinar preserva a quantidade de amostras")
	ok(ids_of(r) == ids_of(before), "identidades e ordem preservadas (nenhuma fusão destrutiva)")
	var same_branches := true
	for i in 195:
		if r.samples[i].branch != before.samples[i].branch:
			same_branches = false
	ok(same_branches, "caminhos de ramo preservados")

	var untouched := true
	for k in range(0, 38):  # u < 0.6
		for i in 3:
			if r.samples[k * 3 + i].position != before.samples[k * 3 + i].position:
				untouched = false
	ok(untouched, "antes do ponto de reunião nada muda")

	var coincide := true
	for k in range(58, 65):  # u >= 0.906
		var p0 := r.samples[k * 3].position
		for i in 1:
			pass
		if not (vnear(p0, r.samples[k * 3 + 1].position, 1e-5) and vnear(p0, r.samples[k * 3 + 2].position, 1e-5) and vnear(p0, base.samples[k].position, 1e-5)):
			coincide = false
	ok(coincide, "após o ponto de reunião os ramos coincidem no centroide (= fluxo de origem)")

	var k_mid := 48  # u = 0.75 → peso 0,5
	var w_mid := smoothstep(0.6, 0.9, 0.75)
	var p_mid := r.samples[k_mid * 3].position
	var b_mid := before.samples[k_mid * 3].position
	var c_mid := base.samples[k_mid].position
	ok(vnear(p_mid, b_mid.lerp(c_mid, w_mid), 1e-5), "convergência suave: posição = lerp(ramo, centroide, smoothstep) (w=%.2f)" % w_mid)

	var k45 := 45
	var w45 := smoothstep(0.6, 0.9, float(k45) / 64.0)
	ok(vnear(r.samples[k45 * 3].position, before.samples[k45 * 3].position.lerp(base.samples[k45].position, w45), 1e-5), "o peso segue smoothstep, não uma rampa linear (u=%.3f, w=%.3f)" % [float(k45) / 64.0, w45])
	var share := r.samples[64 * 3].intensity
	var sum_i := r.samples[64 * 3].intensity + r.samples[64 * 3 + 1].intensity + r.samples[64 * 3 + 2].intensity
	ok(near(share, 1.0 / 3.0, 1e-5) and near(sum_i, 1.0, 1e-5), "intensidade dividida entre os ramos reunidos (soma preservada)")
	ok(near(r.samples[10 * 3].intensity, 1.0, 1e-6), "antes da reunião a intensidade é 1")
	var rn := eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9, "intensity_reduction": 0.0, "width_reduction": 1.0}]])
	ok(near(rn.samples[64 * 3].intensity, 1.0, 1e-6) and near(rn.samples[64 * 3].width, 1.0 / 3.0, 1e-5), "redução de largura e de intensidade são independentes")

	var rs := eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9, "strength": 0.5}]])
	ok(vnear(rs.samples[64 * 3].position, before.samples[64 * 3].position.lerp(base.samples[64].position, 0.5), 1e-5), "intensidade 0,5: reunião parcial")

	var rt := eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9, "t_start": 1.0, "t_duration": 1.0}]], 1.5)
	ok(vnear(rt.samples[64 * 3].position, before.samples[64 * 3].position.lerp(base.samples[64].position, 0.5), 1e-5), "reunião temporal: metade no meio da transição")
	var rt0 := eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9, "t_start": 1.0, "t_duration": 1.0}]], 0.5)
	ok(vnear(rt0.samples[64 * 3].position, before.samples[64 * 3].position, 1e-9), "antes do início temporal os ramos seguem separados")

	# reunião seletiva: apenas dois dos três ramos; ordem preservada
	var c := MotionComposition.new()
	c.sample_count = 65
	c.add_layer(make_layer(&"A", &"M14", Op.BRANCH, bp))
	var lm := make_layer(&"M", &"M15", Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9})
	lm.branches = PackedStringArray(["root/A.0", "root/A.1"])
	c.add_layer(lm)
	var rsel := c.evaluate(_cat, c.make_context(0.0))
	var cb := MotionComposition.new()
	cb.sample_count = 65
	cb.add_layer(make_layer(&"A", &"M14", Op.BRANCH, bp))
	var bsel := cb.evaluate(_cat, cb.make_context(0.0))
	ok(ids_of(rsel) == ids_of(bsel), "reunião seletiva: a ordem das amostras não muda")
	var third := true
	var two := true
	for k in range(58, 65):
		if rsel.samples[k * 3 + 2].position != bsel.samples[k * 3 + 2].position:
			third = false
		if not vnear(rsel.samples[k * 3].position, rsel.samples[k * 3 + 1].position, 1e-5):
			two = false
	ok(third and two, "reunião seletiva: dois ramos coincidem, o terceiro permanece")
	var cen2 := (bsel.samples[64 * 3].position + bsel.samples[64 * 3 + 1].position) * 0.5
	ok(vnear(rsel.samples[64 * 3].position, cen2, 1e-5), "o destino comum é o centroide dos ramos selecionados")
	ok(near(rsel.samples[64 * 3].intensity, 0.5, 1e-5) and near(rsel.samples[64 * 3 + 2].intensity, 1.0, 1e-6), "a divisão de intensidade usa só os ramos reunidos")

	# sem bifurcação: um único fluxo
	var rsolo := eval_specs([[&"M15", Op.MERGE, mp]])
	var solo_ok := true
	for i in 65:
		if rsolo.samples[i].position != base.samples[i].position or rsolo.samples[i].intensity != 1.0:
			solo_ok = false
	ok(solo_ok, "sem ramos, recombinar não altera nada")

	var rsw := eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, {"merge_start": 0.9, "merge_end": 0.6}]])
	ok(finite_ok(rsw), "merge_end < merge_start é tratado (intervalo trocado), sem NaN")

	# duas bifurcações, uma recombinação de nível
	var r2 := eval_specs([[&"M14", Op.BRANCH, {"branches": 2, "split_u": 0.3, "distance": 0.4}], [&"M14", Op.BRANCH, {"branches": 2, "split_u": 0.5, "distance": 0.2}], [&"M15", Op.MERGE, {"merge_start": 0.7, "merge_end": 0.8}]])
	var conv := true
	for k in range(60, 65):
		for i in 1:
			var p0 := r2.samples[k * 4].position
			for j in range(1, 4):
				if not vnear(p0, r2.samples[k * 4 + j].position, 1e-5):
					conv = false
	ok(finite_ok(r2) and conv, "4 ramos aninhados reunidos em um destino comum")

	var b := _cat.get_behavior(&"M15")
	var ext := true
	for high in [false, true]:
		for tt in [0.37, 29.0]:
			var re := eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, extreme_params(b, high)]], tt)
			if not finite_ok(re):
				ext = false
	ok(ext, "domínio no mínimo e no máximo: nenhum valor não finito")
	ok(same_result(r, eval_specs([[&"M14", Op.BRANCH, bp], [&"M15", Op.MERGE, mp]])), "repetibilidade")


# --------------------------------------------------------------------------------------
func t_order_masks_offsets() -> void:
	print("\n-- Ordem, máscaras e defasagens com comportamentos reais --")
	var helix := [&"M01", Op.REPLACE, {"radius": 0.3, "pitch": 0.5, "turns": 2.0}]
	var br := [&"M14", Op.BRANCH, {"branches": 3, "split_u": 0.3, "angle_deg": 40.0, "distance": 0.4}]
	var tw := [&"M08", Op.DEFORM, {"amount_deg": 90.0}]
	var c_ord_a := MotionComposition.new()
	c_ord_a.sample_count = 65
	c_ord_a.seed = 7
	c_ord_a.add_layer(make_layer(&"h", helix[0], helix[1], helix[2]))
	c_ord_a.add_layer(make_layer(&"tw", tw[0], tw[1], tw[2]))
	c_ord_a.add_layer(make_layer(&"br", br[0], br[1], br[2]))
	var cb2 := MotionComposition.new()
	cb2.sample_count = 65
	cb2.seed = 7
	cb2.add_layer(make_layer(&"h", helix[0], helix[1], helix[2]))
	cb2.add_layer(make_layer(&"tw", tw[0], tw[1], tw[2]))
	cb2.add_layer(make_layer(&"br", br[0], br[1], br[2]))
	cb2.move_layer(&"tw", 2)
	var a := c_ord_a.evaluate(_cat, c_ord_a.make_context(0.0))
	var b := cb2.evaluate(_cat, cb2.make_context(0.0))
	ok(a.samples.size() == b.samples.size() and not same_result(a, b), "torcer→bifurcar ≠ bifurcar→torcer")
	var ia := ids_of(a)
	var ib := ids_of(b)
	ia.sort()
	ib.sort()
	ok(ia == ib, "a ordem muda a geometria, não as identidades")

	# máscara espacial: serpentina só na metade final dos ramos
	var c := MotionComposition.new()
	c.sample_count = 65
	c.add_layer(make_layer(&"B", &"M14", Op.BRANCH, br[2]))
	var l := make_layer(&"S", &"M03", Op.OFFSET, {"amplitude": 0.1, "wavelength": 0.4})
	l.mask.u_from = 0.5
	l.mask.u_to = 1.0
	c.add_layer(l)
	var rm := c.evaluate(_cat, c.make_context(0.0))
	var base := eval_specs([br])
	var early := true
	var late := false
	for k in 65:
		for i in 3:
			var moved := rm.samples[k * 3 + i].position != base.samples[k * 3 + i].position
			if k < 32 and moved:
				early = false
			if k > 40 and moved:
				late = true
	ok(early and late, "máscara espacial vale para cada ramo (só u ≥ 0,5 recebe a serpentina)")

	# defasagem com M07 real
	var ca := MotionComposition.new()
	ca.sample_count = 33
	ca.add_layer(make_layer(&"T", &"M07", Op.OFFSET, {"intensity": 0.1, "time_hz": 2.0}))
	var cb := MotionComposition.new()
	cb.sample_count = 33
	cb.add_layer(make_layer(&"T", &"M07", Op.OFFSET, {"intensity": 0.1, "time_hz": 2.0}, 0.7))
	ok(same_result(ca.evaluate(_cat, ca.make_context(0.3)), cb.evaluate(_cat, cb.make_context(1.0))), "defasagem de 0,7 s: avaliar em 1,0 = avaliar em 0,3 sem defasagem")

	# seleção de ramos antes da bifurcação existir
	var cc := MotionComposition.new()
	cc.sample_count = 17
	var lw := make_layer(&"W", &"M17", Op.MULTIPLY_ATTRIBUTE, {})
	lw.branches = PackedStringArray(["root/B.1"])
	lw.active_from = 0.0
	cc.add_layer(lw)
	cc.add_layer(make_layer(&"B", &"M14", Op.BRANCH, {"branches": 3}))
	var rc := cc.evaluate(_cat, cc.make_context(0.1))
	var has_diag := false
	for d in rc.diagnostics:
		if d.code == &"layer_branch_missing":
			has_diag = true
	ok(has_diag and rc.samples.size() == 51, "selecionar um ramo antes de ele existir gera diagnóstico (a ordem importa) e a camada é ignorada")

	# layer.intensity em topologia: 0 desliga, outros valores aplicam por inteiro
	var cd := MotionComposition.new()
	cd.sample_count = 17
	var li := make_layer(&"B", &"M14", Op.BRANCH, {"branches": 3})
	li.intensity = 0.0
	cd.add_layer(li)
	ok(cd.evaluate(_cat, cd.make_context(0.0)).samples.size() == 17, "topologia com intensidade 0 é ignorada")
	li.intensity = 0.3
	ok(cd.evaluate(_cat, cd.make_context(0.0)).samples.size() == 51, "topologia com intensidade > 0 aplica por inteiro (a quantidade vem dos parâmetros)")


func t_guards() -> void:
	print("\n-- Proteções com bifurcações reais --")
	var c := MotionComposition.new()
	c.sample_count = 128
	c.add_layer(make_layer(&"A", &"M14", Op.BRANCH, {"branches": 16}))
	c.add_layer(make_layer(&"B", &"M14", Op.BRANCH, {"branches": 16}))
	c.add_layer(make_layer(&"C", &"M14", Op.BRANCH, {"branches": 16}))
	var r := c.evaluate(_cat, c.make_context(0.0))
	var lim := false
	for d in r.diagnostics:
		if d.code == &"layer_sample_limit":
			lim = true
	ok(lim and r.samples.size() == 128 * 256, "crescimento combinatório (128×16×16×16 = 524288) é barrado antes de alocar; as duas primeiras bifurcações permanecem (32768)")
	var c2 := MotionComposition.new()
	c2.sample_count = 128
	c2.max_samples = 300
	c2.add_layer(make_layer(&"A", &"M14", Op.BRANCH, {"branches": 3}))
	var r2 := c2.evaluate(_cat, c2.make_context(0.0))
	ok(r2.samples.size() == 128 and not r2.diagnostics.is_empty(), "limite configurável (300): bifurcação 128×3 recusada")


# --------------------------------------------------------------------------------------
## Receita da §6 sem M19 (Etapa 4): compressão → crescimento → zigue-zague+torção → bifurcação em 3
## → serpentina+turbulência → recombinação → onda radial+explosão → dissolução. Janelas pela defasagem.
func recipe() -> MotionComposition:
	var c := MotionComposition.new()
	c.id = &"receita"
	c.sample_count = 65
	c.duration = 3.0
	c.seed = 2026
	c.add_layer(make_layer(&"compress", &"M11", Op.DEFORM, {"strength": 0.8, "center": 0.5, "extent": 0.5, "softness": 0.2}))
	c.add_layer(make_layer(&"grow", &"M17", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.45, "width": 0.1}))
	c.add_layer(make_layer(&"zig", &"M02", Op.OFFSET, {"amplitude": 0.06, "frequency": 6.0}, 0.45))
	c.add_layer(make_layer(&"twist", &"M08", Op.DEFORM, {"amount_deg": 120.0}, 0.45))
	c.add_layer(make_layer(&"branch", &"M14", Op.BRANCH, {"branches": 3, "split_u": 0.3, "angle_deg": 35.0, "distance": 0.4}, 1.05))
	c.add_layer(make_layer(&"snake", &"M03", Op.OFFSET, {"amplitude": 0.03, "wavelength": 0.3}, 1.5))
	c.add_layer(make_layer(&"turb", &"M07", Op.OFFSET, {"intensity": 0.02}, 1.5))
	c.add_layer(make_layer(&"merge", &"M15", Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9, "t_duration": 0.3}, 1.95))
	c.add_layer(make_layer(&"wave", &"M13", Op.OFFSET, {"speed": 1.5, "amplitude": 0.05}, 2.25))
	c.add_layer(make_layer(&"burst", &"M16", Op.OFFSET, {"distance": 0.3, "t_duration": 0.3}, 2.25))
	c.add_layer(make_layer(&"dissolve", &"M18", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.45}, 2.55))
	return c


func t_recipe() -> void:
	print("\n-- Receita da §6 (sem M19) construída só com a biblioteca --")
	var c := recipe()
	ok(c.validate(_cat).is_empty(), "a receita valida sem diagnósticos")
	var all_ok := true
	var counts_ok := true
	var t := 0.0
	while t <= 3.0001:
		var r := c.evaluate(_cat, c.make_context(t))
		if not finite_ok(r):
			all_ok = false
		var expect := 65 if t < 1.05 else 195
		if r.samples.size() != expect:
			counts_ok = false
		t += 0.05
	ok(all_ok, "61 instantes (0 a 3 s, passo 0,05) sem erro nem valores não finitos")
	ok(counts_ok, "65 amostras até a bifurcação (1,05 s) e 195 depois")

	var r0 := c.evaluate(_cat, c.make_context(0.0))
	ok(near(r0.samples[0].width, 0.0, 1e-6) and near(r0.samples[64].width, 0.0, 1e-6), "em t=0 o crescimento ainda não revelou nada")
	var rm := c.evaluate(_cat, c.make_context(2.25))
	var merged := true
	for k in range(60, 65):
		var p0 := rm.samples[k * 3].position
		if not (vnear(p0, rm.samples[k * 3 + 1].position, 1e-4) and vnear(p0, rm.samples[k * 3 + 2].position, 1e-4)):
			merged = false
	ok(merged, "em t=2,25 s (reunião concluída) os três fluxos coincidem na cauda")
	var rs := c.evaluate(_cat, c.make_context(1.8))
	var apart := rs.samples[64 * 3].position.distance_to(rs.samples[64 * 3 + 1].position)
	ok(apart > 0.3, "em t=1,8 s (separados) os fluxos estão afastados (%.2f m)" % apart)
	var rd := c.evaluate(_cat, c.make_context(3.0))
	var gone := true
	for s in rd.samples:
		if s.width > 1e-6:
			gone = false
	ok(gone, "em t=3 s a dissolução removeu tudo")
	ok(same_result(c.evaluate(_cat, c.make_context(1.7)), recipe().evaluate(_cat, recipe().make_context(1.7))), "receita reproduzível (instância nova, mesmo resultado)")
	var seek := c.evaluate(_cat, c.make_context(1.7))
	for tt in [0.0, 2.9, 0.4, 1.1]:
		c.evaluate(_cat, c.make_context(tt))
	ok(same_result(seek, c.evaluate(_cat, c.make_context(1.7))), "buscar outros instantes antes não altera o resultado")

	# trocar a ordem de duas camadas muda a receita
	var swapped := recipe()
	swapped.move_layer(&"turb", 3)
	ok(not same_result(c.evaluate(_cat, c.make_context(2.0)), swapped.evaluate(_cat, swapped.make_context(2.0))), "reordenar camadas da receita altera o resultado")
	# desligar a camada de bifurcação
	var nob := recipe()
	nob.set_enabled(&"branch", false)
	var rn := nob.evaluate(_cat, nob.make_context(2.0))
	ok(rn.samples.size() == 65 and not rn.has_errors(), "sem a bifurcação a receita continua avaliando (recombinar um único fluxo é neutro)")

	var t0 := Time.get_ticks_usec()
	var n := 40
	for i in n:
		c.evaluate(_cat, c.make_context(float(i) * 0.07))
	print("  [INFO] receita completa (11 camadas, 65→195 amostras): %.2f ms por avaliação (GDScript, headless, sem render)" % (float(Time.get_ticks_usec() - t0) / n / 1000.0))
