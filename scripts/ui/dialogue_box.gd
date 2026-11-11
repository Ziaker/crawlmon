class_name DialogueBox
extends CanvasLayer
## Caixa de Diálogo Tática — Estilo CRAWLMON // ÂNGULO ZERO V2
## Geometria inclinada (-8°), sombras duras em bloco, retícula tática,
## faixa de destaque Lime/Coral, enquadramento 1:1 perfeito para ícones PMD,
## efeito typewriter dinâmico e prompt de ação animado.

signal dialogue_closed

var is_open := false

# Dimensões e geometria do painel tático
const PANEL_W := 1060.0
const PANEL_H := 174.0
const SLANT := 22.0  ## Inclinação angular das laterais (-8°)
const PORTRAIT_SIZE := 112.0  ## Área quadrada perfeita para o ícone PMD

# Cores da paleta Ângulo Zero
const COLOR_INK := Color(0.03, 0.05, 0.09, 0.98)        # #080e18
const COLOR_NAVY := Color(0.06, 0.10, 0.17, 0.96)       # #101c2c
const COLOR_STEEL := Color(0.27, 0.39, 0.48, 0.90)      # #455869
const COLOR_CREAM := Color(0.94, 0.93, 0.87, 1.0)       # #f0eedf
const COLOR_LIME := Color(0.84, 0.99, 0.42, 1.0)        # #d7fd6a
const COLOR_CORAL := Color(1.0, 0.38, 0.31, 1.0)        # #ff624f
const COLOR_AQUA := Color(0.38, 0.85, 0.91, 1.0)        # #62d8e7
const COLOR_GOLD := Color(0.97, 0.80, 0.47, 1.0)        # #f7cb78
const COLOR_SHADOW := Color(0.01, 0.02, 0.05, 0.88)     # #02070e

var _root: Control
var _dim_rect: ColorRect
var _draw_layer: Control
var _portrait_rect: TextureRect
var _speaker_name: String = ""
var _dialogue_text: String = ""

# Labels dedicadas
var _name_label: Label
var _eyebrow_label: Label
var _text_label: Label
var _prompt_label: Label
var _portrait_tag: Label
var _on_close_callback: Callable

# Controle do efeito Typewriter
var _is_typing := false
var _type_speed := 46.0  ## Caracteres por segundo
var _char_accumulator := 0.0
var _anim_timer := 0.0


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Fundo sutil para focar a atenção no diálogo (cinematic dim)
	_dim_rect = ColorRect.new()
	_dim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim_rect.color = Color(0.02, 0.04, 0.08, 0.35)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim_rect)

	# Camada customizada de desenho vetorial tático
	_draw_layer = Control.new()
	_draw_layer.position = Vector2((1280.0 - PANEL_W) * 0.5, 720.0 - PANEL_H - 24.0)
	_draw_layer.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	_draw_layer.draw.connect(_on_draw_panel)
	_root.add_child(_draw_layer)

	# Nameplate Labels (no topo esquerdo sobrepondo o painel)
	var nx := SLANT + 16.0
	var ny := -20.0
	
	_eyebrow_label = Label.new()
	_eyebrow_label.position = Vector2(nx + 16.0, ny + 2.0)
	_eyebrow_label.text = "▲ ENCONTRO // DIÁLOGO"
	_eyebrow_label.add_theme_font_size_override("font_size", 9)
	_eyebrow_label.add_theme_color_override("font_color", COLOR_LIME)
	_draw_layer.add_child(_eyebrow_label)

	_name_label = Label.new()
	_name_label.position = Vector2(nx + 16.0, ny + 13.0)
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", COLOR_GOLD)
	_draw_layer.add_child(_name_label)

	# Container interno do Retrato PMD (104x104 útil dentro da moldura 112x112)
	var portrait_pos := Vector2(36.0, (PANEL_H - PORTRAIT_SIZE) * 0.5)
	
	_portrait_rect = TextureRect.new()
	_portrait_rect.position = portrait_pos + Vector2(4.0, 4.0)
	_portrait_rect.size = Vector2(PORTRAIT_SIZE - 8.0, PORTRAIT_SIZE - 8.0)
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_draw_layer.add_child(_portrait_rect)

	_portrait_tag = Label.new()
	_portrait_tag.position = Vector2(portrait_pos.x, portrait_pos.y + PORTRAIT_SIZE + 2.0)
	_portrait_tag.size = Vector2(PORTRAIT_SIZE, 14.0)
	_portrait_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_tag.text = "PMD // RETRATO"
	_portrait_tag.add_theme_font_size_override("font_size", 9)
	_portrait_tag.add_theme_color_override("font_color", COLOR_STEEL)
	_draw_layer.add_child(_portrait_tag)

	# Label do Texto do Diálogo
	_text_label = Label.new()
	_text_label.position = Vector2(portrait_pos.x + PORTRAIT_SIZE + 24.0, 32.0)
	_text_label.size = Vector2(PANEL_W - (portrait_pos.x + PORTRAIT_SIZE + 56.0), PANEL_H - 72.0)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 16)
	_text_label.add_theme_color_override("font_color", COLOR_CREAM)
	_text_label.add_theme_constant_override("line_spacing", 5)
	_draw_layer.add_child(_text_label)

	# Label do Botão de Avanço no rodapé direito
	var bx := PANEL_W - SLANT - 180.0
	var by := PANEL_H - 34.0
	_prompt_label = Label.new()
	_prompt_label.position = Vector2(bx + 14.0, by + 4.0)
	_prompt_label.size = Vector2(150.0, 20.0)
	_prompt_label.text = "[Z] AVANÇAR ▶"
	_prompt_label.add_theme_font_size_override("font_size", 11)
	_prompt_label.add_theme_color_override("font_color", COLOR_STEEL)
	_draw_layer.add_child(_prompt_label)


