class_name PreGameViewBoot
extends Control

signal title_entered
signal menu_action(action_id: String)

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")
const TitleV2Draw = preload("res://scripts/ui/pre_game/pre_game_title_v2_draw.gd")

## D-1265: title/menu use the v2 look (3D world is a separate node behind this view).
var use_v2: bool = true
## D-1265: leader species of the save (icon stamped on the save card); empty = no card.
var save_leader_id: String = ""
var save_info: Dictionary = {}  # level, respect, cascos, play_seconds
var _t: float = 0.0
var _menu_t: float = 0.0

const MENU_COUNT: int = 4
const PLAY_COUNT: int = 3
## D-1226: menu buttons scaled 1.5x (2x covered the 3D model; creator asked for "um pouco" menos).
const MENU_K: float = 1.5

var view_mode: String = "title"
var menu_index: int = 0
var play_drawer_open: bool = false
var play_index: int = 0
var save_available: bool = false
var concept_label_text: String = "CONCEPT A: STATUS SPIRES"
var loading_label: String = "PREPARING THREADED LOAD..."
var loading_progress: float = 0.0
var quit_confirm_index: int = 1

var _hover_id: String = ""
var _hits: Array[Dictionary] = []
var _drawer_t: float = 0.0
var _reduce_motion: bool = false
var _drawer_xform: Transform2D = Transform2D.IDENTITY
var _drawer_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	set_process(true)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		_reduce_motion = bool(gs.get_meta("reduce_camera_motion", false))
	_drawer_t = 1.0 if play_drawer_open else 0.0
	# D-1204: a capture (--shot=) must not catch the intro animation mid-slide.
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if str(a).begins_with("--shot="):
			_reduce_motion = true
			_t = 10.0
			_menu_t = 10.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover_id = ""
		queue_redraw()
	elif what == NOTIFICATION_RESIZED:
		queue_redraw()


func _process(delta: float) -> void:
	if use_v2 and view_mode in ["title", "menu", "quit_modal"]:
		_t += delta
		_menu_t += delta
		queue_redraw()
	if view_mode == "loading":
		queue_redraw()
	var target: float = 1.0 if (play_drawer_open and view_mode == "menu") else 0.0
	if _reduce_motion:
		if not is_equal_approx(_drawer_t, target):
			_drawer_t = target
			queue_redraw()
		return
	if not is_equal_approx(_drawer_t, target):
		_drawer_t = move_toward(_drawer_t, target, delta * 7.5)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if handle_gui_input(event):
		accept_event()


func set_state(p_mode: String, p_menu_idx: int, p_drawer_open: bool, p_play_idx: int,
		p_save_available: bool) -> void:
	if p_mode in ["title", "menu", "loading", "quit_modal"]:
		if p_mode == "menu" and view_mode != "menu" and view_mode != "quit_modal":
			_menu_t = -0.4 if not _reduce_motion else 10.0
		if p_mode == "title" and view_mode != "title":
			_t = 0.0 if not _reduce_motion else 10.0
		view_mode = p_mode
	menu_index = clampi(p_menu_idx, 0, MENU_COUNT - 1)
	play_drawer_open = p_drawer_open
	play_index = clampi(p_play_idx, 0, PLAY_COUNT - 1)
	save_available = p_save_available
	_drawer_t = 1.0 if (p_drawer_open and view_mode == "menu") else 0.0
	_hover_id = ""
	queue_redraw()


func handle_gui_input(event: InputEvent) -> bool:
	if view_mode == "loading":
		return true
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var hovered := _hit_at(mm.position)
		if hovered != _hover_id:
			_hover_id = hovered
			_sync_focus_from_hover(hovered)
			queue_redraw()
		if not hovered.is_empty():
			return true
		if view_mode == "quit_modal":
			return true
		if play_drawer_open and view_mode == "menu" and _is_over_drawer(mm.position):
			return true
		return false

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if view_mode == "title":
				title_entered.emit()
				return true
			if view_mode == "quit_modal":
				var modal_hit := _hit_at(mb.position)
				if modal_hit == "quit_cancel" or modal_hit == "quit_confirm":
					_activate(modal_hit)
				return true
			var hit := _hit_at(mb.position)
			if not hit.is_empty():
				_activate(hit)
				return true
			if play_drawer_open and view_mode == "menu" and _is_over_drawer(mb.position):
				return true
			return false
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if view_mode == "quit_modal":
				view_mode = "menu"
				quit_confirm_index = 1
				_hover_id = ""
				queue_redraw()
				return true
			if view_mode == "menu" and play_drawer_open:
				play_drawer_open = false
				play_index = 0
				_hover_id = ""
				queue_redraw()
				return true
	return false


