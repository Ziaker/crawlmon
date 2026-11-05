extends SceneTree
## Motion Composer V1 — Etapa 2b: testes de M16, M17 e M18 (D-302).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa2b_impacto_envelopes.gd

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


func run(bid: StringName, op: int, params: Dictionary = {}, t: float = 0.0, n: int = 65, intensity: float = 1.0, seed_v: int = 7) -> MotionResult:
	return eval_layers([[bid, op, params, intensity]], t, n, seed_v)


func disp(r: MotionResult, b0: MotionResult, i: int) -> Vector3:
	return r.samples[i].position - b0.samples[i].position


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


func visible_count(r: MotionResult) -> int:
	var n := 0
	for s in r.samples:
		if s.visible:
			n += 1
	return n


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 2b: M16, M17, M18 (D-302)")
	print("=================================================================")
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_cat = MotionCatalog.new()
	ok(MotionBehaviors.register_all(_cat).is_empty(), "register_all registra M01–M18 sem diagnóstico")

	t_catalog()
	t_generic()
	t_m16()
	t_m17()
	t_m18()
	t_combined()

	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "nenhum comportamento cria nós")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_catalog() -> void:
	print("\n-- Catálogo --")
	var all_ok := true
	for id in [&"M16", &"M17", &"M18"]:
		var b := _cat.get_behavior(id)
		if b == null or b.version != 1 or b.display_name == "" or b.description == "" or b.group == &"" or b.params.is_empty():
			all_ok = false
	ok(all_ok, "M16, M17 e M18 registrados com metadados")
	var miss := _cat.missing_v1()
	ok(miss.is_empty(), "catálogo V1 completo (%s)" % [miss])
	ok(MotionBehaviors.all().size() == 20, "20 comportamentos implementados")
	var c := MotionComposition.new()
	var l := MotionLayer.new()
	l.id = &"A"
	l.behavior_id = &"M17"
	l.op = Op.REPLACE
	c.add_layer(l)
	ok(not c.validate(_cat).is_empty(), "M17 recusa REPLACE (aceita só MASK e MULTIPLY_ATTRIBUTE)")


func t_generic() -> void:
	print("\n-- Contrato comum --")
	var entries := [[&"M16", Op.OFFSET], [&"M17", Op.MULTIPLY_ATTRIBUTE], [&"M18", Op.MULTIPLY_ATTRIBUTE]]
	var valid := true
	var rep := true
	var ext := true
	var half := true
	var ids := true
	var pause := true
	for e in entries:
		var b := _cat.get_behavior(e[0])
		var r := run(e[0], e[1], {}, 0.4)
		if not finite_ok(r) or r.samples.size() != 65:
			valid = false
		var r2 := run(e[0], e[1], {}, 0.4)
		for i in 65:
			if r.samples[i].position != r2.samples[i].position or r.samples[i].width != r2.samples[i].width or r.samples[i].opacity != r2.samples[i].opacity:
				rep = false
		for high in [false, true]:
			for tt in [0.37, 29.0]:
				if not finite_ok(run(e[0], e[1], extreme_params(b, high), tt)):
					ext = false
		# intensidade 0,5: ponto médio da entrada (posição 0 / atributos 1)
		var full := run(e[0], e[1], {}, 0.4)
		var h := run(e[0], e[1], {}, 0.4, 65, 0.5)
		var base := eval_layers([], 0.4)
		for i in 65:
			var mid_pos := (base.samples[i].position + full.samples[i].position) * 0.5
			var mid_w := (1.0 + full.samples[i].width) * 0.5 if e[0] != &"M16" else 1.0
			if h.samples[i].position.distance_to(mid_pos) > 1e-4:
				half = false
			if e[0] != &"M16" and not near(h.samples[i].width, 1.0 * lerpf(1.0, full.samples[i].width, 0.5), 1e-4):
				half = false
			if e[0] == &"M16" and mid_w != 1.0:
				half = false
		var ra := run(e[0], e[1], {}, 0.31)
		var rb := run(e[0], e[1], {}, 1.9)
		for i in 65:
			if ra.samples[i].element_id != rb.samples[i].element_id:
				ids = false
		var rp1 := run(e[0], e[1], {}, 0.31)
		for i in 65:
			if ra.samples[i].position != rp1.samples[i].position:
				pause = false
	ok(valid, "parâmetros padrão avaliam sem erro")
	ok(rep, "repetibilidade")
	ok(ext, "domínio no mínimo e no máximo, em dois instantes: nenhum valor não finito")
	ok(half, "intensidade 0,5 = ponto médio entre a entrada e o efeito pleno")
	ok(ids, "ids de elemento independem do tempo")
	ok(pause, "pausa: mesmo instante, mesmo resultado")
	var a := run(&"M17", Op.MULTIPLY_ATTRIBUTE, {}, 0.4)
	var b := run(&"M17", Op.MULTIPLY_ATTRIBUTE, {}, 0.8)
	var diff := false
	for i in 65:
		if a.samples[i].width != b.samples[i].width:
			diff = true
	ok(diff, "evolui no tempo com os padrões")


