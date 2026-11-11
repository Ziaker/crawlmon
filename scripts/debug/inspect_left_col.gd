extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var left_col = hud.get_node("MainVBox/ContentArea/LeftCol")
	print("LeftCol size: ", left_col.size)
	for child in left_col.get_children():
		print(" - ", child.name, " min_size: ", child.custom_minimum_size, " actual size: ", child.size, " pos: ", child.position)
		if child.name == "AdvanceLockNotice":
			for gc in child.get_children():
				print("     * ", gc.name, " size: ", gc.size, " pos: ", gc.position)
				for ggc in gc.get_children():
					print("         ** ", ggc.name, " size: ", ggc.size, " pos: ", ggc.position)
					for gggc in ggc.get_children():
						print("             *** ", gggc.name, " size: ", gggc.size, " pos: ", gggc.position, " text: ", gggc.text if gggc is Label else "")

	quit(0)
