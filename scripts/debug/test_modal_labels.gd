extends SceneTree

func _init() -> void:
	var lab = load("res://scenes/debug/level_up_hud_lab.tscn").instantiate()
	root.add_child(lab)
	for i in range(10): await process_frame
	var hud = lab.get_node("LevelUpHUD")
	var modal = hud.inspection_modal
	var card = hud.moves_grid.get_child(2)
	card.move_inspect_requested.emit(card._skill)
	for i in range(10): await process_frame

	var ml = modal.get_node("CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block2/Margin/VBox/ManifestLabel")
	var fl = modal.get_node("CenterContainer/ModalCard/Margin/VBox/BlocksRow/Block1/Margin/VBox/FormulaBox/Margin/VBox/HBox/FormulaLabel")
	print("ManifestLabel size: ", ml.size, " min_size: ", ml.get_combined_minimum_size(), " custom: ", ml.custom_minimum_size)
	print("FormulaLabel size: ", fl.size, " min_size: ", fl.get_combined_minimum_size(), " custom: ", fl.custom_minimum_size)
	quit(0)
