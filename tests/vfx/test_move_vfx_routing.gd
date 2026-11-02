extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle_fx := BattleFx.new()
	root.add_child(battle_fx)
	_test_normalization()
	_test_incoming_data_receives_move_id(battle_fx)
	_test_impact_dispatch(battle_fx)
	_test_ghost_snapshot(battle_fx)
	_test_monochrome_impact_pulse()
	await process_frame
	battle_fx.queue_free()
	if failures == 0:
		print("MOVE_VFX_ROUTING_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _test_normalization() -> void:
	_expect(BattleFx.normalize_move_id("Soco Rápido") == "soco_rapido", "normalization must remove accents")
	_expect(BattleFx.normalize_move_id("  Golpe de Caratê  ") == "golpe_carate", "normalization must resolve the canonical move id")
	_expect(BattleFx.normalize_move_id("Quebra de Telha") == "quebra_telha", "normalization must remove connector words used only by display names")
	_expect(BattleFx.normalize_move_id("Onda de Choque") == "onda_choque", "Shock Wave display name must route to its canonical id")
	_expect(BattleFx.normalize_move_id("Investida Escavadora") == "investida_escavadora", "normalization must preserve word boundaries")
	_expect(BattleFx.normalize_move_id("Tackle") == "tackle", "normalization must support the English basic move")


func _test_incoming_data_receives_move_id(battle_fx: BattleFx) -> void:
	var attacker := Combatant.new("Router A", 10, 5, 0.5, true)
	var target := Combatant.new("Router B", 10, 5, 0.5, false)
	var attacker_model := Node3D.new()
	var target_model := Node3D.new()
	target_model.position = Vector3(0, 0, -8)
	battle_fx.add_child(attacker_model)
	battle_fx.add_child(target_model)
	battle_fx.register(attacker, attacker_model)
	battle_fx.register(target, target_model)
	var inc := Battle.Incoming.new()
	inc.attacker = attacker
	inc.target = target
	inc.kind = Skill.Kind.MELEE
	inc.element = Element.Type.FISICO
	inc.label = "Soco Rápido"
	battle_fx.fx_motion.begin_attack(inc)
	_expect(inc.data.get("move_id", "") == "soco_rapido", "begin_attack must propagate normalized move_id into inc.data")


func _test_impact_dispatch(battle_fx: BattleFx) -> void:
	var authored: Array[Node3D] = battle_fx.fx_impacts._impact(Element.Type.FISICO, Vector3(1, 1, 2), Color.WHITE, false, Vector3.FORWARD, "investida")
	_expect(_has_named(authored, "TackleImpactB1"), "authored move impact must dispatch B1 before elemental fallback")
	var fallback: Array[Node3D] = battle_fx.fx_impacts._impact(Element.Type.FISICO, Vector3(-1, 1, 2), Color.WHITE, false, Vector3.FORWARD, "move_desconhecido")
	_expect(not _has_named(fallback, "TackleImpactB1"), "unknown moves must retain elemental fallback")
	_expect(fallback.size() >= 2, "physical elemental fallback must remain active")


func _test_ghost_snapshot(battle_fx: BattleFx) -> void:
	var model := Node3D.new()
	model.position = Vector3(2, 0, -3)
	battle_fx.add_child(model)
	var ghost := VfxLib.spawn_ghost_snapshot(battle_fx, model, Color("00f5d4"), 0.12)
	_expect(ghost.name == "GhostSnapshot", "snapshot helper must identify temporary copies")
	_expect(ghost.global_transform.is_equal_approx(model.global_transform), "snapshot must freeze at the model's current transform")
	model.position = Vector3.ZERO
	_expect(not ghost.global_position.is_equal_approx(model.global_position), "snapshot must not follow later model movement")


func _test_monochrome_impact_pulse() -> void:
	var director := BattleCamera.new()
	var camera := Camera3D.new()
	root.add_child(director)
	director.add_child(camera)
	director.setup(camera)
	director.impact_post(Vector3.FORWARD * -4.0, Color.WHITE, true, true)
	var amount: float = director._post_mat.get_shader_parameter("monochrome")
	_expect(is_equal_approx(amount, 1.0), "heavy authored impact must be able to trigger the 2-frame monochrome pulse")
	director.queue_free()


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
