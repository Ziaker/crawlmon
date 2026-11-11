class_name StatPipsStrip
extends Control

## SMT III 24-Pip Segmented Attribute Bar.
## Renders procedurally via _draw() with -9 deg parallelogram slant (D-390, D-413).

@export var pip_size := Vector2(6.0, 14.0)
@export var pip_spacing := 1.5
@export var total_pips := 24
@export var skew_deg := -9.0

const COLOR_BASE := Color("#f87171")         # Salmon / Coral Red
const COLOR_NATURE_BUFF := Color("#22c55e")   # Emerald Green
const COLOR_NATURE_NERF := Color("#7f1d1d")   # Wine Red
const COLOR_ALLOCATED := Color("#00d8f6")     # Neon Cyber Cyan
const COLOR_ALLY_PROF := Color("#facc15")     # Gold
const COLOR_EMPTY := Color("#141c26")         # Dark Slate
const COLOR_BORDER := Color("#1f2d3e")

var _base_pts: int = 0
var _nature_mod: int = 0
var _allocated_pts: int = 0
var _ally_prof: int = 0


func _init() -> void:
	_update_min_size()


func _ready() -> void:
	_update_min_size()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_min_size()


func _update_min_size() -> void:
	var dx := pip_size.y * tan(deg_to_rad(-skew_deg))
	custom_minimum_size = Vector2(total_pips * (pip_size.x + pip_spacing) + dx, pip_size.y)


func setup(base_pts: int, nature_mod: int, allocated_pts: int, ally_prof: int = 0) -> void:
	_base_pts = base_pts
	_nature_mod = nature_mod
	_allocated_pts = allocated_pts
	_ally_prof = ally_prof
	queue_redraw()


func _draw() -> void:
	var active_base = maxi(0, _base_pts + mini(0, _nature_mod))
	var buff_pts = maxi(0, _nature_mod)
	var nerf_pts = maxi(0, -_nature_mod)
	var dx := pip_size.y * tan(deg_to_rad(-skew_deg))

	for i in range(total_pips):
		var x0 := i * (pip_size.x + pip_spacing) + dx
		var p0 := Vector2(x0, 0.0)
		var p1 := Vector2(x0 + pip_size.x, 0.0)
		var p2 := Vector2(x0 + pip_size.x - dx, pip_size.y)
		var p3 := Vector2(x0 - dx, pip_size.y)

		var poly := PackedVector2Array([p0, p1, p2, p3])
		var border_poly := PackedVector2Array([p0, p1, p2, p3, p0])

		var color := COLOR_EMPTY
		var is_empty := true
		if i < active_base:
			color = COLOR_BASE
			is_empty = false
		elif i < active_base + buff_pts:
			color = COLOR_NATURE_BUFF
			is_empty = false
		elif i < active_base + buff_pts + _allocated_pts:
			color = COLOR_ALLOCATED
			is_empty = false
		elif i < active_base + buff_pts + _allocated_pts + _ally_prof:
			color = COLOR_ALLY_PROF
			is_empty = false
		elif i < active_base + buff_pts + _allocated_pts + _ally_prof + nerf_pts:
			color = COLOR_NATURE_NERF
			is_empty = false

		draw_colored_polygon(poly, color)

		var border_color := COLOR_BORDER
		if not is_empty:
			if color == COLOR_NATURE_NERF:
				border_color = COLOR_BASE
			else:
				border_color = color.darkened(0.2)

		draw_polyline(border_poly, border_color, 1.0, true)
