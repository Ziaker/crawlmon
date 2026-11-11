extends Node
## D-1134: laboratório das 4 direções da badge [Z] ATTACK.
##
## Abre o lab 3D real, esconde o HUD, enquadra o jogador e um inimigo de lado
## (Slime ou Gible) e desenha a badge ao vivo + as 4 opções. O alvo e a câmera
## vêm do mundo real (D-235); o retículo/tail são projetados na tela.
##
## Controles: 1-4 escolhe · ESPAÇO testa o Z · T estado (pronto/recarga/sem
## alvo) · G alvo (Slime/Gible) · M espelha a câmera · Esc sai.

const LAB := preload("res://scenes/debug/murky_forest_3d_lab.tscn")
const BADGE := preload("res://scripts/ui/attack_badge.gd")
const RETICLE := preload("res://scripts/ui/attack_target_reticle.gd")
const STYLE_NAMES := ["ATTACK CARD", "COMMAND STRIP", "SMT UPLINK", "Z-POW"]
const STYLE_FILES := ["A", "B", "C", "D"]
const BADGE_SIZE := Vector2(380.0, 58.0)
const BADGE_READY := 0

const AMBER := Color(1.000, 0.722, 0.278)
const CREAM := Color(0.918, 0.914, 0.851)
const MUTED := Color(0.58, 0.64, 0.67)
const AQUA := Color(0.384, 0.847, 0.906)

var _lab: Node3D
var _player: CharacterBody3D
var _target_a: Node3D
var _target_b: Node3D
var _target: Node3D
var _side_cam: Camera3D
var _badge: Control
var _options: Array[Control] = []
var _option_labels: Array[Label] = []
var _reticle: Control
var _style_label: Label
var _context_label: Label
var _live_label: Label
var _status: Label
var _style := 0
var _state := 0
var _target_index := 0
var _mirror := false
var _font_impact: Font
var _font_body: Font


func _ready() -> void:
	_font_impact = _system_font(["Impact", "Haettenschweiler", "Arial Black"], 900)
	_font_body = _system_font(["Arial", "Segoe UI"], 800)
	_lab = LAB.instantiate()
	add_child(_lab)
	await _frames(20)
	_player = _lab.get("player")
	_target_a = _lab.get("_enemy")
	_target_b = _lab.get("_second_enemy")
	if _player == null or _target_a == null:
		push_error("AttackBadgeLab: player/target missing")
		return
	_hide_lab_hud()
	_setup_target()
	_build_ui()
	# O lab fica estático para o protótipo: a câmera de lado e a badge mandam.
	_lab.set_process(false)
	_lab.set_physics_process(false)
	_lab.set_process_unhandled_input(false)
	_hide_world_labels()
	_apply_style()
	_apply_state()
	set_process(true)


func _process(_delta: float) -> void:
	if _badge == null or _side_cam == null or _target == null:
		return
	if not is_instance_valid(_target):
		return
	var focus_y := clampf(_actor_visual_top(_target) * 0.75, 0.45, 1.8)
	var top := _target.global_position + Vector3.UP * focus_y
	var screen := _side_cam.unproject_position(top)
	var valid := not _side_cam.is_position_behind(top)
	_badge.set_target_screen(screen, valid)
	if _reticle != null:
		_reticle.set_target(screen, _style == 2 and valid and _state == 0)
	_update_context()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	match key:
		KEY_1:
			set_preview_style(0)
		KEY_2:
			set_preview_style(1)
		KEY_3:
			set_preview_style(2)
		KEY_4:
			set_preview_style(3)
		KEY_SPACE:
			press_preview()
		KEY_T:
			set_preview_state((_state + 1) % 3)
		KEY_G:
			_switch_target()
		KEY_M:
			_mirror = not _mirror
			_setup_target()
		KEY_ESCAPE:
			get_tree().quit()


func set_preview_style(p_style: int) -> void:
	_style = clampi(p_style, 0, 3)
	if _badge != null:
		_badge.set_style(_style)
	for i in _options.size():
		_options[i].set_style(i)
		if i < _option_labels.size():
			_option_labels[i].text = "%s%d  %s" % ["▶ " if i == _style else "   ", i + 1, STYLE_NAMES[i]]
			_option_labels[i].add_theme_color_override("font_color", AMBER if i == _style else MUTED)
	if _style_label != null:
		_style_label.text = "%d · %s" % [_style + 1, STYLE_NAMES[_style]]
	if _reticle != null:
		_reticle.active = _style == 2 and _state == 0
	_update_context()


