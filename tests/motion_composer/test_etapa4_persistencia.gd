extends SceneTree
## Motion Composer V1 — Etapa 4: M19 rastro temporal, M20 pós-imagem e histórico (D-304).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa4_persistencia.gd

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


func near(a: float, b: float, eps: float = 1e-4) -> bool:
	return absf(a - b) <= eps


func vnear(a: Vector3, b: Vector3, eps: float = 1e-4) -> bool:
	return a.distance_to(b) <= eps


## Emissor que anda em +X a 10 m/s (sem rotação).
func emitter_line(t: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(10.0 * t, 0.0, 0.0))


## Emissor que gira 90°/s em torno de Z e anda em +X.
func emitter_turn(t: float) -> Transform3D:
	return Transform3D(Basis(Vector3.BACK, deg_to_rad(90.0) * t), Vector3(4.0 * t, 0.0, 0.0))


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


## Composição: hélice com giro (L0) + camadas extras ("L1", "L2", ...).
func build(extra: Array, n: int = 8, seed_v: int = 7) -> MotionComposition:
	var c := MotionComposition.new()
	c.id = &"t"
	c.sample_count = n
	c.seed = seed_v
	c.add_layer(make_layer(&"L0", &"M01", Op.REPLACE, HELIX))
	var i := 1
	for e in extra:
		c.add_layer(make_layer(StringName("L%d" % i), e[0], e[1], e[2]))
		i += 1
	return c


func eval_at(c: MotionComposition, t: float, emitter: Callable = Callable()) -> MotionResult:
	var ctx := c.make_context(t)
	ctx.emitter_fn = emitter
	return c.evaluate(_cat, ctx)


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


func same_result(a: MotionResult, b: MotionResult) -> bool:
	if a.samples.size() != b.samples.size():
		return false
	for i in a.samples.size():
		var x := a.samples[i]
		var y := b.samples[i]
		if x.position != y.position or x.width != y.width or x.opacity != y.opacity or x.element_id != y.element_id or x.branch != y.branch or x.visible != y.visible or x.age != y.age:
			return false
	return true


## Amostras do rastro/pós-imagem do elemento-pai `pid`, ordenadas por idade.
func copies_of(r: MotionResult, parent_u: float, first_copy_index: int) -> Array:
	var out := []
	for i in range(first_copy_index, r.samples.size()):
		if absf(r.samples[i].u - parent_u) < 1e-9 and r.samples[i].age > 0.0:
			out.append(r.samples[i])
	out.sort_custom(func(a, b): return a.age < b.age)
	return out


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 4: M19, M20 E HISTÓRICO (D-304)")
	print("=================================================================")
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_cat = MotionCatalog.new()
	ok(MotionBehaviors.register_all(_cat).is_empty(), "register_all registra M01–M20 sem diagnóstico")

	t_catalog()
	t_history_contract()
	t_m19()
	t_m20()
	t_distinct()
	t_emitter()
	t_robustness()

	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "nenhum comportamento cria nós")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


# --------------------------------------------------------------------------------------
func t_catalog() -> void:
	print("\n-- Catálogo: V1 completa --")
	ok(_cat.missing_v1().is_empty(), "os 20 comportamentos M01–M20 estão registrados")
	ok(MotionBehaviors.all().size() == 20, "20 comportamentos implementados")
	var a := _cat.get_behavior(&"M19")
	var b := _cat.get_behavior(&"M20")
	ok(a.kind == MotionTypes.Kind.HISTORICAL and b.kind == MotionTypes.Kind.HISTORICAL and a.needs_history and b.needs_history, "M19 e M20 são HISTORICAL e declaram needs_history")
	ok(a.accepted_operations == [Op.PERSIST] and b.accepted_operations == [Op.PERSIST], "ambos aceitam só PERSIST")
	var c := build([[&"M19", Op.OFFSET, {}]])
	ok(not c.validate(_cat).is_empty(), "M19 recusa OFFSET")
	ok(a.output_count(8, a.resolve_params({})) == 80 and b.output_count(8, b.resolve_params({})) == 32, "output_count: 8×10 amostras de rastro; 8×4 pós-imagens")


