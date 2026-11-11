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
	# D-170: the projectile root is only a handle; the authored flight is an AbraMoveVfx layer
	# (TRAVEL stage) that reads the real caster and target. The old named scene-tree effects
	# (ConfusionMentalWaves, PsybeamContinuous, ShockWaveTravel, RapidTeleportWarp) are gone.
	var roots := {
		"confusao": "AbraConfusionTravel",
		"raio_psiquico": "AbraPsybeamTravel",
		"onda_choque": "AbraShockWaveTravel",
		"teleporte_rapido": "AbraTeleportTravel",
	}
	for move_id: String in roots:
		var root := battle_fx.fx_projectiles._spawn_move(null, move_id, from, to, Color("bd9afd"))
		_expect(root != null and root.name == roots[move_id], "%s must own its travel root" % move_id)
		if root != null:
			root.queue_free()
		var layer := AbraMoveVfx.travel(battle_fx, move_id, from, to)
		_expect(layer != null and layer.move_id == move_id and layer.stage == AbraMoveVfx.Stage.TRAVEL, "%s must use the authored Abra travel layer" % move_id)
		if is_instance_valid(layer):
			layer.queue_free()


func _test_impact_dispatch(battle_fx: BattleFx) -> void:
	var pos := Vector3(0, 1, -8)
	var cases := {
		"confusao": ["AbraConfusaoImpact", Element.Type.PSIQUICO],
		"raio_psiquico": ["AbraRaioPsiquicoImpact", Element.Type.PSIQUICO],
		"onda_choque": ["AbraOndaChoqueImpact", Element.Type.RAIO],
	}
	for move_id: String in cases:
		var wanted: String = cases[move_id][0]
		var layer := battle_fx.get_node_or_null(wanted)
		if layer != null:
			layer.queue_free()  # a previous case may have left one
		battle_fx.fx_impacts._impact(cases[move_id][1], pos, Color("bd9afd"), true, Vector3.FORWARD, move_id)
		layer = battle_fx.get_node_or_null(wanted)
		_expect(layer is AbraMoveVfx and (layer as AbraMoveVfx).stage == AbraMoveVfx.Stage.IMPACT, "%s must spawn its authored Abra impact layer" % move_id)
		if layer != null:
			layer.queue_free()


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
	# D-1079: the rules plan the timeline; the FX layer only reads it.
	var planner := AttackPlanner.new(null)
	var shock := Incoming.new()
	shock.attacker = abra
	shock.target = target
	shock.kind = Skill.Kind.CAST
	shock.element = Element.Type.RAIO
	shock.label = "Onda de Choque"
	planner.plan(shock)
	battle_fx.fx_attack_plan.begin_attack(shock)
	_expect(shock.plan[0][0] == Incoming.Phase.TRAVEL and shock.plan[1][0] == Incoming.Phase.STRIKE, "Shock Wave must telegraph in TRAVEL before its sky STRIKE")
	_expect(shock.impact_phase == Incoming.Phase.STRIKE, "Shock Wave damage must land with the descending pillar")
	var teleport := Incoming.new()
	teleport.attacker = abra
	teleport.target = target
	teleport.kind = Skill.Kind.PROJECTILE
	teleport.element = Element.Type.PSIQUICO
	teleport.label = "Teleporte Rápido"
	planner.plan(teleport)
	battle_fx.fx_attack_plan.begin_attack(teleport)
	teleport.plan_i = 0
	teleport.phase = Incoming.Phase.TRAVEL
	teleport.phase_time = 0.12
	battle_fx.fx_motion.on_phase(teleport, Incoming.Phase.TRAVEL)
	battle_fx.fx_projectiles.drive(teleport)
	# D-170: the old pinch scale was removed; the body vanishes and the AbraMoveVfx warp owns the silhouette.
	_expect(not model.visible, "Teleport must hide the body during TRAVEL (D-170 warp owns the silhouette)")
	_expect(battle_fx.find_children("GhostSnapshot*", "Node3D", true, false).size() >= 1, "Teleport must leave a decoy at its origin")
	teleport.plan_i = 2
	teleport.phase = Incoming.Phase.RETURN
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
