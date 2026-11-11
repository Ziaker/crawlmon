extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(5):
		await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var tsb = hud.get_node("MainVBox/HeaderBar/Margin/HBox/TeamStatsBox")
	for child in tsb.get_children():
		print("TSB child: ", child.name, " size: ", child.size, " min_size: ", child.custom_minimum_size)
	var titles = tsb.get_node("TitlesVBox")
	for child in titles.get_children():
		print("  Title child: ", child.name, " size: ", child.size, " min_size: ", child.custom_minimum_size, " text: ", child.text)
	quit(0)
