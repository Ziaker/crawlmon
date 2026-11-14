class_name OverworldDashDust
extends Node3D
## D-1100/D-1173: dust of the overworld attack advance, now the same recipe as
## the combat (`fx_motion._spawn_takeoff_dust` + `_dust_trail`):
##
##   - takeoff: smoke flipbook, 8 smoke puffs and 7 gravel specks at the start;
##   - trail: every 0.055 s, 4 smoke puffs (0.82, 0.78, 0.72; 0.55-1.15 m;
##     rise 0.25) and 3 gravel specks on alternating feet (+/-0.22 m).
##
## The only difference from the battle dust is the opacity: D-1100 item 12
## keeps the advance dust at alpha 0.22. Everything is world-space (top_level)
## so the actor keeps moving and the already-born puffs stay behind.

const DUST_ALPHA := 0.22
const LAB_FOOT_DUST_ALPHA := 0.42
const CADENCE := 0.055
const SMOKE_COLOR := Color(0.82, 0.78, 0.72)
const TAKEOFF_COLOR := Color(0.80, 0.76, 0.70)
const SIDE_OFFSET := 0.22
const WALK_DUST := preload("res://scripts/overworld/vfx/overworld_walk_dust.gd")
## The dash continuation keeps the previous walking cadence (0.0917 s); the
## 30%-sparser rate applies to normal walking only (2026-11-11).
const WALK_CONTINUE_CADENCE := 0.091667

var _active := false
var _streaming := false
var _start_live := false
var _end_live := false
var _t := 0.0
var _step := 0
var _dir := Vector3.FORWARD
var _last_world := Vector3.ZERO
var _has_last := false
## D-1173: the walking puffs continue during the first half of the real dash.
var _dash_duration := 0.10
var _elapsed := 0.0
var _slide_time := 0.0
var _continue_t := 0.0
var _walk_step := 0


## Kept for the existing setup contract; this dust spawns one-shots instead of
## persistent emitters.
func setup_emitters() -> void:
	pass


## The controller knows the planned advance duration; the VFX forwards it here.
func set_dash_duration(seconds: float) -> void:
	_dash_duration = maxf(seconds, 0.0)


## D-1189: in the braking tail (the last `seconds` of the advance) the trail runs at 1/3 of the cadence.
func set_slide_time(seconds: float) -> void:
	_slide_time = maxf(seconds, 0.0)


func begin(ground_point: Vector3, dir := Vector3.FORWARD) -> void:
	_active = true
	_streaming = true
	_start_live = true
	_end_live = false
	_t = 0.0
	_step = 0
	_elapsed = 0.0
	_walk_step = 0
	# First walking continuation at a quarter of the first half, so even the
	# shortest 0.06 s dash still gets one before the half closes.
	_continue_t = maxf(0.006, _dash_duration * 0.5 * 0.25)
	_dir = dir.normalized() if dir.length_squared() > 0.001 else Vector3.FORWARD
	follow_ground(ground_point)
	_last_world = ground_point
	_has_last = true
	_takeoff(ground_point)


func follow_ground(ground_point: Vector3) -> void:
	if is_inside_tree():
		global_position = ground_point
	else:
		position = ground_point


func tick(delta: float) -> void:
	if not _streaming:
		return
	var now := global_position
	if _has_last:
		var moved := now - _last_world
		moved.y = 0.0
		if moved.length_squared() > 0.0004:
			_dir = moved.normalized()
	_last_world = now
	_has_last = true
	_t += delta
	var sliding := _slide_time > 0.0 and _elapsed >= _dash_duration - _slide_time
	var cadence := CADENCE * (3.0 if sliding else 1.0)
	while _t >= cadence:
		_t -= cadence
		_trail_step(Vector3(now.x, now.y + 0.08, now.z))
	# D-1173: the walking puff keeps generating through the FIRST HALF of the
	# real dash, at the walking size (50%). After that only the dash dust runs.
	_elapsed += delta
	var half := _dash_duration * 0.5
	if _elapsed <= half:
		_continue_t -= delta
		while _continue_t <= 0.0 and _elapsed <= half:
			_walk_step += 1
			var side := -SIDE_OFFSET if (_walk_step % 2 == 0) else SIDE_OFFSET
			var side_vec := Vector3(-_dir.z, 0.0, _dir.x)
			var foot := Vector3(now.x, now.y + 0.08, now.z) + side_vec * side
			WALK_DUST.spawn_effect(self, foot, _dir, 1.0, WALK_DUST.SMOKE_SIZE_WALK)
			_continue_t += WALK_CONTINUE_CADENCE


## Congela a simulação das partículas para diagnósticos (overdraw/restos).
func set_frozen(frozen: bool) -> void:
	var speed := 0.0 if frozen else 1.0
	for node in find_children("*", "CPUParticles3D", true, false):
		(node as CPUParticles3D).speed_scale = speed


func finish(ground_point: Vector3) -> void:
	if not _active:
		return
	follow_ground(ground_point)
	_active = false
	_streaming = false
	_start_live = false
	_end_live = true
	_arrival(ground_point)


func stop() -> void:
	_active = false
	_streaming = false


func clear() -> void:
	_active = false
	_streaming = false
	_start_live = false
	_end_live = false
	for child in get_children():
		if child is CPUParticles3D or child is MeshInstance3D:
			child.queue_free()


func is_emitting() -> bool:
	return _streaming


func get_dust_alpha() -> float:
	return DUST_ALPHA


func get_debug_state() -> Dictionary:
	return {
		"alpha": DUST_ALPHA,
		"emitting": _streaming,
		"start": _start_live,
		"stream": _streaming,
		"end": _end_live,
	}