# --------------------------------------------------------------------------------------
func t_m16() -> void:
	print("\n-- M16 Explosão direcional --")
	var base := eval_layers([], 0.0, 257)
	var p := {"direction": Vector3(0, 0, 1), "cone_deg": 30.0, "distance": 1.0, "t_start": 0.0, "t_duration": 1.0, "curve": 1.0}
	var r := run(&"M16", Op.OFFSET, p, 1.0, 257)
	var in_cone := true
	var bounded := true
	var max_ang := 0.0
	for i in 257:
		var d := disp(r, base, i)
		var l := d.length()
		if l > 1.0 + 1e-4 or l < 0.5 - 1e-4:
			bounded = false
		var ang := d.angle_to(Vector3(0, 0, 1))
		max_ang = maxf(max_ang, ang)
		if ang > deg_to_rad(30.0) + 1e-3:
			in_cone = false
	ok(bounded, "alcance entre 50% e 100% da distância (variação determinística por elemento)")
	ok(in_cone, "todas as direções dentro da abertura angular (cone 30°)")
	var lmin := 9.0
	var lmax := 0.0
	for i in 257:
		var ll := disp(r, base, i).length()
		lmin = minf(lmin, ll)
		lmax = maxf(lmax, ll)
	ok(lmin < 0.6 and lmax > 0.9, "alcance varia de elemento para elemento (%.2f a %.2f)" % [lmin, lmax])
	ok(max_ang > deg_to_rad(30.0) * 0.8, "a abertura é aproveitada (máx. %.1f°)" % rad_to_deg(max_ang))
	var r0 := run(&"M16", Op.OFFSET, {"direction": Vector3(1, 0, 0), "cone_deg": 0.0, "t_duration": 1.0, "curve": 1.0}, 1.0, 65)
	var parallel := true
	for i in 65:
		if disp(r0, eval_layers([], 0.0, 65), i).angle_to(Vector3(1, 0, 0)) > 1e-3:
			parallel = false
	ok(parallel, "cone 0: todos exatamente na direção")

	var rb_before := run(&"M16", Op.OFFSET, {"direction": Vector3(0, 0, 1), "t_start": 0.5}, 0.2, 257)
	var zero := true
	for i in 257:
		if disp(rb_before, base, i) != Vector3.ZERO:
			zero = false
	ok(zero, "antes do início temporal: nenhum deslocamento")

	var rh := run(&"M16", Op.OFFSET, p, 0.5, 257)
	ok(near(disp(rh, base, 10).length(), 0.5 * disp(r, base, 10).length(), 1e-4), "curva linear: meio da duração = metade do deslocamento")
	var p2 := p.duplicate()
	p2["curve"] = 2.0
	var rh2 := run(&"M16", Op.OFFSET, p2, 0.5, 257)
	var rf2 := run(&"M16", Op.OFFSET, p2, 1.0, 257)
	ok(near(disp(rh2, base, 10).length(), 0.75 * disp(rf2, base, 10).length(), 1e-4), "curva 2 (saída suave): 75% no meio da duração")
	var rpost := run(&"M16", Op.OFFSET, p, 5.0, 257)
	ok(near(disp(rpost, base, 10).length(), disp(r, base, 10).length(), 1e-6), "depois do fim: deslocamento final mantido")

	var p3 := p.duplicate()
	p3["cone_deg"] = 60.0
	p3["distribution"] = 1.0
	var p4 := p3.duplicate()
	p4["distribution"] = 3.0
	var m1 := _mean_angle(run(&"M16", Op.OFFSET, p3, 1.0, 257), base)
	var m3 := _mean_angle(run(&"M16", Op.OFFSET, p4, 1.0, 257), base)
	ok(m3 < m1 * 0.8, "distribuição 3 concentra no eixo (%.1f° vs %.1f°)" % [rad_to_deg(m3), rad_to_deg(m1)])

	var r_seed := eval_layers([[&"M16", Op.OFFSET, p]], 1.0, 257, 99)
	ok(disp(r_seed, base, 10) != disp(r, base, 10), "semente da composição altera as direções")
	var az_changed := 0
	for i in range(1, 257):
		var d1 := disp(r, base, i)
		var d2 := disp(r_seed, base, i)
		if absf(wrapf(atan2(d1.y, d1.x) - atan2(d2.y, d2.x), -PI, PI)) > 0.05:
			az_changed += 1
	ok(az_changed > 200, "a semente altera também o azimute (%d de 256 elementos)" % az_changed)
	var r_33 := eval_layers([[&"M16", Op.OFFSET, p]], 1.0, 33)
	ok(disp(r_33, eval_layers([], 0.0, 33), 5) == disp(eval_layers([[&"M16", Op.OFFSET, p]], 1.0, 65), eval_layers([], 0.0, 65), 5), "o elemento 5 recebe o mesmo deslocamento com 33 ou 65 amostras (depende só do id)")

	var pr := {"direction": Vector3(0, 0, 1), "cone_deg": 0.0, "radial": 1.0, "origin": Vector3(0, 0, 2), "t_duration": 1.0, "curve": 1.0}
	var rr := run(&"M16", Op.OFFSET, pr, 1.0, 65)
	var radial_ok := true
	var b65 := eval_layers([], 0.0, 65)
	for i in 65:
		if disp(rr, b65, i).angle_to(Vector3(0, 0, -1)) > 1e-3:
			radial_ok = false
	ok(radial_ok, "componente radial: afasta da origem (origem em z=2 → deslocamento ao longo de −Z)")

	var ro1 := run(&"M16", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 1.0, "dissipate": 1.0, "curve": 1.0}, 1.0, 65)
	var ro0 := run(&"M16", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 1.0, "dissipate": 1.0, "curve": 1.0}, 0.0, 65)
	var rhalf := run(&"M16", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 1.0, "dissipate": 0.5, "curve": 1.0}, 1.0, 65)
	ok(near(ro0.samples[3].opacity, 1.0) and near(ro1.samples[3].opacity, 0.0) and near(rhalf.samples[3].opacity, 0.5), "dissipação: opacidade final = 1 − dissipate")
	var rz := run(&"M16", Op.OFFSET, {"direction": Vector3.ZERO, "radial": 0.0}, 1.0)
	ok(finite_ok(rz), "direção nula não gera NaN")
	var rx := run(&"M16", Op.OFFSET, {"direction": Vector3(1, 0, 0), "cone_deg": 20.0}, 1.0, 257)
	var sx := 0.0
	var sy := 0.0
	for i in 257:
		var d := disp(rx, base, i)
		sx += d.x
		sy += absf(d.y)
	ok(sx > sy * 3.0, "direção configurável (+X)")


