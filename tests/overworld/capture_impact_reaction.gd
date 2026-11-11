extends SceneTree
## Windowed visual proof of the DQT hit reaction (D-235/D-1045).
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##       --position -4000,0 --fixed-fps 60 \
##       --script res://tests/overworld/capture_impact_reaction.gd
##
## Triggers the real player attack against the DQT Cyclops and saves frames at
## impact, mid-push and after the push. Headless is not used: the slow motion and
## the rendered viewport are the point of this capture.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const OUT := "res://docs/referencias/exploracao/3d"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(30)
	var player: CharacterBody3D = lab.get("player")
	var rooms: Array = lab.get("_room_enemies")
	var entry: Dictionary = rooms[0]
	var body: Node3D = entry["node"]
	var ap: AnimationPlayer = entry["ap"]
	player.global_position = body.global_position + Vector3(0.0, 0.0, 2.8)
	player.velocity = Vector3.ZERO
	var to := body.global_position - player.global_position
	to.y = 0.0
	var yaw := atan2(to.x, to.z)
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	await _frames(8)
	var start := body.global_position

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
	while lab.get_node_or_null("TackleImpact") == null and guard < 180:
		await _frames(1)
		guard += 1
	print("impact=", lab.get_node_or_null("TackleImpact") != null, " guard=", guard,
		" anim=", ap.current_animation, " moved=%.2f" % body.global_position.distance_to(start))
	await _frames(2)
	_save("test_impact_reaction_cyclops_impact.png")
	await _real(0.25)
	_save("test_impact_reaction_cyclops_push.png")
	await _real(0.55)
	_save("test_impact_reaction_cyclops_after.png")
	print("final anim=", ap.current_animation, " moved=%.2f" % body.global_position.distance_to(start))
	Engine.time_scale = 1.0
	quit(0)


func _real(seconds: float) -> void:
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
