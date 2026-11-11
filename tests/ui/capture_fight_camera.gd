extends SceneTree
## Visual proof of the Fight QoL camera: high/wide TATICA while choosing a move,
## gliding at real speed during the decision slow-motion, then back to CINEMA.

const OUT := "res://test_captures/qol_camera"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 900:
		await process_frame
		guard += 1
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	await _wait(0.8)
	await _snap("01_main_cinema")

	bs._show_fight()
	await _wait(1.2)  # real seconds; the camera glide ignores the 0.2x slow-motion
	await _snap("02_fight_tactica_slowmo")
	await _wait(1.1)  # the 2 s decision slow-motion is now over
	await _snap("03_fight_tactica_clean")

	bs._on_cancel()
	await _wait(1.2)
	await _snap("04_main_cinema_back")

	print("QOL_CAMERA_CAPTURE_DONE")
	bs.queue_free()
	await process_frame
	quit(0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _snap(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(OUT + "/" + name + ".png")
		print("SNAP ", name)
