extends Control
## Impacto 2D do laboratório de ataque: estrela, anel, faíscas e POW.
## Não é HUD de jogo; é só a leitura do golpe no protótipo.

const KANIT := preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")
const CREAM := Color(0.918, 0.914, 0.851)
const AMBER := Color(1.000, 0.722, 0.278)
const CORAL := Color(1.000, 0.384, 0.310)
const CYAN := Color(0.220, 0.741, 0.973)

var _time := -1.0
var _pos := Vector2.ZERO
var _power := 1.0
var _comic := false
var _color := AMBER
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 3110


func play(screen_pos: Vector2, power: float, comic: bool, color := AMBER) -> void:
	_pos = screen_pos
	_power = power
	_comic = comic
	_color = color
	_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if _time < 0.0:
		return
	_time += delta
	if _time > 0.55:
		_time = -1.0
	queue_redraw()


func _draw() -> void:
	if _time < 0.0:
		return
	var k := clampf(1.0 - _time / 0.55, 0.0, 1.0)
	var grow := 1.0 - pow(1.0 - k, 3.0)
	var r := lerpf(8.0, 54.0 * _power, grow)
	var star := PackedVector2Array()
	for i in 20:
		var a := -PI * 0.5 + TAU * float(i) / 20.0
		var rad := r if i % 2 == 0 else r * 0.44
		star.append(_pos + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(star, Color(_color.r, _color.g, _color.b, 0.24 * k))
	var outline := PackedVector2Array(star)
	outline.append(star[0])
	draw_polyline(outline, Color(CREAM.r, CREAM.g, CREAM.b, 0.85 * k), 2.0, true)
	draw_circle(_pos, 7.0 + 4.0 * k, Color(1.0, 0.98, 0.88, 0.9 * k))
	draw_arc(_pos, r * 1.15, 0.0, TAU, 32,
		Color(_color.r, _color.g, _color.b, 0.45 * k), 2.0)
	for i in 10:
		var a := TAU * float(i) / 10.0 + 0.2
		var p0 := _pos + Vector2(cos(a), sin(a)) * (r * 0.65)
		var p1 := _pos + Vector2(cos(a), sin(a)) * (r * 1.45)
		draw_line(p0, p1, Color(1.0, 0.93, 0.72, 0.65 * k), 2.0)
	if _comic:
		var txt := "POW!"
		var fs := int(lerpf(22.0, 42.0, grow))
		var w := KANIT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := _pos + Vector2(-w * 0.5 + 8.0, -r - 10.0)
		for dx in [-2, 0, 2]:
			for dy in [-2, 0, 2]:
				if dx == 0 and dy == 0:
					continue
				draw_string(KANIT, p + Vector2(dx, dy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
					Color(0.03, 0.03, 0.04, 0.9 * k))
		draw_string(KANIT, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(CREAM.r, CREAM.g, CREAM.b, k))
