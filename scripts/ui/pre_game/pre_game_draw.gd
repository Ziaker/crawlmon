class_name PreGameDraw
extends RefCounted
## 1:1 Neo-Brutalist drawing primitives for the Pre-Game UI (D-433, D-1079).
## Geometry follows the HTML: rotate + skewX, a counter-skew for upright text,
## zero-blur hard shadows, crisp closed borders and clipped accent edge bars.
## English only (D-413 / D-1085); explicit icon paths, never a folder scan.

# --- Palette ------------------------------------------------------------------

const BG_TOP := Color("26535f")
const BG_MID1 := Color("143343")
const BG_MID2 := Color("092133")
const BG_DARK := Color("051322")

const LIME := Color("d6fa66")
const LIME_FAN := Color("d7fd6a")
const CORAL := Color("ff746c")
const CORAL_FAN := Color("ff624f")

const CYAN := Color("63d9ec")
const GOLD := Color("f0c57e")
const GOLD_BORDER := Color("dfc980")
const SATCHEL := Color("3c2415")

const INK := Color("080e18")
const CARD_INK := Color("061726")
const NAVY := Color("0a1929")
const DEEP_INK := Color("07131e")
const BAR_DARK := Color("030c16")

const PAPER := Color("f4eee1")
const PAPER_ACTIVE := Color("fdfde8")
const BORDER_MUTED := Color("7c8b87")

const TEXT_MUTED := Color("8ea7b0")
const TEXT_SUB := Color("b7cad1")
const TEXT_DIM := Color("9ec0cc")
const PAPER_MUTED := Color("365263")

const STAT_GOOD := Color("86efac")
const STAT_BAD := Color("fca5a5")
const MAG_VIOLET := Color("b5a5fe")
const POW_AMBER := Color("f59e0b")
const CYAN_BORDER := Color("65b5b3")

# --- Element / Move Type / Move Range lookups --------------------------------

const ELEMENTS: Array[Dictionary] = [
	{"id": 0, "key": "neutral", "name": "Neutral", "bg": Color("cbd5e1"), "fg": Color("080e18"), "is_light": true, "svg_path": "res://assets/ui/icons/elements/neutral.svg"},
	{"id": 1, "key": "fire", "name": "Fire", "bg": Color("f97316"), "fg": Color("ffffff"), "is_light": false, "svg_path": "res://assets/ui/icons/elements/fire.svg"},
	{"id": 2, "key": "water_ice", "name": "Water", "bg": Color("0284c7"), "fg": Color("ffffff"), "is_light": false, "svg_path": "res://assets/ui/icons/elements/water_ice.svg"},
	{"id": 3, "key": "electric", "name": "Electric", "bg": Color("fde047"), "fg": Color("080e18"), "is_light": true, "svg_path": "res://assets/ui/icons/elements/electric.svg"},
	{"id": 4, "key": "psychic", "name": "Psychic", "bg": Color("ec4899"), "fg": Color("ffffff"), "is_light": false, "svg_path": "res://assets/ui/icons/elements/psychic.svg"},
	{"id": 5, "key": "nature", "name": "Nature", "bg": Color("84cc16"), "fg": Color("080e18"), "is_light": true, "svg_path": "res://assets/ui/icons/elements/nature.svg"},
	{"id": 6, "key": "sound", "name": "Sound", "bg": Color("06b6d4"), "fg": Color("080e18"), "is_light": true, "svg_path": "res://assets/ui/icons/elements/sound.svg"},
	{"id": 7, "key": "earth", "name": "Earth", "bg": Color("b45309"), "fg": Color("ffffff"), "is_light": false, "svg_path": "res://assets/ui/icons/elements/earth.svg"},
	{"id": 8, "key": "wind", "name": "Wind", "bg": Color("4ff7ba"), "fg": Color("080e18"), "is_light": true, "svg_path": "res://assets/ui/icons/elements/wind.svg"},
	{"id": 9, "key": "light", "name": "Light", "bg": Color("fef08a"), "fg": Color("080e18"), "is_light": true, "svg_path": "res://assets/ui/icons/elements/light.svg"},
	{"id": 10, "key": "dark", "name": "Dark", "bg": Color("6b21a8"), "fg": Color("ffffff"), "is_light": false, "svg_path": "res://assets/ui/icons/elements/dark.svg"},
	{"id": 11, "key": "mystic", "name": "Mystic", "bg": Color("65b5b3"), "fg": Color("080e18"), "is_light": true, "svg_path": "res://assets/ui/icons/elements/mystic.svg"},
]

