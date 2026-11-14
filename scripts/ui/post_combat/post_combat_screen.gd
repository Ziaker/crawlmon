class_name PostCombatScreen
extends Control
## D-1192: pós-combate do protótipo D-1185 (`prototypes/level_up_overhaul.html`), no palco 1280×720.
## Etapas: XP de todos → LV de cada um que subiu → Move novo → volta ao mapa.
## Lógica em PostCombatFlow / MoveInspectInfo; aqui só layout, desenho, animação e entrada.
## Nada depende de personagem (D-235): tudo vem do Combatant/Skill reais.

signal finished

## D-1192 em aberto: o criador ainda não escolheu Deslizar/Pop/Cair; padrão do protótipo.
const ENTER_STYLE := "slide"
const TEXT_FX := true

const STATS := [["STR", "Ataque físico"], ["MAG", "Ataque mágico"], ["VIT", "HP máximo"],
	["WIS", "Defesa mágica e MP"], ["AGI", "Ritmo do ATB"], ["LUK", "Crítico e esquiva"]]
const TILT_CARDS := [-1.6, 1.2]
const TILT_QUEUE := [-1.0, 1.4, -0.6, 1.0, -1.4, 0.8]
const TILT_ROWS := [-0.7, 0.6, -0.5, 0.8, -0.6, 0.5]
const TILT_SLOTS := [-1.6, 1.3, 1.1, -1.4, -0.9, 1.6, 1.4, -1.1]
const TILT_SG := [-1.2, 1.0]

const ART_DIR := "res://sugimori/por_nome/"
## D-1074: recorte do rosto dentro da arte Sugimori (px da arte: x0, y0, x1, y1). Dado de arte,
## não de regra; sem entrada usa a arte inteira.
const FACE_CROP := {
	"abra": Rect2i(300, 120, 320, 360),
	"pancham": Rect2i(300, 40, 680, 760),
	"gible": Rect2i(30, 100, 490, 560),
}

const GRAY_SHADER := "shader_type canvas_item;\nvoid fragment(){ vec4 c = texture(TEXTURE, UV) * COLOR; float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722)); COLOR = vec4(vec3(l * 0.55), c.a); }"

var _total_xp := 0
var _sums: Array = []
var _steps: Array = []
var _si := 0
var _ui := {}
var _step_t0 := 0.0
var _enter_i := 0
var _last_enter := 0.0

var _stage: Control
var _overlay: Control
var _fx: Control
var _hot: Array = []  ## {b: PcBlock, r: Rect2 (local), tip: String}
var _focusables := {}  ## f -> PcBlock
var _focus := ""
var _insp: Control = null
var _tip: PcBlock = null
var _tip_t := 0.0
var _confirm: Control = null
var _spot: ColorRect = null
var _fx_list: Array = []
var _gray: ShaderMaterial = null
var _art_cache := {}


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = Vector2(1280, 720)


func open(total_xp: int, summaries: Array, steps: Array) -> void:
	_total_xp = total_xp
	_sums = summaries
	_steps = steps
	var sh := Shader.new()
	sh.code = GRAY_SHADER
	_gray = ShaderMaterial.new()
	_gray.shader = sh
	var bgc := Control.new()
	bgc.size = size
	bgc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bgc.draw.connect(_draw_bg.bind(bgc))
	add_child(bgc)
	_stage = Control.new()
	_stage.size = size
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	var bars := Control.new()
	bars.size = size
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(func() -> void:
		bars.draw_rect(Rect2(0, 0, 520, 4), PcDraw.LIME)
		bars.draw_rect(Rect2(520, 0, 360, 4), PcDraw.CORAL))
	add_child(bars)
	_overlay = Control.new()
	_overlay.size = size
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_si = 0
	_render()


# --- Fundo do palco -------------------------------------------------------------

func _draw_bg(c: Control) -> void:
	# radial-gradient(ellipse at 55% 35%, #17364b 0%, #0b1d2b 50%, #050c14 100%) + faixas .bgcity
	c.draw_texture_rect(_bg_tex(), Rect2(Vector2.ZERO, size), false)
	var x := 120.0
	while x < 1280.0:
		c.draw_rect(Rect2(x, 0, 50, 720), Color(40 / 255.0, 80 / 255.0, 110 / 255.0, 0.08 * 0.7))
		x += 170.0


var _bg_texture: Texture2D = null


## Gradiente elíptico do #stage (farthest-corner a partir de 55% 35%), calculado uma vez.
func _bg_tex() -> Texture2D:
	if _bg_texture != null:
		return _bg_texture
	var w := 320
	var h := 180
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var c0 := Color("17364b")
	var c1 := Color("0b1d2b")
	var c2 := Color("050c14")
	var cx := 0.55
	var cy := 0.35
	var rx := sqrt(2.0) * maxf(cx, 1.0 - cx)
	var ry := sqrt(2.0) * maxf(cy, 1.0 - cy)
	for y in h:
		for x in w:
			var dx := ((x + 0.5) / w - cx) / rx
			var dy := ((y + 0.5) / h - cy) / ry
			var t := sqrt(dx * dx + dy * dy)
			var col := c0.lerp(c1, t / 0.5) if t < 0.5 else c1.lerp(c2, clampf((t - 0.5) / 0.5, 0.0, 1.0))
			img.set_pixel(x, y, col)
	_bg_texture = ImageTexture.create_from_image(img)
	return _bg_texture


# --- Fluxo --------------------------------------------------------------------------

func _render() -> void:
	_close_tip()
	for ch in _stage.get_children():
		ch.queue_free()
	_hot.clear()
	_focusables.clear()
	_focus = ""
	_ui = {}
	_spot = null
	_fx = null
	_fx_list.clear()
	_step_t0 = PcBlock.now()
	_enter_i = 0
	_last_enter = 0.0
	var s: Dictionary = _steps[_si]
	match str(s["kind"]):
		"xp":
			_build_xp()
		"lv":
			_build_lv(int(s["index"]))
		"move":
			_build_mv(int(s["index"]), StringName(s["move_id"]))


func _next() -> void:
	_si += 1
	if _si >= _steps.size():
		_close_tip()
		finished.emit()
		queue_free()
		return
	_render()


## Cria um bloco; `enters` = entra na sequência (ENTER_SEL do protótipo), na ordem do DOM.
func _blk(parent: Control, r: Rect2, rot: float, k: float, bg: Color, shadow: Vector2, painter: Callable, enters := true) -> PcBlock:
	var b := PcBlock.new().setup(r, rot, k, bg, shadow)
	b.painter = painter
	parent.add_child(b)
	_enter_block(b, enters)
	return b


func _enter_block(b: PcBlock, enters: bool, counts := true) -> void:
	var d := _enter_i * 0.045
	b.t0 = _step_t0 + d
	if enters:
		if counts:
			_last_enter = d
		_enter_i += 1
		b.enter(ENTER_STYLE, d)


func _letters_t(b: PcBlock) -> float:
	return (b.age() - 0.14) if TEXT_FX else 999.0


func _typed(b: PcBlock, cps := 0.016) -> int:
	if not TEXT_FX:
		return -1
	return maxi(0, int(floor((b.age() - 0.26) / cps)))


# --- Peças comuns -------------------------------------------------------------------

func _skill_info(s: Skill) -> Dictionary:
	var lines: Array[String] = MoveInspectInfo.effect_lines(s)
	return {
		"n": s.display_name, "el": int(s.element), "ty": MoveInspectInfo.type_key(s),
		"rg": MoveInspectInfo.range_key(s), "atb": s.cost, "mp": s.mp_cost,
		"pw": MoveInspectInfo.power_text(s), "lines": lines, "d": " · ".join(lines),
		"id": PostCombatFlow.move_id_of(s),
	}


## Badges de tipo/alcance (34×28, ou 28×22 nos cards pequenos). Registra o pop-up de cada ícone.
func _badges(b: PcBlock, m: Dictionary, x: float, y: float, w: float, h: float, ico: float, gap: float) -> void:
	var items: Array = []
	if m["ty"] == "STATUS":
		items.append(["STATUS", PcDraw.TYPE_C["STATUS"], PcDraw.TYPE_ICON["STATUS"], PcDraw.INK, "status"])
	else:
		items.append([m["ty"], PcDraw.TYPE_C.get(m["ty"], Color.WHITE), PcDraw.TYPE_ICON.get(m["ty"], ""), Color.WHITE, str(m["ty"])])
		if str(m["rg"]) != "":
			items.append(["rg", Color.WHITE, "range/" + str(m["rg"]), PcDraw.INK, "rg:" + str(m["rg"])])
	for it in items:
		var r := Rect2(x, y, w, h)
		PcDraw.fill_para(b, r, 6.0, it[1])
		PcDraw.draw_icon(b, it[2], Rect2(r.get_center() - Vector2(ico, ico) * 0.5, Vector2(ico, ico)), it[3])
		_hot_add(b, r, it[4])
		x += w + gap


func _hot_add(b: PcBlock, r: Rect2, tip: String) -> void:
	for h in _hot:
		if h["b"] == b and h["tip"] == tip and (h["r"] as Rect2).is_equal_approx(r):
			return
	_hot.append({"b": b, "r": r, "tip": tip})


## Pílulas ATB/MP/POWER (D-1188: POWER lilás se mágico, âmbar se físico). Retorna a largura total.
func _pills(m: Dictionary) -> Array:
	var out: Array = [["%d ATB" % int(m["atb"]), Color("1d6fd6"), Color.WHITE], ["%d MP" % int(m["mp"]), Color("2563eb"), Color.WHITE]]
	if str(m["pw"]) != "":
		var c: Color = PcDraw.STAT_C["MAG"] if m["ty"] == "MAG" else Color("f59e0b")
		out.append(["POWER ×" + str(m["pw"]), c, Color("111111")])
	return out


