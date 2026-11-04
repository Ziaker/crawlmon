extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 1: relógio, modo de edição (D-042) e presets em pasta fixa (D-045).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_relogio_presets.gd

const Op := MotionTypes.Op

var _fails: int = 0
var _checks: int = 0


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func near(a: float, b: float, eps: float = 1e-6) -> bool:
	return absf(a - b) <= eps


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


func same_result(a: MotionResult, b: MotionResult) -> bool:
	if a.samples.size() != b.samples.size():
		return false
	for i in a.samples.size():
		var x := a.samples[i]
		var y := b.samples[i]
		if x.position.distance_to(y.position) > 1e-6 or absf(x.width - y.width) > 1e-6 or absf(x.opacity - y.opacity) > 1e-6 or x.element_id != y.element_id or x.branch != y.branch or x.visible != y.visible:
			return false
	return true


func has_code(diags: Array, code: StringName) -> bool:
	for d in diags:
		if d.code == code:
			return true
	return false


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 1): RELÓGIO, EDIÇÃO, PRESETS (D-305)")
	print("=================================================================")
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	t_clock()
	t_session()
	t_presets_roundtrip()
	t_presets_invalid()
	t_presets_files()
	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "relógio, sessão e presets não criam nós")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_clock() -> void:
	print("\n-- Relógio local (§9.1) --")
	var c := MotionClock.new()
	ok(c.time == 0.0 and not c.playing and c.duration == 3.0 and c.speed == 1.0, "estado inicial: parado em 0, ciclo de 3 s, 1x")
	c.advance(1.0)
	ok(c.time == 0.0, "parado não avança")
	c.play()
	c.advance(0.5)
	ok(near(c.time, 0.5), "reproduzir avança em tempo real")
	c.pause()
	c.advance(10.0)
	ok(near(c.time, 0.5), "pausar mantém o tempo")
	c.set_speed(2.0)
	c.play()
	c.advance(0.25)
	ok(near(c.time, 1.0), "velocidade 2x: 0,25 s reais = 0,5 s de animação")
	c.set_speed(0.1)
	var before := c.time
	c.advance(1.0)
	ok(near(c.time, before + 0.1), "velocidade 0,1x")
	ok(MotionClock.SPEEDS == [0.1, 0.25, 0.5, 1.0, 2.0], "velocidades propostas: 0,1x 0,25x 0,5x 1x 2x")
	c.set_speed(100.0)
	ok(c.speed == 8.0, "velocidade limitada")
	c.set_speed(1.0)
	c.pause()
	c.seek(1.0)
	c.step(1)
	ok(near(c.time, 1.0 + 1.0 / 60.0) and not c.playing, "avançar um quadro (1/60 s), pausado")
	c.step(-2)
	ok(near(c.time, 1.0 - 1.0 / 60.0), "retroceder quadros")
	c.seek(-5.0)
	ok(c.time == 0.0, "seek não passa de 0")
	c.seek(99.0)
	ok(c.time == 3.0, "seek não passa da duração")
	c.seek(2.5)
	c.loop = true
	c.play()
	c.advance(1.0)
	ok(near(c.time, 0.5) and c.playing, "laço: volta ao início do ciclo (2,5 + 1,0 → 0,5)")
	c.loop = false
	c.seek(2.5)
	c.play()
	c.advance(1.0)
	ok(c.time == 3.0 and not c.playing, "sem laço: para no fim")
	c.loop = true
	c.set_loop_window(1.0, 2.0)
	ok(c.time == 3.0 or c.time >= 1.0, "janela de laço move o tempo para dentro quando ele estava antes")
	c.seek(1.8)
	c.play()
	c.advance(0.5)
	ok(near(c.time, 1.3) and c.loop_start == 1.0, "repetir um trecho [1, 2]: 1,8 + 0,5 → 1,3")
	ok(c.history_start() == 1.0, "history_start = início do trecho repetido (§19.4)")
	c.restart()
	ok(c.time == 1.0, "reiniciar com trecho: volta ao início do trecho")
	c.loop = false
	ok(c.history_start() == 0.0, "sem laço, o histórico começa em 0")
	c.restart()
	ok(c.time == 0.0, "reiniciar sem laço: volta a 0")


