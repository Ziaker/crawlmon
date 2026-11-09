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
		"hero": true, "portrait": "abra", "pos": Vector2(14, 76), "scale": 1.0},
	{"name": "PANCHAM", "hp": 100, "max_hp": 100, "mp": 10, "max_mp": 20,
		"hero": false, "portrait": "pancham", "pos": Vector2(14, 190), "scale": 0.85},
	{"name": "ORC", "hp": 46, "max_hp": 100, "mp": 8, "max_mp": 20,
		"hero": false, "portrait": "orc", "pos": Vector2(14, 292), "scale": 0.85},
]

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
		card.position = data["pos"]
		card.scale = Vector2.ONE * float(data["scale"])
		card.size = CARD_SIZE
		card.custom_minimum_size = CARD_SIZE
		_layer.add_child(card)
		_cards.append({"control": card, "ally": not bool(data["hero"])})


func _load_portrait(character_name: String) -> Texture2D:
	var path := "res://personagens/portraits/%s.png" % character_name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


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
				_slant_texture(pr.grow(-2.0), 5.0, portrait)
			else:
				draw_texture_rect(portrait, Rect2(24, 32, 44, 44), false)
		draw_string(font, Vector2(84, 44), character_name.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, 150, 18, fg)
		if not hero:
			_text_right(font, size.x - 48, 40, "ALLY | AI", 8, Color(fg, 0.6))
		var bar_x := 84.0
		var bar_w := 120.0
		draw_rect(Rect2(bar_x, 52, bar_w, 7), track)
		var hp_ratio := clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
		draw_rect(Rect2(bar_x, 52, bar_w * hp_ratio, 7), hp_col)
		draw_string(font, Vector2(bar_x + bar_w + 8, 59), "HP %d/%d" % [hp, max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)
		draw_rect(Rect2(bar_x, 64, bar_w, 5), track)
		var mp_ratio := clampf(float(mp) / float(maxi(max_mp, 1)), 0.0, 1.0)
		draw_rect(Rect2(bar_x, 64, bar_w * mp_ratio, 5), MP_BLUE)
		draw_string(font, Vector2(bar_x + bar_w + 8, 69), "MP %d/%d" % [mp, max_mp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, fg)

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

	func _slant_texture(r: Rect2, skew: float, tex: Texture2D) -> void:
		var pts := _pts(r, skew)
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
		draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, tex)
