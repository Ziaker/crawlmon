extends Node3D
## D-1094: placa de nome flutuante do overworld, em 3 estilos.
##
## A placa Ã© sempre genÃ©rica: serve para NPC, aliado e inimigo, de qualquer
## lado e em qualquer posiÃ§Ã£o (D-235). O estilo muda a arte, a fonte e a
## entrada; o papel (`NPC`/`ALLY`/`ENEMY`) Ã© sÃ³ texto.
##
## Uso:
##   var plate = NAMEPLATE.new()
##   plate.display_name = "BULBASAUR"
##   plate.role_text = "NPC"
##   plate.style_id = "paper"   # paper | terminal | comic
##   plate.position = Vector3(0, 1.2, 0)
##   body.add_child(plate)
##
## A placa se vira para a cÃ¢mera sozinha e o lab controla o tamanho por
## distÃ¢ncia com `set_distance_scale()`.

const COMIC_FONT := preload("res://assets/fonts/kanit/Kanit-BlackItalic.ttf")
## O nome precisa ficar legÃ­vel a ~6-8 m; a placa Ã© maior que o Label3D antigo
## justamente para o texto nÃ£o encolher junto com a moldura.
const PIXEL_SIZE := 0.0034
const PLATE_PATHS := {
	"paper": "res://assets/ui/nameplates/nameplate_paper.png",
	"terminal": "res://assets/ui/nameplates/nameplate_terminal.png",
	"comic": "res://assets/ui/nameplates/nameplate_comic.png",
}

var display_name := ""
var role_text := "NPC"
var style_id := "paper"

var _visual: Node3D
var _plate: Sprite3D
var _name_label: Label3D
var _ghost_label: Label3D
var _role_label: Label3D
var _sweep: Sprite3D
var _serif: SystemFont
var _mono: SystemFont
var _texture_cache: Dictionary = {}
var _name_home := Vector3.ZERO
var _time := 0.0
var _phase := 0.0
var _distance_scale := 1.0
var _base_tilt := 0.0
var _sway_amp := 0.0
var _bob_amp := 0.01
var _intro_tween: Tween
var _typing := false
var _typed_chars := 0.0
var _glitch_timer := 0.0
var _glitch_time := 0.0


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
	_update_intro(delta)
	if _intro_tween != null and _intro_tween.is_valid() and _intro_tween.is_running():
		return
	var bob := sin(_time * 2.0 + _phase) * _bob_amp
	var roll := _base_tilt + sin(_time * 1.35 + _phase) * _sway_amp
	if style_id == "terminal":
		bob = sin(_time * 7.0 + _phase) * _bob_amp
		roll += sin(_time * 11.0 + _phase) * 0.002
		_update_glitch(delta)
		_sweep.position.y = -0.14 + fmod(_time * 0.55, 1.0) * 0.28
	_visual.position.y = bob
	_visual.rotation.z = roll


