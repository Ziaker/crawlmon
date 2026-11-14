class_name MoveInspectInfo
extends RefCounted
## Texts of the Move inspection computed from the REAL Skill/MoveData (D-1192, prototype D-1185).
## The prototype INSPECT JSON was generated from content/moves/*/move.tres; nothing is copied from it.

const StatusScreenScript := preload("res://scripts/ui/status_screen.gd")

const STATUS_WINDUP := 0.5  ## battle.gd::STATUS_WINDUP (D-031).
const WINDUP := 1.5  ## battle.gd::WINDUP.
const STATUS_VFX_TAIL := 1.0  ## battle.gd::STATUS_VFX_TAIL; with no explicit pause the total is windup + tail.

const AQUA := Color("63d9ec")
const LIME := Color("d6fa66")
const CORAL := Color("ff746c")
const GOLD := Color("f0c57e")
const GRAY := Color("94a3b8")
const PAPER := Color("e2e8f0")
const HP_COLOR := Color("e96159")
const MP_COLOR := Color("38bdf8")

const STAT_COLORS := {
	"STR": Color("ff746c"),
	"MAG": Color("b5a5fe"),
	"VIT": Color("7ee081"),
	"WIS": Color("63d9ec"),
	"AGI": Color("f0c57e"),
	"LUK": Color("d6fa66"),
}

const STAT_FULL := {
	"Strength": "STR",
	"Magic": "MAG",
	"Vitality": "VIT",
	"Wisdom": "WIS",
	"Agility": "AGI",
	"Luck": "LUK",
}

## Same element association as ELEMENT_ICON_KEYS in exploration_battle_hud.gd, in the prototype EL casing.
const ELEMENT_KEYS := {
	Element.Type.FISICO: "NEUTRAL",
	Element.Type.FOGO: "FIRE",
	Element.Type.AGUA_GELO: "WATER",
	Element.Type.RAIO: "ELECTRIC",
	Element.Type.PSIQUICO: "PSYCHIC",
	Element.Type.VENENO: "NATURE",
	Element.Type.SOM: "SOUND",
	Element.Type.TERRA: "EARTH",
	Element.Type.VENTO: "WIND",
	Element.Type.LUZ: "LIGHT",
	Element.Type.TREVAS: "DARK",
	Element.Type.MYSTIC: "MYSTIC",
}

const HL_PATTERN := "(\\b(?:STR|MAG|VIT|WIS|AGI|LUK)\\b)|(\\b(?:Strength|Wisdom|Magic|Vitality|Agility|Luck)\\b)|(\\d+(?:[.,]\\d+)?\\s?s\\b)|([+-]?\\d+(?:[.,]\\d+)?%|×\\s?\\d+(?:[.,]\\d+)?|x\\d+(?:[.,]\\d+)?)|(\\b(?:STUN|BURN|ARMOR|Guard|GUARD|Burst|K\\.O\\.)\\b)|(\\bHP\\b)|(\\bMP\\b)|(\\bATB\\b)"

## Round 13 mechanics, keyed by REAL move ids (prototype keys mapped by display_name).
const MECH := {
	"confusao": [],
	"raio_psiquico": [],
	"onda_choque": ["If it is dodged, the impact still shows but deals no damage."],
	"teleporte_rapido": ["The user can't be hit during the strike: attacks on it miss."],
	"media": ["Heals 10 + MAG HP on every living ally (up to max HP)."],
	"sukunda": ["-1 SPD on one enemy, down to -5. Lasts the whole battle."],
	"sukukaja": ["+1 SPD on every living ally, up to +5. Lasts the whole battle."],
	"tarukaja": ["+1 ATK on every living ally, up to +5. Lasts the whole battle.", "ATK buffs raise physical damage only."],
	"megido": ["Hits every enemy."],
	"hassou_tobi": ["Hits every enemy."],
	"heal": ["Its effect is not implemented in battle yet: it does nothing."],
	"electric_beam": ["On hit: 20% + (user LUK − target LUK)% chance to STUN the target for 4 s."],
	"soco_rapido": ["Wind-up of only 0.2 s: good for hitting an enemy in its wind-up."],
	"golpe_carate": ["On hit: 30% chance of -1 SPD on the target (down to -5)."],
	"quebra_telha": ["Breaks the target's Guard."],
	"provocacao": ["The target's next attack goes to the user.", "Attacks it already aimed at someone else are redirected to the user."],
	"war_cry": ["Interrupts every enemy in wind-up; their ATB is not refunded.", "+1 Burst if it interrupts at least one (once per use). No damage."],
}

