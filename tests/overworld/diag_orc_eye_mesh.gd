extends SceneTree
## D-1295: forma e UV da malha Eye_Model_a do Orc (base do shader de pálpebra).
func _init() -> void:
	var inst := (load("res://assets/modelos/dqt_orc/dqt_orc.glb") as PackedScene).instantiate()
	root.add_child(inst)
	for n in inst.find_children("Eye_Model*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var a := mi.mesh.surface_get_arrays(0)
		var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var lo := Vector2(1e9, 1e9)
		var hi := Vector2(-1e9, -1e9)
		for p in uv:
			lo = lo.min(p)
			hi = hi.max(p)
		print("MESH ", mi.name, " verts=", vs.size(), " uv ", lo, hi, " aabb=", mi.mesh.get_aabb(), " mat=", mi.mesh.surface_get_material(0).resource_name)
		var lo2 := Vector2(1e9, 1e9)
		var hi2 := Vector2(-1e9, -1e9)
		var cnt := 0
		for i in vs.size():
			if vs[i].x > 0.0:
				cnt += 1
				lo2 = lo2.min(uv[i])
				hi2 = hi2.max(uv[i])
		print("HALF x>0 n=", cnt, " uv ", lo2, hi2)
		for i in mini(vs.size(), 0):
			print("  v", vs[i], " uv", uv[i])
	quit()
