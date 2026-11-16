class_name PreGameViewCharSelect
extends Control
## 1:1 Neo-Brutalist Pre-Game Character Selection (D-1207 / D-1208).
## Draws the five HTML zones with PreGameDraw primitives and the real D-1093
## portrait textures. English only (D-413 / D-1085), static typing throughout.

signal back_to_menu
signal character_selected(idx: int)
signal move_selected(idx: int)
signal confirm_protagonist
signal open_skill_dossier
signal open_advanced_dossier(layer: int)
signal toggle_shift_math
signal camera_action(action: String)

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")

const BASE_W := 1280.0
const BASE_H := 720.0
const ROSTER_TOP := 160.0
const ROSTER_STEP := 52.0
const ROSTER_W := 284.0
const ROSTER_H := 46.0
const STAGE_BOX := Rect2(325.0, 68.0, 490.0, 402.0)
const STARTER_COUNT := 3

var char_index: int = 0
var move_index: int = 0
var shift_math_mode: bool = false
var turntable_active: bool = false
var show_rig_overlay: bool = false
var framing_text: String = ""
## D-1226: false = 3D model with the game pixel filter, true = character art only.
var art_only: bool = false

var _protagonists: Array[Dictionary] = []
var _kit_cache: Dictionary = {}
var _art_cache: Dictionary = {}
var _hover_id: String = ""

# --- Lifecycle ---------------------------------------------------------------

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_protagonists = PreGameCatalog.build_protagonist_list()
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	if not gui_input.is_connected(handle_gui_input):
		gui_input.connect(handle_gui_input)

func _ensure_data() -> void:
	if _protagonists.is_empty():
		_protagonists = PreGameCatalog.build_protagonist_list()

func _current_spec() -> Dictionary:
	_ensure_data()
	if _protagonists.is_empty():
		return {}
	return _protagonists[clampi(char_index, 0, _protagonists.size() - 1)]

func _current_move() -> Dictionary:
	var sp := _current_spec()
	var ids: Array = sp.get("starter_moves", [])
	if ids.is_empty():
		return PreGameCatalog.get_move_spec("tackle")
	return PreGameCatalog.get_move_spec(str(ids[clampi(move_index, 0, ids.size() - 1)]))

func set_state(p_char_index: int = 0, p_move_index: int = 0, p_shift_math: bool = false,
		p_turntable: bool = false, p_show_rig: bool = false, p_framing_text: String = "") -> void:
	_ensure_data()
	var count := maxi(_protagonists.size(), 1)
	char_index = clampi(p_char_index, 0, count - 1)
	move_index = clampi(p_move_index, 0, STARTER_COUNT - 1)
	shift_math_mode = p_shift_math
	turntable_active = p_turntable
	show_rig_overlay = p_show_rig
	if not p_framing_text.is_empty():
		framing_text = p_framing_text
	queue_redraw()

# --- Scale, layout & audit ----------------------------------------------------

func _scale_x() -> float:
	return size.x / BASE_W

func _scale_y() -> float:
	return size.y / BASE_H

func get_pedestal_safe_rect() -> Rect2:
	var sx := _scale_x()
	var sy := _scale_y()
	return Rect2(STAGE_BOX.position.x * sx, STAGE_BOX.position.y * sy, STAGE_BOX.size.x * sx, STAGE_BOX.size.y * sy)

func get_quad_audit_rects() -> Dictionary:
	var sx := _scale_x()
	var sy := _scale_y()
	var s := minf(sx, sy)
	return {
		"roster": Rect2(28.0 * sx, ROSTER_TOP * sy, ROSTER_W * s, ROSTER_STEP * 6.0 * sy),
		"pedestal": get_pedestal_safe_rect(),
		"affinity": _affinity_rect(sx, sy, s),
		"dossier": Rect2(830.0 * sx, 186.0 * sy, 422.0 * s, 204.0 * sy),
		"confirm_btn": _confirm_rect(sx, sy, s),
		"deck": Rect2(28.0 * sx, 574.0 * sy, 1224.0 * s, 108.0 * sy),
		"footer": Rect2(0.0, 684.0 * sy, size.x, 24.0 * sy),
	}

func _affinity_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(325.0 * sx, 536.0 * sy, 490.0 * s, 24.0 * s)

func _view_chip_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(570.0 * sx - 105.0 * s, 94.0 * sy, 210.0 * s, 30.0 * s)

func _confirm_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(830.0 * sx, 394.0 * sy, 422.0 * s, 44.0 * s)

func _roster_item_rect(sx: float, sy: float, s: float, idx: int) -> Rect2:
	var step_x := (float(idx) * 4.5 + (30.0 if idx == char_index else 0.0)) * s
	var y := ROSTER_TOP * sy + float(idx) * ROSTER_STEP * sy
	return Rect2(28.0 * sx + step_x, y, ROSTER_W * s, ROSTER_H * s)

func _strip_rect(sx: float, sy: float, s: float, idx: int) -> Rect2:
	var w := 212.0 * s
	var gap := 6.0 * s
	var y := 592.0 * sy - (2.0 * s if idx == move_index else 0.0)
	return Rect2(28.0 * sx + float(idx) * (w + gap), y, w, 42.0 * s)

func _menu_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(28.0 * sx, 44.0 * sy, 78.0 * s, 20.0 * s)

func _adv_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(28.0 * sx + 86.0 * s, 44.0 * sy, 196.0 * s, 20.0 * s)

func _advance_bar_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(1056.0 * sx, 344.0 * sy, 188.0 * s, 28.0 * s)

func _inspect_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(694.0 * sx, 588.0 * sy, 558.0 * s, 94.0 * s)

func _math_pill_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(1074.0 * sx, 664.0 * sy, 76.0 * s, 15.0 * s)

func _spec_pill_rect(sx: float, sy: float, s: float) -> Rect2:
	return Rect2(1156.0 * sx, 664.0 * sy, 62.0 * s, 15.0 * s)

# --- Drawing entry point ------------------------------------------------------

func _draw() -> void:
	_ensure_data()
	var sx := _scale_x()
	var sy := _scale_y()
	var s := minf(sx, sy)
	PreGameDraw.draw_top_edge_rail(self, size.x)
	_draw_top_bar(sx, sy, s)
	_draw_pedestal(sx, sy, s)
	_draw_art(sx, sy, s)
	_draw_roster(sx, sy, s)
	_draw_view_chip(sx, sy, s)
	_draw_affinity_row(sx, sy, s)
	_draw_dossier(sx, sy, s)
	_draw_deck(sx, sy, s)
	_draw_footer(sx, sy, s)
	draw_set_transform_matrix(Transform2D.IDENTITY)

