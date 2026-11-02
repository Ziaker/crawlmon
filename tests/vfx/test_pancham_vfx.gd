extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle_fx := BattleFx.new()
	root.add_child(battle_fx)
	_test_hit_stop_profiles()
	_test_move_timelines(battle_fx)
	_test_motion_choreography(battle_fx)
	_test_authored_impacts(battle_fx)
	_test_brick_barrier(battle_fx)
	_test_taunt_projectile_and_status(battle_fx)
	await process_frame
	battle_fx.queue_free()
	if failures == 0:
		print("PANCHAM_VFX_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _test_hit_stop_profiles() -> void:
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("soco_rapido"), 0.075), "Quick Punch needs 75ms hit-stop")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("golpe_carate"), 0.095), "Karate Chop needs 95ms hit-stop")
	_expect(is_equal_approx(BattleFx.move_hit_stop_duration("quebra_telha"), 0.110), "Brick Break needs 110ms hit-stop")
	_expect(BattleFx.move_uses_bw_pulse("golpe_carate"), "Karate Chop needs the monochrome pulse")
	_expect(BattleFx.move_uses_bw_pulse("quebra_telha"), "Brick Break needs the monochrome pulse")
	_expect(not BattleFx.move_uses_bw_pulse("soco_rapido"), "Quick Punch must keep its chromatic palette")


func _test_move_timelines(battle_fx: BattleFx) -> void:
	var attacker := Combatant.new("Pancham Test", 20, 8, 0.5, true)
	var target := Combatant.new("Target Test", 20, 8, 0.5, false)
	var attacker_model := Node3D.new()
	var target_model := Node3D.new()
	target_model.position = Vector3(0, 0, -8)
	battle_fx.add_child(attacker_model)
	battle_fx.add_child(target_model)
	battle_fx.register(attacker, attacker_model)
	battle_fx.register(target, target_model)
	var quick := Battle.Incoming.new()
	quick.attacker = attacker
	quick.target = target
	quick.kind = Skill.Kind.MELEE
	quick.element = Element.Type.FISICO
	quick.label = "Soco Rápido"
	battle_fx.fx_motion.begin_attack(quick)
	_expect(is_equal_approx(float(quick.data["run_t"]), Battle.TRAVEL_MIN), "Quick Punch travel must clamp to Battle's fastest legal travel time")
	var taunt := Battle.Incoming.new()
	taunt.attacker = attacker
	taunt.target = target
	taunt.kind = Skill.Kind.STATUS
	taunt.element = Element.Type.FISICO
	taunt.label = "Provocação"
	battle_fx.fx_motion.begin_attack(taunt)
	_expect(taunt.impact_phase == Battle.Phase.TRAVEL, "Taunt contact must occur after its travelling rings")
	_expect(taunt.plan.any(func(segment) -> bool: return segment[0] == Battle.Phase.TRAVEL), "Taunt timeline must include a visual TRAVEL phase")


func _test_motion_choreography(battle_fx: BattleFx) -> void:
	var model := Node3D.new()
	battle_fx.add_child(model)
	var quick_data := {"move_id": "soco_rapido", "run_t": 0.25, "dir": Vector3.FORWARD}
	for k in [0.24, 0.48, 0.72]:
		battle_fx.fx_motion._drive_travel_move(null, quick_data, model, 0.12 + 0.25 * k)
	var ghosts := battle_fx.find_children("GhostSnapshot*", "Node3D", true, false)
	_expect(ghosts.size() == 3, "Quick Punch travel must leave exactly three spaced snapshots")
	var karate_data := {"move_id": "golpe_carate", "run_t": 0.25, "dir": Vector3.FORWARD}
	model.position = Vector3.ZERO
	battle_fx.fx_motion._drive_travel_move(null, karate_data, model, 0.12 + 0.25 * 0.70)
	_expect(model.position.y > 0.0, "Karate Chop must enter its final parabolic jump")
	var brick_data := {"move_id": "quebra_telha", "run_t": 0.25, "dir": Vector3.FORWARD}
	model.position = Vector3.ZERO
	battle_fx.fx_motion._drive_travel_move(null, brick_data, model, 0.12 + 0.25 * 0.50)
	_expect(model.position.y >= 3.1, "Brick Break must reach its high meteor jump")


func _test_authored_impacts(battle_fx: BattleFx) -> void:
	var quick := battle_fx.fx_impacts._impact(Element.Type.FISICO, Vector3(0, 1, 0), Color.WHITE, false, Vector3.FORWARD, "soco_rapido")
	_expect(_has_named(quick, "QuickPunchBarrage"), "Quick Punch must dispatch its six-hit barrage")
	var karate := battle_fx.fx_impacts._impact(Element.Type.FISICO, Vector3(0, 1, 0), Color.WHITE, true, Vector3.FORWARD, "golpe_carate")
	_expect(_has_named(karate, "KarateGuillotine"), "Karate Chop must dispatch the vertical guillotine slash")
	_expect(_has_named(karate, "KarateLightColumn"), "Karate Chop must dispatch the tapered light column")
	var brick := battle_fx.fx_impacts._impact(Element.Type.FISICO, Vector3(0, 1, 0), Color.WHITE, true, Vector3.FORWARD, "quebra_telha")
	_expect(_has_named(brick, "BrickBreakImpact"), "Brick Break must dispatch its crimson impact")


func _test_brick_barrier(battle_fx: BattleFx) -> void:
	var target := Combatant.new("Barrier Target", 10, 5, 0.5, false)
	var barrier := battle_fx.fx_impacts.spawn_brick_barrier(target, Vector3(0, 1, 0), Vector3.FORWARD)
	_expect(barrier.name == "BrickHexBarrier", "Brick Break must create the hex barrier during preparation")
	_expect(barrier.get_child_count() >= 7, "hex barrier must visibly read as a tiled screen")
	var shards := battle_fx.fx_impacts.shatter_brick_barrier(target, Vector3(0, 1, 0), Vector3.FORWARD)
	_expect(shards.name == "BrickBarrierShards", "contact must replace the barrier with shard geometry")
	_expect(shards.get_child_count() == 15, "Brick Break must eject 14-16 polygonal fragments")


func _test_taunt_projectile_and_status(battle_fx: BattleFx) -> void:
	var waves := battle_fx.fx_projectiles._spawn_move(null, "provocacao", Vector3.ZERO, Vector3(0, 1, -8), Color("ff624f"))
	_expect(waves != null and waves.name == "TauntShockWaves", "Taunt must own its travelling acoustic rings")
	_expect(waves != null and waves.get_child_count() == 4, "Taunt must launch four acoustic rings")
	var handled := battle_fx.fx_impacts._status_impact_move("provocacao", Vector3(0, 1, -8))
	_expect(handled, "Taunt must own its status impact")
	var marks := battle_fx.find_children("RageMark*", "Label3D", true, false)
	_expect(marks.size() == 3, "Taunt must pulse three rage-vein marks above the target")


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
