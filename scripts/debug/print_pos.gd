extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(5):
		await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var b = hud.get_node("MainVBox/HeaderBar/Margin/HBox/TeamStatsBox/TeamStatsBadge")
	print("Badge global pos: ", b.global_position, " size: ", b.size)
	var l = hud.get_node("MainVBox/HeaderBar/Margin/HBox/TeamStatsBox/TeamStatsBadge/Margin/Label")
	print("Label global pos: ", l.global_position, " size: ", l.size, " text: ", l.text)
	var box = hud.get_node("MainVBox/HeaderBar/Margin/HBox/TeamStatsBox")
	print("TeamStatsBox global pos: ", box.global_position, " size: ", box.size)
	var margin = hud.get_node("MainVBox/HeaderBar/Margin")
	print("Margin global pos: ", margin.global_position, " size: ", margin.size)
	quit(0)
