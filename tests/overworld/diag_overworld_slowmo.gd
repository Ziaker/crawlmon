extends SceneTree
## Windowed diagnostic for the overworld impact slow motion (D-1100/D-1129).
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 \
##       --script res://tests/overworld/diag_overworld_slowmo.gd
##
## Headless runs skip `_slow_motion()` on purpose, so this check must run with a
## window. It triggers the real `_on_attack_impact` call site and samples the
## global clock, proving the scale and the real-time duration.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 8:
		await process_frame
	Engine.time_scale = 1.0
	var player: Node3D = lab.get("player")
	var start := Time.get_ticks_msec()
	lab.call("_on_attack_impact", player.global_position, Vector3.FORWARD, 1, [])
	var min_scale := 1.0
	var last_below_one := 0
	while Time.get_ticks_msec() - start < 1500:
		min_scale = minf(min_scale, Engine.time_scale)
		if Engine.time_scale < 0.999:
			last_below_one = Time.get_ticks_msec() - start
		await process_frame
	print("SLOWMO min=%.4f last_below_1_ms=%d restored=%.2f" % [
		min_scale, last_below_one, Engine.time_scale])
	Engine.time_scale = 1.0
	quit(0)
