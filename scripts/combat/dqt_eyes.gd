class_name DqtEyes
extends Node
## D-340: eyes of the DQ Tact models.
##
## 1. Game rule (Aiming.MQ.CutoffByScaleNodeAnimation): a node "<X>_scale" drives
##    the mesh "<X>": it is shown only while the animated scale is above 0.5.
##    The Slime's Eye_Model_a is a closed-eye decal; without this rule the decal
##    is always drawn and the Slime looks asleep.
## 2. Own blink: if a model has a closed-eye decal (the Eye_Model_* that the
##    Sleep clip shows), the eyes close for BLINK_TIME every 3-6 s, whenever the
##    current clip keeps them open. Nothing here depends on the species.

const CUTOFF := 0.5
const SCALE_SUFFIX := "_scale"
const BLINK_TIME := 0.12
const BLINK_MIN := 3.0
const BLINK_MAX := 6.0

var _pairs: Array = []  ## [{mesh, skeleton, bone, node}]
var _closed: MeshInstance3D  ## closed-eye decal, or null
var _rng := RandomNumberGenerator.new()
var _until_blink := 0.0
var _blink_left := 0.0


## Adds the driver to `model_root` when the model has at least one "<X>_scale"
## pair. `sleep_clip` names the clip whose visible Eye_Model_* is the closed eye.
static func attach(model_root: Node3D, glb_root: Node, ap: AnimationPlayer, sleep_clip: String) -> DqtEyes:
	var eyes := DqtEyes.new()
	eyes.name = "DqtEyes"
	if not eyes._bind(glb_root, ap, sleep_clip):
		eyes.free()
		return null
	model_root.add_child(eyes)
	return eyes


func _bind(glb_root: Node, ap: AnimationPlayer, sleep_clip: String) -> bool:
	var skeletons := glb_root.find_children("*", "Skeleton3D", true, false)
	for node in glb_root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var scale_name := String(mi.name) + SCALE_SUFFIX
		var entry := {"mesh": mi, "skeleton": null, "bone": -1, "node": null, "scale_name": scale_name}
		for s in skeletons:
			var b := (s as Skeleton3D).find_bone(scale_name)
			if b >= 0:
				entry["skeleton"] = s
				entry["bone"] = b
				break
		if int(entry["bone"]) < 0:
			entry["node"] = glb_root.find_child(scale_name, true, false)
		if int(entry["bone"]) >= 0 or entry["node"] != null:
			_pairs.append(entry)
	if _pairs.is_empty():
		return false
	if ap != null and ap.has_animation(sleep_clip):
		var anim := ap.get_animation(sleep_clip)
		for e in _pairs:
			var mi: MeshInstance3D = e["mesh"]
			if not String(mi.name).begins_with("Eye_Model"):
				continue
			if _scale_at(anim, String(e["scale_name"]), 0.0) > CUTOFF:
				_closed = mi
				break
	_rng.randomize()
	_until_blink = _rng.randf_range(BLINK_MIN, BLINK_MAX)
	process_priority = 100  # after the AnimationPlayer has posed the skeleton
	return true


static func _scale_at(anim: Animation, scale_name: String, t: float) -> float:
	for i in anim.get_track_count():
		if anim.track_get_type(i) != Animation.TYPE_SCALE_3D:
			continue
		var path := anim.track_get_path(i)
		if String(path.get_concatenated_subnames()) == scale_name or String(path).ends_with(scale_name):
			return anim.scale_track_interpolate(i, t).x
	return 1.0


func _scale_of(e: Dictionary) -> float:
	if int(e["bone"]) >= 0:
		return (e["skeleton"] as Skeleton3D).get_bone_pose_scale(int(e["bone"])).x
	return (e["node"] as Node3D).scale.x


func has_closed_eye() -> bool:
	return _closed != null


func _process(delta: float) -> void:
	var closed_by_clip := false
	for e in _pairs:
		var shown := _scale_of(e) > CUTOFF
		(e["mesh"] as MeshInstance3D).visible = shown
		if e["mesh"] == _closed and shown:
			closed_by_clip = true
	if _closed == null:
		return
	if closed_by_clip:
		_blink_left = 0.0  # the clip already shows closed eyes: no blink
		return
	if _blink_left > 0.0:
		_blink_left -= delta
		_show_closed()
		return
	_until_blink -= delta
	if _until_blink <= 0.0:
		_blink_left = BLINK_TIME
		_until_blink = _rng.randf_range(BLINK_MIN, BLINK_MAX)
		_show_closed()


## Closed decal on, the other eye decals off.
func _show_closed() -> void:
	for e in _pairs:
		var mi: MeshInstance3D = e["mesh"]
		if mi == _closed:
			mi.visible = true
		elif String(mi.name).begins_with("Eye_Model"):
			mi.visible = false
