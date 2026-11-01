class_name BattleHud
extends Control
## Battle HUD in the approved V9 layout, drawn natively: hero card above the
## command stack (left column), ally card anchored next to its model (lower
## right), name/HP tags floating over each enemy, camera indicator, alerts,
## log and a footer with the real key bindings. Everything reads live data
## from Battle / Combatant. MP does not exist in the runtime yet, so cards show
## "MP N/D" instead of an invented value.

const LIME := Color("d7fd6a")
const CORAL := Color("ff624f")
const AQUA := Color("62d8e7")
const GOLD := Color("f7cb78")
const INK := Color("080e18")
const NAVY := Color("101c2c")
const CREAM := Color("f0eedf")
const ROMAN := ["I", "II", "III", "IV"]
const FOOTER_H := 36.0
const MARGIN := 28.0

signal status_closed
signal status_unit_selected(unit: Combatant)

var menu: FanMenu

var _battle: Battle
var _camera: Camera3D
var _models: Dictionary = {}
var _director: BattleCamera
var _cards: Array[UnitCard] = []
var _tags: Dictionary = {}  ## enemy Combatant -> EnemyTag
var _alert: Label
var _log: Label
var _log_lines: Array[String] = []
var _tabs: CameraTabs
var _target: Combatant
var _status: StatusPanel
var _status_open := false
var _shown_hp: Dictionary = {}  ## Combatant -> float
var _last_hp: Dictionary = {}
var _hp_hold: Dictionary = {}  ## Combatant -> ticks (msec) before the bar starts moving


static func slant(c: CanvasItem, r: Rect2, skew: float, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)]), color)


