@tool
class_name SlantedButton
extends Button

## Neo-Brutalist Slanted Parallelogram Button (-9 deg slant).
## Faithful replication of prototypes/hud_post_combat.html slanted button geometry.

@export var skew_deg: float = -9.0 : set = _set_skew_deg
@export var bg_color: Color = Color("#d4ff32") : set = _set_bg_color
@export var border_color: Color = Color.BLACK : set = _set_border_color
@export var border_width: float = 2.0 : set = _set_border_width
@export var shadow_offset: Vector2 = Vector2(3, 3) : set = _set_shadow_offset
@export var shadow_color: Color = Color(0, 0, 0, 0.85) : set = _set_shadow_color
@export var is_pulsing: bool = false : set = _set_pulsing

var _is_hovered: bool = false
var _is_pressed: bool = false
var _glow_tween: Tween


func _init() -> void:
	focus_mode = FOCUS_ALL
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	queue_redraw()


func _set_skew_deg(val: float) -> void:
	skew_deg = val
	queue_redraw()


func _set_bg_color(val: Color) -> void:
	bg_color = val
	queue_redraw()


func _set_border_color(val: Color) -> void:
	border_color = val
	queue_redraw()


func _set_border_width(val: float) -> void:
	border_width = val
	queue_redraw()


func _set_shadow_offset(val: Vector2) -> void:
	shadow_offset = val
	queue_redraw()


func _set_shadow_color(val: Color) -> void:
	shadow_color = val
	queue_redraw()


func _set_pulsing(val: bool) -> void:
	is_pulsing = val
	if _glow_tween:
		_glow_tween.kill()
		_glow_tween = null
	if not is_inside_tree():
		return
	if is_pulsing:
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.6, 1.0), 0.55)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_glow_tween.tween_property(self, "modulate", Color.WHITE, 0.55)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		modulate = Color.WHITE


func _on_mouse_entered() -> void:
	_is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_is_hovered = false
	queue_redraw()


func _on_button_down() -> void:
	_is_pressed = true
	queue_redraw()


func _on_button_up() -> void:
	_is_pressed = false
	queue_redraw()


func _draw() -> void:
	var w = size.x
	var h = size.y
	if w <= 0 or h <= 0:
		return

	var dx = h * tan(deg_to_rad(-skew_deg))

	var p0 = Vector2(dx, 0.0)
	var p1 = Vector2(w, 0.0)
	var p2 = Vector2(w - dx, h)
	var p3 = Vector2(0.0, h)

	# 1. Shadow
	if shadow_offset != Vector2.ZERO and shadow_color.a > 0.0 and not _is_pressed:
		var s0 = p0 + shadow_offset
		var s1 = p1 + shadow_offset
		var s2 = p2 + shadow_offset
		var s3 = p3 + shadow_offset
		draw_colored_polygon(PackedVector2Array([s0, s1, s2, s3]), shadow_color)

	# 2. Fill color
	var fill = bg_color
	if disabled:
		fill = Color(0.2, 0.24, 0.3, 0.6)
	elif _is_pressed:
		fill = bg_color.darkened(0.15)
	elif _is_hovered:
		fill = bg_color.lightened(0.12)

	draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), fill)

	# 3. Border
	var b_col = border_color
	if disabled:
		b_col = Color(0.1, 0.12, 0.16, 0.5)
	draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), b_col, border_width, true)

	# 4. Text
	if text != "":
		var f: Font = get_theme_font("font")
		if f == null:
			f = ThemeDB.fallback_font
		var fs: int = get_theme_font_size("font_size")
		if fs <= 0:
			fs = 13
		var fc: Color = get_theme_color("font_color")
		if disabled:
			var dfc = get_theme_color("font_disabled_color")
			fc = dfc if dfc.a > 0.0 else Color(0.45, 0.5, 0.6, 0.7)
		elif _is_pressed:
			var pfc = get_theme_color("font_pressed_color")
			if pfc.a > 0.0:
				fc = pfc
		elif _is_hovered:
			var hfc = get_theme_color("font_hover_color")
			if hfc.a > 0.0:
				fc = hfc

		var str_sz = f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var ascent = f.get_ascent(fs)
		var text_x = (w - str_sz.x) * 0.5
		var text_y = (h - str_sz.y) * 0.5 + ascent
		draw_string(f, Vector2(text_x, text_y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, fc)


func _has_point(point: Vector2) -> bool:
	if point.y < 0.0 or point.y > size.y:
		return false
	var dx = size.y * tan(deg_to_rad(-skew_deg))
	var t = point.y / size.y
	var left_x = (1.0 - t) * dx
	var right_x = size.x - t * dx
	return point.x >= left_x and point.x <= right_x