func t_session() -> void:
	print("\n-- Sessão e modo de edição (D-042) --")
	var s := MotionLabSession.new()
	ok(s.edit_mode == MotionLabSession.EditMode.UPDATE_NOW, "modo inicial proposto: atualizar no instante atual")
	ok(s.catalog.missing_v1().is_empty(), "o catálogo da sessão tem os 20 comportamentos")
	s.composition.add_layer(make_layer(&"H", &"M01", Op.REPLACE, {"spin_deg_s": 180.0, "turns": 2.0}))
	s.composition.add_layer(make_layer(&"T", &"M19", Op.PERSIST, {}))
	s.clock.seek(1.2)
	var r0 := s.evaluate()
	ok(not r0.has_errors() and r0.samples.size() == 64 * 11, "avalia 64 amostras + rastro de 10 por elemento")

	# atualizar no instante atual: edita, mantém o tempo, reconstrói os rastros
	s.composition.set_param(&"H", &"radius", 0.5)
	s.notify_edited()
	ok(near(s.clock.time, 1.2), "atualizar: o instante é mantido após a edição")
	var r1 := s.evaluate()
	var fresh := MotionLabSession.new()
	fresh.composition.add_layer(make_layer(&"H", &"M01", Op.REPLACE, {"spin_deg_s": 180.0, "turns": 2.0, "radius": 0.5}))
	fresh.composition.add_layer(make_layer(&"T", &"M19", Op.PERSIST, {}))
	fresh.clock.seek(1.2)
	ok(same_result(r1, fresh.evaluate()), "atualizar: rastros reconstruídos com os novos parâmetros = composição nova no mesmo instante")
	ok(not same_result(r0, r1), "a edição altera o resultado")

	# reiniciar
	s.edit_mode = MotionLabSession.EditMode.RESTART
	s.composition.set_param(&"H", &"radius", 0.4)
	s.notify_edited()
	ok(s.clock.time == 0.0, "reiniciar: volta ao nascimento após a edição")
	s.clock.seek(0.0)
	var rn := s.evaluate()
	var born_hidden := true
	for smp in rn.samples:
		if smp.age > 0.0 and smp.visible:
			born_hidden = false
	ok(born_hidden, "no nascimento nenhum rastro existe ainda (todo o histórico é anterior ao instante 0)")

	# isolamento de camada
	s.edit_mode = MotionLabSession.EditMode.UPDATE_NOW
	s.clock.seek(1.0)
	s.set_solo(&"H")
	var rs := s.evaluate()
	ok(rs.samples.size() == 64 and s.composition.layers.size() == 2, "isolar camada avalia só ela, sem alterar a composição original")
	s.set_solo(&"")
	ok(s.evaluate().samples.size() == 64 * 11, "sem isolamento, volta a avaliar tudo")

	# emissor de demonstração
	ok(MotionLabSession.emitter_transform(MotionLabSession.Emitter.STATIC, 3.0) == Transform3D.IDENTITY, "emissor parado = identidade")
	ok(near(MotionLabSession.emitter_transform(MotionLabSession.Emitter.LINE, 2.0).origin.x, 3.0), "emissor em linha: 1,5 m/s")
	var o := MotionLabSession.emitter_transform(MotionLabSession.Emitter.ORBIT, 1.7).origin
	ok(near(o.length(), 1.2), "emissor em órbita: raio 1,2 m")
	s.emitter_mode = MotionLabSession.Emitter.LINE
	s.composition.set_param(&"T", &"world_space", true)
	var rw := s.evaluate()
	ok(not rw.has_errors() and not has_code(rw.diagnostics, &"layer_emitter_history_missing"), "o laboratório sempre fornece a história do emissor (sem aviso)")
	# a sessão repassa history_start do relógio
	s.clock.loop = true
	s.clock.set_loop_window(1.0, 2.0)
	s.clock.seek(1.02)
	var rl := s.evaluate()
	var hidden := 0
	for smp in rl.samples:
		if smp.age > 0.0 and not smp.visible:
			hidden += 1
	ok(hidden > 0, "ao repetir um trecho, o rastro anterior ao início do trecho fica oculto")


