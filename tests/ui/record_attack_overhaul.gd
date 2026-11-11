extends SceneTree
## Grava os 3 overhauls em sequência (real-time, 60 fps).
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 60 \
##     --write-movie docs/referencias/ui/attack_overhaul/attack_overhaul.avi \
##     --script res://tests/ui/record_attack_overhaul.gd

const LAB := "res://scenes/debug/attack_overhaul_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(50)
	for i in 3:
		lab.call("_select_profile", i)
		await _frames(40)
		lab.call("_start_attack")
		var guard := 0
		while int(lab.get("_phase")) != 0 and guard < 180:
			await process_frame
			guard += 1
		await _frames(30)
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
