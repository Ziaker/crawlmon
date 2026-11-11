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


## V1.10 (D-377): malha de lança em revolução. `levels` = [Vector3(y, rx, rz)] com y em 0..1 e os raios em METROS
## (a mesma escala do protótipo: 6,4 m de comprimento). O comprimento é aplicado depois no pincel, no eixo Y; os raios
## ficam em metros para a lança poder esticar sem engordar. Fecha a base e a ponta quando o raio não é zero.
static func spear(levels: Array, sides := 8) -> Dictionary:
	var n := levels.size()
	if n < 2 or sides < 3:
		return {}
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	for r in n:
		var lev: Vector3 = levels[r]
		var y := lev.x
		var rx := maxf(lev.y, MIN_RADIUS)
		var rz := maxf(lev.z, MIN_RADIUS)
		var prev: Vector3 = levels[maxi(r - 1, 0)]
		var next: Vector3 = levels[mini(r + 1, n - 1)]
		var dy := next.x - prev.x
		var drx := next.y - prev.y
		var drz := next.z - prev.z
		for j in sides:
			var a := TAU * float(j) / float(sides)
			var ca := cos(a)
			var sa := sin(a)
			verts.append(Vector3(ca * rx, y, sa * rz))
			# Tangente do anel x tangente do perfil = normal da superfície.
			var ring := Vector3(-sa * rx, 0.0, ca * rz)
			var profile := Vector3(drx * ca, dy, drz * sa)
			var nrm := ring.cross(profile)
			if nrm.length_squared() < 1e-10:
				nrm = Vector3(ca, 0.0, sa)
			nrm = nrm.normalized()
			if nrm.dot(Vector3(ca, 0.0, sa)) < 0.0:
				nrm = -nrm
			norms.append(nrm)
			uvs.append(Vector2(float(j) / float(sides), y))
			cols.append(Color(y, 1.0, 0.0, rx))
	var idxs := PackedInt32Array()
	for r in n - 1:
		for j in sides:
			var a0 := r * sides + j
			var a1 := r * sides + (j + 1) % sides
			var b0 := (r + 1) * sides + j
			var b1 := (r + 1) * sides + (j + 1) % sides
			idxs.append_array(PackedInt32Array([a0, b0, a1, a1, b0, b1]))
	# Tampa da base (o cabo não fica oco).
	var base_i := verts.size()
	verts.append(Vector3(0.0, float((levels[0] as Vector3).x), 0.0))
	norms.append(Vector3.DOWN)
	uvs.append(Vector2(0.5, 0.0))
	cols.append(Color(0.0, 1.0, 0.0, 0.0))
	for j in sides:
		idxs.append_array(PackedInt32Array([base_i, (j + 1) % sides, j]))
	# Tampa da ponta (só se o último nível tiver raio).
	var last: Vector3 = levels[n - 1]
	if last.y > MIN_RADIUS * 2.0 or last.z > MIN_RADIUS * 2.0:
		var tip_i := verts.size()
		verts.append(Vector3(0.0, last.x, 0.0))
		norms.append(Vector3.UP)
		uvs.append(Vector2(0.5, 1.0))
		cols.append(Color(1.0, 1.0, 0.0, 0.0))
		var first_i := (n - 1) * sides
		for j in sides:
			idxs.append_array(PackedInt32Array([tip_i, first_i + j, first_i + (j + 1) % sides]))
	return {"vertices": verts, "normals": norms, "uvs": uvs, "colors": cols, "indices": idxs, "rings": n, "length": 1.0}


## D-378: perfil do CABO (local y 0..1) e da LÂMINA (local y 0..1), separados para o cabo crescer e a lâmina
## continuar fixa na ponta. Raios em METROS: o cabo é fino e a lâmina tem a largura de uma folha.
const SHAFT_LEVELS := [
	Vector3(0.000, 0.020, 0.020),
	Vector3(0.014, 0.155, 0.155),
	Vector3(0.032, 0.112, 0.112),
	Vector3(0.048, 0.082, 0.082),
	Vector3(0.085, 0.145, 0.145),
	Vector3(0.105, 0.145, 0.145),
	Vector3(0.940, 0.145, 0.145),
	Vector3(0.975, 0.185, 0.185),
	Vector3(1.000, 0.170, 0.170),
]
const BLADE_LEVELS := [
	Vector3(0.000, 0.110, 0.110),
	Vector3(0.035, 0.205, 0.170),
	Vector3(0.090, 0.330, 0.160),
	Vector3(0.175, 0.300, 0.135),
	Vector3(0.330, 0.240, 0.115),
	Vector3(0.560, 0.180, 0.090),
	Vector3(0.780, 0.120, 0.062),
	Vector3(0.920, 0.070, 0.040),
	Vector3(1.000, 0.000, 0.000),
]


