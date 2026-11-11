class_name HtmlMeshLib
extends RefCounted
## Malhas equivalentes às do Three.js usadas no protótipo HTML Card C.
##
## Convenções literais:
## - CylinderGeometry do Three: anel em (r*sin(theta), y, r*cos(theta)).
##   Depois de rotateX(+90deg): (r*sin(theta), -r*cos(theta), z).
## - ConeGeometry = CylinderGeometry com radiusTop 0.
## - OctahedronGeometry e DodecahedronGeometry normalizam os vértices no raio.
## - TorusGeometry: anel no plano XY, tubo em Z; rotateX(+90deg) leva para XZ.
## - ExtrudeGeometry do fin: forma XY extrudada em +Z; o mesh do HTML gira Y +90deg.
## - Todas as faces usam normais planas (flatShading do Three).

const TAU_F := TAU


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	return st


static func _commit(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	return st.commit()


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, center: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-14:
		return
	if n.dot((a + b + c) / 3.0 - center) < 0.0:
		var tmp := b
		b = c
		c = tmp
	# Godot usa frente clockwise; a ordem CCW acima é a normal outward do
	# Three.js, então invertemos a ordem de envio para o Godot.
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


static func _tri_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-14:
		return
	if n.dot(normal) < 0.0:
		var tmp := b
		b = c
		c = tmp
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


static func _ring_z(r: float, z: float, segs: int) -> Array:
	var pts: Array = []
	for i in range(segs):
		var th := TAU_F * float(i) / float(segs)
		pts.append(Vector3(r * sin(th), -r * cos(th), z))
	return pts


static func _ring_y(r: float, y: float, segs: int) -> Array:
	var pts: Array = []
	for i in range(segs):
		var th := TAU_F * float(i) / float(segs)
		pts.append(Vector3(r * sin(th), y, r * cos(th)))
	return pts


## CylinderGeometry ao longo de Z, com a mesma convenção angular do Three.
## z0 = base (radius_bottom), z1 = topo (radius_top).
static func cylinder_z(radius_top: float, radius_bottom: float, z0: float, z1: float, segs: int, capped := true) -> ArrayMesh:
	var st := _begin()
	var bottom := _ring_z(radius_bottom, z0, segs)
	var top := _ring_z(radius_top, z1, segs)
	var mid := Vector3(0.0, 0.0, (z0 + z1) * 0.5)
	for i in range(segs):
		var j := (i + 1) % segs
		var b0: Vector3 = bottom[i]
		var b1: Vector3 = bottom[j]
		var t0: Vector3 = top[i]
		var t1: Vector3 = top[j]
		_tri(st, b0, b1, t1, mid)
		_tri(st, b0, t1, t0, mid)
	if capped:
		var cb := Vector3(0.0, 0.0, z0)
		var ct := Vector3(0.0, 0.0, z1)
		for i in range(segs):
			var j := (i + 1) % segs
			_tri_n(st, cb, bottom[j], bottom[i], Vector3(0.0, 0.0, -1.0))
			_tri_n(st, ct, top[i], top[j], Vector3(0.0, 0.0, 1.0))
	return _commit(st)


## CylinderGeometry ao longo de Y (atores), com a convenção do Three.
static func cylinder_y(radius_top: float, radius_bottom: float, height: float, segs: int, capped := true) -> ArrayMesh:
	var st := _begin()
	var y0 := -height * 0.5
	var y1 := height * 0.5
	var bottom := _ring_y(radius_bottom, y0, segs)
	var top := _ring_y(radius_top, y1, segs)
	var mid := Vector3.ZERO
	for i in range(segs):
		var j := (i + 1) % segs
		var b0: Vector3 = bottom[i]
		var b1: Vector3 = bottom[j]
		var t0: Vector3 = top[i]
		var t1: Vector3 = top[j]
		_tri(st, b0, b1, t1, mid)
		_tri(st, b0, t1, t0, mid)
	if capped:
		var cb := Vector3(0.0, y0, 0.0)
		var ct := Vector3(0.0, y1, 0.0)
		for i in range(segs):
			var j := (i + 1) % segs
			_tri_n(st, cb, bottom[j], bottom[i], Vector3(0.0, -1.0, 0.0))
			_tri_n(st, ct, top[i], top[j], Vector3(0.0, 1.0, 0.0))
	return _commit(st)


## ConeGeometry ao longo de +Y, base em y=0, ápice em y=height.
static func cone_y(radius: float, height: float, segs: int) -> ArrayMesh:
	var st := _begin()
	var base := _ring_y(radius, 0.0, segs)
	var apex := Vector3(0.0, height, 0.0)
	for i in range(segs):
		var j := (i + 1) % segs
		_tri(st, base[i], base[j], apex, Vector3(0.0, height * 0.5, 0.0))
	var cb := Vector3.ZERO
	for i in range(segs):
		var j := (i + 1) % segs
		_tri_n(st, cb, base[j], base[i], Vector3(0.0, -1.0, 0.0))
	return _commit(st)


## OctahedronGeometry(radius, detail) do Three.
static func octahedron(radius: float, detail := 0) -> ArrayMesh:
	var verts: Array = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 1, 0), Vector3(0, -1, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1),
	]
	for i in range(verts.size()):
		verts[i] = (verts[i] as Vector3).normalized() * radius
	var faces: Array = [
		[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2],
		[1, 2, 5], [1, 5, 3], [1, 3, 4], [1, 4, 2],
	]
	for _level in range(detail):
		var next_faces: Array = []
		for f in faces:
			var a: Vector3 = verts[f[0]]
			var b: Vector3 = verts[f[1]]
			var c: Vector3 = verts[f[2]]
			var ab := ((a + b) * 0.5).normalized() * radius
			var bc := ((b + c) * 0.5).normalized() * radius
			var ca := ((c + a) * 0.5).normalized() * radius
			var iab := verts.size()
			verts.append(ab)
			var ibc := verts.size()
			verts.append(bc)
			var ica := verts.size()
			verts.append(ca)
			next_faces.append([f[0], iab, ica])
			next_faces.append([f[1], ibc, iab])
			next_faces.append([f[2], ica, ibc])
			next_faces.append([iab, ibc, ica])
		faces = next_faces
	var st := _begin()
	for f in faces:
		_tri(st, verts[f[0]], verts[f[1]], verts[f[2]], Vector3.ZERO)
	return _commit(st)