func t_history_contract() -> void:
	print("\n-- Contrato de histórico --")
	var c := build([[&"M19", Op.PERSIST, {}]])
	var ctx := c.make_context(1.0)
	ok(not ctx.history_fn.is_valid(), "o contexto externo não traz histórico (só o compositor o fornece às camadas PERSIST)")
	var s := MotionSample.new()
	ok(s.age == 0.0 and s.duplicate_sample().age == 0.0, "MotionSample.age existe e vale 0 por padrão")
	s.age = 0.25
	ok(s.duplicate_sample().age == 0.25, "age é copiada")
	var b19 := _cat.get_behavior(&"M19")
	var one: Array[MotionSample] = [MotionSample.make_rest(0.5, 1, 1.0)]
	var out := b19.apply(one, b19.resolve_params({}), MotionContext.new(), 1.0, &"L")
	var hidden := true
	for o in out:
		if o.visible or o.opacity != 0.0:
			hidden = false
	ok(out.size() == 10 and hidden, "sem histórico disponível, o comportamento devolve as amostras previstas invisíveis (contagem estável, sem erro)")


func t_m19() -> void:
	print("\n-- M19 Rastro temporal --")
	var c := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05}]])
	var base := build([])
	var t := 1.0
	var r := eval_at(c, t)
	ok(not r.has_errors() and r.samples.size() == 8 * 11, "8 amostras + 10 de rastro por elemento (88)")
	var uniq := {}
	for s in r.samples:
		uniq[s.element_id] = true
	ok(uniq.size() == 88, "ids únicos")
	var trail := copies_of(r, eval_at(base, t).samples[3].u, 8)
	ok(trail.size() == 10, "10 amostras de rastro para o elemento 3")
	var ages_ok := true
	for j in trail.size():
		if not near(trail[j].age, 0.05 * float(j + 1), 1e-6):
			ages_ok = false
	ok(ages_ok, "idades 0,05 … 0,50 s, igualmente espaçadas")
	ok(trail[0].branch == "root/L1.0", "um único ramo de rastro por elemento (root/L1.0)")

	# correção histórica: cada amostra é o estado do fluxo no instante anterior
	var hist_ok := true
	for j in trail.size():
		var past := eval_at(base, t - trail[j].age)
		if not vnear(trail[j].position, past.samples[3].position, 1e-5):
			hist_ok = false
	ok(hist_ok, "cada amostra do rastro = fluxo anterior avaliado em t − idade (reconstrução por avaliação direta)")
	ok(not vnear(trail[9].position, eval_at(base, t).samples[3].position, 1e-3), "o rastro não é a posição atual repetida")

	# busca, retrocesso e reinício
	var r1 := eval_at(c, 1.0)
	for tt in [0.1, 2.5, 0.0, 1.7]:
		eval_at(c, tt)
	ok(same_result(r1, eval_at(c, 1.0)), "seek/retrocesso/reinício não alteram o resultado")
	ok(same_result(r1, eval_at(build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05}]]), 1.0)), "composição recriada: mesmo histórico")

	# antes do nascimento
	var rb := eval_at(c, 0.2)
	var tb := copies_of(rb, eval_at(base, 0.2).samples[3].u, 8)
	var born_ok := tb.size() == 10
	for j in tb.size():
		var expect_visible: bool = (0.2 - tb[j].age) >= 0.0
		if tb[j].visible != expect_visible or (not expect_visible and tb[j].opacity != 0.0):
			born_ok = false
	ok(born_ok, "amostras de antes do instante 0 ficam invisíveis; a contagem não muda")
	ok(rb.samples.size() == 88, "mesma quantidade antes e depois do nascimento (ids estáveis)")

	# propriedades por idade
	var cw := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05, "width_start": 1.0, "width_end": 0.0}]])
	var rw := eval_at(cw, 1.0)
	var tw := copies_of(rw, eval_at(base, 1.0).samples[3].u, 8)
	var mono_w := true
	var mono_o := true
	for j in range(1, tw.size()):
		if tw[j].width > tw[j - 1].width + 1e-9:
			mono_w = false
		if tw[j].opacity > tw[j - 1].opacity + 1e-9:
			mono_o = false
	ok(mono_w and mono_o and near(tw[4].width, 0.5, 1e-5) and near(tw[4].opacity, 0.5, 1e-5), "largura e opacidade decaem com a idade (metade na idade 0,25 s)")
	ok(near(tw[9].opacity, 0.0, 1e-6), "opacidade chega a 0 na idade máxima")
	var cc := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05, "fade_curve": 2.0}]])
	var tc := copies_of(eval_at(cc, 1.0), eval_at(base, 1.0).samples[3].u, 8)
	ok(near(tc[4].opacity, 0.25, 1e-5), "curva de dissipação 2: opacidade 0,25 em metade da vida")
	var c0 := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05, "width_start": 2.0, "width_end": 2.0}]])
	var t0 := copies_of(eval_at(c0, 1.0), eval_at(base, 1.0).samples[3].u, 8)
	ok(near(t0[0].width, 2.0) and near(t0[9].width, 2.0), "largura inicial e final configuráveis")

	# intensidade da camada
	var ch := build([[&"M19", Op.PERSIST, {}]])
	ch.layers[1].intensity = 0.5
	var th := copies_of(eval_at(ch, 1.0), eval_at(base, 1.0).samples[3].u, 8)
	ok(near(th[4].opacity, 0.5 * 0.5, 1e-5), "intensidade 0,5 da camada reduz a opacidade do rastro pela metade")
	ch.layers[1].intensity = 0.0
	ok(eval_at(ch, 1.0).samples.size() == 8, "intensidade 0: sem rastro")

	# alteração de parâmetros: sem misturar revisões
	var cp := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.05}]])
	eval_at(cp, 1.0)
	cp.set_param(&"L1", &"duration", 0.2)
	var after := eval_at(cp, 1.0)
	var fresh := eval_at(build([[&"M19", Op.PERSIST, {"duration": 0.2, "sample_interval": 0.05}]]), 1.0)
	ok(after.samples.size() == 8 * 5 and same_result(after, fresh) and after.revision == cp.revision, "alterar um parâmetro reconstrói o histórico inteiro com os novos valores")

	# camadas depois do rastro continuam atuando
	var cn := build([[&"M19", Op.PERSIST, {}], [&"M07", Op.OFFSET, {"intensity": 0.05}]])
	ok(finite_ok(eval_at(cn, 1.0)) and eval_at(cn, 1.0).samples.size() == 88, "camadas posteriores atuam também sobre o rastro")