func _mean_angle(r: MotionResult, base: MotionResult) -> float:
	var s := 0.0
	for i in r.samples.size():
		s += disp(r, base, i).angle_to(Vector3(0, 0, 1))
	return s / float(r.samples.size())


# --------------------------------------------------------------------------------------
func t_m17() -> void:
	print("\n-- M17 Crescimento progressivo --")
	var p := {"t_start": 0.0, "t_duration": 1.0, "curve": 1.0, "width": 0.0}
	var r0 := run(&"M17", Op.MASK, p, 0.0)
	var rh := run(&"M17", Op.MASK, p, 0.5)
	var r1 := run(&"M17", Op.MASK, p, 1.0)
	ok(visible_count(r0) == 0, "no início nada está visível")
	ok(visible_count(r1) == 65, "no fim tudo está visível")
	var prefix := true
	var cut := -1
	for i in 65:
		if rh.samples[i].visible:
			if cut >= 0:
				prefix = false
		elif cut < 0:
			cut = i
	ok(prefix and cut >= 31 and cut <= 34, "direção 0: trecho visível é um prefixo que cresce (corte em %d)" % cut)
	var prev := 0
	var monotone := true
	for k in 11:
		var n := visible_count(run(&"M17", Op.MASK, p, float(k) / 10.0))
		if n < prev:
			monotone = false
		prev = n
	ok(monotone, "a região visível nunca encolhe com o tempo")

	var pd := p.duplicate()
	pd["direction"] = 1
	var rd := run(&"M17", Op.MASK, pd, 0.5)
	ok(rd.samples[64].visible and not rd.samples[0].visible, "direção 1: cresce do fim para o início")
	var pc := p.duplicate()
	pc["direction"] = 2
	var rc := run(&"M17", Op.MASK, pc, 0.5)
	ok(rc.samples[32].visible and not rc.samples[0].visible and not rc.samples[64].visible, "direção 2: cresce do centro para as bordas")

	var pw := p.duplicate()
	pw["width"] = 0.3
	var rw := run(&"M17", Op.MULTIPLY_ATTRIBUTE, pw, 0.5)
	var has_partial := false
	for s in rw.samples:
		if s.width > 0.02 and s.width < 0.98:
			has_partial = true
	ok(has_partial and near(rw.samples[0].width, 1.0, 0.02) and near(rw.samples[64].width, 0.0, 0.02), "largura de transição produz borda gradual")
	ok(near(rw.samples[32].width, 0.5, 1e-3), "a frente avança até progresso × (1 + largura): u=0,5 fica em 50 %% (obtido %.3f)" % rw.samples[32].width)
	ok(near(run(&"M17", Op.MULTIPLY_ATTRIBUTE, pw, 1.0).samples[64].width, 1.0, 1e-6), "no fim, mesmo com transição larga, tudo em 1")
	ok(near(run(&"M17", Op.MULTIPLY_ATTRIBUTE, pw, 0.0).samples[0].width, 0.0, 1e-6), "no início, mesmo com transição larga, tudo em 0")

	var pcurve := p.duplicate()
	pcurve["curve"] = 2.0
	var rcv := run(&"M17", Op.MASK, pcurve, 0.5)
	ok(visible_count(rcv) < visible_count(rh) and abs(visible_count(rcv) - 16) <= 2, "curva 2: a 50 %% do tempo cresceu 25 %% (visíveis=%d)" % visible_count(rcv))

	var pf := {"t_duration": 1.0, "width": 0.0, "affect_width": false, "affect_intensity": true, "affect_opacity": true, "affect_visibility": false}
	var rf := run(&"M17", Op.MULTIPLY_ATTRIBUTE, pf, 0.5)
	ok(near(rf.samples[60].intensity, 0.0, 1e-6) and near(rf.samples[60].opacity, 0.0, 1e-6) and near(rf.samples[60].width, 1.0, 1e-6)
		and near(rf.samples[2].intensity, 1.0, 1e-6), "canais selecionáveis: intensidade e opacidade sem espessura")
	var rm := run(&"M17", Op.MASK, pf, 0.0)
	ok(visible_count(rm) == 65, "visibilidade desligada: nada some")

	var pj := p.duplicate()
	pj["width"] = 0.2
	pj["jitter"] = 1.0
	var rj1 := run(&"M17", Op.MASK, pj, 0.5)
	var rj2 := run(&"M17", Op.MASK, pj, 0.5)
	var ragged := false
	var seen_off := false
	for i in 65:
		if rj1.samples[i].visible != rj2.samples[i].visible:
			ragged = true
		if rj1.samples[i].visible:
			if seen_off:
				ragged = ragged or false
		else:
			seen_off = true
	var interleave := false
	var found_off := false
	for s in rj1.samples:
		if not s.visible:
			found_off = true
		elif found_off:
			interleave = true
	ok(not ragged, "irregularidade (jitter) é determinística")
	ok(interleave, "jitter 1 produz borda irregular (visíveis depois de invisíveis)")
	var rpos := run(&"M17", Op.MASK, p, 0.5)
	var untouched := true
	for i in 65:
		if rpos.samples[i].position != eval_layers([], 0.5).samples[i].position:
			untouched = false
	ok(untouched, "MASK não altera a geometria")


