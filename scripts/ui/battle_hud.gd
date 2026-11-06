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
var _banner := {}  ## Status move being performed (D-031): {skill, who, t0}
var _pops: Array = []  ## Damage numbers: {c, text, crit, weak, t0, dx}
var _engage_marks: Array = []  ## {p, k, back} drawn by _draw()
var _back_until: Dictionary = {}  ## Combatant -> msec: shows VOLTANDO until then
var _tags: Dictionary = {}  ## enemy Combatant -> EnemyTag
var _alert: Label
var _log: Label
var _log_lines: Array[String] = []
var _tabs: CameraTabs
var _target: Combatant
var _status: StatusPanel
var _status_open := false
var _reward_layer: RewardLayer
var _heal_layer: Control  ## D-347: the option 2 numbers above the HP cards/tags
var _inc_tags: Dictionary = {}  ## Battle.Incoming -> AttackTag
var _hint: EvadeHint
var _burn_k: Dictionary = {}  ## D-239: Combatant -> 0..1, how much its card is burning (eases in and out)
var _burn_ticks: Dictionary = {}  ## D-239: Combatant -> {t0 (msec), dmg} of its last Burn tick


static func slant(c: CanvasItem, r: Rect2, skew: float, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)]), color)


## Draws `tex` inside the same parallelogram as slant(): the texture covers the
## frame's bounding box (centre crop, aspect kept) and is clipped to the slant.
static func slant_texture(c: CanvasItem, r: Rect2, skew: float, tex: Texture2D) -> void:
	var pts := PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)])
	var tex_aspect := float(tex.get_width()) / float(tex.get_height())
	var box_aspect := r.size.x / r.size.y
	var u_span := 1.0
	var v_span := 1.0
	if box_aspect < tex_aspect:
		u_span = box_aspect / tex_aspect
	else:
		v_span = tex_aspect / box_aspect
	var uvs := PackedVector2Array()
	for p in pts:
		var k := (p - r.position) / r.size
		uvs.append(Vector2(0.5 + (k.x - 0.5) * u_span, 0.5 + (k.y - 0.5) * v_span))
	c.draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, tex)