func handle_key_action(action: String) -> bool:
	match view_mode:
		"title":
			title_entered.emit()
			return true
		"loading":
			return true
		"quit_modal":
			return _handle_quit_key(action)
		"menu":
			return _handle_menu_key(action)
	return false


func _handle_menu_key(action: String) -> bool:
	match action:
		"up":
			if play_drawer_open:
				play_index = posmod(play_index - 1, PLAY_COUNT)
			else:
				menu_index = posmod(menu_index - 1, MENU_COUNT)
			queue_redraw()
			return true
		"down":
			if play_drawer_open:
				play_index = posmod(play_index + 1, PLAY_COUNT)
			else:
				menu_index = posmod(menu_index + 1, MENU_COUNT)
			queue_redraw()
			return true
		"confirm":
			if play_drawer_open:
				_activate("drawer:%d" % play_index)
			else:
				_activate("menu:%d" % menu_index)
			return true
		"back":
			if play_drawer_open:
				play_drawer_open = false
				play_index = 0
				queue_redraw()
			return true
	return false


func _handle_quit_key(action: String) -> bool:
	match action:
		"up":
			quit_confirm_index = 0
			queue_redraw()
			return true
		"down":
			quit_confirm_index = 1
			queue_redraw()
			return true
		"confirm":
			_activate("quit_confirm" if quit_confirm_index == 1 else "quit_cancel")
			return true
		"back":
			view_mode = "menu"
			quit_confirm_index = 1
			_hover_id = ""
			queue_redraw()
			return true
	return true


func _activate(hit_id: String) -> void:
	if hit_id.begins_with("menu:"):
		var idx := clampi(int(hit_id.substr(5)), 0, MENU_COUNT - 1)
		menu_index = idx
		var item: Dictionary = PreGameCatalog.MENU_ITEMS[idx]
		var action_id := str(item.get("id", ""))
		match action_id:
			"play":
				play_drawer_open = true
				play_index = 0
				queue_redraw()
			"settings", "credits":
				play_drawer_open = false
				queue_redraw()
				menu_action.emit(action_id)
			"quit":
				play_drawer_open = false
				view_mode = "quit_modal"
				quit_confirm_index = 1
				queue_redraw()
		return
	if hit_id.begins_with("drawer:"):
		var play_idx := clampi(int(hit_id.substr(7)), 0, PLAY_COUNT - 1)
		play_index = play_idx
		match play_idx:
			0:
				menu_action.emit("new_game")
			1:
				if save_available:
					menu_action.emit("continue")
			2:
				menu_action.emit("new_expedition")
		queue_redraw()
		return
	match hit_id:
		"drawer_back":
			play_drawer_open = false
			play_index = 0
			queue_redraw()
		"quit_cancel":
			view_mode = "menu"
			quit_confirm_index = 1
			queue_redraw()
		"quit_confirm":
			menu_action.emit("quit_confirmed")
		"title_press":
			title_entered.emit()


func _sync_focus_from_hover(hovered: String) -> void:
	if hovered.begins_with("menu:") and not play_drawer_open:
		menu_index = clampi(int(hovered.substr(5)), 0, MENU_COUNT - 1)
	elif hovered.begins_with("drawer:"):
		play_index = clampi(int(hovered.substr(7)), 0, PLAY_COUNT - 1)
	elif hovered == "quit_cancel":
		quit_confirm_index = 0
	elif hovered == "quit_confirm":
		quit_confirm_index = 1


func _hit_at(mouse_pos: Vector2) -> String:
	for i in range(_hits.size() - 1, -1, -1):
		var hit: Dictionary = _hits[i]
		var base_xform: Transform2D = hit["xform"]
		var hit_size: Vector2 = hit["size"]
		if PreGameDraw.hit_test(mouse_pos, base_xform, hit_size):
			return str(hit["id"])
	return ""


func _is_over_drawer(mouse_pos: Vector2) -> bool:
	if _drawer_size == Vector2.ZERO:
		return false
	return PreGameDraw.hit_test(mouse_pos, _drawer_xform, _drawer_size)


func _add_hit(hit_id: String, base_xform: Transform2D, hit_size: Vector2) -> void:
	_hits.append({"id": hit_id, "xform": base_xform, "size": hit_size})


