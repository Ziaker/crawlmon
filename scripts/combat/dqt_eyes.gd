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


## D-1295 (lids by bone): models without a closed-eye decal but with eyelid bones (`*mabuta*`: Orc, Cyclops,
## Sabrecub) hold the pose their own Sleep clip gives those bones at t=0 while BLIND / hit.
var _lids: Array = []  ## [{skeleton, bone, pos, rot, scl}] (null where the clip has no track of that kind)
var _eye_meshes: Array[MeshInstance3D] = []
var hide_eye_mesh_on_close := false  ## profile flag: draw a skin-colored lid over the eye while closed (Orc)
const COVER_SCALE := 2.7  ## the pupil mesh is enlarged this much (its eye bone) so the skin color covers the whole eye white
var _glb: Node
var _cover_mat: StandardMaterial3D
var cover_color := Color(0.62, 0.51, 0.39)
var _eye_bones: Array = []  ## [{skeleton, bone}] eye bones (names with "eye", not "mabuta")


## Lid color: `cover_color` from the model profile (`eye_cover_color`, the lit skin tone around the eye, unshaded).
func _cover_init() -> void:
	if _cover_mat != null or _eye_meshes.is_empty():
		return
	_cover_mat = StandardMaterial3D.new()
	_cover_mat.albedo_color = cover_color
	_cover_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for s in _glb.find_children("*", "Skeleton3D", true, false):
		var sk := s as Skeleton3D
		for b in sk.get_bone_count():
			var nm := sk.get_bone_name(b).to_lower()
			if nm.contains("eye") and not nm.contains("mabuta") and not nm.contains("translate"):
				_eye_bones.append({"skeleton": sk, "bone": b})


func _cover(on: bool) -> void:
	_cover_init()
	for m in _eye_meshes:
		if is_instance_valid(m):
			m.set_surface_override_material(0, _cover_mat if on else null)
	if on:
		for e in _eye_bones:
			var sk: Skeleton3D = e["skeleton"]
			sk.set_bone_pose_scale(e["bone"], sk.get_bone_pose_scale(e["bone"]) * COVER_SCALE)


func _bind_lids(glb_root: Node, ap: AnimationPlayer, sleep_clip: String) -> void:
	if ap == null or not ap.has_animation(sleep_clip):
		return
	_glb = glb_root
	var anim := ap.get_animation(sleep_clip)
	for n in glb_root.find_children("Eye_Model*", "MeshInstance3D", true, false):
		_eye_meshes.append(n as MeshInstance3D)
	for s in glb_root.find_children("*", "Skeleton3D", true, false):
		var sk := s as Skeleton3D
		for b in sk.get_bone_count():
			if not sk.get_bone_name(b).to_lower().contains("mabuta"):
				continue
			var e := {"skeleton": sk, "bone": b, "pos": null, "rot": null, "scl": null}
			for i in anim.get_track_count():
				if String(anim.track_get_path(i).get_concatenated_subnames()) != sk.get_bone_name(b):
					continue
				match anim.track_get_type(i):
					Animation.TYPE_POSITION_3D:
						e["pos"] = anim.position_track_interpolate(i, 0.0)
					Animation.TYPE_ROTATION_3D:
						e["rot"] = anim.rotation_track_interpolate(i, 0.0)
					Animation.TYPE_SCALE_3D:
						e["scl"] = anim.scale_track_interpolate(i, 0.0)
			_lids.append(e)


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
		_bind_lids(glb_root, ap, sleep_clip)
		if _lids.is_empty():
			return false
		process_priority = 100
		return true
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
	return _closed != null or not _lids.is_empty()


func _hold_lids() -> void:
	for e in _lids:
		var sk: Skeleton3D = e["skeleton"]
		var b: int = e["bone"]
		if e["pos"] != null:
			sk.set_bone_pose_position(b, e["pos"])
		if e["rot"] != null:
			sk.set_bone_pose_rotation(b, e["rot"])
		if e["scl"] != null:
			sk.set_bone_pose_scale(b, e["scl"])


## D-1295: same interface as EyeBlink (BattleFx drives BLIND and hit through it). Closed = the decal is shown.
var hold_closed := false  ## BLIND
var squeeze_left := 0.0   ## hit/impact: closed for this many more seconds
var lid_k := 0.0          ## 0 open / 1 closed (decal on)
var blinks := 0           ## own blinks started so far


func squeeze(seconds: float) -> void:
	squeeze_left = maxf(squeeze_left, seconds)


func blink_now() -> void:
	_until_blink = 0.0


func _process(delta: float) -> void:
	squeeze_left = maxf(squeeze_left - delta, 0.0)
	if not _lids.is_empty():  # lids by bone: only BLIND / hit (no own random blink; the Sabrecub clip already blinks)
		lid_k = 1.0 if (hold_closed or squeeze_left > 0.0) else 0.0
		if lid_k > 0.0:
			_hold_lids()
		if hide_eye_mesh_on_close:  # profile flag (Orc: the lid pose does not cover the eye)
			_cover(lid_k > 0.0)
		return
	var closed_by_clip := false
	for e in _pairs:
		var shown := _scale_of(e) > CUTOFF
		(e["mesh"] as MeshInstance3D).visible = shown
		if e["mesh"] == _closed and shown:
			closed_by_clip = true
	if _closed == null:
		return
	if hold_closed or squeeze_left > 0.0:
		_blink_left = 0.0
		lid_k = 1.0
		_show_closed()
		return
	if closed_by_clip:
		_blink_left = 0.0  # the clip already shows closed eyes: no blink
		lid_k = 1.0
		return
	lid_k = 0.0
	if _blink_left > 0.0:
		_blink_left -= delta
		lid_k = 1.0
		_show_closed()
		return
	_until_blink -= delta
	if _until_blink <= 0.0:
		_blink_left = BLINK_TIME
		blinks += 1
		_until_blink = _rng.randf_range(BLINK_MIN, BLINK_MAX)
		lid_k = 1.0
		_show_closed()


## Closed decal on, the other eye decals off.
func _show_closed() -> void:
	for e in _pairs:
		var mi: MeshInstance3D = e["mesh"]
		if mi == _closed:
			mi.visible = true
		elif String(mi.name).begins_with("Eye_Model"):
			mi.visible = false
