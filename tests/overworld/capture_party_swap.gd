extends SceneTree
## Windowed proof of the debug party selector (E) and the Orc/DQT framing.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##       --position -4000,0 --fixed-fps 60 \
##       --script res://tests/overworld/capture_party_swap.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT := "res://test_captures"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(40)

	_send_key(KEY_E)
	await _frames(3)
	_save("party_swap_lab_selector.png")

	_send_key(KEY_E)
	await _frames(3)
	var result: Variant = lab.call("debug_swap_party", 2)
	print("swap_orc=", result)
	await _frames(45)
	_save("party_swap_lab_orc.png")

	var player: CharacterBody3D = lab.get("player")
	print("player_height=%.2f cam_dist=%.2f" % [
		float(lab.get("player_height")),
		player.global_position.distance_to((lab.get("_camera") as Camera3D).global_position)])
	quit(0)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved ", file_name)


func _send_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.keycode = keycode
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var rel := InputEventKey.new()
	rel.physical_keycode = keycode
	rel.keycode = keycode
	rel.pressed = false
	Input.parse_input_event(rel)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
