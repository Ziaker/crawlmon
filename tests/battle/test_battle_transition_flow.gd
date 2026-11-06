extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTANDO FLUXO COMPLETO: EXPLORAÇÃO -> TRANSIÇÃO -> BATALHA ---")

	# 1. Carregar a cena principal de exploração
	var exp_packed := load("res://scenes/exploration.tscn") as PackedScene
	if exp_packed == null:
		print("ERRO: Não foi possível carregar scenes/exploration.tscn")
		quit(1)
		return

	var exp_scene := exp_packed.instantiate()
	root.add_child(exp_scene)
	current_scene = exp_scene
	print("PASS: Exploração instanciada e ativa.")

	for i in 5:
		await process_frame

	# 2. Acionar início de batalha como ocorre quando colide com inimigo
	print("Disparando GameState.start_battle()...")
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		# Instancia autoload se executando isoladamente via SceneTree script
		var gs_script = preload("res://scripts/autoload/game_state.gd")
		gs = gs_script.new()
		gs.name = "GameState"
		root.add_child(gs)
	gs.start_battle("test_enemy", Vector2(120, 120))

	# 3. Aguardar a transição e troca de cena para battle.tscn.
	# 600 frames: a intro roda em tempo real e o headless pode ter delta menor
	# que 1/60 s; 180 frames era curto demais.
	var timeout := 600
	var battle_loaded := false
	for i in timeout:
		await process_frame
		if current_scene != null and current_scene.name == "BattleScene":
			battle_loaded = true
			break

	if not battle_loaded:
		# Se a transição mudou via change_scene_to_file mas current_scene não foi atribuído diretamente, buscar na raiz
		for c in root.get_children():
			if c.name == "BattleScene":
				battle_loaded = true
				break

	if not battle_loaded:
		print("ERRO: Cena de batalha não carregou após a transição!")
		quit(1)
		return

	print("PASS: Cena de batalha carregada com sucesso após transição!")

	# 4. Aguardar a intro dos combatentes correndo e o início do combate.
	# O teste precisa FALHAR se o loop não iniciar; apenas imprimir "PASS" não vale.
	var battle_running := false
	for i in timeout:
		await process_frame
		var bs = root.get_node_or_null("BattleScene")
		if bs != null and bs.battle != null and bs.battle.running:
			battle_running = true
			break

	if not battle_running:
		print("ERRO: a batalha carregou, mas battle.running continuou false após %d frames!" % timeout)
		quit(1)
		return

	print("PASS: Batalha iniciada e em execução (battle.running = %s)!" % battle_running)

	# 5. Executar mais 60 frames com a batalha ativa
	for i in 60:
		await process_frame

	print("PASS: 60 frames de batalha executados sem nenhum erro ou travamento.")
	print("=== FLUXO COMPLETO DE TRANSIÇÃO E COMBATE TESTADO COM 100% DE SUCESSO ===")
	quit(0)
