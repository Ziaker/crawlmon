extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 7: seleção de ramos e máscaras na interface (§5.4, §19.3, D-305).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_ramos_mascaras.gd

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


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


func slider(lab: MotionLab, node_name: String) -> HSlider:
	return lab._params_box.find_child(node_name, true, false) as HSlider


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 7): RAMOS E MÁSCARAS (D-305)")
	print("=================================================================")
	MotionPresets.dir_override = "user://motion_composer_test_ramos_%d" % Time.get_ticks_usec()
	await t_logic()
	await t_lab()
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_logic() -> void:
	print("\n-- Ramos disponíveis antes de uma camada --")
	var cat := MotionCatalog.new()
	MotionBehaviors.register_all(cat)
	var c := MotionComposition.new()
	c.sample_count = 8
	c.add_layer(make_layer(&"h", &"M01", Op.REPLACE, {}))
	c.add_layer(make_layer(&"b1", &"M14", Op.BRANCH, {"branches": 3}))
	c.add_layer(make_layer(&"m", &"M17", Op.MULTIPLY_ATTRIBUTE, {}))
	c.add_layer(make_layer(&"b2", &"M14", Op.BRANCH, {"branches": 2}))
	c.add_layer(make_layer(&"z", &"M18", Op.MULTIPLY_ATTRIBUTE, {}))
	var ctx := c.make_context(1.0)
	ok(c.branches_before(&"h", cat, ctx) == PackedStringArray(["root"]), "antes da primeira camada só existe 'root'")
	ok(c.branches_before(&"b1", cat, ctx) == PackedStringArray(["root"]), "antes da bifurcação ainda só 'root'")
	var after := c.branches_before(&"m", cat, ctx)
	ok(after == PackedStringArray(["root/b1.0", "root/b1.1", "root/b1.2"]), "depois da bifurcação em 3: três caminhos (%s)" % [after])
	var nested := c.branches_before(&"z", cat, ctx)
	ok(nested.size() == 6 and nested[0] == "root/b1.0/b2.0" and nested[5] == "root/b1.2/b2.1", "depois de duas bifurcações: 3 × 2 = 6 caminhos aninhados, ordenados")
	ok(c.branches_before(&"nao_existe", cat, ctx).is_empty(), "camada inexistente: lista vazia")
	# a ordem não depende de como as amostras foram geradas: o resultado vem sempre em ordem alfabética
	var sorted_ok := true
	for i in range(1, nested.size()):
		if nested[i - 1] >= nested[i]:
			sorted_ok = false
	ok(sorted_ok, "a lista é estritamente crescente (sem repetidos e em ordem)")
	# 12 ramos: a geração produz b.0 … b.11 (ordem numérica); a lista tem de vir em ordem de texto (b.0, b.1, b.10, b.11, b.2 …)
	var rev := MotionComposition.new()
	rev.sample_count = 4
	rev.add_layer(make_layer(&"b", &"M14", Op.BRANCH, {"branches": 12, "phase_deg": 180.0}))
	rev.add_layer(make_layer(&"z", &"M18", Op.MULTIPLY_ATTRIBUTE, {}))
	var rl := rev.branches_before(&"z", cat, rev.make_context(1.0))
	var expect_names: Array = []
	for i in 12:
		expect_names.append("root/b.%d" % i)
	expect_names.sort()
	ok(rl.size() == 12 and Array(rl) == expect_names and rl[2] == "root/b.10", "a lista vem em ordem de texto, não na ordem de geração (%s)" % [rl])
	var c2 := MotionComposition.new()
	c2.sample_count = 8
	c2.add_layer(make_layer(&"h", &"M01", Op.REPLACE, {}))
	var lb := make_layer(&"b1", &"M14", Op.BRANCH, {"branches": 3, "t_start": 0.0})
	lb.active_from = 2.0
	c2.add_layer(lb)
	c2.add_layer(make_layer(&"m", &"M17", Op.MULTIPLY_ATTRIBUTE, {}))
	ok(c2.branches_before(&"m", cat, c2.make_context(1.0)) == PackedStringArray(["root"]), "bifurcação ainda inativa no instante: só 'root'")
	ok(c2.branches_before(&"m", cat, c2.make_context(2.5)).size() == 3, "bifurcação já ativa: 3 ramos")
	var before_rev := c.revision
	c.branches_before(&"z", cat, ctx)
	ok(c.revision == before_rev and c.layer_ids().size() == 5, "consultar não altera a composição")


