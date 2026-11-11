extends Node
## Laboratório de game feel do ataque: 3 overhauls completos.
##
## 1 SNAP & IMPACT · 2 DUELISTA · 3 COMIC CRASH
## Z ou Espaço ataca · 1/2/3 troca · Esc sai.
##
## O lab real é congelado; o ataque é uma sequência própria (input, avanço,
## hit-stop, impacto, recuperação) para comparar o feel sem iniciar batalha.

const LAB := preload("res://scenes/debug/murky_forest_3d_lab.tscn")
const IMPACT_FX := preload("res://scripts/ui/attack_impact_fx.gd")

const AMBER := Color(1.000, 0.722, 0.278)
const CREAM := Color(0.918, 0.914, 0.851)
const MUTED := Color(0.58, 0.64, 0.67)
const CYAN := Color(0.220, 0.741, 0.973)
const CORAL := Color(1.000, 0.384, 0.310)
const INK := Color(0.031, 0.031, 0.039)

const PROFILES := [
	{
		"name": "SNAP & IMPACT",
		"windup": 0.03, "lunge": 0.12, "hitstop": 0.07, "recover": 0.18,
		"knock": 0.22, "shake": 0.055, "fov": 46.0, "flash": 0.11,
		"comic": false, "color": AMBER, "pullback": 0.05, "squash": 0.035,
		"anim_start": 0.00, "anim_speed": 4.6,
	},
	{
		"name": "DUELISTA",
		"windup": 0.09, "lunge": 0.16, "hitstop": 0.06, "recover": 0.30,
		"knock": 0.16, "shake": 0.035, "fov": 48.0, "flash": 0.07,
		"comic": false, "color": CYAN, "pullback": 0.10, "squash": 0.06,
		"anim_start": 0.00, "anim_speed": 3.4,
	},
	{
		"name": "COMIC CRASH",
		"windup": 0.14, "lunge": 0.10, "hitstop": 0.13, "recover": 0.38,
		"knock": 0.44, "shake": 0.090, "fov": 44.0, "flash": 0.18,
		"comic": true, "color": CORAL, "pullback": 0.16, "squash": 0.10,
		"anim_start": 0.00, "anim_speed": 2.8,
	},
]

enum Phase { IDLE, WINDUP, LUNGE, HITSTOP, RECOVER, RESET }

var _lab: Node3D
var _player: CharacterBody3D
var _target: Node3D
var _camera: Camera3D
var _player_ap: AnimationPlayer
var _fx: Control
var _flash: ColorRect
var _profile := 0
var _phase := Phase.IDLE
var _clock := 0.0
var _dir := Vector3.FORWARD
var _side := Vector3.RIGHT
var _player_home := Vector3.ZERO
var _target_home := Vector3.ZERO
var _target_scale := Vector3.ONE
var _lunge_end := Vector3.ZERO
var _cam_base_pos := Vector3.ZERO
var _cam_base_look := Vector3.ZERO
var _cam_attack_pos := Vector3.ZERO
var _cam_attack_look := Vector3.ZERO
var _base_fov := 50.0
var _cam_blend := 0.0
var _shake_time := 0.0
var _shake_amp := 0.0
var _rng := RandomNumberGenerator.new()
var _font_impact: Font
var _font_body: Font
var _mode_labels: Array[Label] = []
var _mode_lines: Array[ColorRect] = []
var _timing_label: Label
var _phase_label: Label
var _status_label: Label


func _ready() -> void:
	_font_impact = _system_font(["Impact", "Haettenschweiler", "Arial Black"], 900)
	_font_body = _system_font(["Arial", "Segoe UI"], 800)
	_rng.seed = 3111
	_lab = LAB.instantiate()
	add_child(_lab)
	await _frames(30)
	_player = _lab.get("player")
	_target = _lab.get("_enemy")
	if _player == null or _target == null:
		push_error("AttackOverhaulLab: player/target missing")
		return
	_setup_stage()
	_build_ui()
	_select_profile(0)
	set_process(true)


