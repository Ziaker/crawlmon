extends Control
## D-237: protótipo (mock-up) do FUNDO dos cartões em chamas durante o Burn (jogador: fundo branco; aliado: fundo
## roxo/azul; inimigo: fundo preto). A barra de vida NÃO muda de cor. O fundo vira laranja escuro pulsante, chamuscado
## (bordas carbonizadas com brasa), com fogo lambendo de baixo e brasas subindo.
## NÃO é o HUD do jogo: redesenha as medidas e cores do `battle_hud.gd` em escala maior, só para o vídeo.
## As chamas, o chamuscado e as brasas são animados pela biblioteca do Motion Composer (M12 pulso viajante + M07
## turbulência; M16 explosão direcional + M07 + M16 dissolução). Nada daqui toca no combate nem no HUD real.
## Gravar: godot --path . res://prototypes/burn_hud/burn_hud_proto.tscn --write-movie out.avi --fixed-fps 30

const Op := MotionTypes.Op
const DURATION := 9.4
const HIT_T := 1.6  ## the Fire Bullet interrupts an action and Burn is applied
const BURN_LEN := 4.0  ## ficha: 4 s
const TICK_DMG := 2  ## ficha: 2 HP per second
const FIRST_TICK := 1.0  ## PROPOSTA do protótipo (pendente na D-236): the first tick 1 s after the hit

const CREAM := Color("f0eedf")
const CORAL := Color("ff624f")
const LIME := Color("d7fd6a")
const AQUA := Color("62d8e7")
const BURN_TOP := Color("7d2e06")   ## dark orange background, top
const BURN_BOT := Color("cc5b0c")   ## and bottom (hotter)
const BURN_TEXT := Color("fff1d4")  ## text on the burnt background
const FLAME_OUT := Color("d8400a")
const FLAME_MID := Color("ff8a1c")
const FLAME_IN := Color("ffd24a")

var t := 0.0
var _cat := MotionCatalog.new()
var _teeth: MotionComposition  ## runs along the edge of a card: heights of the flames and the char band
var _embers: MotionComposition
var _font: Font
var _units: Array[Dictionary] = []


func _ready() -> void:
	MotionBehaviors.register_all(_cat)
	_font = FanMenu.body_font()
	_teeth = _make([[&"M12", Op.OFFSET, {"speed": 0.7, "width": 0.14, "amplitude": 1.0, "displace": 0.8, "axis_deg": 90.0, "loop": true, "ripples": 2.0}],
		[&"M07", Op.OFFSET, {"scale": 0.12, "intensity": 0.35, "time_hz": 7.0}]], 26, 3)
	_embers = _make([[&"M16", Op.OFFSET, {"direction": Vector3(0, 1, 0), "cone_deg": 50.0, "distance": 1.6, "distribution": 1.6, "t_duration": 0.8, "curve": 0.8}],
		[&"M07", Op.OFFSET, {"scale": 0.4, "intensity": 0.15, "time_hz": 3.0}],
		[&"M16", Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.9, "dissipate": 1.0, "curve": 1.0}]], 16, 5)
	_units = [
		{"kind": "hero", "name": "ABRA", "hp": 96, "max": 128, "pos": Vector2(28, 372), "scale": 1.9},
		{"kind": "ally", "name": "PANCHAM", "hp": 132, "max": 180, "pos": Vector2(660, 372), "scale": 1.9},
		{"kind": "enemy", "name": "GIBLE", "hp": 152, "max": 152, "pos": Vector2(440, 120), "scale": 2.7},
	]
	for u in _units:
		u["shown"] = float(u["hp"])


func _make(specs: Array, n: int, seed_v: int) -> MotionComposition:
	var c := MotionComposition.new()
	c.id = &"burn"
	c.sample_count = n
	c.seed = seed_v
	c.duration = 4.0
	var i := 0
	for s in specs:
		var l := MotionLayer.new()
		l.id = StringName("L%d" % i)
		l.behavior_id = s[0]
		l.op = s[1]
		l.params = s[2]
		c.add_layer(l)
		i += 1
	return c


