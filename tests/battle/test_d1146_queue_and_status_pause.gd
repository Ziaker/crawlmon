extends SceneTree
## D-1146/D-1147: one-slot queue replacement, interruption-only cancellation, snapshot of the
## queue, status-pause action gates (Evade/Guard yes; Items/Steps no) and War Cry's visual
## freeze (feature) without the generic aura.
## Run with: godot --headless --path . --script res://tests/battle/test_d1146_queue_and_status_pause.gd

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — FILA D-161 E PAUSA DE STATUS (D-1146/D-1147)")
	print("=================================================================")
	_test_queue_replacement()
	_test_projectile_does_not_drop_queue()
	_test_queue_snapshot()
	await _test_status_pause_gates()
	await _test_status_pause_midframe_stops_attacks()
	await _test_war_cry_freeze_and_aura()
	await _test_buff_visual_respects_freeze()
	print("=================================================================")
	if failures == 0:
		print("D1146_QUEUE_AND_STATUS_PAUSE_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)


func _test_queue_replacement() -> void:
	var b := Battle.new()
	var hero := Combatant.new("Hero", 100, 10, 0.5, true)
	hero.atb = 5.0
	hero.mp = 20
	var foe := Combatant.new("Foe", 100, 10, 0.5, false)
	b.start([hero], [foe])
	var old_skill := Skill.basic()
	hero.queued_skill = old_skill
	var started := b.request_skill(hero, Skill.basic(), foe)
	_expect(started and hero.queued_skill == null, "Nova escolha imediata substitui a vaga antiga (D-1146)")


func _test_projectile_does_not_drop_queue() -> void:
	var b := Battle.new()
	var hero := Combatant.new("Hero", 100, 10, 0.5, true)
	var foe := Combatant.new("Foe", 100, 10, 0.5, false)
	b.start([hero], [foe])
	hero.queued_skill = Skill.basic()
	var inc := Incoming.new()
	inc.attacker = hero
	inc.target = foe
	inc.kind = Skill.Kind.PROJECTILE
	inc.phase = Battle.Phase.TRAVEL
	inc.motion = "cast"
	inc.plan = [[Battle.Phase.TRAVEL, 1.0]]
	inc.plan_i = 0
	b._landing.append(inc)
	var stopped := b.interrupt_attacks_of(hero, foe, 1.0)
	_expect(not stopped and hero.queued_skill != null and b._landing.has(inc),
		"Hit com projétil em voo não apaga a fila (D-1146)")

	var b2 := Battle.new()
	var hero2 := Combatant.new("Hero2", 100, 10, 0.5, true)
	var foe2 := Combatant.new("Foe2", 100, 10, 0.5, false)
	b2.start([hero2], [foe2])
	hero2.queued_skill = Skill.basic()
	var windup := Incoming.new()
	windup.attacker = hero2
	windup.target = foe2
	windup.kind = Skill.Kind.MELEE
	windup.phase = Battle.Phase.WINDUP
	windup.plan = []
	b2.incoming.append(windup)
	var stopped2 := b2.interrupt_attacks_of(hero2, foe2, 1.0)
	_expect(stopped2 and hero2.queued_skill == null, "Interrupção real do wind-up apaga a fila (D-1146)")


func _test_queue_snapshot() -> void:
	var b := Battle.new()
	var hero := Combatant.new("Hero", 100, 10, 0.5, true)
	var foe := Combatant.new("Foe", 100, 10, 0.5, false)
	b.start([hero], [foe])
	hero.queued_skill = Skill.basic()
	hero.queued_target = foe
	var snap := b.save_state()
	hero.queued_skill = null
	hero.queued_target = null
	b.restore_state(snap)
	_expect(hero.queued_skill != null and hero.queued_target == foe,
		"Snapshot/restore preserva a fila (D-1042/D-1044)")
	var empty := hero.save_state()
	empty["queued_skill"] = null
	empty["queued_target"] = null
	hero.restore_state(empty)
	_expect(hero.queued_skill == null and hero.queued_target == null,
		"Restore sem fila limpa a fila atual")


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


func _status_skill(id: String) -> Skill:
	return Skill.from_id(StringName(id))


## D-1150: the status pause declared by the AI in this frame must stop the rest of the frame,
## so an in-flight attack cannot resolve and cancel the player's move/queue.
func _test_status_pause_midframe_stops_attacks() -> void:
	var bs: Node3D = await _new_scene()
	var battle: Battle = bs.get_node("Battle")
	var leader: Combatant = bs.leader
	var caster: Combatant = battle.enemies[0]
	var in_flight: Combatant = battle.enemies[1] if battle.enemies.size() > 1 else battle.enemies[0]
	var rak := _status_skill("rakunda")
	caster.act_policy = Combatant.Act.SKILL
	caster.skills.clear()
	caster.skills.append(rak)
	caster.atb = 5.0
	caster.mp = 20
	battle._ai._think_left[caster] = 0.0
	battle._ai._plans[caster] = {"skill": rak, "target": leader, "value": 99.0}
	leader.queued_skill = Skill.basic()
	leader.queued_target = in_flight
	var pending := Incoming.new()
	pending.attacker = in_flight
	pending.target = leader
	pending.phase = Battle.Phase.STAGGER
	pending.phase_time = 0.0
	battle._landing.append(pending)
	battle._process(0.1)
	_expect(battle._status_pause != null, "IA declara o status e a pausa começa no mesmo quadro (D-1150)")
	_expect(is_zero_approx(pending.phase_time), "Ataque em voo não avança depois da pausa no mesmo quadro")
	_expect(leader.queued_skill != null, "A fila do jogador sobrevive à pausa declarada no meio do quadro")
	bs.free()


func _test_status_pause_gates() -> void:
	var bs: Node3D = await _new_scene()
	var battle: Battle = bs.get_node("Battle")
	var leader: Combatant = battle.party[0]
	var caster: Combatant = battle.enemies[0]
	var tar := _status_skill("tarukaja")
	caster.atb = 3.0
	caster.mp = 20
	leader.atb = 3.0
	leader.mp = 20
	leader.inventory["potion"] = 1
	var used := battle.use_skill(caster, tar, caster)
	await process_frame
	_expect(used and battle.is_status_paused(), "Pausa de status ativa para o teste")
	var item := Item.get_item("potion")
	var item_ok := battle.use_item(leader, item, leader)
	_expect(not item_ok, "Item bloqueado durante a pausa (D-1146)")
	var step_ok := battle.can_step(leader, 1)
	_expect(not step_ok and battle.step_block_reason(leader) == "pausa de status",
		"Passo bloqueado durante a pausa (D-1146)")
	var guard_reason := battle.guard_block_reason(leader)
	var guard_ok := battle.use_guard(leader)
	_expect(guard_reason == "" and guard_ok, "Guard permitido durante a pausa (D-1146)")
	bs.free()


func _test_war_cry_freeze_and_aura() -> void:
	var bs: Node3D = await _new_scene()
	var battle: Battle = bs.get_node("Battle")
	var leader: Combatant = battle.party[0]
	var enemy: Combatant = battle.enemies[0]
	var fake := Incoming.new()
	fake.attacker = leader
	fake.label = "War Cry"
	var before: int = bs.fx.get_child_count()
	bs.fx.on_status_pause_started(fake)
	_expect(bs.fx.get_child_count() == before, "War Cry não cria a aura genérica da D-031 (D-1147)")
	bs.fx.on_status_pause_ended(fake)
	var ap: AnimationPlayer = bs.fx._anim_player(enemy)
	if ap != null and ap.has_animation("attack"):
		ap.play("attack")
	var war := _status_skill("war_cry")
	leader.atb = 3.0
	leader.mp = 3
	var used := battle.use_skill(leader, war, enemy)
	await process_frame
	_expect(used and battle._status_pause == null, "War Cry não pausa o motor (D-1127)")
	_expect(ap != null and is_zero_approx(ap.speed_scale), "War Cry congela a animação dos outros (feature D-1147)")
	_expect(not battle._war_cry_active.is_empty(), "War Cry registra o evento ativo para fechar o congelamento")
	# The freeze ends with this War Cry's own end event, not before.
	if not battle._war_cry_active.is_empty():
		bs.fx.on_status_pause_ended(battle._war_cry_active[0])
	_expect(ap != null and not is_zero_approx(ap.speed_scale), "O fim do War Cry descongela o lote dele")
	var cancelled := Incoming.new()
	cancelled.attacker = leader
	cancelled.label = "War Cry"
	cancelled.ghost = true
	cancelled.interrupted = true
	bs.fx.on_phase(cancelled, Battle.Phase.RETURN)
	_expect(bs.fx.get_node_or_null("WarCryVfx") == null, "Cast cancelado não dispara o cone (D-1147)")
	bs.free()


func _test_buff_visual_respects_freeze() -> void:
	var bs: Node3D = await _new_scene()
	var battle: Battle = bs.get_node("Battle")
	var victim: Combatant = battle.enemies[0]
	var caster: Combatant = battle.enemies[1] if battle.enemies.size() > 1 else battle.enemies[0]
	var ap: AnimationPlayer = bs.fx._anim_player(victim)
	if ap != null and ap.has_animation("attack"):
		ap.play("attack")
	var rak := _status_skill("rakunda")
	caster.atb = 3.0
	caster.mp = 20
	var used := battle.use_skill(caster, rak, victim)
	var waited := 0.0
	while used and battle._status_pause != null and victim.def_buff >= 0 and waited < 3.0:
		await process_frame
		waited += 0.016
	_expect(used and battle._status_pause and victim.def_buff < 0, "Rakunda aplicou o debuff durante a pausa")
	_expect(ap != null and is_zero_approx(ap.speed_scale),
		"Buff/debuff não religa a animação congelada pela pausa (D-1146)")
	bs.free()
