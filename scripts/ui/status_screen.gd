class_name StatusScreen
extends Control
## Out-of-combat team status screen: roster on the left, selected character
## art in the middle, combat gauges/attributes on the right, and LoL-style
## skill tray at the bottom with live inspection card.
##
## Up/Down: character. Left/Right: skill. Shift: advanced formulas. Z: expand. X: close.

signal closed

const LIME := Color("d6fa66")
const CORAL := Color("ff746c")
const PAPER := Color("f4eee1")
const INK := Color("10263a")
const BLUE := Color("63d9ec")
const VIOLET := Color("bd9afd")
const GOLD := Color("f0c57e")
const ART_DIR := "res://sugimori/por_nome/"
const FACE_DIR := "res://personagens/portraits/"
const NatureData = preload("res://scripts/data/nature_data.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")

var _party: Array[Combatant] = []
var _member := 0
var _move := 0
var _detail_open := false
var _shift_held := false
var force_shift_view := false
var _nature_hovered := false
var _nature_pinned := false
var force_nature_view := false
var _inventory_selected_id: String = ""
var _inventory_hovered_slot: int = -1
var force_inventory_selected_id: String = ""

var desc_tilt_mode := 0 ## D-429: 0 = Shear/Italic Skew 9°, 1 = Angular Rotation -9°

var _bg: GradientTexture2D
var _art_cache: Dictionary = {}
var _faces: Array[TextureRect] = []
var _slot_icons: Array[TextureRect] = []
var _drawer_icon: TextureRect = null


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("26535f"), Color("143343"), Color("092133"), Color("051322")])
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.66, 1.0])
	_bg = GradientTexture2D.new()
	_bg.gradient = g
	_bg.fill = GradientTexture2D.FILL_RADIAL
	_bg.fill_from = Vector2(0.48, 0.55)
	_bg.fill_to = Vector2(1.1, 1.0)
	_bg.width = 256
	_bg.height = 144


func _process(_delta: float) -> void:
	if not visible:
		return
	var now_shift := Input.is_key_pressed(KEY_SHIFT) or force_shift_view
	if now_shift != _shift_held:
		_shift_held = now_shift
		queue_redraw()


func open(party: Array[Combatant], index := 0) -> void:
	_party = party
	_member = clampi(index, 0, maxi(party.size() - 1, 0))
	_move = 0
	_detail_open = false
	_shift_held = false
	_nature_hovered = false
	_nature_pinned = false
	_inventory_selected_id = ""
	visible = true
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		for f in _faces:
			f.visible = false
		for si in _slot_icons:
			si.visible = false
		if _drawer_icon != null:
			_drawer_icon.visible = false


func _get_nature_badge_rect() -> Rect2:
	var x := 848.0
	var pw := 208.0
	var sx := x + pw + 8.0
	var ly := 82.0 + 70.0
	var sy := ly + 68.0
	var bw := 70.0
	if not _party.is_empty() and _member >= 0 and _member < _party.size():
		var c := _party[_member]
		var nat: Dictionary = NatureData.get_nature(c.nature_id)
		var nat_name: String = str(nat.get("name", c.nature_id.capitalize())).to_upper()
		var title := FanMenu.title_font()
		var nw := title.get_string_size(nat_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		bw = nw + 16.0
	return Rect2(sx + 6.0, sy + 114.0, bw, 20.0)


func _get_satchel_rect() -> Rect2:
	return Rect2(29.0, 268.0, 276.0, 288.0)


func _get_inventory_slot_rect(idx: int) -> Rect2:
	var col := idx % 2
	var row := idx / 2
	var sx := 29.0 + 10.0 + float(col) * 128.0
	var sy := 268.0 + 38.0 + float(row) * 26.0
	return Rect2(sx, sy, 122.0, 22.0)


func _get_drawer_rect() -> Rect2:
	return Rect2(29.0 + 8.0, 268.0 + 172.0, 260.0, 108.0)


func _get_drawer_close_rect() -> Rect2:
	var dr := _get_drawer_rect()
	return Rect2(dr.end.x - 56.0, dr.position.y + 6.0, 48.0, 18.0)


func _get_satchel_items() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if Engine.has_singleton("GameState") or get_node_or_null("/root/GameState") != null:
		var gs = get_node_or_null("/root/GameState")
		if gs != null and gs.inventory is Dictionary and not gs.inventory.is_empty():
			for k in gs.inventory.keys():
				var it := Item.get_item(k)
				if it != null:
					list.append({"id": k, "item": it, "count": int(gs.inventory[k])})
	if list.is_empty():
		var default_ids := [
			{"id": "potion", "count": 4},
			{"id": "super_potion", "count": 2},
			{"id": "revive", "count": 1},
			{"id": "sitrus_berry", "count": 3},
			{"id": "lum_berry", "count": 2},
			{"id": "elixir", "count": 1},
		]
		for d in default_ids:
			var it := Item.get_item(d.id)
			if it != null:
				list.append({"id": d.id, "item": it, "count": d.count})
	return list


func _gui_input(event: InputEvent) -> void:
	if not visible or _detail_open:
		return
	var active_sel := _inventory_selected_id if force_inventory_selected_id.is_empty() else force_inventory_selected_id
	if event is InputEventMouseMotion:
		var hovered := _get_nature_badge_rect().has_point(event.position)
		if hovered != _nature_hovered:
			_nature_hovered = hovered
			queue_redraw()
		var hovered_slot := -1
		for i in 10:
			if _get_inventory_slot_rect(i).has_point(event.position):
				hovered_slot = i
				break
		if hovered_slot != _inventory_hovered_slot:
			_inventory_hovered_slot = hovered_slot
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _get_nature_badge_rect().has_point(event.position):
			_nature_pinned = not _nature_pinned
			queue_redraw()
			accept_event()
			return
		if not active_sel.is_empty() and _get_drawer_close_rect().has_point(event.position):
			_inventory_selected_id = ""
			force_inventory_selected_id = ""
			queue_redraw()
			accept_event()
			return
		var items_list := _get_satchel_items()
		for i in 10:
			if _get_inventory_slot_rect(i).has_point(event.position):
				if i < items_list.size():
					var clicked_id: String = items_list[i].id
					if _inventory_selected_id == clicked_id:
						_inventory_selected_id = ""
					else:
						_inventory_selected_id = clicked_id
					force_inventory_selected_id = ""
					queue_redraw()
					accept_event()
					return
		# Move strip selection via click (D-435)
		var moves_list := _moves(_party[_member])
		for i in moves_list.size():
			var col := i % 4
			var row := i / 4
			var sx := 29.0 + float(col) * (136.0 + 8.0)
			var sy := 598.0 + float(row) * (38.0 + 12.0)
			if Rect2(sx, sy, 136.0 + 7.0, 38.0).has_point(event.position):
				_move = i
				queue_redraw()
				accept_event()
				return


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not _inventory_selected_id.is_empty() and (event.is_action_pressed("cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_X)):
		_inventory_selected_id = ""
		force_inventory_selected_id = ""
		queue_redraw()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		return
	if InputMap.has_action("menu") and event.is_action_pressed("menu"):
		if _detail_open:
			_detail_open = false
		else:
			visible = false
			closed.emit()
	elif _detail_open:
		if event.is_action_pressed("confirm"):
			_detail_open = false
		else:
			return
	elif event.is_action_pressed("ui_up"):
		_member = posmod(_member - 1, _party.size())
		_move = 0
		_nature_hovered = false
		_nature_pinned = false
	elif event.is_action_pressed("ui_down"):
		_member = posmod(_member + 1, _party.size())
		_move = 0
		_nature_hovered = false
		_nature_pinned = false
	elif event.is_action_pressed("ui_left"):
		_move = posmod(_move - 1, _moves(_party[_member]).size())
	elif event.is_action_pressed("ui_right"):
		_move = posmod(_move + 1, _moves(_party[_member]).size())
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_8:
		var slot_idx: int = int(event.keycode) - int(KEY_1)
		if slot_idx < _moves(_party[_member]).size():
			_move = slot_idx
		else:
			return
	elif event.is_action_pressed("confirm"):
		_detail_open = true
	else:
		return
	queue_redraw()
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _moves(c: Combatant) -> Array[Skill]:
	var list: Array[Skill] = [Skill.basic()]
	list.append_array(c.skills)
	return list


func _art(c: Combatant) -> Texture2D:
	var key := c.name.to_lower()
	if not _art_cache.has(key):
		var path := ART_DIR + key + ".png"
		_art_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _art_cache[key]


func _face(c: Combatant) -> Texture2D:
	var path := FACE_DIR + c.name.to_lower() + ".png"
	return load(path) if ResourceLoader.exists(path) else null


# --- Drawing helpers --------------------------------------------------------------

const ELEMENT_COLORS := {
	Element.Type.FISICO: Color("cbd5e1"),
	Element.Type.FOGO: Color("f97316"),
	Element.Type.AGUA_GELO: Color("0284c7"),
	Element.Type.RAIO: Color("fde047"),
	Element.Type.VENTO: Color("4ff7ba"),
	Element.Type.PSIQUICO: Color("ec4899"),
	Element.Type.LUZ: Color("fef08a"),
	Element.Type.TREVAS: Color("6b21a8"),
	Element.Type.VENENO: Color("84cc16"),
	Element.Type.SOM: Color("06b6d4"),
	Element.Type.TERRA: Color("b45309"),
}

const ELEMENT_GLYPH_COLORS := {
	Element.Type.FISICO: Color("080e18"),
	Element.Type.FOGO: Color.WHITE,
	Element.Type.AGUA_GELO: Color.WHITE,
	Element.Type.RAIO: Color("080e18"),
	Element.Type.VENTO: Color("080e18"),
	Element.Type.PSIQUICO: Color.WHITE,
	Element.Type.LUZ: Color("080e18"),
	Element.Type.TREVAS: Color.WHITE,
	Element.Type.VENENO: Color("080e18"),
	Element.Type.SOM: Color("080e18"),
	Element.Type.TERRA: Color.WHITE,
}

var _icon_cache: Dictionary = {}

func _get_element_icon(elem: Element.Type) -> Texture2D:
	var name_key := ""
	match elem:
		Element.Type.FISICO:
			name_key = "neutral"
		Element.Type.FOGO:
			name_key = "fire"
		Element.Type.AGUA_GELO:
			name_key = "water_ice"
		Element.Type.RAIO:
			name_key = "electric"
		Element.Type.PSIQUICO:
			name_key = "psychic"
		Element.Type.VENENO:
			name_key = "nature"
		Element.Type.SOM:
			name_key = "sound"
		Element.Type.TERRA:
			name_key = "earth"
		Element.Type.VENTO:
			name_key = "wind"
		Element.Type.LUZ:
			name_key = "light"
		Element.Type.TREVAS:
			name_key = "dark"
		_:
			name_key = "neutral"
	if not _icon_cache.has("elem_" + name_key):
		var path := "res://assets/ui/icons/elements/%s.svg" % name_key
		_icon_cache["elem_" + name_key] = load(path) if ResourceLoader.exists(path) else null
	return _icon_cache["elem_" + name_key]

func _get_type_icon(type_name: String) -> Texture2D:
	if not _icon_cache.has("type_" + type_name):
		var path := "res://assets/ui/icons/move_types/%s.svg" % type_name
		_icon_cache["type_" + type_name] = load(path) if ResourceLoader.exists(path) else null
	return _icon_cache["type_" + type_name]

func _get_range_icon(range_name: String) -> Texture2D:
	if not _icon_cache.has("range_" + range_name):
		var path := "res://assets/ui/icons/range/%s.svg" % range_name
		_icon_cache["range_" + range_name] = load(path) if ResourceLoader.exists(path) else null
	return _icon_cache["range_" + range_name]

func _slant(r: Rect2, skew: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)]), color)


