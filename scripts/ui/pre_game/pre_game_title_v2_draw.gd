class_name PreGameTitleV2Draw
extends RefCounted
## D-1265: title screen v2 2D layer (slash title as art + slanted menu plates + enter hint).
## Static draw helpers shared by PreGameViewBoot (real flow) and the debug scene title_v2.
## Design space 1280x720, scaled by min(sx, sy); everything is anchored so nothing is cut.

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")


static func ease_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


static func _fs(base: float, s: float) -> int:
	return maxi(8, int(round(base * s)))


## Word with a stepped black extrusion (solid slab look) over an optional coral echo.
static func _word(ci: CanvasItem, text: String, pos: Vector2, fsize: int, face: Color, skew: float,
		rot: float, depth: float, echo: bool, dx: float = 0.0) -> void:
	var font := PreGameDraw.title_font()
	var base := Transform2D(0.0, pos) * Transform2D(deg_to_rad(rot), Vector2.ZERO) \
		* PreGameDraw.skew_xform(skew) * Transform2D(0.0, Vector2(dx, 0.0))
	var asc := font.get_ascent(fsize)
	if echo:
		ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(depth * 2.1, depth * 2.1)))
		ci.draw_string(font, Vector2(0, asc), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize,
			Color(PreGameDraw.CORAL, 0.55))
	for i in range(int(ceil(depth)), 0, -1):
		ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(i, i) * 0.9))
		ci.draw_string(font, Vector2(0, asc), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, PreGameDraw.INK)
	ci.draw_set_transform_matrix(base)
	ci.draw_string(font, Vector2(0, asc), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, face)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func draw_backdrop_gradient(ci: CanvasItem, size: Vector2) -> void:
	var gw := size.x * 0.62
	var c := Color(0.02, 0.05, 0.09, 0.82)
	var z := Color(0.02, 0.05, 0.09, 0.0)
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(gw, 0), Vector2(gw * 0.8, size.y), Vector2(0, size.y)]),
		PackedColorArray([c, z, z, c]))
	# UX: bottom shade grounds the footer/hint/context card, top shade calms the rail area.
	var b0 := Color(0.01, 0.03, 0.06, 0.0)
	var b1 := Color(0.01, 0.03, 0.06, 0.62)
	ci.draw_polygon(PackedVector2Array([Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.72), Vector2(size.x, size.y), Vector2(0, size.y)]),
		PackedColorArray([b0, b0, b1, b1]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y * 0.14), Vector2(0, size.y * 0.14)]),
		PackedColorArray([Color(b1, 0.45), Color(b1, 0.45), b0, b0]))


