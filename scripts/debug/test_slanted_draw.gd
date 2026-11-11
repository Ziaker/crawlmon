extends SceneTree

func _init() -> void:
	var root_ctrl = Control.new()
	root_ctrl.custom_minimum_size = Vector2(400, 300)
	root_ctrl.size = Vector2(400, 300)
	root.add_child(root_ctrl)
	
	var panel = SlantedPanelTest.new()
	panel.position = Vector2(50, 50)
	panel.size = Vector2(300, 150)
	root_ctrl.add_child(panel)
	
	await process_frame
	await process_frame
	
	var img = root.get_viewport().get_texture().get_image()
	img.save_png("test_slanted_panel.png")
	print("Saved test_slanted_panel.png")
	quit(0)

class SlantedPanelTest extends Control:
	var skew_deg: float = -9.0
	var bg_color: Color = Color("#0d1824")
	var border_color: Color = Color.BLACK
	var border_width: float = 2.0
	var shadow_offset: Vector2 = Vector2(4, 4)
	
	func _draw() -> void:
		var w = size.x
		var h = size.y
		var dx = h * tan(deg_to_rad(-skew_deg))
		var p0 = Vector2(dx, 0)
		var p1 = Vector2(w, 0)
		var p2 = Vector2(w - dx, h)
		var p3 = Vector2(0, h)
		
		# Shadow
		var s0 = p0 + shadow_offset
		var s1 = p1 + shadow_offset
		var s2 = p2 + shadow_offset
		var s3 = p3 + shadow_offset
		draw_colored_polygon(PackedVector2Array([s0, s1, s2, s3]), Color(0, 0, 0, 0.8))
		
		# Background
		draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), bg_color)
		
		# Border
		draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), border_color, border_width, true)
