extends Node
## Laboratório dos 4 conceitos de HUD de ataque SEM bloco.
##
## 1 MIRA  · 2 SELO  · 3 GLIFO  · 4 FITA
## ESPAÇO testa o Z · T estado (pronto/recarga) · G alvo · M espelha.
##
## O alvo, o jogador e a câmera são os do lab 3D real; nada é projetado por
## coordenada fixa de personagem, time ou lado.

const LAB := preload("res://scenes/debug/murky_forest_3d_lab.tscn")
const HUD := preload("res://scripts/ui/attack_hud.gd")
const MODE_NAMES := ["MIRA", "SELO", "GLIFO", "FITA"]

const AMBER := Color(1.000, 0.722, 0.278)
const CREAM := Color(0.918, 0.914, 0.851)
const MUTED := Color(0.58, 0.64, 0.67)
const AQUA := Color(0.384, 0.847, 0.906)
const CORAL := Color(1.000, 0.384, 0.310)

var _lab: Node3D
var _player: CharacterBody3D
var _target_a: Node3D
var _target_b: Node3D
var _target: Node3D
var _side_cam: Camera3D
var _hud: Control
var _mode := 2
var _state := 0
var _target_index := 0
var _mirror := false
var _mode_labels: Array[Label] = []
var _mode_underlines: Array[ColorRect] = []
var _mode_title: Label
var _context_label: Label
var _status: Label
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
		push_error("AttackHudLab: player/target missing")
		return
	_hide_lab_hud()
	_setup_target()
	_build_ui()
	_lab.set_process(false)
	_lab.set_physics_process(false)
	_lab.set_process_unhandled_input(false)
	_hide_world_labels()
	_freeze_actor(_player)
	_freeze_actor(_target_a)
	_freeze_actor(_target_b)
	_apply_mode()
	_apply_state()
	set_process(true)


func _process(_delta: float) -> void:
	if _hud == null or _side_cam == null or _target == null:
		return
	if not is_instance_valid(_target):
		return
	_hud.call("set_projection", _side_cam, _player, _target)
	_update_context()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1:
			set_preview_mode(0)
		KEY_2:
			set_preview_mode(1)
		KEY_3:
			set_preview_mode(2)
		KEY_4:
			set_preview_mode(3)
		KEY_SPACE:
			press_preview()
		KEY_T:
			set_preview_state((_state + 1) % 2)
		KEY_G:
			_switch_target()
		KEY_M:
			_mirror = not _mirror
			_setup_target()
		KEY_ESCAPE:
			get_tree().quit()


func set_preview_mode(p_mode: int) -> void:
	_mode = clampi(p_mode, 0, 3)
	if _hud != null:
		_hud.call("set_mode", _mode)
	for i in _mode_labels.size():
		var active := i == _mode
		_mode_labels[i].add_theme_color_override("font_color", AMBER if active else MUTED)
		_mode_underlines[i].visible = active
	if _mode_title != null:
		_mode_title.text = "%d · %s" % [_mode + 1, MODE_NAMES[_mode]]
	_update_context()


func set_preview_state(p_state: int) -> void:
	_state = clampi(p_state, 0, 1)
	if _hud != null:
		_hud.call("set_context", _target_name(), _distance(), _state, 0.55 if _state == 1 else 0.0)
	_update_context()


func press_preview() -> void:
	if _hud == null:
		return
	_hud.call("play_press")
	if _status != null:
		_status.text = "Z TESTADO"
		var tw := create_tween()
		tw.tween_interval(0.5)
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
	if _hud != null:
		_hud.call("set_projection", _side_cam, _player, _target)
	_update_context()


func _target_name() -> String:
	return "SLIME" if _target_index == 0 else "GIBLE"


func _distance() -> float:
	if _player == null or _target == null:
		return 0.0
	return _player.global_position.distance_to(_target.global_position)


func _state_name() -> String:
	return "RECARGA" if _state == 1 else "PRONTO"


