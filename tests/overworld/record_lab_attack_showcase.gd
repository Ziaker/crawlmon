extends SceneTree
## D-1125 / D-1120: grava a demonstração limpa do ataque no lab real.
## - HUD do lab oculto (CanvasLayer), câmera de lado, atacante e alvo visíveis.
## - Rótulos 3D "JOGADOR" e "INIMIGO" para não confundir os dois Gibles.
## - Rodar SEM --headless, com --fixed-fps 120:
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 120 --write-movie <saida.avi> \
##     --script res://tests/overworld/record_lab_attack_showcase.gd -- --scenario=player
##
## Cenários: player (jogador ataca o Slime; azul), enemy (Gible ataca o
## jogador; vermelho) e contact (encostar no Slime; branco).

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"

var scenario := "player"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenario="):
			scenario = a.substr(11)
	call_deferred("_run")


func _run() -> void:
	var packed := load(LAB) as PackedScene
	if packed == null:
		push_error("lab scene missing")
		quit(1)
		return
	var lab := packed.instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(20)

	var controller = lab.get("_attack_controller")
	var player: CharacterBody3D = lab.get("player")
	if controller == null or player == null:
		push_error("lab attack controller/player missing")
		quit(1)
		return

	var target: Node3D = lab.get("_enemy") if scenario in ["player", "contact"] else lab.get("_second_enemy")
	if target == null:
		push_error("target missing for scenario " + scenario)
		quit(1)
		return

	# HUD do lab: some com o texto de debug, minimapa, prompts e badges.
	for child in lab.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false

	# Posição e enquadramento iguais para os três casos.
	var offset := 0.30 if scenario == "contact" else 3.0
	player.global_position = target.global_position + Vector3(0.0, 0.0, offset)
	player.velocity = Vector3.ZERO
	var to_target := target.global_position - player.global_position
	to_target.y = 0.0
	var yaw := atan2(to_target.x, to_target.z)
	lab.set("player_yaw", yaw)
	player.rotation.y = yaw

	var mid := (player.global_position + target.global_position) * 0.5
	var flat := to_target.normalized()
	var side := Vector3(-flat.z, 0.0, flat.x)
	var cam := Camera3D.new()
	cam.fov = 58.0
	lab.add_child(cam)
	# Câmera baixa e próxima: enquadra os dois corpos e corta os ícones/placas
	# altos do lab (D-1125), que poluíam a leitura.
	cam.global_position = mid + side * 4.6 + Vector3(0.0, 1.35, 0.0)
	cam.look_at(mid + Vector3(0.0, 0.65, 0.0), Vector3.UP)
	cam.current = true
	await _frames(20)

	if scenario == "player":
		controller.try_interact()
		await _seconds(2.20)
	elif scenario == "contact":
		await _seconds(1.40)
	else:
		# Gible entra em CHASE sozinho: telegraph 0,4 + wind-up 0,12 + dash
		# 0,18 + impacto 0,5; a transição vem depois. Espera o suficiente para
		# a tela ENCONTRO aparecer inteira (D-1125).
		await _seconds(2.40)
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true).timeout
