extends Control
## D-1092: faixa lateral de papel com o comentário de um aliado.
## Entra pela esquerda sem substituir o card do NPC.

const CIRCLE_SHADER := preload("res://shaders/dialogue_portrait_circle.gdshader")
const BASE_W := 380.0
const BASE_H := 82.0
## D-1110: 10% menor e 88 px mais alto; o 3º não encosta no painel do NPC.
const SCALE := 0.9

var slot := 0
var _base_y := 200.0
var _font_name: Font
var _font_body: Font
var _panel: Control
var _portrait: TextureRect
var _portrait_fallback: Label
var _name_label: Label
var _body: Label
var _accent: ColorRect
var _text := ""
var _typing := false
var _visible_chars := 0
var _type_accum := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(BASE_W, BASE_H)
	size = Vector2(BASE_W, BASE_H)
	_font_name = _font(["Georgia", "Times New Roman", "Cambria"], 700)
	_font_body = _font(["Georgia", "Times New Roman", "Cambria"], 600)
	_build()
	scale = Vector2(SCALE, SCALE)
	visible = false


func setup(index: int) -> void:
	slot = index
	_base_y = 200.0 + float(index) * 83.0
	position = Vector2(-420.0, _base_y)
	visible = false


func open(ally_name: String, text: String, portrait: Texture2D, tint: Color) -> void:
	_text = text
	_name_label.text = ally_name
	_portrait.texture = portrait
	_portrait_fallback.visible = portrait == null
	if portrait == null:
		_portrait_fallback.text = ally_name.substr(0, 1)
	_accent.color = tint
	_body.text = text
	_body.visible_characters = 0
	_visible_chars = 0
	_type_accum = 0.0
	_typing = true
	visible = true
	modulate.a = 0.0
	position = Vector2(-420.0, _base_y)
	rotation = deg_to_rad(-5.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:x", 24.0, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(self, "rotation", deg_to_rad(-1.5), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not visible:
		return
	_typing = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:x", -420.0, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.set_parallel(false)
	tw.tween_callback(func() -> void: visible = false)


func _process(delta: float) -> void:
	if not _typing:
		return
	_type_accum += delta
	while _type_accum >= 0.012 and _visible_chars < _text.length():
		_visible_chars += 1
		_type_accum -= 0.012
	_body.visible_characters = _visible_chars
	if _visible_chars >= _text.length():
		_typing = false


func _build() -> void:
	_panel = Control.new()
	_panel.name = "Banner"
	_panel.size = Vector2(BASE_W, BASE_H)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.pivot_offset = Vector2(0.0, BASE_H)
	add_child(_panel)

	var shadow := Panel.new()
	shadow.position = Vector2(4.0, 5.0)
	shadow.size = Vector2(BASE_W, BASE_H)
	shadow.add_theme_stylebox_override("panel", _flat(
		Color(0.0, 0.0, 0.0, 0.30), Color(0.0, 0.0, 0.0, 0.0), 0, 4))
	_panel.add_child(shadow)

	var paper := Panel.new()
	paper.size = Vector2(BASE_W, BASE_H)
	paper.add_theme_stylebox_override("panel", _flat(
		Color(0.92, 0.84, 0.66, 0.98), Color(0.16, 0.25, 0.16), 3, 4))
	_panel.add_child(paper)

	_accent = ColorRect.new()
	_accent.position = Vector2(0.0, 4.0)
	_accent.size = Vector2(8.0, BASE_H - 8.0)
	_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_accent)

	var portrait_back := Panel.new()
	portrait_back.position = Vector2(14.0, 13.0)
	portrait_back.size = Vector2(56.0, 56.0)
	# D-1095: a borda preta externa continua; a franja interna marrom sai
	# pelo fundo dourado cozido no retrato, não por remover esta borda.
	portrait_back.add_theme_stylebox_override("panel", _flat(
		Color(0.85, 0.68, 0.30), Color(0.16, 0.25, 0.16), 2, 28))
	_panel.add_child(portrait_back)

	_portrait = TextureRect.new()
	# D-1095: aro dourado interno de volta; fundo do ícone marrom escuro.
	_portrait.position = Vector2(4.0, 4.0)
	_portrait.size = Vector2(48.0, 48.0)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = CIRCLE_SHADER
	_portrait.material = mat
	portrait_back.add_child(_portrait)

	_portrait_fallback = Label.new()
	_portrait_fallback.position = Vector2(4.0, 4.0)
	_portrait_fallback.size = Vector2(48.0, 48.0)
	_portrait_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_fallback.add_theme_font_override("font", _font_name)
	_portrait_fallback.add_theme_font_size_override("font_size", 26)
	_portrait_fallback.add_theme_color_override("font_color", Color(0.16, 0.25, 0.16))
	_portrait_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_fallback.visible = false
	portrait_back.add_child(_portrait_fallback)

	var name_tab := PanelContainer.new()
	name_tab.position = Vector2(82.0, 7.0)
	name_tab.size = Vector2(250.0, 24.0)
	name_tab.add_theme_stylebox_override("panel", _flat(
		Color(0.14, 0.23, 0.15, 0.98), Color(0.85, 0.68, 0.30, 0.95), 1, 2))
	_name_label = Label.new()
	_name_label.text = "ALLY"
	_name_label.custom_minimum_size = Vector2(230.0, 16.0)
	_name_label.add_theme_font_override("font", _font_name)
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_tab.add_child(_name_label)
	_panel.add_child(name_tab)

	_body = Label.new()
	_body.position = Vector2(82.0, 31.0)
	_body.size = Vector2(282.0, 44.0)
	_body.custom_minimum_size = Vector2(282.0, 44.0)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_override("font", _font_body)
	_body.add_theme_font_size_override("font_size", 16)
	_body.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08))
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_body)


func _font(names: Array, weight: int) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(names)
	font.font_weight = weight
	return font


func _flat(bg: Color, border: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = border_w
	s.border_width_top = border_w
	s.border_width_right = border_w
	s.border_width_bottom = border_w
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 8.0
	s.content_margin_right = 8.0
	s.content_margin_top = 2.0
	s.content_margin_bottom = 2.0
	return s
