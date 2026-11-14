class_name PcDraw
extends RefCounted
## D-1192: desenho do pós-combate do protótipo D-1185 (`prototypes/level_up_overhaul.html`).
## Regra D-433 §5: paralelogramo só como FUNDO (polígono); texto sempre reto e medido
## (encolhe para caber). Medidas em px do palco 1280×720, tiradas do CSS do protótipo.

const INK := Color("080e18")
const INK2 := Color("10263a")
const NAVY := Color("0a1a27")
const NAVY2 := Color("0e2435")
const PAPER := Color("f4eee1")
const TEXT_DARK := Color("111b29")
const AQUA := Color("63d9ec")
const LIME := Color("d6fa66")
const GOLD := Color("f0c57e")
const CORAL := Color("ff746c")
const SHADOW := Color(0, 0, 0, 0.55)

## Rodada 4 da D-1185: uma cor por stat; HP/MP nas cores das barras do HUD.
const STAT_C := {
	"STR": Color("ff746c"), "MAG": Color("b5a5fe"), "VIT": Color("7ee081"),
	"WIS": Color("63d9ec"), "AGI": Color("f0c57e"), "LUK": Color("d6fa66"),
	"HP": Color("e96159"), "MP": Color("38bdf8"),
}

## Cores de ELEMENT_COLORS (status_screen.gd) e se o glifo/texto é escuro (protótipo `EL`).
const EL_COLOR := {
	Element.Type.FISICO: Color("cbd5e1"), Element.Type.FOGO: Color("f97316"),
	Element.Type.AGUA_GELO: Color("0284c7"), Element.Type.RAIO: Color("fde047"),
	Element.Type.VENTO: Color("4ff7ba"), Element.Type.PSIQUICO: Color("ec4899"),
	Element.Type.LUZ: Color("fef08a"), Element.Type.TREVAS: Color("6b21a8"),
	Element.Type.VENENO: Color("84cc16"), Element.Type.SOM: Color("06b6d4"),
	Element.Type.TERRA: Color("b45309"), Element.Type.MYSTIC: Color("65b5b3"),
}
const EL_DARK := [Element.Type.RAIO, Element.Type.LUZ, Element.Type.MYSTIC, Element.Type.FISICO,
	Element.Type.VENENO, Element.Type.SOM, Element.Type.VENTO]
const EL_ICON := {
	Element.Type.FISICO: "neutral", Element.Type.FOGO: "fire", Element.Type.AGUA_GELO: "water",
	Element.Type.RAIO: "electric", Element.Type.PSIQUICO: "psychic", Element.Type.VENENO: "nature",
	Element.Type.SOM: "sound", Element.Type.TERRA: "earth", Element.Type.VENTO: "wind",
	Element.Type.LUZ: "light", Element.Type.TREVAS: "dark", Element.Type.MYSTIC: "mystic",
}
## Badges de tipo (protótipo `TYPE` + D-1190: Status laranja PROVISÓRIO, glifo escuro).
const TYPE_C := {"MAG": Color("0ea5e9"), "PHY": Color("ef4444"), "FIELD": Color("22c55e"), "STATUS": Color("ffffff")}
const TYPE_ICON := {"MAG": "move_types/magical", "PHY": "move_types/physical", "FIELD": "move_types/field", "STATUS": "move_types/status"}
const ICON_DIR := "res://assets/ui/icons/"

static var _fonts := {}
static var _icons := {}


static func el_color(e: int) -> Color:
	return EL_COLOR.get(e, Color("cbd5e1"))


static func el_dark(e: int) -> bool:
	return EL_DARK.has(e)


static func el_icon(e: int) -> String:
	return "elements/" + str(EL_ICON.get(e, "neutral"))


# --- Fontes -------------------------------------------------------------------

## Impact (títulos) e Arial 800 (corpo) do jogo; `spacing` = letter-spacing do CSS.
static func impact(spacing := 0) -> Font:
	return _font("i", FanMenu.title_font(), spacing)


static func arial(spacing := 0) -> Font:
	return _font("a", FanMenu.body_font(), spacing)


## Arial peso 700 (parágrafos e listas da inspeção, como no protótipo).
static func arial700() -> Font:
	if not _fonts.has("a700"):
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Arial", "Segoe UI"])
		f.font_weight = 700
		_fonts["a700"] = f
	return _fonts["a700"]


static func _font(key: String, base: Font, spacing: int) -> Font:
	var k := key + str(spacing)
	if not _fonts.has(k):
		if spacing == 0:
			_fonts[k] = base
		else:
			var fv := FontVariation.new()
			fv.base_font = base
			fv.spacing_glyph = spacing
			_fonts[k] = fv
	return _fonts[k]


## Linha de base para um texto cujo topo de caixa CSS é `top` com altura de linha `lh`
## (lh <= 0 = line-height normal).
static func baseline(font: Font, size: int, top: float, lh := -1.0) -> float:
	var a := font.get_ascent(size)
	var d := font.get_descent(size)
	if lh <= 0.0:
		return top + a
	return top + (lh - (a + d)) * 0.5 + a


