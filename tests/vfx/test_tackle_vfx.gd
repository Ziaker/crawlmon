extends SceneTree

var failures := 0


class FakeIncoming:
	extends RefCounted
	var label := ""

	func _init(p_label: String) -> void:
		label = p_label


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle_fx := BattleFx.new()
	root.add_child(battle_fx)
	_test_tackle_routing(battle_fx.fx_motion)
	_test_tackle_strike_timing(battle_fx.fx_motion)
	_test_tackle_strike(battle_fx.fx_motion)
	_test_tackle_impact(battle_fx.fx_impacts)
	await process_frame
	battle_fx.queue_free()
	if failures == 0:
		print("TACKLE_VFX_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _test_tackle_routing(motion: FxMotion) -> void:
	_expect(motion._is_tackle(FakeIncoming.new("Tackle")), "Tackle must use its dedicated VFX")
	_expect(motion._is_tackle(FakeIncoming.new("Investida")), "Investida must use its dedicated VFX")
	_expect(not motion._is_tackle(FakeIncoming.new("Quick Attack")), "other melee attacks must keep generic VFX")
	_expect(motion._should_emit_travel_dust(FakeIncoming.new("Tackle")), "Tackle travel must emit dust under D-041")
	_expect(motion._should_emit_travel_dust(FakeIncoming.new("Quick Attack")), "other melee travel must emit dust")


func _test_tackle_strike_timing(motion: FxMotion) -> void:
	var data := {"antic": 0.08, "hit": 0.45}
	_expect(not motion._should_start_strike_vfx(data, 0.08), "A2 must not start immediately after anticipation")
	_expect(not motion._should_start_strike_vfx(data, 0.31), "A2 must wait for the attack animation's contact window")
	_expect(motion._should_start_strike_vfx(data, 0.33), "A2 must start 0.20 seconds before contact")


func _test_tackle_strike(motion: FxMotion) -> void:
	var nodes: Array[Node3D] = motion._tackle_strike_vfx(Vector3.ZERO, Vector3.FORWARD)
	_expect(nodes.size() == 2, "A2 must create exactly two smear blades")
	if nodes.size() != 2:
		return
	var outer := nodes[0] as MeshInstance3D
	var inner := nodes[1] as MeshInstance3D
	_expect(outer.name == "TackleSmearOuter", "outer blade must be identifiable")
	_expect(inner.name == "TackleSmearCore", "inner blade must be identifiable")
	_expect(outer.position.is_equal_approx(Vector3(0, 0.95, -1.15)), "A2 must orbit at the approved shoulder offset")
	_expect(_shader_color(outer).is_equal_approx(Color("fb5607")), "outer blade must be fire orange")
	_expect(_shader_color(inner).is_equal_approx(Color("ffbe0b").lightened(0.35)), "inner blade must be white-gold")


func _test_tackle_impact(impacts: FxImpacts) -> void:
	var nodes: Array[Node3D] = impacts._tackle_impact(Vector3(1, 1, 2), Vector3.FORWARD, false)
	var names: Array[String] = []
	for node in nodes:
		names.append(node.name)
	_expect("TackleShockCone" in names, "D-041 must include 3D shock cone")
	_expect("TackleSlashArcA" in names, "D-041 must include crossed slash arc A")
	_expect("TackleSlashArcB" in names, "D-041 must include crossed slash arc B")
	_expect("TackleFlipbookMain" in names, "D-041 must include main impact flipbook")
	_expect("TackleFlipbookCore" in names, "D-041 must include core impact flipbook")
	_expect("TackleGroundSmoke" in names, "D-041 must include ground radial smoke")


func _shader_color(node: MeshInstance3D) -> Color:
	return (node.material_override as ShaderMaterial).get_shader_parameter("color") as Color


func _named(nodes: Array[Node3D], wanted: String) -> Node3D:
	for node in nodes:
		if node.name == wanted:
			return node
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