func t_presets_roundtrip() -> void:
	print("\n-- Presets: ida e volta --")
	MotionPresets.dir_override = "user://motion_composer_test_%d" % Time.get_ticks_usec()
	var cat := MotionCatalog.new()
	MotionBehaviors.register_all(cat)
	var c := MotionComposition.new()
	c.id = &"teste"
	c.sample_count = 33
	c.duration = 2.5
	c.seed = 4242
	c.add_layer(make_layer(&"bez", &"M04", Op.REPLACE, {"p1": Vector3(0.2, 0.1, 0.4), "drift_hz": 1.5}))
	var lm := make_layer(&"br", &"M14", Op.BRANCH, {"branches": 3, "split_u": 0.3})
	lm.space = MotionTypes.Space.EMITTER
	c.add_layer(lm)
	var lp := make_layer(&"pul", &"M12", Op.MULTIPLY_ATTRIBUTE, {"loop": true, "speed": 0.7})
	lp.branches = PackedStringArray(["root/br.1", "root/br.2"])
	lp.mask.u_from = 0.2
	lp.mask.feather = 0.1
	lp.mask.time_enabled = true
	lp.mask.t_to = 2.0
	lp.mask.elements = PackedInt64Array([5, 77])
	lp.intensity = 0.8
	lp.time_offset = 0.25
	lp.active_from = 0.1
	lp.active_to = 2.2
	c.add_layer(lp)
	c.add_layer(make_layer(&"tr", &"M19", Op.PERSIST, {"world_space": true, "max_samples": 12}))
	var text := MotionPresets.to_json(c, cat)
	ok(text.begins_with("{") and "crawlmon.motion_composer.preset" in text and '"version": 1' in text, "JSON UTF-8 versionado, com formato identificado")
	ok(not ("Vector3(" in text), "vetores gravados como componentes numéricos explícitos (x, y, z)")
	var res := MotionPresets.from_json(text, cat)
	var c2: MotionComposition = res["composition"]
	ok(c2 != null and res["diagnostics"].is_empty(), "carrega sem diagnósticos")
	var same := c2 != null
	if same:
		for t in [0.0, 0.7, 1.9, 2.4]:
			var e1 := c.evaluate(cat, c.make_context(t))
			var e2 := c2.evaluate(cat, c2.make_context(t))
			if not same_result(e1, e2):
				same = false
	ok(same, "composição carregada produz o mesmo resultado em 4 instantes (ordem, parâmetros, máscaras, ramos, espaço, defasagens, semente)")
	ok(c2.layer_ids() == c.layer_ids() and c2.sample_count == 33 and c2.seed == 4242 and near(c2.duration, 2.5), "ordem e dados da composição preservados")
	var lp2 := c2.find_layer(&"pul")
	ok(lp2.mask.elements == PackedInt64Array([5, 77]) and lp2.branches == PackedStringArray(["root/br.1", "root/br.2"]) and lp2.mask.time_enabled and near(lp2.intensity, 0.8), "máscara, seleção de ramos e intensidade preservadas")
	ok(typeof(c2.find_layer(&"br").params["branches"]) == TYPE_INT and typeof(c2.find_layer(&"bez").params["p1"]) == TYPE_VECTOR3, "tipos dos parâmetros restaurados (int e Vector3)")
	var text2 := MotionPresets.to_json(c2, cat)
	ok(text2 == text, "gravar de novo o que foi carregado gera exatamente o mesmo arquivo (estável)")


