class_name PreGameViewModals
extends Control
## Pre-Game overlay modals (D-1207 / D-1208), including the reusable R18-Q4
## Expedition Nature Roulette shared with the 3D Hub Gate.
##
## Covers the Skill Dossier, the Confirm Protagonist card, the 3-Layer Advanced
## Dossier delegate and the Roulette. The roulette locks species, Nature,
## individual offsets, consolidated stats and Entry HP/MP BEFORE the animation
## starts: skipping always reveals that exact result and never rerolls.

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")
const PreGameViewAdvanced = preload("res://scripts/ui/pre_game/pre_game_view_advanced.gd")
const PortraitIcons = preload("res://scripts/ui/portrait_icon.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")

const ROULETTE_ACCENT := Color("f0c57e")
const ROULETTE_PURE_ACCENT := Color("63d9ec")
const DIM_DOSSIER := Color(0.016, 0.043, 0.071, 0.84)
const DIM_ROULETTE := Color(0.016, 0.043, 0.071, 0.92)

signal modal_closed(which: String)
signal species_changed(idx: int)
signal start_roulette_from_confirm
signal roulette_finished(result: Dictionary)
signal roulette_enter_expedition(result: Dictionary)
signal roulette_cancelled

var active_modal: String = "":
	set(value):
		active_modal = value
		_update_mouse_filter()
		queue_redraw()

var char_index: int = 0
var move_index: int = 0

var roulette_context: String = "NEW_GAME"
var roulette_spinning: bool = false
var roulette_lit_idx: int = 0
var roulette_locked_result: Dictionary = {}

var _adv_view: PreGameViewAdvanced = null
var _slot: NatureSlotView = null
## Debug/capture knobs (--speed=, --mute=1).
var roulette_speed: float = 1.0
var roulette_muted: bool = false

var _hit_dossier_close: PackedVector2Array = PackedVector2Array()
var _hit_confirm_cancel: PackedVector2Array = PackedVector2Array()
var _hit_confirm_start: PackedVector2Array = PackedVector2Array()
var _hit_roulette_skip: PackedVector2Array = PackedVector2Array()
var _hit_roulette_back: PackedVector2Array = PackedVector2Array()
var _hit_roulette_enter: PackedVector2Array = PackedVector2Array()
var _roulette_enter_rect: Rect2 = Rect2()

# --- Advanced delegate proxies ------------------------------------------------

var adv_layer: int:
	get:
		return int(_adv_view.adv_layer) if _adv_view != null else 0
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.adv_layer = value

var dossier_level: int:
	get:
		return int(_adv_view.dossier_level) if _adv_view != null else 0
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.dossier_level = value

var learn_filter: String:
	get:
		return str(_adv_view.learn_filter) if _adv_view != null else ""
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.learn_filter = value

var compare_idx: int:
	get:
		return int(_adv_view.compare_idx) if _adv_view != null else -1
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.compare_idx = value

var reveal_unknowns: bool:
	get:
		return bool(_adv_view.reveal_unknowns) if _adv_view != null else false
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.reveal_unknowns = value

var debug_dev_spec: bool:
	get:
		return bool(_adv_view.debug_dev_spec) if _adv_view != null else false
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.debug_dev_spec = value

var sim_level: int:
	get:
		return int(_adv_view.sim_level) if _adv_view != null else 1
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.sim_level = value

var sim_nature_id: String:
	get:
		return str(_adv_view.sim_nature_id) if _adv_view != null else ""
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.sim_nature_id = value

var sim_alloc: Dictionary:
	get:
		if _adv_view != null and _adv_view.sim_alloc is Dictionary:
			return _adv_view.sim_alloc
		return {}
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.sim_alloc = value

var sim_batch_log: Array[Dictionary]:
	get:
		if _adv_view != null:
			return _adv_view.sim_batch_log
		var empty: Array[Dictionary] = []
		return empty
	set(value):
		var view: PreGameViewAdvanced = _ensure_adv_view()
		view.sim_batch_log = value

# --- Lifecycle ----------------------------------------------------------------

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_mouse_filter()
	focus_mode = Control.FOCUS_ALL
	resized.connect(_on_resized)
	set_process(true)


func _on_resized() -> void:
	queue_redraw()


func _ensure_slot() -> NatureSlotView:
	if _slot == null:
		_slot = NatureSlotView.new()
		_slot.name = "NatureSlot"
		add_child(_slot)
		_slot.settled.connect(_on_slot_settled)
		_slot.enter_requested.connect(_on_slot_enter)
	return _slot


