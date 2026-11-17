extends SceneTree

const SCENE_PATH := "res://scenes/debug/murky_forest_3d_lab.tscn"

var _points := [
	{"name": "entry", "pos": Vector3(0.0, 0.05, -4.0)},
	{"name": "corridor_arch", "pos": Vector3(11.0, 0.05, -10.0)},
	{"name": "canopy", "pos": Vector3(8.0, 0.05, 0.0)},
	{"name": "niche", "pos": Vector3(16.0, 0.05, 0.0)},
]

func _initialize() -> void:
	var summary_only := _wants_summary_json()
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_emit(_empty_report(), summary_only)
		quit(1)
		return
	var inst := packed.instantiate()
	root.add_child(inst)
	await process_frame

	var regions := inst.find_children("*", "NavigationRegion3D", true, false)
	if regions.is_empty():
		_emit(_empty_report(), summary_only)
		quit(1)
		return

	var region := regions[0] as NavigationRegion3D
	var nav_mesh: NavigationMesh = region.navigation_mesh
	if nav_mesh == null:
		_emit(_empty_report(), summary_only)
		quit(1)
		return

	var verts := nav_mesh.get_vertices()
	var poly_count := nav_mesh.get_polygon_count()
	var polys: Array[PackedInt32Array] = []
	for i in poly_count:
		polys.append(nav_mesh.get_polygon(i))

	var adj: Array[Array] = []
	for i in poly_count:
		adj.append([])
	for i in poly_count:
		for j in range(i + 1, poly_count):
			if _shared_vertices(polys[i], polys[j]) >= 2:
				adj[i].append(j)
				adj[j].append(i)

	var entry_pos: Vector3 = _points[0]["pos"]
	var start := _containing_polygons(polys, verts, Vector2(entry_pos.x, entry_pos.z))
	var reached := {}
	var queue: Array[int] = []
	for p in start:
		if not reached.has(p):
			reached[p] = true
			queue.append(p)
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for nb in adj[cur]:
			if not reached.has(nb):
				reached[nb] = true
				queue.append(nb)

	var reachable: Array[String] = []
	var unreachable: Array[String] = []
	for pt in _points:
		var pos: Vector3 = pt["pos"]
		var contained := _containing_polygons(polys, verts, Vector2(pos.x, pos.z))
		var found := false
		for p in contained:
			if reached.has(p):
				found = true
				break
		if found:
			reachable.append(String(pt["name"]))
		else:
			unreachable.append(String(pt["name"]))

	var all_ok := unreachable.is_empty()
	_emit({
		"reachable": reachable,
		"unreachable": unreachable,
		"polygons": poly_count,
		"vertices": verts.size(),
		"ok": all_ok,
	}, summary_only)
	inst.queue_free()
	quit(0 if all_ok else 1)

func _empty_report() -> Dictionary:
	return {"reachable": [], "unreachable": [], "polygons": 0, "vertices": 0, "ok": false}

func _wants_summary_json() -> bool:
	for a in OS.get_cmdline_args():
		if a == "--summary-json":
			return true
	for a in OS.get_cmdline_user_args():
		if a == "--summary-json":
			return true
	return false

func _emit(data: Dictionary, summary_only: bool) -> void:
	print("GRAPH_JSON: ", JSON.stringify(data))
	if not summary_only:
		print("PASS" if data.get("ok", false) else "FAIL")

func _shared_vertices(a: PackedInt32Array, b: PackedInt32Array) -> int:
	var present := {}
	for v in b:
		present[v] = true
	var count := 0
	for v in a:
		if present.has(v):
			count += 1
	return count

func _containing_polygons(polys: Array[PackedInt32Array], verts: PackedVector3Array, p: Vector2) -> Array[int]:
	var out: Array[int] = []
	for i in polys.size():
		var poly := polys[i]
		var min_x := INF
		var max_x := -INF
		var min_z := INF
		var max_z := -INF
		for vi in poly:
			var v := verts[vi]
			min_x = minf(min_x, v.x)
			max_x = maxf(max_x, v.x)
			min_z = minf(min_z, v.z)
			max_z = maxf(max_z, v.z)
		if p.x >= min_x and p.x <= max_x and p.y >= min_z and p.y <= max_z:
			out.append(i)
	return out
