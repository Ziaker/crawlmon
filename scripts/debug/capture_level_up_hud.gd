extends SceneTree

func _init() -> void:
	print("--- CAPTURING LEVEL UP HUD SCREENSHOTS ---")
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	if lab_scene == null:
		printerr("FAIL: Could not load level_up_hud_lab.tscn")
		quit(1)
		return

	var lab = lab_scene.instantiate()
	root.add_child(lab)

	# Wait frames for rendering and layout
	for i in range(15):
		await process_frame

	# Capture main screen
	var img = root.get_texture().get_image()
	img.save_png("res://level_up_hud_main_capture.png")
	print("SAVED: level_up_hud_main_capture.png")

	# Open inspection modal on card 2 (Psybeam)
	var hud = lab.get_node("LevelUpHUD")
	var moves_grid = hud.moves_grid
	var card = moves_grid.get_child(2) # Psybeam
	card.move_inspect_requested.emit(card._skill)

	for i in range(10):
		await process_frame

	print("MODAL FORMULA: ", hud.inspection_modal.formula_label.text)
	print("MODAL RESULT: ", hud.inspection_modal.formula_result_badge.text)
	print("MODAL SYNERGY: ", hud.inspection_modal.synergy_label.text)

	var img_modal = root.get_texture().get_image()
	img_modal.save_png("res://level_up_hud_modal_capture.png")
	print("SAVED: level_up_hud_modal_capture.png")

	quit(0)
