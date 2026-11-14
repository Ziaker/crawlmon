class_name KnockEcho
extends Control
## D-1205: the eco textual "KNOCK-UP" (option 1 of prototypes/knockup_card_eco/index.html, approved by the creator).
## Flat, saturated, no borders (D-1061). Drawn in the HUD layer (2D), so it sits IN FRONT of the target's card (creator: it was behind).
## The letters leave the body already separate, scatter wide, hold, then snap together crooked above the card, with a comic "hit" (flat
## coral star), and fade. Plays `SPEED` times faster than the flight (`air`). Nothing depends on a character, team or side (D-235).
##   0-9 %    letters appear small ON the body, then fly to the card (0-46 %)   46 %  scattered, 1.14x, rotated     54 %  still scattered
##   64 %     snap into the word at 1.36x              72 %  0.90x   80 %  1.07x   90 %  1.0x   100 %  gone (fade 90-100 %)
##   55-100 % flat star pops behind the word           58-78 %  the word shakes once (the hit)

const WORD := "KNOCK-UP"
const FONT_NAMES := ["Impact", "Arial Black"]
const LETTER_COLOR := Color(1.0, 0.90, 0.0)  ## #ffe600, flat
const STAR_COLOR := Color(1.0, 0.353, 0.373)  ## #ff5a5f, flat coral
const LETTER_PX := 29.92  ## letter height in HUD pixels (was 44, then 37.4: creator asked 15% and then 20% smaller)
const SCATTER := 2.8  ## scatter radius in letter-sizes
const ANGLE_OFFSET := 0.8
const SPEED := 2.0  ## how many times faster than the Knock-up flight the whole echo plays (creator: "mais rápido ainda")
const CARD_LIFT_PX := 46.0  ## the word sits this many HUD pixels above the card's top edge
const HOLD_EXTRA := 0.5  ## seconds the finished word stays in the scene before it fades (creator: "mais meio segundo")
const HOLD_AT := 0.90  ## animation point where the word is complete and the hold starts
const TILT_DEG := -9.0  ## the joined word is crooked (creator: "se formar torto")

const STAR := [
	Vector2(50, 0), Vector2(58, 18), Vector2(76, 8), Vector2(70, 27), Vector2(92, 22), Vector2(79, 39), Vector2(100, 50),
	Vector2(79, 61), Vector2(92, 78), Vector2(70, 73), Vector2(76, 92), Vector2(58, 82), Vector2(50, 100), Vector2(42, 82),
	Vector2(24, 92), Vector2(30, 73), Vector2(8, 78), Vector2(21, 61), Vector2(0, 50), Vector2(21, 39), Vector2(8, 22),
	Vector2(30, 27), Vector2(24, 8), Vector2(42, 18),
]

static var _font: Font

var air := 1.3
var _t := 0.0
var _anchor := Vector2.ZERO  ## where the word forms (HUD px)
var _from := Vector2.ZERO  ## where the letters leave from (the body, HUD px)
var _letters: Array[Dictionary] = []  ## {ch, w, from, scat, word, rot}


## Spawns the echo in the HUD. `anchor_screen`: where the word forms (above the card); `body_screen`: where the letters leave from.
static func spawn(hud: Control, anchor_screen: Vector2, body_screen: Vector2, p_air: float = 1.3) -> KnockEcho:
	var e := KnockEcho.new()
	e.name = "KnockEcho"
	e.air = maxf(p_air, 0.3)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	e.z_index = 100
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(e)
	e._build(anchor_screen + Vector2(0.0, -CARD_LIFT_PX), body_screen)
	return e


func _build(anchor: Vector2, body: Vector2) -> void:
	_anchor = anchor
	_from = body
	var font := _text_font()
	var n := WORD.length()
	var widths: Array[float] = []
	var total := 0.0
	for i in n:
		var w := font.get_string_size(WORD[i], HORIZONTAL_ALIGNMENT_LEFT, -1, int(LETTER_PX / 0.79)).x
		widths.append(w)
		total += w + 1.0
	var x := -total * 0.5
	var tilt := deg_to_rad(TILT_DEG)
	for i in n:
		var cx := x + widths[i] * 0.5
		x += widths[i] + 1.0
		var word_pos := anchor + Vector2(cx, 0.0).rotated(tilt)
		var angle := float(i) / float(n) * TAU + ANGLE_OFFSET
		var dist := SCATTER * LETTER_PX * (0.82 + float((i * 19) % 40) / 100.0)
		var scat := anchor + Vector2(cos(angle) * dist, sin(angle) * dist * 0.6 - 0.13 * LETTER_PX)
		var from := body + Vector2(-(float(i) - float(n - 1) * 0.5) * 0.9 * LETTER_PX, 0.0)
		var rot := deg_to_rad((float((i * 53) % 100) - 50.0) / 100.0 * 60.0)
		_letters.append({"ch": WORD[i], "w": widths[i], "from": from, "scat": scat, "word": word_pos, "rot": rot})


