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
	print("   CRAWLMON — TESTES DE VIDA ROLANTE (MOTHER 3 / D-048)")
	print("=================================================================")

	# 1. Verificação inicial de inicialização e toggle
	_expect(Combatant.rolling_hp_enabled == true, "Vida rolante está ativada por padrão")
	
	var hero := Combatant.new("Hero", 60, 15, 0.5, true)
	_expect(hero.hp == 60 and hero.target_hp == 60 and is_equal_approx(hero.rolling_hp, 60.0), "Combatant inicializa com hp, target_hp e rolling_hp sincronizados")

	# 2. Assimetria: Inimigos sofrem dano imediato sem odômetro (fiel a Mother 3)
	var foe := Combatant.new("Foe", 50, 10, 0.4, false)
	foe.take_damage(20)
	_expect(foe.hp == 30 and foe.target_hp == 30 and is_equal_approx(foe.rolling_hp, 30.0), "Inimigos sofrem dano instantaneamente sem usar odômetro")

	# 3. Dano não-fatal no jogador: target_hp é atualizado e o odômetro desce com o tempo
	var tick_events := [0]
	hero.odometer_ticked.connect(func(_c, _v): tick_events[0] += 1)

	hero.take_damage(30) # 60 max, def=0 -> 30 de dano final. Novo target deve ser 30.
	_expect(hero.target_hp == 30, "Dano não-fatal atualiza target_hp imediatamente para 30")
	_expect(hero.hp == 60, "No momento do golpe, hp do jogador ainda está em 60 (rolamento pendente)")

	# Simula 0.5s de tick (em 60 max_hp, taxa ~ 60/3.0 = 20 HP/s -> 0.5s drena ~10 HP)
	hero.tick_rolling_hp(0.5)
	_expect(hero.hp < 60 and hero.hp > 30, "Após 0.5s, odômetro desceu parcialmente (HP atual: %d)" % hero.hp)
	_expect(tick_events[0] > 0, "Sinal odometer_ticked disparado durante a descida dos números (%d tiques)" % tick_events[0])

	# Simula mais 2.0s para concluir o rolamento
	hero.tick_rolling_hp(2.0)
	_expect(hero.hp == 30 and hero.target_hp == 30, "Após o tempo necessário, HP alcançou o target_hp (30)")

	# 4. Dano fatal no jogador: morte imediata sem odômetro
	var died_fired := [false]
	hero.died.connect(func(_c): died_fired[0] = true)
	hero.take_damage(35) # HP atual é 30, dano é 35 (dano >= hp)
	_expect(died_fired[0] == true, "Dano fatal dispara died imediatamente")
	_expect(hero.hp == 0 and hero.target_hp == 0, "Dano fatal zera o HP na hora sem rolamento de odômetro")

	# 5. Cura durante rolamento: inverte o rolamento suavemente (Opção A)
	var hero2 := Combatant.new("Hero2", 100, 15, 0.5, true)
	hero2.in_battle = true
	hero2.take_damage(40) # target_hp = 60
	hero2.tick_rolling_hp(0.3) # drena um pouco: rolling_hp cai para ~90
	var hp_mid := hero2.hp
	_expect(hp_mid < 100 and hp_mid > 60, "HP descendo após dano (HP intermediário: %d)" % hp_mid)

	# Usa cura de +30 HP
	hero2.heal(30)
	# Novo target deve ser 60 + 30 = 90
	_expect(hero2.target_hp == 90, "Cura durante rolamento atualiza novo target_hp para 90")
	
	# Continua tickando: o odômetro deve se mover em direção a 90
	hero2.tick_rolling_hp(1.5)
	_expect(hero2.hp == 90, "Odômetro estabilizou no novo alvo curado (90)")

	# 6. Desaceleração pela câmera lenta (D-047 / D-019):
	# Testamos que em delta escalado por 0.2x o avanço é exatamente 20%
	var hero_norm := Combatant.new("H_Norm", 100, 15, 0.5, true)
	var hero_slow := Combatant.new("H_Slow", 100, 15, 0.5, true)
	hero_norm.take_damage(50)
	hero_slow.take_damage(50)

	var delta_real := 0.5
	hero_norm.tick_rolling_hp(delta_real * 1.0)
	hero_slow.tick_rolling_hp(delta_real * 0.2) # escala de tempo 0.2x

	var drain_norm := 100.0 - hero_norm.rolling_hp
	var drain_slow := 100.0 - hero_slow.rolling_hp
	_expect(is_equal_approx(drain_slow, drain_norm * 0.2), "Sob câmera lenta 0.2x o odômetro drena a 20%% da velocidade normal")

	# 7. Configuração / Toggle desligado:
	Combatant.rolling_hp_enabled = false
	var hero3 := Combatant.new("Hero3", 50, 10, 0.5, true)
	hero3.take_damage(15)
	_expect(hero3.hp == 35 and hero3.target_hp == 35, "Com rolling_hp_enabled = false, dano no jogador é 100%% instantâneo")
	Combatant.rolling_hp_enabled = true # restaura

	# 8. Vitória anula dano restante (Mother 3):
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)

	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame

	var party_lead: Combatant = battle.party[0]
	party_lead.take_damage(20) # inicia rolamento
	_expect(party_lead.target_hp < party_lead.hp, "Dano registrado com target menor que hp")
	
	# Mata todos os inimigos para disparar vitória imediatamente
	for e in battle.enemies:
		e.hp = 0
		e.target_hp = 0
	battle._check_end()
	
	_expect(battle.running == false, "Batalha encerrada com vitória")
	_expect(party_lead.target_hp == party_lead.hp, "Ao vencer a batalha, o odômetro congela e o dano restante é anulado")

	bs.free()

	print("=================================================================")
	if failures == 0:
		print("D048_ROLLING_HP_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
