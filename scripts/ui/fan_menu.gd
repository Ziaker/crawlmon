class_name FanMenu
extends Control
## Command list for the battle HUD. FAN style is the staggered Fight / Itens /
## Evade / Tactics stack; DRAWER style is the panel used by sub-menus (moves,
## items, targets, tactics). Same API as MenuList: Z (confirm) picks, X (menu)
## cancels. Entries are Strings or {"text", "enabled", "detail"}.

signal chosen(index: int)
signal cancelled
signal moved(index: int)
signal side(direction: int)  ## Left (-1) / right (+1) on the highlighted row.
signal side_chosen(index: int)  ## D-1236: Z on a row of the side fan (EMPLOY / SUMMON).
signal side_closed  ## D-1236: the side fan was closed with left or X.

enum Style { FAN, DRAWER }

const LIME := Color("d7fd6a")
const CORAL := Color("ff624f")
const GOLD := Color("f7cb78")
const INK := Color("080e18")
const CREAM := Color("f0eedf")
const NAVY := Color("0a1929")
const GUARD_BLUE := Color("1f6fd6")  ## D-272: the Guard block (flat blue instead of the green highlight).
const MoveIcons = preload("res://scripts/ui/move_icons.gd")

const FAN_W := 232.0
const FAN_H := 38.0
const FAN_STEP := 42.0
const DRAWER_W := 262.0
const ROW_H := 36.0
const MAX_ROWS := 5

var style := Style.FAN
var header := ""  ## Chapter label (FAN) or panel title (DRAWER).
var note := ""  ## Extra line at the bottom of the drawer (pages, hints).
var index := 0

var _texts: Array[String] = []
var _details: Array[String] = []
var _enabled: Array[bool] = []
var _ids: Array[String] = []  ## "id" of each entry ("" when it has none): rows are found by id, never by position.
var _accents: Array[Color] = []  ## Row text color when not highlighted (alpha 0 = default)
var _hop_t := 0.0
var _arrow: Array[Color] = []  ## Creator (2026-11-17): a slanted tab OUTSIDE the block, same height as it (alpha 0 = none).
var _hilite: Array[Color] = []  ## Highlight color of the row (alpha 0 = the default green).
var _shield: Array[bool] = []  ## The row draws a shield icon instead of the diamond (D-272).
var _fuse_row: Array[bool] = []  ## D-1296: the FIGHT row while the burst fuse is lit (orange body, flames, fuse on top).
const FUSE_ORANGE := Color("ff8a2b")  ## D-1296 (creator: "ff8a2b").
const BurstFuseFx = preload("res://scripts/ui/burst_fuse_fx.gd")
var _fx: BurstFuseFx
## D-1236: side fan. A second stack of slanted blocks born to the right of one row of the main fan
## (the alternative tab of TACTICS). While it is open the main fan stays visible, dimmed, and the
## side fan takes the input. Navigating and closing it never spends anything.
const SIDE_GAP := 16.0  ## Distance between the main fan and the side fan.
const SIDE_TEXT_GAP := 18.0  ## Minimum room between the title of a block and its detail text.
const SIDE_DIM := 0.45  ## Opacity of the main fan while the side fan is open.
var side_open := false
var side_index := 0
var _side_anchor := 0  ## Row of the main fan the side fan was opened from.
var _side_texts: Array[String] = []
var _side_details: Array[String] = []
var _side_enabled: Array[bool] = []
static var _title_font: Font
static var _body_font: Font
var _skills: Array = []
static var _icon_cache: Dictionary = {}


static func _get_icon(path: String) -> Texture2D:
	if _icon_cache.has(path):
		return _icon_cache[path]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_icon_cache[path] = tex
		return tex
	return null



static func title_font() -> Font:
	if _title_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Impact", "Haettenschweiler", "Arial Black"])
		_title_font = f
	return _title_font


static func body_font() -> Font:
	if _body_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Arial", "Segoe UI"])
		f.font_weight = 800
		_body_font = f
	return _body_font