static func width(font: Font, text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Maior tamanho <= size em que o texto cabe em max_w.
static func fit(font: Font, text: String, size: int, max_w: float, min_size := 8) -> int:
	var s := size
	if max_w <= 0.0:
		return s
	while s > min_size and width(font, text, s) > max_w:
		s -= 1
	return s


# --- Formas -------------------------------------------------------------------

static func para(r: Rect2, k: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(r.position.x + k, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - k, r.end.y), Vector2(r.position.x, r.end.y)])


static func fill_para(ci: CanvasItem, r: Rect2, k: float, col: Color) -> void:
	if col.a <= 0.0 or r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	ci.draw_colored_polygon(para(r, minf(k, r.size.x * 0.5)), col)


## Paralelogramo cortado por um retângulo (barra de XP com overflow:hidden).
static func fill_para_clipped(ci: CanvasItem, r: Rect2, k: float, clip: Rect2, col: Color) -> void:
	if clip.size.x <= 0.5:
		return
	var rect := PackedVector2Array([clip.position, Vector2(clip.end.x, clip.position.y), clip.end, Vector2(clip.position.x, clip.end.y)])
	for poly in Geometry2D.intersect_polygons(para(r, k), rect):
		if poly.size() >= 3:
			ci.draw_colored_polygon(poly, col)


# --- Ícones (SVG brancos, tingidos) ----------------------------------------------

static func icon(name: String, px: int) -> Texture2D:
	var size := maxi(16, int(ceil(px / 16.0)) * 16)
	var key := name + "@" + str(size)
	if _icons.has(key):
		return _icons[key]
	var path := ICON_DIR + name + ".svg"
	var tex: Texture2D = null
	var svg := FileAccess.get_file_as_string(path)
	if svg != "":
		var img := Image.new()
		if img.load_svg_from_string(svg, size / 24.0) == OK:
			tex = ImageTexture.create_from_image(img)
	if tex == null and ResourceLoader.exists(path):
		tex = load(path)
	_icons[key] = tex
	return tex


static func draw_icon(ci: CanvasItem, name: String, r: Rect2, col: Color) -> void:
	var tex := icon(name, int(maxf(r.size.x, r.size.y)))
	if tex != null:
		ci.draw_texture_rect(tex, r, false, col)


# --- Texto --------------------------------------------------------------------

