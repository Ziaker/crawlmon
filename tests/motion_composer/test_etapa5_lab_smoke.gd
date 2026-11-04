extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 1: fumaça do laboratório (cena instanciada, sem tela).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_lab_smoke.gd

var _fails: int = 0
var _checks: int = 0


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 1): LABORATÓRIO (D-305)")
	print("=================================================================")
	MotionPresets.dir_override = "user://motion_composer_test_lab_%d" % Time.get_ticks_usec()
	var scene: PackedScene = load("res://scenes/motion_lab/motion_lab.tscn")
	var lab: MotionLab = scene.instantiate()
	root.add_child(lab)
	for i in 4:
		await process_frame
	var s := lab.session
	ok(s.composition.layer_ids() == [&"helice", &"rastro"], "a cena abre com a composição de demonstração (hélice + rastro)")
	ok(lab.points.shown_count > 0, "pontos desenhados (%d)" % lab.points.shown_count)
	ok(lab.points.get_child(0) is MultiMeshInstance3D, "a representação é um MultiMeshInstance3D")
	var mat := (lab.points.get_child(0) as MultiMeshInstance3D).multimesh.mesh.material as ShaderMaterial
	ok(mat != null and mat.shader != null and mat.shader.code.contains("shader_type spatial") and mat.shader.resource_path.ends_with(".gdshader"), "o desenho usa ShaderMaterial com .gdshader (spatial), não HTML nem material improvisado")
	ok(s.last_result.stats["samples"] > 0 and not s.last_result.has_errors(), "avaliação sem erros e com estatísticas")

	# catálogo → adicionar camada
	lab._catalog_list.select(1)
	lab._on_catalog_selected(1)
	ok(lab._add_op.item_count > 0, "ao escolher M02 o menu mostra as operações aceitas")
	var before := s.composition.layers.size()
	lab._on_add_layer()
	ok(s.composition.layers.size() == before + 1 and s.composition.layers[1].behavior_id == &"M02", "adicionar camada insere M02 logo após a selecionada")
	# reordenar / ligar / isolar / remover
	var sel := lab._selected
	lab._move_selected(1)
	ok(s.composition.layer_ids().find(sel) == 2, "descer a camada")
	lab._toggle_selected()
	ok(not s.composition.find_layer(sel).enabled, "desligar a camada")
	lab._toggle_selected()
	lab._toggle_solo()
	ok(s.solo_layer == sel, "isolar a camada selecionada")
	lab._toggle_solo()
	ok(s.solo_layer == &"", "desfazer o isolamento")
	# editar parâmetro: modo atualizar mantém o tempo
	s.clock.pause()
	s.clock.seek(1.3)
	s.composition.set_param(&"helice", &"radius", 0.4)
	lab._after_edit()
	ok(is_equal_approx(s.clock.time, 1.3), "editar no modo 'atualizar' mantém o instante")
	s.edit_mode = MotionLabSession.EditMode.RESTART
	s.composition.set_param(&"helice", &"radius", 0.35)
	lab._after_edit()
	ok(s.clock.time == 0.0, "editar no modo 'reiniciar' volta ao nascimento")
	lab._remove_selected()
	ok(s.composition.layers.size() == before, "remover a camada")
	# presets
	lab._preset_name.text = "smoke_lab"
	lab._on_save_preset()
	ok(MotionPresets.list_names() == PackedStringArray(["smoke_lab"]) and lab._preset_status.text.begins_with("Salvo"), "salvar preset pela interface")
	lab._refresh_presets()
	s.composition.remove_layer(&"rastro")
	lab._on_load_preset()
	ok(s.composition.layer_ids().has(&"rastro") and lab._preset_status.text == "Carregado.", "carregar preset restaura a composição")
	# cores por ramo distinguíveis (ramos irmãos diferem só no último caractere do caminho)
	var hues: Array[float] = []
	for b in ["root/bifurcacao.0", "root/bifurcacao.1", "root/bifurcacao.2"]:
		hues.append(MotionPointsView.branch_color(b).h)
	var min_gap := 1.0
	for i in 3:
		for j in range(i + 1, 3):
			var d := absf(hues[i] - hues[j])
			min_gap = minf(min_gap, minf(d, 1.0 - d))
	ok(min_gap > 0.08, "ramos irmãos têm matizes bem distintos (menor distância %.3f)" % min_gap)
	# representação: pontos ↔ fitas conservam a composição
	var rev := s.composition.revision
	var time_before := s.clock.time
	lab.set_representation(1)
	await process_frame
	ok(lab.ribbons.visible and not lab.points.visible and lab.ribbons.triangle_count > 0, "Fitas: a vista de fitas desenha e a de pontos some")
	var rmat := (lab.ribbons.get_child(0) as MeshInstance3D).material_override as ShaderMaterial
	ok(rmat != null and rmat.shader.resource_path.ends_with(".gdshader"), "as fitas usam ShaderMaterial com .gdshader")
	lab.set_representation(2)
	await process_frame
	ok(lab.ribbons.visible and lab.points.visible and lab.points.shown_count > 0 and lab.ribbons.triangle_count > 0, "Pontos + fitas desenha as duas")
	lab.set_representation(0)
	ok(s.composition.revision == rev and is_equal_approx(s.clock.time, time_before), "trocar a representação não altera a composição, a revisão nem o relógio")
	lab.set_representation(3)
	await process_frame
	ok(lab.fragments.visible and not lab.points.visible and not lab.ribbons.visible and lab.fragments.shown_count > 0, "Fragmentos: só a vista de fragmentos aparece e desenha")
	var fmat := ((lab.fragments.get_child(0) as MultiMeshInstance3D).multimesh.mesh.surface_get_material(0)) as ShaderMaterial
	ok(fmat != null and fmat.shader.resource_path.ends_with(".gdshader"), "os fragmentos usam ShaderMaterial com .gdshader")
	ok(s.composition.revision == rev and is_equal_approx(s.clock.time, time_before), "a troca para Fragmentos também conserva composição, revisão e relógio")
	lab.set_representation(0)
	lab.set_representation(4)
	await process_frame
	ok(lab.smoke.visible and not lab.points.visible and not lab.fragments.visible and not lab.ribbons.visible and lab.smoke.shown_count > 0, "Fumaça: só a vista de fumaça aparece e desenha")
	ok(s.composition.revision == rev and is_equal_approx(s.clock.time, time_before), "a troca para Fumaça também conserva composição, revisão e relógio")
	lab.set_representation(0)
	# comparação A/B no laboratório
	s.clock.pause()
	s.clock.seek(1.2)
	lab.set_ab_mode(MotionLabSession.AbMode.BEFORE_AFTER)
	await process_frame
	ok(not lab.view_a.visible and lab._ab_status.text.begins_with("Fixe A"), "antes × depois sem A fixado: nada à esquerda e a mensagem pede para fixar A")
	lab.capture_a()
	await process_frame
	ok(lab.view_a.visible and lab._label_a.visible and lab._label_b.visible, "com A fixado aparecem os dois lados e os rótulos")
	ok(lab.view_a.position.x < 0.0 and lab.view_set.position.x > 0.0 and is_equal_approx(lab.view_a.position.x, -lab.view_set.position.x), "A à esquerda, B à direita, simétricos")
	ok(lab._label_a.text.begins_with("A:") and lab._label_b.text.begins_with("B:"), "rótulos A e B")
	ok(lab.view_a.points.shown_count == lab.view_set.points.shown_count and lab.view_a.points.shown_count > 0, "logo após fixar, os dois lados desenham o mesmo número de pontos")
	s.composition.set_param(&"helice", &"radius", 0.5)
	lab._after_edit()
	await process_frame
	ok(lab._ab_status.text.contains("diferentes") and not lab._ab_status.text.contains("0 diferentes"), "depois de editar, a diferença aparece na leitura (%s)" % lab._ab_status.text.left(60))
	ok(s.snapshot_a.find_layer(&"helice").params["radius"] != 0.5, "A não mudou com a edição")
	lab.set_ab_mode(MotionLabSession.AbMode.NEUTRAL)
	lab.set_representation(1)
	await process_frame
	ok(lab.view_a.representation == 0 and lab.view_set.representation == 1 and lab.view_a.points.visible and lab.view_set.ribbons.visible, "neutra × escolhida: A em pontos, B na representação escolhida")
	lab.set_ab_mode(MotionLabSession.AbMode.ISOLATED)
	await process_frame
	ok(lab.view_a.visible and lab._label_a.text.begins_with("A: só"), "isolada × combinada: rótulo cita a camada")
	lab.set_ab_mode(MotionLabSession.AbMode.OFF)
	await process_frame
	ok(not lab.view_a.visible and lab.view_set.position == Vector3.ZERO and not lab._label_b.visible, "desligar a comparação volta B ao centro e esconde A e os rótulos")
	lab.set_representation(0)
	# pelo menos um quadro depois de tudo
	await process_frame
	ok(lab.points.shown_count > 0 and not s.last_result.has_errors(), "continua desenhando sem erros após as operações")
	for n in MotionPresets.list_names():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(MotionPresets.path_for(n)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MotionPresets.dir()))
	MotionPresets.dir_override = ""
	lab.queue_free()
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)
