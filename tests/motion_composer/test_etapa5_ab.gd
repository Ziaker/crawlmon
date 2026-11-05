extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 5: comparação A/B (§10.4, §19.5, D-305).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_ab.gd
## "A/B mantém duas revisões imutáveis com o mesmo tempo e semente."

const Op := MotionTypes.Op
const AB := MotionLabSession.AbMode

var _fails: int = 0
var _checks: int = 0


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func near(a: float, b: float, eps: float = 1e-4) -> bool:
	return absf(a - b) <= eps


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


func new_session() -> MotionLabSession:
	var s := MotionLabSession.new()
	s.composition.sample_count = 32
	s.composition.seed = 11
	s.composition.add_layer(make_layer(&"helice", &"M01", Op.REPLACE, {"radius": 0.3, "pitch": 0.5, "turns": 2.0, "spin_deg_s": 90.0}))
	s.composition.add_layer(make_layer(&"rastro", &"M19", Op.PERSIST, {"duration": 0.4, "sample_interval": 0.05}))
	s.clock.seek(1.2)
	return s


func same_result(a: MotionResult, b: MotionResult) -> bool:
	if a.samples.size() != b.samples.size():
		return false
	for i in a.samples.size():
		var x := a.samples[i]
		var y := b.samples[i]
		if x.position != y.position or x.width != y.width or x.opacity != y.opacity or x.element_id != y.element_id or x.branch != y.branch or x.visible != y.visible:
			return false
	return true


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 5): COMPARAÇÃO A/B (D-305)")
	print("=================================================================")
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	t_diff()
	t_snapshot()
	t_modes()
	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "a comparação é dado puro (não cria nós)")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_diff() -> void:
	print("\n-- Diferença entre dois resultados --")
	var s := new_session()
	var r := s.evaluate()
	var same := MotionLabSession.diff(r, r)
	ok(same["matched"] == r.samples.size() and same["changed"] == 0 and same["only_a"] == 0 and same["only_b"] == 0, "um resultado contra ele mesmo: tudo igual")
	ok(same["max_distance"] == 0.0 and same["mean_distance"] == 0.0 and same["max_attribute"] == 0.0, "distâncias e atributos nulos")

	var s2 := new_session()
	s2.composition.set_param(&"helice", &"radius", 0.5)
	var d := MotionLabSession.diff(r, s2.evaluate())
	ok(d["changed"] > 0 and d["only_a"] == 0 and d["only_b"] == 0, "outro raio: os mesmos elementos, posições diferentes (%d alterados)" % d["changed"])
	ok(d["max_distance"] > 0.19 and d["max_distance"] < 0.45, "a maior diferença de posição reflete o raio 0,3 → 0,5 (%.3f m)" % d["max_distance"])
	ok(d["mean_distance"] > 0.0 and d["mean_distance"] <= d["max_distance"], "a média não passa do máximo")

	var s3 := new_session()
	s3.composition.remove_layer(&"rastro")
	var d2 := MotionLabSession.diff(r, s3.evaluate())
	ok(d2["matched"] == 32 and d2["only_a"] == r.samples.size() - 32 and d2["only_b"] == 0 and d2["changed"] == 0, "sem o rastro: os 32 elementos da hélice coincidem e sobram só os do rastro em A")
	var d3 := MotionLabSession.diff(s3.evaluate(), r)
	ok(d3["only_b"] == r.samples.size() - 32 and d3["only_a"] == 0, "a ordem A × B inverte o lado que sobra")

	var s4 := new_session()
	s4.composition.add_layer(make_layer(&"larg", &"M17", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 5.0, "width": 0.0}))
	var d4 := MotionLabSession.diff(r, s4.evaluate())
	ok(d4["max_attribute"] > 0.1 and d4["max_distance"] == 0.0, "mudança só de atributo (largura): posição igual, atributo diferente")
	ok(d4["changed"] > 0, "mudança só de atributo conta como elemento alterado")
	var s5 := new_session()
	s5.composition.add_layer(make_layer(&"some", &"M17", Op.MASK, {"t_duration": 5.0, "width": 0.0}))
	var d5 := MotionLabSession.diff(r, s5.evaluate())
	ok(d5["max_attribute"] == 1.0 and d5["changed"] > 0 and d5["max_distance"] == 0.0, "diferença só de visibilidade vale como atributo máximo 1")
	ok(MotionLabSession.diff(null, r)["matched"] == 0, "sem A não há correspondência")