## Uma linha; encolhe para caber em max_w. align: 0 esquerda, 1 centro, 2 direita (x = âncora).
static func line(ci: CanvasItem, font: Font, text: String, x: float, top: float, size: int, col: Color,
		max_w := -1.0, align := 0, lh := -1.0) -> float:
	var s := fit(font, text, size, max_w)
	var w := width(font, text, s)
	var dx := x - (w * 0.5 if align == 1 else (w if align == 2 else 0.0))
	ci.draw_string(font, Vector2(dx, baseline(font, s, top, lh)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, col)
	return w


## Várias cores numa linha: parts = [[texto, Color], ...]. Encolhe o conjunto para caber.
static func parts_width(font: Font, parts: Array, size: int) -> float:
	var w := 0.0
	for p in parts:
		w += width(font, str(p[0]), size)
	return w


static func parts_fit(font: Font, parts: Array, size: int, max_w: float) -> int:
	var s := size
	while max_w > 0.0 and s > 8 and parts_width(font, parts, s) > max_w:
		s -= 1
	return s


## Letra a letra (rodada 5): cada letra cai de -0,5em com escala 1,7 e assenta;
## 28 ms entre letras, 0,34 s cada, curva cubic-bezier(.2,1.4,.4,1). `t` = segundos desde o início
## (negativo = ainda não começou). Também serve estático (t grande).
static func letters(ci: CanvasItem, font: Font, parts: Array, x: float, top: float, size: int, max_w: float,
		t: float, lh := -1.0, align := 0) -> float:
	var s := parts_fit(font, parts, size, max_w)
	var total := parts_width(font, parts, s)
	var cx := x - (total * 0.5 if align == 1 else (total if align == 2 else 0.0))
	var base := baseline(font, s, top, lh)
	var mid_y := base - font.get_ascent(s) * 0.5
	var i := 0
	for p in parts:
		var txt := str(p[0])
		var col: Color = p[1]
		for ch in txt:
			var adv := font.get_char_size(ch.unicode_at(0), s).x
			if ch.strip_edges() == "":
				cx += adv
				continue
			var lt := t - i * 0.028
			i += 1
			var q := 1.0 if t > 50.0 else clampf(lt / 0.34, 0.0, 1.0)
			if q <= 0.0:
				cx += adv
				continue
			var e := bezier(0.2, 1.4, 0.4, 1.0, q)
			var sc := 1.7 + (1.0 - 1.7) * e
			var center := Vector2(cx + adv * 0.5, mid_y - 0.5 * s * (1.0 - e))
			ci.draw_set_transform(center, 0.0, Vector2(sc, sc))
			ci.draw_char(font, Vector2(-adv * 0.5, base - mid_y), ch, s, Color(col, col.a * clampf(e, 0.0, 1.0)))
			cx += adv
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return total


## Quebra segmentos coloridos ({text, color}) em linhas de largura w.
static func wrap_lines(font: Font, segs: Array, w: float, size: int) -> Array:
	var words: Array = []  # [texto, cor, espaço_antes]
	var pending := false
	for sg in segs:
		var txt := str(sg["text"])
		var col: Variant = sg.get("color", null)
		var chunks := txt.split(" ", true)
		for j in chunks.size():
			if j > 0:
				pending = true
			if chunks[j] != "":
				words.append([chunks[j], col, pending])
				pending = false
	var lines: Array = []
	var cur: Array = []
	var cw := 0.0
	var sp := width(font, "a a", size) - width(font, "aa", size)  # largura real do espaço entre palavras
	for wd in words:
		var ww := width(font, wd[0], size)
		var lead: float = sp if (wd[2] and cur.size() > 0) else 0.0
		if cur.size() > 0 and cw + lead + ww > w and wd[2]:
			lines.append(cur)
			cur = []
			cw = 0.0
			lead = 0.0
		cur.append({"text": wd[0], "color": wd[1], "x": cw + lead})
		cw += lead + ww
	if cur.size() > 0:
		lines.append(cur)
	return lines


static func wrapped_height(font: Font, segs: Array, w: float, size: int, lh: float) -> float:
	return wrap_lines(font, segs, w, size).size() * lh


## Desenha texto quebrado; `visible` = quantos caracteres mostrar (máquina de escrever; -1 = todos).
## Retorna a altura usada.
static func draw_wrapped(ci: CanvasItem, font: Font, segs: Array, x: float, top: float, w: float, size: int,
		lh: float, default_col: Color, visible := -1, center := false) -> float:
	var lines := wrap_lines(font, segs, w, size)
	var left := visible
	var y := top
	for ln in lines:
		var lw := 0.0
		if center and ln.size() > 0:
			var last: Dictionary = ln[ln.size() - 1]
			lw = float(last["x"]) + width(font, str(last["text"]), size)
		var ox := x + ((w - lw) * 0.5 if center else 0.0)
		var b := baseline(font, size, y, lh)
		for wd in ln:
			var txt := str(wd["text"])
			if visible >= 0:
				if left <= 0:
					return lines.size() * lh
				if txt.length() > left:
					txt = txt.substr(0, left)
				left -= txt.length() + 1
			var col: Color = default_col
			if wd["color"] is Color and (wd["color"] as Color).a > 0.0:
				col = wd["color"]
			ci.draw_string(font, Vector2(ox + float(wd["x"]), b), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		y += lh
	return lines.size() * lh


## Converte "texto <b>destaque</b> texto" em segmentos; `hi` é a cor do <b>.
static func markup(text: String, hi: Color) -> Array:
	var out: Array = []
	var rest := text
	while true:
		var a := rest.find("<b>")
		if a < 0:
			if rest != "":
				out.append({"text": rest, "color": null})
			break
		if a > 0:
			out.append({"text": rest.substr(0, a), "color": null})
		var b := rest.find("</b>", a)
		if b < 0:
			b = rest.length()
		out.append({"text": rest.substr(a + 3, b - a - 3), "color": hi})
		rest = rest.substr(mini(rest.length(), b + 4))
	return out


static func seg_len(segs: Array) -> int:
	var n := 0
	for sg in segs:
		n += str(sg["text"]).length()
	return n


# --- Curvas -------------------------------------------------------------------

## cubic-bezier(x1,y1,x2,y2) do CSS, avaliada em t (0..1). y pode passar de 1 (mola).
static func bezier(x1: float, y1: float, x2: float, y2: float, t: float) -> float:
	if t <= 0.0:
		return 0.0
	if t >= 1.0:
		return 1.0
	var u := t
	for _i in 8:
		var x := _bz(x1, x2, u) - t
		var dx := _bz_d(x1, x2, u)
		if absf(x) < 0.0005 or absf(dx) < 0.000001:
			break
		u = clampf(u - x / dx, 0.0, 1.0)
	return _bz(y1, y2, u)


static func _bz(p1: float, p2: float, u: float) -> float:
	var v := 1.0 - u
	return 3.0 * v * v * u * p1 + 3.0 * v * u * u * p2 + u * u * u


static func _bz_d(p1: float, p2: float, u: float) -> float:
	var v := 1.0 - u
	return 3.0 * v * v * p1 + 6.0 * v * u * (p2 - p1) + 3.0 * u * u * (1.0 - p2)
