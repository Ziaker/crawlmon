class_name AttackTargetReticle
extends Control
## D-1134: retículo de alvo do estilo SMT UPLINK (e auxiliar dos demais).
## Projetado na tela a partir da posição real do alvo (D-235); não usa lado,
## time nem coordenadas fixas.

const CYAN := Color(0.251, 0.949, 0.851)

var active := false
var center := Vector2.ZERO

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	if active:
		queue_redraw()


func set_target(pos: Vector2, is_active: bool) -> void:
	center = pos
	active = is_active
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 5.2)
	var s := 30.0 + pulse * 2.0
	var arm := 10.0
	var a := 0.55 + 0.25 * pulse
	var col := Color(CYAN.r, CYAN.g, CYAN.b, a)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner := center + Vector2(sx * s, sy * s)
			draw_line(corner, corner + Vector2(-sx * arm, 0.0), col, 2.0)
			draw_line(corner, corner + Vector2(0.0, -sy * arm), col, 2.0)
	var d := 5.0
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -d), center + Vector2(d, 0.0),
		center + Vector2(0.0, d), center + Vector2(-d, 0.0),
	])
	draw_colored_polygon(diamond, Color(CYAN.r, CYAN.g, CYAN.b, 0.85 * a))
	var font := ThemeDB.fallback_font
	var label := "LOCK"
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(font, center + Vector2(-tw * 0.5, s + 16.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
