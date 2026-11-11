extends SceneTree

func _init() -> void:
	var lab = Control.new()
	lab.size = Vector2(1280, 720)
	root.add_child(lab)
	
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color("#060a10")
	lab.add_child(bg)
	
	var SlantedPanelScript = load("res://scripts/ui/components/slanted_panel.gd")
	var panel = SlantedPanelScript.new()
	panel.skew_deg = -9.0
	panel.bg_color = Color("#0d1824")
	panel.border_color = Color.BLACK
	panel.border_width = 2.0
	panel.shadow_offset = Vector2(6, 6)
	panel.position = Vector2(100, 100)
	panel.size = Vector2(400, 200)
	panel.custom_minimum_size = Vector2(400, 200)
	lab.add_child(panel)
	
	for i in range(5):
		await process_frame
		
	var img = root.get_texture().get_image()
	img.save_png("test_slanted_render.png")
	print("TEST SLANTED RENDER SAVED SUCCESSFULLY")
	quit(0)
