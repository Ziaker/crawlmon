class_name PreGameViewAdvanced
extends Control

signal close_requested
signal species_changed(idx: int)
signal layer_changed(layer: int)

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const Affinity = preload("res://scripts/data/affinity.gd")

const C_DEEP_INK := Color("07131e")
const C_INK := Color("080e18")
const C_CARD_INK := Color("061726")
const C_HEAD_BAR := Color("040d16")
const C_LAYER_BAR := Color("091a28")
const C_BAR_LINE := Color("163042")
const C_BORDER := Color("1c3a50")
const C_CHIP_DARK := Color("0c1d2c")
const C_CYAN := Color("63d9ec")
const C_LIME := Color("d6fa66")
const C_CORAL := Color("ff746c")
const C_GOLD := Color("f0c57e")
const C_PAPER := Color("f4eee1")
const C_TEXT := Color("b7cad1")
const C_MUTED := Color("7e9ca8")
const C_DOMAIN := Color("8fb4c2")
const C_TILE := Color("0b1c29")
const C_FOOTER := Color("081421")
const C_GRID := Color("163042")
const C_TABLE_HEAD := Color("0c2233")
const C_PANEL := Color("071a27")
const C_KICKER := Color("6b5a2a")
const C_PAPER_SUB := Color("5d6b6b")

const C_TAB_LABELS: Array[String] = [
	"1. SELECTION SPEC",
	"2. SPECIES DOSSIER (LV.1/10/20)",
	"3. BUILD SIMULATOR (LV.50) & 48-EV",
	"4. [DEBUG] EXPEDITION SIMULATOR",
]

const C_NATURE_LABELS: Array[String] = [
	"Hardy", "Docile", "Brave", "Timid", "Modest", "Calm", "Jolly", "Adamant",
]

var char_index: int = 0
var adv_layer: int = 2
var dossier_level: int = 1
var learn_filter: String = "ALL"
var compare_idx: int = 1
var reveal_unknowns: bool = false
var debug_dev_spec: bool = false
var sim_level: int = 50
var sim_nature_id: String = "hardy"
var sim_alloc: Dictionary = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
var sim_batch_log: Array[Dictionary] = []

var _s: float = 1.0
var _origin := Vector2.ZERO
var _modal := Rect2()
var _entries: Array[Dictionary] = []
var _hit_zones: Array[Dictionary] = []
var _hover_key: String = ""
var _learn_area := Rect2()
var _batch_area := Rect2()
var _learn_scroll: int = 0
var _batch_scroll: int = 0
var _sim_nature_open: bool = false


func open(c_idx: int, layer: int = 2) -> void:
	_ensure_entries()
	char_index = clampi(c_idx, 0, maxi(_entries.size() - 1, 0))
	adv_layer = clampi(layer, 1, 4)
	if compare_idx == char_index:
		compare_idx = (char_index + 1) % _species_count()
	_hover_key = ""
	_learn_scroll = 0
	_batch_scroll = 0
	_sim_nature_open = false
	queue_redraw()


func set_species(c_idx: int) -> void:
	_ensure_entries()
	var next := clampi(c_idx, 0, maxi(_entries.size() - 1, 0))
	if next == char_index:
		return
	char_index = next
	if compare_idx == char_index:
		compare_idx = (char_index + 1) % _species_count()
	_learn_scroll = 0
	species_changed.emit(char_index)
	queue_redraw()


func set_layer(layer: int) -> void:
	var next := clampi(layer, 1, 4)
	if next == adv_layer:
		return
	adv_layer = next
	layer_changed.emit(adv_layer)
	queue_redraw()


func run_batch_sim(count: int) -> void:
	_ensure_entries()
	var total := 10 if count <= 10 else 20
	sim_batch_log.clear()
	var entry := _entry(char_index)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in total:
		var offsets := CrawlmonAttributeMath.roll_individual_offsets(rng)
		var nature_id := PreGameCatalog._roll_nature_id()
		var nature := PreGameCatalog.get_nature_by_id(nature_id)
		var mods: Dictionary = nature.get("mods", {})
		var tag := "PURE 0/0"
		if not mods.is_empty():
			tag = str(nature.get("mods_text", "")).replace("  ·  ", " / ")
			if tag == "No stat changes":
				tag = "PURE 0/0"
		var cons := PreGameCatalog.consolidate_stats(entry, nature_id, offsets, 1)
		sim_batch_log.append({
			"#": i + 1,
			"nature_id": nature_id,
			"nature_name": str(cons.get("nature_name", nature.get("name", nature_id))),
			"tag": tag,
			"stat_sum": int(cons.get("stats_total", 0)),
			"hp": int(cons.get("max_hp", 0)),
			"mp": int(cons.get("max_mp", 0)),
		})
	_batch_scroll = 0
	queue_redraw()


func handle_gui_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var zone := _zone_at(motion.position)
		var key := ""
		if not zone.is_empty():
			key = _zone_key(str(zone.get("id", "")), zone.get("data", {}))
		if key != _hover_key:
			_hover_key = key
			queue_redraw()
		return true
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP or button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if not button.pressed:
				return false
			var step := -1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1
			if _learn_area.has_point(button.position):
				var rows := _filtered_learn_rows(_entry(char_index)).size()
				var visible := _learn_visible_rows()
				_learn_scroll = clampi(_learn_scroll + step, 0, maxi(0, rows - visible))
				queue_redraw()
				return true
			if _batch_area.has_point(button.position):
				var batch_visible := _batch_visible_rows()
				_batch_scroll = clampi(_batch_scroll + step, 0, maxi(0, sim_batch_log.size() - batch_visible))
				queue_redraw()
				return true
			return false
		if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			var zone := _zone_at(button.position)
			if not zone.is_empty():
				_activate(str(zone.get("id", "")), zone.get("data", {}))
				return true
	return false


func handle_key_action(action: String) -> bool:
	match action:
		"back", "toggle_adv":
			close_requested.emit()
			return true
		"tab_left":
			set_layer(adv_layer - 1)
			return true
		"tab_right":
			set_layer(adv_layer + 1)
			return true
		"left":
			if adv_layer <= 2:
				set_species((char_index - 1 + _species_count()) % _species_count())
			else:
				set_layer(adv_layer - 1)
			return true
		"right":
			if adv_layer <= 2:
				set_species((char_index + 1) % _species_count())
			else:
				set_layer(adv_layer + 1)
			return true
		"layer_1":
			set_layer(1)
			return true
		"layer_2":
			set_layer(2)
			return true
		"layer_3":
			set_layer(3)
			return true
		"layer_4":
			set_layer(4)
			return true
		"reveal":
			reveal_unknowns = not reveal_unknowns
			queue_redraw()
			return true
	return false


func _draw() -> void:
	_hit_zones.clear()
	_learn_area = Rect2()
	_batch_area = Rect2()
	_s = minf(size.x / 1280.0, size.y / 720.0)
	if _s <= 0.0:
		return
	_entries = PreGameCatalog.build_protagonist_list()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.016, 0.043, 0.071, 0.90))
	var cw := 1120.0 * _s
	var ch := 633.0 * _s
	_origin = (size - Vector2(cw, ch)) * 0.5
	_modal = Rect2(_origin, Vector2(cw, ch))
	draw_rect(Rect2(_origin + Vector2(12.0, 12.0) * _s, Vector2(cw, ch)), Color.BLACK)
	draw_rect(_modal, C_DEEP_INK)
	draw_rect(Rect2(_origin, Vector2(7.0 * _s, ch)), C_CYAN)
	draw_rect(_modal, Color.BLACK, false, 2.0 * _s)
	_draw_head()
	_draw_layer_bar()
	match adv_layer:
		1:
			_draw_layer1()
		2:
			_draw_layer2()
		3:
			_draw_layer3()
		_:
			_draw_layer4()


