class_name RewardLayer
extends Control
## Draws the reward tokens (ATB blocks and flaming Bursts) on top of the HUD. Every
## frame it reads Battle.rewards: the logic owns the clock (float 1.4 s, fly 0.4 s,
## impact 0.6 s) and this only decides where the token is on screen at that moment.

const CYAN := Color(0.35, 0.9, 1.0)
const FLAME := Color(1.0, 0.42, 0.08)
const GOLD := Color(1.0, 0.82, 0.25)

var hud: BattleHud
var battle: Battle


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if battle == null or hud == null:
		return
	for r in battle.rewards:
		var a: float = r.age()
		if a < 0.0:
			continue
		var dest: Variant = hud.reward_dest(r)
		if dest == null:
			continue
		var src: Variant = hud.reward_source(r)
		if a >= r.float_time + r.fly_time:
			_draw_impact(r, dest as Vector2, a - r.float_time - r.fly_time)
			continue
		if src == null:
			continue
		var pos := _token_pos(r, src as Vector2, dest as Vector2, a)
		var pop := clampf(a / 0.15, 0.0, 1.0)
		var s := lerpf(0.3, 1.0, pop * pop * (3.0 - 2.0 * pop))
		if a > r.float_time:  # Shrinks a little while it flies in.
			s *= lerpf(1.0, 0.75, (a - r.float_time) / maxf(r.fly_time, 0.001))
			_draw_trail(r, src as Vector2, dest as Vector2, a, s)
		if r.kind == "burst":
			_draw_burst_token(pos, s, r.id)
		else:
			_draw_atb_token(pos, s, r.id)


## Where the token is `a` seconds after it spawned.
func _token_pos(r, src: Vector2, dest: Vector2, a: float) -> Vector2:
	# Burst out in a random direction (stable per token): very fast at first, then a hard
	# brake over 0.3 s; after that it only hovers.
	var rise := 1.0 - pow(1.0 - clampf(a / 0.3, 0.0, 1.0), 5.0)
	var ang := fposmod(sin(r.id * 12.9898) * 43758.5453, 1.0) * TAU
	var fan := Vector2(cos(ang), sin(ang)) * 72.0 * rise
	var hover := src + fan + Vector2(sin(a * 3.0 + r.id) * 5.0, sin(a * 2.2 + r.id * 1.7) * 4.0) * rise
	if a <= r.float_time:
		return hover
	var k := clampf((a - r.float_time) / maxf(r.fly_time, 0.001), 0.0, 1.0)
	return hover.lerp(dest, k * k)  # Straight line to the slot, accelerating.


func _draw_trail(r, src: Vector2, dest: Vector2, a: float, s: float) -> void:
	for j in range(1, 7):
		var back := a - j * 0.022
		if back < r.float_time:
			break
		var p := _token_pos(r, src, dest, back)
		var fade := 1.0 - j / 7.0
		if r.kind == "burst":
			draw_circle(p, 9.0 * s * fade, Color(FLAME, 0.35 * fade))
		else:
			draw_circle(p, 6.0 * s * fade, Color(CYAN, 0.4 * fade))


func _draw_atb_token(p: Vector2, s: float, id: int) -> void:
	var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.015 + id)
	# Soft additive-looking halos, then the bright slanted block.
	draw_circle(p, 26.0 * s, Color(CYAN, 0.10 * pulse))
	draw_circle(p, 17.0 * s, Color(CYAN, 0.18 * pulse))
	var w := 34.0 * s
	var h := 17.0 * s
	var sk := 5.0 * s
	var pts := PackedVector2Array([p + Vector2(-w * 0.5 + sk, -h * 0.5), p + Vector2(w * 0.5, -h * 0.5), p + Vector2(w * 0.5 - sk, h * 0.5), p + Vector2(-w * 0.5, h * 0.5)])
	draw_colored_polygon(pts, Color(0.2, 0.75, 0.95, 0.95))
	var inner := PackedVector2Array([p + Vector2(-w * 0.5 + sk + 3 * s, -h * 0.5 + 3 * s), p + Vector2(w * 0.5 - 3 * s, -h * 0.5 + 3 * s), p + Vector2(w * 0.5 - sk - 3 * s, h * 0.5 - 3 * s), p + Vector2(-w * 0.5 + 3 * s, h * 0.5 - 3 * s)])
	draw_colored_polygon(inner, Color(0.75, 0.98, 1.0, 0.95))
	draw_line(pts[0], pts[1], Color(1, 1, 1, 0.9), 2.0 * s)


func _draw_burst_token(p: Vector2, s: float, id: int) -> void:
	var now := Time.get_ticks_msec()
	draw_circle(p, 30.0 * s, Color(1.0, 0.5, 0.1, 0.12))
	draw_circle(p, 20.0 * s, Color(1.0, 0.6, 0.15, 0.2))
	# Flame tongues licking up from the letter.
	for j in 7:
		var ph := now * 0.014 + j * 1.7 + id * 2.3
		var x := p.x + (j - 3.0) * 6.0 * s
		var h := (20.0 + 12.0 * sin(ph)) * s * (1.0 - absf(j - 3.0) * 0.12)
		var sway := sin(ph * 0.8) * 3.0 * s
		var base_y := p.y + 8.0 * s
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5.0 * s, base_y), Vector2(x + sway, base_y - h - 10.0 * s), Vector2(x + 5.0 * s, base_y)]), Color(FLAME, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3.0 * s, base_y), Vector2(x + sway * 0.7, base_y - h * 0.65 - 6.0 * s), Vector2(x + 3.0 * s, base_y)]), Color(GOLD, 0.95))
	# Embers.
	for j in 8:
		var life := fmod(now * 0.0011 + j * 0.173 + id * 0.31, 1.0)
		var ex := p.x + sin(j * 2.4 + now * 0.003) * 16.0 * s
		var ey := p.y - life * 36.0 * s
		draw_circle(Vector2(ex, ey), 2.2 * s * (1.0 - life), Color(1.0, 0.8, 0.3, 1.0 - life))
	# The glowing B.
	var font := FanMenu.title_font()
	var size_px := int(40.0 * s)
	var off := Vector2(-11.0 * s, 13.0 * s)
	for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		draw_string(font, p + off + d * s, "B", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color(1.0, 0.35, 0.05, 0.9))
	draw_string(font, p + off, "B", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color(1.0, 0.97, 0.75))


func _draw_impact(r, dest: Vector2, a: float) -> void:
	var k := clampf(a / Battle.REWARD_IMPACT, 0.0, 1.0)
	var col := FLAME if r.kind == "burst" else CYAN
	draw_arc(dest, 10.0 + 38.0 * k, 0.0, TAU, 36, Color(col, 1.0 - k), 3.0)
	draw_arc(dest, 6.0 + 24.0 * k, 0.0, TAU, 28, Color(1, 1, 1, (1.0 - k) * 0.8), 2.0)
	draw_circle(dest, 16.0 * (1.0 - k), Color(1, 1, 1, (1.0 - k) * 0.7))
	for j in 8:
		var ang: float = j * TAU / 8.0 + r.id
		var from := dest + Vector2(cos(ang), sin(ang)) * (8.0 + 20.0 * k)
		var to := dest + Vector2(cos(ang), sin(ang)) * (14.0 + 34.0 * k)
		draw_line(from, to, Color(col.lightened(0.4), 1.0 - k), 2.0)
