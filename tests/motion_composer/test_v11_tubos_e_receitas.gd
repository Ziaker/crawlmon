extends SceneTree
## Motion Composer V1.1 (D-322): geometria de tubo (MotionMesh) e as camadas do fogo refeito. Sem relógio, sem cena.
## godot --headless --path . --script res://tests/motion_composer/test_v11_tubos_e_receitas.gd

var failures := 0


func _init() -> void:
	_test_tube_basic()
	_test_tube_degenerate()
	_test_tube_mirror_independent()
	_test_fire_effect_layers()
	if failures == 0:
		print("MC_V11_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _line(n: int, dir: Vector3) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in n:
		pts.append(dir * float(i) * 0.5)
	return pts


func _test_tube_basic() -> void:
	var n := 10
	var pts := _line(n, Vector3.FORWARD)
	var rad := PackedFloat32Array()
	for i in n:
		rad.append(0.1 + 0.02 * float(i))
	var d := MotionMesh.tube(pts, rad, PackedFloat32Array(), PackedFloat32Array(), 8, 3)
	_expect(not d.is_empty(), "o tubo deve gerar geometria")
	var rings: int = d["rings"]
	_expect(rings == n + 3, "n pontos + 3 anéis da tampa (%d)" % rings)
	_expect((d["vertices"] as PackedVector3Array).size() == rings * 9, "9 vértices por anel (a costura é duplicada)")
	_expect((d["indices"] as PackedInt32Array).size() == (rings - 1) * 8 * 6, "2 triângulos por face")
	_expect(is_equal_approx(float(d["length"]), 4.5), "comprimento em metros ao longo do eixo (%f)" % float(d["length"]))
	for v in d["vertices"] as PackedVector3Array:
		_expect(v.is_finite(), "vértice finito")
	# O raio do último anel é o pedido e a ponta fecha (último anel da tampa ~ 0).
	var verts: PackedVector3Array = d["vertices"]
	var r_last := Vector2(verts[(n - 1) * 9].x, verts[(n - 1) * 9].y).length()
	_expect(absf(r_last - rad[n - 1]) < 0.001, "raio do último ponto respeitado (%f)" % r_last)
	var tip := verts[(rings - 1) * 9]
	_expect(Vector2(tip.x, tip.y).length() < 0.02, "a tampa fecha a ponta")
	# Malha carregável.
	var mesh := ArrayMesh.new()
	_expect(MotionMesh.upload(mesh, d) and mesh.get_surface_count() == 1, "a malha sobe para um ArrayMesh")
	_expect(not MotionMesh.upload(mesh, {}) and mesh.get_surface_count() == 0, "dados vazios limpam a malha")


func _test_tube_degenerate() -> void:
	_expect(MotionMesh.tube(PackedVector3Array([Vector3.ZERO]), PackedFloat32Array([0.1]), PackedFloat32Array(), PackedFloat32Array()).is_empty(), "um ponto só não faz tubo")
	var same := PackedVector3Array([Vector3.ONE, Vector3.ONE, Vector3.ONE])
	var d := MotionMesh.tube(same, PackedFloat32Array([0.1, 0.1, 0.1]), PackedFloat32Array(), PackedFloat32Array())
	_expect(not d.is_empty(), "pontos coincidentes não quebram")
	for v in d["vertices"] as PackedVector3Array:
		_expect(v.is_finite(), "sem NaN com pontos coincidentes")
	# Eixo vertical (o vetor de referência 'cima' seria paralelo).
	var up := MotionMesh.tube(_line(5, Vector3.UP), PackedFloat32Array([0.1, 0.1, 0.1, 0.1, 0.1]), PackedFloat32Array(), PackedFloat32Array())
	for v in up["vertices"] as PackedVector3Array:
		_expect(v.is_finite(), "sem NaN no eixo vertical")
	_expect(MotionMesh.tube(_line(3, Vector3.RIGHT), PackedFloat32Array([0.1]), PackedFloat32Array(), PackedFloat32Array()).is_empty(), "raios de tamanho errado são recusados")


## D-235: a geometria só depende dos pontos, nunca de lado/personagem: espelhar o eixo espelha o tubo.
func _test_tube_mirror_independent() -> void:
	var rad := PackedFloat32Array([0.05, 0.1, 0.15, 0.2])
	var a := MotionMesh.tube(_line(4, Vector3(1, 0, 0)), rad, PackedFloat32Array(), PackedFloat32Array())
	var b := MotionMesh.tube(_line(4, Vector3(-1, 0, 0)), rad, PackedFloat32Array(), PackedFloat32Array())
	_expect(is_equal_approx(float(a["length"]), float(b["length"])), "mesmo comprimento nas duas direções")
	_expect((a["indices"] as PackedInt32Array).size() == (b["indices"] as PackedInt32Array).size(), "mesma topologia nas duas direções")


## O fogo refeito: quatro fases, cada uma só com composições + representações do Motion Composer.
func _test_fire_effect_layers() -> void:
	var fx := MotionPresets.fire_effect(7)
	var per_phase := {}
	var kinds := {}
	for l in fx.layers:
		per_phase[l["phase"]] = int(per_phase.get(l["phase"], 0)) + 1
		for r in l["reps"]:
			kinds[(r as MotionRep).kind] = true
		var comp: MotionComposition = l["comp"]
		var res := comp.evaluate(MotionStrand.catalog(), comp.make_context(0.3))
		_expect(not res.has_errors(), "camada %s sem erros de composição" % String(comp.id))
	_expect(per_phase.has("windup") and per_phase.has("travel") and per_phase.has("impact"), "carga, voo e impacto têm camadas")
	for k in ["tube", "bulb", "flipbook", "ring", "embers", "smoke"]:
		_expect(kinds.has(k), "o fogo usa a representação %s" % k)
	# Alvo único (D-308 item 10): no voo existe UM corpo e UMA cabeça (bulb), nada de segunda bola.
	var heads := 0
	var bodies := 0
	for l in fx.layers:
		if l["phase"] != "travel":
			continue
		for r in l["reps"]:
			if (r as MotionRep).kind == "bulb":
				heads += 1
			if (r as MotionRep).kind == "tube" and String((l["comp"] as MotionComposition).id) == "fire_body":
				bodies += 1
	_expect(heads == 1 and bodies == 1, "um corpo e uma cabeça no voo (cabeças=%d corpos=%d)" % [heads, bodies])


func _expect(c: bool, m: String) -> void:
	if not c:
		failures += 1
		push_error(m)
