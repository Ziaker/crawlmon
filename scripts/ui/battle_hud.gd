class_name BattleHud
extends BattleHudDraw
## Battle HUD in the approved V9 layout, drawn natively: hero card above the
## command stack (left column), ally card anchored next to its model (lower
## right), name/HP tags floating over each enemy, camera indicator, alerts,
## log and a footer with the real key bindings. Everything reads live data
## from Battle / Combatant. MP does not exist in the runtime yet, so cards show
## "MP N/D" instead of an invented value.

const SkillInfoPanelScript = preload("res://scripts/ui/skill_info_panel.gd")
const AttackTagShatterScript = preload("res://scripts/ui/attack_tag_shatter.gd")
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
var _regen: Control  ## D-982
var _tags: Dictionary = {}  ## enemy Combatant -> EnemyTag
var _alert: Label
var _log: Label
var _log_lines: Array[String] = []
var _skill_info
var _tabs: CameraTabs
var _target: Combatant
## Prototype hook: the portrait shield arc replaces the small shield badges.
## Default false; only the shield-HUD lab turns it on.
var hide_shield_badges := false
var _status: StatusPanel
var _status_open := false
var _reward_layer: RewardLayer
var _heal_layer: Control  ## D-347: the option 2 numbers above the HP cards/tags
var _inc_tags: Dictionary = {}  ## Battle.Incoming -> AttackTag
var _hint: EvadeHint
var _burn_k: Dictionary = {}  ## D-239: Combatant -> 0..1, how much its card is burning (eases in and out)
var _stun_k: Dictionary = {}  ## D-980: Combatant -> 0..1, how dizzy its card is (eases in and out)
var _blind_k: Dictionary = {}  ## D-1121: Combatant -> 0..1, how blurry its portrait is (eases in and out)
var _blind_snap: Dictionary = {}  ## D-1121: Combatant -> 0..1, focus-snap flash after BLIND ends
var _blind_prev: Dictionary = {}  ## D-1121: previous blind_k, to detect the end
var _card_ghosts: Dictionary = {}  ## D-1134: Combatant -> Array[UnitCard] (two translucent copies)
var _menu_ghosts: Array[FanMenu] = []  ## D-1134: two translucent copies of the leader's action menu
var _burn_ticks: Dictionary = {}  ## D-239: Combatant -> {t0 (msec), dmg} of its last Burn tick


## The clock every HUD animation reads. In play it is the real clock. When the game is recorded with `--fixed-fps N`, each frame takes
## far longer than 1/N s to render, so the real clock would run the HUD animations many times faster than the battle in the video: there
## it is the number of frames drawn divided by N, the same time the battle itself runs on.
## Draws `tex` inside the same parallelogram as slant(): the texture covers the
## frame's bounding box (centre crop, aspect kept) and is clipped to the slant.
## D-1070: the "ATB is full, the MP is recovering 1.75x faster" marker: two chevrons "^" stacked tight, over the MP block. They pulse
## upward one after the other. `top_center` is the middle of the block's top edge.
## A shear that leans text by the same angle as slant(r, skew): top edge right, bottom edge left, pivoting on the middle of `r`.
## D-1062: the MP charge block drawn as WATER filling a tank shaped like a PARALLELOGRAM (the same slant() shape as the card, at
## `skew` px over its height: 9 degrees was asked). A deep-blue body, a lighter back wave and a front wave that slide sideways on the
## surface, a thin foam line on the crest, and bubbles that rise through the water. `charge` runs 0..1 over the 8 s pulse (1 when
## the MP is full). Everything is clipped to the slanted shape: its left edge at height y is x0 + skew * (1 - k), the right edge
## x1 - skew * k, with k = (y - top) / height.
## The outline of the same parallelogram slant() fills (the Burst slot uses it like the ATB blocks).
## D-1026: an animated CHROME border around a card / tag shaped like slant(): bands of bright reflection slide along the perimeter
## over a steel base, like light running over polished metal. Drawn for every unit that has the ARMOR badge, whatever its side.
## Colour of a battle-log line: the eye finds interrupts, shields and heals fast.
## One compact line with every active status and its real timer.
func setup(battle: Battle, party: Array[Combatant], enemies: Array[Combatant], camera: Camera3D, models: Dictionary, director: BattleCamera) -> void:
	_battle = battle
	battle.hit_resolved.connect(_on_hit_pop)
	battle.healed.connect(heal_gain)  # D-347: number above the owner's HP card/tag
	battle.burn_ticked.connect(func(t: Combatant, d: int) -> void: _burn_ticks[t] = {"t0": BattleHud.clock_ms(), "dmg": d})  # D-239
	battle.status_pause_started.connect(func(inc) -> void:
		_banner = {"skill": String(inc.label), "who": inc.attacker.name, "t0": BattleHud.clock_ms(), "out": -1})
	battle.status_pause_ended.connect(func(_inc) -> void:
		if not _banner.is_empty():
			_banner["out"] = BattleHud.clock_ms())
	battle.engage_ended.connect(func(actor: Combatant, _o, _g, _s) -> void: _back_until[actor] = BattleHud.clock_ms() + 800)
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
		# D-1134: two translucent copies of the whole card for the BLIND ghost.
		var ghosts: Array[UnitCard] = []
		for g in 2:
			var ghost := UnitCard.new()
			ghost.combatant = party[i]
			ghost.hud = self
			ghost.hero = card.hero
			ghost.order = i
			ghost.is_ghost = true
			ghost.z_index = 1
			ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ghost.visible = false
			add_child(ghost)
			ghost.process_mode = Node.PROCESS_MODE_DISABLED
			ghosts.append(ghost)
		_card_ghosts[party[i]] = ghosts
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
	# D-1134: two translucent copies of the whole action menu for the BLIND ghost.
	for g in 2:
		var menu_ghost := FanMenu.new()
		menu_ghost.z_index = 1
		menu_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_ghost.visible = false
		add_child(menu_ghost)
		menu_ghost.process_mode = Node.PROCESS_MODE_DISABLED
		_menu_ghosts.append(menu_ghost)
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
	_regen = RegenPanel.new()  # D-982: MP regen of the allies, next to CAMERA DIRECTION
	_regen.hud = self
	add_child(_regen)
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
	# D-959: the battle history panel was removed (it blocked the view; a new one will replace it). Move sheet below.
	_skill_info = SkillInfoPanelScript.new()
	_skill_info.hud = self
	add_child(_skill_info)


## The move sheet shown beside the Fight list (hidden by every other screen).
func show_skill_info(skill: Skill, target: Combatant) -> void:
	if _skill_info == null or skill == null:
		return
	_skill_info.show_skill(skill, _battle.party[0] if _battle != null and not _battle.party.is_empty() else null, target, _battle)
	_skill_info.visible = true


func hide_skill_info() -> void:
	if _skill_info != null:
		_skill_info.visible = false


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
	if _skill_info != null and on:
		_skill_info.visible = false
	_tabs.visible = not on
	for card in _cards:
		card.visible = not on
	for e in _tags:
		(_tags[e] as Control).visible = false


## Debug/test tool: after party[0] changes, rebind every card to the same party
## index (hero card = new leader) without touching the combatants or their state.
func debug_rebind_party(party: Array[Combatant]) -> void:
	if party.size() != _cards.size():
		return
	var old: Array[Dictionary] = []
	for i in _cards.size():
		old.append({
			"combatant": _cards[i].combatant,
			"ghosts": _card_ghosts.get(_cards[i].combatant, []),
		})
	_card_ghosts.clear()
	for i in _cards.size():
		var c := party[i]
		var card := _cards[i]
		card.combatant = c
		card.hero = i == 0
		card.order = i
		card.queue_redraw()
		var ghosts: Array = old[i].get("ghosts", [])
		for ghost in ghosts:
			ghost.combatant = c
			ghost.hero = i == 0
			ghost.order = i
			ghost.queue_redraw()
		_card_ghosts[c] = ghosts
	_layout_cards()


