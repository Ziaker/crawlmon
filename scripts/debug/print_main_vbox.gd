extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(5):
		await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var vbox = hud.get_node("MainVBox")
	for child in vbox.get_children():
		print(child.name, " size: ", child.size, " min_size: ", child.custom_minimum_size)
	var content = hud.get_node("MainVBox/ContentArea")
	for child in content.get_children():
		print("  Content child: ", child.name, " size: ", child.size, " min_size: ", child.custom_minimum_size)
	quit(0)