func set_preview_state(p_state: int) -> void:
	_state = clampi(p_state, 0, 2)
	if _badge != null:
		_badge.set_context(_target_name(), _distance(), _state, 0.55 if _state == 1 else 0.0)
	if _reticle != null:
		_reticle.active = _style == 2 and _state == 0
	_update_context()


func press_preview() -> void:
	if _badge == null:
		return
	_badge.play_press()
	if _status != null:
		_status.text = "Z TESTADO"
		var tw := create_tween()
		tw.tween_interval(0.45)
		tw.tween_callback(func() -> void:
			if _status != null:
				_status.text = "")


func set_preview_target(p_index: int) -> void:
	_target_index = posmod(p_index, 2)
	_setup_target()


func set_preview_mirror(p_mirror: bool) -> void:
	_mirror = p_mirror
	_setup_target()


func _switch_target() -> void:
	_target_index = 1 - _target_index
	_setup_target()


func _setup_target() -> void:
	_target = _target_a if _target_index == 0 else _target_b
	if _target == null:
		return
	_player.global_position = _target.global_position + Vector3(0.0, 0.0, 3.0)
	_player.velocity = Vector3.ZERO
	var to_target := _target.global_position - _player.global_position
	to_target.y = 0.0
	var yaw := atan2(to_target.x, to_target.z)
	_lab.set("player_yaw", yaw)
	_player.rotation.y = yaw
	var mid := (_player.global_position + _target.global_position) * 0.5
	var flat := to_target.normalized()
	var side := Vector3(-flat.z, 0.0, flat.x) * (-1.0 if _mirror else 1.0)
	if _side_cam == null:
		_side_cam = Camera3D.new()
		_side_cam.fov = 55.0
		_side_cam.near = 0.05
		_lab.add_child(_side_cam)
	_side_cam.global_position = mid + side * 4.6 + Vector3(0.0, 2.0, 0.0)
	_side_cam.look_at(mid + Vector3(0.0, 0.15, 0.0), Vector3.UP)
	_side_cam.h_offset = 0.9
	_side_cam.current = true
	_update_context()


func _target_name() -> String:
	return "SLIME" if _target_index == 0 else "GIBLE"


func _distance() -> float:
	if _player == null or _target == null:
		return 0.0
	return _player.global_position.distance_to(_target.global_position)


func _actor_visual_top(node: Node3D) -> float:
	# D-235: a altura vem do modelo real do alvo, nunca de uma constante por
	# personagem; funciona para Slime, Gible ou qualquer ator.
	var top := 0.0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var box := mi.global_transform * mi.mesh.get_aabb()
		top = maxf(top, box.position.y + box.size.y - node.global_position.y)
	return top


func _state_name() -> String:
	match _state:
		0:
			return "PRONTO"
		1:
			return "RECARGA"
		_:
			return "SEM ALVO"


func _update_context() -> void:
	if _badge != null:
		_badge.set_context(_target_name(), _distance(), _state, 0.55 if _state == 1 else 0.0)
	if _context_label != null:
		if _state == 2:
			_context_label.text = "DEMO DE ESTADO  ·  SEM ALVO"
		else:
			_context_label.text = "ALVO: %s  ·  %.1f m  ·  %s" % [_target_name(), _distance(), _state_name()]
	for mini in _options:
		if mini != null:
			mini.set_context(_target_name(), _distance(), BADGE_READY)


func _apply_style() -> void:
	set_preview_style(_style)


func _apply_state() -> void:
	set_preview_state(_state)


func _hide_lab_hud() -> void:
	for child in _lab.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	var hud := _lab.get_node_or_null("ExplorationBattleHud")
	if hud != null:
		hud.set_process(false)
		for child in hud.get_children():
			if child is CanvasLayer:
				(child as CanvasLayer).visible = false


