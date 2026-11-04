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
	print("\n-- Parâmetros de cada puff --")
	var s := MotionSample.make_rest(0.5, 21, 1.0)
	var a := MotionSmokeView.puff_params(s, 0.12, 0.8)
	ok(a == MotionSmokeView.puff_params(s, 0.12, 0.8), "determinístico por elemento")
	var rolls := {}
	var min_size := 9.0
	var max_size := 0.0
	var frames_ok := true
	for id in 300:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		var p := MotionSmokeView.puff_params(sm, 0.12, 0.8)
		rolls[snappedf(p["roll"], 0.01)] = true
		min_size = minf(min_size, p["size"])
		max_size = maxf(max_size, p["size"])
		if p["frame"] < 3 or p["frame"] > 6:
			frames_ok = false
	ok(rolls.size() > 150, "giro (roll) varia de elemento para elemento (%d valores distintos em 300)" % rolls.size())
	ok(min_size >= 0.12 * 0.8 - 1e-6 and max_size <= 0.12 * 1.2 + 1e-6 and max_size - min_size > 0.015, "tamanho entre 80 %% e 120 %% do base (%.3f a %.3f)" % [min_size, max_size])
	ok(frames_ok, "amostras atuais usam um quadro de corpo da fumaça (3 a 6)")
	var w := MotionSample.make_rest(0.5, 21, 1.0)
	w.width = 2.0
	ok(near(MotionSmokeView.puff_params(w, 0.12, 0.8)["size"], a["size"] * 2.0), "a largura da amostra multiplica o tamanho")
	w.width = 0.0
	ok(MotionSmokeView.puff_params(w, 0.12, 0.8)["size"] == 0.0, "largura 0: tamanho 0")
	# o quadro acompanha a idade: nasce pequeno, enche e dissipa (a folha tem o ciclo de vida de uma baforada)
	var frames: Array[int] = []
	for age in [0.05, 0.2, 0.4, 0.6, 0.8, 2.0]:
		var sm := MotionSample.make_rest(0.5, 21, 1.0)
		sm.age = age
		frames.append(MotionSmokeView.puff_params(sm, 0.12, 0.8)["frame"])
	ok(frames == [1, 4, 8, 11, 15, 15], "quadro pela idade: 0,05 s → 1, 0,2 → 4, 0,4 → 8, 0,6 → 11, 0,8 → 15, além da vida fica no último (%s)" % [frames])
	var mono := true
	for i in range(1, frames.size()):
		if frames[i] < frames[i - 1]:
			mono = false
	ok(mono, "o quadro nunca recua com a idade")
	var sm0 := MotionSample.make_rest(0.5, 21, 1.0)
	sm0.age = 0.3
	var other := MotionSample.make_rest(0.5, 99, 1.0)
	other.age = 0.3
	ok(MotionSmokeView.puff_params(sm0, 0.12, 0.8)["frame"] == MotionSmokeView.puff_params(other, 0.12, 0.8)["frame"], "o quadro de uma baforada em andamento depende só da idade")
	ok(MotionSmokeView.puff_params(sm0, 0.12, 0.4)["frame"] > MotionSmokeView.puff_params(sm0, 0.12, 0.8)["frame"], "vida menor, quadro mais adiantado")


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
	var tex := mat.get_shader_parameter("sheet_tex") as Texture2D
	ok(tex != null and tex.resource_path == "res://assets/vfx/flipbook_smoke.png", "reaproveita a folha de fumaça que o jogo já tem (assets/vfx/flipbook_smoke.png), sem construtores com temporizador")
	ok(mat.get_shader_parameter("h_frames") == 4 and mat.get_shader_parameter("v_frames") == 4, "folha 4 × 4 (16 quadros)")
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
			drawn_pos.append(smp.position)
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
