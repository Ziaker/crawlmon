extends SceneTree
## D-1173: video da revisão — caminhada e dash do overworld, normal e espelhado.
## Rodar SEM --headless, com Movie Maker:
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 60 --write-movie test_captures/d1173_dust.avi \
##     --script res://tests/overworld/record_dust_match_video.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# 1) Caminhada: lado normal e lado espelhado, no salão central.
	var lab := await _load_lab()
	var player: CharacterBody3D = lab.get("player")
	var cam := _side_camera(lab)
	player.global_position = Vector3(5.5, 0.25, 0.0)
	lab.set("_cam_yaw", PI * 0.5)
	lab.set("player_yaw", PI * 0.5)
	player.rotation.y = PI * 0.5
	_press(KEY_W, true)
	for i in 96:
		_follow_walk_camera(cam, player, 3.2)
		await process_frame
	# Espelho: mesma caminhada, câmera do outro lado.
	player.global_position = Vector3(5.5, 0.25, 0.0)
	for i in 96:
		_follow_walk_camera(cam, player, -3.2)
		await process_frame
	_press(KEY_W, false)
	await _frames(6)

	# 2) Dash normal, do lado direito da ação.
	await _prepare_dash(lab)
	var target: Node3D = lab.get("_enemy")
	_player_near(lab, player, target, 2.2)
	_place_action_camera(cam, player, target, 1.0)
	await _frames(10)
	await _dash_and_record(cam, player, target, 1.0, 72)
	lab.queue_free()
	await _frames(3)

	# 3) Dash espelhado, lab novo e câmera do lado esquerdo.
	lab = await _load_lab()
	player = lab.get("player")
	cam = _side_camera(lab)
	await _prepare_dash(lab)
	target = lab.get("_enemy")
	_player_near(lab, player, target, 2.2)
	_place_action_camera(cam, player, target, -1.0)
	await _frames(10)
	await _dash_and_record(cam, player, target, -1.0, 72)
	Engine.time_scale = 1.0
	quit(0)


func _dash_and_record(cam: Camera3D, player: CharacterBody3D, target: Node3D,
		side: float, frames: int) -> void:
	_press(KEY_Z, true)
	await process_frame
	_press(KEY_Z, false)
	for i in frames:
		_place_action_camera(cam, player, target, side)
		await process_frame


func _load_lab() -> Node3D:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 30:
		await process_frame
	for child in lab.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	# O Gible é movido para longe para não entrar em CHASE no vídeo.
	var gible: Node3D = lab.get("_second_enemy")
	if gible != null:
		gible.global_position = Vector3(32.0, 0.0, 32.0)
	return lab


func _prepare_dash(lab: Node3D) -> void:
	var controller = lab.get("_attack_controller")
	controller.process_mode = Node.PROCESS_MODE_INHERIT
	# Gravação: o ataque e o VFX rodam, mas a transição de batalha não abre.
	for conn in controller.battle_requested.get_connections():
		controller.battle_requested.disconnect(conn["callable"])
	await _frames(2)


func _player_near(lab: Node3D, player: CharacterBody3D, target: Node3D, distance: float) -> void:
	player.global_position = target.global_position + Vector3(0.0, 0.0, distance)
	player.velocity = Vector3.ZERO
	var to := target.global_position - player.global_position
	to.y = 0.0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	player.rotation.y = yaw


func _side_camera(lab: Node3D) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = 56.0
	lab.add_child(cam)
	cam.current = true
	return cam


func _follow_walk_camera(cam: Camera3D, player: Node3D, side: float) -> void:
	cam.global_position = Vector3(player.global_position.x, 1.25, player.global_position.z + side)
	cam.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)


func _place_action_camera(cam: Camera3D, player: Node3D, target: Node3D, side: float) -> void:
	var mid := (player.global_position + target.global_position) * 0.5
	cam.global_position = Vector3(mid.x + 2.2 * side, 1.15, mid.z)
	cam.look_at(Vector3(mid.x, 0.45, mid.z), Vector3.UP)


func _press(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