func _init() -> void:
	custom_minimum_size = Vector2(DRAWER_W, 250)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_entries(entries: Array, keep_index := false) -> void:
	_texts.clear()
	_details.clear()
	_enabled.clear()
	_ids.clear()
	_accents.clear()
	_hilite.clear()
	_arrow.clear()
	_shield.clear()
	_fuse_row.clear()
	_skills.clear()
	for e in entries:
		_fuse_row.append(e is Dictionary and bool(e.get("fuse", false)))
		if e is Dictionary:
			_texts.append(e["text"])
			_details.append(e.get("detail", ""))
			_enabled.append(e.get("enabled", true))
			_ids.append(String(e.get("id", "")))
			_accents.append(e.get("accent", Color(0, 0, 0, 0)))
			_hilite.append(e.get("hilite", Color(0, 0, 0, 0)))
			_arrow.append(e.get("arrow", Color(0, 0, 0, 0)))
			_shield.append(e.get("shield", false))
			_skills.append(e.get("skill", null))
		else:
			_texts.append(str(e))
			_details.append("")
			_enabled.append(true)
			_ids.append("")
			_accents.append(Color(0, 0, 0, 0))
			_hilite.append(Color(0, 0, 0, 0))
			_arrow.append(Color(0, 0, 0, 0))
			_shield.append(false)
			_skills.append(null)
	side_open = false  # D-1236: new entries always start with the side fan closed.
	index = clampi(index if keep_index else 0, 0, maxi(_texts.size() - 1, 0))
	queue_redraw()
	moved.emit(index)


## Row of the entry with that "id" (-1 when there is none): callers never depend on the row order.
func row_of(id: String) -> int:
	return _ids.find(id)


## "id" of a row ("" when the entry has none).
func id_at(i: int) -> String:
	return _ids[i] if i >= 0 and i < _ids.size() else ""


## Changes the small text of one row (e.g. the reason a command is unavailable).
func set_detail(i: int, text: String) -> void:
	if i >= 0 and i < _details.size() and _details[i] != text:
		_details[i] = text
		queue_redraw()


## Highlights a row (used to reopen a menu on the last choice).
func select(i: int) -> void:
	if _texts.is_empty():
		return
	index = clampi(i, 0, _texts.size() - 1)
	queue_redraw()
	moved.emit(index)


func set_enabled(i: int, value: bool) -> void:
	if i >= 0 and i < _enabled.size() and _enabled[i] != value:
		_enabled[i] = value
		queue_redraw()


## D-1236: opens the side fan next to the highlighted row. Entries are {"text", "detail", "enabled"}.
func open_side(entries: Array) -> void:
	_side_texts.clear()
	_side_details.clear()
	_side_enabled.clear()
	for e in entries:
		_side_texts.append(String(e["text"]))
		_side_details.append(String(e.get("detail", "")))
		_side_enabled.append(bool(e.get("enabled", true)))
	if _side_texts.is_empty():
		return
	_side_anchor = index
	side_index = 0
	side_open = true
	queue_redraw()


func close_side() -> void:
	if side_open:
		side_open = false
		queue_redraw()


func set_side_enabled(i: int, value: bool) -> void:
	if i < _side_enabled.size() and _side_enabled[i] != value:
		_side_enabled[i] = value
		queue_redraw()


func set_side_detail(i: int, text: String) -> void:
	if i < _side_details.size() and _side_details[i] != text:
		_side_details[i] = text
		queue_redraw()


