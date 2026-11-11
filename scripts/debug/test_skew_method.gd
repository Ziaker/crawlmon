extends SceneTree

func _init() -> void:
	var c = Control.new()
	# In Godot 4, CanvasItem has draw_set_transform and material
	# Let's test if a CanvasGroup or SubViewport or Shader can shear children
	print("CanvasItem methods test")
	quit(0)