func _on_slot_settled(_summary: Dictionary) -> void:
	roulette_spinning = false
	queue_redraw()
	roulette_finished.emit(roulette_locked_result.duplicate(true))


func _on_slot_enter() -> void:
	roulette_enter_expedition.emit(roulette_locked_result.duplicate(true))

# --- Public API ---------------------------------------------------------------

func open_skill_dossier(c_idx: int, m_idx: int) -> void:
	_prepare_open()
	char_index = maxi(c_idx, 0)
	move_index = maxi(m_idx, 0)
	active_modal = "skill_dossier"


func open_confirm_char(c_idx: int) -> void:
	_prepare_open()
	char_index = maxi(c_idx, 0)
	active_modal = "confirm_char"


func open_advanced(c_idx: int, layer: int = 2) -> void:
	_prepare_open()
	char_index = maxi(c_idx, 0)
	var view: PreGameViewAdvanced = _ensure_adv_view()
	view.visible = true
	view.open(char_index, layer)
	active_modal = "advanced"


func open_roulette(c_idx: int, context_mode: String = "NEW_GAME", forced_nature_id: String = "", reduce_motion: bool = false) -> Dictionary:
	if _adv_view != null:
		_adv_view.visible = false
	char_index = maxi(c_idx, 0)
	roulette_context = "HUB_GATE" if context_mode == "HUB_GATE" else "NEW_GAME"
	active_modal = "roulette"
	roulette_locked_result = _build_roulette_result(char_index, forced_nature_id)
	var nature_id := str(roulette_locked_result.get("nature_id", "hardy"))
	var target := _nature_index(nature_id)
	roulette_lit_idx = target if target >= 0 else 0
	var info: Dictionary = {}
	if roulette_locked_result.get("nature") is Dictionary:
		info = roulette_locked_result["nature"] as Dictionary
	var slot := _ensure_slot()
	slot.visible = true
	slot.speed = roulette_speed
	slot.muted = roulette_muted
	roulette_spinning = not reduce_motion
	slot.start(nature_id, info, reduce_motion)
	queue_redraw()
	return roulette_locked_result.duplicate(true)


## Debug: freezes the slot `ms` after the reels start spinning (boot delay included).
func freeze_roulette_at(ms: float) -> void:
	if _slot == null:
		return
	_slot.frozen = true
	_slot.advance(NatureSlotView.LEAD_MS / maxf(_slot.speed, 0.05) + ms)


## Debug: freezes the entrance `ms` after the roulette opens (--roulette-intro-at=).
func freeze_roulette_intro_at(ms: float) -> void:
	if _slot == null:
		return
	_slot.frozen = true
	_slot.advance(ms / maxf(_slot.speed, 0.05))


func get_slot() -> NatureSlotView:
	return _slot


func skip_roulette() -> void:
	if active_modal != "roulette" or _slot == null:
		return
	_slot.skip()


func close_modal() -> void:
	var which := active_modal
	if which.is_empty():
		return
	active_modal = ""
	roulette_spinning = false
	if _slot != null:
		_slot.visible = false
	if _adv_view != null:
		_adv_view.visible = false
	queue_redraw()
	modal_closed.emit(which)


func is_open() -> bool:
	return active_modal != ""


func get_roulette_enter_rect() -> Rect2:
	return _roulette_enter_rect

# --- Input --------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if handle_gui_input(event):
		accept_event()


func handle_gui_input(event: InputEvent) -> bool:
	if active_modal.is_empty():
		return false
	if active_modal == "advanced":
		if _adv_view != null and _adv_view.visible:
			return _adv_view.handle_gui_input(event)
		return false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return false
		if mb.button_index == MOUSE_BUTTON_LEFT:
			return _handle_click(mb.position)
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			return _handle_back()
	return false


func handle_key_action(action: String) -> bool:
	if active_modal.is_empty():
		return false
	if active_modal == "advanced":
		if _adv_view != null and _adv_view.handle_key_action(action):
			queue_redraw()
			return true
		if action == "toggle_adv" or action == "back":
			close_modal()
			return true
		return false
	match action:
		"confirm":
			return _handle_confirm()
		"back":
			return _handle_back()
		"skip":
			if active_modal == "roulette":
				skip_roulette()
				return true
			return false
		"toggle_dossier":
			if active_modal == "skill_dossier":
				open_confirm_char(char_index)
			else:
				open_skill_dossier(char_index, move_index)
			return true
		"toggle_adv":
			open_advanced(char_index, 2)
			return true
		"tab_left":
			return _cycle_species(-1)
		"tab_right":
			return _cycle_species(1)
		"left":
			if active_modal == "skill_dossier":
				return _cycle_move(-1)
			return _cycle_species(-1)
		"right":
			if active_modal == "skill_dossier":
				return _cycle_move(1)
			return _cycle_species(1)
		"layer_1":
			open_advanced(char_index, 1)
			return true
		"layer_2":
			open_advanced(char_index, 2)
			return true
		"layer_3":
			open_advanced(char_index, 3)
			return true
		"layer_4":
			open_advanced(char_index, 4)
			return true
	return false


