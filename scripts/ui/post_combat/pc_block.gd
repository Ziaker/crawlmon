class_name PcBlock
extends Control
## D-1192: um bloco do pós-combate. Fundo em paralelogramo (+ sombra dura deslocada),
## o bloco gira INTEIRO (`rotation` em volta do centro, como o `rotate` do CSS) e o
## conteúdo é desenhado reto por `painter`. Animações por Tween em deslocamentos separados
## (entrada, seleção, chegada, tremor), que se somam à posição/rotação base.

var k := 14.0
var bg := Color(0, 0, 0, 0)
var shadow := Vector2.ZERO
var painter := Callable()
var t0 := 0.0  ## Início da animação de texto do bloco (segundos de relógio).
var live := false  ## Redesenha a cada quadro (texto animado, barras).

var base_pos := Vector2.ZERO
var base_rot := 0.0
var enter_off := Vector2.ZERO
var anim_off := Vector2.ZERO
var shake_off := Vector2.ZERO
var lift := 0.0
var lift_px := 8.0
var lift_scale := 0.04
var anim_scale := 1.0
var anim_rot := 0.0
var pulse_scale := 1.0
var rest_alpha := 1.0  ## Opacidade final (ex.: etapa já feita da fila = .4).
var stat_pop_t0 := -999.0  ## D-1224: instante do último impacto de ponto na linha.
var construct_p := 1.0  ## D-1224: 0->1 construção estrutural do polígono.
var construct_mode := 0  ## 0=normal, 1=extrusão horizontal, 2=desdobramento diagonal, 3=abre do retrato.
var construct_accent := Color.TRANSPARENT
var construct_origin := Rect2()
var extra_w := 0.0  ## D-1224: extensão horizontal momentânea ao bater um ponto.
var idle_amp := 0.0
var idle_phase := 0.0

## Seleção (rodada 9): sobe com mola, barra coral que se estende, seta ▶ pulsando.
var focused := false
var focus_since := 0.0
var _lift_tw: Tween = null
var _kick_tw: Tween = null


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func setup(r: Rect2, rot_deg: float, p_k := 14.0, p_bg := Color(0, 0, 0, 0), p_shadow := Vector2.ZERO) -> PcBlock:
	base_pos = r.position
	size = r.size
	pivot_offset = r.size * 0.5
	base_rot = deg_to_rad(rot_deg)
	k = p_k
	bg = p_bg
	shadow = p_shadow
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	apply()
	return self


func apply() -> void:
	var idle_off := Vector2.ZERO
	var idle_rot := 0.0
	if idle_amp > 0.0 and now() - t0 > 0.55:
		var t_idle := now() - t0 - 0.55
		var ramp := clampf(t_idle / 0.4, 0.0, 1.0)
		idle_off = Vector2(0.0, sin(now() * 2.2 + idle_phase) * idle_amp * ramp)
		idle_rot = deg_to_rad(cos(now() * 1.8 + idle_phase) * idle_amp * 0.08 * ramp)
	position = base_pos + enter_off + anim_off + shake_off + idle_off + Vector2(0, -lift_px * lift)
	rotation = base_rot + anim_rot + idle_rot
	var s := anim_scale * (1.0 + lift_scale * lift) * pulse_scale
	scale = Vector2(s, s)


func age() -> float:
	return now() - t0


func _process(_d: float) -> void:
	if idle_amp > 0.0 and now() - t0 > 0.55:
		apply()
	var age_pop := now() - stat_pop_t0
	if live or focused or construct_p < 0.999 or absf(extra_w) > 0.1 or (stat_pop_t0 >= 0.0 and age_pop >= 0.0 and age_pop <= 0.42):
		queue_redraw()


