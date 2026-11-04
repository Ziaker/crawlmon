extends SceneTree
## Motion Composer V1 — Etapa 5, fatia 3: representação Fragmentos (D-044, D-305).
## Rodar: godot --headless --path . --script res://tests/motion_composer/test_etapa5_fragmentos.gd

const Op := MotionTypes.Op

var _fails: int = 0
var _checks: int = 0
var _cat: MotionCatalog


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func near(a: float, b: float, eps: float = 1e-5) -> bool:
	return absf(a - b) <= eps


func make_layer(id: StringName, bid: StringName, op: int, params: Dictionary = {}) -> MotionLayer:
	var l := MotionLayer.new()
	l.id = id
	l.behavior_id = bid
	l.op = op
	l.params = params
	return l


func burst_samples(t: float, n: int = 64) -> Array[MotionSample]:
	var c := MotionComposition.new()
	c.sample_count = n
	c.seed = 3
	c.add_layer(make_layer(&"h", &"M01", Op.REPLACE, {"radius": 0.25, "pitch": 0.5, "turns": 2.0}))
	c.add_layer(make_layer(&"b", &"M16", Op.OFFSET, {"radial": 1.0, "origin": Vector3(0, 0, 0.5), "cone_deg": 60.0, "distance": 1.0, "t_duration": 0.9, "t_start": 0.0}))
	return c.evaluate(_cat, c.make_context(t)).samples


