class_name SkillInfoPanel
extends Control
## Live tactical sheet of the highlighted Fight move (D-417, D-420, D-434, D-435, D-436).
## Compact side blade positioned beside the Fight drawer, completely eliminating central arena occlusion.

const TITLE_FONT := preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")
const LIME := Color("d7fd6a")
const CORAL := Color("ff624f")
const AQUA := Color("62d8e7")
const GOLD := Color("f7cb78")
const INK := Color("080e18")
const CREAM := Color("f0eedf")
const DARK_BG := Color(0.04, 0.07, 0.11, 0.75)
const BORDER_COLOR := Color(0.20, 0.30, 0.42, 0.9)
const CYAN := Color("38bdf8")
const AMBER := Color("f59e0b")
const MoveIcons = preload("res://scripts/ui/move_icons.gd")

var hud: Control
var skill: Skill
var caster: Combatant
var target: Combatant
var battle: Battle
var _t := 0.0
var _body_font: Font


func _init() -> void:
	# D-436, D-439: Compact lateral blade at x: 296, y: 474 (width: 292, height: 196),
	# reduced from 246px to 196px, perfectly flush with the Fight drawer bottom at 670.
	position = Vector2(296, 474)
	size = Vector2(292, 196)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1, 1, 1, 0.75)
	visible = false


func show_skill(sk: Skill, p_caster: Combatant, p_target: Combatant, p_battle: Battle) -> void:
	skill = sk
	caster = p_caster
	target = p_target
	battle = p_battle
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t >= 0.1:  # timers and incoming ETAs stay live
		_t = 0.0
		queue_redraw()


var _icon_cache: Dictionary = {}


func _get_element_icon(elem: Element.Type) -> Texture2D:
	return BattleHud.element_icon(elem)


func _get_type_icon(tname: String) -> Texture2D:
	var p := "res://assets/ui/icons/move_types/%s.svg" % tname
	if _icon_cache.has(p):
		return _icon_cache[p]
	if ResourceLoader.exists(p):
		var tex: Texture2D = load(p)
		_icon_cache[p] = tex
		return tex
	return null


func _get_range_icon(rname: String) -> Texture2D:
	var p := "res://assets/ui/icons/range/%s.svg" % rname
	if _icon_cache.has(p):
		return _icon_cache[p]
	if ResourceLoader.exists(p):
		var tex: Texture2D = load(p)
		_icon_cache[p] = tex
		return tex
	return null

func _font() -> Font:
	if _body_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Arial", "Segoe UI"])
		f.font_weight = 800
		_body_font = f
	return _body_font


func _title_font() -> Font:
	return TITLE_FONT


func _slant(r: Rect2, skew: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y),
		Vector2(r.end.x + skew, r.position.y),
		Vector2(r.end.x, r.end.y),
		Vector2(r.position.x, r.end.y)
	]), color)


func _breaks_guard(skill: Skill) -> bool:
	if skill == null:
		return false
	if skill.data != null:
		return skill.data.has_tag(&"guard_break")
	return BattleSpace.move_id(skill.display_name) == "quebra_telha"


func _draw_para_flat(r: Rect2, skew: float, color: Color, outline: Color = Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y),
		Vector2(r.end.x + skew, r.position.y),
		Vector2(r.end.x, r.end.y),
		Vector2(r.position.x, r.end.y)
	])
	draw_colored_polygon(pts, color)
	if outline.a > 0.0:
		pts.append(pts[0])
		draw_polyline(pts, outline, 1.0)


func _status_line(c: Combatant) -> String:
	var parts: Array[String] = []
	if c.is_shielded():
		parts.append("SHIELD %d | %.1fs" % [c.shield_hp, c.shield_timer])
	if c.is_guarding():
		parts.append("GUARD %.1fs" % c.guard_timer)
	if c.is_stunned():
		parts.append("STUN %.1fs" % c.stun_timer)
	if c.is_burning():
		var left := maxf(c.burn_clock + float(c.burn_ticks_left - 1) * Battle.BURN_INTERVAL, 0.0)
		parts.append("BURN %.1fs" % left)
	if c.is_blind():
		parts.append("BLIND %.1fs" % c.blind_timer)
	if c.taunted_by != null:
		parts.append("TAUNT")
	if c.is_invulnerable:
		parts.append("INVULN")
	if c.is_magic_immune():
		parts.append("MAG. IMMUNE %.1fs" % c.magic_immune_timer)
	if c.atk_buff != 0:
		parts.append("ATK %+d" % c.atk_buff)
	if c.def_buff != 0:
		parts.append("DEF %+d" % c.def_buff)
	if c.speed_buff != 0:
		parts.append("SPD %+d" % c.speed_buff)
	return " | ".join(parts) if not parts.is_empty() else "No active effects"