const MOVE_TYPES: Dictionary = {
	"physical": {"bg": Color("ef4444"), "fg": Color("ffffff"), "svg_path": "res://assets/ui/icons/move_types/physical.svg"},
	"magical": {"bg": Color("0ea5e9"), "fg": Color("ffffff"), "svg_path": "res://assets/ui/icons/move_types/magical.svg"},
	"guard": {"bg": Color("cbd5e1"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/move_types/guard.svg"},
	"dodge": {"bg": Color("fcb900"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/move_types/dodge.svg"},
	"status": {"bg": Color("ffffff"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/move_types/status.svg"},
	"field": {"bg": Color("22c55e"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/move_types/field.svg"},
}

const MOVE_RANGES: Dictionary = {
	"melee": {"bg": Color("f4eee1"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/range/melee.svg"},
	"mid": {"bg": Color("f4eee1"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/range/mid.svg"},
	"long": {"bg": Color("f4eee1"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/range/long.svg"},
	"area": {"bg": Color("f4eee1"), "fg": Color("080e18"), "svg_path": "res://assets/ui/icons/range/area.svg"},
}

static var _mono_font: Font
static var _tex_cache: Dictionary = {}

# --- Fonts & icons -------------------------------------------------------------

static func title_font() -> Font:
	return FanMenu.title_font()


static func body_font() -> Font:
	return FanMenu.body_font()


static func mono_font() -> Font:
	if _mono_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
		f.font_weight = 700
		_mono_font = f
	return _mono_font


static func load_icon(res_path: String) -> Texture2D:
	if res_path.is_empty():
		return null
	if _tex_cache.has(res_path):
		return _tex_cache[res_path] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(res_path):
		tex = load(res_path) as Texture2D
	_tex_cache[res_path] = tex
	return tex


static func elem_info(elem_id: int) -> Dictionary:
	var idx := clampi(elem_id, 0, ELEMENTS.size() - 1)
	return ELEMENTS[idx]

# --- Transforms ---------------------------------------------------------------

static func skew_xform(skew_x_deg: float) -> Transform2D:
	return Transform2D(Vector2(1.0, 0.0), Vector2(tan(deg_to_rad(skew_x_deg)), 1.0), Vector2.ZERO)


static func card_xform(center: Vector2, rot_deg: float, skew_x_deg: float) -> Transform2D:
	return Transform2D(0.0, center) * Transform2D(deg_to_rad(rot_deg), Vector2.ZERO) * skew_xform(skew_x_deg)


static func local_poly(size: Vector2, clip_norm: PackedVector2Array = PackedVector2Array()) -> PackedVector2Array:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	if clip_norm.is_empty():
		return PackedVector2Array([
			Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
		])
	var out := PackedVector2Array()
	for p in clip_norm:
		out.append(Vector2((p.x - 0.5) * size.x, (p.y - 0.5) * size.y))
	return out


static func clip_strip_to_poly(poly: PackedVector2Array, strip_rect: Rect2) -> PackedVector2Array:
	if poly.size() < 3:
		return PackedVector2Array()
	var r := strip_rect.abs()
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return PackedVector2Array()
	var rect := PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)
	])
	var best := PackedVector2Array()
	var best_area := 0.0
	for part in Geometry2D.intersect_polygons(poly, rect):
		if part.size() < 3:
			continue
		var area := absf(_polygon_area(part))
		if area > best_area:
			best_area = area
			best = part
	return best


static func push_counter_skew(ci: CanvasItem, base_xform: Transform2D, skew_x_deg: float) -> void:
	ci.draw_set_transform_matrix(base_xform * skew_xform(-skew_x_deg))


static func push_xform(ci: CanvasItem, xform: Transform2D) -> void:
	ci.draw_set_transform_matrix(xform)


static func pop_xform(ci: CanvasItem) -> void:
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func hit_test(mouse_pos: Vector2, base_xform: Transform2D, size: Vector2) -> bool:
	var local := base_xform.affine_inverse() * mouse_pos
	return absf(local.x) <= size.x * 0.5 and absf(local.y) <= size.y * 0.5

# --- Cards & badges ------------------------------------------------------------

static func draw_card(ci: CanvasItem, center: Vector2, size: Vector2, rot_deg: float, skew_x_deg: float,
		fill: Color, border_col: Color, border_w: float, shadow_offset := Vector2(6, 6),
		shadow_col := Color(0, 0, 0, 0.94), accents: Array[Dictionary] = [],
		clip_norm := PackedVector2Array()) -> Transform2D:
	var rot := Transform2D(deg_to_rad(rot_deg), Vector2.ZERO)
	var skew := skew_xform(skew_x_deg)
	var poly := local_poly(size, clip_norm)
	if shadow_offset != Vector2.ZERO:
		ci.draw_set_transform_matrix(Transform2D(0.0, center + shadow_offset) * rot * skew)
		ci.draw_colored_polygon(poly, shadow_col)
	var xform := card_xform(center, rot_deg, skew_x_deg)
	ci.draw_set_transform_matrix(xform)
	ci.draw_colored_polygon(poly, fill)
	for accent in accents:
		var edge := str(accent.get("edge", "left"))
		var band := float(accent.get("size", 4.0))
		var col: Color = accent.get("color", fill)
		if band <= 0.0:
			continue
		var w := size.x
		var h := size.y
		var strip := Rect2()
		match edge:
			"left":
				strip = Rect2(-w * 0.5, -h * 0.5, band, h)
			"right":
				strip = Rect2(w * 0.5 - band, -h * 0.5, band, h)
			"top":
				strip = Rect2(-w * 0.5, -h * 0.5, w, band)
			"bottom":
				strip = Rect2(-w * 0.5, h * 0.5 - band, w, band)
			_:
				continue
		var clipped := clip_strip_to_poly(poly, strip)
		if clipped.size() >= 3:
			ci.draw_colored_polygon(clipped, col)
	if border_w > 0.0 and poly.size() >= 3:
		var closed := poly.duplicate()
		closed.append(poly[0])
		ci.draw_polyline(closed, border_col, border_w, true)
	return xform


static func draw_slash_title(ci: CanvasItem, top_left: Vector2, left_word: String, right_word: String,
		font_size: int, rot_deg: float, skew_x_deg: float, shadow_offset := Vector2(5, 5),
		echo_coral := false) -> float:
	var font := title_font()
	var left_text := left_word.to_upper()
	var right_text := right_word.to_upper()
	var total := 0.0
	if echo_coral:
		var echo := Color(CORAL, 0.42)
		_slash_title_pass(ci, top_left + Vector2(11, 11), font, left_text, right_text, font_size,
			rot_deg, skew_x_deg, echo, echo, echo)
	_slash_title_pass(ci, top_left + shadow_offset, font, left_text, right_text, font_size,
		rot_deg, skew_x_deg, INK, INK, INK)
	total = _slash_title_pass(ci, top_left, font, left_text, right_text, font_size,
		rot_deg, skew_x_deg, PAPER, CORAL, LIME)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	return total


static func _slash_title_pass(ci: CanvasItem, origin: Vector2, font: Font, left_text: String,
		right_text: String, font_size: int, rot_deg: float, skew_x_deg: float,
		left_col: Color, slash_col: Color, right_col: Color) -> float:
	var gap := maxf(2.0, float(font_size) * 0.16)
	var left_w := font.get_string_size(left_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var slash_w := font.get_string_size("/", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var right_w := font.get_string_size(right_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var total := left_w + gap + slash_w + gap + right_w
	var ascent := font.get_ascent(font_size)
	var base := Transform2D(0.0, origin) * Transform2D(deg_to_rad(rot_deg), Vector2.ZERO) * skew_xform(skew_x_deg)
	ci.draw_set_transform_matrix(base)
	ci.draw_string(font, Vector2(0.0, ascent), left_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, left_col)
	var cursor := left_w + gap
	var slash_center := Vector2(cursor + slash_w * 0.5, ascent - float(font_size) * 0.36)
	ci.draw_set_transform_matrix(base * Transform2D(deg_to_rad(8.0), slash_center))
	ci.draw_string(font, Vector2(-slash_w * 0.5, float(font_size) * 0.36), "/", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, slash_col)
	ci.draw_set_transform_matrix(base)
	cursor += slash_w + gap
	ci.draw_string(font, Vector2(cursor, ascent), right_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, right_col)
	return total


static func draw_elem_chip(ci: CanvasItem, top_left: Vector2, elem_id: int, height: float = 16.0,
		icon_only := false) -> float:
	var info := elem_info(elem_id)
	var bg: Color = info.get("bg", Color("cbd5e1"))
	var fg: Color = info.get("fg", INK)
	var tex := load_icon(str(info.get("svg_path", "")))
	var font := body_font()
	var font_size := maxi(8, int(round(height * 0.62)))
	var inset := 2.0
	var icon_sz := height - inset * 2.0
	var gap := 4.0
	var label := "" if icon_only else str(info.get("name", "")).to_upper()
	var label_w := 0.0
	if not label.is_empty():
		label_w = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var width := height if icon_only else (inset * 2.0 + icon_sz + gap + label_w)
	var rect := Rect2(top_left, Vector2(width, height))
	ci.draw_rect(rect, bg)
	ci.draw_rect(rect, INK, false, 1.0)
	if tex != null:
		ci.draw_texture_rect(tex, Rect2(top_left + Vector2(inset, inset), Vector2(icon_sz, icon_sz)), false, fg)
	if not label.is_empty():
		var base_y := rect.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		var tx := top_left.x + inset + icon_sz + gap
		ci.draw_string(font, Vector2(tx, base_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fg)
	return width


static func draw_move_badge(ci: CanvasItem, center: Vector2, size_px: float, bg: Color, fg: Color,
		icon_tex: Texture2D, skew_deg := -10.0) -> void:
	var half := size_px * 0.5
	var local := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)
	])
	var xform := Transform2D(0.0, center) * skew_xform(skew_deg)
	var pts := PackedVector2Array()
	for p in local:
		pts.append(xform * p)
	ci.draw_colored_polygon(pts, bg)
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	ci.draw_polyline(closed, INK, 1.0, true)
	if icon_tex != null:
		var pad := size_px * 0.18
		var ih := half - pad
		var icon_local := PackedVector2Array([
			Vector2(-ih, -ih), Vector2(ih, -ih), Vector2(ih, ih), Vector2(-ih, ih)
		])
		var icon_pts := PackedVector2Array()
		for p in icon_local:
			icon_pts.append(xform * p)
		var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		ci.draw_polygon(icon_pts, PackedColorArray([fg, fg, fg, fg]), uvs, icon_tex)


static func draw_atb_pips(ci: CanvasItem, top_left: Vector2, cost: int, total := 3,
		pip_size := Vector2(10.0, 6.0), on_col := Color("63d9ec"),
		off_col := Color(0.031, 0.055, 0.094, 0.35), skew_deg := -14.0) -> float:
	var gap := 3.0
	var xf := skew_xform(skew_deg)
	var hx := pip_size.x * 0.5
	var hy := pip_size.y * 0.5
	var local := PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)
	])
	for i in total:
		var center := top_left + Vector2(float(i) * (pip_size.x + gap) + hx, hy)
		var m := Transform2D(0.0, center) * xf
		var pts := PackedVector2Array()
		for p in local:
			pts.append(m * p)
		ci.draw_colored_polygon(pts, on_col if i < cost else off_col)
	return float(total) * pip_size.x + float(maxi(total - 1, 0)) * gap


static func draw_top_edge_rail(ci: CanvasItem, width: float) -> void:
	ci.draw_rect(Rect2(0.0, 0.0, width * 0.25, 4.0), LIME)
	ci.draw_rect(Rect2(width * 0.25, 0.0, width * 0.17, 4.0), CORAL)
	ci.draw_rect(Rect2(width * 0.88, 0.0, width * 0.12, 3.0), CYAN)


static func draw_kbd_pill(ci: CanvasItem, top_left: Vector2, key_text: String, desc_text: String,
		font_size := 10) -> float:
	var key_font := mono_font()
	var desc_font := mono_font()
	var key := key_text.to_upper()
	var pad_x := 5.0
	var pill_w := key_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + pad_x * 2.0
	var pill_h := float(font_size) + 6.0
	var rect := Rect2(top_left, Vector2(pill_w, pill_h))
	ci.draw_rect(rect, PAPER)
	ci.draw_rect(rect, Color.BLACK, false, 1.0)
	var key_base := rect.get_center().y + (key_font.get_ascent(font_size) - key_font.get_descent(font_size)) * 0.5
	ci.draw_string(key_font, Vector2(top_left.x + pad_x, key_base), key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)
	var desc_w := 0.0
	if not desc_text.is_empty():
		desc_w = desc_font.get_string_size(desc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var desc_base := rect.get_center().y + (desc_font.get_ascent(font_size) - desc_font.get_descent(font_size)) * 0.5
		ci.draw_string(desc_font, Vector2(top_left.x + pill_w + 5.0, desc_base), desc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("b2c5cb"))
	return pill_w + (5.0 + desc_w if not desc_text.is_empty() else 0.0)

# --- Text ----------------------------------------------------------------------

static func draw_wrapped_text(ci: CanvasItem, font: Font, top_left: Vector2, text: String,
		font_size: int, color: Color, max_w: float, line_height_mult := 1.28) -> float:
	var lines := _wrap_text_lines(font, text, font_size, max_w)
	var line_h := float(font_size) * line_height_mult
	var y := top_left.y + font.get_ascent(font_size)
	for line in lines:
		ci.draw_string(font, Vector2(top_left.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, max_w, font_size, color)
		y += line_h
	return float(lines.size()) * line_h


static func _wrap_text_lines(font: Font, text: String, font_size: int, max_w: float) -> PackedStringArray:
	var out := PackedStringArray()
	if text.is_empty():
		return out
	for paragraph in text.split("\n"):
		if paragraph.strip_edges().is_empty():
			out.append("")
			continue
		var current := ""
		for word in paragraph.split(" ", false):
			if current.is_empty():
				current = word
			else:
				var trial := current + " " + word
				if max_w <= 0.0 or font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_w:
					current = trial
				else:
					out.append(current)
					current = word
		if not current.is_empty():
			out.append(current)
	return out


static func draw_text_shadowed(ci: CanvasItem, font: Font, baseline_pos: Vector2, text: String,
		font_size: int, color: Color, shadow_col := Color(0, 0, 0, 0.9),
		shadow_off := Vector2(2, 2)) -> void:
	if shadow_col.a > 0.0:
		ci.draw_string(font, baseline_pos + shadow_off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_col)
	ci.draw_string(font, baseline_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func _polygon_area(poly: PackedVector2Array) -> float:
	var n := poly.size()
	if n < 3:
		return 0.0
	var area := 0.0
	for i in n:
		var j := (i + 1) % n
		area += poly[i].x * poly[j].y - poly[j].x * poly[i].y
	return area * 0.5
