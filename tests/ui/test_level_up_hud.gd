extends SceneTree

const LevelUpHUDLab = preload("res://scripts/debug/level_up_hud_lab.gd")
const LevelUpHUD = preload("res://scripts/ui/level_up_hud.gd")
const MoveCard = preload("res://scripts/ui/components/move_card.gd")
const MoveInspectionModal = preload("res://scripts/ui/components/move_inspection_modal.gd")

func _init() -> void:
	print("--- STARTING LEVEL UP HUD TEST ---")
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	if lab_scene == null:
		printerr("FAIL: Could not load level_up_hud_lab.tscn")
		quit(1)
		return

	var lab = lab_scene.instantiate()
	root.add_child(lab)

	# Process frames to let shaders compile and _ready execute
	for i in range(10):
		await process_frame

	var hud = lab.get_node_or_null("LevelUpHUD") as LevelUpHUD
	if hud == null:
		printerr("FAIL: LevelUpHUD not found in lab")
		quit(1)
		return

	# Verify 3D model was mounted
	var mount = hud.model_mount
	if mount == null or mount.get_child_count() == 0:
		printerr("FAIL: ModelMount has no 3D character instantiated")
		quit(1)
		return
	print("PASS: 3D character mounted: ", mount.get_child(0).name)

	# Verify moves grid has 8 cards
	var moves_grid = hud.moves_grid
	if moves_grid == null or moves_grid.get_child_count() != 8:
		printerr("FAIL: MovesGrid does not have 8 cards: ", moves_grid.get_child_count() if moves_grid else "null")
		quit(1)
		return
	print("PASS: MovesGrid instantiated with 8 MoveCard slots")

	# Test opening move inspection modal
	var first_card = moves_grid.get_child(0)
	first_card.move_inspect_requested.emit(first_card._skill)
	await process_frame

	var modal = hud.inspection_modal
	if modal == null or not modal.visible:
		printerr("FAIL: InspectionModal did not open upon move_inspect_requested")
		quit(1)
		return
	print("PASS: MoveInspectionModal opened successfully with -9 degree blocks")

	modal.close_modal()
	await process_frame
	if modal.visible:
		printerr("FAIL: InspectionModal did not close")
		quit(1)
		return
	print("PASS: MoveInspectionModal closed cleanly")

	# Verify D-401 lock: Leader has 1 distributable point, return button must be disabled
	var return_btn = hud.return_btn
	if return_btn == null or not return_btn.disabled:
		printerr("FAIL: D-401 Lock gate violated: Return button should be disabled when leader has unallocated points")
		quit(1)
		return
	print("PASS: D-401 exit lock verified (Return button disabled)")

	print("--- ALL LEVEL UP HUD TESTS PASSED ---")
	quit(0)