func _draw_wrapped_text(font: Font, pos: Vector2, text: String, max_w: float, font_size: int, line_spacing: float, color: Color) -> float:
	var words := text.split(" ")
	var cur_line := ""
	var y := pos.y
	for word in words:
		var test_line := cur_line + (" " if cur_line != "" else "") + word
		if font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_w and cur_line != "":
			draw_string(font, Vector2(pos.x, y), cur_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
			y += float(font_size) + line_spacing
			cur_line = word
		else:
			cur_line = test_line
	if cur_line != "":
		draw_string(font, Vector2(pos.x, y), cur_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		y += float(font_size) + line_spacing
	return y

func _draw() -> void:
	if skill == null:
		return
	var font := _font()
	var title_font := _title_font()
	var w := size.x
	var h := size.y

	# 1. Base shadow and panel container (D-135, D-417)
	_draw_para_flat(Rect2(4, 4, w - 8, h - 8), 6.0, Color(0, 0, 0, 0.45))
	_draw_para_flat(Rect2(0, 0, w, h), 6.0, DARK_BG, BORDER_COLOR)

	# 2. Top Header with solid element color (D-417, D-420, D-438)
	# Neutral/physical moves use the exact same grey Color("cbd5e1") as the UnitCards
	var elem_color: Color = StatusScreen.ELEMENT_COLORS.get(skill.element, BattleFx.COLORS.get(skill.element, Color("cbd5e1")))
	_draw_para_flat(Rect2(0, 0, w, 38), 6.0, elem_color)
	draw_rect(Rect2(0, 0, 4, 38), LIME)

	# Watermark: translucent element SVG icon behind header (D-417, D-437)
	var elem_icon := _get_element_icon(skill.element)
	if elem_icon != null:
		var wm_sz := 48.0
		var wm_r := Rect2(Vector2(w - wm_sz + 6.0, -5.0), Vector2(wm_sz, wm_sz))
		var wm_col := Color("080e18", 0.16) if elem_color.get_luminance() > 0.55 else Color(1, 1, 1, 0.22)
		draw_texture_rect(elem_icon, wm_r, false, wm_col)

	# Title text
	var move_name := skill.display_name.to_upper()
	var title_size := 15
	var name_w := title_font.get_string_size(move_name, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	while title_size > 11 and name_w > 110.0:
		title_size -= 1
		name_w = title_font.get_string_size(move_name, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var title_color := INK if elem_color.get_luminance() > 0.55 else Color.WHITE
	draw_string(title_font, Vector2(12, 25), move_name, HORIZONTAL_ALIGNMENT_LEFT, 110.0, title_size, title_color)

	# 3 Icons at the TOP: 1) Element Icon, 2) Type Icon, 3) Range Icon (D-438)
	var bx := 12.0 + name_w + 6.0
	var badge_y := 10.0
	var badge_sz := 17.0

	# Icon 1: Element Glyph Badge
	if elem_icon != null:
		_draw_para_flat(Rect2(Vector2(bx, badge_y), Vector2(badge_sz, badge_sz)), 2.0, Color(0, 0, 0, 0.45))
		var e_glyph_col: Color = StatusScreen.ELEMENT_GLYPH_COLORS.get(skill.element, Color.WHITE)
		var gcol := Color.WHITE if elem_color.get_luminance() > 0.55 else e_glyph_col
		draw_texture_rect(elem_icon, Rect2(Vector2(bx + 2.0, badge_y + 2.0), Vector2(13.0, 13.0)), false, gcol)
		bx += badge_sz + 4.0

	# Icon 2: Type Badge (Physical, Magical, Guard, Dodge)
	var type_name := "magical"
	var type_col := Color("0ea5e9")
	var type_fg := Color.WHITE
	if skill.kind == Skill.Kind.MELEE or (skill.element == Element.Type.FISICO and skill.kind != Skill.Kind.STATUS):
		type_name = "physical"
		type_col = Color("ef4444")
		type_fg = Color.WHITE
	elif skill.display_name.to_lower() == "guard":
		type_name = "guard"
		type_col = Color("cbd5e1")
		type_fg = Color("080e18")
	elif skill.display_name.to_lower() == "teleport":
		type_name = "dodge"
		type_col = Color("fcb900")
		type_fg = Color("080e18")

	var badge_col := type_col
	if skill.data != null and skill.data.icon_color.a > 0.0:
		badge_col = skill.data.icon_color
	var type_ic := _get_type_icon(type_name)
	if skill.data != null:
		var move_ic: Texture2D = MoveIcons.for_move(skill.data.id)
		if move_ic != null:
			type_ic = move_ic
	if type_ic != null:
		_draw_para_flat(Rect2(Vector2(bx, badge_y), Vector2(badge_sz, badge_sz)), 2.0, badge_col)
		draw_texture_rect(type_ic, Rect2(Vector2(bx + 2.0, badge_y + 2.0), Vector2(13.0, 13.0)), false, type_fg)
		bx += badge_sz + 4.0

	# Icon 3: Range / Delivery Badge (Melee, Mid, Long, Area)
	var range_name := "mid"
	if skill.is_aoe:
		range_name = "area"
	elif skill.kind == Skill.Kind.MELEE:
		range_name = "melee"
	elif skill.kind == Skill.Kind.PROJECTILE:
		range_name = "long"

	var range_ic := _get_range_icon(range_name)
	if range_ic != null:
		_draw_para_flat(Rect2(Vector2(bx, badge_y), Vector2(badge_sz, badge_sz)), 2.0, Color.WHITE)
		draw_texture_rect(range_ic, Rect2(Vector2(bx + 2.0, badge_y + 2.0), Vector2(13.0, 13.0)), false, Color("080e18"))
		bx += badge_sz + 6.0



	# 3. Cost Row with Flat Chips (D-416, D-438, D-439: Wind-up alongside MP, solid flat color, no border)
	var cost_y := 43.0
	draw_string(font, Vector2(12, cost_y + 11), "ATB", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(CREAM, 0.6))
	var pip_w := 12.0
	var pip_h := 10.0
	var pip_x := 36.0
	for i in 5:
		var active := i < skill.cost
		var pcolor := CYAN if active else Color(0.14, 0.20, 0.28, 1.0)
		_draw_para_flat(Rect2(pip_x + i * (pip_w + 4.0), cost_y + 2, pip_w, pip_h), 2.5, pcolor)

	# Flat MP Chip (No border, solid flat color - D-439)
	var mp_str := "%d MP" % skill.mp_cost
	var mp_w := font.get_string_size(mp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 10.0
	var mp_x := w - mp_w - 12.0
	var mp_bg := Color("0284c7") if skill.mp_cost > 0 else Color(0.12, 0.18, 0.25, 0.95)
	var mp_fg := Color.WHITE if skill.mp_cost > 0 else Color(CREAM, 0.6)
	_draw_para_flat(Rect2(mp_x, cost_y, mp_w, 15), 2.0, mp_bg)
	draw_string(font, Vector2(mp_x + 5, cost_y + 11), mp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, mp_fg)

	# Flat Wind-up Chip alongside MP (Hourglass + value, No border, solid flat color - D-439)
	var wu_str := "⏳ %.2fs" % skill.windup
	var wu_w := font.get_string_size(wu_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 10.0
	var wu_x := mp_x - wu_w - 6.0
	var wu_bg := Color("b45309")
	_draw_para_flat(Rect2(wu_x, cost_y, wu_w, 15), 2.0, wu_bg)
	draw_string(font, Vector2(wu_x + 5, cost_y + 11), wu_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("fffbeb"))

	# 4. Target & Damage Forecast Box (y: 64..112)
	var tbox_y := 64.0
	var tbox_h := 48.0
	_draw_para_flat(Rect2(10, tbox_y, w - 20, tbox_h), 3.0, Color(0.06, 0.10, 0.16, 0.95), Color(0.18, 0.28, 0.40, 0.7))

	# Target Name & Current HP
	var target_str := "ALL ALLIES" if skill.is_friendly else (target.name.to_upper() if target != null else "NO TARGET")
	draw_string(font, Vector2(18, tbox_y + 15), "TARGET: " + target_str, HORIZONTAL_ALIGNMENT_LEFT, 155, 10, CREAM)
	if target != null and not skill.is_friendly:
		var hp_str := "HP %d/%d" % [target.hp, target.max_hp]
		draw_string(font, Vector2(w - 20 - font.get_string_size(hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x, tbox_y + 15), hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(CREAM, 0.6))

	# Forecast Damage & Modifiers
	if skill.is_friendly or skill.kind == Skill.Kind.STATUS:
		var s_fc := Skill.status_forecast(skill, caster) if caster != null else skill.effect_line()
		draw_string(font, Vector2(18, tbox_y + 32), s_fc, HORIZONTAL_ALIGNMENT_LEFT, w - 36.0, 9, GOLD)
	elif target != null:
		var raw := Battle.estimate_damage(caster, target, skill) if caster != null and battle != null else int(skill.power * 10)
		var is_weak := skill.element in target.weaknesses
		var dmg_str := "~%d DMG" % raw
		draw_string(font, Vector2(18, tbox_y + 33), dmg_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GOLD)

		var tag_x := 18.0 + font.get_string_size(dmg_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 8.0
		if is_weak:
			_draw_para_flat(Rect2(tag_x, tbox_y + 22, 62, 14), 2.0, AMBER)
			draw_string(font, Vector2(tag_x + 5, tbox_y + 32), "WEAK 1.5×", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, INK)
		elif target.is_guarding() and _breaks_guard(skill):
			_draw_para_flat(Rect2(tag_x, tbox_y + 22, 76, 14), 2.0, CORAL)
			draw_string(font, Vector2(tag_x + 4, tbox_y + 32), "GUARD BREAK", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, INK)

		# Mini HP Forecast Bar
		var bar_x := 18.0
		var bar_y := tbox_y + 40.0
		var bar_w := w - 36.0
		var max_h := float(maxi(target.max_hp, 1))
		var cur_pct := clampf(float(target.hp) / max_h, 0.0, 1.0)
		var post_pct := clampf(float(maxi(0, target.hp - raw)) / max_h, 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w, 3), Color(0.12, 0.16, 0.22, 1.0))
		draw_rect(Rect2(bar_x, bar_y, bar_w * cur_pct, 3), Color(GOLD, 0.7))
		draw_rect(Rect2(bar_x, bar_y, bar_w * post_pct, 3), CORAL)

	# 5. Rich Move Mechanics & Details (D-420, D-436, D-437, D-439)
	var text_y := 111.0
	var text_w := w - 24.0

	# Line 1: Rich mechanics description
	var mech_desc := skill.mechanics_description()
	var next_y := _draw_wrapped_text(font, Vector2(12, text_y + 10), mech_desc, text_w, 9, 2.5, CREAM)

	# Line 2: Kinematic motion / delivery summary
	var motion_desc := skill.visual_motion_summary()
	next_y = _draw_wrapped_text(font, Vector2(12, maxf(next_y + 3.0, text_y + 34.0)), motion_desc, text_w, 9, 2.5, Color(CREAM, 0.8))

	# Line 3: Attribute scaling (Wind-up is already in cost row at top - D-439)
	var stat_name := "MAG" if (skill.element != Element.Type.FISICO and skill.kind != Skill.Kind.MELEE) else "STR"
	var scale_desc := "Scales with %s (%d%%)" % [stat_name, int(round(skill.power * 100.0))] if skill.kind != Skill.Kind.STATUS else "Fixed status potency"
	draw_string(font, Vector2(12, maxf(next_y + 3.0, text_y + 58.0)), scale_desc, HORIZONTAL_ALIGNMENT_LEFT, text_w, 9, AQUA)

	# Subtle bottom accent footer (D-439: compact at h - 14)
	draw_rect(Rect2(10, h - 16, w - 20, 1), Color(BORDER_COLOR, 0.35))
	draw_string(font, Vector2(12, h - 6), "ACTION PREVIEW // CRAWLMON BATTLE HUD", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(CREAM, 0.3))


func _alive_allies() -> Array[String]:
	var names: Array[String] = []
	if battle == null:
		return names
	var team: Array = battle.party if caster != null and caster.is_player else battle.enemies
	for a in team:
		if a != null and a.is_alive():
			names.append(a.name)
	return names


func _forecast() -> String:
	if caster == null:
		return skill.effect_line()
	if skill.is_friendly or skill.kind == Skill.Kind.STATUS:
		return Skill.status_forecast(skill, caster)
	if target == null or battle == null:
		return "—"
	if target.is_invulnerable_target():
		return "Untargetable | 0 damage (Teleport/Dig)"
	var raw := Battle.estimate_damage(caster, target, skill)
	var weak := skill.element in target.weaknesses
	var text := "~%d%s (no crit)" % [raw, " | WEAK" if weak else ""]
	if caster.is_blind():
		text += " | 35% miss (blind)"
	if target.is_guarding():
		if _breaks_guard(skill):
			text += " | BREAKS Guard (+1 ATB)"
		else:
			raw = maxi(1, ceili(float(raw) * (1.0 - Battle.GUARD_REDUCTION)))
			text += " | Guard cuts to %d and breaks" % raw
	if target.is_shielded():
		var absorbed := mini(raw, target.shield_hp)
		var hp := raw - absorbed
		text += " | shield absorbs %d" % absorbed
		if absorbed >= target.shield_hp:
			text += " and BREAKS"
		text += " | HP -%d" % hp
	else:
		text += " | HP -%d" % raw
	return text


func _incoming() -> String:
	if battle == null or target == null:
		return ""
	var bits: Array[String] = []
	for inc in battle.active_attacks():
		if inc.ghost:
			continue
		if inc.attacker == target:
			bits.append("%s → %s in %.1fs" % [inc.label, inc.target.name if inc.target != null else "?", inc.eta()])
		elif inc.target == target and not inc.dodged:
			bits.append("incoming %s from %s in %.1fs" % [inc.label, inc.attacker.name, inc.eta()])
		if bits.size() >= 2:
			break
	return " | ".join(bits)