func _handle_confirm() -> bool:
	if active_modal == "roulette":
		if _slot != null and _slot.is_spinning():
			skip_roulette()
		elif _slot != null:
			_slot.request_exit()
		return true
	if active_modal == "confirm_char":
		start_roulette_from_confirm.emit()
		return true
	if active_modal == "skill_dossier":
		close_modal()
		return true
	return false


func _handle_back() -> bool:
	if active_modal == "roulette":
		roulette_cancelled.emit()
		close_modal()
		return true
	close_modal()
	return true


func _handle_click(point: Vector2) -> bool:
	match active_modal:
		"skill_dossier":
			if _in_poly(_hit_dossier_close, point):
				close_modal()
				return true
		"confirm_char":
			if _in_poly(_hit_confirm_cancel, point):
				close_modal()
				return true
			if _in_poly(_hit_confirm_start, point):
				start_roulette_from_confirm.emit()
				return true
		"roulette":
			if _slot == null:
				return false
			match _slot.hit_test(point):
				"skip":
					skip_roulette()
					return true
				"back":
					roulette_cancelled.emit()
					close_modal()
					return true
				"enter":
					_slot.request_exit()
					return true
	return false


func _cycle_species(step: int) -> bool:
	var count := _species_count()
	if count <= 0:
		return false
	char_index = posmod(char_index + step, count)
	species_changed.emit(char_index)
	queue_redraw()
	return true


func _cycle_move(step: int) -> bool:
	var spec := _protagonist_spec(char_index)
	var starters: Array = []
	if spec.get("starter_moves") is Array:
		starters = spec["starter_moves"] as Array
	if starters.is_empty():
		return false
	move_index = posmod(move_index + step, starters.size())
	queue_redraw()
	return true

# --- Advanced delegate plumbing -----------------------------------------------

func _ensure_adv_view() -> PreGameViewAdvanced:
	if _adv_view != null:
		return _adv_view
	_adv_view = PreGameViewAdvanced.new()
	_adv_view.name = "PreGameAdvancedView"
	_adv_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_adv_view.visible = false
	add_child(_adv_view)
	if _adv_view.has_signal("close_requested"):
		_adv_view.close_requested.connect(_on_adv_close_requested)
	if _adv_view.has_signal("species_changed"):
		_adv_view.species_changed.connect(_on_adv_species_changed)
	if _adv_view.has_signal("layer_changed"):
		_adv_view.layer_changed.connect(_on_adv_layer_changed)
	return _adv_view


func _on_adv_close_requested() -> void:
	if active_modal == "advanced":
		close_modal()


func _on_adv_species_changed(idx: int) -> void:
	char_index = idx
	species_changed.emit(idx)


func _on_adv_layer_changed(_layer: int) -> void:
	queue_redraw()


func _prepare_open() -> void:
	if _adv_view != null:
		_adv_view.visible = false
	roulette_spinning = false


func _update_mouse_filter() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if is_open() else Control.MOUSE_FILTER_IGNORE

# --- Data helpers -------------------------------------------------------------

func _species_count() -> int:
	return maxi(PreGameCatalog.build_protagonist_list().size(), 1)


func _protagonist_spec(idx: int) -> Dictionary:
	var list := PreGameCatalog.build_protagonist_list()
	if list.is_empty():
		return {}
	return list[clampi(idx, 0, list.size() - 1)]


func _species_name(idx: int) -> String:
	return str(_protagonist_spec(idx).get("name", "Unknown"))


func _nature_index(nature_id: String) -> int:
	var target := nature_id.to_lower()
	var natures := PreGameCatalog.NATURES_LIST()
	for i in natures.size():
		if str(natures[i].get("id", "")).to_lower() == target:
			return i
	return -1


