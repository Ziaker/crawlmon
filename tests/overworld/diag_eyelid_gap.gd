extends SceneTree
## Eyelid gap (distance upper-lid chain centroid <-> lower-lid chain centroid, left eye) per clip/time, vs idle.
func _init() -> void:
	call_deferred("_run")
func _centroid(sk: Skeleton3D, side: String, part: String) -> Vector3:
	var c := Vector3.ZERO; var n := 0
	for b in sk.get_bone_count():
		var nm := sk.get_bone_name(b)
		if nm.begins_with(side + "_" + part + "_eyelid"):
			c += sk.get_bone_global_pose(b).origin; n += 1
	return c / maxf(n, 1)
func _run() -> void:
	var ids := ["pikachu", "eevee", "charmander"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
	for id in ids:
		var glb := (load("res://assets/modelos/%s/%s.glb" % [id, id]) as PackedScene).instantiate()
		root.add_child(glb)
		var ap: AnimationPlayer = glb.find_children("*", "AnimationPlayer", true, false)[0]
		var sk: Skeleton3D = glb.find_children("*", "Skeleton3D", true, false)[0]
		ap.play("idle"); ap.seek(0.0, true); ap.pause()
		await process_frame
		var g0 := (_centroid(sk, "left", "upper") - _centroid(sk, "left", "lower")).length()
		print("GAP ", id, " idle gap=%.5f" % g0)
		for clip in ["damage", "down", "attack", "victory"]:
			var len := ap.get_animation(clip).length
			var mn := 9.0; var tmn := 0.0
			for k in 25:
				ap.play(clip); ap.seek(len * k / 24.0, true); ap.pause()
				await process_frame
				var g := (_centroid(sk, "left", "upper") - _centroid(sk, "left", "lower")).length()
				if g < mn: mn = g; tmn = len * k / 24.0
			print("GAP ", id, " ", clip, " min_gap_ratio=%.2f at t=%.2f" % [mn / g0, tmn])
		glb.queue_free()
	quit(0)
