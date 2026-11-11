extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var grid = hud.moves_grid
	print("MovesGrid size: ", grid.size, " pos: ", grid.position)
	for i in range(grid.get_child_count()):
		var c = grid.get_child(i) as Control
		var title = c.get_node_or_null("ContentMargin/VBox/TitleLabel") as Label
		var desc = c.get_node_or_null("ContentMargin/VBox/DescLabel") as Label
		var vbox = c.get_node_or_null("ContentMargin/VBox") as Control
		print("Card %d: size=%s pos=%s vbox_size=%s" % [i, str(c.size), str(c.position), str(vbox.size if vbox else Vector2.ZERO)])
		if desc:
			print("   desc text='%s' size=%s pos=%s clip_text=%s" % [desc.text, str(desc.size), str(desc.position), str(desc.clip_text)])

	quit(0)
