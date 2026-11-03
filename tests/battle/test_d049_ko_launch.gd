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
	print("   CRAWLMON — TESTES DE IMPACTO DE K.O. E SCREEN SHAKE (D-049)")
	print("=================================================================")

	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)

	var battle: Battle = bs.get_node("Battle")
	var cam: BattleCamera = bs.director
	var fx: BattleFx = bs.fx

	while not battle.running:
		await process_frame

	for i in 10:
		await process_frame

	# 1. Teste do Screen Shake e FOV-Kick em BattleCamera
	_expect(cam._shake_trauma == 0.0, "Câmera inicia com trauma de shake zerado")
	_expect(cam._fov_kick == 0.0, "Câmera inicia com FOV-kick zerado")

	var hit_dir := Vector3(1.0, 0.0, 0.5).normalized()
	cam.ko_shake(hit_dir, Vector3(0, 1, 0), Color.RED)

	_expect(is_equal_approx(cam._shake_trauma, 1.0), "ko_shake ativa trauma de shake em 1.0 (máximo)")
	_expect(is_equal_approx(cam._fov_kick, 4.5), "ko_shake aplica micro FOV-kick elástico de 4.5 graus")
	_expect(cam._shake_dir.dot(-hit_dir) > 0.99, "Direção do trauma shake é alinhada com o vetor oposto ao golpe")

	# Simula 0.1s de frame: câmera deve apresentar deslocamento direcional
	cam._apply(0.1)
	_expect(cam._shake_trauma < 1.0 and cam._shake_trauma > 0.0, "Trauma decai com o tempo (atual: %.2f)" % cam._shake_trauma)
	_expect(cam._fov_kick < 4.5 and cam._fov_kick > 0.0, "FOV-kick retorna suavemente (atual: %.2f)" % cam._fov_kick)

	# Simula 0.4s adicionais para decaimento completo (~0.35s de duração acordada)
	for s in 5:
		cam._apply(0.1)
	_expect(cam._shake_trauma == 0.0, "Shake encerra completamente após decaimento rápido")
	_expect(cam._fov_kick == 0.0, "FOV retorna exatamente à configuração normal")

	# 2. Teste do Lançamento Balístico do Inimigo (launch_ko)
	var enemy: Combatant = battle.enemies[0]
	var enemy_model: Node3D = bs.models[enemy]
	var initial_pos := enemy_model.position

	_expect(enemy_model != null, "Modelo do inimigo encontrado na cena")

	# Dispara o lançamento balístico de K.O.
	fx.fx_motion.launch_ko(enemy, Vector3.ZERO, Vector3.RIGHT)

	# Aguarda 0.45s (próximo ao ápice parabólico)
	await create_timer(0.45, true, false, true).timeout
	var mid_pos := enemy_model.position
	_expect(mid_pos.y > 1.2, "Durante o voo balístico, o inimigo atinge arco elevado (Y atual: %.2f m)" % mid_pos.y)
	_expect(mid_pos.distance_to(initial_pos) > 2.0, "Inimigo se deslocou horizontalmente para longe da posição inicial")

	# Aguarda aterrissagem e dissipação final (~0.9s restantes)
	await create_timer(1.0, true, false, true).timeout
	_expect(enemy_model.scale.length() < 0.1 or not enemy_model.visible, "Ao concluir o pouso e dissipação, o modelo desaparece da arena")

	bs.free()

	print("=================================================================")
	if failures == 0:
		print("D049_KO_LAUNCH_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