## Title art + kicker plate. `t` = seconds since the title appeared.
static func draw_title(ci: CanvasItem, size: Vector2, t: float) -> void:
	var sx := size.x / 1280.0
	var sy := size.y / 720.0
	var s := minf(sx, sy)
	var a1 := ease_out(t / 0.7)
	var k := 0.8  # creator: logo 20% smaller
	var slide := (1.0 - a1) * -600.0 * s
	# Creator: one word, flat text (no extrusion/echo/background): CRAWL white, MON red.
	var fsz := _fs(150.0 * k, s)
	var pos := Vector2(44.0 * s + slide, 70.0 * sy)
	var crawl_w := PreGameDraw.title_font().get_string_size("CRAWL", HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	_word(ci, "CRAWL", pos, fsz, PreGameDraw.PAPER, -13.0, -2.2, 0.0, false)
	_word(ci, "MON", pos, fsz, PreGameDraw.CORAL, -13.0, -2.2, 0.0, false, crawl_w)


## Menu plates; `add_hit` is called as add_hit(hit_id: String, xform: Transform2D, size: Vector2).
## `mt` = seconds since the menu appeared. Returns nothing; plates stagger in.
static func draw_plates(ci: CanvasItem, size: Vector2, mt: float, menu_index: int, add_hit: Callable) -> void:
	var sx := size.x / 1280.0
	var sy := size.y / 720.0
	var s := minf(sx, sy)
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	var clip := PackedVector2Array([Vector2(0.04, 0.0), Vector2(1.0, 0.0), Vector2(0.96, 1.0), Vector2(0.0, 1.0)])
	var n := PreGameCatalog.MENU_ITEMS.size()
	var plate_w := 330.0 * s
	var base_y := 235.0 * sy  # creator: menu higher, closer to the logo
	for idx in range(n):
		var item: Dictionary = PreGameCatalog.MENU_ITEMS[idx]
		var focused := idx == menu_index
		var pa := ease_out((mt - 0.05 - idx * 0.09) / 0.45)
		var h := (54.0 if focused else 46.0) * s
		var fill := Color(0.075, 0.12, 0.175, 0.94)  # UX: lighter than the scene so idle plates read as buttons
		if focused:
			fill = PreGameDraw.CORAL if str(item.get("id", "")) == "quit" else PreGameDraw.LIME_FAN
		var cx := 28.0 * s + plate_w * 0.5 + (float(idx) * 16.0 + (22.0 if focused else 0.0)) * s \
			- (1.0 - pa) * 420.0 * s
		var cy := base_y + float(idx) * 76.0 * s + 30.0 * s
		var psize := Vector2(plate_w, h)
		var xf := PreGameDraw.draw_card(ci, Vector2(cx, cy), psize, -1.6, -10.0, fill, Color.BLACK, 2.0,
			Vector2(8, 8) * s if focused else Vector2(5, 5) * s, Color(0, 0, 0, 0.7), [], clip)
		add_hit.call("menu:%d" % idx, xf, psize)
		var d := 5.5 * s
		ci.draw_set_transform_matrix(xf * PreGameDraw.skew_xform(10.0) * Transform2D(deg_to_rad(45.0),
			Vector2(-psize.x * 0.5 + 24.0 * s, 0.0)))
		ci.draw_rect(Rect2(Vector2(-d, -d), Vector2(d, d) * 2.0), PreGameDraw.INK if focused else Color("ff624f"))
		PreGameDraw.push_counter_skew(ci, xf, -10.0)
		var lsz := _fs(30.0, s)
		var lbase := (display.get_ascent(lsz) - display.get_descent(lsz)) * 0.5
		ci.draw_string(display, Vector2(-psize.x * 0.5 + 40.0 * s, lbase), str(item.get("label", "")),
			HORIZONTAL_ALIGNMENT_LEFT, -1, lsz, PreGameDraw.INK if focused else PreGameDraw.PAPER)
		var tsz := _fs(11.0, s)
		var tbase := (mono.get_ascent(tsz) - mono.get_descent(tsz)) * 0.5
		ci.draw_string(mono, Vector2(-psize.x * 0.5, tbase), str(item.get("tag", "")),
			HORIZONTAL_ALIGNMENT_RIGHT, psize.x - 22.0 * s, tsz,
			Color(PreGameDraw.INK, 0.72) if focused else PreGameDraw.TEXT_SUB)
		PreGameDraw.pop_xform(ci)


## "Press enter" plate (title state, or the debug scene). Returns its xform and size for hit tests.
static func draw_enter_hint(ci: CanvasItem, size: Vector2, t: float, hover: bool) -> Array:
	var s := minf(size.x / 1280.0, size.y / 720.0)
	var display := PreGameDraw.title_font()
	var blink := 1.0 if hover else 0.8 + 0.2 * sin(t * 3.0)
	# UX: the single call to action sits bottom-left, under the logo's column, clear of the character.
	var psize := Vector2(520.0 * s, 44.0 * s)
	var hx := PreGameDraw.draw_card(ci, Vector2(40.0 * s + psize.x * 0.5, size.y - 52.0 * s), psize, -1.6, -8.0,
		Color(PreGameDraw.LIME if hover else PreGameDraw.PAPER, blink), Color.BLACK, 2.0,
		Vector2(7, 7) * s, Color(0, 0, 0, 0.9), [],
		PackedVector2Array([Vector2(0, 0), Vector2(0.97, 0), Vector2(1, 1), Vector2(0.03, 1)]))
	PreGameDraw.push_counter_skew(ci, hx, -8.0)
	ci.draw_string(display, Vector2(-psize.x * 0.5 + 18.0 * s, 8.0 * s), "CLICK OR PRESS ANY KEY // ENTER LABYRINTH",
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(21.0, s), PreGameDraw.INK)
	PreGameDraw.pop_xform(ci)
	return [hx, psize]


## Small CRAWL (white) + MON (red) mark, same flat slanted text as the title. `pos` = top-left.
static func _mini_logo(ci: CanvasItem, pos: Vector2, fsz: int) -> void:
	var w := PreGameDraw.title_font().get_string_size("CRAWL", HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	_word(ci, "CRAWL", pos, fsz, PreGameDraw.PAPER, -13.0, -2.2, 0.0, false)
	_word(ci, "MON", pos, fsz, PreGameDraw.CORAL, -13.0, -2.2, 0.0, false, w)


## Quit modal in the v2 language: cold dimmed scene, one slanted dark plate, same logo mark and
## the menu's plate buttons (lime on focus, coral for the destructive one). Hits: quit_cancel / quit_confirm.
static func draw_quit_modal(ci: CanvasItem, size: Vector2, confirm_index: int, add_hit: Callable) -> void:
	var s := minf(size.x / 1280.0, size.y / 720.0)
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.03, 0.06, 0.72))
	var c := size * 0.5
	var psize := Vector2(520.0, 250.0) * s
	var clip := PackedVector2Array([Vector2(0.03, 0.0), Vector2(1.0, 0.0), Vector2(0.97, 1.0), Vector2(0.0, 1.0)])
	var xf := PreGameDraw.draw_card(ci, c, psize, -1.6, -10.0, Color(0.075, 0.12, 0.175, 0.97), Color.BLACK, 2.0,
		Vector2(9, 9) * s, Color(0, 0, 0, 0.75), [], clip)
	PreGameDraw.push_counter_skew(ci, xf, -10.0)
	_mini_logo_local(ci, Vector2(-psize.x * 0.5 + 30.0 * s, -psize.y * 0.5 + 14.0 * s), _fs(40.0, s))
	var tsz := _fs(34.0, s)
	ci.draw_string(display, Vector2(-psize.x * 0.5 + 34.0 * s, -8.0 * s), "QUIT GAME?",
		HORIZONTAL_ALIGNMENT_LEFT, -1, tsz, PreGameDraw.PAPER)
	var bsz := _fs(13.0, s)
	ci.draw_string(mono, Vector2(-psize.x * 0.5 + 34.0 * s, 24.0 * s), "Exit the Crawlmon desktop application?",
		HORIZONTAL_ALIGNMENT_LEFT, -1, bsz, PreGameDraw.TEXT_SUB)
	PreGameDraw.pop_xform(ci)
	var bw := 200.0 * s
	var bh := 46.0 * s
	var by := psize.y * 0.5 - 52.0 * s
	var specs := [
		["quit_cancel", "[X] CANCEL", -bw * 0.5 - 14.0 * s, confirm_index == 0, PreGameDraw.LIME_FAN],
		["quit_confirm", "QUIT [ENTER]", bw * 0.5 + 14.0 * s, confirm_index == 1, PreGameDraw.CORAL],
	]
	for sp in specs:
		var focused: bool = sp[3]
		var fill := Color(0.04, 0.07, 0.11, 0.96)
		if focused:
			fill = sp[4]
		var bs := Vector2(bw, bh)
		var bx := PreGameDraw.draw_card(ci, xf * Vector2(float(sp[2]), by), bs, -1.6, -10.0, fill, Color.BLACK, 2.0,
			Vector2(6, 6) * s if focused else Vector2(4, 4) * s, Color(0, 0, 0, 0.7), [], clip)
		add_hit.call(str(sp[0]), bx, bs)
		PreGameDraw.push_counter_skew(ci, bx, -10.0)
		var lsz := _fs(22.0, s)
		var lb := (display.get_ascent(lsz) - display.get_descent(lsz)) * 0.5
		ci.draw_string(display, Vector2(-bs.x * 0.5, lb), str(sp[1]), HORIZONTAL_ALIGNMENT_CENTER, bs.x, lsz,
			PreGameDraw.INK if focused else PreGameDraw.PAPER)
		PreGameDraw.pop_xform(ci)