func _draw_pill(b: PcBlock, x: float, y: float, h: float, pad: float, fs: int, p: Array) -> float:
	var f := PcDraw.arial()
	var w := PcDraw.width(f, p[0], fs) + pad * 2.0
	PcDraw.fill_para(b, Rect2(x, y, w, h), 7.0, p[1])
	b.draw_string(f, Vector2(x + pad, PcDraw.baseline(f, fs, y, h)), p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, p[2])
	return w


func _newtag(parent: PcBlock, fs: int, right: float, top: float, pop_delay := 0.3) -> PcBlock:
	var f := PcDraw.impact(1)
	var w := PcDraw.width(f, "NEW!", fs) + 28.0
	var h := fs * 1.15 + 7.0
	var t := PcBlock.new().setup(Rect2(parent.size.x + right - w, top, w, h), 9.0, 7.0, PcDraw.LIME)
	t.painter = func(b: PcBlock) -> void:
		PcDraw.line(b, f, "NEW!", 14, 4, fs, PcDraw.INK, w - 20, 0, fs * 1.15)
	parent.add_child(t)
	t.z_index = 3
	if pop_delay >= 0.0:
		t.anim_scale = 0.0
		t.apply()
		var tw := t.create_tween()
		tw.tween_interval(pop_delay)
		tw.tween_method(func(q: float) -> void:
			t.anim_scale = PcDraw.bezier(0.2, 1.6, 0.4, 1.0, q)
			t.apply(), 0.0, 1.0, 0.5)
	return t


func _prompt(txt: String, lock: bool) -> PcBlock:
	_ui["prompt_txt"] = txt
	_ui["prompt_lock"] = lock
	var b := _blk(_stage, Rect2(938, 646, 290, 46), -2.0, 14.0, PcDraw.INK, Vector2(7, 7), _paint_prompt)
	_ui["prompt"] = b
	return b


func _paint_prompt(b: PcBlock) -> void:
	var lock: bool = _ui.get("prompt_lock", false)
	var foc := b.focused
	b.bg = PcDraw.AQUA if foc else PcDraw.INK
	var f := PcDraw.arial()
	var txt: String = _ui.get("prompt_txt", "")
	var tw := PcDraw.width(f, txt, 17)
	var total := 28.0 + 10.0 + tw
	var x := (b.size.x - total) * 0.5
	var key_bg := Color("3b4656") if lock else PcDraw.PAPER
	var key_tx := PcDraw.INK
	var col := Color("6f7f93") if lock else (PcDraw.INK if foc else Color.WHITE)
	b.draw_rect(Rect2(x, 9, 28, 28), key_bg)
	PcDraw.line(b, f, "Z", x + 14, 9, 16, key_tx, 28, 1, 28)
	PcDraw.line(b, f, txt, x + 38, 0, 17, col, b.size.x - x - 48, 0, 46)


## Faixa de etapas no topo (right 52, top 22).
func _strip() -> void:
	var f := PcDraw.arial()
	var labels: Array = []
	for s in _steps:
		labels.append(_step_short(s))
	labels.append("MAPA")
	var ws: Array = []
	var total := 0.0
	for l in labels:
		var w := PcDraw.width(f, l, 12) + 24.0
		ws.append(w)
		total += w
	total += 6.0 * (labels.size() - 1)
	var x := 1228.0 - total
	for i in labels.size():
		var cur := i == _si
		var done := i < _si
		var bg := PcDraw.AQUA if cur else PcDraw.NAVY2
		var col := PcDraw.INK if cur else (Color("3d4a5c") if done else Color("6f7f93"))
		var lab: String = labels[i]
		_blk(_stage, Rect2(x, 22, ws[i], 24), 0.0, 6.0, bg, Vector2.ZERO, func(b: PcBlock) -> void:
			PcDraw.line(b, f, lab, b.size.x * 0.5, 0, 12, col, b.size.x - 8, 1, 24))
		x += float(ws[i]) + 6.0


func _step_short(s: Dictionary) -> String:
	match str(s["kind"]):
		"xp":
			return "XP"
		"lv":
			return "LV " + _name(int(s["index"]))
		_:
			return "MOVE " + _name(int(s["index"]))


func _cmb(i: int) -> Combatant:
	return _sums[i]["combatant"]


func _name(i: int) -> String:
	return _cmb(i).name.to_upper()


func _member_el(c: Combatant) -> int:
	var els := c.get_elements()
	return int(els[0]) if els.size() > 0 else int(Element.Type.FISICO)


func _art(c: Combatant) -> Texture2D:
	var key := c.species_id.to_lower() if c.species_id != "" else c.name.to_lower()
	if not _art_cache.has(key):
		var path := ART_DIR + key + ".png"
		_art_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _art_cache[key]


## Retrato (portrait() do protótipo): o recorte cobre a caixa, centrado na horizontal, topo alinhado.
func _portrait(b: PcBlock, c: Combatant, r: Rect2, outline: float, rot_deg := 0.0) -> void:
	if rot_deg != 0.0:
		b.draw_set_transform(r.get_center(), deg_to_rad(rot_deg), Vector2.ONE)
		r = Rect2(-r.size * 0.5, r.size)
	b.draw_rect(r.grow(outline), PcDraw.INK2)
	b.draw_rect(r, Color("5c3c1e"))
	# Ícone único das HUDs (recorte Sugimori + fundo ciano-verde): scripts/ui/portrait_icon.gd.
	var tex: Texture2D = preload("res://scripts/ui/portrait_icon.gd").get_icon(c.name)
	if tex != null:
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		var kk := maxf(r.size.x / tw, r.size.y / th)
		var src := Rect2((tw - r.size.x / kk) * 0.5, (th - r.size.y / kk) * 0.5, r.size.x / kk, r.size.y / kk)
		b.draw_texture_rect_region(tex, r, src)
	b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Etapa XP -------------------------------------------------------------------------

func _build_xp() -> void:
	var tf := PcDraw.impact(1)
	var title := _blk(_stage, Rect2(52, 30, 1100, 64), 0.0, 0.0, Color(0, 0, 0, 0), Vector2.ZERO, func(b: PcBlock) -> void:
		PcDraw.letters(b, tf, [["VICTORY ", PcDraw.PAPER], ["/", PcDraw.CORAL], ["+%d XP" % _total_xp, PcDraw.LIME]], 0, 0, 62, 1100, _letters_t(b), 64))
	title.live = true
	_ui["xp"] = []
	for i in _sums.size():
		var sm: Dictionary = _sums[i]
		var hero: bool = sm.get("is_leader", false)
		var st := {"lv": int(sm["old_level"]), "xp": float(sm["old_xp"]), "stamp": false}
		_ui["xp"].append(st)
		var card := _blk(_stage, Rect2(52, 150 + i * 156, 700, 130), TILT_CARDS[i % 2], 20.0,
			PcDraw.PAPER if hero else Color("e6e3d2"), Vector2(7, 7), _paint_card.bind(i))
		card.live = true
		if not sm["is_alive"]:
			card.material = _gray
		var stamp := PcBlock.new().setup(Rect2(314, -24, 186, 42), -5.0, 12.0, PcDraw.CORAL)
		stamp.painter = func(b: PcBlock) -> void:
			PcDraw.line(b, PcDraw.impact(1), "LEVEL UP!", 93, 0, 26, Color.WHITE, 170, 1, 42)
		stamp.anim_scale = 0.0
		stamp.apply()
		stamp.use_parent_material = true
		card.add_child(stamp)
		st["stamp_b"] = stamp
	_prompt("CONTINUAR", true)
	_queue()
	_ui["xp_done"] = false
	_ui["xp_t0"] = _step_t0 + (0.0 if ENTER_STYLE == "none" else 0.65)


