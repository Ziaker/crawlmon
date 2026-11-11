class_name MotionPainter
extends Node3D
## D-308: the Motion Composer's drawing backend (spec section 8, D-044). A composition only produces motion data;
## representations (MotionRep) turn that data into pictures by calling these pooled primitives. Everything here
## uses what the game already has (fire / ash / glow / ring / scorch / streak shaders, 3D fire meshes) and works
## in GL Compatibility (no GPU particles). Nothing here knows a character, a team or a side (D-235).

var cam_pos_fn := Callable()  ## () -> Vector3, camera world position
var cam_basis_fn := Callable()  ## () -> Basis, camera world basis
var time := 0.0  ## effect time, explicit (never the engine clock)
var neutral := false  ## spec 8.3: neutral material (white unshaded dots) to judge the motion by itself

var _pool: Dictionary = {}
var _used: Dictionary = {}
var _prims: Dictionary = {}  ## D-337: shared meshes of the atelier primitives (cone4/5/7, funnel, frag_one, cyl)
var _lights: Array[OmniLight3D] = []
var _lights_used := 0

## D-377: perfil da lança da Drain Spear. y em 0..1; raios em metros (a mesma silhueta do protótipo de 6,4 m).
const SPEAR_LEVELS := [
	Vector3(0.000, 0.018, 0.018),
	Vector3(0.020, 0.150, 0.150),
	Vector3(0.042, 0.110, 0.110),
	Vector3(0.056, 0.080, 0.080),
	Vector3(0.078, 0.140, 0.140),
	Vector3(0.098, 0.145, 0.145),
	Vector3(0.600, 0.145, 0.145),
	Vector3(0.618, 0.250, 0.250),
	Vector3(0.634, 0.250, 0.250),
	Vector3(0.650, 0.180, 0.180),
	Vector3(0.675, 0.180, 0.180),
	Vector3(0.690, 0.340, 0.260),
	Vector3(0.720, 0.520, 0.330),
	Vector3(0.780, 0.440, 0.280),
	Vector3(0.860, 0.300, 0.210),
	Vector3(0.940, 0.160, 0.130),
	Vector3(1.000, 0.000, 0.000),
]



func begin_frame() -> void:
	for k in _used.keys():
		_used[k] = 0
	_lights_used = 0


## Custos do quadro desenhado (ferramentas de avaliação, D-323): nós visíveis, triângulos enviados ao desenho e nós por pincel.
func stats() -> Dictionary:
	var nodes := 0
	var tris := 0
	var by_key := {}
	for k in _pool.keys():
		var arr: Array = _pool[k]
		var used := int(_used.get(k, 0))
		by_key[k] = used
		for i in used:
			nodes += 1
			var mesh := (arr[i] as MeshInstance3D).mesh
			if mesh is ArrayMesh:
				var am := mesh as ArrayMesh
				for sidx in am.get_surface_count():
					var a := am.surface_get_arrays(sidx)
					var ix: Variant = a[Mesh.ARRAY_INDEX]
					tris += (ix as PackedInt32Array).size() / 3 if ix != null else 0
			elif mesh is SphereMesh:
				tris += 24 * 14 * 2
			else:
				tris += 2
	return {"nodes": nodes, "tris": tris, "by_key": by_key, "lights": _lights_used}


func end_frame() -> void:
	for k in _pool.keys():
		var arr: Array = _pool[k]
		for i in range(int(_used.get(k, 0)), arr.size()):
			(arr[i] as MeshInstance3D).visible = false
	for i in range(_lights_used, _lights.size()):
		_lights[i].visible = false
		_lights[i].light_energy = 0.0


func _cam_pos() -> Vector3:
	return cam_pos_fn.call() if cam_pos_fn.is_valid() else Vector3(0, 3, 8)


func cam_pos() -> Vector3:
	return _cam_pos()


func _cam_basis() -> Basis:
	return cam_basis_fn.call() if cam_basis_fn.is_valid() else Basis.IDENTITY