## Same mark inside an already pushed local transform (no own transform).
static func _mini_logo_local(ci: CanvasItem, pos: Vector2, fsz: int) -> void:
	var font := PreGameDraw.title_font()
	var w := font.get_string_size("CRAWL", HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	var asc := font.get_ascent(fsz)
	ci.draw_string(font, pos + Vector2(0, asc), "CRAWL", HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, PreGameDraw.PAPER)
	ci.draw_string(font, pos + Vector2(w, asc), "MON", HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, PreGameDraw.CORAL)


## Loading screen in the v2 language: cold dark backdrop, logo mark, one slanted plate with label,
## target name and a lime progress bar. `t` = seconds (animates the bar sheen only).
static func draw_loading(ci: CanvasItem, size: Vector2, label: String, progress: float, t: float) -> void:
	var s := minf(size.x / 1280.0, size.y / 720.0)
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.045, 0.075, 1.0))
	draw_backdrop_gradient(ci, size)
	var psize := Vector2(640.0, 170.0) * s
	var clip := PackedVector2Array([Vector2(0.03, 0.0), Vector2(1.0, 0.0), Vector2(0.97, 1.0), Vector2(0.0, 1.0)])
	var xf := PreGameDraw.draw_card(ci, size * 0.5, psize, -1.6, -10.0, Color(0.075, 0.12, 0.175, 0.97), Color.BLACK,
		2.0, Vector2(9, 9) * s, Color(0, 0, 0, 0.75), [], clip)
	PreGameDraw.push_counter_skew(ci, xf, -10.0)
	var left := -psize.x * 0.5 + 34.0 * s
	var top := -psize.y * 0.5 + 18.0 * s
	_mini_logo_local(ci, Vector2(left, top), _fs(34.0, s))
	var lsz := _fs(32.0, s)
	ci.draw_string(display, Vector2(left, top + 62.0 * s + display.get_ascent(lsz)), label.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, lsz, PreGameDraw.PAPER)
	var bar := Rect2(Vector2(left, top + 120.0 * s), Vector2(psize.x - 150.0 * s, 10.0 * s))
	ci.draw_rect(bar, PreGameDraw.INK)
	var p := clampf(progress, 0.0, 1.0)
	if p > 0.0:
		ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * p, bar.size.y)), PreGameDraw.LIME_FAN)
		var sheen := fposmod(t * 0.8, 1.0) * bar.size.x * p
		ci.draw_rect(Rect2(bar.position + Vector2(sheen, 0), Vector2(12.0 * s, bar.size.y)).intersection(
			Rect2(bar.position, Vector2(bar.size.x * p, bar.size.y))), Color(1, 1, 1, 0.35))
	var psz := _fs(15.0, s)
	ci.draw_string(mono, Vector2(bar.end.x + 14.0 * s, bar.position.y + 9.0 * s), "%d%%" % int(round(p * 100.0)),
		HORIZONTAL_ALIGNMENT_LEFT, -1, psz, PreGameDraw.LIME_FAN)
	PreGameDraw.pop_xform(ci)


