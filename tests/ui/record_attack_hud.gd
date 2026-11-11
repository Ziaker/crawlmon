extends SceneTree
## Grava a demo dos 4 conceitos de HUD de ataque (sem áudio).
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 60 \
##     --write-movie docs/referencias/ui/attack_hud_lab/attack_hud_options.avi \
##     --script res://tests/ui/record_attack_hud.gd

const LAB := "res://scenes/debug/attack_hud_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(40)
	for i in 4:
		lab.call("set_preview_mode", i)
		lab.call("set_preview_state", 0)
		await _frames(60)
		lab.call("press_preview")
		await _frames(50)
	# Estados nos dois conceitos opostos.
	lab.call("set_preview_mode", 0)
	lab.call("set_preview_state", 1)
	await _frames(60)
	lab.call("set_preview_mode", 1)
	lab.call("set_preview_state", 1)
	await _frames(60)
	# Outro alvo e lado espelhado.
	lab.call("set_preview_state", 0)
	lab.call("set_preview_mode", 0)
	lab.call("set_preview_target", 1)
	await _frames(70)
	lab.call("set_preview_mirror", true)
	await _frames(70)
	lab.call("set_preview_mode", 3)
	await _frames(80)
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
