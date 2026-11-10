class_name HealGainMark
extends Control
## D-343/D-347: the option 2 "Persona Kinetic Cross" heal gain, drawn exactly as the HTML
## prototype (Kanit Black Italic, asymmetric cross, flat dark cut, tactical underline). D-347 moved
## it off the character and above the owner's HP card/tag: it appears outside the card, near the
## HP, tilted right on an enemy and left on an ally, drifting diagonally up in that same direction
## and fading in/out over 1.4 s. The green crosses stay a separate 3D VFX (HealGainFx) at the
## character, as the creator chose.

const FONT_PATH := "res://assets/fonts/kanit/Kanit-BlackItalic.ttf"
const RENDER_SCALE := 3.0
const FONT_SIZE := 62.0
const SCREEN_HEIGHT := 0.11  ## share of the viewport height; above a card, not inside it
const LIFE := 1.4
const FADE_OUT_START := 1.05
const FADE_OUT_TIME := 0.35
const ROT_DEG := 6.0  ## enemy: clockwise (right); ally: counter-clockwise (left)
const CARD_GAP := 4.0  ## the mark's bottom stays this far above the card
const INWARD_X := 26.0  ## near the HP, towards the battlefield centre
const END_OFFSET := Vector2(12.0, -16.0)  ## gentle diagonal climb, mirrored by side

const COL_DIGITS := Color("b7ffc9")
const COL_CROSS := Color("a8ffc4")
const COL_CUT := Color("08150e")
const COL_WHITE := Color("f4fff7")

static var _font_cache: FontVariation

var value := 0
var _top_center := Vector2.ZERO
var _dir := 1.0  ## +1 enemy (right), -1 ally (left)
var _inward := 1.0  ## +1 card on the left half, -1 on the right half
var _t := 0.0
var _anchor := Vector2.ZERO
var _start := Vector2.ZERO
var _end := Vector2.ZERO
var _viewport: SubViewport
var _rect: TextureRect
var _tex_size := Vector2i(320, 200)


# --- Factory -------------------------------------------------------------------------


## `top_center` is the top-center of the owner's HP card/tag. The mark is born just above the card,
## outside it and near the HP, in front of it and visible from the first frame (D-348). `enemy`
## picks the tilt and the diagonal direction; `inward` keeps the number near the HP.
static func spawn(parent: Control, top_center: Vector2, amount: int, enemy: bool, inward: float) -> HealGainMark:
	var mark := HealGainMark.new()
	mark.value = amount
	mark._top_center = top_center
	mark._dir = 1.0 if enemy else -1.0
	mark._inward = inward
	parent.add_child(mark)
	return mark


## The Kanit instance used by both the measure and the drawing.
static func font() -> FontVariation:
	if _font_cache == null:
		var base := load(FONT_PATH) as FontFile
		if base == null:
			# Never break the battle because a font is missing: the fallback still shows the value.
			var fallback := FontVariation.new()
			fallback.base_font = ThemeDB.fallback_font
			_font_cache = fallback
		else:
			var fv := FontVariation.new()
			fv.base_font = base
			fv.spacing_glyph = -int(round(2.0 * RENDER_SCALE))  # letter-spacing: -2px in the HTML
			fv.variation_opentype = {"tnum": 1}  # font-variant-numeric: tabular-nums
			_font_cache = fv
	return _font_cache


# --- Lifecycle -----------------------------------------------------------------------


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var measured := HealGainArt.measure(font(), value, RENDER_SCALE)
	_tex_size = measured["size"]
	var aspect := float(_tex_size.x) / float(_tex_size.y)
	var h := get_viewport_rect().size.y * SCREEN_HEIGHT
	var w := h * aspect
	size = Vector2(w, h)
	pivot_offset = size * 0.5
	# D-348: born outside the card, near the HP and in front of it, visible immediately.
	_start = Vector2(_top_center.x + INWARD_X * _inward, _top_center.y - CARD_GAP - h * 0.5)
	_end = _start + Vector2(END_OFFSET.x * _dir, END_OFFSET.y)
	position = _start - size * 0.5
	# The art already carries the HTML skewX(-4deg); this makes the final drawing lean ±6°.
	rotation = deg_to_rad(ROT_DEG * _dir + 4.0)
	modulate.a = 1.0

	_viewport = SubViewport.new()
	_viewport.size = _tex_size
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(_viewport)

	var art := HealGainArt.new()
	art.setup(value, font(), float(measured["pad"]), RENDER_SCALE)
	_viewport.add_child(art)

	# The rect exists from the first frame (D-348: visible from the start); the viewport is
	# rendered once and then disabled.
	_rect = TextureRect.new()
	_rect.texture = _viewport.get_texture()
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_viewport):
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / LIFE, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 2.0)
	position = _start.lerp(_end, e) - size * 0.5
	modulate.a = 1.0 - clampf((_t - FADE_OUT_START) / FADE_OUT_TIME, 0.0, 1.0)
	if _t >= LIFE:
		queue_free()


# --- The exact option 2 drawing ------------------------------------------------------