static var _paper_tex: ImageTexture = null


## Light-yellow paper grain (procedural, tiled): speckles + faint horizontal fibres, mostly transparent.
static func paper_texture() -> ImageTexture:
	if _paper_tex != null:
		return _paper_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1265
	for y in n:
		for x in n:
			var v := rng.randf()
			var a := 0.0
			if v > 0.82:
				a = rng.randf_range(0.05, 0.16)
			img.set_pixel(x, y, Color(0.45, 0.36, 0.14, a))
	for i in 70:  # fibres
		var fx := rng.randi_range(0, n - 1)
		var fy := rng.randi_range(0, n - 1)
		var fl := rng.randi_range(6, 22)
		for k in fl:
			var px := (fx + k) % n
			var c := img.get_pixel(px, fy)
			img.set_pixel(px, fy, Color(0.45, 0.36, 0.14, minf(c.a + 0.1, 0.22)))
	_paper_tex = ImageTexture.create_from_image(img)
	return _paper_tex


## Save card (top right, only when the game has a save): light-yellow paper block with the
## leader icon stamped on its left end + 4 stats (creator): leader level, respect level, cascos
## balance and playtime. `info` keys: level, respect, cascos (ints), play_seconds (float).
static func draw_save_card(ci: CanvasItem, size: Vector2, icon: Texture2D, info: Dictionary = {}) -> void:
	var s := minf(size.x / 1280.0, size.y / 720.0)
	var csize := Vector2(400.0, 86.0) * s
	var center := Vector2(size.x - 40.0 * s - csize.x * 0.5, 112.0 * s)
	var clip := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.97, 0.0), Vector2(1.0, 1.0), Vector2(0.03, 1.0)])
	var xf := PreGameDraw.draw_card(ci, center, csize, -7.0, -8.0, Color("f5eeb0"), Color.BLACK, 2.0,
		Vector2(7, 7) * s, Color(0, 0, 0, 0.85), [], clip)
	var poly := PreGameDraw.local_poly(csize, clip)
	var uvs := PackedVector2Array()
	for p in poly:
		uvs.append((p + csize * 0.5) / 128.0 * 1.6)
	ci.draw_set_transform_matrix(xf)
	var prev_rep := ci.texture_repeat
	ci.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ci.draw_polygon(poly, PackedColorArray([Color.WHITE]), uvs, paper_texture())
	ci.texture_repeat = prev_rep
	# Stamp: ink ring + monochrome icon, slightly rotated, overlapping the card's left end.
	var r := 52.0 * s
	var sc := Vector2(-csize.x * 0.5 + 6.0 * s, 0.0)
	ci.draw_set_transform_matrix(xf * Transform2D(deg_to_rad(-8.0), sc))
	var ink := Color(0.12, 0.09, 0.05, 0.82)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, ink, 3.5 * s, true)
	ci.draw_arc(Vector2.ZERO, r * 0.88, 0.0, TAU, 48, Color(ink, 0.5), 1.5 * s, true)
	if icon != null:
		# Circular cut of the icon (opaque square portraits), warm print tint.
		var rr := r * 0.84
		var disc := PackedVector2Array()
		var duv := PackedVector2Array()
		for i in 48:
			var ang := TAU * float(i) / 48.0
			var v := Vector2(cos(ang), sin(ang))
			disc.append(v * rr)
			duv.append(v * 0.5 + Vector2(0.5, 0.5))
		ci.draw_polygon(disc, PackedColorArray([Color(1.0, 0.93, 0.78, 0.95)]), duv, icon)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_save_stats(ci, xf, csize, s, info)