func _node(key: String, shader_name: String, kind := "quad") -> MeshInstance3D:
	if not _pool.has(key):
		_pool[key] = []
		_used[key] = 0
	var arr: Array = _pool[key]
	var i: int = _used[key]
	if i >= arr.size():
		var made := MeshInstance3D.new()
		if kind == "tube":
			made.mesh = ArrayMesh.new()
			made.extra_cull_margin = 16.0  # the arrays are rebuilt every frame in world space
		else:
			made.mesh = _prim(kind)
		made.material_override = VfxLib.shader_mat(shader_name, {})
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(made)
		arr.append(made)
	_used[key] = i + 1
	var mi: MeshInstance3D = arr[i]
	mi.visible = true
	return mi


## D-337: shared meshes of the atelier primitives. All of them are built around the origin with a radius of 0.5
## (or, for the cones, base on y = 0 and apex on y = 1) so a caller only sets the transform: the same fixed size in
## metres in every view (D-334). Never character, team or side (D-235).
func _prim(kind: String) -> Mesh:
	if _prims.has(kind):
		return _prims[kind]
	var m: Mesh
	match kind:
		"sphere":
			var sph := SphereMesh.new()
			sph.radius = 0.5
			sph.height = 1.0
			sph.radial_segments = 24
			sph.rings = 14
			m = sph
		"cyl", "cyl_pillar":
			var cm := CylinderMesh.new()
			cm.top_radius = 1.1
			cm.bottom_radius = 1.45
			cm.height = 6.8
			cm.radial_segments = 32
			cm.rings = 1
			cm.cap_top = false
			cm.cap_bottom = false
			m = cm
		"cyl_heal":  # Media: CylinderGeometry(1.25, 1.45, 7.5, 32, 1, true)
			var ch := CylinderMesh.new()
			ch.top_radius = 1.25
			ch.bottom_radius = 1.45
			ch.height = 7.5
			ch.radial_segments = 32
			ch.rings = 1
			ch.cap_top = false
			ch.cap_bottom = false
			m = ch
		"funnel":  # Sand Attack: CylinderGeometry(1.75, 0.55, 3.8, 32, 16, true)
			var fm := CylinderMesh.new()
			fm.top_radius = 1.75
			fm.bottom_radius = 0.55
			fm.height = 3.8
			fm.radial_segments = 32
			fm.rings = 16
			fm.cap_top = false
			fm.cap_bottom = false
			m = fm
		"cone4":
			m = _cone_mesh(4)
		"cone5":
			m = _cone_mesh(5)
		"cone7":
			m = _cone_mesh(7)
		"frag_one":
			m = _dodeca_mesh()
		"spear":  # D-377: malha fechada da lança (MotionMesh.spear), compartilhada por todas as instâncias
			var am := ArrayMesh.new()
			MotionMesh.upload(am, MotionMesh.spear(SPEAR_LEVELS, 8))
			m = am
		"spear_shaft":  # D-378: cabo que cresce; a lâmina é uma malha separada, fixa na ponta
			var ams := ArrayMesh.new()
			MotionMesh.upload(ams, MotionMesh.spear_shaft(8))
			m = ams
		"spear_blade":
			var amb := ArrayMesh.new()
			MotionMesh.upload(amb, MotionMesh.spear_blade(8))
			m = amb
		"aura":  # D-378: fita espiral procedural (a malha real é reconstruída por instância, por quadro)
			m = ArrayMesh.new()
		"vortex":  # D-379: vórtice helicoidal cônico do início da estocada (malha por instância)
			m = ArrayMesh.new()
		"vortex_cone":  # D-379: funil visível do boost (base larga, ponta fina)
			var vc := CylinderMesh.new()
			vc.top_radius = 0.06
			vc.bottom_radius = 1.0
			vc.height = 1.0
			vc.radial_segments = 48
			vc.rings = 24
			vc.cap_top = false
			vc.cap_bottom = false
			m = vc
		_:
			var q := QuadMesh.new()
			q.size = Vector2.ONE
			m = q
	_prims[kind] = m
	return m


