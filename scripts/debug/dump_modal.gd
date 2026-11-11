extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var card = hud.moves_grid.get_child(2)
	card.move_inspect_requested.emit(card._skill)
	for i in range(10):
		await process_frame

	var modal = hud.inspection_modal
	print("MODAL size: ", modal.size)
	_dump(modal, 0)
	quit(0)

func _dump(node: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth):
		indent += "  "
	if node is Control:
		var c := node as Control
		var text_str = ""
		if c is Label:
			text_str = " | text='" + (c as Label).text + "'"
		elif c is Button:
			text_str = " | btn_text='" + (c as Button).text + "'"
		print(indent, node.name, " [", node.get_class(), "] size: ", c.size, " pos: ", c.position, " min_size: ", c.custom_minimum_size, text_str)
	for ch in node.get_children():
		_dump(ch, depth + 1)