func _draw_head() -> void:
	var bar := Rect2(Vector2(_origin.x, _origin.y), Vector2(_modal.size.x, 42.0 * _s))
	draw_rect(bar, C_HEAD_BAR)
	draw_line(Vector2(bar.position.x, bar.end.y), Vector2(bar.end.x, bar.end.y), Color.BLACK, 1.5 * _s)
	var title_font := PreGameDraw.title_font()
	var title_fs := _fs(19.0)
	var title := "ADVANCED DOSSIER"
	var baseline := bar.position.y + (bar.size.y + title_font.get_ascent(title_fs) - title_font.get_descent(title_fs)) * 0.5
	draw_string(title_font, Vector2(bar.position.x + 20.0 * _s, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, C_LIME)
	var body := PreGameDraw.body_font()
	var chip_fs := _fs(8.0)
	var chip_h := 20.0 * _s
	var chip_y := bar.position.y + (bar.size.y - chip_h) * 0.5
	var title_w := title_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs).x
	var chip_x := bar.position.x + 20.0 * _s + title_w + 14.0 * _s
	for i in _entries.size():
		var label := str(_entries[i].get("name", "")).to_upper()
		var w := body.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, chip_fs).x + 16.0 * _s
		var active := i == char_index
		_draw_skew_chip(Rect2(Vector2(chip_x, chip_y), Vector2(w, chip_h)), label,
			C_LIME if active else C_CHIP_DARK, C_INK if active else C_PAPER, chip_fs, "species", {"idx": i})
		chip_x += w + 5.0 * _s
	var close_label := "CLOSE [A / TAB / ESC]"
	var close_fs := _fs(8.0)
	var close_h := 21.0 * _s
	var close_w := body.get_string_size(close_label, HORIZONTAL_ALIGNMENT_LEFT, -1, close_fs).x + 16.0 * _s
	var close_rect := Rect2(Vector2(bar.end.x - 16.0 * _s - close_w, bar.position.y + (bar.size.y - close_h) * 0.5), Vector2(close_w, close_h))
	_draw_skew_chip(close_rect, close_label, C_CORAL, C_INK, close_fs, "close")
	var reveal_label := "REVEAL UNKNOWNS (D-981): " + ("ON" if reveal_unknowns else "OFF")
	var reveal_w := body.get_string_size(reveal_label, HORIZONTAL_ALIGNMENT_LEFT, -1, chip_fs).x + 16.0 * _s
	var reveal_rect := Rect2(Vector2(close_rect.position.x - 10.0 * _s - reveal_w, close_rect.position.y), Vector2(reveal_w, close_h))
	_draw_skew_chip(reveal_rect, reveal_label, C_GOLD if reveal_unknowns else C_CHIP_DARK,
		C_INK if reveal_unknowns else C_CYAN, chip_fs, "reveal")


func _draw_layer_bar() -> void:
	var bar := Rect2(Vector2(_origin.x, _origin.y + 42.0 * _s), Vector2(_modal.size.x, 52.0 * _s))
	draw_rect(bar, C_LAYER_BAR)
	draw_line(Vector2(bar.position.x, bar.end.y), Vector2(bar.end.x, bar.end.y), C_BAR_LINE, 1.5 * _s)
	var mono := PreGameDraw.mono_font()
	var fs := _fs(8.2)
	var x := bar.position.x + 8.0 * _s
	var y := bar.position.y + 6.0 * _s
	var h := 22.0 * _s
	for i in C_TAB_LABELS.size():
		var label := C_TAB_LABELS[i]
		var w := mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0 * _s
		var rect := Rect2(Vector2(x, y), Vector2(w, h))
		var active := (i + 1) == adv_layer
		draw_rect(rect, C_CYAN if active else C_CHIP_DARK)
		draw_rect(rect, Color.BLACK if active else C_BAR_LINE, false, 1.0 * _s)
		if _zone_key("layer", {"layer": i + 1}) == _hover_key:
			draw_rect(rect.grow(1.0 * _s), C_PAPER, false, 1.0 * _s)
		_centered_text(rect, label, mono, fs, C_INK if active else C_DOMAIN)
		_hit_zones.append({"id": "layer", "rect": rect, "data": {"layer": i + 1}})
		x += w + 5.0 * _s
	var subtitle := "3-LAYER SPEC // CHARACTER SELECTION -> DOSSIER LV.1/10/20 -> SIMULATOR LV.50"
	draw_string(mono, Vector2(bar.position.x + 24.0 * _s, bar.end.y - 8.0 * _s), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(7.5), C_MUTED)


func _draw_layer1() -> void:
	var entry := _entry(char_index)
	var left := _col_left()
	var right := _col_right()
	left.size.y = 184.0 * _s
	right.size.y = 184.0 * _s
	_panel(left, C_PAPER, Color.BLACK, 1.5 * _s, Vector2(4.0, 4.0) * _s)
	_panel(right, C_CARD_INK, C_BORDER, 1.0 * _s, Vector2(4.0, 4.0) * _s)
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	var species_name := str(entry.get("name", "")).to_upper()
	var kicker := "LAYER 1 // CLEAN SELECTION SUMMARY (" + species_name + ")"
	var kicker_fs := _fs(9.5)
	draw_string(mono, Vector2(left.position.x + 12.0 * _s, left.position.y + 19.0 * _s),
		kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_fs, Color("0e2435"))
	var height_text := "%.2fm" % float(entry.get("height", 1.0))
	var height_w := mono.get_string_size(height_text, HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_fs).x
	draw_string(mono, Vector2(left.end.x - 12.0 * _s - height_w, left.position.y + 19.0 * _s), height_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_fs, Color("0e2435"))
	draw_line(Vector2(left.position.x + 12.0 * _s, left.position.y + 25.0 * _s),
		Vector2(left.end.x - 12.0 * _s, left.position.y + 25.0 * _s), Color(0.039, 0.102, 0.153, 0.20), 1.0 * _s)
	var portrait := Rect2(Vector2(left.position.x + 12.0 * _s, left.position.y + 34.0 * _s), Vector2(68.0, 68.0) * _s)
	var tex: Texture2D = entry.get("portrait_icon", null) as Texture2D
	if tex == null:
		tex = PreGameCatalog.species_portrait(str(entry.get("id", "")))
	if tex != null:
		draw_rect(portrait, Color("77c7d7"))
		draw_texture_rect(tex, portrait, false)
	else:
		draw_rect(portrait, Color("77c7d7"))
	draw_rect(portrait, Color("234057"), false, 2.0 * _s)
	var bx := portrait.end.x + 12.0 * _s
	var bw := left.end.x - 12.0 * _s - bx
	var starters: Array = entry.get("starter_moves", [])
	var m1 := str(PreGameCatalog.get_move_spec(str(starters[1])).get("name", "Move 1")) if starters.size() > 1 else "Move 1"
	var m2 := str(PreGameCatalog.get_move_spec(str(starters[2])).get("name", "Move 2")) if starters.size() > 2 else "Move 2"
	var bullets := PackedStringArray([
		"All 6 Protagonists Unlocked: Selectable immediately under NEW GAME.",
		"Starter Kit (C2): Universal Tackle + %s + %s." % [m1, m2],
		"HP/MP & Nature: Excluded from basic Selection (C1); Nature rolls at Gate (R18-Q4).",
	])
	var by := portrait.position.y
	var bullet_fs := _fs(10.5)
	for text in bullets:
		var used := PreGameDraw.draw_wrapped_text(self, body, Vector2(bx, by), text, bullet_fs, C_INK, bw, 1.30)
		by += used + 2.0 * _s
	var foot := Rect2(Vector2(left.position.x + 10.0 * _s, left.end.y - 42.0 * _s), Vector2(left.size.x - 20.0 * _s, 33.0 * _s))
	draw_rect(foot, Color("081624"))
	_hit_zones.append({"id": "raw_toggle", "rect": foot, "data": {}})
	if _zone_key("raw_toggle", {}) == _hover_key:
		draw_rect(foot.grow(1.0 * _s), C_CYAN, false, 1.0 * _s)
	var base_stats: Dictionary = entry.get("base_stats", {})
	var base_parts := PackedStringArray()
	for stat in PreGameCatalog.STAT_ORDER:
		base_parts.append("%s=%d" % [stat, int(base_stats.get(stat, 0))])
	draw_string(mono, Vector2(foot.position.x + 8.0 * _s, foot.position.y + 13.0 * _s),
		"15-PT INNATE DISTRIBUTION (D-390): " + " · ".join(base_parts), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.6), C_PAPER)
	var raw_stats: Dictionary = entry.get("raw_stats", {})
	var raw_parts := PackedStringArray()
	for stat in PreGameCatalog.STAT_ORDER:
		raw_parts.append("%s=%d" % [stat, int(raw_stats.get(stat, 0))])
	draw_string(mono, Vector2(foot.position.x + 8.0 * _s, foot.position.y + 27.0 * _s),
		"RAW SOURCE DATA [SHIFT]: " + " · ".join(raw_parts), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.6), C_PAPER)
	_draw_layer1_briefing(right)


