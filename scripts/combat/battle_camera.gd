class_name BattleCamera
extends Node
## Battle camera director with the three approved framings: CINEMA (over the
## party's shoulder looking at the enemies), TATICA (high overview, used while
## picking a target) and IMPACTO (close on the target of a hit). Moves are slow
## eased glides: no sway, shake, roll or flashes.

enum Mode { CINEMA, TATICA, IMPACTO }

signal mode_changed(mode: Mode)

const CINEMA_POS := Vector3(1.0, 3.0, 6.5)
const CINEMA_LOOK := Vector3(3.0, 1.8, -20.0)
const CINEMA_FOV := 60.0
const TATICA_POS := Vector3(1.0, 6.0, 9.5)
const TATICA_FOV := 58.0
const GLIDE := 1.0

var camera: Camera3D
var mode := Mode.CINEMA

var _pos := CINEMA_POS
var _look := CINEMA_LOOK
var _fov := CINEMA_FOV
var _tween: Tween
var _token := 0


func setup(p_camera: Camera3D) -> void:
	camera = p_camera
	_apply()


func _process(_delta: float) -> void:
	_apply()


func cinema(time := GLIDE) -> void:
	_go(Mode.CINEMA, CINEMA_POS, CINEMA_LOOK, CINEMA_FOV, time)


## High overview looking at `focus` (the highlighted target).
func tactical(focus: Vector3, time := GLIDE) -> void:
	_go(Mode.TATICA, TATICA_POS, focus.lerp(Vector3(2.0, 0.0, 0.0), 0.35), TATICA_FOV, time)


## Soft emphasis on a hit: the camera pans toward the target (FOV narrows by a
## few degrees, no dolly), then settles back to CINEMA. Ignored
## while the player is picking a target.
func impact(target_pos: Vector3, target_is_party: bool, hold := 0.6) -> void:
	if mode == Mode.TATICA:
		return
	var pos := CINEMA_POS + Vector3(0.6, 0.0, 0.0)  # Same spot as CINEMA: only the aim and FOV change.
	var fov := 57.0
	_go(Mode.IMPACTO, pos, target_pos + Vector3(0, 1.2, 0), fov, 1.1)
	var token := _token
	await get_tree().create_timer(hold + 1.1).timeout
	if token == _token:
		cinema()


func _go(new_mode: Mode, pos: Vector3, look: Vector3, fov: float, time: float) -> void:
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
	camera.fov = _fov