func _process(delta: float) -> void:
	t += delta
	if t >= DURATION:
		get_tree().quit()
		return
	queue_redraw()


# --- Burn timeline (PROPOSTA): applied at HIT_T, a tick of 2 HP every second starting 1 s later, 4 s in all.

func _ticks_done() -> int:
	if t < HIT_T + FIRST_TICK:
		return 0
	return clampi(int(floor(t - HIT_T - FIRST_TICK)) + 1, 0, int(BURN_LEN))


func _burn_k() -> float:
	var on := clampf((t - HIT_T) / 0.35, 0.0, 1.0)
	var off := 1.0 - clampf((t - (HIT_T + BURN_LEN)) / 0.7, 0.0, 1.0)
	return on * off


func _pulse() -> float:
	return 0.5 + 0.5 * sin(t * TAU * 1.5)


func _since_tick() -> float:
	var d := _ticks_done()
	if d == 0:
		return 9.0
	return t - (HIT_T + FIRST_TICK + float(d - 1))


# --- Drawing ------------------------------------------------------------------------------------


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("0b1622"))
	for i in 12:
		draw_rect(Rect2(0, 480 + i * 20, 1280, 20), Color(0.05, 0.12, 0.18, 0.04 * i))
	draw_string(_font, Vector2(36, 44), "BURN (opção 2) — fundo do cartão chamuscado", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, CREAM)
	draw_string(_font, Vector2(36, 70), "Protótipo de HUD (mock-up, não é o jogo). A barra de vida não muda; o fundo vira laranja com fogo. Motion Composer anima o fogo.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(CREAM, 0.6))
	var done := _ticks_done()
	for u in _units:
		var hp_now := int(u["hp"]) - TICK_DMG * done
		u["shown"] = move_toward(float(u["shown"]), float(hp_now), 0.9)
		var pending := maxi(0, TICK_DMG * (int(BURN_LEN) - done)) if _burn_k() > 0.0 and t < HIT_T + BURN_LEN + 0.05 else 0
		draw_set_transform(u["pos"], 0.0, Vector2.ONE * float(u["scale"]))
		match u["kind"]:
			"hero": _card(u, true, pending)
			"ally": _card(u, false, pending)
			"enemy": _tag(u, pending)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_caption()


func _caption() -> void:
	var lines := [[0.0, "HUD normal: fundo branco (jogador), roxo/azul (aliado) e preto (inimigo)."],
		[HIT_T, "Fire Bullet interrompe a ação do alvo: Burn aplicado (4 s, 2 HP por segundo)."],
		[HIT_T + 0.6, "O fundo do cartão vira laranja escuro chamuscado, com fogo e brasas; a barra de vida não muda de cor."],
		[HIT_T + FIRST_TICK, "A cada tick: -2 HP e o trecho hachurado (dano que ainda vai chegar) encolhe."],
		[HIT_T + BURN_LEN, "Último tick: o Burn termina e o fundo original volta."]]
	var cur := ""
	for l in lines:
		if t >= float(l[0]):
			cur = l[1]
	draw_rect(Rect2(0, 640, 1280, 80), Color(0.02, 0.05, 0.09, 0.85))
	draw_string(_font, Vector2(36, 688), cur, HORIZONTAL_ALIGNMENT_LEFT, 1200, 22, CREAM)


func _slant_pts(r: Rect2, skew: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(r.position.x + skew, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - skew, r.end.y), Vector2(r.position.x, r.end.y)])


