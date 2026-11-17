class_name BodyFootprint
extends RefCounted
## D-1269: footprint (circle on the floor plane + height) of a character, MEASURED from its
## visible model, never from the species or a fixed number (D-235). Shared by the body
## separation (`BodySeparation`) and by the overworld attack contact (`_body_radius`), so
## "touching" means the same thing everywhere.
##
## Radius = high percentile of the horizontal distance, from the ACTOR ORIGIN, of the skinned
## vertices of the body meshes in the 10%-90% height band (so a lowered weapon/tail tip or a
## raised hand does not inflate it, but limbs and belly count). Measured once per actor.

const BAND_LO := 0.10
const BAND_HI := 0.90
const PERCENTILE := 0.94
const CLIPS := ["idle", "walk", "run"]
const POSE_SAMPLES := 4
const FALLBACK_RADIUS := 0.35
const MIN_MESH_SHARE := 0.25  ## other meshes count only if >= 25% of the biggest one (weapons, eyes: no)

static var max_samples := 4500  ## vertex cap per mesh (tests lower it for per-frame hulls)
static var _tries: Dictionary = {}
static var _cache: Dictionary = {}  ## instance id -> {"radius", "height", "base"}


static func radius_of(node: Node3D) -> float:
	return float(info(node)["radius"])


static func height_of(node: Node3D) -> float:
	return float(info(node)["height"])


static func info(node: Node3D) -> Dictionary:
	if node == null or not is_instance_valid(node):
		return {"radius": FALLBACK_RADIUS, "height": 1.0, "base": 0.0, "off": Vector2.ZERO, "w": FALLBACK_RADIUS, "half": 0.0, "measured": false}
	var key := node.get_instance_id()
	var now := Time.get_ticks_msec()
	if _cache.has(key):
		var cached: Dictionary = _cache[key]
		# One re-measure after the spawn transients settle (pop-in scale, bind pose) have passed.
		if bool(cached.get("settled", false)) or now - int(cached["t"]) < 2500:
			return cached
		var again := _measure(node)
		if bool(again["measured"]):
			again["t"] = now
			again["settled"] = true
			_cache[key] = again
			return again
		cached["settled"] = true
		return cached
	var result := _measure(node)
	# Do not freeze a failed measurement (model not built yet): retry next call.
	if bool(result["measured"]):
		result["t"] = now
		_cache[key] = result
	return result


## Visual centre of the body on the floor plane, in world space (y = actor y).
static func center_of(node: Node3D) -> Vector3:
	var off: Vector2 = info(node)["off"]
	var c := node.global_transform * Vector3(off.x, 0.0, off.y)
	c.y = node.global_position.y
	return c


## Capsule on the floor plane (oriented along the actor's forward axis): [p0, p1] world (x, z) and radius.
static func capsule_of(node: Node3D) -> Dictionary:
	var fi := info(node)
	var c := center_of(node)
	var fwd := node.global_transform.basis.z
	var axis := Vector2(fwd.x, fwd.z)
	axis = axis.normalized() if axis.length() > 0.0001 else Vector2(0.0, 1.0)
	var c2 := Vector2(c.x, c.z)
	var h := float(fi["half"])
	return {"p0": c2 - axis * h, "p1": c2 + axis * h, "r": float(fi["w"]), "y": c.y, "axis": axis}


## Closest points of two 2D segments -> [pa, pb].
static func closest_points(a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2) -> Array:
	var d1 := a1 - a0
	var d2 := b1 - b0
	var r := a0 - b0
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var t := 0.0
	if a <= 0.000001 and e <= 0.000001:
		return [a0, b0]
	if a <= 0.000001:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c := d1.dot(r)
		if e <= 0.000001:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b := d1.dot(d2)
			var denom := a * e - b * b
			s = clampf((b * f - c * e) / denom, 0.0, 1.0) if denom > 0.000001 else 0.0
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	return [a0 + d1 * s, b0 + d2 * t]


## Edge-to-edge gap between the capsules of two bodies (negative = overlapping depth).
static func gap(a: Node3D, b: Node3D) -> float:
	var ca := capsule_of(a)
	var cb := capsule_of(b)
	var cp := closest_points(ca["p0"], ca["p1"], cb["p0"], cb["p1"])
	return (cp[0] as Vector2).distance_to(cp[1]) - float(ca["r"]) - float(cb["r"])


## Distance on the floor plane between the visual centres of two bodies.
static func center_distance(a: Node3D, b: Node3D) -> float:
	var ca := center_of(a)
	var cb := center_of(b)
	return Vector2(ca.x - cb.x, ca.z - cb.z).length()


