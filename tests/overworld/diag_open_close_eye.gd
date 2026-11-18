extends SceneTree
## D-1295: how a model keeps its OpenEye/CloseEye nodes (type, parent, children) and the scale each clip gives them at
## t=0 / mid / end. Logic only. Args: --id=dqt_platypunk
func _init() -> void:
	var id := "dqt_platypunk"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="):
			id = a.substr(5)
	var inst := (load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene).instantiate()
	root.add_child(inst)
	for nm in ["OpenEye", "CloseEye"]:
		var n := inst.find_child(nm, true, false)
		print(nm, " -> ", n, " class=", n.get_class() if n else "-", " parent=", n.get_parent().name if n else "-")
		if n:
			for c in n.get_children():
				print("   child ", c.name, " ", c.get_class())
	for n in inst.find_children("Eye_Model*", "MeshInstance3D", true, false):
		print("mesh ", n.name, " parent=", n.get_parent().name, " vis=", n.visible)
	var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
	for c in ap.get_animation_list():
		var anim := ap.get_animation(c)
		var line := ""
		for i in anim.get_track_count():
			var p := String(anim.track_get_path(i))
			if p.contains("OpenEye") or p.contains("CloseEye"):
				var ty := anim.track_get_type(i)
				if ty == Animation.TYPE_SCALE_3D:
					var t0 := anim.scale_track_interpolate(i, 0.0).x
					var tm := anim.scale_track_interpolate(i, anim.length * 0.5).x
					line += " %s=%.2f/%.2f" % [p.get_slice(":", p.get_slice_count(":") - 1), t0, tm]
				elif ty == Animation.TYPE_POSITION_3D:
					line += " %s pos0=%s mid=%s |" % [p.get_slice(":", p.get_slice_count(":") - 1), anim.position_track_interpolate(i, 0.0), anim.position_track_interpolate(i, anim.length * 0.5)]
		print(c, " len=%.2f" % anim.length, line)
	quit()