## Width of the side blocks: the longest "title + gap + detail", the same for every block, so the
## detail text never touches the title whatever it says (D-1236).
func side_width() -> float:
	var w := 0.0
	for i in _side_texts.size():
		var tw := title_font().get_string_size(_side_texts[i].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
		var dw := body_font().get_string_size(_side_details[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		w = maxf(w, 44.0 + tw + SIDE_TEXT_GAP + dw + 18.0)
	return ceilf(w)


func _side_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") or event.is_action_pressed("ui_left"):
		close_side()
		side_closed.emit()
	elif event.is_action_pressed("ui_down"):
		side_index = posmod(side_index + 1, _side_texts.size())
		queue_redraw()
	elif event.is_action_pressed("ui_up"):
		side_index = posmod(side_index - 1, _side_texts.size())
		queue_redraw()
	elif event.is_action_pressed("confirm"):
		if _side_enabled[side_index]:
			side_chosen.emit(side_index)
	elif not event.is_action_pressed("ui_right"):
		return
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if side_open and style == Style.FAN:
		_side_input(event)
		return
	if event.is_action_pressed("menu"):
		cancelled.emit()
	elif _texts.is_empty():
		return
	elif event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("confirm"):
		if _enabled[index]:
			chosen.emit(index)
	elif event.is_action_pressed("ui_left"):
		side.emit(-1)
	elif event.is_action_pressed("ui_right"):
		side.emit(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _move(step: int) -> void:
	index = posmod(index + step, _texts.size())
	queue_redraw()
	moved.emit(index)


func _slant(r: Rect2, skew: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)]), color)


## D-1296: lights the burst fuse over the row marked "fuse" for `seconds` REAL seconds.
func fuse_start(seconds: float) -> void:
	if _fx == null:
		_fx = BurstFuseFx.new()
		add_child(_fx)
	_fx.start(seconds)
	queue_redraw()


## D-1296: the fuse is over. `cut` = the player clicked FIGHT (small explosion over its block). Call it BEFORE
## set_entries() changes the rows, so the block it plays over is still known.
func fuse_end(cut: bool) -> void:
	if _fx == null:
		return
	var row := _fuse_row.find(true)
	_fx.stop(_row_rect(row) if row >= 0 else Rect2(), cut)
	queue_redraw()


func _row_rect(i: int) -> Rect2:
	var x := i * 8.0 + (9.0 if i == index else 0.0)
	return Rect2(x, 22 + i * FAN_STEP, FAN_W, FAN_H)


func _process(delta: float) -> void:
	_hop_t += delta  # own clock (not wall time), so a recorded movie is deterministic
	if _fx != null and _fx.busy():
		_fx.advance(delta / maxf(Engine.time_scale, 0.01))  # real time: the burst slow-motion must not slow the fuse
		queue_redraw()
	if style == Style.FAN and not side_open and visible and index >= 0 and index < _arrow.size() and _arrow[index].a > 0.0:
		queue_redraw()  # the highlighted row's tab hops


func _draw() -> void:
	if style == Style.FAN:
		_draw_fan()
	else:
		_draw_drawer()
		if _fx != null:  # D-1296: the click opens the move list (drawer): the explosion still plays over it
			_fx.draw_over(self, Rect2())
			_fx.draw_pop(self)


func _draw_fan() -> void:
	var small := body_font()
	draw_string(small, Vector2(6, 12), header, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LIME)
	var dim := SIDE_DIM if side_open else 1.0  # D-1236: the main fan steps back while the side fan is open.
	for i in _texts.size():
		var active := i == index
		var x := i * 8.0 + (9.0 if active else 0.0)
		var r := Rect2(x, 22 + i * FAN_STEP, FAN_W, FAN_H)
		_slant(Rect2(r.position + Vector2(5, 5), r.size), 8.0, Color(0, 0, 0, 0.45 * dim))
		var row_col: Color = _hilite[i] if _hilite[i].a > 0.0 else LIME  # the main blocks keep their own color; the SIDE fan options take the tab color
		var blue: bool = row_col.get_luminance() < 0.35  # dark body: white text and glyph
		var on_fuse: bool = i < _fuse_row.size() and _fuse_row[i] and _fx != null and _fx.active
		var body: Color = row_col if active else Color(INK, 0.92)
		if on_fuse:
			body = FUSE_ORANGE  # D-1296: the FIGHT block is orange for as long as the fuse burns, highlighted or not
		body.a *= dim
		_slant(r, 8.0, body)
		if on_fuse:
			_fx.draw_flames(self, r)
		var fg := (Color.WHITE if blue else INK) if active else Color("e4e9e4")
		var alpha := (1.0 if _enabled[i] else 0.4) * dim
		var cy := r.position.y + r.size.y * 0.5
		if _shield[i]:
			var sx := r.position.x + 24
			draw_colored_polygon(PackedVector2Array([
				Vector2(sx - 9, cy - 9), Vector2(sx + 9, cy - 9), Vector2(sx + 9, cy + 1),
				Vector2(sx, cy + 10), Vector2(sx - 9, cy + 1)]), Color(Color.WHITE if active else GUARD_BLUE, alpha))
		else:
			draw_colored_polygon(PackedVector2Array([
				Vector2(r.position.x + 24, cy - 8), Vector2(r.position.x + 32, cy),
				Vector2(r.position.x + 24, cy + 8), Vector2(r.position.x + 16, cy)]), Color((Color.WHITE if blue else INK) if active else CORAL, alpha))
		draw_string(title_font(), Vector2(r.position.x + 44, cy + 9), _texts[i].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(fg, alpha))
		if _details[i] != "":
			BattleHud.text_right(self, small, r.end.x - 18, cy + 4, _details[i], 10, Color(fg, 0.75 * alpha))
		if i < _arrow.size() and _arrow[i].a > 0.0 and not side_open:
			var hop := 0.0
			if active:  # Creator (2026-11-17): the tab keeps hopping while its row is highlighted (provisional: 5 px to the left, 2 hops/s)
				hop = absf(sin(_hop_t * TAU * 1.0)) * 5.0  # to the LEFT (creator), not up
			var tab := Rect2(r.end.x + 6.0 - hop, r.position.y, 22.0, r.size.y)  # same height and slant as the block, outside it
			_slant(Rect2(tab.position + Vector2(3, 3), tab.size), 8.0, Color(0, 0, 0, 0.45 * dim))
			_slant(tab, 8.0, Color(_arrow[i], dim))  # exact arrow color, never faded by the row's enabled state
	if _fx != null:  # D-1296: the 3D fuse and its sparks on top of the rows; the pop/explosion of the click last
		var fr := _fuse_row.find(true)
		if fr >= 0 and _fx.active:
			_fx.draw_over(self, _row_rect(fr))
		else:
			_fx.draw_over(self, Rect2())
		_fx.draw_pop(self)
	if side_open:
		_draw_side()


## D-1236: the side fan. Same block as the main fan (slant, shadow, diamond, title, detail), born to
## the right of the anchor row and centred on it.
func _draw_side() -> void:
	var small := body_font()
	var w := side_width()
	var ax := _side_anchor * 8.0 + 9.0 + FAN_W + SIDE_GAP
	var ay := 22.0 + _side_anchor * FAN_STEP - (_side_texts.size() - 1) * FAN_STEP * 0.5
	var side_col: Color = _arrow[_side_anchor] if _side_anchor >= 0 and _side_anchor < _arrow.size() and _arrow[_side_anchor].a > 0.0 else LIME
	for i in _side_texts.size():
		var active := i == side_index
		var r := Rect2(ax + i * 8.0 + (9.0 if active else 0.0), ay + i * FAN_STEP, w, FAN_H)
		_slant(Rect2(r.position + Vector2(5, 5), r.size), 8.0, Color(0, 0, 0, 0.45))
		_slant(r, 8.0, side_col if active else Color(INK, 0.92))  # creator 2026-11-17: the Summon/Employ options are aqua (the tab color), not lime
		var fg := INK if active else Color("e4e9e4")
		var alpha := 1.0 if _side_enabled[i] else 0.4
		var cy := r.position.y + r.size.y * 0.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(r.position.x + 24, cy - 8), Vector2(r.position.x + 32, cy),
			Vector2(r.position.x + 24, cy + 8), Vector2(r.position.x + 16, cy)]), Color(INK if active else CORAL, alpha))
		draw_string(title_font(), Vector2(r.position.x + 44, cy + 9), _side_texts[i].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(fg, alpha))
		if _side_details[i] != "":
			BattleHud.text_right(self, small, r.end.x - 18, cy + 4, _side_details[i], 10, Color(fg, 0.75 * alpha))