func _fs(base_size: float, s: float) -> int:
	return maxi(6, int(round(base_size * s)))


func _no_accents() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	return out


func _accents(edge: String, band: float, color: Color) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if edge.is_empty() or band <= 0.0:
		return out
	out.append({"edge": edge, "size": band, "color": color})
	return out


func _draw_centered(font: Font, text: String, font_size: int, color: Color, width: float) -> void:
	var baseline := (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(-width * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, width,
		font_size, color)


func _nested_card(parent_xform: Transform2D, local_center: Vector2, card_size: Vector2,
		rot_deg: float, skew_deg: float, fill: Color, border_col: Color, border_w: float,
		shadow_offset: Vector2, shadow_col: Color, accents: Array[Dictionary] = [],
		clip_norm: PackedVector2Array = PackedVector2Array()) -> Transform2D:
	var rot := Transform2D(deg_to_rad(rot_deg), Vector2.ZERO)
	var skew := PreGameDraw.skew_xform(skew_deg)
	var poly := PreGameDraw.local_poly(card_size, clip_norm)
	var anchor := parent_xform * Transform2D(0.0, local_center)
	if shadow_offset != Vector2.ZERO:
		draw_set_transform_matrix(anchor * Transform2D(0.0, shadow_offset) * rot * skew)
		draw_colored_polygon(poly, shadow_col)
	var xform := anchor * rot * skew
	draw_set_transform_matrix(xform)
	draw_colored_polygon(poly, fill)
	for accent in accents:
		var edge := str(accent.get("edge", "left"))
		var band := float(accent.get("size", 4.0))
		var col: Color = accent.get("color", fill)
		if band <= 0.0:
			continue
		var w := card_size.x
		var h := card_size.y
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
		var clipped := PreGameDraw.clip_strip_to_poly(poly, strip)
		if clipped.size() >= 3:
			draw_colored_polygon(clipped, col)
	if border_w > 0.0 and poly.size() >= 3:
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, border_col, border_w, true)
	return xform


func _draw() -> void:
	_hits.clear()
	var sx := size.x / 1280.0
	var sy := size.y / 720.0
	var s := minf(sx, sy)

	if use_v2 and view_mode == "title":
		_draw_title_v2()
	elif use_v2 and view_mode in ["menu", "quit_modal"]:
		_draw_menu_v2(sx, sy, s)
		if view_mode == "quit_modal":
			_draw_quit_modal(sx, sy, s)
	elif view_mode == "title":
		_draw_title(sx, sy, s)
	elif view_mode == "loading":
		_draw_loading(sx, sy, s)
	else:
		_draw_menu(sx, sy, s)
		if view_mode == "quit_modal":
			_draw_quit_modal(sx, sy, s)

	PreGameDraw.draw_top_edge_rail(self, size.x)


func _draw_title_v2() -> void:
	TitleV2Draw.draw_backdrop_gradient(self, size)
	TitleV2Draw.draw_title(self, size, _t)
	var hint: Array = TitleV2Draw.draw_enter_hint(self, size, _t, _hover_id == "title_press")
	_add_hit("title_press", hint[0], hint[1])


func _draw_menu_v2(sx: float, sy: float, s: float) -> void:
	TitleV2Draw.draw_backdrop_gradient(self, size)
	TitleV2Draw.draw_title(self, size, maxf(_t, 3.0))
	TitleV2Draw.draw_plates(self, size, _menu_t, menu_index, _add_hit)
	if save_available:
		TitleV2Draw.draw_save_card(self, size, PreGameCatalog.species_portrait(save_leader_id) if save_leader_id != "" else null, save_info)
	_draw_context_card(sx, sy, s)
	_draw_footer(sx, sy, s)
	_draw_drawer(sx, sy, s)