func t_m20() -> void:
	print("\n-- M20 Pós-imagem --")
	var c := build([[&"M20", Op.PERSIST, {"count": 4, "interval": 0.1}]])
	var base := build([])
	var t := 1.0
	var r := eval_at(c, t)
	ok(not r.has_errors() and r.samples.size() == 8 * 5, "8 amostras + 4 pós-imagens por elemento (40)")
	var pu := eval_at(base, t).samples[3].u
	var ghosts := copies_of(r, pu, 8)
	ok(ghosts.size() == 4, "4 pós-imagens do elemento 3")
	var ages_ok := true
	for k in 4:
		if not near(ghosts[k].age, 0.1 * float(k + 1), 1e-6):
			ages_ok = false
	ok(ages_ok, "instantes discretos: 0,1 / 0,2 / 0,3 / 0,4 s antes")
	var br := {}
	for g in ghosts:
		br[g.branch] = true
	ok(br.size() == 4 and br.has("root/L1.0") and br.has("root/L1.3"), "cada pós-imagem é um ramo identificável (root/L1.0 … root/L1.3)")
	var hist_ok := true
	for g in ghosts:
		if not vnear(g.position, eval_at(base, t - g.age).samples[3].position, 1e-5):
			hist_ok = false
	ok(hist_ok, "cada pós-imagem = estado do fluxo em t − idade")
	var op_ok := true
	for k in 4:
		if not near(ghosts[k].opacity, 1.0 - 0.8 * float(k + 1) / 5.0, 1e-5):
			op_ok = false
	ok(op_ok, "opacidade em degraus: 0,84 / 0,68 / 0,52 / 0,36")
	var cs := build([[&"M20", Op.PERSIST, {"count": 4, "interval": 0.1, "scale": 0.5}]])
	var gs := copies_of(eval_at(cs, t), pu, 8)
	ok(near(gs[0].width, 0.5) and near(gs[2].width, 0.125), "tamanho: largura multiplicada por escala^k")
	var cb := eval_at(c, 0.25)
	var gb := copies_of(cb, eval_at(base, 0.25).samples[3].u, 8)
	var born_ok := gb.size() == 4
	for g in gb:
		var vis: bool = (0.25 - g.age) >= 0.0
		if g.visible != vis:
			born_ok = false
	ok(born_ok and not gb[2].visible and gb[1].visible, "pós-imagens anteriores ao instante 0 ficam invisíveis (0,25 s: só 2 visíveis)")
	var r1 := eval_at(c, t)
	for tt in [0.0, 3.0, 0.4]:
		eval_at(c, tt)
	ok(same_result(r1, eval_at(c, t)), "seek/retrocesso/reinício não alteram o resultado")
	var cc := build([[&"M20", Op.PERSIST, {"count": 3, "interval": 0.1}]])
	cc.set_param(&"L1", &"count", 2)
	ok(eval_at(cc, t).samples.size() == 8 * 3, "alterar a quantidade reconstrói: 8 × (1 + 2)")


