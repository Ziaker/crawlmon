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
	print("   CRAWLMON — TESTES DE BUFFS ±5 E CÁLCULO FRACIONÁRIO (D-159)")
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
	var base_s: Vector3 = fx._orig_scale.get(player, model.scale)

	# -------------------------------------------------------------
	# 1. TESTE DE ACUMULAÇÃO ADITIVA E LIMITES ±5
	# -------------------------------------------------------------
	print("\n--- TESTE 1: ACUMULAÇÃO ADITIVA (-3 + 1 = -2) E LIMITES ±5 ---")
	
	player.clear_buffs()
	_expect(player.atk_buff == 0, "Buff inicial zerado")

	# Caso literal do criador: ATK -3 + 1 -> -2
	player.buff_stat("atk", -3)
	_expect(player.atk_buff == -3, "Aplica ATK -3 (atual: %d)" % player.atk_buff)

	player.buff_stat("atk", 1)
	_expect(player.atk_buff == -2, "Caso do criador: ATK -3 com buff +1 resulta em ATK -2 (atual: %d)" % player.atk_buff)

	# Limite inferior -5
	player.buff_stat("atk", -3)
	_expect(player.atk_buff == -5, "Atinge limite mínimo de ATK -5 (atual: %d)" % player.atk_buff)
	_expect(not player.can_buff("atk", -1), "can_buff retorna falso para redução além de -5")

	player.buff_stat("atk", -2)
	_expect(player.atk_buff == -5, "Buff não ultrapassa limite inferior de -5 (atual: %d)" % player.atk_buff)

	# Limite superior +5
	player.buff_stat("atk", 10)
	_expect(player.atk_buff == 5, "Atinge limite máximo de ATK +5 (atual: %d)" % player.atk_buff)
	_expect(not player.can_buff("atk", 1), "can_buff retorna falso para aumento além de +5")

	player.buff_stat("atk", 2)
	_expect(player.atk_buff == 5, "Buff não ultrapassa limite superior de +5 (atual: %d)" % player.atk_buff)

	# Mesma regra para DEF e SPD
	player.buff_stat("def", 5)
	_expect(player.def_buff == 5, "DEF atinge +5")
	player.buff_stat("def", -10)
	_expect(player.def_buff == -5, "DEF atinge -5")

	player.buff_stat("spd", 5)
	_expect(player.speed_buff == 5, "SPD atinge +5")
	player.buff_stat("spd", -10)
	_expect(player.speed_buff == -5, "SPD atinge -5")

	# -------------------------------------------------------------
	# 2. TESTE DE CÁLCULO FRACIONÁRIO DE COMBATE
	# -------------------------------------------------------------
	print("\n--- TESTE 2: FÓRMULA FRACIONÁRIA DE COMBATE (SMT/POKÉMON) ---")
	
	player.clear_buffs()
	player.base_attack = 100

	# Testes positivos de ATK
	player.buff_stat("atk", 1) # +1 -> x1.25 -> 125
	_expect(player.attack == 125, "ATK +1 calcula 125 (esperado: 125, atual: %d)" % player.attack)

	player.buff_stat("atk", 1) # +2 -> x1.50 -> 150
	_expect(player.attack == 150, "ATK +2 calcula 150 (esperado: 150, atual: %d)" % player.attack)

	player.buff_stat("atk", 3) # +5 -> x2.25 -> 225
	_expect(player.attack == 225, "ATK +5 calcula 225 (esperado: 225, atual: %d)" % player.attack)

	# Testes negativos de ATK
	player.buff_stat("atk", -6) # -1 -> 100 / 1.25 = 80
	_expect(player.attack == 80, "ATK -1 calcula 80 (esperado: 80, atual: %d)" % player.attack)

	player.buff_stat("atk", -1) # -2 -> 100 / 1.50 = 67
	_expect(player.attack == 67, "ATK -2 calcula 67 (esperado: 67, atual: %d)" % player.attack)

	player.buff_stat("atk", -3) # -5 -> 100 / 2.25 = 44
	_expect(player.attack == 44, "ATK -5 calcula 44 sem zerar ou negativar (esperado: 44, atual: %d)" % player.attack)

	# Testes de DEF mitigação e amplificação de dano
	player.clear_buffs()
	var dummy_enemy: Combatant = battle.enemies[0]
	dummy_enemy.clear_buffs()

	# DEF +5: recebe 100 / 2.25 = 44 de dano (mitigação de 56%)
	dummy_enemy.buff_stat("def", 5)
	dummy_enemy.hp = 1000
	dummy_enemy.take_damage(100)
	var dmg_def_p5 := 1000 - dummy_enemy.hp
	_expect(dmg_def_p5 == 44, "DEF +5 mitiga dano para 44 (não zera nem cura, esperado: 44, atual: %d)" % dmg_def_p5)

	# DEF -5: recebe 100 * 2.25 = 225 de dano (+125% dano)
	dummy_enemy.buff_stat("def", -10)
	dummy_enemy.hp = 1000
	dummy_enemy.take_damage(100)
	var dmg_def_m5 := 1000 - dummy_enemy.hp
	_expect(dmg_def_m5 == 225, "DEF -5 amplifica dano para 225 (+125%%, esperado: 225, atual: %d)" % dmg_def_m5)

	# -------------------------------------------------------------
	# 3. TESTE DE TETO VISUAL EM 3 STACKS NOS MODELOS 3D
	# -------------------------------------------------------------
	print("\n--- TESTE 3: TETO VISUAL TRAVADO EM 3 STACKS (D-159) ---")

	player.clear_buffs()
	await create_timer(0.40, true, false, true).timeout

	# +3 Stacks
	player.buff_stat("atk", 3)
	await create_timer(0.40, true, false, true).timeout
	var s_p3 := model.scale
	var exp_s_p3 := base_s * (1.0 + 3.0 * 0.15) # 1.45
	_expect(s_p3.is_equal_approx(exp_s_p3), "Escala do modelo em +3 é 1.45 (atual: %s)" % str(s_p3))

	# +4 e +5 Stacks mantêm a escala de +3
	player.buff_stat("atk", 2)
	_expect(player.atk_buff == 5, "Lógica em +5 ATK")
	await create_timer(0.40, true, false, true).timeout
	var s_p5 := model.scale
	_expect(s_p5.is_equal_approx(exp_s_p3), "Teto visual: modelo em +5 ATK não passa da escala de +3 (atual: %s, teto: %s)" % [str(s_p5), str(exp_s_p3)])

	# -3 Stacks
	player.buff_stat("atk", -8) # de +5 para -3
	_expect(player.atk_buff == -3, "Lógica em -3 ATK")
	await create_timer(0.40, true, false, true).timeout
	var s_m3 := model.scale
	var exp_s_m3 := base_s * (1.0 - 3.0 * 0.15) # 0.55
	_expect(s_m3.is_equal_approx(exp_s_m3), "Escala do modelo em -3 é 0.55 (atual: %s)" % str(s_m3))

	# -4 e -5 Stacks mantêm a escala de -3
	player.buff_stat("atk", -2) # de -3 para -5
	_expect(player.atk_buff == -5, "Lógica em -5 ATK")
	await create_timer(0.40, true, false, true).timeout
	var s_m5 := model.scale
	_expect(s_m5.is_equal_approx(exp_s_m3), "Piso visual: modelo em -5 ATK não encolhe além de -3 (atual: %s, piso: %s)" % [str(s_m5), str(exp_s_m3)])

	# Limpeza geral
	player.clear_buffs()
	await create_timer(0.40, true, false, true).timeout
	_expect(model.scale.is_equal_approx(base_s), "clear_buffs restaura escala padrão")

	bs.free()

	print("=================================================================")
	if failures == 0:
		print("D159_BUFF_STACKS_LIMIT5_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
