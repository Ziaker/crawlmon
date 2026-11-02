extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle_fx := BattleFx.new()
	root.add_child(battle_fx)
	_test_profiles()
	_test_projectile_dispatch(battle_fx)
	_test_impact_dispatch(battle_fx)
	_test_teleport_pinching(battle_fx.fx_projectiles)
	_test_special_timelines_and_teleport_drive(battle_fx)
	await process_frame
	battle_fx.queue_free()
	if failures == 0:
		print("ABRA_VFX_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _test_profiles() -> void:
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("confusao"), 0.085), "Confusion needs 85ms hit-stop")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("raio_psiquico"), 0.095), "Psybeam needs 95ms hit-stop")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("onda_choque"), 0.100), "Shock Wave needs 100ms hit-stop")
	_expect(BattleFx.move_uses_bw_pulse("onda_choque"), "Shock Wave needs the two-frame monochrome pulse")


func _test_projectile_dispatch(battle_fx: BattleFx) -> void:
	var from := Vector3(0, 1, 0)
	var to := Vector3(0, 1, -8)
	var confusion := battle_fx.fx_projectiles._spawn_move(null, "confusao", from, to, Color("bd9afd"))
	_expect(confusion != null and confusion.name == "ConfusionMentalWaves", "Confusion must emit authored mental waves")
	_expect(confusion != null and confusion.get_child_count() == 3, "Confusion must emit three concentric waves")
	var beam := battle_fx.fx_projectiles._spawn_move(null, "raio_psiquico", from, to, Color("bd9afd"))
	_expect(beam != null and beam.name == "PsybeamContinuous", "Psybeam must use a continuous cylindrical beam")
	_expect(beam != null and beam.get_child_count() == 4, "Psybeam must contain core, halo and two helices")
	var shock := battle_fx.fx_projectiles._spawn_move(null, "onda_choque", from, to, Color("d6fa66"))
	_expect(shock != null and shock.name == "ShockWaveTravel", "Shock Wave must own its ascending arc and target lock")
	var teleport := battle_fx.fx_projectiles._spawn_move(null, "teleporte_rapido", from, to, Color("63d9ec"))
	_expect(teleport != null and teleport.name == "RapidTeleportWarp", "Rapid Teleport must own its spatial choreography")


func _test_impact_dispatch(battle_fx: BattleFx) -> void:
	var pos := Vector3(0, 1, -8)
	var confusion := battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color("bd9afd"), false, Vector3.FORWARD, "confusao")
	_expect(_has_named(confusion, "ConfusionGravityField"), "Confusion must dispatch the telekinetic gravity field")
	var beam := battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color("bd9afd"), true, Vector3.FORWARD, "raio_psiquico")
	_expect(_has_named(beam, "PsybeamPrismImpact"), "Psybeam must dispatch its prism refraction")
	var shock := battle_fx.fx_impacts._impact(Element.Type.RAIO, pos, Color("d6fa66"), true, Vector3.FORWARD, "onda_choque")
	_expect(_has_named(shock, "ShockWavePillar"), "Shock Wave must dispatch its double procedural lightning pillar")


func _test_teleport_pinching(projectiles: FxProjectiles) -> void:
	_expect(projectiles._teleport_scale(0.0).is_equal_approx(Vector3.ONE), "Teleport must start at normal scale")
	_expect(projectiles._teleport_scale(0.12 / 0.22).is_equal_approx(Vector3(0.06, 2.1, 0.06)), "Teleport must pinch to the approved spatial silhouette in 0.12s")
	_expect(projectiles._teleport_scale(1.0).is_equal_approx(Vector3.ONE), "Teleport must finish materialized")


func _test_special_timelines_and_teleport_drive(battle_fx: BattleFx) -> void:
	var abra := Combatant.new("Abra Test", 20, 8, 0.5, true)
	var target := Combatant.new("Target Test", 20, 8, 0.5, false)
	var model := Node3D.new()
	var target_model := Node3D.new()
	target_model.position = Vector3(0, 0, -8)
	battle_fx.add_child(model)
	battle_fx.add_child(target_model)
	battle_fx.register(abra, model)
	battle_fx.register(target, target_model)
	var shock := Battle.Incoming.new()
	shock.attacker = abra
	shock.target = target
	shock.kind = Skill.Kind.CAST
	shock.element = Element.Type.RAIO
	shock.label = "Onda de Choque"
	battle_fx.fx_motion.begin_attack(shock)
	_expect(shock.plan[0][0] == Battle.Phase.TRAVEL and shock.plan[1][0] == Battle.Phase.STRIKE, "Shock Wave must telegraph in TRAVEL before its sky STRIKE")
	_expect(shock.impact_phase == Battle.Phase.STRIKE, "Shock Wave damage must land with the descending pillar")
	var teleport := Battle.Incoming.new()
	teleport.attacker = abra
	teleport.target = target
	teleport.kind = Skill.Kind.PROJECTILE
	teleport.element = Element.Type.PSIQUICO
	teleport.label = "Teleporte Rápido"
	battle_fx.fx_motion.begin_attack(teleport)
	teleport.plan_i = 0
	teleport.phase = Battle.Phase.TRAVEL
	teleport.phase_time = 0.12
	battle_fx.fx_motion.on_phase(teleport, Battle.Phase.TRAVEL)
	battle_fx.fx_projectiles.drive(teleport)
	_expect(model.scale.is_equal_approx(Vector3(0.06, 2.1, 0.06)), "Teleport body must reach the approved pinch at 0.12s")
	_expect(battle_fx.find_children("GhostSnapshot*", "Node3D", true, false).size() >= 1, "Teleport must leave a cyan decoy at its origin")
	teleport.plan_i = 2
	teleport.phase = Battle.Phase.RETURN
	teleport.phase_time = 0.30
	battle_fx.fx_projectiles.drive(teleport)
	_expect(model.position.is_equal_approx(Vector3.ZERO), "Teleport RETURN must restore Abra to its logical slot")


func _has_named(nodes: Array[Node3D], wanted: String) -> bool:
	for node in nodes:
		if node.name == wanted:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