func _paint_card(b: PcBlock, i: int) -> void:
	if not _ui.has("xp"):
		return
	var sm: Dictionary = _sums[i]
	var c: Combatant = sm["combatant"]
	var hero: bool = sm.get("is_leader", false)
	var alive: bool = sm["is_alive"]
	var st: Dictionary = _ui["xp"][i]
	# faixa lima (herói) / aqua (aliado)
	PcDraw.fill_para(b, Rect2(-6, 0, 10, b.size.y), 4.0, PcDraw.LIME if hero else PcDraw.AQUA)
	_portrait(b, c, Rect2(30, 15, 96, 100), 3.0)
	var nf := PcDraw.impact(1)
	var nm := c.name.to_upper()
	var nw := PcDraw.letters(b, nf, [[nm, PcDraw.TEXT_DARK]], 146, 12, 32, 300, _letters_t(b))
	var e := _member_el(c)
	var er := Rect2(146 + nw + 14, 18, 34, 24)
	PcDraw.fill_para(b, er, 6.0, PcDraw.el_color(e))
	PcDraw.draw_icon(b, PcDraw.el_icon(e), Rect2(er.get_center() - Vector2(8, 8), Vector2(16, 16)), PcDraw.INK if PcDraw.el_dark(e) else Color.WHITE)
	_hot_add(b, er, "el:" + MoveInspectInfo.element_key(e))
	# LV. a → b (direita 52)
	var af := PcDraw.arial()
	var right := b.size.x - 52.0
	var lv_parts: Array = []
	if int(st["lv"]) > int(sm["old_level"]):
		lv_parts = [[str(sm["old_level"]), nf, 30, PcDraw.TEXT_DARK], ["→", nf, 24, PcDraw.CORAL], [str(st["lv"]), nf, 30, PcDraw.TEXT_DARK]]
	else:
		lv_parts = [[str(st["lv"]), nf, 30, PcDraw.TEXT_DARK]]
	var base := PcDraw.baseline(nf, 30, 16)
	var w := 0.0
	for p in lv_parts:
		w += PcDraw.width(p[1], p[0], p[2]) + (8.0 if p[0] == "→" else 0.0)
	var lvw := PcDraw.width(af, "LV.", 18) + 4.0
	var x := right - w - lvw
	b.draw_string(af, Vector2(x, base), "LV.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("3a4250"))
	x += lvw
	for p in lv_parts:
		if p[0] == "→":
			x += 4.0
		b.draw_string(p[1], Vector2(x, base), p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, p[2], p[3])
		x += PcDraw.width(p[1], p[0], p[2]) + (4.0 if p[0] == "→" else 0.0)
	if alive:
		PcDraw.line(b, af, "+%d XP" % _total_xp, 146, 58, 17, Color("2f6b12"), 300)
	else:
		PcDraw.line(b, af, "K.O. · +0 XP", 146, 58, 17, Color("444444"), 300)
	# Barra de XP (left 146, right 52, top 84, 20 px)
	var bar := Rect2(146, 84, b.size.x - 146 - 52, 20)
	PcDraw.fill_para(b, bar, 8.0, Color("d3cfbd"))
	var req := float(CrawlmonAttributeMath.get_xp_for_level_transition(int(st["lv"])))
	var frac := clampf(float(st["xp"]) / maxf(1.0, req), 0.0, 1.0)
	PcDraw.fill_para_clipped(b, Rect2(146, 84, 502, 20), 8.0, Rect2(146, 84, 502 * frac, 20), PcDraw.GOLD)
	PcDraw.line(b, af, "%d / %d XP" % [int(floor(float(st["xp"]))), int(req)], bar.end.x - 10, 60, 14, Color("3a4250"), 200, 2)


func _xp_tick() -> void:
	if not _ui.has("xp") or _ui.get("xp_done", true):
		return
	var p := clampf((PcBlock.now() - float(_ui["xp_t0"])) / 1.4, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - p, 3.0)
	for i in _sums.size():
		var sm: Dictionary = _sums[i]
		var st: Dictionary = _ui["xp"][i]
		var gain := float(_total_xp) if sm["is_alive"] else 0.0
		var lv := int(sm["old_level"])
		var xp := float(sm["old_xp"]) + gain * e
		while lv < int(sm["new_level"]) and xp >= CrawlmonAttributeMath.get_xp_for_level_transition(lv):
			xp -= CrawlmonAttributeMath.get_xp_for_level_transition(lv)
			lv += 1
		if p >= 1.0:
			lv = int(sm["new_level"])
			xp = float(sm["current_xp"])
		st["lv"] = lv
		st["xp"] = xp
		if lv > int(sm["old_level"]) and not st["stamp"]:
			st["stamp"] = true
			var sb: PcBlock = st["stamp_b"]
			var tw := sb.create_tween()
			tw.tween_method(func(q: float) -> void:
				sb.anim_scale = PcDraw.bezier(0.2, 1.6, 0.4, 1.0, q)
				sb.apply(), 0.0, 1.0, 0.32)
	if p >= 1.0:
		_ui["xp_done"] = true
		_ui["prompt_lock"] = false
		(_ui["prompt"] as PcBlock).queue_redraw()


## Fila "NESTA VITÓRIA // N ETAPAS" (left 806, top 150, 420 px, 1,2°).
func _queue() -> void:
	var n := _steps.size() + 1
	var q := Control.new()
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	q.position = Vector2(806, 150)
	q.size = Vector2(420, 34 + n * 52 - 8)
	q.pivot_offset = q.size * 0.5
	q.rotation_degrees = 1.2
	_stage.add_child(q)
	var etapas := _steps.size()
	_blk(q, Rect2(0, 0, 420, 22), 0.0, 0.0, Color(0, 0, 0, 0), Vector2.ZERO, func(b: PcBlock) -> void:
		PcDraw.line(b, PcDraw.arial(), "NESTA VITÓRIA // %d ETAPAS" % etapas, 0, 0, 14, PcDraw.LIME, 420)
		b.draw_rect(Rect2(0, 20, 420, 2), Color("3f5a2a")))
	for i in n:
		var lab: Array
		if i < _steps.size():
			lab = _queue_label(_steps[i])
		else:
			lab = ["MAPA", "Voltar à exploração"]
		var cur := i == _si
		var blk := _blk(q, Rect2(0, 34 + i * 52, 420, 44), TILT_QUEUE[i % 6], 12.0,
			PcDraw.AQUA if cur else PcDraw.NAVY2, Vector2(7, 7), _paint_qi.bind(lab, cur), false)
		blk.rest_alpha = 0.4 if i < _si else 1.0
		_enter_i -= 0
		_enter_block(blk, true)


func _paint_qi(b: PcBlock, lab: Array, cur: bool) -> void:
	var kf := PcDraw.impact(1)
	var kw := PcDraw.width(kf, lab[0], 13) + 16.0
	var kh := 13.0 * 1.15 + 6.0
	var ky := (b.size.y - kh) * 0.5
	b.draw_rect(Rect2(22, ky, kw, kh), PcDraw.INK)
	PcDraw.line(b, kf, lab[0], 22 + kw * 0.5, ky, 13, PcDraw.GOLD, kw, 1, kh)
	PcDraw.line(b, PcDraw.arial(), lab[1], 22 + kw + 10, 0, 15, PcDraw.INK if cur else Color("dbe4ee"), b.size.x - 16 - (22 + kw + 10), 0, b.size.y)


func _queue_label(s: Dictionary) -> Array:
	match str(s["kind"]):
		"xp":
			return ["XP", "Experiência do grupo"]
		"lv":
			var sm: Dictionary = _sums[int(s["index"])]
			return ["LV", "%s · Lv %d → %d · %s" % [_name(int(s["index"])), int(sm["old_level"]), int(sm["new_level"]), "pontos" if sm.get("is_leader", false) else "auto"]]
		_:
			var sk := Skill.from_id(StringName(s["move_id"]))
			return ["MOVE", "%s · %s" % [_name(int(s["index"])), sk.display_name if sk != null else str(s["move_id"])]]


# --- Etapa LV ---------------------------------------------------------------------------

func _build_lv(i: int) -> void:
	var sm: Dictionary = _sums[i]
	var c: Combatant = sm["combatant"]
	var hero: bool = sm.get("is_leader", false)
	var pts := int(c.distributable_points) if hero else PostCombatFlow.ally_points_pending(sm)
	_ui["m"] = i
	_ui["hero"] = hero
	_ui["alloc"] = {}
	_ui["left"] = pts if hero else 0
	_ui["pts"] = pts
	_ui["sel"] = 0 if hero else 6
	var lvc := _blk(_stage, Rect2(52, 118, 500, 500), -2.5, 26.0, PcDraw.PAPER if hero else Color("e6e3d2"), Vector2(7, 7), _paint_lvcard.bind(i))
	lvc.live = true
	var hp_g := int(sm.get("new_max_hp", c.max_hp)) - int(sm.get("old_max_hp", c.max_hp))
	var mp_g := int(sm.get("new_max_mp", c.max_mp)) - int(sm.get("old_max_mp", c.max_mp))
	var sg := [["HP MÁX", "HP", int(sm.get("old_max_hp", c.max_hp)), hp_g], ["MP MÁX", "MP", int(sm.get("old_max_mp", c.max_mp)), mp_g]]
	for j in 2:
		var row: Array = sg[j]
		var b := PcBlock.new().setup(Rect2(44, 282 + j * 56, 412, 44), TILT_SG[j], 12.0, PcDraw.INK2)
		b.painter = func(bb: PcBlock) -> void:
			var sc: Color = PcDraw.STAT_C[row[1]]
			PcDraw.fill_para(bb, Rect2(0, 0, 22, 44), 12.0, sc)
			PcDraw.line(bb, PcDraw.impact(1), row[0], 26, 0, 20, sc, 200, 0, 44)
			var af := PcDraw.arial()
			var gtxt := "+%d" % row[3]
			var gw := PcDraw.width(af, gtxt, 17)
			PcDraw.line(bb, af, gtxt, bb.size.x - 26, 0, 17, PcDraw.LIME, 80, 2, 44)
			PcDraw.line(bb, af, str(row[2]), bb.size.x - 26 - gw - 8, 0, 17, Color("dbe4ee"), 80, 2, 44)
		lvc.add_child(b)
	var stamp := PcBlock.new().setup(Rect2(290, -22, 186, 42), -5.0, 12.0, PcDraw.CORAL)
	stamp.t0 = lvc.t0
	stamp.live = true
	stamp.painter = func(b: PcBlock) -> void:
		PcDraw.letters(b, PcDraw.impact(1), [["LEVEL UP!", Color.WHITE]], 93, 0, 26, 170, (b.now() - lvc.t0 - 0.14) if TEXT_FX else 999.0, 42, 1)
	lvc.add_child(stamp)
	var attr := _blk(_stage, Rect2(604, 128, 620, 482), 1.5, 26.0, PcDraw.NAVY, Vector2(7, 7), _paint_attr)
	attr.live = true
	_ui["rows"] = []
	for r in 6:
		var rb := PcBlock.new().setup(Rect2(44, 84 + r * 52, 532, 46), TILT_ROWS[r], 12.0, PcDraw.NAVY2)
		rb.painter = _paint_row.bind(r)
		attr.add_child(rb)
		_enter_block(rb, true)
		_ui["rows"].append(rb)
	var cb := PcBlock.new().setup(Rect2(44, 404, 532, 54), -1.0, 16.0, Color("253446"), Vector2(7, 7))
	cb.painter = _paint_cbtn
	attr.add_child(cb)
	_enter_block(cb, true)
	_ui["cbtn"] = cb
	_strip()


func _paint_lvcard(b: PcBlock, i: int) -> void:
	if not _ui.has("hero"):
		return
	var sm: Dictionary = _sums[i]
	var c: Combatant = sm["combatant"]
	var hero: bool = sm.get("is_leader", false)
	_portrait(b, c, Rect2(44, 34, 196, 216), 4.0, 2.0)
	var tf := PcDraw.impact(0)
	PcDraw.letters(b, tf, [[c.name.to_upper(), PcDraw.TEXT_DARK]], 262, 38, 46, b.size.x - 262 - 30, _letters_t(b))
	# LV. a → b
	var af := PcDraw.arial()
	var base := PcDraw.baseline(tf, 44, 98)
	var x := 262.0
	b.draw_string(af, Vector2(x, base), "LV. ", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("3a4250"))
	x += PcDraw.width(af, "LV. ", 20)
	for p in [[str(sm["old_level"]), 44, PcDraw.TEXT_DARK], ["→", 24, PcDraw.CORAL], [str(sm["new_level"]), 44, PcDraw.TEXT_DARK]]:
		if p[0] == "→":
			x += 4.0
		b.draw_string(tf, Vector2(x, base), p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, p[1], p[2])
		x += PcDraw.width(tf, p[0], p[1]) + (4.0 if p[0] == "→" else 0.0)
	var pts := int(_ui.get("pts", 0))
	var l1 := "Líder · distribua os pontos" if hero else "Aliado · pontos automáticos"
	var l2 := "%d ponto%s de atributo" % [pts, "s" if pts > 1 else ""]
	var n := _typed(b)
	var maxw := b.size.x - 262 - 26
	var s1 := PcDraw.fit(af, l1, 15, maxw)
	var s2 := PcDraw.fit(af, l2, 15, maxw)
	var t1 := l1 if n < 0 else l1.substr(0, n)
	var t2 := l2 if n < 0 else l2.substr(0, maxi(0, n - l1.length() - 1))
	b.draw_string(af, Vector2(262, PcDraw.baseline(af, s1, 166, 24)), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("3a4250"))
	b.draw_string(af, Vector2(262, PcDraw.baseline(af, s2, 190, 24)), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("3a4250"))


func _paint_attr(b: PcBlock) -> void:
	if not _ui.has("hero"):
		return
	PcDraw.letters(b, PcDraw.impact(1), [["ATTRIBUTES ", PcDraw.PAPER], ["/", PcDraw.CORAL]], 50, 24, 30, 300, _letters_t(b))
	var txt := "PONTOS: %d" % int(_ui["left"]) if _ui["hero"] else "AUTOMÁTICO"
	PcDraw.line(b, PcDraw.arial(), txt, b.size.x - 50, 30, 18, PcDraw.LIME, 200, 2)


func _paint_row(b: PcBlock, r: int) -> void:
	if not _ui.has("hero"):
		return
	var c := _cmb(int(_ui["m"]))
	var st: String = STATS[r][0]
	var a := int((_ui["alloc"] as Dictionary).get(st, 0))
	var sel := int(_ui["sel"]) == r
	var auto: bool = (not bool(_ui["hero"])) and a > 0
	b.bg = Color("21486a") if sel else (Color("3a2f12") if auto else PcDraw.NAVY2)
	var sc: Color = PcDraw.STAT_C[st]
	PcDraw.fill_para(b, Rect2(0, 0, 22, b.size.y), 12.0, sc)
	var tf := PcDraw.impact(1)
	var af := PcDraw.arial()
	PcDraw.line(b, tf, st, 28, 0, 24, sc, 66, 0, b.size.y)
	var hero: bool = _ui["hero"]
	var right := b.size.x - 24.0
	var arrow_c := Color.WHITE if sel else Color("4f6077")
	var x := right
	if hero:
		var w := PcDraw.width(af, "▶", 16)
		PcDraw.line(b, af, "▶", right, 0, 16, arrow_c, 30, 2, b.size.y)
		x = right - w - 10.0
	var plus := ("+%d" % a) if a > 0 else ""
	if hero:
		PcDraw.line(b, af, plus, x - 34, 0, 18, PcDraw.LIME, 34, 0, b.size.y)
		x -= 34.0 + 10.0
	else:
		PcDraw.line(b, af, plus, x, 0, 18, PcDraw.LIME, 34, 2, b.size.y)
		x -= 34.0 + 10.0
	PcDraw.line(b, af, str(c.get_effective_stat(st) + a), x, 0, 24, Color("e6edf5"), 60, 2, b.size.y)
	x -= 34.0 + 10.0
	if hero:
		PcDraw.line(b, af, "◀", x, 0, 16, arrow_c, 30, 2, b.size.y)
		x -= PcDraw.width(af, "◀", 16)
	var ds_x := 28.0 + 66.0
	var ds_w := (b.size.x - 24.0 - 130.0) - ds_x
	PcDraw.line(b, af, STATS[r][1], ds_x, 0, 14, Color("8fa3b8"), ds_w, 0, b.size.y)


func _paint_cbtn(b: PcBlock) -> void:
	if not _ui.has("hero"):
		return
	var ready := int(_ui["left"]) == 0
	var sel := int(_ui["sel"]) == 6
	b.bg = (Color("efff9e") if sel else PcDraw.LIME) if ready else Color("253446")
	var txt := "CONFIRMAR" if ready else "DISTRIBUA TODOS OS PONTOS"
	PcDraw.line(b, PcDraw.impact(1), txt, b.size.x * 0.5, 0, 24, PcDraw.INK if ready else Color("6f7f93"), b.size.x - 40, 1, b.size.y)


func _lv_redraw() -> void:
	for rb in _ui.get("rows", []):
		(rb as PcBlock).queue_redraw()
	if _ui.has("cbtn"):
		(_ui["cbtn"] as PcBlock).queue_redraw()


func _lv_key(k: String) -> void:
	var hero: bool = _ui["hero"]
	var sel := int(_ui["sel"])
	var alloc: Dictionary = _ui["alloc"]
	if k == "up":
		_ui["sel"] = (sel + 6) % 7
	elif k == "down":
		_ui["sel"] = (sel + 1) % 7
	elif hero and k == "right" and sel < 6 and int(_ui["left"]) > 0:
		alloc[STATS[sel][0]] = int(alloc.get(STATS[sel][0], 0)) + 1
		_ui["left"] = int(_ui["left"]) - 1
	elif hero and k == "left" and sel < 6:
		var stn: String = STATS[sel][0]
		if int(alloc.get(stn, 0)) > 0:
			alloc[stn] = int(alloc[stn]) - 1
			_ui["left"] = int(_ui["left"]) + 1
	elif k == "z":
		if sel < 6 and int(_ui["left"]) > 0 and hero:
			alloc[STATS[sel][0]] = int(alloc.get(STATS[sel][0], 0)) + 1
			_ui["left"] = int(_ui["left"]) - 1
		elif int(_ui["left"]) == 0 and (sel == 6 or not hero):
			if hero:
				PostCombatFlow.apply_leader_allocation(_cmb(int(_ui["m"])), alloc)
			_next()
			return
		elif int(_ui["left"]) == 0:
			_ui["sel"] = 6
	_lv_redraw()


# --- Etapa MOVE NOVO --------------------------------------------------------------------

func _build_mv(i: int, mv: StringName) -> void:
	var c := _cmb(i)
	_ui["m"] = i
	_ui["mv"] = mv
	_ui["full"] = c.skills.size() >= PostCombatFlow.MAX_MOVES
	_ui["learned"] = not _ui["full"]
	_ui["new_idx"] = -1
	_ui["result"] = ""
	if not _ui["full"]:
		_ui["new_idx"] = PostCombatFlow.learn_into_free_slot(c, mv)
	var tf := PcDraw.impact(1)
	var head := _blk(_stage, Rect2(52, 30, 700, 64), 0.0, 0.0, Color(0, 0, 0, 0), Vector2.ZERO, func(b: PcBlock) -> void:
		PcDraw.letters(b, tf, [["NEW ", PcDraw.PAPER], ["/", PcDraw.CORAL], ["MOVE", PcDraw.AQUA]], 0, 0, 62, 700, _letters_t(b), 64))
	head.live = true
	var new_skill := Skill.from_id(mv)
	var sheet := _blk(_stage, Rect2(52, 132, 440, 250), -2.5, 18.0, PcDraw.el_color(int(new_skill.element)), Vector2(7, 7), _paint_sheet.bind(new_skill))
	sheet.live = true
	_newtag(sheet, 22, 14, -18)
	_focusables["sheet"] = sheet
	_blk(_stage, Rect2(540, 126, 690, 22), 0.0, 0.0, Color(0, 0, 0, 0), Vector2.ZERO, _paint_slots_head)
	_ui["slots"] = []
	for s in 8:
		_ui["slots"].append(_slot(s, true))
	if _ui["full"]:
		var skip := _blk(_stage, Rect2(52, 430, 440, 56), 1.5, 16.0, Color("3a1715"), Vector2(7, 7), func(b: PcBlock) -> void:
			b.bg = PcDraw.CORAL if b.focused else Color("3a1715")
			PcDraw.line(b, PcDraw.impact(1), "NÃO APRENDER " + new_skill.display_name.to_upper(), b.size.x * 0.5, 0, 22,
				Color.WHITE if b.focused else Color("ffb3aa"), b.size.x - 40, 1, b.size.y))
		_focusables["skip"] = skip
		_ui["skip"] = skip
	var msg := _blk(_stage, Rect2(52, 510, 440, 80), 0.0, 0.0, Color(0, 0, 0, 0), Vector2.ZERO, _paint_msg)
	msg.live = true
	_ui["msg_b"] = msg
	_prompt("ESCOLHA UM MOVE" if _ui["full"] else "CONTINUAR", _ui["full"])
	_focusables["go"] = _ui["prompt"]
	_strip()
	_set_focus("s0" if _ui["full"] else "sheet")
	if int(_ui["new_idx"]) >= 0:
		var nb: PcBlock = _ui["slots"][int(_ui["new_idx"])]
		_epic_arrive(nb, _last_enter + 0.45)


func _slot(s: int, building: bool) -> PcBlock:
	var c := _cmb(int(_ui["m"]))
	var r := Rect2(540 + (s % 2) * 350, 166 + floori(s / 2.0) * 110, 330, 100)
	var b: PcBlock
	if s >= c.skills.size():
		b = PcBlock.new().setup(r, TILT_SLOTS[s], 14.0, Color(14 / 255.0, 36 / 255.0, 53 / 255.0, 0.4))
		b.painter = func(bb: PcBlock) -> void:
			PcDraw.line(bb, PcDraw.impact(0), "VAGA LIVRE", 28, 34, 20, Color("4d6278"), 280)
		_stage.add_child(b)
		if building:
			_enter_block(b, true)
		return b
	var sk: Skill = c.skills[s]
	b = PcBlock.new().setup(r, TILT_SLOTS[s], 14.0, PcDraw.NAVY2, Vector2(6, 6))
	b.painter = _paint_mcard.bind(sk)
	_stage.add_child(b)
	var arriving := s == int(_ui.get("new_idx", -1))
	if building:
		if arriving:
			_enter_block(b, false)
			_enter_i += 1  # o índice conta, mas o Move novo entra depois, com animação própria
		else:
			_enter_block(b, true)
	_focusables["s%d" % s] = b
	if PostCombatFlow.move_id_of(sk) == _ui["mv"] and arriving:
		var tag := _newtag(b, 17, 10, -14, -1.0)
		tag.visible = false
		b.set_meta("newtag", tag)
	return b


func _paint_sheet(b: PcBlock, sk: Skill) -> void:
	if not _ui.has("mv"):
		return
	var m := _skill_info(sk)
	var e: int = m["el"]
	var dark := PcDraw.el_dark(e)
	var fg := PcDraw.INK if dark else Color.WHITE
	var sub := Color(8 / 255.0, 14 / 255.0, 24 / 255.0, 0.85) if dark else Color(1, 1, 1, 0.92)
	PcDraw.draw_icon(b, PcDraw.el_icon(e), Rect2(b.size.x - 26 - 170, 34, 170, 170), Color(0, 0, 0, 0.16) if dark else Color(1, 1, 1, 0.24))
	PcDraw.letters(b, PcDraw.impact(0), [[str(m["n"]).to_upper(), fg]], 34, 22, 42, b.size.x - 34 - 24, _letters_t(b))
	_badges(b, m, 34, 80, 34, 28, 18, 8)
	var af := PcDraw.arial()
	var segs := [{"text": str(m["d"]), "color": null}]
	var fs := 15
	while fs > 10 and PcDraw.wrapped_height(af, segs, 206, fs, fs + 6.0) > 70.0:
		fs -= 1
	PcDraw.draw_wrapped(b, af, segs, 34, 124, 206, fs, fs + 6.0, sub, _typed(b))
	var x := 34.0
	for p in _pills(m):
		x += _draw_pill(b, x, b.size.y - 24 - 28, 28, 14, 14, p) + 8.0


func _paint_mcard(b: PcBlock, sk: Skill) -> void:
	if not _ui.has("mv"):
		return
	var m := _skill_info(sk)
	var e: int = m["el"]
	b.bg = Color("21486a") if b.focused else PcDraw.NAVY2
	var tile := Rect2(0, 0, 78, b.size.y)
	PcDraw.fill_para(b, tile, 14.0, PcDraw.el_color(e))
	PcDraw.draw_icon(b, PcDraw.el_icon(e), Rect2(tile.get_center() - Vector2(17, 17), Vector2(34, 34)), PcDraw.INK if PcDraw.el_dark(e) else Color.WHITE)
	_hot_add(b, tile, "el:" + MoveInspectInfo.element_key(e))
	PcDraw.draw_icon(b, PcDraw.el_icon(e), Rect2(b.size.x - 18 - 80, 10, 80, 80), Color(1, 1, 1, 0.13))
	PcDraw.line(b, PcDraw.impact(1), str(m["n"]).to_upper(), 92, 12, 24, Color.WHITE, b.size.x - 92 - 16)
	_badges(b, m, 92, 46, 28, 22, 14, 6)
	var y := b.size.y - 12.0 - 16.0
	for p in 5:
		PcDraw.fill_para(b, Rect2(92 + p * 18, y + 2, 15, 12), 4.0, Color("22a8d6") if p < int(m["atb"]) else Color("244055"))
	PcDraw.line(b, PcDraw.arial(), "%dMP" % int(m["mp"]), b.size.x - 22, y, 14, Color("cfe3f5"), 80, 2, 16)


func _paint_slots_head(b: PcBlock) -> void:
	if not _ui.has("mv"):
		return
	var c := _cmb(int(_ui["m"]))
	var af := PcDraw.arial()
	var t1 := "%s // MOVES %d/8" % [c.name.to_upper(), mini(8, c.skills.size())]
	var w := PcDraw.line(b, af, t1, 0, 0, 14, PcDraw.LIME, 400)
	var sub: String
	if _ui["result"] != "":
		sub = ("aprendido na vaga %d" % (int(_ui["new_idx"]) + 1)) if int(_ui["new_idx"]) >= 0 else "nada mudou"
	elif _ui["full"]:
		sub = "cheio: escolha um para esquecer"
	else:
		sub = "aprendido na vaga %d" % (int(_ui["new_idx"]) + 1)
	PcDraw.line(b, af, sub, w + 10, 0, 14, Color("8a99ad"), b.size.x - w - 10)
	b.draw_rect(Rect2(0, 20, b.size.x, 2), Color("3f5a2a"))


func _msg_text() -> String:
	var c := _cmb(int(_ui["m"]))
	if _ui["result"] != "":
		return _ui["result"]
	if _ui["full"]:
		return "Setas escolhem o Move. Z inspeciona; na inspeção, Z esquece."
	return "%s aprendeu <b>%s</b>!" % [c.name.to_upper(), Skill.from_id(_ui["mv"]).display_name]


func _paint_msg(b: PcBlock) -> void:
	if not _ui.has("mv"):
		return
	var txt := _msg_text()
	var segs := PcDraw.markup(txt, PcDraw.LIME)
	var af := PcDraw.arial()
	var fs := 18
	while fs > 11 and PcDraw.wrapped_height(af, segs, 440, fs, fs + 8.0) > 80.0:
		fs -= 1
	var n := _typed(b) if not _ui.get("msg_instant", false) else -1
	PcDraw.draw_wrapped(b, af, segs, 0, 0, 440, fs, fs + 8.0, Color("e6edf5"), n)


func _mv_paint() -> void:
	var go: PcBlock = _ui["prompt"]
	_ui["prompt_lock"] = not _ui["learned"]
	_ui["prompt_txt"] = "CONTINUAR" if _ui["learned"] else "ESCOLHA UM MOVE"
	go.queue_redraw()
	if _ui.has("skip"):
		(_ui["skip"] as PcBlock).visible = not _ui["learned"]
	for ch in _stage.get_children():
		if ch is PcBlock:
			(ch as PcBlock).queue_redraw()


func _set_focus(f: String) -> void:
	_focus = f
	for key in _focusables:
		var b: PcBlock = _focusables[key]
		if not is_instance_valid(b):
			continue
		var on: bool = key == f
		if key == "sheet":
			b.set_focus(on, 6.0, 0.03)
		else:
			b.set_focus(on)
		b.queue_redraw()


## Navegação espacial (moveFocus do protótipo): o item mais próximo na direção da seta.
func _move_focus(dir: Vector2) -> void:
	if not _focusables.has(_focus):
		return
	var cur: PcBlock = _focusables[_focus]
	var a := _center(cur)
	var best := ""
	var bd := 1e9
	for key in _focusables:
		var b: PcBlock = _focusables[key]
		if b == cur or not b.visible:
			continue
		var c := _center(b)
		var dx := c.x - a.x
		var dy := c.y - a.y
		var along := dx * dir.x + dy * dir.y
		if along <= 4.0:
			continue
		var across := absf(dx * dir.y - dy * dir.x)
		var d := along + across * 2.2
		if d < bd:
			bd = d
			best = key
	if best != "":
		_set_focus(best)


func _center(b: PcBlock) -> Vector2:
	return b.base_pos + b.size * 0.5


func _activate(f: String) -> void:
	if f == "sheet":
		_open_inspect(Skill.from_id(_ui["mv"]), -1)
	elif f == "skip":
		_open_confirm()
	elif f == "go":
		if _ui["learned"]:
			_next()
	elif f.begins_with("s"):
		var idx := int(f.substr(1))
		var c := _cmb(int(_ui["m"]))
		if idx < c.skills.size():
			_open_inspect(c.skills[idx], idx if (_ui["full"] and not _ui["learned"]) else -1)
	_mv_paint()


func _forget_slot(idx: int) -> void:
	var c := _cmb(int(_ui["m"]))
	var old := PostCombatFlow.forget_and_learn(c, idx, _ui["mv"])
	var old_sk := Skill.from_id(old)
	_ui["new_idx"] = idx
	_ui["full"] = false
	_ui["learned"] = true
	_ui["result"] = "%s esqueceu %s e aprendeu <b>%s</b>!" % [c.name.to_upper(), old_sk.display_name if old_sk != null else str(old), Skill.from_id(_ui["mv"]).display_name]
	_ui["msg_instant"] = true
	var oldb: PcBlock = _ui["slots"][idx]
	_focusables.erase("s%d" % idx)
	for h in _hot.duplicate():
		if h["b"] == oldb:
			_hot.erase(h)
	oldb.queue_free()
	var nb := _slot(idx, false)
	_ui["slots"][idx] = nb
	_epic_arrive(nb, 0.08)
	_set_focus("go")
	_mv_paint()


func _skip_learning() -> void:
	var c := _cmb(int(_ui["m"]))
	_ui["new_idx"] = -1
	_ui["full"] = false
	_ui["learned"] = true
	_ui["result"] = "%s não aprendeu <b>%s</b>." % [c.name.to_upper(), Skill.from_id(_ui["mv"]).display_name]
	_ui["msg_instant"] = true
	_set_focus("go")
	_mv_paint()


# --- Chegada épica do Move novo (rodada 10; sem flash de tela) ---------------------------

func _epic_arrive(b: PcBlock, delay: float) -> void:
	b.modulate.a = 0.0
	var e := int((b.painter.get_bound_arguments()[0] as Skill).element)
	var col := PcDraw.el_color(e)
	var tw := b.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		if _spot == null:
			_spot = ColorRect.new()
			_spot.color = Color(2 / 255.0, 5 / 255.0, 10 / 255.0, 0.62)
			_spot.size = size
			_spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_spot.z_index = 7
			_stage.add_child(_spot)
		_spot.modulate.a = 0.0
		_spot.create_tween().tween_property(_spot, "modulate:a", 1.0, 0.25)
		b.z_index = 8)
	# slam .62 s: (-120,-300) ×2,4 −14° → (0,8) ×.94 1° → (0,-6) ×1,06 → (0,2) ×.99 → repouso
	var keys := [[0.0, Vector2(-120, -300), 2.4, -14.0, 0.0], [0.55, Vector2(0, 8), 0.94, 1.0, 1.0],
		[0.72, Vector2(0, -6), 1.06, 0.0, 1.0], [0.86, Vector2(0, 2), 0.99, 0.0, 1.0], [1.0, Vector2.ZERO, 1.0, 0.0, 1.0]]
	for i in range(1, keys.size()):
		var ka: Array = keys[i - 1]
		var kb: Array = keys[i]
		tw.tween_method(func(q: float) -> void:
			var t := PcDraw.bezier(0.55, 0.0, 0.35, 1.0, q)
			b.anim_off = (ka[1] as Vector2).lerp(kb[1], t)
			b.anim_scale = lerpf(ka[2], kb[2], t)
			b.anim_rot = deg_to_rad(lerpf(ka[3], kb[3], t))
			b.modulate.a = lerpf(ka[4], kb[4], t)
			b.apply(), 0.0, 1.0, (float(kb[0]) - float(ka[0])) * 0.62)
		if i == 1:
			tw.tween_callback(_impact.bind(b, e, col))
	tw.tween_callback(func() -> void: b.z_index = 4 if b.focused else 0)
	var tw2 := create_tween()
	tw2.tween_interval(delay + 1.05)
	tw2.tween_callback(func() -> void:
		if _spot != null and is_instance_valid(_spot):
			_spot.create_tween().tween_property(_spot, "modulate:a", 0.0, 0.25))