static func text_right(c: CanvasItem, font: Font, right_x: float, y: float, text: String, size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	c.draw_string(font, Vector2(right_x - w, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func setup(battle: Battle, party: Array[Combatant], enemies: Array[Combatant], camera: Camera3D, models: Dictionary, director: BattleCamera) -> void:
	_battle = battle
	battle.hit_resolved.connect(_on_hit_pop)
	battle.healed.connect(heal_gain)  # D-347: number above the owner's HP card/tag
	battle.burn_ticked.connect(func(t: Combatant, d: int) -> void: _burn_ticks[t] = {"t0": Time.get_ticks_msec(), "dmg": d})  # D-239
	battle.status_pause_started.connect(func(inc) -> void:
		_banner = {"skill": String(inc.label), "who": inc.attacker.name, "t0": Time.get_ticks_msec(), "out": -1})
	battle.status_pause_ended.connect(func(_inc) -> void:
		if not _banner.is_empty():
			_banner["out"] = Time.get_ticks_msec())
	battle.engage_ended.connect(func(actor: Combatant, _o, _g, _s) -> void: _back_until[actor] = Time.get_ticks_msec() + 800)
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
	# D-348: in front of the cards/tags, below the menu/status; visible from the first frame.
	_heal_layer = Control.new()
	_heal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_heal_layer)
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
	_log.visible = false  # D-343: right side clean, as in the heal gain prototype
	_tabs = CameraTabs.new()
	add_child(_tabs)
	_hint = EvadeHint.new()
	add_child(_hint)
	_reward_layer = RewardLayer.new()
	_reward_layer.hud = self
	_reward_layer.battle = battle
	add_child(_reward_layer)
	_reward_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle.reward_landed.connect(_on_reward_landed)
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


## D-347: the odometer is archived; HP is shown and changes immediately.
func shown_hp(c: Combatant) -> float:
	return float(c.hp)


## D-347: the option 2 Heal Gain number appears above the owner's HP card/tag, outside it, near
## the HP row. It is tilted right for an enemy and left for an ally, drifts diagonally up in that
## direction and fades in/out over 1.4 s. The green crosses stay at the character (HealGainFx).
func heal_gain(_actor: Combatant, target: Combatant, amount: int) -> void:
	# D-348: the HP/bar is applied first; the number appears a beat later.
	await get_tree().create_timer(0.10).timeout
	if not is_instance_valid(self) or not is_instance_valid(target):
		return
	var card: Control = null
	for c in _cards:
		if c.combatant == target:
			card = c
			break
	var enemy := not target.is_player
	if card == null:
		card = _tags.get(target)
	if card == null:
		return
	var card_size: Vector2 = card.size * card.scale
	var top := card.position.y
	if card is EnemyTag:
		top -= 16.0  # the enemy badge row floats above the tag
	var center_x := card.position.x + card_size.x * 0.5
	var inward := 1.0 if center_x < get_viewport_rect().size.x * 0.5 else -1.0
	HealGainMark.spawn(_heal_layer, Vector2(center_x, top), amount, enemy, inward)


## Debug aid: an enemy that enters the field mid-battle (test spawns).
func add_enemy(c: Combatant) -> void:
	var tag := EnemyTag.new()
	tag.combatant = c
	tag.hud = self
	add_child(tag)
	_tags[c] = tag


## Debug aid: a test enemy left the field; drop its tag and selection.
func remove_enemy(c: Combatant) -> void:
	var tag: EnemyTag = _tags.get(c)
	if tag != null:
		tag.queue_free()
		_tags.erase(c)
	if _target == c:
		_target = null


## Pause-screen with everyone's status; closing it emits status_closed.
func open_status(party: Array[Combatant], enemies: Array[Combatant]) -> void:
	_set_status_mode(true)
	_status.open(party, enemies)


func _set_status_mode(on: bool) -> void:
	_status_open = on
	menu.visible = not on
	_alert.visible = not on
	_log.visible = false  # D-343: keep the right side clean even after closing Status
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
	for inc in _battle.active_attacks():
		if not inc.dodged:
			lines.append("! %s  >  %s   %.1fs" % [inc.attacker.name, inc.target.name, inc.eta()])
	_alert.text = ""  # The floating attack tags replace this text.
	_track_burn(_delta)
	_layout_cards()
	_layout_tags()
	for card in _cards:  # A landed reward nudges its card for a moment.
		if card.pulse > 0.0:
			card.position += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 3.0 * card.pulse
			card.pulse = maxf(card.pulse - _delta * 2.5, 0.0)
	for e in _tags:
		var t: EnemyTag = _tags[e]
		if t.pulse > 0.0:
			t.position += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 3.0 * t.pulse
			t.pulse = maxf(t.pulse - _delta * 2.5, 0.0)
	_sync_incoming()
	_draw_engaged()
	queue_redraw()


## Damage numbers pop the instant a hit lands (hit_resolved is emitted at the impact).
func _on_hit_pop(_attacker: Combatant, target: Combatant, _element: Element.Type, info: Dictionary) -> void:
	if info.get("evaded", false) or info.get("status", false):
		return
	_pops.append({"c": target, "value": int(info["dmg"]), "crit": bool(info["crit"]), "weak": bool(info["weak"]),
		"t0": Time.get_ticks_msec(), "dx": float((_pops.size() % 3) - 1) * 84.0 + randf_range(-14.0, 14.0)})


## The status move's name strip: slides in from the left, holds while the engine is
## paused, slides out when it runs again.
func _draw_banner() -> void:
	if _banner.is_empty():
		return
	var now := Time.get_ticks_msec()
	var t_in := (now - int(_banner["t0"])) / 1000.0
	var k := clampf(t_in / 0.18, 0.0, 1.0)
	if int(_banner["out"]) >= 0:
		var t_out := (now - int(_banner["out"])) / 1000.0
		if t_out > 0.22:
			_banner = {}
			return
		k = 1.0 - clampf(t_out / 0.22, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - k, 3.0)
	var title := FanMenu.title_font()
	var font := FanMenu.body_font()
	var y := 58.0  # Up at the top of the screen, between the logo and the camera tabs.
	var w := 560.0
	var x := lerpf(-w, 360.0, ease)
	BattleHud.slant(self, Rect2(Vector2(x + 8, y + 8), Vector2(w, 70)), 14.0, Color(0, 0, 0, 0.45 * ease))
	BattleHud.slant(self, Rect2(Vector2(x, y), Vector2(w, 70)), 14.0, Color(INK, 0.96))
	draw_rect(Rect2(x, y, 8, 70), CORAL)
	draw_string(font, Vector2(x + 26, y + 22), "%s USA" % String(_banner["who"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(CREAM, 0.85))
	draw_string(title, Vector2(x + 26, y + 58), String(_banner["skill"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w - 40, 38, LIME)


func _draw_pops() -> void:
	var now := Time.get_ticks_msec()
	var title := FanMenu.title_font()
	var keep: Array = []
	for p in _pops:
		var age := (now - int(p["t0"])) / 1000.0
		if age > 1.05:
			continue
		keep.append(p)
		var c: Combatant = p["c"]
		var at: Variant = _screen_pos(c, _head_of(c) * 0.3)
		if at == null:
			continue
		# Pop in with an overshoot, settle, drift up and fade out.
		var sc := 1.0
		if age < 0.1:
			sc = lerpf(0.35, 1.5, age / 0.1)
		elif age < 0.22:
			sc = lerpf(1.5, 1.0, (age - 0.1) / 0.12)
		var rise := 78.0 * (1.0 - pow(1.0 - clampf(age / 1.0, 0.0, 1.0), 2.0))
		var jitter := sin(age * 90.0) * 5.0 * clampf(1.0 - age / 0.2, 0.0, 1.0)
		var alpha := 1.0 - clampf((age - 0.68) / 0.37, 0.0, 1.0)
		var crit: bool = p["crit"]
		var weak: bool = p["weak"]
		var size := 84 if crit else 62
		var fill := Color("ffd84a") if crit else (Color("ff9a3a") if weak else Color("f6f3e6"))
		var text := str(p["value"])
		var origin: Vector2 = (at as Vector2) + Vector2(float(p["dx"]) + jitter, -4.0 - rise)
		draw_set_transform(origin, -0.12, Vector2(sc, sc))
		var half := Vector2(-200.0, 0.0)
		draw_string(title, half + Vector2(5, 6), text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, Color(CORAL.r, CORAL.g, CORAL.b, alpha))
		draw_string_outline(title, half, text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, 14, Color(0.04, 0.07, 0.12, alpha))
		draw_string(title, half, text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, Color(fill, alpha))
		if crit:
			draw_string(title, half + Vector2(0, -size * 0.75), "CRÍTICO!", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 22, Color(1.0, 0.95, 0.6, alpha))
		elif weak:
			draw_string(title, half + Vector2(0, -size * 0.75), "FRAQUEZA!", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 20, Color(1.0, 0.8, 0.5, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_pops = keep


## Above an engaged character: how long it stays next to its opponent (the slow-motion),
## then a short "VOLTANDO" while it leaps back home.
func _draw_engaged() -> void:
	_engage_marks.clear()
	if _status_open:
		return
	for c in _battle.party + _battle.enemies:
		if not c.is_alive():
			continue
		var p: Variant = _screen_pos(c, _head_of(c) + 1.0)
		if p == null:
			continue
		if c.engaged_with != null:
			_engage_marks.append({"p": p, "k": clampf(c.engage_left / Battle.ENGAGE_SECONDS, 0.0, 1.0), "back": false})
		elif Time.get_ticks_msec() < _back_until.get(c, 0):
			_engage_marks.append({"p": p, "k": 0.0, "back": true})


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
		for inc in _battle.active_attacks():
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
				var lift := 92.0 if not inc.attacker.is_player else 10.0
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
		_hint.time_left = minf(evadable.travel_left(), 9.99)
		_hint.can_now = evadable.can_evade_now()
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


## Where the token flies to: the matching slot on the owner's card (or enemy tag).
func reward_dest(r) -> Variant:
	for card in _cards:
		if card.combatant == r.owner:
			if r.kind == "burst":
				return card.burst_slot_global()
			return card.extra_slot_global(r.slot) if r.extra else card.atb_slot_global(r.slot)
	var tag: EnemyTag = _tags.get(r.owner)
	if tag != null and tag.visible:
		if r.kind == "burst":
			return tag.burst_slot_global()
		return tag.extra_slot_global(r.slot) if r.extra else tag.atb_slot_global(r.slot)
	return null


## Where the token is born: over the character that earned it.
func reward_source(r) -> Variant:
	return _screen_pos(r.source, _head_of(r.source) * 0.55)


func _on_reward_landed(r) -> void:
	for card in _cards:
		if card.combatant == r.owner:
			card.pulse = 1.0
	var tag: EnemyTag = _tags.get(r.owner)
	if tag != null:
		tag.pulse = 1.0


## Rising flame tongues behind a Burst slot (it is on fire while a Burst is available).
static func draw_flames(ci: CanvasItem, rect: Rect2, now: int, power: float) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var base_y := rect.position.y + rect.size.y * 0.55
	ci.draw_circle(Vector2(cx, rect.position.y + rect.size.y * 0.4), rect.size.x * 1.1, Color(1.0, 0.55, 0.1, (0.12 + 0.05 * sin(now * 0.01)) * power))
	for j in 5:
		var ph := now * 0.013 + j * 1.9
		var h := (13.0 + 8.0 * sin(ph)) * power * (rect.size.y / 17.0 + 0.4)
		var x := rect.position.x + (j + 0.5) * rect.size.x / 5.0
		var w := rect.size.x / 4.5
		var sway := sin(ph * 0.7) * 2.5
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w, base_y), Vector2(x + sway, base_y - h), Vector2(x + w, base_y)]), Color(1.0, 0.42, 0.08, 0.9))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.55, base_y), Vector2(x + sway * 0.7, base_y - h * 0.62), Vector2(x + w * 0.55, base_y)]), Color(1.0, 0.85, 0.3, 0.95))