func t_m18() -> void:
	print("\n-- M18 Dissolução progressiva --")
	var p := {"t_start": 0.0, "t_duration": 1.0, "curve": 1.0, "width": 0.0}
	ok(visible_count(run(&"M18", Op.MASK, p, 0.0)) == 65, "no início tudo está visível")
	ok(visible_count(run(&"M18", Op.MASK, p, 1.0)) == 0, "no fim nada resta")
	var rh := run(&"M18", Op.MASK, p, 0.5)
	var suffix := true
	var seen := false
	for i in 65:
		if rh.samples[i].visible:
			seen = true
		elif seen:
			suffix = false
	ok(suffix and not rh.samples[0].visible and rh.samples[64].visible, "direção 0: a cauda (início) some primeiro; resta um sufixo")
	var pd := p.duplicate()
	pd["direction"] = 1
	var rd := run(&"M18", Op.MASK, pd, 0.5)
	ok(rd.samples[0].visible and not rd.samples[64].visible, "direção 1: some do fim para o início")
	var pw := p.duplicate()
	pw["width"] = 0.3
	var grow := run(&"M17", Op.MULTIPLY_ATTRIBUTE, pw, 0.4)
	var diss := run(&"M18", Op.MULTIPLY_ATTRIBUTE, pw, 0.4)
	var comp := true
	for i in 65:
		if not near(grow.samples[i].width + diss.samples[i].width, 1.0, 1e-5):
			comp = false
	ok(comp, "crescimento + dissolução com os mesmos parâmetros somam 1 (complementares)")
	var rpf := run(&"M18", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 1.0, "width": 0.0, "affect_width": false, "affect_intensity": true}, 0.5)
	ok(near(rpf.samples[0].intensity, 0.0, 1e-6) and near(rpf.samples[64].intensity, 1.0, 1e-6) and near(rpf.samples[3].width, 1.0, 1e-6), "atua sobre a intensidade sem tocar na espessura")
	var rt := run(&"M18", Op.MULTIPLY_ATTRIBUTE, {"t_start": 1.0, "t_duration": 1.0, "width": 0.0}, 0.5)
	ok(near(rt.samples[0].width, 1.0, 1e-6), "antes do início temporal: nada some")
	var pj := p.duplicate()
	pj["jitter"] = 1.0
	pj["width"] = 0.2
	var rj := run(&"M18", Op.MASK, pj, 0.5)
	var rj_seed := eval_layers([[&"M18", Op.MASK, pj]], 0.5, 65, 123)
	var differs := false
	for i in 65:
		if rj.samples[i].visible != rj_seed.samples[i].visible:
			differs = true
	ok(differs, "a semente da composição muda o padrão irregular da dissolução")