func _draw() -> void:
	var w := size.x + extra_w
	var h := size.y
	var used := bg
	var show_content := true
	if construct_mode == 1 and construct_p < 0.999:
		var e := PcDraw.bezier(0.16, 1.18, 0.30, 1.0, construct_p)
		var cur_w := maxf(18.0, lerpf(22.0, w, e))
		var cur_k := minf(k * clampf(cur_w / maxf(1.0, w), 0.25, 1.0), cur_w * 0.45)
		if shadow != Vector2.ZERO:
			PcDraw.fill_para(self, Rect2(shadow * clampf(e, 0.0, 1.0), Vector2(cur_w, h)), cur_k, PcDraw.SHADOW)
		PcDraw.fill_para(self, Rect2(Vector2.ZERO, Vector2(cur_w, h)), cur_k, bg)
		show_content = construct_p >= 0.45
	elif construct_mode == 2 and construct_p < 0.999:
		var e := PcDraw.bezier(0.16, 1.12, 0.28, 1.0, construct_p)
		var cur_w := maxf(12.0, w * clampf(e, 0.0, 1.08))
		var ox := (w - cur_w) * 0.18
		var cur_k := minf(lerpf(k * 1.6, k, clampf(e, 0.0, 1.0)), cur_w * 0.45)
		if construct_accent.a > 0.0:
			var lead_off := Vector2(14.0 * (1.0 - e), 10.0 * (1.0 - e))
			PcDraw.fill_para(self, Rect2(Vector2(ox, 0.0) + lead_off, Vector2(cur_w, h)), cur_k, construct_accent)
		if shadow != Vector2.ZERO:
			PcDraw.fill_para(self, Rect2(Vector2(ox, 0.0) + shadow * clampf(e * e, 0.0, 1.0), Vector2(cur_w, h)), cur_k, PcDraw.SHADOW)
		PcDraw.fill_para(self, Rect2(ox, 0.0, cur_w, h), cur_k, bg)
		show_content = construct_p >= 0.42
	elif construct_mode == 3 and construct_p < 0.999:
		if construct_p > 0.01:
			var e := PcDraw.bezier(0.16, 1.14, 0.30, 1.0, construct_p)
			var cur_pos := construct_origin.position.lerp(Vector2.ZERO, e)
			var cur_sz := construct_origin.size.lerp(Vector2(w, h), e)
			var cur_k := minf(k * clampf(e, 0.0, 1.0), cur_sz.x * 0.45)
			if shadow != Vector2.ZERO:
				PcDraw.fill_para(self, Rect2(cur_pos + shadow * clampf(e * e, 0.0, 1.0), cur_sz), cur_k, PcDraw.SHADOW)
			PcDraw.fill_para(self, Rect2(cur_pos, cur_sz), cur_k, bg)
		show_content = true
	else:
		var r := Rect2(Vector2.ZERO, Vector2(w, h))
		if shadow != Vector2.ZERO:
			PcDraw.fill_para(self, Rect2(shadow, Vector2(w, h)), k, PcDraw.SHADOW)
		PcDraw.fill_para(self, r, k, bg)
	if show_content and painter.is_valid():
		painter.call(self)
	if bg != used:
		queue_redraw.call_deferred()  # o painter trocou o fundo (seleção): redesenha com a cor nova
	if focused:
		_draw_focus()


func _draw_focus() -> void:
	var ft := now() - focus_since
	# Barra coral embaixo (left 6, right 6, bottom -13, 6 px), cresce da esquerda em .28 s.
	var p := PcDraw.bezier(0.2, 1.0, 0.3, 1.0, clampf(ft / 0.28, 0.0, 1.0))
	var bw := (size.x - 12.0) * p
	PcDraw.fill_para(self, Rect2(6, size.y + 7, bw, 6), 6.0, PcDraw.CORAL)
	# Seta ▶ à esquerda (left -28, 16×22), vai e volta 6 px em .7 s.
	var ph := fmod(ft, 0.7) / 0.7
	var e := PcDraw.bezier(0.42, 0.0, 0.58, 1.0, ph * 2.0 if ph < 0.5 else (1.0 - ph) * 2.0)
	var x := -28.0 + 6.0 * e
	var y := size.y * 0.5 - 11.0
	draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 16, y + 11), Vector2(x, y + 22)]), PcDraw.CORAL)


func set_focus(on: bool, lift_y := 8.0, lift_s := 0.04) -> void:
	if on == focused:
		return
	focused = on
	focus_since = now()
	lift_px = lift_y
	lift_scale = lift_s
	z_index = 4 if on else 0
	if _lift_tw != null:
		_lift_tw.kill()
	var from := lift
	var to := 1.0 if on else 0.0
	_lift_tw = create_tween()
	_lift_tw.tween_method(func(q: float) -> void:
		lift = from + (to - from) * PcDraw.bezier(0.2, 1.6, 0.4, 1.0, q)
		apply(), 0.0, 1.0, 0.28)
	queue_redraw()


