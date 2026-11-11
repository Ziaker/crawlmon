class_name AttackBadge
extends Control
## D-1134: protótipo de 4 visuais para a badge [Z] ATTACK do overworld.
##
## Desenhada em _draw() para casar com o prompt atual (D-1085) e os cards do
## jogo (D-1074/D-1094/D-1096/D-1097). O componente é independente do lab:
## recebe o contexto (alvo, distância, estado) e emite badge_pressed.
##
## Estilos:
##   0 ATTACK CARD  - Flat Card creme, tinta, Impact, sombra dura, barra âmbar.
##   1 COMMAND STRIP - Move Strip navy/ciano, losango, ticks de alcance.
##   2 SMT UPLINK   - terminal ciano/vermelho, scanline, LOCK, glitch.
##   3 Z-POW        - comic/balão creme, Kanit, halftone, rabicho no alvo.
##
## D-235: nada depende de personagem, time ou lado; o alvo chega por contexto.
## D-1100/D-1127: as cores azul/vermelho NÃO significam "no alcance"; o
## vermelho do SMT é só acento do terminal. O ataque é Z; E não aparece.

signal badge_pressed

enum Style { ATTACK_CARD, COMMAND_STRIP, SMT_UPLINK, Z_POW }
enum State { READY, RECHARGING, NO_TARGET }

const SIZE := Vector2(380.0, 58.0)
const ATTACK_RANGE := 4.5
const KANIT := preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")

const CREAM := Color(0.918, 0.914, 0.851)
const INK := Color(0.067, 0.106, 0.161)
const NAVY := Color(0.059, 0.106, 0.165)
const SLATE := Color(0.200, 0.255, 0.333)
const CYAN := Color(0.220, 0.741, 0.973)
const BLUE := Color(0.145, 0.388, 0.922)
const AQUA := Color(0.384, 0.847, 0.906)
const LIME := Color(0.843, 0.992, 0.416)
const CORAL := Color(1.000, 0.384, 0.310)
const GOLD := Color(0.969, 0.796, 0.471)
const AMBER := Color(1.000, 0.722, 0.278)
const SMT_BG := Color(0.016, 0.035, 0.047)
const SMT_CYAN := Color(0.251, 0.949, 0.851)
const SMT_RED := Color(1.000, 0.361, 0.239)
const COMIC_PAPER := Color(0.988, 0.949, 0.839)
const COMIC_INK := Color(0.031, 0.031, 0.039)
const COMIC_YELLOW := Color(1.000, 0.824, 0.247)

var style: int = Style.ATTACK_CARD
var state: int = State.READY
var target_name := "SLIME"
var distance := 3.2
var cooldown := 0.0
var target_screen := Vector2.ZERO
var target_screen_valid := false

var _time := 0.0
var _press := 0.0
var _flash := 0.0
var _pow := 0.0
var _glitch := 0.0
var _font_impact: Font
var _font_body: Font
var _font_mono: Font
var _font_comic: Font
var _particles: CPUParticles2D
var _dots: PackedVector2Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = SIZE * 0.5
	_load_fonts()
	_build_dots()
	_build_particles()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_press = maxf(0.0, _press - delta * 4.5)
	_flash = maxf(0.0, _flash - delta * 6.0)
	_pow = maxf(0.0, _pow - delta * 2.8)
	_glitch = maxf(0.0, _glitch - delta * 12.0)
	queue_redraw()


func set_style(p_style: int) -> void:
	style = p_style
	queue_redraw()


func set_context(p_name: String, p_distance: float, p_state: int, p_cooldown := 0.0) -> void:
	target_name = p_name
	distance = clampf(p_distance, 0.05, ATTACK_RANGE)
	state = p_state
	cooldown = clampf(p_cooldown, 0.0, 1.0)
	queue_redraw()


func set_target_screen(pos: Vector2, valid: bool) -> void:
	target_screen = pos
	target_screen_valid = valid
	queue_redraw()