## D-239: Burn on the HUD. The background of the card turns scorched dark orange (the HP bar keeps its colours).
const BURN_TOP := Color("7d2e06")
const BURN_BOT := Color("cc5b0c")
const BURN_TEXT := Color("fff1d4")


func _track_burn(delta: float) -> void:
	if _battle == null:
		return
	for c in _battle.party + _battle.enemies:
		var goal := 1.0 if (c.is_burning() and c.is_alive()) else 0.0
		_burn_k[c] = move_toward(float(_burn_k.get(c, 0.0)), goal, delta * 2.8)


func burn_k(c: Combatant) -> float:
	return float(_burn_k.get(c, 0.0))


## Seconds since the last Burn tick of `c` (9 when there was none).
func burn_tick_age(c: Combatant) -> float:
	var d: Dictionary = _burn_ticks.get(c, {})
	return 9.0 if d.is_empty() else float(Time.get_ticks_msec() - int(d["t0"])) / 1000.0


## 1 -> 0 over 0.3 s after each tick: a brief lightening of the HP fill.
func burn_flash(c: Combatant) -> float:
	return clampf(1.0 - burn_tick_age(c) / 0.3, 0.0, 1.0) * burn_k(c)


## Seconds of Burn left (D-238: the next tick plus one second per tick after it).
static func burn_left(c: Combatant) -> float:
	return maxf(c.burn_clock + float(c.burn_ticks_left - 1) * Battle.BURN_INTERVAL, 0.0)


static func _slant_pts(r: Rect2, skew: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)])


## Card background. Not burning: the flat colour of the game. Burning: a dark orange gradient that pulses, a scorched
## (charred) edge with an ember line, tongues of fire licking up from the bottom edge (never higher than `max_flame`
## px, and drawn before the text and the ATB cells so they stay on top) and a hot halo around the card.
static func draw_card_bg(ci: CanvasItem, r: Rect2, skew: float, normal: Color, k: float, max_flame: float, now: int) -> void:
	if k <= 0.01:
		slant(ci, r, skew, normal)
		return
	var pulse := 0.5 + 0.5 * sin(now * 0.0094)
	var top := normal.lerp(BURN_TOP.lerp(BURN_BOT, 0.1 + 0.2 * pulse), k)
	var bot := normal.lerp(BURN_BOT.lerp(Color("e8841f"), pulse * 0.6), k)
	for i in 4:
		ci.draw_colored_polygon(_slant_pts(r.grow(2.0 + float(i) * 2.5), skew), Color(1.0, 0.42, 0.08, (0.09 + 0.05 * pulse) * k / float(i + 1)))
	ci.draw_polygon(_slant_pts(r, skew), PackedColorArray([top, top, bot, bot]))
	var n := 26
	var soot := Color(0.05, 0.02, 0.01, 0.62 * k)
	var ember := Color(1.0, 0.5, 0.1, (0.45 + 0.35 * pulse) * k)
	var top_in := PackedVector2Array()
	var bot_in := PackedVector2Array()
	var top_out := PackedVector2Array()
	var bot_out := PackedVector2Array()
	for i in n:
		var f := float(i) / float(n - 1)
		var d := 2.5 + 3.0 * absf(sin(float(i) * 1.7 + now * 0.004)) + 2.0 * absf(sin(float(i) * 2.9 - now * 0.003))
		var x := lerpf(r.position.x + skew, r.end.x, f)
		var xb := lerpf(r.position.x, r.end.x - skew, f)
		top_out.append(Vector2(x, r.position.y))
		top_in.append(Vector2(x, r.position.y + d))
		bot_out.append(Vector2(xb, r.end.y))
		bot_in.append(Vector2(xb, r.end.y - d * 0.6))
	for strip in [[top_out, top_in], [bot_out, bot_in]]:
		var a_pts: PackedVector2Array = strip[0]
		var b_pts: PackedVector2Array = strip[1]
		var poly := PackedVector2Array(a_pts)
		for j in range(b_pts.size() - 1, -1, -1):
			poly.append(b_pts[j])
		ci.draw_colored_polygon(poly, soot)
		ci.draw_polyline(b_pts, ember, 1.0)
	var step := (r.size.x - skew) / float(n)
	for i in n:
		var h := clampf(0.6 + 0.5 * sin(now * 0.011 + i * 1.7) + 0.35 * sin(now * 0.017 + i * 2.9) + 0.6 * maxf(sin(now * 0.0045 - i * 0.5), 0.0), 0.2, 1.7) * max_flame * 0.95 * k
		var x0 := r.position.x + float(i) * step
		var lean := sin(now * 0.007 + i * 2.3) * 4.0
		var base_y := r.end.y - 0.5
		var cols := [Color(0.85, 0.25, 0.04, 0.8), Color(1.0, 0.54, 0.11, 0.8), Color(1.0, 0.82, 0.29, 0.85)]
		for layer in 3:
			var lh := h * (1.0 - 0.28 * float(layer))
			var half := step * (0.62 - 0.17 * float(layer))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x0 + step * 0.5 - half, base_y), Vector2(x0 + step * 0.5 + lean * (1.0 - 0.2 * float(layer)), base_y - lh), Vector2(x0 + step * 0.5 + half, base_y)]), cols[layer])