func t_distinct() -> void:
	print("\n-- Rastro ≠ pós-imagem --")
	var base := build([])
	var pu := eval_at(base, 1.0).samples[3].u
	var m19 := eval_at(build([[&"M19", Op.PERSIST, {"duration": 0.4, "sample_interval": 0.1}]]), 1.0)
	var m20 := eval_at(build([[&"M20", Op.PERSIST, {"count": 4, "interval": 0.1, "fade": 0.0}]]), 1.0)
	var a := copies_of(m19, pu, 8)
	var b := copies_of(m20, pu, 8)
	ok(a.size() == b.size() and a.size() == 4, "mesma quantidade e idades nos dois")
	var same_pos := true
	for i in 4:
		if not vnear(a[i].position, b[i].position, 1e-6):
			same_pos = false
	ok(same_pos, "mesmos estados históricos nas mesmas idades")
	var br19 := {}
	var br20 := {}
	for s in a:
		br19[s.branch] = true
	for s in b:
		br20[s.branch] = true
	ok(br19.size() == 1 and br20.size() == 4, "rastro: um fluxo contínuo (1 ramo); pós-imagem: estados discretos (4 ramos)")
	ok(not (near(a[3].width, b[3].width) and near(a[3].opacity, b[3].opacity)), "rastro afina e some com a idade; pós-imagem mantém os atributos do estado")
	var dense := eval_at(build([[&"M19", Op.PERSIST, {"duration": 0.4, "sample_interval": 0.02}]]), 1.0)
	ok(copies_of(dense, pu, 8).size() == 20, "rastro denso: 20 amostras no mesmo intervalo em que a pós-imagem tem 4")


func t_emitter() -> void:
	print("\n-- História do emissor (posição e direção) --")
	var base := build([])
	var t := 2.0
	var pu := eval_at(base, t).samples[3].u
	var cf := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.1, "world_space": false}]])
	var cw := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.1, "world_space": true}]])
	var tf := copies_of(eval_at(cf, t, emitter_line), pu, 8)
	var tw := copies_of(eval_at(cw, t, emitter_line), pu, 8)
	var past := eval_at(base, t - tf[2].age).samples[3].position
	ok(vnear(tf[2].position, past, 1e-5), "world_space desligado: o rastro acompanha o emissor (coordenadas locais do instante passado)")
	ok(vnear(tw[2].position, past + Vector3(-10.0 * tw[2].age, 0, 0), 1e-4), "world_space ligado: o rastro fica para trás no mundo (−10 m/s × idade em X)")
	var turn_ok := true
	for j in tw.size():
		var e_now := emitter_turn(t)
		var e_then := emitter_turn(t - tw[j].age)
		var expect := e_now.affine_inverse() * e_then * eval_at(base, t - tw[j].age).samples[3].position
		var got: Vector3 = copies_of(eval_at(cw, t, emitter_turn), pu, 8)[j].position
		if not vnear(got, expect, 1e-4):
			turn_ok = false
	ok(turn_ok, "emissor que gira e anda: rastro = E(t)⁻¹·E(t − idade)·posição histórica")
	var cs := eval_at(cw, t, emitter_line)
	var cs2 := eval_at(cw, t, emitter_line)
	ok(same_result(cs, cs2), "a mesma história do emissor produz o mesmo rastro")
	var rs := eval_at(cw, t, emitter_turn)
	ok(not same_result(cs, rs), "outra história do emissor produz outro rastro")
	var g20 := build([[&"M20", Op.PERSIST, {"count": 2, "interval": 0.1, "world_space": true}]])
	var gg := copies_of(eval_at(g20, t, emitter_line), pu, 8)
	ok(vnear(gg[1].position, eval_at(base, t - gg[1].age).samples[3].position + Vector3(-10.0 * gg[1].age, 0, 0), 1e-4), "M20 também respeita world_space")
	ok(eval_at(cf, t).samples.size() == 8 * 6, "sem emissor definido (identidade) o rastro continua válido (8 × (1 + 5))")