## `fx_motion._spawn_takeoff_dust`: smoke flipbook + 8 puffs + 7 gravel.
func _takeoff(ground_point: Vector3) -> void:
	var ground := Vector3(ground_point.x, ground_point.y + 0.08, ground_point.z)
	var back := -_dir if _dir.length_squared() > 0.001 else Vector3.BACK
	_spawn_flipbook(
		ground + Vector3.UP * 0.28,
		Color(TAKEOFF_COLOR, DUST_ALPHA),
		2.2, 0.40, randf_range(-18.0, 18.0), 1.6, false)
	_spawn_burst(ground, {
		"tex": VfxLib.smoke_tex(), "additive": false, "amount": 8, "life": 0.45,
		"speed": Vector2(1.8, 4.2), "dir": back + Vector3.UP * 0.35, "spread": 42.0,
		"size": Vector2(0.35, 0.70), "end_scale": 1.6, "gravity": Vector3(0.0, 0.4, 0.0),
		"ramp": VfxLib.ramp([
			Color(0.82, 0.78, 0.72, 0.85 * DUST_ALPHA),
			Color(0.82, 0.78, 0.72, 0.0),
		], [0.0, 1.0]),
	})
	_spawn_burst(ground, {
		"amount": 7, "life": 0.30, "speed": Vector2(2.5, 6.0),
		"dir": back + Vector3.UP * 0.45, "spread": 35.0,
		"size": Vector2(0.08, 0.18), "end_scale": 0.0,
		"ramp": VfxLib.ramp([
			Color(0.9, 0.85, 0.75, 0.9 * DUST_ALPHA),
			Color(0.70, 0.65, 0.55, 0.0),
		]),
	})
	# D-1173 (creator, 2026-11-11): the walking smoke, once, at the start of the
	# dash, on both feet, at full opacity and the CURRENT full size (not the
	# 50% walking size). It marks the strong advance; the takeoff/trail above
	# stay at alpha 0.22 and are not removed.
	var side_vec := Vector3(-_dir.z, 0.0, _dir.x)
	for side: float in [-SIDE_OFFSET, SIDE_OFFSET]:
		WALK_DUST.spawn_effect(
			self, ground + side_vec * side, _dir, 1.0, WALK_DUST.SMOKE_SIZE_DASH_START)


## `fx_motion._dust_trail`: 4 smoke puffs + 3 gravel specks on alternating feet.
func _trail_step(base: Vector3) -> void:
	_step += 1
	var side := -SIDE_OFFSET if (_step % 2 == 0) else SIDE_OFFSET
	var side_vec := Vector3(-_dir.z, 0.0, _dir.x)
	var foot := base + side_vec * side
	_spawn_burst(foot, {
		"tex": VfxLib.smoke_tex(), "additive": false, "amount": 4, "life": 0.38,
		"speed": Vector2(0.5, 3.0), "gravity": Vector3(0.0, 0.25, 0.0),
		"size": Vector2(0.55, 1.15), "end_scale": 1.8, "damping": 1.5, "radius": 0.4,
		"ramp": VfxLib.ramp([
			Color(SMOKE_COLOR, 0.0),
			Color(SMOKE_COLOR, 0.75 * DUST_ALPHA),
			Color(SMOKE_COLOR, 0.0),
		], [0.0, 0.2, 1.0]),
	})
	_spawn_burst(foot, {
		"amount": 3, "life": 0.22, "speed": Vector2(1.2, 3.2),
		"dir": -_dir + Vector3.UP * 0.3, "spread": 30.0,
		"size": Vector2(0.06, 0.14), "end_scale": 0.0,
		"ramp": VfxLib.ramp([
			Color(0.88, 0.84, 0.76, 0.9 * DUST_ALPHA),
			Color(0.70, 0.65, 0.55, 0.0),
		]),
	})


## `fx_motion._spawn_arrival_skid`: two angled plumes as the attacker brakes.
func _arrival(ground_point: Vector3) -> void:
	var ground := Vector3(ground_point.x, ground_point.y + 0.06, ground_point.z)
	var norm := _dir.normalized() if _dir.length_squared() > 0.001 else Vector3.FORWARD
	var side_vec := Vector3(-norm.z, 0.0, norm.x)
	for side: float in [-0.28, 0.28]:
		var foot: Vector3 = ground + side_vec * side
		_spawn_burst(foot, {
			"tex": VfxLib.smoke_tex(), "additive": false, "amount": 6, "life": 0.38,
			"speed": Vector2(1.5, 3.8),
			"dir": norm * 0.4 + side_vec * (side * 0.8) + Vector3.UP * 0.25,
			"spread": 35.0, "size": Vector2(0.3, 0.6), "end_scale": 1.4,
			"ramp": VfxLib.ramp([
				Color(0.82, 0.78, 0.72, 0.8 * DUST_ALPHA),
				Color(0.82, 0.78, 0.72, 0.0),
			], [0.0, 1.0]),
		})


func _spawn_burst(world_pos: Vector3, opts: Dictionary) -> CPUParticles3D:
	var p := VfxLib.burst(self, world_pos, opts)
	# Place the emitter before the one-shot is born (VfxLib.burst emits first).
	p.emitting = false
	p.top_level = true
	p.local_coords = false
	p.global_position = world_pos
	p.restart()
	p.emitting = true
	return p


func _spawn_flipbook(world_pos: Vector3, color: Color, size: float, duration: float,
		roll: float, energy: float, additive: bool) -> MeshInstance3D:
	var mi := VfxLib.flipbook(self, world_pos, "smoke", color, size, duration, roll, energy, additive)
	mi.top_level = true
	mi.global_position = world_pos
	return mi
