class_name ModelGait
extends RefCounted
## D-1264: measures, from the model itself, (a) how far a clip pushes the feet below the
## rest pose (sinking into the floor) and (b) the ground speed a walk/run clip is authored for
## (the speed of a planted foot relative to the body). No per-species numbers: everything is
## derived from the skeleton, so any species/clip works (D-235).
##
## Model convention: the character faces +Z in the model root's local space.

const CLIPS := ["idle", "walk", "run"]
const SAMPLES := 24
const SKIP_NAMES := ["mesh", "lod", "origin", "eye", "hara"]
const LOW_BAND := 0.22      ## vertices within this fraction of the height above the sole
const MAX_LOW_VERTS := 700  ## per-pose cost cap

static var _cache := {}     ## model path -> analyze() result (the skeleton never changes)


## Foot bones = leaf bones near the ground in rest pose (mesh/lod/origin helpers excluded).
static func foot_bones(skel: Skeleton3D, model: Node3D, height: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	skel.reset_bone_poses()
	for b in skel.get_bone_count():
		if skel.get_bone_children(b).size() > 0:
			continue
		var nm := skel.get_bone_name(b).to_lower()
		var skip := false
		for s in SKIP_NAMES:
			if nm.contains(s):
				skip = true
		if skip:
			continue
		if _local_pos(skel, model, b).y < height * 0.3:
			out.append(b)
	return out


static func _local_pos(skel: Skeleton3D, model: Node3D, b: int) -> Vector3:
	return model.global_transform.affine_inverse() * (skel.global_transform * skel.get_bone_global_pose(b).origin)


## Returns {clip: {"sink": m (>=0, how far the lowest foot goes below rest),
## "ground_speed": m/s or 0.0, "length": s}}. The model must be inside the tree.
static func analyze(model: Node3D, ap: AnimationPlayer, height: float, cache_key := "") -> Dictionary:
	if cache_key != "" and _cache.has(cache_key):
		return _cache[cache_key]
	var result := {}
	var skels := model.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty() or ap == null:
		return result
	var skel: Skeleton3D = skels[0]
	var feet := foot_bones(skel, model, height)
	if feet.is_empty():
		return result
	var rest_low := 1e9
	for b in feet:
		rest_low = minf(rest_low, _local_pos(skel, model, b).y)
	var low_verts := _collect_low_vertices(skel, model, height)
	var rest_sole := _sole_y(skel, model, low_verts)
	var saved := ap.current_animation
	var saved_pos := ap.current_animation_position
	for clip in CLIPS:
		if not ap.has_animation(clip):
			continue
		var anim := ap.get_animation(clip)
		var dt := anim.length / SAMPLES
		var prev := {}
		var low := 1e9
		var contact_speed := 0.0
		var contact_n := 0
		var heights := []
		var steps := []
		for i in SAMPLES + 1:
			ap.play(clip)
			ap.seek(dt * i, true)
			ap.pause()
			skel.force_update_all_bone_transforms()
			var row := {}
			for b in feet:
				var p := _local_pos(skel, model, b)
				row[b] = p
				low = minf(low, p.y)
			heights.append(row)
		# Planted foot: per foot, samples whose height is in the lowest quarter of its range.
		for b in feet:
			var lo := 1e9
			var hi := -1e9
			for row in heights:
				lo = minf(lo, (row[b] as Vector3).y)
				hi = maxf(hi, (row[b] as Vector3).y)
			if hi - lo < 0.01:
				continue
			for i in SAMPLES:
				var a: Vector3 = heights[i][b]
				var c: Vector3 = heights[i + 1][b]
				if a.y <= lo + (hi - lo) * 0.25 and c.y <= lo + (hi - lo) * 0.25:
					contact_speed += -(c.z - a.z) / dt
					contact_n += 1
		var sole := 1e9
		if not low_verts.is_empty():
			for i in SAMPLES:
				ap.seek(dt * i, true)
				skel.force_update_all_bone_transforms()
				sole = minf(sole, _sole_y(skel, model, low_verts))
		var gs := contact_speed / contact_n if contact_n > 0 else 0.0
		result[clip] = {
			"rest_sole": rest_sole if not low_verts.is_empty() else rest_low,
			"sink": maxf(0.0, rest_sole - sole) if not low_verts.is_empty() else maxf(0.0, rest_low - low),
			"ground_speed": maxf(0.0, gs) if clip != "idle" else 0.0,
			"length": anim.length,
		}
	if saved != "":
		ap.play(saved)
		ap.seek(saved_pos, true)
	else:
		ap.stop()
	skel.reset_bone_poses()
	if cache_key != "":
		_cache[cache_key] = result
	return result


## Skinned vertices near the ground in rest pose: [{"mi", "skin_idx":[], "v":[], "bones":[], "w":[]}]
static func _collect_low_vertices(skel: Skeleton3D, model: Node3D, height: float) -> Array:
	var out := []
	skel.reset_bone_poses()
	var inv := model.global_transform.affine_inverse()
	var min_y := 1e9
	var all := []
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or m.skin == null or m.name.contains("_tuta_") or m.name.to_lower().contains("lod"):
			continue
		var bind_to_bone := PackedInt32Array()
		for i in m.skin.get_bind_count():
			var bi := m.skin.get_bind_bone(i)
			if bi < 0:
				bi = skel.find_bone(m.skin.get_bind_name(i))
			bind_to_bone.append(bi)
		for s in m.mesh.get_surface_count():
			var arrays := m.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones = arrays[Mesh.ARRAY_BONES]
			var weights = arrays[Mesh.ARRAY_WEIGHTS]
			if bones == null or weights == null or (bones as PackedInt32Array).is_empty():
				continue
			var per := (bones as PackedInt32Array).size() / maxi(1, verts.size())
			for vi in verts.size():
				var p := _skin_vertex(skel, m, bind_to_bone, verts[vi], bones, weights, vi, per)
				var y := (inv * (skel.global_transform * p)).y
				min_y = minf(min_y, y)
				all.append([y, m, bind_to_bone, verts[vi], bones, weights, vi, per])
	var band := min_y + height * LOW_BAND
	var picked := []
	for e in all:
		if e[0] <= band:
			picked.append(e)
	var stride := maxi(1, picked.size() / MAX_LOW_VERTS)
	for i in range(0, picked.size(), stride):
		out.append(picked[i])
	return out


static func _skin_vertex(skel: Skeleton3D, m: MeshInstance3D, bind_to_bone: PackedInt32Array,
		v: Vector3, bones, weights, vi: int, per: int) -> Vector3:
	var acc := Vector3.ZERO
	var wsum := 0.0
	for k in per:
		var w: float = weights[vi * per + k]
		if w <= 0.0:
			continue
		var bind: int = bones[vi * per + k]
		var bone := bind_to_bone[bind] if bind < bind_to_bone.size() else -1
		if bone < 0:
			continue
		acc += (skel.get_bone_global_pose(bone) * m.skin.get_bind_pose(bind) * v) * w
		wsum += w
	return acc / wsum if wsum > 0.0 else v


static func _sole_y(skel: Skeleton3D, model: Node3D, low_verts: Array) -> float:
	var inv := model.global_transform.affine_inverse()
	var lo := 1e9
	for e in low_verts:
		var p := _skin_vertex(skel, e[1], e[2], e[3], e[4], e[5], e[6], e[7])
		lo = minf(lo, (inv * (skel.global_transform * p)).y)
	return lo