func t_presets_invalid() -> void:
	print("\n-- Presets: validação antes de substituir --")
	var cat := MotionCatalog.new()
	MotionBehaviors.register_all(cat)
	var c := MotionComposition.new()
	c.add_layer(make_layer(&"a", &"M01", Op.REPLACE, {"radius": 0.3}))
	var good := MotionPresets.to_dict(c, cat)
	ok(MotionPresets.from_dict(good, cat)["composition"] != null, "base válida")

	var r := MotionPresets.from_json("{ isto não é json", cat)
	ok(r["composition"] == null and has_code(r["diagnostics"], &"preset_parse"), "JSON inválido")
	r = MotionPresets.from_json("[1, 2]", cat)
	ok(r["composition"] == null and has_code(r["diagnostics"], &"preset_format"), "raiz que não é objeto")
	var d := good.duplicate(true)
	d["format"] = "outro.formato"
	ok(MotionPresets.from_dict(d, cat)["composition"] == null, "formato desconhecido")
	d = good.duplicate(true)
	d["version"] = 99
	r = MotionPresets.from_dict(d, cat)
	ok(r["composition"] == null and has_code(r["diagnostics"], &"preset_version"), "versão desconhecida é recusada com mensagem")
	d = good.duplicate(true)
	d["layers"][0]["behavior"] = "M99"
	r = MotionPresets.from_dict(d, cat)
	ok(r["composition"] == null and has_code(r["diagnostics"], &"preset_behavior"), "comportamento ausente no catálogo")
	d = good.duplicate(true)
	d["layers"][0]["behavior_version"] = 7
	r = MotionPresets.from_dict(d, cat)
	ok(r["composition"] == null and has_code(r["diagnostics"], &"preset_behavior_version"), "versão do comportamento diferente exige migração (recusado, não adivinhado)")
	d = good.duplicate(true)
	d["layers"][0]["params"]["inexistente"] = 1.0
	ok(has_code(MotionPresets.from_dict(d, cat)["diagnostics"], &"param_unknown"), "parâmetro desconhecido")
	d = good.duplicate(true)
	d["layers"][0]["params"]["radius"] = "grande"
	ok(has_code(MotionPresets.from_dict(d, cat)["diagnostics"], &"preset_param_type"), "tipo de parâmetro errado")
	d = good.duplicate(true)
	d["layers"][0]["params"]["radius"] = 999.0
	r = MotionPresets.from_dict(d, cat)
	ok(r["composition"] == null and has_code(r["diagnostics"], &"param_domain"), "parâmetro fora do domínio")
	d = good.duplicate(true)
	d["layers"][0]["params"]["direction"] = 0.5
	ok(has_code(MotionPresets.from_dict(d, cat)["diagnostics"], &"preset_param_type"), "inteiro não inteiro")
	d = good.duplicate(true)
	d["layers"][0]["op"] = "VOAR"
	ok(has_code(MotionPresets.from_dict(d, cat)["diagnostics"], &"preset_op"), "operação desconhecida")
	d = good.duplicate(true)
	d["layers"][0]["op"] = "MASK"
	ok(has_code(MotionPresets.from_dict(d, cat)["diagnostics"], &"layer_op_not_accepted"), "operação não aceita pelo comportamento")
	d = good.duplicate(true)
	d["layers"].append(d["layers"][0].duplicate(true))
	ok(has_code(MotionPresets.from_dict(d, cat)["diagnostics"], &"layer_id_duplicate"), "ids de camada duplicados")
	d = good.duplicate(true)
	d["composition"]["sample_count"] = 1.5
	ok(MotionPresets.from_dict(d, cat)["composition"] == null, "sample_count não inteiro")
	d = good.duplicate(true)
	d["composition"]["duration"] = -1
	ok(MotionPresets.from_dict(d, cat)["composition"] == null, "duração negativa (validação da composição)")
	d = good.duplicate(true)
	d["layers"][0]["space"] = "MARTE"
	ok(has_code(MotionPresets.from_dict(d, cat)["diagnostics"], &"preset_space"), "espaço desconhecido")
	d = good.duplicate(true)
	d["layers"][0]["script"] = "extends Node\nfunc _init(): OS.crash()"
	ok(MotionPresets.from_dict(d, cat)["composition"] != null, "chaves estranhas (como 'script') são ignoradas: o carregamento nunca executa código")


func t_presets_files() -> void:
	print("\n-- Presets: pasta fixa --")
	var cat := MotionCatalog.new()
	MotionBehaviors.register_all(cat)
	var c := MotionComposition.new()
	c.add_layer(make_layer(&"a", &"M03", Op.OFFSET, {"amplitude": 0.2}))
	ok(MotionPresets.DIR == "user://motion_composer/presets", "pasta fixa proposta: user://motion_composer/presets")
	for bad in ["", "../fora", "a/b", "a b", "ç", "x".repeat(65), "a.json"]:
		ok(not MotionPresets.valid_name(bad) and not MotionPresets.save(bad, c, cat).is_empty(), "nome recusado: '%s'" % bad.left(12))
	ok(MotionPresets.valid_name("meu_preset-01") and MotionPresets.valid_name("A".repeat(64)), "nomes válidos")
	ok(MotionPresets.list_names().is_empty(), "pasta vazia/inexistente: lista vazia")
	ok(MotionPresets.save("alfa", c, cat).is_empty(), "salvar")
	ok(MotionPresets.save("alfa", c, cat).is_empty(), "salvar de novo substitui")
	var tmp_left := false
	for f in DirAccess.get_files_at(MotionPresets.dir()):
		if f.ends_with(".tmp"):
			tmp_left = true
	ok(not tmp_left, "nenhum arquivo temporário sobra")
	MotionPresets.save("beta", c, cat)
	ok(MotionPresets.list_names() == PackedStringArray(["alfa", "beta"]), "lista ordenada")
	var r := MotionPresets.load_preset("alfa", cat)
	ok(r["composition"] != null and r["composition"].layer_ids() == [&"a"], "carregar")
	ok(MotionPresets.load_preset("nao_existe", cat)["composition"] == null, "carregar inexistente falha com diagnóstico")
	var f := FileAccess.open(MotionPresets.path_for("quebrado"), FileAccess.WRITE)
	f.store_string("{ corrompido")
	f.close()
	var rq := MotionPresets.load_preset("quebrado", cat)
	ok(rq["composition"] == null and not rq["diagnostics"].is_empty(), "arquivo corrompido: erro explícito, nada é substituído")
	for n in ["alfa", "beta", "quebrado"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MotionPresets.path_for(n)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MotionPresets.dir()))
	MotionPresets.dir_override = ""
