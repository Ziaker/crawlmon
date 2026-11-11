extends SceneTree

func _init() -> void:
	var ctrl = Control.new()
	print("Control has skew:", "skew" in ctrl)
	var n2d = Node2D.new()
	print("Node2D has skew:", "skew" in n2d)
	quit()
