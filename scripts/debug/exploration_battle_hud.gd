extends Node
## D-1072: HUD de exploração no estilo dos cartões de batalha (UnitCard).
##
## Nó aditivo: esconde os badges antigos, achata as bolinhas do mini-mapa e
## desenha três cards 330x104 com retrato, nome, HP e MP iguais aos do battle.
## ATB, Burst, status, burn/armor e o tanque de água do MP ficam de fora porque
## são sistemas de combate; a exploração usa só a casca + HP/MP.

const CARD_SIZE := Vector2(330, 104)
const CARD_DATA := [
	{"name": "ABRA", "hp": 86, "max_hp": 100, "mp": 14, "max_mp": 20,
		"hero": true, "portrait": "abra", "elements": [Element.Type.PSIQUICO],
		"pos": Vector2(14, 76), "scale": 1.0},
	{"name": "PANCHAM", "hp": 100, "max_hp": 100, "mp": 10, "max_mp": 20,
		"hero": false, "portrait": "pancham",
		"elements": [Element.Type.FISICO, Element.Type.TREVAS],
		"pos": Vector2(14, 190), "scale": 0.85},
	{"name": "ORC", "hp": 46, "max_hp": 100, "mp": 8, "max_mp": 20,
		"hero": false, "portrait": "orc", "elements": [Element.Type.FISICO],
		"pos": Vector2(14, 292), "scale": 0.85},
	{"name": "GIBLE", "hp": 100, "max_hp": 100, "mp": 10, "max_mp": 20,
		"hero": false, "portrait": "gible", "elements": [Element.Type.TERRA],
		"pos": Vector2(14, 394), "scale": 0.85},
]

## D-1074: close no rosto dentro da arte Sugimori (UV normalizado).
## Abra = opção 3; Pancham = opção 2; Gible = opção 2; Orc usa o retrato inteiro.
var FACE_REGIONS := {
	"abra": Rect2(300.0 / 851.0, 120.0 / 851.0, 320.0 / 851.0, 360.0 / 851.0),
	"pancham": Rect2(300.0 / 1261.0, 40.0 / 1261.0, 680.0 / 1261.0, 760.0 / 1261.0),
	"gible": Rect2(30.0 / 762.0, 100.0 / 762.0, 490.0 / 762.0, 560.0 / 762.0),
}

## D-1074: mesmo mapa de elementos do BattleHud (FISICO usa "neutral").
const ELEMENT_ICON_KEYS := {
	Element.Type.FISICO: "neutral",
	Element.Type.FOGO: "fire",
	Element.Type.AGUA_GELO: "water_ice",
	Element.Type.RAIO: "electric",
	Element.Type.PSIQUICO: "psychic",
	Element.Type.VENENO: "nature",
	Element.Type.SOM: "sound",
	Element.Type.TERRA: "earth",
	Element.Type.VENTO: "wind",
	Element.Type.LUZ: "light",
	Element.Type.TREVAS: "dark",
	Element.Type.MYSTIC: "mystic",
}
const ELEMENT_HERO_COLORS := {
	Element.Type.FISICO: Color("334155"), Element.Type.FOGO: Color("c2410c"),
	Element.Type.AGUA_GELO: Color("0369a1"), Element.Type.RAIO: Color("a16207"),
	Element.Type.PSIQUICO: Color("c026d3"), Element.Type.VENENO: Color("15803d"),
	Element.Type.SOM: Color("0f766e"), Element.Type.TERRA: Color("78350f"),
	Element.Type.VENTO: Color("047857"), Element.Type.LUZ: Color("a16207"),
	Element.Type.TREVAS: Color("1e1b4b"), Element.Type.MYSTIC: Color("0f766e"),
}
const ELEMENT_ALLY_COLORS := {
	Element.Type.FISICO: Color("e2e8f0"), Element.Type.FOGO: Color("fdba74"),
	Element.Type.AGUA_GELO: Color("7dd3fc"), Element.Type.RAIO: Color("fde047"),
	Element.Type.PSIQUICO: Color("f9a8d4"), Element.Type.VENENO: Color("86efac"),
	Element.Type.SOM: Color("5eead4"), Element.Type.TERRA: Color("d6b48c"),
	Element.Type.VENTO: Color("a7f3d0"), Element.Type.LUZ: Color("fef08a"),
	Element.Type.TREVAS: Color("c4b5fd"), Element.Type.MYSTIC: Color("99f6e4"),
}