func _process(delta: float) -> void:
	_t += delta
	if _word_p() >= 1.0:
		queue_free()
		return
	queue_redraw()


## Animation point of the letters: normal speed, but frozen at HOLD_AT for HOLD_EXTRA seconds (the word stays in the scene).
func _word_p() -> float:
	var run := air / SPEED
	var t_hold := HOLD_AT * run
	if _t < t_hold:
		return _t / run
	if _t < t_hold + HOLD_EXTRA:
		return HOLD_AT
	return HOLD_AT + (_t - t_hold - HOLD_EXTRA) / run


## Piecewise-linear keyframes: keys = [[p0, v0], [p1, v1], ...].
static func _key(p: float, keys: Array) -> float:
	if p <= float(keys[0][0]):
		return float(keys[0][1])
	for j in range(1, keys.size()):
		if p <= float(keys[j][0]):
			var a: Array = keys[j - 1]
			var b: Array = keys[j]
			var k := (p - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			return lerpf(float(a[1]), float(b[1]), k)
	return float(keys[keys.size() - 1][1])


func _draw() -> void:
	var p := clampf(_word_p(), 0.0, 1.0)
	var ps := clampf(_t * SPEED / air, 0.0, 1.0)  # the star keeps its own clock (no hold)
	var to_scat := 1.0 - pow(1.0 - clampf(p / 0.55, 0.0, 1.0), 3.0)
	var kw := clampf((p - 0.60) / 0.08, 0.0, 1.0)
	var to_word := kw * kw * (3.0 - 2.0 * kw)
	var scale_v := _key(p, [[0.0, 0.25], [0.55, 1.14], [0.60, 1.06], [0.64, 1.36], [0.72, 0.90], [0.80, 1.07], [0.90, 1.0], [1.0, 1.0]])
	var alpha := _key(p, [[0.0, 0.0], [0.09, 1.0], [0.90, 1.0], [1.0, 0.0]])
	var shake := Vector2.ZERO
	var tilt := deg_to_rad(TILT_DEG)
	if p > 0.58 and p < 0.78:
		var s := (p - 0.58) / 0.20
		shake = Vector2(0.0, sin(s * TAU * 2.0) * 0.06 * LETTER_PX * (1.0 - s))
		tilt += sin(s * TAU * 2.0) * deg_to_rad(1.5) * (1.0 - s)
	# the star, behind the word
	var sa := _key(ps, [[0.0, 0.0], [0.55, 0.0], [0.62, 1.0], [0.70, 0.95], [0.84, 0.45], [1.0, 0.0]])
	if sa > 0.01:
		var ss := _key(ps, [[0.0, 0.15], [0.55, 0.15], [0.62, 1.12], [0.70, 1.26], [0.84, 1.06], [1.0, 0.94]])
		var srot := deg_to_rad(_key(ps, [[0.55, 0.0], [0.62, 3.0], [0.70, 5.0], [1.0, 0.0]]))
		draw_set_transform(_anchor, srot, Vector2.ONE * LETTER_PX * 5.0 * ss)
		var pts := PackedVector2Array()
		for pt in STAR:
			pts.append(Vector2((pt.x - 50.0) / 100.0, (pt.y - 50.0) / 100.0))
		draw_colored_polygon(pts, Color(STAR_COLOR, sa))
	var font := _text_font()
	var fs := int(LETTER_PX / 0.79)
	for L in _letters:
		var pos: Vector2 = (L["from"] as Vector2).lerp(L["scat"], to_scat)
		pos = pos.lerp(L["word"], to_word) + shake
		var rot := float(L["rot"]) * to_scat * (1.0 - to_word) + tilt * to_word
		draw_set_transform(pos, rot, Vector2.ONE * scale_v)
		var w := float(L["w"])
		draw_string(font, Vector2(-w * 0.5, LETTER_PX * 0.5), String(L["ch"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(LETTER_COLOR, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _text_font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(FONT_NAMES)
		_font = f
	return _font