## ConeGeometry(radius = 1, height = 1, sides) moved so the base sits on y = 0 and the apex on y = 1.
func _cone_mesh(sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := Vector3(0.0, 1.0, 0.0)
	for i in sides:
		var a0 := -float(i) / float(sides) * TAU
		var a1 := -float(i + 1) / float(sides) * TAU
		var p0 := Vector3(cos(a0), 0.0, sin(a0))
		var p1 := Vector3(cos(a1), 0.0, sin(a1))
		var nrm := (p1 - apex).cross(p0 - apex).normalized()
		st.set_normal(nrm)
		st.set_uv(Vector2(float(i) / float(sides), 1.0))
		st.add_vertex(p0)
		st.set_normal(nrm)
		st.set_uv(Vector2((float(i) + 0.5) / float(sides), 0.0))
		st.add_vertex(apex)
		st.set_normal(nrm)
		st.set_uv(Vector2(float(i + 1) / float(sides), 1.0))
		st.add_vertex(p1)
	return st.commit()


## DodecahedronGeometry(radius = 0.5, detail = 0) as the dual of an icosahedron (the atelier's crater rocks).
func _dodeca_mesh() -> ArrayMesh:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var v: Array[Vector3] = [
		Vector3(-1, phi, 0), Vector3(1, phi, 0), Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi), Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1), Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
	]
	var f: Array[int] = [
		0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
		1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
		3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
		4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
	]
	var dode: Array[Vector3] = []
	for fi in 20:
		var c := v[f[fi * 3]] + v[f[fi * 3 + 1]] + v[f[fi * 3 + 2]]
		dode.append(c.normalized() * 0.5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vi in 12:
		var ids: Array[int] = []
		for fi in 20:
			if f[fi * 3] == vi or f[fi * 3 + 1] == vi or f[fi * 3 + 2] == vi:
				ids.append(fi)
		var axis := v[vi].normalized()
		var center := Vector3.ZERO
		for fi in ids:
			center += dode[fi]
		center /= float(ids.size())
		var t0 := dode[ids[0]] - axis * axis.dot(dode[ids[0]])
		t0 = t0.normalized()
		var b0 := axis.cross(t0).normalized()
		ids.sort_custom(func(a: int, b: int) -> bool:
			var pa := dode[a] - axis * axis.dot(dode[a])
			var pb := dode[b] - axis * axis.dot(dode[b])
			return atan2(pa.dot(b0), pa.dot(t0)) < atan2(pb.dot(b0), pb.dot(t0)))
		for i in ids.size():
			var p0 := dode[ids[i]]
			var p1 := dode[ids[(i + 1) % ids.size()]]
			st.set_normal(axis)
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(center)
			st.set_normal(axis)
			st.set_uv(Vector2(0.0, 0.0))
			st.add_vertex(p0)
			st.set_normal(axis)
			st.set_uv(Vector2(1.0, 1.0))
			st.add_vertex(p1)
	return st.commit()


## Roll that points a flame's tip (+Y of the quad) along `world_dir` on screen.
func roll_for(world_dir: Vector3) -> float:
	var cb := _cam_basis()
	return atan2(-world_dir.dot(cb.x), world_dir.dot(cb.y))


func flame(pos: Vector3, size: float, intensity: float, roll: float, fade: float, blob: float, seed_ := 0.0, spark := false) -> void:
	if size <= 0.02 or fade >= 0.99:
		return
	if neutral:
		dot(pos, size * 0.3)
		return
	var mi := _node("flame", "fire_flame")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("roll", roll)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("blob", blob)
	mat.set_shader_parameter("seed", seed_)
	if spark:
		mat.set_shader_parameter("core", Color(1.0, 0.62, 0.16))
		mat.set_shader_parameter("hot", Color(1.0, 0.62, 0.16))
		mat.set_shader_parameter("mid", Color(1.0, 0.45, 0.08))
		mat.set_shader_parameter("edge", Color(0.92, 0.18, 0.04))


func glow(pos: Vector3, size: float, intensity: float) -> void:
	if size <= 0.05 or intensity <= 0.02 or neutral:
		return
	var mi := _node("glow", "fire_glow")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	(mi.material_override as ShaderMaterial).set_shader_parameter("intensity", intensity)


## Grey ash / smoke puff.
func smoke(pos: Vector3, size: float, alpha: float, seed_: float) -> void:
	if alpha <= 0.02 or neutral:
		return
	var mi := _node("ash", "fire_ash")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("alpha", alpha)
	mat.set_shader_parameter("seed", seed_)


## A streak of fire: long side along `dir_w`, facing the camera. fade 0..1.
func streak(center: Vector3, dir_w: Vector3, length: float, width: float, fade: float, hot := false) -> void:
	if length <= 0.02 or fade >= 0.99:
		return
	if neutral:
		dot(center, width)
		return
	var mi := _node("streak", "streak")
	var y := dir_w.normalized()
	var to_cam := (_cam_pos() - center).normalized()
	var z := to_cam - y * to_cam.dot(y)
	z = z.normalized() if z.length() > 0.001 else Vector3.UP
	var x := y.cross(z).normalized()
	mi.transform = Transform3D(Basis(x, y, z), center)
	mi.scale = Vector3(width, length, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("color", Color(1.0, 0.82, 0.35) if hot else Color(1.0, 0.5, 0.1))
	mat.set_shader_parameter("progress", fade)
	mat.set_shader_parameter("energy", 2.6 if hot else 2.0)


## 3D fire mesh (sphere, or a spindle along `axis` when `length` > 0).
func orb(pos: Vector3, radius: float, intensity: float, fade := 0.0, axis := Vector3.UP, length := 0.0, seed_ := 0.0, flow := 3.0) -> void:
	if radius <= 0.01 or intensity <= 0.02 or fade >= 0.99:
		return
	if neutral:
		dot(pos, radius)
		return
	var mi := _node("orb", "fire_orb", "sphere")
	var ax := axis.normalized()
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis, pos)
	mi.scale = Vector3(radius * 2.0, maxf(length, radius * 2.0), radius * 2.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("flow", flow)


## V1.1 (D-322): a real 3D flame tube. `data` comes from MotionMesh.tube (world-space arrays); `params` are the
## uniforms of shaders/mc_flame_body.gdshader (colours, flow, lick, ...). One pooled mesh per call.
func tube(data: Dictionary, params: Dictionary) -> void:
	if data.is_empty():
		return
	if neutral:
		var v: PackedVector3Array = data["vertices"]
		for i in range(0, v.size(), 40):
			dot(v[i], 0.05)
		return
	var mi := _node("tube", "mc_flame_body", "tube")
	if not MotionMesh.upload(mi.mesh as ArrayMesh, data):
		mi.visible = false
		return
	mi.transform = Transform3D.IDENTITY
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("use_uv_len", 1.0)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.10 (D-377): a lança mágica 3D da Drain Spear. `base` é o cabo; `axis` aponta para a ponta; `length` em metros
## estica só o eixo Y (a espessura fica em metros, então a lança alongada continua fina). `reveal`/`dissolve` vão de 0
## a 1 ao longo do cabo→ponta; `opacity` e `energy` são o brilho. Uma malha compartilhada, um material por instância.
func spear(base: Vector3, axis: Vector3, length: float, reveal: float, dissolve: float, opacity: float, energy: float, tint: Color, params := {}) -> void:
	if length <= 0.01 or opacity <= 0.01 or dissolve >= 0.999 or reveal <= 0.001:
		return
	if neutral:
		dot(base + axis.normalized() * length * 0.5, minf(length * 0.12, 0.5))
		return
	var mi := _node("spear", "mc_drain_spear", "spear")
	var ax := axis.normalized() if axis.length() > 0.001 else Vector3.UP
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis * Basis.from_scale(Vector3(1.0, length, 1.0)), base)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("reveal", clampf(reveal, 0.0, 1.0))
	mat.set_shader_parameter("dissolve", clampf(dissolve, 0.0, 1.0))
	mat.set_shader_parameter("opacity", clampf(opacity, 0.0, 1.0))
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("tt", time)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## D-378: desenha uma PARTE da lança (cabo ou lâmina). Cada parte tem a sua própria malha e o seu próprio
## reveal/dissolve; o cabo cresce sem esticar a lâmina. `part` = "shaft" | "blade".
func spear_part(base: Vector3, axis: Vector3, length: float, part: String, reveal: float, dissolve: float, opacity: float, energy: float, tint: Color, params := {}, thickness := 1.0) -> void:
	if length <= 0.01 or opacity <= 0.01 or dissolve >= 0.999 or reveal <= 0.001:
		return
	if neutral:
		dot(base + axis.normalized() * length * 0.5, minf(length * 0.12, 0.5))
		return
	var key := "spear_" + part
	var mi := _node(key, "mc_drain_spear", key)
	if part == "shaft":
		# D-378: o cabo é reconstruído com o comprimento real para o punho não esticar.
		var sm := mi.mesh as ArrayMesh
		if sm == null:
			sm = ArrayMesh.new()
			mi.mesh = sm
		MotionMesh.upload(sm, MotionMesh.spear_shaft_mesh(length, 8))
	var ax := axis.normalized() if axis.length() > 0.001 else Vector3.UP
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis * Basis.from_scale(Vector3(thickness, length, thickness)), base)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("reveal", clampf(reveal, 0.0, 1.0))
	mat.set_shader_parameter("dissolve", clampf(dissolve, 0.0, 1.0))
	mat.set_shader_parameter("opacity", clampf(opacity, 0.0, 1.0))
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("tt", time)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## D-378: uma faixa espiral de aura em volta da lança. A fita é reconstruída em coordenadas locais e girada para
## o eixo da lança; `phase` em radianos, `turns` voltas ao longo do comprimento. Sem personagem/time/lado (D-235).
func aura_band(base: Vector3, axis: Vector3, length: float, phase: float, turns: float, radius: float, width: float, opacity: float, energy: float, color: Color, params := {}) -> void:
	if length <= 0.05 or opacity <= 0.01 or radius <= 0.01:
		return
	if neutral:
		dot(base + axis.normalized() * length * 0.5, minf(length * 0.10, 0.4))
		return
	var mi := _node("aura", "mc_aura_band", "aura")
	var am := mi.mesh as ArrayMesh
	if am == null:
		am = ArrayMesh.new()
		mi.mesh = am
	MotionMesh.upload(am, MotionMesh.helix_band(length, radius, turns, phase, width, 64, true))
	var ax := axis.normalized() if axis.length() > 0.001 else Vector3.UP
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis, base)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("opacity", clampf(opacity, 0.0, 1.0))
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("tt", time)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## D-379: vórtice helicoidal cônico do começo da estocada. A fita começa larga na base do vórtice e afina na
## ponta, girando como um ventilador. O fade vem da opacidade da composição (após 0,4 s).
func vortex_band(base: Vector3, axis: Vector3, length: float, phase: float, turns: float, radius_start: float, radius_end: float, width: float, opacity: float, energy: float, color: Color, params := {}) -> void:
	if length <= 0.05 or opacity <= 0.01 or maxf(radius_start, radius_end) <= 0.01:
		return
	if neutral:
		dot(base + axis.normalized() * length * 0.5, minf(length * 0.10, 0.4))
		return
	var mi := _node("vortex", "mc_aura_band", "vortex")
	var am := mi.mesh as ArrayMesh
	if am == null:
		am = ArrayMesh.new()
		mi.mesh = am
	MotionMesh.upload(am, MotionMesh.helix_band(length, radius_start, turns, phase, width, 72, true, radius_end))
	var ax := axis.normalized() if axis.length() > 0.001 else Vector3.UP
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis, base)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("opacity", clampf(opacity, 0.0, 1.0))
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("tt", time)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## D-379: funil aditivo do boost. A base larga fica em `base` e a ponta fina em `base + axis*length`.
## O shader desenha as linhas espirais girando; é a parte mais visível do "vórtice drill".
func vortex_cone(base: Vector3, axis: Vector3, length: float, radius: float, opacity: float, energy: float, color: Color, params := {}) -> void:
	if length <= 0.05 or opacity <= 0.01 or radius <= 0.01:
		return
	if neutral:
		dot(base + axis.normalized() * length * 0.5, minf(length * 0.12, 0.5))
		return
	var mi := _node("vortex_cone", "mc_vortex_drill", "vortex_cone")
	var ax := axis.normalized() if axis.length() > 0.001 else Vector3.UP
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis * Basis.from_scale(Vector3(radius, length, radius)), base + ax * length * 0.5)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("opacity", clampf(opacity, 0.0, 1.0))
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("tt", time)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.1 (D-322): the flame shader on a sphere/spindle (the charge ball, the head). `axis`/`length` stretch it into a spindle.
func bulb(pos: Vector3, radius: float, axis: Vector3, length: float, params: Dictionary) -> void:
	if radius <= 0.01:
		return
	if neutral:
		dot(pos, radius)
		return
	var mi := _node("bulb", "mc_flame_body", "sphere")
	var ax := axis.normalized() if axis.length() > 0.01 else Vector3.UP
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis, pos)
	mi.scale = Vector3(radius * 2.0, maxf(length, radius * 2.0), radius * 2.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("use_uv_len", 0.0)
	mat.set_shader_parameter("sphere_radius", radius)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.1 (D-322): a game flipbook sprite (assets/vfx/flipbook_<sheet>.png), camera-facing, frame chosen by `progress` 0..1.
func flipbook(pos: Vector3, size: float, progress: float, sheet: String, color: Color, energy: float, roll_deg: float, tint := false) -> void:
	if size <= 0.02 or progress >= 0.999:
		return
	if neutral:
		dot(pos, size * 0.3)
		return
	var mi := _node("fb_" + sheet + ("_tint" if tint else ""), "mc_sprite_tint" if tint else "flipbook")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("sheet_tex", VfxLib.flipbook_tex(sheet))
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("progress", progress)
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("roll_rad", deg_to_rad(roll_deg))


## V1.2 (D-323): qualquer forma do compositor (tubo, fita, arco, casca, fragmentos) com o material estilizado `mc_surface`.
## `data` vem de MotionMesh.tube / MotionShapes.*; `params` são os uniforms de shaders/mc_surface.gdshader.
func surface(data: Dictionary, params: Dictionary, key := "surface", shader_name := "mc_surface") -> void:
	if data.is_empty() or _fully_dissolved(data):
		return
	if neutral:
		var v: PackedVector3Array = data["vertices"]
		for i in range(0, v.size(), 40):
			dot(v[i], 0.05)
		return
	var mi := _node(key, shader_name, "tube")
	if not MotionMesh.upload(mi.mesh as ArrayMesh, data):
		mi.visible = false
		return
	mi.transform = Transform3D.IDENTITY
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	if shader_name == "mc_surface":
		mat.set_shader_parameter("use_vcolor", 1.0)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## True when every vertex is already dissolved away (COLOR.b >= 0.99): nothing would be drawn, so no node is spent.
func _fully_dissolved(data: Dictionary) -> bool:
	for c in data["colors"] as PackedColorArray:
		if c.b < 0.99:
			return false
	return true


## V1.2: uma gota / bolha / pedra pequena (esfera esticada ao longo de `dir`) com o material estilizado.
func drop(pos: Vector3, radius: float, dir: Vector3, stretch: float, dissolve: float, params: Dictionary) -> void:
	if radius <= 0.004 or dissolve >= 0.99:
		return
	if neutral:
		dot(pos, radius * 2.0)
		return
	var mi := _node("drop", "mc_surface", "sphere")
	var ax := dir.normalized() if dir.length() > 0.01 else Vector3.DOWN
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis, pos)
	mi.scale = Vector3(radius * 2.0, radius * 2.0 * maxf(stretch, 1.0), radius * 2.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("use_vcolor", 0.0)
	mat.set_shader_parameter("u_radius", radius)
	mat.set_shader_parameter("u_dissolve", dissolve)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.2: fagulha / brasa (esticada ao longo do movimento na tela).
func spark(pos: Vector3, size: float, fade: float, stretch: float, roll: float, params: Dictionary) -> void:
	if size <= 0.004 or fade >= 0.99:
		return
	if neutral:
		dot(pos, size)
		return
	var mi := _node("spark", "mc_spark")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("stretch", stretch)
	mat.set_shader_parameter("roll", roll)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.2: nuvem estilizada (fumaça, vapor, poeira, névoa).
func puff(pos: Vector3, size: float, alpha: float, fade: float, seed_: float, roll: float, params: Dictionary) -> void:
	if size <= 0.02 or alpha <= 0.02 or fade >= 0.99:
		return
	if neutral:
		return
	var mi := _node("puff", "mc_puff")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("alpha", alpha)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("roll", roll)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.10 (D-377): luz pontual de curta duração para a lança e o impacto. A luz não decide nada: só ilumina a cena
## enquanto o efeito a desenha. Pool próprio, apagada no fim do quadro.
func light(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	if energy <= 0.01 or range_m <= 0.1 or neutral:
		return
	if _lights_used >= _lights.size():
		var l := OmniLight3D.new()
		l.shadow_enabled = false
		l.light_specular = 0.4
		add_child(l)
		_lights.append(l)
	var li := _lights[_lights_used]
	_lights_used += 1
	li.visible = true
	li.position = pos
	li.light_color = color
	li.light_energy = energy
	li.omni_range = range_m


## V1.2: halo de luz estilizado.
func halo(pos: Vector3, size: float, intensity: float, params: Dictionary) -> void:
	if size <= 0.05 or intensity <= 0.02 or neutral:
		return
	var mi := _node("halo", "mc_halo")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("intensity", intensity)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.2: marca decorativa no chão (queimado, poça, rachadura, arrasto).
func mark(center: Vector3, radius: float, fade: float, seed_: float, params: Dictionary) -> void:
	if radius <= 0.05 or fade >= 0.99 or neutral:
		return
	var mi := _node("mark", "mc_mark")
	mi.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(center.x, 0.035, center.z))
	mi.scale = Vector3(radius * 2.0, radius * 2.0, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("seed", seed_)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.3 (D-332): chama estilizada de contorno nítido (Persona / Genshin / Pokémon) no shader mc_fire_cel.
## `phase` é o ciclo de balanço (periódico); `roll` vira a ponta da chama; `fade` encolhe pelas pontas.
func cel_flame(pos: Vector3, size: float, fade: float, seed_: float, roll: float, phase: float, params: Dictionary) -> void:
	if size <= 0.02 or fade >= 0.99:
		return
	if neutral:
		dot(pos, size * 0.3)
		return
	var mi := _node("cel", "mc_fire_cel")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("phase", phase)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("roll", roll)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.3 (D-332): sprite de flipbook com mistura alfa (cores chapadas aparecem como são). `frame_pos` 0..1 = o ciclo inteiro.
func sprite(pos: Vector3, size: float, frame_pos: float, sheet: String, fade: float, roll: float, energy: float) -> void:
	if size <= 0.02 or fade >= 0.99:
		return
	if neutral:
		dot(pos, size * 0.3)
		return
	var mi := _node("sp_" + sheet, "mc_sprite")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("sheet_tex", VfxLib.flipbook_tex(sheet))
	mat.set_shader_parameter("frame_pos", fposmod(frame_pos, 1.0))
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("roll", roll)
	mat.set_shader_parameter("energy", energy)


## V1.4 (D-332): fogo como efeito (mc_fire_flow): campo de calor turbulento em degraus chapados (amarelo, laranja, vermelho,
## queimado, fuligem preta) com opacidade muito variável. Cada instância tem semente, velocidade e largura próprias.
func fire_flow(pos: Vector3, size: float, seed_: float, fade: float, speed: float, roll: float, params: Dictionary) -> void:
	if size <= 0.03 or fade >= 0.99:
		return
	if neutral:
		dot(pos, size * 0.3)
		return
	var mi := _node("flow", "mc_fire_flow")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("speed", speed)
	mat.set_shader_parameter("roll", roll)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.5 (D-332): UMA chama com ciclo de vida (mc_flame_one). `age` 0..1 é a vida inteira; `seed_` muda a forma (muda a cada ciclo).
func flame_one(pos: Vector3, size: float, age: float, seed_: float, params: Dictionary) -> void:
	if size <= 0.03 or age >= 0.995:
		return
	if neutral:
		dot(pos, size * 0.3)
		return
	var mi := _node("one", "mc_flame_one")
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("age", age)
	mat.set_shader_parameter("seed", seed_)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.7 (D-332, atelier / Splitter Flames): a bola de fogo do atelier (esfera com seno no vértice e cor por fresnel), mc_fireball.
func fireball(pos: Vector3, radius: float, seed_: float, params: Dictionary) -> void:
	if radius <= 0.01:
		return
	if neutral:
		dot(pos, radius)
		return
	var mi := _node("fireball", "mc_fireball", "sphere")
	mi.position = pos
	mi.scale = Vector3.ONE * radius * 2.0
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("seed", seed_)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.7: o vórtice de fogo do release (espiral achatada, mc_vortex_disc). `diameter` em metros; `normal` é a direção do disco.
func vortex_disc(pos: Vector3, normal: Vector3, diameter: float, progress: float, spin: float, params: Dictionary) -> void:
	if diameter <= 0.02 or progress >= 0.995:
		return
	if neutral:
		dot(pos, diameter * 0.3)
		return
	var mi := _node("vdisc", "mc_vortex_disc")
	var n := normal.normalized() if normal.length() > 0.01 else Vector3.FORWARD
	var up := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	mi.transform = Transform3D(Basis.looking_at(-n, up) * Basis(Vector3.BACK, spin), pos)
	mi.scale = Vector3(diameter, diameter, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("progress", progress)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## V1.7: o pilar de fogo do impacto (cilindro aberto, mc_pillar). `base` é o ponto no chão; `sxz` escala a largura.
func pillar(base: Vector3, sxz: float, progress: float, params: Dictionary) -> void:
	if progress >= 0.995 or sxz <= 0.01:
		return
	if neutral:
		dot(base + Vector3.UP * 1.0, 0.5)
		return
	var mi := _node("pillar", "mc_pillar", "cyl")
	mi.position = base + Vector3.UP * 3.4
	mi.scale = Vector3(sxz, 1.0, sxz)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("progress", progress)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])


## D-377: anel de choque ciano/branco da Drain Spear, virado para a câmera (`normal` = direção do olhar). `radius` em
## metros; `progress` 0..1 abre o anel; `fade` 0..1 apaga. Não é o ring de fogo.
func shock_ring(center: Vector3, normal: Vector3, radius: float, progress: float, fade: float, intensity: float, seed_ := 0.0, thick := 0.06) -> void:
	if radius <= 0.05 or fade >= 0.99 or intensity <= 0.02 or neutral:
		return
	var mi := _node("shock", "mc_shock_ring")
	var n := normal.normalized() if normal.length() > 0.01 else Vector3.FORWARD
	var up := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	mi.transform = Transform3D(Basis.looking_at(n, up), center)
	mi.scale = Vector3(radius / 0.78 * 2.0, radius / 0.78 * 2.0, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("fade", clampf(fade, 0.0, 1.0))
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("thick", thick)


func scorch(center: Vector3, radius: float, fade: float, intensity: float, seed_ := 0.0) -> void:
	if radius <= 0.05 or fade >= 0.99 or neutral:
		return
	var mi := _node("scorch", "fire_scorch")
	mi.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(center.x, 0.04, center.z))
	mi.scale = Vector3(radius * 2.0, radius * 2.0, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("seed", seed_)


func ring(center: Vector3, normal: Vector3, radius: float, fade: float, intensity: float, seed_ := 0.0, thick := 0.05, params := {}) -> void:
	if radius <= 0.02 or fade >= 0.99 or neutral:
		return
	var mi := _node("ring", "fire_ring")
	var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	mi.transform = Transform3D(Basis.looking_at(normal, up), center)
	mi.scale = Vector3(radius / 0.78 * 2.0, radius / 0.78 * 2.0, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", time)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("thick", thick)
	for k in params.keys():  # V1.12 (D-1026): optional look overrides (colours `orange` / `red`, `solid`, `dashes`); empty = the old look
		mat.set_shader_parameter(k, params[k])


## V1.13 (D-1026): a flat chrome plate (a straight-edged triangle) at `pos`, turned by `rot`, `size` metres, dissolving with `fade`.
func plate(pos: Vector3, size: float, rot: Basis, fade: float, seed_: float) -> void:
	if size <= 0.02 or fade >= 0.99 or neutral:
		return
	var mi := _node("plate", "mc_plate")
	mi.transform = Transform3D(rot.scaled(Vector3(size, size, size)), pos)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("seed", seed_)


## Neutral marker (spec 8.3): a plain unshaded white dot, to see the motion without any look.
func dot(pos: Vector3, size: float) -> void:
	var mi := _node("dot", "el_particle")
	mi.position = pos
	mi.scale = Vector3(maxf(size, 0.04), maxf(size, 0.04), 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("kind", 1)
