class_name BattleHudDraw
extends Control
## Static drawing primitives shared by BattleHud and other HUD components.
## Extracted from battle_hud.gd in Etapa 4; BattleHud inherits these methods
## and constants, so external BattleHud.slant()/BattleHud.element_icon() calls
## keep working.

const LIME := Color("d7fd6a")
const CORAL := Color("ff624f")
const AQUA := Color("62d8e7")
const GOLD := Color("f7cb78")
const INK := Color("080e18")
const NAVY := Color("101c2c")
const CREAM := Color("f0eedf")
const ARMOR_BG := Color("9aa3ad")  ## D-1026: grey metallic badge (colour approved by the creator)
const ARMOR_FG := Color("1c2228")
const BURN_TOP := Color("7d2e06")
const BURN_BOT := Color("cc5b0c")
const BURN_TEXT := Color("fff1d4")
const TAG_LIFT := 44.0  ## D-982: higher again (D-981: 16), so the tag does not cover its enemy

static var _fixed_fps := -1.0
static var _elem_icons: Dictionary = {}

static func clock_ms() -> int:
	if _fixed_fps < 0.0:
		_fixed_fps = 0.0
		var args := OS.get_cmdline_args()
		for i in args.size():
			if args[i] == "--fixed-fps" and i + 1 < args.size():
				_fixed_fps = float(args[i + 1])
	if _fixed_fps > 0.0:
		return int(float(Engine.get_frames_drawn()) * 1000.0 / _fixed_fps)
	return Time.get_ticks_msec()

static func slant(c: CanvasItem, r: Rect2, skew: float, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)]), color)

static func slant_texture(c: CanvasItem, r: Rect2, skew: float, tex: Texture2D) -> void:
	var pts := PackedVector2Array([
		Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)])
	var tex_aspect := float(tex.get_width()) / float(tex.get_height())
	var box_aspect := r.size.x / r.size.y
	var u_span := 1.0
	var v_span := 1.0
	if box_aspect < tex_aspect:
		u_span = box_aspect / tex_aspect
	else:
		v_span = tex_aspect / box_aspect
	var uvs := PackedVector2Array()
	for p in pts:
		var k := (p - r.position) / r.size
		uvs.append(Vector2(0.5 + (k.x - 0.5) * u_span, 0.5 + (k.y - 0.5) * v_span))
	c.draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, tex)

static func draw_mp_fast_marker(ci: CanvasItem, top_center: Vector2, now: int) -> void:
	var t := float(now) * 0.001
	for i in 2:  # i = 0 is the upper chevron: it leads the pulse
		var y := top_center.y - 14.0 + float(i) * 3.6  # 5 px higher than the first version (creator)
		var a := 0.55 + 0.45 * sin(t * 7.0 - float(i) * 1.3)
		var col := Color("38bdf8").lightened(0.35)
		col.a = a
		var pts := PackedVector2Array([Vector2(top_center.x - 5.5, y + 3.6), Vector2(top_center.x, y), Vector2(top_center.x + 5.5, y + 3.6)])
		ci.draw_polyline(pts, col, 2.2)

static func slant_xform(r: Rect2, skew: float) -> Transform2D:
	var k := skew / maxf(r.size.y, 1.0)
	return Transform2D(Vector2(1.0, 0.0), Vector2(-k, 1.0), Vector2(k * (r.position.y + r.size.y * 0.5), 0.0))

