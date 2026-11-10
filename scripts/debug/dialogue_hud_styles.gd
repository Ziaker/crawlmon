extends Control
## D-1087: três protótipos de HUD de diálogo, cada um com sua abertura.
## A = SMT III/terminal, B = comic/manga, C = card de papel/RPG.
## Este nó só desenha/lê; não toca em batalha, 2D ou regras.

enum Style { SMT, COMIC, PAPER }

const PORTRAIT_PATH := "res://sugimori/por_nome/bulbasaur.png"
const SMT_SHADER := preload("res://shaders/dialogue_smt_panel.gdshader")
const HALFTONE_SHADER := preload("res://shaders/dialogue_halftone.gdshader")
const PAPER_SHADER := preload("res://shaders/dialogue_paper.gdshader")
const CIRCLE_SHADER := preload("res://shaders/dialogue_portrait_circle.gdshader")

var style: int = Style.SMT
var _speaker := "BULBASAUR"
var _text := ""
var _panel: Control
var _bg: ColorRect
var _body: Label
var _next: Label
var _name_label: Label
var _name_tab: Control
var _halftone: ColorRect
var _seal: Control
var _portrait: TextureRect
var _portrait_back: Control
var _portrait_fallback: Label
var _font_body: Font
var _font_name: Font
var _font_ui: Font
var _time := 0.0
var _opened := false
var _typing := false
var _type_delay := 0.0
var _type_accum := 0.0
var _visible_chars := 0
var _char_delay := 0.02


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func setup(style_id: int) -> void:
	style = style_id
	for child in get_children():
		child.queue_free()
	_panel = null
	_bg = null
	_body = null
	_next = null
	_name_label = null
	_name_tab = null
	_halftone = null
	_seal = null
	_portrait = null
	_portrait_back = null
	_portrait_fallback = null
	match style:
		Style.SMT:
			_build_smt()
		Style.COMIC:
			_build_comic()
		Style.PAPER:
			_build_paper()
	visible = false


func open(speaker: String, text: String, next_text: String = "NEXT") -> void:
	_set_content(speaker, text, next_text, 0.35)
	visible = true
	match style:
		Style.SMT:
			_animate_smt()
		Style.COMIC:
			_animate_comic()
		Style.PAPER:
			_animate_paper()
	queue_redraw()


func set_line(speaker: String, text: String, next_text: String = "NEXT") -> void:
	_set_content(speaker, text, next_text, 0.1)
	visible = true


func set_next_text(next_text: String) -> void:
	if _next != null:
		_next.text = "[Z] " + next_text


func _set_content(speaker: String, text: String, next_text: String, delay: float) -> void:
	_speaker = speaker
	_text = text
	if _name_label != null:
		_name_label.text = speaker
	if _body != null:
		_body.text = text
		_body.visible_characters = 0
	_visible_chars = 0
	_type_accum = 0.0
	_type_delay = delay
	_typing = false
	_opened = true
	if _next != null:
		_next.text = "[Z] " + next_text
		_next.visible = false
		_next.modulate.a = 0.0


func is_typing() -> bool:
	return _typing or _type_delay > 0.0


func finish_typing() -> void:
	_type_delay = 0.0
	_typing = false
	_visible_chars = _text.length()
	if _body != null:
		_body.visible_characters = _visible_chars
	if _next != null:
		_next.visible = true
		_next.modulate.a = 1.0


func close() -> void:
	_opened = false
	_typing = false
	if _next != null:
		_next.visible = false
	visible = false


func set_portrait(texture: Texture2D) -> void:
	if _portrait != null:
		_portrait.texture = texture
	if _portrait_fallback != null:
		_portrait_fallback.visible = texture == null
		if texture == null:
			_portrait_fallback.text = _speaker.substr(0, 1) if not _speaker.is_empty() else "?"


func _process(delta: float) -> void:
	_time += delta
	if _bg != null and _bg.material is ShaderMaterial:
		(_bg.material as ShaderMaterial).set_shader_parameter("time", _time)
	if _halftone != null:
		_halftone.position.x = 20.0 + sin(_time * 1.7) * 5.0
	if not _opened:
		return
	if _type_delay > 0.0:
		_type_delay -= delta
		if _type_delay <= 0.0:
			_typing = true
	if _typing:
		_type_accum += delta
		while _type_accum >= _char_delay and _visible_chars < _text.length():
			_visible_chars += 1
			_type_accum -= _char_delay
		if _body != null:
			_body.visible_characters = _visible_chars
		if _visible_chars >= _text.length():
			_typing = false
			if _next != null:
				_next.visible = true
	if _next != null and _next.visible:
		_next.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_time * 4.0))


