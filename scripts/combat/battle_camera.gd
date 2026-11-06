class_name BattleCamera
extends Node
## Battle camera director. The base framing (CINEMA) is a diagonal view from
## the right-rear of the party looking toward the left of the field, with a
## fixed Dutch tilt. TATICA lifts the view while a target is picked; actions
## (a run, a cast) pan the aim along the field. There is never any zoom, shake
## or animated roll. A short burst of speed lines marks strong hits.

enum Mode { CINEMA, TATICA, IMPACTO, STATUS }
## D-015 experiment (debug toggle): how the framing keeps every living enemy in view.
enum FrameMode { OFF, SMOOTH, DEADZONE }

signal mode_changed(mode: Mode)

const CINEMA_POS := Vector3(3.8, 2.875, 7.0)
const CINEMA_LOOK := Vector3(-2.0, 0.0, -20.0)
const TATICA_POS := Vector3(3.0, 6.0, 9.5)
const FOV := 80.0
const TILT_DEG := 4.0  ## Fixed Dutch angle (counter-clockwise).
const GLIDE := 1.0

## Framing (D-015): a safe border no living enemy may cross, as a share of the screen.
const FRAME_MARGIN := 0.06
const FRAME_DEADZONE := 0.10  ## Extra border before the DEADZONE framing reacts (hysteresis).
const FRAME_MAX_STEP := 0.30  ## Radians a single containment step may turn (avoids flipping).
const FRAME_FOLLOW := 9.0  ## SMOOTH: how fast the framing follows the enemies (1/s).
const FRAME_SNAP := 16.0  ## DEADZONE: how fast it settles after an enemy crosses the border.

var camera: Camera3D
var mode := Mode.CINEMA

## Debug toggles only (keys K/L/M in the battle debug panel). The shipped default
## stays exactly the framing of D-020 (fixed, no zoom, no shake).
var frame_mode := FrameMode.OFF
var react_in_tactica := false
var leader_priority := false

var _pos := CINEMA_POS
var _look := CINEMA_LOOK
var _fov := FOV
var _tween: Tween
var _token := 0
var _frame_points := Callable()  ## Provided by the battle scene: living enemies' torso points.
var _frame_offset := Vector3.ZERO  ## Shift the framing adds to the mode's own aim.
var _frame_active := false  ## DEADZONE: currently reacting to a crossing.
var _tactica_focus := Vector3.ZERO
var _has_tactica_focus := false
var _prio_until := 0
var _prio_weight := 0
var _lines: SpeedLines

# D-049: Epic K.O. directional trauma shake and FOV punch
var _shake_trauma := 0.0
var _shake_decay := 3.0
var _shake_dir := Vector3.ZERO
var _fov_kick := 0.0
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
		"monochrome": 0.0,
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


func _process(delta: float) -> void:
	_apply(delta)


## Screen-space impact post-processing (subtle chromatic aberration, radial blur
## and elemental color grade strictly during the strike frame — zero camera shake).
func impact_post(world_pos: Vector3, elem_color: Color, heavy := false, monochrome_pulse := false) -> void:
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
	_post_mat.set_shader_parameter("monochrome", 1.0 if monochrome_pulse else 0.0)
	if _post_tw != null and _post_tw.is_valid():
		_post_tw.kill()
	_post_tw = create_tween().set_parallel(true)
	_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("strength", v), peak, 0.0, 0.24 if heavy else 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if monochrome_pulse:
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("monochrome", v), 1.0, 0.0, 0.045)


## Tactical time-dilation screen tone during menu decision slow-motion (D-047).
func set_decision_slowmo(active: bool) -> void:
	if _post_mat == null or camera == null or not camera.is_inside_tree():
		return
	if _post_tw != null and _post_tw.is_valid():
		_post_tw.kill()
	_post_tw = create_tween().set_parallel(true)
	if active:
		_post_mat.set_shader_parameter("center", Vector2(0.5, 0.46))
		_post_mat.set_shader_parameter("tint_color", Color("70d6ff"))
		_post_mat.set_shader_parameter("monochrome", 0.18)
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("strength", v), float(_post_mat.get_shader_parameter("strength")), 0.22, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("strength", v), float(_post_mat.get_shader_parameter("strength")), 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("monochrome", v), float(_post_mat.get_shader_parameter("monochrome")), 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cinema(time := GLIDE) -> void:
	_go(Mode.CINEMA, CINEMA_POS, CINEMA_LOOK, time)


