class_name MotionRibbonBuilder
extends RefCounted
## Geometria das Fitas (D-044) como dado puro: agrupa as amostras em fitas e gera vértices, cores, UVs e
## índices. Não conhece Node nem material (§2.1); a vista só os entrega ao ArrayMesh.
##
## Agrupamento (genérico, sem saber qual comportamento produziu as amostras):
## - por ramo; se todas as amostras do ramo têm a mesma idade, é uma fita de ESTADO ordenada por u
##   (o fluxo atual, cada ramo de bifurcação, cada pós-imagem);
## - se as idades variam (rastro), cada elemento (u, rest) é uma fita de HISTÓRIA ordenada por idade,
##   começando na amostra atual do mesmo elemento, para a fita não ter vão.
##
## Orientação (§19.4): base de rotação mínima (transporte paralelo) a partir da base da primeira amostra;
## tangente nula reaproveita a anterior; inversão brusca de direção não gira a fita.

const MIN_OPACITY := 0.001
const EPS := 1e-6


static func _drawn(s: MotionSample) -> bool:
	return s.visible and s.opacity > MIN_OPACITY


static func _less_u(a: MotionSample, b: MotionSample) -> bool:
	return a.u < b.u or (a.u == b.u and a.element_id < b.element_id)


static func _less_age(a: MotionSample, b: MotionSample) -> bool:
	return a.age < b.age or (a.age == b.age and a.element_id < b.element_id)


## Fitas como listas de amostras ordenadas (mínimo 2 pontos). Ordem determinística.
static func strips(samples: Array[MotionSample]) -> Array:
	var groups := {}
	var order: Array[String] = []
	for s in samples:
		if not groups.has(s.branch):
			groups[s.branch] = []
			order.append(s.branch)
		groups[s.branch].append(s)
	var heads := {}
	for s in samples:
		if s.age == 0.0:
			heads[[s.branch, s.u, s.rest.x, s.rest.y]] = s
	var out: Array = []
	for br in order:
		var g: Array = groups[br]
		var uniform := true
		for s in g:
			if s.age != (g[0] as MotionSample).age:
				uniform = false
				break
		if uniform:
			if g.size() >= 2:
				g.sort_custom(_less_u)
				out.append(g)
			continue
		var parent := br.substr(0, br.rfind("/")) if br.rfind("/") >= 0 else br
		var sub := {}
		var sub_order: Array = []
		for s in g:
			var key := [s.u, s.rest.x, s.rest.y]
			if not sub.has(key):
				sub[key] = []
				sub_order.append(key)
			sub[key].append(s)
		for key in sub_order:
			var st: Array = sub[key]
			st.sort_custom(_less_age)
			var head: Variant = heads.get([parent, key[0], key[1], key[2]])
			if head != null and (st[0] as MotionSample).age > 0.0:
				st.push_front(head)
			if st.size() >= 2:
				out.append(st)
	return out


## Resultado: vertices, colors, uvs, indices, aabb, strip_count, triangle_count.
static func build(samples: Array[MotionSample], base_width: float) -> Dictionary:
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var strip_count := 0
	for st in strips(samples):
		var base := verts.size()
		if not _emit(st, base_width, verts, cols, uvs, idx, base):
			continue
		strip_count += 1
		for i in range(base, verts.size()):
			lo = lo.min(verts[i])
			hi = hi.max(verts[i])
	var box := AABB()
	if not verts.is_empty():
		box = AABB(lo, hi - lo)
	return {"vertices": verts, "colors": cols, "uvs": uvs, "indices": idx, "aabb": box,
		"strip_count": strip_count, "triangle_count": idx.size() / 3}


## Acrescenta uma fita; false se for degenerada (todos os pontos coincidentes).
static func _emit(st: Array, base_width: float, verts: PackedVector3Array, cols: PackedColorArray,
		uvs: PackedVector2Array, idx: PackedInt32Array, base: int) -> bool:
	var n := st.size()
	var tang: Array[Vector3] = []
	tang.resize(n)
	var valid: Array[bool] = []
	valid.resize(n)
	for i in n:
		var a := st[maxi(i - 1, 0)] as MotionSample
		var b := st[mini(i + 1, n - 1)] as MotionSample
		var d := b.position - a.position
		valid[i] = d.length() > EPS
		tang[i] = d.normalized() if valid[i] else Vector3.ZERO
	var first := valid.find(true)
	if first < 0:
		return false
	for i in range(first - 1, -1, -1):  # início sem tangente: usa a primeira válida
		tang[i] = tang[first]
	for i in range(first + 1, n):  # tangente nula no meio: reaproveita a anterior
		if not valid[i]:
			tang[i] = tang[i - 1]

	var side := _perp_to(tang[0], (st[0] as MotionSample).basis.x)
	for i in n:
		var s := st[i] as MotionSample
		if i > 0:
			side = _perp_to(tang[i], side)
		var hw := 0.5 * base_width * maxf(s.width, 0.0)
		var col := MotionPointsView.branch_color(s.branch)
		var glow := clampf(s.intensity, 0.0, 1.5)
		var c := Color(col.r * glow, col.g * glow, col.b * glow, clampf(s.opacity, 0.0, 1.0) if s.visible else 0.0)
		verts.append(s.position - side * hw)
		verts.append(s.position + side * hw)
		cols.append(c)
		cols.append(c)
		var u := float(i) / float(maxi(n - 1, 1))
		uvs.append(Vector2(u, 0.0))
		uvs.append(Vector2(u, 1.0))
	for i in n - 1:
		if not (_drawn(st[i]) or _drawn(st[i + 1])):
			continue
		var a0 := base + 2 * i
		var b0 := base + 2 * (i + 1)
		idx.append_array(PackedInt32Array([a0, a0 + 1, b0, a0 + 1, b0 + 1, b0]))
	return true


## Vetor unitário perpendicular a `t`, o mais próximo possível de `hint` (transporte paralelo).
static func _perp_to(t: Vector3, hint: Vector3) -> Vector3:
	var p := hint - t * hint.dot(t)
	if p.length() > 1e-4:
		return p.normalized()
	var alt := Vector3.UP if absf(t.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	return t.cross(alt).normalized()