func t_lab() -> void:
	print("\n-- Interface: ramos e máscaras --")
	var scene: PackedScene = load("res://scenes/motion_lab/motion_lab.tscn")
	var lab: MotionLab = scene.instantiate()
	root.add_child(lab)
	await process_frame
	var s := lab.session
	# base: estudo de bifurcação + uma camada que apaga a largura (dissolução completa), para ver quem é afetado
	lab.load_study(&"M14")
	s.clock.pause()
	s.clock.seek(1.8)
	var kill := make_layer(&"apaga", &"M18", Op.MULTIPLY_ATTRIBUTE, {"t_start": 0.0, "t_duration": 0.01, "width": 0.0})
	s.composition.add_layer(kill, 1)
	lab._selected = &"apaga"
	lab._after_edit()
	lab._refresh_layers()
	await process_frame
	await process_frame
	var checks := []
	for i in 6:
		var cb := lab._params_box.find_child("ramo_%d" % i, true, false)
		if cb != null:
			checks.append(cb)
	ok(checks.size() == 3, "a camada depois da bifurcação lista os 3 ramos como opções (%d)" % checks.size())
	ok(lab._params_box.find_child("ramos_box", true, false) != null and lab._params_box.find_child("mascara_box", true, false) != null, "as duas seções existem no painel de parâmetros")
	var r_all := s.evaluate()
	var all_zero := true
	for smp in r_all.samples:
		if smp.width > 0.01:
			all_zero = false
	ok(all_zero, "sem ramo marcado a camada afeta todos (largura 0 em tudo)")

	# marcar um ramo
	(checks[1] as CheckBox).button_pressed = true
	await process_frame
	var target := String((checks[1] as CheckBox).text)
	ok(s.composition.find_layer(&"apaga").branches == PackedStringArray([target]), "marcar um ramo grava a seleção (%s)" % target)
	var r_one := s.evaluate()
	var hit_ok := true
	var other_ok := true
	var hits := 0
	for smp in r_one.samples:
		if smp.branch == target:
			hits += 1
			if smp.width > 0.01:
				hit_ok = false
		elif smp.width < 0.5:
			other_ok = false
	ok(hits > 0 and hit_ok and other_ok, "só o ramo marcado é apagado; os outros mantêm a largura")
	(checks[1] as CheckBox).button_pressed = false
	await process_frame
	ok(s.composition.find_layer(&"apaga").branches.is_empty(), "desmarcar volta a 'todos'")

	# máscara espacial
	lab._rebuild_params()
	await process_frame
	await process_frame
	ok(slider(lab, "mask_u_from") != null and slider(lab, "mask_u_to") != null and slider(lab, "mask_feather") != null and slider(lab, "mask_t_from") != null and slider(lab, "layer_active_from") != null, "controles da máscara e da janela existem")
	slider(lab, "mask_u_from").value = 0.5
	await process_frame
	ok(is_equal_approx(s.composition.find_layer(&"apaga").mask.u_from, 0.5), "o controle grava a máscara")
	var r_mask := s.evaluate()
	var low_ok := true
	var high_ok := true
	for smp in r_mask.samples:
		if smp.u < 0.45 and smp.width < 0.5:
			low_ok = false
		if smp.u > 0.55 and smp.width > 0.05:
			high_ok = false
	ok(low_ok and high_ok, "máscara u ≥ 0,5: a primeira metade fica intacta e a segunda é apagada")
	var inv := lab._params_box.find_child("mask_invert", true, false) as CheckBox
	inv.button_pressed = true
	await process_frame
	var r_inv := s.evaluate()
	var inv_ok := true
	for smp in r_inv.samples:
		if smp.u < 0.45 and smp.width > 0.05:
			inv_ok = false
		if smp.u > 0.55 and smp.width < 0.5:
			inv_ok = false
	ok(inv_ok, "inverter: agora a primeira metade é apagada e a segunda fica intacta")
	inv.button_pressed = false
	var feather := slider(lab, "mask_feather")
	feather.value = 0.3
	await process_frame
	var mid := false
	for smp in s.evaluate().samples:
		if smp.u > 0.25 and smp.u < 0.48 and smp.width > 0.1 and smp.width < 0.9:
			mid = true
	ok(mid, "o degradê produz largura intermediária na borda da faixa")
	feather.value = 0.0

	# ordem forçada: u_to nunca fica abaixo de u_from
	slider(lab, "mask_u_from").value = 0.9
	await process_frame
	ok(is_equal_approx(s.composition.find_layer(&"apaga").mask.u_to, 1.0), "início 0,9 com fim 1,0: o fim não precisa se mover")
	slider(lab, "mask_u_to").value = 0.95
	slider(lab, "mask_u_from").value = 0.97
	await process_frame
	ok(is_equal_approx(s.composition.find_layer(&"apaga").mask.u_to, 0.97), "início 0,97 além do fim 0,95: o fim é arrastado para 0,97")
	slider(lab, "mask_u_to").value = 0.5
	await process_frame
	ok(is_equal_approx(s.composition.find_layer(&"apaga").mask.u_from, 0.5), "fim 0,5 antes do início 0,97: o início é arrastado para 0,5")
	slider(lab, "mask_u_from").value = 0.9
	await process_frame
	var mk := s.composition.find_layer(&"apaga").mask
	ok(mk.u_from <= mk.u_to, "mover o início além do fim arrasta o fim (faixa sempre válida: %.2f–%.2f)" % [mk.u_from, mk.u_to])
	ok(s.composition.validate(s.catalog).is_empty(), "a composição continua válida depois das edições")
	slider(lab, "mask_u_from").value = 0.0

	# janela de atividade
	slider(lab, "layer_active_from").value = 2.5
	await process_frame
	var inactive := true
	for smp in s.evaluate().samples:
		if smp.width < 0.5:
			inactive = false
	ok(inactive, "janela a partir de 2,5 s: no instante 1,8 s a camada está inativa e nada é apagado")
	slider(lab, "layer_active_from").value = 0.0

	# máscara temporal
	(lab._params_box.find_child("mask_time_enabled", true, false) as CheckBox).button_pressed = true
	slider(lab, "mask_t_from").value = 0.0
	slider(lab, "mask_t_to").value = 1.0
	await process_frame
	var out_window := true
	for smp in s.evaluate().samples:
		if smp.width < 0.5:
			out_window = false
	ok(out_window, "máscara temporal 0–1 s: em 1,8 s o peso é 0 e nada é apagado")
	slider(lab, "mask_t_to").value = 2.5
	await process_frame
	var in_window := false
	for smp in s.evaluate().samples:
		if smp.width < 0.05:
			in_window = true
	ok(in_window, "máscara temporal 0–2,5 s: em 1,8 s o efeito volta")

	# camada de topologia: aviso de que ignora a máscara
	lab._selected = &"bifurcacao"
	lab._rebuild_params()
	await process_frame
	await process_frame
	var warn := false
	for ch in (lab._params_box.find_child("mascara_box", true, false) as VBoxContainer).get_children():
		if ch is Label and (ch as Label).text.contains("ignora a máscara"):
			warn = true
	ok(warn, "numa camada de topologia a interface avisa que a máscara por amostra é ignorada")
	var nob := lab._params_box.find_child("ramos_box", true, false) as VBoxContainer
	var only_root := false
	for ch in nob.get_children():
		if ch is Label and (ch as Label).text.contains("só existe o ramo"):
			only_root = true
	ok(only_root, "antes de qualquer bifurcação a seção de ramos explica que só existe 'root'")

	for n in MotionPresets.list_names():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MotionPresets.path_for(n)))
	MotionPresets.dir_override = ""
	lab.queue_free()
