class_name PreGameViewSettingsCredits
extends Control
## 1:1 Neo-Brutalist Pre-Game Settings & Credits view (D-433 / D-1079 / D-1207).
## Static, typed, English-only (D-413) drawing through PreGameDraw primitives.
## Mouse and keyboard share one focus model: Q/E switch tabs, arrows move and
## adjust, click or drag the 10-pip slider, click a keybind to capture the key.

signal back_requested
signal settings_changed(settings: Dictionary)

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")

const TAB_COUNT := 5

const BACKDROP := Color(0.020, 0.063, 0.102, 0.93)
const DIVIDER := Color("1e3b4e")
const CHIP_BG := Color("05101a")
const CHIP_BORDER := Color("26485a")
const CYCLE_BG := Color("05101a")
const CYCLE_BORDER := Color("26485a")
const PIP_OFF := Color("1e293b")
const ROW_DARK_TEXT := Color("f4eee1")
const ROW_LIGHT_TEXT := Color("0a1a27")
const TAB_INACTIVE := Color("cbd5e1")
const SUB_DARK := Color("8ea7b0")
const SUB_LIGHT := Color("365263")

var mode: String = "settings"
var settings: Dictionary = {}
var settings_tab_idx: int = 0
var focused_row_idx: int = 0
var listening_key: String = ""

var _dragging_slider: bool = false
var _drag_row_key: String = ""

static var _regular_font_cache: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	queue_redraw()


func setup_settings(p_settings: Dictionary) -> void:
	settings = p_settings.duplicate(true)
	for tab in PreGameCatalog.SETTINGS_TAB_ORDER:
		var rows_v: Variant = settings.get(tab)
		if not (rows_v is Array):
			settings[tab] = (PreGameCatalog.DEFAULT_SETTINGS[tab] as Array).duplicate(true)
	settings_tab_idx = clampi(settings_tab_idx, 0, TAB_COUNT - 1)
	focused_row_idx = 0
	listening_key = ""
	_dragging_slider = false
	queue_redraw()


func set_mode(p_mode: String) -> void:
	mode = "credits" if p_mode == "credits" else "settings"
	listening_key = ""
	_dragging_slider = false
	queue_redraw()


func _ensure_settings() -> void:
	if settings.is_empty():
		setup_settings(PreGameCatalog.clone_default_settings())
		return
	for tab in PreGameCatalog.SETTINGS_TAB_ORDER:
		var rows_v: Variant = settings.get(tab)
		if not (rows_v is Array):
			settings[tab] = (PreGameCatalog.DEFAULT_SETTINGS[tab] as Array).duplicate(true)


func _current_tab() -> String:
	return PreGameCatalog.SETTINGS_TAB_ORDER[clampi(settings_tab_idx, 0, TAB_COUNT - 1)]


func _current_rows() -> Array:
	_ensure_settings()
	var rows_v: Variant = settings.get(_current_tab())
	if rows_v is Array:
		return rows_v as Array
	return []


func _rows_for(tab: String) -> Array:
	_ensure_settings()
	var rows_v: Variant = settings.get(tab)
	if rows_v is Array:
		return rows_v as Array
	return []


func _row_at_index(idx: int) -> Dictionary:
	var rows := _current_rows()
	if idx < 0 or idx >= rows.size():
		return {}
	var row_v: Variant = rows[idx]
	if row_v is Dictionary:
		return row_v as Dictionary
	return {}


func _row_by_key(key: String) -> Dictionary:
	for tab in PreGameCatalog.SETTINGS_TAB_ORDER:
		for row_v in _rows_for(tab):
			if row_v is Dictionary and str((row_v as Dictionary).get("key", "")) == key:
				return row_v as Dictionary
	return {}


func _clamp_focus() -> void:
	var count := _current_rows().size()
	focused_row_idx = clampi(focused_row_idx, 0, maxi(count - 1, 0))


func _emit_change() -> void:
	settings_changed.emit(settings)


func _draw() -> void:
	_ensure_settings()
	var sx := size.x / 1280.0
	var sy := size.y / 720.0
	var s := minf(sx, sy)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.020, 0.063, 0.102, 0.93))
	PreGameDraw.draw_top_edge_rail(self, size.x)
	_draw_header(sx, sy, s)
	if mode == "credits":
		_draw_credits(sx, sy, s)
	else:
		_draw_settings(sx, sy, s)