func _draw_title(sx: float, sy: float, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	var hover_press := _hover_id == "title_press"

	var ribbon_xform := PreGameDraw.draw_card(self, Vector2(194.0 * sx, 46.0 * sy),
		Vector2(436.0 * s, 26.0 * s), -5.5, -14.0, PreGameDraw.CORAL, Color.BLACK, 2.0,
		Vector2(5, 5) * s)
	PreGameDraw.push_counter_skew(self, ribbon_xform, -14.0)
	_draw_centered(mono, "BUILD TARGET // GODOT 4.7 GL COMPATIBILITY 3D", _fs(11.0, s),
		PreGameDraw.INK, 420.0 * s)
	PreGameDraw.pop_xform(self)

	var shard_accents: Array[Dictionary] = [
		{"edge": "left", "size": 8.0 * s, "color": PreGameDraw.CYAN},
		{"edge": "bottom", "size": 4.0 * s, "color": Color.BLACK},
	]
	PreGameDraw.draw_card(self, Vector2(316.0 * sx, 536.0 * sy),
		Vector2(688.0 * s, 178.0 * s), 3.2, -18.0, Color(0.063, 0.149, 0.227, 0.92),
		Color.BLACK, 0.0, Vector2.ZERO, Color(0, 0, 0, 0.0), shard_accents,
		PackedVector2Array([
			Vector2(0.04, 0.0), Vector2(1.0, 0.0), Vector2(0.92, 1.0), Vector2(0.0, 1.0)
		]))

	var kicker_xform := PreGameDraw.draw_card(self, Vector2(233.0 * sx, 450.0 * sy),
		Vector2(358.0 * s, 26.0 * s), -2.8, -14.0, PreGameDraw.LIME, Color.BLACK, 2.0,
		Vector2(4, 4) * s)
	PreGameDraw.push_counter_skew(self, kicker_xform, -14.0)
	_draw_centered(mono, "3D TACTICAL DUNGEON CRAWLER // ATB + EVADE", _fs(11.0, s),
		PreGameDraw.INK, 342.0 * s)
	PreGameDraw.pop_xform(self)

	PreGameDraw.draw_slash_title(self, Vector2(54.0 * sx, 476.0 * sy), "CRAWL", "MON",
		_fs(94.0, s), -1.6, -13.0, Vector2(6, 6) * s, true)

	var navy_xform := PreGameDraw.draw_card(self, Vector2(332.0 * sx, 585.0 * sy),
		Vector2(556.0 * s, 29.0 * s), 1.4, -10.0, PreGameDraw.NAVY, Color.BLACK, 2.0,
		Vector2.ZERO, Color(0, 0, 0, 0.0), _accents("left", 6.0 * s, PreGameDraw.CORAL))
	PreGameDraw.push_counter_skew(self, navy_xform, -10.0)
	_draw_centered(mono, "ASYMMETRIC NEO-BRUTALIST INTERFACE — STATUS_SCREEN & FANMENU DNA",
		_fs(11.5, s), PreGameDraw.CYAN, 544.0 * s)
	PreGameDraw.pop_xform(self)

	var press_center := Vector2(288.0 * sx + (8.0 * s if hover_press else 0.0), 638.0 * sy)
	var press_rot := -1.8 if hover_press else -3.2
	var press_fill := PreGameDraw.LIME if hover_press else PreGameDraw.PAPER
	var press_size := Vector2(465.0 * s, 44.0 * s)
	var press_xform := PreGameDraw.draw_card(self, press_center, press_size, press_rot, -8.0,
		press_fill, Color.BLACK, 2.5, Vector2(7, 7) * s, Color(0, 0, 0, 0.94),
		_no_accents(), PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.96, 0.0), Vector2(1.0, 1.0), Vector2(0.04, 1.0)
		]))
	_add_hit("title_press", press_xform, press_size)
	PreGameDraw.push_counter_skew(self, press_xform, -8.0)
	_draw_centered(display, "CLICK OR PRESS ANY KEY // ENTER LABYRINTH", _fs(19.0, s),
		PreGameDraw.INK, 445.0 * s)
	PreGameDraw.pop_xform(self)