func _hide_world_labels() -> void:
	# O protótipo é sobre a badge: placas e ícones de estado do lab saem do
	# quadro para não competir com a leitura. Os atores e os anéis ficam.
	for entry in _lab.get("_name_labels"):
		var plate := entry.get("node") as Node3D
		if plate != null and is_instance_valid(plate):
			plate.visible = false
	for entry in _lab.get("_state_icons"):
		var icon := entry.get("sprite") as Node3D
		if icon != null and is_instance_valid(icon):
			icon.visible = false


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	add_child(canvas)
	var root := Control.new()
	root.name = "BadgeLabUI"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	_reticle = RETICLE.new()
	root.add_child(_reticle)

	var header_bg := ColorRect.new()
	header_bg.position = Vector2(760.0, 10.0)
	header_bg.size = Vector2(500.0, 70.0)
	header_bg.color = Color(0.02, 0.03, 0.05, 0.50)
	header_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header_bg)

	var options_bg := ColorRect.new()
	options_bg.position = Vector2(872.0, 88.0)
	options_bg.size = Vector2(396.0, 330.0)
	options_bg.color = Color(0.02, 0.03, 0.05, 0.55)
	options_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(options_bg)

	var title := Label.new()
	title.text = "ATTACK BADGE — 4 DIREÇÕES"
	title.position = Vector2(30.0, 18.0)
	title.add_theme_font_override("font", _font_impact)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CREAM)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "protótipo D-1134  ·  [Z] ATTACK  ·  identidade D-1074 / D-1094"
	sub.position = Vector2(32.0, 54.0)
	sub.add_theme_font_override("font", _font_body)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", MUTED)
	root.add_child(sub)

	_style_label = Label.new()
	_style_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label.position = Vector2(800.0, 22.0)
	_style_label.size = Vector2(448.0, 26.0)
	_style_label.add_theme_font_override("font", _font_impact)
	_style_label.add_theme_font_size_override("font_size", 20)
	_style_label.add_theme_color_override("font_color", AMBER)
	root.add_child(_style_label)

	_context_label = Label.new()
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_context_label.position = Vector2(740.0, 52.0)
	_context_label.size = Vector2(508.0, 22.0)
	_context_label.add_theme_font_override("font", _font_body)
	_context_label.add_theme_font_size_override("font_size", 12)
	_context_label.add_theme_color_override("font_color", AQUA)
	root.add_child(_context_label)

	_live_label = Label.new()
	_live_label.text = "AO VIVO"
	_live_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_live_label.position = Vector2(193.0, 520.0)
	_live_label.size = Vector2(220.0, 18.0)
	_live_label.add_theme_font_override("font", _font_body)
	_live_label.add_theme_font_size_override("font_size", 10)
	_live_label.add_theme_color_override("font_color", MUTED)
	root.add_child(_live_label)

	_badge = BADGE.new()
	_badge.set_style(_style)
	_badge.set_context(_target_name(), _distance(), BADGE_READY)
	_badge.scale = Vector2(1.3, 1.3)
	_badge.pivot_offset = BADGE_SIZE * 0.5
	_badge.position = Vector2(250.0, 570.0)
	_badge.badge_pressed.connect(_on_badge_pressed)
	root.add_child(_badge)

	var grid := VBoxContainer.new()
	grid.position = Vector2(884.0, 96.0)
	grid.add_theme_constant_override("separation", 6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(grid)
	for i in 4:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(380.0, 74.0)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 2)
		grid.add_child(box)
		var label := Label.new()
		label.text = "%s%d  %s" % ["▶ " if i == _style else "   ", i + 1, STYLE_NAMES[i]]
		label.add_theme_font_override("font", _font_body)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", AMBER if i == _style else MUTED)
		box.add_child(label)
		var mini := BADGE.new()
		mini.set_style(i)
		mini.set_context(_target_name(), _distance(), BADGE_READY)
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(mini)
		_options.append(mini)
		_option_labels.append(label)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.position = Vector2(250.0, 652.0)
	_status.size = Vector2(500.0, 18.0)
	_status.add_theme_font_override("font", _font_impact)
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", AMBER)
	root.add_child(_status)

	var hint := Label.new()
	hint.text = "1–4 escolhe  ·  ESPAÇO testa o Z  ·  T estado  ·  G alvo (Slime/Gible)  ·  M espelha  ·  Esc sai"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(140.0, 690.0)
	hint.size = Vector2(1000.0, 18.0)
	hint.add_theme_font_override("font", _font_body)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", MUTED)
	root.add_child(hint)


func _on_badge_pressed() -> void:
	pass


func _system_font(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	return f


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
