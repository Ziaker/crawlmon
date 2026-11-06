class_name MotionShapes
extends RefCounted
## Motion Composer V1.2 (D-323): geradores de forma reutilizáveis (D-274 item 4): FITA, LÂMINA, ARCO, CASCA e
## CONJUNTO DE FRAGMENTOS (o TUBO CURVO está em MotionMesh.tube). Dado puro: pontos e parâmetros entram, arrays saem,
## sem Node, sem material, sem relógio (spec 2.1). Todas usam o MESMO layout de vértice do tubo (ver MotionMesh), então
## uma família de shaders serve a todas:
##   UV.x   através da forma, 0..1 (ou ângulo, 0..1)
##   UV.y   metros ao longo da forma
##   COLOR  r = posição ao longo (0 cauda .. 1 cabeça), g = intensidade, b = dissolução 0..1, a = meia-largura/raio em metros
## O movimento vem do compositor (as amostras); largura, espessura e deformação variam por amostra.


class Builder:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()

	func vertex(p: Vector3, n: Vector3, uv: Vector2, c: Color) -> int:
		verts.append(p)
		norms.append(n)
		uvs.append(uv)
		cols.append(c)
		return verts.size() - 1

	func tri(a: int, b: int, c: int) -> void:
		idx.append_array(PackedInt32Array([a, b, c]))

	func quad(a: int, b: int, c: int, d: int) -> void:
		idx.append_array(PackedInt32Array([a, b, c, a, c, d]))

	func data() -> Dictionary:
		if verts.is_empty() or idx.is_empty():
			return {}
		return {"vertices": verts, "normals": norms, "uvs": uvs, "colors": cols, "indices": idx, "rings": 0, "length": 0.0}


static func _tangents(pts: PackedVector3Array) -> PackedVector3Array:
	var n := pts.size()
	var t := PackedVector3Array()
	t.resize(n)
	for i in n:
		var d := pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]
		t[i] = d.normalized() if d.length_squared() > 1e-10 else (t[i - 1] if i > 0 else Vector3.FORWARD)
	return t


## FITA / LÂMINA: faixa plana ao longo de `pts` com largura por ponto. `face` é a normal da faixa (a direção para onde
## ela "olha"); com `face` nula usa +Y. Largura em metros (meia-largura = widths[i] / 2). Lâmina = fita com perfil de folha.
static func ribbon(pts: PackedVector3Array, widths: PackedFloat32Array, face := Vector3.UP, dissolve := PackedFloat32Array(), intensity := PackedFloat32Array()) -> Dictionary:
	var n := pts.size()
	if n < 2 or widths.size() != n:
		return {}
	var tans := _tangents(pts)
	var b := Builder.new()
	var run := 0.0
	var prev_side := Vector3.ZERO
	var rows: Array[Vector2i] = []
	for i in n:
		if i > 0:
			run += pts[i].distance_to(pts[i - 1])
		var f := face.normalized() if face.length_squared() > 1e-8 else Vector3.UP
		var side := tans[i].cross(f)
		if side.length_squared() < 1e-8:
			side = prev_side if prev_side != Vector3.ZERO else tans[i].cross(Vector3.RIGHT)
		side = side.normalized()
		prev_side = side
		var nrm := side.cross(tans[i]).normalized()
		var half := maxf(widths[i], 0.0) * 0.5
		var col := Color(float(i) / float(n - 1), intensity[i] if intensity.size() == n else 1.0, clampf(dissolve[i] if dissolve.size() == n else 0.0, 0.0, 1.0), half)
		var l := b.vertex(pts[i] - side * half, nrm, Vector2(0.0, run), col)
		var r := b.vertex(pts[i] + side * half, nrm, Vector2(1.0, run), col)
		rows.append(Vector2i(l, r))
	for i in n - 1:
		b.quad(rows[i].x, rows[i + 1].x, rows[i + 1].y, rows[i].y)
	var d := b.data()
	if not d.is_empty():
		d["length"] = run
		d["rings"] = n
	return d


## ARCO: faixa curva sobre um círculo (meia-lua, marca de corte, crescente). `axis` é o eixo do círculo (normal do plano),
## `start_dir` a direção do começo do arco; varre `sweep_deg`. A largura segue sin(pi*u)^taper (afina nas duas pontas).
static func arc(center: Vector3, axis: Vector3, start_dir: Vector3, radius: float, sweep_deg: float, width: float, segments := 24, taper := 0.8,
		dissolve := 0.0, intensity := 1.0) -> Dictionary:
	if radius <= 0.0 or segments < 2:
		return {}
	var ax := axis.normalized() if axis.length_squared() > 1e-8 else Vector3.UP
	var s0 := start_dir - ax * start_dir.dot(ax)
	s0 = s0.normalized() if s0.length_squared() > 1e-8 else ax.cross(Vector3.RIGHT).normalized()
	var pts := PackedVector3Array()
	var ws := PackedFloat32Array()
	for i in segments + 1:
		var u := float(i) / float(segments)
		var a := deg_to_rad(sweep_deg) * u
		pts.append(center + (s0 * cos(a) + ax.cross(s0) * sin(a)) * radius)
		ws.append(width * pow(maxf(sin(PI * u), 0.0), taper))
	var dis := PackedFloat32Array()
	var inten := PackedFloat32Array()
	for i in pts.size():
		dis.append(dissolve)
		inten.append(intensity)
	return ribbon(pts, ws, ax, dis, inten)