const PLANNED := {
	"confusao": ["Planned (D-1187): 20% + LUK chance to cause Confusion. Not active yet."],
}

const TIPS := {
	"MAG": ["MAGICAL", "Uses the user's MAG. The target's WIS reduces it."],
	"PHY": ["PHYSICAL", "Uses the user's STR. ATK buffs (Tarukaja) raise it."],
	"status": ["STATUS", "Status Move: no damage, can't be dodged. It pauses the battle while it resolves."],
	"FIELD": ["FIELD", "Field Move."],
	"rg:melee": ["MELEE", "The user runs to the target and strikes it up close."],
	"rg:mid": ["MID RANGE", "Cast on the target from where the user stands."],
	"rg:long": ["LONG RANGE", "A projectile or beam fired from where the user stands."],
	"rg:area": ["AREA", "Hits every enemy at once."],
}

static var _hl_regex: RegEx = null


## battle.gd line 276: an explicit windup wins; otherwise 0.5 s for status and 1.5 s for attacks.
static func effective_windup(s: Skill) -> float:
	if s == null:
		return 0.0
	if s.windup >= 0.0:
		return s.windup
	return STATUS_WINDUP if s.kind == Skill.Kind.STATUS else WINDUP


## Status pause length used by the engine: explicit MoveData.status_pause, else windup + the VFX tail.
## Media has no status_pause in its .tres, so this gives 0.5 + 1.0 = 1.5 s like the prototype JSON.
static func engine_pause(s: Skill) -> float:
	if s == null or s.kind != Skill.Kind.STATUS:
		return 0.0
	if s.data != null and s.data.status_pause >= 0.0:
		return s.data.status_pause
	return effective_windup(s) + STATUS_VFX_TAIL


## effect_line() split on the pipe, stripped, without the bare "<n> ATB" cost parts.
static func effect_lines(s: Skill) -> Array[String]:
	var out: Array[String] = []
	if s == null:
		return out
	var atb_re := RegEx.new()
	atb_re.compile("^\\d+ ATB$")
	for part in s.effect_line().split("|"):
		var text := part.strip_edges()
		if text == "":
			continue
		if atb_re.search(text) != null:
			continue
		out.append(text)
	return out


## "STATUS"/"MAG"/"PHY" (prototype line 357).
static func type_key(s: Skill) -> String:
	if s == null:
		return "PHY"
	if s.kind == Skill.Kind.STATUS:
		return "STATUS"
	return "MAG" if s.is_magical() else "PHY"


## ""/"area"/"melee"/"long"/"mid" from kind/aoe (prototype line 358).
static func range_key(s: Skill) -> String:
	if s == null or s.kind == Skill.Kind.STATUS:
		return ""
	if s.is_aoe:
		return "area"
	match s.kind:
		Skill.Kind.MELEE:
			return "melee"
		Skill.Kind.PROJECTILE:
			return "long"
		_:
			return "mid"


## "" for status, otherwise the power formatted as the prototype ("1,4", "1,5", "2,0").
static func power_text(s: Skill) -> String:
	if s == null or s.kind == Skill.Kind.STATUS:
		return ""
	return _fmt(s.power)