# --- Drawing: top bar ---------------------------------------------------------

func _draw_top_bar(sx: float, sy: float, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var kicker := "PROTAGONISTS // ALL 6 UNLOCKED AT NEW GAME (D-1207)"
	var kfs := int(round(10.5 * s))
	var k_anchor := Vector2(28.0 * sx, 14.0 * sy)
	var k_xf := Transform2D(deg_to_rad(-1.2), Vector2.ZERO)
	k_xf.origin = k_anchor
	draw_set_transform_matrix(k_xf)
	draw_string(mono, Vector2(0.0, mono.get_ascent(kfs)), kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs, PreGameDraw.LIME)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var kw := mono.get_string_size(kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs).x
	draw_line(k_anchor + Vector2(0.0, float(kfs) + 5.0 * s), k_anchor + Vector2(kw, float(kfs) + 5.0 * s), Color(0.839, 0.980, 0.400, 0.42), 1.0)
	var menu_rect := _menu_rect(sx, sy, s)
	_draw_chip(menu_rect, "[X] MENU", PreGameDraw.CARD_INK, PreGameDraw.PAPER, _hover_id == "menu", s, Vector2(2.5, 2.5) * s)
	var adv_rect := _adv_rect(sx, sy, s)
	_draw_chip(adv_rect, "ADVANCED DOSSIER [A / TAB]", PreGameDraw.CYAN, PreGameDraw.INK, _hover_id == "advanced", s)
	PreGameDraw.draw_slash_title(self, Vector2(size.x - 365.0 * s, 12.0 * sy), "SELECT", "PROTAGONIST", int(round(36.0 * s)), -1.8, -9.0, Vector2(3, 3) * s)

func _draw_chip(rect: Rect2, label: String, fill: Color, text_col: Color, hover: bool,
		s: float, shadow: Vector2 = Vector2.ZERO) -> void:
	var use_fill := fill.lightened(0.10) if hover else fill
	var border := PreGameDraw.CYAN if hover else PreGameDraw.INK
	var xf := PreGameDraw.draw_card(self, rect.get_center(), rect.size, 0.0, -9.0, use_fill,
		border, 1.5 * maxf(s, 0.75), shadow, Color(0.0, 0.0, 0.0, 0.85))
	PreGameDraw.push_counter_skew(self, xf, -9.0)
	var font := PreGameDraw.mono_font()
	var fs := int(round(9.0 * s))
	var baseline := (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	draw_string(font, Vector2(-rect.size.x * 0.5 + 7.0 * s, baseline), label,
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0 * s, fs, text_col)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_pedestal(sx: float, sy: float, s: float) -> void:
	var r := get_pedestal_safe_rect()
	var arm := 18.0 * s
	var col := Color(PreGameDraw.CYAN, 0.24)
	var w := 1.8 * s
	draw_line(r.position, r.position + Vector2(arm, 0.0), col, w, true)
	draw_line(r.position, r.position + Vector2(0.0, arm), col, w, true)
	draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x - arm, r.position.y), col, w, true)
	draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + arm), col, w, true)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x + arm, r.end.y), col, w, true)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.end.y - arm), col, w, true)
	draw_line(r.end, r.end - Vector2(arm, 0.0), col, w, true)
	draw_line(r.end, r.end - Vector2(0.0, arm), col, w, true)
	var mono := PreGameDraw.mono_font()
	var fs := int(round(8.5 * s))
	var badge_txt := "CHARACTER ART" if art_only else "LIVE 3D STAGE // AUTO-FRAME FOCUS"
	var bw := mono.get_string_size(badge_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0 * s
	var bh := 18.0 * s
	var bcenter := Vector2(r.position.x + r.size.x * 0.5, r.position.y + 13.0 * s)
	var bxf := PreGameDraw.draw_card(self, bcenter, Vector2(bw, bh), 0.0, -9.0, Color("081421"), Color("234057"), 1.2 * s, Vector2.ZERO, Color.TRANSPARENT)
	PreGameDraw.push_counter_skew(self, bxf, -9.0)
	draw_string(mono, Vector2(-bw * 0.5 + 9.0 * s, (mono.get_ascent(fs) - mono.get_descent(fs)) * 0.5),
		badge_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.CYAN)
	draw_set_transform_matrix(Transform2D.IDENTITY)

# --- Drawing: Zona A roster ---------------------------------------------------

func _portrait_tex(sp: Dictionary) -> Texture2D:
	if sp.get("portrait_icon") is Texture2D:
		return sp["portrait_icon"] as Texture2D
	var id := str(sp.get("id", ""))
	if id.is_empty():
		return null
	return PreGameCatalog.species_portrait(id)

func _draw_tex_fit(tex: Texture2D, box: Rect2) -> void:
	var ts := tex.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return
	var k := minf(box.size.x / ts.x, box.size.y / ts.y)
	var target := ts * k
	draw_texture_rect(tex, Rect2(box.get_center() - target * 0.5, target), false, Color.WHITE)

func _kit_text(sp: Dictionary) -> String:
	var key := str(sp.get("id", ""))
	if _kit_cache.has(key):
		return str(_kit_cache[key])
	var ids: Array = sp.get("starter_moves", [])
	var names: Array[String] = []
	for i in range(1, mini(3, ids.size())):
		var spec := PreGameCatalog.get_move_spec(str(ids[i]))
		names.append(str(spec.get("name", "")).to_upper())
	var text := " / ".join(names)
	_kit_cache[key] = text
	return text

func _element_names(sp: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var elements: Array = sp.get("elements", [])
	for e_idx in elements.size():
		var info := PreGameDraw.elem_info(int(elements[e_idx]))
		out.append(str(info.get("name", "")).to_upper())
	return out

func _draw_roster(sx: float, sy: float, s: float) -> void:
	var body := PreGameDraw.body_font()
	var title := PreGameDraw.title_font()
	var mono := PreGameDraw.mono_font()
	for idx in _protagonists.size():
		var sp: Dictionary = _protagonists[idx]
		var active := idx == char_index
		var rect := _roster_item_rect(sx, sy, s, idx)
		var rot := -1.4 if active else (-0.5 if idx % 2 == 0 else 0.7)
		var fill := PreGameDraw.PAPER_ACTIVE if active else PreGameDraw.PAPER
		var shadow := (Vector2(6.0, 6.0) if active else Vector2(4.0, 5.0)) * s
		var shadow_col := Color.BLACK if active else Color(0.016, 0.051, 0.086, 0.72)
		var accents: Array[Dictionary] = []
		if _hover_id == "roster:%d" % idx:
			accents.append({"edge": "right", "size": 3.0 * s, "color": PreGameDraw.CYAN})
		var clip := PackedVector2Array([Vector2(0.03, 0.0), Vector2(1.0, 0.0), Vector2(0.97, 1.0), Vector2(0.0, 1.0)])
		var xf := PreGameDraw.draw_card(self, rect.get_center(), rect.size, rot, -7.0, fill, PreGameDraw.INK, 1.6 * s, shadow, shadow_col, accents, clip)
		if active:
			var rw := rect.size.x
			var rh := rect.size.y
			# D-1226: full parallelogram marker, parallel to the card's slanted left edge.
			var stripe_w := 9.0 * s
			var gap := 4.0 * s
			var top_lx := (0.03 - 0.5) * rw - gap
			var bot_lx := -0.5 * rw - gap
			var stripe := PackedVector2Array([
				Vector2(top_lx - stripe_w, -0.5 * rh),
				Vector2(top_lx, -0.5 * rh),
				Vector2(bot_lx, 0.5 * rh),
				Vector2(bot_lx - stripe_w, 0.5 * rh),
			])
			draw_colored_polygon(stripe, PreGameDraw.LIME)
		PreGameDraw.push_counter_skew(self, xf, -7.0)
		var half_w := rect.size.x * 0.5
		var px := -half_w + (12.0 if active else 7.0) * s
		var py := -18.0 * s
		var psz := 36.0 * s
		draw_rect(Rect2(Vector2(px, py), Vector2(psz, psz)), Color("77c7d7"))
		draw_rect(Rect2(Vector2(px, py), Vector2(psz, psz)), Color("234057"), false, 2.0 * s)
		var tex := _portrait_tex(sp)
		if tex != null:
			_draw_tex_fit(tex, Rect2(Vector2(px + 2.0 * s, py + 2.0 * s), Vector2(psz - 4.0 * s, psz - 4.0 * s)))
		var name_text := str(sp.get("name", "")).to_upper()
		var nfs := int(round(16.0 * s))
		var nx := px + psz + 8.0 * s
		draw_string(title, Vector2(nx, py + title.get_ascent(nfs) + 2.0 * s), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, PreGameDraw.INK)
		var chip_x := nx + title.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x + 6.0 * s
		var elements: Array = sp.get("elements", [])
		for e_idx in elements.size():
			chip_x += PreGameDraw.draw_elem_chip(self, Vector2(chip_x, py + 1.0 * s), int(elements[e_idx]), 13.0 * s, true) + 3.0 * s
		var hfs := int(round(9.0 * s))
		var htext := "%.2fm" % float(sp.get("height", 1.0))
		var hw := mono.get_string_size(htext, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs).x
		draw_string(mono, Vector2(half_w - 8.0 * s - hw, py + mono.get_ascent(hfs) + 2.0 * s), htext, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, PreGameDraw.PAPER_MUTED)
		var bfs := int(round(7.5 * s))
		var by := 11.0 * s + body.get_ascent(bfs)
		var base_txt := "15-PT BASE"
		draw_string(mono, Vector2(nx, by), base_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs, PreGameDraw.PAPER_MUTED)
		var kit := _kit_text(sp)
		var kfs := maxi(4, int(round(7.0 * s)))
		var min_kfs := maxi(4, int(round(5.0 * s)))
		var min_kit_x := nx + mono.get_string_size(base_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x + 6.0 * s
		var max_kw := maxf(24.0 * s, (half_w - 13.0 * s) - min_kit_x)
		while kfs > min_kfs and mono.get_string_size(kit, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs).x > max_kw:
			kfs -= 1
		var kit_w := mono.get_string_size(kit, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs).x
		draw_string(mono, Vector2(half_w - 13.0 * s - kit_w, by), kit, HORIZONTAL_ALIGNMENT_LEFT, -1, kfs, PreGameDraw.PAPER_MUTED)
		draw_set_transform_matrix(Transform2D.IDENTITY)

# --- Drawing: view chip, art view and elemental affinities (D-1226) ----------

## D-1226: flat skewed-parallelogram toggle above the model/art, like the menu buttons.
func _draw_view_chip(sx: float, sy: float, s: float) -> void:
	var rect := _view_chip_rect(sx, sy, s)
	var hover := _hover_id == "view"
	var fill := PreGameDraw.LIME_FAN if (art_only or hover) else Color(0.031, 0.055, 0.094, 0.94)
	var text_col := PreGameDraw.INK if (art_only or hover) else PreGameDraw.PAPER
	var xf := PreGameDraw.draw_card(self, rect.get_center(), rect.size, -1.6, -10.0, fill,
		Color.TRANSPARENT, 0.0, Vector2.ZERO, Color.TRANSPARENT)
	PreGameDraw.push_counter_skew(self, xf, -10.0)
	var title := PreGameDraw.title_font()
	var fs := int(round(15.0 * s))
	var label := "RENDER IMAGE" if art_only else "3D MODEL"
	var tag_fs := int(round(8.0 * s))
	var mono := PreGameDraw.mono_font()
	draw_string(title, Vector2(-rect.size.x * 0.5 + 16.0 * s, (title.get_ascent(fs) - title.get_descent(fs)) * 0.5), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)
	draw_string(mono, Vector2(-rect.size.x * 0.5, (mono.get_ascent(tag_fs) - mono.get_descent(tag_fs)) * 0.5), "SWITCH [F]",
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0 * s, tag_fs, Color(text_col, 0.7))
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _art_tex(sp: Dictionary) -> Texture2D:
	var id := str(sp.get("id", ""))
	var path := str(PreGameCatalog.DQT_PORTRAIT_PATHS.get(id, "res://sugimori/por_nome/%s.png" % id))
	if _art_cache.has(path):
		return _art_cache[path] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var src := load(path) as Texture2D
		if src != null:
			var img := src.get_image()
			if img != null:
				if img.is_compressed():
					img.decompress()
				img.convert(Image.FORMAT_RGBA8)
				tex = ImageTexture.create_from_image(img)
	_art_cache[path] = tex
	return tex if tex != null else _portrait_tex(sp)

func _draw_art(_sx: float, _sy: float, s: float) -> void:
	if not art_only:
		return
	var tex := _art_tex(_current_spec())
	if tex == null:
		return
	var r := get_pedestal_safe_rect()
	var pad := 30.0 * s
	_draw_tex_fit(tex, Rect2(r.position + Vector2(pad, 62.0 * s), r.size - Vector2(pad * 2.0, 62.0 * s + pad)))

func _draw_affinity_row(sx: float, sy: float, s: float) -> void:
	var sp := _current_spec()
	if sp.is_empty():
		return
	var mono := PreGameDraw.mono_font()
	var fs := int(round(8.5 * s))
	var rect := _affinity_rect(sx, sy, s)
	var x := rect.position.x
	var base_y := rect.position.y + (rect.size.y + mono.get_ascent(fs) - mono.get_descent(fs)) * 0.5
	var groups: Array[Dictionary] = [
		{"label": "WEAK TO", "ids": sp.get("weaknesses", [])},
		{"label": "RESISTS", "ids": sp.get("resistances", [])},
	]
	for g in groups:
		var label := str(g["label"])
		draw_string(mono, Vector2(x, base_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.CYAN)
		x += mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8.0 * s
		var ids: Array = g["ids"]
		if ids.is_empty():
			draw_string(mono, Vector2(x, base_y), "NONE", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.TEXT_MUTED)
			x += mono.get_string_size("NONE", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		for id in ids:
			x += PreGameDraw.draw_elem_chip(self, Vector2(x, rect.position.y + 3.0 * s), int(id), 18.0 * s, true) + 3.0 * s
		x += 18.0 * s

# --- Drawing: Zona C dossier --------------------------------------------------

func _draw_row(mono: Font, body: Font, x: float, y_top: float, s: float, label: String, value: String, fs: int) -> void:
	draw_string(body, Vector2(x, y_top + body.get_ascent(fs)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.PAPER_MUTED)
	draw_string(mono, Vector2(x + 52.0 * s, y_top + mono.get_ascent(fs)), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.INK)

func _draw_elem_box(top_left: Vector2, elem_id: int, box: Vector2, s: float) -> void:
	var info := PreGameDraw.elem_info(elem_id)
	var bg: Color = info.get("bg", Color("cbd5e1"))
	var fg: Color = info.get("fg", PreGameDraw.INK)
	var rect := Rect2(top_left, box)
	draw_rect(rect, bg)
	draw_rect(rect, PreGameDraw.INK, false, 1.0 * maxf(s, 0.8))
	var tex := PreGameDraw.load_icon(str(info.get("svg_path", "")))
	if tex != null:
		var pad := 4.0 * s
		draw_texture_rect(tex, Rect2(rect.position + Vector2(pad, pad), rect.size - Vector2(pad, pad) * 2.0), false, fg)

func _draw_dossier(sx: float, sy: float, s: float) -> void:
	var sp := _current_spec()
	if sp.is_empty():
		return
	var body := PreGameDraw.body_font()
	var title := PreGameDraw.title_font()
	var mono := PreGameDraw.mono_font()
	var x0 := 830.0 * sx
	var rfs := int(round(8.5 * s))
	var role := "PROTAGONIST #%d/6 // NEW GAME STARTER" % (char_index + 1)
	var role_w := mono.get_string_size(role, HORIZONTAL_ALIGNMENT_LEFT, -1, rfs).x + 18.0 * s
	var role_rect := Rect2(Vector2(x0, 190.0 * sy), Vector2(role_w, 16.0 * s))
	var role_xf := PreGameDraw.draw_card(self, role_rect.get_center(), role_rect.size, -1.2, -6.0, Color(0.027, 0.110, 0.169, 0.94), Color.BLACK, 1.2 * s, Vector2.ZERO, Color.TRANSPARENT, [{"edge": "left", "size": 4.0 * s, "color": PreGameDraw.CORAL}], PackedVector2Array())
	PreGameDraw.push_counter_skew(self, role_xf, -6.0)
	draw_string(mono, Vector2(-role_rect.size.x * 0.5 + 8.0 * s, (mono.get_ascent(rfs) - mono.get_descent(rfs)) * 0.5),
		role, HORIZONTAL_ALIGNMENT_LEFT, -1, rfs, PreGameDraw.LIME)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var origin_base := role_rect.position.y + (role_rect.size.y + mono.get_ascent(rfs) - mono.get_descent(rfs)) * 0.5
	draw_string(mono, Vector2(role_rect.end.x + 10.0 * s, origin_base),
		"%.2fm • %s" % [float(sp.get("height", 1.0)), str(sp.get("origin", ""))],
		HORIZONTAL_ALIGNMENT_LEFT, -1, rfs, PreGameDraw.TEXT_MUTED)
	var name_text := str(sp.get("name", "")).to_upper()
	var nfs := int(round(40.0 * s))
	draw_set_transform_matrix(Transform2D(0.0, Vector2(x0, 222.0 * sy)) * PreGameDraw.skew_xform(-8.0))
	draw_string(title, Vector2(0.0, title.get_ascent(nfs)), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, PreGameDraw.PAPER)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var chip_x := x0 + title.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x + 12.0 * s
	var elements: Array = sp.get("elements", [])
	for e_idx in elements.size():
		_draw_elem_box(Vector2(chip_x, 228.0 * sy), int(elements[e_idx]), Vector2(32.0, 22.0) * s, s)
		chip_x += 36.0 * s
	var kicker_fs := int(round(8.0 * s))
	var row_fs := int(round(8.0 * s))
	var pass_fs := int(round(7.5 * s))
	var lc_size := Vector2(210.0, 122.0) * s
	var lc_clip := PackedVector2Array([Vector2(0.02, 0.0), Vector2(1.0, 0.0), Vector2(0.98, 1.0), Vector2(0.0, 1.0)])
	var lxf := PreGameDraw.draw_card(self, Vector2(935.0 * sx, 326.0 * sy), lc_size, -1.6, -6.0, PreGameDraw.PAPER, PreGameDraw.INK, 1.6 * s, Vector2(5.0, 5.0) * s, Color.BLACK, [], lc_clip)
	PreGameDraw.push_counter_skew(self, lxf, -6.0)
	var lx := -lc_size.x * 0.5 + 14.0 * s
	var ltop := -lc_size.y * 0.5
	draw_string(mono, Vector2(lx, ltop + 4.0 * s + mono.get_ascent(kicker_fs)), "SPECIES PROFILE (C1)", HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_fs, PreGameDraw.PAPER_MUTED)
	_draw_row(mono, body, lx, ltop + 16.0 * s, s, "HEIGHT", "%.2f m" % float(sp.get("height", 1.0)), row_fs)
	_draw_row(mono, body, lx, ltop + 29.0 * s, s, "INNATE", " / ".join(PackedStringArray(_element_names(sp))), row_fs)
	_draw_row(mono, body, lx, ltop + 42.0 * s, s, "KIT", "TACKLE + 2 SPEC", row_fs)
	draw_line(Vector2(lx, ltop + 53.0 * s), Vector2(lc_size.x * 0.5 - 10.0 * s, ltop + 53.0 * s), Color(PreGameDraw.INK, 0.28), 1.0)
	PreGameDraw.draw_wrapped_text(self, body, Vector2(lx, ltop + 57.0 * s), str(sp.get("passive_summary", "")), pass_fs, PreGameDraw.PAPER_MUTED, lc_size.x - 24.0 * s, 1.22)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var rc_size := Vector2(204.0, 122.0) * s
	var rxf := PreGameDraw.draw_card(self, Vector2(1150.0 * sx, 326.0 * sy), rc_size, 1.5, -5.0, Color(0.024, 0.09, 0.15, 0.96), PreGameDraw.INK, 1.6 * s, Vector2(5.0, 5.0) * s, Color.BLACK, [], PackedVector2Array())
	PreGameDraw.push_counter_skew(self, rxf, -5.0)
	var rx := -rc_size.x * 0.5 + 8.0 * s
	var rtop := -rc_size.y * 0.5
	var header := "RAW SPECIES SPEC [SHIFT]" if shift_math_mode else "BASE 15 PTS (D-390)"
	draw_string(mono, Vector2(rx, rtop + 4.0 * s + mono.get_ascent(kicker_fs)), header, HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_fs, PreGameDraw.LIME)
	var stats: Dictionary = sp.get("base_stats", {})
	var raw: Dictionary = sp.get("raw_stats", {})
	var col_w := 92.0 * s
	var col_gap := 4.0 * s
	for i in 6:
		var stat: String = PreGameCatalog.STAT_ORDER[i]
		var cidx := i % 2
		var row := int(i / 2)
		var cx := rx + float(cidx) * (col_w + col_gap)
		var cy := rtop + 26.0 * s + float(row) * 14.0 * s
		draw_string(mono, Vector2(cx, cy), stat, HORIZONTAL_ALIGNMENT_LEFT, -1, row_fs, Color("9ec0cc"))
		var value := "%d pt" % int(stats.get(stat, 1))
		var val_col := PreGameDraw.PAPER
		if shift_math_mode:
			value = "%d (%d)" % [int(stats.get(stat, 1)), int(raw.get(stat, 0))]
			val_col = PreGameDraw.CYAN
		var val_w := mono.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, row_fs).x
		draw_string(mono, Vector2(cx + col_w - 6.0 * s - val_w, cy), value, HORIZONTAL_ALIGNMENT_LEFT, -1, row_fs, val_col)
		draw_line(Vector2(cx, cy + 3.0 * s), Vector2(cx + col_w - 4.0 * s, cy + 3.0 * s), Color(PreGameDraw.PAPER, 0.14), 1.0)
	draw_line(Vector2(rx, rtop + 64.0 * s), Vector2(rc_size.x * 0.5 - 8.0 * s, rtop + 64.0 * s), Color(PreGameDraw.PAPER, 0.22), 1.0)
	var bar_rect := Rect2(Vector2(rx, rtop + 74.0 * s), Vector2(rc_size.x - 16.0 * s, 28.0 * s))
	var bar_hover := _hover_id == "advance3"
	draw_rect(bar_rect, PreGameDraw.GOLD.lightened(0.12) if bar_hover else PreGameDraw.GOLD)
	draw_rect(bar_rect, PreGameDraw.INK, false, 1.0 * maxf(s, 0.8))
	draw_string(mono, Vector2(bar_rect.position.x + 5.0 * s, bar_rect.position.y + 3.0 * s + mono.get_ascent(pass_fs)), "EXPEDITION NATURE", HORIZONTAL_ALIGNMENT_LEFT, -1, pass_fs, PreGameDraw.INK)
	var gate_txt := "ROLLED AT GATE (R18-Q4)"
	var gate_fs := int(round(6.6 * s))
	var gate_w := mono.get_string_size(gate_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, gate_fs).x
	draw_string(mono, Vector2(bar_rect.end.x - 5.0 * s - gate_w, bar_rect.position.y + 14.5 * s + mono.get_ascent(gate_fs)), gate_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, gate_fs, Color(PreGameDraw.INK, 0.82))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var cb_size := Vector2(422.0, 44.0) * s
	var cb_center := Vector2(1041.0 * sx, 416.0 * sy)
	var cb_fill := PreGameDraw.PAPER if _hover_id == "confirm" else PreGameDraw.LIME
	var cxf := PreGameDraw.draw_card(self, cb_center, cb_size, -1.4, -10.0, cb_fill, PreGameDraw.INK, 2.0 * s, Vector2(6.0, 6.0) * s, Color.BLACK, [], PackedVector2Array())
	PreGameDraw.push_counter_skew(self, cxf, -10.0)
	var confirm_fs := int(round(15.0 * s))
	var confirm_text := "CONFIRM PROTAGONIST [Z / DOUBLE-CLICK]"
	var confirm_w := title.get_string_size(confirm_text, HORIZONTAL_ALIGNMENT_LEFT, -1, confirm_fs).x
	draw_string(title, Vector2(-confirm_w * 0.5, (title.get_ascent(confirm_fs) - title.get_descent(confirm_fs)) * 0.5 + 2.0 * s), confirm_text, HORIZONTAL_ALIGNMENT_LEFT, -1, confirm_fs, PreGameDraw.INK)
	draw_set_transform_matrix(Transform2D.IDENTITY)

# --- Drawing: Zona D deck -----------------------------------------------------

func _draw_atb_strip(sx: float, sy: float, s: float, idx: int) -> void:
	var sp := _current_spec()
	var ids: Array = sp.get("starter_moves", [])
	if idx >= ids.size():
		return
	var spec := PreGameCatalog.get_move_spec(str(ids[idx]))
	var rect := _strip_rect(sx, sy, s, idx)
	var active := idx == move_index
	var info := PreGameDraw.elem_info(int(spec.get("elem", 0)))
	var bg: Color = info.get("bg", PreGameDraw.CYAN)
	var fg_icon: Color = info.get("fg", Color.WHITE)
	var accents: Array[Dictionary] = [{"edge": "left", "size": 28.0 * s, "color": bg}]
	var fill := Color("1a2e3b") if active else Color("081624")
	var border := PreGameDraw.GOLD_BORDER if active else Color("1e3f54")
	var bw := 2.0 * s if active else 1.0 * s
	var shadow := Vector2(3.0, 3.0) * s if active else Vector2.ZERO
	var xf := PreGameDraw.draw_card(self, rect.get_center(), rect.size, 0.0, -10.0, fill, border, bw, shadow, Color.BLACK, accents, PackedVector2Array())
	draw_set_transform_matrix(xf)
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	var half_w := rect.size.x * 0.5
	var hfs := int(round(7.5 * s))
	draw_string(mono, Vector2(-half_w + 3.0 * s, -rect.size.y * 0.5 + 2.0 * s + mono.get_ascent(hfs)), str(idx + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, Color(fg_icon, 0.72))
	var tex := PreGameDraw.load_icon(str(info.get("svg_path", "")))
	if tex != null:
		draw_texture_rect(tex, Rect2(Vector2(-half_w + 7.0 * s, -6.0 * s), Vector2(14.0 * s, 14.0 * s)), false, fg_icon)
	PreGameDraw.push_counter_skew(self, xf, -10.0)
	var move_upper := str(spec.get("name", "")).to_upper()
	var nfs := int(round(13.0 * s))
	var max_nw := rect.size.x - 42.0 * s
	while nfs > 9 and body.get_string_size(move_upper, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > max_nw:
		nfs -= 1
	draw_string(body, Vector2(-half_w + 34.0 * s, -rect.size.y * 0.5 + 4.0 * s + body.get_ascent(nfs)),
		move_upper, HORIZONTAL_ALIGNMENT_LEFT, max_nw, nfs, PreGameDraw.PAPER)
	var pill_text := "BASIC" if idx == 0 else "STARTER"
	var pill_w := mono.get_string_size(pill_text, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs).x + 6.0 * s
	var pill_rect := Rect2(Vector2(-half_w + 34.0 * s, 7.0 * s), Vector2(pill_w, 12.0 * s))
	draw_rect(pill_rect, Color(PreGameDraw.PAPER, 0.08))
	draw_rect(pill_rect, Color(PreGameDraw.CYAN, 0.45), false, 1.0)
	draw_string(mono, Vector2(pill_rect.position.x + 3.0 * s, pill_rect.position.y + mono.get_ascent(hfs) + 1.0 * s), pill_text, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, PreGameDraw.CYAN)
	PreGameDraw.draw_atb_pips(self, Vector2(pill_rect.end.x + 6.0 * s, 10.0 * s), int(spec.get("atb", 1)), 3, Vector2(8.0, 5.0) * s, PreGameDraw.CYAN, Color(0.031, 0.055, 0.094, 0.35), -14.0)
	var mp := int(spec.get("mp", 0))
	var cost_text := "FREE" if mp <= 0 else "%dMP" % mp
	var cost_w := mono.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs).x
	draw_string(mono, Vector2(half_w - 8.0 * s - cost_w, 7.0 * s + mono.get_ascent(hfs) + 1.0 * s), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, hfs, PreGameDraw.GOLD if mp > 0 else PreGameDraw.TEXT_SUB)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_inspect(sx: float, sy: float, s: float) -> void:
	var sp := _current_spec()
	var spec := _current_move()
	var rect := _inspect_rect(sx, sy, s)
	var info := PreGameDraw.elem_info(int(spec.get("elem", 0)))
	var bg: Color = info.get("bg", Color("cbd5e1"))
	var is_light := bool(info.get("is_light", false))
	var fg := PreGameDraw.INK if is_light else Color.WHITE
	var desc_col := Color(PreGameDraw.INK, 0.90) if is_light else Color(1.0, 1.0, 1.0, 0.94)
	var clip := PackedVector2Array([Vector2(0.015, 0.0), Vector2(1.0, 0.0), Vector2(0.985, 1.0), Vector2(0.0, 1.0)])
	var xf := PreGameDraw.draw_card(self, rect.get_center(), rect.size, 0.7, 0.0, bg, PreGameDraw.INK, 1.6 * s, Vector2(5.0, 5.0) * s, Color.BLACK, [], clip)
	draw_set_transform_matrix(xf)
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	var title := PreGameDraw.title_font()
	var half_w := rect.size.x * 0.5
	var half_h := rect.size.y * 0.5
	var tex := PreGameDraw.load_icon(str(info.get("svg_path", "")))
	if tex != null:
		var wm_col := Color(0.0, 0.0, 0.0, 0.22) if is_light else Color(1.0, 1.0, 1.0, 0.26)
		draw_texture_rect(tex, Rect2(Vector2(half_w - 86.0 * s, -39.0 * s), Vector2(78.0 * s, 78.0 * s)), false, wm_col)
	var nfs := int(round(20.0 * s))
	var move_name := str(spec.get("name", "")).to_upper()
	draw_string(title, Vector2(-half_w + 14.0 * s, -half_h + 7.0 * s + title.get_ascent(nfs)), move_name, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, fg)
	var badge_x := -half_w + 14.0 * s + title.get_string_size(move_name, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x + 12.0 * s
	var badge_y := -half_h + 18.0 * s
	var type_key := str(spec.get("type_key", "physical"))
	var type_info: Dictionary = PreGameDraw.MOVE_TYPES.get(type_key, PreGameDraw.MOVE_TYPES["physical"])
	var type_tex := PreGameDraw.load_icon(str(type_info.get("svg_path", "")))
	PreGameDraw.draw_move_badge(self, Vector2(badge_x + 9.0 * s, badge_y), 19.0 * s, type_info.get("bg", PreGameDraw.PAPER), type_info.get("fg", PreGameDraw.INK), type_tex, -10.0)
	badge_x += 23.0 * s
	var range_key := str(spec.get("range_key", ""))
	if not range_key.is_empty():
		var range_info: Dictionary = PreGameDraw.MOVE_RANGES.get(range_key, PreGameDraw.MOVE_RANGES["melee"])
		var range_tex := PreGameDraw.load_icon(str(range_info.get("svg_path", "")))
		PreGameDraw.draw_move_badge(self, Vector2(badge_x + 9.0 * s, badge_y), 19.0 * s, range_info.get("bg", PreGameDraw.PAPER), range_info.get("fg", PreGameDraw.INK), range_tex, -10.0)
	var cfs := int(round(8.5 * s))
	var kind_val := int(spec.get("kind", 0))
	var dmg_type_val := int(spec.get("dmg_type", 0))
	var pow_val := float(spec.get("power", 0.0))
	var pow_col := Color("b5a5fe") if (dmg_type_val == 1 and kind_val != 3) else Color("f59e0b")
	var pow_txt := "POWER —" if (kind_val == 3 or pow_val <= 0.0) else "POWER ×%.1f" % pow_val
	var cx := half_w - 14.0 * s
	cx -= _draw_stat_chip_right(cx, -half_h + 10.0 * s, pow_txt, pow_col, PreGameDraw.INK, s, cfs) + 5.0 * s
	cx -= _draw_stat_chip_right(cx, -half_h + 10.0 * s, "%d MP" % int(spec.get("mp", 0)), Color("2563eb"), Color.WHITE, s, cfs) + 5.0 * s
	_draw_stat_chip_right(cx, -half_h + 10.0 * s, "%d ATB" % int(spec.get("atb", 0)), Color("0891b2"), Color.WHITE, s, cfs)
	draw_line(Vector2(-half_w + 14.0 * s, -half_h + 31.0 * s), Vector2(half_w - 14.0 * s, -half_h + 31.0 * s), Color(0.0, 0.0, 0.0, 0.14) if is_light else Color(1.0, 1.0, 1.0, 0.18), 1.0)
	var scale_attr := "MAG" if dmg_type_val == 1 else "STR"
	var base_stats: Dictionary = sp.get("base_stats", {})
	var raw_stats: Dictionary = sp.get("raw_stats", {})
	var attr_val := int(base_stats.get(scale_attr, 1))
	var raw_val := int(raw_stats.get(scale_attr, 0))
	var est_dmg := int(round(float(attr_val) * pow_val * 1.45))
	var windup := float(spec.get("windup", 0.0))
	var desc := ""
	if shift_math_mode:
		desc = "MATH OVERRIDE: Power ×%.2f (%d est) · 15-pt %s=%d (Raw %d) · Wind-up %.2fs" % [pow_val, est_dmg, scale_attr, attr_val, raw_val, windup]
	else:
		desc = "%s Wind-up: %.2fs · Scales %s" % [str(spec.get("text", "")), windup, scale_attr]
	var bfs := int(round(9.0 * s))
	PreGameDraw.draw_wrapped_text(self, body, Vector2(-half_w + 14.0 * s, -half_h + 35.0 * s), desc, bfs, desc_col, rect.size.x - 104.0 * s, 1.2)
	var cap_fs := int(round(7.5 * s))
	var cap_txt := "MATH OVERRIDE ACTIVE [SHIFT]" if shift_math_mode else "STARTER INSPECTOR (FULL TREE IN [A/TAB])"
	draw_string(mono, Vector2(-half_w + 14.0 * s, half_h - 6.0 * s), cap_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_fs, Color(fg.r, fg.g, fg.b, 0.78))
	var math_rect := _math_pill_rect(sx, sy, s)
	var spec_rect := _spec_pill_rect(sx, sy, s)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_pill_on_card(math_rect, "STANDARD" if shift_math_mode else "MATH [SHIFT]", _hover_id == "math", s)
	_draw_pill_on_card(spec_rect, "SPEC [D]", _hover_id == "spec", s)

func _draw_stat_chip_right(right_x: float, top_y: float, label: String, bg: Color, fg: Color, s: float, fs: int) -> float:
	var mono := PreGameDraw.mono_font()
	var w := mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 12.0 * s
	var h := 16.0 * s
	var rect := Rect2(Vector2(right_x - w, top_y), Vector2(w, h))
	draw_rect(rect, bg)
	draw_rect(rect, PreGameDraw.INK, false, 1.2)
	draw_string(mono, Vector2(rect.position.x + 6.0 * s, top_y + (h + mono.get_ascent(fs) - mono.get_descent(fs)) * 0.5 - 0.5 * s), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)
	return w

func _draw_pill_on_card(rect: Rect2, label: String, hover: bool, s: float) -> void:
	var bg := Color("132a3e") if hover else Color("081624")
	var border := PreGameDraw.CYAN if hover else Color("1e3f54")
	draw_rect(rect, bg)
	draw_rect(rect, border, false, 1.2)
	var mono := PreGameDraw.mono_font()
	var fs := int(round(7.5 * s))
	var w := mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(mono, Vector2(rect.get_center().x - w * 0.5, rect.position.y + (rect.size.y + mono.get_ascent(fs) - mono.get_descent(fs)) * 0.5 - 0.5 * s), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.PAPER)

func _draw_deck_header(sx: float, sy: float, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var fs := int(round(8.5 * s))
	var y := 574.0 * sy + mono.get_ascent(fs)
	draw_string(mono, Vector2(28.0 * sx, y), "STARTER KIT // BASIC ACTION: TACKLE + 2 SPECIES MOVES (C2)", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.LIME)
	var mid := "← → OR KEYS 1–3 · LEARN TREE LV.1/10/20 IN [A/TAB]"
	var mid_w := mono.get_string_size(mid, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(mono, Vector2(560.0 * sx - mid_w * 0.5, y), mid, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.TEXT_MUTED)
	var right := "[SHIFT] MATH OVERRIDE · [A / TAB] ADVANCED DOSSIER"
	var right_w := mono.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(mono, Vector2(1252.0 * sx - right_w, y), right, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.GOLD)

func _draw_deck(sx: float, sy: float, s: float) -> void:
	_draw_deck_header(sx, sy, s)
	for i in STARTER_COUNT:
		_draw_atb_strip(sx, sy, s, i)
	_draw_inspect(sx, sy, s)

# --- Drawing: footer ----------------------------------------------------------

func _draw_footer(sx: float, sy: float, s: float) -> void:
	var bar_rect := Rect2(28.0 * sx, 684.0 * sy, size.x - 56.0 * sx, 24.0 * sy)
	draw_rect(bar_rect, Color(0.012, 0.047, 0.086, 0.95))
	draw_line(bar_rect.position, Vector2(bar_rect.end.x, bar_rect.position.y), Color(0.698, 0.773, 0.796, 0.35), maxf(1.0, 1.0 * s))
	var x := 38.0 * sx
	var y := 690.0 * sy
	var fs := maxi(8, int(round(9.0 * s)))
	x += PreGameDraw.draw_kbd_pill(self, Vector2(x, y), "↑/↓", "PROTAGONIST (1–6)", fs) + 14.0 * s
	x += PreGameDraw.draw_kbd_pill(self, Vector2(x, y), "←/→", "MOVES (1–3)", fs) + 14.0 * s
	x += PreGameDraw.draw_kbd_pill(self, Vector2(x, y), "A / TAB", "ADVANCED DOSSIER", fs) + 14.0 * s
	x += PreGameDraw.draw_kbd_pill(self, Vector2(x, y), "R-CLICK / X", "BACK", fs) + 14.0 * s
	var mono := PreGameDraw.mono_font()
	var gold := "NO FIXED NATURE / NO COMBAT HP IN SELECTION (C1)"
	var gw := mono.get_string_size(gold, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(mono, Vector2(1242.0 * sx - gw, y + mono.get_ascent(fs)), gold, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PreGameDraw.GOLD)

# --- Input --------------------------------------------------------------------

func _hit_id(pos: Vector2) -> String:
	var sx := _scale_x()
	var sy := _scale_y()
	var s := minf(sx, sy)
	for idx in _protagonists.size():
		if _roster_item_rect(sx, sy, s, idx).has_point(pos):
			return "roster:%d" % idx
	for i in STARTER_COUNT:
		if _strip_rect(sx, sy, s, i).has_point(pos):
			return "strip:%d" % i
	if _menu_rect(sx, sy, s).has_point(pos):
		return "menu"
	if _adv_rect(sx, sy, s).has_point(pos):
		return "advanced"
	if _advance_bar_rect(sx, sy, s).has_point(pos):
		return "advance3"
	if _confirm_rect(sx, sy, s).has_point(pos):
		return "confirm"
	if _math_pill_rect(sx, sy, s).has_point(pos):
		return "math"
	if _spec_pill_rect(sx, sy, s).has_point(pos):
		return "spec"
	if _view_chip_rect(sx, sy, s).has_point(pos):
		return "view"
	return ""

func _cycle_char(delta: int) -> void:
	var count := maxi(_protagonists.size(), 1)
	char_index = (char_index + delta + count) % count
	move_index = 0
	character_selected.emit(char_index)
	queue_redraw()

func _cycle_move(delta: int) -> void:
	move_index = (move_index + delta + STARTER_COUNT) % STARTER_COUNT
	move_selected.emit(move_index)
	queue_redraw()

func _activate(hit: String, double_click: bool = false) -> bool:
	if hit.begins_with("roster:"):
		var idx := int(hit.get_slice(":", 1))
		if idx != char_index:
			char_index = clampi(idx, 0, maxi(_protagonists.size() - 1, 0))
			move_index = 0
			character_selected.emit(char_index)
			queue_redraw()
		elif double_click:
			confirm_protagonist.emit()
		return true
	if hit.begins_with("strip:"):
		var sidx := int(hit.get_slice(":", 1))
		if sidx != move_index:
			move_index = clampi(sidx, 0, STARTER_COUNT - 1)
			move_selected.emit(move_index)
			queue_redraw()
		elif double_click:
			confirm_protagonist.emit()
		return true
	match hit:
		"menu":
			back_to_menu.emit()
			return true
		"advanced":
			open_advanced_dossier.emit(2)
			return true
		"advance3":
			open_advanced_dossier.emit(3)
			return true
		"confirm":
			confirm_protagonist.emit()
			queue_redraw()
			return true
		"math":
			shift_math_mode = not shift_math_mode
			toggle_shift_math.emit()
			queue_redraw()
			return true
		"spec":
			open_skill_dossier.emit()
			return true
		"view":
			art_only = not art_only
			camera_action.emit("toggle_art")
			queue_redraw()
			return true
	return false

func handle_gui_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var hit := _hit_id(mm.position)
		if hit != _hover_id:
			_hover_id = hit
			queue_redraw()
		return false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return false
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_char(-1)
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_char(1)
			return true
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			back_to_menu.emit()
			return true
		if mb.button_index == MOUSE_BUTTON_LEFT:
			return _activate(_hit_id(mb.position), mb.double_click)
	return false

func handle_key_action(action: String) -> bool:
	match action.to_lower():
		"up", "char_prev", "protagonist_prev":
			_cycle_char(-1)
			return true
		"down", "char_next", "protagonist_next":
			_cycle_char(1)
			return true
		"left", "move_prev":
			_cycle_move(-1)
			return true
		"right", "move_next":
			_cycle_move(1)
			return true
		"1", "slot_1":
			_select_move(0)
			return true
		"2", "slot_2":
			_select_move(1)
			return true
		"3", "slot_3":
			_select_move(2)
			return true
		"confirm", "z", "enter", "ui_accept":
			confirm_protagonist.emit()
			return true
		"cancel", "x", "back", "ui_cancel":
			back_to_menu.emit()
			return true
		"dossier", "advanced", "a", "tab":
			open_advanced_dossier.emit(2)
			return true
		"skill_dossier", "d":
			open_skill_dossier.emit()
			return true
		"shift", "toggle_shift_math":
			shift_math_mode = not shift_math_mode
			toggle_shift_math.emit()
			queue_redraw()
			return true
		"view_toggle", "f":
			art_only = not art_only
			camera_action.emit("toggle_art")
			queue_redraw()
			return true
	return false

func _select_move(idx: int) -> void:
	var clamped := clampi(idx, 0, STARTER_COUNT - 1)
	if clamped == move_index:
		return
	move_index = clamped
	move_selected.emit(move_index)
	queue_redraw()