## DodecahedronGeometry(radius, 0) do Three (12 pentágonos triangulados).
static func dodecahedron(radius: float) -> ArrayMesh:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var raw: Array = [
		Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, -1), Vector3(-1, 1, 1),
		Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(1, 1, -1), Vector3(1, 1, 1),
		Vector3(0, -1.0 / phi, -phi), Vector3(0, -1.0 / phi, phi),
		Vector3(0, 1.0 / phi, -phi), Vector3(0, 1.0 / phi, phi),
		Vector3(-1.0 / phi, -phi, 0), Vector3(-1.0 / phi, phi, 0),
		Vector3(1.0 / phi, -phi, 0), Vector3(1.0 / phi, phi, 0),
		Vector3(-phi, 0, -1.0 / phi), Vector3(phi, 0, -1.0 / phi),
		Vector3(-phi, 0, 1.0 / phi), Vector3(phi, 0, 1.0 / phi),
	]
	var verts: Array = []
	for v in raw:
		verts.append((v as Vector3).normalized() * radius)
	var idx: Array = [
		3, 11, 7, 3, 7, 15, 3, 15, 13, 7, 19, 17, 7, 17, 6, 7, 6, 15,
		17, 4, 8, 17, 8, 10, 17, 10, 6, 8, 0, 16, 8, 16, 2, 8, 2, 10,
		0, 12, 1, 0, 1, 18, 0, 18, 16, 6, 10, 2, 6, 2, 13, 6, 13, 15,
		2, 16, 18, 2, 18, 3, 2, 3, 13, 18, 1, 9, 18, 9, 11, 18, 11, 3,
		4, 14, 12, 4, 12, 0, 4, 0, 8, 11, 9, 5, 11, 5, 19, 11, 19, 7,
		19, 5, 14, 19, 14, 4, 19, 4, 17, 1, 12, 14, 1, 14, 5, 1, 5, 9,
	]
	var st := _begin()
	for i in range(0, idx.size(), 3):
		_tri(st, verts[idx[i]], verts[idx[i + 1]], verts[idx[i + 2]], Vector3.ZERO)
	return _commit(st)


