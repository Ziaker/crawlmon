extends SceneTree
## D-377 / D-378: teste do efeito da Drain Spear no Motion Composer. Sem cena e sem relÃ³gio: valida a geometria
## (lanÃ§a inteira, cabo, lÃ¢mina, fita espiral), o shader, as camadas/fases do preset e a avaliaÃ§Ã£o determinÃ­stica.
## godot --headless --path . --script res://tests/motion_composer/test_v110_drain_spear.gd

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
	_test_spear_mesh()
	_test_aura_mesh()
	_test_shaders()
	_test_preset()
	if _fails == 0:
		print("MC_V110_DRAIN_SPEAR_PASS (%d checks)" % _checks)
	quit(1 if _fails > 0 else 0)


func _check_mesh(data: Dictionary, label: String) -> void:
	ok(not data.is_empty(), "%s existe" % label)
	if data.is_empty():
		return
	var verts: PackedVector3Array = data["vertices"]
	var norms: PackedVector3Array = data["normals"]
	var uvs: PackedVector2Array = data["uvs"]
	var idxs: PackedInt32Array = data["indices"]
	ok(verts.size() > 30, "%s tem volume (%d vÃ©rtices)" % [label, verts.size()])
	ok(norms.size() == verts.size(), "%s: um normal por vÃ©rtice" % label)
	ok(uvs.size() == verts.size(), "%s: um UV por vÃ©rtice" % label)
	ok(idxs.size() > 0 and idxs.size() % 3 == 0, "%s: Ã­ndices triangulares" % label)
	var min_y := 999.0
	var max_y := -999.0
	var min_uv := 999.0
	var max_uv := -999.0
	for v in verts:
		min_y = minf(min_y, v.y)
		max_y = maxf(max_y, v.y)
	for uv in uvs:
		min_uv = minf(min_uv, uv.y)
		max_uv = maxf(max_uv, uv.y)
	ok(is_equal_approx(min_y, 0.0) and is_equal_approx(max_y, 1.0), "%s: comprimento local 0..1" % label)
	ok(is_equal_approx(min_uv, 0.0) and is_equal_approx(max_uv, 1.0), "%s: UV.y cobre a peÃ§a" % label)
	var mesh := ArrayMesh.new()
	ok(MotionMesh.upload(mesh, data), "%s sobe para ArrayMesh" % label)
	ok(mesh.get_surface_count() == 1, "%s: uma superfÃ­cie" % label)
	for v in verts:
		ok(v.is_finite(), "%s: vÃ©rtice finito" % label)
		break


func _test_spear_mesh() -> void:
	_check_mesh(MotionMesh.spear(MotionPainter.SPEAR_LEVELS, 8), "malha da lanÃ§a inteira")
	_check_mesh(MotionMesh.spear_shaft(8), "malha do cabo")
	_check_mesh(MotionMesh.spear_blade(8), "malha da lÃ¢mina")


func _test_aura_mesh() -> void:
	var data := MotionMesh.helix_band(2.7, 0.46, 2.4, 0.0, 0.055, 48, true)
	ok(not data.is_empty(), "fita espiral existe")
	if data.is_empty():
		return
	var verts: PackedVector3Array = data["vertices"]
	var norms: PackedVector3Array = data["normals"]
	var idxs: PackedInt32Array = data["indices"]
	ok(verts.size() == 49 * 2, "a fita tem 48 segmentos + 1 (%d vÃ©rtices)" % verts.size())
	ok(norms.size() == verts.size(), "a fita tem normal por vÃ©rtice")
	ok(idxs.size() == 48 * 6, "a fita tem 6 Ã­ndices por segmento")
	var min_y := 999.0
	var max_y := -999.0
	for v in verts:
		min_y = minf(min_y, v.y)
		max_y = maxf(max_y, v.y)
	ok(is_equal_approx(min_y, 0.0) and is_equal_approx(max_y, 2.7), "a fita cobre o comprimento da lanÃ§a")
	var mesh := ArrayMesh.new()
	ok(MotionMesh.upload(mesh, data), "a fita sobe para ArrayMesh")


func _test_shaders() -> void:
	var sh := load("res://shaders/mc_drain_spear.gdshader") as Shader
	ok(sh != null, "o shader mc_drain_spear carrega")
	if sh != null:
		var names := {}
		for u in sh.get_shader_uniform_list():
			names[String(u["name"])] = true
		for n in ["reveal", "dissolve", "opacity", "energy", "tint", "tip_color", "edge_color", "rim", "tt", "seed"]:
			ok(names.has(n), "uniform %s existe" % n)
	var aura := load("res://shaders/mc_aura_band.gdshader") as Shader
	ok(aura != null, "o shader mc_aura_band carrega")
	if aura != null:
		var an := {}
		for u in aura.get_shader_uniform_list():
			an[String(u["name"])] = true
		for n in ["color", "opacity", "energy", "rim_color", "light_dir", "rim_power", "flow_speed", "tt"]:
			ok(an.has(n), "aura: uniform %s existe" % n)


