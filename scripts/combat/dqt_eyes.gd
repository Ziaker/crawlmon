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
var paint_closed_eye := false  ## profile flag: paint the closed eye in the head texture while closed (Orc)
var cover_color := Color(0.62, 0.51, 0.39)  ## fallback skin tone when none can be measured around the eye
var _glb: Node
var _paint_ready := false
var _head_mi: MeshInstance3D
var _head_surface := 0
var _closed_mat: Material  ## copy of the head material whose albedo texture has the eye whites painted over


## Closed eye for models whose eye white lives in the head texture and whose lids do not cover it (Orc):
## for each eye, the pupil sticker's center is matched to the nearest head vertices, their UVs give a texel
## in the head texture, the near-white blob (the sclera) around it is flood-filled and repainted with the skin
## color measured in a ring around it, and a curved lash line is drawn across it. The painted copy of the head
## material replaces the original only while the eye is closed; the pupil sticker is hidden meanwhile.
func _cover_init() -> void:
	if _paint_ready:
		return
	_paint_ready = true
	if _eye_meshes.is_empty():
		return
	var best_mat: BaseMaterial3D
	for n in _glb.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.name.begins_with("Eye_Model") or mi.name.begins_with("WModel"):
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mat != null and mat.albedo_texture != null:
				_head_mi = mi
				_head_surface = s
				best_mat = mat
	if _head_mi == null:
		return
	var src_img: Image = preload("res://scripts/common/eye_blink.gd")._image_of(best_mat.albedo_texture)
	if src_img == null:
		return
	var img := src_img.duplicate() as Image
	var head := _head_mi.mesh.surface_get_arrays(_head_surface)
	var hv: PackedVector3Array = head[Mesh.ARRAY_VERTEX]
	var huv: PackedVector2Array = head[Mesh.ARRAY_TEX_UV]
	var sv: PackedVector3Array = _eye_meshes[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var painted := 0
	for side in [-1.0, 1.0]:
		var lo := Vector3(1e9, 1e9, 1e9)
		var hi := Vector3(-1e9, -1e9, -1e9)
		for v in sv:
			if v.x * side >= 0.0:
				lo = lo.min(v)
				hi = hi.max(v)
		if lo.x > hi.x:
			continue
		var c := (lo + hi) * 0.5
		var near: Array = []
		for i in hv.size():
			near.append([hv[i].distance_squared_to(c), i])
		near.sort_custom(func(x, y): return x[0] < y[0])
		var seed := Vector2i(-1, -1)
		var seed_score := -1.0
		for k in mini(near.size(), 12):
			var uv: Vector2 = huv[near[k][1]]
			var cx := int(uv.x * img.get_width())
			var cy := int(uv.y * img.get_height())
			for dy in range(-24, 25, 2):
				for dx in range(-24, 25, 2):
					var px := Vector2i(clampi(cx + dx, 0, img.get_width() - 1), clampi(cy + dy, 0, img.get_height() - 1))
					var col := img.get_pixelv(px)
					if _is_white(col) and col.v > seed_score:
						seed_score = col.v
						seed = px
		if seed.x < 0:
			continue
		painted += _paint_eye(img, seed)
	if painted == 0:
		return
	var mat2 := best_mat.duplicate() as BaseMaterial3D
	mat2.albedo_texture = ImageTexture.create_from_image(img)
	_closed_mat = mat2


static func _is_white(c: Color) -> bool:
	return c.v > 0.55 and (maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))) < 0.2


## Flood-fills the white blob from `seed`, repaints it with the surrounding skin color and draws the lash line.
func _paint_eye(img: Image, seed: Vector2i) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var mask := PackedByteArray()
	mask.resize(w * h)
	var stack: Array[Vector2i] = [seed]
	var pts: Array[Vector2i] = []
	mask[seed.y * w + seed.x] = 1
	while not stack.is_empty() and pts.size() < 9000:
		var p: Vector2i = stack.pop_back()
		pts.append(p)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or mask[q.y * w + q.x] == 1:
				continue
			if _is_white(img.get_pixelv(q)):
				mask[q.y * w + q.x] = 1
				stack.append(q)
	if pts.size() < 12 or pts.size() >= 9000:
		return 0
	var lo := Vector2i(w, h)
	var hi := Vector2i(-1, -1)
	for p in pts:
		lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
		hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
	var sum := Color(0, 0, 0, 1)
	var n := 0
	for y in range(maxi(lo.y - 5, 0), mini(hi.y + 6, h)):
		for x in range(maxi(lo.x - 5, 0), mini(hi.x + 6, w)):
			if mask[y * w + x] == 1:
				continue
			var col := img.get_pixel(x, y)
			if col.v > 0.4 and col.s > 0.1:
				sum.r += col.r
				sum.g += col.g
				sum.b += col.b
				n += 1
	var skin := Color(sum.r / n, sum.g / n, sum.b / n, 1.0) if n > 8 else cover_color
	for p in pts:
		img.set_pixelv(p, skin)
	# Lash line: an arch bowing down across the blob (closed-eye curve), only on the repainted pixels.
	var cxm := (lo.x + hi.x) * 0.5
	var cym := (lo.y + hi.y) * 0.5
	var hw := maxf((hi.x - lo.x) * 0.5, 1.0)
	var hh := maxf((hi.y - lo.y) * 0.5, 1.0)
	var ink := Color(0.10, 0.07, 0.05, 1.0)
	for x in range(lo.x, hi.x + 1):
		var tt := (x - cxm) / hw
		var yy := int(cym + 0.2 * hh * (1.0 - tt * tt))
		for dy in range(-1, 2):
			var px := Vector2i(x, yy + dy)
			if px.y >= 0 and px.y < h and mask[px.y * w + px.x] == 1:
				img.set_pixelv(px, ink)
	return pts.size()


func _cover(on: bool) -> void:
	_cover_init()
	for m in _eye_meshes:
		if is_instance_valid(m):
			m.visible = not on  # the pupil sticker goes away while the eye is closed
	if _head_mi != null and _closed_mat != null and is_instance_valid(_head_mi):
		_head_mi.set_surface_override_material(_head_surface, _closed_mat if on else null)


## Bones whose Sleep pose closes the eye: eyelids (`*mabuta*`) or the open/close eye bones (`OpenEye`/`CloseEye`,
## whose position the clips toggle to show one eye or the other).
static func is_lid_bone_name(bone_name: String) -> bool:
	var l := bone_name.to_lower()
	return l.contains("mabuta") or l == "openeye" or l == "closeeye"


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
			if not is_lid_bone_name(sk.get_bone_name(b)):
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
		if paint_closed_eye:  # profile flag (Orc: the lid pose does not cover the eye)
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
