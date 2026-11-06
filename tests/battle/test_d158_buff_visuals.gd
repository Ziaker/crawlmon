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
	print("   CRAWLMON — TESTES DE ESCALAMENTO VISUAL DE BUFFS/DEBUFFS (D-158)")
	print("=================================================================")

	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)

	var battle: Battle = bs.get_node("Battle")
	var fx: BattleFx = bs.fx

	while not battle.running:
		await process_frame
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD  # Only what this test does may change the state.
		c.react_policy = Combatant.React.NONE

	for i in 10:
		await process_frame

	var player: Combatant = battle.party[0]
	var model: Node3D = bs.models[player]
	var ap: AnimationPlayer = model.get_meta("anim_player") if model.has_meta("anim_player") else null

	var base_s: Vector3 = fx._orig_scale.get(player, model.scale)
	var base_spd: float = fx._orig_speed.get(player, ap.speed_scale if ap else 1.0)

	_expect(model != null, "Modelo do jogador instanciado e registrado")
	_expect(base_s.length() > 0.0, "Escala original registrada: %s" % str(base_s))
	if ap:
		_expect(base_spd > 0.0, "Velocidade original registrada: %.2f" % base_spd)

	# -------------------------------------------------------------
	# 1. TESTE DE ATK BUFF (+1, +2, -1, -2) -> Model Scale (±15% per stack)
	# -------------------------------------------------------------
	print("\n--- TESTE 1: ATK BUFF -> ESCALA DO MODELO (±15%) ---")
	
	# +1 ATK
	player.buff_stat("atk", 1)
	_expect(player.atk_buff == 1, "Player ATK buff == +1")
	await create_timer(0.40, true, false, true).timeout
	var s_p1 := model.scale
	var exp_s_p1 := base_s * 1.15
	_expect(s_p1.is_equal_approx(exp_s_p1), "ATK +1 aumenta escala em +15%% (esperado: %s, atual: %s)" % [str(exp_s_p1), str(s_p1)])
	_expect(fx._base_scale[player].is_equal_approx(exp_s_p1), "fx._base_scale atualizado para preservar porte em animações")

	# +2 ATK
	player.buff_stat("atk", 1)
	_expect(player.atk_buff == 2, "Player ATK buff == +2")
	await create_timer(0.40, true, false, true).timeout
	var s_p2 := model.scale
	var exp_s_p2 := base_s * 1.30
	_expect(s_p2.is_equal_approx(exp_s_p2), "ATK +2 aumenta escala em +30%% (esperado: %s, atual: %s)" % [str(exp_s_p2), str(s_p2)])

	# -1 ATK (delta -3 de +2 resulta em -1)
	player.buff_stat("atk", -3)
	_expect(player.atk_buff == -1, "Player ATK buff == -1")
	await create_timer(0.40, true, false, true).timeout
	var s_m1 := model.scale
	var exp_s_m1 := base_s * 0.85
	_expect(s_m1.is_equal_approx(exp_s_m1), "ATK -1 reduz escala em -15%% (esperado: %s, atual: %s)" % [str(exp_s_m1), str(s_m1)])

	# -2 ATK (delta -1 resulta em -2)
	player.buff_stat("atk", -1)
	_expect(player.atk_buff == -2, "Player ATK buff == -2")
	await create_timer(0.40, true, false, true).timeout
	var s_m2 := model.scale
	var exp_s_m2 := base_s * 0.70
	_expect(s_m2.is_equal_approx(exp_s_m2), "ATK -2 reduz escala em -30%% (esperado: %s, atual: %s)" % [str(exp_s_m2), str(s_m2)])

	# Retorno para neutro (ATK 0)
	player.buff_stat("atk", 2)
	_expect(player.atk_buff == 0, "Player ATK buff == 0")
	await create_timer(0.40, true, false, true).timeout
	_expect(model.scale.is_equal_approx(base_s), "ATK 0 retorna à escala base nominal")

	# -------------------------------------------------------------
	# 2. TESTE DE SPD BUFF (+1, +2, -1, -2) -> Animation Speed (±15% per stack)
	# -------------------------------------------------------------
	print("\n--- TESTE 2: SPD BUFF -> VELOCIDADE DE ANIMAÇÃO (±15%) ---")
	if ap:
		# +1 SPD
		player.buff_stat("spd", 1)
		_expect(player.speed_buff == 1, "Player SPD buff == +1")
		await create_timer(0.40, true, false, true).timeout
		var exp_spd_p1 := base_spd * 1.15
		_expect(is_equal_approx(ap.speed_scale, exp_spd_p1), "SPD +1 acelera animação em +15%% (esperado: %.3f, atual: %.3f)" % [exp_spd_p1, ap.speed_scale])
		_expect(is_equal_approx(fx._base_speed[player], exp_spd_p1), "fx._base_speed rastreia velocidade de animação")

		# +2 SPD
		player.buff_stat("spd", 1)
		_expect(player.speed_buff == 2, "Player SPD buff == +2")
		await create_timer(0.40, true, false, true).timeout
		var exp_spd_p2 := base_spd * 1.30
		_expect(is_equal_approx(ap.speed_scale, exp_spd_p2), "SPD +2 acelera animação em +30%% (esperado: %.3f, atual: %.3f)" % [exp_spd_p2, ap.speed_scale])

		# -1 SPD
		player.buff_stat("spd", -3)
		_expect(player.speed_buff == -1, "Player SPD buff == -1")
		await create_timer(0.40, true, false, true).timeout
		var exp_spd_m1 := base_spd * 0.85
		_expect(is_equal_approx(ap.speed_scale, exp_spd_m1), "SPD -1 desacelera animação em -15%% (esperado: %.3f, atual: %.3f)" % [exp_spd_m1, ap.speed_scale])

		# -2 SPD
		player.buff_stat("spd", -1)
		_expect(player.speed_buff == -2, "Player SPD buff == -2")
		await create_timer(0.40, true, false, true).timeout
		var exp_spd_m2 := base_spd * 0.70
		_expect(is_equal_approx(ap.speed_scale, exp_spd_m2), "SPD -2 desacelera animação em -30%% (esperado: %.3f, atual: %.3f)" % [exp_spd_m2, ap.speed_scale])

		# Retorno para neutro (SPD 0)
		player.buff_stat("spd", 2)
		_expect(player.speed_buff == 0, "Player SPD buff == 0")
		await create_timer(0.40, true, false, true).timeout
		_expect(is_equal_approx(ap.speed_scale, base_spd), "SPD 0 retorna à velocidade base de animação")

	# -------------------------------------------------------------
	# 3. TESTE DE DEF BUFF (+1, +2, -1, -2) -> Outline e Shaders (±35%)
	# -------------------------------------------------------------
	print("\n--- TESTE 3: DEF BUFF -> CONTORNO SHADER E BRILHO ARMADURA ---")
	
	var test_mat: BaseMaterial3D = null
	var test_line: ShaderMaterial = null
	for mi in VfxLib.meshes_of(model):
		if mi.name in ["BurstRing", "ReadyRing"] or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m_cand = mi.get_surface_override_material(i)
			if m_cand is BaseMaterial3D:
				test_mat = m_cand
				if test_mat.next_pass is ShaderMaterial:
					test_line = test_mat.next_pass
					break
		if test_mat != null:
			break

	_expect(test_mat != null, "Material de superfície encontrado no modelo")
	_expect(test_line != null, "ShaderMaterial de contorno encontrado no next_pass")

	if test_line != null and test_mat != null:
		# +1 DEF
		player.buff_stat("def", 1)
		_expect(player.def_buff == 1, "Player DEF buff == +1")
		await create_timer(0.40, true, false, true).timeout
		var w_p1: float = test_line.get_shader_parameter("width")
		var exp_w_p1 := 0.0035 * 1.35
		_expect(is_equal_approx(w_p1, exp_w_p1), "DEF +1 engrossa contorno em +35%% (esperado: %.5f, atual: %.5f)" % [exp_w_p1, w_p1])
		_expect(test_mat.metallic >= 0.35, "DEF +1 adiciona brilho metálico de blindagem (atual: %.2f)" % test_mat.metallic)

		# +2 DEF
		player.buff_stat("def", 1)
		_expect(player.def_buff == 2, "Player DEF buff == +2")
		await create_timer(0.40, true, false, true).timeout
		var w_p2: float = test_line.get_shader_parameter("width")
		var exp_w_p2 := 0.0035 * 1.70
		_expect(is_equal_approx(w_p2, exp_w_p2), "DEF +2 engrossa contorno em +70%% (esperado: %.5f, atual: %.5f)" % [exp_w_p2, w_p2])
		_expect(test_mat.metallic >= 0.75, "DEF +2 maximiza blindagem metálica (atual: %.2f)" % test_mat.metallic)

		# -1 DEF
		player.buff_stat("def", -3)
		_expect(player.def_buff == -1, "Player DEF buff == -1")
		await create_timer(0.40, true, false, true).timeout
		var w_m1: float = test_line.get_shader_parameter("width")
		var exp_w_m1 := 0.0035 * 0.65
		_expect(is_equal_approx(w_m1, exp_w_m1), "DEF -1 afina contorno em -35%% (esperado: %.5f, atual: %.5f)" % [exp_w_m1, w_m1])
		_expect(test_mat.metallic == 0.0, "DEF -1 zera brilho metálico")

		# -2 DEF
		player.buff_stat("def", -1)
		_expect(player.def_buff == -2, "Player DEF buff == -2")
		await create_timer(0.40, true, false, true).timeout
		var w_m2: float = test_line.get_shader_parameter("width")
		var exp_w_m2 := 0.0035 * 0.30
		_expect(is_equal_approx(w_m2, exp_w_m2), "DEF -2 afina contorno em -70%% (esperado: %.5f, atual: %.5f)" % [exp_w_m2, w_m2])

		# Retorno para neutro (DEF 0)
		player.buff_stat("def", 2)
		_expect(player.def_buff == 0, "Player DEF buff == 0")
		await create_timer(0.40, true, false, true).timeout
		var w_0: float = test_line.get_shader_parameter("width")
		_expect(is_equal_approx(w_0, 0.0035), "DEF 0 retorna contorno ao valor nominal (0.0035)")

	# -------------------------------------------------------------
	# 4. TESTE DE CLEAR_BUFFS (Restauração total)
	# -------------------------------------------------------------
	print("\n--- TESTE 4: CLEAR_BUFFS() RESTAURAÇÃO TOTAL ---")
	player.buff_stat("atk", 2)
	player.buff_stat("spd", -2)
	player.buff_stat("def", 2)
	await create_timer(0.40, true, false, true).timeout

	_expect(not model.scale.is_equal_approx(base_s), "Modelo está escalado antes de clear_buffs")

	player.clear_buffs()
	_expect(player.atk_buff == 0 and player.speed_buff == 0 and player.def_buff == 0, "clear_buffs zera todos os stacks de buffs")
	await create_timer(0.40, true, false, true).timeout

	_expect(model.scale.is_equal_approx(base_s), "clear_buffs restaura escala original com tween suave")
	if ap:
		_expect(is_equal_approx(ap.speed_scale, base_spd), "clear_buffs restaura velocidade de animação original")
	if test_line:
		var w_clear: float = test_line.get_shader_parameter("width")
		_expect(is_equal_approx(w_clear, 0.0035), "clear_buffs restaura contorno normal")
	if test_mat:
		_expect(test_mat.metallic == 0.0, "clear_buffs restaura metallic neutro (0.0)")

	bs.free()

	print("=================================================================")
	if failures == 0:
		print("D158_BUFF_VISUALS_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
