extends SceneTree

const SCENE_PATH := "res://scenes/debug/murky_forest_3d_lab.tscn"
const DIVIDER_X := 13.5
const GAP_Z_MIN := -1.5
const GAP_Z_MAX := 1.5


func _initialize() -> void:
	var summary_only := _has_summary_flag()

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_emit(summary_only, _result(0.0, 0, 0))
		return

	var inst: Node = packed.instantiate()
	root.add_child(inst)
	await process_frame
	# NavigationServer3D sincroniza a malha de navegacao no passo fisico.
	for _i in range(3):
		await physics_frame

	var regions: Array = inst.find_children("*", "NavigationRegion3D", true, false)
	if regions.is_empty():
		inst.queue_free()
		_emit(summary_only, _result(0.0, 0, 0))
		return

	var region := regions[0] as NavigationRegion3D
	var map := region.get_navigation_map()

	var points: Array = [
		Vector3(0.0, 0.05, -4.0),   # entrada
		Vector3(11.0, 0.05, -10.0), # corredor
		Vector3(8.0, 0.05, 0.0),    # dossel
		Vector3(16.0, 0.05, 0.0),   # nicho
	]

	var path_min := INF
	var found_any := false
	var stack_pairs := 0
	var wall_hits := 0

	for i in range(1, points.size()):
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		var path: PackedVector3Array = NavigationServer3D.map_get_path(map, a, b, true)
		if path.size() < 2:
			stack_pairs += 1
			continue
		found_any = true
		path_min = minf(path_min, _path_length(path))
		if _crosses_divider(path):
			wall_hits += 1

	if not found_any:
		path_min = 0.0

	inst.queue_free()
	_emit(summary_only, _result(path_min, stack_pairs, wall_hits))


func _has_summary_flag() -> bool:
	for arg in OS.get_cmdline_args():
		if String(arg).begins_with("--summary-json"):
			return true
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--summary-json"):
			return true
	return false


func _result(path_min: float, stack_pairs: int, wall_hits: int) -> Dictionary:
	return {
		"path_min": path_min,
		"stack_pairs": stack_pairs,
		"wall_hits": wall_hits,
		# Modo headless: nenhuma camera ativa na cena, portanto 0 por definicao.
		"cam_inside": 0,
		"ok": stack_pairs == 0 and wall_hits == 0,
	}


func _path_length(path: PackedVector3Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
	return total


func _crosses_divider(path: PackedVector3Array) -> bool:
	for i in range(1, path.size()):
		var p := path[i - 1]
		var q := path[i]
		var crossing := (p.x < DIVIDER_X and q.x > DIVIDER_X) or (p.x > DIVIDER_X and q.x < DIVIDER_X)
		if not crossing:
			continue
		var t := (DIVIDER_X - p.x) / (q.x - p.x)
		var z := p.z + (q.z - p.z) * t
		if z < GAP_Z_MIN or z > GAP_Z_MAX:
			return true
	return false


func _emit(summary_only: bool, data: Dictionary) -> void:
	var ok := bool(data.get("ok", false))
	print("AUDIT_JSON: " + JSON.stringify(data))
	if not summary_only:
		print("PASS" if ok else "FAIL")
	quit(0 if ok else 1)