func _slant_border(r: Rect2, skew: float, color: Color, width := 1.0) -> void:
	draw_polyline(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y),
		Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y),
		Vector2(r.position.x, r.end.y),
		Vector2(r.position.x + skew, r.position.y)
	]), color, width)


func _draw_para_flat(pos: Vector2, size_vec: Vector2, skew: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x + skew, pos.y),
		Vector2(pos.x + size_vec.x + skew, pos.y),
		Vector2(pos.x + size_vec.x, pos.y + size_vec.y),
		Vector2(pos.x, pos.y + size_vec.y)
	]), color)


func _draw_para_border(pos: Vector2, size_vec: Vector2, skew: float, color: Color, width := 1.0) -> void:
	draw_polyline(PackedVector2Array([
		Vector2(pos.x + skew, pos.y),
		Vector2(pos.x + size_vec.x + skew, pos.y),
		Vector2(pos.x + size_vec.x, pos.y + size_vec.y),
		Vector2(pos.x, pos.y + size_vec.y),
		Vector2(pos.x + skew, pos.y)
	]), color, width)


func _badge(pos: Vector2, text: String, bg_col: Color, text_col: Color) -> float:
	var font := FanMenu.body_font()
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	var pad := 6.0
	var w := sz.x + pad * 2.0
	var h := 16.0
	var r := Rect2(pos.x, pos.y - 12.0, w, h)
	_slant(r, 3.0, bg_col)
	_text(font, Vector2(pos.x + pad, pos.y), text, 9, text_col)
	return w + 6.0


func _text(font: Font, pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_right(font: Font, right_x: float, y: float, text: String, size: int, color: Color) -> void:
	BattleHud.text_right(self, font, right_x, y, text, size, color)


func _text_centered(font: Font, center_x: float, y: float, text: String, font_size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(center_x - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw() -> void:
	if _party.is_empty():
		return
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var c := _party[_member]
	draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false)
	_draw_spires()
	draw_rect(Rect2(0, 0, size.x * 0.25, 3), LIME)
	draw_rect(Rect2(size.x * 0.25, 0, size.x * 0.17, 3), CORAL)

	# Header: TEAM / STATS (D-413)
	_text(title, Vector2(29, 56), "TEAM", 40, PAPER)
	var w := title.get_string_size("TEAM", HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	_text(title, Vector2(29 + w + 6, 56), "/", 44, CORAL)
	_text(title, Vector2(29 + w + 24, 56), "STATS", 40, LIME)

	_draw_roster()
	_draw_inventory()
	_draw_art(c)
	_draw_panel(c)
	_draw_moves(c)

	# Footer
	draw_rect(Rect2(0, size.y - 28, size.x, 28), Color(0.012, 0.047, 0.086, 0.95))
	draw_rect(Rect2(0, size.y - 28, size.x, 1), Color("365365"))
	_text(body, Vector2(29, size.y - 10), "↑ ↓  MEMBER   ·   ← →  SKILLS   ·   SHIFT  ADVANCED   ·   Z  EXPAND   ·   X  CLOSE", 10, Color("b2c5cb"))
	_text_right(body, size.x - 29, size.y - 10, "TEAM // STATUS", 10, GOLD)
	if _detail_open:
		_draw_detail(c)


func _draw_spires() -> void:
	for i in 12:
		var h := 104.0 + float((i * 67) % 250) * 0.8
		var x := i * 114.0 + 20.0
		var base := size.y - 78.0 * 0.8 - 28.0
		var col := Color(0.11, 0.25, 0.3, 0.38)
		draw_rect(Rect2(x, base - h, 27, h), col)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, base - h), Vector2(x + 33, base - h), Vector2(x + 27, base - h - 10), Vector2(x, base - h - 10)]), Color(0.11, 0.27, 0.35, 0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 13.5, base - h - 40), Vector2(x + 27, base - h - 10), Vector2(x, base - h - 10)]), Color(0.06, 0.16, 0.22, 0.4))
		draw_circle(Vector2(x + 13.5, base - h - 46), 4.0, Color(0.96, 0.84, 0.56, 0.5))


func _draw_roster() -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	_text(body, Vector2(29, 100), "TEAM // %d MEMBERS" % _party.size(), 11, LIME)
	draw_rect(Rect2(29, 105, 276, 2), Color(LIME, 0.35))
	for i in _party.size():
		var u := _party[i]
		var on := i == _member
		var r := Rect2(29 + (6.0 if on else 0.0), 116 + i * 74.0, 276, 66)
		_slant(Rect2(r.position + Vector2(4, 5), r.size), 8.0, Color(0.016, 0.05, 0.086, 0.65))
		_slant(r, 8.0, Color("fdfde8") if on else PAPER)
		if on:
			draw_rect(Rect2(r.position.x, r.position.y, 7, r.size.y), LIME)
		var face := Rect2(r.position.x + 14, r.position.y + 10, 46, 46)
		draw_rect(face, Color(0.07, 0.145, 0.21))
		var tex := _face(u)
		_place_face(i, tex, face.grow(-2))
		draw_rect(face, Color(0.137, 0.25, 0.34), false, 2.0)
		var tx := r.position.x + 70
		_text(title, Vector2(tx, r.position.y + 28), u.name.to_upper(), 18, Color("0a1a27"))

		# Element icons beside name in roster (D-404, D-413, D-414)
		var name_w := title.get_string_size(u.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var u_elems: Array = u.get_elements()
		var ex := tx + name_w + 8.0
		var ey := r.position.y + 13.0
		var eh := 15.0
		if u_elems.size() == 1:
			var ew := 36.0
			var er := Rect2(ex, ey, ew, eh)
			var bg_c: Color = ELEMENT_COLORS.get(u_elems[0], BattleFx.COLORS[u_elems[0]])
			var fg_c: Color = ELEMENT_GLYPH_COLORS.get(u_elems[0], Color("080e18"))
			_draw_para_flat(Vector2(ex, ey), Vector2(ew, eh), 2.5, bg_c)
			var icon := _get_element_icon(u_elems[0])
			if icon != null:
				var ic_sz := 13.0
				var ic_r := Rect2(er.get_center() - Vector2(ic_sz * 0.5, ic_sz * 0.5), Vector2(ic_sz, ic_sz))
				draw_texture_rect(icon, ic_r, false, fg_c)
		else:
			for k in mini(u_elems.size(), 2):
				var ew := 18.0
				var bx := ex + k * (ew + 4.0)
				var er := Rect2(bx, ey, ew, eh)
				var bg_c: Color = ELEMENT_COLORS.get(u_elems[k], BattleFx.COLORS[u_elems[k]])
				var fg_c: Color = ELEMENT_GLYPH_COLORS.get(u_elems[k], Color("080e18"))
				_draw_para_flat(Vector2(bx, ey), Vector2(ew, eh), 2.5, bg_c)
				var icon := _get_element_icon(u_elems[k])
				if icon != null:
					var ic_sz := 13.0
					var ic_r := Rect2(er.get_center() - Vector2(ic_sz * 0.5, ic_sz * 0.5), Vector2(ic_sz, ic_sz))
					draw_texture_rect(icon, ic_r, false, fg_c)

		_text_right(body, r.end.x - 14, r.position.y + 26, "LV. %d" % u.level, 10, Color("536f80"))
		_stat_bar(Vector2(tx, r.position.y + 38), 128.0, "HP", float(u.hp) / maxi(u.max_hp, 1), CORAL, "%d/%d" % [u.hp, u.max_hp], r.end.x - 14)
		_stat_bar(Vector2(tx, r.position.y + 52), 128.0, "MP", float(u.mp) / maxi(u.max_mp, 1), Color("5f88f5"), "%d/%d" % [u.mp, u.max_mp], r.end.x - 14)


func _place_slot_icon(i: int, tex: Texture2D, rect: Rect2, mod: Color) -> void:
	while _slot_icons.size() <= i:
		var tr := TextureRect.new()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(tr)
		_slot_icons.append(tr)
	var slot_tr := _slot_icons[i]
	slot_tr.texture = tex
	slot_tr.position = rect.position
	slot_tr.size = rect.size
	slot_tr.modulate = mod
	slot_tr.visible = visible and tex != null


func _place_drawer_icon(tex: Texture2D, rect: Rect2) -> void:
	if _drawer_icon == null:
		_drawer_icon = TextureRect.new()
		_drawer_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drawer_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_drawer_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_drawer_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(_drawer_icon)
	_drawer_icon.texture = tex
	_drawer_icon.position = rect.position
	_drawer_icon.size = rect.size
	_drawer_icon.visible = visible and tex != null


func _place_face(i: int, tex: Texture2D, rect: Rect2) -> void:
	while _faces.size() <= i:
		var tr := TextureRect.new()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(tr)
		_faces.append(tr)
	var face_rect := _faces[i]
	face_rect.texture = tex
	face_rect.position = rect.position
	face_rect.size = rect.size
	face_rect.visible = tex != null


func _stat_bar(pos: Vector2, w: float, label: String, k: float, color: Color, value: String, right_x: float) -> void:
	var body := FanMenu.body_font()
	_text(body, Vector2(pos.x, pos.y + 6), label, 9, Color("6b8290"))
	var track := Rect2(pos.x + 18, pos.y, w, 6)
	draw_rect(track, Color("abbdc6"))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(k, 0.0, 1.0), track.size.y)), color)
	_text_right(body, right_x, pos.y + 7, value, 9, Color("183040"))


