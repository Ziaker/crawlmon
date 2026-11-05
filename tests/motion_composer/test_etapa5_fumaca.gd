extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 4: representação Fumaça/billboards (D-044, D-305).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_fumaca.gd

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


func near(a: float, b: float, eps: float = 1e-5) -> bool:
	return absf(a - b) <= eps


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


func trail_samples(t: float, n: int = 16) -> Array[MotionSample]:
	var c := MotionComposition.new()
	c.sample_count = n
	c.seed = 5
	c.add_layer(make_layer(&"h", &"M01", Op.REPLACE, {"radius": 0.1, "pitch": 0.3, "turns": 1.0}))
	c.add_layer(make_layer(&"t", &"M19", Op.PERSIST, {"duration": 0.8, "sample_interval": 0.05}))
	return c.evaluate(_cat, c.make_context(t)).samples


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 4): FUMAÇA/BILLBOARDS (D-305)")
	print("=================================================================")
	_cat = MotionCatalog.new()
	MotionBehaviors.register_all(_cat)
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	t_puffs()
	t_opacity()
	t_order()
	t_view()
	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "parâmetros e ordenação dos puffs são funções puras (não criam nós)")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_puffs() -> void:
	print("
-- Parâmetros de cada baforada (regras da poeira do jogo) --")
	var s := MotionSample.make_rest(0.5, 21, 1.0)
	var a := MotionSmokeView.puff_params(s, 0.85, 0.38, 1.8)
	ok(a == MotionSmokeView.puff_params(s, 0.85, 0.38, 1.8), "determinístico por elemento")
	var rolls := {}
	var min_size := 9.0
	var max_size := 0.0
	var seen_frames := {}
	for id in 300:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		var p := MotionSmokeView.puff_params(sm, 0.85, 0.38, 1.8)
		rolls[snappedf(p["roll"], 0.01)] = true
		min_size = minf(min_size, p["size"])
		max_size = maxf(max_size, p["size"])
		seen_frames[p["frame"]] = true
	ok(rolls.size() > 150, "giro (roll) varia de elemento para elemento (%d valores distintos em 300)" % rolls.size())
	ok(min_size >= 0.85 * 0.65 - 1e-6 and max_size <= 0.85 * 1.35 + 1e-6 and min_size < 0.6 and max_size > 1.1, "tamanho de 0,55 a 1,15 m como a poeira do jogo (%.2f a %.2f)" % [min_size, max_size])
	ok(seen_frames.size() == 4 and seen_frames.has(0) and seen_frames.has(3), "as 4 variações do atlas são usadas, todas entre 0 e 3")
	var aged := MotionSample.make_rest(0.5, 21, 1.0)
	aged.age = 0.2
	ok(MotionSmokeView.puff_params(aged, 0.85, 0.38, 1.8)["frame"] == a["frame"] and MotionSmokeView.puff_params(aged, 0.85, 0.38, 1.8)["roll"] == a["roll"], "variação e giro não mudam com a idade (a baforada não pisca)")
	var g0: float = MotionSmokeView.puff_params(s, 0.85, 0.38, 1.8)["size"]
	aged.age = 0.38
	ok(near(MotionSmokeView.puff_params(aged, 0.85, 0.38, 1.8)["size"], g0 * 1.8), "ao fim da vida a baforada tem 1,8× o tamanho inicial (end_scale do jogo)")
	aged.age = 0.19
	ok(near(MotionSmokeView.puff_params(aged, 0.85, 0.38, 1.8)["size"], g0 * 1.4), "no meio da vida, 1,4×")
	aged.age = 5.0
	ok(near(MotionSmokeView.puff_params(aged, 0.85, 0.38, 1.8)["size"], g0 * 1.8), "além da vida o tamanho fica no final")
	ok(near(MotionSmokeView.puff_params(aged, 0.85, 0.38, 1.0)["size"], g0), "crescimento 1: tamanho constante")
	var w := MotionSample.make_rest(0.5, 21, 1.0)
	w.width = 2.0
	ok(near(MotionSmokeView.puff_params(w, 0.85, 0.38, 1.8)["size"], g0 * 2.0), "a largura da amostra multiplica o tamanho")
	w.width = 0.0
	ok(MotionSmokeView.puff_params(w, 0.85, 0.38, 1.8)["size"] == 0.0, "largura 0: tamanho 0")

	print("
-- Rampa de opacidade pela vida (jogo: 0 → 0,75 aos 20 % → 0) --")
	ok(MotionSmokeView.puff_alpha(0.0, 0.38) == 1.0, "amostra atual (idade 0), sem vida: opacidade plena")
	ok(near(MotionSmokeView.puff_alpha(0.038, 0.38), 0.375), "aos 10 % da vida: 0,375 (subindo)")
	ok(near(MotionSmokeView.puff_alpha(0.076, 0.38), 0.75), "aos 20 %: pico de 0,75")
	ok(near(MotionSmokeView.puff_alpha(0.228, 0.38), 0.375), "aos 60 %: 0,375 (descendo)")
	ok(MotionSmokeView.puff_alpha(0.38, 0.38) == 0.0 and MotionSmokeView.puff_alpha(1.0, 0.38) == 0.0, "no fim da vida e depois: some")
	var mono := true
	var prev := 0.0
	for k in range(1, 20):
		var v := MotionSmokeView.puff_alpha(0.019 * k, 0.38)
		if k > 4 and v > prev + 1e-6:
			mono = false
		prev = v
	ok(mono, "depois do pico a opacidade só cai")

	print("
-- Movimento da poeira (atrito, subida, esfera de origem) --")
	var o := MotionSample.make_rest(0.5, 21, 1.0)
	ok(MotionSmokeView.puff_offset(o, 0.5, 3.0, 1.5, 0.25, 0.0) == Vector3.ZERO, "amostra atual sem raio de origem: sem deslocamento")
	o.age = 0.3
	var free := MotionSmokeView.puff_offset(o, 1.0, 1.0, 0.0, 0.0, 0.0)
	ok(near(free.length(), 0.3, 1e-4), "sem atrito: velocidade × idade")
	var damped := MotionSmokeView.puff_offset(o, 1.0, 1.0, 1.5, 0.0, 0.0)
	ok(near(damped.length(), (1.0 - exp(-1.5 * 0.3)) / 1.5, 1e-4) and damped.length() < free.length(), "com atrito 1,5: (1 − e^(−1,5·t)) / 1,5, menos que sem atrito")
	var up := MotionSmokeView.puff_offset(o, 0.0, 0.0, 1.5, 0.25, 0.0)
	ok(up.is_equal_approx(Vector3(0, 0.5 * 0.25 * 0.09, 0)), "sem velocidade, só a subida: ½·g·t²")
	var rr := MotionSmokeView.puff_offset(o, 0.0, 0.0, 1.5, 0.0, 0.4)
	ok(rr.length() <= 0.4 + 1e-5, "o ponto de partida fica dentro da esfera de origem (raio 0,4)")
	var reach := 0.0
	var inside_all := true
	for id in 400:
		var sm0 := MotionSample.make_rest(0.0, id, 1.0)
		var st := MotionSmokeView.puff_offset(sm0, 0.0, 0.0, 1.5, 0.0, 0.4)
		reach = maxf(reach, st.length())
		if st.length() > 0.4 + 1e-5:
			inside_all = false
	ok(inside_all and reach > 0.34, "o ponto de partida preenche a esfera de origem (alcance máximo %.2f de 0,4 m)" % reach)
	var mean := Vector3.ZERO
	var far := 0.0
	var spread_y_neg := 0
	var n := 400
	for id in n:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		sm.age = 0.2
		var d := MotionSmokeView.puff_offset(sm, 0.5, 3.0, 1.5, 0.0, 0.4)
		mean += d
		far = maxf(far, d.length())
		if d.y < 0.0:
			spread_y_neg += 1
	mean /= float(n)
	ok(mean.length() < 0.1, "direções cobrem a esfera toda (deslocamento médio %.3f ≈ 0)" % mean.length())
	ok(spread_y_neg > 120 and spread_y_neg < 280, "metade das baforadas sai para baixo (o chão do laboratório oculta essa metade)")
	ok(far > 0.35 and far < 1.0, "alcance de abertura em 0,2 s entre 0,35 e 1 m (%.2f)" % far)
	o.age = 0.2
	ok(MotionSmokeView.puff_offset(o, 0.5, 3.0, 1.5, 0.25, 0.4) == MotionSmokeView.puff_offset(o, 0.5, 3.0, 1.5, 0.25, 0.4), "determinístico")


func t_opacity() -> void:
	print("\n-- Jogo da opacidade: densidade, oscilação e curva --")
	var dens := []
	var lo := 9.0
	var hi := 0.0
	for id in 400:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		var d := MotionSmokeView.puff_density(sm, 0.65)
		dens.append(d)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	ok(lo >= 0.35 - 1e-6 and hi <= 1.0 and lo < 0.4 and hi > 0.97, "densidade de cada baforada entre 0,35 e 1 (%.2f a %.2f)" % [lo, hi])
	var buckets := {}
	for d in dens:
		buckets[int(d * 10.0)] = true
	ok(buckets.size() >= 6, "a densidade se espalha por toda a faixa (%d faixas de 0,1 usadas)" % buckets.size())
	var sm7 := MotionSample.make_rest(0.0, 7, 1.0)
	ok(MotionSmokeView.puff_density(sm7, 0.0) == 1.0, "variação 0: todas iguais")
	ok(MotionSmokeView.puff_density(sm7, 0.65) == MotionSmokeView.puff_density(sm7, 0.65), "determinístico")

	var fl := MotionSample.make_rest(0.0, 9, 1.0)
	ok(MotionSmokeView.puff_flicker_factor(fl, 0.35) == 1.0, "amostra atual não oscila")
	var fmin := 9.0
	var fmax := 0.0
	var moves := 0
	var prev := -1.0
	for k in range(1, 61):
		fl.age = 0.01 * float(k)
		var f := MotionSmokeView.puff_flicker_factor(fl, 0.35)
		fmin = minf(fmin, f)
		fmax = maxf(fmax, f)
		if prev >= 0.0 and absf(f - prev) > 1e-6:
			moves += 1
		prev = f
	ok(fmin >= 0.65 - 1e-6 and fmax <= 1.0 + 1e-9 and fmax - fmin > 0.2, "a oscilação fica entre 1 − quantidade e 1 e é bem visível (%.2f a %.2f)" % [fmin, fmax])
	ok(moves > 50, "a opacidade muda a cada instante da vida")
	var phases := {}
	for id in 200:
		var pf := MotionSample.make_rest(0.0, id, 1.0)
		pf.age = 0.2
		phases[snappedf(MotionSmokeView.puff_flicker_factor(pf, 0.35), 0.02)] = true
	ok(phases.size() > 8, "cada baforada oscila em fase própria (%d valores distintos na mesma idade)" % phases.size())
	ok(MotionSmokeView.puff_flicker_factor(fl, 0.0) == 1.0, "oscilação 0: opacidade fiel à rampa")
	var start_phases := {}
	for id in 200:
		var pf2 := MotionSample.make_rest(0.0, id, 1.0)
		pf2.age = 0.001
		start_phases[snappedf(MotionSmokeView.puff_flicker_factor(pf2, 0.35), 0.02)] = true
	ok(start_phases.size() > 8, "logo no início da vida cada baforada já está em fase própria (%d valores distintos)" % start_phases.size())

	ok(near(MotionSmokeView.puff_alpha(0.3, 0.5, 1.0), MotionSmokeView.puff_alpha(0.3, 0.5)), "expoente 1 é a rampa reta do jogo")
	var linear := MotionSmokeView.puff_alpha(0.3, 0.5, 1.0)
	var soft := MotionSmokeView.puff_alpha(0.3, 0.5, 2.0)
	ok(soft < linear and soft > 0.0, "expoente maior esmaece mais logo depois do pico (%.3f < %.3f)" % [soft, linear])
	ok(near(MotionSmokeView.puff_alpha(0.1, 0.5, 3.0), 0.75) and MotionSmokeView.puff_alpha(0.5, 0.5, 3.0) == 0.0, "o pico e o fim não dependem do expoente")
	ok(MotionSmokeView.puff_alpha(0.3, 0.5, 0.5) > linear, "expoente menor que 1 mantém mais opacidade (cauda longa)")

	var view := MotionSmokeView.new()
	var s0 := MotionSample.make_rest(0.0, 3, 1.0)
	s0.age = 0.2
	var a_full := view.puff_final_alpha(s0)
	s0.opacity = 0.5
	ok(near(view.puff_final_alpha(s0), a_full * 0.5), "a opacidade da amostra multiplica a final")
	var s_ex := MotionSample.make_rest(0.0, 3, 1.0)
	s_ex.age = 0.2
	var expected := MotionSmokeView.puff_alpha(0.2, view.puff_life, view.puff_fade_pow) * MotionSmokeView.puff_density(s_ex, view.puff_density_var) * MotionSmokeView.puff_flicker_factor(s_ex, view.puff_flicker)
	ok(near(view.puff_final_alpha(s_ex), expected) and MotionSmokeView.puff_flicker_factor(s_ex, view.puff_flicker) < 0.999, "a opacidade final é rampa × densidade × oscilação (a oscilação conta de fato)")
	view.puff_density_var = 0.0
	view.puff_flicker = 0.0
	view.puff_fade_pow = 1.0
	s0.opacity = 1.0
	ok(near(view.puff_final_alpha(s0), MotionSmokeView.puff_alpha(0.2, view.puff_life)), "sem densidade, oscilação nem curva, a opacidade final é a rampa do jogo")
	view.free()
	var v2 := MotionSmokeView.new()
	var vmin := 9.0
	var vmax := 0.0
	for id in 300:
		var sx := MotionSample.make_rest(0.0, id, 1.0)
		sx.age = 0.2
		var af := v2.puff_final_alpha(sx)
		vmin = minf(vmin, af)
		vmax = maxf(vmax, af)
	ok(vmax - vmin > 0.25, "a opacidade final varia muito entre baforadas da mesma idade (%.2f a %.2f)" % [vmin, vmax])
	v2.free()


func t_order() -> void:
	print("\n-- Ordenação de translúcidos (§19.5) --")
	var pos := PackedVector3Array([Vector3(0, 0, 1), Vector3(0, 0, 5), Vector3(0, 0, 3), Vector3(0, 0, -2)])
	var order := MotionSmokeView.back_to_front(pos, Vector3(0, 0, 10))
	ok(order == PackedInt32Array([3, 0, 2, 1]), "do mais distante ao mais próximo da câmera (%s)" % [order])
	ok(MotionSmokeView.back_to_front(pos, Vector3(0, 0, -10)) == PackedInt32Array([1, 2, 0, 3]), "outra câmera, outra ordem")
	var tie := PackedVector3Array([Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0)])
	ok(MotionSmokeView.back_to_front(tie, Vector3(0, 0, 5)) == MotionSmokeView.back_to_front(tie, Vector3(0, 0, 5)), "empates desempatam sempre da mesma forma")
	ok(MotionSmokeView.back_to_front(tie, Vector3(0, 0, 5)) == PackedInt32Array([0, 1, 2]), "empate de distância: menor índice primeiro")
	ok(MotionSmokeView.back_to_front(PackedVector3Array(), Vector3.ZERO).is_empty(), "sem puffs, sem ordem")
	var perm := MotionSmokeView.back_to_front(pos, Vector3(3, 2, 1))
	var seen := {}
	for i in perm:
		seen[i] = true
	ok(perm.size() == 4 and seen.size() == 4, "a ordem é uma permutação (nenhum puff perdido ou repetido)")


func t_view() -> void:
	print("\n-- Representação (MultiMesh de quads + shader) --")
	var view := MotionSmokeView.new()
	root.add_child(view)
	var s := trail_samples(1.0)
	view.show_samples(s, Vector3(0, 0, 4))
	var visible_count := 0
	for smp in s:
		if smp.visible and view.puff_final_alpha(smp) > 0.001 and smp.width > 0.0:
			visible_count += 1
	ok(view.shown_count == visible_count and view.shown_count > 0, "um puff por amostra visível (%d)" % view.shown_count)
	var mmi := view.get_child(0) as MultiMeshInstance3D
	ok(mmi.multimesh.mesh is QuadMesh and mmi.multimesh.use_colors and mmi.multimesh.use_custom_data, "MultiMesh de QuadMesh com cor e dados por instância (giro e quadro)")
	var mat := (mmi.multimesh.mesh as QuadMesh).material as ShaderMaterial
	ok(mat != null and mat.shader.resource_path.ends_with(".gdshader") and mat.shader.code.contains("shader_type spatial"), "ShaderMaterial com .gdshader (spatial), sem HTML")
	ok(mat.shader.code.contains("blend_mix") and not mat.shader.code.contains("blend_add"), "mistura alfa (blend_mix), sem depender de adição luminosa (§19.5)")
	var tex := mat.get_shader_parameter("puff_tex") as Texture2D
	ok(tex != null and tex == MotionSmokeView.make_puff_atlas() and tex.get_width() == 128 and tex.get_height() == 128, "atlas de baforadas 2 × 2 (128 px) gerado por ruído suave, no estilo do jogo, sem temporizadores")
	ok(mat.get_shader_parameter("h_frames") == 2 and mat.get_shader_parameter("v_frames") == 2, "atlas 2 × 2 (4 variações)")
	var img := tex.get_image()
	var cell_sum := []
	for v in 4:
		var acc := 0.0
		for y in 64:
			for x in 64:
				acc += img.get_pixel((v % 2) * 64 + x, (v / 2) * 64 + y).a
		cell_sum.append(acc)
	var distinct := true
	for i in 4:
		for j in range(i + 1, 4):
			if absf(cell_sum[i] - cell_sum[j]) < 1.0:
				distinct = false
	ok(distinct, "as 4 variações do atlas são diferentes entre si")
	ok(img.get_pixel(0, 0).a == 0.0 and img.get_pixel(127, 0).a == 0.0 and img.get_pixel(0, 127).a == 0.0, "cantos transparentes: a baforada não tem borda dura nem sangra no vizinho")
	var peak := 0.0
	for y in range(20, 44):
		for x in range(20, 44):
			peak = maxf(peak, img.get_pixel(x, y).a)
	ok(peak > 0.5, "o miolo da baforada é denso (alfa máximo %.2f)" % peak)
	var hidden := trail_samples(1.0)
	hidden[0].visible = false
	hidden[1].opacity = 0.0
	hidden[2].width = 0.0
	ok(s.size() > 0 and visible_count < s.size(), "baforadas mais velhas que a vida (%.2f s) e amostras sem opacidade não são desenhadas (%d de %d)" % [view.puff_life, visible_count, s.size()])
	view.show_samples(hidden, Vector3(0, 0, 4))
	ok(view.shown_count == visible_count - 3, "invisíveis, transparentes e de tamanho 0 não são desenhados")
	view.show_samples([] as Array[MotionSample], Vector3.ZERO)
	ok(view.shown_count == 0, "sem amostras, nada desenhado")
	var drawn_pos := PackedVector3Array()
	for smp in s:
		if smp.visible and view.puff_final_alpha(smp) > 0.001 and smp.width > 0.0:
			drawn_pos.append(smp.position + MotionSmokeView.puff_offset(smp, view.puff_speed_min, view.puff_speed_max, view.puff_damping, view.puff_rise, view.puff_radius))
	view.show_samples(s, Vector3(0, 0, 4))
	ok(view.last_order == MotionSmokeView.back_to_front(drawn_pos, Vector3(0, 0, 4)), "a vista desenha na ordem do mais distante ao mais próximo da câmera")
	view.show_samples(s, Vector3.INF)
	ok(view.shown_count == visible_count and view.last_order == PackedInt32Array(range(visible_count)), "sem câmera conhecida, desenha na ordem das amostras")
	var t0 := Time.get_ticks_usec()
	var big := trail_samples(1.0, 64)
	for i in 20:
		view.show_samples(big, Vector3(0, 0, 4))
	print("  [INFO] preencher e ordenar %d puffs: %.2f ms por quadro (GDScript, headless)" % [big.size(), float(Time.get_ticks_usec() - t0) / 20.0 / 1000.0])
	view.queue_free()