## Embers rising off a burning card (deterministic in time, so no randomness in the HUD).
static func draw_burn_embers(ci: CanvasItem, body: Rect2, k: float, now: int) -> void:
	if k <= 0.01:
		return
	for j in 16:
		var ph := fposmod(now * 0.0011 + float(j) * 0.37, 1.0)
		var x := body.position.x + 8.0 + fposmod(float(j) * 47.3, body.size.x - 16.0) + sin(ph * 6.0 + float(j)) * 4.0
		var y := body.end.y - 2.0 - ph * 32.0
		var sz := 1.5 * (1.0 - ph * 0.5)
		var p := Vector2(x, y)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -sz), p + Vector2(sz, 0), p + Vector2(0, sz), p + Vector2(-sz, 0)]), Color(Color("ffd24a").lerp(Color("ff8a1c"), ph), (1.0 - ph) * k * 0.9))


## Pending Burn damage on the HP bar: the last stretch of the fill, hatched, shrinking with every tick.
static func draw_burn_pending(ci: CanvasItem, bar: Rect2, c: Combatant, shown_frac: float) -> void:
	if not c.is_burning() or c.max_hp <= 0:
		return
	var fw := bar.size.x * clampf(shown_frac, 0.0, 1.0)
	var pw := clampf(float(c.burn_ticks_left * Battle.BURN_DMG) / float(c.max_hp) * bar.size.x, 0.0, fw)
	if pw < 0.5:
		return
	var px := bar.position.x + fw - pw
	ci.draw_rect(Rect2(px, bar.position.y, pw, bar.size.y), Color("ffb347", 0.5))
	var s := px - bar.size.y
	while s < px + pw:
		var a := Vector2(clampf(s, px, px + pw), bar.end.y)
		var b := Vector2(clampf(s + bar.size.y, px, px + pw), bar.position.y)
		ci.draw_line(a, b, Color(0.1, 0.02, 0.0, 0.85), 1.0)
		s += 2.4