## High view looking toward `focus` (the highlighted target).
func tactical(focus: Vector3, time := GLIDE) -> void:
	_tactica_focus = focus
	_has_tactica_focus = true
	_go(Mode.TATICA, TATICA_POS, focus.lerp(Vector3(2.0, 0.0, 0.0), 0.35), time)


## An action is happening at `look_pos`: aim there (no dolly, no zoom), then
## settle back to CINEMA. Ignored while the player is picking a target, unless
## the debug toggle `react_in_tactica` is on (D-015 test): the high view then
## leans toward the action and returns to the highlighted target.
func action(look_pos: Vector3, hold := 1.2, weight := 1) -> void:
	if leader_priority:
		var now := Time.get_ticks_msec()
		if now < _prio_until and weight < _prio_weight:
			return  # A hit on the leader keeps the camera until its framing ends.
		_prio_weight = weight
		_prio_until = now + int((hold + 1.0) * 1000.0)
	if mode == Mode.TATICA:
		if not react_in_tactica:
			return
		var focus := _tactica_focus if _has_tactica_focus else look_pos
		_go(Mode.TATICA, TATICA_POS, focus.lerp(look_pos, 0.45) + Vector3(0, 1.4, 0), 0.45)
		var tok_t := _token
		await get_tree().create_timer(hold + 0.6, false).timeout
		if tok_t == _token:
			tactical(focus, 0.6)
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


# --- D-015 experiment: keep every living enemy in view -----------------------


## The battle scene provides the on-screen anchors (torso) of the living enemies.
func watch_enemies(provider: Callable) -> void:
	_frame_points = provider


## Debug toggle order: OFF (today's fixed framing) -> SMOOTH -> DEADZONE.
func set_frame_mode(m: int) -> void:
	frame_mode = m
	_frame_offset = Vector3.ZERO
	_frame_active = false


func _apply(delta := 0.0) -> void:
	if camera == null or not camera.is_inside_tree():
		return

	if delta > 0.0:
		if _shake_trauma > 0.0:
			_shake_trauma = maxf(_shake_trauma - _shake_decay * delta, 0.0)
		if _fov_kick > 0.0:
			_fov_kick = move_toward(_fov_kick, 0.0, 16.0 * delta)

	var shake_offset := Vector3.ZERO
	if _shake_trauma > 0.0:
		var amount := _shake_trauma * _shake_trauma
		var noise_t := Time.get_ticks_msec() * 0.045
		var jitter := Vector3(sin(noise_t * 2.1), cos(noise_t * 2.7), sin(noise_t * 3.3)) * 0.22
		shake_offset = (_shake_dir * 0.38 + jitter) * amount

	camera.position = _pos + shake_offset
	camera.fov = _fov - _fov_kick
	# Measure the framing from the mode's own aim (no Dutch tilt yet), then apply
	# the final orientation once.
	camera.look_at(_look)
	var look := _look
	if frame_mode != FrameMode.OFF and mode != Mode.STATUS and _frame_points.is_valid():
		look = _framed_look(delta)
	camera.look_at(look)
	camera.rotate_object_local(Vector3.BACK, deg_to_rad(TILT_DEG))


## Directional hit shake for regular attacks with lower intensity than K.O. (D-157).
func hit_shake(hit_dir: Vector3, heavy := false, mult := 1.0) -> void:
	if _shake_trauma >= 0.75:
		return  # Don't downgrade an active K.O. shake
	var base_trauma := 0.55 if heavy else 0.35
	_shake_trauma = maxf(_shake_trauma, clampf(base_trauma * mult, 0.25, 0.65))
	_shake_dir = -hit_dir.normalized() if hit_dir.length_squared() > 0.001 else Vector3.BACK
	_fov_kick = maxf(_fov_kick, 1.5 if heavy else 0.5)
	_shake_decay = 4.5


## Epic K.O. directional trauma shake and FOV punch (D-049 / D-157).
func ko_shake(hit_dir: Vector3, world_pos: Vector3, elem_color: Color) -> void:
	_shake_trauma = 1.0
	_shake_dir = -hit_dir.normalized() if hit_dir.length_squared() > 0.001 else Vector3.BACK
	_fov_kick = 4.5
	_shake_decay = 3.0
	impact_post(world_pos, elem_color, true, true)
	if _lines != null:
		_lines.burst()