func _build_roulette_result(c_idx: int, forced_nature_id: String) -> Dictionary:
	var spec := _protagonist_spec(c_idx)
	var nature_id := forced_nature_id.to_lower()
	if PreGameCatalog.get_nature_by_id(nature_id).is_empty():
		nature_id = str(PreGameCatalog._roll_nature_id()).to_lower()
	var nature := PreGameCatalog.get_nature_by_id(nature_id)
	if nature.is_empty():
		nature_id = "hardy"
		nature = PreGameCatalog.get_nature_by_id("hardy")

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var offsets: Dictionary = CrawlmonAttributeMath.roll_individual_offsets(rng)
	var consolidated: Dictionary = PreGameCatalog.consolidate_stats(spec, nature_id, offsets, 1)
	var stats: Dictionary = {}
	if consolidated.get("stats") is Dictionary:
		stats = (consolidated["stats"] as Dictionary).duplicate(true)
	var entry_hp := int(consolidated.get("max_hp", PreGameCatalog.calc_max_hp(1, int(stats.get("VIT", 1)))))
	var entry_mp := int(consolidated.get("max_mp", PreGameCatalog.calc_max_mp(1, int(stats.get("WIS", 1)))))
	return {
		"species": str(spec.get("id", "")),
		"nature_id": nature_id,
		"nature": nature,
		"offsets": offsets,
		"stats": stats,
		"entry_hp": entry_hp,
		"entry_mp": entry_mp,
	}


func _base_stats_of(spec: Dictionary) -> Dictionary:
	if spec.get("base_stats") is Dictionary:
		return (spec["base_stats"] as Dictionary).duplicate(true)
	var raw: Dictionary = {}
	if spec.get("raw_stats") is Dictionary:
		raw = (spec["raw_stats"] as Dictionary).duplicate(true)
	if raw.is_empty():
		return {"STR": 3, "MAG": 3, "VIT": 3, "WIS": 2, "AGI": 2, "LUK": 2}
	return CrawlmonAttributeMath.convert_species_stats_to_15_points(raw)


func _base_stats_line(spec: Dictionary) -> String:
	return _stats_line(_base_stats_of(spec))


func _stats_line(stats: Dictionary) -> String:
	var parts: PackedStringArray = []
	for stat in PreGameCatalog.STAT_ORDER:
		parts.append("%s %d" % [stat, int(stats.get(stat, 0))])
	return " · ".join(parts)


func _starter_kit_line(spec: Dictionary) -> String:
	var starters: Array = []
	if spec.get("starter_moves") is Array:
		starters = spec["starter_moves"] as Array
	var names: PackedStringArray = []
	for move_v in starters:
		var move_spec := PreGameCatalog.get_move_spec(str(move_v))
		names.append(str(move_spec.get("name", str(move_v).capitalize())))
	if names.is_empty():
		return "BASIC ACTION: Tackle + two species starters (C2)."
	var rest := PackedStringArray()
	for i in range(1, names.size()):
		rest.append(names[i])
	if rest.is_empty():
		return "BASIC ACTION: %s" % names[0]
	return "BASIC ACTION: %s + %s" % [names[0], " + ".join(rest)]


func _nature_mod_summary(entry: Dictionary) -> String:
	if bool(entry.get("pure", false)):
		return "PURE 0/0"
	var mods: Dictionary = {}
	if entry.get("mods") is Dictionary:
		mods = entry["mods"] as Dictionary
	var parts: PackedStringArray = []
	for stat in PreGameCatalog.STAT_ORDER:
		var value := int(mods.get(stat, 0))
		if value == 0:
			continue
		parts.append("%s%s%d" % [stat, "+" if value > 0 else "", value])
	if parts.is_empty():
		return "PURE 0/0"
	return " ".join(parts)


func _roulette_stats_line() -> String:
	var stats: Dictionary = {}
	if roulette_locked_result.get("stats") is Dictionary:
		stats = (roulette_locked_result["stats"] as Dictionary).duplicate(true)
	var parts: PackedStringArray = []
	for stat in PreGameCatalog.STAT_ORDER:
		parts.append("%s %d" % [stat, int(stats.get(stat, 0))])
	return "Rolled Stats (maxi(1, b+o+n)): %s | Entry HP %d · MP %d" % [
		" · ".join(parts),
		int(roulette_locked_result.get("entry_hp", 0)),
		int(roulette_locked_result.get("entry_mp", 0)),
	]

# --- Drawing ------------------------------------------------------------------

func _draw() -> void:
	_reset_hit_rects()
	if active_modal.is_empty() or active_modal == "advanced":
		return
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var s := minf(size.x / 1280.0, size.y / 720.0)
	if s <= 0.0:
		return
	var center := size * 0.5
	if active_modal == "roulette":
		return
	draw_rect(Rect2(Vector2.ZERO, size), DIM_DOSSIER)
	match active_modal:
		"skill_dossier":
			_draw_skill_dossier(s, center)
		"confirm_char":
			_draw_confirm_char(s, center)