func _draw_layer1_briefing(rect: Rect2) -> void:
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, rect.position.y + 19.0 * _s),
		"FIRST EXPEDITION BRIEFING (C6) & PIPELINE (C8)", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.5), C_CYAN)
	var lines: Array[String] = [
		"1. NEW GAME: Select Species → Confirm → Roll Expedition Nature (R18-Q4) → Hub / First Expedition.",
		"2. CONTINUE: Resumes Hub 3D with saved party/progress without re-picking protagonist or re-rolling Nature.",
		"3. NEW EXPEDITION (HUB GATE): Previews Briefing → Spins R18-Q4 Nature Roulette → Enters 3D Expedition (Real-Time Explore → Strike → ATB Combat).",
	]
	var y := rect.position.y + 32.0 * _s
	var fs := _fs(10.5)
	for line in lines:
		var used := PreGameDraw.draw_wrapped_text(self, body, Vector2(rect.position.x + 12.0 * _s, y), line, fs, C_TEXT, rect.size.x - 24.0 * _s, 1.38)
		y += used + 4.0 * _s


func _draw_layer2() -> void:
	var left := _col_left()
	var right := _col_right()
	left.size.y = 358.0 * _s
	right.size.y = 358.0 * _s
	_panel(left, C_CARD_INK, C_BORDER, 1.0 * _s, Vector2(4.0, 4.0) * _s)
	_panel(right, C_CARD_INK, C_BORDER, 1.0 * _s, Vector2(4.0, 4.0) * _s)
	var entry := _entry(char_index)
	_draw_dossier(left, entry)
	_draw_learn_tree(right, entry)


func _draw_dossier(rect: Rect2, entry: Dictionary) -> void:
	var mono := PreGameDraw.mono_font()
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, rect.position.y + 19.0 * _s),
		"REFERENCE STATS & MILESTONE", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.5), C_CYAN)
	var levels: Array[int] = [1, 10, 20]
	var label_fs := _fs(8.8)
	var widths: Array[float] = []
	var total_w := 0.0
	for level in levels:
		var w := mono.get_string_size("LV.%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, label_fs).x + 12.0 * _s
		widths.append(w)
		total_w += w
	total_w += 4.0 * 2.0 * _s
	var px := rect.end.x - 10.0 * _s - total_w
	for i in levels.size():
		var w: float = widths[i]
		_draw_pill(Rect2(Vector2(px, rect.position.y + 7.0 * _s), Vector2(w, 18.0 * _s)),
			"LV.%d" % levels[i], dossier_level == levels[i], "dossier_level", {"level": levels[i]}, C_LIME, label_fs)
		px += w + 4.0 * _s
	var alloc := _uniform_alloc(dossier_level)
	var cons := PreGameCatalog.consolidate_stats(entry, "hardy", alloc, dossier_level)
	var kpis := [
		{"label": "HP BASE", "value": str(int(cons.get("max_hp", 0))), "color": C_CORAL},
		{"label": "MP BASE", "value": str(int(cons.get("max_mp", 0))), "color": Color("38bdf8")},
		{"label": "ATB SPD", "value": "%.3f" % float(cons.get("atb_speed", 0.0)), "color": C_LIME},
		{"label": "BONUS PTS", "value": "+%d" % int(cons.get("bonus_points", 0)), "color": C_GOLD},
	]
	var inner_x := rect.position.x + 10.0 * _s
	var inner_w := rect.size.x - 20.0 * _s
	var gap := 6.0 * _s
	var kw := (inner_w - gap * 3.0) * 0.25
	var ky := rect.position.y + 34.0 * _s
	var kh := 46.0 * _s
	for i in kpis.size():
		var r := Rect2(Vector2(inner_x + float(i) * (kw + gap), ky), Vector2(kw, kh))
		var accent: Color = kpis[i]["color"]
		draw_rect(r, Color("06111b"))
		draw_rect(Rect2(r.position, Vector2(3.0 * _s, r.size.y)), accent)
		draw_string(mono, Vector2(r.position.x + 8.0 * _s, r.position.y + 14.0 * _s),
			str(kpis[i]["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.2), C_MUTED)
		draw_string(mono, Vector2(r.position.x + 8.0 * _s, r.position.y + 36.0 * _s),
			str(kpis[i]["value"]), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(16.0), C_PAPER)
	var affinities: Dictionary = entry.get("affinities", {})
	var aff_header := "%s — 12 ELEMENT AFFINITIES (D-397 / D-440)" % str(entry.get("name", "")).to_upper()
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, rect.position.y + 100.0 * _s), aff_header,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.2), C_CYAN)
	var tile_gap := 3.0 * _s
	var tw := (inner_w - tile_gap * 11.0) / 12.0
	var th := 42.0 * _s
	var ty := rect.position.y + 108.0 * _s
	for idx in 12:
		var r := Rect2(Vector2(inner_x + float(idx) * (tw + tile_gap), ty), Vector2(tw, th))
		_draw_affinity_tile(r, idx, affinities, true)
	var cmp_y := ty + th + 20.0 * _s
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, cmp_y + 12.0 * _s),
		"SPECIES COMPARATOR (D-981 DISCOVERY POLICY)", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.8), C_CYAN)
	var others: Array[int] = []
	for i in _entries.size():
		if i != char_index:
			others.append(i)
	var compare_fs := _fs(7.6)
	var total_cmp_w := mono.get_string_size("vs ", HORIZONTAL_ALIGNMENT_LEFT, -1, compare_fs).x
	for idx in others:
		total_cmp_w += mono.get_string_size(str(_entries[idx].get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, compare_fs).x + 10.0 * _s + 3.0 * _s
	var vx := rect.end.x - 10.0 * _s - total_cmp_w
	draw_string(mono, Vector2(vx, cmp_y + 12.0 * _s), "vs", HORIZONTAL_ALIGNMENT_LEFT, -1, compare_fs, C_MUTED)
	vx += mono.get_string_size("vs ", HORIZONTAL_ALIGNMENT_LEFT, -1, compare_fs).x
	for idx in others:
		var label := str(_entries[idx].get("name", ""))
		var w := mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, compare_fs).x + 10.0 * _s
		_draw_pill(Rect2(Vector2(vx, cmp_y), Vector2(w, 16.0 * _s)), label, idx == compare_idx,
			"compare", {"idx": idx}, C_CYAN, compare_fs)
		vx += w + 3.0 * _s
	var cmp_entry := _entry(compare_idx)
	var cmp_aff: Dictionary = cmp_entry.get("affinities", {})
	var uy := cmp_y + 22.0 * _s
	for idx in 12:
		var r := Rect2(Vector2(inner_x + float(idx) * (tw + tile_gap), uy), Vector2(tw, th))
		if reveal_unknowns:
			_draw_affinity_tile(r, idx, cmp_aff, true)
		else:
			var tile_r := Rect2(r.position, Vector2(r.size.x, r.size.y - 14.0 * _s))
			draw_rect(tile_r, Color("0c1824"))
			_draw_dashed_rect(tile_r, Color("475569"), 1.2 * _s, 3.0 * _s, 2.0 * _s)
			_centered_text(tile_r, "?", mono, _fs(10.0), C_MUTED)
			var letter_r := Rect2(Vector2(r.position.x, r.end.y - 13.0 * _s), Vector2(r.size.x, 12.0 * _s))
			_centered_text(letter_r, "?", mono, _fs(8.0), Color("64748b"))
	var cap_txt := ("[DEBUG: REVEAL ALL AFFINITIES] Enabled — comparing raw affinity table for " + str(cmp_entry.get("name", ""))) if reveal_unknowns else "[ ? ] UNKNOWN (D-981) — Wild/other species remain hidden until discovered in combat."
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, uy + th + 16.0 * _s),
		cap_txt, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0 * _s, _fs(8.2), C_GOLD if reveal_unknowns else C_MUTED)