## CASCA: superfície de revolução oca em torno de `axis` a partir de `apex` (cone, cúpula, coroa de chama, onda de
## choque). `profile(t)` dá o raio em t = 0..1 ao longo da altura: com `profile_pow` p, raio = base_radius * t^p
## (p < 1 = cúpula, p = 1 = cone, p > 1 = trombeta). `open` = 1 deixa a boca aberta, 0 não importa (a casca é sempre aberta
## na base). Reta, sem espessura: o volume vem do shader (borda, fresnel, erosão).
static func shell(apex: Vector3, axis: Vector3, height: float, base_radius: float, profile_pow := 1.0, rings := 10, sides := 20,
		dissolve := 0.0, intensity := 1.0) -> Dictionary:
	if height <= 0.0 or base_radius <= 0.0 or rings < 2 or sides < 3:
		return {}
	var ax := axis.normalized() if axis.length_squared() > 1e-8 else Vector3.UP
	var ref := Vector3.UP if absf(ax.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var e1 := ax.cross(ref).normalized()
	var e2 := ax.cross(e1)
	var b := Builder.new()
	var stride := sides + 1
	for r in rings + 1:
		var t := float(r) / float(rings)
		var rad := base_radius * pow(t, profile_pow)
		for j in stride:
			var f := float(j) / float(sides)
			var a := f * TAU
			var dir := e1 * cos(a) + e2 * sin(a)
			var slope := base_radius * profile_pow * pow(maxf(t, 1e-3), profile_pow - 1.0) / height
			var nrm := (dir - ax * slope).normalized()
			b.vertex(apex + ax * (height * t) + dir * rad, nrm, Vector2(f, height * t), Color(1.0 - t, intensity, clampf(dissolve, 0.0, 1.0), rad))
	for r in rings:
		for j in sides:
			var a0 := r * stride + j
			b.quad(a0, a0 + stride, a0 + stride + 1, a0 + 1)
	var d := b.data()
	if not d.is_empty():
		d["length"] = height
		d["rings"] = rings + 1
	return d


## CONJUNTO DE FRAGMENTOS: pedras/estilhaços de baixa contagem de polígonos, cada um um bloco irregular de faces PLANAS
## (cel-shading lê bem faces chapadas), numa malha só. `centers`/`sizes`: um por fragmento; a rotação e a irregularidade vêm
## de `seed` + índice (determinístico). `spin`: rotação extra por fragmento em radianos (vem do compositor, no tempo).
## `dissolve`/`intensity` por fragmento (vazios = 0 / 1). irregularity 0 = cubo, 1 = muito torto.
static func fragments(centers: PackedVector3Array, sizes: PackedFloat32Array, seed_value: int, irregularity := 0.35, spin := PackedFloat32Array(),
		dissolve := PackedFloat32Array(), intensity := PackedFloat32Array()) -> Dictionary:
	var n := centers.size()
	if n == 0 or sizes.size() != n:
		return {}
	var b := Builder.new()
	var corner := [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]
	var faces := [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [3, 7, 6, 2], [0, 4, 7, 3], [1, 2, 6, 5]]
	for i in n:
		var sz := maxf(sizes[i], 0.0)
		if sz <= 0.0:
			continue
		var cs: Array[Vector3] = []
		for k in 8:
			var jx := MotionHash.float01(seed_value, i, k, 1) - 0.5
			var jy := MotionHash.float01(seed_value, i, k, 2) - 0.5
			var jz := MotionHash.float01(seed_value, i, k, 3) - 0.5
			cs.append(corner[k] * 0.5 + Vector3(jx, jy, jz) * irregularity)
		var ang := Vector3(MotionHash.float01(seed_value, i, 0, 4), MotionHash.float01(seed_value, i, 0, 5), MotionHash.float01(seed_value, i, 0, 6)) * TAU
		var rot := Basis.from_euler(ang)
		if spin.size() == n:
			rot = Basis(Vector3(MotionHash.float01(seed_value, i, 0, 7) - 0.5, 1.0, MotionHash.float01(seed_value, i, 0, 8) - 0.5).normalized(), spin[i]) * rot
		var dis := clampf(dissolve[i] if dissolve.size() == n else 0.0, 0.0, 1.0)
		var inten := intensity[i] if intensity.size() == n else 1.0
		for f in faces:
			var p0: Vector3 = rot * (cs[f[0]] * sz)
			var p1: Vector3 = rot * (cs[f[1]] * sz)
			var p2: Vector3 = rot * (cs[f[2]] * sz)
			var p3: Vector3 = rot * (cs[f[3]] * sz)
			var nrm := (p1 - p0).cross(p3 - p0).normalized()
			if nrm.length_squared() < 0.5:
				nrm = (p2 - p1).cross(p0 - p1).normalized()
			var col := Color(0.5, inten, dis, sz * 0.5)
			var v0 := b.vertex(centers[i] + p0, nrm, Vector2(0, 0), col)
			var v1 := b.vertex(centers[i] + p1, nrm, Vector2(1, 0), col)
			var v2 := b.vertex(centers[i] + p2, nrm, Vector2(1, 1), col)
			var v3 := b.vertex(centers[i] + p3, nrm, Vector2(0, 1), col)
			b.quad(v0, v1, v2, v3)
	var d := b.data()
	if not d.is_empty():
		d["rings"] = 0
	return d
