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
var _accents: Array[Color] = []  ## Row text color when not highlighted (alpha 0 = default)
var _hilite: Array[Color] = []  ## Highlight color of the row (alpha 0 = the default green).
var _shield: Array[bool] = []  ## The row draws a shield icon instead of the diamond (D-272).
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
	_accents.clear()
	_hilite.clear()
	_shield.clear()
	_skills.clear()
	for e in entries:
		if e is Dictionary:
			_texts.append(e["text"])
			_details.append(e.get("detail", ""))
			_enabled.append(e.get("enabled", true))
			_accents.append(e.get("accent", Color(0, 0, 0, 0)))
			_hilite.append(e.get("hilite", Color(0, 0, 0, 0)))
			_shield.append(e.get("shield", false))
			_skills.append(e.get("skill", null))
		else:
			_texts.append(str(e))
			_details.append("")
			_enabled.append(true)
			_accents.append(Color(0, 0, 0, 0))
			_hilite.append(Color(0, 0, 0, 0))
			_shield.append(false)
			_skills.append(null)
	index = clampi(index if keep_index else 0, 0, maxi(_texts.size() - 1, 0))
	queue_redraw()
	moved.emit(index)


## Changes the small text of one row (e.g. the reason a command is unavailable).
func set_detail(i: int, text: String) -> void:
	if i < _details.size() and _details[i] != text:
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
	if i < _enabled.size() and _enabled[i] != value:
		_enabled[i] = value
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
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


func _draw() -> void:
	if style == Style.FAN:
		_draw_fan()
	else:
		_draw_drawer()


func _draw_fan() -> void:
	var small := body_font()
	draw_string(small, Vector2(6, 12), header, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LIME)
	for i in _texts.size():
		var active := i == index
		var x := i * 8.0 + (9.0 if active else 0.0)
		var r := Rect2(x, 22 + i * FAN_STEP, FAN_W, FAN_H)
		_slant(Rect2(r.position + Vector2(5, 5), r.size), 8.0, Color(0, 0, 0, 0.45))
		var blue: bool = _hilite[i].a > 0.0
		_slant(r, 8.0, (_hilite[i] if blue else LIME) if active else Color(INK, 0.92))
		var fg := (Color.WHITE if blue else INK) if active else Color("e4e9e4")
		var alpha := 1.0 if _enabled[i] else 0.4
		var cy := r.position.y + r.size.y * 0.5
		if _shield[i]:
			var sx := r.position.x + 24
			draw_colored_polygon(PackedVector2Array([
				Vector2(sx - 9, cy - 9), Vector2(sx + 9, cy - 9), Vector2(sx + 9, cy + 1),
				Vector2(sx, cy + 10), Vector2(sx - 9, cy + 1)]), Color(Color.WHITE if active else GUARD_BLUE, alpha))
		else:
			draw_colored_polygon(PackedVector2Array([
				Vector2(r.position.x + 24, cy - 8), Vector2(r.position.x + 32, cy),
				Vector2(r.position.x + 24, cy + 8), Vector2(r.position.x + 16, cy)]), Color(INK if active else CORAL, alpha))
		draw_string(title_font(), Vector2(r.position.x + 44, cy + 9), _texts[i].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(fg, alpha))
		if _details[i] != "":
			BattleHud.text_right(self, small, r.end.x - 18, cy + 4, _details[i], 10, Color(fg, 0.75 * alpha))


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