## Player / ally card, laid out like the real one (battle_hud.gd). Only the BACKGROUND burns.
func _card(u: Dictionary, hero: bool, pending: int) -> void:
	var k := _burn_k()
	var accent := AQUA if hero else Color("b6a3fe")
	var bg := Color("eae9d9") if hero else Color("17283b")
	var fg := (Color("111b29") if hero else Color("eceada")).lerp(BURN_TEXT, k)
	var track := Color("7b8c90") if hero else Color("526176")
	var hp_col := Color("e96159") if hero else Color("b5a5fe")
	var w := 300.0
	draw_string(_font, Vector2(8, 11), ("%s / RECURSOS" % String(u["name"])) if hero else "ALIADO / RECURSOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, CREAM if hero else Color("e6ddff"))
	BattleHud.text_right(self, _font, w - 8, 11, "ATB 05", 10, LIME)
	var body := Rect2(0, 18, w, 82)
	BattleHud.slant(self, Rect2(body.position + Vector2(6, 6), body.size), 8.0, Color(0, 0, 0, 0.5))
	_burnt_body(body, 8.0, bg, k, 10.0)
	draw_rect(Rect2(0, 18, 7, 82), accent)
	var pr := Rect2(16, 26, 56, 62)
	BattleHud.slant(self, pr, 6.0, (Color("263d57") if hero else Color("54456c")).lerp(Color("4a1a06"), k))
	draw_circle(Vector2(44, 58), 15.0, Color(accent, 0.5).lerp(Color(1.0, 0.5, 0.15, 0.55), k))
	draw_string(_font, Vector2(84, 44), String(u["name"]), HORIZONTAL_ALIGNMENT_LEFT, 150, 18, fg)
	BattleHud.text_right(self, _font, w - 48, 40, "JOGADOR" if hero else "ALIADO · IA", 8, Color(fg, 0.6))
	var bar := Rect2(84, 52, 120, 7)
	var hp_txt := "HP %d/%d" % [ceili(float(u["shown"])), int(u["max"])]
	_hp_bar(bar, float(u["shown"]) / float(u["max"]), float(pending) / float(u["max"]), track, hp_col, Vector2(bar.end.x + 8.0 + _font.get_string_size(hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 5.0, 59.0))
	draw_string(_font, Vector2(bar.end.x + 8, 59), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)
	_burn_badge(Vector2(84, 64))
	for i in 5:
		var r := Rect2(84 + i * 17, 80, 15, 8)
		BattleHud.slant(self, r, 2.0, Color("c1c4b9") if hero else Color("344359"))
		if i < 3:
			BattleHud.slant(self, r, 2.0, Color("167e9e") if hero else Color("c7adfc"))
	_burn_embers(body, k, 1.0)


## Enemy tag over the model: name, 5 px bar, "HP x / y" and the ATB blocks. Black background -> scorched orange.
func _tag(u: Dictionary, pending: int) -> void:
	var k := _burn_k()
	var w := 150.0
	var body := Rect2(0, -2, w, 58)
	_burnt_body(body, 4.0, Color(0.03, 0.06, 0.1, 0.92), k, 6.0)
	draw_string(_font, Vector2(0, 15), String(u["name"]), HORIZONTAL_ALIGNMENT_CENTER, w, 12, CORAL.lerp(BURN_TEXT, k))
	var bar := Rect2(14, 20, w - 28, 5)
	var hp_txt := "HP %d / %d" % [ceili(float(u["shown"])), int(u["max"])]
	_hp_bar(bar, float(u["shown"]) / float(u["max"]), float(pending) / float(u["max"]), Color("3a4756"), CORAL, Vector2(w * 0.5 + _font.get_string_size(hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x * 0.5 + 5.0, 37.0))
	draw_string(_font, Vector2(0, 37), hp_txt, HORIZONTAL_ALIGNMENT_CENTER, w, 10, CREAM.lerp(BURN_TEXT, k))
	_burn_badge(Vector2(w * 0.5 - 24.0, -14.0))
	for i in 5:
		var r := Rect2(8 + i * 18, 44, 16, 8)
		BattleHud.slant(self, r, 2.0, Color("2a3442"))
		if i < 4:
			BattleHud.slant(self, r, 2.0, Color(0.4, 0.88, 1.0))
	_burn_embers(body, k, 0.7)


## The card background. Normal: the flat colour of the game. Burning: a dark orange gradient that pulses, with a
## scorched (charred) edge that glows like embers, tongues of fire licking up from the bottom edge (kept under
## `max_flame` px so they never reach the text) and a hot halo around the card. The Motion Composer drives the
## flame heights and the ragged char line (M12 + M07 samples along the edge).
func _burnt_body(r: Rect2, skew: float, normal_bg: Color, k: float, max_flame: float) -> void:
	var pulse := _pulse()
	var top := normal_bg.lerp(BURN_TOP.lerp(BURN_BOT, 0.1 + 0.2 * pulse), k)
	var bot := normal_bg.lerp(BURN_BOT.lerp(Color("e8841f"), pulse * 0.6), k)
	if k > 0.0:
		for i in 4:  # hot halo around the card
			draw_colored_polygon(_slant_pts(r.grow(2.0 + float(i) * 2.5), skew), Color(1.0, 0.42, 0.08, (0.09 + 0.05 * pulse) * k / float(i + 1)))
	draw_polygon(_slant_pts(r, skew), PackedColorArray([top, top, bot, bot]))
	if k <= 0.0:
		return
	var res := _teeth.evaluate(_cat, _teeth.make_context(t))
	if res.has_errors():
		return
	var n := res.samples.size()
	# scorched edge: a charred band along the four edges with a ragged inner line that glows like embers
	var soot := Color(0.05, 0.02, 0.01, 0.62 * k)
	var ember := Color(1.0, 0.5, 0.1, (0.45 + 0.35 * pulse) * k)
	var top_pts := PackedVector2Array()
	var top_in := PackedVector2Array()
	var bot_pts := PackedVector2Array()
	var bot_in := PackedVector2Array()
	for i in n:
		var s := res.samples[i]
		var f := float(i) / float(n - 1)
		var d := 2.5 + absf(s.position.y) * 3.0 + absf(s.position.x) * 2.0
		var x := lerpf(r.position.x + skew, r.end.x, f)
		var xb := lerpf(r.position.x, r.end.x - skew, f)
		top_pts.append(Vector2(x, r.position.y))
		top_in.append(Vector2(x, r.position.y + d))
		bot_pts.append(Vector2(xb, r.end.y))
		bot_in.append(Vector2(xb, r.end.y - d * 0.6))
	for strip in [[top_pts, top_in], [bot_pts, bot_in]]:
		var a_pts: PackedVector2Array = strip[0]
		var b_pts: PackedVector2Array = strip[1]
		var poly := PackedVector2Array(a_pts)
		for j in range(b_pts.size() - 1, -1, -1):
			poly.append(b_pts[j])
		draw_colored_polygon(poly, soot)
		draw_polyline(b_pts, ember, 1.0)
	# side edges
	var lw := 2.0 + 2.0 * pulse
	draw_rect(Rect2(r.end.x - lw - 1.0, r.position.y, lw, r.size.y), Color(soot, 0.5 * k))
	# tongues of fire along the bottom edge, inside the card (M12 pulse running along + M07 flicker)
	var step := (r.size.x - skew) / float(n)
	for i in n:
		var s := res.samples[i]
		var h := clampf(0.6 + s.position.y * 1.0 + s.intensity * 0.25, 0.2, 1.7) * max_flame * 0.95 * k  # drawn before the text and the ATB cells, which stay on top
		var x0 := r.position.x + float(i) * step
		var lean := s.position.x * 4.0
		var base_y := r.end.y - 0.5
		var cols := [Color(FLAME_OUT, 0.8), Color(FLAME_MID, 0.8), Color(FLAME_IN, 0.85)]
		for layer in 3:
			var lh := h * (1.0 - 0.28 * float(layer))
			var half := step * (0.62 - 0.17 * float(layer))
			draw_colored_polygon(PackedVector2Array([Vector2(x0 + step * 0.5 - half, base_y), Vector2(x0 + step * 0.5 + lean * (1.0 - 0.2 * float(layer)), base_y - lh), Vector2(x0 + step * 0.5 + half, base_y)]), cols[layer])


## Embers rising off the card (three overlapping Motion Composer bursts, one new burst every 0.3 s).
func _burn_embers(body: Rect2, k: float, sc: float) -> void:
	if k <= 0.0:
		return
	for ph in 3:
		var tt := fposmod(t + float(ph) * 0.3, 0.9)
		_embers.seed = int(floor((t + float(ph) * 0.3) / 0.9)) * 7 + ph
		var r := _embers.evaluate(_cat, _embers.make_context(tt))
		if r.has_errors():
			continue
		for s in r.samples:
			if not s.visible or s.opacity <= 0.03:
				continue
			var p := Vector2(body.position.x + 8.0 + s.u * (body.size.x - 16.0) + s.position.x * 10.0 * sc, body.end.y - 2.0 - minf(s.position.y * 22.0 * sc, 30.0 * sc))
			var sz := (1.5 - 0.7 * (1.0 - s.opacity)) * sc
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -sz), p + Vector2(sz, 0), p + Vector2(0, sz), p + Vector2(-sz, 0)]), Color(FLAME_IN.lerp(FLAME_MID, 1.0 - s.opacity), s.opacity * k * 0.9))