func _reset_hit_rects() -> void:
	_hit_dossier_close = PackedVector2Array()
	_hit_confirm_cancel = PackedVector2Array()
	_hit_confirm_start = PackedVector2Array()
	_hit_roulette_skip = PackedVector2Array()
	_hit_roulette_back = PackedVector2Array()
	_hit_roulette_enter = PackedVector2Array()
	_roulette_enter_rect = Rect2()


func _draw_skill_dossier(s: float, center: Vector2) -> void:
	var card_size := Vector2(680.0, 304.0) * s
	var xform := PreGameDraw.draw_card(self, center, card_size, -0.8, 0.0,
		PreGameDraw.DEEP_INK, Color.BLACK, 2.0 * s, Vector2(12.0, 12.0) * s, Color.BLACK,
		[{"edge": "left", "size": 7.0 * s, "color": Color("ec4899")}])
	var w := card_size.x
	var h := card_size.y
	var left := -w * 0.5
	var top := -h * 0.5
	var pad := 24.0 * s
	var mono := PreGameDraw.mono_font()
	var title := PreGameDraw.title_font()

	var spec := _protagonist_spec(char_index)
	var starters: Array = []
	if spec.get("starter_moves") is Array:
		starters = spec["starter_moves"] as Array
	var move_id := ""
	if not starters.is_empty():
		move_id = str(starters[clampi(move_index, 0, starters.size() - 1)])
	var move := PreGameCatalog.get_move_spec(move_id)

	draw_string(mono, Vector2(left + pad, top + 24.0 * s),
		"SKILL DOSSIER // TECHNICAL SPECIFICATION",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, maxi(6, int(round(11.0 * s))), Color("ec4899"))

	var move_name := str(move.get("name", move_id.capitalize())).to_upper()
	var title_fs := maxi(10, int(round(30.0 * s)))
	draw_string(title, Vector2(left + pad, top + 60.0 * s),
		move_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_fs, PreGameDraw.PAPER)

	var title_w := title.get_string_size(move_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_fs).x
	var badge_h := 20.0 * s
	var badge_y := top + 39.0 * s
	var bx := left + pad + title_w + 14.0 * s
	bx += PreGameDraw.draw_elem_chip(self, Vector2(bx, badge_y), int(move.get("elem", 0)), badge_h, true) + 6.0 * s

	var type_key := str(move.get("type_key", "physical"))
	var type_info: Dictionary = {}
	var raw_type: Variant = PreGameDraw.MOVE_TYPES.get(type_key)
	if raw_type is Dictionary:
		type_info = raw_type
	if type_info.is_empty():
		type_info = PreGameDraw.MOVE_TYPES["physical"]
	var badge_cy := badge_y + badge_h * 0.5
	var type_icon := PreGameDraw.load_icon(str(type_info.get("svg_path", "")))
	PreGameDraw.draw_move_badge(self, Vector2(bx + badge_h * 0.5, badge_cy), badge_h,
		type_info.get("bg", PreGameDraw.PAPER), type_info.get("fg", PreGameDraw.INK), type_icon, -10.0)
	bx += badge_h + 6.0 * s

	var range_key := str(move.get("range_key", ""))
	var raw_range: Variant = PreGameDraw.MOVE_RANGES.get(range_key)
	if raw_range is Dictionary:
		var range_info: Dictionary = raw_range
		var range_icon := PreGameDraw.load_icon(str(range_info.get("svg_path", "")))
		PreGameDraw.draw_move_badge(self, Vector2(bx + badge_h * 0.5, badge_cy), badge_h,
			range_info.get("bg", PreGameDraw.PAPER), range_info.get("fg", PreGameDraw.INK), range_icon, -10.0)

	var atb := int(move.get("atb", 0))
	var mp := int(move.get("mp", 0))
	var power := float(move.get("power", 0.0))
	var kind := int(move.get("kind", 0))
	var dmg_type := int(move.get("dmg_type", 0))
	var pwr_label := "POWER —" if (kind == 3 or power <= 0.0) else "POWER ×%.1f" % power
	var pwr_bg := Color("b5a5fe") if (dmg_type == 1 and kind != 3) else Color("f59e0b")
	var chip_size := maxi(6, int(round(9.5 * s)))
	var right_edge := w * 0.5 - pad
	var chips: Array[Dictionary] = [
		{"text": "%d ATB" % atb, "bg": Color("0891b2"), "fg": PreGameDraw.PAPER},
		{"text": "%d MP" % mp, "bg": Color("2563eb"), "fg": PreGameDraw.PAPER},
		{"text": pwr_label, "bg": pwr_bg, "fg": PreGameDraw.INK},
	]
	var chip_x := right_edge
	var chip_h := 20.0 * s
	var chip_cy := top + 20.0 * s + chip_h * 0.5
	for i in range(chips.size() - 1, -1, -1):
		var item: Dictionary = chips[i]
		var text := str(item.get("text", ""))
		var text_w := mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, chip_size).x
		var pill_w := text_w + 18.0 * s
		var pill_cx := chip_x - pill_w * 0.5
		_draw_nested_stat_chip(xform, Vector2(pill_cx, chip_cy), Vector2(pill_w, chip_h), -10.0,
			item.get("bg", PreGameDraw.CYAN), item.get("fg", PreGameDraw.PAPER), text, chip_size, s)
		chip_x -= pill_w + 7.0 * s

	var sec_x := left + pad
	var sec_w := w - pad * 2.0 - 8.0 * s
	var sec_y := top + 82.0 * s
	var windup_text := str(move.get("windup_text", "%.2fs" % float(move.get("windup", 0.0))))
	var sections: Array[Dictionary] = [
		{"head": "[ 01 // MECHANICS & COMBAT EFFECT ]", "col": PreGameDraw.CORAL, "body": str(move.get("text", ""))},
		{"head": "[ 02 // VISUALS & 3D AESTHETICS ]", "col": PreGameDraw.GOLD, "body": str(move.get("visuals", ""))},
		{"head": "[ 03 // MOTION & SPATIAL DISPLACEMENT ]", "col": PreGameDraw.CYAN, "body": str(move.get("motion", ""))},
		{"head": "[ 04 // WIND-UP & 15-PT ATTRIBUTE SCALING ]", "col": PreGameDraw.LIME,
			"body": "Wind-up %s · %d ATB · %d MP · scales from the 15-point base with individual offsets and Nature mods (D-390)." % [windup_text, atb, mp]},
	]
	for row in sections:
		_draw_section(sec_x, sec_y, sec_w, str(row.get("head", "")),
			row.get("col", PreGameDraw.PAPER), str(row.get("body", "")), s)
		sec_y += 44.0 * s

	var close_label := "CLOSE [D / X]"
	var close_font := maxi(8, int(round(13.5 * s)))
	var close_sz := Vector2(title.get_string_size(close_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, close_font).x + 26.0 * s, 24.0 * s)
	var close_center := Vector2(left + pad + close_sz.x * 0.5, top + h - 20.0 * s)
	_hit_dossier_close = _draw_blade(self, xform, close_center, close_sz, -10.0,
		PreGameDraw.LIME, close_label, close_font, PreGameDraw.INK, true)
	PreGameDraw.pop_xform(self)


