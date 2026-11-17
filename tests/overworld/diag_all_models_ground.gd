extends SceneTree
## D-1264: sink (m below the rest-pose sole, per clip) for EVERY model in assets/modelos,
## scaled to height 1.0. Also the sole height vs y=0 at rest.
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var lab = load("res://scripts/debug/third_person_3d_lab.gd").new()
	var G = load("res://scripts/overworld/model_gait.gd")
	for id in DirAccess.get_directories_at("res://assets/modelos"):
		if not ResourceLoader.exists("res://assets/modelos/%s/%s.glb" % [id, id]):
			continue
		var model: Node3D = lab.call("_make_model", id, 1.0)
		root.add_child(model)
		await process_frame
		var ap: AnimationPlayer = lab.call("_find_anim_player", model)
		if ap == null:
			print("GROUND %s no_anim" % id)
			model.queue_free()
			continue
		var r: Dictionary = G.analyze(model, ap, 1.0, id)
		var parts := []
		var worst := 0.0
		for c in r:
			parts.append("%s=%.3f" % [c, r[c]["sink"]])
			worst = maxf(worst, float(r[c]["sink"]))
		var rs := float(r["idle"]["rest_sole"]) if r.has("idle") else 0.0
		print("GROUND %s rest_sole_y=%.3f worst_sink=%.3f %s" % [id, rs, worst, " ".join(parts)])
		model.queue_free()
		await process_frame
	quit(0)