static func forget(node: Node3D) -> void:
	if node != null:
		_cache.erase(node.get_instance_id())


static func _capsule_radius(node: Node3D) -> float:
	for child in node.find_children("*", "CollisionShape3D", true, false):
		var cs := child as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		if cs.shape is CapsuleShape3D:
			return (cs.shape as CapsuleShape3D).radius
		if cs.shape is SphereShape3D:
			return (cs.shape as SphereShape3D).radius
		if cs.shape is CylinderShape3D:
			return (cs.shape as CylinderShape3D).radius
	return FALLBACK_RADIUS


## Points (actor-local) of the body meshes in the CURRENT pose: skinned vertices, or the mesh itself
## when it is rigid. Only ArrayMesh bodies count (quads, blob shadows, rings are not bodies).
static func body_points(node: Node3D) -> PackedVector3Array:
	var biggest := 0
	var verts_of := {}
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or not (mi.mesh is ArrayMesh) or not mi.is_visible_in_tree():
			continue
		var n := 0
		for s in mi.mesh.get_surface_count():
			n += mi.mesh.surface_get_array_len(s)
		if n < 24:
			continue
		verts_of[mi] = n
		biggest = maxi(biggest, n)
	# Skinned meshes are the body; rigid ones (rings, props) only count when there is no skinned mesh.
	var skinned := {}
	for mi in verts_of:
		if mi.skin != null and not mi.skeleton.is_empty():
			skinned[mi] = verts_of[mi]
	if not skinned.is_empty():
		verts_of = skinned
		biggest = 0
		for mi in verts_of:
			biggest = maxi(biggest, int(verts_of[mi]))
	var to_node := node.global_transform.affine_inverse()
	var pts := PackedVector3Array()
	for mi in verts_of:
		if float(verts_of[mi]) >= float(biggest) * MIN_MESH_SHARE:
			_append_points(pts, mi, to_node, int(verts_of[mi]), biggest)
	return pts


static func _measure(node: Node3D) -> Dictionary:
	var live := body_points(node)
	var live_band := _band(live)
	if live_band.is_empty():
		return {"radius": _capsule_radius(node), "height": 1.0, "base": 0.0, "off": Vector2.ZERO, "w": FALLBACK_RADIUS, "half": 0.0, "measured": false}
	# Pose-independent: samples of the idle/walk/run clips on a throwaway copy of the model (the live
	# AnimationPlayer is never touched; the live pose may be a transient one, e.g. a bind pose).
	var poses: Array = _sampled_poses(node)
	if poses.is_empty():
		# Clips not ready yet (aliases still being applied): retry a few times before trusting the live pose.
		var key := node.get_instance_id()
		_tries[key] = int(_tries.get(key, 0)) + 1
		if int(_tries[key]) < 30:
			return {"radius": FALLBACK_RADIUS, "height": 1.0, "base": 0.0, "off": Vector2.ZERO, "w": FALLBACK_RADIUS, "half": 0.0, "measured": false}
		poses = [live_band]
	var center := Vector2.ZERO
	for band in poses:
		center += _mid_extent(band)
	center /= float(poses.size())
	var radius := 0.0
	var w := 0.0
	var zhalf := 0.0
	for band in poses:
		radius = maxf(radius, _percentile_dist(band, center))
		var xs: Array[float] = []
		var zs: Array[float] = []
		for q in band:
			xs.append(absf(q.x - center.x))
			zs.append(absf(q.y - center.y))
		xs.sort()
		zs.sort()
		w += xs[mini(int(float(xs.size()) * PERCENTILE), xs.size() - 1)] / float(poses.size())
		zhalf += zs[mini(int(float(zs.size()) * PERCENTILE), zs.size() - 1)] / float(poses.size())
	w = maxf(w, 0.12)
	# D-1269 (capsule): segment along the model's forward axis (local Z) + lateral radius w.
	var half := maxf(zhalf - w, 0.0)
	var min_y := INF
	var max_y := -INF
	for p in live:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	return {"radius": maxf(radius, 0.12), "height": maxf(max_y - min_y, 0.05), "base": min_y,
		"off": center, "w": w, "half": half, "measured": true}