static func draw_mp_water(ci: CanvasItem, r: Rect2, skew: float, c: Combatant, now: int) -> void:
	var mp_blue := Color("38bdf8")
	var charge := 1.0 if c.mp >= c.max_mp else clampf(c.mp_regen_timer / Combatant.MP_REGEN_INTERVAL, 0.0, 1.0)
	var t := float(now) * 0.001
	var top := r.position.y
	var h := r.size.y
	slant(ci, r, skew, Color("0c2a3b"))
	var level := r.end.y - h * charge
	if charge > 0.0:
		for layer in 2:
			var amp := 1.7 if layer == 0 else 1.2
			var phase := t * (2.6 if layer == 0 else -3.4) + float(layer) * 1.9
			var col := mp_blue.lightened(0.32) if layer == 0 else mp_blue
			col.a = 0.72 if layer == 0 else 1.0
			var steps := 10
			var pts := PackedVector2Array()
			# the surface, from the left edge to the right edge at its own height
			var y_l := clampf(level + amp * sin(phase), top, r.end.y)
			var y_r := clampf(level + amp * sin(float(steps) * 0.95 + phase), top, r.end.y)
			var xl := r.position.x + skew * (1.0 - (y_l - top) / h)
			var xr := r.end.x - skew * ((y_r - top) / h)
			for i in steps + 1:
				var f := float(i) / float(steps)
				var y := level + amp * sin(float(i) * 0.95 + phase) if charge < 1.0 else top + 1.0 + amp * 0.5 * sin(float(i) * 0.95 + phase)
				y = clampf(y, top, r.end.y)
				var x := lerpf(r.position.x + skew * (1.0 - (y - top) / h), r.end.x - skew * ((y - top) / h), f)
				pts.append(Vector2(x, y))
			pts.append(Vector2(r.end.x - skew, r.end.y))
			pts.append(Vector2(r.position.x, r.end.y))
			ci.draw_colored_polygon(pts, col)
		# foam on the crest of the front wave
		var foam := PackedVector2Array()
		for i in 11:
			var f2 := float(i) / 10.0
			var y2 := level + 1.2 * sin(float(i) * 0.95 + t * -3.4 + 1.9) if charge < 1.0 else top + 1.0
			y2 = clampf(y2, top, r.end.y)
			var x2 := lerpf(r.position.x + skew * (1.0 - (y2 - top) / h), r.end.x - skew * ((y2 - top) / h), f2)
			foam.append(Vector2(x2, y2))
		ci.draw_polyline(foam, Color(1, 1, 1, 0.7), 1.0)
		# bubbles rising through the water, inside the slanted walls
		var water_h := r.end.y - level
		for k in 4:
			var u := fposmod(t * 0.22 + float(k) * 0.29, 1.0)
			var by := r.end.y - u * water_h
			if by > level + 2.0:
				var kk := (by - top) / h
				var x_min := r.position.x + skew * (1.0 - kk) + 2.5
				var x_max := r.end.x - skew * kk - 2.5
				var bx := x_min + fposmod(float(k) * 3.1 + sin(t * 1.7 + float(k)) * 1.6, maxf(x_max - x_min, 1.0))
				ci.draw_circle(Vector2(bx, by), 1.1, Color(1, 1, 1, 0.45 * (1.0 - u * 0.5)))
	slant_outline(ci, r, skew, Color("061a26"), 1.0)

static func slant_outline(c: CanvasItem, r: Rect2, skew: float, color: Color, width: float) -> void:
	var p := _slant_pts(r, skew)
	p.append(p[0])
	c.draw_polyline(p, color, width)

static func draw_chrome_border(c: CanvasItem, r: Rect2, skew: float, now: int, width := 4.0, flush_left := false, outside := false) -> void:
	var rr := r.grow(width * 0.5) if outside else r.grow(-width * 0.5)  # inside the edge it is never clipped; outside it never covers what the card draws
	var pts := _slant_pts(rr, skew)
	if flush_left:  # the card has a square strip on its left (the MP charge bar): the border goes around the strip too, so it covers the WHOLE card
		pts = PackedVector2Array([Vector2(rr.position.x, rr.position.y), Vector2(rr.end.x, rr.position.y), Vector2(rr.end.x - skew, rr.end.y), Vector2(rr.position.x, rr.end.y)])
	var n := pts.size()
	var lens: Array[float] = []
	var total := 0.0
	for i in n:
		var l := pts[i].distance_to(pts[(i + 1) % n])
		lens.append(l)
		total += l
	var steps := 90
	var prev := pts[0]
	for k in range(1, steps + 1):
		var d := total * float(k) / float(steps)
		var acc := 0.0
		var cur := pts[0]
		for i in n:
			if d <= acc + lens[i] or i == n - 1:
				cur = pts[i].lerp(pts[(i + 1) % n], clampf((d - acc) / maxf(lens[i], 0.001), 0.0, 1.0))
				break
			acc += lens[i]
		var t := float(k) / float(steps)
		var band := 0.5 + 0.5 * sin(t * TAU * 3.0 - float(now) * 0.003375)
		var glint := pow(maxf(0.0, sin(t * TAU * 2.0 - float(now) * 0.0021)), 8.0)
		var col := Color(0.20, 0.25, 0.35).lerp(Color(0.80, 0.86, 0.96), pow(band, 1.3)).lerp(Color.WHITE, glint)
		c.draw_line(prev, cur, col, width)
		prev = cur

