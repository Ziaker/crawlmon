extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	for id in ["pikachu", "eevee", "charmander"]:
		var glb := (load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene).instantiate()
		root.add_child(glb)
		for mi in glb.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			for s in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(s)
				if mat == null or not str(mat.resource_name).ends_with("_eye"): continue
				var arr := m.mesh.surface_get_arrays(s)
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var lo := Vector2(9, 9); var hi := Vector2(-9, -9)
				for u in uv: lo = lo.min(u); hi = hi.max(u)
				var blo := Vector3(9,9,9); var bhi := Vector3(-9,-9,-9)
				for p in v: blo = blo.min(p); bhi = bhi.max(p)
				print("UV ", id, " ", m.name, " s=", s, " uv ", lo, hi, " pos ", blo, bhi)
		glb.queue_free()
	quit(0)