func _impact(b: PcBlock, e: int, col: Color) -> void:
	if not is_instance_valid(b):
		return
	if _fx == null:
		_fx = Control.new()
		_fx.size = size
		_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx.z_index = 9
		_fx.draw.connect(_draw_fx)
		_stage.add_child(_fx)
	var c := b.base_pos + b.size * 0.5
	var t := PcBlock.now()
	_fx_list.append({"kind": "ghost", "c": c, "t": t, "col": col, "icon": PcDraw.el_icon(e)})
	_fx_list.append({"kind": "ring", "c": c, "t": t, "col": col})
	_fx_list.append({"kind": "ring", "c": c, "t": t + 0.08, "col": Color.WHITE})
	for i in 14:
		var a := i * (360.0 / 14.0) + (8.0 if i % 2 == 1 else -8.0)
		_fx_list.append({"kind": "ray", "c": c, "t": t, "col": col, "a": deg_to_rad(a), "w": 140.0 + (i % 3) * 50.0})
	for i in 18:
		var a := randf() * TAU
		var d := 120.0 + randf() * 170.0
		_fx_list.append({"kind": "spark", "c": c, "t": t, "col": col if i % 3 != 0 else Color.WHITE,
			"d": Vector2(cos(a) * d, sin(a) * d + 60.0)})
	for s in _ui.get("slots", []):
		if is_instance_valid(s) and s != b:
			(s as PcBlock).shake()
	if _focusables.has("sheet"):
		(_focusables["sheet"] as PcBlock).shake()
	if b.has_meta("newtag"):
		var tag: PcBlock = b.get_meta("newtag")
		tag.visible = true
		var tw := tag.create_tween()
		var ks := [[0.0, 3.2, 40.0, 0.0], [0.6, 0.9, -6.0, 1.0], [1.0, 1.0, 0.0, 1.0]]
		for i in range(1, ks.size()):
			var ka: Array = ks[i - 1]
			var kb: Array = ks[i]
			tw.tween_method(func(q: float) -> void:
				var tt := PcDraw.bezier(0.2, 1.8, 0.4, 1.0, q)
				tag.anim_scale = lerpf(ka[1], kb[1], tt)
				tag.anim_rot = deg_to_rad(lerpf(ka[2], kb[2], tt))
				tag.modulate.a = clampf(lerpf(ka[3], kb[3], tt), 0.0, 1.0)
				tag.apply(), 0.0, 1.0, (float(kb[0]) - float(ka[0])) * 0.5)