func _draw_inventory() -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var satchel_r := _get_satchel_rect()
	var pos := satchel_r.position
	var size_vec := satchel_r.size
	var active_sel := _inventory_selected_id if force_inventory_selected_id.is_empty() else force_inventory_selected_id

	# 1. Rustic Satchel Brown Leather Base Parallelogram (D-416, D-424, D-428)
	_draw_para_flat(pos, size_vec, 14.0, Color("3c2415"))
	_draw_para_border(pos, size_vec, 14.0, Color("52331c"), 1.0)

	# 2. Header: EXPEDITION SATCHEL (D-424, D-431: Confined within Parallelogram)
	_draw_para_flat(Vector2(pos.x + 20.0, pos.y + 9.0), Vector2(5.0, 15.0), 3.0, Color("dfc980"))
	_text(title, Vector2(pos.x + 30.0, pos.y + 22.0), "EXPEDITION SATCHEL", 16, Color("dfc980"))

	var items_list := _get_satchel_items()
	var cap_txt := "%02d / 10" % items_list.size()
	_draw_para_flat(Vector2(pos.x + size_vec.x - 54.0, pos.y + 8.0), Vector2(46.0, 15.0), 3.0, Color("24140a"))
	_text(body, Vector2(pos.x + size_vec.x - 48.0, pos.y + 19.5), cap_txt, 9, Color("dfc980"))

	draw_line(Vector2(pos.x + 16.0, pos.y + 28.0), Vector2(pos.x + size_vec.x - 6.0, pos.y + 28.0), Color("52331c"), 1.0)

	# 3. 10 Slots Matrix (2 columns x 5 rows) with strict D-416/D-428 parallelogram slant (skew=5.0)
	for i in 10:
		var r := _get_inventory_slot_rect(i)
		var is_occupied: bool = i < items_list.size()
		var item_id_str: String = str(items_list[i].id) if is_occupied else ""
		var is_sel: bool = is_occupied and (item_id_str == active_sel)
		var is_dim: bool = not active_sel.is_empty() and not is_sel

		if is_occupied:
			var d: Dictionary = items_list[i]
			var it: Item = d.item
			var count: int = d.count

			var bg_col: Color = Color("dfc980") if is_sel else Color("29170c")
			var text_col: Color = Color("24140a") if is_sel else Color("f5eedb")
			var count_col: Color = Color("24140a") if is_sel else Color("dfc980")
			var alpha: float = 0.28 if is_dim else 1.0

			bg_col.a *= alpha
			text_col.a *= alpha
			count_col.a *= alpha
			var icon_mod := Color(1, 1, 1, alpha)

			# Distinct Parallelogram Slot Tile (skew = 5.0)
			_draw_para_flat(r.position, r.size, 5.0, bg_col)
			if is_sel:
				_draw_para_border(r.position, r.size, 5.0, Color("dfc980"), 1.5)
			else:
				_draw_para_border(r.position, r.size, 5.0, Color(0.31, 0.18, 0.09, alpha), 1.0)

			# Optical Centerline Alignment for Slot Tile (D-430: TextureRect)
			var mid_slot_y := r.position.y + r.size.y * 0.5
			var ic_sz := 14.0
			var icon_tex := Item.icon_of(it.id)
			var icon_rect := Rect2(r.position.x + 6.0, mid_slot_y - ic_sz * 0.5, ic_sz, ic_sz)
			_place_slot_icon(i, icon_tex, icon_rect, icon_mod)

			var name_pos := Vector2(icon_rect.end.x + 5.0, mid_slot_y + 3.5)
			_text(body, name_pos, it.display_name.to_upper(), 9, text_col)
			_text_right(body, r.end.x - 3.0, mid_slot_y + 3.5, "×%d" % count, 9, count_col)
		else:
			_place_slot_icon(i, null, Rect2(), Color.WHITE)
			var empty_alpha := 0.12 if not active_sel.is_empty() else 0.40
			_draw_para_flat(r.position, r.size, 5.0, Color(0.14, 0.08, 0.04, empty_alpha))
			_draw_para_border(r.position, r.size, 5.0, Color(0.27, 0.15, 0.07, empty_alpha), 1.0)
			var mid_slot_y := r.position.y + r.size.y * 0.5
			var slot_txt := "[ SLOT %02d ]" % (i + 1)
			var slot_col := Color("6d513d", 0.22 if not active_sel.is_empty() else 0.8)
			_text(body, Vector2(r.position.x + 8.0, mid_slot_y + 3.5), slot_txt, 8, slot_col)
			_text_right(body, r.end.x - 6.0, mid_slot_y + 3.5, "—", 8, slot_col)

	# 4. Footer or Slide-Up Detail Drawer (A + C, D-431: Separated Labels Without Collision)
	if active_sel.is_empty():
		_place_drawer_icon(null, Rect2())
		draw_line(Vector2(pos.x + 16.0, pos.y + 266.0), Vector2(pos.x + size_vec.x - 16.0, pos.y + 266.0), Color("4f2f18"), 1.0)
		_text(body, Vector2(pos.x + 16.0, pos.y + 278.0), "CLICK ITEM FOR DETAILS (A+C)", 8, Color("a5915d"))
		_text_right(body, pos.x + size_vec.x - 16.0, pos.y + 278.0, "10 SLOTS", 8, Color("dfc980"))
	else:
		var dr := _get_drawer_rect()
		var dr_skew := 10.0

		# Dark Leather Drawer Base & Burnt Yellow Border - STRICT PARALLELOGRAM (D-428)
		_draw_para_flat(dr.position, dr.size, dr_skew, Color("201007"))
		_draw_para_border(dr.position, dr.size, dr_skew, Color("dfc980"), 1.5)

		var cur_item := Item.get_item(active_sel)
		if cur_item != null:
			# Strict D-429 Parallelogram Border Boundaries:
			# dr_left_x(dy)  = dr.position.x + dr_skew * (1.0 - dy / dr.size.y)
			# dr_right_x(dy) = dr.position.x + dr.size.x + dr_skew * (1.0 - dy / dr.size.y)

			# 1. Drawer Header (D-427, D-428, D-429, D-430: Real Pixel Art Icon)
			var mid_hdr_y := dr.position.y + 16.0
			var ic_sz := 18.0
			# Top of icon is at dy = 7.0; safe margin = 10.0px inside slanted left border (D-429)
			var ic_x := dr.position.x + dr_skew * (1.0 - 7.0 / dr.size.y) + 10.0
			var ic_pos := Vector2(ic_x, mid_hdr_y - ic_sz * 0.5)
			var it_icon := Item.icon_of(active_sel)
			_place_drawer_icon(it_icon, Rect2(ic_pos, Vector2(ic_sz, ic_sz)))

			# Item Name
			var name_pos := Vector2(ic_pos.x + ic_sz + 6.0, mid_hdr_y + 5.5)
			_text(title, name_pos, cur_item.display_name.to_upper(), 18, Color("dfc980"))
			var name_w := title.get_string_size(cur_item.display_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x

			# Distinct Parallelogram Badge (D-426, D-428: skew = 6.0, Verde Herbal)
			var badge_x := name_pos.x + name_w + 8.0
			var badge_w := 72.0
			var badge_h := 16.0
			var badge_y := mid_hdr_y - badge_h * 0.5
			_draw_para_flat(Vector2(badge_x, badge_y), Vector2(badge_w, badge_h), 6.0, Color("2e7d4e"))
			var kind_txt := "CONSUMABLE" if cur_item.kind == Item.Kind.CONSUMABLE else "HELD"
			_text(body, Vector2(badge_x + 8.0, mid_hdr_y + 4.0), kind_txt, 8, Color.WHITE)

			# Close Button tucked safely inside top-right border (D-429)
			var close_right_x := dr.position.x + dr.size.x + dr_skew * (1.0 - 16.0 / dr.size.y) - 8.0
			_text_right(body, close_right_x, mid_hdr_y + 4.0, "[X] CLOSE", 8, Color("dfc980"))

			# Slanted Divider 1 along true drawer slope (D-429)
			var div1_y := dr.position.y + 28.0
			var div1_left := dr.position.x + dr_skew * (1.0 - 28.0 / dr.size.y) + 8.0
			var div1_right := dr.position.x + dr.size.x + dr_skew * (1.0 - 28.0 / dr.size.y) - 8.0
			draw_line(Vector2(div1_left, div1_y), Vector2(div1_right, div1_y), Color("3c2415"), 1.0)

			# Description Text with 9-degree slant (D-429)
			var desc_y := dr.position.y + 42.0
			var desc_left := dr.position.x + dr_skew * (1.0 - 42.0 / dr.size.y) + 8.0
			var desc_right := dr.position.x + dr.size.x + dr_skew * (1.0 - 42.0 / dr.size.y) - 8.0
			var max_desc_w := desc_right - desc_left - 6.0

			if desc_tilt_mode == 1:
				# Option B: Angular Rotation (-9 deg)
				draw_set_transform(Vector2(desc_left, desc_y + 6.0), deg_to_rad(-9.0), Vector2.ONE)
				draw_multiline_string(body, Vector2.ZERO, cur_item.description, HORIZONTAL_ALIGNMENT_LEFT, max_desc_w, 9, 2, Color("d4c3b2"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				# Option A (Default): Dynamic Shear / Italic Skew (9 deg forward lean via Transform2D)
				var shear_tan := tan(deg_to_rad(9.0))
				var xform := Transform2D(Vector2(1.0, 0.0), Vector2(-shear_tan, 1.0), Vector2(desc_left, desc_y))
				draw_set_transform_matrix(xform)
				draw_multiline_string(body, Vector2.ZERO, cur_item.description, HORIZONTAL_ALIGNMENT_LEFT, max_desc_w, 9, 2, Color("d4c3b2"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			# Slanted Divider 2 along true drawer slope (D-429)
			var div2_y := dr.position.y + 76.0
			var div2_left := dr.position.x + dr_skew * (1.0 - 76.0 / dr.size.y) + 8.0
			var div2_right := dr.position.x + dr.size.x + dr_skew * (1.0 - 76.0 / dr.size.y) - 8.0
			draw_line(Vector2(div2_left, div2_y), Vector2(div2_right, div2_y), Color("3c2415"), 1.0)
			_text(body, Vector2(div2_left, dr.position.y + 91.0), "TARGET: Single Ally", 8, Color("ab965a"))

			# Orthogonal Rectangular Action Button (D-430: quadrado reto, 90 deg, alinhamento preciso)
			var btn_w := 88.0
			var btn_h := 20.0
			var btn_y := dr.position.y + 76.0 + (32.0 - btn_h) * 0.5
			var btn_x := dr.position.x + dr.size.x - btn_w - 8.0
			var btn_rect := Rect2(btn_x, btn_y, btn_w, btn_h)
			draw_rect(btn_rect, Color("dfc980"))

			var btn_txt := "USE (1 ATB) [Z]"
			var txt_sz := body.get_string_size(btn_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
			var txt_pos := Vector2(btn_x + (btn_w - txt_sz.x) * 0.5, btn_y + btn_h * 0.5 + 3.0)
			_text(body, txt_pos, btn_txt, 8, Color("24140a"))


func _draw_art(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var box := Rect2(384, 84, 352, 464)
	var center := box.get_center()
	draw_set_transform(center, deg_to_rad(-11.0), Vector2.ONE)
	var pts := PackedVector2Array([
		Vector2(-box.size.x * 0.5 + box.size.x * 0.32, -box.size.y * 0.5), Vector2(-box.size.x * 0.5 + box.size.x * 0.94, -box.size.y * 0.5),
		Vector2(-box.size.x * 0.5 + box.size.x * 0.68, box.size.y * 0.5), Vector2(-box.size.x * 0.5, box.size.y * 0.5)])
	var cols := PackedColorArray([Color(0.98, 0.4, 0.37, 0.66), Color(0.98, 0.4, 0.37, 0.66), Color(0.6, 0.2, 0.24, 0.72), Color(0.6, 0.2, 0.24, 0.72)])
	draw_polygon(pts, cols)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var art := _art(c)
	var area := Rect2(336, 68, 488, 504)
	if art != null:
		var s := minf(area.size.x / art.get_width(), area.size.y / art.get_height())
		var sz := Vector2(art.get_width(), art.get_height()) * s
		var pos := area.position + (area.size - sz) * 0.5
		draw_texture_rect(art, Rect2(pos + Vector2(10, 14), sz), false, Color(0, 0, 0, 0.35))
		draw_texture_rect(art, Rect2(pos, sz), false)
	else:
		_text(title, Vector2(area.position.x + 130, area.get_center().y), c.name.to_upper(), 44, Color(1, 1, 1, 0.25))


func _draw_panel(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var x := 848.0
	var w := 403.0
	var y := 82.0
	var is_leader := c == _party[0]
	var tag_y := 62.0
	_draw_para_flat(Vector2(x, tag_y), Vector2(168, 16), 4.0, Color(0.027, 0.11, 0.17))
	_draw_para_flat(Vector2(x, tag_y), Vector2(3, 16), 1.0, CORAL)
	_text(body, Vector2(x + 10, tag_y + 12), "PROTAGONIST" if is_leader else "ALLY", 9, LIME)
	if is_leader and c.distributable_points > 0:
		_draw_para_flat(Vector2(x + 176, tag_y), Vector2(172, 16), 4.0, Color(0.027, 0.11, 0.17))
		_draw_para_flat(Vector2(x + 176, tag_y), Vector2(3, 16), 1.0, LIME)
		_text(body, Vector2(x + 186, tag_y + 12), "★ %d PT%s PENDING" % [
			c.distributable_points,
			"S" if c.distributable_points > 1 else ""
		], 9, LIME)

	# Main Character Name
	_text(title, Vector2(x, y + 54), c.name.to_upper(), 46, PAPER)

	# Element icon blocks beside main name (D-404, D-413, D-414)
	var main_name_w := title.get_string_size(c.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
	var c_elems: Array = c.get_elements()
	var e_start_x := x + main_name_w + 16.0
	var e_y := y + 26.0
	var skew_elem := 7.0
	if c_elems.size() == 1:
		var ew := 54.0
		var eh := 28.0
		var bg_c: Color = ELEMENT_COLORS.get(c_elems[0], BattleFx.COLORS[c_elems[0]])
		var fg_c: Color = ELEMENT_GLYPH_COLORS.get(c_elems[0], Color("080e18"))
		_draw_para_flat(Vector2(e_start_x, e_y), Vector2(ew, eh), skew_elem, bg_c)
		var icon := _get_element_icon(c_elems[0])
		if icon != null:
			var ic_sz := 24.0
			var center := Vector2(e_start_x + (ew + skew_elem) * 0.5, e_y + eh * 0.5)
			var ic_r := Rect2(center - Vector2(ic_sz * 0.5, ic_sz * 0.5), Vector2(ic_sz, ic_sz))
			draw_texture_rect(icon, ic_r, false, fg_c)
	else:
		for k in mini(c_elems.size(), 2):
			var ew := 28.0
			var eh := 28.0
			var sx_k := e_start_x + k * (ew + 7.0)
			var bg_c: Color = ELEMENT_COLORS.get(c_elems[k], BattleFx.COLORS[c_elems[k]])
			var fg_c: Color = ELEMENT_GLYPH_COLORS.get(c_elems[k], Color("080e18"))
			_draw_para_flat(Vector2(sx_k, e_y), Vector2(ew, eh), skew_elem, bg_c)
			var icon := _get_element_icon(c_elems[k])
			if icon != null:
				var ic_sz := 22.0
				var center := Vector2(sx_k + (ew + skew_elem) * 0.5, e_y + eh * 0.5)
				var ic_r := Rect2(center - Vector2(ic_sz * 0.5, ic_sz * 0.5), Vector2(ic_sz, ic_sz))
				draw_texture_rect(icon, ic_r, false, fg_c)

	# Level / EXP (D-399)
	var ly := y + 70.0
	var lv := Rect2(x, ly, w, 56)
	draw_rect(lv, Color(0.035, 0.12, 0.17, 0.86))
	draw_rect(lv, Color("4f7387"), false, 1.0)
	_text(body, Vector2(x + 14, ly + 25), "LEVEL", 11, PAPER)
	_text(title, Vector2(x + 66, ly + 30), "%d" % c.level, 28, Color(LIME, 0.9))
	var next_xp := CrawlmonAttributeMath.get_xp_for_level_transition(c.level + 1)
	var remaining := maxi(0, next_xp - c.xp)
	var exp_str := "EXP  %d / %d  (Remaining %d)" % [c.xp, next_xp, remaining]
	_text_right(body, lv.end.x - 14, ly + 23, exp_str, 10, Color("9ec0cc"))
	var k_xp := clampf(float(c.xp) / float(maxi(next_xp, 1)), 0.0, 1.0)
	draw_rect(Rect2(x + 14, ly + 38, w - 28, 8), Color("253844"))
	if k_xp > 0.001:
		draw_rect(Rect2(x + 14, ly + 38, (w - 28) * k_xp, 8), LIME)

	# Combat gauges (D-120, D-390, D-391, D-392, D-413, D-416, D-421)
	var sy := ly + 68.0
	var pw := 208.0
	_draw_para_flat(Vector2(x, sy), Vector2(pw, 142), 6.0, PAPER)
	_draw_para_flat(Vector2(x + 14, sy + 10), Vector2(3.0, 8.0), 1.0, Color("0e2435"))
	_text(body, Vector2(x + 20, sy + 18), "COMBAT GAUGES", 10, Color("0e2435"))
	_panel_bar(x + 14, sy + 32, pw - 28, "HP", float(c.hp) / maxi(c.max_hp, 1), CORAL, "%d / %d" % [c.hp, c.max_hp])
	
	# MP Bar without 8s clutter (D-413, D-421)
	_panel_bar(x + 14, sy + 58, pw - 28, "MP", float(c.mp) / maxi(c.max_mp, 1), Color("3f72e5"), "%d / %d" % [c.mp, c.max_mp])

	# ATB without redundant text (D-413, D-421)
	_text(body, Vector2(x + 14, sy + 92), "ATB", 10, Color("0a1a27"))
	for i in int(Combatant.BLOCKS):
		_draw_para_flat(Vector2(x + 48 + i * 20, sy + 82), Vector2(17, 12), 3.0, Color("138cb5"))
	draw_rect(Rect2(x + 14, sy + 108, pw - 28, 1), Color(0.2, 0.3, 0.4, 0.25))
	_text(body, Vector2(x + 14, sy + 128), "ATB SPEED", 10, Color("0e2435"))
	_text_right(body, x + pw - 14, sy + 128, "%.2f blocks/s" % c.speed, 10, Color("0a1a27"))

	# Right box: 6 Attributes & Integrated Nature - Option 1C (D-120, D-390, D-413, D-416, D-421)
	var sx := x + pw + 8.0
	var sw := w - pw - 8.0
	_draw_para_flat(Vector2(sx, sy), Vector2(sw, 142), 6.0, Color(0.025, 0.09, 0.15, 0.95))
	_draw_para_flat(Vector2(sx + 10, sy + 10), Vector2(3.0, 8.0), 1.0, LIME)
	_text(body, Vector2(sx + 16, sy + 18), "ATTRIBUTES", 10, LIME)

	var nat: Dictionary = NatureData.get_nature(c.nature_id)
	var nat_mods: Dictionary = nat.get("mods", {})

	var mid_x := sx + sw * 0.5
	var stat_rows := [
		["STR", c.str, int(nat_mods.get("STR", 0)), "MAG", c.mag, int(nat_mods.get("MAG", 0)), sy + 38.0],
		["VIT", c.vit, int(nat_mods.get("VIT", 0)), "WIS", c.wis, int(nat_mods.get("WIS", 0)), sy + 62.0],
		["AGI", c.agi, int(nat_mods.get("AGI", 0)), "LUK", c.luk, int(nat_mods.get("LUK", 0)), sy + 86.0],
	]
	for row in stat_rows:
		var ry: float = row[6]
		# Col 1
		_text(body, Vector2(sx + 10, ry), str(row[0]), 9, Color("8ea9b5"))
		_text_right(body, mid_x - 22, ry, str(row[1]), 11, Color.WHITE)
		var m1: int = row[2]
		if m1 != 0:
			var m1_col: Color = LIME if m1 > 0 else CORAL
			var m1_str: String = ("+%d" if m1 > 0 else "%d") % m1
			_text(body, Vector2(mid_x - 20, ry), m1_str, 9, m1_col)
		else:
			_text(body, Vector2(mid_x - 18, ry), "—", 9, Color(0.35, 0.45, 0.5, 0.6))
		
		# Col 2
		_text(body, Vector2(mid_x + 8, ry), str(row[3]), 9, Color("8ea9b5"))
		_text_right(body, sx + sw - 22, ry, str(row[4]), 11, Color.WHITE)
		var m2: int = row[5]
		if m2 != 0:
			var m2_col: Color = LIME if m2 > 0 else CORAL
			var m2_str: String = ("+%d" if m2 > 0 else "%d") % m2
			_text(body, Vector2(sx + sw - 20, ry), m2_str, 9, m2_col)
		else:
			_text(body, Vector2(sx + sw - 18, ry), "—", 9, Color(0.35, 0.45, 0.5, 0.6))

		draw_rect(Rect2(sx + 8, ry + 7, sw - 16, 1), Color(0.53, 0.65, 0.69, 0.15))

	# Footer Row (Option 1C / D-422): Split footer with NATURE on left, WEAK on right
	draw_rect(Rect2(sx + 8, sy + 106, sw - 16, 1), Color(0.53, 0.65, 0.69, 0.2))

	# Left of footer: NATURE NAME (D-421, D-422, D-432) - Larger text, without "NAT"
	var nat_name: String = str(nat.get("name", c.nature_id.capitalize())).to_upper()
	var is_nat_active := _nature_hovered or _nature_pinned or force_nature_view
	var nat_rect := _get_nature_badge_rect()
	if is_nat_active:
		_draw_para_flat(Vector2(nat_rect.position.x, nat_rect.position.y), Vector2(nat_rect.size.x, nat_rect.size.y), 2.0, Color(0.94, 0.77, 0.49, 0.18))
	_draw_para_flat(Vector2(sx + 8, sy + 114), Vector2(3.5, 20.0), 1.0, GOLD)
	_text(title, Vector2(sx + 15, sy + 132), nat_name, 20, GOLD)

	# Right of footer: WEAK with element parallelogram badges (D-413, D-416, D-421, D-431)
	if c.weaknesses.is_empty():
		_text_right(body, sx + sw - 10, sy + 128, "WEAK: —", 9, Color("6e8a97"))
	else:
		var w_box_w := 20.0
		var w_box_h := 16.0
		var w_gap := 4.0
		var total_w := float(c.weaknesses.size()) * (w_box_w + w_gap) - w_gap
		var wx := sx + sw - 10.0 - total_w
		var weak_lbl := "WEAK:"
		var weak_sz := body.get_string_size(weak_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		_text(body, Vector2(wx - weak_sz - 6.0, sy + 128.0), weak_lbl, 9, Color("8ea9b5"))
		for w_elem in c.weaknesses:
			var w_col: Color = ELEMENT_COLORS.get(w_elem, BattleFx.COLORS[w_elem])
			var fg_c: Color = ELEMENT_GLYPH_COLORS.get(w_elem, Color("080e18"))
			_draw_para_flat(Vector2(wx, sy + 116.0), Vector2(w_box_w, w_box_h), 2.0, w_col)
			var icon := _get_element_icon(w_elem)
			if icon != null:
				var ic_sz := 13.0
				var center_pos := Vector2(wx + w_box_w * 0.5 + 1.0, sy + 116.0 + w_box_h * 0.5)
				var ic_r := Rect2(center_pos - Vector2(ic_sz * 0.5, ic_sz * 0.5), Vector2(ic_sz, ic_sz))
				draw_texture_rect(icon, ic_r, false, fg_c)
			wx += w_box_w + w_gap

	# Tooltip and Combat Personality Paragraph (D-422, D-431: Redundant subtitle removed)
	if is_nat_active:
		# Combat Personality Paragraph in the open area above the brown line (D-422)
		var py := 376.0
		var pw_box := 403.0
		var ph_box := 144.0
		_draw_para_flat(Vector2(x, py), Vector2(pw_box, ph_box), 6.0, Color(0.025, 0.09, 0.15, 0.96))
		_draw_para_flat(Vector2(x, py), Vector2(4.0, ph_box), 1.0, GOLD)
		_text(title, Vector2(x + 16, py + 22), "NATURE // %s" % nat_name, 22, GOLD)
		_text_right(body, x + pw_box - 16, py + 20, "COMBAT PERSONALITY", 9, Color("8ea9b5"))
		draw_rect(Rect2(x + 12, py + 28, pw_box - 24, 1), Color(0.53, 0.65, 0.69, 0.2))

		var desc_txt: String = _get_nature_combat_description(c.nature_id)
		draw_multiline_string(body, Vector2(x + 16, py + 46), desc_txt, HORIZONTAL_ALIGNMENT_LEFT, pw_box - 32, 11, -1, Color("e3f2fd"))

		# Tactical parameter strip (D-422, D-432: Dynamic separation without collision)
		var ai_bias_str := _format_nature_ai(nat)
		draw_rect(Rect2(x + 12, py + 116, pw_box - 24, 1), Color(0.53, 0.65, 0.69, 0.15))
		var doc_lbl := "AI DOCTRINE:"
		var doc_w := body.get_string_size(doc_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		_text(body, Vector2(x + 16, py + 132), doc_lbl, 9, GOLD)
		_text(body, Vector2(x + 16 + doc_w + 10.0, py + 132), ai_bias_str, 9, Color("a5c2ce"))


func _panel_bar(x: float, y: float, w: float, label: String, k: float, color: Color, value: String) -> void:
	var body := FanMenu.body_font()
	_text(body, Vector2(x, y + 8), label, 10, Color("0a1a27"))
	var track_w := w - 36 - 70
	_draw_para_flat(Vector2(x + 36, y), Vector2(track_w, 9), 2.5, Color("8d9caa"))
	var fill_w := track_w * clampf(k, 0.0, 1.0)
	if fill_w > 1.0:
		_draw_para_flat(Vector2(x + 36, y), Vector2(fill_w, 9), 2.5, color)
	_text_right(body, x + w, y + 9, value, 10, Color("0a1a27"))


func _draw_moves(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var list := _moves(c)
	var top := 574.0

	# Section Header (D-413)
	_text(body, Vector2(29, top + 8), "SKILLS // %d EQUIPPED" % list.size(), 10, LIME)
	_text(body, Vector2(225, top + 8), "← → SELECT", 9, Color("8ea7b0"))
	var shift_prompt := "HOLD SHIFT: ADVANCED STATS  ·  Z EXPAND" if not _shift_held else "SHIFT ACTIVE: ADVANCED MATH VIEW"
	_text_right(body, size.x - 29, top + 8, shift_prompt, 9, LIME if _shift_held else Color("8ea7b0"))
	draw_rect(Rect2(29, top + 13, size.x - 58, 1), Color(LIME, 0.25))

	# 1. 2×4 Grid of Segmented Battle Strips (D-434)
	var strip_w := 136.0
	var strip_h := 38.0
	var skew := 7.0
	var gap_x := 8.0
	var gap_y := 12.0
	var grid_x := 29.0
	var grid_y := 598.0

	for i in list.size():
		var m := list[i]
		var on := i == _move
		var col := i % 4
		var row := i / 4
		var sx := grid_x + float(col) * (strip_w + gap_x)
		var sy := grid_y + float(row) * (strip_h + gap_y)

		var elem_col: Color = ELEMENT_COLORS.get(m.element, BattleFx.COLORS[m.element])
		var glyph_col: Color = ELEMENT_GLYPH_COLORS.get(m.element, Color.WHITE)

		# Outer Strip Body (Parallelogram with 7.0px slant)
		var body_bg: Color = Color("1a2e3b") if on else Color("091b26")
		var body_border: Color = Color("dfc980") if on else Color("173344")
		var border_w: float = 1.5 if on else 1.0

		_draw_para_flat(Vector2(sx, sy), Vector2(strip_w, strip_h), skew, body_bg)
		_draw_para_border(Vector2(sx, sy), Vector2(strip_w, strip_h), skew, body_border, border_w)

		# Left Element Icon Block (36px wide)
		var elem_w := 36.0
		var elem_bg: Color = elem_col if on else elem_col.darkened(0.25)
		_draw_para_flat(Vector2(sx, sy), Vector2(elem_w, strip_h), skew, elem_bg)

		var elem_icon := _get_element_icon(m.element)
		if elem_icon != null:
			var ic_sz := 18.0
			var center := Vector2(sx + (elem_w + skew) * 0.5 + 2.0, sy + 21.0)
			var ic_r := Rect2(center - Vector2(ic_sz * 0.5, ic_sz * 0.5), Vector2(ic_sz, ic_sz))
			draw_texture_rect(elem_icon, ic_r, false, glyph_col if on else glyph_col.darkened(0.12))

		# Hotkey number aligned to FAR TOP-LEFT CORNER over icon block (D-435)
		var num_w := 12.0
		var num_h := 11.0
		var num_skew := 2.0
		var num_y := sy
		var num_x := sx + skew - num_skew
		var num_bg: Color = Color("dfc980") if on else Color(0.04, 0.08, 0.12, 0.88)
		var num_border: Color = Color("dfc980") if on else Color(0.18, 0.35, 0.48, 0.85)
		var num_text_col: Color = Color("1b120c") if on else Color.WHITE

		_draw_para_flat(Vector2(num_x, num_y), Vector2(num_w, num_h), num_skew, num_bg)
		_draw_para_border(Vector2(num_x, num_y), Vector2(num_w, num_h), num_skew, num_border, 0.8)
		_text_centered(body, num_x + (num_w + num_skew) * 0.5, num_y + num_h - 2.5, str(i + 1), 8, num_text_col)

		# Right Data Area (Move Name + ATB Pips + MP Cost)
		var data_x := sx + elem_w + skew + 5.0
		var avail_w := (sx + strip_w + skew - 6.0) - data_x

		# Move Name in Teko font (full unhindered width, no collision!)
		var name_txt := m.display_name.to_upper()
		var name_col: Color = Color("dfc980") if on else Color.WHITE
		draw_string(title, Vector2(data_x, sy + 16.0), name_txt, HORIZONTAL_ALIGNMENT_LEFT, avail_w, 14, name_col)

		# Bottom Row: True Parallelogram ATB Pips (/ /) & Tight MP Text (D-434)
		var pip_w := 8.5
		var pip_h := 7.0
		var pip_skew := 2.5
		var pip_gap := 2.5
		var pip_y := sy + strip_h - 11.0

		for p in range(3):
			var filled: bool = (p < m.cost)
			var pip_x := data_x + float(p) * (pip_w + pip_gap)
			var pip_fill: Color = (Color("38bdf8") if on else Color("138cb5")) if filled else Color("081722")
			var pip_border_col: Color = (Color("7dd3fc") if on else Color("0284c7")) if filled else Color("1e384b")
			_draw_para_flat(Vector2(pip_x, pip_y), Vector2(pip_w, pip_h), pip_skew, pip_fill)
			_draw_para_border(Vector2(pip_x, pip_y), Vector2(pip_w, pip_h), pip_skew, pip_border_col, 0.8)

		# Tight MP Text (D-434: only rendered if m.mp_cost > 0; completely omitted/empty when 0)
		if m.mp_cost > 0:
			var mp_txt := "%dMP" % m.mp_cost
			var mp_col: Color = Color("38bdf8") if on else Color("8da8b5")
			var mp_w := body.get_string_size(mp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var mp_x := sx + strip_w + skew - 8.0 - mp_w
			_text(body, Vector2(mp_x, sy + strip_h - 4.5), mp_txt, 10, mp_col)

	# 2. Ability Tooltip Card with Watermark & Parallelogram Badges (D-416, D-434)
	var card_x := 618.0
	var card_w := (size.x - 29.0) - card_x
	var card_y := 598.0
	var card_h := 88.0
	var cr := Rect2(card_x, card_y, card_w, card_h)

	var active_m := list[_move]
	var active_col: Color = ELEMENT_COLORS.get(active_m.element, BattleFx.COLORS[active_m.element])
	var is_light := active_m.element in [
		Element.Type.RAIO, Element.Type.VENTO, Element.Type.LUZ,
		Element.Type.SOM, Element.Type.VENENO, Element.Type.FISICO
	]
	var text_col: Color = Color("080e18") if is_light else Color.WHITE
	var desc_col: Color = Color(0.08, 0.14, 0.20, 0.95) if is_light else Color(0.95, 0.97, 1.0, 0.95)

	# Full element flat card background (no borders - D-416)
	_draw_para_flat(cr.position, cr.size, 6.0, active_col)

	# Large translucent elemental watermark in the background (D-416)
	var wm_icon := _get_element_icon(active_m.element)
	if wm_icon != null:
		var wm_sz := 78.0
		var wm_pos := Vector2(cr.end.x - wm_sz - 16.0, cr.position.y + (cr.size.y - wm_sz) * 0.5)
		var wm_tint := Color(0, 0, 0, 0.18) if is_light else Color(1, 1, 1, 0.24)
		draw_texture_rect(wm_icon, Rect2(wm_pos, Vector2(wm_sz, wm_sz)), false, wm_tint)

	# Line 1: Move Name (Top Left), Badges beside name, and Cost/Power Parallelograms (Top Right)
	# (D-416, D-419)
	var name_txt := active_m.display_name.to_upper()
	var name_font_size := 22
	var name_w := title.get_string_size(name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, name_font_size).x
	var name_pos := Vector2(card_x + 18.0, card_y + 24.0)
	_text(title, name_pos, name_txt, name_font_size, text_col)

	# Badges beside name (Right side of name text, matching font height ~20px - D-419)
	var bx := card_x + 18.0 + name_w + 12.0
	var badge_h := 20.0
	var badge_w := 20.0
	var badge_y := card_y + 6.0

	var type_name := "magical"
	var type_col := Color("0ea5e9")
	var type_fg := Color.WHITE
	if active_m.kind == Skill.Kind.MELEE or (active_m.element == Element.Type.FISICO and active_m.kind != Skill.Kind.STATUS):
		type_name = "physical"
		type_col = Color("ef4444")
		type_fg = Color.WHITE
	elif active_m.display_name.to_lower() == "guard":
		type_name = "guard"
		type_col = Color("cbd5e1")
		type_fg = Color("080e18")
	elif active_m.display_name.to_lower() == "teleport":
		type_name = "dodge"
		type_col = Color("fcb900")
		type_fg = Color("080e18")

	if active_m.kind != Skill.Kind.STATUS:
		var type_ic := _get_type_icon(type_name)
		if type_ic != null:
			_draw_para_flat(Vector2(bx, badge_y), Vector2(badge_w, badge_h), 3.0, type_col)
			draw_texture_rect(type_ic, Rect2(Vector2(bx + 2.5, badge_y + 2.5), Vector2(15.0, 15.0)), false, type_fg)
			bx += badge_w + 7.0

	var range_name := "mid"
	if active_m.is_aoe:
		range_name = "area"
	elif active_m.kind == Skill.Kind.MELEE:
		range_name = "melee"
	elif active_m.kind == Skill.Kind.PROJECTILE:
		range_name = "long"

	if active_m.kind != Skill.Kind.STATUS:
		var range_ic := _get_range_icon(range_name)
		if range_ic != null:
			_draw_para_flat(Vector2(bx, badge_y), Vector2(badge_w, badge_h), 3.0, Color.WHITE)
			draw_texture_rect(range_ic, Rect2(Vector2(bx + 2.5, badge_y + 2.5), Vector2(15.0, 15.0)), false, Color("080e18"))
			bx += badge_w + 7.0

	# Top-Right Cost & Power Parallelograms (Height matching font size 20px - D-416, D-419)
	var power_txt := "—" if active_m.kind == Skill.Kind.STATUS else "×%s" % String.num(active_m.power, 1).replace(".", ",")
	var pow_str := "POWER %s" % power_txt
	var pow_w := body.get_string_size(pow_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 12.0
	var mp_str := "%d MP" % active_m.mp_cost
	var mp_w := body.get_string_size(mp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 12.0
	var atb_str := "%d ATB" % active_m.cost
	var atb_w := body.get_string_size(atb_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 12.0

	var skew_badge := 4.0
	var chip_h := 20.0
	var chip_y := card_y + 6.0
	var chip_text_y := card_y + 20.0
	var right_edge := cr.end.x - 14.0 - skew_badge
	var pow_x := right_edge - pow_w
	var mp_x := pow_x - mp_w - 6.0
	var atb_x := mp_x - atb_w - 6.0

	# ATB parallelogram (Teal #0891b2 / #138cb5)
	_draw_para_flat(Vector2(atb_x, chip_y), Vector2(atb_w, chip_h), skew_badge, Color("0891b2"))
	_text(body, Vector2(atb_x + 6.0 + skew_badge * 0.4, chip_text_y), atb_str, 10, Color.WHITE)

	# MP parallelogram (Blue #2563eb / #3f72e5)
	_draw_para_flat(Vector2(mp_x, chip_y), Vector2(mp_w, chip_h), skew_badge, Color("2563eb"))
	_text(body, Vector2(mp_x + 6.0 + skew_badge * 0.4, chip_text_y), mp_str, 10, Color.WHITE)

	# POWER parallelogram (Amber #f59e0b)
	_draw_para_flat(Vector2(pow_x, chip_y), Vector2(pow_w, chip_h), skew_badge, Color("f59e0b"))
	_text(body, Vector2(pow_x + 6.0 + skew_badge * 0.4, chip_text_y), pow_str, 10, Color("080e18"))

	# Subtle horizontal divider
	draw_rect(Rect2(card_x + 18.0, card_y + 32.0, card_w - 36.0, 1.0), Color(0, 0, 0, 0.10) if is_light else Color(1, 1, 1, 0.12))

	# Expanded Information Section (D-419: dense, informative, clean typography)
	if _shift_held:
		# Shift Mode: Advanced Formulas, Scaling math & MP cycles (D-413, D-419)
		var base_dmg := roundi(float(c.attack) * active_m.power)
		var scale_attr := "MAG" if (active_m.kind != Skill.Kind.MELEE and active_m.element != Element.Type.FISICO) else "STR"
		var attr_val := c.mag if scale_attr == "MAG" else c.str
		var mod_str := "FORMULA: Base ×%.2f (%d Dmg) · Scaling: %s %d (+%.1f%%) · Nature Bonus: %+d" % [
			active_m.power, base_dmg, scale_attr, attr_val, float(attr_val) * 5.0, c.innate_stats.get(scale_attr, 0)
		]
		var regen_left := c.mp_regen_left()
		var rec_str := "MP CYCLE: Cost %d MP · Pool %d/%d MP · Next +%d MP in %.1fs · Windup: %.2fs" % [
			active_m.mp_cost, c.mp, c.max_mp, c.mp_regen_amount(), regen_left,
			(active_m.windup if active_m.windup >= 0.0 else 1.0)
		]
		var target_type := "Area of Effect" if active_m.is_aoe else "Single Target"
		var tip_str := "TACTICAL: %s · %s delivery · Element: %s (1.5× against target weaknesses)" % [
			target_type, Skill.kind_name(active_m.kind), Element.name_of(active_m.element)
		]
		draw_string(body, Vector2(card_x + 18, card_y + 47), mod_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 96, 10, text_col)
		draw_string(body, Vector2(card_x + 18, card_y + 62), rec_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 96, 10, desc_col)
		draw_string(body, Vector2(card_x + 18, card_y + 77), tip_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 96, 10, desc_col)
	else:
		# Standard View (Non-expanded Z): Rich 3-line breakdown (D-419, D-420)
		# Line 1: Mechanics & Tactical Action (NO redundant ATB/MP/Power repetition)
		var line1_str := active_m.tactical_summary()

		# Line 2: Visual Aesthetic & Displacement / Motion
		var line2_str := active_m.visual_motion_summary()

		# Line 3: Scaling Attribute, Wind-up & MP Cycle (clean metrics)
		var scale_attr := "MAG" if (active_m.kind != Skill.Kind.MELEE and active_m.element != Element.Type.FISICO) else "STR"
		var attr_val := c.mag if scale_attr == "MAG" else c.str
		var wind_sec := active_m.windup if active_m.windup >= 0.0 else 1.0
		var line3_str := "Wind-up: %.2fs (interruptible) · Scales with %s %d · MP Cycle: +%d MP / 8.0s" % [
			wind_sec, scale_attr, attr_val, c.mp_regen_amount()
		]

		draw_string(body, Vector2(card_x + 18, card_y + 47), line1_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 96, 11, text_col)
		draw_string(body, Vector2(card_x + 18, card_y + 62), line2_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 96, 11, desc_col)
		draw_string(body, Vector2(card_x + 18, card_y + 77), line3_str, HORIZONTAL_ALIGNMENT_LEFT, card_w - 96, 10, desc_col)


func _draw_detail(c: Combatant) -> void:
	var body := FanMenu.body_font()
	var title := FanMenu.title_font()
	var m := _moves(c)[_move]

	# Backdrop Dimmer
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.016, 0.055, 0.094, 0.92))

	# Dossier Modal Dimensions (780 x 510 px centered on 1280 x 720)
	var mw := 780.0
	var mh := 510.0
	var mx := (size.x - mw) * 0.5
	var my := (size.y - mh) * 0.5
	var r := Rect2(mx, my, mw, mh)

	# Main Panel (Flat Neo-brutalist solid fill, D-135, D-416, D-420)
	draw_rect(r, Color(0.024, 0.082, 0.13, 0.98))

	# Left Accent Bar in canonical element color
	var elem_col: Color = ELEMENT_COLORS.get(m.element, BattleFx.COLORS.get(m.element, Color.WHITE))
	draw_rect(Rect2(r.position.x, r.position.y, 8.0, r.size.y), elem_col)

	# Watermark Icon in background
	var wm_icon := _get_element_icon(m.element)
	if wm_icon != null:
		var wm_sz := 130.0
		var wm_pos := Vector2(r.end.x - wm_sz - 24.0, r.position.y + 16.0)
		draw_texture_rect(wm_icon, Rect2(wm_pos, Vector2(wm_sz, wm_sz)), false, Color(1, 1, 1, 0.08))

	# --- Header Bar ---
	var hx := r.position.x + 28.0
	var hy := r.position.y + 26.0
	_text(body, Vector2(hx, hy), "SKILL DOSSIER // TECHNICAL SPECIFICATION", 10, elem_col)

	var name_txt := m.display_name.to_upper()
	var name_sz := 32
	var name_w := title.get_string_size(name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, name_sz).x
	_text(title, Vector2(hx, hy + 36.0), name_txt, name_sz, PAPER)

	# Badges right beside name (22x22px, matching cap-height - D-419)
	var bx := hx + name_w + 14.0
	var badge_y := hy + 16.0
	var badge_sz := 22.0

	var type_name := "magical"
	var type_col := Color("0ea5e9")
	var type_fg := Color.WHITE
	if m.kind == Skill.Kind.MELEE or (m.element == Element.Type.FISICO and m.kind != Skill.Kind.STATUS):
		type_name = "physical"
		type_col = Color("ef4444")
		type_fg = Color.WHITE
	elif m.display_name.to_lower() == "guard":
		type_name = "guard"
		type_col = Color("cbd5e1")
		type_fg = Color("080e18")
	elif m.display_name.to_lower() == "teleport":
		type_name = "dodge"
		type_col = Color("fcb900")
		type_fg = Color("080e18")

	if m.kind != Skill.Kind.STATUS:
		var type_ic := _get_type_icon(type_name)
		if type_ic != null:
			_draw_para_flat(Vector2(bx, badge_y), Vector2(badge_sz, badge_sz), 3.0, type_col)
			draw_texture_rect(type_ic, Rect2(Vector2(bx + 3.0, badge_y + 3.0), Vector2(16.0, 16.0)), false, type_fg)
			bx += badge_sz + 8.0

	var range_name := "mid"
	if m.is_aoe:
		range_name = "area"
	elif m.kind == Skill.Kind.MELEE:
		range_name = "melee"
	elif m.kind == Skill.Kind.PROJECTILE:
		range_name = "long"

	if m.kind != Skill.Kind.STATUS:
		var range_ic := _get_range_icon(range_name)
		if range_ic != null:
			_draw_para_flat(Vector2(bx, badge_y), Vector2(badge_sz, badge_sz), 3.0, Color.WHITE)
			draw_texture_rect(range_ic, Rect2(Vector2(bx + 3.0, badge_y + 3.0), Vector2(16.0, 16.0)), false, Color("080e18"))
			bx += badge_sz + 8.0

	# Top-Right Cost & Power Parallelograms (22px high - D-416, D-419)
	var power_txt := "—" if m.kind == Skill.Kind.STATUS else "×%s" % String.num(m.power, 1).replace(".", ",")
	var pow_str := "POWER %s" % power_txt
	var pow_w := body.get_string_size(pow_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 16.0
	var mp_str := "%d MP" % m.mp_cost
	var mp_w := body.get_string_size(mp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 16.0
	var atb_str := "%d ATB" % m.cost
	var atb_w := body.get_string_size(atb_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 16.0

	var skew_badge := 4.0
	var chip_h := 22.0
	var chip_y := hy + 16.0
	var chip_text_y := hy + 31.0
	var right_edge := r.end.x - 24.0 - skew_badge
	var pow_x := right_edge - pow_w
	var mp_x := pow_x - mp_w - 8.0
	var atb_x := mp_x - atb_w - 8.0

	_draw_para_flat(Vector2(atb_x, chip_y), Vector2(atb_w, chip_h), skew_badge, Color("0891b2"))
	_text(body, Vector2(atb_x + 8.0 + skew_badge * 0.4, chip_text_y), atb_str, 11, Color.WHITE)

	_draw_para_flat(Vector2(mp_x, chip_y), Vector2(mp_w, chip_h), skew_badge, Color("2563eb"))
	_text(body, Vector2(mp_x + 8.0 + skew_badge * 0.4, chip_text_y), mp_str, 11, Color.WHITE)

	_draw_para_flat(Vector2(pow_x, chip_y), Vector2(pow_w, chip_h), skew_badge, Color("f59e0b"))
	_text(body, Vector2(pow_x + 8.0 + skew_badge * 0.4, chip_text_y), pow_str, 11, Color("080e18"))

	# Divider below header
	draw_rect(Rect2(hx, hy + 50.0, r.size.x - 56.0, 1.0), Color(0.4, 0.55, 0.65, 0.25))

	# --- 5 Structured Content Sections (D-420) ---
	var content_w := r.size.x - 56.0
	var cy := hy + 68.0

	# 1. MECHANICS & EFFECT (O que faz)
	_text(body, Vector2(hx, cy), "[ 01 // MECHANICS & COMBAT EFFECT ]", 10, elem_col)
	cy += 16.0
	var mech_txt := m.mechanics_description()
	draw_multiline_string(body, Vector2(hx, cy), mech_txt, HORIZONTAL_ALIGNMENT_LEFT, content_w, 11, -1, PAPER)
	cy += 36.0

	# 2. VISUALS & VFX (Visual)
	_text(body, Vector2(hx, cy), "[ 02 // VISUALS & 3D AESTHETICS ]", 10, GOLD)
	cy += 16.0
	var vis_txt := m.visual_description()
	draw_multiline_string(body, Vector2(hx, cy), vis_txt, HORIZONTAL_ALIGNMENT_LEFT, content_w, 11, -1, Color("ffeaa7"))
	cy += 36.0

	# 3. MOTION & DISPLACEMENT (Deslocamento)
	_text(body, Vector2(hx, cy), "[ 03 // MOTION & SPATIAL DISPLACEMENT ]", 10, Color("38bdf8"))
	cy += 16.0
	var mot_txt := m.motion_description()
	draw_multiline_string(body, Vector2(hx, cy), mot_txt, HORIZONTAL_ALIGNMENT_LEFT, content_w, 11, -1, Color("bae6fd"))
	cy += 36.0

	# 4. WIND-UP & TELEGRAPH (Wind-up)
	_text(body, Vector2(hx, cy), "[ 04 // WIND-UP & TELEGRAPH BEHAVIOR ]", 10, Color("f87171"))
	cy += 16.0
	var wind_txt := m.windup_description()
	draw_multiline_string(body, Vector2(hx, cy), wind_txt, HORIZONTAL_ALIGNMENT_LEFT, content_w, 11, -1, Color("fecaca"))
	cy += 36.0

	# 5. TACTICAL SYNERGY & SCALING (Escala e Tática)
	_text(body, Vector2(hx, cy), "[ 05 // TACTICAL SYNERGY & ATTRIBUTE SCALING ]", 10, Color("a78bfa"))
	cy += 16.0
	var scale_attr_d := "MAG" if (m.kind != Skill.Kind.MELEE and m.element != Element.Type.FISICO) else "STR"
	var attr_val_d := c.mag if scale_attr_d == "MAG" else c.str
	var base_dmg := roundi(float(c.attack) * m.power)
	var syn_txt := "Scales with %s (%d pts, +%.1f%% dmg) · Base Damage: %d HP · Exploits target elemental weaknesses for 1.5× damage · MP Recovery cycle: +%d MP / 8.0s." % [
		scale_attr_d, attr_val_d, float(attr_val_d) * 5.0, base_dmg, c.mp_regen_amount()
	]
	draw_multiline_string(body, Vector2(hx, cy), syn_txt, HORIZONTAL_ALIGNMENT_LEFT, content_w, 11, -1, Color("ddd6fe"))

	# Footer: Close Prompt (Parallelogram Flat Button)
	var btn_y := r.end.y - 38.0
	_draw_para_flat(Vector2(hx, btn_y), Vector2(130.0, 26.0), 4.0, LIME)
	_text(title, Vector2(hx + 18.0, btn_y + 19.0), "CLOSE (Z / X)", 15, Color("080e18"))


func _format_nature_mods(mods: Dictionary) -> String:
	var parts: Array[String] = []
	for attr in ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]:
		var val := int(mods.get(attr, 0))
		if val > 0:
			parts.append("+%d %s" % [val, attr])
		elif val < 0:
			parts.append("%d %s" % [val, attr])
	if parts.is_empty():
		return "Neutral (Balanced attributes)"
	return "  ·  ".join(parts)


func _format_nature_ai(nat: Dictionary) -> String:
	var agg: float = float(nat.get("aggression_mult", 1.0))
	var bias: float = float(nat.get("atb_reserve_bias", 0.0))
	var bias_str := "Default"
	if bias > 0.1:
		bias_str = "Cautious (+%.1fs)" % bias
	elif bias < -0.1:
		bias_str = "Aggressive (%.1fs)" % bias
	return "Aggression %.1f×  ·  ATB Reserve %s" % [agg, bias_str]


func _get_nature_combat_description(nature_id: String) -> String:
	match nature_id.to_lower():
		"brave":
			return "Frontline vanguard. Advances directly into melee range and spends ATB blocks immediately on attack skills, prioritizing continuous offensive pressure over dodging."
		"modest":
			return "Backline spellcaster. Stays at long range and prioritizes casting high-impact magical skills, pacing actions carefully to conserve MP for crucial moments."
		"adamant":
			return "Relentless melee brawler. Charges targets aggressively in close quarters, maintaining high offensive pressure with heavy physical strikes."
		"timid":
			return "Evasive skirmisher. Maintains safe distance from enemies and reserves ATB blocks to reliably dodge incoming attacks."
		"calm":
			return "Defensive counter-attacker. Reads enemy attack telegraphs and reserves ATB blocks to Guard incoming hits, striking back during enemy recovery windows."
		"jolly":
			return "Mobile flanker. Continuously repositions around targets to exploit openings and disrupt combat tempo with swift, opportunistic strikes."
		"docile":
			return "Support specialist. Holds a safe distance behind allies, prioritizing party recovery, shields, and buffs before committing to direct attacks."
		"hardy", _:
			return "Balanced combatant. Maintains a steady combat cadence with standard ATB distribution, adapting evenly between offensive strikes and defense."
