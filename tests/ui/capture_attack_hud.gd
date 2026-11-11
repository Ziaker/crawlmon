extends SceneTree
## Captura os 4 conceitos da HUD de ataque sem bloco.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --script res://tests/ui/capture_attack_hud.gd

const LAB := "res://scenes/debug/attack_hud_lab.tscn"
const OUT_DIR := "res://docs/referencias/ui/attack_hud_lab"
const FILES := ["A_mira", "B_selo", "C_glifo", "D_fita"]

var _lab: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(LAB) as PackedScene
	_lab = packed.instantiate()
	root.add_child(_lab)
	current_scene = _lab
	await _frames(45)
	for i in 4:
		_lab.call("set_preview_mode", i)
		_lab.call("set_preview_state", 0)
		await _frames(36)
		_save("%s.png" % FILES[i])
		_lab.call("press_preview")
		await _frames(4)
		_save("%s_press.png" % FILES[i])
		await _frames(40)
	# Estados nos dois conceitos mais opostos.
	_lab.call("set_preview_mode", 0)
	_lab.call("set_preview_state", 1)
	await _frames(20)
	_save("A_mira_recharging.png")
	_lab.call("set_preview_mode", 1)
	_lab.call("set_preview_state", 1)
	await _frames(20)
	_save("B_selo_recharging.png")
	# Outro alvo e o lado espelhado (D-235).
	_lab.call("set_preview_state", 0)
	_lab.call("set_preview_mode", 0)
	_lab.call("set_preview_target", 1)
	await _frames(36)
	_save("A_mira_gible.png")
	_lab.call("set_preview_mirror", true)
	await _frames(36)
	_save("A_mira_mirror_gible.png")
	_lab.call("set_preview_mode", 3)
	await _frames(36)
	_save("D_fita_mirror_gible.png")
	quit(0)


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var path := abs_dir.path_join(file_name)
	img.save_png(path)
	print("saved %s" % path)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
