extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var hb = hud.get_node("MainVBox/HeaderBar")
	print("HeaderBar min_size: ", hb.get_combined_minimum_size())
	_dump(hb, 0)
	quit(0)

func _dump(node: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth):
		indent += "  "
	if node is Control:
		var c := node as Control
		var txt = ""
		if c is Label:
			txt = " | text='" + (c as Label).text + "'"
		elif c is Button:
			txt = " | btn_text='" + (c as Button).text + "'"
		print(indent, node.name, " min_size: ", c.get_combined_minimum_size(), " custom_min: ", c.custom_minimum_size, " actual: ", c.size, txt)
	for ch in node.get_children():
		_dump(ch, depth + 1)
