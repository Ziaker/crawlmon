extends Control
## D-1156: notificação de coleta no estilo Paper Tag (opção A escolhida).
## O card nasce do impacto do orbe, com pivô no ícone; o papel é desenhado no _draw.

const BASE_Y := 96.0
const FINAL_POS := Vector2(20.0, BASE_Y)
const CARD_SIZE := Vector2(300.0, 86.0)
const PAPER := Color("#e8dfc8")
const INK := Color("#211b15")
const CRIMSON := Color("#7e2b24")

var _paper := PAPER
var _outline := INK
var _ink := INK
var _accent := CRIMSON
var _sub_color := Color("#5d5140")
var _icon_bg := Color("#2b251d")
var _inner := Color(0.23, 0.18, 0.13, 0.22)
var _rest_scale := 1.0
var _anchor: Node3D
var _anchor_height := 1.4

var _icon: TextureRect
var _icon_panel: Panel
var _kicker: Label
var _name: Label
var _sub: Label
var _qty: Label
var _qty_panel: Panel
var _tween: Tween
var _revealed := false
var _home := FINAL_POS


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = CARD_SIZE
	custom_minimum_size = CARD_SIZE
	rotation = deg_to_rad(-1.5)
	visible = false
	_build()
	# O card nasce do ícone: escala/rotação giram em volta do centro dele.
	pivot_offset = _icon_panel.position + _icon_panel.size * 0.5
	position = Vector2(-340.0, BASE_Y)
	set_process(false)


func _build() -> void:
	_kicker = _label("ITEM COLLECTED", 9, _accent, true)
	_kicker.position = Vector2(80.0, 20.0)
	_kicker.size = Vector2(168.0, 14.0)
	add_child(_kicker)

	_name = _label("ITEM", 23, _ink, false)
	_name.position = Vector2(80.0, 29.0)
	_name.size = Vector2(168.0, 28.0)
	_name.clip_text = true
	add_child(_name)

	_sub = _label("ITEM · CONSUMABLE", 8, _sub_color, true)
	_sub.position = Vector2(80.0, 56.0)
	_sub.size = Vector2(168.0, 12.0)
	add_child(_sub)

	_icon_panel = Panel.new()
	_icon_panel.position = Vector2(12.0, 15.0)
	_icon_panel.size = Vector2(54.0, 54.0)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = _icon_bg
	icon_style.border_color = _outline
	icon_style.set_border_width_all(2)
	icon_style.set_corner_radius_all(27)
	icon_style.shadow_color = Color(0, 0, 0, 0.28)
	icon_style.shadow_size = 3
	_icon_panel.add_theme_stylebox_override("panel", icon_style)
	add_child(_icon_panel)

	_icon = TextureRect.new()
	_icon.position = Vector2(7.0, 7.0)
	_icon.size = Vector2(40.0, 40.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon_panel.add_child(_icon)

	_qty_panel = Panel.new()
	_qty_panel.position = Vector2(254.0, 25.0)
	_qty_panel.size = Vector2(34.0, 34.0)
	var qty_style := StyleBoxFlat.new()
	qty_style.bg_color = Color(1, 1, 1, 0.16)
	qty_style.border_color = _accent
	qty_style.set_border_width_all(2)
	qty_style.set_corner_radius_all(17)
	_qty_panel.add_theme_stylebox_override("panel", qty_style)
	add_child(_qty_panel)

	_qty = _label("+1", 14, _accent, false)
	_qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_qty.position = Vector2.ZERO
	_qty.size = _qty_panel.size
	_qty_panel.add_child(_qty)


func _label(text: String, font_size: int, color: Color, mono: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(
		["Consolas", "Courier New"] if mono else ["Georgia", "Times New Roman", "Cambria"])
	font.font_weight = 800 if mono else 700
	label.add_theme_font_override("font", font)
	return label


func _draw() -> void:
	var paper := PackedVector2Array([
		Vector2(2, 3), Vector2(28, 0), Vector2(64, 2), Vector2(108, 0),
		Vector2(152, 2), Vector2(198, 0), Vector2(246, 2), Vector2(298, 1),
		Vector2(300, 18), Vector2(298, 44), Vector2(300, 70), Vector2(297, 84),
		Vector2(262, 86), Vector2(220, 84), Vector2(178, 86), Vector2(132, 84),
		Vector2(86, 86), Vector2(44, 84), Vector2(3, 83), Vector2(0, 65),
		Vector2(2, 38), Vector2(0, 16),
	])
	var shadow := PackedVector2Array()
	for point in paper:
		shadow.append(point + Vector2(7.0, 8.0))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.42))
	draw_colored_polygon(paper, _paper)
	var outline := paper.duplicate()
	outline.append(paper[0])
	draw_polyline(outline, _outline, 2.0, true)
	var inner := PackedVector2Array()
	for point in paper:
		inner.append(point * 0.97 + Vector2(4.0, 3.0))
	inner.append(inner[0])
	draw_polyline(inner, _inner, 1.0, true)