func t_snapshot() -> void:
	print("\n-- A é um instantâneo imutável --")
	var s := new_session()
	ok(s.snapshot_a == null and s.ab_mode == AB.OFF, "começa sem A e com a comparação desligada")
	s.composition.revision = 7
	var diags := s.capture_a()
	ok(diags.is_empty() and s.snapshot_a != null and s.snapshot_a != s.composition, "fixar A cria uma cópia independente")
	var frozen := s.evaluate_snapshot()
	ok(same_result(frozen, s.evaluate()), "no instante em que A é fixado, A = composição viva (mesmo tempo, mesma semente)")
	var rev_a := s.snapshot_a.revision
	var seed_a := s.snapshot_a.seed

	s.composition.set_param(&"helice", &"radius", 0.55)
	s.composition.add_layer(make_layer(&"extra", &"M08", Op.DEFORM, {"amount_deg": 90.0}))
	s.composition.remove_layer(&"rastro")
	s.composition.seed = 999
	s.composition.revision += 5
	ok(same_result(frozen, s.evaluate_snapshot()), "editar, adicionar, remover camadas e trocar a semente na composição viva não altera A")
	ok(rev_a == 7, "A guarda a revisão que a composição viva tinha ao ser fixada (7)")
	ok(s.snapshot_a.revision == rev_a and s.snapshot_a.seed == seed_a and s.snapshot_a.layer_ids() == [&"helice", &"rastro"], "A mantém revisão, semente e camadas")
	ok(not same_result(frozen, s.evaluate()), "a composição viva (B) mudou")
	s.snapshot_a.find_layer(&"helice").params["radius"] = 0.9
	ok(s.composition.find_layer(&"helice").params["radius"] == 0.55, "mexer na cópia A não vaza para a composição viva")

	var s2 := new_session()
	ok(s2.evaluate_snapshot() == null, "sem A fixado não há resultado de A")
	s2.capture_a()
	s2.clear_a()
	ok(s2.snapshot_a == null, "descartar A")

	# tempo e emissor valem para os dois lados
	var s3 := new_session()
	s3.capture_a()
	s3.composition.set_param(&"rastro", &"world_space", true)
	s3.emitter_mode = MotionLabSession.Emitter.RUN
	var a_run := s3.evaluate_snapshot()
	var b_run := s3.evaluate()
	ok(a_run.time == b_run.time and a_run.time == s3.clock.time, "A e B são avaliados no mesmo instante")
	ok(MotionLabSession.diff(a_run, b_run)["changed"] > 0, "o emissor é o mesmo para os dois; a diferença vem só da edição (world_space)")


func t_modes() -> void:
	print("\n-- Modos de comparação (§10.4) --")
	var s := new_session()
	var r := s.evaluate_ab()
	ok(r["a"] == null and r["error"] == "" and r["b"] != null, "desligado: só B, sem erro")

	s.ab_mode = AB.BEFORE_AFTER
	r = s.evaluate_ab()
	ok(r["a"] == null and r["error"] != "", "antes × depois sem A fixado: erro explícito (%s)" % r["error"])
	s.capture_a()
	r = s.evaluate_ab()
	ok(r["a"] != null and r["diff"]["changed"] == 0 and r["error"] == "", "antes × depois logo após fixar: sem diferença")
	s.composition.set_param(&"helice", &"radius", 0.45)
	r = s.evaluate_ab()
	ok(r["diff"]["changed"] > 0 and r["diff"]["max_distance"] > 0.1, "antes × depois após editar o raio: diferença de posição visível (%.3f m)" % r["diff"]["max_distance"])

	s.ab_mode = AB.ISOLATED
	s.ab_layer = &"helice"
	r = s.evaluate_ab()
	ok(r["a"].samples.size() == 32 and r["b"].samples.size() == 32 * 9, "isolada × combinada: A só com a hélice (32), B com o rastro (288)")
	ok(r["diff"]["matched"] == 32 and r["diff"]["changed"] == 0 and r["diff"]["only_b"] == 256, "a hélice isolada coincide com a hélice dentro da composição (nenhuma camada anterior a altera)")
	s.ab_layer = &"inexistente"
	r = s.evaluate_ab()
	ok(r["a"] == null and r["error"] != "", "isolar uma camada que não existe: erro explícito")
	s.ab_layer = &"rastro"
	r = s.evaluate_ab()
	ok(r["a"] != null and r["error"] == "" and r["a"].samples.size() > 0, "isolar um comportamento histórico avalia sem erro")
	ok(s.composition.layer_ids() == [&"helice", &"rastro"] and s.solo_layer == &"", "a comparação não altera a composição nem o isolamento da sessão")

	s.ab_mode = AB.NEUTRAL
	r = s.evaluate_ab()
	ok(r["a"] != null and same_result(r["a"], r["b"]) and r["diff"]["changed"] == 0, "neutra × escolhida: os dados são os mesmos; só o desenho muda")
	# a comparação usa a mesma semente e o mesmo tempo nos dois lados
	s.ab_mode = AB.BEFORE_AFTER
	s.capture_a()
	var ra := s.evaluate_ab()
	ok(ra["a"].time == ra["b"].time and ra["a"].revision == s.snapshot_a.revision, "A carrega a revisão do instantâneo; ambos no mesmo instante")
