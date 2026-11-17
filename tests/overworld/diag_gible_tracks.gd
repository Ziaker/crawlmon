extends SceneTree
## D-1264: prints sink (m below rest) and ground speed (m/s) per clip for each species.
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var lab = load("res://scripts/debug/third_person_3d_lab.gd").new()
	for id in ["abra", "pancham", "gible", "dqt_slime", "dqt_orc", "dqt_cyclops"]:
		var model: Node3D = lab.call("_make_model", id, 1.0)
		root.add_child(model)
		await process_frame
		var ap: AnimationPlayer = lab.call("_find_anim_player", model)
		var r: Dictionary = load("res://scripts/overworld/model_gait.gd").analyze(model, ap, 1.0)
		print("== ", id)
		for c in r:
			print("  %s sink=%.3f ground_speed=%.2f len=%.2f" % [c, r[c]["sink"], r[c]["ground_speed"], r[c]["length"]])
		model.queue_free()
	quit(0)
