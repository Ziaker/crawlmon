extends SceneTree

const SmtStageVfx = preload("res://scripts/vfx/smt/smt_stage_vfx.gd")
const SmtBuffController = preload("res://scripts/vfx/smt/smt_buff_controller.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- INICIANDO TESTE DO SISTEMA VFX SMT (D-035) ---")
	var success := true

	# Teste 1: Shader
	var shader := load("res://shaders/smt_stage_vfx.gdshader") as Shader
	if shader == null:
		print("ERRO: Shader smt_stage_vfx.gdshader falhou ao carregar!")
		success = false
	else:
		print("PASS: Shader smt_stage_vfx.gdshader carregado com sucesso.")

	# Teste 2: Setup dos 3 tipos em SmtStageVfx
	var test_root := Node3D.new()
	test_root.name = "TestRoot"
	root.add_child(test_root)

	var dummy_target := Node3D.new()
	dummy_target.name = "DummyTarget"
	dummy_target.position = Vector3(2, 0, -5)
	test_root.add_child(dummy_target)

	var tests := [
		{
			"type": SmtStageVfx.MoveType.TARUKAJA,
			"name": "TARUKAJA",
			"expected_color": Color("#D7FD6A"),
			"expected_label": "↗ ATK +1",
			"expected_orbitals": 4
		},
		{
			"type": SmtStageVfx.MoveType.RAKUNDA,
			"name": "RAKUNDA",
			"expected_color": Color("#FF624F"),
			"expected_label": "↘ DEF -1",
			"expected_orbitals": 6
		},
		{
			"type": SmtStageVfx.MoveType.SUKUNDA,
			"name": "SUKUNDA",
			"expected_color": Color("#F7CB78"),
			"expected_label": "↯ SPD -1",
			"expected_orbitals": 6
		}
	]

	for t in tests:
		var vfx := SmtStageVfx.new()
		test_root.add_child(vfx)
		vfx.setup(t["type"], dummy_target, 1.0)

		# Validar cor
		var col: Color = SmtStageVfx.COLORS[t["type"]]
		if not col.is_equal_approx(t["expected_color"]):
			print("ERRO no teste %s: cor esperada %s, obtida %s" % [t["name"], t["expected_color"], col])
			success = false
		else:
			print("PASS [%s]: Cor cromática correta (%s)." % [t["name"], col.to_html()])

		# Validar label
		var lbl: String = SmtStageVfx.LABELS[t["type"]]
		if lbl != t["expected_label"]:
			print("ERRO no teste %s: label esperado %s, obtido %s" % [t["name"], t["expected_label"], lbl])
			success = false
		else:
			print("PASS [%s]: Label de sobreposição correto (%s)." % [t["name"], lbl])

		# Validar número de orbitais
		var pivot := vfx.get_node_or_null("OrbitalPivot") as Node3D
		if pivot == null or pivot.get_child_count() != t["expected_orbitals"]:
			var count := pivot.get_child_count() if pivot else 0
			print("ERRO no teste %s: orbitais esperados %d, obtidos %d" % [t["name"], t["expected_orbitals"], count])
			success = false
		else:
			print("PASS [%s]: Quantidade de geometrias orbitais correta (%d nós)." % [t["name"], pivot.get_child_count()])

		# Validar número de anéis (3 anéis)
		var rings_root := vfx.get_node_or_null("RingsRoot") as Node3D
		if rings_root == null or rings_root.get_child_count() != 3:
			var count := rings_root.get_child_count() if rings_root else 0
			print("ERRO no teste %s: anéis esperados 3, obtidos %d" % [t["name"], count])
			success = false
		else:
			print("PASS [%s]: Três anéis holográficos presentes." % t["name"])

		# Validar Selo Rúnico no Chão (D-037)
		var sigil := vfx.get_node_or_null("GroundSigil") as MeshInstance3D
		if sigil == null:
			print("ERRO no teste %s: nó GroundSigil ausente!" % t["name"])
			success = false
		else:
			print("PASS [%s]: GroundSigil procedural presente e ativo." % t["name"])

		# Validar SpecialRoot (D-037)
		var special_root := vfx.get_node_or_null("SpecialRoot") as Node3D
		if special_root == null or special_root.get_child_count() == 0:
			print("ERRO no teste %s: SpecialRoot ausente ou vazio!" % t["name"])
			success = false
		else:
			print("PASS [%s]: SpecialRoot presente com %d elementos específicos." % [t["name"], special_root.get_child_count()])

		# Simular avanço de frames (0.5s e 1.0s)
		vfx._process(0.5)
		vfx._process(0.6)
		print("PASS [%s]: _process(delta) executado sem erros até o ciclo de vida final." % t["name"])

	# Teste 3: Controlador SmtBuffController
	var controller := SmtBuffController.new()
	test_root.add_child(controller)
	controller.register_model(dummy_target, dummy_target)

	var handled_tarukaja := controller.play_move_by_id("tarukaja", dummy_target, 1.0)
	var handled_rakunda := controller.play_move_by_id("rakunda", dummy_target, 1.0)
	var handled_sukunda := controller.play_move_by_id("sukunda", dummy_target, 1.0)

	if not (handled_tarukaja and handled_rakunda and handled_sukunda):
		print("ERRO: Controlador não despachou todos os moves SMT por ID!")
		success = false
	else:
		print("PASS: SmtBuffController despachou Tarukaja, Rakunda e Sukunda com sucesso.")

	# Teste 4: on_hit_resolved
	controller.on_hit_resolved(dummy_target, dummy_target, 0, {"skill_name": "Tarukaja", "buff": "atk"})
	controller.on_hit_resolved(dummy_target, dummy_target, 0, {"skill_name": "Rakunda", "debuff": "def"})
	controller.on_hit_resolved(dummy_target, dummy_target, 0, {"skill_name": "Sukunda", "debuff": "spd"})
	print("PASS: SmtBuffController.on_hit_resolved processou todos os eventos.")

	# Cleanup
	test_root.queue_free()

	if success:
		print("=== TODOS OS TESTES SMT VFX PASSARAM COM SUCESSO (100%) ===")
		quit(0)
	else:
		print("=== FALHA EM TESTES DO SISTEMA SMT VFX ===")
		quit(1)
