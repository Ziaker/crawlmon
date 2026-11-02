extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle_fx := BattleFx.new()
	root.add_child(battle_fx)
	_test_profiles_and_ids()
	_test_projectiles(battle_fx)
	_test_impacts(battle_fx)
	_test_motion(battle_fx)
	await process_frame
	battle_fx.queue_free()
	if failures == 0:
		print("GIBLE_VFX_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _test_profiles_and_ids() -> void:
	_expect(BattleFx.normalize_move_id("Tiro de Areia") == "tiro_areia", "Sand Attack display name must resolve to its canonical id")
	_expect(BattleFx.normalize_move_id("Garra do Dragão") == "garra_dragao", "Dragon Claw display name must resolve to its canonical id")
	_expect(BattleFx.normalize_move_id("Fúria do Dragão") == "furia_dragao", "Dragon Rage display name must resolve to its canonical id")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("mordida"), 0.095), "Bite needs 95ms hit-stop")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("garra_dragao"), 0.105), "Dragon Claw needs 105ms hit-stop")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("furia_dragao"), 0.115), "Dragon Rage needs 115ms hit-stop")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("investida_escavadora"), 0.120), "Dig Rush needs 120ms hit-stop")
	_expect(BattleFx.move_uses_bw_pulse("garra_dragao"), "Dragon Claw needs the two-frame monochrome pulse")
	_expect(BattleFx.move_uses_bw_pulse("furia_dragao"), "Dragon Rage needs the two-frame monochrome pulse")
	_expect(BattleFx.move_uses_bw_pulse("investida_escavadora"), "Dig Rush needs the two-frame monochrome pulse")


func _test_projectiles(battle_fx: BattleFx) -> void:
	var from := Vector3(0, 1, 0)
	var to := Vector3(0, 1, -8)
	var sand := battle_fx.fx_projectiles._spawn_move(null, "tiro_areia", from, to, Color("f0c57e"))
	_expect(sand != null and sand.name == "SandSpiralJet", "Sand Attack must use an authored spiral cone jet")
	var rage := battle_fx.fx_projectiles._spawn_move(null, "furia_dragao", from, to, Color("63d9ec"))
	_expect(rage != null and rage.name == "DragonRageComet", "Dragon Rage must use an authored plasma comet")
	_expect(rage != null and rage.get_child_count() == 9, "Dragon Rage comet must contain its core and eight decreasing tail spheres")


func _test_impacts(battle_fx: BattleFx) -> void:
	var pos := Vector3(0, 1, -8)
	var bite := battle_fx.fx_impacts._impact(Element.Type.TREVAS, pos, Color("ff624f"), false, Vector3.FORWARD, "mordida")
	_expect(_has_named(bite, "BiteSpectralJaw"), "Bite must dispatch its spectral jaw")
	var jaw := _find_named(bite, "BiteSpectralJaw")
	_expect(jaw != null and jaw.get_child_count() == 11, "Bite jaw must contain dark miasma and ten fangs")
	var sand := battle_fx.fx_impacts._impact(Element.Type.TERRA, pos, Color("f0c57e"), false, Vector3.FORWARD, "tiro_areia")
	_expect(_has_named(sand, "SandVortexImpact"), "Sand Attack must dispatch its dust vortex")
	var claw := battle_fx.fx_impacts._impact(Element.Type.FISICO, pos, Color("00f59b"), true, Vector3.FORWARD, "garra_dragao")
	_expect(_has_named(claw, "DragonClawImpact"), "Dragon Claw must dispatch its three parallel marks")
	var rage := battle_fx.fx_impacts._impact(Element.Type.FISICO, pos, Color("63d9ec"), true, Vector3.FORWARD, "furia_dragao")
	_expect(_has_named(rage, "DragonRageSupernova"), "Dragon Rage must dispatch its spherical supernova")
	var dig := battle_fx.fx_impacts._impact(Element.Type.TERRA, pos, Color("f0c57e"), true, Vector3.FORWARD, "investida_escavadora")
	_expect(_has_named(dig, "DigRushEruption"), "Dig Rush must dispatch its tectonic eruption")
	var eruption := _find_named(dig, "DigRushEruption")
	_expect(eruption != null and eruption.get_child_count() == 10, "Dig Rush must erupt ten basalt monoliths")


func _test_motion(battle_fx: BattleFx) -> void:
	var model := Node3D.new()
	battle_fx.add_child(model)
	var claw_data := {"move_id": "garra_dragao", "run_t": 0.25, "dir": Vector3.FORWARD}
	battle_fx.fx_motion._drive_travel_move(null, claw_data, model, 0.12 + 0.25 * 0.5)
	_expect(model.position.y > 1.0, "Dragon Claw travel must lift Gible into a jump arc")
	model.position = Vector3.ZERO
	var dig_data := {"move_id": "investida_escavadora", "run_t": 0.25, "dir": Vector3.FORWARD, "from": Vector3.ZERO, "stand": Vector3(0, 0, -6)}
	battle_fx.fx_motion._drive_travel_move(null, dig_data, model, 0.12 + 0.25 * 0.55)
	_expect(model.position.y < -0.5, "Dig Rush must submerge Gible after 16% of travel")
	_expect(battle_fx.find_children("DigMound*", "Node3D", true, false).size() >= 4, "Dig Rush must progressively leave earth mounds along its route")


func _find_named(nodes: Array[Node3D], wanted: String) -> Node3D:
	for node in nodes:
		if node.name == wanted:
			return node
	return null


func _has_named(nodes: Array[Node3D], wanted: String) -> bool:
	return _find_named(nodes, wanted) != null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