## The HP bar keeps its own colours (the creator: it is the background that changes). While burning it only shows the
## pending damage as a hatched segment at the end of the fill, a brief flash on each tick and a floating "-2".
func _hp_bar(bar: Rect2, frac: float, pend: float, track: Color, normal: Color, tick_at: Vector2) -> void:
	var k := _burn_k()
	draw_rect(bar, track)
	var fw := bar.size.x * clampf(frac, 0.0, 1.0)
	var tick_f := clampf(1.0 - _since_tick() / 0.3, 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(fw, bar.size.y)), normal.lerp(Color.WHITE, tick_f * 0.5 * k))
	var pw := clampf(pend * bar.size.x, 0.0, fw)
	if pw > 0.5 and k > 0.0:
		var px := bar.position.x + fw - pw
		var s := px - bar.size.y
		while s < px + pw:
			var a := Vector2(clampf(s, px, px + pw), bar.position.y + bar.size.y)
			var b := Vector2(clampf(s + bar.size.y, px, px + pw), bar.position.y)
			draw_line(a, b, Color(0.1, 0.02, 0.0, 0.85), 1.0)
			s += 2.4
	if k > 0.0 and _ticks_done() > 0 and _since_tick() < 0.9:
		var f := _since_tick() / 0.9
		var ty := tick_at.y - 6.0 * f
		draw_string(_font, Vector2(tick_at.x + 0.7, ty + 0.7), "-%d" % TICK_DMG, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.1, 0.02, 0.0, 0.9 * (1.0 - f)))
		draw_string(_font, Vector2(tick_at.x, ty), "-%d" % TICK_DMG, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.78, 0.35, 1.0 - f))


## Status badge, same style as the real ones (slanted, "BURN 3.2s"), with a small flame icon.
func _burn_badge(at: Vector2) -> void:
	var k := _burn_k()
	if k <= 0.0 or t > HIT_T + BURN_LEN + 0.05:
		return
	var left := maxf(HIT_T + BURN_LEN - t, 0.0)
	var txt := "BURN %.1fs" % left
	var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 16.0
	BattleHud.slant(self, Rect2(at, Vector2(tw, 11)), 2.0, Color("b5470b"))
	var f := at + Vector2(5, 9.5)
	draw_colored_polygon(PackedVector2Array([f + Vector2(-2.5, 0), f + Vector2(0, -8.0), f + Vector2(2.5, 0)]), FLAME_MID)
	draw_colored_polygon(PackedVector2Array([f + Vector2(-1.2, 0), f + Vector2(0, -4.5), f + Vector2(1.2, 0)]), FLAME_IN)
	draw_string(_font, at + Vector2(11, 8.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fff3d6"))
