extends SceneTree
## D-1162/D-1163: contrato mínimo do VFX 3D do Javelin Throw — perfil HTML Card C.
## - 5 peças, 14 lâminas (7 internas + 7 externas), 7 pós-imagens, 10 detritos e 8 faíscas;
## - o ápice da lança aponta para o `chest` real, inclusive com âncoras espelhadas (D-235);
## - a coroa existe no release e a cruz no impacto;
## - no fim tudo está oculto, sem escala negativa e sem sobra.
## godot --headless --path . --script res://tests/battle/test_javelin_vfx.gd

var _fails := 0


func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c:
		_fails += 1


func _anchors(hand: Vector3, chest: Vector3) -> Dictionary:
	var axis := (chest - hand).normalized()
	return {
		"hand": hand,
		"chest": chest,
		"feet": Vector3(chest.x, 0.0, chest.z),
		"axis": axis,
		"distance": hand.distance_to(chest),
		"impact_scale": 1.1,
		"target_radius": 0.55,
		"view_scale": 1.0,
	}


func _draw(vfx: JavelinThrowVfxHtml, a: Dictionary, stage: String, t: float, extra := {}) -> void:
	var p := a.duplicate()
	p["stage"] = stage
	p["windup_t"] = t if stage == "windup" else 0.75
	p["windup_total"] = 0.75
	p["flight_u"] = 0.0
	p["flight_t"] = 0.0
	p["flight_duration"] = 0.30
	p["release_t"] = -1.0
	p["since_impact"] = -1.0
	p["impact_chest"] = a["chest"]
	for k in extra:
		p[k] = extra[k]
	vfx.draw(p)


func _count(vfx: JavelinThrowVfxHtml, pattern: String, type := "Node3D") -> int:
	return vfx.find_children(pattern, type, true, false).size()


