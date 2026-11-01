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
var _inc_tags: Dictionary = {}  ## Battle.Incoming -> AttackTag
var _hint: EvadeHint
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
	_log.size = Vector2(386, 64)
	_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.clip_text = true
	_tabs = CameraTabs.new()
	add_child(_tabs)
	_hint = EvadeHint.new()
	add_child(_hint)
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
	_alert.text = ""  # The floating attack tags replace this text.
	_track_hp()
	_layout_cards()
	_layout_tags()
	_sync_incoming()
	queue_redraw()


func _screen_pos(c: Combatant, height: float) -> Variant:
	var model: Node3D = _models.get(c)
	if model == null:
		return null
	var world := model.global_position + Vector3(0, height, 0)
	if _camera.is_position_behind(world):
		return null
	return _camera.unproject_position(world)


func _sync_incoming() -> void:
	var live := {}
	if not _status_open:
		for inc in _battle.incoming:
			if inc.dodged:
				continue
			live[inc] = true
			var tag: AttackTag = _inc_tags.get(inc)
			if tag == null:
				tag = AttackTag.new()
				tag.inc = inc
				add_child(tag)
				_inc_tags[inc] = tag
			var p: Variant = _screen_pos(inc.attacker, _head_of(inc.attacker) + (0.4 if not inc.attacker.is_player else 0.2))
			tag.visible = p != null
			if p != null:
				var lift := 72.0 if not inc.attacker.is_player else 10.0
				tag.position = (p as Vector2) - Vector2(tag.size.x * 0.5, tag.size.y + lift)
			tag.queue_redraw()
	for inc in _inc_tags.keys():
		if not live.has(inc):
			(_inc_tags[inc] as Control).queue_free()
			_inc_tags.erase(inc)
	# Evade prompt on the player's character.
	var leader: Combatant = _battle.party[0]
	var evadable = _battle.find_evadable(leader) if not _status_open else null
	_hint.visible = evadable != null
	if evadable != null:
		var hp: Variant = _screen_pos(leader, _head_of(leader) + 0.3)
		_hint.visible = hp != null
		if hp != null:
			_hint.position = (hp as Vector2) - Vector2(_hint.size.x * 0.5, _hint.size.y + 14.0)
		_hint.time_left = evadable.time_left
		_hint.queue_redraw()


