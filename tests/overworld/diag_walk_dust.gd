extends SceneTree
## Diagnóstico do dust de caminhada (D-1173). Rodar headless.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 30:
		await process_frame
	var player: CharacterBody3D = lab.get("player")
	var dust: CPUParticles3D = lab.get("_player_dust")
	print("dust=", dust, " class=", dust.get_class(), " script=", dust.get_script())
	print("before emitting=", dust.emitting, " children=", dust.get_child_count(), " visible=", dust.visible)
	player.global_position = Vector3(6.0, 0.25, 0.0)
	lab.set("_cam_yaw", PI * 0.5)
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_W
	ev.keycode = KEY_W
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 40:
		await physics_frame
	print("after emitting=", dust.emitting, " children=", dust.get_child_count(),
		" pos=", player.global_position, " vel=", player.velocity)
	for child in dust.get_children():
		if child is CPUParticles3D:
			var p := child as CPUParticles3D
			print("  burst emitting=", p.emitting, " amount=", p.amount,
				" pos=", p.global_position, " visible=", p.visible,
				" speed_scale=", p.speed_scale, " lifetime=", p.lifetime,
				" aabb=", p.visibility_aabb)
	var rel := InputEventKey.new()
	rel.physical_keycode = KEY_W
	rel.keycode = KEY_W
	rel.pressed = false
	Input.parse_input_event(rel)
	quit(0)
