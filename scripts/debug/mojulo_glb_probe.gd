extends SceneTree

# Probe headless de um GLB: carrega em runtime (sem importar no projeto) e
# imprime um resumo em JSON. Uso:
#   godot --headless --path <root> --script res://scripts/debug/mojulo_glb_probe.gd -- <glb_absoluto>

func _init() -> void:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if user_args.is_empty():
		printerr("MOJULO_PROBE ERROR: caminho do GLB nao informado")
		quit(1)
		return
	var abs_path: String = user_args[0]
	if not FileAccess.file_exists(abs_path):
		printerr("MOJULO_PROBE ERROR: arquivo nao encontrado: " + abs_path)
		quit(1)
		return

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: Error = doc.append_from_file(abs_path, state)
	if err != OK:
		printerr("MOJULO_PROBE ERROR: append_from_file falhou (erro %d)" % err)
		quit(1)
		return
	var scene: Node = doc.generate_scene(state)
	if scene == null:
		printerr("MOJULO_PROBE ERROR: generate_scene retornou null")
		quit(1)
		return

	# Entra na arvore para que os global transforms fiquem validos.
	root.add_child(scene)

	var nodes: Array[Node] = []
	_walk(scene, nodes)

	var stats := {
		"load_ok": true,
		"node_count": nodes.size(),
		"mesh_instance_count": 0,
		"surface_count": 0,
		"triangle_count": 0,
		"vertex_count": 0,
		"unique_material_count": 0,
		"standard_material_count": 0,
		"shader_material_count": 0,
		"unshaded_count": 0,
		"vertex_color_albedo_count": 0,
		"has_collision": false,
		"camera_count": 0,
		"light_count": 0,
	}

	var materials := {}
	var has_aabb := false
	var overall := AABB()

	for node in nodes:
		if node is Camera3D:
			stats["camera_count"] += 1
		if node is Light3D:
			stats["light_count"] += 1
		if node is CollisionShape3D or node is CollisionObject3D:
			stats["has_collision"] = true
		if not (node is MeshInstance3D):
			continue

		var mi := node as MeshInstance3D
		stats["mesh_instance_count"] += 1
		if mi.material_override != null:
			materials[mi.material_override.get_instance_id()] = mi.material_override

		var mesh: Mesh = mi.mesh
		if mesh != null:
			var surfaces: int = mesh.get_surface_count()
			stats["surface_count"] += surfaces
			for i in range(surfaces):
				var index_len := 0
				if mesh is ArrayMesh:
					index_len = (mesh as ArrayMesh).surface_get_array_index_len(i)
				var array_len: int = mesh.surface_get_array_len(i)
				if index_len > 0:
					stats["triangle_count"] += int(index_len / 3.0)
				else:
					stats["triangle_count"] += int(array_len / 3.0)
				stats["vertex_count"] += array_len

				var mat: Material = mi.get_surface_override_material(i)
				if mat == null:
					mat = mesh.surface_get_material(i)
				if mat != null:
					materials[mat.get_instance_id()] = mat

		var box: AABB = mi.global_transform * mi.get_aabb()
		if has_aabb:
			overall = overall.merge(box)
		else:
			overall = box
			has_aabb = true

	for id in materials.keys():
		var mat: Material = materials[id]
		if mat is StandardMaterial3D:
			var std := mat as StandardMaterial3D
			stats["standard_material_count"] += 1
			if std.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				stats["unshaded_count"] += 1
			if std.vertex_color_use_as_albedo:
				stats["vertex_color_albedo_count"] += 1
		elif mat is ShaderMaterial:
			stats["shader_material_count"] += 1

	stats["unique_material_count"] = materials.size()

	var size := Vector3.ZERO
	if has_aabb:
		size = overall.size
	stats["aabb_size"] = {"x": size.x, "y": size.y, "z": size.z}
	stats["largest_horizontal_extent_m"] = maxf(size.x, size.z)

	print("MOJULO_PROBE " + JSON.stringify(stats))

	root.remove_child(scene)
	scene.free()
	quit(0)


func _walk(node: Node, out: Array[Node]) -> void:
	out.append(node)
	for child in node.get_children():
		_walk(child, out)