func _init() -> void:
	var vfx := JavelinThrowVfxHtml.new()
	root.add_child(vfx)
	vfx.setup(null)
	await process_frame

	var a := _anchors(Vector3(-2.0, 1.50, 2.8), Vector3(2.4, 1.20, -2.6))
	_draw(vfx, a, "windup", 0.30)
	ok(_count(vfx, "Shaft") == 1, "haste montada")
	ok(_count(vfx, "Grip") == 1, "empunhadura montada")
	ok(_count(vfx, "Collar") == 1, "colar montado")
	ok(_count(vfx, "Fins") == 1, "penas montadas")
	ok(_count(vfx, "Tip") == 1, "ponta montada (última peça)")
	ok(_count(vfx, "Blade*") == 14, "coroa tem 14 lâminas (7+7)")
	ok(_count(vfx, "Ghost*") == 7, "7 pós-imagens 3D")
	ok(_count(vfx, "Debris*") == 10, "10 blocos de detritos")
	ok(_count(vfx, "Spark*") == 8, "8 faíscas críticas")

	# Orientação: o ápice tem de ficar do lado do chest, não do lado oposto.
	var st := vfx.debug_state()
	var tip: Vector3 = st["tip"]
	ok((tip - a["hand"]).dot(a["chest"] - a["hand"]) > 0.0, "ápice aponta para o chest real")
	ok(tip.distance_to(a["chest"]) < a["distance"], "ápice viaja na direção do alvo")

	# Lado espelhado: outras posições, outro alvo, mesma regra (D-235).
	var b := _anchors(Vector3(3.2, 1.25, -3.4), Vector3(-2.7, 1.05, 2.1))
	_draw(vfx, b, "windup", 0.75)
	st = vfx.debug_state()
	tip = st["tip"]
	ok((tip - b["hand"]).dot(b["chest"] - b["hand"]) > 0.0, "lado espelhado mantém o ápice no alvo")
	ok((st["basis_z"] as Vector3).dot(b["axis"]) > 0.85, "basis do dardo acompanha o eixo real")

	# Release: a coroa nasce e fica visível em +0.15 s.
	_draw(vfx, a, "flight", 0.0, {
		"release_t": 0.15, "flight_u": 0.5, "flight_t": 0.15, "flight_duration": 0.30,
	})
	var crown := vfx.find_child("PrismaticCrown3D", true, false) as Node3D
	ok(crown != null and crown.visible, "coroa visível em +0,15 s")
	ok(not (vfx.debug_state().get("star_visible", true)), "estrela corta no disparo (HTML)")

	# Pulso/estrela/retículo.
	_draw(vfx, a, "windup", 0.60)
	var wst := vfx.debug_state()
	ok(bool(wst.get("star_visible", false)), "estrela 3D visível no pulso (0,60 s)")
	ok(float(wst.get("tip_emission", 0.0)) > 0.70, "emissão da ponta sobe com o pulso")
	var sv := vfx.find_child("StarSpikeV", true, false) as MeshInstance3D
	var sh := vfx.find_child("StarSpikeH", true, false) as MeshInstance3D
	var sc := vfx.find_child("StarCore", true, false) as MeshInstance3D
	var axv := (sv.transform.basis * Vector3(0, 1, 0)).normalized() if sv != null else Vector3.ZERO
	var axh := (sh.transform.basis * Vector3(0, 1, 0)).normalized() if sh != null else Vector3.ZERO
	ok(absf(axv.y) > 0.9 and absf(axh.x) > 0.9, "estrela HTML tem espinhos vertical e horizontal")
	ok(sc != null and sc.visible, "estrela HTML tem núcleo")
	var collar := vfx.find_child("CollarMesh", true, false) as MeshInstance3D
	var collar_col: Variant = null
	if collar != null and collar.material_override is StandardMaterial3D:
		collar_col = (collar.material_override as StandardMaterial3D).albedo_color
	ok(collar_col != null and (collar_col as Color).r > 0.8 and (collar_col as Color).g < 0.5, "colar vermelho do HTML")
	ok(bool(wst.get("reticle_visible", false)), "retículo octaédrico visível")
	var ring_early := float(wst.get("reticle_ring_scale", 0.0))
	_draw(vfx, a, "windup", 0.72)
	var ring_late := float(vfx.debug_state().get("reticle_ring_scale", 0.0))
	ok(ring_early > ring_late, "retículo encolhe até o ponto fraco")
	_draw(vfx, a, "windup", 0.74)
	ok(bool(vfx.debug_state().get("reticle_visible", false)), "retículo ainda visível em 0,74 s")
	_draw(vfx, a, "flight", 0.0, {
		"release_t": 0.05, "flight_u": 0.17, "flight_t": 0.05, "flight_duration": 0.30,
	})
	ok(not bool(vfx.debug_state().get("reticle_visible", true)), "retículo desliga no release")
	_draw(vfx, a, "flight", 0.0, {
		"release_t": 0.10, "flight_u": 0.33, "flight_t": 0.10, "flight_duration": 0.30,
	})
	ok(not bool(vfx.debug_state().get("star_visible", true)), "estrela não sobrevive ao disparo")
	_draw(vfx, a, "flight", 0.0, {
		"release_t": 0.30, "flight_u": 0.50, "flight_t": 0.15, "flight_duration": 0.30,
	})
	var g1 := vfx.find_child("Ghost1", true, false) as Node3D
	var g_alpha: float = 0.0
	if g1 != null:
		for gn in g1.find_children("*", "MeshInstance3D", true, false):
			var gm := (gn as MeshInstance3D).material_override
			if gm is StandardMaterial3D:
				g_alpha = (gm as StandardMaterial3D).albedo_color.a
				break
	ok(float(g_alpha) > 0.10, "pós-imagem com opacidade de leitura")
	ok(bool(vfx.debug_state().get("beam_visible", false)), "feixe perfurante visível no voo")
	_draw(vfx, a, "flight", 0.0, {
		"release_t": 0.36, "flight_u": 1.0, "flight_t": 0.30, "flight_duration": 0.30,
	})
	ok(not bool(vfx.debug_state().get("crown_visible", true)), "coroa dissipada em +0,35 s")

	# Impacto: flash cresce, espinhos de solo nascem e a cruz tem aresta 3D.
	_draw(vfx, a, "impact", 0.0, {
		"release_t": 0.30, "flight_u": 1.0, "flight_t": 0.30, "flight_duration": 0.30,
		"since_impact": 0.08, "impact_chest": a["chest"],
	})
	var flash_early := float(vfx.debug_state().get("flash_outer_scale", 0.0))
	_draw(vfx, a, "impact", 0.0, {
		"release_t": 0.30, "flight_u": 1.0, "flight_t": 0.30, "flight_duration": 0.30,
		"since_impact": 0.27, "impact_chest": a["chest"],
	})
	var flash_late := float(vfx.debug_state().get("flash_outer_scale", 0.0))
	ok(flash_late > flash_early, "flash HTML expande até 0,28 s")
	_draw(vfx, a, "impact", 0.0, {
		"release_t": 0.30, "flight_u": 1.0, "flight_t": 0.30, "flight_duration": 0.30,
		"since_impact": 0.08, "impact_chest": a["chest"],
	})
	ok(bool(vfx.debug_state().get("spike0_visible", false)), "espinhos 3D de solo visíveis no impacto")
	ok(vfx.find_child("CrossEdge", true, false) != null, "cruz tem aresta 3D")
	_draw(vfx, a, "impact", 0.0, {
		"release_t": 0.47, "flight_u": 1.0, "flight_t": 0.30, "flight_duration": 0.30,
		"since_impact": 0.70, "impact_chest": a["chest"],
	})
	ok(not bool(vfx.debug_state().get("spike0_visible", true)), "espinhos recolhem com o anel de solo")

	# Impacto: a cruz existe e desenha no chest congelado.
	_draw(vfx, a, "impact", 0.0, {
		"release_t": 0.30, "flight_u": 1.0, "flight_t": 0.30, "flight_duration": 0.30,
		"since_impact": 0.20, "impact_chest": a["chest"],
	})
	var cross := vfx.find_child("CrossBlade0", true, false) as MeshInstance3D
	ok(cross != null and cross.visible, "cruz 3D visível no impacto")
	ok(cross.global_position.distance_to(a["chest"]) < 0.01, "cruz ancorada no chest")

	# Fim: tudo oculto.
	_draw(vfx, a, "done", 0.0)
	ok(not (vfx.find_child("Javelin", true, false) as Node3D).visible, "lança oculta no fim")
	ok(not cross.is_visible_in_tree(), "cruz oculta no fim")

	# Nenhuma escala negativa em nenhum nó (D-235: nunca inverter por escala).
	var negative := 0
	for n in vfx.find_children("*", "Node3D", true, false):
		var n3 := n as Node3D
		if n3.scale.x < 0.0 or n3.scale.y < 0.0 or n3.scale.z < 0.0:
			negative += 1
	ok(negative == 0, "nenhuma escala negativa")

	vfx.queue_free()
	await process_frame
	print("RESULT: %s" % ("PASS" if _fails == 0 else "FAIL (%d)" % _fails))
	quit(0 if _fails == 0 else 1)