## Floor-plane (x, z) points of the 10%-90% height band of a point cloud.
static func _band(pts: PackedVector3Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.is_empty():
		return out
	var min_y := INF
	var max_y := -INF
	for p in pts:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var height := maxf(max_y - min_y, 0.05)
	for p in pts:
		if p.y >= min_y + BAND_LO * height and p.y <= min_y + BAND_HI * height:
			out.append(Vector2(p.x, p.z))
	return out


## Middle of the (5%, 95%) extent on each floor axis: the visual centre of the body.
static func _mid_extent(band: PackedVector2Array) -> Vector2:
	var xs: Array[float] = []
	var zs: Array[float] = []
	for q in band:
		xs.append(q.x)
		zs.append(q.y)
	xs.sort()
	zs.sort()
	var lo := int(float(xs.size()) * 0.05)
	var hi := mini(int(float(xs.size()) * 0.95), xs.size() - 1)
	return Vector2((xs[lo] + xs[hi]) * 0.5, (zs[lo] + zs[hi]) * 0.5)


static func _percentile_dist(band: PackedVector2Array, center: Vector2) -> float:
	var d: Array[float] = []
	for q in band:
		d.append(q.distance_to(center))
	d.sort()
	return d[mini(int(float(d.size()) * PERCENTILE), d.size() - 1)]


## The direct child of `node` that carries the body (the model root).
static func _model_root(node: Node3D) -> Node3D:
	var best: Node3D = null
	var best_n := 0
	for child in node.get_children():
		var c3 := child as Node3D
		if c3 == null:
			continue
		var n := 0
		for m in c3.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi != null and mi.mesh is ArrayMesh and mi.skin != null:
				for s in mi.mesh.get_surface_count():
					n += mi.mesh.surface_get_array_len(s)
		if n > best_n:
			best_n = n
			best = c3
	return best


## One band (floor-plane points) per sampled pose of the idle/walk/run clips; [] if not possible.
static func _sampled_poses(node: Node3D) -> Array:
	var out: Array = []
	var model := _model_root(node)
	if model == null or not node.is_inside_tree():
		return out
	var probe := Node3D.new()
	node.get_tree().root.add_child(probe)
	probe.transform = Transform3D(Basis.from_scale(node.global_transform.basis.get_scale()), Vector3(20000.0, 0.0, 20000.0))
	var copy := model.duplicate() as Node3D
	probe.add_child(copy)
	copy.transform = model.transform
	var aps := copy.find_children("*", "AnimationPlayer", true, false)
	var skels := copy.find_children("*", "Skeleton3D", true, false)
	if not aps.is_empty() and not skels.is_empty():
		var ap := aps[0] as AnimationPlayer
		var skel := skels[0] as Skeleton3D
		for clip in CLIPS:
			if not ap.has_animation(clip):
				continue
			var len := ap.get_animation(clip).length
			for i in POSE_SAMPLES:
				ap.play(clip)
				ap.seek(len * float(i) / float(POSE_SAMPLES), true)
				ap.pause()
				skel.force_update_all_bone_transforms()
				var band := _band(body_points(probe))
				if not band.is_empty():
					out.append(band)
	probe.queue_free()
	return out


static func _append_points(pts: PackedVector3Array, mi: MeshInstance3D, to_node: Transform3D,
		total_verts: int, biggest: int) -> void:
	var skel: Skeleton3D = null
	if not mi.skeleton.is_empty():
		skel = mi.get_node_or_null(mi.skeleton) as Skeleton3D
	var bone_xf: Array[Transform3D] = []
	if skel != null and mi.skin != null:
		var skel_to_node := to_node * skel.global_transform
		for i in mi.skin.get_bind_count():
			var bone := mi.skin.get_bind_bone(i)
			if bone < 0:
				bone = skel.find_bone(mi.skin.get_bind_name(i))
			bone_xf.append(skel_to_node * skel.get_bone_global_pose(maxi(bone, 0)) * mi.skin.get_bind_pose(i))
	var mesh_to_node := to_node * mi.global_transform
	var stride := maxi(1, int(ceil(float(total_verts) / float(max_samples))))
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bs = arr[Mesh.ARRAY_BONES]
		var ws = arr[Mesh.ARRAY_WEIGHTS]
		var per := 0
		if not bone_xf.is_empty() and vs.size() > 0 and bs != null and bs.size() > 0:
			per = int(bs.size() / vs.size())
		var vi := 0
		while vi < vs.size():
			var p := mesh_to_node * vs[vi]
			if per > 0:
				var acc := Vector3.ZERO
				var wsum := 0.0
				for j in per:
					var w: float = ws[vi * per + j]
					var bi: int = bs[vi * per + j]
					if w <= 0.0 or bi >= bone_xf.size():
						continue
					acc += (bone_xf[bi] * vs[vi]) * w
					wsum += w
				if wsum > 0.0:
					p = acc / wsum
			pts.append(p)
			vi += stride
