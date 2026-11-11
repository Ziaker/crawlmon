extends SceneTree

func _init() -> void:
	var tex = load("res://assets/ui/icons/elements/psychic.svg")
	print("Loaded psychic.svg:", tex != null)
	var tex_type = load("res://assets/ui/icons/move_types/magical.svg")
	print("Loaded magical.svg:", tex_type != null)
	var tex_range = load("res://assets/ui/icons/range/long.svg")
	print("Loaded long.svg:", tex_range != null)
	quit(0)
