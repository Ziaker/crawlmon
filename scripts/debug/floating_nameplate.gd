extends Node3D
## D-1096: placa de nome flutuante na linguagem dos cards/HUDs do jogo.
##
## 3 estilos, todos baseados na UI real:
##   unit_card  — UnitCard de batalha/exploração (D-1072/D-1074)
##   move_strip — Move Strips da hotbar/status (D-417/D-434)
##   expedition — Expedition Satchel/status (D-424–D-431)
##
## A placa é genérica: serve NPC, aliado e inimigo, de qualquer lado (D-235).
## As barras de HP/MP e os pips de ATB são decorativos; não mostram dados.
##
## Uso:
##   var plate = NAMEPLATE.new()
##   plate.display_name = "BULBASAUR"
##   plate.role_text = "NPC"
##   plate.style_id = "unit_card"
##   plate.position = Vector3(0, 1.2, 0)
##   body.add_child(plate)

const PLATE_W := 768.0
const PLATE_H := 216.0
## 35% maior que a D-1094 (512×144 a 0,0034 = 1,74 m); aqui 2,35 m.
const PIXEL_SIZE := 0.003978
const PLATE_PATHS := {
	"unit_card": "res://assets/ui/nameplates/nameplate_unit_card.png",
	"move_strip": "res://assets/ui/nameplates/nameplate_move_strip.png",
	"expedition": "res://assets/ui/nameplates/nameplate_expedition.png",
}

var display_name := ""
var role_text := "NPC"
var style_id := "unit_card"

var _visual: Node3D
var _plate: Sprite3D
var _name_label: Label3D
var _role_label: Label3D
var _display_font: SystemFont
var _body_font: SystemFont
var _serif_font: SystemFont
var _texture_cache: Dictionary = {}
var _name_home := Vector3.ZERO
var _time := 0.0
var _phase := 0.0
var _base_tilt := 0.0
var _sway_amp := 0.0
var _bob_amp := 0.012
var _intro_tween: Tween


func _ready() -> void:
	_phase = randf() * TAU
	_build_fonts()
	_build()
	_apply_style()
	play_intro()


func _process(delta: float) -> void:
	_time += delta
	if not is_visible_in_tree():
		return
	_face_camera()
	if _intro_tween != null and _intro_tween.is_valid() and _intro_tween.is_running():
		return
	var bob := sin(_time * 2.0 + _phase) * _bob_amp
	var roll := _base_tilt + sin(_time * 1.35 + _phase) * _sway_amp
	_visual.position.y = bob
	_visual.rotation.z = roll


func _build_fonts() -> void:
	_display_font = SystemFont.new()
	_display_font.font_names = PackedStringArray(["Impact", "Haettenschweiler", "Arial Black"])

	_body_font = SystemFont.new()
	_body_font.font_names = PackedStringArray(["Arial", "Segoe UI"])
	_body_font.font_weight = 800

	_serif_font = SystemFont.new()
	_serif_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	_serif_font.font_weight = 700


func _build() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	_plate = Sprite3D.new()
	_plate.name = "Plate"
	_plate.pixel_size = PIXEL_SIZE
	_plate.shaded = false
	_plate.double_sided = true
	_plate.transparent = true
	_plate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_plate.render_priority = 0
	_visual.add_child(_plate)

	_name_label = Label3D.new()
	_name_label.name = "Name"
	_name_label.pixel_size = PIXEL_SIZE
	_name_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_name_label.no_depth_test = false
	_name_label.double_sided = false
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.render_priority = 3
	_visual.add_child(_name_label)

	_role_label = Label3D.new()
	_role_label.name = "Role"
	_role_label.pixel_size = PIXEL_SIZE
	_role_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_role_label.no_depth_test = false
	_role_label.double_sided = false
	_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_role_label.render_priority = 4
	_visual.add_child(_role_label)


