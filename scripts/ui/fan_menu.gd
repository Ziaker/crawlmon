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

const FAN_W := 232.0
const FAN_H := 38.0
const FAN_STEP := 42.0
const DRAWER_W := 262.0
const ROW_H := 36.0
const MAX_ROWS := 5

var style := Style.FAN
var header := ""  ## Chapter label (FAN) or panel title (DRAWER).
var index := 0

var _texts: Array[String] = []
var _details: Array[String] = []
var _enabled: Array[bool] = []
var _accents: Array[Color] = []  ## Row text color when not highlighted (alpha 0 = default)
var _hilite: Array[Color] = []  ## Highlight color of the row (alpha 0 = the default green).
var _shield: Array[bool] = []  ## The row draws a shield icon instead of the diamond (D-272).
static var _title_font: Font
static var _body_font: Font


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
	for e in entries:
		if e is Dictionary:
			_texts.append(e["text"])
			_details.append(e.get("detail", ""))
			_enabled.append(e.get("enabled", true))
			_accents.append(e.get("accent", Color(0, 0, 0, 0)))
			_hilite.append(e.get("hilite", Color(0, 0, 0, 0)))
			_shield.append(e.get("shield", false))
		else:
			_texts.append(str(e))
			_details.append("")
			_enabled.append(true)
			_accents.append(Color(0, 0, 0, 0))
			_hilite.append(Color(0, 0, 0, 0))
			_shield.append(false)
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
		var alpha := 1.0 if _enabled[i] else 0.45
		if active:
			draw_rect(Rect2(8, y, DRAWER_W - 16, ROW_H - 3), LIME)
		else:
			draw_line(Vector2(10, y + ROW_H - 2), Vector2(DRAWER_W - 10, y + ROW_H - 2), Color("354758"), 1.0)
		var fg := INK if active else (CREAM if _accents[i].a == 0.0 else _accents[i])
		var detail_w := small.get_string_size(_details[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(small, Vector2(16, y + 23), _texts[i], HORIZONTAL_ALIGNMENT_LEFT, DRAWER_W - 40.0 - detail_w, 15, Color(fg, alpha))
		if _details[i] != "":
			BattleHud.text_right(self, small, DRAWER_W - 14, y + 22, _details[i], 10, Color(INK if active else GOLD, alpha))
	if _texts.size() > rows:
		BattleHud.text_right(self, small, DRAWER_W - 14, h - 3, "%d/%d" % [index + 1, _texts.size()], 9, Color(1, 1, 1, 0.5))
