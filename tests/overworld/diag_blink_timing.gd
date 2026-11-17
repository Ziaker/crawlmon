extends SceneTree
## EyeBlink runs by itself: samples `closed` for 8 s of process frames (expect >=1 full blink).
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var lab = load("res://scripts/debug/third_person_3d_lab.gd").new()
	var m: Node3D = lab.call("_make_model", "pikachu", 1.0)
	root.add_child(m)
	var bl = m.find_child("EyeBlink", true, false)
	var peak := 0.0; var blinks := 0; var was := false
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 8000:
		await process_frame
		var cv = bl._mats[0].get_shader_parameter("closed"); var c: float = 0.0 if cv == null else float(cv)
		peak = maxf(peak, c)
		var closed_now := c > 0.9
		if closed_now and not was: blinks += 1
		was = closed_now
	print("BLINKTIMING peak=", peak, " blinks_in_8s=", blinks)
	quit(0)
