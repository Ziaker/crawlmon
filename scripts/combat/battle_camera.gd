class_name BattleCamera
extends Node
## Cinematic camera director. Idles in a diagonal over-the-shoulder view with a
## slow sway, then cuts to shots (telegraph push-ins, tracking, impact
## close-ups, dodge whips) with FOV punch, Dutch roll, letterbox bars, screen
## flash and hit-stop. Higher-priority shots interrupt lower ones; when a
## shot's hold time runs out the camera glides back to idle.

const IDLE_POS := Vector3(-8.5, 2.8, 6.5)
const IDLE_LOOK := Vector3(2.0, 1.2, -0.5)
const IDLE_FOV := 58.0
const BAR_HEIGHT := 56.0

var camera: Camera3D
var base_pos := IDLE_POS
var look_at_pos := IDLE_LOOK
var fov := IDLE_FOV
var roll := 0.0  ## Degrees of Dutch tilt.
var shake_offset := Vector3.ZERO

var _priority := 0
var _lock_until := 0.0
var _tween: Tween
var _bars: Array[ColorRect] = []
var _flash: ColorRect
var _bars_on := false


func setup(p_camera: Camera3D) -> void:
	camera = p_camera
	var layer := CanvasLayer.new()
	layer.layer = 0  # Above the 3D scene, below the battle UI.
	add_child(layer)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		_bars.append(bar)
	_set_bars(0.0)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _process(_delta: float) -> void:
	if camera == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var sway_k := 1.0 if _priority == 0 else 0.25
	var sway := Vector3(sin(t * 0.35) * 0.35, sin(t * 0.23) * 0.12, cos(t * 0.29) * 0.3) * sway_k
	camera.position = base_pos + sway + shake_offset
	camera.look_at(look_at_pos)
	camera.rotate_object_local(Vector3.BACK, deg_to_rad(roll))
	camera.fov = fov
	if _priority > 0 and t > _lock_until:
		release()


## Cut/glide to a shot. Ignored if a higher-priority shot is still held.
func frame(pos: Vector3, look: Vector3, p_fov: float, p_roll: float, time: float, priority: int, hold: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if priority < _priority and now < _lock_until:
		return
	_priority = priority
	_lock_until = now + hold
	_glide(pos, look, p_fov, p_roll, time)
	_show_bars(priority >= 2)


## Drop the current shot and glide back to the idle framing.
func release() -> void:
	_priority = 0
	_lock_until = 0.0
	_glide(IDLE_POS, IDLE_LOOK, IDLE_FOV, 0.0, 0.9)
	_show_bars(false)


func orbit(center: Vector3, radius: float, height: float, from_deg: float, to_deg: float, time: float, p_fov: float) -> void:
	_priority = 9
	_lock_until = Time.get_ticks_msec() / 1000.0 + 1000.0
	if _tween and _tween.is_valid():
		_tween.kill()
	look_at_pos = center
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(func(d: float) -> void:
		base_pos = center + Vector3(sin(deg_to_rad(d)) * radius, height, cos(deg_to_rad(d)) * radius),
		from_deg, to_deg, time)
	_tween.tween_property(self, "fov", p_fov, time)
	_tween.tween_property(self, "roll", 0.0, time)
	_show_bars(true)


func shake(strength: float) -> void:
	var tw := create_tween()
	for i in 5:
		tw.tween_property(self, "shake_offset", Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * strength, 0.03)
	tw.tween_property(self, "shake_offset", Vector3.ZERO, 0.04)


func flash(alpha: float) -> void:
	_flash.color.a = alpha
	create_tween().tween_property(_flash, "color:a", 0.0, 0.25)


## Brief slow-motion; `real_seconds` is wall-clock time.
func hit_stop(time_scale: float, real_seconds: float) -> void:
	Engine.time_scale = time_scale
	get_tree().create_timer(real_seconds, true, false, true).timeout.connect(
		func() -> void: Engine.time_scale = 1.0)


func _glide(pos: Vector3, look: Vector3, p_fov: float, p_roll: float, time: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "base_pos", pos, time)
	_tween.tween_property(self, "look_at_pos", look, time)
	_tween.tween_property(self, "fov", p_fov, time)
	_tween.tween_property(self, "roll", p_roll, time)


func _show_bars(on: bool) -> void:
	if on == _bars_on:
		return
	_bars_on = on
	create_tween().tween_method(_set_bars, BAR_HEIGHT if not on else 0.0, BAR_HEIGHT if on else 0.0, 0.15)


func _set_bars(height: float) -> void:
	_bars[0].offset_bottom = height
	_bars[1].offset_top = -height