func _apply_style() -> void:
	if _plate == null:
		return
	_plate.texture = _texture_for(style_id)
	_name_label.text = display_name
	_role_label.text = role_text
	_name_label.outline_size = 0
	_role_label.outline_size = 0
	match style_id:
		"move_strip":
			_name_label.font = _display_font
			_name_label.font_size = 70
			_name_label.modulate = Color(0.918, 0.914, 0.851)
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_name_home = _plate_pos(214.0, 116.0)
			_role_label.font = _body_font
			_role_label.font_size = 24
			_role_label.modulate = Color(0.874, 0.788, 0.502)
			_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_role_label.position = _plate_pos(214.0, 70.0)
			_base_tilt = 0.0
			_sway_amp = 0.0
			_bob_amp = 0.008
		"expedition":
			_name_label.font = _serif_font
			_name_label.font_size = 74
			_name_label.modulate = Color(0.918, 0.914, 0.851)
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_name_home = _plate_pos(94.0, 112.0)
			_role_label.font = _body_font
			_role_label.font_size = 24
			_role_label.modulate = Color(0.874, 0.788, 0.502)
			_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_role_label.position = _plate_pos(184.0, 178.0)
			_base_tilt = deg_to_rad(-1.5)
			_sway_amp = 0.008
			_bob_amp = 0.014
		_:
			# A — bloco paralelogramo flat, só o nome; nenhum detalhe.
			_name_label.font = _display_font
			_name_label.font_size = 100
			_name_label.modulate = Color(0.067, 0.106, 0.161)
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_name_home = _plate_pos(384.0, 108.0)
			_role_label.font = _body_font
			_role_label.font_size = 24
			_role_label.modulate = Color(0.874, 0.788, 0.502)
			_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_role_label.position = _plate_pos(650.0, 41.0)
			_base_tilt = 0.0
			_sway_amp = 0.0
			_bob_amp = 0.012
	_role_label.visible = style_id != "unit_card"
	_name_label.position = _name_home
	_visual.rotation.z = _base_tilt


func _plate_pos(px: float, py: float) -> Vector3:
	return Vector3(
		(px - PLATE_W * 0.5) * PIXEL_SIZE,
		(PLATE_H * 0.5 - py) * PIXEL_SIZE,
		0.02)


func _texture_for(id: String) -> Texture2D:
	if not _texture_cache.has(id):
		_texture_cache[id] = load(str(PLATE_PATHS.get(id, PLATE_PATHS["unit_card"])))
	return _texture_cache[id] as Texture2D


func set_style(id: String) -> void:
	if not PLATE_PATHS.has(id):
		return
	style_id = id
	_apply_style()
	play_intro()


func set_distance_scale(value: float) -> void:
	scale = Vector3.ONE * value


func play_intro() -> void:
	if _visual == null:
		return
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	match style_id:
		"move_strip":
			_visual.scale = Vector3(0.02, 1.0, 1.0)
			_intro_tween = create_tween()
			_intro_tween.tween_property(_visual, "scale", Vector3(1.05, 1.05, 1.05), 0.20) \
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			_intro_tween.tween_property(_visual, "scale", Vector3.ONE, 0.12) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		"expedition":
			_visual.scale = Vector3.ONE * 0.70
			_intro_tween = create_tween()
			_intro_tween.tween_property(_visual, "scale", Vector3.ONE * 1.05, 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_intro_tween.tween_property(_visual, "scale", Vector3.ONE, 0.14) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_:
			_visual.scale = Vector3.ONE * 0.60
			_intro_tween = create_tween()
			_intro_tween.tween_property(_visual, "scale", Vector3.ONE * 1.06, 0.20) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_intro_tween.tween_property(_visual, "scale", Vector3.ONE, 0.12) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _face_camera() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var target := cam.global_position
	if global_position.is_equal_approx(target):
		return
	look_at(target, Vector3.UP)
	# Sprite3D/Label3D olham para +Z; `look_at` aponta -Z para a câmera.
	rotate_object_local(Vector3.UP, PI)