func _draw_fx() -> void:
	var now := PcBlock.now()
	var alive: Array = []
	for f in _fx_list:
		var age := now - float(f["t"])
		var c: Vector2 = f["c"]
		var col: Color = f["col"]
		match str(f["kind"]):
			"ghost":
				if age < 0.8:
					var p := PcDraw.bezier(0.1, 0.7, 0.3, 1.0, maxf(0.0, age) / 0.8)
					var s := lerpf(0.4, 2.1, p) * 300.0
					_fx.draw_set_transform(c, deg_to_rad(lerpf(-20.0, 10.0, p)), Vector2.ONE)
					PcDraw.draw_icon(_fx, f["icon"], Rect2(-s * 0.5, -s * 0.5, s, s), Color(col, 0.55 * (1.0 - p)))
					_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					alive.append(f)
			"ring":
				if age < 0.7:
					if age >= 0.0:
						var p := PcDraw.bezier(0.1, 0.7, 0.3, 1.0, age / 0.7)
						var sc := lerpf(0.3, 11.0, p)
						var bw := lerpf(6.0, 1.0, p) * sc
						_fx.draw_arc(c, 20.0 * sc - bw * 0.5, 0.0, TAU, 96, Color(col, 1.0 - p), bw)
					alive.append(f)
			"ray":
				if age < 0.55:
					var p := PcDraw.bezier(0.1, 0.8, 0.3, 1.0, age / 0.55)
					var len := float(f["w"]) * lerpf(0.1, 1.0, p)
					var off := lerpf(30.0, 160.0, p)
					var dir := Vector2.from_angle(f["a"])
					var nrm := Vector2(-dir.y, dir.x)
					var p0 := c + dir * off
					var p1 := p0 + dir * len
					var a := 1.0 - p
					_fx.draw_polygon(PackedVector2Array([p0 - nrm * 1.2, p1 - nrm * 4.0, p1 + nrm * 4.0, p0 + nrm * 1.2]),
						PackedColorArray([Color(col, a), Color(col, 0.0), Color(col, 0.0), Color(col, a)]))
					alive.append(f)
			"spark":
				if age < 0.8:
					var p := PcDraw.bezier(0.15, 0.7, 0.4, 1.0, age / 0.8)
					var pos := c + (f["d"] as Vector2) * p
					var s := lerpf(1.4, 0.2, p) * 5.0
					var rot := deg_to_rad(220.0 * p)
					var pts := PackedVector2Array()
					for q in 4:
						pts.append(pos + Vector2.from_angle(rot + q * PI * 0.5 - PI * 0.5) * s)
					_fx.draw_colored_polygon(pts, Color(col, 1.0 - p))
					alive.append(f)
	_fx_list = alive


