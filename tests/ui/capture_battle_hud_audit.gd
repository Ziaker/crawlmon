extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("test_captures")
	root.size = Vector2i(1280, 720)

	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)

	var battle: Node = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 900:
		await process_frame
		guard += 1

	# Hold actions so battle state remains stable for capture
	for c in battle.party + battle.enemies:
		c.act_policy = 0 # HOLD
		c.react_policy = 0 # NONE

	for i in 10:
		await process_frame

	# 1. Capture Idle Battle with Main Menu & Cards
	var img1 := root.get_texture().get_image()
	img1.save_png("test_captures/audit_01_battle_idle.png")
	print("[AUDIT CAPTURE] audit_01_battle_idle.png saved!")

	# 2. Open Fight Menu
	bs._show_fight()
	for i in 10:
		await process_frame

	var img2 := root.get_texture().get_image()
	img2.save_png("test_captures/audit_02_fight_open_tackle.png")
	print("[AUDIT CAPTURE] audit_02_fight_open_tackle.png saved!")

	# 3. Select 2nd Move (Confusion)
	var menu = bs._menu
	if menu != null:
		menu.index = 1
		bs._on_moved(1)
	for i in 6:
		await process_frame

	var img3 := root.get_texture().get_image()
	img3.save_png("test_captures/audit_03_fight_open_confusion.png")
	print("[AUDIT CAPTURE] audit_03_fight_open_confusion.png saved!")

	# 4. Select 3rd Move (Psybeam or another move)
	if menu != null:
		menu.index = 2
		bs._on_moved(2)
	for i in 6:
		await process_frame

	var img4 := root.get_texture().get_image()
	img4.save_png("test_captures/audit_04_fight_open_psybeam.png")
	print("[AUDIT CAPTURE] audit_04_fight_open_psybeam.png saved!")

	print("=== ALL AUDIT CAPTURES SUCCESSFUL ===")
	quit(0)