static var _element_icon_cache: Dictionary = {}

var _lab: Node3D
var _layer: CanvasLayer
var _cards: Array[Dictionary] = []
var _font: Font


func _ready() -> void:
	await get_tree().physics_frame
	_lab = get_parent() as Node3D
	if _lab == null:
		return
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Arial", "Segoe UI"])
	_font.font_weight = 800
	_flatten_dots()
	_hide_old_badges()
	_build_cards()


func _process(_delta: float) -> void:
	if _lab == null:
		return
	var party_visible := bool(_lab.get("_party_visible"))
	for entry in _cards:
		if bool(entry["ally"]):
			(entry["control"] as Control).visible = party_visible
	# D-1072/D-1063: o ciclo de NPCs cria marcadores novos depois do _ready;
	# achatar de novo garante que a bolinha branca também fique sem contorno.
	_flatten_dots()


func _flatten_dots() -> void:
	var markers = _lab.get("_minimap_markers")
	if markers == null:
		return
	for m in markers:
		var dot := m["rect"] as Panel
		if dot == null:
			continue
		var style := dot.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			continue
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		dot.queue_redraw()


func _hide_old_badges() -> void:
	var badges = _lab.get("_hud_badges")
	if badges == null or badges.is_empty():
		return
	var first := badges[0]["panel"] as Control
	if first == null:
		return
	var parent := first.get_parent()
	if parent is Control:
		(parent as Control).visible = false


func _build_cards() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 19
	add_child(_layer)
	for data in CARD_DATA:
		var card := ExplorationCard.new()
		card.character_name = str(data["name"])
		card.hp = int(data["hp"])
		card.max_hp = int(data["max_hp"])
		card.mp = int(data["mp"])
		card.max_mp = int(data["max_mp"])
		card.hero = bool(data["hero"])
		card.font = _font
		card.portrait = _load_portrait(str(data["portrait"]))
		card.portrait_region = FACE_REGIONS.get(str(data["portrait"]), Rect2(0.0, 0.0, 1.0, 1.0))
		var elements: Array = data.get("elements", [])
		card.element_icons = _load_element_icons(elements)
		card.element_colors = _element_colors(elements, card.hero)
		card.position = data["pos"]
		card.scale = Vector2.ONE * float(data["scale"])
		card.size = CARD_SIZE
		card.custom_minimum_size = CARD_SIZE
		_layer.add_child(card)
		_cards.append({"control": card, "ally": not bool(data["hero"])})


func _load_portrait(character_name: String) -> Texture2D:
	# D-1074: Pokémon usam a arte Sugimori local; DQT (Orc) cai no retrato atual.
	var sugimori := "res://sugimori/por_nome/%s.png" % character_name
	if ResourceLoader.exists(sugimori):
		return load(sugimori) as Texture2D
	var path := "res://personagens/portraits/%s.png" % character_name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _load_element_icons(elements: Array) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for e in elements:
		out.append(_load_element_icon(e))
	return out


func _load_element_icon(e: Element.Type) -> Texture2D:
	var key := str(ELEMENT_ICON_KEYS.get(e, "neutral"))
	if _element_icon_cache.has(key):
		return _element_icon_cache[key] as Texture2D
	var path := "res://assets/ui/icons/elements/%s.svg" % key
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_element_icon_cache[key] = tex
	return tex


func _element_colors(elements: Array, hero: bool) -> Array[Color]:
	var out: Array[Color] = []
	var table := ELEMENT_HERO_COLORS if hero else ELEMENT_ALLY_COLORS
	for e in elements:
		out.append(table.get(e, Color("111b29") if hero else Color("eceada")))
	return out