func _layout_cards() -> void:
	if _status_open:
		return
	for card in _cards:
		if card.hero:
			card.position = Vector2(MARGIN, 318)
		else:
			# Ally card scaled down by 15% (scale = Vector2(0.85, 0.85)).
			# Anchored permanently beside its original home position on the right of the field.
			var eff_w := card.size.x * card.scale.x
			var eff_h := card.size.y * card.scale.y
			var ally_x := 1280.0 - eff_w - MARGIN
			var ally_y := 720.0 - FOOTER_H - eff_h - 18.0
			if card.order > 1:
				ally_y -= (card.order - 1) * (eff_h + 12.0)
			card.position = Vector2(ally_x, ally_y)


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
	var hero := true:
		set(val):
			hero = val
			if not hero:
				scale = Vector2(0.85, 0.85)
			else:
				scale = Vector2.ONE
	var order := 0
	var _portrait: Texture2D

	# Animation states for ATB and Burst
	var _prev_atb := 0.0
	var _prev_burst := 0
	var _block_is_full: Array[bool] = [false, false, false, false, false]
	var _block_fill_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var _extra_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var _burst_gain_flash := 0.0

	func _init() -> void:
		size = Vector2(330, 104)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		if not hero:
			scale = Vector2(0.85, 0.85)
		if combatant != null:
			_prev_atb = combatant.atb
			_prev_burst = combatant.burst
			for i in 5:
				_block_is_full[i] = combatant.atb >= float(i + 1)
			var path := "res://personagens/portraits/%s.png" % combatant.name.to_lower()
			if ResourceLoader.exists(path):
				_portrait = load(path)

	func _process(delta: float) -> void:
		if combatant == null:
			return
		var cur_atb := combatant.atb
		var cur_burst := combatant.burst

		# Extra block detection: sudden ATB jump >= 0.7 blocks (from weakness/crit/auto-evade)
		if cur_atb - _prev_atb >= 0.7:
			var start_b := clampi(int(floor(_prev_atb)), 0, 4)
			var end_b := clampi(int(floor(cur_atb)), 0, 4)
			for b in range(start_b, end_b + 1):
				_extra_flash[b] = 1.0

		# Block full completion detection (ficando cheios)
		for i in 5:
			if cur_atb >= float(i + 1):
				if not _block_is_full[i]:
					_block_is_full[i] = true
					_block_fill_flash[i] = 1.0
			else:
				_block_is_full[i] = false

		# Burst gain detection
		if cur_burst > _prev_burst:
			_burst_gain_flash = 1.0

		_prev_atb = cur_atb
		_prev_burst = cur_burst

		# Decay animation timers
		for i in 5:
			if _block_fill_flash[i] > 0.0:
				_block_fill_flash[i] = maxf(_block_fill_flash[i] - delta * 3.2, 0.0)
			if _extra_flash[i] > 0.0:
				_extra_flash[i] = maxf(_extra_flash[i] - delta * 2.2, 0.0)
		if _burst_gain_flash > 0.0:
			_burst_gain_flash = maxf(_burst_gain_flash - delta * 2.5, 0.0)

		queue_redraw()

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
		var now := Time.get_ticks_msec()

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
			# Background slot
			BattleHud.slant(self, r, 3.0, atb_bg)
			BattleHud.slant(self, Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), 2.8, atb_bg.darkened(0.2))

			var fill := clampf(c.atb - i, 0.0, 1.0)
			if fill > 0.0:
				var fill_w := r.size.x * fill
				var base_col: Color = atb_fill
				if fill >= 1.0:
					# Breathing glow pulse for full blocks
					var breathe := 0.5 + 0.5 * sin(now * 0.007 + i * 1.3)
					base_col = atb_fill.lightened(0.15 + breathe * 0.12)
				var fill_rect := Rect2(r.position, Vector2(fill_w, r.size.y))
				BattleHud.slant(self, fill_rect, 3.0 * fill, base_col)

				# Block actively rising: animated shimmer and glowing leading edge
				if fill < 1.0:
					# Shimmer sweep along filling portion
					var shim_phase := fmod(now * 0.003 + i * 0.4, 1.4)
					if shim_phase >= 0.0 and shim_phase <= fill:
						var sx := r.position.x + shim_phase * r.size.x
						draw_line(Vector2(sx + 2.0, r.position.y), Vector2(sx - 1.0, r.end.y), Color(1, 1, 1, 0.45), 2.0)
					# Glowing leading edge
					var edge_x := r.position.x + fill_w
					var edge_pulse := 0.75 + 0.25 * sin(now * 0.018)
					var edge_col := Color.WHITE if hero else Color("e0d4ff")
					edge_col.a = edge_pulse
					draw_line(Vector2(edge_x + 1.0, r.position.y), Vector2(edge_x - 2.0, r.end.y), edge_col, 2.0)
				else:
					# Full block: glowing top highlight line
					draw_line(Vector2(r.position.x + 3.0, r.position.y + 1), Vector2(r.end.x, r.position.y + 1), Color(1, 1, 1, 0.45), 1.0)

			# Extra blocks surge animation (from weakness/crit/auto-evade)
			if _extra_flash[i] > 0.0:
				var surge_alpha := _extra_flash[i]
				var surge_col := GOLD.lerp(Color.WHITE, 0.4)
				surge_col.a = surge_alpha * 0.85
				BattleHud.slant(self, Rect2(r.position - Vector2(1, 1), r.size + Vector2(2, 2)), 3.0, surge_col)

			# Block just became full: completion flash
			if _block_fill_flash[i] > 0.0:
				var flash_alpha := _block_fill_flash[i]
				var flash_col := Color(1, 1, 1, flash_alpha * 0.8)
				BattleHud.slant(self, Rect2(r.position - Vector2(1, 1), r.size + Vector2(2, 2)), 3.0, flash_col)

		# Burst slot
		var slot := Rect2(bar_x + 30 + 5 * 29 + 4, 78, 25, 17)
		if c.burst > 0:
			var b_pulse := 0.5 + 0.5 * sin(now * 0.01)
			# Outer pulsating aura
			var aura := Rect2(slot.position - Vector2(2.0 + b_pulse * 1.5, 2.0 + b_pulse * 1.5), slot.size + Vector2(4.0 + b_pulse * 3.0, 4.0 + b_pulse * 3.0))
			draw_rect(aura, Color(1.0, 0.82, 0.2, 0.25 + b_pulse * 0.25))
			# Slot fill
			draw_rect(slot, GOLD.lerp(Color.WHITE, b_pulse * 0.2))
			# Traveling diagonal sheen
			var sheen := fmod(now * 0.002, 1.5) - 0.25
			var sheen_x := slot.position.x + sheen * slot.size.x
			draw_line(Vector2(sheen_x + 3, slot.position.y), Vector2(sheen_x - 3, slot.end.y), Color(1, 1, 1, 0.6), 2.0)
			# Glowing border
			draw_rect(slot, Color.WHITE.lerp(GOLD, 0.4), false, 1.5)
			# Burst text
			var b_txt := "B" if c.burst < 2 else "B%d" % c.burst
			draw_string(font, slot.position + Vector2(0, 13), b_txt, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 11, Color("201a08"))
			# Sudden burst gain flash
			if _burst_gain_flash > 0.0:
				var g_col := Color(1, 1, 1, _burst_gain_flash * 0.85)
				draw_rect(Rect2(slot.position - Vector2(3, 3), slot.size + Vector2(6, 6)), g_col)
		else:
			# Empty burst slot
			draw_rect(slot, Color("151a24"))
			draw_rect(slot, Color("344254"), false, 1.0)
			draw_string(font, slot.position + Vector2(0, 13), "B", HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 11, Color("4a576b"))

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