func set_target(c: Combatant) -> void:
	_target = c


func set_menu_style(style: FanMenu.Style, header: String) -> void:
	menu.style = style
	menu.header = header
	menu.position = Vector2(MARGIN, 424) if style == FanMenu.Style.DRAWER else Vector2(MARGIN, 436)
	menu.queue_redraw()


func _on_log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 14:
		_log_lines.pop_front()


func _process(_delta: float) -> void:
	if _battle == null:
		return
	var lines := PackedStringArray()
	for inc in _battle.active_attacks():
		if not inc.dodged:
			lines.append("! %s  >  %s   %.1fs" % [inc.attacker.name, inc.target.name, inc.eta()])
	_alert.text = ""  # The floating attack tags replace this text.
	_track_burn(_delta)
	_follow_leader(_delta)
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
	_sync_blind_ghosts()
	_sync_blind_menu()
	queue_redraw()


## D-1134: the whole card (background, name, bars, ATB and portrait) gets two
## translucent copies when its owner is BLIND. Both orbit clockwise in opposite
## phases. The real card keeps the sharp text, the crisp badge and the blurred
## portrait; the ghosts are only the double image.
func _sync_blind_ghosts() -> void:
	var now := BattleHud.clock_ms()
	for card in _cards:
		var k := blind_k(card.combatant)
		var show := k > 0.01 and card.visible
		var ghosts: Array = _card_ghosts.get(card.combatant, [])
		for gi in ghosts.size():
			var ghost: UnitCard = ghosts[gi]
			ghost.visible = show
			if not show:
				continue
			# Screen Y points down: increasing angle goes right -> down -> left -> up (clockwise).
			var angle := float(now) * 0.0015 + float(gi) * PI
			var radius := 8.0 + 1.0 * sin(float(now) * 0.0011 + float(gi) * 1.7)
			var off := Vector2(cos(angle), sin(angle)) * radius
			ghost.position = card.position + off
			ghost.rotation = card.rotation
			ghost.pivot_offset = card.pivot_offset
			ghost.scale = card.scale
			ghost.size = card.size
			ghost.modulate = Color(1, 1, 1, 0.20 * k)
			ghost.queue_redraw()


## D-1134: the action menu is the leader's; while the leader is BLIND, two
## translucent copies of the whole FanMenu orbit clockwise around it.
func _sync_blind_menu() -> void:
	if _menu_ghosts.is_empty() or menu == null or _battle == null:
		return
	var now := BattleHud.clock_ms()
	var k := blind_k(_battle.party[0])
	var show := menu.visible and k > 0.01
	for gi in _menu_ghosts.size():
		var mg := _menu_ghosts[gi]
		mg.visible = show
		if not show:
			continue
		mg.style = menu.style
		mg.header = menu.header
		mg.note = menu.note
		mg.index = menu.index
		mg._texts = menu._texts.duplicate()
		mg._details = menu._details.duplicate()
		mg._enabled = menu._enabled.duplicate()
		mg._accents = menu._accents.duplicate()
		mg._hilite = menu._hilite.duplicate()
		mg._shield = menu._shield.duplicate()
		mg._skills = menu._skills.duplicate()
		mg.custom_minimum_size = menu.custom_minimum_size
		mg.size = menu.size
		var angle := float(now) * 0.0013 + float(gi) * PI
		var radius := 6.0 + 0.8 * sin(float(now) * 0.0011 + float(gi) * 1.7)
		mg.position = menu.position + Vector2(cos(angle), sin(angle)) * radius
		mg.modulate = Color(1, 1, 1, 0.18 * k)
		mg.queue_redraw()


## Damage numbers pop the instant a hit lands (hit_resolved is emitted at the impact).
func _on_hit_pop(_attacker: Combatant, target: Combatant, _element: Element.Type, info: Dictionary) -> void:
	if info.get("evaded", false) or info.get("status", false):
		return
	# D-1113: the bubble absorbed everything; the Move's impact still plays, but
	# there is no damage number (especially not a misleading "0").
	if int(info.get("dmg", 0)) <= 0 and int(info.get("shield_absorbed", 0)) > 0:
		return
	_pops.append({"c": target, "value": int(info["dmg"]), "crit": bool(info["crit"]), "weak": bool(info["weak"]),
		"magic": bool(info.get("magic", false)),
		"t0": BattleHud.clock_ms(), "dx": float((_pops.size() % 3) - 1) * 84.0 + randf_range(-14.0, 14.0)})