func t_combined() -> void:
	print("\n-- Combinação com a Etapa 2 --")
	# espiral → crescimento → pulso → dissolução: tudo pela biblioteca
	var layers := [
		[&"M01", Op.REPLACE, {"radius": 0.25, "pitch": 0.5, "turns": 3.0}],
		[&"M17", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 1.0, "width": 0.2}],
		[&"M12", Op.MULTIPLY_ATTRIBUTE, {"speed": 0.5, "start": 0.0}],
		[&"M18", Op.MULTIPLY_ATTRIBUTE, {"t_start": 1.0, "t_duration": 1.0, "width": 0.2}],
		[&"M16", Op.OFFSET, {"t_start": 1.5, "t_duration": 0.5, "distance": 0.5}],
	]
	var a := eval_layers(layers, 0.6)
	var b := eval_layers(layers, 1.7)
	ok(finite_ok(a) and finite_ok(b), "cinco camadas encadeadas avaliam sem erro em dois instantes")
	ok(a.samples[20].width != b.samples[20].width, "o estado muda entre os instantes")
	var again := eval_layers(layers, 1.7)
	var same := true
	for i in 65:
		if b.samples[i].position != again.samples[i].position or b.samples[i].width != again.samples[i].width:
			same = false
	ok(same, "composição reproduzível")