static func _fmt_int(v: int) -> String:
	var t := str(absi(v))
	var out := ""
	for i in t.length():
		if i > 0 and (t.length() - i) % 3 == 0:
			out += "."
		out += t[i]
	return ("-" if v < 0 else "") + out


static func _fmt_time(sec: float) -> String:
	var m := int(sec) / 60
	return "%02d:%02d" % [m / 60, m % 60]


static func _draw_save_stats(ci: CanvasItem, xf: Transform2D, csize: Vector2, s: float, info: Dictionary) -> void:
	var mono := PreGameDraw.mono_font()
	var display := PreGameDraw.title_font()
	var cells := [
		["LEVEL", str(int(info.get("level", 1)))],
		["RESPECT", str(int(info.get("respect", 0)))],
		["CASCOS", _fmt_int(int(info.get("cascos", 0)))],
		["PLAYTIME", _fmt_time(float(info.get("play_seconds", 0.0)))],
	]
	PreGameDraw.push_counter_skew(ci, xf, -8.0)
	var left := -csize.x * 0.5 + 76.0 * s
	var cell_w := (csize.x - 76.0 * s - 14.0 * s) / 4.0
	for i in cells.size():
		var x := left + float(i) * cell_w
		ci.draw_string(mono, Vector2(x, -10.0 * s), str(cells[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(11.0, s), Color(PreGameDraw.INK, 0.7))
		ci.draw_string(display, Vector2(x, 20.0 * s), str(cells[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1,
			_fs(25.0, s), PreGameDraw.INK)
	PreGameDraw.pop_xform(ci)