func _draw_affinity_tile(rect: Rect2, elem_id: int, affinities: Dictionary, show_letter: bool) -> void:
	var icon_h := rect.size.y - 14.0 * _s
	var icon_rect := Rect2(rect.position, Vector2(rect.size.x, icon_h))
	var info := PreGameDraw.elem_info(elem_id)
	var affinity := int(affinities.get(elem_id, 0))
	var bg: Color = info.get("bg", C_TILE)
	var fg: Color = info.get("fg", Color.WHITE)
	var alpha := 0.30 if affinity == 0 else 1.0
	draw_rect(icon_rect, Color(bg.r, bg.g, bg.b, alpha))
	draw_rect(icon_rect, Color.BLACK, false, 1.0 * _s)
	var tex := PreGameDraw.load_icon(str(info.get("svg_path", "")))
	if tex != null:
		var isz := minf(rect.size.x - 8.0 * _s, icon_h - 6.0 * _s)
		var ipos := Vector2(icon_rect.position.x + (icon_rect.size.x - isz) * 0.5, icon_rect.position.y + (icon_rect.size.y - isz) * 0.5)
		draw_texture_rect(tex, Rect2(ipos, Vector2(isz, isz)), false, Color(fg.r, fg.g, fg.b, alpha))
	if not show_letter:
		return
	var letter := "–"
	var col := C_MUTED
	if affinity == int(Affinity.Type.WEAK):
		letter = "W"
		col = C_CORAL
	elif affinity == int(Affinity.Type.RESIST):
		letter = "R"
		col = C_CYAN
	var letter_r := Rect2(Vector2(rect.position.x, rect.end.y - 13.0 * _s), Vector2(rect.size.x, 12.0 * _s))
	_centered_text(letter_r, letter, PreGameDraw.mono_font(), _fs(8.5), col)


func _draw_learn_tree(rect: Rect2, entry: Dictionary) -> void:
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, rect.position.y + 19.0 * _s),
		"MOVE LEARN TREE (LV.1 / LV.10 / LV.20)", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.5), C_CYAN)
	var filters: Array[String] = ["ALL", "LV.1", "LV.10", "LV.20"]
	var filter_fs := _fs(8.5)
	var total := 0.0
	for filter in filters:
		total += mono.get_string_size(filter, HORIZONTAL_ALIGNMENT_LEFT, -1, filter_fs).x + 12.0 * _s
	total += 4.0 * 3.0 * _s
	var fx := rect.end.x - 10.0 * _s - total
	for filter in filters:
		var w := mono.get_string_size(filter, HORIZONTAL_ALIGNMENT_LEFT, -1, filter_fs).x + 12.0 * _s
		_draw_pill(Rect2(Vector2(fx, rect.position.y + 7.0 * _s), Vector2(w, 17.0 * _s)), filter,
			learn_filter == filter, "learn_filter", {"filter": filter}, C_LIME, filter_fs)
		fx += w + 4.0 * _s
	var rows := _filtered_learn_rows(entry)
	var top := rect.position.y + 29.0 * _s
	var bottom := rect.end.y - 6.0 * _s
	var row_h := 24.0 * _s
	var row_gap := 4.0 * _s
	var step := row_h + row_gap
	var visible := maxi(1, int(floor((bottom - top + row_gap) / step)))
	_learn_scroll = clampi(_learn_scroll, 0, maxi(0, rows.size() - visible))
	_learn_area = Rect2(Vector2(rect.position.x, top), Vector2(rect.size.x, bottom - top))
	for i in range(_learn_scroll, mini(rows.size(), _learn_scroll + visible)):
		var row: Dictionary = rows[i]
		var ry := top + float(i - _learn_scroll) * step
		_draw_learn_row(Rect2(Vector2(rect.position.x + 10.0 * _s, ry), Vector2(rect.size.x - 20.0 * _s, row_h)), row)
	if rows.size() > visible:
		var hint := "SCROLL  ·  %d/%d" % [mini(_learn_scroll + visible, rows.size()), rows.size()]
		draw_string(mono, Vector2(rect.end.x - 12.0 * _s - mono.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(7.5)).x, bottom - 2.0 * _s),
			hint, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(7.5), C_MUTED)


func _draw_learn_row(rect: Rect2, row: Dictionary) -> void:
	var mono := PreGameDraw.mono_font()
	draw_rect(rect, Color("07131e"))
	draw_rect(rect, Color("1b364d"), false, 1.0 * _s)
	var pill_h := 16.0 * _s
	var item_y := rect.position.y + (rect.size.y - pill_h) * 0.5
	var pill := Rect2(Vector2(rect.position.x + 8.0 * _s, item_y), Vector2(36.0 * _s, pill_h))
	draw_rect(pill, C_LIME)
	_centered_text(pill, "LV.%d" % int(row.get("level", 1)), mono, _fs(8.5), C_INK)
	var move_id := str(row.get("move", ""))
	var spec := PreGameCatalog.get_move_spec(move_id)
	var elem := int(spec.get("elem", 0))
	var chip_w := PreGameDraw.draw_elem_chip(self, Vector2(pill.end.x + 6.0 * _s, item_y), elem, pill_h, true)
	var fs := _fs(8.4)
	var base_y := rect.get_center().y + (mono.get_ascent(fs) - mono.get_descent(fs)) * 0.5
	var name_text := str(spec.get("name", move_id.capitalize())).to_upper()
	var name_x := pill.end.x + 6.0 * _s + chip_w + 6.0 * _s
	draw_string(mono, Vector2(name_x, base_y), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_PAPER)
	var name_w := mono.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tag := "[" + str(row.get("tag", "")) + "]"
	var tag_x := name_x + name_w + 5.0 * _s
	draw_string(mono, Vector2(tag_x, base_y), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_CYAN)
	var left_end := tag_x + mono.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8.0 * _s
	var stat_raw := str(spec.get("text", "")).split("|")[0].strip_edges()
	var desc_fs := _fs(7.6)
	var desc_y := rect.get_center().y + (mono.get_ascent(desc_fs) - mono.get_descent(desc_fs)) * 0.5
	var right_line := "%d ATB · %d MP · %s" % [int(spec.get("atb", 0)), int(spec.get("mp", 0)), stat_raw]
	var max_rw := maxf(40.0 * _s, (rect.end.x - 8.0 * _s) - left_end)
	var right_w := mono.get_string_size(right_line, HORIZONTAL_ALIGNMENT_LEFT, -1, desc_fs).x
	if right_w > max_rw:
		var trimmed := stat_raw
		while trimmed.length() > 8:
			var cut := trimmed.rfind(" ")
			trimmed = trimmed.substr(0, cut if cut > 4 else trimmed.length() - 4).strip_edges()
			right_line = "%d ATB · %d MP · %s..." % [int(spec.get("atb", 0)), int(spec.get("mp", 0)), trimmed]
			right_w = mono.get_string_size(right_line, HORIZONTAL_ALIGNMENT_LEFT, -1, desc_fs).x
			if right_w <= max_rw:
				break
		if right_w > max_rw:
			right_line = "%d ATB · %d MP" % [int(spec.get("atb", 0)), int(spec.get("mp", 0))]
			right_w = mono.get_string_size(right_line, HORIZONTAL_ALIGNMENT_LEFT, -1, desc_fs).x
	var draw_w := minf(right_w, max_rw)
	draw_string(mono, Vector2(rect.end.x - 8.0 * _s - draw_w, desc_y), right_line,
		HORIZONTAL_ALIGNMENT_LEFT, draw_w, desc_fs, Color("9ec0cc"))


