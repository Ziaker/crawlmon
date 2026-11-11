extends SceneTree
## Mede o tempo REAL entre o impacto e o pedido de transição.
## Rodar SEM --headless (a câmera lenta só roda com display):
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 60 \
##     --script res://tests/overworld/diag_transition_timing.gd -- --case=blue
##
## --case=blue: o jogador aperta Z e acerta.
## --case=red:  o jogador fica parado e espera o inimigo acertar.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"

var _impact_us := -1
var _battle_us := -1
var _scale_at_impact := 1.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var case_name := "blue"
	var dist := 2.2
	var target := "first"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case="):
			case_name = arg.trim_prefix("--case=")
		if arg.begins_with("--dist="):
			dist = float(arg.trim_prefix("--dist="))
		if arg.begins_with("--target="):
			target = arg.trim_prefix("--target=")
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 40:
		await process_frame
	var player: CharacterBody3D = lab.get("player") as CharacterBody3D
	var enemy: Node3D = (lab.get("_second_enemy") if target == "second" else lab.get("_enemy")) as Node3D
	var controller = lab.get("_attack_controller")
	controller.impact_requested.connect(_on_impact)
	controller.battle_requested.connect(_on_battle)
	player.global_position = enemy.global_position + Vector3(0.0, 0.0, dist)
	player.velocity = Vector3.ZERO
	var to := enemy.global_position - player.global_position
	to.y = 0.0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	await physics_frame
	if case_name == "blue":
		_press(KEY_Z, true)
		await physics_frame
		_press(KEY_Z, false)
	var log_frames: Array[String] = []
	for i in 900:
		await physics_frame
		if _impact_us >= 0 and _battle_us < 0:
			log_frames.append("%d:scale=%.3f hold=%.4f" % [
				i, Engine.time_scale, float(controller.get("_impact_hold"))])
			if log_frames.size() > 40:
				log_frames.pop_front()
		if _battle_us >= 0:
			break
	if "--log-frames" in OS.get_cmdline_user_args():
		print("FRAMES ", " | ".join(log_frames))
	var delta_ms := -1
	if _impact_us >= 0 and _battle_us >= 0:
		delta_ms = int((_battle_us - _impact_us) / 1000.0)
	print("TIMING case=%s impact_us=%d battle_us=%d delta_ms=%d scale_at_impact=%.3f" % [
		case_name, _impact_us, _battle_us, delta_ms, _scale_at_impact])
	quit(0)


func _on_impact(_pos: Vector3, _dir: Vector3, _adv: int, _contacts: Array) -> void:
	if _impact_us >= 0:
		return
	_impact_us = Time.get_ticks_usec()
	_scale_at_impact = Engine.time_scale


func _on_battle(_adv: int) -> void:
	if _battle_us < 0:
		_battle_us = Time.get_ticks_usec()


func _press(keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)
