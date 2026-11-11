extends SceneTree
## D-1173: real-lab dash dust, no walking case (avoids a stray encounter).
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 60 \
##     --script res://tests/overworld/capture_dash_real.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT := "res://test_captures"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(30)
	for child in lab.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	var player: CharacterBody3D = lab.get("player")
	var target: Node3D = lab.get("_enemy")
	# Freeze every other enemy; only the dash target stays.
	for entry in lab.get("_room_enemies"):
		(entry["node"] as Node3D).process_mode = Node.PROCESS_MODE_DISABLED
	var gible: Node3D = lab.get("_second_enemy")
	gible.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = target.global_position + Vector3(0.0, 0.0, 3.0)
	player.velocity = Vector3.ZERO
	var to := target.global_position - player.global_position
	to.y = 0.0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	await _frames(12)
	_press(KEY_Z, true)
	await _frames(1)
	_press(KEY_Z, false)
	await _seconds(0.05)
	_save("d1173_dash_real_takeoff.png")
	await _seconds(0.08)
	_save("d1173_dash_real_trail.png")
	await _seconds(0.10)
	_save("d1173_dash_real_after.png")
	Engine.time_scale = 1.0
	quit(0)


func _press(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved ", file_name)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
