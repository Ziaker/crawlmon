extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs = packed.instantiate()
	root.add_child(bs)

	var battle: Node = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 900:
		await process_frame
		guard += 1

	for c in battle.party + battle.enemies:
		c.act_policy = 0
		c.react_policy = 0

	# Set leader MP to 1! Tackle (0 MP) is affordable, Confusion (3 MP) and Psybeam (5 MP) are dimmed and disabled!
	bs.leader.mp = 1

	# Open Fight drawer and move selection to Confusion
	bs._show_fight()
	bs._fill_fight(false)
	bs._menu.select(1)
	bs._update_fight_header(1)

	for i in 15:
		await process_frame

	var img := root.get_texture().get_image()
	img.save_png("test_captures/audit_05_fight_low_mp_dimmed.png")
	print("[AUDIT CAPTURE] audit_05_fight_low_mp_dimmed.png saved!")
	quit(0)
