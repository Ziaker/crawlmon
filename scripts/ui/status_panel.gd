class_name StatusPanel
extends Control
## Pause view of one character at a time: the camera frames the selected unit
## (animated) while its status card sits on the right. Left/Right (or Up/Down)
## picks another unit; Z or X closes. The battle scene pauses the tree while
## it is open.

signal closed
signal selected(unit: Combatant)

const LIME := Color("d7fd6a")
const CORAL := Color("ff624f")
const AQUA := Color("62d8e7")
const GOLD := Color("f7cb78")
const INK := Color("080e18")
const CREAM := Color("f0eedf")
const LILAC := Color("b6a3fe")
const ACT_NAMES := ["Attack", "Skills", "Hold"]
const REACT_NAMES := ["None", "Evade"]
const CARD := Rect2(868, 100, 384, 566)

var _party: Array[Combatant] = []
var _units: Array[Combatant] = []
var _index := 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open(party: Array[Combatant], enemies: Array[Combatant]) -> void:
	_party = party
	_units = []
	_units.append_array(party)
	for e in enemies:
		if e.is_alive():
			_units.append(e)
	_index = 0
	visible = true
	selected.emit(_units[0])
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("confirm"):
		visible = false
		closed.emit()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_pick(1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_pick(-1)
	else:
		return
	get_viewport().set_input_as_handled()


func _pick(step: int) -> void:
	_index = posmod(_index + step, _units.size())
	selected.emit(_units[_index])


func _draw() -> void:
	if _units.is_empty():
		return
	var font := FanMenu.body_font()
	var title := FanMenu.title_font()
	# Darken the right edge so the card reads over the arena.
	for i in 10:
		draw_rect(Rect2(CARD.position.x - 60.0 + i * 8.0, 0, 8.0, size.y), Color(0.02, 0.05, 0.09, 0.05 * (i + 1)))
	draw_rect(Rect2(CARD.position.x + 20.0, 0, size.x, size.y), Color(0.02, 0.05, 0.09, 0.5))
	draw_string(title, Vector2(28, 100), "STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, CREAM)
	draw_string(font, Vector2(28, 120), "//  GAME PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LIME)
	# Unit tabs above the card.
	var x := CARD.position.x
	for i in _units.size():
		var u := _units[i]
		var on := i == _index
		var w := font.get_string_size(u.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 28.0
		BattleHud.slant(self, Rect2(x, 66, w, 26), 6.0, LIME if on else Color(0.05, 0.1, 0.16, 0.9))
		draw_string(font, Vector2(x + 14, 84), u.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK if on else Color("9cb4bb"))
		x += w + 4.0
	_draw_unit(_units[_index], CARD)
	draw_rect(Rect2(0, size.y - 36, size.x, 36), Color(0.03, 0.07, 0.11, 0.95))
	draw_string(font, Vector2(28, size.y - 13), "ARROWS  SELECT CHARACTER   |   Z / X  BACK TO BATTLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b5c3c2"))


func _draw_unit(c: Combatant, r: Rect2) -> void:
	var font := FanMenu.body_font()
	var is_leader := _party.size() > 0 and c == _party[0]
	var role := "PLAYER" if is_leader else ("ALLY" if c.is_player else "ENEMY")
	var accent := AQUA if is_leader else (LILAC if c.is_player else CORAL)
	var bg := Color("eae9d9") if is_leader else (Color("17283b") if c.is_player else Color(0.05, 0.08, 0.13))
	var fg := Color("111b29") if is_leader else Color("eceada")
	var dim := Color(fg, 0.62)
	BattleHud.slant(self, Rect2(r.position + Vector2(7, 7), r.size), 10.0, Color(0, 0, 0, 0.5))
	BattleHud.slant(self, r, 10.0, bg)
	draw_rect(Rect2(r.position, Vector2(7, r.size.y)), accent)
	var x := r.position.x + 22.0
	var right := r.end.x - 16.0
	var y := r.position.y + 26.0
	# Header.
	draw_string(font, Vector2(x, y), role, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent if not is_leader else Color("1b7f95"))
	y += 30.0
	draw_string(FanMenu.title_font(), Vector2(x, y), c.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, fg)
	y += 22.0
	# HP bar.
	var bar_w := right - x
	draw_rect(Rect2(x, y, bar_w, 9), Color("7b8c90") if is_leader else Color("3a4756"))
	draw_rect(Rect2(x, y, bar_w * clampf(float(c.hp) / c.max_hp, 0.0, 1.0), 9), Color("e96159") if not (c.is_player and not is_leader) else Color("b5a5fe"))
	y += 24.0
	draw_string(font, Vector2(x, y), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)
	BattleHud.text_right(self, font, right, y, "%d / %d" % [c.hp, c.max_hp], 13, fg)
	y += 26.0
	# Stats.
	var atk_str := str(c.attack) + (" (+%d)" % c.atk_buff if c.atk_buff > 0 else (" (%d)" % c.atk_buff if c.atk_buff < 0 else ""))
	var def_str := "DEFAULT"
	if c.def_buff > 0:
		var mit := (1.0 - 1.0 / (1.0 + float(c.def_buff) * DamageMath.DEF_STAGE)) * 100.0
		def_str = "+%d%% mitigation (+%d)" % [roundi(mit), c.def_buff]
	elif c.def_buff < 0:
		var vuln := float(abs(c.def_buff)) * DamageMath.DEF_STAGE * 100.0
		def_str = "-%d%% defense (%d)" % [roundi(vuln), c.def_buff]
	var spd_str := "%.2f blocks/s" % c.speed + (" (+%d)" % c.speed_buff if c.speed_buff > 0 else (" (%d)" % c.speed_buff if c.speed_buff < 0 else ""))
	# Status effects, with the real timers (QoL 2).
	var status_str := BattleHud.status_line(c, false)
	if status_str.length() > 52:
		status_str = status_str.substr(0, 50) + "…"
	var shield_str := "%d / %d · %.1f s" % [c.shield_hp, c.shield_max, c.shield_timer] if c.is_shielded() else "—"
	for row in [
		["STATE", status_str],
		["ATTACK", atk_str],
		["DEFENSE", def_str],
		["SPEED", spd_str],
		["ATB", "%.1f / %d" % [c.atb, int(Combatant.BLOCKS)]],
		["BURST", str(c.burst)],
		["SHIELD", shield_str],
	]:
		draw_string(font, Vector2(x, y), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, dim)
		BattleHud.text_right(self, font, right, y, row[1], 10 if row[0] == "STATE" else 13, fg)
		y += 20.0
	y += 8.0
	var aff := c.affinity_text()
	_section_row(x, right, y, "AFFINITIES", aff if aff != "" else "—", fg, LIME if fg.v > 0.5 else Color("1b7f95"))
	y += 18.0
	var held := c.get_held_item()
	_section_row(x, right, y, "ITEM", held.display_name if held != null else "—", fg, LIME if fg.v > 0.5 else Color("1b7f95"))
	y += 18.0
	var moves: Array[Skill] = [Skill.basic()]
	moves.append_array(c.skills)
	_section(r, x, right, y, "MOVES | EFFECT (%d)" % moves.size(), fg)
	y += 20.0
	var cap := mini(moves.size(), 14 if is_leader else 9)  # allies still show Tactics below
	for i in cap:
		var s := moves[i]
		draw_string(font, Vector2(x, y), s.display_name, HORIZONTAL_ALIGNMENT_LEFT, int(right - x) - 142, 11, fg)
		BattleHud.text_right(self, font, right, y, "%d · %s" % [s.cost, s.short_effect()], 9, GOLD if not is_leader else Color("9a6b00"))
		y += 16.0
	if c.is_player and not is_leader:
		y += 8.0
		_section(r, x, right, y, "TACTICS (IA)", fg)
		y += 22.0
		draw_string(font, Vector2(x, y), "Action: %s" % ACT_NAMES[c.act_policy], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, fg)
		y += 20.0
		draw_string(font, Vector2(x, y), "Reaction: %s" % REACT_NAMES[c.react_policy], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, fg)


func _section(_r: Rect2, x: float, right: float, y: float, text: String, fg: Color) -> void:
	draw_rect(Rect2(x, y - 12, right - x, 1), Color(fg, 0.25))
	draw_string(FanMenu.body_font(), Vector2(x, y + 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LIME if fg.v > 0.5 else Color("1b7f95"))


## Compact label/value row (weaknesses, held item) so both fit on the card.
func _section_row(x: float, right: float, y: float, label: String, value: String, fg: Color, accent: Color) -> void:
	draw_rect(Rect2(x, y - 12, right - x, 1), Color(fg, 0.2))
	draw_string(FanMenu.body_font(), Vector2(x, y + 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent)
	BattleHud.text_right(self, FanMenu.body_font(), right, y + 1, value, 11, fg)