func play_press() -> void:
	if state == State.NO_TARGET:
		return
	_press = 1.0
	_flash = 1.0
	_pow = 1.0 if style == Style.Z_POW else 0.0
	_glitch = 1.0 if style == Style.SMT_UPLINK else 0.0
	_emit_particles()
	var base := scale
	var t := create_tween()
	t.tween_property(self, "scale", base * 1.07, 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", base, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	badge_pressed.emit()


static func style_name(p_style: int) -> String:
	match p_style:
		Style.ATTACK_CARD:
			return "ATTACK CARD"
		Style.COMMAND_STRIP:
			return "COMMAND STRIP"
		Style.SMT_UPLINK:
			return "SMT UPLINK"
		Style.Z_POW:
			return "Z-POW"
		_:
			return "?"


func _load_fonts() -> void:
	_font_impact = _system_font(["Impact", "Haettenschweiler", "Arial Black"], 900)
	_font_body = _system_font(["Arial", "Segoe UI"], 800)
	_font_mono = _system_font(["Consolas", "Courier New"], 700)
	_font_comic = KANIT


func _system_font(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	return f


func _build_dots() -> void:
	_rng.seed = 1134
	_dots.clear()
	for i in 72:
		_dots.append(Vector2(_rng.randf_range(8.0, SIZE.x - 8.0), _rng.randf_range(5.0, SIZE.y - 5.0)))


func _build_particles() -> void:
	_particles = CPUParticles2D.new()
	_particles.name = "BadgeParticles"
	_particles.emitting = false
	_particles.one_shot = true
	_particles.local_coords = false
	_particles.position = SIZE * 0.5
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 18.0
	_particles.direction = Vector2(0.0, -1.0)
	_particles.spread = 180.0
	_particles.gravity = Vector2(0.0, 420.0)
	_particles.angular_velocity_min = -220.0
	_particles.angular_velocity_max = 220.0
	_particles.angle_min = -20.0
	_particles.angle_max = 20.0
	add_child(_particles)


func _emit_particles() -> void:
	if _particles == null:
		return
	match style:
		Style.ATTACK_CARD:
			_particles.texture = _particle_texture(Vector2i(6, 6))
			_particles.color = AMBER
			_particles.amount = 12
			_particles.lifetime = 0.5
			_particles.initial_velocity_min = 60.0
			_particles.initial_velocity_max = 160.0
			_particles.scale_amount_min = 0.5
			_particles.scale_amount_max = 1.2
			_particles.gravity = Vector2(0.0, 420.0)
		Style.COMMAND_STRIP:
			_particles.texture = _particle_texture(Vector2i(3, 12))
			_particles.color = CYAN
			_particles.amount = 16
			_particles.lifetime = 0.32
			_particles.initial_velocity_min = 90.0
			_particles.initial_velocity_max = 250.0
			_particles.scale_amount_min = 0.4
			_particles.scale_amount_max = 1.0
			_particles.gravity = Vector2.ZERO
		Style.SMT_UPLINK:
			_particles.texture = _particle_texture(Vector2i(4, 4))
			_particles.color = SMT_CYAN
			_particles.amount = 20
			_particles.lifetime = 0.3
			_particles.initial_velocity_min = 50.0
			_particles.initial_velocity_max = 210.0
			_particles.scale_amount_min = 0.4
			_particles.scale_amount_max = 1.1
			_particles.gravity = Vector2.ZERO
		Style.Z_POW:
			_particles.texture = _particle_texture(Vector2i(8, 5))
			_particles.color = COMIC_YELLOW
			_particles.amount = 18
			_particles.lifetime = 0.55
			_particles.initial_velocity_min = 90.0
			_particles.initial_velocity_max = 230.0
			_particles.scale_amount_min = 0.6
			_particles.scale_amount_max = 1.5
			_particles.gravity = Vector2(0.0, 520.0)
	_particles.restart()
	_particles.emitting = true


func _particle_texture(cell: Vector2i) -> ImageTexture:
	var img := Image.create(cell.x, cell.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	for x in cell.x:
		img.set_pixel(x, 0, Color(1, 1, 1, 0.45))
		img.set_pixel(x, cell.y - 1, Color(1, 1, 1, 0.45))
	return ImageTexture.create_from_image(img)


func _tint(c: Color, alpha := 1.0) -> Color:
	var out := c
	if state == State.RECHARGING:
		out = out.lerp(Color(0.36, 0.38, 0.41), 0.58)
	if state == State.NO_TARGET:
		out = out.lerp(Color(0.30, 0.32, 0.35), 0.72)
	out.a *= alpha * (0.38 if state == State.NO_TARGET else 1.0)
	return out


func _text(font: Font, pos: Vector2, text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	if font == null:
		font = ThemeDB.fallback_font
	draw_string(font, pos, text, align, width, size, color)


func _draw() -> void:
	var w := SIZE.x
	var h := SIZE.y
	var alpha := 1.0
	match style:
		Style.ATTACK_CARD:
			_draw_card(w, h, alpha)
		Style.COMMAND_STRIP:
			_draw_strip(w, h, alpha)
		Style.SMT_UPLINK:
			_draw_smt(w, h, alpha)
		Style.Z_POW:
			_draw_comic(w, h, alpha)
	if state == State.NO_TARGET:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.015, 0.02, 0.03, 0.55))
		var msg := "SEM ALVO"
		var font := _font_impact if _font_impact != null else ThemeDB.fallback_font
		var tw := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		_text(font, Vector2((w - tw) * 0.5, h * 0.5 + 9.0), msg, 26, Color(0.86, 0.88, 0.90, 0.85))
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(1, 1, 1, 0.16 * _flash))


# --- 0 · ATTACK CARD ---------------------------------------------------------
func _draw_card(w: float, h: float, alpha: float) -> void:
	var skew := h * 0.10
	var shadow := PackedVector2Array([
		Vector2(skew + 7.0, 6.0), Vector2(w + 7.0, 6.0),
		Vector2(w - skew + 7.0, h + 6.0), Vector2(7.0, h + 6.0),
	])
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.42))
	var plate := PackedVector2Array([
		Vector2(skew, 0.0), Vector2(w, 0.0),
		Vector2(w - skew, h), Vector2(0.0, h),
	])
	draw_colored_polygon(plate, _tint(CREAM, alpha))
	# fibras discretas do papel
	for p in _dots:
		draw_circle(p, 1.0, Color(INK.r, INK.g, INK.b, 0.045 * alpha))
	draw_line(Vector2(skew + 2.0, 2.0), Vector2(w - 2.0, 2.0), _tint(AMBER, alpha), 2.0)
	# entalhe do Z
	var key := PackedVector2Array([
		Vector2(skew + 8.0, 7.0), Vector2(62.0, 7.0),
		Vector2(56.0, h - 7.0), Vector2(5.0, h - 7.0),
	])
	draw_colored_polygon(key, _tint(INK, alpha))
	var zx := 22.0
	_text(_font_impact, Vector2(zx, 39.0), "Z", 27, _tint(CREAM, alpha))
	_text(_font_impact, Vector2(76.0, 35.0), "ATTACK", 31, _tint(INK, alpha))
	var state_txt := "PRONTO" if state == State.READY else ("RECARGA" if state == State.RECHARGING else "")
	_text(_font_body, Vector2(78.0, 49.0), "%s  ·  %.1f m" % [target_name, distance], 9, Color(INK.r, INK.g, INK.b, 0.72 * alpha))
	if state_txt != "":
		var tw := _font_body.get_string_size(state_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		_text(_font_body, Vector2(w - tw - 18.0, 49.0), state_txt, 9, Color(INK.r, INK.g, INK.b, 0.55 * alpha))
	# barra de alcance/recarga
	var fill := clampf(1.0 - distance / ATTACK_RANGE, 0.08, 1.0)
	if state == State.RECHARGING:
		fill = 1.0 - cooldown
	draw_rect(Rect2(10.0, h - 7.0, w - 20.0, 3.0), Color(INK.r, INK.g, INK.b, 0.18 * alpha))
	draw_rect(Rect2(10.0, h - 7.0, (w - 20.0) * fill, 3.0), _tint(AMBER, alpha))
	if _press > 0.0:
		draw_line(Vector2(skew + 4.0, h * 0.5), Vector2(w - 6.0, h * 0.5), Color(1, 0.86, 0.55, 0.45 * _press), 2.0)


# --- 1 · COMMAND STRIP -------------------------------------------------------
func _draw_strip(w: float, h: float, alpha: float) -> void:
	var plate := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(w - 18.0, 0.0),
		Vector2(w, h), Vector2(0.0, h),
	])
	draw_colored_polygon(plate, _tint(NAVY, alpha))
	draw_line(Vector2(0.0, h - 1.0), Vector2(w - 1.0, h - 1.0), _tint(CYAN, alpha), 2.0)
	# losango do Z
	var cx := 32.0
	var cy := h * 0.5
	var d := 22.0
	var diamond := PackedVector2Array([
		Vector2(cx, cy - d), Vector2(cx + d, cy),
		Vector2(cx, cy + d), Vector2(cx - d, cy),
	])
	draw_colored_polygon(diamond, _tint(CYAN, alpha))
	_text(_font_impact, Vector2(cx - 9.0, cy + 9.0), "Z", 23, _tint(NAVY, alpha))
	_text(_font_impact, Vector2(70.0, 32.0), "ATTACK", 27, _tint(CREAM, alpha))
	_text(_font_body, Vector2(72.0, 48.0), "%s  ·  %.1f m" % [target_name, distance], 9, _tint(AQUA, alpha))
	var fill := clampf(1.0 - distance / ATTACK_RANGE, 0.08, 1.0)
	if state == State.RECHARGING:
		fill = 1.0 - cooldown
	for i in 5:
		var tx := w - 92.0 + float(i) * 14.0
		var on := float(i) < fill * 5.0
		draw_rect(Rect2(tx, h - 17.0, 8.0, 10.0), _tint(CYAN if on else SLATE, alpha))
	_text(_font_body, Vector2(w - 92.0, h - 22.0), "RANGE", 8, _tint(SLATE, alpha))
	if _press > 0.0:
		var sx := fmod(_time * 620.0, w)
		draw_line(Vector2(sx, 2.0), Vector2(sx, h - 3.0), Color(0.25, 0.95, 0.90, 0.55 * _press), 2.0)