# --- Inspeção (Z ou clique; não abre sozinha) --------------------------------------------

func _open_inspect(sk: Skill, forget_idx: int) -> void:
	if sk == null:
		return
	_close_tip()
	var m := _skill_info(sk)
	var e: int = m["el"]
	var dark := PcDraw.el_dark(e)
	var fg := PcDraw.INK if dark else Color.WHITE
	var c := _cmb(int(_ui["m"]))
	_insp = Control.new()
	_insp.size = size
	_insp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_insp.z_index = 20
	var dim := ColorRect.new()
	dim.color = Color(3 / 255.0, 7 / 255.0, 12 / 255.0, 0.9)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_insp.add_child(dim)
	_overlay.add_child(_insp)
	_ui["insp_forget"] = forget_idx
	var t0 := PcBlock.now()
	var blocks: Array = []
	var head := PcBlock.new().setup(Rect2(72, 54, 1136, 156), -1.2, 24.0, PcDraw.el_color(e), Vector2(7, 7))
	head.painter = func(b: PcBlock) -> void:
		PcDraw.draw_icon(b, PcDraw.el_icon(e), Rect2(b.size.x - 60 - 170, -6, 170, 170), Color(0, 0, 0, 0.16) if dark else Color(1, 1, 1, 0.24))
		PcDraw.line(b, PcDraw.arial(1), c.name.to_upper() + " // INSPECT", 46, 16, 14, Color(fg, 0.75), 400)
		PcDraw.letters(b, PcDraw.impact(0), [[str(m["n"]).to_upper(), fg]], 46, 36, 58, 420, (b.age() - 0.14) if TEXT_FX else 999.0)
		_badges(b, m, 46, 104, 34, 28, 18, 8)
		_paint_insp_lines(b, m["lines"])
		var y := 26.0
		for p in _pills(m):
			var w := PcDraw.width(PcDraw.arial(), p[0], 16) + 32.0
			_draw_pill(b, b.size.x - 220 - w, y, 32, 16, 16, p)
			y += 32.0 + 7.0
	head.live = true
	_insp.add_child(head)
	blocks.append(head)
	if PostCombatFlow.move_id_of(sk) == _ui["mv"]:
		_newtag(head, 28, 16, -22)
	var b1 := PcBlock.new().setup(Rect2(72, 236, 620, 396), 1.0, 20.0, PcDraw.NAVY, Vector2(7, 7))
	b1.painter = _paint_mech.bind(sk, c)
	b1.live = true
	_insp.add_child(b1)
	blocks.append(b1)
	var b2 := PcBlock.new().setup(Rect2(716, 236, 492, 396), -1.0, 20.0, Color("1a1226"), Vector2(7, 7))
	b2.painter = _paint_visual.bind(sk)
	b2.live = true
	_insp.add_child(b2)
	blocks.append(b2)
	if forget_idx >= 0:
		blocks.append(_insp_button(Rect2(690, 652, 250, 44), "Z", "ESQUECER ESTE", PcDraw.CORAL, Color.WHITE, Color.WHITE, PcDraw.INK, "forget"))
		blocks.append(_insp_button(Rect2(958, 652, 250, 44), "X", "VOLTAR", PcDraw.PAPER, PcDraw.INK, PcDraw.INK, Color.WHITE, "back"))
	else:
		blocks.append(_insp_button(Rect2(958, 652, 250, 44), "Z", "FECHAR", PcDraw.PAPER, PcDraw.INK, PcDraw.INK, Color.WHITE, "back"))
	for i in blocks.size():
		var bb: PcBlock = blocks[i]
		bb.t0 = t0 + i * 0.06
		bb.enter(ENTER_STYLE, i * 0.06)


