extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	for id in ["charmander", "pikachu", "gible", "pancham"]:
		var glb := (load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene).instantiate()
		root.add_child(glb)
		var ap: AnimationPlayer = glb.find_children("*", "AnimationPlayer", true, false)[0]
		var types := {}
		var eye_tracks := []
		for n in ap.get_animation_list():
			var a := ap.get_animation(n)
			for i in a.get_track_count():
				var path := str(a.track_get_path(i))
				types[a.track_get_type(i)] = int(types.get(a.track_get_type(i), 0)) + 1
				if path.to_lower().contains("eye") and not eye_tracks.has(path):
					eye_tracks.append(path)
		print("EYE ", id, " track_types=", types, " eye_tracks=", eye_tracks.slice(0, 8))
		for mi in glb.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			for s in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(s)
				if mat != null and (str(mat.resource_name).to_lower().contains("eye") or m.name.to_lower().contains("eye")):
					print("EYE   mesh=", m.name, " surf=", s, " mat=", mat.resource_name, " cls=", mat.get_class(), " uv1_scale=", (mat as BaseMaterial3D).uv1_scale if mat is BaseMaterial3D else "-")
		glb.queue_free()
	quit(0)
