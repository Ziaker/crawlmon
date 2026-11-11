extends SceneTree
## Automated headless test suite for LevelUpHUD & Universal Move Cards (D-401, D-420, D-433, D-416).

const Combatant = preload("res://scripts/combat/combatant.gd")
const Skill = preload("res://scripts/data/skill.gd")
const Element = preload("res://scripts/data/element.gd")


func _init() -> void:
	print("[TEST] Starting suite: test_level_up_hud.gd")
	call_deferred("_run_tests")


func _run_tests() -> void:
	var hud_scene: PackedScene = load("res://scenes/ui/level_up_hud.tscn")
	if hud_scene == null:
		push_error("FAILED to load res://scenes/ui/level_up_hud.tscn")
		quit(1)
		return

	var hud = hud_scene.instantiate()
	root.add_child(hud)

	# Build mock party
	var leader = Combatant.new("Abra", 37, 4, 1.2, true, 8)
	leader.species_id = "Abra"
	leader.level = 2
	leader.innate_stats = {"STR": 1, "MAG": 7, "VIT": 1, "WIS": 4, "AGI": 1, "LUK": 1}
	leader.distributable_points = 1
	leader.sync_effective_stats()
	leader.update_resource_maximums()

	# Equip a skill on leader
	var psybeam = Skill.new("Psybeam", 1.2, 2, Element.Type.PSIQUICO, Skill.Kind.CAST, false, false, false, 1.4, false, 6)
	leader.skills.append(psybeam)

	var party_summaries: Array[Dictionary] = [
		{
			"combatant": leader,
			"old_xp": 0,
			"current_xp": 50,
			"levels_gained": 1,
			"points_gained": 1
		}
	]

	print("  -> Initializing LevelUpHUD...")
	hud.open(party_summaries, 50)

	# Test 1 & 2: D-401 exit lock
	print("  -> Testing D-401 Exit Lock enforcement...")
	var return_btn = hud.get_node("MainVBox/FooterBar/Margin/HBox/ReturnBtn") as Button
	var lock_notice = hud.get_node("MainVBox/ContentArea/LeftCol/AdvanceLockNotice") as Control
	if not return_btn.disabled:
		push_error("D-401 VIOLATION: ReturnBtn should be disabled when Leader has unallocated points!")
		quit(1)
		return
	if not lock_notice.visible:
		push_error("D-401 VIOLATION: AdvanceLockNotice should be visible when Leader has unallocated points!")
		quit(1)
		return
	print("  [PASS] Exit lock is active.")

	# Test 3: Increment MAG
	print("  -> Testing Stat Allocation Stepper...")
	var plus_btn = hud.get_node("MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox/MAG/PlusBtn") as Button
	plus_btn.pressed.emit()

	if return_btn.disabled:
		push_error("ReturnBtn should become enabled once all pending points are allocated in session!")
		quit(1)
		return
	print("  [PASS] Stepper allocation enabled ReturnBtn.")

	# Test 4: Confirm allocation
	print("  -> Testing Allocation Confirmation & Resource Sync...")
	var confirm_btn = hud.get_node("MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/LeaderControls/ConfirmAllocBtn") as Button
	var old_max_mp = leader.max_mp
	confirm_btn.pressed.emit()

	if leader.progression_points.get("MAG", 0) != 1:
		push_error("MAG was not committed to leader.progression_points!")
		quit(1)
		return
	if leader.distributable_points != 0:
		push_error("distributable_points should be 0 after allocation!")
		quit(1)
		return
	print("  [PASS] Allocation committed and distributable points decremented.")

	# Test 5 & 6: Move Inspection Modal & Focus Trap
	print("  -> Testing MoveCard click and Inspection Modal open/close...")
	var moves_grid = hud.get_node("MainVBox/ContentArea/RightCol/Margin/VBox/MovesGrid") as GridContainer
	if moves_grid.get_child_count() == 0:
		push_error("MovesGrid has no MoveCard instances instantiated!")
		quit(1)
		return

	var first_card = moves_grid.get_child(0) as MoveCard
	first_card.move_inspect_requested.emit(psybeam)

	var modal = hud.get_node("InspectionModal") as MoveInspectionModal
	if not modal.visible:
		push_error("InspectionModal should be visible after inspect request!")
		quit(1)
		return

	var modal_close = modal.get_node("CenterContainer/ModalCard/Margin/VBox/TopBar/CloseBtn") as Button
	if not modal_close.has_focus():
		push_error("Focus Trap Failure: CloseBtn should have focus upon opening modal!")
		quit(1)
		return
	print("  [PASS] Modal opened with proper focus trap.")

	# Close modal
	modal.close_modal()
	if modal.visible:
		push_error("InspectionModal should be hidden after close_modal()!")
		quit(1)
		return
	print("  [PASS] Modal closed successfully.")

	print("[TEST SUCCESS] All 6 LevelUpHUD unit tests passed 100%!")
	hud.queue_free()
	quit(0)