func _draw_layer3() -> void:
	var left := _col_left()
	var right := _col_right()
	left.size.y = 266.0 * _s
	right.size.y = 330.0 * _s
	_panel(left, C_CARD_INK, C_BORDER, 1.0 * _s, Vector2(4.0, 4.0) * _s)
	_panel(right, C_CARD_INK, C_BORDER, 1.0 * _s, Vector2(4.0, 4.0) * _s)
	_draw_combo_table(right)
	_draw_simulator(left)


func _draw_simulator(rect: Rect2) -> void:
	var entry := _entry(char_index)
	var mono := PreGameDraw.mono_font()
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, rect.position.y + 19.0 * _s),
		"BUILD SIMULATOR (LV.%d) — THEORYCRAFT ONLY" % sim_level, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.2), C_CYAN)
	var budget_total := PreGameCatalog.total_bonus_points_at_level(sim_level)
	var remaining := maxi(budget_total - _sim_alloc_total(), 0)
	var reset_label := "Reset"
	var reset_fs := _fs(8.5)
	var reset_w := mono.get_string_size(reset_label, HORIZONTAL_ALIGNMENT_LEFT, -1, reset_fs).x + 14.0 * _s
	var reset_rect := Rect2(Vector2(rect.end.x - 10.0 * _s - reset_w, rect.position.y + 7.0 * _s), Vector2(reset_w, 18.0 * _s))
	_draw_pill(reset_rect, reset_label, false, "sim_reset", {}, C_CYAN, reset_fs)
	var budget_text := "Budget Remaining: %d / %d pts" % [remaining, budget_total]
	var budget_w := mono.get_string_size(budget_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.8)).x
	draw_string(mono, Vector2(reset_rect.position.x - 8.0 * _s - budget_w, rect.position.y + 19.0 * _s), budget_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.8), C_LIME if remaining == 0 else C_GOLD)
	var row_y := rect.position.y + 34.0 * _s
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, row_y + 13.0 * _s), "Target Lv:", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.8), C_TEXT)
	var lx := rect.position.x + 76.0 * _s
	var level_fs := _fs(8.5)
	var level_values: Array[int] = [1, 10, 20, 50]
	for level in level_values:
		var label := "Lv.%d" % level
		var w := mono.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, level_fs).x + 12.0 * _s
		_draw_pill(Rect2(Vector2(lx, row_y), Vector2(w, 18.0 * _s)), label, sim_level == level, "sim_level", {"level": level}, C_LIME, level_fs)
		lx += w + 4.0 * _s
	var cur_nat := PreGameCatalog.get_nature_by_id(sim_nature_id)
	var nat_disp := str(cur_nat.get("name", sim_nature_id))
	if sim_nature_id in ["hardy", "docile"]:
		nat_disp += " (PURE DISCIPLINE)"
	var drop_w := 178.0 * _s
	var drop_rect := Rect2(Vector2(rect.end.x - 10.0 * _s - drop_w, row_y), Vector2(drop_w, 18.0 * _s))
	var hyp_txt := "Hypothetical Nature:"
	var hyp_w := mono.get_string_size(hyp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.5)).x
	draw_string(mono, Vector2(drop_rect.position.x - 6.0 * _s - hyp_w, row_y + 13.0 * _s), hyp_txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.5), C_TEXT)
	draw_rect(drop_rect, Color("05101a"))
	draw_rect(drop_rect, C_LIME if _sim_nature_open else Color("475569"), false, 1.0 * _s)
	draw_string(mono, Vector2(drop_rect.position.x + 6.0 * _s, row_y + 13.0 * _s),
		_ellipsize(mono, nat_disp, _fs(8.5), drop_w - 22.0 * _s), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.5), C_GOLD)
	var ax := drop_rect.end.x - 10.0 * _s
	var ay := row_y + drop_rect.size.y * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(ax - 3.5 * _s, ay - 2.0 * _s),
		Vector2(ax + 3.5 * _s, ay - 2.0 * _s),
		Vector2(ax, ay + 2.5 * _s),
	]), C_GOLD)
	_hit_zones.append({"id": "sim_nature_toggle", "rect": drop_rect, "data": {}})
	var base_stats: Dictionary = entry.get("base_stats", {})
	var mods: Dictionary = cur_nat.get("mods", {})
	var stat_row_h := 40.0 * _s
	var rows_y := rect.position.y + 66.0 * _s
	var col_w := (rect.size.x - 20.0 * _s - 10.0 * _s) * 0.5
	for i in 6:
		var stat := PreGameCatalog.STAT_ORDER[i]
		var col := i % 2
		var row := int(floor(float(i) / 2.0))
		var x0 := rect.position.x + 10.0 * _s + float(col) * (col_w + 10.0 * _s)
		var ry := rows_y + float(row) * stat_row_h
		_draw_stat_row(x0, ry, col_w, stat, base_stats, mods)
	var bar := Rect2(Vector2(rect.position.x + 10.0 * _s, rect.end.y - 42.0 * _s), Vector2(rect.size.x - 20.0 * _s, 30.0 * _s))
	draw_rect(bar, Color("05111c"))
	draw_rect(bar, Color("1e3b52"), false, 1.0 * _s)
	var cons := PreGameCatalog.consolidate_stats(entry, sim_nature_id, sim_alloc, sim_level)
	var stats: Dictionary = cons.get("stats", {})
	var crit := int(round(CrawlmonAttributeMath.critical_chance(int(stats.get("LUK", 1)), 3) * 100.0))
	var segment_fs := _fs(9.8)
	var segments: Array[Dictionary] = [
		{"label": "HP:", "value": str(int(cons.get("max_hp", 0))), "color": C_CORAL},
		{"label": "MP:", "value": str(int(cons.get("max_mp", 0))), "color": Color("38bdf8")},
		{"label": "ATB:", "value": "%.3f/s" % float(cons.get("atb_speed", 0.0)), "color": C_LIME},
		{"label": "CRIT vs LUK3:", "value": "%d%%" % crit, "color": C_GOLD},
	]
	var seg_w := (bar.size.x - 20.0 * _s) / 4.0
	for i in segments.size():
		var seg: Dictionary = segments[i]
		var sx := bar.position.x + 10.0 * _s + float(i) * seg_w
		var label := str(seg["label"])
		var value := str(seg["value"])
		var seg_col: Color = seg["color"]
		draw_string(mono, Vector2(sx, bar.position.y + 19.0 * _s), label, HORIZONTAL_ALIGNMENT_LEFT, -1, segment_fs, C_TEXT)
		var lw := mono.get_string_size(label + " ", HORIZONTAL_ALIGNMENT_LEFT, -1, segment_fs).x
		draw_string(mono, Vector2(sx + lw, bar.position.y + 19.0 * _s), value, HORIZONTAL_ALIGNMENT_LEFT, -1, segment_fs, seg_col)
	if _sim_nature_open:
		var opt_h := 18.0 * _s
		var nats := PreGameCatalog.NATURES_LIST()
		var pop := Rect2(Vector2(drop_rect.position.x, drop_rect.end.y + 2.0 * _s), Vector2(drop_w, opt_h * float(nats.size())))
		draw_rect(pop, Color("05101a"))
		draw_rect(pop, C_GOLD, false, 1.5 * _s)
		for ni in nats.size():
			var nat: Dictionary = nats[ni]
			var nid := str(nat.get("id", ""))
			var r := Rect2(Vector2(pop.position.x, pop.position.y + float(ni) * opt_h), Vector2(drop_w, opt_h))
			var sel := nid == sim_nature_id
			if sel or _zone_key("sim_nature", {"id": nid}) == _hover_key:
				draw_rect(r, Color("133046") if sel else Color("0d2234"))
			var nlabel := str(nat.get("name", nid))
			if nid in ["hardy", "docile"]:
				nlabel += " (PURE DISCIPLINE)"
			draw_string(mono, Vector2(r.position.x + 6.0 * _s, r.position.y + 13.0 * _s),
				_ellipsize(mono, nlabel, _fs(8.2), drop_w - 12.0 * _s), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.2), C_LIME if sel else C_GOLD)
			_hit_zones.append({"id": "sim_nature", "rect": r, "data": {"id": nid}})


