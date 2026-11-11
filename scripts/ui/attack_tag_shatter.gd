class_name AttackTagShatter
extends Control
## D-1104 (scope corrected by D-1160): when an action is really interrupted — a hit
## that cancels its wind-up/travel before the impact, War Cry/status cancellation or a
## clash — its AttackTag is destroyed into 9 shards of the card's real texture and a
## flat "interrupted" echo appears centered where the card was. Evade and automatic
## dodge are misses (D-104/D-106) and leave normally; a hit during the return is not
## an interruption either. HUD feedback only; it does not touch combat rules
## (D-019/D-1040, D-235).

const DURATION := 0.55
const FADE_START := 0.35
const GRAVITY := 900.0
const ECHO_TEXT := "INTERRUPTED"
const ECHO_COLOR := Color("ff4d6d")
const ECHO_FONT_SIZE := 26
const ECHO_LETTER_SPACING := 4.0

var _t := 0.0
var _pieces: Array[Dictionary] = []


static func spawn(hud: Control, origin: Vector2, card_size: Vector2, card_texture: Texture2D) -> AttackTagShatter:
	var shatter := AttackTagShatter.new()
	shatter.name = "AttackTagShatter"
	shatter.position = origin
	shatter.size = card_size
	shatter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(shatter)
	hud.move_child(shatter, hud.get_child_count() - 1)
	shatter._build(card_size, card_texture)
	return shatter


func _build(card_size: Vector2, card_texture: Texture2D) -> void:
	var w := card_size.x
	var h := card_size.y
	# 3 x 3 pieces with slightly irregular cuts; every piece keeps the real card pixels.
	var x1 := randf_range(42.0, 56.0)
	var x2 := randf_range(94.0, 108.0)
	var y1 := randf_range(10.0, 14.0)
	var y2 := randf_range(24.0, 28.0)
	var xs := [0.0, x1, x2, w]
	var ys := [0.0, y1, y2, h]
	for iy in 3:
		for ix in 3:
			var p0 := Vector2(xs[ix], ys[iy])
			var p1 := Vector2(xs[ix + 1], ys[iy])
			var p2 := Vector2(xs[ix + 1], ys[iy + 1])
			var p3 := Vector2(xs[ix], ys[iy + 1])
			var center := (p0 + p2) * 0.5
			var poly := Polygon2D.new()
			poly.name = "Shard%d_%d" % [ix, iy]
			poly.texture = card_texture
			poly.polygon = PackedVector2Array([p0 - center, p1 - center, p2 - center, p3 - center])
			poly.uv = PackedVector2Array([p0, p1, p2, p3])
			poly.position = center
			add_child(poly)
			var dir := center - card_size * 0.5
			if dir.length_squared() < 0.001:
				dir = Vector2.RIGHT
			dir = dir.normalized()
			var vel := dir * randf_range(90.0, 190.0) + Vector2(0.0, randf_range(-120.0, -40.0))
			_pieces.append({"node": poly, "vel": vel, "spin": randf_range(-4.0, 4.0)})

	var echo := EchoText.new()
	echo.name = "InterruptedEcho"
	echo.text = ECHO_TEXT
	echo.color = ECHO_COLOR
	echo.font_size = ECHO_FONT_SIZE
	echo.letter_spacing = ECHO_LETTER_SPACING
	echo.size = Vector2(300, 44)
	echo.position = Vector2(w * 0.5 - echo.size.x * 0.5, h * 0.5 - echo.size.y * 0.5)
	echo.pivot_offset = echo.size * 0.5
	echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(echo)
	echo.scale = Vector2.ONE * 1.2
	var tw := echo.create_tween()
	tw.tween_property(echo, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(DURATION - 0.28)
	tw.tween_property(echo, "modulate:a", 0.0, 0.20)
	# White blink on arrival, settling back to the coral word by 0.20 s.
	var flash_tw := echo.create_tween()
	flash_tw.tween_property(echo, "flash", 0.0, 0.20)


func _process(delta: float) -> void:
	_t += delta
	var alpha := 1.0
	if _t > FADE_START:
		alpha = 1.0 - clampf((_t - FADE_START) / (DURATION - FADE_START), 0.0, 1.0)
	for piece in _pieces:
		var node: Polygon2D = piece["node"]
		var vel: Vector2 = piece["vel"]
		vel.y += GRAVITY * delta
		piece["vel"] = vel
		node.position += vel * delta
		node.rotation += float(piece["spin"]) * delta
		node.modulate.a = alpha
	if _t >= DURATION:
		queue_free()


## Flat, borderless echo (D-1061). A plain Control has no text minimum size, so its
## 300 x 44 box stays exactly centered on the destroyed card.
class EchoText extends Control:
	var text := ""
	var color := Color.WHITE
	var font_size := 26
	var letter_spacing := 4.0
	var flash := 1.0:
		set(value):
			flash = value
			queue_redraw()

	func _draw() -> void:
		var font := FanMenu.title_font()
		var ascent := font.get_ascent(font_size)
		var descent := font.get_descent(font_size)
		var baseline := size.y * 0.5 + (ascent - descent) * 0.5
		var widths: Array[float] = []
		var total := 0.0
		for i in text.length():
			var w := font.get_char_size(text.unicode_at(i), font_size).x
			widths.append(w)
			total += w
		total += letter_spacing * maxf(text.length() - 1, 0.0)
		var x := (size.x - total) * 0.5
		for i in text.length():
			var ch := text[i]
			draw_string(font, Vector2(x, baseline), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
			if flash > 0.001:
				draw_string(font, Vector2(x, baseline), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 1.0, 1.0, flash))
			x += widths[i] + letter_spacing
