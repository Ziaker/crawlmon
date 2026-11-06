class_name HealGainFx
extends Node3D
## D-343: the green crosses that rise with the option 2 heal gain. The motion is the Motion Composer
## (MotionPresets.heal_gain_effect / M26) and the look is the game flipbook `heal_cross`; this node
## only hands the real position (the number's current anchor), the explicit clock and the camera
## distance scale to the effect.

const LIFE := 1.4
const REF_DIST := 4.0  ## the camera distance at which the crosses keep their tuned size
const SCALE_MIN := 0.5
const SCALE_MAX := 2.2

var _effect: MotionEffect
var _painter: MotionPainter
var _origin := Vector3.ZERO
var _t := 0.0


static func spawn(parent: Node3D, pos: Vector3) -> HealGainFx:
	var node := HealGainFx.new()
	node._origin = pos
	parent.add_child(node)
	return node


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY  # the painter nodes use world positions; keep this node at identity
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3:
		var cam := get_viewport().get_camera_3d()
		return cam.global_position if cam != null else Vector3(0, 3, 8)
	_painter.cam_basis_fn = func() -> Basis:
		var cam := get_viewport().get_camera_3d()
		return cam.global_transform.basis if cam != null else Basis.IDENTITY
	add_child(_painter)
	_effect = MotionPresets.heal_gain_effect(randi(), _origin)


func _process(delta: float) -> void:
	_t += delta
	var anchor := _origin
	# D-308: keep the crosses reading the same on screen in the normal and the mirrored view (the
	# near camera would otherwise turn the metre-sized ring into a huge, off-screen halo).
	var sc := 1.0
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		sc = clampf(anchor.distance_to(cam.global_position) / REF_DIST, SCALE_MIN, SCALE_MAX)
	_painter.time = _t
	_painter.begin_frame()
	var geo := {
		"origin": anchor,
		"dest": anchor + Vector3.UP,
		"head": anchor,
		"axis": Vector3.FORWARD,
		"k": clampf(_t / LIFE, 0.0, 1.0),
		"p": 0.0,
		"scale": sc,
	}
	_effect.draw(_painter, "windup", _t, geo)
	_painter.end_frame()
	if _t >= LIFE:
		queue_free()
