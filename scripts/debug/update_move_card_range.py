with open('scripts/ui/components/move_card.gd', 'r', encoding='utf-8') as f:
    text = f.read()

target = """	var range_tex_path = "res://assets/ui/icons/range/%s.svg" % _get_range_file(_skill)
	if ResourceLoader.exists(range_tex_path):
		range_icon.texture = load(range_tex_path)"""

replacement = """	var range_tex_path = "res://assets/ui/icons/range/%s.svg" % _get_range_file(_skill)
	if ResourceLoader.exists(range_tex_path):
		range_icon.texture = load(range_tex_path)
		range_icon.modulate = Color.BLACK"""

if target in text:
    text = text.replace(target, replacement)
    with open('scripts/ui/components/move_card.gd', 'w', encoding='utf-8') as f:
        f.write(text)
    print("Updated range_icon.modulate in move_card.gd")
else:
    print("Target not found in move_card.gd")