func _draw_header(sx: float, sy: float, s: float) -> void:
	draw_rect(Rect2(28.0 * sx, 56.0 * sy, size.x - 56.0 * sx, maxf(1.5, 2.0 * s)), Color("1e3b4e"))
	var title_size := maxi(1, int(round(30.0 * s)))
	if mode == "credits":
		PreGameDraw.draw_slash_title(self, Vector2(28.0 * sx, 16.0 * sy), "CREDITS", "INPUTS",
			title_size, -1.0, -9.0, Vector2(3.0, 3.0) * s)
	else:
		PreGameDraw.draw_slash_title(self, Vector2(28.0 * sx, 16.0 * sy), "SYSTEM", "SETTINGS",
			title_size, -1.0, -9.0, Vector2(3.0, 3.0) * s)
	for chip in _header_chips(sx, sy, s):
		var center: Vector2 = chip["center"]
		var chip_size: Vector2 = chip["size"]
		var xf: Transform2D = chip["xform"]
		var accents: Array[Dictionary] = []
		PreGameDraw.draw_card(self, center, chip_size, 0.0, -10.0, CHIP_BG, CHIP_BORDER,
			maxf(1.0, 2.0 * s), Vector2(3.0, 3.0) * s, Color(0.0, 0.0, 0.0, 0.95), accents)
		PreGameDraw.push_counter_skew(self, xf, -10.0)
		_draw_text_centered(PreGameDraw.mono_font(), str(chip["text"]), Vector2.ZERO,
			maxi(7, int(round(10.0 * s))), PreGameDraw.PAPER)
		PreGameDraw.pop_xform(self)


