with open('scripts/ui/components/slanted_button.gd', 'r', encoding='utf-8') as f:
    text = f.read()

target = """	# 3. Border
	var b_col = border_color
	if disabled:
		b_col = Color(0.1, 0.12, 0.16, 0.5)
	draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), b_col, border_width, true)"""

replacement = """	# 3. Border
	var b_col = border_color
	if disabled:
		b_col = Color(0.1, 0.12, 0.16, 0.5)
	draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), b_col, border_width, true)

	# 4. Text
	if text != "":
		var f: Font = get_theme_font("font")
		if f == null:
			f = ThemeDB.fallback_font
		var fs: int = get_theme_font_size("font_size")
		if fs <= 0:
			fs = 13
		var fc: Color = get_theme_color("font_color")
		if disabled:
			var dfc = get_theme_color("font_disabled_color")
			fc = dfc if dfc.a > 0.0 else Color(0.45, 0.5, 0.6, 0.7)
		elif _is_pressed:
			var pfc = get_theme_color("font_pressed_color")
			if pfc.a > 0.0:
				fc = pfc
		elif _is_hovered:
			var hfc = get_theme_color("font_hover_color")
			if hfc.a > 0.0:
				fc = hfc

		var str_sz = f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var ascent = f.get_ascent(fs)
		var text_x = (w - str_sz.x) * 0.5
		var text_y = (h - str_sz.y) * 0.5 + ascent
		draw_string(f, Vector2(text_x, text_y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, fc)"""

if target in text:
    text = text.replace(target, replacement)
    with open('scripts/ui/components/slanted_button.gd', 'w', encoding='utf-8') as f:
        f.write(text)
    print("Successfully added text drawing to SlantedButton.")
else:
    print("Target not found.")
