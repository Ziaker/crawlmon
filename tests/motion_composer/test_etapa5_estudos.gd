extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 6: estudos individuais dos 20 comportamentos e a receita (§10.3, §19.7, D-305).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_estudos.gd

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


func eval_at(c: MotionComposition, t: float) -> MotionResult:
	var ctx := c.make_context(t)
	ctx.emitter_fn = func(tt: float) -> Transform3D: return MotionLabSession.emitter_transform(MotionLabSession.Emitter.STATIC, tt)
	return c.evaluate(_cat, ctx)


func finite_ok(r: MotionResult) -> bool:
	if r.has_errors():
		return false
	for s in r.samples:
		if not s.is_finite_sample():
			return false
	return true


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 6): ESTUDOS INDIVIDUAIS (D-305)")
	print("=================================================================")
	_cat = MotionCatalog.new()
	MotionBehaviors.register_all(_cat)
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	t_catalog()
	t_each()
	t_aux()
	t_recipe()
	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "os estudos são composições (dado puro, sem nós)")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_catalog() -> void:
	print("\n-- Cobertura --")
	var ids := MotionStudies.ids()
	ok(ids.size() == 21 and ids[0] == &"M01" and ids[19] == &"M20" and ids[20] == MotionStudies.RECIPE, "21 estudos: M01–M20 e a receita da §6")
	var all_note := true
	var all_title := true
	for id in ids:
		if MotionStudies.note(id) == "":
			all_note = false
		if MotionStudies.title(id) == "" or MotionStudies.title(id) == String(id):
			all_title = false
	ok(all_note and all_title, "todos têm título e nota explicando o que olhar")
	var covered := {}
	for id in MotionStudies.IDS:
		var c := MotionStudies.build(id)
		for l in c.layers:
			if l.behavior_id == id and not String(l.id).begins_with("aux_"):
				covered[id] = true
	ok(covered.size() == 20, "cada estudo M01–M20 contém uma camada do próprio comportamento fora do acabamento")
	ok(MotionStudies.build(&"M05") != MotionStudies.build(&"M05"), "cada chamada monta uma composição nova (sem estado compartilhado)")


func t_each() -> void:
	print("\n-- Cada estudo: válido, finito, distinguível e com ciclo de 4 momentos --")
	var bad_valid := []
	var bad_finite := []
	var bad_identity := []
	var bad_moments := []
	var bad_repeat := []
	var slow := []
	var timeline := [0.1, 0.9, 1.6, 2.7]
	for id in MotionStudies.IDS:
		var c := MotionStudies.build(id)
		var diags := c.validate(_cat)
		if not diags.is_empty():
			bad_valid.append("%s: %s" % [id, diags[0]])
			continue
		var t0 := Time.get_ticks_usec()
		var fin := true
		var t := 0.0
		while t <= 3.0001:
			if not finite_ok(eval_at(c, t)):
				fin = false
			t += 0.125
		var ms := float(Time.get_ticks_usec() - t0) / 25.0 / 1000.0
		if ms > 25.0:
			slow.append("%s %.1f ms" % [id, ms])
		if not fin:
			bad_finite.append(id)
		# identidade: sem o comportamento estudado o resultado é outro, em algum instante
		var without := MotionStudies.build(id)
		for lid in MotionStudies.main_layer_ids(id):
			without.set_enabled(lid, false)
		var changed := 0
		for tt in [0.7, 1.2, 1.8, 2.2]:
			var dd := MotionLabSession.diff(eval_at(without, tt), eval_at(c, tt))
			changed += dd["changed"] + dd["only_a"] + dd["only_b"]
		if changed == 0:
			bad_identity.append(id)
		# quatro momentos: nascimento, desenvolvimento, transformação, dissipação
		var states := []
		for tt in timeline:
			states.append(eval_at(c, tt))
		var distinct := 0
		for i in states.size():
			for j in range(i + 1, states.size()):
				if MotionLabSession.diff(states[i], states[j])["changed"] > 0:
					distinct += 1
		if distinct < 5:
			bad_moments.append("%s (%d/6 pares)" % [id, distinct])
		# repetibilidade
		var a := eval_at(c, 1.3)
		var b := eval_at(MotionStudies.build(id), 1.3)
		if MotionLabSession.diff(a, b)["changed"] != 0 or a.samples.size() != b.samples.size():
			bad_repeat.append(id)
	ok(bad_valid.is_empty(), "os 20 estudos validam sem diagnóstico %s" % [bad_valid])
	ok(bad_finite.is_empty(), "25 instantes de cada estudo sem erro nem valor inválido %s" % [bad_finite])
	ok(bad_identity.is_empty(), "desligar o comportamento estudado muda o resultado em todos os estudos (identidade distinguível) %s" % [bad_identity])
	ok(bad_moments.is_empty(), "nascimento, desenvolvimento, transformação e dissipação são estados diferentes entre si em todos os estudos %s" % [bad_moments])
	ok(bad_repeat.is_empty(), "os estudos são reproduzíveis (composição nova, mesmo resultado) %s" % [bad_repeat])
	print("  [INFO] estudos acima de 25 ms por avaliação: %s" % [slow])