## Burn damage numbers: they leave the HP bar at every tick and hop (two bounces) up and away from the card. Same
## font, size, outline and pop-in as the normal damage number (_draw_pops), but ORANGE instead of white (creator).
## Only the latest tick is drawn.
func draw_burn_tick_jump(ci: CanvasItem, _font: Font, bar: Rect2, frac: float, c: Combatant, _fs: int) -> void:
	var age := burn_tick_age(c)
	if age >= 1.1 or burn_k(c) <= 0.0:
		return
	var f := age / 1.1
	var fw := bar.size.x * clampf(frac, 0.0, 1.0)
	var phase := f * 2.0
	var n := int(phase)
	var local := phase - float(n)
	var h := (1.0 - pow(2.0 * local - 1.0, 2.0)) * 46.0 * pow(0.45, float(n))
	var dmg := int((_burn_ticks.get(c, {}) as Dictionary).get("dmg", Battle.BURN_DMG))
	var sc := 1.0
	if age < 0.1:
		sc = lerpf(0.35, 1.5, age / 0.1)
	elif age < 0.22:
		sc = lerpf(1.5, 1.0, (age - 0.1) / 0.12)
	var alpha := 1.0 - clampf((f - 0.7) / 0.3, 0.0, 1.0)
	var title := FanMenu.title_font()
	var text := str(dmg)
	var origin := Vector2(bar.position.x + fw + 26.0 * f, bar.position.y - 22.0 - h)
	ci.draw_set_transform(origin, -0.12, Vector2(sc, sc))
	var half := Vector2(-200.0, 0.0)
	ci.draw_string(title, half + Vector2(5, 6), text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, 62, Color(CORAL.r, CORAL.g, CORAL.b, alpha))
	ci.draw_string_outline(title, half, text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, 62, 14, Color(0.04, 0.07, 0.12, alpha))
	ci.draw_string(title, half, text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, 62, Color(Color("ff8a1c"), alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _head_of(c: Combatant) -> float:
	var model: Node3D = _models.get(c)
	return model.get_meta("head_y") if model != null and model.has_meta("head_y") else 2.0


func _layout_tags() -> void:
	if _status_open:
		return
	var shown: Array[EnemyTag] = []
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
			if tag.visible:
				shown.append(tag)
	_separate_tags(shown)


## Tags that would overlap are pushed apart sideways (each half the overlap), so
## every HP bar stays readable and still sits over its own enemy. Recomputed from
## the projected spots every frame, so there is no drift.
func _separate_tags(shown: Array[EnemyTag]) -> void:
	const GAP := 6.0
	shown.sort_custom(func(a: EnemyTag, b: EnemyTag) -> bool:
		return a.position.x + a.size.x * 0.5 < b.position.x + b.size.x * 0.5)
	for _pass in 6:
		for i in range(shown.size() - 1):
			var a := shown[i]
			var b := shown[i + 1]
			var ra := Rect2(a.position, a.size).grow(GAP * 0.5)
			var rb := Rect2(b.position, b.size).grow(GAP * 0.5)
			if not ra.intersects(rb):
				continue
			var push := (a.position.x + a.size.x + GAP) - b.position.x
			if push > 0.0:
				a.position.x -= push * 0.5
				b.position.x += push * 0.5
	var view := get_viewport_rect().size
	for t in shown:
		t.position.x = clampf(t.position.x, 0.0, maxf(0.0, view.x - t.size.x))


## Five position marks (-2..+2) under a character: the filled one is where it stands.
static func draw_pos_marks(ci: CanvasItem, center: Vector2, step: int) -> void:
	for i in 5:
		var r := Rect2(center + Vector2((i - 2) * 14.0 - 5.0, 0.0), Vector2(10.0, 5.0))
		var here := i - 2 == step
		ci.draw_rect(r, Color(0.95, 0.93, 0.85, 0.95) if here else Color(0.4, 0.5, 0.6, 0.45))
		if i == 2 and not here:
			ci.draw_rect(Rect2(r.position + Vector2(3.0, -2.0), Vector2(4.0, 2.0)), Color(0.95, 0.93, 0.85, 0.5))  # The middle


func _draw() -> void:
	var font := FanMenu.body_font()
	for m in _engage_marks:
		var pt: Vector2 = m["p"]
		var bar := Rect2(pt + Vector2(-36, 0), Vector2(72, 7))
		if m["back"]:
			draw_string(font, pt + Vector2(-36, 8), "VOLTANDO", HORIZONTAL_ALIGNMENT_CENTER, 72, 11, CORAL)
		else:
			draw_string(font, pt + Vector2(-36, -4), "ENGAJADO", HORIZONTAL_ALIGNMENT_CENTER, 72, 10, Color(CREAM, 0.9))
			draw_rect(bar, Color(0, 0, 0, 0.55))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(m["k"]), bar.size.y)), LIME.lerp(CORAL, 1.0 - float(m["k"])))
			draw_rect(bar, Color(1, 1, 1, 0.5), false, 1.0)
	_draw_banner()
	_draw_pops()
	draw_rect(Rect2(0, 720 - FOOTER_H, 1280, FOOTER_H), Color(0.03, 0.07, 0.11, 0.95))
	draw_line(Vector2(0, 720 - FOOTER_H), Vector2(1280, 720 - FOOTER_H), Color("2a3d47"), 1.0)
	var hint := "SETAS MOVER   ·   Z CONFIRMAR   ·   X VOLTAR   ·   ESPAÇO DESVIAR   ·   1-9 GOLPES   ·   R REPETE   ·   C CONFIG."
	draw_string(font, Vector2(MARGIN, 720 - 13), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b5c3c2"))


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
	var pulse := 0.0  ## Set when a reward lands: a small nudge of the whole card.

	func atb_slot_global(i: int) -> Vector2:
		return position + Vector2(84.0 + 30.0 + i * 29.0 + 13.0, 86.5) * scale

	func extra_slot_global(k: int) -> Vector2:
		return position + Vector2(84.0 + 30.0 + k * 11.0 + 4.5, 99.0) * scale

	func burst_slot_global() -> Vector2:
		return position + Vector2(84.0 + 30.0 + 5.0 * 29.0 + 4.0 + 12.5, 86.5) * scale

	func _init() -> void:
		size = Vector2(330, 104)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		if not hero:
			scale = Vector2(0.85, 0.85)
		if combatant != null:
			_prev_atb = combatant.shown_atb()
			_prev_burst = combatant.shown_burst()
			for i in 5:
				_block_is_full[i] = combatant.shown_atb() >= float(i + 1)
			var path := "res://personagens/portraits/%s.png" % combatant.name.to_lower()
			if ResourceLoader.exists(path):
				_portrait = load(path)

	func _process(delta: float) -> void:
		if combatant == null:
			return
		var cur_atb := combatant.shown_atb()
		var cur_burst := combatant.shown_burst()

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
		var bk := hud.burn_k(c)  # D-239
		var fg := (Color("111b29") if hero else Color("eceada")).lerp(BattleHud.BURN_TEXT, bk)
		var track := Color("7b8c90") if hero else Color("526176")
		var hp_col := Color("e96159") if hero else Color("b5a5fe")
		var atb_bg := Color("c1c4b9") if hero else Color("344359")
		var atb_fill := Color("167e9e") if hero else Color("c7adfc")
		var now := Time.get_ticks_msec()

		# Title row.
		# Card body.
		var body := Rect2(0, 18, size.x, 82)
		BattleHud.slant(self, Rect2(body.position + Vector2(6, 6), body.size), 8.0, Color(0, 0, 0, 0.5))
		BattleHud.draw_card_bg(self, body, 8.0, bg, bk, 10.0, now)
		draw_rect(Rect2(0, 18, 7, 82), accent)
		# Portrait.
		var pr := Rect2(16, 26, 56, 62)
		BattleHud.slant(self, pr, 6.0, (Color("263d57") if hero else Color("54456c")).lerp(Color("4a1a06"), bk))
		if _portrait != null:
			if _portrait.get_width() > 64:
				# High-res portraits (DQT art) fill the whole slanted frame, clipped to its shape.
				BattleHud.slant_texture(self, pr.grow(-2.0), 5.0, _portrait)
			else:
				draw_texture_rect(_portrait, Rect2(pr.position + Vector2(8, 6), Vector2(44, 44)), false)
		# Name.
		draw_string(font, Vector2(84, 44), c.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 150, 18, fg)
		BattleHud.text_right(self, font, size.x - 48, 40, "JOGADOR" if hero else "ALIADO · IA", 8, Color(fg, 0.6))
		# HP.
		var bar_x := 84.0
		var bar_w := 120.0
		draw_rect(Rect2(bar_x, 52, bar_w, 7), track)
		var shown := hud.shown_hp(c)
		draw_rect(Rect2(bar_x, 52, bar_w * clampf(shown / c.max_hp, 0.0, 1.0), 7), hp_col.lerp(Color.WHITE, hud.burn_flash(c) * 0.5))
		BattleHud.draw_burn_pending(self, Rect2(bar_x, 52, bar_w, 7), c, shown / c.max_hp)  # D-239
		var hp_txt := "HP %d/%d" % [ceili(shown), c.max_hp]
		draw_string(font, Vector2(bar_x + bar_w + 8, 59), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)

		# Status and Buff badges (D-032)
		var badges: Array[Dictionary] = []
		if c.is_stunned():
			badges.append({"text": "⚡ STUN %.1fs" % c.stun_timer, "bg": Color("d32f2f"), "fg": Color.WHITE})
		if c.is_burning():  # D-239
			badges.append({"text": "🔥 BURN %.1fs" % BattleHud.burn_left(c), "bg": Color("b5470b"), "fg": Color("fff3d6")})
		if c.is_blind():
			badges.append({"text": "👁 CEGO %.1fs" % c.blind_timer, "bg": Color("c29b38"), "fg": Color.WHITE})
		if c.taunted_by != null:
			badges.append({"text": "💢 TAUNT", "bg": Color("c2185b"), "fg": Color.WHITE})
		if c.is_guarding():
			badges.append({"text": "🛡 GUARD", "bg": Color("1f6fd6"), "fg": Color.WHITE})  # D-272
		if c.is_invulnerable:
			badges.append({"text": "🛡 INVULN", "bg": Color("00838f"), "fg": Color.WHITE})
		if c.atk_buff != 0:
			badges.append({"text": "ATK %+d" % c.atk_buff, "bg": Color("3d6600") if c.atk_buff > 0 else Color("c93022"), "fg": Color("#d7fd6a") if c.atk_buff > 0 else Color("#ffb4ab")})
		if c.def_buff != 0:
			badges.append({"text": "DEF %+d" % c.def_buff, "bg": Color("3d6600") if c.def_buff > 0 else Color("c93022"), "fg": Color("#d7fd6a") if c.def_buff > 0 else Color("#ffb4ab")})
		if c.speed_buff != 0:
			badges.append({"text": "VEL %+d" % c.speed_buff, "bg": Color("3d6600") if c.speed_buff > 0 else Color("8a6300"), "fg": Color("#d7fd6a") if c.speed_buff > 0 else Color("#f7cb78")})

		var bx := 8.0
		var by := 5.0  # D-239/D-240: the status badges sit above the card body (the row where the title was), outside the HUD body
		for b in badges:
			var txt: String = b["text"]
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 8.0
			if bx + tw > size.x - 10:
				break
			var br := Rect2(bx, by, tw, 11)
			BattleHud.slant(self, br, 2.0, b["bg"])
			draw_string(font, Vector2(bx + 4.0, by + 9.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, b["fg"])
			bx += tw + 4.0

		# ATB blocks + burst slot.
		draw_string(font, Vector2(bar_x, 91), "ATB", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)
		for i in int(Combatant.BLOCKS):
			var r := Rect2(bar_x + 30 + i * 29, 80, 26, 13)
			# Background slot
			BattleHud.slant(self, r, 3.0, atb_bg)
			BattleHud.slant(self, Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), 2.8, atb_bg.darkened(0.2))

			var fill := clampf(c.shown_atb() - i, 0.0, 1.0)
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

			# Reserved: credited to the logic, but its token is still on the way.
			if clampf(c.atb - i, 0.0, 1.0) > fill + 0.001:
				var rsv := 0.5 + 0.5 * sin(now * 0.012 + i)
				var outline := PackedVector2Array([
					Vector2(r.position.x + 3.0, r.position.y), Vector2(r.end.x, r.position.y),
					Vector2(r.end.x - 3.0, r.end.y), Vector2(r.position.x, r.end.y), Vector2(r.position.x + 3.0, r.position.y)])
				draw_polyline(outline, Color(0.45, 0.92, 1.0, 0.35 + 0.4 * rsv), 1.5)

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
		var sb := c.shown_burst()
		if sb > 0:
			var b_pulse := 0.5 + 0.5 * sin(now * 0.01)
			BattleHud.draw_flames(self, slot, now, 1.0)  # The slot burns while a Burst is ready.
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
			var b_txt := "B" if sb < 2 else "B%d" % sb
			for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				draw_string(font, slot.position + Vector2(0, 14) + d, b_txt, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 13, Color(1.0, 0.45, 0.05, 0.9))
			draw_string(font, slot.position + Vector2(0, 14), b_txt, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 13, Color(1.0, 1.0, 0.9))
			# Sudden burst gain flash
			if _burst_gain_flash > 0.0:
				var g_col := Color(1, 1, 1, _burst_gain_flash * 0.85)
				draw_rect(Rect2(slot.position - Vector2(3, 3), slot.size + Vector2(6, 6)), g_col)
		else:
			# Empty burst slot
			draw_rect(slot, Color("151a24"))
			draw_rect(slot, Color("344254"), false, 1.0)
			draw_string(font, slot.position + Vector2(0, 13), "B", HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 11, Color("4a576b"))
			if c.burst > 0:  # Credited, token still flying: the slot is reserved.
				draw_rect(slot, Color(1.0, 0.6, 0.15, 0.4 + 0.4 * (0.5 + 0.5 * sin(now * 0.012))), false, 1.5)

		# Extra ATB blocks (beyond the five): small squares in a row under the bar.
		var ex_shown := int(c.shown_extra())
		for k in int(c.extra + 0.001):
			var er := Rect2(bar_x + 30 + k * 11, 96, 9, 6)
			if k < ex_shown:
				draw_rect(er, Color(0.55, 0.95, 1.0))
				draw_rect(er, Color.WHITE, false, 1.0)
			else:
				draw_rect(er, Color(0.45, 0.92, 1.0, 0.45), false, 1.0)

		BattleHud.draw_pos_marks(self, Vector2(size.x * 0.5, 108.0), c.pos_step)
		# Order numeral.
		draw_rect(Rect2(size.x - 40, 18, 30, 82), (Color("d6d6c9") if hero else Color("33455b")).lerp(Color("5a2106"), bk))
		draw_string(FanMenu.title_font(), Vector2(size.x - 40, 70), ROMAN[mini(order, 3)], HORIZONTAL_ALIGNMENT_CENTER, 30, 22, (Color("203448") if hero else Color("e3dcfb")).lerp(BattleHud.BURN_TEXT, bk))
		BattleHud.draw_burn_embers(self, body, bk, now)
		hud.draw_burn_tick_jump(self, font, Rect2(bar_x, 52, bar_w, 7), shown / c.max_hp, c, 11)  # D-239


# --- Enemy tag -------------------------------------------------------------------

class EnemyTag extends Control:
	var combatant: Combatant
	var hud: BattleHud
	var active := false
	var pulse := 0.0  ## Set when a reward lands: a small nudge of the tag.

	func _init() -> void:
		size = Vector2(132, 84)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func atb_slot_global(i: int) -> Vector2:
		return position + Vector2(8.0 + i * 18.0 + 8.0, 48.0)

	func extra_slot_global(k: int) -> Vector2:
		return position + Vector2(8.0 + k * 9.0 + 3.5, 61.0)

	func burst_slot_global() -> Vector2:
		return position + Vector2(112.5, 48.0)

	func _draw() -> void:
		var c := combatant
		var font := FanMenu.body_font()
		var now := Time.get_ticks_msec()
		var box := Rect2(0, 0, size.x, 56)
		BattleHud.slant(self, Rect2(box.position + Vector2(3, 4), box.size), 7.0, Color(0, 0, 0, 0.45))
		var bk := hud.burn_k(c)  # D-239
		BattleHud.draw_card_bg(self, box, 7.0, Color("eae9d9") if active else Color(INK, 0.9), bk, 6.0, now)

		# Status and Buff badges floating above enemy tag (D-032)
		var e_badges: Array[Dictionary] = []
		if c.is_stunned():
			e_badges.append({"text": "⚡ STUN %.1fs" % c.stun_timer, "bg": Color("d32f2f"), "fg": Color.WHITE})
		if c.is_burning():  # D-239
			e_badges.append({"text": "🔥 BURN %.1fs" % BattleHud.burn_left(c), "bg": Color("b5470b"), "fg": Color("fff3d6")})
		if c.is_blind():
			e_badges.append({"text": "👁 CEGO %.1fs" % c.blind_timer, "bg": Color("c29b38"), "fg": Color.WHITE})
		if c.taunted_by != null:
			e_badges.append({"text": "💢 TAUNT", "bg": Color("c2185b"), "fg": Color.WHITE})
		if c.is_guarding():
			e_badges.append({"text": "🛡 GUARD", "bg": Color("1f6fd6"), "fg": Color.WHITE})  # D-272
		if c.is_invulnerable:
			e_badges.append({"text": "🛡 INVULN", "bg": Color("00838f"), "fg": Color.WHITE})
		if c.atk_buff != 0:
			e_badges.append({"text": "ATK %+d" % c.atk_buff, "bg": Color("3d6600") if c.atk_buff > 0 else Color("c93022"), "fg": Color("#d7fd6a") if c.atk_buff > 0 else Color("#ffb4ab")})
		if c.def_buff != 0:
			e_badges.append({"text": "DEF %+d" % c.def_buff, "bg": Color("3d6600") if c.def_buff > 0 else Color("c93022"), "fg": Color("#d7fd6a") if c.def_buff > 0 else Color("#ffb4ab")})
		if c.speed_buff != 0:
			e_badges.append({"text": "VEL %+d" % c.speed_buff, "bg": Color("3d6600") if c.speed_buff > 0 else Color("8a6300"), "fg": Color("#d7fd6a") if c.speed_buff > 0 else Color("#f7cb78")})

		var total_w := 0.0
		for b in e_badges:
			total_w += font.get_string_size(b["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 8.0
		var e_bx := maxf((size.x - total_w) * 0.5, 0.0)
		for b in e_badges:
			var txt: String = b["text"]
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 7.0
			var br := Rect2(e_bx, -14, tw, 11)
			BattleHud.slant(self, br, 2.0, b["bg"])
			draw_string(font, Vector2(e_bx + 3.0, -5.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, b["fg"])
			e_bx += tw + 3.0

		var name_col := Color("b74134") if active else CORAL
		draw_string(font, Vector2(0, 15), c.name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, name_col.lerp(BattleHud.BURN_TEXT, bk))
		draw_rect(Rect2(14, 20, size.x - 28, 5), Color("7b8c90") if active else Color("3a4756"))
		var shown := hud.shown_hp(c)
		draw_rect(Rect2(14, 20, (size.x - 28) * clampf(shown / c.max_hp, 0.0, 1.0), 5), CORAL.lerp(Color.WHITE, hud.burn_flash(c) * 0.5))
		BattleHud.draw_burn_pending(self, Rect2(14, 20, size.x - 28, 5), c, shown / c.max_hp)  # D-239
		var hp_txt := "HP %d / %d" % [ceili(shown), c.max_hp]
		draw_string(font, Vector2(0, 37), hp_txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, (Color("111d2a") if active else CREAM).lerp(BattleHud.BURN_TEXT, bk))
		# ATB: five small blocks, reserved outlines for blocks still flying in.
		for i in 5:
			var r := Rect2(8 + i * 18, 44, 16, 8)
			BattleHud.slant(self, r, 2.0, Color("9aa7b0") if active else Color("2a3442"))
			var fill := clampf(c.shown_atb() - i, 0.0, 1.0)
			if fill > 0.0:
				BattleHud.slant(self, Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), 2.0 * fill, Color(0.4, 0.88, 1.0) if fill >= 1.0 else Color(0.2, 0.55, 0.75))
			if clampf(c.atb - i, 0.0, 1.0) > fill + 0.001:
				var rsv := 0.5 + 0.5 * sin(now * 0.012 + i)
				var o := PackedVector2Array([Vector2(r.position.x + 2.0, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - 2.0, r.end.y), Vector2(r.position.x, r.end.y), Vector2(r.position.x + 2.0, r.position.y)])
				draw_polyline(o, Color(0.45, 0.92, 1.0, 0.35 + 0.4 * rsv), 1.5)
		# Burst slot: on fire while a Burst is available.
		var slot := Rect2(101, 43, 23, 10)
		var sb := c.shown_burst()
		if sb > 0:
			BattleHud.draw_flames(self, slot, now, 0.8)
			draw_rect(slot, GOLD.lerp(Color.WHITE, 0.15 + 0.15 * sin(now * 0.01)))
			draw_rect(slot, Color.WHITE.lerp(GOLD, 0.4), false, 1.2)
			var txt := "B" if sb < 2 else "B%d" % sb
			draw_string(font, slot.position + Vector2(0, 9), txt, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 10, Color(0.2, 0.1, 0.0))
		else:
			draw_rect(slot, Color("151a24"))
			draw_rect(slot, Color("344254"), false, 1.0)
			draw_string(font, slot.position + Vector2(0, 9), "B", HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 9, Color("4a576b"))
			if c.burst > 0:
				draw_rect(slot, Color(1.0, 0.6, 0.15, 0.4 + 0.4 * (0.5 + 0.5 * sin(now * 0.012))), false, 1.5)
		# Extra ATB blocks.
		var ex_shown := int(c.shown_extra())
		for k in int(c.extra + 0.001):
			var er := Rect2(8 + k * 9, 58, 7, 5)
			if k < ex_shown:
				draw_rect(er, Color(0.55, 0.95, 1.0))
			else:
				draw_rect(er, Color(0.45, 0.92, 1.0, 0.45), false, 1.0)
		BattleHud.draw_pos_marks(self, Vector2(size.x * 0.5, 82.0), c.pos_step)
		BattleHud.draw_burn_embers(self, box, bk, now)
		hud.draw_burn_tick_jump(self, font, Rect2(14, 20, size.x - 28, 5), shown / c.max_hp, c, 9)  # D-239
		var cx := size.x * 0.5
		var cy := 72.0
		var diamond := PackedVector2Array([Vector2(cx, cy - 7), Vector2(cx + 7, cy), Vector2(cx, cy + 7), Vector2(cx - 7, cy)])
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
		size = Vector2(150, 42)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if inc == null:
			return
		var font := FanMenu.body_font()
		var col: Color = BattleFx.COLORS[inc.element]
		var enemy: bool = not inc.attacker.is_player
		var w_total: float = inc.total_windup if inc.get("total_windup") != null and inc.total_windup > 0.05 else Battle.WINDUP
		var in_perfect: bool = enemy and inc.can_evade_now()  # Gold while the Evade works
		BattleHud.slant(self, Rect2(Vector2(3, 4), size - Vector2(3, 4)), 6.0, Color(0, 0, 0, 0.5))
		BattleHud.slant(self, Rect2(Vector2.ZERO, size - Vector2(3, 4)), 6.0, Color(0.04, 0.08, 0.14, 0.94))
		draw_rect(Rect2(0, 0, 5, size.y - 4), GOLD if in_perfect else col)
		draw_string(font, Vector2(12, 16), String(inc.label).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 12, GOLD if in_perfect else Color.WHITE)
		draw_string(font, Vector2(12, 28), "%s > %s" % [inc.attacker.name, inc.target.name], HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 9, CORAL if enemy else AQUA)
		var k := 1.0 if inc.resolved else clampf(1.0 - inc.time_left / w_total, 0.0, 1.0)
		var bar_w := size.x - 26.0
		draw_rect(Rect2(12, 32, bar_w, 4), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(12, 32, bar_w * k, 4), GOLD if in_perfect else col)


## Dynamic reaction prompt over the player's character: shows early (wait) vs normal vs PERFECT window.
class EvadeHint extends Control:
	var time_left := 0.0
	var can_now := false  ## The attack is on its way: Evade works now.

	func _init() -> void:
		size = Vector2(204, 52)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

	func _draw() -> void:
		var font := FanMenu.body_font()
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.016)
		var is_perfect := false
		var is_early := not can_now
		var bg_col := GOLD.lerp(Color.WHITE, pulse * 0.6) if is_perfect else (Color("2b394a") if is_early else LIME.lerp(Color.WHITE, pulse * 0.45))
		var fg_col := INK if not is_early else CREAM
		BattleHud.slant(self, Rect2(Vector2(4, 5), size - Vector2(4, 5)), 8.0, Color(0, 0, 0, 0.55))
		BattleHud.slant(self, Rect2(Vector2.ZERO, size - Vector2(4, 5)), 8.0, bg_col)
		draw_string(FanMenu.title_font(), Vector2(14, 31), "ESPAÇO", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, fg_col)
		var status_txt := "PERFECT!" if is_perfect else ("AGUARDE..." if is_early else "DESVIAR!")
		draw_string(font, Vector2(102, 21), status_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CORAL if is_early else fg_col)
		draw_string(font, Vector2(102, 36), ("%.2fs" % time_left) if can_now else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(fg_col, 0.8))
