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
	print("   CRAWLMON — TESTES DE HIT SHAKE E LANÇAMENTO LONGE DE K.O. (D-157)")
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

	# 1. Teste de Intensidade do Hit Shake (Normal vs Heavy vs K.O.)
	var strike_dir := Vector3(0.0, 0.0, -1.0)
	
	# Normal hit shake
	cam.hit_shake(strike_dir, false, 1.0)
	_expect(cam._shake_trauma >= 0.30 and cam._shake_trauma <= 0.40, "Hit shake normal ativa trauma calibrado (atual: %.2f, esperado ~0.35)" % cam._shake_trauma)
	_expect(cam._fov_kick <= 0.6, "Hit shake normal aplica micro FOV-kick sutil (atual: %.2f)" % cam._fov_kick)
	_expect(cam._shake_trauma < 0.6, "Hit shake normal é significativamente menor que o hit final de K.O.")

	# Decaimento rápido do hit shake normal
	cam._apply(0.12)
	_expect(cam._shake_trauma < 0.15, "Hit shake normal decai rapidamente (~0.12s)")
	cam._apply(0.10)
	_expect(cam._shake_trauma == 0.0, "Hit shake normal encerra completamente")

	# Heavy hit shake (Fraqueza / Crítico)
	cam.hit_shake(strike_dir, true, 1.2)
	_expect(cam._shake_trauma >= 0.50 and cam._shake_trauma <= 0.65, "Hit shake pesado ativa trauma intermediário (atual: %.2f, esperado ~0.55-0.65)" % cam._shake_trauma)
	_expect(cam._fov_kick >= 1.0 and cam._fov_kick <= 1.8, "Hit shake pesado aplica micro FOV-kick de impacto (atual: %.2f)" % cam._fov_kick)
	_expect(cam._shake_trauma < 1.0, "Hit shake pesado tem menos intensidade que o K.O. final (1.0)")

	# K.O. shake final (D-049)
	cam.ko_shake(strike_dir, Vector3.ZERO, Color.RED)
	_expect(cam._shake_trauma == 1.0, "K.O. shake final ativa trauma máximo de 1.0")
	_expect(cam._fov_kick >= 4.0, "K.O. shake final aplica FOV-kick épico (4.5)")

	# Limpa câmera
	for s in 5:
		cam._apply(0.1)

	# 2. Teste do Lançamento de K.O. à Distância ("Lançado longe", sem girar em falso)
	var enemy: Combatant = battle.enemies[0]
	var enemy_model: Node3D = bs.models[enemy]
	var initial_pos := enemy_model.position

	# Dispara o lançamento balístico corrigido
	fx.fx_motion.launch_ko(enemy)

	# Aguarda 0.55s (perto do ápice do voo parabólico)
	await create_timer(0.55, true, false, true).timeout
	var mid_pos := enemy_model.position
	var mid_dist := mid_pos.distance_to(initial_pos)

	_expect(mid_pos.y >= 7.0, "Inimigo atinge arco balístico elevado no ar (Y atual: %.2f m, >= 7.0m)" % mid_pos.y)
	_expect(mid_dist >= 12.0, "Inimigo é arremessado a grande distância no meio do trajeto (distância atual: %.2f m, >= 12.0m)" % mid_dist)
	_expect(mid_pos.z < initial_pos.z - 8.0, "Inimigo voa profundamente para o fundo da arena (Z atual: %.2f, inicial: %.2f)" % [mid_pos.z, initial_pos.z])

	# Aguarda término completo do voo e dissipação no horizonte (~0.7s adicionais)
	await create_timer(0.70, true, false, true).timeout
	_expect(not enemy_model.visible or enemy_model.scale.length() < 0.1, "Inimigo dissipa no horizonte e fica invisível")

	bs.free()

	print("=================================================================")
	if failures == 0:
		print("D157_HITSHAKE_AND_LAUNCH_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