func _draw_menu(sx: float, sy: float, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()

	_draw_logo(sx, sy, s)

	var clip := PackedVector2Array([
		Vector2(0.04, 0.0), Vector2(1.0, 0.0), Vector2(0.96, 1.0), Vector2(0.0, 1.0)
	])
	for idx in range(MENU_COUNT):
		var item: Dictionary = PreGameCatalog.MENU_ITEMS[idx]
		var item_id := str(item.get("id", ""))
		var label := str(item.get("label", ""))
		var tag := str(item.get("tag", ""))
		var focused: bool = idx == menu_index and (not play_drawer_open or idx == 0)
		var tilt: float = 0.0
		var btn_size := Vector2(300.0 * s, (52.0 if focused else 46.0) * s) * MENU_K
		var fill := Color(0.031, 0.055, 0.094, 0.94)
		if focused:
			fill = PreGameDraw.CORAL if item_id == "quit" else PreGameDraw.LIME_FAN
		var shadow := (Vector2(8, 8) if focused else Vector2(5, 5)) * s
		# D-1226: straight buttons, each staggered 10 px further forward (right) than the previous.
		var step_x := (float(idx) * 10.0 + (16.0 if focused else 0.0)) * s
		var center := Vector2(35.0 * sx + btn_size.x * 0.5 + step_x, 250.0 * sy + float(idx) * 54.0 * sy * MENU_K)
		var btn_xform := PreGameDraw.draw_card(self, center, btn_size, tilt, -10.0, fill,
			Color.BLACK, 2.0, shadow, Color(0, 0, 0, 0.68), _no_accents(), clip)
		_add_hit("menu:%d" % idx, btn_xform, btn_size)

		var d_half := 5.5 * s * MENU_K
		var d_center := Vector2(-btn_size.x * 0.5 + 22.0 * s * MENU_K, 0.0)
		var d_xf := btn_xform * PreGameDraw.skew_xform(10.0) * Transform2D(deg_to_rad(45.0), d_center)
		draw_set_transform_matrix(d_xf)
		var diamond_col := PreGameDraw.INK if focused else Color("ff624f")
		draw_rect(Rect2(Vector2(-d_half, -d_half), Vector2(d_half * 2.0, d_half * 2.0)), diamond_col)

		PreGameDraw.push_counter_skew(self, btn_xform, -10.0)
		var label_size := _fs(24.0 * MENU_K, s)
		var label_base := (display.get_ascent(label_size) - display.get_descent(label_size)) * 0.5
		var label_col := PreGameDraw.INK if focused else PreGameDraw.PAPER
		draw_string(display, Vector2(-btn_size.x * 0.5 + 34.0 * s * MENU_K, label_base), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, label_col)
		var tag_size := _fs(10.0 * MENU_K, s)
		var tag_base := (mono.get_ascent(tag_size) - mono.get_descent(tag_size)) * 0.5
		var tag_col := Color(PreGameDraw.INK.r, PreGameDraw.INK.g, PreGameDraw.INK.b, 0.72)
		if not focused:
			tag_col = PreGameDraw.TEXT_MUTED
		draw_string(mono, Vector2(-btn_size.x * 0.5, tag_base), tag,
			HORIZONTAL_ALIGNMENT_RIGHT, btn_size.x - 18.0 * s * MENU_K, tag_size, tag_col)
		PreGameDraw.pop_xform(self)

	_draw_context_card(sx, sy, s)
	_draw_footer(sx, sy, s)
	_draw_drawer(sx, sy, s)


## D-1226: game logo, lowered from the top edge: coral echo + black extrusion behind the
## slash title, a slanted lime/coral/cyan bar stack underneath. Flat, no borders.
func _draw_logo(sx: float, sy: float, s: float) -> void:
	var origin := Vector2(46.0 * sx, 54.0 * sy)
	var fs := _fs(96.0, s)
	var width := PreGameDraw.draw_slash_title(self, origin, "CRAWL", "MON", fs, -5.0, -11.0,
		Vector2(8, 8) * s, true)
	var skew := tan(deg_to_rad(11.0))
	var y0 := origin.y + float(fs) * 1.1
	var bars: Array[Dictionary] = [
		{"dx": 0.0, "w": width * 0.96, "h": 10.0, "col": PreGameDraw.LIME},
		{"dx": 26.0, "w": width * 0.52, "h": 6.0, "col": PreGameDraw.CORAL},
	]
	var y := y0
	for bar in bars:
		var h: float = float(bar["h"]) * s
		var x: float = origin.x + float(bar["dx"]) * s
		var w: float = float(bar["w"])
		var pts := PackedVector2Array([
			Vector2(x + h * skew, y), Vector2(x + w + h * skew, y),
			Vector2(x + w, y + h), Vector2(x, y + h)])
		var shade := PackedVector2Array()
		for p in pts:
			shade.append(p + Vector2(4.0, 4.0) * s)
		draw_colored_polygon(shade, PreGameDraw.INK)
		draw_colored_polygon(pts, bar["col"])
		y += h + 6.0 * s


func _draw_context_card(sx: float, sy: float, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	var body := PreGameDraw.body_font()
	var item: Dictionary = PreGameCatalog.MENU_ITEMS[clampi(menu_index, 0, MENU_COUNT - 1)]
	var kicker := str(item.get("kicker", ""))
	var title := str(item.get("label", ""))
	var desc := str(item.get("desc", ""))
	var card_size := Vector2(348.0 * s, 118.0 * s)
	var xform := PreGameDraw.draw_card(self, Vector2(1077.0 * sx, 639.0 * sy), card_size,
		-2.4, -10.0, PreGameDraw.PAPER, Color.BLACK, 2.0, Vector2(7, 7) * s,
		Color(0, 0, 0, 0.9), _accents("left", 7.0 * s, PreGameDraw.CORAL))
	PreGameDraw.push_counter_skew(self, xform, -10.0)
	var left := -card_size.x * 0.5 + 20.0 * s
	var top := -card_size.y * 0.5 + 12.0 * s
	var kicker_size := _fs(10.0, s)
	draw_string(mono, Vector2(left, top + mono.get_ascent(kicker_size)), kicker,
		HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_size, PreGameDraw.PAPER_MUTED)
	var title_size := _fs(24.0, s)
	draw_string(display, Vector2(left, top + 34.0 * s + display.get_ascent(title_size)), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, PreGameDraw.INK)
	PreGameDraw.draw_wrapped_text(self, body, Vector2(left, top + 62.0 * s), desc,
		_fs(12.0, s), Color("1e3547"), card_size.x - 40.0 * s, 1.22)
	PreGameDraw.pop_xform(self)


func _draw_footer(sx: float, sy: float, s: float) -> void:
	var xform := PreGameDraw.draw_card(self, Vector2(198.0 * sx, 696.0 * sy),
		Vector2(340.0 * s, 26.0 * s), -1.0, 0.0, Color(0.012, 0.047, 0.086, 0.95),
		Color.BLACK, 0.0, Vector2.ZERO, Color(0, 0, 0, 0.0),
		_accents("top", 1.0, Color("365365")))
	draw_set_transform_matrix(xform)
	var pill_font := _fs(9.0, s)
	var pill_h := float(pill_font + 8)
	var px := -340.0 * s * 0.5 + 8.0 * s
	var py := -pill_h * 0.5
	var first_w := PreGameDraw.draw_kbd_pill(self, Vector2(px, py), "MOUSE",
		"HOVER / CLICK / R-CLICK BACK", pill_font)
	PreGameDraw.draw_kbd_pill(self, Vector2(px + first_w + 10.0 * s, py), "↑/↓ Z X", "KEYS",
		pill_font)
	PreGameDraw.pop_xform(self)


func _draw_drawer(sx: float, sy: float, s: float) -> void:
	if not play_drawer_open and _drawer_t <= 0.001:
		return
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	var t := clampf(_drawer_t, 0.0, 1.0)
	var card_size := Vector2(296.0 * s, 218.0 * s)
	var center := Vector2(715.0 * sx + (1.0 - t) * 36.0 * s, 338.0 * sy)
	if use_v2:  # D-1265: beside the plates, clear of the leader
		center = Vector2(572.0 * sx + (1.0 - t) * 36.0 * s, 335.0 * sy)
	var xform := PreGameDraw.draw_card(self, center, card_size, 1.8, -7.0, PreGameDraw.NAVY,
		PreGameDraw.BORDER_MUTED, 1.5, Vector2(9, 9) * s, Color(0, 0, 0, 0.82),
		_accents("top", 6.0 * s, PreGameDraw.LIME_FAN))
	_drawer_xform = xform
	_drawer_size = card_size

	var back_size := Vector2(96.0 * s, 22.0 * s)
	var back_center := Vector2(-card_size.x * 0.5 + 62.0 * s, -card_size.y * 0.5 + 24.0 * s)
	var back_fill := PreGameDraw.CORAL if _hover_id == "drawer_back" else PreGameDraw.LIME_FAN
	var back_xform := _nested_card(xform, back_center, back_size, 0.0, -12.0, back_fill,
		Color.BLACK, 1.5, Vector2(3, 3) * s, Color(0, 0, 0, 0.75))
	if play_drawer_open:
		_add_hit("drawer_back", back_xform, back_size)
	PreGameDraw.push_counter_skew(self, back_xform, -12.0)
	_draw_centered(mono, "< BACK (X)", _fs(9.5, s), PreGameDraw.INK, 88.0 * s)
	PreGameDraw.pop_xform(self)

	PreGameDraw.push_counter_skew(self, xform, -7.0)
	var top_size := _fs(9.5, s)
	var top_base := -card_size.y * 0.5 + 24.0 * s
	top_base += (mono.get_ascent(top_size) - mono.get_descent(top_size)) * 0.5
	draw_string(mono, Vector2(-card_size.x * 0.5, top_base), "PLAY // CAMPAIGN",
		HORIZONTAL_ALIGNMENT_RIGHT, card_size.x - 16.0 * s, top_size, PreGameDraw.TEXT_SUB)
	PreGameDraw.pop_xform(self)

	var blade_size := Vector2(258.0 * s, 35.0 * s)
	for i in range(PLAY_COUNT):
		var focused := play_index == i
		var shift := (6.0 if focused else 0.0) * s
		var blade_center := Vector2(shift, -card_size.y * 0.5 + 58.0 * s + float(i) * 41.0 * s)
		var dim := 0.36 if (i == 1 and not save_available) else 1.0
		var fill := Color(0.043, 0.086, 0.133, 0.98 * dim)
		if focused:
			fill = Color(PreGameDraw.LIME_FAN.r, PreGameDraw.LIME_FAN.g, PreGameDraw.LIME_FAN.b,
				0.98 * dim)
		var border_col := Color.BLACK if focused else Color(0.22, 0.30, 0.36, 1.0)
		var shadow := Vector2(3, 3) * s if focused else Vector2(2, 2) * s
		var blade_rot := -1.0 if i % 2 == 0 else 0.9
		var blade_xform := _nested_card(xform, blade_center, blade_size, blade_rot, -8.0, fill,
			border_col, 1.5, shadow, Color(0, 0, 0, 0.70))
		if play_drawer_open:
			_add_hit("drawer:%d" % i, blade_xform, blade_size)
		var label := "NEW GAME"
		var tag := "6 PROTAGONISTS"
		if i == 1:
			label = "CONTINUE"
			tag = "HUB SLOT 01" if save_available else "NO SAVE"
		elif i == 2:
			label = "NEW EXPEDITION"
			tag = "HUB GATE"
		var text_col := PreGameDraw.INK if focused else PreGameDraw.PAPER
		if dim < 1.0:
			text_col = Color(text_col.r, text_col.g, text_col.b, text_col.a * 0.5)
		if not focused and dim >= 1.0:
			text_col = PreGameDraw.PAPER
		PreGameDraw.push_counter_skew(self, blade_xform, -8.0)
		var blade_label_size := _fs(16.0, s)
		var blade_base := (display.get_ascent(blade_label_size)
			- display.get_descent(blade_label_size)) * 0.5
		draw_string(display, Vector2(-blade_size.x * 0.5 + 14.0 * s, blade_base), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, blade_label_size, text_col)
		var blade_tag_size := _fs(8.8, s)
		var blade_tag_base := (mono.get_ascent(blade_tag_size)
			- mono.get_descent(blade_tag_size)) * 0.5
		draw_string(mono, Vector2(-blade_size.x * 0.5, blade_tag_base), tag,
			HORIZONTAL_ALIGNMENT_RIGHT, blade_size.x - 14.0 * s, blade_tag_size,
			Color(text_col.r, text_col.g, text_col.b, text_col.a * 0.75))
		PreGameDraw.pop_xform(self)

	PreGameDraw.push_counter_skew(self, xform, -7.0)
	PreGameDraw.draw_wrapped_text(self, mono, Vector2(-card_size.x * 0.5 + 16.0 * s, 54.0 * s),
		"NEW GAME picks starter; CONTINUE locked until SaveService; NEW EXPEDITION opens Gate + Nature Roulette.",
		_fs(8.8, s), PreGameDraw.TEXT_DIM, card_size.x - 32.0 * s, 1.18)
	PreGameDraw.pop_xform(self)


func _draw_quit_modal(sx: float, sy: float, s: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.016, 0.043, 0.071, 0.80))
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	var card_size := Vector2(390.0 * s, 175.0 * s)
	var xform := PreGameDraw.draw_card(self, Vector2(640.0 * sx, 360.0 * sy), card_size,
		-1.5, -9.0, PreGameDraw.NAVY, PreGameDraw.CORAL, 2.5, Vector2(8, 8) * s,
		Color(0, 0, 0, 0.90))

	PreGameDraw.push_counter_skew(self, xform, -9.0)
	var left := -card_size.x * 0.5 + 24.0 * s
	var top := -card_size.y * 0.5 + 22.0 * s
	var title_size := _fs(26.0, s)
	draw_string(display, Vector2(left, top + display.get_ascent(title_size)), "QUIT GAME?",
		HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, PreGameDraw.PAPER)
	var body_size := _fs(12.0, s)
	draw_string(mono, Vector2(left, top + 48.0 * s + mono.get_ascent(body_size)),
		"Exit Crawlmon desktop application?", HORIZONTAL_ALIGNMENT_LEFT, -1, body_size,
		PreGameDraw.TEXT_SUB)
	PreGameDraw.pop_xform(self)

	var cancel_size := Vector2(132.0 * s, 32.0 * s)
	var cancel_center := Vector2(-102.0 * s, card_size.y * 0.5 - 36.0 * s)
	var cancel_fill := Color(0.031, 0.055, 0.094, 0.96)
	var cancel_border := PreGameDraw.BORDER_MUTED
	var cancel_text := PreGameDraw.PAPER
	if quit_confirm_index == 0:
		cancel_fill = PreGameDraw.CORAL
		cancel_border = Color.BLACK
		cancel_text = PreGameDraw.INK
	var cancel_xform := _nested_card(xform, cancel_center, cancel_size, 0.0, -8.0, cancel_fill,
		cancel_border, 1.5, Vector2(3, 3) * s, Color(0, 0, 0, 0.75))
	_add_hit("quit_cancel", cancel_xform, cancel_size)
	PreGameDraw.push_counter_skew(self, cancel_xform, -8.0)
	_draw_centered(mono, "[X] CANCEL", _fs(10.0, s), cancel_text, 122.0 * s)
	PreGameDraw.pop_xform(self)

	var confirm_size := Vector2(186.0 * s, 32.0 * s)
	var confirm_center := Vector2(70.0 * s, card_size.y * 0.5 - 36.0 * s)
	var confirm_fill := Color(0.070, 0.140, 0.200, 0.98)
	var confirm_text := PreGameDraw.CORAL
	if quit_confirm_index == 1:
		confirm_fill = PreGameDraw.LIME_FAN
		confirm_text = PreGameDraw.INK
	var confirm_xform := _nested_card(xform, confirm_center, confirm_size, -0.8, -10.0,
		confirm_fill, PreGameDraw.CORAL, 2.0, Vector2(3, 3) * s, Color(0, 0, 0, 0.75))
	_add_hit("quit_confirm", confirm_xform, confirm_size)
	PreGameDraw.push_counter_skew(self, confirm_xform, -10.0)
	_draw_centered(mono, "QUIT [ENTER]", _fs(10.5, s), confirm_text, 176.0 * s)
	PreGameDraw.pop_xform(self)


func _draw_loading(sx: float, sy: float, s: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.063, 0.102, 0.92))
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	var card_size := Vector2(440.0 * s, 146.0 * s)
	var xform := PreGameDraw.draw_card(self, Vector2(640.0 * sx, 360.0 * sy), card_size,
		-1.5, -9.0, PreGameDraw.NAVY, Color.BLACK, 2.0, Vector2(7, 7) * s,
		Color(0, 0, 0, 0.92))
	PreGameDraw.push_counter_skew(self, xform, -9.0)
	var left := -card_size.x * 0.5 + 20.0 * s
	var top := -card_size.y * 0.5 + 16.0 * s
	var label_size := _fs(10.0, s)
	draw_string(mono, Vector2(left, top + mono.get_ascent(label_size)), loading_label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, PreGameDraw.CYAN)
	var title_size := _fs(22.0, s)
	draw_string(display, Vector2(left, top + 32.0 * s + display.get_ascent(title_size)),
		"TARGET: APPROVED 3D CAMPAIGN SCENE", HORIZONTAL_ALIGNMENT_LEFT, -1, title_size,
		PreGameDraw.PAPER)
	var bar := Rect2(Vector2(left, top + 68.0 * s), Vector2(card_size.x - 40.0 * s, 8.0 * s))
	draw_rect(bar, Color("05101a"))
	var progress := clampf(loading_progress, 0.0, 1.0)
	if progress > 0.0:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)),
			PreGameDraw.LIME)
	var pct_size := _fs(9.5, s)
	var pct_base := bar.position.y + bar.size.y + 14.0 * s + mono.get_ascent(pct_size)
	draw_string(mono, Vector2(left, pct_base), "%d%%" % int(round(progress * 100.0)),
		HORIZONTAL_ALIGNMENT_LEFT, -1, pct_size, PreGameDraw.LIME)
	draw_string(mono, Vector2(left, pct_base), "ResourceLoader.load_threaded_request",
		HORIZONTAL_ALIGNMENT_RIGHT, card_size.x - 40.0 * s, pct_size, PreGameDraw.TEXT_MUTED)
	PreGameDraw.pop_xform(self)
