extends SceneTree

func _init() -> void:
	var tex := BattleHud.element_icon(Element.Type.FISICO)
	if tex == null:
		print("ERROR: tex is null!")
		quit(1)
		return
	var img: Image = tex.get_image()
	if img == null:
		print("ERROR: img is null!")
		quit(1)
		return
	img.save_png("scratch/loaded_neutral_icon.png")
	print("Saved scratch/loaded_neutral_icon.png! Size: ", img.get_size())
	quit(0)