func _draw_drawer() -> void:
	var small := body_font()
	var rows := mini(_texts.size(), MAX_ROWS)
	var h := 56.0 + rows * ROW_H + 10.0
	draw_rect(Rect2(8, 8, DRAWER_W, h), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(0, 0, DRAWER_W, h), NAVY)
	draw_rect(Rect2(0, 0, DRAWER_W, 5), LIME)
	draw_rect(Rect2(0, 0, DRAWER_W, h), Color("7c8b87"), false, 1.0)
	_slant(Rect2(12, 14, 86, 20), 5.0, LIME)
	draw_string(small, Vector2(22, 29), "‹ VOLTAR (X)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)
	draw_string(small, Vector2(110, 29), header, HORIZONTAL_ALIGNMENT_LEFT, 146, 10, LIME)
	var first := clampi(index - rows + 1, 0, maxi(_texts.size() - rows, 0)) if index >= rows else 0
	for n in rows:
		var i := first + n
		var y := 48.0 + n * ROW_H
		var active := i == index
		var enabled := _enabled[i]
		var alpha := 1.0 if enabled else 0.32
		var sk: Skill = _skills[i] if i < _skills.size() else null

		# Element color stripe (D-438: neutral/physical uses Color("cbd5e1"))
		var elem_col := Color("cbd5e1")
		if sk != null:
			elem_col = StatusScreen.ELEMENT_COLORS.get(sk.element, BattleFx.COLORS.get(sk.element, Color("cbd5e1")))

		if active:
			draw_rect(Rect2(8, y, DRAWER_W - 16, ROW_H - 3), LIME if enabled else Color(0.2, 0.25, 0.3, 0.8))
			draw_rect(Rect2(8, y, 4, ROW_H - 3), elem_col)
		else:
			if sk != null:
				draw_rect(Rect2(8, y, DRAWER_W - 16, ROW_H - 3), Color(0.04, 0.08, 0.12, 0.6 if enabled else 0.3))
			draw_rect(Rect2(8, y, 4, ROW_H - 3), Color(elem_col, alpha))
			draw_line(Vector2(10, y + ROW_H - 2), Vector2(DRAWER_W - 10, y + ROW_H - 2), Color("354758"), 1.0)

		var fg := (INK if enabled else Color("64748b")) if active else (CREAM if _accents[i].a == 0.0 else _accents[i])

		# Icons on the right side of the row: Element, Type, Range (D-438, D-1145)
		var icons_w := 0.0
		if sk != null:
			var ic_y := y + 3.0
			var ic_sz := 13.0
			var ic_gap := 3.0
			var icons: Array[Dictionary] = []

			# Icon 1: Element SVG (D-438, D-440)
			var elem_ic := BattleHud.element_icon(sk.element)
			if elem_ic != null:
				icons.append({"tex": elem_ic, "bg": Color(0, 0, 0, 0.5 * alpha), "fg": Color(elem_col if not active else INK, alpha)})

			# Icon 2: Type SVG (physical, magical, guard, dodge; pure status has none)
			var type_name := sk.type_icon_name()
			if not type_name.is_empty():
				var type_col := Color("0ea5e9")
				if type_name == "physical":
					type_col = Color("ef4444")
				elif type_name == "guard":
					type_col = Color("cbd5e1")
				elif type_name == "dodge":
					type_col = Color("fcb900")
				elif type_name == "status":  # D-1190: white, chosen by the creator
					type_col = Color("ffffff")
				elif type_name == "field":  # D-1190: green
					type_col = Color("22c55e")
				var badge_col := type_col
				if sk.data != null and sk.data.icon_color.a > 0.0:
					badge_col = sk.data.icon_color
				var type_ic := _get_icon("res://assets/ui/icons/move_types/%s.svg" % type_name)
				if sk.data != null:
					var move_ic: Texture2D = MoveIcons.for_move(sk.data.id)
					if move_ic != null:
						type_ic = move_ic
				var type_fg := INK if type_name == "status" else Color.WHITE
				if type_ic != null:
					icons.append({"tex": type_ic, "bg": Color(badge_col, 0.7 * alpha), "fg": Color(type_fg if not active else INK, alpha)})

			# Icon 3: Range SVG (melee, mid, long, area; pure status has none)
			var range_name := ""
			if sk.kind != Skill.Kind.STATUS:
				range_name = "mid"
				if sk.is_aoe:
					range_name = "area"
				elif sk.kind == Skill.Kind.MELEE:
					range_name = "melee"
				elif sk.kind == Skill.Kind.PROJECTILE:
					range_name = "long"
			if not range_name.is_empty():
				var range_ic := _get_icon("res://assets/ui/icons/range/%s.svg" % range_name)
				if range_ic != null:
					icons.append({"tex": range_ic, "bg": Color(0.9, 0.95, 1.0, 0.8 * alpha), "fg": Color("080e18", alpha)})

			var icon_count := icons.size()
			if icon_count > 0:
				var rx := DRAWER_W - 16.0 - (float(icon_count) * ic_sz + float(icon_count - 1) * ic_gap)
				icons_w = float(icon_count) * ic_sz + float(icon_count - 1) * ic_gap + 4.0
				for icon in icons:
					draw_rect(Rect2(rx, ic_y, ic_sz, ic_sz), icon["bg"])
					draw_texture_rect(icon["tex"], Rect2(rx + 1, ic_y + 1, ic_sz - 2, ic_sz - 2), false, icon["fg"])
					rx += ic_sz + ic_gap

		# Move Name
		var name_size := 14
		var max_w := DRAWER_W - 20.0 - icons_w
		while name_size > 10 and small.get_string_size(_texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > max_w:
			name_size -= 1
		draw_string(small, Vector2(16, y + 17), _texts[i], HORIZONTAL_ALIGNMENT_LEFT, max_w, name_size, Color(fg, alpha))

		# Detail line (ATB · MP | target forecast)
		if _details[i] != "":
			var det_col := (INK if enabled else Color("475569")) if active else (GOLD if enabled else Color("64748b"))
			draw_string(small, Vector2(16, y + 30), _details[i], HORIZONTAL_ALIGNMENT_LEFT, DRAWER_W - 26.0, 9, Color(det_col, alpha * 0.95))
	if note != "":
		draw_string(small, Vector2(14, h - 3), note, HORIZONTAL_ALIGNMENT_LEFT, DRAWER_W - 70, 9, LIME)
	if _texts.size() > rows:
		BattleHud.text_right(self, small, DRAWER_W - 14, h - 3, "%d/%d" % [index + 1, _texts.size()], 9, Color(1, 1, 1, 0.5))