## valsHTML (prototype 667-686): TARGET, WIND-UP, ENGINE PAUSE (status), SCALES and tag extras.
static func vals(s: Skill) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if s == null:
		return out
	var status := s.kind == Skill.Kind.STATUS

	var target := "ONE ENEMY"
	if s.is_friendly:
		target = "ALL ALLIES" if s.is_aoe else "ONE ALLY"
	elif s.is_aoe:
		target = "ALL ENEMIES"
	out.append({"label": "TARGET", "value": target, "color": PAPER, "wide": true})

	out.append({"label": "WIND-UP", "value": "%s s" % _fmt(effective_windup(s)), "color": AQUA, "wide": false})

	if status:
		var pause := engine_pause(s)
		out.append({
			"label": "ENGINE PAUSE",
			"value": ("%s s" % _fmt(pause)) if pause > 0.0 else "NONE",
			"color": AQUA if pause > 0.0 else GRAY,
			"wide": false,
		})

	if not status:
		var scale := "MAG" if s.is_magical() else "STR"
		out.append({"label": "SCALES", "value": scale, "color": _stat_color(scale), "wide": false})

	if _has_tag(s, &"stun"):
		out.append({"label": "ON HIT", "value": "STUN", "color": CORAL, "wide": false})
	if _has_tag(s, &"guard_break"):
		out.append({"label": "BREAKS", "value": "GUARD", "color": CORAL, "wide": false})
	if _has_tag(s, &"untargetable"):
		out.append({"label": "DURING", "value": "UNTARGETABLE", "color": LIME, "wide": false})
	if s.data != null and s.data.bypass_def:
		out.append({"label": "IGNORES", "value": "DEFENSE", "color": CORAL, "wide": false})

	return out


## MECH + PLANNED for the real move id; each entry says whether it is a planned (not active) line.
static func mech_effect(s: Skill) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if s == null:
		return out
	var id := _move_id(s)
	var own: Array = MECH.get(id, [])
	for text in own:
		out.append({"text": String(text), "planned": false})
	var planned: Array = PLANNED.get(id, [])
	for text in planned:
		out.append({"text": String(text), "planned": true})
	return out


## mechHTML COMBAT RULES (prototype 727-736).
static func combat_rules(s: Skill) -> Array[String]:
	var out: Array[String] = []
	if s == null:
		return out
	if s.kind != Skill.Kind.STATUS:
		var first := "If the user is hit during the wind-up, the Move is cancelled and its ATB is lost."
		if s.kind == Skill.Kind.PROJECTILE:
			first += " Once fired, hitting the user no longer stops it."
		out.append(first)
		out.append("Dodge: manual Evade in the last 0.25 s before contact; 10% auto-dodge.")
		out.append("10% crit for ×2 damage. Weak target ×1.5, Resist ×0.5. Guard halves it.")
		if s.is_magical():
			out.append("The target's WIS reduces it: ×10/(10+WIS).")
	else:
		out.append("Can't be dodged.")
		var pause := engine_pause(s)
		if pause > 0.0:
			out.append("The battle pauses for %s s while it resolves." % _fmt(pause))
		else:
			out.append("It does not pause the battle.")
	return out


## forecast() (prototype 689-702) using the combatant's real effective STR/MAG.
static func forecast(s: Skill, c: Combatant) -> String:
	if s == null:
		return ""
	if s.kind != Skill.Kind.STATUS:
		var stat_name := "MAG" if s.is_magical() else "STR"
		var value := 0
		if c != null:
			value = c.get_effective_stat(stat_name)
		var target := ", on every enemy." if s.is_aoe else ", on one target."
		return "Damage = %d%% of %s (%s %d)%s" % [roundi(s.power * 100.0), stat_name, stat_name, value, target]

	var effect := s.effect_line()
	var text := ""
	if effect.contains("10 + MAG"):
		var mag_value := 0
		if c != null:
			mag_value = c.get_effective_stat("MAG")
		text = "Heals 10 + MAG = %d HP on each living ally." % (10 + mag_value)
	else:
		text = ". ".join(PackedStringArray(effect_lines(s))) + "."
	if effect.to_lower().contains("not implemented"):
		text += " This effect does not work in battle yet."
	var pause := engine_pause(s)
	if pause > 0.0:
		text += " The battle engine pauses for %s s while it resolves." % _fmt(pause)
	return text


## LOOK / MOTION & DISPLACEMENT / WIND-UP POSTURE from the real move sheet.
static func visual_sections(s: Skill) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if s == null:
		return out
	out.append({"title": "LOOK", "text": s.visual_description()})
	out.append({"title": "MOTION & DISPLACEMENT", "text": s.motion_description()})
	var posture := _posture(s.windup_description())
	if posture != "":
		out.append({"title": "WIND-UP POSTURE", "text": posture})
	return out