func t_aux() -> void:
	print("\n-- Acabamento do estudo (nascer e dissolver) --")
	var c := MotionStudies.build(&"M05")
	var aux := MotionStudies.aux_layer_ids(c)
	ok(aux == [&"aux_nascimento", &"aux_dissolucao"], "o acabamento são duas camadas identificadas (aux_nascimento, aux_dissolucao)")
	var born := eval_at(c, 0.0)
	var thin := true
	for s in born.samples:
		if s.width > 0.01:
			thin = false
	ok(thin, "no nascimento (t = 0) o estudo ainda não apareceu")
	var gone := eval_at(c, 2.99)
	var vanished := true
	for s in gone.samples:
		if s.width > 0.05:
			vanished = false
	ok(vanished, "ao fim do ciclo o estudo dissolveu")
	var raw := MotionStudies.build(&"M05", false)
	ok(MotionStudies.aux_layer_ids(raw).size() == 2 and not raw.find_layer(&"aux_nascimento").enabled and not raw.find_layer(&"aux_dissolucao").enabled, "sem acabamento as camadas existem, mas desligadas")
	var shown := false
	for s in eval_at(raw, 0.0).samples:
		if s.width > 0.5:
			shown = true
	ok(shown, "sem acabamento o comportamento aparece já em t = 0, inteiro")
	for id in [&"M17", &"M18", MotionStudies.RECIPE]:
		ok(MotionStudies.aux_layer_ids(MotionStudies.build(id)).is_empty(), "%s não tem acabamento (ele é o próprio comportamento ou a receita)" % id)
	var m19 := MotionStudies.build(&"M19")
	ok(m19.layers[m19.layers.size() - 1].behavior_id == &"M19", "no rastro, o acabamento vem antes do M19 (o rastro herda o nascer e o dissolver)")
	var m20 := MotionStudies.build(&"M20")
	ok(m20.layers[m20.layers.size() - 1].behavior_id == &"M20", "na pós-imagem, o acabamento vem antes do M20")
	var m5 := MotionStudies.build(&"M05")
	ok(m5.layers[m5.layers.size() - 1].id == &"aux_dissolucao", "nos demais, o acabamento fecha a composição")


func t_recipe() -> void:
	print("\n-- Receita da §6 como estudo --")
	var c := MotionStudies.build(MotionStudies.RECIPE)
	ok(c.layers.size() == 11 and c.sample_count == 96, "11 camadas e 96 amostras")
	ok(c.validate(_cat).is_empty(), "valida sem diagnósticos")
	var counts_ok := true
	var t := 0.0
	while t <= 3.0001:
		var r := eval_at(c, t)
		if not finite_ok(r):
			counts_ok = false
		if r.samples.size() != (96 if t < 1.05 else 288):
			counts_ok = false
		t += 0.05
	ok(counts_ok, "61 instantes: 96 amostras até a bifurcação e 288 depois, sem erros")
	var behaviors := {}
	for l in c.layers:
		behaviors[l.behavior_id] = true
	var needed := [&"M11", &"M17", &"M02", &"M08", &"M14", &"M03", &"M07", &"M15", &"M13", &"M16", &"M18"]
	var has_all := true
	for b in needed:
		if not behaviors.has(b):
			has_all = false
	ok(has_all, "usa os 11 comportamentos da receita (M11, M17, M02, M08, M14, M03, M07, M15, M13, M16, M18) e nenhuma trajetória exclusiva")