# --- Incoming attack tag -----------------------------------------------------------

## Floating label over an attacker: move name, who it targets and a countdown bar.
class AttackTag extends Control:
	var inc

	func _init() -> void:
		size = Vector2(160, 48)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if inc == null:
			return
		var font := FanMenu.body_font()
		var col: Color = BattleFx.COLORS[inc.element]
		var enemy: bool = not inc.attacker.is_player
		BattleHud.slant(self, Rect2(Vector2(3, 4), size - Vector2(3, 4)), 7.0, Color(0, 0, 0, 0.5))
		BattleHud.slant(self, Rect2(Vector2.ZERO, size - Vector2(3, 4)), 7.0, Color(0.04, 0.08, 0.14, 0.94))
		draw_rect(Rect2(0, 0, 6, size.y - 4), col)
		draw_string(font, Vector2(14, 17), String(inc.label).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 13, Color.WHITE)
		draw_string(font, Vector2(14, 31), "%s  >  %s" % [inc.attacker.name, inc.target.name], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, CORAL if enemy else AQUA)
		var k := clampf(1.0 - inc.time_left / Battle.WINDUP, 0.0, 1.0)
		draw_rect(Rect2(14, 36, size.x - 30, 4), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(14, 36, (size.x - 30) * k, 4), col)


## Pulsing prompt over the player's character while an attack aimed at it can
## still be evaded.
class EvadeHint extends Control:
	var time_left := 0.0

	func _init() -> void:
		size = Vector2(190, 50)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

	func _draw() -> void:
		var font := FanMenu.body_font()
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		BattleHud.slant(self, Rect2(Vector2(4, 5), size - Vector2(4, 5)), 8.0, Color(0, 0, 0, 0.5))
		BattleHud.slant(self, Rect2(Vector2.ZERO, size - Vector2(4, 5)), 8.0, LIME.lerp(Color.WHITE, pulse * 0.5))
		draw_string(FanMenu.title_font(), Vector2(16, 30), "ESPAÇO", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
		draw_string(font, Vector2(104, 21), "DESVIAR!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
		draw_string(font, Vector2(104, 36), "%.1fs" % time_left, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(INK, 0.7))