func _setup_stage() -> void:
	_hide_lab_hud()
	_freeze_world()
	_hide_world_labels()
	_target_home = _target.global_position
	_target_scale = _target.scale
	_player_home = _target_home + Vector3(0.0, 0.0, 2.4)
	_player.global_position = _player_home
	_player.velocity = Vector3.ZERO
	_dir = _target_home - _player_home
	_dir.y = 0.0
	_dir = _dir.normalized()
	_side = Vector3(-_dir.z, 0.0, _dir.x)
	_player.rotation.y = atan2(_dir.x, _dir.z)
	var mid := (_player_home + _target_home) * 0.5
	_cam_base_pos = mid + _side * 4.8 - _dir * 1.0 + Vector3(0.0, 2.1, 0.0)
	_cam_base_look = mid + Vector3(0.0, 0.75, 0.0)
	_cam_attack_pos = _cam_base_pos - _dir * 0.35 + _side * 0.15 + Vector3(0.0, 0.05, 0.0)
	_cam_attack_look = mid + Vector3(0.0, 0.8, 0.0)
	_camera = Camera3D.new()
	_camera.name = "OverhaulCam"
	_camera.fov = _base_fov
	_camera.near = 0.05
	_lab.add_child(_camera)
	_camera.global_position = _cam_base_pos
	_camera.look_at(_cam_base_look, Vector3.UP)
	_camera.current = true
	_lunge_end = _player_home + _dir * maxf(0.0, _player_home.distance_to(_target_home) - 1.05)


func _freeze_world() -> void:
	_lab.set_process(false)
	_lab.set_physics_process(false)
	_lab.set_process_unhandled_input(false)
	var controller := _lab.get("_attack_controller") as Node
	if controller != null:
		controller.set_process(false)
		controller.set_physics_process(false)
	for body in _lab.find_children("*", "CharacterBody3D", true, false):
		(body as CharacterBody3D).set_process(false)
		(body as CharacterBody3D).set_physics_process(false)
	for ap in _lab.find_children("*", "AnimationPlayer", true, false):
		(ap as AnimationPlayer).stop()
	for child in _player.find_children("*", "AnimationPlayer", true, false):
		var ap := child as AnimationPlayer
		if ap != null and ap.has_animation("attack"):
			_player_ap = ap
			break


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
		if plate != null:
			plate.visible = false
	for entry in _lab.get("_state_icons"):
		var icon := entry.get("sprite") as Node3D
		if icon != null:
			icon.visible = false
	for entry in _lab.get("_marker_rings"):
		var mesh := entry.get("mesh") as Node3D
		if mesh != null:
			mesh.visible = false


func _process(delta: float) -> void:
	_update_shake(delta)
	if _phase == Phase.IDLE:
		_apply_camera(0.0)
		return
	var p: Dictionary = PROFILES[_profile]
	_clock += delta
	match _phase:
		Phase.WINDUP:
			var t := clampf(_clock / float(p["windup"]), 0.0, 1.0)
			var e := t * t
			_player.global_position = _player_home - _dir * (float(p["pullback"]) * e)
			_player.scale = Vector3(1.0 + float(p["squash"]) * e, 1.0 - float(p["squash"]) * e, 1.0 + float(p["squash"]) * e)
			_cam_blend = t * 0.55
			_update_phase_label("WIND-UP")
			if _clock >= float(p["windup"]):
				_phase = Phase.LUNGE
				_clock = 0.0
				_player.scale = Vector3.ONE
		Phase.LUNGE:
			var t := clampf(_clock / float(p["lunge"]), 0.0, 1.0)
			var e := 1.0 - pow(1.0 - t, 3.0)
			_player.global_position = _player_home.lerp(_lunge_end, e)
			_cam_blend = lerpf(0.55, 1.0, t)
			_update_phase_label("AVANÇO")
			if _clock >= float(p["lunge"]):
				_impact()
		Phase.HITSTOP:
			_update_phase_label("IMPACTO - HIT-STOP")
			if _clock >= float(p["hitstop"]):
				_phase = Phase.RECOVER
				_clock = 0.0
				if _player_ap != null:
					_player_ap.speed_scale = 1.3
		Phase.RECOVER:
			_update_phase_label("RECUPERAÇÃO")
			_cam_blend = maxf(0.0, 1.0 - _clock / maxf(0.01, float(p["recover"])))
			if _clock >= float(p["recover"]):
				_start_reset()
		Phase.RESET:
			_cam_blend = maxf(0.0, 1.0 - _clock / 0.55)
			if _clock >= 0.55:
				_finish_reset()
	_apply_camera(_cam_blend)