static func spear_shaft(sides := 8) -> Dictionary:
	return spear(SHAFT_LEVELS, sides)


## D-378: cabo com comprimento REAL. O punho e a ponteira ficam com medidas fixas em metros; só o miolo
## entre eles cresce. Devolve y normalizado em 0..1 (o pincel aplica a escala Y = comprimento), então o
## detalhe do punho não estica quando a lança vai de 2,7 m a ~16 m.
static func spear_shaft_mesh(length: float, sides := 8) -> Dictionary:
	var l := maxf(length, 0.2)
	var fixed := [
		Vector3(0.000, 0.020, 0.020),
		Vector3(0.020, 0.155, 0.155),
		Vector3(0.045, 0.112, 0.112),
		Vector3(0.070, 0.082, 0.082),
		Vector3(0.120, 0.145, 0.145),
		Vector3(0.160, 0.145, 0.145),
	]
	var levels: Array[Vector3] = []
	if l <= 0.6:
		levels.append(Vector3(0.0, 0.145, 0.145))
		levels.append(Vector3(l, 0.145, 0.145))
	else:
		for v in fixed:
			levels.append(v)
		levels.append(Vector3(l - 0.20, 0.145, 0.145))
		levels.append(Vector3(l - 0.08, 0.185, 0.185))
		levels.append(Vector3(l, 0.170, 0.170))
	var norm: Array[Vector3] = []
	for v in levels:
		norm.append(Vector3(v.x / l, v.y, v.z))
	return spear(norm, sides)


static func spear_blade(sides := 8) -> Dictionary:
	return spear(BLADE_LEVELS, sides)


## D-378: faixa espiral (aura) em volta de +Y. `length` em metros no eixo Y; `radius`/`width` em metros.
## A fita é construída em coordenadas locais (base em y=0, ponta em y=length) e o pincel aplica a rotação/base.
## UV.x = ao longo da fita (0..1), UV.y = através da largura (0..1); a normal aponta para fora do eixo (iluminação).
static func helix_band(length: float, radius: float, turns: float, phase: float, width: float, segments := 64, taper := true, radius_end := -1.0) -> Dictionary:
	var n := maxi(segments, 6)
	var l := maxf(length, 0.001)
	var r := maxf(radius, 0.001)
	var r1 := maxf(radius_end, 0.001) if radius_end >= 0.0 else r
	var w := maxf(width, 0.001)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idxs := PackedInt32Array()
	var dr := r1 - r
	for i in n + 1:
		var u := float(i) / float(n)
		var ang := phase + u * turns * TAU
		var ca := cos(ang)
		var sa := sin(ang)
		var rr := lerpf(r, r1, u)
		var c := Vector3(ca * rr, u * l, sa * rr)
		var radial := Vector3(ca, 0.0, sa)
		var tan := Vector3(-sa * rr * turns * TAU + ca * dr, l, ca * rr * turns * TAU + sa * dr)
		tan = tan.normalized() if tan.length_squared() > 1e-10 else Vector3.UP
		var side := tan.cross(radial)
		side = side.normalized() if side.length_squared() > 1e-10 else Vector3.UP
		var tw := w * (pow(sin(PI * u), 0.55) if taper else 1.0)
		verts.append(c - side * tw * 0.5)
		verts.append(c + side * tw * 0.5)
		norms.append(radial)
		norms.append(radial)
		uvs.append(Vector2(u, 0.0))
		uvs.append(Vector2(u, 1.0))
		cols.append(Color(u, 1.0, 0.0, 1.0))
		cols.append(Color(u, 1.0, 0.0, 1.0))
	for i in n:
		var a := i * 2
		idxs.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
	return {"vertices": verts, "normals": norms, "uvs": uvs, "colors": cols, "indices": idxs, "rings": n + 1, "length": l}


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