static func text_right(c: CanvasItem, font: Font, right_x: float, y: float, text: String, size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	c.draw_string(font, Vector2(right_x - w, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func log_color(text: String) -> Color:
	var t := text.to_lower()
	if t.contains("bubble shield") or t.contains("shield") or t.contains("absorb"):
		return Color("8fe8ff")
	if t.contains("quebra") or t.contains("rompe") or t.contains("interromp") or t.contains("derrotad") or t.contains("caiu"):
		return Color("ff8a72")
	if t.contains("dodge") or t.contains("evade") or t.contains("burst") or t.contains("perfect"):
		return Color("d7fd6a")
	if t.contains("guard") or t.contains("block"):
		return Color("8db6ff")
	if t.contains("burn") or t.contains("fire"):
		return Color("ffb15a")
	if t.contains("heal") or t.contains("restore") or t.contains("media"):
		return Color("8dffb0")
	if t.contains("weak") or t.contains("critical") or t.contains("crit"):
		return Color("ffd84a")
	if t.contains("taunt") or t.contains("provoke"):
		return Color("ff9ec4")
	return Color("f0eedf")

static func status_line(c: Combatant, include_buffs := true) -> String:
	var parts: Array[String] = []
	if c.is_shielded():
		parts.append("SHIELD %d | %.1fs" % [c.shield_hp, c.shield_timer])
	if c.is_guarding():
		parts.append("GUARD %.1fs" % c.guard_timer)
	if c.is_stunned():
		parts.append("STUN %.1fs" % c.stun_timer)
	if c.is_burning():
		parts.append("BURN %.1fs" % burn_left(c))
	if c.is_blind():
		parts.append("BLIND %.1fs" % c.blind_timer)
	if c.taunted_by != null:
		parts.append("TAUNT")
	if c.is_invulnerable:
		parts.append("INVULN")
	if c.is_magic_immune():
		parts.append("MAG. IMMUNE %.1fs" % c.magic_immune_timer)
	if include_buffs and c.atk_buff != 0:
		parts.append("ATK %+d" % c.atk_buff)
	if include_buffs and c.def_buff != 0:
		parts.append("DEF %+d" % c.def_buff)
	if include_buffs and c.speed_buff != 0:
		parts.append("SPD %+d" % c.speed_buff)
	return " | ".join(parts) if not parts.is_empty() else "No active effects"

static func draw_flames(ci: CanvasItem, rect: Rect2, now: int, power: float) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var base_y := rect.position.y + rect.size.y * 0.55
	ci.draw_circle(Vector2(cx, rect.position.y + rect.size.y * 0.4), rect.size.x * 1.1, Color(1.0, 0.55, 0.1, (0.12 + 0.05 * sin(now * 0.01)) * power))
	for j in 5:
		var ph := now * 0.013 + j * 1.9
		var h := (13.0 + 8.0 * sin(ph)) * power * (rect.size.y / 17.0 + 0.4)
		var x := rect.position.x + (j + 0.5) * rect.size.x / 5.0
		var w := rect.size.x / 4.5
		var sway := sin(ph * 0.7) * 2.5
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w, base_y), Vector2(x + sway, base_y - h), Vector2(x + w, base_y)]), Color(1.0, 0.42, 0.08, 0.9))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.55, base_y), Vector2(x + sway * 0.7, base_y - h * 0.62), Vector2(x + w * 0.55, base_y)]), Color(1.0, 0.85, 0.3, 0.95))

