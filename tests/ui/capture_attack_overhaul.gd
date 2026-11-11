extends SceneTree
## Captura os 3 overhauls: wind-up, impacto e recuperação.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/ui/capture_attack_overhaul.gd

const LAB := "res://scenes/debug/attack_overhaul_lab.tscn"
const OUT := "res://docs/referencias/ui/attack_overhaul"
const FILES := ["snap", "duelist", "comic"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(50)
	for i in 3:
		lab.call("_select_profile", i)
		await _frames(15)
		lab.call("_start_attack")
		await _frames(2)
		_save("%s_windup.png" % FILES[i])
		var guard := 0
		while int(lab.get("_phase")) != 3 and guard < 90:
			await process_frame
			guard += 1
		_save("%s_impact.png" % FILES[i])
		var guard2 := 0
		while int(lab.get("_phase")) == 3 and guard2 < 30:
			await process_frame
			guard2 += 1
		await _frames(4)
		_save("%s_recover.png" % FILES[i])
		await _frames(100)
	quit(0)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved %s" % file_name)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
