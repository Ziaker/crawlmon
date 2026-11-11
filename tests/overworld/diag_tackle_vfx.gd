extends SceneTree
## Isola as camadas do impacto do Tackle para achar o clarão.
##   --hide=none|star|flip|white|cone
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/overworld/diag_tackle_vfx.gd -- --hide=star

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT := "res://docs/referencias/ui/attack_overhaul"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var mode := "none"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hide="):
			mode = arg.trim_prefix("--hide=")
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
	if host != null:
		for child in host.get_children():
			if not (child is Node3D):
				continue
			var n := child as Node3D
			var hide := false
			match mode:
				"star":
					hide = n.name.begins_with("@") and n is MeshInstance3D
				"star1":
					hide = n == host.get_child(0)
				"flip":
					hide = n.name.contains("Flipbook")
				"white":
					hide = (n.name.begins_with("@") and n is MeshInstance3D) or n.name.contains("Flipbook")
				"cone":
					hide = n.name.contains("ShockCone") or n.name.contains("SlashArc")
			if hide:
				n.visible = false
		print("mode=", mode, " host=", host, " scale=", host.scale.x)
	await _frames(1)
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join("vfx_%s.png" % mode))
	print("saved vfx_%s.png" % mode)
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