func _draw_stat_row(x0: float, y0: float, width: float, stat: String, base_stats: Dictionary, mods: Dictionary) -> void:
	var mono := PreGameDraw.mono_font()
	var row_box := Rect2(x0, y0, width, 34.0 * _s)
	draw_rect(row_box, Color("07131e"))
	draw_rect(row_box, Color("1b364d"), false, 1.0 * _s)
	var base := int(base_stats.get(stat, 0))
	var nat := int(mods.get(stat, 0))
	var allocated := int(sim_alloc.get(stat, 0))
	var effective := maxi(1, base + nat + allocated)
	var sign_n := "+" if nat >= 0 else ""
	draw_string(mono, Vector2(x0 + 8.0 * _s, y0 + 21.0 * _s), stat, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.6), Color("9ec0cc"))
	draw_string(mono, Vector2(x0 + 36.0 * _s, y0 + 21.0 * _s), str(effective), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(11.5), Color.WHITE)
	draw_string(mono, Vector2(x0 + 58.0 * _s, y0 + 20.0 * _s), "(b%d%s%d+%d)" % [base, sign_n, nat, allocated],
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.2), Color("64748b"))
	var bw := 24.0 * _s
	var bh := 18.0 * _s
	var gap := 3.0 * _s
	var bx := x0 + width - 6.0 * _s - (bw * 3.0 + gap * 2.0)
	var by := y0 + 8.0 * _s
	var step_fs := _fs(8.2)
	_draw_pill(Rect2(Vector2(bx, by), Vector2(bw, bh)), "-", false, "sim_alloc", {"stat": stat, "delta": -1}, C_CORAL, step_fs)
	_draw_pill(Rect2(Vector2(bx + bw + gap, by), Vector2(bw, bh)), "+1", false, "sim_alloc", {"stat": stat, "delta": 1}, C_CYAN, step_fs)
	_draw_pill(Rect2(Vector2(bx + (bw + gap) * 2.0, by), Vector2(bw, bh)), "+5", false, "sim_alloc", {"stat": stat, "delta": 5}, C_LIME, step_fs)


