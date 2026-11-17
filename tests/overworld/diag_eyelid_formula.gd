extends SceneTree
## Closed-eye pose per eyelid bone: delta(rest idle -> peak of the clip), axis in the bone's local space.
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var ids := ["pikachu", "eevee", "charmander"]
	var clip := "down"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
		if a.begins_with("--clip="): clip = a.substr(7)
	for id in ids:
		var glb := (load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene).instantiate()
		root.add_child(glb)
		var ap: AnimationPlayer = glb.find_children("*", "AnimationPlayer", true, false)[0]
		var idle := ap.get_animation("idle")
		var an := ap.get_animation(clip)
		for i in an.get_track_count():
			var path := str(an.track_get_path(i))
			if not path.contains("eyelid") or an.track_get_type(i) != Animation.TYPE_ROTATION_3D: continue
			var bone := path.get_slice(":", 1)
			var ii := idle.find_track(an.track_get_path(i), Animation.TYPE_ROTATION_3D)
			var rest: Quaternion = idle.track_get_key_value(ii, 0)
			var best := 0.0; var bt := 0.0; var bq := rest
			for j in an.track_get_key_count(i):
				var q: Quaternion = an.track_get_key_value(i, j)
				var d := rest.angle_to(q)
				if d > best: best = d; bt = an.track_get_key_time(i, j); bq = q
			var dq := bq * rest.inverse()  # world-ish delta
			var dl := rest.inverse() * bq   # local delta
			var ax := dl.get_axis() if best > 0.001 else Vector3.ZERO
			print("FORM ", id, " ", bone, " deg=%.1f t=%.2f local_axis=(%.2f,%.2f,%.2f)" % [rad_to_deg(best), bt, ax.x, ax.y, ax.z])
		glb.queue_free()
	quit(0)
