extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TEST D-440: NEUTRAL GLYPH AND ATTACKTAG DISCOVERY ---")

	# 1. Verify element_icon for FISICO returns valid texture
	var neutral_tex := BattleHud.element_icon(Element.Type.FISICO)
	assert(neutral_tex != null, "Neutral icon should not be null")
	print("  [PASS] BattleHud.element_icon(FISICO) successfully loaded")

	# 2. Check AttackTag structure and logic
	var tag := BattleHud.AttackTag.new()
	assert(tag.size == Vector2(150, 38), "AttackTag size matches D-985 specification")
	print("  [PASS] AttackTag size is 150x38")

	# 3. Check Neutral SVG file on disk contains diamond core paths
	var svg_f := FileAccess.open("res://assets/ui/icons/elements/neutral.svg", FileAccess.READ)
	assert(svg_f != null, "neutral.svg must exist")
	var svg_text := svg_f.get_as_text()
	assert("polygon points" in svg_text or "12 2L2 12" in svg_text, "neutral.svg contains Diamond Core geometry")
	print("  [PASS] neutral.svg contains Diamond Core geometry")

	var phys_f := FileAccess.open("res://assets/ui/icons/elements/physical.svg", FileAccess.READ)
	assert(phys_f != null, "physical.svg must exist")
	var phys_text := phys_f.get_as_text()
	assert("polygon points" in phys_text or "12 2L2 12" in phys_text, "physical.svg contains Diamond Core geometry")
	print("  [PASS] physical.svg contains Diamond Core geometry")

	print("=== ALL D-440 TESTS PASSED SUCCESSFULLY ===")
	quit(0)
