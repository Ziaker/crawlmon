extends SceneTree
## Diagnóstico do Z com o timing Comic: distância, impacto e vantagem.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --headless --fixed-fps 60 \
##     --script res://tests/overworld/diag_z_comic.gd -- --dist=2.2

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var dist := 2.2
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dist="):
			dist = float(arg.trim_prefix("--dist="))
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 40:
		await process_frame
	var player: CharacterBody3D = lab.get("player") as CharacterBody3D
	var target_name := "slime"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--target="):
			target_name = arg.trim_prefix("--target=")
	var enemy: Node3D = (lab.get("_enemy") if target_name == "slime" else lab.get("_second_enemy")) as Node3D
	var c = lab.get("_attack_controller")
	var impacts: Array = []
	var battles: Array = []
	c.impact_requested.connect(func(pos: Vector3, _dir: Vector3, adv: int, contacts: Array) -> void:
		impacts.append({"adv": adv, "pos": pos, "contacts": contacts.size(),
			"gap": player.global_position.distance_to(enemy.global_position)}))
	c.battle_requested.connect(func(adv: int) -> void: battles.append(adv))
	player.global_position = enemy.global_position + Vector3(0.0, 0.0, dist)
	player.velocity = Vector3.ZERO
	var to := enemy.global_position - player.global_position
	to.y = 0.0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	await physics_frame
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_Z
	ev.keycode = KEY_Z
	ev.pressed = true
	Input.parse_input_event(ev)
	await physics_frame
	var rel := InputEventKey.new()
	rel.physical_keycode = KEY_Z
	rel.keycode = KEY_Z
	rel.pressed = false
	Input.parse_input_event(rel)
	for i in 240:
		await physics_frame
		if not battles.is_empty():
			break
	print("RESULT dist=%.1f impacts=%s battles=%s phase=%s" % [
		dist, str(impacts), str(battles), str(c.get("_player_phase"))])
	quit(0)