class ExplorationCard extends Control:
	const CARD_SIZE := Vector2(330, 104)
	const HERO_BG := Color("eae9d9")
	const ALLY_BG := Color("17283b")
	const FG_HERO := Color("111b29")
	const FG_ALLY := Color("eceada")
	const TRACK_HERO := Color("7b8c90")
	const TRACK_ALLY := Color("526176")
	const HP_HERO := Color("e96159")
	const HP_ALLY := Color("b5a5fe")
	const MP_BLUE := Color("38bdf8")
	const PORTRAIT_HERO := Color("263d57")
	const PORTRAIT_ALLY := Color("54456c")
	const AQUA := Color("62d8e7")

	var character_name := ""
	var hp := 0
	var max_hp := 1
	var mp := 0
	var max_mp := 1
	var hero := true
	var font: Font
	var portrait: Texture2D
	var portrait_region := Rect2(0.0, 0.0, 1.0, 1.0)
	var element_icons: Array[Texture2D] = []
	var element_colors: Array[Color] = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = CARD_SIZE
		custom_minimum_size = CARD_SIZE

	func _draw() -> void:
		var bg := HERO_BG if hero else ALLY_BG
		var fg := FG_HERO if hero else FG_ALLY
		var track := TRACK_HERO if hero else TRACK_ALLY
		var hp_col := HP_HERO if hero else HP_ALLY
		var body := Rect2(0, 18, size.x, 82)
		_slant(Rect2(body.position + Vector2(6, 6), body.size), 8.0, Color(0, 0, 0, 0.5))
		_slant(body, 8.0, bg)
		var pr := Rect2(16, 26, 56, 62)
		_slant(pr, 6.0, PORTRAIT_HERO if hero else PORTRAIT_ALLY)
		if portrait != null:
			if portrait.get_width() > 64:
				_slant_texture(pr.grow(-2.0), 5.0, portrait, portrait_region)
			else:
				draw_texture_rect(portrait, Rect2(24, 32, 44, 44), false)
		var bar_x := 84.0
		var bar_w := 162.0
		draw_rect(Rect2(bar_x, 55, bar_w, 12), track)
		var hp_ratio := clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
		draw_rect(Rect2(bar_x, 55, bar_w * hp_ratio, 12), hp_col)
		draw_rect(Rect2(bar_x, 74, bar_w, 10), track)
		var mp_ratio := clampf(float(mp) / float(maxi(max_mp, 1)), 0.0, 1.0)
		draw_rect(Rect2(bar_x, 74, bar_w * mp_ratio, 10), MP_BLUE)

		# D-1074: o texto acompanha o mesmo ângulo do corpo (8 px em 82 px).
		draw_set_transform_matrix(_body_shear())
		var name_text := character_name.to_upper()
		draw_string(font, Vector2(84, 45), name_text,
			HORIZONTAL_ALIGNMENT_LEFT, 150, 20, fg)
		# D-1074: ícones de elemento logo depois do nome (até dois).
		var name_w := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var icon_x := 84.0 + minf(name_w, 150.0) + 8.0
		for i in element_icons.size():
			var tex: Texture2D = element_icons[i]
			if tex == null:
				continue
			var col: Color = element_colors[i] if i < element_colors.size() else fg
			draw_texture_rect(tex, Rect2(icon_x, 27, 18, 18), false, col)
			icon_x += 20.0
		if not hero:
			_text_right(font, size.x - 14, 41, "ALLY | AI", 8, Color(fg, 0.6))
		draw_string(font, Vector2(bar_x + bar_w + 10, 65), "HP %d/%d" % [hp, max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, fg)
		draw_string(font, Vector2(bar_x + bar_w + 10, 84), "MP %d/%d" % [mp, max_mp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, fg)
		draw_set_transform_matrix(Transform2D.IDENTITY)

	func _body_shear() -> Transform2D:
		var k := 8.0 / 82.0
		return Transform2D(Vector2(1.0, 0.0), Vector2(-k, 1.0), Vector2(k * 18.0, 0.0))

	func _text_right(f: Font, right_x: float, y: float, text: String, size_px: int, color: Color) -> void:
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		draw_string(f, Vector2(right_x - w, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

	func _pts(r: Rect2, skew: float) -> PackedVector2Array:
		return PackedVector2Array([
			Vector2(r.position.x + skew, r.position.y),
			Vector2(r.end.x, r.position.y),
			Vector2(r.end.x - skew, r.end.y),
			Vector2(r.position.x, r.end.y),
		])

	func _slant(r: Rect2, skew: float, color: Color) -> void:
		draw_colored_polygon(_pts(r, skew), color)

	func _slant_texture(r: Rect2, skew: float, tex: Texture2D, src: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)) -> void:
		var pts := _pts(r, skew)
		var tex_aspect := (src.size.x * tex.get_width()) / (src.size.y * tex.get_height())
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
			uvs.append(Vector2(
				src.position.x + src.size.x * (0.5 + (k.x - 0.5) * u_span),
				src.position.y + src.size.y * (0.5 + (k.y - 0.5) * v_span)))
		draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, tex)
