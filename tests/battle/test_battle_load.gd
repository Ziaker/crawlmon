extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTANDO CARREGAMENTO DA CENA DE BATALHA (scenes/battle.tscn) ---")
	var packed := load("res://scenes/battle.tscn") as PackedScene
	if packed == null:
		print("ERRO: scenes/battle.tscn não pôde ser carregada!")
		quit(1)
		return

	var inst := packed.instantiate()
	root.add_child(inst)
	print("PASS: Instanciou scenes/battle.tscn com sucesso.")

	# Espera 3 frames para disparar _ready, _spawn e inicialização de modelos
	for i in 3:
		await process_frame

	print("PASS: 3 frames processados na cena de batalha sem erros.")
	inst.queue_free()
	print("=== SUCESSO: BATTLE SCENE CARREGOU E EXECUTOU PERFEITAMENTE ===")
	quit(0)
