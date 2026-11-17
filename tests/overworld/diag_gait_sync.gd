extends SceneTree
## D-1264: walks every species as hub leader (and as follower via the lab) and prints
## foot height vs floor, body speed, clip, playback scale and planted-foot world speed
## (0 = no skating). Headless, ~10 s:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/overworld/diag_gait_sync.gd
const IDS := ["abra", "pancham", "gible", "dqt_slime", "dqt_orc", "dqt_cyclops", "charmander", "bulbasaur", "squirtle", "pikachu", "eevee", "dqt_platypunk", "dqt_sabrecub"]
const HUB := "res://scenes/debug/hub_3d_prototype.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ids: Array = IDS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="):
			ids = a.substr(6).split(",")
	for id in ids:
		var lab: Node = (load(HUB) as PackedScene).instantiate()
		root.add_child(lab)
		for i in 6: await physics_frame
		lab.call("_set_player_species", id)
		await physics_frame
		var player: CharacterBody3D = lab.get("player")
		var model: Node3D = lab.get("player_model")
		var ap: AnimationPlayer = lab.get("player_ap")
		player.global_position = Vector3(0, 0.0, 5.5)
		lab.set("_auto_nav_target", Vector3(0, 0, -3.0))
		var gait: Dictionary = load("res://scripts/overworld/model_gait.gd").analyze(model, ap, float(model.get_meta("model_height")), id)
		var skel: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		var feet: PackedInt32Array = load("res://scripts/overworld/model_gait.gd").foot_bones(skel, model, float(model.get_meta("model_height")))
		var speeds := []
		var slip := 0.0
		var slip_n := 0
		var prev := {}
		var min_floor_gap := 1e9
		var body_below_floor := -1e9
		var G = load("res://scripts/overworld/model_gait.gd")
		var low_verts: Array = G._collect_low_vertices(skel, model, float(model.get_meta("model_height")))
		var worst_pen := 1e9   # min(sole world y - floor y): negative = mesh inside the floor
		var worst_at := Vector3.ZERO
		var clip := ""
		var scale := 1.0
		for f in 70:
			await physics_frame
			if f < 15:
				prev.clear()
				continue
			clip = ap.current_animation
			scale = ap.speed_scale
			var hv := Vector2(player.velocity.x, player.velocity.z).length()
			speeds.append(hv)
			var q := PhysicsRayQueryParameters3D.create(player.global_position + Vector3(0, 1.5, 0), player.global_position + Vector3(0, -2.0, 0), 1)
			var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
			if not hit.is_empty():
				var sole_w: float = model.global_position.y + G._sole_y(skel, model, low_verts)
				var pen := sole_w - float(hit["position"].y)
				if pen < worst_pen:
					worst_pen = pen
					worst_at = player.global_position
				body_below_floor = maxf(body_below_floor, float(hit["position"].y) - player.global_position.y)
			var lowest := 1e9
			var lowest_b := -1
			var poss := {}
			for b in feet:
				var p: Vector3 = skel.global_transform * skel.get_bone_global_pose(b).origin
				poss[b] = p
				if p.y < lowest:
					lowest = p.y
					lowest_b = b
			min_floor_gap = minf(min_floor_gap, lowest - player.global_position.y)
			if prev.has(lowest_b) and lowest - player.global_position.y < 0.06 * float(model.get_meta("model_height")) + float(0.02):
				var d: Vector3 = (poss[lowest_b] as Vector3) - (prev[lowest_b] as Vector3)
				slip += Vector2(d.x, d.z).length() * Engine.physics_ticks_per_second
				slip_n += 1
			prev = poss
		var avg := 0.0
		for s in speeds: avg += s
		avg /= maxf(1.0, speeds.size())
		var gs := 0.0
		if gait.has(clip):
			gs = float(gait[clip]["ground_speed"])
		print("GAIT %s body_speed=%.2f clip=%s scale=%.2f clip_ground_speed=%.2f expected_foot_speed=%.2f planted_foot_world_speed=%.2f foot_min_gap_to_floor=%.3f body_below_floor=%.3f mesh_vs_floor_min=%.3f at=%s" % [
			id, avg, clip, scale, gs, gs * scale, slip / maxf(1.0, slip_n), min_floor_gap, body_below_floor, worst_pen, worst_at])
		var sink_run: float = float(gait.get("run", {}).get("sink", 0.0))
		print("GAIT %s sink(clip run)=%.3f sink(walk)=%.3f" % [id, sink_run, float(gait.get("walk", {}).get("sink", 0.0))])
		if DisplayServer.get_name() != "headless":
			var img := lab.get_viewport().get_texture().get_image()
			img.save_png(ProjectSettings.globalize_path("res://tests/battle/_shots/walk_%s.png" % id))
		lab.queue_free()
		await process_frame
	quit(0)
