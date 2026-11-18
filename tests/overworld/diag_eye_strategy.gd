extends SceneTree
## D-1295: onboarding of a model's eyes. For every assets/modelos/<id>/<id>.glb (or --ids=a,b) prints the detected
## closed-eye strategy and what the data has (eye surfaces, Eye_Model meshes, <X>_scale pairs, OpenEye/CloseEye,
## *mabuta* bones, Sleep clip). Logic only (run with --headless). Args: --ids=a,b
func _init() -> void:
	var ids: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="):
			ids = a.substr(6).split(",")
	if ids.is_empty():
		for d in DirAccess.get_directories_at("res://assets/modelos"):
			ids.append(d)
	print("id | strategy | eye_surf | Eye_Model | scale_pairs | closed_decal | open_close | lid_bones | sleep_clip | paint_candidate | clips_with_04")
	for id in ids:
		var path := "res://assets/modelos/%s/%s.glb" % [id, id]
		if not ResourceLoader.exists(path):
			print("%s | NO_GLB" % id)
			continue
		var inst := (load(path) as PackedScene).instantiate()
		root.add_child(inst)
		var ap := _find_ap(inst)
		var clip := ""
		var clips: Array = []
		if ap != null:
			for c in ap.get_animation_list():
				if String(c).ends_with("04"):
					clips.append(String(c))
		if clips.size() > 0:
			clip = clips[0]
		var info: Dictionary = preload("res://scripts/common/eye_strategy.gd").detect(inst, ap, clip)
		print("%s | %s | %d | %s | %d | %s | %s | %d | %s | %s | %s" % [id, info["strategy"], info["eye_surfaces"],
			",".join(PackedStringArray(info["eye_meshes"])), info["scale_pairs"], info["closed_decal"],
			",".join(PackedStringArray(info["open_close"])), (info["lid_bones"] as Array).size(), info["sleep_clip"],
			info["paint_candidate"], ",".join(PackedStringArray(clips))])
		inst.queue_free()
	quit()


func _find_ap(n: Node) -> AnimationPlayer:
	var l := n.find_children("*", "AnimationPlayer", true, false)
	return l[0] as AnimationPlayer if not l.is_empty() else null
