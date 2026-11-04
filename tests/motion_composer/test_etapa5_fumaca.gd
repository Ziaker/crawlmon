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
	t_order()
	t_view()
	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "parâmetros e ordenação dos puffs são funções puras (não criam nós)")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_puffs() -> void:
	print("
-- Parâmetros de cada baforada --")
	var s := MotionSample.make_rest(0.5, 21, 1.0)
	var a := MotionSmokeView.puff_params(s, 0.35, 0.9, 1.6)
	ok(a == MotionSmokeView.puff_params(s, 0.35, 0.9, 1.6), "determinístico por elemento")
	var rolls := {}
	var min_size := 9.0
	var max_size := 0.0
	var seen_frames := {}
	for id in 300:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		var p := MotionSmokeView.puff_params(sm, 0.35, 0.9, 1.6)
		rolls[snappedf(p["roll"], 0.01)] = true
		min_size = minf(min_size, p["size"])
		max_size = maxf(max_size, p["size"])
		seen_frames[p["frame"]] = true
	ok(rolls.size() > 150, "giro (roll) varia de elemento para elemento (%d valores distintos em 300)" % rolls.size())
	ok(min_size >= 0.35 * 0.8 - 1e-6 and max_size <= 0.35 * 1.2 + 1e-6 and max_size - min_size > 0.04, "tamanho entre 80 %% e 120 %% do base (%.3f a %.3f)" % [min_size, max_size])
	ok(seen_frames.size() == 4 and seen_frames.has(0) and seen_frames.has(3), "as 4 variações do atlas são usadas, todas entre 0 e 3")
	var aged := MotionSample.make_rest(0.5, 21, 1.0)
	aged.age = 0.5
	ok(MotionSmokeView.puff_params(aged, 0.35, 0.9, 1.6)["frame"] == a["frame"] and MotionSmokeView.puff_params(aged, 0.35, 0.9, 1.6)["roll"] == a["roll"], "variação e giro não mudam com a idade (a baforada não pisca)")
	# crescimento com a idade (o jogo usa 1,4 a 1,6 ao fim da vida)
	var g0: float = MotionSmokeView.puff_params(s, 0.35, 0.9, 1.6)["size"]
	aged.age = 0.9
	ok(near(MotionSmokeView.puff_params(aged, 0.35, 0.9, 1.6)["size"], g0 * 1.6), "ao fim da vida a baforada tem 1,6× o tamanho inicial")
	aged.age = 0.45
	ok(near(MotionSmokeView.puff_params(aged, 0.35, 0.9, 1.6)["size"], g0 * 1.3), "no meio da vida, 1,3×")
	aged.age = 5.0
	ok(near(MotionSmokeView.puff_params(aged, 0.35, 0.9, 1.6)["size"], g0 * 1.6), "além da vida o tamanho fica no final")
	ok(near(MotionSmokeView.puff_params(aged, 0.35, 0.9, 1.0)["size"], g0), "crescimento 1: tamanho constante")
	var w := MotionSample.make_rest(0.5, 21, 1.0)
	w.width = 2.0
	ok(near(MotionSmokeView.puff_params(w, 0.35, 0.9, 1.6)["size"], g0 * 2.0), "a largura da amostra multiplica o tamanho")
	w.width = 0.0
	ok(MotionSmokeView.puff_params(w, 0.35, 0.9, 1.6)["size"] == 0.0, "largura 0: tamanho 0")

	print("
-- Subida e abertura pela idade --")
	var o := MotionSample.make_rest(0.5, 21, 1.0)
	ok(MotionSmokeView.puff_offset(o, 0.5, 0.5) == Vector3.ZERO, "amostra atual (idade 0): sem deslocamento")
	o.age = 0.4
	var o1 := MotionSmokeView.puff_offset(o, 0.5, 0.5)
	o.age = 0.8
	var o2 := MotionSmokeView.puff_offset(o, 0.5, 0.5)
	ok(o2.distance_to(o1 * 2.0) < 1e-5, "proporcional à idade (linear)")
	var only_rise := MotionSmokeView.puff_offset(o, 0.5, 0.0)
	ok(only_rise.is_equal_approx(Vector3(0, 0.4, 0)), "sem abertura, só sobe (rise × idade)")
	ok(near((o2 - only_rise).length(), 0.5 * 0.8), "a abertura tem comprimento abertura × idade")
	ok(MotionSmokeView.puff_offset(o, 0.0, 0.0) == Vector3.ZERO, "subida 0 e abertura 0: a vista é fiel às posições")
	var dirs := {}
	var up_ok := true
	for id in 200:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		sm.age = 1.0
		var d := MotionSmokeView.puff_offset(sm, 0.0, 1.0)
		dirs[snappedf(d.x, 0.05)] = true
		if d.y < cos(deg_to_rad(70.0)) - 1e-4 or not near(d.length(), 1.0, 1e-4):
			up_ok = false
	ok(up_ok, "direção de abertura unitária, dentro de um cone de 70° em torno da vertical")
	ok(dirs.size() > 15, "a direção varia por elemento (%d valores distintos de x em 200)" % dirs.size())
	var rep := MotionSample.make_rest(0.0, 5, 1.0)
	rep.age = 0.7
	ok(MotionSmokeView.puff_offset(rep, 0.5, 0.5) == MotionSmokeView.puff_offset(rep, 0.5, 0.5), "determinístico")


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
		if smp.visible and smp.opacity > 0.001 and smp.width > 0.0:
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
	view.show_samples(hidden, Vector3(0, 0, 4))
	ok(view.shown_count == visible_count - 3, "invisíveis, transparentes e de tamanho 0 não são desenhados")
	view.show_samples([] as Array[MotionSample], Vector3.ZERO)
	ok(view.shown_count == 0, "sem amostras, nada desenhado")
	var drawn_pos := PackedVector3Array()
	for smp in s:
		if smp.visible and smp.opacity > 0.001 and smp.width > 0.0:
			drawn_pos.append(smp.position + MotionSmokeView.puff_offset(smp, view.puff_rise, view.puff_spread))
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