func _draw_confirm_char(s: float, center: Vector2) -> void:
	var card_size := Vector2(684.0, 294.0) * s
	var xform := PreGameDraw.draw_card(self, center, card_size, -0.8, 0.0,
		PreGameDraw.DEEP_INK, Color.BLACK, 2.0 * s, Vector2(12.0, 12.0) * s, Color.BLACK,
		[{"edge": "left", "size": 7.0 * s, "color": PreGameDraw.LIME}])
	var w := card_size.x
	var h := card_size.y
	var left := -w * 0.5
	var top := -h * 0.5
	var pad := 22.0 * s
	var mono := PreGameDraw.mono_font()
	var title := PreGameDraw.title_font()

	var spec := _protagonist_spec(char_index)
	var species_id := str(spec.get("id", ""))
	var portrait_pos := Vector2(left + pad, top + pad)
	var portrait_sz := Vector2(62.0, 62.0) * s
	draw_rect(Rect2(portrait_pos, portrait_sz), Color("77c7d7"))
	var tex: Texture2D = PreGameCatalog.species_portrait(species_id)
	if tex != null:
		draw_texture_rect(tex, Rect2(portrait_pos + Vector2(2.0, 2.0) * s, portrait_sz - Vector2(4.0, 4.0) * s), false)
	draw_rect(Rect2(portrait_pos, portrait_sz), Color.BLACK, false, 1.8 * s)

	var text_x := portrait_pos.x + portrait_sz.x + 14.0 * s
	draw_string(mono, Vector2(text_x, top + 30.0 * s),
		"CONFIRM PROTAGONIST (C1 — NO HP/MP OR FIXED NATURE)",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, maxi(6, int(round(8.5 * s))), PreGameDraw.LIME)
	draw_string(title, Vector2(text_x, top + 64.0 * s),
		str(spec.get("name", "Unknown")).to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, maxi(10, int(round(30.0 * s))), PreGameDraw.PAPER)
	var elem_names := PackedStringArray()
	for e_val in spec.get("elements", []):
		var einfo := PreGameDraw.elem_info(int(e_val))
		elem_names.append(str(einfo.get("name", "")).capitalize())
	var elem_str := " / ".join(elem_names) if not elem_names.is_empty() else "Physical"
	draw_string(mono, Vector2(text_x, top + 84.0 * s),
		"Height: %.2fm | Innate: %s" % [float(spec.get("height", 0.0)), elem_str],
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, maxi(6, int(round(8.5 * s))), PreGameDraw.TEXT_SUB)

	var sec_x := left + pad
	var sec_w := w - pad * 2.0
	var sec_y := top + 112.0 * s
	var sections: Array[Dictionary] = [
		{"head": "[ BASE 15-PT ATTRIBUTES (D-390) ]", "col": PreGameDraw.CYAN, "body": _base_stats_line(spec)},
		{"head": "[ STARTER KIT (C2) ]", "col": PreGameDraw.GOLD, "body": _starter_kit_line(spec)},
		{"head": "[ FIRST EXPEDITION BRIEFING (C6) ]", "col": PreGameDraw.LIME,
			"body": "1. 3D Exploration in Hub/Zone -> 2. Preemptive Strike on encounter -> 3. 5-Block ATB Combat. Expedition Nature rolls at Expedition Start (R18-Q4)."},
	]
	for row in sections:
		_draw_section(sec_x, sec_y, sec_w, str(row.get("head", "")),
			row.get("col", PreGameDraw.PAPER), str(row.get("body", "")), s)
		sec_y += 44.0 * s

	var right_edge := w * 0.5 - pad
	var start_font := maxi(9, int(round(14.5 * s)))
	var start_label := "START EXPEDITION ROULETTE [ENTER]"
	var start_sz := Vector2(title.get_string_size(start_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, start_font).x + 28.0 * s, 28.0 * s)
	var start_center := Vector2(right_edge - start_sz.x * 0.5, top + h - 22.0 * s)
	_hit_confirm_start = _draw_blade(self, xform, start_center, start_sz, -10.0,
		PreGameDraw.LIME, start_label, start_font, PreGameDraw.INK, true)

	var cancel_font := maxi(7, int(round(9.5 * s)))
	var cancel_label := "CANCEL [X]"
	var cancel_sz := _chip_size(cancel_label, cancel_font)
	var cancel_pos := Vector2(right_edge - start_sz.x - 14.0 * s - cancel_sz.x, top + h - 22.0 * s - cancel_sz.y * 0.5)
	_hit_confirm_cancel = _draw_chip(self, xform, cancel_pos, cancel_label, cancel_font,
		PreGameDraw.CARD_INK, Color("1e3f54"), PreGameDraw.PAPER)
	PreGameDraw.pop_xform(self)


