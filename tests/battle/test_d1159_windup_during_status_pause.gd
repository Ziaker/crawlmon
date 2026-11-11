extends SceneTree
## D-1159: an attack may start its wind-up during a real status pause, pay its cost and stay
## frozen until the pause ends. A status move still waits in the one-slot queue.

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _new_scene() -> Node3D:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	bs.set_meta("vfx_room", true)
	bs.set_meta("vfx_room_mirror", true)
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	return bs


func _start_pause(battle: Battle) -> bool:
	var caster: Combatant = battle.enemies[0]
	var leader: Combatant = battle.party[0]
	var rak: Skill = Skill.from_id(&"rakunda")
	caster.atb = 3.0
	caster.mp = 20
	return battle.use_skill(caster, rak, leader)


func _run() -> void:
	print("=================================================================")
	print("   CRAWMON — WIND-UP DURANTE A PAUSA DE STATUS (D-1159)")
	print("=================================================================")
	await _test_attack_starts_and_freezes()
	await _test_status_move_waits()
	print("=================================================================")
	if failures == 0:
		print("D1159_WINDUP_DURING_PAUSE_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)


func _test_attack_starts_and_freezes() -> void:
	var bs: Node3D = await _new_scene()
	var battle: Battle = bs.get_node("Battle")
	var leader: Combatant = bs.leader
	var enemy: Combatant = battle.enemies[0]
	var used := _start_pause(battle)
	await process_frame
	leader.atb = 5.0
	leader.mp = 20
	var before_atb := leader.atb
	var started := battle.request_skill(leader, Skill.basic(), enemy)
	_expect(used and battle.is_status_paused(), "Pausa de status ativa")
	_expect(started and battle.is_winding_up(leader) and leader.queued_skill == null,
		"Ataque começa o wind-up durante a pausa (D-1159)")
	_expect(leader.atb < before_atb, "O custo é pago no início do wind-up")
	var inc = null
	for i in battle.incoming:
		if i.attacker == leader:
			inc = i
	_expect(inc != null and is_equal_approx(inc.time_left, inc.total_windup),
		"Wind-up fica parado durante a pausa")
	var ap: AnimationPlayer = bs.fx._anim_player(leader)
	_expect(ap != null and is_zero_approx(ap.speed_scale), "Animação do novo wind-up fica congelada")
	var frozen_left: float = inc.time_left if inc != null else -1.0
	for i in 6:
		await process_frame
	_expect(inc != null and is_equal_approx(inc.time_left, frozen_left), "O tempo do wind-up não anda na pausa")
	var t0 := Time.get_ticks_msec()
	while battle.is_status_paused() and Time.get_ticks_msec() - t0 < 8000:
		await process_frame
	await process_frame
	await process_frame
	_expect(battle.is_winding_up(leader), "Depois da pausa o wind-up continua")
	_expect(ap != null and ap.speed_scale > 0.0, "Depois da pausa a animação volta a andar")
	bs.free()


func _test_status_move_waits() -> void:
	var bs: Node3D = await _new_scene()
	var battle: Battle = bs.get_node("Battle")
	var leader: Combatant = bs.leader
	var tar: Skill = Skill.from_id(&"tarukaja")
	var used := _start_pause(battle)
	await process_frame
	leader.atb = 5.0
	leader.mp = 20
	var requested := battle.request_skill(leader, tar, leader)
	_expect(used and requested and leader.queued_skill == tar and not battle.is_winding_up(leader),
		"Move de status não abre outra pausa: entra na vaga")
	var t0 := Time.get_ticks_msec()
	while battle.is_status_paused() and Time.get_ticks_msec() - t0 < 8000:
		await process_frame
	await process_frame
	await process_frame
	_expect(battle.is_winding_up(leader) and leader.queued_skill == null,
		"Move de status começa quando a pausa acaba")
	bs.free()
