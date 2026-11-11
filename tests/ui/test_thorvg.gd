extends SceneTree

func _init() -> void:
	var im := Image.new()
	var err := im.load("res://assets/ui/icons/elements/neutral.svg")
	print("Load err: ", err, " size: ", im.get_size())
	im.save_png("scratch/thorvg_test.png")
	quit(0)
