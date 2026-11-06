extends SceneTree
## Motion Composer V1.2 (D-323): geradores de forma (fita, arco, casca, fragmentos). Dado puro, sem cena.
## godot --headless --path . --script res://tests/motion_composer/test_v12_formas.gd

var _fails := 0
var _checks := 0


func ok(cond: bool, name: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] ", name)
	else:
		_fails += 1
		print("  [FAIL] ", name)


func _init() -> void:
	_test_ribbon()
	_test_arc()
	_test_shell()
	_test_fragments()
	print("%d verificações, %d falhas" % [_checks, _fails])
	if _fails == 0:
		print("MC_V12_FORMAS_PASS")
	quit(1 if _fails > 0 else 0)


func _all_finite(d: Dictionary) -> bool:
	for v in d["vertices"] as PackedVector3Array:
		if not v.is_finite():
			return false
	for nn in d["normals"] as PackedVector3Array:
		if not nn.is_finite() or absf(nn.length() - 1.0) > 0.01:
			return false
	return true


func _in_range(d: Dictionary) -> bool:
	var n := (d["vertices"] as PackedVector3Array).size()
	for i in d["indices"] as PackedInt32Array:
		if i < 0 or i >= n:
			return false
	return (d["indices"] as PackedInt32Array).size() % 3 == 0


func _line(n: int) -> PackedVector3Array:
	var p := PackedVector3Array()
	for i in n:
		p.append(Vector3(0, 0, -float(i) * 0.5))
	return p


func _test_ribbon() -> void:
	var n := 8
	var w := PackedFloat32Array()
	for i in n:
		w.append(0.4 * sin(PI * float(i) / float(n - 1)) + 0.05)
	var d := MotionShapes.ribbon(_line(n), w, Vector3.UP)
	ok(not d.is_empty() and (d["vertices"] as PackedVector3Array).size() == n * 2, "fita: 2 vértices por ponto")
	ok((d["indices"] as PackedInt32Array).size() == (n - 1) * 6 and _in_range(d), "fita: 2 triângulos por segmento, índices válidos")
	ok(_all_finite(d), "fita: vértices e normais finitos e unitários")
	ok(absf(float(d["length"]) - 3.5) < 1e-4, "fita: comprimento em metros")
	var v: PackedVector3Array = d["vertices"]
	ok(absf(v[6].distance_to(v[7]) - w[3]) < 1e-4, "fita: a largura do ponto é a pedida")
	ok(absf((d["normals"] as PackedVector3Array)[0].dot(Vector3.UP)) > 0.99, "fita: a normal olha para `face`")
	var par := MotionShapes.ribbon(_line(4), PackedFloat32Array([0.1, 0.1, 0.1, 0.1]), Vector3(0, 0, 1))
	ok(not par.is_empty() and _all_finite(par), "fita: `face` paralela à tangente não gera NaN")
	ok(MotionShapes.ribbon(_line(1), PackedFloat32Array([0.1])).is_empty(), "fita: um ponto só é recusado")
	ok(MotionShapes.ribbon(_line(3), PackedFloat32Array([0.1])).is_empty(), "fita: larguras de tamanho errado são recusadas")
	var dis := PackedFloat32Array([0.0, 0.5, 1.0, 2.0])
	var dd := MotionShapes.ribbon(_line(4), PackedFloat32Array([0.1, 0.1, 0.1, 0.1]), Vector3.UP, dis)
	ok(((dd["colors"] as PackedColorArray)[6]).b <= 1.0, "fita: a dissolução é limitada a 1")


func _test_arc() -> void:
	var d := MotionShapes.arc(Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 120.0, 0.5, 24)
	ok(not d.is_empty() and _all_finite(d) and _in_range(d), "arco: gera malha válida")
	ok(absf(float(d["length"]) - 2.0 * deg_to_rad(120.0)) < 0.05, "arco: comprimento ≈ raio × varredura (%.3f)" % float(d["length"]))
	var v: PackedVector3Array = d["vertices"]
	ok(v[0].distance_to(v[1]) < 0.01 and v[v.size() - 1].distance_to(v[v.size() - 2]) < 0.01, "arco: afina nas duas pontas")
	var mid := v.size() / 2
	ok(v[mid - 1].distance_to(v[mid]) > 0.3, "arco: a largura é máxima no meio")
	for p in v:
		ok(absf(p.y) < 0.3 and absf(Vector2(p.x, p.z).length() - 2.0) < 0.3, "arco: fica sobre o círculo do raio pedido") if p == v[mid] else null
	ok(MotionShapes.arc(Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 0.0, 90.0, 0.2).is_empty(), "arco: raio zero é recusado")
	var para := MotionShapes.arc(Vector3.ZERO, Vector3.UP, Vector3.UP, 1.0, 90.0, 0.2)
	ok(not para.is_empty() and _all_finite(para), "arco: direção inicial paralela ao eixo não gera NaN")