# --- 2 · SMT UPLINK ----------------------------------------------------------
func _draw_smt(w: float, h: float, alpha: float) -> void:
	var cut := 7.0
	var plate := PackedVector2Array([
		Vector2(cut, 0.0), Vector2(w, 0.0), Vector2(w, h - cut),
		Vector2(w - cut, h), Vector2(0.0, h), Vector2(0.0, cut),
	])
	draw_colored_polygon(plate, _tint(SMT_BG, alpha))
	draw_polyline(plate + PackedVector2Array([plate[0]]), _tint(SMT_CYAN, alpha), 1.4, true)
	# bloco vermelho do terminal
	draw_rect(Rect2(8.0, 7.0, 36.0, h - 14.0), _tint(SMT_RED, alpha))
	_text(_font_mono, Vector2(16.0, 38.0), "[Z]", 15, _tint(Color(1, 1, 1), alpha))
	_text(_font_body, Vector2(54.0, 32.0), "ATTACK", 23, _tint(Color(0.92, 1.0, 0.98), alpha))
	_text(_font_mono, Vector2(56.0, 47.0), "%s  //  %.1f m" % [target_name, distance], 9, _tint(SMT_CYAN, alpha))
	var lock_txt := "LOCK" if state == State.READY else ("WAIT" if state == State.RECHARGING else "NONE")
	var lw := _font_mono.get_string_size(lock_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	_text(_font_mono, Vector2(w - lw - 16.0, 22.0), lock_txt, 9, _tint(SMT_CYAN, alpha))
	_text(_font_mono, Vector2(w - 82.0, h - 12.0), "SMT //", 8, _tint(SMT_RED, alpha))
	# scanline
	var sy := fmod(_time * 34.0, h)
	draw_line(Vector2(2.0, sy), Vector2(w - 2.0, sy), Color(SMT_CYAN.r, SMT_CYAN.g, SMT_CYAN.b, 0.18 * alpha), 1.0)
	if _glitch > 0.0:
		var gx := sin(_time * 90.0) * 4.0 * _glitch
		draw_rect(Rect2(0.0, h * 0.38 + gx, w, 2.0), Color(SMT_CYAN.r, SMT_CYAN.g, SMT_CYAN.b, 0.55 * _glitch))
		draw_rect(Rect2(6.0, h * 0.62 - gx, w - 12.0, 1.0), Color(SMT_RED.r, SMT_RED.g, SMT_RED.b, 0.45 * _glitch))
	if _press > 0.0:
		draw_rect(Rect2(0.0, 0.0, w, h), Color(0.25, 0.95, 0.90, 0.10 * _press))


# --- 3 · Z-POW ---------------------------------------------------------------
func _draw_comic(w: float, h: float, alpha: float) -> void:
	if target_screen_valid and state != State.NO_TARGET:
		_draw_comic_tail(w, h, alpha)
	var balloon := PackedVector2Array([
		Vector2(4.0, 8.0), Vector2(14.0, 1.0), Vector2(w - 30.0, 1.0),
		Vector2(w - 12.0, 8.0), Vector2(w - 8.0, h * 0.5), Vector2(w - 12.0, h - 8.0),
		Vector2(w - 30.0, h - 1.0), Vector2(14.0, h - 1.0), Vector2(4.0, h - 8.0),
		Vector2(1.0, h * 0.5),
	])
	draw_colored_polygon(balloon, _tint(COMIC_PAPER, alpha))
	draw_polyline(balloon + PackedVector2Array([balloon[0]]), _tint(COMIC_INK, alpha), 5.0, true)
	# meio-tom
	for p in _dots:
		draw_circle(p, 1.0, Color(COMIC_INK.r, COMIC_INK.g, COMIC_INK.b, 0.10 * alpha))
	# keycap Z preta
	draw_rect(Rect2(16.0, 12.0, 34.0, h - 24.0), _tint(COMIC_INK, alpha))
	_text(_font_comic, Vector2(23.0, 40.0), "Z", 24, _tint(COMIC_PAPER, alpha))
	var title := "ATTACK!"
	_text(_font_comic, Vector2(66.0 + 3.0, 38.0 + 3.0), title, 31, _tint(COMIC_YELLOW, alpha))
	_text(_font_comic, Vector2(66.0, 38.0), title, 31, _tint(COMIC_INK, alpha))
	_text(_font_body, Vector2(68.0, 51.0), "%s  ·  %.1f m" % [target_name, distance], 9, _tint(COMIC_INK, alpha))
	if _pow > 0.0:
		_draw_comic_pow(w, h, alpha)


func _draw_comic_tail(w: float, h: float, alpha: float) -> void:
	var local := (target_screen - global_position) / scale
	var start := Vector2(w * 0.52, h * 0.9)
	var dir := (local - start)
	if dir.length_squared() < 4.0:
		return
	dir = dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var side := 9.0
	var tail := PackedVector2Array([
		start + perp * side,
		local + dir * 8.0,
		start - perp * side,
	])
	draw_colored_polygon(tail, _tint(COMIC_PAPER, alpha))
	draw_polyline(tail + PackedVector2Array([tail[0]]), _tint(COMIC_INK, alpha), 4.0, true)


func _draw_comic_pow(w: float, h: float, alpha: float) -> void:
	var c := Vector2(w - 58.0, -16.0)
	var star := PackedVector2Array()
	for i in 10:
		var ang := -PI * 0.5 + float(i) * PI / 5.0
		var rad := 28.0 if i % 2 == 0 else 12.0
		star.append(c + Vector2(cos(ang), sin(ang)) * rad * (0.55 + 0.45 * _pow))
	draw_colored_polygon(star, Color(COMIC_YELLOW.r, COMIC_YELLOW.g, COMIC_YELLOW.b, 0.85 * _pow))
	draw_polyline(star + PackedVector2Array([star[0]]), Color(COMIC_INK.r, COMIC_INK.g, COMIC_INK.b, 0.8 * _pow), 3.0, true)
	_text(_font_comic, c + Vector2(-20.0, 5.0), "POW", 14, Color(COMIC_INK.r, COMIC_INK.g, COMIC_INK.b, _pow))
