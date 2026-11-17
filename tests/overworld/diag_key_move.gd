extends SceneTree
## Real input path: holds UP and prints how far each leader moves in 1.5 s (0 = the character is frozen).
const HUB := "res://scenes/debug/murky_forest_3d_lab.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for id in ["abra", "dqt_orc"]:
		var lab: Node = (load(HUB) as PackedScene).instantiate()
		root.add_child(lab)
		for i in 6: await physics_frame
		if lab.has_method("_set_player_species"): lab.call("_set_player_species", id)
		await physics_frame
		var player: CharacterBody3D = lab.get("player")
		var start := player.global_position
		var ev := InputEventKey.new()
		ev.keycode = KEY_UP
		ev.physical_keycode = KEY_UP
		ev.pressed = true
		Input.parse_input_event(ev)
		for i in 90: await physics_frame
		var p := player.global_position
		print("KEY_MOVE %s moved=%.2f speed_scale=%.2f anim=%s" % [id, Vector2(p.x, p.z).distance_to(Vector2(start.x, start.z)), (lab.get("player_ap") as AnimationPlayer).speed_scale, (lab.get("player_ap") as AnimationPlayer).current_animation])
		ev.pressed = false
		Input.parse_input_event(ev)
		lab.queue_free()
		await physics_frame
	quit(0)