func _build_fonts() -> void:
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


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
	_plate.position = Vector3(0.0, 0.0, 0.0)
	_visual.add_child(_plate)

	_name_label = Label3D.new()
	_name_label.name = "Name"
	_name_label.pixel_size = PIXEL_SIZE
	_name_label.font_size = 52
	_name_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_name_label.no_depth_test = false
	_name_label.double_sided = false
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.render_priority = 3
	_name_label.position = Vector3(0.0, 0.02, 0.012)
	_visual.add_child(_name_label)

	_ghost_label = Label3D.new()
	_ghost_label.name = "Ghost"
	_ghost_label.pixel_size = PIXEL_SIZE
	_ghost_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_ghost_label.no_depth_test = false
	_ghost_label.double_sided = false
	_ghost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ghost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ghost_label.modulate = Color(0.98, 0.20, 0.14, 0.90)
	_ghost_label.render_priority = 4
	_ghost_label.visible = false
	_visual.add_child(_ghost_label)

	_role_label = Label3D.new()
	_role_label.name = "Role"
	_role_label.pixel_size = PIXEL_SIZE
	_role_label.font_size = 24
	_role_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_role_label.no_depth_test = false
	_role_label.double_sided = false
	_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_role_label.render_priority = 5
	_visual.add_child(_role_label)

	# Feixe de varredura do terminal (sÃ³ aparece no estilo "terminal").
	var img := Image.create_empty(4, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		var a := 1.0 - absf(float(y) - 15.5) / 16.0
		for x in 4:
			img.set_pixel(x, y, Color(0.62, 1.0, 0.92, a))
	_sweep = Sprite3D.new()
	_sweep.name = "Sweep"
	_sweep.texture = ImageTexture.create_from_image(img)
	_sweep.pixel_size = PIXEL_SIZE
	_sweep.scale = Vector3(110.0, 1.0, 1.0)
	_sweep.position = Vector3(0.0, 0.0, 0.02)
	_sweep.shaded = false
	_sweep.transparent = true
	_sweep.double_sided = true
	_sweep.modulate = Color(1.0, 1.0, 1.0, 0.30)
	_sweep.render_priority = 1
	_visual.add_child(_sweep)


func _apply_style() -> void:
	if _plate == null:
		return
	_plate.texture = _texture_for(style_id)
	_sweep.visible = style_id == "terminal"
	_ghost_label.visible = false
	_glitch_timer = 0.0
	_glitch_time = 0.0
	_name_label.text = display_name
	_role_label.text = role_text
	_name_label.outline_size = 0
	_name_label.outline_modulate = Color(0, 0, 0, 0)
	_role_label.outline_size = 0
	_role_label.outline_modulate = Color(0, 0, 0, 0)
	match style_id:
		"terminal":
			_name_label.font = _mono
			_name_label.font_size = 50
			_name_label.modulate = Color(0.62, 1.0, 0.93)
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_name_home = _plate_pos(40.0, 82.0)
			_role_label.font = _mono
			_role_label.font_size = 24
			_role_label.modulate = Color(0.42, 0.95, 0.86)
			_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_role_label.position = _plate_pos(36.0, 30.0)
			_base_tilt = 0.0
			_sway_amp = 0.0
			_bob_amp = 0.003
			_ghost_label.font = _mono
			_ghost_label.font_size = 50
			_ghost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_ghost_label.position = _name_home + Vector3(0.026, 0.0, 0.001)
		"comic":
			_name_label.font = COMIC_FONT
			_name_label.font_size = 54
			_name_label.modulate = Color(0.06, 0.05, 0.06)
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_name_home = _plate_pos(250.0, 74.0)
			_role_label.font = COMIC_FONT
			_role_label.font_size = 24
			_role_label.modulate = Color(0.97, 0.92, 0.78)
			_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_role_label.position = _plate_pos(438.0, 28.0)
			_base_tilt = deg_to_rad(-2.5)
			_sway_amp = 0.012
			_bob_amp = 0.018
		_:
			_name_label.font = _serif
			_name_label.font_size = 52
			_name_label.modulate = Color(0.15, 0.12, 0.08)
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_name_home = _plate_pos(256.0, 68.0)
			_role_label.font = _serif
			_role_label.font_size = 26
			_role_label.modulate = Color(0.88, 0.82, 0.60)
			_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_role_label.position = _plate_pos(72.0, 121.0)
			_base_tilt = 0.0
			_sway_amp = 0.012
			_bob_amp = 0.012
	_name_label.position = _name_home
	_visual.position.x = 0.0
	# O terminal mostra o glitch já no primeiro ciclo de exibição.
	_glitch_timer = 1.2 if style_id == "terminal" else 0.0
	_glitch_time = 0.0


func _plate_pos(px: float, py: float) -> Vector3:
	# Converte pixels da textura (512x144) para o espaço local da placa.
	return Vector3((px - 256.0) * PIXEL_SIZE, (72.0 - py) * PIXEL_SIZE, 0.02)


func _texture_for(id: String) -> Texture2D:
	if not _texture_cache.has(id):
		_texture_cache[id] = load(str(PLATE_PATHS.get(id, PLATE_PATHS["paper"])))
	return _texture_cache[id] as Texture2D


func set_style(id: String) -> void:
	if not PLATE_PATHS.has(id):
		return
	style_id = id
	_apply_style()
	play_intro()


func set_distance_scale(value: float) -> void:
	_distance_scale = value
	scale = Vector3.ONE * value


func play_intro() -> void:
	if _visual == null:
		return
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_typing = false
	_typed_chars = 0.0
	_ghost_label.visible = false
	_name_label.text = display_name
	if style_id == "terminal":
		_typing = true
		_name_label.text = ""
		_visual.scale = Vector3(0.04, 1.0, 1.0)
		_intro_tween = create_tween()
		_intro_tween.tween_property(_visual, "scale", Vector3(1.04, 1.04, 1.04), 0.18) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(_visual, "scale", Vector3.ONE, 0.10) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif style_id == "comic":
		_visual.scale = Vector3.ONE * 0.12
		_intro_tween = create_tween()
		_intro_tween.tween_property(_visual, "scale", Vector3.ONE * 1.18, 0.16) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(_visual, "scale", Vector3.ONE, 0.22) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		_visual.scale = Vector3.ONE * 0.72
		_intro_tween = create_tween()
		_intro_tween.tween_property(_visual, "scale", Vector3.ONE * 1.06, 0.20) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(_visual, "scale", Vector3.ONE, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_intro(delta: float) -> void:
	if not _typing:
		return
	_typed_chars += delta * 26.0
	var count := mini(int(_typed_chars), display_name.length())
	_name_label.text = display_name.substr(0, count)
	if count >= display_name.length():
		_typing = false


func _update_glitch(delta: float) -> void:
	if _glitch_time > 0.0:
		_glitch_time -= delta
		_ghost_label.visible = true
		_ghost_label.text = _name_label.text
		_visual.position.x = randf_range(-0.014, 0.014) if _ghost_label.visible else 0.0
		_name_label.position.x = _name_home.x + randf_range(-0.010, 0.010)
		return
	_ghost_label.visible = false
	_visual.position.x = 0.0
	_name_label.position.x = _name_home.x
	_glitch_timer += delta
	if _glitch_timer >= 2.4 and display_name.length() > 0:
		_glitch_timer = 0.0
		_glitch_time = 0.18


func _face_camera() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var target := cam.global_position
	if global_position.is_equal_approx(target):
		return
	look_at(target, Vector3.UP)
	# O Sprite3D/Label3D olham para +Z; `look_at` aponta -Z para a cÃ¢mera.
	rotate_object_local(Vector3.UP, PI)