func t_robustness() -> void:
	print("\n-- Robustez e limites --")
	for id in [&"M19", &"M20"]:
		var b := _cat.get_behavior(id)
		var ext := true
		for high in [false, true]:
			for tt in [0.37, 29.0]:
				var c := build([[id, Op.PERSIST, extreme_params(b, high)]], 8)
				if not finite_ok(eval_at(c, tt, emitter_turn)):
					ext = false
		ok(ext, "%s: domínio no mínimo e no máximo, em dois instantes: nenhum valor não finito" % id)
	var big := build([[&"M19", Op.PERSIST, {"duration": 5.0, "sample_interval": 0.005}]], 8)
	ok(eval_at(big, 3.0).samples.size() == 8 * 257, "limite de 256 amostras de rastro por elemento (duração 5 s ÷ 0,005 s é reduzido)")
	var lim := build([[&"M19", Op.PERSIST, {}]], 1000)
	lim.max_samples = 5000
	var rl := eval_at(lim, 1.0)
	var has_diag := false
	for d in rl.diagnostics:
		if d.code == &"layer_sample_limit":
			has_diag = true
	ok(has_diag and rl.samples.size() == 1000, "limite de amostras da composição barra o rastro antes de alocar")
	var nest := build([[&"M19", Op.PERSIST, {"duration": 0.2, "sample_interval": 0.1}], [&"M20", Op.PERSIST, {"count": 2, "interval": 0.1}]])
	var rn := eval_at(nest, 1.0)
	ok(finite_ok(rn) and rn.samples.size() == 8 * 3 * 3, "histórico de histórico: M20 sobre um fluxo que já tem rastro (8 × 3 × 3)")
	var win := build([[&"M19", Op.PERSIST, {}]])
	win.layers[1].active_from = 2.0
	ok(eval_at(win, 1.0).samples.size() == 8 and eval_at(win, 2.5).samples.size() == 88, "janela de atividade da camada vale também para o rastro")
	# o histórico respeita as janelas das camadas anteriores
	var cwin := build([[&"M19", Op.PERSIST, {"duration": 0.5, "sample_interval": 0.1}]])
	cwin.layers[0].active_from = 0.0
	var m := MotionLayer.new()
	m.id = &"X"
	m.behavior_id = &"M06"
	m.op = Op.OFFSET
	m.params = {"target": Vector3(0, 0, 0), "reach": 5.0}
	m.active_from = 1.0
	cwin.add_layer(m, 1)
	var before := eval_at(cwin, 1.2)
	var base_only := build([])
	var pu := eval_at(base_only, 1.2).samples[3].u
	var tr := copies_of(before, pu, 8)
	var past_ok := true
	for g in tr:
		var tp: float = 1.2 - g.age
		var ref := build([])
		var m2 := MotionLayer.new()
		m2.id = &"X"
		m2.behavior_id = &"M06"
		m2.op = Op.OFFSET
		m2.params = {"target": Vector3(0, 0, 0), "reach": 5.0}
		m2.active_from = 1.0
		ref.add_layer(m2)
		if not vnear(g.position, eval_at(ref, tp).samples[3].position, 1e-5):
			past_ok = false
	ok(past_ok, "o histórico usa as janelas de atividade das camadas anteriores em cada instante passado")
	var t0 := Time.get_ticks_usec()
	var cost := build([[&"M19", Op.PERSIST, {}]], 128)
	for i in 20:
		eval_at(cost, 1.0 + float(i) * 0.01)
	print("  [INFO] M19 padrão (128 amostras → 1408, 11 avaliações do fluxo): %.2f ms por avaliação (GDScript, headless, sem render)" % (float(Time.get_ticks_usec() - t0) / 20.0 / 1000.0))