static func _torus_pt(u: float, v: float, major_r: float, tube_r: float, xz: bool) -> Vector3:
	var cu := cos(u)
	var su := sin(u)
	var cv := cos(v)
	var sv := sin(v)
	var rr := major_r + tube_r * cv
	var p := Vector3(rr * cu, rr * su, tube_r * sv)
	if xz:
		p = Vector3(p.x, -p.z, p.y)
	return p


## TorusGeometry(radius, tube, radialSegments, tubularSegments).
## xz=true aplica rotateX(+90deg) como no anel rasteiro do HTML.
static func torus(major_r: float, tube_r: float, radial_segs: int, tubular_segs: int, xz := false) -> ArrayMesh:
	var st := _begin()
	for j in range(tubular_segs):
		var u0 := TAU_F * float(j) / float(tubular_segs)
		var u1 := TAU_F * float(j + 1) / float(tubular_segs)
		var center := Vector3(major_r * cos(u0), major_r * sin(u0), 0.0)
		if xz:
			center = Vector3(center.x, 0.0, center.y)
		for i in range(radial_segs):
			var v0 := TAU_F * float(i) / float(radial_segs)
			var v1 := TAU_F * float(i + 1) / float(radial_segs)
			var p00 := _torus_pt(u0, v0, major_r, tube_r, xz)
			var p10 := _torus_pt(u1, v0, major_r, tube_r, xz)
			var p11 := _torus_pt(u1, v1, major_r, tube_r, xz)
			var p01 := _torus_pt(u0, v1, major_r, tube_r, xz)
			_tri(st, p00, p10, p11, center)
			_tri(st, p00, p11, p01, center)
	return _commit(st)


## ExtrudeGeometry da pena do HTML, já com rotateY(+90deg) e position (0, 0.03, 0).
## A espessura fica em X (0..0.018) e a forma em (Z, Y), como no protótipo.
static func fin_extrude() -> ArrayMesh:
	var shape: Array = [
		Vector2(0.0, 0.0),
		Vector2(0.16, -0.08),
		Vector2(0.19, -0.34),
		Vector2(0.0, -0.26),
	]
	var x0 := 0.0
	var x1 := 0.018
	var pts0: Array = []
	var pts1: Array = []
	for p in shape:
		pts0.append(Vector3(x0, p.y + 0.03, -p.x))
		pts1.append(Vector3(x1, p.y + 0.03, -p.x))
	var center := Vector3.ZERO
	for p in pts0:
		center += p
	for p in pts1:
		center += p
	center /= 8.0
	var st := _begin()
	# faces front/back (quad convexo -> 2 triângulos)
	_tri(st, pts0[0], pts0[1], pts0[2], center)
	_tri(st, pts0[0], pts0[2], pts0[3], center)
	_tri(st, pts1[0], pts1[1], pts1[2], center)
	_tri(st, pts1[0], pts1[2], pts1[3], center)
	# bordas
	for i in range(4):
		var j := (i + 1) % 4
		_tri(st, pts0[i], pts1[i], pts1[j], center)
		_tri(st, pts0[i], pts1[j], pts0[j], center)
	return _commit(st)


## Linhas a partir de uma lista de pares de pontos.
static func lines(edges: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	for e in edges:
		st.add_vertex(e[0])
		st.add_vertex(e[1])
	return st.commit()


static func cone_edges(radius: float, z_apex: float, z_base: float, segs: int) -> Array:
	var edges: Array = []
	var apex := Vector3(0.0, 0.0, z_apex)
	var base := _ring_z(radius, z_base, segs)
	for i in range(segs):
		edges.append([apex, base[i]])
		edges.append([base[i], base[(i + 1) % segs]])
	return edges


static func octahedron_edges(radius: float, scale := Vector3.ONE) -> Array:
	var v: Array = [
		Vector3(1, 0, 0) * radius * scale.x,
		Vector3(-1, 0, 0) * radius * scale.x,
		Vector3(0, 1, 0) * radius * scale.y,
		Vector3(0, -1, 0) * radius * scale.y,
		Vector3(0, 0, 1) * radius * scale.z,
		Vector3(0, 0, -1) * radius * scale.z,
	]
	var pairs: Array = [
		[0, 2], [0, 3], [0, 4], [0, 5],
		[1, 2], [1, 3], [1, 4], [1, 5],
		[2, 4], [4, 3], [3, 5], [5, 2],
	]
	var edges: Array = []
	for p in pairs:
		edges.append([v[p[0]], v[p[1]]])
	return edges