# --- Drawing primitives -------------------------------------------------------

func _draw_section(x: float, y: float, width: float, head: String, head_col: Color, body_text: String, s: float) -> void:
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	var head_size := maxi(6, int(round(9.0 * s)))
	var body_size := maxi(6, int(round(9.5 * s)))
	draw_string(mono, Vector2(x, y), head, HORIZONTAL_ALIGNMENT_LEFT, -1.0, head_size, head_col)
	var text := body_text
	if text.strip_edges().is_empty():
		text = "—"
	PreGameDraw.draw_wrapped_text(self, body, Vector2(x, y + 3.0 * s), text, body_size,
		PreGameDraw.TEXT_SUB, width, 1.22)


func _draw_nested_stat_chip(base_xform: Transform2D, center: Vector2, sz: Vector2, skew_deg: float,
		bg: Color, fg: Color, label: String, font_size: int, s: float) -> void:
	var skew := PreGameDraw.skew_xform(skew_deg)
	var hx := sz.x * 0.5
	var hy := sz.y * 0.5
	var local := PackedVector2Array([
		center + skew * Vector2(-hx, -hy),
		center + skew * Vector2(hx, -hy),
		center + skew * Vector2(hx, hy),
		center + skew * Vector2(-hx, hy),
	])
	var sh_off := Vector2(2.0, 2.0) * s
	var sh := PackedVector2Array()
	for p in local:
		sh.append(p + sh_off)
	draw_colored_polygon(sh, Color.BLACK)
	draw_colored_polygon(local, bg)
	var closed := PackedVector2Array(local)
	closed.append(local[0])
	draw_polyline(closed, Color.BLACK, 1.4 * s, true)
	var mono := PreGameDraw.mono_font()
	var text_w := mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var text_xf := base_xform * Transform2D(0.0, center) * skew * PreGameDraw.skew_xform(-skew_deg)
	draw_set_transform_matrix(text_xf)
	draw_string(mono, Vector2(-text_w * 0.5, (mono.get_ascent(font_size) - mono.get_descent(font_size)) * 0.5),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fg)
	draw_set_transform_matrix(base_xform)


