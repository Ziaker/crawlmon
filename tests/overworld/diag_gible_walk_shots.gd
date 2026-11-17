extends SceneTree
## Real hub, real key input: Gible walks; prints anim state per frame batch and saves PNGs.
## Run windowed: Godot --path . --script res://tests/overworld/diag_gible_walk_shots.gd -- --out=<dir> [--id=gible]
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var out := "user://shots"
	var id := "gible"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--id="): id = a.substr(5)
	DirAccess.make_dir_recursive_absolute(out)
	var lab: Node = (load("res://scenes/debug/hub_3d_prototype.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 30: await physics_frame
	lab.call("_set_player_species", id)
	for i in 30: await physics_frame
	var ap: AnimationPlayer = lab.get("player_ap")
	print("CLIPS ", id, " ", ap.get_animation_list())
	for n in ap.get_animation_list():
		var an := ap.get_animation(n)
		print("  clip ", n, " len=", an.length, " loop=", an.loop_mode, " tracks=", an.get_track_count())
	var ev := InputEventKey.new()
	ev.keycode = KEY_RIGHT
	ev.physical_keycode = KEY_RIGHT
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 60:
		await physics_frame
		if i % 6 == 0:
			print("F%02d cur=%s pos=%.3f scale=%.2f playing=%s vel=%.2f" % [i, ap.current_animation, ap.current_animation_position, ap.speed_scale, str(ap.is_playing()), (lab.get("player") as CharacterBody3D).velocity.length()])
		if i in [20, 24, 28, 32, 36]:
			await process_frame
			root.get_viewport().get_texture().get_image().save_png("%s/%s_walk_%02d.png" % [out, id, i])
	quit(0)