## Entrada (rodada 2). style: "slide" (−90 px → +8 → 0), "pop", "drop"; .42 s,
## cubic-bezier(.2,.9,.3,1) por trecho; fica invisível até o atraso (fill-mode backwards).
func enter(style: String, delay: float) -> void:
	if style == "none":
		modulate.a = rest_alpha
		return
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(delay)
	var segs: Array
	match style:
		"pop":
			segs = [[0.0, 0.55, 0.0], [0.65, 1.06, 1.0], [1.0, 1.0, 1.0]]
		"drop":
			segs = [[0.0, -70.0, 0.0], [0.6, 6.0, 1.0], [0.8, -3.0, 1.0], [1.0, 0.0, 1.0]]
		_:
			segs = [[0.0, -90.0, 0.0], [0.7, 8.0, 1.0], [1.0, 0.0, 1.0]]
	for i in range(1, segs.size()):
		var a: Array = segs[i - 1]
		var b: Array = segs[i]
		var dur: float = (b[0] - a[0]) * 0.42
		tw.tween_method(func(q: float) -> void:
			var e := PcDraw.bezier(0.2, 0.9, 0.3, 1.0, q)
			var v: float = a[1] + (b[1] - a[1]) * e
			modulate.a = clampf(a[2] + (b[2] - a[2]) * e, 0.0, 1.0) * rest_alpha
			match style:
				"pop": anim_scale = v
				"drop": enter_off = Vector2(0, v)
				_: enter_off = Vector2(v, 0)
			apply(), 0.0, 1.0, dur)


## D-1224: desdobramento diagonal estrutural dos cartões principais (com lâmina de destaque atrás).
func unfold_card(accent: Color, from_off: Vector2, from_rot_deg: float, delay: float, dur := 0.46) -> void:
	construct_mode = 2
	construct_p = 0.0
	construct_accent = accent
	modulate.a = 0.0
	enter_off = from_off
	anim_rot = deg_to_rad(from_rot_deg)
	apply()
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_method(func(q: float) -> void:
		var e := PcDraw.bezier(0.16, 1.12, 0.28, 1.0, q)
		construct_p = q
		enter_off = from_off * (1.0 - e)
		anim_rot = deg_to_rad(from_rot_deg * (1.0 - e))
		modulate.a = clampf(q * 3.5, 0.0, 1.0) * rest_alpha
		apply()
		queue_redraw(), 0.0, 1.0, dur)
	tw.tween_callback(func() -> void:
		construct_p = 1.0
		construct_mode = 0
		enter_off = Vector2.ZERO
		anim_rot = 0.0
		modulate.a = rest_alpha
		apply()
		queue_redraw())


## D-1224: extrusão horizontal das barras e faixas a partir da aba esquerda.
func extrude_bar(delay: float, dur := 0.36) -> void:
	construct_mode = 1
	construct_p = 0.0
	modulate.a = 0.0
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_method(func(q: float) -> void:
		construct_p = q
		modulate.a = clampf(q * 4.0, 0.0, 1.0) * rest_alpha
		queue_redraw(), 0.0, 1.0, dur)
	tw.tween_callback(func() -> void:
		construct_p = 1.0
		construct_mode = 0
		modulate.a = rest_alpha
		queue_redraw())


## D-1224: abre o cartão de trás de um retângulo interno (Foco no Retrato).
func open_from_rect(origin_r: Rect2, delay: float, dur := 0.28) -> void:
	construct_mode = 3
	construct_origin = origin_r
	construct_p = 0.0
	modulate.a = rest_alpha
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_method(func(q: float) -> void:
		construct_p = q
		queue_redraw(), 0.0, 1.0, dur)
	tw.tween_callback(func() -> void:
		construct_p = 1.0
		construct_mode = 0
		queue_redraw())


## D-1224: golpe físico lateral na própria geometria da barra (estica e estala de volta).
func kick_bar(px := 18.0) -> void:
	stat_pop_t0 = now()
	if _kick_tw != null and is_instance_valid(_kick_tw):
		_kick_tw.kill()
	_kick_tw = create_tween()
	_kick_tw.tween_method(func(q: float) -> void:
		var s := sin(q * PI)
		extra_w = px * s
		enter_off.x = (px * 0.55) * s
		apply()
		queue_redraw(), 0.0, 1.0, 0.28)
	_kick_tw.tween_callback(func() -> void:
		extra_w = 0.0
		enter_off.x = 0.0
		apply()
		queue_redraw())


## Tremor (keyframes shake, .32 s linear).
func shake() -> void:
	var pts := [Vector2.ZERO, Vector2(-7, 4), Vector2(6, -3), Vector2(-4, 2), Vector2(2, -1), Vector2.ZERO]
	var tw := create_tween()
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		tw.tween_method(func(q: float) -> void:
			shake_off = a.lerp(b, q)
			apply(), 0.0, 1.0, 0.064)
