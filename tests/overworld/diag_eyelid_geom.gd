extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var id := "pikachu"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="): id = a.substr(5)
	var glb := (load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene).instantiate()
	root.add_child(glb)
	var sk: Skeleton3D = glb.find_children("*", "Skeleton3D", true, false)[0]
	var eye := Vector3.ZERO; var n := 0
	for b in sk.get_bone_count():
		if sk.get_bone_name(b).begins_with("left_") and sk.get_bone_name(b).contains("eyelid"):
			eye += sk.get_bone_global_pose(b).origin; n += 1
	eye /= n
	print("GEOM eye_center=", eye, " nbones=", n)
	for b in sk.get_bone_count():
		var nm := sk.get_bone_name(b)
		if nm.begins_with("left_") and nm.contains("eyelid"):
			var gp := sk.get_bone_global_pose(b)
			var par := sk.get_bone_parent(b)
			print("GEOM ", nm, " rel=", ((gp.origin - eye) * 1000.0).snapped(Vector3(0.1,0.1,0.1)), " parent=", sk.get_bone_name(par) if par >= 0 else "-", " ydir=", gp.basis.y.snapped(Vector3(0.01,0.01,0.01)))
	glb.queue_free()
	quit(0)
