extends SceneTree
## D-1100/D-1106: grava o ataque no lab real (modelos GLB, câmera do lab).
##
## Rodar SEM --headless, com --write-movie:
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 30 --write-movie <saida.avi> \
##     --script res://tests/overworld/record_lab_attack_video.gd -- --scenario=player
##
## Cenários: player (Abra ataca o Slime; transição azul), enemy (Gible ataca o
## jogador; transição vermelha) e contact (encostar no Slime; transição branca).
## O clipe termina no começo da transição.

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
	if scenario == "enemy":
		# Gible is not the Medroso; the Slime keeps D-1086. The Gible is already
		# registered by the lab and will enter CHASE on its own.
		pass
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

	# Player at +Z of the target, facing it. Contact uses the Medroso Slime
	# (passive, no CHASE), so the touch is a normal contact, not an enemy attack.
	var offset := 0.30 if scenario == "contact" else 3.0
	player.global_position = target.global_position + Vector3(0.0, 0.0, offset)
	player.velocity = Vector3.ZERO
	var to_target := target.global_position - player.global_position
	to_target.y = 0.0
	var yaw := atan2(to_target.x, to_target.z)
	lab.set("player_yaw", yaw)
	player.rotation.y = yaw

	# Side camera for the player/contact cases; the enemy case uses the lab
	# camera behind the player, because the impact happens on the player.
	if scenario != "enemy":
		var cam := Camera3D.new()
		cam.fov = 55.0
		lab.add_child(cam)
		cam.current = true
		var mid := (player.global_position + target.global_position) * 0.5
		var flat_dir := (target.global_position - player.global_position)
		flat_dir.y = 0.0
		flat_dir = flat_dir.normalized()
		var side := Vector3(-flat_dir.z, 0.0, flat_dir.x)
		cam.global_position = mid + side * 5.5 + Vector3(0.0, 2.4, 0.0)
		cam.look_at(mid + Vector3(0.0, 0.8, 0.0), Vector3.UP)
	await _frames(20)

	if scenario == "player":
		controller.try_interact()
		await _seconds(3.0)
	elif scenario == "contact":
		# The controller detects the touch and starts the white CONTATO transition.
		await _seconds(1.8)
	else:
		# Wait for the Gible CHASE -> telegraph (0.4 s) -> pre-advance -> dash -> impact.
		await _seconds(3.8)
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true).timeout
