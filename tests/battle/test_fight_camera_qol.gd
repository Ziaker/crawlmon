extends SceneTree
## QoL camera: the Fight menu uses the same high, wide TATICA framing as item
## target selection, follows the highlighted target, and its glide is not slowed
## by the 0.2x decision slow-motion.

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(ok: bool, msg: String) -> void:
	if ok:
		print("  [PASS] ", msg)
	else:
		failures += 1
		print("  [FAIL] ", msg)


func _run() -> void:
	print("--- FIGHT CAMERA QOL ---")
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 900:
		await process_frame
		guard += 1
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	for i in 4:
		await process_frame

	var target_model: Node3D = bs.models[battle.enemies[0]]
	var expected_look := target_model.global_position.lerp(Vector3(2.0, 0.0, 0.0), 0.35)
	bs._show_fight()
	var director: BattleCamera = bs.director
	_expect(director.mode == BattleCamera.Mode.TATICA, "Fight entra no enquadramento TÁTICA amplo")
	_expect(bs._decision_slowmo_active, "o slow motion de decisão está ativo")
	_expect(is_equal_approx(Engine.time_scale, 0.2), "Engine.time_scale está em 0.2x")

	# The glide lasts 1 s of REAL time even while the engine runs at 0.2x.
	await create_timer(1.25, true, false, true).timeout
	var to_tatica := director._pos.distance_to(BattleCamera.TATICA_POS)
	_expect(to_tatica < 0.15, "o glide do Fight chega à TÁTICA em ~1 s real (dist %.3f)" % to_tatica)
	_expect(bs._decision_slowmo_active, "o slow motion ainda está ativo depois do glide")
	_expect(director._look.distance_to(expected_look) < 0.2, "a câmera mira o alvo destacado do Fight")

	# Left/right swaps the Fight target and the camera follows it.
	bs._debug_add_test_enemies()
	await process_frame
	bs._on_menu_side(1)
	var second: Combatant = bs._fight_target
	var second_look := (bs.models[second] as Node3D).global_position.lerp(Vector3(2.0, 0.0, 0.0), 0.35)
	await create_timer(1.25, true, false, true).timeout
	_expect(director._look.distance_to(second_look) < 0.2, "a câmera acompanha a troca de alvo no Fight")

	bs._on_cancel()
	await create_timer(1.25, true, false, true).timeout
	_expect(director.mode == BattleCamera.Mode.CINEMA, "cancelar o Fight volta para CINEMA")
	_expect(director._pos.distance_to(BattleCamera.CINEMA_POS) < 0.15, "a câmera volta ao enquadramento base")

	bs.queue_free()
	await process_frame
	if failures == 0:
		print("FIGHT_CAMERA_QOL_PASS")
	else:
		print("FIGHT_CAMERA_QOL_FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