func _start_attack() -> void:
	if _phase != Phase.IDLE:
		return
	var p: Dictionary = PROFILES[_profile]
	_clock = 0.0
	_cam_blend = 0.0
	_phase = Phase.WINDUP
	_status_label.text = "ATACANDO"
	_update_phase_label("INPUT ACK · WIND-UP")
	_play_attack_anim(p)


func _impact() -> void:
	_phase = Phase.HITSTOP
	_clock = 0.0
	var p: Dictionary = PROFILES[_profile]
	_player.global_position = _lunge_end
	_player.scale = Vector3(1.05, 0.92, 1.05)
	_cam_blend = 1.0
	if _player_ap != null:
		_player_ap.speed_scale = 0.0
	# alvo reage
	var knock := float(p["knock"])
	var squash := _target_scale * Vector3(1.12, 0.82, 1.12)
	var tw := create_tween()
	tw.tween_property(_target, "global_position", _target_home + _dir * knock, 0.07)
	tw.parallel().tween_property(_target, "scale", squash, 0.07)
	tw.tween_property(_target, "global_position", _target_home, 0.36)
	tw.parallel().tween_property(_target, "scale", _target_scale, 0.36)
	var pw := create_tween()
	pw.tween_property(_player, "scale", Vector3.ONE, 0.18)
	# leitura do impacto
	var world := _target_home + Vector3.UP * 0.35
	var screen := _camera.unproject_position(world)
	_fx.call("play", screen, 0.85 if not bool(p["comic"]) else 1.2, bool(p["comic"]), p["color"])
	_flash.color = Color(1.0, 0.96, 0.86, float(p["flash"]))
	var fw := create_tween()
	fw.tween_property(_flash, "color:a", 0.0, 0.18)
	_shake_time = 0.18
	_shake_amp = float(p["shake"])
	_status_label.text = "IMPACTO"
	_update_phase_label("IMPACTO - HIT-STOP")


func _start_reset() -> void:
	_phase = Phase.RESET
	_clock = 0.0
	if _player_ap != null:
		_player_ap.stop()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_player, "global_position", _player_home, 0.28)
	tw.tween_property(_player, "scale", Vector3.ONE, 0.15)
	tw.tween_property(_target, "global_position", _target_home, 0.28)
	tw.tween_property(_target, "scale", _target_scale, 0.28)
	_update_phase_label("RESET")


func _finish_reset() -> void:
	_phase = Phase.IDLE
	_clock = 0.0
	_cam_blend = 0.0
	_player.global_position = _player_home
	_player.scale = Vector3.ONE
	_target.global_position = _target_home
	_target.scale = _target_scale
	_status_label.text = "PRONTO"


func _play_attack_anim(p: Dictionary) -> void:
	if _player_ap == null:
		return
	var anim := _player_ap.get_animation("attack")
	if anim == null:
		return
	_player_ap.play("attack")
	_player_ap.seek(minf(float(p["anim_start"]), maxf(0.0, anim.length - 0.02)), true)
	_player_ap.speed_scale = float(p["anim_speed"])


func _apply_camera(blend: float) -> void:
	if _camera == null:
		return
	var pos := _cam_base_pos.lerp(_cam_attack_pos, blend)
	var look := _cam_base_look.lerp(_cam_attack_look, blend)
	if _shake_time > 0.0:
		pos += Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), 0.0) * _shake_amp
	_camera.global_position = pos
	_camera.look_at(look, Vector3.UP)
	var p: Dictionary = PROFILES[_profile]
	_camera.fov = lerpf(_base_fov, float(p["fov"]), blend)