## TIPS/tipText (prototype 742-756): [title, body]; "el:<NAME>" builds the element sentence.
static func tip(key: String) -> Array[String]:
	var out: Array[String] = []
	if key.begins_with("el:"):
		var element_name := key.substr(3)
		var title := element_name
		if not element_name.is_empty():
			title = element_name.substr(0, 1) + element_name.substr(1).to_lower()
		out.append(element_name)
		out.append("%s element. A target weak to it takes ×1.5; a resistant one takes ×0.5." % title)
		return out
	var entry: Array = TIPS.get(key, [key, ""])
	out.append(String(entry[0]))
	out.append(String(entry[1]))
	return out


## hl() (prototype 659-665) as segments; plain text is transparent and not bold.
## The concatenation of every segment text is exactly the input text.
static func highlight(text: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if text.is_empty():
		return out
	var re := _highlight_regex()
	var cursor := 0
	for hit in re.search_all(text):
		var start := hit.get_start()
		if start > cursor:
			out.append({"text": text.substr(cursor, start - cursor), "color": Color(0, 0, 0, 0), "bold": false})
		var color := Color(0, 0, 0, 0)
		if hit.get_string(1) != "":
			color = _stat_color(hit.get_string(1))
		elif hit.get_string(2) != "":
			color = _stat_color(String(STAT_FULL.get(hit.get_string(2), "STR")))
		elif hit.get_string(3) != "":
			color = AQUA
		elif hit.get_string(4) != "":
			color = GOLD
		elif hit.get_string(5) != "":
			color = CORAL
		elif hit.get_string(6) != "":
			color = HP_COLOR
		elif hit.get_string(7) != "":
			color = MP_COLOR
		elif hit.get_string(8) != "":
			color = AQUA
		out.append({"text": hit.get_string(), "color": color, "bold": true})
		cursor = hit.get_end()
	if cursor < text.length():
		out.append({"text": text.substr(cursor), "color": Color(0, 0, 0, 0), "bold": false})
	return out


## Prototype EL key ("PSYCHIC", "ELECTRIC", ...); FISICO is "NEUTRAL" like the icon map.
static func element_key(e: Element.Type) -> String:
	return str(ELEMENT_KEYS.get(e, "NEUTRAL"))


## status_screen.gd::ELEMENT_COLORS.
static func element_color(e: Element.Type) -> Color:
	var color: Color = StatusScreenScript.ELEMENT_COLORS.get(e, Color("cbd5e1"))
	return color


static func _posture(windup_text: String) -> String:
	var body := windup_text.strip_edges()
	var prefix := RegEx.new()
	prefix.compile("^\\s*(?:\\d+(?:[.,]\\d+)?\\s*s\\s+wind-up|[Ii]nstant wind-up)\\s*\\.\\s*")
	body = prefix.sub(body, "", false)
	var timing := RegEx.new()
	timing.compile("^\\d+(?:[.,]\\d+)?\\s*s\\s+[^.]*\\.\\s*")
	body = timing.sub(body, "", false)
	body = body.strip_edges()
	var semicolon := body.find(";")
	if semicolon >= 0:
		body = body.substr(0, semicolon).strip_edges()
	if body.is_empty():
		return ""
	if not body.ends_with(".") and not body.ends_with("!") and not body.ends_with("?"):
		body += "."
	return body


static func _move_id(s: Skill) -> String:
	if s == null:
		return ""
	if s.data != null:
		return String(s.data.id)
	return BattleSpace.move_id(s.display_name)


static func _has_tag(s: Skill, tag: StringName) -> bool:
	return s.data != null and s.data.tags.has(tag)


static func _stat_color(stat: String) -> Color:
	var color: Color = STAT_COLORS.get(stat, PAPER)
	return color


static func _highlight_regex() -> RegEx:
	if _hl_regex == null:
		_hl_regex = RegEx.new()
		_hl_regex.compile(HL_PATTERN)
	return _hl_regex


static func _fmt(value: float) -> String:
	var text := "%.2f" % value
	if text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	return text.replace(".", ",")
