extends SceneTree
func _init() -> void:
	for f in ["pancham/pancham", "abra/abra", "gible/gible"]:
		var n := (load("res://assets/modelos/%s.glb" % f) as PackedScene).instantiate()
		var a := (n.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation("attack")
		var rot: Array[int] = []
		for i in a.get_track_count():
			if a.track_get_type(i) == Animation.TYPE_ROTATION_3D:
				rot.append(i)
		var line := ""
		var t := 0.0
		var prev := {}
		while t <= 1.0:
			var spd := 0.0
			for i in rot:
				spd = maxf(spd, a.rotation_track_interpolate(i, t).angle_to(a.rotation_track_interpolate(i, t + 1.0 / 30.0)) * 30.0)
			line += "%.2f:%.1f " % [t, spd]
			t += 1.0 / 15.0
		print(f, " ", line)
		n.free()
	quit()