# --- shared helpers ---------------------------------------------------------

func _make_font(names: Array, weight: int) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(names)
	font.font_weight = weight
	return font


func _label(text_value: String, pos: Vector2, box: Vector2, font: Font,
		size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = box
	label.custom_minimum_size = box
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _load_portrait() -> Texture2D:
	if ResourceLoader.exists(PORTRAIT_PATH):
		return load(PORTRAIT_PATH) as Texture2D
	return null


func _portrait_rect(pos: Vector2, box: Vector2, circular: bool) -> TextureRect:
	var tr := TextureRect.new()
	tr.position = pos
	tr.size = box
	tr.custom_minimum_size = box
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = _load_portrait()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if circular:
		var mat := ShaderMaterial.new()
		mat.shader = CIRCLE_SHADER
		tr.material = mat
	_portrait = tr
	return tr


func _panel_root(pos: Vector2, box: Vector2) -> Control:
	_panel = Control.new()
	_panel.position = pos
	_panel.size = box
	_panel.pivot_offset = box * 0.5
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	return _panel


func _add_next(pos: Vector2, box: Vector2, font: Font, color: Color) -> void:
	_next = _label("[Z] NEXT", pos, box, font, 15, color)
	_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next.visible = false
	_panel.add_child(_next)


# --- A: SMT III / terminal ------------------------------------------------

func _build_smt() -> void:
	_font_body = _make_font(["Consolas", "Courier New"], 700)
	_font_name = _make_font(["Consolas", "Courier New"], 700)
	_font_ui = _make_font(["Arial", "Segoe UI"], 800)
	_char_delay = 0.016
	_panel_root(Vector2(48.0, 492.0), Vector2(1184.0, 196.0))

	_bg = ColorRect.new()
	_bg.position = Vector2.ZERO
	_bg.size = _panel.size
	_bg.color = Color.WHITE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SMT_SHADER
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("time", 0.0)
	_bg.material = mat
	_panel.add_child(_bg)

	var frame := Panel.new()
	frame.position = Vector2(22.0, 34.0)
	frame.size = Vector2(126.0, 128.0)
	frame.add_theme_stylebox_override("panel", _flat(
		Color(0.02, 0.06, 0.07, 0.95), Color(0.25, 0.95, 0.85, 0.9), 2, 0))
	_panel.add_child(frame)
	frame.add_child(_portrait_rect(Vector2(3.0, 3.0), Vector2(120.0, 122.0), false))

	_name_tab = PanelContainer.new()
	_name_tab.position = Vector2(18.0, -18.0)
	_name_tab.size = Vector2(310.0, 38.0)
	_name_tab.add_theme_stylebox_override("panel", _flat(
		Color(0.85, 0.22, 0.16, 0.96), Color(1.0, 0.58, 0.35, 0.95), 2, 2))
	_name_label = _label(_speaker, Vector2.ZERO, Vector2(290.0, 30.0), _font_name, 20,
		Color(0.02, 0.03, 0.04))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_tab.add_child(_name_label)
	_panel.add_child(_name_tab)

	_body = _label(_text, Vector2(166.0, 36.0), Vector2(980.0, 112.0), _font_body, 21,
		Color(0.78, 0.95, 0.92))
	_panel.add_child(_body)

	var corner := _label("SMT //", Vector2(1050.0, 10.0), Vector2(110.0, 22.0),
		_font_ui, 12, Color(0.45, 0.95, 0.85, 0.85))
	corner.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel.add_child(corner)
	_add_next(Vector2(1040.0, 160.0), Vector2(120.0, 24.0), _font_ui,
		Color(0.4, 0.95, 0.85))


func _animate_smt() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.985, 0.985)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.16)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var mat := _bg.material as ShaderMaterial
	mat.set_shader_parameter("progress", 0.0)
	var wipe := create_tween()
	wipe.tween_method(func(v: float): mat.set_shader_parameter("progress", v),
		0.0, 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_name_tab.position.x = -40.0
	tw.tween_property(_name_tab, "position:x", 18.0, 0.35).set_delay(0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_body.modulate.a = 0.0
	tw.tween_property(_body, "modulate:a", 1.0, 0.18).set_delay(0.25)


# --- B: comic / manga ------------------------------------------------------

func _build_comic() -> void:
	_font_body = _make_font(["Comic Sans MS", "Segoe UI", "Arial"], 900)
	_font_name = _make_font(["Comic Sans MS", "Segoe UI Black", "Arial"], 900)
	_font_ui = _make_font(["Arial", "Segoe UI"], 800)
	_char_delay = 0.022
	_panel_root(Vector2(120.0, 420.0), Vector2(1040.0, 250.0))
	_panel.pivot_offset = Vector2(150.0, 250.0)

	var tail_outline := Polygon2D.new()
	tail_outline.polygon = PackedVector2Array([
		Vector2(96.0, 230.0), Vector2(28.0, 338.0), Vector2(190.0, 230.0)])
	tail_outline.color = Color(0.03, 0.03, 0.04)
	_panel.add_child(tail_outline)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(108.0, 228.0), Vector2(58.0, 318.0), Vector2(174.0, 228.0)])
	tail.color = Color(0.99, 0.95, 0.84)
	_panel.add_child(tail)

	var bubble := Panel.new()
	bubble.position = Vector2.ZERO
	bubble.size = Vector2(1040.0, 230.0)
	bubble.add_theme_stylebox_override("panel", _flat(
		Color(0.99, 0.95, 0.84), Color(0.03, 0.03, 0.04), 6, 30))
	_panel.add_child(bubble)

	_halftone = ColorRect.new()
	_halftone.position = Vector2(20.0, 20.0)
	_halftone.size = Vector2(1000.0, 190.0)
	_halftone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hm := ShaderMaterial.new()
	hm.shader = HALFTONE_SHADER
	hm.set_shader_parameter("dot_color", Color(0.08, 0.08, 0.10, 0.16))
	hm.set_shader_parameter("scale", 16.0)
	_halftone.material = hm
	_panel.add_child(_halftone)

	_portrait_back = Panel.new()
	_portrait_back.position = Vector2(24.0, 28.0)
	_portrait_back.size = Vector2(164.0, 164.0)
	_portrait_back.pivot_offset = Vector2(82.0, 82.0)
	_portrait_back.add_theme_stylebox_override("panel", _flat(
		Color(0.03, 0.03, 0.04), Color(0.03, 0.03, 0.04), 0, 82))
	_panel.add_child(_portrait_back)
	_portrait_back.add_child(_portrait_rect(Vector2(8.0, 8.0), Vector2(148.0, 148.0), true))

	_name_tab = PanelContainer.new()
	_name_tab.position = Vector2(16.0, -18.0)
	_name_tab.size = Vector2(330.0, 42.0)
	_name_tab.rotation = deg_to_rad(-2.0)
	_name_tab.add_theme_stylebox_override("panel", _flat(
		Color(0.03, 0.03, 0.04, 0.98), Color(0.99, 0.95, 0.84), 2, 4))
	_name_label = _label(_speaker, Vector2.ZERO, Vector2(310.0, 34.0), _font_name, 24,
		Color(0.99, 0.95, 0.84))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_tab.add_child(_name_label)
	_panel.add_child(_name_tab)

	_body = _label(_text, Vector2(210.0, 38.0), Vector2(780.0, 170.0), _font_body, 22,
		Color(0.06, 0.06, 0.07))
	_panel.add_child(_body)
	_add_next(Vector2(850.0, 190.0), Vector2(160.0, 26.0), _font_ui,
		Color(0.06, 0.06, 0.07))


