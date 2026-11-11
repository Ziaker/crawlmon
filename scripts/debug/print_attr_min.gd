extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(5):
		await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var attr_vbox = hud.get_node("MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox")
	for child in attr_vbox.get_children():
		print("Attr child: ", child.name, " size: ", child.size, " min_size: ", child.get_combined_minimum_size())
	quit(0)
