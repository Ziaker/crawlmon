class_name MotionMesh
extends RefCounted
## Motion Composer V1.1 (D-322): procedural geometry for representations (spec 8.1 "geometria procedural", D-274 item 4:
## "tubo curvo"). Turns an ordered strand of points into a closed tapered TUBE with real volume, so it reads from any
## camera angle (a flat ribbon vanishes when the shot flies straight away from the camera). Pure data in, arrays out:
## no Node, no material, no clock (spec 2.1). The renderer (MotionPainter) uploads the arrays.
##
## Vertex layout (consumed by shaders/mc_flame_body.gdshader):
##   UV.x   angle around the tube, 0..1 (the seam is duplicated so UV does not wrap)
##   UV.y   distance along the strand in METERS from the first point (stable when the tube stretches)
##   COLOR  r = position along the strand 0..1 (1 = head), g = intensity, b = dissolve progress 0..1, a = ring radius in metres

const MIN_RADIUS := 0.0005


## pts: ordered points (tail -> head). radii: per point. dissolve/intensity: per point (may be empty).
## cap_rings: rings of the rounded head cap (0 = open end). Returns {} when there is nothing to draw.
static func tube(pts: PackedVector3Array, radii: PackedFloat32Array, dissolve: PackedFloat32Array, intensity: PackedFloat32Array,
		sides := 8, cap_rings := 3) -> Dictionary:
	var n := pts.size()
	if n < 2 or radii.size() != n or sides < 3:
		return {}
	# Tangents (central differences; one-sided at the ends).
	var tans := PackedVector3Array()
	tans.resize(n)
	for i in n:
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, n - 1)]
		var t := (b - a)
		tans[i] = t.normalized() if t.length_squared() > 1e-10 else (tans[i - 1] if i > 0 else Vector3.FORWARD)
	# Parallel-transport frame: no twisting, no flips.
	var nrm := Vector3.UP if absf(tans[0].dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	nrm = (nrm - tans[0] * nrm.dot(tans[0])).normalized()
	var normals_f := PackedVector3Array()
	var binormals := PackedVector3Array()
	normals_f.resize(n)
	binormals.resize(n)
	for i in n:
		var cand := nrm - tans[i] * nrm.dot(tans[i])
		if cand.length_squared() < 1e-8:
			cand = tans[i].cross(Vector3.UP if absf(tans[i].dot(Vector3.UP)) < 0.95 else Vector3.RIGHT)
		nrm = cand.normalized()
		normals_f[i] = nrm
		binormals[i] = tans[i].cross(nrm).normalized()
	# Rings: the strand itself, then the head cap.
	var ring_pos: Array[Vector3] = []
	var ring_rad: Array[float] = []
	var ring_nrm: Array[Vector3] = []
	var ring_bin: Array[Vector3] = []
	var ring_len := PackedFloat32Array()
	var ring_u := PackedFloat32Array()
	var ring_dis := PackedFloat32Array()
	var ring_int := PackedFloat32Array()
	var run := 0.0
	for i in n:
		if i > 0:
			run += pts[i].distance_to(pts[i - 1])
		ring_pos.append(pts[i])
		ring_rad.append(maxf(radii[i], MIN_RADIUS))
		ring_nrm.append(normals_f[i])
		ring_bin.append(binormals[i])
		ring_len.append(run)
		ring_u.append(float(i) / float(n - 1))
		ring_dis.append(dissolve[i] if dissolve.size() == n else 0.0)
		ring_int.append(intensity[i] if intensity.size() == n else 1.0)
	var r_last := ring_rad[n - 1]
	for k in range(1, cap_rings + 1):
		var th := (PI * 0.5) * float(k) / float(cap_rings)
		ring_pos.append(pts[n - 1] + tans[n - 1] * (sin(th) * r_last))
		ring_rad.append(maxf(cos(th) * r_last, MIN_RADIUS))
		ring_nrm.append(normals_f[n - 1])
		ring_bin.append(binormals[n - 1])
		ring_len.append(run + sin(th) * r_last)
		ring_u.append(1.0)
		ring_dis.append(ring_dis[n - 1])
		ring_int.append(ring_int[n - 1])
	var rings := ring_pos.size()
	var stride := sides + 1
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	verts.resize(rings * stride)
	norms.resize(rings * stride)
	uvs.resize(rings * stride)
	cols.resize(rings * stride)
	for r in rings:
		for j in stride:
			var f := float(j) / float(sides)
			var a := f * TAU
			var dir := ring_nrm[r] * cos(a) + ring_bin[r] * sin(a)
			var idx := r * stride + j
			verts[idx] = ring_pos[r] + dir * ring_rad[r]
			norms[idx] = dir
			uvs[idx] = Vector2(f, ring_len[r])
			cols[idx] = Color(ring_u[r], ring_int[r], clampf(ring_dis[r], 0.0, 1.0), ring_rad[r])
	var idxs := PackedInt32Array()
	for r in rings - 1:
		for j in sides:
			var a0 := r * stride + j
			var a1 := a0 + 1
			var b0 := a0 + stride
			var b1 := b0 + 1
			idxs.append_array(PackedInt32Array([a0, b0, a1, a1, b0, b1]))
	return {"vertices": verts, "normals": norms, "uvs": uvs, "colors": cols, "indices": idxs, "rings": rings, "length": run}


## Uploads the arrays into `mesh` (cleared first). Returns false when the arrays are empty.
static func upload(mesh: ArrayMesh, data: Dictionary) -> bool:
	mesh.clear_surfaces()
	if data.is_empty():
		return false
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = data["normals"]
	arrays[Mesh.ARRAY_TEX_UV] = data["uvs"]
	arrays[Mesh.ARRAY_COLOR] = data["colors"]
	arrays[Mesh.ARRAY_INDEX] = data["indices"]
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return true
