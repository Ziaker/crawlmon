extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var grid = hud.moves_grid
	for i in range(4):
		var c = grid.get_child(i)
		var desc: Label = c.get_node("ContentMargin/VBox/DescLabel")
		var lc = desc.get_line_count()
		var lh = desc.get_line_height()
		print("Card %d: lines=%d line_h=%d total_h=%d box_h=%.1f" % [i, lc, lh, lc * lh, desc.size.y])

	quit(0)