static func element_icon(e: Element.Type) -> Texture2D:
	var names := {Element.Type.FISICO: "neutral", Element.Type.FOGO: "fire", Element.Type.AGUA_GELO: "water_ice", Element.Type.RAIO: "electric", Element.Type.PSIQUICO: "psychic", Element.Type.VENENO: "nature", Element.Type.SOM: "sound", Element.Type.TERRA: "earth", Element.Type.VENTO: "wind", Element.Type.LUZ: "light", Element.Type.TREVAS: "dark"}
	var key: String = names.get(e, "neutral")
	if not _elem_icons.has(key):
		var path := "res://assets/ui/icons/elements/%s.svg" % key
		_elem_icons[key] = load(path) if ResourceLoader.exists(path) else null
	return _elem_icons[key]

static func draw_dizzy(ci: CanvasItem, pr: Rect2, k: float, now: int, scale_k := 1.0) -> void:
	if k <= 0.01:
		return
	var tt := now / 1000.0
	for e in 2:
		var ec := pr.position + Vector2(pr.size.x * (0.36 if e == 0 else 0.64), pr.size.y * 0.42)
		ci.draw_circle(ec, 7.0 * scale_k, Color(1, 1, 1, k))
		hud_spiral(ci, ec, 6.0 * scale_k, tt * (7.0 if e == 0 else -7.0), Color(0.07, 0.1, 0.16, k), 1.6 * scale_k)
	var sizes := [6.0, 4.5, 7.0, 5.0]
	var spins := [3.0, -4.0, 2.0, -2.5]
	for si in 4:
		var a := tt * 3.0 + float(si) * TAU / 4.0
		var sp := pr.position + Vector2(pr.size.x * 0.5, 2.0) + Vector2(cos(a) * pr.size.x * 0.43, sin(a) * 5.0 * scale_k)
		hud_star(ci, sp, float(sizes[si]) * k * scale_k, tt * float(spins[si]), Color(1.0, 0.86, 0.15, k))

static func hud_star(ci: CanvasItem, c: Vector2, r: float, ang: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := ang - PI * 0.5 + float(i) * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.42))
	ci.draw_colored_polygon(pts, col)

static func hud_spiral(ci: CanvasItem, c: Vector2, r: float, ang: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var f := float(i) / 39.0
		var a := ang + f * TAU * 2.5
		pts.append(c + Vector2(cos(a), sin(a)) * r * f)
	ci.draw_polyline(pts, col, w, true)

static func burn_left(c: Combatant) -> float:
	return maxf(c.burn_clock + float(c.burn_ticks_left - 1) * Battle.BURN_INTERVAL, 0.0)

static func _slant_pts(r: Rect2, skew: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)])

