extends SceneTree

func _init() -> void:
	var lab_scene: PackedScene = load("res://scenes/debug/level_up_hud_lab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)

	for i in range(10):
		await process_frame

	var hud = lab.get_node("LevelUpHUD")
	var ca = hud.get_node("MainVBox/ContentArea")
	print("ContentArea size: ", ca.size, " pos: ", ca.position)
	for ch in ca.get_children():
		print(ch.name, " size: ", ch.size, " pos: ", ch.position)
		if ch.name == "RightCol":
			for rch in ch.get_children():
				print("  ", rch.name, " size: ", rch.size, " pos: ", rch.position)
				for rrch in rch.get_children():
					print("    ", rrch.name, " size: ", rrch.size, " pos: ", rrch.position)

	var fb = hud.get_node("MainVBox/FooterBar")
	print("FooterBar size: ", fb.size, " pos: ", fb.position)

	quit(0)