class HealGainArt:
	extends Node2D
	## Draws the HTML option 2 markup on a transparent viewport. The Node2D skew is the CSS
	## `transform: skewX(-4deg)`; the row/underline geometry follows the HTML values scaled by
	## RENDER_SCALE. The font size 62 and the -2px letter spacing are the prototype's.

	const FONT_SIZE := 62.0
	const COL_DIGITS := Color("b7ffc9")
	const COL_CROSS := Color("a8ffc4")
	const COL_CUT := Color("08150e")
	const COL_WHITE := Color("f4fff7")

	var value := 0
	var font: Font
	var pad := 0.0
	var scale_k := 3.0
	var text := ""
	var text_w := 0.0
	var cross_w := 0.0
	var cross_h := 0.0
	var row_w := 0.0
	var row_h := 0.0


	static func measure(p_font: Font, p_value: int, s: float) -> Dictionary:
		var fs := FONT_SIZE * s
		var t := str(p_value)
		var tw := p_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var cw := 38.0 * s
		var ch := 44.0 * s
		var rh := maxf(ch, fs * 0.82)
		var tx := cw - 4.0 * s
		var rw := tx + tw
		var th := rh + 3.0 * s + 6.0 * s
		var px := 12.0 * s
		var py := 11.0 * s
		var size := Vector2i(ceili(rw + px * 2.0 + 4.0 * s), ceili(th + py * 2.0 + 4.0 * s))
		return {"size": size, "pad": px, "row_h": rh, "row_w": rw, "text_x": tx, "text_w": tw}


	func setup(p_value: int, p_font: Font, p_pad: float, s: float) -> void:
		value = p_value
		font = p_font
		pad = p_pad
		scale_k = s
		position = Vector2(pad, pad + 2.0 * s)
		skew = deg_to_rad(-4.0)
		text = str(value)
		var fs := FONT_SIZE * scale_k
		text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		cross_w = 38.0 * scale_k
		cross_h = 44.0 * scale_k
		row_h = maxf(cross_h, fs * 0.82)
		row_w = (cross_w - 4.0 * scale_k) + text_w
		queue_redraw()


	func _draw() -> void:
		var s := scale_k
		var fs := FONT_SIZE * s
		var text_x := cross_w - 4.0 * s
		var cross_y := (row_h - cross_h) * 0.5
		var cap_h := fs * 0.72
		var baseline := cross_y + cross_h * 0.5 + cap_h * 0.5
		var under_y := row_h + 3.0 * s

		# Flat drop shadows: CSS drop-shadow(3px 3px 0) + drop-shadow(-1px -1px 0).
		for off in [Vector2(3.0, 3.0) * s, Vector2(-1.0, -1.0) * s]:
			_draw_row_shadow(cross_y, text_x, baseline, off, s)
		_draw_underline(under_y, s, Vector2(2.0, 2.0) * s, true)

		# Main row: cross, diamond spark and the digits (#B7FFC9).
		_draw_cross(Vector2(0, cross_y), s, COL_CROSS)
		_draw_diamond(Vector2(0, cross_y), s, COL_WHITE)
		draw_string(font, Vector2(text_x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), COL_DIGITS)

		# Tactical underline: slanted mint bar + white dot (#F4FFF7).
		_draw_underline(under_y, s, Vector2.ZERO, false)


	func _draw_row_shadow(cross_y: float, text_x: float, baseline: float, off: Vector2, s: float) -> void:
		_draw_cross(Vector2(off.x, cross_y + off.y), s, COL_CUT)
		_draw_diamond(Vector2(off.x, cross_y + off.y), s, COL_CUT)
		draw_string(font, Vector2(text_x + off.x, baseline + off.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(FONT_SIZE * s), COL_CUT)


	func _draw_cross(origin: Vector2, s: float, col: Color) -> void:
		# Path M16 6H24V18H35V26H24V39H16V26H5V18H16V6Z, split into the two rectangles it is made of.
		draw_rect(Rect2(origin + Vector2(16, 6) * s, Vector2(8, 33) * s), col)
		draw_rect(Rect2(origin + Vector2(5, 18) * s, Vector2(30, 8) * s), col)


	func _draw_diamond(origin: Vector2, s: float, col: Color) -> void:
		var pts := PackedVector2Array([
			origin + Vector2(7, 4) * s, origin + Vector2(12, 9) * s,
			origin + Vector2(7, 14) * s, origin + Vector2(2, 9) * s,
		])
		draw_colored_polygon(pts, col)


	func _draw_underline(y: float, s: float, off: Vector2, shadow: bool) -> void:
		var dot_w := 9.0 * s
		var bar_w := row_w - dot_w - 4.0 * s
		var bar_y := y + 1.0 * s
		var bar_h := 4.0 * s
		var col := COL_CUT if shadow else COL_CROSS
		var dcol := COL_CUT if shadow else COL_WHITE
		var bx := off.x
		var by := bar_y + off.y
		var top_right := bx + bar_w
		var bottom_right := bx + bar_w * 0.96
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx, by), Vector2(top_right, by), Vector2(bottom_right, by + bar_h), Vector2(bx, by + bar_h)
		]), col)
		draw_rect(Rect2(Vector2(bx + bar_w + 4.0 * s, by), Vector2(dot_w, bar_h)), dcol)
