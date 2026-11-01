class_name EncounterTransition
extends CanvasLayer
## Encounter transition "Fenda tática" (from prototypes/transicao-encontro.html):
## five slanted panels close over the map, the "ENCONTRO" seal stamps, then the
## panels open on the battle. The scene is swapped while the screen is covered.
## Created on demand by GameState.start_battle(); lives under the root so it
## survives the scene change. Timeline (progress 0..1 over DURATION seconds):
##   0.02-0.44 panels close, 0.38-0.66 seal, 0.60-0.98 panels open.

signal revealed  ## The panels start opening; the battle is behind them.
signal finished

const W := 1280.0
const H := 720.0
const PANELS := 5
const SLANT := 84.0
const DURATION := 1.5
const SWAP_AT := 0.46
const REVEAL_AT := 0.60

const LIME := Color("d7fd6a")
const CORAL := Color("ff624f")
const CREAM := Color("f0eedf")

var active := false
var has_revealed := false

var _p := 0.0
var _target := ""
var _swapped := false
var _canvas: Canvas


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Canvas.new()
	add_child(_canvas)
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.visible = false


func play_to(scene_path: String) -> void:
	if active:
		return
	active = true
	has_revealed = false
	_swapped = false
	_p = 0.0
	_target = scene_path
	_canvas.visible = true
	get_tree().paused = true  # Freeze the map under the closing panels.


func _process(delta: float) -> void:
	if not active:
		return
	_p = minf(_p + delta / DURATION, 1.0)
	if not _swapped and _p >= SWAP_AT:
		_swapped = true
		get_tree().paused = false
		get_tree().change_scene_to_file(_target)
	if not has_revealed and _p >= REVEAL_AT:
		has_revealed = true
		revealed.emit()
	_canvas.p = _p
	_canvas.queue_redraw()
	if _p >= 1.0:
		active = false
		_canvas.visible = false
		finished.emit()


# --- Easing helpers (same curves as the prototype) ---------------------------

static func smooth(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


static func ease_out_back(t: float) -> float:
	var c1 := 1.9
	var c3 := c1 + 1.0
	var x := clampf(t, 0.0, 1.0) - 1.0
	return 1.0 + c3 * x * x * x + c1 * x * x


class Canvas extends Control:
	var p := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP  # Swallow clicks while covering the screen.

	func _draw() -> void:
		var pw := W / PANELS
		for i in PANELS:
			var closed := EncounterTransition.smooth(0.02 + i * 0.025, 0.44, p)
			var opened := EncounterTransition.smooth(0.60 + i * 0.02, 0.98, p)
			var k := clampf(closed - opened, 0.0, 1.0)
			if k <= 0.001:
				continue
			_draw_panel(i, k, pw)
		_draw_seal()
		var gl := EncounterTransition.smooth(0.60, 0.70, p) * (1.0 - EncounterTransition.smooth(0.72, 0.86, p))
		if gl > 0.01:
			draw_rect(Rect2(Vector2.ZERO, size), Color(CREAM, gl * 0.35))

	func _draw_panel(i: int, k: float, pw: float) -> void:
		var dir := -1.0 if i % 2 == 0 else 1.0
		var dy := dir * (H + 140.0) * (1.0 - k)
		var x0 := i * pw - SLANT
		var x1 := (i + 1) * pw
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0 + SLANT, dy), Vector2(x1 + SLANT, dy), Vector2(x1, H + dy), Vector2(x0, H + dy)]), Color("0b1420"))
		# Diagonal veins, clipped to the panel's slanted band.
		var slope := 0.5 + SLANT / H
		var g := -H
		while g < W:
			var y_a := maxf(0.0, (x0 + SLANT - g) / slope)
			var y_b := minf(H, (x1 + SLANT - g) / slope)
			if y_a < y_b:
				draw_line(Vector2(g + 0.5 * y_a, y_a + dy), Vector2(g + 0.5 * y_b, y_b + dy), Color(LIME, 0.06), 2.0)
			g += 26.0
		# Light edge on the side that enters last.
		var edge := Color(CORAL if i % 2 == 1 else LIME, 0.9 * k)
		if dir < 0.0:
			draw_line(Vector2(x0, H + dy), Vector2(x1, H + dy), edge, 4.0)
		else:
			draw_line(Vector2(x0 + SLANT, dy), Vector2(x1 + SLANT, dy), edge, 4.0)

	func _draw_seal() -> void:
		var a := EncounterTransition.smooth(0.38, 0.46, p) * (1.0 - EncounterTransition.smooth(0.58, 0.66, p))
		if a <= 0.01:
			return
		var sc := lerpf(0.6, 1.0, EncounterTransition.ease_out_back((p - 0.38) / 0.16))
		draw_set_transform(Vector2(W * 0.5, H * 0.5), -0.045, Vector2(sc, sc))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-250, -46), Vector2(258, -46), Vector2(236, 46), Vector2(-272, 46)]), Color(CORAL, a))
		_spaced_text(FanMenu.body_font(), "ENCONTRO", 62, 10.0, Vector2(0, 21), Color(0.082, 0.016, 0.024, a))
		var grow := EncounterTransition.ease_out(EncounterTransition.smooth(0.42, 0.60, p))
		draw_line(Vector2(-250, 62), Vector2(-250 + 150 * grow, 62), Color(LIME, a), 4.0)
		draw_line(Vector2(250, 62), Vector2(250 - 150 * grow, 62), Color(LIME, a), 4.0)
		_spaced_text(FanMenu.body_font(), "MON SELVAGEM", 15, 6.0, Vector2(0, 81), Color(CREAM, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## Centered text with extra letter spacing (baseline at pos.y).
	func _spaced_text(font: Font, text: String, font_size: int, spacing: float, pos: Vector2, color: Color) -> void:
		var total := 0.0
		for ch in text:
			total += font.get_char_size(ch.unicode_at(0), font_size).x + spacing
		total -= spacing
		var x := pos.x - total * 0.5
		for ch in text:
			draw_char(font, Vector2(x, pos.y), ch, font_size, color)
			x += font.get_char_size(ch.unicode_at(0), font_size).x + spacing
