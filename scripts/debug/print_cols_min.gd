extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(5):
		await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var left = hud.get_node("MainVBox/ContentArea/LeftCol")
	for child in left.get_children():
		print("Left child: ", child.name, " size: ", child.size, " min_size: ", child.get_combined_minimum_size())
	var right = hud.get_node("MainVBox/ContentArea/RightCol")
	for child in right.get_children():
		print("Right child: ", child.name, " size: ", child.size, " min_size: ", child.get_combined_minimum_size())
	quit(0)
