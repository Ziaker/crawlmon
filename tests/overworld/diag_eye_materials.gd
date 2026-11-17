extends SceneTree
## Dumps every surface material of the given species' GLB (eye ones flagged). Args: --ids=a,b
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var ids := ["pikachu", "eevee", "charmander", "bulbasaur", "gible"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
	for id in ids:
		var ps := load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene
		if ps == null:
			print("MAT ", id, " LOAD FAIL"); continue
		var glb := ps.instantiate()
		root.add_child(glb)
		for mi in glb.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			for s in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(s)
				var line := "MAT %s mesh=%s s=%d mat=%s" % [id, m.name, s, mat.resource_name if mat else "null"]
				if mat is BaseMaterial3D:
					var b := mat as BaseMaterial3D
					line += " alb=%s tex=%s emis=%s etex=%s transp=%d shading=%d cull=%d metal=%.2f rough=%.2f" % [b.albedo_color, b.albedo_texture.resource_path if b.albedo_texture else "NONE", b.emission_enabled, b.emission_texture != null, b.transparency, b.shading_mode, b.cull_mode, b.metallic, b.roughness]
					if b.albedo_texture:
						var img := b.albedo_texture.get_image()
						if img:
							var c := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
							line += " center_px=" + str(c) + " size=" + str(img.get_size())
				print(line)
		glb.queue_free()
	quit(0)
