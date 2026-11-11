extends Control
## D-1156: orbe de coleta. Nasce no chão, na posição projetada do item, e voa
## até o centro do ícone da notificação. Tudo é derivado da câmera e do item;
## nada depende de personagem, time ou lado (D-235).

signal arrived

const FLIGHT_TIME := 0.45
const LOOP_TIME := 0.16
const ARRIVAL_TIME := 0.22
const TRAIL_MAX := 14

var _glow: GradientTexture2D
var _active := false
var _phase := 0
var _t := 0.0
var _arrival_t := 0.0
var _start := Vector2.ZERO
var _target := Vector2.ZERO
var _loop_center := Vector2.ZERO
var _loop_end := Vector2.ZERO
var _loop_radius := 42.0
var _fly_c1 := Vector2.ZERO
var _fly_c2 := Vector2.ZERO
var _pos := Vector2.ZERO
var _scale := 1.0
var _trail: Array[Vector2] = []
var _spark_phase := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_glow = _make_glow_texture()
	visible = false
	set_process(false)


func _make_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 0.74, 0.34, 0.0))
	gradient.add_point(0.22, Color(1.0, 0.96, 0.78, 0.92))
	gradient.add_point(0.55, Color(1.0, 0.86, 0.5, 0.42))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture


func fly(from: Vector2, to: Vector2) -> void:
	_start = from
	_target = to
	var dist := from.distance_to(to)
	# Arco bem fechado: meia-volta em volta do item, saindo do chão para a
	# direita e terminando no topo, já apontando para o impacto.
	_loop_radius = clampf(dist * 0.065, 32.0, 52.0)
	_loop_center = from + Vector2(0.0, -_loop_radius)
	_loop_end = _loop_center + Vector2(0.0, -_loop_radius)
	var flight_delta := to - _loop_end
	var flight_dist := maxf(flight_delta.length(), 1.0)
	_fly_c1 = _loop_end + Vector2(-flight_dist * 0.22, -flight_dist * 0.06)
	_fly_c2 = to + Vector2(flight_dist * 0.08, flight_dist * 0.10)
	_pos = from
	_trail.clear()
	_t = 0.0
	_arrival_t = 0.0
	_scale = 0.45
	_phase = 0
	_spark_phase = randf() * TAU
	_active = true
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	if _phase == 0:
		_t = minf(_t + delta / FLIGHT_TIME, 1.0)
		var loop_ratio := LOOP_TIME / FLIGHT_TIME
		if _t <= loop_ratio:
			var loop_k := _t / loop_ratio
			var theta := deg_to_rad(90.0 - 180.0 * loop_k)
			_pos = _loop_center + Vector2(cos(theta), sin(theta)) * _loop_radius
		else:
			var k := (_t - loop_ratio) / (1.0 - loop_ratio)
			var eased := 1.0 - pow(1.0 - k, 2.0)
			_pos = _bezier3(_loop_end, _fly_c1, _fly_c2, _target, eased)
		_trail.push_front(_pos)
		if _trail.size() > TRAIL_MAX:
			_trail.resize(TRAIL_MAX)
		var grow := minf(_t / 0.09, 1.0)
		_scale = lerpf(0.45, 1.0, grow) * lerpf(1.0, 0.72, _t * _t)
		if _t >= 1.0:
			_phase = 1
			_arrival_t = 0.0
			_trail.clear()
			arrived.emit()
	else:
		_arrival_t += delta
		if _arrival_t >= ARRIVAL_TIME:
			_active = false
			visible = false
			set_process(false)
	queue_redraw()


func _bezier3(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * u * a + 3.0 * u * u * t * b + 3.0 * u * t * t * c + t * t * t * d


func _draw() -> void:
	if not _active:
		return
	if _phase == 0:
		_draw_start_burst()
		_draw_trail()
		_draw_orb(_pos)
	else:
		_draw_arrival()


func _draw_start_burst() -> void:
	if _t > 0.38:
		return
	var k := _t / 0.38
	var radius := lerpf(6.0, 44.0, k)
	draw_arc(_start, radius, 0.0, TAU, 30,
		Color(1.0, 0.9, 0.62, 0.7 * (1.0 - k)), 2.4, true)
	for i in 6:
		var angle := _spark_phase + TAU * float(i) / 6.0
		var from := _start + Vector2(cos(angle), sin(angle)) * (8.0 + 24.0 * k)
		var to := _start + Vector2(cos(angle), sin(angle)) * (14.0 + 36.0 * k)
		draw_line(from, to, Color(1.0, 0.92, 0.64, 0.65 * (1.0 - k)), 2.0, true)


func _draw_trail() -> void:
	for i in range(_trail.size() - 1, -1, -1):
		var f := 1.0 - float(i) / float(TRAIL_MAX)
		var size := lerpf(12.0, 46.0, f)
		var alpha := 0.45 * pow(f, 1.4)
		draw_texture_rect(_glow, Rect2(_trail[i] - Vector2(size, size) * 0.5,
			Vector2(size, size)), false, Color(1.0, 0.88, 0.56, alpha))
	for i in range(1, _trail.size()):
		var f := 1.0 - float(i) / float(TRAIL_MAX)
		draw_line(_trail[i - 1], _trail[i],
			Color(1.0, 0.95, 0.72, 0.22 * f), 1.5, true)


func _draw_orb(center: Vector2) -> void:
	var glow_size := 92.0 * _scale
	draw_texture_rect(_glow, Rect2(center - Vector2(glow_size, glow_size) * 0.5,
		Vector2(glow_size, glow_size)), false, Color(1.0, 0.9, 0.62, 0.78))
	var core_size := 34.0 * _scale
	draw_texture_rect(_glow, Rect2(center - Vector2(core_size, core_size) * 0.5,
		Vector2(core_size, core_size)), false, Color(1.0, 1.0, 0.95, 1.0))
	draw_circle(center, 6.0 * _scale, Color(1.0, 1.0, 1.0, 1.0))
	var spin := _t * 15.0 + _spark_phase
	for i in 5:
		var angle := spin + TAU * float(i) / 5.0
		var orbit := (20.0 + sin(spin * 1.3 + float(i)) * 3.5) * _scale
		var dot := center + Vector2(cos(angle), sin(angle)) * orbit
		draw_circle(dot, 2.4 * _scale, Color(1.0, 0.97, 0.8, 0.95))


func _draw_arrival() -> void:
	var k := clampf(_arrival_t / ARRIVAL_TIME, 0.0, 1.0)
	var radius := lerpf(5.0, 30.0, k)
	draw_arc(_target, radius, 0.0, TAU, 30,
		Color(1.0, 0.95, 0.75, 0.8 * (1.0 - k)), 2.6, true)
	var size := lerpf(48.0, 14.0, k)
	draw_texture_rect(_glow, Rect2(_target - Vector2(size, size) * 0.5,
		Vector2(size, size)), false, Color(1.0, 0.92, 0.7, 0.7 * (1.0 - k)))