func _draw_blade(ci: CanvasItem, base_xform: Transform2D, center: Vector2, sz: Vector2,
		skew_deg: float, fill: Color, label: String, font_size: int, text_col: Color,
		use_title_font: bool = false) -> PackedVector2Array:
	var skew := PreGameDraw.skew_xform(skew_deg)
	var hx := sz.x * 0.5
	var hy := sz.y * 0.5
	var local := PackedVector2Array([
		center + skew * Vector2(-hx, -hy),
		center + skew * Vector2(hx, -hy),
		center + skew * Vector2(hx, hy),
		center + skew * Vector2(-hx, hy),
	])
	if use_title_font:
		var sh := PackedVector2Array()
		for p in local:
			sh.append(p + Vector2(4.0, 4.0))
		ci.draw_colored_polygon(sh, Color.BLACK)
	ci.draw_colored_polygon(local, fill)
	var closed := PackedVector2Array(local)
	closed.append(local[0])
	ci.draw_polyline(closed, Color.BLACK if use_title_font else Color("234057"), 1.6 if use_title_font else 1.2, true)

	var font := PreGameDraw.title_font() if use_title_font else PreGameDraw.mono_font()
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var text_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var text_xf := base_xform * Transform2D(0.0, center) * skew * PreGameDraw.skew_xform(-skew_deg)
	ci.draw_set_transform_matrix(text_xf)
	var baseline_y := (ascent - descent) * (0.42 if use_title_font else 0.50)
	ci.draw_string(font, Vector2(-text_w * 0.5, baseline_y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_col)
	ci.draw_set_transform_matrix(base_xform)

	var global := PackedVector2Array()
	for p in local:
		global.append(base_xform * p)
	return global


func _chip_size(label: String, font_size: int) -> Vector2:
	var font := PreGameDraw.mono_font()
	var pad_x := float(font_size) * 0.85
	return Vector2(font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x + pad_x * 2.0,
		float(font_size) + 10.0)


func _draw_chip(ci: CanvasItem, base_xform: Transform2D, top_left: Vector2, label: String,
		font_size: int, fill: Color, border: Color, text_col: Color) -> PackedVector2Array:
	var font := PreGameDraw.mono_font()
	var pad_x := float(font_size) * 0.85
	var sz := _chip_size(label, font_size)
	var rect := Rect2(top_left, sz)
	ci.draw_rect(rect, fill)
	ci.draw_rect(rect, border, false, 1.0)
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	ci.draw_string(font, Vector2(top_left.x + pad_x, top_left.y + (sz.y + ascent - descent) * 0.5),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_col)
	var local := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	var global := PackedVector2Array()
	for p in local:
		global.append(base_xform * p)
	return global


func _stamp_font_size(label: String, max_text_w: float, s: float) -> int:
	var font := PreGameDraw.title_font()
	var fs := maxi(9, int(round(15.5 * s)))
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
	if w > max_text_w and w > 0.0:
		fs = maxi(8, int(floor(float(fs) * (max_text_w / w))))
	return fs


func _draw_stamp(base_xform: Transform2D, center: Vector2, label: String, col: Color, s: float) -> void:
	var font := PreGameDraw.title_font()
	var font_size := _stamp_font_size(label, 340.0 * s, s)
	var text_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var sz := Vector2(text_w + 26.0 * s, 30.0 * s)
	var half := sz * 0.5
	var xf := base_xform * Transform2D(0.0, center) * Transform2D(deg_to_rad(-2.4), Vector2.ZERO) * PreGameDraw.skew_xform(-8.0)
	draw_set_transform_matrix(xf)
	draw_rect(Rect2(-half, sz), Color(col, 0.14))
	draw_rect(Rect2(-half, sz), col, false, 2.5 * s)
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	draw_string(font, Vector2(-text_w * 0.5, (ascent - descent) * 0.44), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, col)
	draw_set_transform_matrix(base_xform)


func _in_poly(poly: PackedVector2Array, point: Vector2) -> bool:
	if poly.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, poly)


func _global_bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var gt := get_global_transform()
	var rect := Rect2(gt * poly[0], Vector2.ZERO)
	for i in range(1, poly.size()):
		rect = rect.expand(gt * poly[i])
	return rect
