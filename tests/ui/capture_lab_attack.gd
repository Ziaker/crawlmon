extends SceneTree
## Verifica o Z no lab do GLIFO: o boneco ataca (lunge + clipe), sem batalha.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/ui/capture_lab_attack.gd

const LAB := "res://scenes/debug/attack_hud_lab.tscn"
const OUT := "res://docs/referencias/ui/attack_hud_lab"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 50:
		await process_frame
	var player = lab.get("_player")
	var start: Vector3 = player.global_position
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_Z
	ev.keycode = KEY_Z
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var rel := InputEventKey.new()
	rel.physical_keycode = KEY_Z
	rel.keycode = KEY_Z
	rel.pressed = false
	Input.parse_input_event(rel)
	for i in 24:
		await process_frame
		if i in [1, 6, 12, 20]:
			_save("lab_attack_%02d.png" % i)
	print("moved=%.3f" % player.global_position.distance_to(start))
	quit(0)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved %s" % file_name)