func _update_context() -> void:
	if _hud != null:
		_hud.call("set_context", _target_name(), _distance(), _state, 0.55 if _state == 1 else 0.0)
	if _context_label != null:
		_context_label.text = "ALVO: %s  ·  %.1f m  ·  %s" % [_target_name(), _distance(), _state_name()]


func _apply_mode() -> void:
	set_preview_mode(_mode)


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
	for entry in _lab.get("_name_labels"):
		var plate := entry.get("node") as Node3D
		if plate != null and is_instance_valid(plate):
			plate.visible = false
	for entry in _lab.get("_state_icons"):
		var icon := entry.get("sprite") as Node3D
		if icon != null and is_instance_valid(icon):
			icon.visible = false
	for entry in _lab.get("_marker_rings"):
		var mesh := entry.get("mesh") as Node3D
		if mesh != null and is_instance_valid(mesh):
			mesh.visible = false


func _freeze_actor(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.find_children("*", "AnimationPlayer", true, false):
		var ap := child as AnimationPlayer
		if ap == null:
			continue
		ap.stop()
		ap.seek(0.0, true)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	add_child(canvas)
	var root := Control.new()
	root.name = "AttackHudLabUI"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	_hud = HUD.new()
	_hud.call("set_mode", _mode)
	_hud.call("set_context", _target_name(), _distance(), _state)
	_hud.call("set_projection", _side_cam, _player, _target)
	root.add_child(_hud)

	var title := Label.new()
	title.text = "Z HUD — 4 CONCEITOS"
	title.position = Vector2(30.0, 18.0)
	title.add_theme_font_override("font", _font_impact)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CREAM)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "sem placa  ·  o Z vive no alvo, no jogador ou entre os dois"
	sub.position = Vector2(32.0, 54.0)
	sub.add_theme_font_override("font", _font_body)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", MUTED)
	root.add_child(sub)

	_mode_title = Label.new()
	_mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mode_title.position = Vector2(800.0, 22.0)
	_mode_title.size = Vector2(448.0, 26.0)
	_mode_title.add_theme_font_override("font", _font_impact)
	_mode_title.add_theme_font_size_override("font_size", 22)
	_mode_title.add_theme_color_override("font_color", AMBER)
	root.add_child(_mode_title)

	_context_label = Label.new()
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_context_label.position = Vector2(740.0, 52.0)
	_context_label.size = Vector2(508.0, 22.0)
	_context_label.add_theme_font_override("font", _font_body)
	_context_label.add_theme_font_size_override("font_size", 12)
	_context_label.add_theme_color_override("font_color", AQUA)
	root.add_child(_context_label)

	# Seletor só de texto, sem cards: uma linha e um sublinhado no ativo.
	var strip := HBoxContainer.new()
	strip.position = Vector2(300.0, 648.0)
	strip.add_theme_constant_override("separation", 34)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(strip)
	for i in 4:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(box)
		var label := Label.new()
		label.text = "%d  %s" % [i + 1, MODE_NAMES[i]]
		label.add_theme_font_override("font", _font_impact)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", AMBER if i == _mode else MUTED)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
		var line := ColorRect.new()
		line.color = AMBER
		line.custom_minimum_size = Vector2(0.0, 2.0)
		line.visible = i == _mode
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(line)
		_mode_labels.append(label)
		_mode_underlines.append(line)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.position = Vector2(390.0, 674.0)
	_status.size = Vector2(500.0, 16.0)
	_status.add_theme_font_override("font", _font_impact)
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", AMBER)
	root.add_child(_status)

	var hint := Label.new()
	hint.text = "1–4 conceito  ·  ESPAÇO testa o Z  ·  T estado  ·  G alvo  ·  M espelha  ·  Esc sai"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(200.0, 694.0)
	hint.size = Vector2(880.0, 18.0)
	hint.add_theme_font_override("font", _font_body)
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", MUTED)
	hint.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(hint)


func _system_font(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	return f


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
