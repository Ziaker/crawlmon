extends SceneTree
## D-1270: leader + followers walk across the altar slopes (hub or forest scene); prints foot-height
## minus floor-height for each body and saves a game-camera shot. Windowed:
##   Godot.exe --path . --script res://tests/overworld/diag_altar_followers.gd -- --scene=hub|forest --shot=<png>
const SCENES := {"hub": "res://scenes/debug/hub_3d_prototype.tscn", "forest": "res://scenes/debug/murky_forest_3d_lab.tscn"}

func _arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % k):
			return a.substr(k.length() + 3)
	return d

func _floor_y(lab: Node, x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x + 0.0137, 3.0, z + 0.0091), Vector3(x + 0.0137, -1.0, z + 0.0091), 1)
	var hit: Dictionary = (lab as Node3D).get_world_3d().direct_space_state.intersect_ray(q)
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else -99.0

func _key(code: int, down: bool) -> void:
	var k := InputEventKey.new()
	k.keycode = code
	k.physical_keycode = code
	k.pressed = down
	Input.parse_input_event(k)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var which := _arg("scene", "hub")
	var lab: Node = (load(SCENES[which]) as PackedScene).instantiate()
	root.add_child(lab)
	for i in 10: await physics_frame
	if lab.get("_arrival") != null:
		lab.set("_arrival", null)  # skip the arrival cutscene (forest)
	var player: CharacterBody3D = lab.get("player")
	var followers: Array = lab.get("_followers")
	for f in followers:
		(f["node"] as Node3D).visible = true
	var altar_z := 1.0 if which == "hub" else 0.0
	var start := Vector3(0.0, 0.0, altar_z + 6.0)
	var goal := Vector3(0.0, 0.0, altar_z - 5.0)
	player.global_position = start
	for f in followers:
		(f["node"] as Node3D).global_position = start + Vector3(0.0, 0.0, 1.2)
	var rec := {}
	var frames := 0
	var mid_shot := false
	var frames_left := 0
	while frames < 600:
		var dir := (goal - player.global_position)
		dir.y = 0.0
		if dir.length() < 0.4:
			break
		var fwd: Vector3 = lab.call("_camera_ground_forward")
		var right := fwd.cross(Vector3.UP).normalized()
		var d := dir.normalized()
		_key(KEY_UP, d.dot(fwd) > 0.35)
		_key(KEY_DOWN, d.dot(fwd) < -0.35)
		_key(KEY_RIGHT, d.dot(right) > 0.35)
		_key(KEY_LEFT, d.dot(right) < -0.35)
		await physics_frame
		frames += 1
		var bodies: Array = [{"n": "leader", "b": player, "m": lab.get("player_model")}]
		for f in followers:
			bodies.append({"n": str(f.get("model_id", "ally")), "b": f["node"], "m": f["model"]})
		for e in bodies:
			var b := e["b"] as Node3D
			var p := b.global_position
			if Vector2(p.x, p.z - altar_z).length() > 2.6:
				continue
			var m := e["m"] as Node3D
			var fy := _floor_y(lab, p.x, p.z)
			if fy < -50.0:
				print("FOLLOW_MISS %s at %s y=%.3f" % [e["n"], str(p), p.y])
				continue
			var gap := p.y + (m.position.y if m != null else 0.0) - fy
			var r: Dictionary = rec.get(e["n"], {"min": 99.0, "max": -99.0})
			r["min"] = minf(r["min"], gap)
			r["max"] = maxf(r["max"], gap)
			rec[e["n"]] = r
		if not mid_shot and Vector2(player.global_position.x, player.global_position.z - altar_z).length() < 1.9:
			mid_shot = true
			for i in 6: await physics_frame
			var img := root.get_viewport().get_texture().get_image()
			var sp := _arg("shot", "")
			if sp != "":
				img.save_png(sp)
	print("FOLLOW_DBG player=%s arrival=%s followers=%d" % [str(player.global_position), str(lab.get("_arrival")), followers.size()])
	for n in rec:
		print("FOLLOW_RAMP scene=%s body=%s gap_min=%.3f gap_max=%.3f" % [which, n, rec[n]["min"], rec[n]["max"]])
	print("FOLLOW_RAMP scene=%s frames=%d reached=%s bodies=%d" % [which, frames, str(Vector2(player.global_position.x - goal.x, player.global_position.z - goal.z).length() < 0.6), rec.size()])
	quit(0)