func _test_shell() -> void:
	var d := MotionShapes.shell(Vector3.ZERO, Vector3.UP, 2.0, 1.0, 1.0, 8, 16)
	ok(not d.is_empty() and _all_finite(d) and _in_range(d), "casca: malha válida")
	ok((d["vertices"] as PackedVector3Array).size() == 9 * 17, "casca: (anéis+1) × (lados+1) vértices")
	var v: PackedVector3Array = d["vertices"]
	var apex_r := Vector2(v[0].x, v[0].z).length()
	var base_r := Vector2(v[8 * 17].x, v[8 * 17].z).length()
	ok(apex_r < 1e-5 and absf(base_r - 1.0) < 1e-4, "casca: fecha no ápice e abre no raio da base")
	ok(absf(v[8 * 17].y - 2.0) < 1e-5, "casca: altura pedida")
	var dome := MotionShapes.shell(Vector3.ZERO, Vector3.UP, 1.0, 1.0, 0.5, 8, 16)
	var cone := MotionShapes.shell(Vector3.ZERO, Vector3.UP, 1.0, 1.0, 1.0, 8, 16)
	ok(Vector2((dome["vertices"] as PackedVector3Array)[4 * 17].x, (dome["vertices"] as PackedVector3Array)[4 * 17].z).length() > Vector2((cone["vertices"] as PackedVector3Array)[4 * 17].x, (cone["vertices"] as PackedVector3Array)[4 * 17].z).length(), "casca: perfil < 1 é cúpula (mais larga que o cone na metade)")
	var tilted := MotionShapes.shell(Vector3(1, 1, 1), Vector3(0, 0, -1), 1.5, 0.6, 1.0, 6, 12)
	ok(not tilted.is_empty() and _all_finite(tilted), "casca: eixo qualquer (independente de lado, D-235)")
	ok(MotionShapes.shell(Vector3.ZERO, Vector3.UP, 0.0, 1.0).is_empty(), "casca: altura zero é recusada")


func _test_fragments() -> void:
	var c := PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(2, 1, 0)])
	var s := PackedFloat32Array([0.3, 0.5, 0.2])
	var d := MotionShapes.fragments(c, s, 11, 0.35)
	ok(not d.is_empty() and _in_range(d), "fragmentos: malha válida")
	ok((d["vertices"] as PackedVector3Array).size() == 3 * 24 and (d["indices"] as PackedInt32Array).size() == 3 * 36, "fragmentos: 6 faces planas (24 vértices, 12 triângulos) por pedra")
	ok(_all_finite(d), "fragmentos: vértices e normais finitos e unitários")
	var again := MotionShapes.fragments(c, s, 11, 0.35)
	ok((d["vertices"] as PackedVector3Array) == (again["vertices"] as PackedVector3Array), "fragmentos: determinístico com a mesma semente")
	var other := MotionShapes.fragments(c, s, 12, 0.35)
	ok((d["vertices"] as PackedVector3Array) != (other["vertices"] as PackedVector3Array), "fragmentos: semente diferente, pedras diferentes")
	var v: PackedVector3Array = d["vertices"]
	var far_ok := true
	for i in 24:
		far_ok = far_ok and v[i].distance_to(c[0]) <= 0.3 * 1.6
	ok(far_ok, "fragmentos: cada pedra fica perto do seu centro (tamanho respeitado)")
	var flat := MotionShapes.fragments(c, s, 11, 0.0)
	ok(not flat.is_empty() and _all_finite(flat), "fragmentos: irregularidade 0 (cubos) válida")
	var spun := MotionShapes.fragments(c, s, 11, 0.35, PackedFloat32Array([0.5, 1.0, 1.5]))
	ok((spun["vertices"] as PackedVector3Array) != (d["vertices"] as PackedVector3Array) and _all_finite(spun), "fragmentos: o giro do compositor muda a pose")
	var gone := MotionShapes.fragments(c, PackedFloat32Array([0.0, 0.5, 0.0]), 11)
	ok((gone["vertices"] as PackedVector3Array).size() == 24, "fragmentos: tamanho 0 não gera pedra")
	ok(MotionShapes.fragments(PackedVector3Array(), PackedFloat32Array(), 1).is_empty(), "fragmentos: lista vazia")
