extends SceneTree
## D-1134: grava a demo das 4 direções da badge (sem áudio).
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##     --position -4000,0 --fixed-fps 60 \
##     --write-movie docs/referencias/ui/attack_badge_lab/attack_badge_options.avi \
##     --script res://tests/ui/record_attack_badges.gd

const LAB := "res://scenes/debug/attack_badge_lab.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(LAB) as PackedScene
	var lab := packed.instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(40)
	for i in 4:
		lab.call("set_preview_style", i)
		lab.call("set_preview_state", 0)
		await _frames(45)
		lab.call("press_preview")
		await _frames(45)
	# Estados na SMT e na ATTACK CARD.
	lab.call("set_preview_style", 2)
	lab.call("set_preview_state", 1)
	await _frames(60)
	lab.call("set_preview_state", 2)
	await _frames(60)
	lab.call("set_preview_style", 0)
	lab.call("set_preview_state", 0)
	await _frames(50)
	# D-235: outro alvo e o lado espelhado.
	lab.call("set_preview_style", 2)
	lab.call("set_preview_target", 1)
	await _frames(60)
	lab.call("set_preview_mirror", true)
	await _frames(60)
	lab.call("set_preview_style", 3)
	await _frames(70)
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
