extends SceneTree
## Captura o impacto real do Tackle no overworld (VFX original, só posição/escala).
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/overworld/capture_tackle_impact.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT := "res://docs/referencias/ui/attack_overhaul"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 40:
		await process_frame
	var player: CharacterBody3D = lab.get("player") as CharacterBody3D
	var enemy: Node3D = lab.get("_enemy") as Node3D
	player.global_position = enemy.global_position + Vector3(0.0, 0.0, 2.2)
	player.velocity = Vector3.ZERO
	var to := enemy.global_position - player.global_position
	to.y = 0.0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	await _frames(15)

	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_Z
	ev.keycode = KEY_Z
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(1)
	var rel := InputEventKey.new()
	rel.physical_keycode = KEY_Z
	rel.keycode = KEY_Z
	rel.pressed = false
	Input.parse_input_event(rel)

	var guard := 0
	while lab.get_node_or_null("TackleImpact") == null and guard < 120:
		await _frames(1)
		guard += 1
	var host := lab.get_node_or_null("TackleImpact") as Node3D
	print("host=", host, " pos=", host.global_position if host else "null",
		" scale=", host.scale.x if host else 0.0)
	for i in 24:
		await _frames(1)
		if i in [0, 2, 5, 9, 14, 20]:
			_save("tackle_impact_%02d.png" % i)
	quit(0)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved %s" % file_name)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
