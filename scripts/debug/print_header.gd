extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(5):
		await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var hbox = hud.get_node("MainVBox/HeaderBar/Margin/HBox")
	for child in hbox.get_children():
		print(child.name, " size: ", child.size, " min_size: ", child.custom_minimum_size)
	quit(0)
