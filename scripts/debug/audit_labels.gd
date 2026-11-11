extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	print("=== AUDITING ALL LABELS IN LEVEL UP HUD ===")
	var hud = lab.get_node("LevelUpHUD")
	_audit_node(hud)

	print("\n=== OPENING MODAL ===")
	var card = hud.moves_grid.get_child(2)
	card.move_inspect_requested.emit(card._skill)
	for i in range(10):
		await process_frame

	_audit_node(hud.inspection_modal)

	quit(0)

func _audit_node(node: Node) -> void:
	if node is Label:
		var lbl := node as Label
		var parent = lbl.get_parent()
		var p_sz = parent.size if parent is Control else Vector2.ZERO
		var p_pos = parent.global_position if parent is Control else Vector2.ZERO
		var l_sz = lbl.size
		var l_pos = lbl.global_position
		var text_sz = lbl.get_theme_font("font").get_string_size(lbl.text, lbl.horizontal_alignment, -1, lbl.get_theme_font_size("font_size")) if lbl.get_theme_font("font") else Vector2.ZERO
		var overflows = false
		if parent is Control:
			if l_pos.x + l_sz.x > p_pos.x + p_sz.x + 2.0 or l_pos.y + l_sz.y > p_pos.y + p_sz.y + 2.0:
				overflows = true
			if text_sz.x > l_sz.x + 4.0 and not lbl.autowrap_mode:
				overflows = true

		if overflows or "..." in lbl.text or text_sz.x > l_sz.x:
			print("OVERFLOW DETECTED: [", lbl.get_path(), "]")
			print("   text: '", lbl.text, "'")
			print("   lbl size: ", l_sz, " | parent size: ", p_sz)
			print("   text size measured: ", text_sz)
			print("   lbl pos: ", l_pos, " | parent pos: ", p_pos)
			print("   autowrap: ", lbl.autowrap_mode, " | clip_text: ", lbl.clip_text)

	for c in node.get_children():
		_audit_node(c)