func _insp_button(r: Rect2, key: String, label: String, bg: Color, fg: Color, key_bg: Color, key_fg: Color, act: String) -> PcBlock:
	var b := PcBlock.new().setup(r, -2.0, 14.0, bg, Vector2(7, 7))
	b.set_meta("act", act)
	b.painter = func(bb: PcBlock) -> void:
		var f := PcDraw.arial()
		var tw := PcDraw.width(f, label, 16)
		var x := (bb.size.x - (28.0 + 10.0 + tw)) * 0.5
		bb.draw_rect(Rect2(x, 8, 28, 28), key_bg)
		PcDraw.line(bb, f, key, x + 14, 8, 16, key_fg, 28, 1, 28)
		PcDraw.line(bb, f, label, x + 38, 0, 16, fg, bb.size.x - x - 44, 0, bb.size.y)
	_insp.add_child(b)
	return b


## Linhas de efeito do combate no cabeçalho (left 470, right 400, centradas na vertical, gap 6).
func _paint_insp_lines(b: PcBlock, lines: Array) -> void:
	var af := PcDraw.arial()
	var w := b.size.x - 470.0 - 400.0
	var fs := 17
	var segs_list: Array = []
	for l in lines:
		segs_list.append(MoveInspectInfo.highlight(str(l)))
	var total := 0.0
	while true:
		total = 0.0
		for sg in segs_list:
			total += PcDraw.wrapped_height(af, sg, w - 28.0, fs, fs + 4.0) + 11.0
		total += 6.0 * maxf(0.0, segs_list.size() - 1)
		if total <= b.size.y - 42.0 or fs <= 10:
			break
		fs -= 1
	var y := 24.0 + ((b.size.y - 42.0) - total) * 0.5
	for sg in segs_list:
		var h := PcDraw.wrapped_height(af, sg, w - 28.0, fs, fs + 4.0) + 11.0
		PcDraw.fill_para(b, Rect2(470, y, w, h), 8.0, Color(8 / 255.0, 14 / 255.0, 24 / 255.0, 0.82))
		PcDraw.draw_wrapped(b, af, sg, 484, y + 5.0, w - 28.0, fs, fs + 4.0, Color("f1f5f9"))
		y += h + 6.0


func _side_label(b: PcBlock, txt: String, bg: Color) -> void:
	var f := PcDraw.impact(1)
	var w := PcDraw.width(f, txt, 20) + 28.0
	var h := 20.0 * 1.15 + 6.0
	PcDraw.fill_para(b, Rect2(40, -16, w, h), 7.0, bg)
	PcDraw.line(b, f, txt, 54, -16, 20, PcDraw.INK, w - 20, 0, h)


## Bloco MECHANICS (lima): grade de valores, EFFECT, COMBAT RULES, WITH <nome>. Só dados do código.
func _paint_mech(b: PcBlock, sk: Skill, c: Combatant) -> void:
	_side_label(b, "MECHANICS", PcDraw.LIME)
	var sections: Array = []
	var eff: Array = []
	for it in MoveInspectInfo.mech_effect(sk):
		eff.append({"text": str(it["text"]), "plan": bool(it.get("planned", false))})
	if eff.size() > 0:
		sections.append({"title": "EFFECT", "li": eff})
	var rules: Array = []
	for r in MoveInspectInfo.combat_rules(sk):
		rules.append({"text": str(r), "plan": false})
	sections.append({"title": "COMBAT RULES", "li": rules})
	sections.append({"title": "WITH " + c.name.to_upper(), "p": MoveInspectInfo.forecast(sk, c)})
	var vals := MoveInspectInfo.vals(sk)
	_layout_sections(b, sections, 544.0, vals, PcDraw.AQUA)


func _paint_visual(b: PcBlock, sk: Skill) -> void:
	_side_label(b, "VISUALS", Color("f472b6"))
	var sections: Array = []
	for s in MoveInspectInfo.visual_sections(sk):
		sections.append({"title": str(s["title"]), "p": str(s["text"]), "plain": true})
	_layout_sections(b, sections, b.size.x - 76.0, [], Color("f9a8d4"))


## Encolhe p/li juntos (17/23 e 15/20; depois 15..11 com linha fs+5) até caber; sem rolagem.
func _layout_sections(b: PcBlock, sections: Array, w: float, vals: Array, h4c: Color) -> void:
	var avail := b.size.y - 26.0 - 20.0
	# openInspect do protótipo: primeiro o CSS (p 17/23, li 15/20); se o bloco transborda, p e li
	# passam a um tamanho único que começa em 16 (linha fs+5) e desce só enquanto não cabe.
	var sizes: Array = [[17, 23.0, 15, 20.0]]
	for fs in range(16, 10, -1):
		sizes.append([fs, fs + 5.0, fs, fs + 5.0])
	var pick: Array = sizes[sizes.size() - 1]
	for sz in sizes:
		if _sections_h(sections, w, vals, sz) <= avail:
			pick = sz
			break
	_sections_draw(b, sections, w, vals, pick, h4c)


func _vals_h(vals: Array) -> float:
	if vals.is_empty():
		return 0.0
	var cols := 0
	var rows := 1
	for v in vals:
		var span := 2 if v.get("wide", false) else 1
		if cols + span > 4:
			rows += 1
			cols = 0
		cols += span
	return rows * 38.0 + (rows - 1) * 6.0 + 14.0


func _sections_h(sections: Array, w: float, vals: Array, sz: Array) -> float:
	var af := PcDraw.arial700()
	var h := _vals_h(vals)
	for s in sections:
		h += PcDraw.impact(1).get_height(20) + 5.0
		if s.has("p"):
			var segs: Array = [{"text": s["p"], "color": null}] if s.get("plain", false) else MoveInspectInfo.highlight(str(s["p"]))
			h += PcDraw.wrapped_height(af, segs, w, sz[0], sz[1])
		else:
			for li in s["li"]:
				h += PcDraw.wrapped_height(af, MoveInspectInfo.highlight(str(li["text"])), w - 16.0, sz[2], sz[3]) + 3.0
			h += 4.0
		h += 14.0
	return h  # o margin-bottom da última seção conta no scrollHeight do protótipo


func _sections_draw(b: PcBlock, sections: Array, w: float, vals: Array, sz: Array, h4c: Color) -> void:
	var af := PcDraw.arial700()
	var tf := PcDraw.impact(1)
	var x := 40.0
	var y := 26.0
	if not vals.is_empty():
		var cw := (w - 3.0 * 8.0) / 4.0
		var col := 0
		var row_y := y
		for v in vals:
			var span := 2 if v.get("wide", false) else 1
			if col + span > 4:
				col = 0
				row_y += 38.0 + 6.0
			var cx := x + col * (cw + 8.0)
			var vw := cw * span + 8.0 * (span - 1)
			PcDraw.fill_para(b, Rect2(cx, row_y, vw, 38), 6.0, Color("132d44"))
			PcDraw.line(b, PcDraw.arial(1), str(v["label"]), cx + 10, row_y + 4, 10, Color("7f93a8"), vw - 20)
			PcDraw.line(b, PcDraw.arial(), str(v["value"]), cx + 10, row_y + 4 + 11.5, 15, v["color"], vw - 20)
			col += span
		y = row_y + 38.0 + 14.0
	var n := _typed(b, 0.004)
	for s in sections:
		var tw := PcDraw.line(b, tf, str(s["title"]), x, y, 20, h4c, w - 20)
		PcDraw.line(b, tf, "/", x + tw + 6, y, 20, PcDraw.CORAL, 20)
		y += tf.get_height(20) + 5.0
		if s.has("p"):
			var segs: Array = [{"text": s["p"], "color": null}] if s.get("plain", false) else MoveInspectInfo.highlight(str(s["p"]))
			y += PcDraw.draw_wrapped(b, af, segs, x, y, w, sz[0], sz[1], Color("d5e0ea"), n)
		else:
			for li in s["li"]:
				var plan: bool = li["plan"]
				var bc := Color("94a3b8") if plan else PcDraw.LIME
				PcDraw.fill_para(b, Rect2(x, y + 7.0 * sz[3] / 20.0, 8, 8), 3.0, bc)
				var segs: Array = [{"text": li["text"], "color": Color("94a3b8")}] if plan else MoveInspectInfo.highlight(str(li["text"]))
				var f := _italic() if plan else af
				y += PcDraw.draw_wrapped(b, f, segs, x + 16.0, y, w - 16.0, sz[2], sz[3], Color("d5e0ea")) + 3.0
			y += 4.0
		y += 14.0


static var _ital: Font = null


func _italic() -> Font:
	if _ital == null:
		var fv := FontVariation.new()
		fv.base_font = PcDraw.arial700()
		fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
		_ital = fv
	return _ital


func _close_inspect() -> void:
	if _insp != null and is_instance_valid(_insp):
		_insp.queue_free()
	_insp = null


