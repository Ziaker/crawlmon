extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(5):
		await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var right_vbox = hud.get_node("MainVBox/ContentArea/RightCol/Margin/VBox")
	for child in right_vbox.get_children():
		print("Right vbox child: ", child.name, " size: ", child.size, " min_size: ", child.get_combined_minimum_size())
	
	var grid = right_vbox.get_node("MovesGrid")
	for card in grid.get_children():
		print("  Card: ", card.name, " size: ", card.size, " min_size: ", card.get_combined_minimum_size())
	quit(0)
