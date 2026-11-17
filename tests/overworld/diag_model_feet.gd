extends SceneTree
## D-1264 diagnostic: feet vs ground and clip stride for every playable species.
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/overworld/diag_model_feet.gd
## Prints, per model: clip list (duration, loop), rest AABB min y, and per clip the lowest
## bone height (relative to the model root) and the horizontal speed of the planted foot.

var LAB: GDScript
const IDS := ["abra", "pancham", "gible", "dqt_slime", "dqt_orc", "dqt_cyclops"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	LAB = load("res://scripts/debug/third_person_3d_lab.gd")
	var lab = LAB.new()
	for id in IDS:
		var model: Node3D = lab.call("_make_model", id, 1.0)
		root.add_child(model)
		await process_frame
		var ap: AnimationPlayer = lab.call("_find_anim_player", model)
		print("== %s ap=%s" % [id, ap != null])
		if ap == null:
			continue
		var clips := []
		for n in ap.get_animation_list():
			var a := ap.get_animation(n)
			clips.append("%s(%.2fs,loop=%d)" % [n, a.length, a.loop_mode])
		print("  clips: ", ", ".join(clips))
		var skel: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		var rest_min := _lowest(skel, model)
		print("  rest lowest bone y=%.3f" % rest_min)
		for n in ["idle", "walk", "run"]:
			if not ap.has_animation(n):
				continue
			var a := ap.get_animation(n)
			ap.play(n)
			var lo := 1e9
			var steps := 16
			var last_foot := Vector3.ZERO
			var foot_speed_sum := 0.0
			var foot_samples := 0
			for i in steps + 1:
				ap.seek(a.length * float(i) / steps, true)
				lo = minf(lo, _lowest(skel, model))
				var fp := _lowest_pos(skel, model)
				if i > 0 and absf(fp.y - rest_min) < 0.05 * 1.0:
					var d := Vector2(fp.x - last_foot.x, fp.z - last_foot.z).length()
					foot_speed_sum += d / (a.length / steps)
					foot_samples += 1
				last_foot = fp
			print("  %s lowest y over clip=%.3f (delta vs rest %.3f) planted-foot speed=%.2f m/s (%d samples)" % [
				n, lo, lo - rest_min, foot_speed_sum / maxf(1.0, foot_samples), foot_samples])
		model.queue_free()
	quit(0)


func _lowest(skel: Skeleton3D, model: Node3D) -> float:
	return _lowest_pos(skel, model).y


func _lowest_pos(skel: Skeleton3D, model: Node3D) -> Vector3:
	var best := Vector3(0, 1e9, 0)
	for b in skel.get_bone_count():
		var p: Vector3 = model.to_local(skel.global_transform * skel.get_bone_global_pose(b).origin)
		if p.y < best.y:
			best = p
	return best