static func draw_card_bg(ci: CanvasItem, r: Rect2, skew: float, normal: Color, k: float, max_flame: float, now: int) -> void:
	if k <= 0.01:
		slant(ci, r, skew, normal)
		return
	var pulse := 0.5 + 0.5 * sin(now * 0.0094)
	var top := normal.lerp(BURN_TOP.lerp(BURN_BOT, 0.1 + 0.2 * pulse), k)
	var bot := normal.lerp(BURN_BOT.lerp(Color("e8841f"), pulse * 0.6), k)
	for i in 4:
		ci.draw_colored_polygon(_slant_pts(r.grow(2.0 + float(i) * 2.5), skew), Color(1.0, 0.42, 0.08, (0.09 + 0.05 * pulse) * k / float(i + 1)))
	ci.draw_polygon(_slant_pts(r, skew), PackedColorArray([top, top, bot, bot]))
	var n := 26
	var soot := Color(0.05, 0.02, 0.01, 0.62 * k)
	var ember := Color(1.0, 0.5, 0.1, (0.45 + 0.35 * pulse) * k)
	var top_in := PackedVector2Array()
	var bot_in := PackedVector2Array()
	var top_out := PackedVector2Array()
	var bot_out := PackedVector2Array()
	for i in n:
		var f := float(i) / float(n - 1)
		var d := 2.5 + 3.0 * absf(sin(float(i) * 1.7 + now * 0.004)) + 2.0 * absf(sin(float(i) * 2.9 - now * 0.003))
		var x := lerpf(r.position.x + skew, r.end.x, f)
		var xb := lerpf(r.position.x, r.end.x - skew, f)
		top_out.append(Vector2(x, r.position.y))
		top_in.append(Vector2(x, r.position.y + d))
		bot_out.append(Vector2(xb, r.end.y))
		bot_in.append(Vector2(xb, r.end.y - d * 0.6))
	for strip in [[top_out, top_in], [bot_out, bot_in]]:
		var a_pts: PackedVector2Array = strip[0]
		var b_pts: PackedVector2Array = strip[1]
		var poly := PackedVector2Array(a_pts)
		for j in range(b_pts.size() - 1, -1, -1):
			poly.append(b_pts[j])
		ci.draw_colored_polygon(poly, soot)
		ci.draw_polyline(b_pts, ember, 1.0)
	var step := (r.size.x - skew) / float(n)
	for i in n:
		var h := clampf(0.6 + 0.5 * sin(now * 0.011 + i * 1.7) + 0.35 * sin(now * 0.017 + i * 2.9) + 0.6 * maxf(sin(now * 0.0045 - i * 0.5), 0.0), 0.2, 1.7) * max_flame * 0.95 * k
		var x0 := r.position.x + float(i) * step
		var lean := sin(now * 0.007 + i * 2.3) * 4.0
		var base_y := r.end.y - 0.5
		var cols := [Color(0.85, 0.25, 0.04, 0.8), Color(1.0, 0.54, 0.11, 0.8), Color(1.0, 0.82, 0.29, 0.85)]
		for layer in 3:
			var lh := h * (1.0 - 0.28 * float(layer))
			var half := step * (0.62 - 0.17 * float(layer))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x0 + step * 0.5 - half, base_y), Vector2(x0 + step * 0.5 + lean * (1.0 - 0.2 * float(layer)), base_y - lh), Vector2(x0 + step * 0.5 + half, base_y)]), cols[layer])

static func draw_burn_embers(ci: CanvasItem, body: Rect2, k: float, now: int) -> void:
	if k <= 0.01:
		return
	for j in 16:
		var ph := fposmod(now * 0.0011 + float(j) * 0.37, 1.0)
		var x := body.position.x + 8.0 + fposmod(float(j) * 47.3, body.size.x - 16.0) + sin(ph * 6.0 + float(j)) * 4.0
		var y := body.end.y - 2.0 - ph * 32.0
		var sz := 1.5 * (1.0 - ph * 0.5)
		var p := Vector2(x, y)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -sz), p + Vector2(sz, 0), p + Vector2(0, sz), p + Vector2(-sz, 0)]), Color(Color("ffd24a").lerp(Color("ff8a1c"), ph), (1.0 - ph) * k * 0.9))

static func draw_burn_pending(ci: CanvasItem, bar: Rect2, c: Combatant, shown_frac: float) -> void:
	if not c.is_burning() or c.max_hp <= 0:
		return
	var fw := bar.size.x * clampf(shown_frac, 0.0, 1.0)
	var pw := clampf(float(c.burn_ticks_left * Battle.BURN_DMG) / float(c.max_hp) * bar.size.x, 0.0, fw)
	if pw < 0.5:
		return
	var px := bar.position.x + fw - pw
	ci.draw_rect(Rect2(px, bar.position.y, pw, bar.size.y), Color("ffb347", 0.5))
	var s := px - bar.size.y
	while s < px + pw:
		var a := Vector2(clampf(s, px, px + pw), bar.end.y)
		var b := Vector2(clampf(s + bar.size.y, px, px + pw), bar.position.y)
		ci.draw_line(a, b, Color(0.1, 0.02, 0.0, 0.85), 1.0)
		s += 2.4

static func draw_pos_marks(ci: CanvasItem, center: Vector2, step: int) -> void:
	for i in 5:
		var r := Rect2(center + Vector2((i - 2) * 14.0 - 5.0, 0.0), Vector2(10.0, 5.0))
		var here := i - 2 == step
		ci.draw_rect(r, Color(0.95, 0.93, 0.85, 0.95) if here else Color(0.4, 0.5, 0.6, 0.45))
		if i == 2 and not here:
			ci.draw_rect(Rect2(r.position + Vector2(3.0, -2.0), Vector2(4.0, 2.0)), Color(0.95, 0.93, 0.85, 0.5))  # The middle