func _draw_combo_table(rect: Rect2) -> void:
	var mono := PreGameDraw.mono_font()
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, rect.position.y + 19.0 * _s),
		"48-COMBO (SPECIES × NATURE) EV TABLE — maxi(1, b+o+n) (C7)", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.2), C_CYAN)
	var grid := Rect2(Vector2(rect.position.x + 10.0 * _s, rect.position.y + 28.0 * _s), Vector2(rect.size.x - 20.0 * _s, 0.0))
	var header_h := 24.0 * _s
	var row_h := 38.0 * _s
	var species_w := 68.0 * _s
	var col_headers: Array[String] = ["Hardy/Docile", "Brave", "Timid", "Modest", "Calm", "Jolly", "Adamant"]
	var col_keys: Array[String] = ["hardy", "brave", "timid", "modest", "calm", "jolly", "adamant"]
	var col_w := (grid.size.x - species_w) / 7.0
	var hy := grid.position.y
	draw_rect(Rect2(grid.position.x, hy, grid.size.x, header_h), C_TABLE_HEAD)
	draw_string(mono, Vector2(grid.position.x + 5.0 * _s, hy + 16.0 * _s), "Species", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(7.8), C_MUTED)
	for c in 7:
		var cx := grid.position.x + species_w + float(c) * col_w
		draw_line(Vector2(cx, hy), Vector2(cx, hy + header_h + 6.0 * row_h), C_GRID, 1.0 * _s)
		draw_string(mono, Vector2(cx + 3.0 * _s, hy + 16.0 * _s), col_headers[c], HORIZONTAL_ALIGNMENT_LEFT, col_w - 4.0 * _s, _fs(7.4), C_CYAN)
	for r in 6:
		var entry: Dictionary = _entries[r] if r < _entries.size() else {}
		var sid := str(entry.get("id", ""))
		var ry := hy + header_h + float(r) * row_h
		if r == char_index:
			draw_rect(Rect2(grid.position.x, ry, grid.size.x, row_h), Color(C_CYAN, 0.14))
		draw_line(Vector2(grid.position.x, ry), Vector2(grid.position.x + grid.size.x, ry), C_GRID, 1.0 * _s)
		var species_label := str(entry.get("name", ""))
		draw_string(mono, Vector2(grid.position.x + 5.0 * _s, ry + 18.0 * _s), species_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.2), C_LIME if r == char_index else C_PAPER)
		var combo: Dictionary = PreGameCatalog.COMBO_EV_TABLE.get(sid, {})
		for c in 7:
			var nature_id: String = col_keys[c]
			var value := str(combo.get(nature_id, "—"))
			var pieces := value.split(" [", false)
			var top_line := pieces[0]
			var bottom_line := ""
			if pieces.size() > 1:
				bottom_line = "[" + pieces[1]
			var cx2 := grid.position.x + species_w + float(c) * col_w + 4.0 * _s
			draw_string(mono, Vector2(cx2, ry + 16.0 * _s), top_line, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.0), C_PAPER)
			draw_string(mono, Vector2(cx2, ry + 29.0 * _s), bottom_line, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(7.2), C_MUTED)
	draw_string(mono, Vector2(rect.position.x + 12.0 * _s, rect.end.y - 12.0 * _s),
		"EV > 15 occurs legitimately because maxi(1, b + o + n) floors penalized stats at 1.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.0), Color("9ec0cc"))


func _draw_layer4() -> void:
	var pad := 22.0 * _s
	var rows_h := maxi(1, mini(14, sim_batch_log.size())) * 20.0 * _s
	var card_h := clampf(86.0 * _s + rows_h, 108.0 * _s, 460.0 * _s)
	var card := Rect2(Vector2(_origin.x + pad, _body_top()), Vector2(_modal.size.x - pad * 2.0, card_h))
	_panel(card, C_CARD_INK, C_BORDER, 1.0 * _s, Vector2(4.0, 4.0) * _s)
	var mono := PreGameDraw.mono_font()
	var body := PreGameDraw.body_font()
	draw_string(mono, Vector2(card.position.x + 12.0 * _s, card.position.y + 19.0 * _s),
		"[DEBUG / SIMULATOR] BATCH EXPEDITION ROLLER (R18-Q4 AUDIT — ZERO GAMEPLAY REROLL)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.5), C_CYAN)
	var button_fs := _fs(9.0)
	var label_20 := "SIMULATE 20 EXPEDITIONS"
	var label_10 := "SIMULATE 10 EXPEDITIONS"
	var w_20 := body.get_string_size(label_20, HORIZONTAL_ALIGNMENT_LEFT, -1, button_fs).x + 16.0 * _s
	var w_10 := body.get_string_size(label_10, HORIZONTAL_ALIGNMENT_LEFT, -1, button_fs).x + 16.0 * _s
	var b20 := Rect2(Vector2(card.end.x - 10.0 * _s - w_20, card.position.y + 7.0 * _s), Vector2(w_20, 20.0 * _s))
	var b10 := Rect2(Vector2(b20.position.x - 6.0 * _s - w_10, b20.position.y), Vector2(w_10, 20.0 * _s))
	_draw_pill(b20, label_20, true, "batch", {"count": 20}, C_CYAN, button_fs)
	_draw_pill(b10, label_10, true, "batch", {"count": 10}, C_LIME, button_fs)
	var count := sim_batch_log.size()
	var pure := 0
	var sum_total := 0
	for row in sim_batch_log:
		sum_total += int(row.get("stat_sum", 0))
		if str(row.get("tag", "")) == "PURE 0/0":
			pure += 1
	var mean_text := "—"
	if count > 0:
		mean_text = "%.2f" % (float(sum_total) / float(count))
	var aggregate := "Protagonist: %s  |  Runs: %d  |  Mean Stat Sum: %s  |  Pure Discipline (Hardy/Docile): %d" % [
		str(_entry(char_index).get("name", "")), count, mean_text, pure,
	]
	draw_string(mono, Vector2(card.position.x + 12.0 * _s, card.position.y + 42.0 * _s), aggregate,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(10.0), C_TEXT)
	var table := Rect2(Vector2(card.position.x + 10.0 * _s, card.position.y + 52.0 * _s),
		Vector2(card.size.x - 20.0 * _s, card.end.y - (card.position.y + 52.0 * _s) - 10.0 * _s))
	draw_rect(table, C_PANEL)
	draw_rect(table, C_BORDER, false, 1.0 * _s)
	var header_h := 22.0 * _s
	draw_rect(Rect2(table.position.x, table.position.y, table.size.x, header_h), C_TABLE_HEAD)
	var columns := [
		{"label": "Expedition #", "x": 0.02},
		{"label": "Rolled Nature", "x": 0.20},
		{"label": "Tag", "x": 0.42},
		{"label": "Total 6-Stat Sum", "x": 0.58},
		{"label": "Lv.1 HP / MP", "x": 0.80},
	]
	for column in columns:
		draw_string(mono, Vector2(table.position.x + table.size.x * float(column["x"]) + 4.0 * _s, table.position.y + 15.0 * _s),
			str(column["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.0), C_CYAN)
	var body_top := table.position.y + header_h
	var body_h := table.end.y - body_top
	var row_h := 20.0 * _s
	var visible := maxi(1, int(floor(body_h / row_h)))
	_batch_area = Rect2(table.position.x, body_top, table.size.x, body_h)
	_batch_scroll = clampi(_batch_scroll, 0, maxi(0, sim_batch_log.size() - visible))
	if sim_batch_log.is_empty():
		draw_string(mono, Vector2(table.position.x + 18.0 * _s, body_top + 18.0 * _s),
			"Click Simulate 10 or 20 Expeditions above to inspect R18-Q4 Nature draws + triangular offsets.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.2), C_MUTED)
	else:
		for i in range(_batch_scroll, mini(sim_batch_log.size(), _batch_scroll + visible)):
			var row: Dictionary = sim_batch_log[i]
			var ry := body_top + float(i - _batch_scroll) * row_h
			if (i - _batch_scroll) % 2 == 1:
				draw_rect(Rect2(table.position.x + 1.0 * _s, ry, table.size.x - 2.0 * _s, row_h), Color(1.0, 1.0, 1.0, 0.02))
			draw_line(Vector2(table.position.x, ry), Vector2(table.end.x, ry), C_GRID, 1.0 * _s)
			var base_y := ry + 14.0 * _s
			draw_string(mono, Vector2(table.position.x + table.size.x * 0.02 + 4.0 * _s, base_y),
				"#" + str(int(row.get("#", 0))), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.0), C_MUTED)
			draw_string(mono, Vector2(table.position.x + table.size.x * 0.20 + 4.0 * _s, base_y),
				str(row.get("nature_name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.0), C_PAPER)
			var tag := str(row.get("tag", ""))
			draw_string(mono, Vector2(table.position.x + table.size.x * 0.42 + 4.0 * _s, base_y),
				"PURE DISCIPLINE" if tag == "PURE 0/0" else "MODIFIED",
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.0), C_CYAN if tag == "PURE 0/0" else C_GOLD)
			draw_string(mono, Vector2(table.position.x + table.size.x * 0.58 + 4.0 * _s, base_y),
				str(int(row.get("stat_sum", 0))), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.0), C_CYAN)
			draw_string(mono, Vector2(table.position.x + table.size.x * 0.80 + 4.0 * _s, base_y),
				"%d HP / %d MP" % [int(row.get("hp", 0)), int(row.get("mp", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(9.0), C_PAPER)
		if sim_batch_log.size() > visible:
			var hint := "SCROLL  ·  %d/%d" % [mini(_batch_scroll + visible, sim_batch_log.size()), sim_batch_log.size()]
			var hint_w := mono.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.0)).x
			draw_string(mono, Vector2(table.end.x - 6.0 * _s - hint_w, table.position.y + 15.0 * _s), hint,
				HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(8.0), C_MUTED)


func _activate(id: String, data: Dictionary) -> void:
	match id:
		"close":
			close_requested.emit()
		"reveal":
			reveal_unknowns = not reveal_unknowns
			queue_redraw()
		"raw_toggle":
			debug_dev_spec = not debug_dev_spec
			queue_redraw()
		"species":
			set_species(int(data.get("idx", 0)))
		"layer":
			set_layer(int(data.get("layer", adv_layer)))
		"dossier_level":
			dossier_level = int(data.get("level", 1))
			queue_redraw()
		"compare":
			compare_idx = int(data.get("idx", compare_idx))
			queue_redraw()
		"learn_filter":
			learn_filter = str(data.get("filter", "ALL"))
			_learn_scroll = 0
			queue_redraw()
		"sim_level":
			_sim_nature_open = false
			_set_sim_level(int(data.get("level", 50)))
		"sim_nature_toggle":
			_sim_nature_open = not _sim_nature_open
			queue_redraw()
		"sim_nature":
			sim_nature_id = str(data.get("id", "hardy"))
			_sim_nature_open = false
			queue_redraw()
		"sim_reset":
			_sim_nature_open = false
			sim_alloc = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
			queue_redraw()
		"sim_alloc":
			_alloc_stat(str(data.get("stat", "STR")), int(data.get("delta", 0)))
		"batch":
			run_batch_sim(int(data.get("count", 10)))


func _set_sim_level(level: int) -> void:
	sim_level = clampi(level, 1, 50)
	_trim_alloc()
	queue_redraw()


func _alloc_stat(stat: String, delta: int) -> void:
	if not sim_alloc.has(stat):
		return
	if delta > 0:
		var room := PreGameCatalog.total_bonus_points_at_level(sim_level) - _sim_alloc_total()
		if room <= 0:
			return
		sim_alloc[stat] = int(sim_alloc.get(stat, 0)) + mini(delta, room)
	else:
		sim_alloc[stat] = maxi(0, int(sim_alloc.get(stat, 0)) + delta)
	queue_redraw()


func _trim_alloc() -> void:
	var budget := PreGameCatalog.total_bonus_points_at_level(sim_level)
	var order: Array[String] = PreGameCatalog.STAT_ORDER
	var guard := 0
	while _sim_alloc_total() > budget and guard < 512:
		var trimmed := false
		for i in range(order.size() - 1, -1, -1):
			var stat := order[i]
			if int(sim_alloc.get(stat, 0)) > 0:
				sim_alloc[stat] = int(sim_alloc.get(stat, 0)) - 1
				trimmed = true
				break
		if not trimmed:
			break
		guard += 1


func _sim_alloc_total() -> int:
	var total := 0
	for stat in PreGameCatalog.STAT_ORDER:
		total += int(sim_alloc.get(stat, 0))
	return total


func _uniform_alloc(level: int) -> Dictionary:
	var alloc: Dictionary = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
	var total := PreGameCatalog.total_bonus_points_at_level(level)
	var order: Array[String] = PreGameCatalog.STAT_ORDER
	for i in total:
		var stat := order[i % order.size()]
		alloc[stat] = int(alloc.get(stat, 0)) + 1
	return alloc


func _filtered_learn_rows(entry: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var tree_v: Variant = entry.get("learn_tree", [])
	if not (tree_v is Array):
		return out
	for item_v in (tree_v as Array):
		if not (item_v is Dictionary):
			continue
		var item: Dictionary = item_v
		if learn_filter != "ALL":
			var wanted := int(learn_filter.trim_prefix("LV."))
			if int(item.get("level", 1)) != wanted:
				continue
		out.append(item)
	return out


func _learn_visible_rows() -> int:
	if _learn_area.size.y <= 0.0:
		return 1
	return maxi(1, int(floor((_learn_area.size.y + 4.0 * _s) / (36.0 * _s))))


func _batch_visible_rows() -> int:
	if _batch_area.size.y <= 0.0:
		return 1
	return maxi(1, int(floor(_batch_area.size.y / (20.0 * _s))))


func _ensure_entries() -> void:
	if _entries.is_empty():
		_entries = PreGameCatalog.build_protagonist_list()


func _entry(index: int) -> Dictionary:
	_ensure_entries()
	if _entries.is_empty():
		return {}
	return _entries[clampi(index, 0, _entries.size() - 1)]


func _species_count() -> int:
	_ensure_entries()
	return maxi(_entries.size(), 1)


func _col_size() -> Vector2:
	var pad := 22.0 * _s
	var gap := 12.0 * _s
	var w := (_modal.size.x - pad * 2.0 - gap) * 0.5
	return Vector2(w, 337.0 * _s)


func _col_left() -> Rect2:
	var pad := 22.0 * _s
	return Rect2(Vector2(_origin.x + pad, _body_top()), _col_size())


func _col_right() -> Rect2:
	var gap := 12.0 * _s
	var left := _col_left()
	return Rect2(Vector2(left.end.x + gap, left.position.y), _col_size())


func _body_top() -> float:
	return _origin.y + 106.5 * _s


func _panel(rect: Rect2, fill: Color, border: Color, border_w: float, shadow: Vector2) -> void:
	if shadow != Vector2.ZERO:
		draw_rect(Rect2(rect.position + shadow, rect.size), Color.BLACK)
	draw_rect(rect, fill)
	if border_w > 0.0:
		draw_rect(rect, border, false, border_w)


func _draw_pill(rect: Rect2, label: String, active: bool, id: String, data: Dictionary, fill_active: Color = C_CYAN, fs: int = -1) -> void:
	draw_rect(rect, fill_active if active else C_CHIP_DARK)
	draw_rect(rect, Color.BLACK if active else C_BORDER, false, 1.0 * _s)
	if _zone_key(id, data) == _hover_key:
		draw_rect(rect.grow(1.0 * _s), C_PAPER, false, 1.0 * _s)
	var font_fs := fs if fs > 0 else _fs(7.5)
	_centered_text(rect, label, PreGameDraw.mono_font(), font_fs, C_INK if active else C_DOMAIN)
	_hit_zones.append({"id": id, "rect": rect, "data": data})


func _draw_skew_chip(rect: Rect2, label: String, fill: Color, text_col: Color, fs: int, id: String, data: Dictionary = {}) -> void:
	var pts := _skew_quad(rect, -8.0)
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	var border_col := C_PAPER if _zone_key(id, data) == _hover_key else Color("0a1a26")
	draw_polyline(closed, border_col, 1.0 * _s, true)
	_hit_zones.append({"id": id, "rect": _aabb(pts), "data": data})
	_centered_text(rect, label, PreGameDraw.body_font(), fs, text_col)


func _skew_quad(rect: Rect2, skew_deg: float) -> PackedVector2Array:
	var xf := PreGameDraw.skew_xform(skew_deg)
	var c := rect.get_center()
	var hx := rect.size.x * 0.5
	var hy := rect.size.y * 0.5
	var out := PackedVector2Array()
	out.append(c + xf * Vector2(-hx, -hy))
	out.append(c + xf * Vector2(hx, -hy))
	out.append(c + xf * Vector2(hx, hy))
	out.append(c + xf * Vector2(-hx, hy))
	return out


func _aabb(pts: PackedVector2Array) -> Rect2:
	if pts.is_empty():
		return Rect2()
	var out := Rect2(pts[0], Vector2.ZERO)
	for i in range(1, pts.size()):
		out = out.expand(pts[i])
	return out


func _centered_text(rect: Rect2, text: String, font: Font, fs: int, color: Color) -> void:
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tx := rect.position.x + (rect.size.x - tw) * 0.5
	var ty := rect.position.y + (rect.size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	draw_string(font, Vector2(tx, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _draw_dashed_rect(rect: Rect2, color: Color, width: float, dash: float, gap: float) -> void:
	var corners := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	for i in 4:
		_draw_dashed_line(corners[i], corners[(i + 1) % 4], color, width, dash, gap)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var length := from.distance_to(to)
	if length <= 0.0:
		return
	var dir := (to - from) / length
	var cursor := 0.0
	while cursor < length:
		var seg_end := minf(cursor + dash, length)
		draw_line(from + dir * cursor, from + dir * seg_end, color, width)
		cursor = seg_end + gap


func _ellipsize(font: Font, text: String, fs: int, max_w: float) -> String:
	if max_w <= 0.0:
		return ""
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= max_w:
		return text
	var out := text
	while out.length() > 1 and font.get_string_size(out + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		out = out.left(out.length() - 1)
	return out + "..."


func _zone_key(id: String, data: Dictionary) -> String:
	return id + "|" + str(data)


func _zone_at(pos: Vector2) -> Dictionary:
	for i in range(_hit_zones.size() - 1, -1, -1):
		var zone: Dictionary = _hit_zones[i]
		var rect: Rect2 = zone.get("rect", Rect2())
		if rect.has_point(pos):
			return zone
	return {}


func _stat_color(stat: String) -> Color:
	match stat:
		"STR":
			return C_CORAL
		"MAG":
			return PreGameDraw.MAG_VIOLET
		"VIT":
			return C_LIME
		"WIS":
			return C_CYAN
		"AGI":
			return C_GOLD
		_:
			return C_GOLD


func _fs(value: float) -> int:
	return maxi(1, int(round(value * _s)))