func _header_chips(sx: float, sy: float, s: float) -> Array[Dictionary]:
	var font := PreGameDraw.mono_font()
	var fs := maxi(7, int(round(10.0 * s)))
	var out: Array[Dictionary] = []
	var right := size.x - 28.0 * sx
	var center_y := 36.0 * sy
	var back_text := "[X] BACK"
	var back_w := font.get_string_size(back_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 20.0 * s
	var back_h := 24.0 * s
	var back_center := Vector2(right - back_w * 0.5, center_y)
	out.append({
		"id": "back",
		"text": back_text,
		"center": back_center,
		"size": Vector2(back_w, back_h),
		"xform": PreGameDraw.card_xform(back_center, 0.0, -10.0),
	})
	if mode == "settings":
		var reset_text := "RESET DEFAULTS"
		var reset_w := font.get_string_size(reset_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 20.0 * s
		var reset_center := Vector2(back_center.x - back_w * 0.5 - 8.0 * s - reset_w * 0.5, center_y)
		out.append({
			"id": "reset",
			"text": reset_text,
			"center": reset_center,
			"size": Vector2(reset_w, back_h),
			"xform": PreGameDraw.card_xform(reset_center, 0.0, -10.0),
		})
	return out


func _draw_settings(sx: float, sy: float, s: float) -> void:
	_draw_tabs(sx, sy, s)
	_draw_rows(sx, sy, s)
	_draw_footer(sx, sy, s,
		[["CLICK / DRAG", "ADJUST"], ["Q/E", "TABS"], ["R-CLICK / X", "RETURN"]],
		"UNIMPLEMENTED ITEMS LABELED [PROPOSAL]")


func _tab_metrics(idx: int, sx: float, sy: float, s: float) -> Dictionary:
	var act := idx == settings_tab_idx
	var step_x := (float(idx) * 7.0 + (12.0 if act else 0.0)) * s
	var tab_w := 230.0 * s
	var tab_h := 41.0 * s
	var center := Vector2(28.0 * sx + step_x + tab_w * 0.5, (370.0 + float(idx - 2) * 49.0) * sy)
	var rot := -2.2 if act else 0.6
	return {
		"idx": idx,
		"center": center,
		"size": Vector2(tab_w, tab_h),
		"rot": rot,
		"skew": -9.0,
		"xform": PreGameDraw.card_xform(center, rot, -9.0),
		"active": act,
	}


func _draw_tabs(sx: float, sy: float, s: float) -> void:
	var clip := PackedVector2Array([
		Vector2(0.04, 0.0), Vector2(1.0, 0.0), Vector2(0.96, 1.0), Vector2(0.0, 1.0)
	])
	var font := PreGameDraw.body_font()
	var fs := maxi(8, int(round(17.0 * s)))
	for idx in range(TAB_COUNT):
		var m := _tab_metrics(idx, sx, sy, s)
		var center: Vector2 = m["center"]
		var tab_size: Vector2 = m["size"]
		var act: bool = m["active"]
		var fill := PreGameDraw.LIME if act else PreGameDraw.INK
		var text_col := PreGameDraw.INK if act else TAB_INACTIVE
		var shadow := (Vector2(6.0, 6.0) if act else Vector2(4.0, 4.0)) * s
		var accents: Array[Dictionary] = []
		var xf := PreGameDraw.draw_card(self, center, tab_size, float(m["rot"]), -9.0, fill,
			Color.BLACK, maxf(1.0, 2.0 * s), shadow, Color(0.0, 0.0, 0.0, 0.95), accents, clip)
		PreGameDraw.push_counter_skew(self, xf, -9.0)
		var baseline := (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		draw_string(font, Vector2(-tab_size.x * 0.5 + 16.0 * s, baseline),
			PreGameCatalog.SETTINGS_TAB_ORDER[idx], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)
		PreGameDraw.pop_xform(self)


func _row_metrics(idx: int, sx: float, sy: float, s: float) -> Dictionary:
	var dark := idx % 2 == 0
	var row_w := 966.0 * s
	var row_h := 55.0 * s
	var center := Vector2(278.0 * sx + row_w * 0.5,
		66.0 * sy + row_h * 0.5 + float(idx) * 62.0 * sy)
	var rot := -0.6 if dark else 0.8
	var skew := -7.0 if dark else -5.0
	return {
		"center": center,
		"size": Vector2(row_w, row_h),
		"rot": rot,
		"skew": skew,
		"xform": PreGameDraw.card_xform(center, rot, skew),
		"dark": dark,
	}


func _draw_rows(sx: float, sy: float, s: float) -> void:
	var rows := _current_rows()
	for idx in range(rows.size()):
		var row_v: Variant = rows[idx]
		if not (row_v is Dictionary):
			continue
		var row: Dictionary = row_v as Dictionary
		var m := _row_metrics(idx, sx, sy, s)
		var center: Vector2 = m["center"]
		var row_size: Vector2 = m["size"]
		var dark: bool = m["dark"]
		var fill: Color = PreGameDraw.NAVY if dark else PreGameDraw.PAPER
		var accents: Array[Dictionary] = []
		var xf := PreGameDraw.draw_card(self, center, row_size, float(m["rot"]), float(m["skew"]),
			fill, Color.BLACK, maxf(1.0, 2.0 * s), Vector2(4.0, 4.0) * s,
			Color(0.0, 0.0, 0.0, 0.96), accents, PackedVector2Array())
		PreGameDraw.push_counter_skew(self, xf, float(m["skew"]))
		_draw_row_content(row, row_size, dark, s)
		PreGameDraw.pop_xform(self)


func _draw_row_content(row: Dictionary, row_size: Vector2, dark: bool, s: float) -> void:
	var body := PreGameDraw.body_font()
	var mono := PreGameDraw.mono_font()
	var text_col := ROW_DARK_TEXT if dark else ROW_LIGHT_TEXT
	var name_fs := maxi(8, int(round(14.0 * s)))
	var sub_fs := maxi(7, int(round(11.0 * s)))
	var left := -row_size.x * 0.5 + 18.0 * s
	var name_base := -row_size.y * 0.5 + 21.0 * s
	var name_text := str(row.get("name", ""))
	draw_string(body, Vector2(left, name_base), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		name_fs, text_col)
	var name_w := body.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_fs).x
	if row.has("badge"):
		_draw_proposal_badge(left + name_w + 7.0 * s, name_base, str(row.get("badge", "PROPOSAL")), mono, s)
	var sub_text := str(row.get("sub", ""))
	if not sub_text.is_empty():
		var sub_col := SUB_DARK if dark else SUB_LIGHT
		draw_string(_regular_font(), Vector2(left, name_base + 16.0 * s), sub_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs, sub_col)
	match str(row.get("type", "")):
		"cycle":
			_draw_cycle_control(row, row_size, s)
		"slider":
			_draw_slider_control(row, row_size, dark, s)
		"key":
			_draw_key_control(row, row_size, s)


func _draw_filled_bordered_rect(rect: Rect2, fill: Color, border: Color, border_px: float) -> void:
	var b := clampf(border_px, 1.0, minf(rect.size.x, rect.size.y) * 0.35)
	draw_rect(rect, border)
	draw_rect(rect.grow(-b), fill)


func _draw_proposal_badge(x: float, name_base: float, badge: String, font: Font, s: float) -> void:
	var text := badge.to_upper()
	var fs := maxi(7, int(round(8.5 * s)))
	var pad := 6.0 * s
	var bw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + pad * 2.0
	var bh := 13.0 * s
	var rect := Rect2(x, name_base - 9.0 * s, bw, bh)
	_draw_filled_bordered_rect(rect, PreGameDraw.SATCHEL, Color.BLACK, maxf(1.0, 1.0 * s))
	_draw_text_centered_rect(font, text, rect, fs, Color("dfc980"))


func _cycle_layout(row: Dictionary, row_size: Vector2, s: float) -> Array[Dictionary]:
	var font := PreGameDraw.mono_font()
	var fs := maxi(7, int(round(11.0 * s)))
	var pad := 9.0 * s
	var gap := 6.0 * s
	var opts: Array = []
	var opts_v: Variant = row.get("opts", [])
	if opts_v is Array:
		opts = opts_v as Array
	var widths: Array[float] = []
	var total := 0.0
	for opt in opts:
		var w := font.get_string_size(str(opt), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + pad * 2.0
		widths.append(w)
		total += w
	total += gap * float(maxi(opts.size() - 1, 0))
	var x := row_size.x * 0.5 - 16.0 * s - total
	var h := 20.0 * s
	var out: Array[Dictionary] = []
	for i in range(opts.size()):
		var rect := Rect2(x, -h * 0.5, widths[i], h)
		out.append({"rect": rect, "text": str(opts[i]), "idx": i})
		x += widths[i] + gap
	return out


func _draw_cycle_control(row: Dictionary, row_size: Vector2, s: float) -> void:
	var layout := _cycle_layout(row, row_size, s)
	var font := PreGameDraw.mono_font()
	var fs := maxi(7, int(round(11.0 * s)))
	var active_idx := clampi(int(row.get("idx", 0)), 0, maxi(layout.size() - 1, 0))
	for item in layout:
		var rect: Rect2 = item["rect"]
		var idx := int(item["idx"])
		var active := idx == active_idx
		_draw_filled_bordered_rect(rect, PreGameDraw.LIME if active else CYCLE_BG,
			PreGameDraw.INK if active else CYCLE_BORDER, maxf(1.0, 1.5 * s))
		_draw_text_centered_rect(font, str(item["text"]), rect, fs,
			PreGameDraw.INK if active else TAB_INACTIVE)


func _slider_layout(row: Dictionary, row_size: Vector2, s: float) -> Dictionary:
	var font := PreGameDraw.mono_font()
	var fs := maxi(7, int(round(12.0 * s)))
	var val := int(round(float(row.get("val", 0.0))))
	var value_text := "%d%s" % [val, str(row.get("unit", "%"))]
	var value_w := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var btn := 22.0 * s
	var pip_w := 11.0 * s
	var gap := 3.0 * s
	var pips_w := pip_w * 10.0 + gap * 9.0
	var right := row_size.x * 0.5 - 16.0 * s
	var plus := Rect2(right - value_w - 8.0 * s - btn, -btn * 0.5, btn, btn)
	var pips := Rect2(plus.position.x - 8.0 * s - pips_w, -9.0 * s, pips_w, 18.0 * s)
	var minus := Rect2(pips.position.x - 8.0 * s - btn, -btn * 0.5, btn, btn)
	return {
		"minus": minus,
		"plus": plus,
		"pips": pips,
		"pip_w": pip_w,
		"gap": gap,
		"value_text": value_text,
		"value_x": right,
		"value_w": value_w,
		"font_size": fs,
	}


func _draw_step_button(rect: Rect2, glyph: String, font: Font, fs: int, s: float) -> void:
	_draw_filled_bordered_rect(rect, CYCLE_BG, CYCLE_BORDER, maxf(1.0, 1.5 * s))
	_draw_text_centered_rect(font, glyph, rect, fs, PreGameDraw.PAPER)


func _draw_slider_control(row: Dictionary, row_size: Vector2, dark: bool, s: float) -> void:
	var layout := _slider_layout(row, row_size, s)
	var font := PreGameDraw.mono_font()
	var fs: int = layout["font_size"]
	var minus: Rect2 = layout["minus"]
	var plus: Rect2 = layout["plus"]
	var pips: Rect2 = layout["pips"]
	var pip_w: float = layout["pip_w"]
	var gap: float = layout["gap"]
	_draw_step_button(minus, "-", font, fs, s)
	_draw_step_button(plus, "+", font, fs, s)
	var val := int(round(float(row.get("val", 0.0))))
	var lit := int(round(float(val) / 10.0))
	for p in range(1, 11):
		var rect := Rect2(pips.position + Vector2(float(p - 1) * (pip_w + gap), 0.0),
			Vector2(pip_w, pips.size.y))
		_draw_filled_bordered_rect(rect, PreGameDraw.LIME if p <= lit else PIP_OFF, Color.BLACK, maxf(1.0, 1.0 * s))
	var baseline := (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	var value_text := str(layout["value_text"])
	var value_w: float = layout["value_w"]
	var value_x: float = layout["value_x"]
	draw_string(font, Vector2(value_x - value_w, baseline), value_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.CYAN if dark else PreGameDraw.NAVY)


func _draw_key_control(row: Dictionary, row_size: Vector2, s: float) -> void:
	var font := PreGameDraw.mono_font()
	var key := str(row.get("key", ""))
	var listening := listening_key == key
	var text := "PRESS KEY / ESC" if listening else str(row.get("val", "")).to_upper()
	var fs := maxi(6, int(round((9.0 if listening else 11.0) * s)))
	var pad := 14.0 * s
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pw := maxf(108.0 * s, text_w + pad * 2.0)
	var ph := 26.0 * s
	var right := row_size.x * 0.5 - 16.0 * s
	var rect := Rect2(right - pw, -ph * 0.5, pw, ph)
	draw_rect(Rect2(rect.position + Vector2(3.0, 3.0) * s, rect.size), Color(0.0, 0.0, 0.0, 0.95))
	_draw_filled_bordered_rect(rect, PreGameDraw.CORAL if listening else PreGameDraw.LIME, Color.BLACK, maxf(1.5, 2.0 * s))
	_draw_text_centered_rect(font, text, rect, fs, PreGameDraw.INK)


func _draw_footer(sx: float, sy: float, s: float, entries: Array, right_text: String) -> void:
	var bar_rect := Rect2(28.0 * sx, 684.0 * sy, size.x - 56.0 * sx, 24.0 * sy)
	draw_rect(bar_rect, Color(0.012, 0.047, 0.086, 0.95))
	draw_line(bar_rect.position, Vector2(bar_rect.end.x, bar_rect.position.y), Color(0.698, 0.773, 0.796, 0.35), maxf(1.0, 1.0 * s))
	var font := PreGameDraw.mono_font()
	var fs := maxi(7, int(round(9.5 * s)))
	var pill_h := float(fs + 6)
	var top_y := 696.0 * sy - pill_h * 0.5
	var x := 38.0 * sx
	for entry in entries:
		var w := PreGameDraw.draw_kbd_pill(self, Vector2(x, top_y), str(entry[0]), str(entry[1]), fs)
		x += w + 14.0 * s
	var right_w := font.get_string_size(right_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var right_base := 696.0 * sy + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	draw_string(font, Vector2(size.x - 38.0 * sx - right_w, right_base), right_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TAB_INACTIVE)


func _draw_credits(sx: float, sy: float, s: float) -> void:
	var center_y := 370.0 * sy
	var card_h := 171.0 * s

	var c1_center := Vector2(236.5 * sx, center_y)
	var c1_size := Vector2(417.0 * sx, card_h)
	var c1_accents: Array[Dictionary] = [{"edge": "left", "size": 7.0 * s, "color": PreGameDraw.CORAL}]
	var c1_xf := PreGameDraw.draw_card(self, c1_center, c1_size, -2.2, -7.0, PreGameDraw.PAPER,
		Color.BLACK, maxf(1.0, 2.0 * s), Vector2(6.0, 6.0) * s, Color(0.0, 0.0, 0.0, 0.95),
		c1_accents, PackedVector2Array())
	PreGameDraw.push_counter_skew(self, c1_xf, -7.0)
	_draw_credit_visual(c1_size, s)
	PreGameDraw.pop_xform(self)

	var c2_center := Vector2(640.0 * sx, center_y)
	var c2_size := Vector2(357.0 * sx, card_h)
	var c2_accents: Array[Dictionary] = []
	var c2_xf := PreGameDraw.draw_card(self, c2_center, c2_size, 2.1, 6.0, PreGameDraw.SATCHEL,
		PreGameDraw.GOLD_BORDER, maxf(1.0, 2.0 * s), Vector2(6.0, 6.0) * s, Color(0.0, 0.0, 0.0, 0.95),
		c2_accents, PackedVector2Array())
	PreGameDraw.push_counter_skew(self, c2_xf, 6.0)
	_draw_credit_repo(c2_size, s)
	PreGameDraw.pop_xform(self)

	var c3_center := Vector2(1043.5 * sx, center_y)
	var c3_size := Vector2(417.0 * sx, card_h)
	var c3_accents: Array[Dictionary] = [{"edge": "top", "size": 5.0 * s, "color": PreGameDraw.CYAN}]
	var c3_xf := PreGameDraw.draw_card(self, c3_center, c3_size, -1.4, -9.0, PreGameDraw.CARD_INK,
		Color.BLACK, maxf(1.0, 2.0 * s), Vector2(6.0, 6.0) * s, Color(0.0, 0.0, 0.0, 0.95),
		c3_accents, PackedVector2Array())
	PreGameDraw.push_counter_skew(self, c3_xf, -9.0)
	_draw_credit_inputs(c3_size, s)
	PreGameDraw.pop_xform(self)

	_draw_footer(sx, sy, s, [["R-CLICK / X", "MAIN MENU"]], "REUSES LIVE 3D STAGE")


func _draw_credit_visual(card_size: Vector2, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	var regular := _regular_font()
	var left := -card_size.x * 0.5 + 18.0 * s
	var top := -card_size.y * 0.5 + 18.0 * s
	draw_string(mono, Vector2(left, top + 8.0 * s), "VISUAL ARCHITECTURE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(7, int(round(9.0 * s))), PreGameDraw.CORAL)
	draw_string(body, Vector2(left, top + 38.0 * s), "CRAWLMON 3D HUD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(round(22.0 * s))), PreGameDraw.INK)
	PreGameDraw.draw_wrapped_text(self, regular, Vector2(left, top + 52.0 * s),
		"Direct reuse of StatusScreen (aff_final.png), FanMenu cascades (d1134_menu_orbit.png), D-1093 portraits and 23 canonical SVG glyphs with zero placeholder rounding.",
		maxi(7, int(round(11.0 * s))), Color("16232e"), card_size.x - 36.0 * s, 1.3)


func _draw_credit_repo(card_size: Vector2, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	var regular := _regular_font()
	var left := -card_size.x * 0.5 + 18.0 * s
	var top := -card_size.y * 0.5 + 18.0 * s
	draw_string(mono, Vector2(left, top + 8.0 * s), "SATCHEL // REPO TRUTH",
		HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(7, int(round(9.0 * s))), PreGameDraw.GOLD)
	draw_string(body, Vector2(left, top + 34.0 * s), "HONEST RUNTIME",
		HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(round(20.0 * s))), PreGameDraw.GOLD)
	PreGameDraw.draw_wrapped_text(self, regular, Vector2(left, top + 50.0 * s),
		"Engine: Godot 4.7 (GL Comp)\nCombat: 5-Block Individual ATB\nContinue stays locked until SaveService is built.\nMouse + Keyboard symmetric focus.",
		maxi(7, int(round(11.0 * s))), PreGameDraw.PAPER, card_size.x - 36.0 * s, 1.25)


func _draw_credit_inputs(card_size: Vector2, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	var left := -card_size.x * 0.5 + 18.0 * s
	var top := -card_size.y * 0.5 + 18.0 * s
	draw_string(mono, Vector2(left, top + 8.0 * s), "CONTROLS (GameState)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(7, int(round(9.0 * s))), PreGameDraw.CYAN)
	draw_string(body, Vector2(left, top + 34.0 * s), "INPUT MAP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(round(20.0 * s))), PreGameDraw.PAPER)
	PreGameDraw.draw_wrapped_text(self, mono, Vector2(left, top + 50.0 * s),
		"HOVER/CLICK — Highlight & Confirm\nR-CLICK / X / ESC — Back / Cancel\nARROWS / WASD — Navigate\nZ / D — Confirm / Skill Dossier\nSHIFT — Math View  |  SPACE — Evade",
		maxi(7, int(round(11.0 * s))), PreGameDraw.PAPER, card_size.x - 36.0 * s, 1.25)


func _draw_text_centered(font: Font, text: String, center: Vector2, fs: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := center.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	draw_string(font, Vector2(center.x - width * 0.5, baseline), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _draw_text_centered_rect(font: Font, text: String, rect: Rect2, fs: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var baseline := rect.position.y + rect.size.y * 0.5 + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	draw_string(font, Vector2(rect.position.x + (rect.size.x - width) * 0.5, baseline), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _regular_font() -> Font:
	if _regular_font_cache == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Arial", "Segoe UI"])
		f.font_weight = 500
		_regular_font_cache = f
	return _regular_font_cache


func _hit_row(pos: Vector2, sx: float, sy: float, s: float) -> int:
	var rows := _current_rows()
	for idx in range(rows.size() - 1, -1, -1):
		var m := _row_metrics(idx, sx, sy, s)
		var xf: Transform2D = m["xform"]
		var row_size: Vector2 = m["size"]
		if PreGameDraw.hit_test(pos, xf, row_size):
			return idx
	return -1


func _switch_to_tab(idx: int) -> void:
	var target := clampi(idx, 0, TAB_COUNT - 1)
	if target == settings_tab_idx:
		return
	settings_tab_idx = target
	focused_row_idx = 0
	listening_key = ""
	_dragging_slider = false
	queue_redraw()


func _move_focus(delta: int) -> void:
	var count := _current_rows().size()
	if count <= 0:
		return
	focused_row_idx = clampi(focused_row_idx + delta, 0, count - 1)
	queue_redraw()


func _adjust_current(delta: int) -> bool:
	var row := _row_at_index(focused_row_idx)
	if row.is_empty():
		return false
	match str(row.get("type", "")):
		"cycle":
			var opts: Array = []
			var opts_v: Variant = row.get("opts", [])
			if opts_v is Array:
				opts = opts_v as Array
			if opts.is_empty():
				return false
			row["idx"] = posmod(int(row.get("idx", 0)) + delta, opts.size())
			_emit_change()
			queue_redraw()
			return true
		"slider":
			var value := int(round(float(row.get("val", 0.0))))
			row["val"] = clampi(value + delta * 10, 0, 100)
			_emit_change()
			queue_redraw()
			return true
	return false


func _confirm_current() -> bool:
	var row := _row_at_index(focused_row_idx)
	if row.is_empty():
		return false
	match str(row.get("type", "")):
		"cycle", "slider":
			return _adjust_current(1)
		"key":
			_begin_listen(str(row.get("key", "")))
			return true
	return false


func _begin_listen(key: String) -> void:
	if key.is_empty():
		return
	listening_key = key
	queue_redraw()


func _cancel_listen() -> void:
	listening_key = ""
	queue_redraw()


func _value_from_local_x(local_x: float, layout: Dictionary) -> int:
	var pips: Rect2 = layout["pips"]
	var t := clampf((local_x - pips.position.x) / maxf(pips.size.x, 1.0), 0.0, 1.0)
	return clampi(int(round(t * 10.0)) * 10, 0, 100)


func _activate_row_click(idx: int, pos: Vector2, sx: float, sy: float, s: float) -> void:
	var row := _row_at_index(idx)
	if row.is_empty():
		return
	var m := _row_metrics(idx, sx, sy, s)
	var xf: Transform2D = m["xform"]
	var row_size: Vector2 = m["size"]
	var local := (xf * PreGameDraw.skew_xform(-float(m["skew"]))).affine_inverse() * pos
	match str(row.get("type", "")):
		"cycle":
			for item in _cycle_layout(row, row_size, s):
				var rect: Rect2 = item["rect"]
				if rect.has_point(local):
					row["idx"] = int(item["idx"])
					_emit_change()
					return
		"slider":
			var layout := _slider_layout(row, row_size, s)
			var minus: Rect2 = layout["minus"]
			var plus: Rect2 = layout["plus"]
			var pips: Rect2 = layout["pips"]
			if minus.has_point(local):
				row["val"] = clampi(int(round(float(row.get("val", 0.0)))) - 10, 0, 100)
				_emit_change()
			elif plus.has_point(local):
				row["val"] = clampi(int(round(float(row.get("val", 0.0)))) + 10, 0, 100)
				_emit_change()
			elif pips.has_point(local):
				row["val"] = _value_from_local_x(local.x, layout)
				_dragging_slider = true
				_drag_row_key = str(row.get("key", ""))
				_emit_change()
		"key":
			_begin_listen(str(row.get("key", "")))


func _drag_slider_to(pos: Vector2, sx: float, sy: float, s: float) -> void:
	var rows := _current_rows()
	for idx in range(rows.size()):
		var row_v: Variant = rows[idx]
		if not (row_v is Dictionary):
			continue
		var row: Dictionary = row_v as Dictionary
		if str(row.get("key", "")) != _drag_row_key:
			continue
		var m := _row_metrics(idx, sx, sy, s)
		var xf: Transform2D = m["xform"]
		var row_size: Vector2 = m["size"]
		var local := (xf * PreGameDraw.skew_xform(-float(m["skew"]))).affine_inverse() * pos
		var layout := _slider_layout(row, row_size, s)
		var pips: Rect2 = layout["pips"]
		var lo := pips.position.x - 8.0 * s
		var hi := pips.position.x + pips.size.x + 8.0 * s
		if local.x >= lo and local.x <= hi:
			var new_val := _value_from_local_x(local.x, layout)
			if new_val != int(round(float(row.get("val", 0.0)))):
				row["val"] = new_val
				_emit_change()
				queue_redraw()
		focused_row_idx = idx
		return


func _capture_key(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
		_cancel_listen()
		return
	var keycode: Key = event.physical_keycode
	if keycode == KEY_NONE:
		keycode = event.keycode
	if keycode == KEY_NONE:
		return
	var label := OS.get_keycode_string(keycode).to_upper()
	if label.is_empty():
		label = event.as_text().to_upper()
	if label.is_empty():
		return
	var row := _row_by_key(listening_key)
	if not row.is_empty():
		row["val"] = label
		_set_input_map_key(listening_key, keycode)
		_emit_change()
	listening_key = ""
	queue_redraw()


func _set_input_map_key(action: String, keycode: Key) -> void:
	if action.is_empty():
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _sync_input_map_from_settings() -> void:
	for row_v in _rows_for("CONTROLS"):
		if not (row_v is Dictionary):
			continue
		var row: Dictionary = row_v as Dictionary
		if str(row.get("type", "")) != "key":
			continue
		var action := str(row.get("key", ""))
		var keycode := OS.find_keycode_from_string(str(row.get("val", "")).to_upper())
		if action.is_empty() or keycode == KEY_NONE:
			continue
		_set_input_map_key(action, keycode)


func _reset_defaults() -> void:
	settings = PreGameCatalog.clone_default_settings()
	_sync_input_map_from_settings()
	_clamp_focus()
	listening_key = ""
	_dragging_slider = false
	PreGameCatalog.apply_settings_to_engine(settings, get_node_or_null("/root/GameState"))
	settings_changed.emit(settings)
	queue_redraw()


func handle_key_action(action: String) -> bool:
	if mode == "credits":
		if action == "back":
			back_requested.emit()
			return true
		return false
	if not listening_key.is_empty():
		if action == "back":
			_cancel_listen()
			return true
		return false
	match action:
		"tab_prev":
			_switch_to_tab(posmod(settings_tab_idx - 1, TAB_COUNT))
			return true
		"tab_next":
			_switch_to_tab(posmod(settings_tab_idx + 1, TAB_COUNT))
			return true
		"up":
			_move_focus(-1)
			return true
		"down":
			_move_focus(1)
			return true
		"left":
			return _adjust_current(-1)
		"right":
			return _adjust_current(1)
		"confirm":
			return _confirm_current()
		"back":
			back_requested.emit()
			return true
	return false


func handle_gui_input(event: InputEvent) -> bool:
	var sx := size.x / 1280.0
	var sy := size.y / 720.0
	var s := minf(sx, sy)
	if mode == "credits":
		return _handle_credits_input(event, sx, sy, s)
	return _handle_settings_input(event, sx, sy, s)


func _handle_credits_input(event: InputEvent, sx: float, sy: float, s: float) -> bool:
	if not (event is InputEventMouseButton):
		return false
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return false
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		back_requested.emit()
		return true
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return false
	for chip in _header_chips(sx, sy, s):
		var xf: Transform2D = chip["xform"]
		var chip_size: Vector2 = chip["size"]
		if PreGameDraw.hit_test(mb.position, xf, chip_size):
			back_requested.emit()
			return true
	return false


func _handle_settings_input(event: InputEvent, sx: float, sy: float, s: float) -> bool:
	if event is InputEventKey:
		if listening_key.is_empty():
			return false
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			_capture_key(key)
			return true
		return false
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging_slider:
			_drag_slider_to(mm.position, sx, sy, s)
			return true
		var hovered := _hit_row(mm.position, sx, sy, s)
		if hovered >= 0:
			if hovered != focused_row_idx:
				focused_row_idx = hovered
				queue_redraw()
			return true
		return false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if not mb.pressed:
				return false
			if not listening_key.is_empty():
				_cancel_listen()
			else:
				back_requested.emit()
			return true
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return false
		if not mb.pressed:
			if _dragging_slider:
				_dragging_slider = false
				return true
			return false
		if not listening_key.is_empty():
			_cancel_listen()
			return true
		for chip in _header_chips(sx, sy, s):
			var xf: Transform2D = chip["xform"]
			var chip_size: Vector2 = chip["size"]
			if PreGameDraw.hit_test(mb.position, xf, chip_size):
				if str(chip["id"]) == "back":
					back_requested.emit()
				else:
					_reset_defaults()
				return true
		for idx in range(TAB_COUNT):
			var tm := _tab_metrics(idx, sx, sy, s)
			var txf: Transform2D = tm["xform"]
			var tsize: Vector2 = tm["size"]
			if PreGameDraw.hit_test(mb.position, txf, tsize):
				_switch_to_tab(idx)
				return true
		var row_idx := _hit_row(mb.position, sx, sy, s)
		if row_idx >= 0:
			focused_row_idx = row_idx
			_activate_row_click(row_idx, mb.position, sx, sy, s)
			queue_redraw()
			return true
	return false