## The status move's name strip: slides in from the left, holds while the engine is
## paused, slides out when it runs again.
func _draw_banner() -> void:
	if _banner.is_empty():
		return
	var now := BattleHud.clock_ms()
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
	draw_string(font, Vector2(x + 26, y + 22), "%s USES" % String(_banner["who"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(CREAM, 0.85))
	draw_string(title, Vector2(x + 26, y + 58), String(_banner["skill"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w - 40, 38, LIME)


func _draw_pops() -> void:
	var now := BattleHud.clock_ms()
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
		var magic: bool = p.get("magic", false)
		var size := 84 if crit else 62
		var fill := Color("62d8e7") if magic else (Color("ffd84a") if crit else (Color("ff9a3a") if weak else Color("f6f3e6")))
		var text := str(p["value"])
		var origin: Vector2 = (at as Vector2) + Vector2(float(p["dx"]) + jitter, -4.0 - rise)
		draw_set_transform(origin, -0.12, Vector2(sc, sc))
		var half := Vector2(-200.0, 0.0)
		draw_string(title, half + Vector2(5, 6), text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, Color(CORAL.r, CORAL.g, CORAL.b, alpha))
		draw_string_outline(title, half, text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, 14, Color(0.04, 0.07, 0.12, alpha))
		draw_string(title, half, text, HORIZONTAL_ALIGNMENT_CENTER, 400.0, size, Color(fill, alpha))
		if magic:
			draw_string(title, half + Vector2(0, -size * 0.75), "MAGIC", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 20, Color(0.38, 0.85, 0.91, alpha))
		elif crit:
			draw_string(title, half + Vector2(0, -size * 0.75), "CRITICAL!", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 22, Color(1.0, 0.95, 0.6, alpha))
		elif weak:
			draw_string(title, half + Vector2(0, -size * 0.75), "WEAK!", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 20, Color(1.0, 0.8, 0.5, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_pops = keep


## Above an engaged character: how long it stays next to its opponent (the slow-motion),
## then a short "RETURNING" while it leaps back home.
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
		elif BattleHud.clock_ms() < _back_until.get(c, 0):
			_engage_marks.append({"p": p, "k": 0.0, "back": true})


func _screen_pos(c: Combatant, height: float) -> Variant:
	var model: Node3D = _models.get(c)
	if model == null:
		return null
	var world := model.global_position + Vector3(0, height, 0)
	if _camera.is_position_behind(world):
		return null
	return _camera.unproject_position(world)


## D-1160: only a real interruption (hit before the impact, War Cry/status cancel,
## clash) destroys the card. A dodged or auto-dodged action is a miss (D-104/D-106),
## and a hit during the return is not an interruption of the action; both leave normally.
static func shows_interruption_feedback(inc) -> bool:
	return inc != null and bool(inc.interruption_feedback)


func _sync_incoming() -> void:
	var live := {}
	if not _status_open:
		for inc in _battle.active_attacks():
			var tag: AttackTag = _inc_tags.get(inc)
			# D-1104 as corrected by D-1160: only a real interruption breaks the card.
			if shows_interruption_feedback(inc):
				if tag != null:
					if tag.visible:
						tag.shatter()
					else:
						tag.queue_free()
					_inc_tags.erase(inc)
				continue
			live[inc] = true
			if tag == null:
				tag = AttackTag.new()
				tag.inc = inc
				tag.hud = self
				add_child(tag)
				_inc_tags[inc] = tag
			var p: Variant = _screen_pos(inc.attacker, _head_of(inc.attacker) + (0.4 if not inc.attacker.is_player else 0.2))
			tag.visible = p != null
			if p != null and not tag.leaving:
				# D-985: an enemy's wind-up tag sits above its tag AND its badge row (66 px tag + lift + 14 px badges + gap).
				var lift := (66.0 + TAG_LIFT + 14.0 + 8.0) if not inc.attacker.is_player else 10.0
				tag.position = (p as Vector2) - Vector2(tag.size.x * 0.5, tag.size.y + lift)
			tag.queue_redraw()
	for inc in _inc_tags.keys():
		if not live.has(inc):
			var tag: AttackTag = _inc_tags[inc]
			# D-1104 as corrected by D-1160: only a real interruption breaks the card
			# (War Cry and a hit erase it from the active list already interrupted).
			if shows_interruption_feedback(inc):
				if tag.visible:
					tag.shatter()
				else:
					tag.queue_free()
			else:
				tag.leave()  # D-985: leaves upward, then frees itself
			_inc_tags.erase(inc)
	# Evade prompt on the player's character.
	var leader: Combatant = _battle.party[0]
	var evadable = _battle.find_evadable(leader) if not _status_open else null
	_hint.visible = false  # D-1006: the "SPACE / DODGE!" prompt was removed
	evadable = null
	if evadable != null:
		var hp: Variant = _screen_pos(leader, _head_of(leader) + 0.3)
		_hint.visible = hp != null
		if hp != null:
			_hint.position = (hp as Vector2) - Vector2(_hint.size.x * 0.5, _hint.size.y + 14.0)
		_hint.time_left = minf(evadable.travel_left(), 9.99)
		_hint.can_now = evadable.can_evade_now()
		_hint.queue_redraw()


## D-1011 (revised): the hero card and the command menu stay fixed at the left margin. When any
## living character's body is behind the menu it fades to 55% opacity (only the menu, not the card).
const LEAD_GAP := 14.0
const LEAD_CARD_W := 330.0
const MENU_FADE_ALPHA := 0.55
var _lead_x := MARGIN


func _follow_leader(delta: float) -> void:
	if _status_open or _battle == null or _camera == null or menu == null:
		return
	var msize := menu.size if menu.size.x > 1.0 else Vector2(FanMenu.DRAWER_W, 250.0)
	var block := Rect2(menu.position, msize)
	var covered := false
	for list in [_battle.party, _battle.enemies]:
		for c in list:
			var model: Node3D = _models.get(c)
			if model == null or not c.is_alive():
				continue
			var h := _head_of(c)
			var r := maxf(0.45 * h, 0.5)
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for p in [Vector3(-r, 0, 0), Vector3(r, 0, 0), Vector3(0, h, 0), Vector3(-r, h * 0.6, 0), Vector3(r, h * 0.6, 0)]:
				var w: Vector3 = model.global_position + p
				if _camera.is_position_behind(w):
					continue
				var sp := _camera.unproject_position(w)
				lo = Vector2(minf(lo.x, sp.x), minf(lo.y, sp.y))
				hi = Vector2(maxf(hi.x, sp.x), maxf(hi.y, sp.y))
			if lo.x <= hi.x and block.intersects(Rect2(lo, hi - lo)):
				covered = true
	var real_dt := delta / maxf(Engine.time_scale, 0.05)
	var want := MENU_FADE_ALPHA if covered else 1.0
	menu.modulate.a = lerpf(menu.modulate.a, want, 1.0 - exp(-12.0 * real_dt))


## D-1010: the part of the 1280x720 screen the HUD leaves free: right of the hero card and
## the menu, left of the ally cards, under the camera/regen panels, above the footer.
func free_rect() -> Rect2:
	var left := MARGIN + LEAD_CARD_W + 10.0  # D-1011: the hero card follows the leader; the leader never goes left of it
	var right := 1280.0 - MARGIN
	for card in _cards:
		if not card.hero:
			right = minf(right, card.position.x - 10.0)
	var top := 0.0
	if _tabs != null:
		top = maxf(top, _tabs.position.y + _tabs.size.y + 8.0)
	var bottom := 720.0 - FOOTER_H - 8.0
	return Rect2(left, top, maxf(right - left, 0.0), maxf(bottom - top, 0.0))


## D-1010: the footprint of an enemy tag above its head point, in px: (left, right, up, down).
func _layout_cards() -> void:
	if _status_open:
		return
	for card in _cards:
		if card.hero:
			card.position = Vector2(_lead_x, 318)
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
## D-239: Burn on the HUD. The background of the card turns scorched dark orange (the HP bar keeps its colours).

func _track_burn(delta: float) -> void:
	if _battle == null:
		return
	for c in _battle.party + _battle.enemies:
		var goal := 1.0 if (c.is_burning() and c.is_alive()) else 0.0
		_burn_k[c] = move_toward(float(_burn_k.get(c, 0.0)), goal, delta * 2.8)
		_stun_k[c] = move_toward(float(_stun_k.get(c, 0.0)), 1.0 if (c.is_stunned() and c.is_alive()) else 0.0, delta * 4.0)  # D-980
		var prev_blind := float(_blind_prev.get(c, 0.0))
		var cur_blind := move_toward(float(_blind_k.get(c, 0.0)), 1.0 if (c.is_blind() and c.is_alive()) else 0.0, delta * 4.0)  # D-1121
		if prev_blind > 0.98 and cur_blind < prev_blind:
			_blind_snap[c] = 1.0  # D-1121: BLIND ended -> focus snaps back
		_blind_prev[c] = cur_blind
		_blind_k[c] = cur_blind
		_blind_snap[c] = maxf(0.0, float(_blind_snap.get(c, 0.0)) - delta * 4.0)


const STUN_SWAY_HZ := 0.3  ## D-982: slower again (D-981: 0.5, before: 0.9)


## D-980/D-981: dizzy portrait overlay (spiral eyes by the frame's proportions, stars circling over it).
func stun_k(c: Combatant) -> float:
	return float(_stun_k.get(c, 0.0))


## D-1121: how much the “Olhar turvo” (blurred, double-vision portrait) is showing.
func blind_k(c: Combatant) -> float:
	return float(_blind_k.get(c, 0.0))


## D-1121: 0..1 focus-snap flash right after BLIND ends (decays in 0.25 s).
func blind_snap(c: Combatant) -> float:
	return float(_blind_snap.get(c, 0.0))


## D-1121: BLIND badge pulse, faster as the timer runs out.
static func blind_badge_pulse(c: Combatant, now: int) -> float:
	var urgency := 1.0 - clampf(c.blind_timer / 4.0, 0.0, 1.0)
	return 0.5 + 0.5 * sin(float(now) * (0.004 + urgency * 0.007))


## D-980: a small five-point star for the HUD.
## D-980: a spiral (dizzy eye) drawn as a polyline.
func burn_k(c: Combatant) -> float:
	return float(_burn_k.get(c, 0.0))


## Seconds since the last Burn tick of `c` (9 when there was none).
func burn_tick_age(c: Combatant) -> float:
	var d: Dictionary = _burn_ticks.get(c, {})
	return 9.0 if d.is_empty() else float(BattleHud.clock_ms() - int(d["t0"])) / 1000.0


## 1 -> 0 over 0.3 s after each tick: a brief lightening of the HP fill.
func burn_flash(c: Combatant) -> float:
	return clampf(1.0 - burn_tick_age(c) / 0.3, 0.0, 1.0) * burn_k(c)


## Seconds of Burn left (D-238: the next tick plus one second per tick after it).
## Card background. Not burning: the flat colour of the game. Burning: a dark orange gradient that pulses, a scorched
## (charred) edge with an ember line, tongues of fire licking up from the bottom edge (never higher than `max_flame`
## px, and drawn before the text and the ATB cells so they stay on top) and a hot halo around the card.
## Embers rising off a burning card (deterministic in time, so no randomness in the HUD).
## Pending Burn damage on the HP bar: the last stretch of the fill, hatched, shrinking with every tick.
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


static func tag_pad() -> Vector4:
	return Vector4(EnemyTag.W * 0.5, EnemyTag.W * 0.5, TAG_LIFT + 66.0 + 22.0, 0.0)


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
			tag.position = (p as Vector2) - Vector2(tag.size.x * 0.5, tag.size.y + TAG_LIFT)  # D-981: a bit higher
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
func _draw() -> void:
	var font := FanMenu.body_font()
	for m in _engage_marks:
		var pt: Vector2 = m["p"]
		var bar := Rect2(pt + Vector2(-36, 0), Vector2(72, 7))
		if m["back"]:
			draw_string(font, pt + Vector2(-36, 8), "RETURNING", HORIZONTAL_ALIGNMENT_CENTER, 72, 11, CORAL)
		else:
			draw_string(font, pt + Vector2(-36, -4), "ENGAGED", HORIZONTAL_ALIGNMENT_CENTER, 72, 10, Color(CREAM, 0.9))
			draw_rect(bar, Color(0, 0, 0, 0.55))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(m["k"]), bar.size.y)), LIME.lerp(CORAL, 1.0 - float(m["k"])))
			draw_rect(bar, Color(1, 1, 1, 0.5), false, 1.0)
	_draw_banner()
	_draw_pops()
	if not _status_open:  # The Status pause view has its own footer.
		draw_rect(Rect2(0, 720 - FOOTER_H, 1280, FOOTER_H), Color(0.03, 0.07, 0.11, 0.95))
		draw_line(Vector2(0, 720 - FOOTER_H), Vector2(1280, 720 - FOOTER_H), Color("2a3d47"), 1.0)
		var hint := "ARROWS MOVE   |   Z CONFIRM   |   X BACK   |   SPACE EVADE   |   1-9 MOVES   |   Q/E PAGE   |   R REPEAT   |   C SETTINGS"
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
	var is_ghost := false  ## D-1134: translucent whole-card copy; skips the portrait overlay
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

	func _burst_slot_rect() -> Rect2:
		return Rect2(size.x - 12.4 - 33.06, 70.3, 33.06, 22.48)

	func burst_slot_global() -> Vector2:
		# D-1102/D-1127: the reward token lands on the slot's real centre (it used to
		# stop ~25 px to the left, over the HP/MP rows).
		return position + _burst_slot_rect().get_center() * scale

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

		# D-980: a stunned card sways in a small circle, like its dizzy character.
		var sk := hud.stun_k(combatant) if hud != null else 0.0
		var tt := BattleHud.clock_ms() / 1000.0
		pivot_offset = size * 0.5
		rotation = deg_to_rad(2.2) * sin(tt * TAU * BattleHud.STUN_SWAY_HZ) * sk

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
		var now := BattleHud.clock_ms()

		# Title row.
		# Card body.
		var body := Rect2(0, 18, size.x, 82)
		BattleHud.slant(self, Rect2(body.position + Vector2(6, 6), body.size), 8.0, Color(0, 0, 0, 0.5))
		BattleHud.draw_card_bg(self, body, 8.0, bg, bk, 10.0, now)
		# D-1062: the MP CHARGE BLOCK. It sits OUTSIDE the card (a little apart from it), a bit bigger than the old strip, and fills
		# like water as the 8 s of the next MP pulse run: two waves slide on the surface and bubbles rise through the water.
		# Full when the MP is full. (It no longer sits on the card, so the ARMOR chrome border never covers it.)
		BattleHud.draw_mp_water(self, Rect2(-17.2, 11.8, 19.2, 94.3), 94.3 * 8.0 / 82.0, c, now)
		if c.atb_full():  # D-1070: full ATB = the MP recovers 1.75x faster: two chevrons above the block
			BattleHud.draw_mp_fast_marker(self, Vector2(-3.0, 11.8), now)  # the card's own angle (8 px over 82 px); same right edge, same thickness
		# Portrait.
		var pr := Rect2(16, 26, 56, 62)
		BattleHud.slant(self, pr, 6.0, (Color("263d57") if hero else Color("54456c")).lerp(Color("4a1a06"), bk))
		var portrait_rect := pr.grow(-2.0)
		var portrait_skew := 5.0
		if _portrait != null:
			if _portrait.get_width() > 64:
				# High-res portraits (DQT art) fill the whole slanted frame, clipped to its shape.
				BattleHud.slant_texture(self, portrait_rect, portrait_skew, _portrait)
			else:
				portrait_rect = Rect2(pr.position + Vector2(8, 6), Vector2(44, 44))
				portrait_skew = 0.0
				draw_texture_rect(_portrait, portrait_rect, false)
		if not is_ghost:
			BattleHud.draw_blind(self, portrait_rect, portrait_skew, _portrait, hud.blind_k(c), now, 1.0, hud.blind_snap(c))  # D-1121
			BattleHud.draw_dizzy(self, pr, hud.stun_k(c), now)  # D-980
		# Name.
		draw_string(font, Vector2(84, 44), c.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 150, 18, fg)
		if not hero:  # D-982: the "PLAYER" label was removed
			BattleHud.text_right(self, font, size.x - 48, 40, "ALLY | AI", 8, Color(fg, 0.6))
		# HP.
		var bar_x := 84.0
		var bar_w := 120.0
		draw_rect(Rect2(bar_x, 52, bar_w, 7), track)
		var shown := hud.shown_hp(c)
		draw_rect(Rect2(bar_x, 52, bar_w * clampf(shown / c.max_hp, 0.0, 1.0), 7), hp_col.lerp(Color.WHITE, hud.burn_flash(c) * 0.5))
		BattleHud.draw_burn_pending(self, Rect2(bar_x, 52, bar_w, 7), c, shown / c.max_hp)  # D-239
		var hp_txt := "HP %d/%d" % [ceili(shown), c.max_hp]
		draw_string(font, Vector2(bar_x + bar_w + 8, 59), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)

		# MP & Regen Indicator (D-413)
		var mp_y := 64.0
		draw_rect(Rect2(bar_x, mp_y, bar_w, 5), track)
		var mp_fill := clampf(float(c.mp) / float(maxi(c.max_mp, 1)), 0.0, 1.0)
		draw_rect(Rect2(bar_x, mp_y, bar_w * mp_fill, 5), Color("38bdf8"))
		var mp_txt := "MP %d/%d" % [c.mp, c.max_mp]
		draw_string(font, Vector2(bar_x + bar_w + 8, mp_y + 5), mp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, fg)
		# D-982: the MP regen countdown moved out of the card, next to CAMERA DIRECTION (RegenPanel).

		# Status and Buff badges (D-032)
		var badges: Array[Dictionary] = []
		if c.queued_skill != null:  # QoL: the move is waiting for ATB (D-161).
			badges.append({"text": "QUEUE: %s" % c.queued_skill.display_name.to_upper(), "bg": Color("7a5a00"), "fg": Color("ffe38a")})
		if c.is_stunned():
			badges.append({"text": "STUN %.1fs" % c.stun_timer, "bg": Color("d32f2f"), "fg": Color.WHITE})
		if c.is_burning():  # D-239
			badges.append({"text": "BURN %.1fs" % BattleHud.burn_left(c), "bg": Color("b5470b"), "fg": Color("fff3d6")})
		if c.is_blind():
			badges.append({"text": "BLIND %.1fs" % c.blind_timer, "bg": Color.BLACK, "fg": Color.WHITE, "blind": true})
		if c.taunted_by != null:
			badges.append({"text": "TAUNT", "bg": Color("c2185b"), "fg": Color.WHITE})
		if c.is_guarding():
			badges.append({"text": "GUARD %.1fs" % c.guard_timer, "bg": Color("1f6fd6"), "fg": Color.WHITE})  # D-272
		if c.is_armored():  # D-1026: grey metallic positive badge with an armour icon (breastplate or helmet, still being tested)
			badges.append({"text": "ARMOR %.1fs" % c.armor_timer, "bg": ARMOR_BG, "fg": ARMOR_FG, "icon": true})
		if c.is_invulnerable:
			badges.append({"text": "INVULN", "bg": Color("00838f"), "fg": Color.WHITE})
		if c.is_shielded() and not hud.hide_shield_badges:
			badges.append({"text": "SHIELD %d | %.1fs" % [c.shield_hp, c.shield_timer], "bg": Color("0b3f7a"), "fg": Color("8fe8ff")})
		if c.is_magic_immune():
			badges.append({"text": "MAG. IMMUNE %.1fs" % c.magic_immune_timer, "bg": Color("5b3f99"), "fg": Color("e2d6ff")})
		if c.atk_buff != 0:
			badges.append({"text": "ATK %+d" % c.atk_buff, "bg": Color("3d6600") if c.atk_buff > 0 else Color("c93022"), "fg": Color("#d7fd6a") if c.atk_buff > 0 else Color("#ffb4ab")})
		if c.def_buff != 0:
			badges.append({"text": "DEF %+d" % c.def_buff, "bg": Color("3d6600") if c.def_buff > 0 else Color("c93022"), "fg": Color("#d7fd6a") if c.def_buff > 0 else Color("#ffb4ab")})
		if c.speed_buff != 0:
			badges.append({"text": "SPD %+d" % c.speed_buff, "bg": Color("3d6600") if c.speed_buff > 0 else Color("8a6300"), "fg": Color("#d7fd6a") if c.speed_buff > 0 else Color("#f7cb78")})

		var bx := 8.0
		var by := -2.0  # D-982: a bit farther above the card (was 5) and 15% bigger (font 8 -> 9.2, height 11 -> 12.65)
		for b in badges:
			if is_ghost:
				break  # D-1134: the status badge stays crisp on the real card only
			var txt: String = b["text"]
			var icon_w := 10.5 if b.has("icon") else 0.0
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 9.2 + icon_w
			if bx + tw > size.x - 10:
				break
			var br := Rect2(bx, by, tw, 12.65)
			var badge_bg: Color = b["bg"]
			var badge_fg: Color = b["fg"]
			if bool(b.get("blind", false)):  # D-1134: black badge, white text, neutral pulse
				var p := BattleHud.blind_badge_pulse(c, BattleHud.clock_ms())
				BattleHud.slant(self, Rect2(bx - 2.0 - p * 1.6, by - 1.5 - p * 1.6, tw + 4.0 + p * 3.2, 15.65 + p * 3.2), 2.3,
					Color(0.84, 0.88, 0.93, 0.18 + 0.24 * p))
			BattleHud.slant(self, br, 2.3, badge_bg)
			if b.has("icon"):
				ArmorIcons.draw(self, Rect2(bx + 3.6, by + 1.6, 9.4, 9.4), badge_fg, badge_bg)
			draw_string(font, Vector2(bx + 4.6 + icon_w, by + 10.4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, badge_fg)
			bx += tw + 5.0

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

		# Burst slot (creator: moved up and right, clear of the card edges, 15% bigger again).
		var slot := _burst_slot_rect()
		var bskew := 5.19  # the ATB blocks' slant (3.0 on 13 px) scaled to this height: the same angle
		var sb := c.shown_burst()
		if sb > 0:
			var b_pulse := 0.5 + 0.5 * sin(now * 0.01)
			BattleHud.draw_flames(self, slot, now, 1.0)  # The slot burns while a Burst is ready.
			# Outer pulsating aura
			var aura := Rect2(slot.position - Vector2(2.0 + b_pulse * 1.5, 2.0 + b_pulse * 1.5), slot.size + Vector2(4.0 + b_pulse * 3.0, 4.0 + b_pulse * 3.0))
			BattleHud.slant(self, aura, bskew, Color(1.0, 0.82, 0.2, 0.25 + b_pulse * 0.25))
			# Slot fill
			BattleHud.slant(self, slot, bskew, GOLD.lerp(Color.WHITE, b_pulse * 0.2))
			# Traveling diagonal sheen
			var sheen := fmod(now * 0.002, 1.5) - 0.25
			var sheen_x := slot.position.x + sheen * slot.size.x
			draw_line(Vector2(sheen_x + 3, slot.position.y), Vector2(sheen_x - 3, slot.end.y), Color(1, 1, 1, 0.6), 2.0)
			# Glowing border
			BattleHud.slant_outline(self, slot, bskew, Color.WHITE.lerp(GOLD, 0.4), 1.5)
			# Burst text
			var b_txt := "B" if sb < 2 else "B%d" % sb
			draw_set_transform_matrix(BattleHud.slant_xform(slot, bskew))  # the letters lean like the slot
			for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				draw_string(font, slot.position + Vector2(0, 17.0) + d, b_txt, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 15, Color(1.0, 0.45, 0.05, 0.9))
			draw_string(font, slot.position + Vector2(0, 17.0), b_txt, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 15, Color(1.0, 1.0, 0.9))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			# Sudden burst gain flash
			if _burst_gain_flash > 0.0:
				var g_col := Color(1, 1, 1, _burst_gain_flash * 0.85)
				BattleHud.slant(self, Rect2(slot.position - Vector2(3, 3), slot.size + Vector2(6, 6)), bskew, g_col)
		else:
			# Empty burst slot
			BattleHud.slant(self, slot, bskew, Color("151a24"))
			BattleHud.slant_outline(self, slot, bskew, Color("344254"), 1.0)
			draw_set_transform_matrix(BattleHud.slant_xform(slot, bskew))
			draw_string(font, slot.position + Vector2(0, 16.0), "B", HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 13, Color("4a576b"))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			if c.burst > 0:  # Credited, token still flying: the slot is reserved.
				BattleHud.slant_outline(self, slot, bskew, Color(1.0, 0.6, 0.15, 0.4 + 0.4 * (0.5 + 0.5 * sin(now * 0.012))), 1.5)

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
		# D-1026 (creator): the order numeral strip (I / II / III, a darker grey bar on the right) was removed.
		BattleHud.draw_burn_embers(self, body, bk, now)
		if c.is_armored():
			BattleHud.draw_chrome_border(self, body, 8.0, now, 4.0, false, true)  # D-1026: animated chrome border around the WHOLE card, drawn outside it, while the ARMOR lasts
		hud.draw_burn_tick_jump(self, font, Rect2(bar_x, 52, bar_w, 7), shown / c.max_hp, c, 11)  # D-239


# --- Enemy tag -------------------------------------------------------------------

class EnemyTag extends Control:
	## D-981: compact tag: portrait, name, element icons ("?" until discovered), HP and ATB only; translucent.
	var combatant: Combatant
	var hud: BattleHud
	var active := false
	var pulse := 0.0  ## Set when a reward lands: a small nudge of the tag.
	var _portrait: Texture2D
	var _portrait_tried := false
	const W := 136.0
	const BOX_H := 44.0
	const PR := Rect2(4, 4, 30, 36)
	const X0 := 40.0
	const ATB_Y := 28.0

	func _init() -> void:
		size = Vector2(W, 66)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func atb_slot_global(i: int) -> Vector2:
		return position + Vector2(X0 + i * 13.0 + 5.5, ATB_Y + 3.5)

	func extra_slot_global(k: int) -> Vector2:
		return position + Vector2(X0 + k * 8.0 + 3.0, ATB_Y + 13.0)

	func _burst_slot_rect() -> Rect2:
		return Rect2(X0 + 5 * 13.0 + 1.0, ATB_Y - 1.675, 14.95, 10.35)

	func burst_slot_global() -> Vector2:
		return position + _burst_slot_rect().get_center() * scale

	func _process(_d: float) -> void:
		if combatant == null or hud == null:
			return
		# D-981: the tag gets dizzy too while its enemy is stunned (slow sway).
		pivot_offset = size * 0.5
		rotation = deg_to_rad(2.2) * sin(BattleHud.clock_ms() / 1000.0 * TAU * BattleHud.STUN_SWAY_HZ) * hud.stun_k(combatant)

	func _draw() -> void:
		var c := combatant
		var font := FanMenu.body_font()
		var now := BattleHud.clock_ms()
		var box := Rect2(0, 0, size.x, BOX_H)
		BattleHud.slant(self, Rect2(box.position + Vector2(3, 3), box.size), 6.0, Color(0, 0, 0, 0.28))
		var bk := hud.burn_k(c)  # D-239
		# D-981: a bit translucent so the arena shows through.
		BattleHud.draw_card_bg(self, box, 6.0, Color("eae9d9", 0.82) if active else Color(INK, 0.4), bk, 5.0, now)

		# Status and Buff badges floating above enemy tag (D-032)
		# D-984: negative effects (debuffs, harmful status) line up from the far left; positive ones (buffs, protections)
		# from the far right. The queued move is neither, so it sits with the positive group's side (right).
		var neg: Array[Dictionary] = []
		var pos: Array[Dictionary] = []
		if c.is_stunned():
			neg.append({"text": "STUN %.1fs" % c.stun_timer, "bg": Color("d32f2f"), "fg": Color.WHITE})
		if c.is_burning():
			neg.append({"text": "BURN %.1fs" % BattleHud.burn_left(c), "bg": Color("b5470b"), "fg": Color("fff3d6")})
		if c.is_blind():
			neg.append({"text": "BLIND %.1fs" % c.blind_timer, "bg": Color.BLACK, "fg": Color.WHITE, "blind": true})
		if c.taunted_by != null:
			neg.append({"text": "TAUNT", "bg": Color("c2185b"), "fg": Color.WHITE})
		for bd in [["ATK", c.atk_buff], ["DEF", c.def_buff], ["SPD", c.speed_buff]]:
			var v: int = bd[1]
			if v < 0:
				neg.append({"text": "%s %+d" % [bd[0], v], "bg": Color("c93022") if bd[0] != "SPD" else Color("8a6300"), "fg": Color("#ffb4ab") if bd[0] != "SPD" else Color("#f7cb78")})
			elif v > 0:
				pos.append({"text": "%s %+d" % [bd[0], v], "bg": Color("3d6600"), "fg": Color("#d7fd6a")})
		if c.is_guarding():
			pos.append({"text": "G %.1fs" % c.guard_timer, "bg": Color("1f6fd6"), "fg": Color.WHITE})
		if c.is_armored():  # D-1026
			pos.append({"text": "ARMOR %.1fs" % c.armor_timer, "bg": ARMOR_BG, "fg": ARMOR_FG, "icon": true})
		if c.is_invulnerable:
			pos.append({"text": "INVULN", "bg": Color("00838f"), "fg": Color.WHITE})
		if c.is_shielded() and not hud.hide_shield_badges:
			pos.append({"text": "S %d | %.1fs" % [c.shield_hp, c.shield_timer], "bg": Color("0b3f7a"), "fg": Color("8fe8ff")})
		if c.is_magic_immune():
			pos.append({"text": "IMM %.1fs" % c.magic_immune_timer, "bg": Color("5b3f99"), "fg": Color("e2d6ff")})
		if c.queued_skill != null:
			pos.append({"text": "QUEUE %s" % c.queued_skill.display_name.to_upper(), "bg": Color("7a5a00"), "fg": Color("ffe38a")})
		var lx := 0.0
		for b in neg:
			var txt: String = b["text"]
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 7.0
			var badge_bg: Color = b["bg"]
			var badge_fg: Color = b["fg"]
			if bool(b.get("blind", false)):  # D-1134: black badge, white text, neutral pulse
				var p := BattleHud.blind_badge_pulse(c, BattleHud.clock_ms())
				BattleHud.slant(self, Rect2(lx - 1.6 - p * 1.2, -15.6 - p * 1.2, tw + 3.2 + p * 2.4, 13.2 + p * 2.4), 2.0,
					Color(0.84, 0.88, 0.93, 0.18 + 0.24 * p))
			BattleHud.slant(self, Rect2(lx, -14, tw, 11), 2.0, badge_bg)
			draw_string(font, Vector2(lx + 3.0, -5.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, badge_fg)
			lx += tw + 3.0
		var rx := size.x
		for b in pos:
			var txt: String = b["text"]
			var icon_w := 8.5 if b.has("icon") else 0.0
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 7.0 + icon_w
			rx -= tw
			BattleHud.slant(self, Rect2(rx, -14, tw, 11), 2.0, b["bg"])
			if b.has("icon"):
				ArmorIcons.draw(self, Rect2(rx + 2.6, -12.6, 8.0, 8.0), b["fg"], b["bg"])
			draw_string(font, Vector2(rx + 3.0 + icon_w, -5.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, b["fg"])
			rx -= 3.0

		# Portrait.
		if not _portrait_tried:
			_portrait_tried = true
			var path := "res://personagens/portraits/%s.png" % c.name.to_lower()
			if ResourceLoader.exists(path):
				_portrait = load(path)
		BattleHud.slant(self, PR, 4.0, Color("54456c").lerp(Color("4a1a06"), bk))
		if _portrait != null:
			BattleHud.slant_texture(self, PR.grow(-1.5), 3.5, _portrait)
		BattleHud.draw_blind(self, PR.grow(-1.5), 3.5, _portrait, hud.blind_k(c), now, 0.75, hud.blind_snap(c))  # D-1121
		BattleHud.draw_dizzy(self, PR, hud.stun_k(c), now, 0.6)

		# Name + element icons ("?" black on white until discovered).
		var name_col := Color("b74134") if active else CORAL
		draw_string(font, Vector2(X0, 13), c.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, W - X0 - 34, 10, name_col.lerp(BattleHud.BURN_TEXT, bk))
		var elems: Array = c.get_elements()
		var team: Array = hud._battle.party if hud._battle != null else []
		var gs_node := get_node_or_null("/root/GameState")  # autoload looked up at runtime (tests may load the HUD without it)
		var known: bool = gs_node != null and bool(gs_node.call("elements_known", c, team))
		var n_ic := maxi(mini(elems.size(), 2), 1)
		for k in n_ic:
			var ir := Rect2(W - 6.0 - float(n_ic - k) * 13.0, 4.0, 12.0, 11.0)
			if not known:
				BattleHud.slant(self, ir, 2.0, Color.WHITE)
				# D-982: centred on the icon by the glyph's real ascent/descent (the slant shifts the visual centre 1 px)
				var qa := font.get_ascent(10)
				var qd := font.get_descent(10)
				draw_string(font, Vector2(ir.position.x + 0.5, ir.get_center().y + (qa - qd) * 0.5 - 0.5), "?", HORIZONTAL_ALIGNMENT_CENTER, ir.size.x, 10, Color.BLACK)
			elif k < elems.size():
				var e: Element.Type = elems[k]
				BattleHud.slant(self, ir, 2.0, StatusScreen.ELEMENT_COLORS.get(e, BattleFx.COLORS.get(e, Color.WHITE)))
				var ic := BattleHud.element_icon(e)
				if ic != null:
					draw_texture_rect(ic, Rect2(ir.get_center() - Vector2(4.5, 4.5), Vector2(9, 9)), false, StatusScreen.ELEMENT_GLYPH_COLORS.get(e, Color("080e18")))

		# HP (no MP on the enemy tag: D-981; no numbers: D-963).
		var hp_r := Rect2(X0, 18, W - X0 - 6, 5)
		draw_rect(hp_r, Color("7b8c90") if active else Color(0.23, 0.28, 0.34, 0.8))
		var shown := hud.shown_hp(c)
		draw_rect(Rect2(hp_r.position, Vector2(hp_r.size.x * clampf(shown / c.max_hp, 0.0, 1.0), hp_r.size.y)), CORAL.lerp(Color.WHITE, hud.burn_flash(c) * 0.5))
		BattleHud.draw_burn_pending(self, hp_r, c, shown / c.max_hp)

		# ATB: five compact blocks.
		for i in 5:
			var r := Rect2(X0 + i * 13.0, ATB_Y, 11, 7)
			BattleHud.slant(self, r, 2.0, Color("9aa7b0") if active else Color(0.16, 0.2, 0.26, 0.85))
			var fill := clampf(c.shown_atb() - i, 0.0, 1.0)
			if fill > 0.0:
				BattleHud.slant(self, Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), 2.0 * fill, Color(0.4, 0.88, 1.0) if fill >= 1.0 else Color(0.2, 0.55, 0.75))
			if clampf(c.atb - i, 0.0, 1.0) > fill + 0.001:
				var rsv := 0.5 + 0.5 * sin(now * 0.012 + i)
				var o := PackedVector2Array([Vector2(r.position.x + 2.0, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - 2.0, r.end.y), Vector2(r.position.x, r.end.y), Vector2(r.position.x + 2.0, r.position.y)])
				draw_polyline(o, Color(0.45, 0.92, 1.0, 0.35 + 0.4 * rsv), 1.2)
		# Burst slot (15% bigger than before, 13 x 9, same centre).
		var slot := _burst_slot_rect()
		var bskew := 2.96  # the tag's ATB slant (2.0 on 7 px) scaled to this height
		var sb := c.shown_burst()
		if sb > 0:
			BattleHud.draw_flames(self, slot, now, 0.6)
			BattleHud.slant(self, slot, bskew, GOLD.lerp(Color.WHITE, 0.15 + 0.15 * sin(now * 0.01)))
			draw_set_transform_matrix(BattleHud.slant_xform(slot, bskew))
			draw_string(font, slot.position + Vector2(0, 8), "B" if sb < 2 else "B%d" % sb, HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 8, Color(0.2, 0.1, 0.0))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		else:
			BattleHud.slant(self, slot, bskew, Color(0.08, 0.1, 0.14, 0.8))
			BattleHud.slant_outline(self, slot, bskew, Color("344254"), 1.0)
			draw_set_transform_matrix(BattleHud.slant_xform(slot, bskew))
			draw_string(font, slot.position + Vector2(0, 8), "B", HORIZONTAL_ALIGNMENT_CENTER, slot.size.x, 8, Color("4a576b"))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			if c.burst > 0:
				BattleHud.slant_outline(self, slot, bskew, Color(1.0, 0.6, 0.15, 0.4 + 0.4 * (0.5 + 0.5 * sin(now * 0.012))), 1.5)
		# Extra ATB blocks.
		var ex_shown := int(c.shown_extra())
		for k in int(c.extra + 0.001):
			var er := Rect2(X0 + k * 8.0, ATB_Y + 11.0, 6, 4)
			if k < ex_shown:
				draw_rect(er, Color(0.55, 0.95, 1.0))
			else:
				draw_rect(er, Color(0.45, 0.92, 1.0, 0.45), false, 1.0)
		BattleHud.draw_pos_marks(self, Vector2(size.x * 0.5, BOX_H + 6.0), c.pos_step)
		BattleHud.draw_burn_embers(self, box, bk, now)
		if c.is_armored():
			BattleHud.draw_chrome_border(self, box, 6.0, now, 3.0)  # D-1026
		hud.draw_burn_tick_jump(self, font, hp_r, shown / c.max_hp, c, 8)
		# D-983: the red target diamond under the tag was removed (the selected tag keeps its light background).


# --- Camera indicator --------------------------------------------------------------

class CameraTabs extends Control:
	var mode := BattleCamera.Mode.CINEMA
	const NAMES := ["CINEMA", "TACTICAL", "IMPACT"]

	func _init() -> void:
		size = Vector2(266, 70)
		position = Vector2(1280 - 24 - 266, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := FanMenu.body_font()
		draw_string(font, Vector2(2, 10), "CAMERA DIRECTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f3e7cd"))
		BattleHud.text_right(self, font, size.x - 2, 10, "AUTOMATIC", 9, LIME)
		for i in 3:
			var r := Rect2(i * 88, 18, 86, 44)
			var on := i == int(mode)
			BattleHud.slant(self, r, 7.0, LIME if on else Color(0.05, 0.1, 0.16, 0.88))
			draw_string(FanMenu.title_font(), Vector2(r.position.x, r.position.y + 21), "%02d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, INK if on else Color("9cb4bb"))
			draw_string(font, Vector2(r.position.x, r.position.y + 36), NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, INK if on else Color("9cb4bb"))


# --- D-982: MP regen of the allies, left of CAMERA DIRECTION ---------------------

class RegenPanel extends Control:
	var hud: BattleHud

	func _init() -> void:
		size = Vector2(170, 70)
		position = Vector2(1280 - 24 - 266 - 12 - 170, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if hud == null or hud._battle == null:
			return
		var font := FanMenu.body_font()
		draw_string(font, Vector2(2, 10), "MP REGEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f3e7cd"))
		var y := 18.0
		for c in hud._battle.party.slice(0, 3):
			var r := Rect2(0, y, size.x, 14)
			BattleHud.slant(self, r, 4.0, Color(0.05, 0.1, 0.16, 0.88))
			draw_string(font, Vector2(8, y + 11), c.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 70, 9, Color("9cb4bb"))
			var txt := "MAX"
			var col := Color("9cb4bb", 0.6)
			if c.mp < c.max_mp:
				txt = "+%d in %.1fs" % [c.mp_regen_amount(), c.mp_regen_left()]
				col = Color("67e8f9")
			BattleHud.text_right(self, font, size.x - 8, y + 11, txt, 9, col)
			y += 17.0


# --- Incoming attack tag -----------------------------------------------------------

## Floating label over an attacker: move name, who it targets and a countdown bar.
class AttackTag extends Control:
	## D-985: the wind-up tag as a move sheet (D-417): flat element colour, element watermark, big name, type and range
	## icons, the target with a mini portrait and a thick countdown bar. It "stamps" in and leaves upward, faster.
	## The Evade window is NOT marked here (it becomes a VFX on the attacker, to be defined).
	## D-440: Unknown enemy wind-up uses neutral dark bg and white slanted [?] block, without spoiling element color.
	var inc
	var hud: BattleHud
	var leaving := false
	var broken := false
	var _t := 0.0
	var _portrait: Texture2D
	var _portrait_tried := false
	static var _icons: Dictionary = {}
	const STAMP_LEN := 0.12
	const LEAVE_LEN := 0.1

	func _init() -> void:
		size = Vector2(150, 38)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size * 0.5

	static func _icon(path: String) -> Texture2D:
		if not _icons.has(path):
			_icons[path] = load(path) if ResourceLoader.exists(path) else null
		return _icons[path]

	## Leaves upward and fades in LEAVE_LEN, then frees itself (faster than the stamp-in).
	func leave() -> void:
		if leaving:
			return
		leaving = true
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "position:y", position.y - 14.0, LEAVE_LEN)
		tw.tween_property(self, "modulate:a", 0.0, LEAVE_LEN)
		tw.chain().tween_callback(queue_free)

	## D-1104: the action was interrupted. Hide this card, capture its real pixels into a
	## transparent SubViewport, then hand them to AttackTagShatter (9 shards + "interrupted").
	func shatter() -> void:
		if broken:
			return
		broken = true
		visible = false
		if hud == null or not is_instance_valid(hud):
			queue_free()
			return
		var vp := SubViewport.new()
		vp.size = Vector2i(int(size.x), int(size.y))
		vp.transparent_bg = true
		vp.disable_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		hud.add_child(vp)
		var copy := AttackTag.new()
		copy.inc = inc
		copy.hud = hud
		copy.size = size
		copy.position = Vector2.ZERO
		copy.set_process(false)
		copy._t = STAMP_LEN
		vp.add_child(copy)
		await RenderingServer.frame_post_draw
		var img: Image = null
		if is_instance_valid(vp):
			img = vp.get_texture().get_image()
			vp.queue_free()
		if not is_instance_valid(hud) or img == null or img.is_empty():
			queue_free()
			return
		AttackTagShatterScript.spawn(hud, position, size, ImageTexture.create_from_image(img))
		queue_free()

	func _process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / STAMP_LEN, 0.0, 1.0)
		scale = Vector2.ONE * lerpf(1.15, 1.0, 1.0 - pow(1.0 - k, 3.0))
		queue_redraw()

	func _draw() -> void:
		if inc == null:
			return
		var font := FanMenu.body_font()
		var title := FanMenu.title_font()

		# D-981, D-440: Check if attacker elements are discovered (anti-spoiler)
		var atk: Combatant = inc.attacker if inc.get("attacker") != null else null
		var is_known := true
		if atk != null and not atk.is_player:
			var gs_node := get_node_or_null("/root/GameState")
			var team: Array = hud._battle.party if (hud != null and hud._battle != null) else []
			is_known = gs_node != null and bool(gs_node.call("elements_known", atk, team))

		var e: Element.Type = inc.element
		var bg: Color = StatusScreen.ELEMENT_COLORS.get(e, BattleFx.COLORS.get(e, Color.WHITE)) if is_known else Color("1e293b", 0.92)
		var fg: Color = StatusScreen.ELEMENT_GLYPH_COLORS.get(e, Color("080e18")) if is_known else Color("f8fafc")
		var body := Rect2(0, 0, size.x, 30)
		BattleHud.slant(self, Rect2(body.position + Vector2(3, 3), body.size), 6.0, Color(0, 0, 0, 0.35))
		BattleHud.slant(self, body, 6.0, bg)

		if not is_known:
			# Unknown badge on the right: White slanted block with black '?' (D-981, D-440)
			var qr := Rect2(size.x - 26, 5, 18, 19)
			BattleHud.slant(self, qr, 2.0, Color.WHITE)
			var qa := font.get_ascent(11)
			var qd := font.get_descent(11)
			draw_string(font, Vector2(qr.position.x + 0.5, qr.get_center().y + (qa - qd) * 0.5 - 0.5), "?", HORIZONTAL_ALIGNMENT_CENTER, qr.size.x, 11, Color.BLACK)
		else:
			# Element watermark behind the name (D-417, D-440: Diamond Core for neutral).
			var wm := BattleHud.element_icon(e)
			if wm != null:
				draw_texture_rect(wm, Rect2(Vector2(size.x - 30, 2), Vector2(26, 26)), false, Color(fg, 0.18))  # D-1006: small, clear of the name

		# Name (big) + type and range icons on its right (D-985, D-440: only 2 icons).
		var name := String(inc.label).to_upper()
		# D-1006: the name shrinks to fit the space left by the two icons (it was cut and covered).
		var room := size.x - 10.0 - 6.0 - 32.0 - 4.0
		var fsz := 17
		while fsz > 10 and title.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x > room:
			fsz -= 1
		draw_string(title, Vector2(10, 17), name, HORIZONTAL_ALIGNMENT_LEFT, room, fsz, fg)
		var nw := minf(title.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x, room)
		var sk: Skill = inc.skill if inc.get("skill") != null else null
		var type_name := sk.type_icon_name() if sk != null else ""
		var range_name := ""
		if sk != null and sk.kind != Skill.Kind.STATUS:
			range_name = "area" if sk.is_aoe else ("melee" if sk.kind == Skill.Kind.MELEE else ("long" if sk.kind == Skill.Kind.PROJECTILE else "mid"))
		var icon_paths: Array[String] = []
		if not type_name.is_empty():
			icon_paths.append("res://assets/ui/icons/move_types/%s.svg" % type_name)
		if not range_name.is_empty():
			icon_paths.append("res://assets/ui/icons/range/%s.svg" % range_name)
		var ix := 10.0 + nw + 6.0
		for path in icon_paths:
			var ic := _icon(path)
			if ic != null:
				var ic_fg := Color("ef4444") if (type_name == "physical" and not is_known and path.contains("move_types")) else fg
				draw_texture_rect(ic, Rect2(Vector2(ix, 5), Vector2(13, 13)), false, ic_fg)
				ix += 16.0
		# Target: mini portrait + name.
		if not _portrait_tried:
			_portrait_tried = true
			var pp := "res://personagens/portraits/%s.png" % String(inc.target.name).to_lower()
			if ResourceLoader.exists(pp):
				_portrait = load(pp)
		var tr := Rect2(10, 19, 9, 9)
		if _portrait != null:
			BattleHud.slant_texture(self, tr, 1.5, _portrait)
		var tgt_hit_player: bool = inc.target.is_player
		draw_string(font, Vector2(23, 27), "> %s" % String(inc.target.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 70, 9, fg)
		# Countdown: thick bar under the body, seconds on the right.
		var w_total: float = inc.total_windup if inc.get("total_windup") != null and inc.total_windup > 0.05 else Battle.WINDUP
		var k := 1.0 if inc.resolved else clampf(1.0 - inc.time_left / w_total, 0.0, 1.0)
		var bar := Rect2(4, 31, size.x - 34, 6)
		BattleHud.slant(self, bar, 2.0, Color(0.03, 0.06, 0.1, 0.85))
		BattleHud.slant(self, Rect2(bar.position, Vector2(bar.size.x * (1.0 - k), bar.size.y)), 2.0, CORAL if tgt_hit_player else Color("f3e7cd"))
		var left := 0.0 if inc.resolved else maxf(inc.time_left, 0.0)
		BattleHud.text_right(self, font, size.x - 2, 38, "%.1fs" % left, 9, Color("f3e7cd"))


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
		var pulse := 0.5 + 0.5 * sin(BattleHud.clock_ms() * 0.016)
		var is_perfect := false
		var is_early := not can_now
		var bg_col := GOLD.lerp(Color.WHITE, pulse * 0.6) if is_perfect else (Color("2b394a") if is_early else LIME.lerp(Color.WHITE, pulse * 0.45))
		var fg_col := INK if not is_early else CREAM
		BattleHud.slant(self, Rect2(Vector2(4, 5), size - Vector2(4, 5)), 8.0, Color(0, 0, 0, 0.55))
		BattleHud.slant(self, Rect2(Vector2.ZERO, size - Vector2(4, 5)), 8.0, bg_col)
		draw_string(FanMenu.title_font(), Vector2(14, 31), "SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, fg_col)
		var status_txt := "PERFECT!" if is_perfect else ("WAIT..." if is_early else "DODGE!")
		draw_string(font, Vector2(102, 21), status_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CORAL if is_early else fg_col)
		draw_string(font, Vector2(102, 36), ("%.2fs" % time_left) if can_now else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(fg_col, 0.8))
