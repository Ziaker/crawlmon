extends SceneTree
## Which eyelid bones are animated per clip (and how much they move) for each species. Args: --ids=a,b
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var ids := ["pikachu", "eevee", "charmander"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
	for id in ids:
		var glb := (load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene).instantiate()
		root.add_child(glb)
		var ap: AnimationPlayer = glb.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ap.get_animation_list():
			var an := ap.get_animation(n)
			var tracks := 0; var moving := 0; var maxd := 0.0
			for i in an.get_track_count():
				if not str(an.track_get_path(i)).to_lower().contains("eyelid"): continue
				if an.track_get_type(i) != Animation.TYPE_ROTATION_3D: continue
				tracks += 1
				var k := an.track_get_key_count(i)
				var q0: Quaternion = an.track_get_key_value(i, 0)
				var d := 0.0
				for j in k:
					d = maxf(d, q0.angle_to(an.track_get_key_value(i, j)))
				if d > 0.01: moving += 1
				maxd = maxf(maxd, d)
			print("LID ", id, " ", n, " len=%.2f" % an.length, " lid_rot_tracks=", tracks, " moving=", moving, " max_deg=%.1f" % rad_to_deg(maxd))
		glb.queue_free()
	quit(0)