# --- Confirmação "Não aprender" -----------------------------------------------------------

func _open_confirm() -> void:
	_confirm = Control.new()
	_confirm.size = size
	_confirm.z_index = 10
	_confirm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.color = Color(2 / 255.0, 4 / 255.0, 8 / 255.0, 0.72)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm.add_child(dim)
	var mvn := Skill.from_id(_ui["mv"]).display_name
	var box := PcBlock.new().setup(Rect2(330, 250, 620, 200), -2.0, 26.0, PcDraw.PAPER, Vector2(7, 7))
	box.painter = func(b: PcBlock) -> void:
		var af := PcDraw.arial()
		var segs := PcDraw.markup("Não aprender <b>%s</b>? Ele não será aprendido agora." % mvn, Color("c23b2a"))
		var l1 := PcDraw.markup("Não aprender <b>%s</b>?" % mvn, Color("c23b2a"))
		var l2 := [{"text": "Ele não será aprendido agora.", "color": null}]
		var fs := 22
		while fs > 12 and (PcDraw.wrapped_height(af, l1, 520, fs, 30) > 30 or PcDraw.wrapped_height(af, l2, 520, fs, 30) > 30):
			fs -= 1
		segs = segs
		PcDraw.draw_wrapped(b, af, l1, 50, 34, 520, fs, 30, PcDraw.TEXT_DARK, -1, true)
		PcDraw.draw_wrapped(b, af, l2, 50, 64, 520, fs, 30, PcDraw.TEXT_DARK, -1, true)
		var items := [["Z", "Sim"], ["X", "Voltar"]]
		var ws: Array = []
		var total := 0.0
		for it in items:
			var w := 28.0 + 8.0 + PcDraw.width(af, it[1], 17)
			ws.append(w)
			total += w
		total += 40.0
		var x := (b.size.x - total) * 0.5
		var y := b.size.y - 28.0 - 28.0
		for i in items.size():
			b.draw_rect(Rect2(x, y, 28, 28), PcDraw.INK)
			PcDraw.line(b, af, items[i][0], x + 14, y, 16, Color.WHITE, 28, 1, 28)
			PcDraw.line(b, af, items[i][1], x + 36, y, 17, PcDraw.TEXT_DARK, 120, 0, 28)
			x += float(ws[i]) + 40.0
	_confirm.add_child(box)
	_stage.add_child(_confirm)


func _close_confirm() -> void:
	if _confirm != null and is_instance_valid(_confirm):
		_confirm.queue_free()
	_confirm = null


# --- Pop-up do ícone (some em 5 s ou no X) ---------------------------------------------------

func _show_tip(h: Dictionary) -> void:
	_close_tip()
	var t: Array = MoveInspectInfo.tip(str(h["tip"]))
	var title := str(t[0])
	var body: Array = MoveInspectInfo.highlight(str(t[1]))
	var af := PcDraw.arial()
	var bh := PcDraw.wrapped_height(af, body, 244, 14, 19.0) if str(t[1]) != "" else 0.0
	var hh := 14.0 + 23.0 + 3.0 + bh + 14.0
	# canto do ícone em coordenadas do palco
	var b: PcBlock = h["b"]
	var r: Rect2 = h["r"]
	var xf := b.get_global_transform()
	var pts := [xf * r.position, xf * Vector2(r.end.x, r.position.y), xf * r.end, xf * Vector2(r.position.x, r.end.y)]
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for p in pts:
		mn = mn.min(p)
		mx = mx.max(p)
	var x := mn.x - 20.0
	var y := mx.y + 12.0
	if x + 300.0 > 1260.0:
		x = 1260.0 - 300.0
	if y + hh > 700.0:
		y = mn.y - hh - 12.0
	_tip = PcBlock.new().setup(Rect2(x, y, 300, hh), -1.5, 10.0, PcDraw.PAPER, Vector2(5, 5))
	_tip.z_index = 40
	_tip.live = true
	_tip_t = PcBlock.now()
	var t0 := _tip_t
	_tip.painter = func(bb: PcBlock) -> void:
		PcDraw.line(bb, PcDraw.impact(1), title, 18, 14, 20, PcDraw.INK, 244)
		if not body.is_empty():
			PcDraw.draw_wrapped(bb, af, body, 18, 14 + 23 + 3, 244, 14, 19.0, PcDraw.TEXT_DARK)
		bb.draw_rect(Rect2(300 - 14 - 22, 10, 22, 22), PcDraw.INK)
		PcDraw.line(bb, af, "✕", 300 - 14 - 11, 10, 13, Color.WHITE, 22, 1, 22)
		var left := clampf(1.0 - (PcBlock.now() - t0) / 5.0, 0.0, 1.0)
		bb.draw_rect(Rect2(12, bb.size.y - 8, 276 * left, 3), PcDraw.CORAL)
	_tip.anim_scale = 0.6
	_tip.modulate.a = 0.0
	_tip.apply()
	var tip := _tip
	var tw := _tip.create_tween()
	tw.tween_method(func(q: float) -> void:
		var e := PcDraw.bezier(0.2, 1.6, 0.4, 1.0, q)
		tip.anim_scale = lerpf(0.6, 1.0, e)
		tip.modulate.a = clampf(e, 0.0, 1.0)
		tip.apply(), 0.0, 1.0, 0.22)
	_overlay.add_child(_tip)


func _close_tip() -> void:
	if _tip != null and is_instance_valid(_tip):
		_tip.queue_free()
	_tip = null


# --- Laço e entrada ------------------------------------------------------------------------

func _process(_d: float) -> void:
	_xp_tick()
	if _fx != null and is_instance_valid(_fx):
		_fx.queue_redraw()
	if _tip != null and PcBlock.now() - _tip_t >= 5.0:
		_close_tip()
	if _ui.has("cbtn"):
		var cb: PcBlock = _ui["cbtn"]
		if int(_ui["left"]) == 0:
			var ph := fmod(PcBlock.now(), 1.1) / 1.1
			var e := PcDraw.bezier(0.42, 0.0, 0.58, 1.0, ph * 2.0 if ph < 0.5 else (1.0 - ph) * 2.0)
			cb.pulse_scale = 1.0 + 0.03 * e
		else:
			cb.pulse_scale = 1.0
		cb.apply()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _steps.is_empty():
		return
	if event is InputEventKey and event.pressed:
		var k := _key_name(event as InputEventKey)
		if k == "":
			return
		get_viewport().set_input_as_handled()
		_on_key(k)
	elif event is InputEventMouseMotion:
		_on_hover((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_on_click((event as InputEventMouseButton).position)


func _key_name(e: InputEventKey) -> String:
	match e.keycode:
		KEY_Z, KEY_ENTER, KEY_KP_ENTER:
			return "z" if not e.echo else ""
		KEY_X, KEY_ESCAPE:
			return "x" if not e.echo else ""
		KEY_C:
			return "c" if not e.echo else ""
		KEY_UP:
			return "up"
		KEY_DOWN:
			return "down"
		KEY_LEFT:
			return "left"
		KEY_RIGHT:
			return "right"
	return ""


func _on_key(k: String) -> void:
	var kind := str(_steps[_si]["kind"])
	if kind == "xp":
		if k == "z" and _ui.get("xp_done", false):
			_next()
		return
	if kind == "lv":
		_lv_key(k)
		return
	# move
	if _insp != null:
		var fi := int(_ui.get("insp_forget", -1))
		if k == "z" and fi >= 0:
			_close_inspect()
			_forget_slot(fi)
		elif k in ["z", "x", "c"]:
			_close_inspect()
		return
	if _confirm != null:
		if k == "z":
			_close_confirm()
			_skip_learning()
		elif k == "x":
			_close_confirm()
		return
	match k:
		"up":
			_move_focus(Vector2.UP)
		"down":
			_move_focus(Vector2.DOWN)
		"left":
			_move_focus(Vector2.LEFT)
		"right":
			_move_focus(Vector2.RIGHT)
		"z", "c":
			_activate(_focus)
	_mv_paint()


func _local(b: Control, p: Vector2) -> Vector2:
	return b.get_global_transform().affine_inverse() * p


func _hit(b: PcBlock, p: Vector2) -> bool:
	return is_instance_valid(b) and b.is_visible_in_tree() and Geometry2D.is_point_in_polygon(_local(b, p), PcDraw.para(Rect2(Vector2.ZERO, b.size), b.k))


func _on_hover(p: Vector2) -> void:
	if _insp != null or _confirm != null or _si >= _steps.size() or str(_steps[_si]["kind"]) != "move":
		return
	for key in _focusables:
		if _hit(_focusables[key], p) and key != _focus:
			_set_focus(key)
			_mv_paint()
			return


func _on_click(p: Vector2) -> void:
	# X do pop-up
	if _tip != null and Rect2(300 - 14 - 22, 10, 22, 22).has_point(_local(_tip, p)):
		_close_tip()
		return
	# ícones: pop-up (não abre a inspeção)
	var hot := _hot.duplicate()
	hot.reverse()
	for h in hot:
		var b: PcBlock = h["b"]
		if not is_instance_valid(b) or not b.is_visible_in_tree():
			continue
		if _insp != null and not _insp.is_ancestor_of(b):
			continue
		if (h["r"] as Rect2).has_point(_local(b, p)):
			_show_tip(h)
			return
	if _si >= _steps.size() or str(_steps[_si]["kind"]) != "move":
		return
	if _insp != null:
		for ch in _insp.get_children():
			if ch is PcBlock and ch.has_meta("act") and _hit(ch, p):
				var fi := int(_ui.get("insp_forget", -1))
				_close_inspect()
				if str(ch.get_meta("act")) == "forget" and fi >= 0:
					_forget_slot(fi)
				return
		return
	if _confirm != null:
		return
	for key in _focusables:
		if _hit(_focusables[key], p):
			_set_focus(key)
			_activate(key)
			return
