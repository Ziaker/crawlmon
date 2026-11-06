class_name ElementShapes
extends RefCounted
## D-274: reusable shape generators for the element effects: camera-facing ribbons, rock spikes and chunks.
## Pure geometry, no character, team or side (D-235).


static func bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return p0 * (u * u * u) + p1 * (3.0 * u * u * t) + p2 * (3.0 * u * t * t) + p3 * (t * t * t)


## A ribbon along `points` (world positions) with a width per point. The mesh stores the centre line; the
## ribbon shaders (el_flame, el_water, el_line) expand it sideways facing the camera (or flat on the ground).
## UV = (position along 0..1, side -1/+1), NORMAL = tangent, COLOR.r = width.
static func ribbon_mesh(points: PackedVector3Array, widths: PackedFloat32Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var n := points.size()
	if n < 2:
		return mesh
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var lo := points[0]
	var hi := points[0]
	var max_w := 0.0
	for i in n:
		var tan_v: Vector3
		if i == 0:
			tan_v = points[1] - points[0]
		elif i == n - 1:
			tan_v = points[n - 1] - points[n - 2]
		else:
			tan_v = points[i + 1] - points[i - 1]
		tan_v = tan_v.normalized() if tan_v.length() > 0.00001 else Vector3.FORWARD
		var u := float(i) / float(n - 1)
		for side in [-1.0, 1.0]:
			verts.append(points[i])
			normals.append(tan_v)
			colors.append(Color(widths[i], 0.0, 0.0, 1.0))
			uvs.append(Vector2(u, side))
		lo = lo.min(points[i])
		hi = hi.max(points[i])
		max_w = maxf(max_w, widths[i])
	for i in n - 1:
		var a := 2 * i
		indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var pad := Vector3.ONE * (max_w + 1.0)  # The vertices sit on the centre line; the shader pushes them out.
	mesh.custom_aabb = AABB(lo - pad, (hi - lo) + pad * 2.0)
	return mesh


## Replaces the ribbon of a MeshInstance3D in place (cheap enough to do every frame for a few ribbons).
static func set_ribbon(mi: MeshInstance3D, points: PackedVector3Array, widths: PackedFloat32Array) -> void:
	mi.mesh = ribbon_mesh(points, widths)
	mi.visible = points.size() >= 2


## A tall rock spike standing on y = 0 with its tip at y = 1 (unit size, jittered). Flat faces.
static func spike_mesh(rng: RandomNumberGenerator, sides := 6) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var base: Array[Vector3] = []
	for i in sides:
		var ang := TAU * float(i) / float(sides) + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(0.28, 0.5)
		base.append(Vector3(cos(ang) * r, 0.0, sin(ang) * r))
	var apex := Vector3(rng.randf_range(-0.08, 0.08), 1.0, rng.randf_range(-0.08, 0.08))
	for i in sides:
		var a := base[i]
		var b := base[(i + 1) % sides]
		for v in [a, apex, b]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## A jittered cube (unit size, centred): a stone chunk. Flat faces.
static func chunk_mesh(rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var c: Array[Vector3] = []
	for i in 8:
		var p := Vector3(0.5 if (i & 1) != 0 else -0.5, 0.5 if (i & 2) != 0 else -0.5, 0.5 if (i & 4) != 0 else -0.5)
		c.append(p + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.2, 0.2), rng.randf_range(-0.2, 0.2)))
	var quads := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 2, 6, 4], [1, 5, 7, 3], [0, 4, 5, 1], [2, 3, 7, 6]]
	for q in quads:
		for tri in [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]:
			for k in tri:
				st.add_vertex(c[k])
	st.generate_normals()
	return st.commit()
