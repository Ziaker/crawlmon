extends SceneTree

func _init() -> void:
	var root_ctrl = Control.new()
	root_ctrl.size = Vector2(1280, 720)
	root.add_child(root_ctrl)
	
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color("#060a10")
	root_ctrl.add_child(bg)
	
	var SlantedPanel = load("res://scripts/ui/components/slanted_panel.gd")
	var p = SlantedPanel.new()
	p.skew_deg = -9.0
	p.bg_color = Color("#0d1824")
	p.border_color = Color.BLACK
	p.border_width = 2.0
	p.shadow_offset = Vector2(4, 4)
	p.position = Vector2(100, 100)
	p.size = Vector2(300, 150)
	root_ctrl.add_child(p)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	p.add_child(margin)
	
	var lbl = Label.new()
	lbl.text = "TEST PARALLELOGRAM"
	margin.add_child(lbl)
	
	for i in range(5):
		await process_frame
		
	var img = root.get_texture().get_image()
	img.save_png("res://test_slanted_capture.png")
	print("CAPTURE SAVED")
	quit(0)