func _init() -> void:
	print("\n=================================================================")
	print("   MOTION COMPOSER V1 — ETAPA 5 (fatia 3): FRAGMENTOS (D-305)")
	print("=================================================================")
	_cat = MotionCatalog.new()
	MotionBehaviors.register_all(_cat)
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	t_orientation()
	t_mesh()
	t_view()
	print("\n-- Independência de representação --")
	ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes_before, "a orientação dos fragmentos é função pura (não cria nós)")
	print("\n  Resultado: %d verificações, %d falhas" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func t_orientation() -> void:
	print("\n-- Orientação e tamanho por fragmento --")
	var s := MotionSample.make_rest(0.5, 11, 1.0)
	var b1 := MotionFragmentsView.fragment_basis(s, 0.05)
	var b2 := MotionFragmentsView.fragment_basis(s, 0.05)
	ok(b1 == b2, "determinístico: mesmo elemento, mesma orientação")
	var s2 := MotionSample.make_rest(0.5, 12, 1.0)
	ok(MotionFragmentsView.fragment_basis(s2, 0.05) != b1, "elementos diferentes recebem orientações diferentes")
	var seed_ok := true
	var scales := []
	var skew := false
	for id in 200:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		var b := MotionFragmentsView.fragment_basis(sm, 0.05)
		var k := b.x.length()
		scales.append(k)
		if not (near(b.y.length(), k, 1e-5) and near(b.z.length(), k, 1e-5)):
			skew = true
		if absf(b.x.normalized().dot(b.y.normalized())) > 1e-4 or b.determinant() <= 0.0:
			seed_ok = false
	ok(seed_ok and not skew, "bases ortogonais, sem espelhamento e com escala uniforme")
	var lo := 9.0
	var hi := 0.0
	for k in scales:
		lo = minf(lo, k)
		hi = maxf(hi, k)
	ok(lo >= 0.05 * 0.6 - 1e-6 and hi <= 0.05 * 1.4 + 1e-6 and hi - lo > 0.02, "tamanho varia de 60 %% a 140 %% do tamanho-base (%.3f a %.3f)" % [lo, hi])
	# direções (independentes do tamanho): giro cobre toda a volta; inclinação até 54° (±0,3·π) e nunca mais que isso
	var xs_min := 1.0
	var xs_max := -1.0
	var tilt_max := 0.0
	var tilt_sum := 0.0
	for id in 400:
		var sm := MotionSample.make_rest(0.0, id, 1.0)
		var bb := MotionFragmentsView.fragment_basis(sm, 0.05)
		xs_min = minf(xs_min, bb.x.normalized().x)
		xs_max = maxf(xs_max, bb.x.normalized().x)
		var ang := bb.z.normalized().angle_to(Vector3.BACK)
		tilt_max = maxf(tilt_max, ang)
		tilt_sum += ang
	ok(xs_min < -0.9 and xs_max > 0.9, "o giro em torno do eixo longo cobre toda a volta (x de %.2f a %.2f)" % [xs_min, xs_max])
	ok(tilt_max > deg_to_rad(45.0) and tilt_max <= deg_to_rad(54.0) + 1e-4 and tilt_sum / 400.0 > deg_to_rad(10.0), "a inclinação varia até 54° (máx. %.1f°)" % rad_to_deg(tilt_max))
	var w := MotionSample.make_rest(0.5, 11, 1.0)
	w.width = 2.0
	ok(near(MotionFragmentsView.fragment_basis(w, 0.05).x.length(), b1.x.length() * 2.0, 1e-5), "a largura da amostra multiplica o tamanho")
	w.width = 0.0
	ok(MotionFragmentsView.fragment_basis(w, 0.05).x.length() < 1e-9, "largura 0: tamanho 0")
	# a base da amostra manda: o eixo longo do fragmento acompanha a tangente quando não há giro aleatório
	var t_s := MotionSample.make_rest(0.5, 11, 1.0)
	t_s.basis = Basis(Vector3.UP, deg_to_rad(90.0))
	ok(MotionFragmentsView.fragment_basis(t_s, 0.05) != b1, "a orientação da amostra entra no resultado")


func t_mesh() -> void:
	print("\n-- Malha do fragmento --")
	var mesh := MotionFragmentsView.make_shard_mesh()
	ok(mesh.get_surface_count() == 1, "uma superfície")
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	ok(verts.size() == 18 and normals.size() == 18, "6 faces triangulares com vértices próprios (18) para facetas nítidas")
	var flat := true
	var outward := true
	var center := Vector3.ZERO
	for v in verts:
		center += v
	center /= float(verts.size())
	for f in 6:
		var n0: Vector3 = normals[3 * f]
		var a: Vector3 = verts[3 * f]
		var b: Vector3 = verts[3 * f + 1]
		var c: Vector3 = verts[3 * f + 2]
		if not (n0.is_equal_approx(normals[3 * f + 1]) and n0.is_equal_approx(normals[3 * f + 2])):
			flat = false
		if not near(n0.length(), 1.0, 1e-4) or n0.dot(((a + b + c) / 3.0) - center) <= 0.0:
			outward = false
		if not near(n0.dot((c - a).cross(b - a).normalized()), 1.0, 1e-3):  # enrolamento horário (frente do Godot)
			outward = false
	ok(flat, "normais planas por face")
	ok(outward, "normais unitárias, apontando para fora e coerentes com a ordem dos vértices")
	var box := mesh.get_aabb()
	ok(box.size.z > box.size.x * 1.5 and box.size.x > box.size.y * 2.0, "forma de estilhaço: comprido em Z, largo em X, fino em Y (%s)" % [box.size])
	ok(box.size.z <= 2.01 and box.size.x <= 1.0, "cabe numa caixa de 2 unidades de comprimento")


func t_view() -> void:
	print("\n-- Representação (MultiMesh + shader) --")
	var view := MotionFragmentsView.new()
	root.add_child(view)
	var s := burst_samples(0.5)
	view.show_samples(s)
	ok(view.shown_count == s.size(), "um fragmento por amostra visível (%d)" % view.shown_count)
	var mmi := view.get_child(0) as MultiMeshInstance3D
	var mat := mmi.multimesh.mesh.surface_get_material(0) as ShaderMaterial
	ok(mmi != null and mat != null and mat.shader.resource_path.ends_with(".gdshader") and mat.shader.code.contains("shader_type spatial"), "MultiMeshInstance3D com malha de estilhaço e ShaderMaterial .gdshader (spatial), sem HTML")
	ok(mmi.multimesh.use_colors and mmi.multimesh.transform_format == MultiMesh.TRANSFORM_3D, "transformação 3D e cor por instância")
	var hidden := burst_samples(0.5)
	hidden[0].visible = false
	hidden[1].opacity = 0.0
	hidden[2].width = 0.0
	view.show_samples(hidden)
	ok(view.shown_count == hidden.size() - 3, "invisíveis, transparentes e de tamanho 0 não são desenhados")
	view.show_samples([] as Array[MotionSample])
	ok(view.shown_count == 0, "sem amostras, nada desenhado")
	view.show_samples(burst_samples(0.9))
	var far := 0.0
	for smp in burst_samples(0.9):
		far = maxf(far, smp.position.distance_to(Vector3(0, 0, 0.5)))
	ok(far > 0.8, "a explosão espalha os elementos (até %.2f m do centro); os fragmentos seguem as posições" % far)
	var t0 := Time.get_ticks_usec()
	var big := burst_samples(0.6, 256)
	for i in 20:
		view.show_samples(big)
	print("  [INFO] preencher %d fragmentos: %.2f ms por quadro (GDScript, headless)" % [big.size(), float(Time.get_ticks_usec() - t0) / 20.0 / 1000.0])
	view.queue_free()
