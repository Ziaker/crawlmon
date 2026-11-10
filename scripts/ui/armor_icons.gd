class_name ArmorIcons
extends RefCounted
## D-1026: the two candidate icons of the ARMOR badge, drawn as flat silhouettes (no image files). The creator
## tests both and approves one: "peitoral" (breastplate) or "capacete" (helmet). Nothing here depends on a
## character, a team or a side (D-235).

const VARIANTS := ["peitoral", "capacete"]

## Which one the HUD draws. `--armor-icon=capacete` on the command line (or CRAWLMON_ARMOR_ICON) picks it for a test run.
static var variant := ""


static func current() -> String:
	if variant == "":
		variant = "peitoral"
		var env := OS.get_environment("CRAWLMON_ARMOR_ICON")
		for a in OS.get_cmdline_args():
			if a.begins_with("--armor-icon="):
				env = a.substr(13)
		if env in VARIANTS:
			variant = env
	return variant


## Draws the current candidate inside `r`. `fg` is the silhouette, `bg` fills the cut-outs (the badge colour).
static func draw(c: CanvasItem, r: Rect2, fg: Color, bg: Color, which := "") -> void:
	var v := which if which != "" else current()
	if v == "capacete":
		_helmet(c, r, fg, bg)
	else:
		_breastplate(c, r, fg)


static func _poly(c: CanvasItem, r: Rect2, pts: Array, col: Color) -> void:
	var out := PackedVector2Array()
	for p in pts:
		out.append(r.position + Vector2(p.x * r.size.x, p.y * r.size.y))
	c.draw_colored_polygon(out, col)


static func _mirror(pts: Array) -> Array:
	var out: Array = []
	for i in range(pts.size() - 1, -1, -1):
		out.append(Vector2(1.0 - pts[i].x, pts[i].y))
	return out


static func _pair(c: CanvasItem, r: Rect2, left: Array, col: Color) -> void:
	_poly(c, r, left, col)
	_poly(c, r, _mirror(left), col)


## Breastplate: two pauldrons, two chest halves split by a gap and two tassets.
static func _breastplate(c: CanvasItem, r: Rect2, col: Color) -> void:
	_pair(c, r, [Vector2(0.03, 0.30), Vector2(0.08, 0.17), Vector2(0.22, 0.10), Vector2(0.34, 0.14), Vector2(0.35, 0.22),
		Vector2(0.30, 0.31), Vector2(0.21, 0.30), Vector2(0.15, 0.27), Vector2(0.07, 0.31)], col)
	_pair(c, r, [Vector2(0.22, 0.40), Vector2(0.28, 0.31), Vector2(0.36, 0.22), Vector2(0.47, 0.25), Vector2(0.47, 0.73),
		Vector2(0.27, 0.73)], col)
	_pair(c, r, [Vector2(0.27, 0.76), Vector2(0.47, 0.76), Vector2(0.45, 0.92), Vector2(0.24, 0.97), Vector2(0.19, 0.92)], col)


## Spartan-style helmet: dome and cheeks, with the T-shaped opening (eyes + nose guard) in the badge colour.
static func _helmet(c: CanvasItem, r: Rect2, col: Color, cut: Color) -> void:
	var outline: Array = []
	for i in 13:  # the dome: a half ellipse from the left side over the top to the right side
		var a := PI + PI * float(i) / 12.0
		outline.append(Vector2(0.5 + 0.37 * cos(a), 0.40 + 0.40 * sin(a)))
	outline.append_array([Vector2(0.87, 0.84), Vector2(0.63, 1.0), Vector2(0.37, 1.0), Vector2(0.13, 0.84)])
	_poly(c, r, outline, col)
	_poly(c, r, [Vector2(0.25, 0.38), Vector2(0.40, 0.38), Vector2(0.40, 0.52), Vector2(0.25, 0.52)], cut)  # left eye
	_poly(c, r, [Vector2(0.60, 0.38), Vector2(0.75, 0.38), Vector2(0.75, 0.52), Vector2(0.60, 0.52)], cut)  # right eye
	_poly(c, r, [Vector2(0.37, 0.50), Vector2(0.63, 0.50), Vector2(0.63, 1.02), Vector2(0.37, 1.02)], cut)  # the open stem
	_poly(c, r, [Vector2(0.42, 0.38), Vector2(0.58, 0.38), Vector2(0.56, 0.70), Vector2(0.44, 0.70)], col)  # nose guard
