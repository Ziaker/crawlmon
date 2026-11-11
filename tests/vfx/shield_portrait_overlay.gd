extends Control
## Prototype: shield reserve as an arc around the HUD portrait, replacing the
## floating 3D ring and the small shield badge. One arc per combatant; only the
## player and the current target get the full arc + icon + number.

var battle: Battle
var hud
var number_font: Font
var pulse: Dictionary = {}
var last_hp: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 50


func _process(delta: float) -> void:
	if battle == null or hud == null:
		return
	for c in battle.party + battle.enemies:
		var hp := c.shield_hp if c.is_shielded() else 0
		var prev: int = last_hp.get(c, -1)
		if hp > 0 and hp != prev:
			pulse[c] = 1.0
		last_hp[c] = hp
	for c in pulse.keys():
		pulse[c] = maxf(0.0, float(pulse[c]) - delta * 3.0)
	queue_redraw()


func _draw() -> void:
	if battle == null or hud == null:
		return
	var target := _current_target()
	for c in battle.party + battle.enemies:
		if not c.is_alive() or not c.is_shielded():
			continue
		var rect := _portrait_rect(c)
		if rect.size.x <= 1.0:
			continue
		var full: bool = c == battle.party[0] or c == target
		var center := rect.get_center()
		var radius := minf(rect.size.x, rect.size.y) * 0.5 + (3.0 if full else 1.5)
		var width := 4.0 if full else 2.0
		var frac := clampf(float(c.shield_hp) / float(maxi(c.shield_max, 1)), 0.0, 1.0)
		var ring := Color(0.03, 0.17, 0.30)
		var on := Color(0.34, 0.84, 1.0)
		var p := float(pulse.get(c, 0.0))

		# Pulse halo only on the player/target and only while a value changes.
		if full:
			var hr := radius + 3.0 + 4.0 * (1.0 - p)
			draw_arc(center, hr, -PI * 0.5, -PI * 0.5 + TAU * frac, 48,
				Color(on.r, on.g, on.b, 0.25 + 0.55 * p), 1.5, true)
		draw_arc(center, radius, 0.0, TAU, 48, ring, width, true)
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * frac, 48,
			on.lerp(Color.WHITE, 0.35 * p), width, true)

		# Number on the portrait's lower-right corner, with a dark rim.
		# The card portrait is larger than the tag portrait, so the font follows it.
		var is_player: bool = c == battle.party[0]
		var fsize := 17 if is_player else (14 if full else 11)
		var baseline := rect.end.y - 2.0
		var outline := Color(0.01, 0.03, 0.06)
		draw_string_outline(number_font, Vector2(rect.position.x, baseline), str(c.shield_hp),
			HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x, fsize, 3, outline)
		draw_string(number_font, Vector2(rect.position.x, baseline), str(c.shield_hp),
			HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x, fsize, Color.WHITE)

		if full:
			_shield_icon(rect.position + Vector2(5.0, 5.0), 4.5 if is_player else 3.5)


func _current_target() -> Combatant:
	var t: Combatant = hud._target
	if t != null and is_instance_valid(t) and t.is_alive():
		return t
	for e in battle.enemies:
		if e.is_alive():
			return e
	return null


func _portrait_rect(c: Combatant) -> Rect2:
	var inv := get_global_transform().affine_inverse()
	for card in hud._cards:
		if card.combatant == c:
			var xf: Transform2D = inv * card.get_global_transform()
			var local := Rect2(16, 26, 56, 62)
			var p1: Vector2 = xf * local.position
			var p2: Vector2 = xf * (local.position + local.size)
			return Rect2(p1, p2 - p1)
	var tag = hud._tags.get(c)
	if tag != null:
		var xf2: Transform2D = inv * tag.get_global_transform()
		var local2 := Rect2(4, 4, 30, 36)
		var q1: Vector2 = xf2 * local2.position
		var q2: Vector2 = xf2 * (local2.position + local2.size)
		return Rect2(q1, q2 - q1)
	return Rect2()


func _shield_icon(p: Vector2, s: float) -> void:
	var pts := PackedVector2Array([
		p + Vector2(-s, -s * 0.9),
		p + Vector2(s, -s * 0.9),
		p + Vector2(s * 0.8, s * 0.25),
		p + Vector2(0, s),
		p + Vector2(-s * 0.8, s * 0.25),
	])
	draw_colored_polygon(pts, Color(0.34, 0.84, 1.0))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(0.01, 0.03, 0.06), 1.0, true)
