extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(15):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var stats_vbox = hud.get_node("MainVBox/ContentArea/LeftCol/AttributesCard/Margin/VBox/StatsVBox")
	var mag_row = stats_vbox.get_node("MAG")
	var plus_btn = mag_row.get_node("PlusBtn")
	print("Pre-click: points remaining =", hud._get_current_hero().distributable_points)
	plus_btn.pressed.emit()

	for i in range(5):
		await process_frame

	var img = root.get_texture().get_image()
	img.save_png("res://level_up_hud_stat_allocated.png")
	print("Post-click: allocated stat captured!")
	quit(0)