func _animate_comic() -> void:
	_panel.scale = Vector2(0.55, 0.55)
	_panel.rotation = deg_to_rad(-5.0)
	_panel.modulate.a = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.62) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "rotation", 0.0, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_name_tab.position.x = -34.0
	tw.tween_property(_name_tab, "position:x", 16.0, 0.35).set_delay(0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_portrait_back.rotation = -0.22
	tw.tween_property(_portrait_back, "rotation", 0.0, 0.38).set_delay(0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_body.modulate.a = 0.0
	tw.tween_property(_body, "modulate:a", 1.0, 0.18).set_delay(0.3)


# --- C: paper / RPG -------------------------------------------------------

func _build_paper() -> void:
	_font_body = _make_font(["Georgia", "Times New Roman", "Cambria"], 600)
	_font_name = _make_font(["Georgia", "Times New Roman", "Cambria"], 700)
	_font_ui = _make_font(["Georgia", "Times New Roman"], 700)
	_char_delay = 0.025
	_panel_root(Vector2(170.0, 470.0), Vector2(940.0, 210.0))
	_panel.rotation = deg_to_rad(-2.0)

	var card := Panel.new()
	card.position = Vector2.ZERO
	card.size = _panel.size
	card.add_theme_stylebox_override("panel", _flat(
		Color(0.88, 0.79, 0.60), Color(0.16, 0.25, 0.16), 4, 4))
	_panel.add_child(card)

	var paper := ColorRect.new()
	paper.position = Vector2(4.0, 4.0)
	paper.size = _panel.size - Vector2(8.0, 8.0)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = PAPER_SHADER
	paper.material = pm
	_panel.add_child(paper)

	var inner := Panel.new()
	inner.position = Vector2(12.0, 12.0)
	inner.size = _panel.size - Vector2(24.0, 24.0)
	inner.add_theme_stylebox_override("panel", _flat(
		Color(0.0, 0.0, 0.0, 0.0), Color(0.18, 0.28, 0.18, 0.7), 2, 2))
	_panel.add_child(inner)

	_name_tab = PanelContainer.new()
	_name_tab.position = Vector2(26.0, -20.0)
	_name_tab.size = Vector2(360.0, 40.0)
	_name_tab.rotation = deg_to_rad(-2.0)
	_name_tab.add_theme_stylebox_override("panel", _flat(
		Color(0.14, 0.23, 0.15, 0.98), Color(0.85, 0.68, 0.30, 0.95), 2, 2))
	_name_label = _label(_speaker, Vector2.ZERO, Vector2(340.0, 32.0), _font_name, 20,
		Color(0.95, 0.86, 0.62))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_tab.add_child(_name_label)
	_panel.add_child(_name_tab)

	_portrait_back = Panel.new()
	_portrait_back.position = Vector2(28.0, 36.0)
	_portrait_back.size = Vector2(142.0, 142.0)
	_portrait_back.pivot_offset = Vector2(71.0, 71.0)
	_portrait_back.add_theme_stylebox_override("panel", _flat(
		Color(0.85, 0.68, 0.30), Color(0.16, 0.25, 0.16), 2, 71))
	_panel.add_child(_portrait_back)
	_portrait_back.add_child(_portrait_rect(Vector2(8.0, 8.0), Vector2(126.0, 126.0), true))
	_portrait_fallback = _label("B", Vector2(8.0, 8.0), Vector2(126.0, 126.0),
		_font_name, 54, Color(0.16, 0.25, 0.16))
	_portrait_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_fallback.visible = false
	_portrait_back.add_child(_portrait_fallback)

	_body = _label(_text, Vector2(190.0, 34.0), Vector2(700.0, 150.0), _font_body, 21,
		Color(0.18, 0.12, 0.08))
	_panel.add_child(_body)
	_add_next(Vector2(600.0, 176.0), Vector2(150.0, 26.0), _font_ui,
		Color(0.14, 0.23, 0.15))

	_seal = Panel.new()
	_seal.position = Vector2(820.0, 138.0)
	_seal.size = Vector2(86.0, 86.0)
	_seal.pivot_offset = Vector2(43.0, 43.0)
	_seal.add_theme_stylebox_override("panel", _flat(
		Color(0.55, 0.10, 0.10, 0.95), Color(0.85, 0.68, 0.30, 0.95), 3, 43))
	var seal_label := _label("M", Vector2.ZERO, Vector2(86.0, 86.0), _font_name, 34,
		Color(0.95, 0.86, 0.62))
	seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_seal.add_child(seal_label)
	_panel.add_child(_seal)


func _animate_paper() -> void:
	_panel.position.y = 620.0
	_panel.rotation = deg_to_rad(7.0)
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "position:y", 470.0, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "rotation", deg_to_rad(-2.0), 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.28)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_seal.scale = Vector2(2.2, 2.2)
	tw.tween_property(_seal, "scale", Vector2.ONE, 0.5).set_delay(0.35) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_portrait_back.rotation = -0.18
	tw.tween_property(_portrait_back, "rotation", 0.0, 0.4).set_delay(0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_body.modulate.a = 0.0
	tw.tween_property(_body, "modulate:a", 1.0, 0.18).set_delay(0.42)


# --- stylebox helper -------------------------------------------------------

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
	s.content_margin_left = 10.0
	s.content_margin_right = 10.0
	s.content_margin_top = 4.0
	s.content_margin_bottom = 4.0
	return s