func _update_shake(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time = maxf(0.0, _shake_time - delta)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1:
			_select_profile(0)
		KEY_2:
			_select_profile(1)
		KEY_3:
			_select_profile(2)
		KEY_Z, KEY_SPACE:
			_start_attack()
		KEY_ESCAPE:
			get_tree().quit()


func _select_profile(index: int) -> void:
	_profile = clampi(index, 0, 2)
	for i in _mode_labels.size():
		var active := i == _profile
		_mode_labels[i].add_theme_color_override("font_color", _profile_color(i) if active else MUTED)
		_mode_lines[i].visible = active
	var p: Dictionary = PROFILES[_profile]
	var impact_ms := int(round((float(p["windup"]) + float(p["lunge"])) * 1000.0))
	_timing_label.text = "IMPACTO %d ms  ·  HIT-STOP %d ms  ·  RECUPERAÇÃO %d ms" % [
		impact_ms, int(round(float(p["hitstop"]) * 1000.0)),
		int(round(float(p["recover"]) * 1000.0))]
	_status_label.text = "PRONTO"
	_update_phase_label("PRONTO")


func _profile_color(index: int) -> Color:
	match index:
		0:
			return AMBER
		1:
			return CYAN
		_:
			return CORAL


func _update_phase_label(text: String) -> void:
	if _phase_label != null:
		_phase_label.text = "FASE  ·  " + text


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	add_child(canvas)
	var root := Control.new()
	root.name = "OverhaulUI"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.96, 0.86, 0.0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)

	_fx = IMPACT_FX.new()
	root.add_child(_fx)

	var title := Label.new()
	title.text = "ATAQUE — 3 OVERHAULS"
	title.position = Vector2(30.0, 18.0)
	title.add_theme_font_override("font", _font_impact)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CREAM)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "input → avanço → impacto → recuperação  ·  sem batalha no protótipo"
	sub.position = Vector2(32.0, 54.0)
	sub.add_theme_font_override("font", _font_body)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", MUTED)
	root.add_child(sub)

	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase_label.position = Vector2(760.0, 22.0)
	_phase_label.size = Vector2(490.0, 24.0)
	_phase_label.add_theme_font_override("font", _font_impact)
	_phase_label.add_theme_font_size_override("font_size", 18)
	_phase_label.add_theme_color_override("font_color", AMBER)
	root.add_child(_phase_label)

	_timing_label = Label.new()
	_timing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timing_label.position = Vector2(620.0, 50.0)
	_timing_label.size = Vector2(630.0, 20.0)
	_timing_label.add_theme_font_override("font", _font_body)
	_timing_label.add_theme_font_size_override("font_size", 11)
	_timing_label.add_theme_color_override("font_color", MUTED)
	root.add_child(_timing_label)

	var strip := HBoxContainer.new()
	strip.position = Vector2(250.0, 648.0)
	strip.add_theme_constant_override("separation", 36)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(strip)
	for i in 3:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(box)
		var label := Label.new()
		label.text = "%d  %s" % [i + 1, str(PROFILES[i]["name"])]
		label.add_theme_font_override("font", _font_impact)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", MUTED)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
		box.add_child(label)
		var line := ColorRect.new()
		line.color = _profile_color(i)
		line.custom_minimum_size = Vector2(0.0, 2.0)
		line.visible = false
		box.add_child(line)
		_mode_labels.append(label)
		_mode_lines.append(line)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.position = Vector2(390.0, 684.0)
	_status_label.size = Vector2(500.0, 18.0)
	_status_label.add_theme_font_override("font", _font_impact)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", CREAM)
	root.add_child(_status_label)

	var hint := Label.new()
	hint.text = "Z / ESPAÇO ataca  ·  1/2/3 troca  ·  Esc sai"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(300.0, 704.0)
	hint.size = Vector2(680.0, 14.0)
	hint.add_theme_font_override("font", _font_body)
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", MUTED)
	root.add_child(hint)


func _system_font(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	return f


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
