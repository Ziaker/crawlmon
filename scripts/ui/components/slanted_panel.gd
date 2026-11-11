@tool
class_name SlantedPanel
extends PanelContainer

## Neo-Brutalist Slanted Parallelogram Panel (-9 deg slant).
## Faithful replication of prototypes/hud_post_combat.html .skew-panel geometry.

@export var skew_deg: float = -9.0 : set = _set_skew_deg
@export var bg_color: Color = Color("#0d1824") : set = _set_bg_color
@export var border_color: Color = Color.BLACK : set = _set_border_color
@export var border_width: float = 2.0 : set = _set_border_width
@export var shadow_offset: Vector2 = Vector2(4, 4) : set = _set_shadow_offset
@export var shadow_color: Color = Color(0, 0, 0, 0.85) : set = _set_shadow_color
@export var is_pulsing: bool = false : set = _set_pulsing

var _glow_tween: Tween


func _init() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _ready() -> void:
	resized.connect(queue_redraw)
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
	if shadow_offset != Vector2.ZERO and shadow_color.a > 0.0:
		var s0 = p0 + shadow_offset
		var s1 = p1 + shadow_offset
		var s2 = p2 + shadow_offset
		var s3 = p3 + shadow_offset
		draw_colored_polygon(PackedVector2Array([s0, s1, s2, s3]), shadow_color)

	# 2. Fill
	draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), bg_color)

	# 3. Border
	if border_width > 0.0:
		draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), border_color, border_width, true)


func _has_point(point: Vector2) -> bool:
	if point.y < 0.0 or point.y > size.y:
		return false
	var dx = size.y * tan(deg_to_rad(-skew_deg))
	var t = point.y / size.y
	var left_x = (1.0 - t) * dx
	var right_x = size.x - t * dx
	return point.x >= left_x and point.x <= right_x