func configure_ally(anchor: Node3D, height: float, rest := 0.78) -> void:
	_anchor = anchor
	_anchor_height = height
	_rest_scale = rest
	_use_ally_palette()
	set_process(true)


func configure_ally_hud(slot: Vector2) -> void:
	_anchor = null
	_rest_scale = 1.0
	_home = slot
	_use_ally_palette()
	set_process(false)


func _use_ally_palette() -> void:
	_paper = Color("#17283b")
	_outline = Color("#0a121c")
	_ink = Color("#eceada")
	_accent = Color("#b5a5fe")
	_sub_color = Color("#b8c6d8")
	_icon_bg = Color("#0e1a28")
	_inner = Color(0.93, 0.91, 0.85, 0.16)
	_apply_palette()


func _apply_palette() -> void:
	if _kicker == null:
		return
	_kicker.add_theme_color_override("font_color", _accent)
	_name.add_theme_color_override("font_color", _ink)
	_sub.add_theme_color_override("font_color", _sub_color)
	_qty.add_theme_color_override("font_color", _accent)
	var icon_style := _icon_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if icon_style != null:
		icon_style.bg_color = _icon_bg
		icon_style.border_color = _outline
	var qty_style := _qty_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if qty_style != null:
		qty_style.border_color = _accent
	queue_redraw()


func _process(_delta: float) -> void:
	if _anchor != null and is_instance_valid(_anchor) and visible:
		_place_above_anchor()


func _place_above_anchor() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var head := _anchor.global_position + Vector3(0.0, _anchor_height + 0.15, 0.0)
	var screen := cam.unproject_position(head)
	var pivot := _icon_panel.position + _icon_panel.size * 0.5
	var rest := _rest_scale
	var pivot_global := Vector2(
		screen.x - (CARD_SIZE.x * 0.5 - pivot.x) * rest,
		screen.y - 12.0 - (CARD_SIZE.y - pivot.y) * rest)
	position = pivot_global - pivot


func show_item(item_id: String) -> Vector2:
	var item := Item.get_item(item_id)
	var display := item.display_name if item != null else item_id.to_upper()
	var kind := "CONSUMABLE" if item != null and item.kind == Item.Kind.CONSUMABLE else "HELD"
	_name.text = display
	var font := _name.get_theme_font("font")
	var font_size := 23
	while font_size > 16 and font.get_string_size(
			display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > _name.size.x:
		font_size -= 1
	_name.add_theme_font_size_override("font_size", font_size)
	_sub.text = "%s · %s" % [item_id.to_upper().replace("_", " "), kind]
	var texture := Item.icon_of(item_id)
	_icon.texture = texture
	_icon.visible = texture != null
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_revealed = false
	visible = true
	modulate.a = 0.0
	# Measure the icon at the final full-size state; the orb flies there.
	if _anchor != null and is_instance_valid(_anchor):
		_place_above_anchor()
	else:
		position = _home
	scale = Vector2.ONE * _rest_scale
	rotation = deg_to_rad(-1.5)
	force_update_transform()
	_icon_panel.force_update_transform()
	var icon_target := icon_center()
	# Wait for the impact as a thin, invisible paper sliver at the icon.
	scale = Vector2(0.1, 0.35) * _rest_scale
	rotation = deg_to_rad(-7.0)
	modulate.a = 0.0
	return icon_target


func set_home(pos: Vector2) -> void:
	_home = pos


func icon_center() -> Vector2:
	if _icon_panel == null:
		return global_position
	return _icon_panel.get_global_rect().get_center()


func reveal_from_impact() -> void:
	if not visible or _revealed:
		return
	_revealed = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE * _rest_scale, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation", deg_to_rad(-1.5), 0.32) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.12)
	_tween.chain().tween_interval(2.2)
	if _anchor != null:
		_tween.chain().tween_property(self, "modulate:a", 0.0, 0.35)
	else:
		_tween.chain().tween_property(self, "position:x", -340.0, 0.35) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
	_tween.chain().tween_callback(func() -> void:
		visible = false
		set_process(false))
