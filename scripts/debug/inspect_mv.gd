extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var mv = hud.get_node("MainVBox")
	print("MainVBox min_size: ", mv.get_combined_minimum_size(), " actual size: ", mv.size)
	for ch in mv.get_children():
		print(" - ", ch.name, " min_size: ", ch.get_combined_minimum_size(), " actual size: ", ch.size)

	var ca = hud.get_node("MainVBox/ContentArea")
	for ch in ca.get_children():
		print("   * ", ch.name, " min_size: ", ch.get_combined_minimum_size(), " actual size: ", ch.size)

	quit(0)