static func text_right(c: CanvasItem, font: Font, right_x: float, y: float, text: String, size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	c.draw_string(font, Vector2(right_x - w, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func setup(battle: Battle, party: Array[Combatant], enemies: Array[Combatant], camera: Camera3D, models: Dictionary, director: BattleCamera) -> void:
	_battle = battle
	_camera = camera
	_models = models
	_director = director
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keeps working while Tactics/Status pause the game.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_vignette()
	for i in party.size():
		var card := UnitCard.new()
		card.combatant = party[i]
		card.hud = self
		card.hero = i == 0
		card.order = i
		add_child(card)
		_cards.append(card)
	for e in enemies:
		var tag := EnemyTag.new()
		tag.combatant = e
		tag.hud = self
		add_child(tag)
		_tags[e] = tag
	menu = FanMenu.new()
	menu.position = Vector2(MARGIN, 424)
	add_child(menu)
	_alert = _make_label(Vector2(0, 28), 14, CORAL)
	_alert.size = Vector2(1280, 60)
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log = _make_label(Vector2(866, 108), 13, Color(CREAM, 0.85))
	_log.size = Vector2(386, 56)
	_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tabs = CameraTabs.new()
	add_child(_tabs)
	_status = StatusPanel.new()
	add_child(_status)
	_status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status.closed.connect(func() -> void:
		_set_status_mode(false)
		status_closed.emit())
	_status.selected.connect(func(u: Combatant) -> void: status_unit_selected.emit(u))
	director.mode_changed.connect(func(m: BattleCamera.Mode) -> void: _tabs.mode = m; _tabs.queue_redraw())
	battle.log_message.connect(_on_log)


## Dark edges and a faint cyan glow in the middle, as in the V9 prototype.
func _add_vignette() -> void:
	var edge := Gradient.new()
	edge.set_color(0, Color(0, 0, 0, 0))
	edge.set_color(1, Color(0.02, 0.04, 0.08, 0.7))
	edge.add_point(0.55, Color(0, 0, 0, 0))
	var glow := Gradient.new()
	glow.set_color(0, Color(0.47, 0.78, 0.8, 0.14))
	glow.set_color(1, Color(0.47, 0.78, 0.8, 0))
	for g in [glow, edge]:
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 512
		tex.height = 288
		var rect := TextureRect.new()
		rect.texture = tex
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.show_behind_parent = true
		add_child(rect)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _make_label(pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_font_override("font", FanMenu.body_font())
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	add_child(l)
	return l


## HP as displayed: waits for the hit effect to land, then drains smoothly.
func shown_hp(c: Combatant) -> float:
	return _shown_hp.get(c, float(c.hp))


func _track_hp() -> void:
	var now := Time.get_ticks_msec()
	for c in _models:
		var last: int = _last_hp.get(c, c.hp)
		if c.hp < last:
			_hp_hold[c] = maxi(now + 450, c.get_meta("hp_hold_until", 0))
		elif c.hp > last:
			_hp_hold[c] = now + 250
		_last_hp[c] = c.hp
		var shown: float = _shown_hp.get(c, float(c.hp))
		if now >= _hp_hold.get(c, 0):
			shown = move_toward(shown, float(c.hp), maxf(absf(shown - c.hp) * 0.12, 0.35))
		_shown_hp[c] = shown


## Pause-screen with everyone's status; closing it emits status_closed.
func open_status(party: Array[Combatant], enemies: Array[Combatant]) -> void:
	_set_status_mode(true)
	_status.open(party, enemies)


func _set_status_mode(on: bool) -> void:
	_status_open = on
	menu.visible = not on
	_alert.visible = not on
	_log.visible = not on
	_tabs.visible = not on
	for card in _cards:
		card.visible = not on
	for e in _tags:
		(_tags[e] as Control).visible = false


func set_target(c: Combatant) -> void:
	_target = c


func set_menu_style(style: FanMenu.Style, header: String) -> void:
	menu.style = style
	menu.header = header
	menu.position = Vector2(MARGIN, 424) if style == FanMenu.Style.DRAWER else Vector2(MARGIN, 436)
	menu.queue_redraw()


func _on_log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 3:
		_log_lines.pop_front()
	_log.text = "\n".join(_log_lines)


func _process(_delta: float) -> void:
	if _battle == null:
		return
	var lines := PackedStringArray()
	for inc in _battle.incoming:
		if not inc.dodged:
			lines.append("! %s  >  %s   %.1fs" % [inc.attacker.name, inc.target.name, inc.time_left])
	_alert.text = "\n".join(lines)
	_track_hp()
	_layout_cards()
	_layout_tags()
	queue_redraw()


func _screen_pos(c: Combatant, height: float) -> Variant:
	var model: Node3D = _models.get(c)
	if model == null:
		return null
	var world := model.global_position + Vector3(0, height, 0)
	if _camera.is_position_behind(world):
		return null
	return _camera.unproject_position(world)


func _layout_cards() -> void:
	if _status_open:
		return
	var hero_stack := Rect2(MARGIN - 6, 300, 350, 400)
	var placed: Array[Rect2] = []
	for card in _cards:
		if card.hero:
			card.position = Vector2(MARGIN, 318)
			placed.append(Rect2(card.position, card.size))
			continue
		var feet: Variant = _screen_pos(card.combatant, 0.0)
		var head: Variant = _screen_pos(card.combatant, _head_of(card.combatant))
		var body := Rect2(Vector2(900, 380), Vector2(120, 200))
		if feet != null and head != null:
			var top: Vector2 = head
			var bottom: Vector2 = feet
			body = Rect2(Vector2(minf(top.x, bottom.x) - 70, top.y), Vector2(140, maxf(bottom.y - top.y, 40)))
		var limit := Rect2(hero_stack.end.x + 12, 110, 1280 - hero_stack.end.x - 28, 720 - FOOTER_H - 118)
		var spots := [
			Vector2(body.end.x + 10, body.end.y - card.size.y),
			Vector2(body.position.x - card.size.x - 10, body.end.y - card.size.y),
			Vector2(body.end.x - card.size.x, body.end.y + 8),
			Vector2(1280 - card.size.x - 16, 720 - FOOTER_H - card.size.y - 8)]
		var chosen := Rect2()
		for i in spots.size():
			var spot: Vector2 = spots[i]
			spot.x = clampf(spot.x, limit.position.x, limit.end.x - card.size.x)
			spot.y = clampf(spot.y, limit.position.y, limit.end.y - card.size.y)
			chosen = Rect2(spot, card.size)
			var clear := not chosen.intersects(body)
			for other in placed:
				clear = clear and not chosen.intersects(other)
			if clear:
				break
		card.position = chosen.position
		placed.append(chosen)


func _head_of(c: Combatant) -> float:
	var model: Node3D = _models.get(c)
	return model.get_meta("head_y") if model != null and model.has_meta("head_y") else 2.0


func _layout_tags() -> void:
	if _status_open:
		return
	for e in _tags:
		var tag: EnemyTag = _tags[e]
		var model: Node3D = _models.get(e)
		var head := 2.4
		if model != null and model.has_meta("head_y"):
			head = model.get_meta("head_y") + 0.4
		var p: Variant = _screen_pos(e, head)
		tag.visible = p != null and e.is_alive()
		if p != null:
			tag.position = (p as Vector2) - Vector2(tag.size.x * 0.5, tag.size.y)
			tag.active = e == _target
			tag.queue_redraw()


func _draw() -> void:
	var font := FanMenu.body_font()
	var title := FanMenu.title_font()
	draw_string(title, Vector2(MARGIN, 52), "CRAWL", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, CREAM)
	var w := title.get_string_size("CRAWL", HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	draw_string(title, Vector2(MARGIN + w, 52), "/", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, CORAL)
	draw_string(title, Vector2(MARGIN + w + 16, 52), "MON", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, LIME)
	draw_rect(Rect2(0, 720 - FOOTER_H, 1280, FOOTER_H), Color(0.03, 0.07, 0.11, 0.95))
	draw_line(Vector2(0, 720 - FOOTER_H), Vector2(1280, 720 - FOOTER_H), Color("2a3d47"), 1.0)
	var hint := "SETAS MOVER   ·   Z CONFIRMAR   ·   X VOLTAR   ·   ESPAÇO DESVIAR (EVADE)   ·   C CONFIGURAÇÕES"
	draw_string(font, Vector2(MARGIN, 720 - 13), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b5c3c2"))
	text_right(self, font, 1280 - MARGIN, 720 - 13, "ATB DE 5 BLOCOS", 11, GOLD)


# --- Unit card -----------------------------------------------------------------

class UnitCard extends Control:
	var combatant: Combatant
	var hud: BattleHud
	var hero := true
	var order := 0
	var _portrait: Texture2D

	func _init() -> void:
		size = Vector2(330, 104)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		var path := "res://personagens/portraits/%s.png" % combatant.name.to_lower()
		if ResourceLoader.exists(path):
			_portrait = load(path)

	func _draw() -> void:
		var c := combatant
		var font := FanMenu.body_font()
		var accent := AQUA if hero else Color("b6a3fe")
		var bg := Color("eae9d9") if hero else Color("17283b")
		var fg := Color("111b29") if hero else Color("eceada")
		var track := Color("7b8c90") if hero else Color("526176")
		var hp_col := Color("e96159") if hero else Color("b5a5fe")
		var atb_bg := Color("c1c4b9") if hero else Color("344359")
		var atb_fill := Color("167e9e") if hero else Color("c7adfc")
		# Title row.
		draw_string(font, Vector2(8, 11), ("%s / RECURSOS" % c.name.to_upper()) if hero else "ALIADO / RECURSOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, CREAM if hero else Color("e6ddff"))
		BattleHud.text_right(self, font, size.x - 8, 11, "ATB %02d" % int(c.atb), 10, LIME)
		# Card body.
		var body := Rect2(0, 18, size.x, 82)
		BattleHud.slant(self, Rect2(body.position + Vector2(6, 6), body.size), 8.0, Color(0, 0, 0, 0.5))
		BattleHud.slant(self, body, 8.0, bg)
		draw_rect(Rect2(0, 18, 7, 82), accent)
		# Portrait.
		var pr := Rect2(16, 26, 56, 62)
		BattleHud.slant(self, pr, 6.0, Color("263d57") if hero else Color("54456c"))
		if _portrait != null:
			draw_texture_rect(_portrait, Rect2(pr.position + Vector2(8, 6), Vector2(44, 44)), false)
		# Name.
		draw_string(font, Vector2(84, 44), c.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 150, 18, fg)
		BattleHud.text_right(self, font, size.x - 48, 40, "JOGADOR" if hero else "ALIADO · IA", 8, Color(fg, 0.6))
		# HP.
		var bar_x := 84.0
		var bar_w := 120.0
		draw_rect(Rect2(bar_x, 52, bar_w, 7), track)
		var shown := hud.shown_hp(c)
		draw_rect(Rect2(bar_x, 52, bar_w * clampf(shown / c.max_hp, 0.0, 1.0), 7), hp_col)
		draw_string(font, Vector2(bar_x + bar_w + 8, 59), "HP %d/%d" % [ceili(shown), c.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)
		# MP (not in the runtime yet).
		draw_rect(Rect2(bar_x, 66, bar_w, 7), Color(track, 0.35))
		draw_string(font, Vector2(bar_x + bar_w + 8, 73), "MP N/D", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(fg, 0.45))
		# ATB blocks + burst slot.
		draw_string(font, Vector2(bar_x, 91), "ATB", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)
		for i in int(Combatant.BLOCKS):
			var r := Rect2(bar_x + 30 + i * 29, 80, 26, 13)
			BattleHud.slant(self, r, 3.0, atb_bg)
			var fill := clampf(c.atb - i, 0.0, 1.0)
			if fill > 0.0:
				BattleHud.slant(self, Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), 3.0, atb_fill if fill < 1.0 else atb_fill.lightened(0.15))
		var slot := Rect2(bar_x + 30 + 5 * 29 + 4, 79, 24, 16)
		draw_rect(slot, GOLD if c.burst > 0 else Color("202430"))
		draw_rect(slot, Color("b58e32"), false, 1.0)
		draw_string(font, slot.position + Vector2(0, 12), "B" if c.burst < 2 else "B%d" % c.burst, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 11, Color("232324") if c.burst > 0 else Color(GOLD, 0.6))
		# Order numeral.
		draw_rect(Rect2(size.x - 40, 18, 30, 82), Color("d6d6c9") if hero else Color("33455b"))
		draw_string(FanMenu.title_font(), Vector2(size.x - 40, 70), ROMAN[mini(order, 3)], HORIZONTAL_ALIGNMENT_CENTER, 30, 22, Color("203448") if hero else Color("e3dcfb"))


# --- Enemy tag -------------------------------------------------------------------

class EnemyTag extends Control:
	var combatant: Combatant
	var hud: BattleHud
	var active := false

	func _init() -> void:
		size = Vector2(132, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := combatant
		var font := FanMenu.body_font()
		var box := Rect2(0, 0, size.x, 44)
		BattleHud.slant(self, Rect2(box.position + Vector2(3, 4), box.size), 7.0, Color(0, 0, 0, 0.45))
		BattleHud.slant(self, box, 7.0, Color("eae9d9") if active else Color(INK, 0.9))
		var name_col := Color("b74134") if active else CORAL
		draw_string(font, Vector2(0, 17), c.name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, name_col)
		draw_rect(Rect2(14, 23, size.x - 28, 5), Color("7b8c90") if active else Color("3a4756"))
		var shown := hud.shown_hp(c)
		draw_rect(Rect2(14, 23, (size.x - 28) * clampf(shown / c.max_hp, 0.0, 1.0), 5), CORAL)
		draw_string(font, Vector2(0, 40), "HP %d / %d" % [ceili(shown), c.max_hp], HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color("111d2a") if active else CREAM)
		var cx := size.x * 0.5
		var cy := 54.0
		var diamond := PackedVector2Array([Vector2(cx, cy - 8), Vector2(cx + 8, cy), Vector2(cx, cy + 8), Vector2(cx - 8, cy)])
		if active:
			draw_colored_polygon(diamond, CORAL)
		else:
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), CORAL, 2.0)


# --- Camera indicator --------------------------------------------------------------

class CameraTabs extends Control:
	var mode := BattleCamera.Mode.CINEMA
	const NAMES := ["CINEMA", "TÁTICA", "IMPACTO"]

	func _init() -> void:
		size = Vector2(266, 70)
		position = Vector2(1280 - 24 - 266, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := FanMenu.body_font()
		draw_string(font, Vector2(2, 10), "DIREÇÃO DE CÂMERA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f3e7cd"))
		BattleHud.text_right(self, font, size.x - 2, 10, "AUTOMÁTICA", 9, LIME)
		for i in 3:
			var r := Rect2(i * 88, 18, 86, 44)
			var on := i == int(mode)
			BattleHud.slant(self, r, 7.0, LIME if on else Color(0.05, 0.1, 0.16, 0.88))
			draw_string(FanMenu.title_font(), Vector2(r.position.x, r.position.y + 21), "%02d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, INK if on else Color("9cb4bb"))
			draw_string(font, Vector2(r.position.x, r.position.y + 36), NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, INK if on else Color("9cb4bb"))