## The look point that keeps every living enemy inside the safe border, smoothed.
## Pan and tilt only: position and FOV never change (D-020: no zoom, no shake).
## The smoothing applies to the *correction* over the mode's own aim, so the
## camera keeps its normal glide and only the framing part moves smoothly.
func _framed_look(delta: float) -> Vector3:
	var framed := _look + _frame_offset
	var target := Vector3.ZERO
	if frame_mode == FrameMode.DEADZONE:
		# Hysteresis: start when an enemy crosses the wide border, stop only when
		# every enemy is comfortably back inside it (the framing itself parks them
		# on the safe border, so a tighter release would chatter).
		var wide := FRAME_MARGIN + FRAME_DEADZONE
		var hold := FRAME_MARGIN + FRAME_DEADZONE * 0.5
		if not _frame_active and _worst_fraction(framed, wide).x >= 0.0:
			_frame_active = true
		elif _frame_active and _worst_fraction(framed, hold).x < 0.0:
			_frame_active = false
		if _frame_active:
			target = _contain(_look, FRAME_MARGIN) - _look
	else:
		target = _contain(_look, FRAME_MARGIN) - _look
	var rate := FRAME_FOLLOW if frame_mode == FrameMode.SMOOTH else FRAME_SNAP
	_frame_offset = _frame_offset.lerp(target, 1.0 - exp(-rate * delta))
	return _look + _frame_offset


## Turns `base` just enough for all points to sit inside the border. Iterative:
## each pass aims at the point that crosses the border the most and rotates the
## view by the exact angle its screen position asks for.
func _contain(base: Vector3, margin: float) -> Vector3:
	var look := base
	for pass_i in 3:
		var f := _worst_fraction(look, margin)
		if f.x < 0.0:
			break
		var vp := camera.get_viewport().get_visible_rect().size
		var tan_v := tan(deg_to_rad(_fov) * 0.5)
		var tan_h := tan_v * (vp.x / maxf(vp.y, 1.0))
		var lim := 1.0 - 2.0 * margin
		# Screen y grows downward: ny > 0 means the point sits above the centre.
		var nx := 2.0 * f.x - 1.0
		var ny := 1.0 - 2.0 * f.y
		var nxt := clampf(nx, -lim, lim)
		var nyt := clampf(ny, -lim, lim)
		var turn_x := atan(nx * tan_h) - atan(nxt * tan_h)  # positive = point is to the right
		var turn_y := atan(ny * tan_v) - atan(nyt * tan_v)  # positive = point is above
		turn_x = clampf(turn_x, -FRAME_MAX_STEP, FRAME_MAX_STEP)
		turn_y = clampf(turn_y, -FRAME_MAX_STEP, FRAME_MAX_STEP)
		var d := look - _pos
		d = d.rotated(Vector3.UP, -turn_x)  # Turn toward the point.
		var right := d.cross(Vector3.UP).normalized()
		if right.length_squared() > 0.5:
			d = d.rotated(right, turn_y)
		look = _pos + d
	return look


## Screen fraction (0..1) of the point that crosses the safe border the most, or
## (-1, -1) when every point is inside. Leaves the camera looking at `look`.
func _worst_fraction(look: Vector3, margin: float) -> Vector2:
	var worst := Vector2(-1.0, -1.0)
	if camera == null or not _frame_points.is_valid():
		return worst
	var vp := camera.get_viewport().get_visible_rect().size
	if vp.x < 2.0 or vp.y < 2.0:
		return worst
	camera.look_at(look)
	var worst_over := 0.0
	for p in _frame_points.call():
		var pt: Vector3 = p
		if camera.is_position_behind(pt):
			continue
		var sp := camera.unproject_position(pt)
		var f := Vector2(sp.x / vp.x, sp.y / vp.y)
		var ox := 0.0
		var oy := 0.0
		if f.x < margin:
			ox = margin - f.x
		elif f.x > 1.0 - margin:
			ox = f.x - (1.0 - margin)
		if f.y < margin:
			oy = margin - f.y
		elif f.y > 1.0 - margin:
			oy = f.y - (1.0 - margin)
		var over := maxf(ox, oy)
		if over > worst_over:
			worst_over = over
			worst = f
	return worst




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
