class_name BattleCamera
extends Node
## Battle camera director. The base framing (CINEMA) is a diagonal view from
## the right-rear of the party looking toward the left of the field, with a
## fixed Dutch tilt. TATICA lifts the view while a target is picked; actions
## (a run, a cast) pan the aim along the field. There is never any zoom, shake
## or animated roll. A short burst of speed lines marks strong hits.

enum Mode { CINEMA, TATICA, IMPACTO, STATUS }

signal mode_changed(mode: Mode)

const CINEMA_POS := Vector3(3.8, 2.5, 7.0)
const CINEMA_LOOK := Vector3(0.0, 2.3, -20.0)
const TATICA_POS := Vector3(3.0, 6.0, 9.5)
const FOV := 60.0
const TILT_DEG := 4.0  ## Fixed Dutch angle (counter-clockwise).
const GLIDE := 1.0

var camera: Camera3D
var mode := Mode.CINEMA

var _pos := CINEMA_POS
var _look := CINEMA_LOOK
var _fov := FOV
var _tween: Tween
var _token := 0
var _lines: SpeedLines
var _post_rect: ColorRect
var _post_mat: ShaderMaterial
var _post_tw: Tween


func setup(p_camera: Camera3D) -> void:
	camera = p_camera
	var layer := CanvasLayer.new()
	layer.layer = 0  # Above the 3D scene, below the battle UI.
	add_child(layer)
	_post_rect = ColorRect.new()
	_post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = VfxLib.shader_mat("impact_post", {
		"strength": 0.0,
		"center": Vector2(0.5, 0.45),
		"tint_color": Color(1.0, 0.9, 0.7, 1.0),
	})
	_post_rect.material = _post_mat
	layer.add_child(_post_rect)
	_post_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lines = SpeedLines.new()
	layer.add_child(_lines)
	_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply()


func _process(_delta: float) -> void:
	_apply()


## Screen-space impact post-processing (subtle chromatic aberration, radial blur
## and elemental color grade strictly during the strike frame — zero camera shake).
func impact_post(world_pos: Vector3, elem_color: Color, heavy := false) -> void:
	if _post_mat == null or camera == null or not camera.is_inside_tree():
		return
	var uv := Vector2(0.5, 0.45)
	if not camera.is_position_behind(world_pos):
		var sp := camera.unproject_position(world_pos)
		var vp := camera.get_viewport().get_visible_rect().size
		if vp.x > 1.0 and vp.y > 1.0:
			uv = Vector2(clampf(sp.x / vp.x, 0.1, 0.9), clampf(sp.y / vp.y, 0.1, 0.9))
	_post_mat.set_shader_parameter("center", uv)
	_post_mat.set_shader_parameter("tint_color", elem_color)
	var peak := 0.88 if heavy else 0.52
	_post_mat.set_shader_parameter("strength", peak)
	if _post_tw != null and _post_tw.is_valid():
		_post_tw.kill()
	_post_tw = create_tween()
	_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("strength", v), peak, 0.0, 0.24 if heavy else 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cinema(time := GLIDE) -> void:
	_go(Mode.CINEMA, CINEMA_POS, CINEMA_LOOK, time)


## High view looking toward `focus` (the highlighted target).
func tactical(focus: Vector3, time := GLIDE) -> void:
	_go(Mode.TATICA, TATICA_POS, focus.lerp(Vector3(2.0, 0.0, 0.0), 0.35), time)


## An action is happening at `look_pos`: aim there (no dolly, no zoom), then
## settle back to CINEMA. Ignored while the player is picking a target.
func action(look_pos: Vector3, hold := 1.2) -> void:
	if mode == Mode.TATICA:
		return
	_go(Mode.IMPACTO, CINEMA_POS, look_pos + Vector3(0, 1.4, 0), 0.8)
	var token := _token
	await get_tree().create_timer(hold + 0.8, false).timeout
	if token == _token:
		cinema()


## Close framing of one character for the status view. The character ends up
## on the left of the frame (the card is on the right).
func status_shot(unit_pos: Vector3, faces_party_side: bool) -> void:
	var offset := Vector3(3.0, 1.5, -5.2) if faces_party_side else Vector3(-3.0, 1.8, 6.5)
	var pos := unit_pos + offset
	var look := unit_pos + Vector3(0, 1.1, 0)
	var right := (look - pos).cross(Vector3.UP).normalized()
	_go(Mode.STATUS, pos, look + right * 1.5, 0.7, 50.0)


## Brief static speed lines around the screen (strong hits only).
func speed_lines() -> void:
	_lines.burst()


func _go(new_mode: Mode, pos: Vector3, look: Vector3, time: float, fov := FOV) -> void:
	_token += 1
	if new_mode != mode:
		mode = new_mode
		mode_changed.emit(mode)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "_pos", pos, time)
	_tween.tween_property(self, "_look", look, time)
	_tween.tween_property(self, "_fov", fov, time)


func _apply() -> void:
	if camera == null or not camera.is_inside_tree():
		return
	camera.position = _pos
	camera.look_at(_look)
	camera.rotate_object_local(Vector3.BACK, deg_to_rad(TILT_DEG))
	camera.fov = _fov


class SpeedLines extends Control:
	var _alpha := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func burst() -> void:
		_alpha = 0.55
		create_tween().tween_property(self, "_alpha", 0.0, 0.35)

	func _process(_delta: float) -> void:
		if _alpha > 0.0:
			queue_redraw()

	func _draw() -> void:
		if _alpha <= 0.0:
			return
		var center := size * 0.5
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 40:
			var ang := rng.randf() * TAU
			var dir := Vector2(cos(ang), sin(ang))
			var r_out := size.length() * 0.6
			var r_in := r_out * rng.randf_range(0.62, 0.8)
			var width := rng.randf_range(3.0, 9.0)
			var perp := Vector2(-dir.y, dir.x) * width
			draw_colored_polygon(PackedVector2Array([center + dir * r_out, center + dir * r_in + perp, center + dir * r_in - perp]), Color(1, 1, 1, _alpha))