func _on_draw_panel() -> void:
	var w := PANEL_W
	var h := PANEL_H
	var s := SLANT

	# 1. SOMBRA DURA EM BLOCO (+8px, +8px)
	var shadow_pts := PackedVector2Array([
		Vector2(s + 8.0, 8.0),
		Vector2(w + 8.0, 8.0),
		Vector2(w - s + 8.0, h + 8.0),
		Vector2(8.0, h + 8.0)
	])
	_draw_layer.draw_colored_polygon(shadow_pts, COLOR_SHADOW)

	# 2. CORPO DO PAINEL TÁTICO (Polígono Inclinado)
	var panel_pts := PackedVector2Array([
		Vector2(s, 0.0),
		Vector2(w, 0.0),
		Vector2(w - s, h),
		Vector2(0.0, h)
	])
	_draw_layer.draw_colored_polygon(panel_pts, COLOR_NAVY)

	# 3. LINHAS DE TEXTURA TÁTICA (Hachuras diagonais de fundo)
	for x in range(int(s), int(w), 24):
		var x_pos := float(x)
		_draw_layer.draw_line(
			Vector2(x_pos, 0.0),
			Vector2(x_pos - s * 0.7, h),
			Color(1.0, 1.0, 1.0, 0.02),
			1.0
		)

	# 4. BORDA DE CONTORNO DE AÇO
	var border_pts := PackedVector2Array([
		Vector2(s, 0.0),
		Vector2(w, 0.0),
		Vector2(w - s, h),
		Vector2(0.0, h),
		Vector2(s, 0.0)
	])
	_draw_layer.draw_polyline(border_pts, COLOR_STEEL, 1.5)

	# 5. BORDA ESQUERDA SÓLIDA DE DESTAQUE (AQUA)
	_draw_layer.draw_line(Vector2(s, 0.0), Vector2(0.0, h), COLOR_AQUA, 4.0)

	# 6. FAIXA SUPERIOR DE DESTAQUE (TOP-ACCENT LIME + CORAL)
	var lime_end := s + 260.0
	var lime_pts := PackedVector2Array([
		Vector2(s, 0.0),
		Vector2(lime_end, 0.0),
		Vector2(lime_end - 4.0, 4.0),
		Vector2(s - 1.0, 4.0)
	])
	_draw_layer.draw_colored_polygon(lime_pts, COLOR_LIME)

	var coral_start := lime_end + 3.0
	var coral_end := coral_start + 65.0
	var coral_pts := PackedVector2Array([
		Vector2(coral_start, 0.0),
		Vector2(coral_end, 0.0),
		Vector2(coral_end - 4.0, 4.0),
		Vector2(coral_start - 4.0, 4.0)
	])
	_draw_layer.draw_colored_polygon(coral_pts, COLOR_CORAL)

	# 7. BADGE DO INTERLOCUTOR (NAMEPLATE INCLINADO NO TOPO ESQUERDO)
	_draw_nameplate(s)

	# 8. MOLDURA RETICULADA DO RETRATO PMD
	_draw_portrait_frame()

	# 9. BOTÃO DE AÇÃO NO RODAPÉ DIREITO
	_draw_prompt_button(w, h, s)


