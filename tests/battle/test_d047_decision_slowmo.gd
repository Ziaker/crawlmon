extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("  [FAIL] %s" % msg)
	else:
		print("  [PASS] %s" % msg)

func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — TESTES DE CÂMERA LENTA DE DECISÃO D-047")
	print("=================================================================")

	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)

	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame

	for i in 5:
		await process_frame

	var leader: Combatant = bs.leader
	leader.atb = 5.0

	# 1. Estado inicial
	_expect(bs._decision_slowmo_available == true, "Câmera lenta está disponível no início")
	_expect(bs._decision_slowmo_active == false, "Câmera lenta inicia desativada")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Velocidade inicial da Engine é 1.0x")

	# 2. Abrir Fight ativa câmera lenta a 0.2x por 3s e consome o uso
	print("[*] Abrindo menu Fight...")
	bs._show_fight()
	_expect(bs._decision_slowmo_active == true, "Câmera lenta ativada ao abrir Fight")
	_expect(bs._decision_slowmo_available == false, "Uso único consumido ao abrir Fight")
	_expect(is_equal_approx(Engine.time_scale, 0.2), "Engine.time_scale reduzido para 0.2x")

	# 3. Cancelar com X volta a 1.0x na hora, mas mantém _decision_slowmo_available == false
	print("[*] Cancelando com tecla X...")
	bs._on_cancel()
	_expect(bs._decision_slowmo_active == false, "Câmera lenta encerrada ao cancelar com X")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Engine.time_scale restaurado para 1.0x imediatamente")
	_expect(bs._decision_slowmo_available == false, "Reabertura ainda bloqueada após sair com X sem agir")

	# 4. Reabrir Fight antes de realizar ação NÃO ativa câmera lenta novamente
	print("[*] Reabrindo menu Fight antes de agir...")
	bs._show_fight()
	_expect(bs._decision_slowmo_active == false, "Reabertura não ativa câmera lenta uma segunda vez")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Engine.time_scale permanece em 1.0x")

	# 5. Executar uma ação restaura a permissão para o próximo turno
	print("[*] Executando uma ação...")
	var skill: Skill = bs._fight_skills[0]
	var target: Combatant = bs._default_target()
	var ok: bool = bs._use_move(skill, target)
	_expect(ok == true, "Ação de ataque executada com sucesso")
	_expect(bs._decision_slowmo_available == true, "Permissão de câmera lenta restaurada após realizar uma ação")

	# 6. Abrir Itens ativa câmera lenta novamente
	print("[*] Abrindo menu Itens no novo turno de ação...")
	bs._show_items()
	_expect(bs._decision_slowmo_active == true, "Câmera lenta ativada ao abrir Itens")
	_expect(is_equal_approx(Engine.time_scale, 0.2), "Engine.time_scale reduzido para 0.2x em Itens")
	_expect(bs._decision_slowmo_available == false, "Permissão consumida para o turno de Itens")

	# 7. Teste de expiração dos 3 segundos (tempo real): o tempo volta a 1.0x mas o menu continua aberto
	print("[*] Aguardando expiração dos 3 segundos em tempo real...")
	# Forçamos o tempo restante para 0.1s para o teste rodar rápido
	bs._decision_slowmo_time_left = 0.1
	await create_timer(0.2, true, false, true).timeout
	_expect(bs._decision_slowmo_active == false, "Câmera lenta encerrada após esgotar o tempo")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Engine.time_scale restaurado para 1.0x após expiração")
	_expect(bs.state == bs.S.ITEMS, "Menu de Itens continua aberto após a expiração dos 3s")

	bs._on_cancel()
	bs.free()

	print("=================================================================")
	if failures == 0:
		print("D047_DECISION_SLOWMO_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