func _test_preset() -> void:
	var fx := MotionPresets.drain_spear_effect(20261106, {"steal_distance": 16.3})
	ok(fx.layers.size() == 27, "27 camadas (windup 5, thrust 4, drill 5, impact 3, impact_flash 3, steal 4, dissolve 3) â€” %d" % fx.layers.size())
	var phases := {}
	var spear_layers := 0
	var aura_layers := 0
	var vortex_layers := 0
	var beam_layers := 0
	for layer in fx.layers:
		var phase := String(layer.get("phase", ""))
		phases[phase] = int(phases.get(phase, 0)) + 1
		var comp: MotionComposition = layer["comp"]
		ok(comp != null, "camada %s tem composiÃ§Ã£o" % phase)
		if comp == null:
			continue
		var res := comp.evaluate(MotionStrand.catalog(), comp.make_context(0.20))
		ok(not res.has_errors(), "comp %s avalia sem erro a 0,20 s" % comp.id)
		ok(not res.samples.is_empty(), "comp %s tem amostras" % comp.id)
		for rep in layer["reps"]:
			var r := rep as MotionRep
			if r.kind == "spear":
				spear_layers += 1
				ok(r.blade_length > 0.2, "a lanÃ§a separa uma lÃ¢mina fixa (%.2f m)" % r.blade_length)
			if r.kind == "aura":
				aura_layers += 1
				ok(r.aura_bands == 6, "aura com 6 faixas")
			if r.kind == "vortex":
				vortex_layers += 1
				ok(r.vortex_bands == 10, "vÃ³rtice com 10 faixas")
				ok(r.vortex_spin >= 4.0, "vÃ³rtice gira como ventilador (%.1f voltas/s)" % r.vortex_spin)
				ok(r.vortex_base_length > 0.0, "vÃ³rtice tambÃ©m na base (mÃ£o)")
			if r.kind == "surface" and String(r.shape) == "tube":
				beam_layers += 1
	ok(int(phases.get("windup", 0)) == 5, "windup tem 5 camadas")
	ok(int(phases.get("thrust", 0)) == 4, "thrust tem 4 camadas")
	ok(int(phases.get("drill", 0)) == 5, "drill tem 5 camadas (vÃ³rtice, burst na mÃ£o, burst na ponta, faÃ­scas, burst largo)")
	ok(int(phases.get("impact", 0)) == 3, "impact tem 3 camadas de leque")
	ok(int(phases.get("impact_flash", 0)) == 3, "impact_flash tem 3 camadas de flash/poeira")
	ok(int(phases.get("steal", 0)) == 4, "steal tem 4 camadas (56+36 streaks, 34 orbes, Ã³rbita Ãºnica)")
	ok(int(phases.get("dissolve", 0)) == 3, "dissolve tem 3 camadas (lanÃ§a, brasas, partÃ­culas)")
	ok(not phases.has("beam"), "nÃ£o existe fase de feixe (sem projÃ©til)")
	ok(beam_layers == 0, "nenhuma camada desenha um tubo de feixe")
	ok(spear_layers == 3, "3 camadas usam a representaÃ§Ã£o spear (reveal, thrust, dissolve) â€” %d" % spear_layers)
	ok(aura_layers == 2, "2 camadas usam a aura (windup, thrust) â€” %d" % aura_layers)
	ok(vortex_layers == 1, "1 camada usa o vÃ³rtice do drill â€” %d" % vortex_layers)
	# O leque reverso precisa existir no Badge Steal (era o efeito que faltava).
	var reverse_bursts := 0
	for layer in fx.layers:
		if String(layer.get("phase", "")) != "steal":
			continue
		var comp: MotionComposition = layer["comp"]
		for ml in comp.layers:
			var md: MotionLayer = ml
			if md.behavior_id == &"M16":
				reverse_bursts += 1
	ok(reverse_bursts >= 2, "o Badge Steal tem leque reverso (M16) â€” %d camadas" % reverse_bursts)
	var has_ghosts := false
	for layer in fx.layers:
		for rep in layer["reps"]:
			var r := rep as MotionRep
			if r.kind == "spear" and r.ghosts > 0:
				has_ghosts = true
	ok(has_ghosts, "a estocada tem pÃ³s-imagens")
	# Determinismo: a mesma semente e o mesmo tempo devolvem os mesmos primeiros pontos.
	var fx2 := MotionPresets.drain_spear_effect(20261106, {"steal_distance": 16.3})
	var a: MotionComposition = fx.layers[0]["comp"]
	var b: MotionComposition = fx2.layers[0]["comp"]
	var ra := a.evaluate(MotionStrand.catalog(), a.make_context(0.5))
	var rb := b.evaluate(MotionStrand.catalog(), b.make_context(0.5))
	ok(ra.samples.size() == rb.samples.size(), "mesma contagem de amostras")
	if not ra.samples.is_empty() and not rb.samples.is_empty():
		ok((ra.samples[0] as MotionSample).position.is_equal_approx((rb.samples[0] as MotionSample).position), "mesma posiÃ§Ã£o com a mesma semente")