func _draw_nameplate(s: float) -> void:
	var nx := s + 16.0
	var ny := -20.0
	var nw := 280.0
	var nh := 34.0
	var n_slant := 10.0

	# Sombra do badge
	var b_shadow := PackedVector2Array([
		Vector2(nx + n_slant + 4.0, ny + 4.0),
		Vector2(nx + nw + 4.0, ny + 4.0),
		Vector2(nx + nw - n_slant + 4.0, ny + nh + 4.0),
		Vector2(nx + 4.0, ny + nh + 4.0)
	])
	_draw_layer.draw_colored_polygon(b_shadow, COLOR_SHADOW)

	# Fundo do badge
	var b_pts := PackedVector2Array([
		Vector2(nx + n_slant, ny),
		Vector2(nx + nw, ny),
		Vector2(nx + nw - n_slant, ny + nh),
		Vector2(nx, ny + nh)
	])
	_draw_layer.draw_colored_polygon(b_pts, COLOR_INK)
	_draw_layer.draw_polyline(PackedVector2Array([
		Vector2(nx + n_slant, ny),
		Vector2(nx + nw, ny),
		Vector2(nx + nw - n_slant, ny + nh),
		Vector2(nx, ny + nh),
		Vector2(nx + n_slant, ny)
	]), COLOR_STEEL, 1.2)

	# Acento esquerdo Lime no badge
	_draw_layer.draw_line(Vector2(nx + n_slant, ny), Vector2(nx, ny + nh), COLOR_LIME, 3.5)


func _draw_portrait_frame() -> void:
	var px := 36.0
	var py := (PANEL_H - PORTRAIT_SIZE) * 0.5
	var sz := PORTRAIT_SIZE

	# Sombra dura da moldura do retrato (+4px, +4px)
	_draw_layer.draw_rect(Rect2(px + 4.0, py + 4.0, sz, sz), COLOR_SHADOW, true)

	# Fundo escuro profundo para o pixel art se destacar
	_draw_layer.draw_rect(Rect2(px, py, sz, sz), COLOR_INK, true)

	# Contorno técnico Aqua
	_draw_layer.draw_rect(Rect2(px, py, sz, sz), COLOR_AQUA, false, 2.0)

	# Retícula de mira nos 4 cantos (Estilo Ângulo Zero)
	var tick := 8.0
	# Superior esquerdo
	_draw_layer.draw_line(Vector2(px - 2.0, py), Vector2(px + tick, py), COLOR_LIME, 2.0)
	_draw_layer.draw_line(Vector2(px, py - 2.0), Vector2(px, py + tick), COLOR_LIME, 2.0)
	# Superior direito
	_draw_layer.draw_line(Vector2(px + sz - tick, py), Vector2(px + sz + 2.0, py), COLOR_LIME, 2.0)
	_draw_layer.draw_line(Vector2(px + sz, py - 2.0), Vector2(px + sz, py + tick), COLOR_LIME, 2.0)
	# Inferior esquerdo
	_draw_layer.draw_line(Vector2(px - 2.0, py + sz), Vector2(px + tick, py + sz), COLOR_LIME, 2.0)
	_draw_layer.draw_line(Vector2(px, py + sz - tick), Vector2(px, py + sz + 2.0), COLOR_LIME, 2.0)
	# Inferior direito
	_draw_layer.draw_line(Vector2(px + sz - tick, py + sz), Vector2(px + sz + 2.0, py + sz), COLOR_LIME, 2.0)
	_draw_layer.draw_line(Vector2(px + sz, py + sz - tick), Vector2(px + sz, py + sz + 2.0), COLOR_LIME, 2.0)


func _draw_prompt_button(w: float, h: float, s: float) -> void:
	var bx := w - s - 180.0
	var by := h - 34.0
	var bw := 165.0
	var bh := 24.0
	var b_slant := 7.0

	var btn_color: Color
	if _is_typing:
		btn_color = COLOR_INK
		_prompt_label.text = "[Z] AVANÇAR ▶"
		_prompt_label.add_theme_color_override("font_color", COLOR_STEEL)
	else:
		var pulse := 0.75 + 0.25 * sin(_anim_timer * 7.0)
		btn_color = COLOR_LIME * Color(1.0, 1.0, 1.0, pulse)
		_prompt_label.text = "[Z] CONCLUIR ▼"
		_prompt_label.add_theme_color_override("font_color", COLOR_INK)

	# Sombra do botão
	var b_shadow := PackedVector2Array([
		Vector2(bx + b_slant + 3.0, by + 3.0),
		Vector2(bx + bw + 3.0, by + 3.0),
		Vector2(bx + bw - b_slant + 3.0, by + bh + 3.0),
		Vector2(bx + 3.0, by + bh + 3.0)
	])
	_draw_layer.draw_colored_polygon(b_shadow, COLOR_SHADOW)

	# Corpo do botão inclinado
	var b_pts := PackedVector2Array([
		Vector2(bx + b_slant, by),
		Vector2(bx + bw, by),
		Vector2(bx + bw - b_slant, by + bh),
		Vector2(bx, by + bh)
	])
	_draw_layer.draw_colored_polygon(b_pts, btn_color)
	_draw_layer.draw_polyline(PackedVector2Array([
		Vector2(bx + b_slant, by),
		Vector2(bx + bw, by),
		Vector2(bx + bw - b_slant, by + bh),
		Vector2(bx, by + bh),
		Vector2(bx + b_slant, by)
	]), COLOR_LIME if not _is_typing else COLOR_STEEL, 1.2)


func _process(delta: float) -> void:
	if not is_open:
		return

	_anim_timer += delta

	# Efeito de máquina de escrever (Typewriter)
	if _is_typing:
		_char_accumulator += delta * _type_speed
		var count := int(_char_accumulator)
		if count >= _dialogue_text.length():
			_finish_typing()
		else:
			_text_label.visible_characters = count
	
	_draw_layer.queue_redraw()


func show_dialogue(speaker_name: String, portrait_texture: Texture2D, dialogue_text: String, on_close: Callable = Callable()) -> void:
	_speaker_name = speaker_name
	_dialogue_text = dialogue_text
	_on_close_callback = on_close

	_portrait_rect.texture = portrait_texture
	_name_label.text = speaker_name.to_upper()

	_text_label.text = dialogue_text
	_text_label.visible_characters = 0
	_char_accumulator = 0.0
	_type_speed = GameState.text_speed_value()  # QoL: settings apply to the next line immediately.
	_is_typing = true
	_anim_timer = 0.0

	is_open = true
	visible = true

	# Transição de entrada suave (Punchy Anime Snap)
	_draw_layer.modulate.a = 0.0
	_dim_rect.modulate.a = 0.0
	_draw_layer.position.y = (720.0 - PANEL_H - 24.0) + 12.0
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim_rect, "modulate:a", 1.0, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(_draw_layer, "modulate:a", 1.0, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(_draw_layer, "position:y", 720.0 - PANEL_H - 24.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_draw_layer.queue_redraw()


func _finish_typing() -> void:
	_is_typing = false
	_text_label.visible_characters = -1
	_draw_layer.queue_redraw()


func close_dialogue() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	dialogue_closed.emit()
	if _on_close_callback.is_valid():
		_on_close_callback.call()
		_on_close_callback = Callable()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		if _is_typing:
			_finish_typing()
		else:
			close_dialogue()
