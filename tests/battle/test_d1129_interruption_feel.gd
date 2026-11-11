extends SceneTree
## D-1129: real interruptions briefly slow the whole game (0.35x / 0.45 s real), shake the
## camera when the interrupt had no hit shake of its own (War Cry/status), play only once
## for 2+ victims in the same frame and throttle only that multi-target case for 6 s.
## Run with: godot --headless --path . --script res://tests/battle/test_d1129_interruption_feel.gd

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _wait_real(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — INTERRUPÇÃO: CÂMERA LENTA E SHAKE (D-1129)")
	print("=================================================================")

	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	bs.set_meta("vfx_room", true)  # Nobody acts on its own.
	bs.set_meta("vfx_room_mirror", true)  # Guarantees 3 units with models (1 ally + 2 enemies).
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	Engine.time_scale = 1.0
	bs._interrupt_multi_ready_at = 0
	bs._interrupt_slowmo_active = false

	var tackle := Skill.new("Tackle", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.5)
	var source: Combatant = battle.party[0]
	var victim1: Combatant = battle.enemies[0]
	var victim2: Combatant = battle.enemies[1]

	# 1. Two victims in the same frame: one slow-motion, one shake, one 6 s lock.
	_expect(_start_windup(battle, victim1, tackle, source), "Vitima 1 entra em wind-up")
	_expect(_start_windup(battle, victim2, tackle, source), "Vitima 2 entra em wind-up")
	battle.interrupt_windup_of(victim1, source)
	battle.interrupt_windup_of(victim2, source)
	await process_frame
	await process_frame
	_expect(is_equal_approx(Engine.time_scale, bs.INTERRUPTION_SLOWMO_SCALE), "Multi-alvo desacelera para 0,35x uma vez")
	_expect(bs._interrupt_multi_ready_at > Time.get_ticks_msec(), "Multi-alvo arma o cooldown de 6 s")
	_expect(bs.director._shake_trauma > 0.0, "War Cry multi-alvo dá shake uma vez")
	var expected_dir := -BattleSpace.flat_dir(source.pos, victim1.pos)
	_expect(bs.director._shake_dir.is_equal_approx(expected_dir), "Shake segue a direção lançador→alvo (D-235)")
	await _wait_real(0.90)
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Volta a 1,0x depois de 0,45 s + 0,12 s")

	# 2. Another multi-target event inside the 6 s window: no second effect.
	bs.director._shake_trauma = 0.0
	_expect(_start_windup(battle, victim1, tackle, source), "Vitima 1 entra em wind-up de novo")
	_expect(_start_windup(battle, victim2, tackle, source), "Vitima 2 entra em wind-up de novo")
	battle.interrupt_windup_of(victim1, source)
	battle.interrupt_windup_of(victim2, source)
	await process_frame
	await process_frame
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Segundo multi-alvo dentro de 6 s não desacelera")
	_expect(bs.director._shake_trauma == 0.0, "Segundo multi-alvo dentro de 6 s não dá shake")

	# 2b. A multi-target HIT (AoE) also counts once and adds no second shake (D-157).
	bs._interrupt_multi_ready_at = 0
	bs.director._shake_trauma = 0.0
	_expect(_start_windup(battle, victim1, tackle, source), "Vitima 1 entra em wind-up para o AoE")
	_expect(_start_windup(battle, victim2, tackle, source), "Vitima 2 entra em wind-up para o AoE")
	battle.interrupt_attacks_of(victim1, source, 1.0)
	battle.interrupt_attacks_of(victim2, source, 1.0)
	await process_frame
	await process_frame
	_expect(is_equal_approx(Engine.time_scale, bs.INTERRUPTION_SLOWMO_SCALE), "AoE com 2 alvos desacelera uma vez")
	_expect(bs.director._shake_trauma == 0.0, "AoE com 2 alvos não soma shake extra de hit")
	await _wait_real(0.90)

	# 3. A single victim still plays during the multi-target cooldown.
	_expect(_start_windup(battle, victim1, tackle, source), "Vitima 1 entra em wind-up sozinha")
	battle.interrupt_windup_of(victim1, source)
	await process_frame
	await process_frame
	_expect(is_equal_approx(Engine.time_scale, bs.INTERRUPTION_SLOWMO_SCALE), "Alvo único desacelera mesmo no cooldown multi-alvo")
	_expect(bs.director._shake_trauma > 0.0, "Alvo único de War Cry dá shake")
	await _wait_real(0.90)

	# 4. A hit interruption already has the normal hit shake (D-157): no second shake.
	bs.director._shake_trauma = 0.0
	_expect(_start_windup(battle, victim1, tackle, source), "Vitima 1 entra em wind-up para o hit")
	battle.interrupt_attacks_of(victim1, source, 1.0)
	await process_frame
	await process_frame
	_expect(is_equal_approx(Engine.time_scale, bs.INTERRUPTION_SLOWMO_SCALE), "Hit que interrompe desacelera")
	_expect(bs.director._shake_trauma == 0.0, "Hit que interrompe não soma um segundo shake")
	await _wait_real(0.90)

	# 5. D-235 symmetry: swapping source/target sides flips the shake direction.
	bs._interrupt_batch.clear()
	bs._interrupt_flush_queued = false
	bs._interrupt_slowmo_active = false
	Engine.time_scale = 1.0
	bs.director._shake_trauma = 0.0
	var mirror_source := Combatant.new("Source", 100, 10, 0.40, true)
	var mirror_victim := Combatant.new("Victim", 100, 10, 0.40, false)
	mirror_source.pos = Vector3(-5, 0, -30)
	mirror_victim.pos = Vector3(5, 0, -30)
	bs._on_interrupted_windup(mirror_victim, mirror_source)
	bs._flush_interruptions()
	_expect(bs.director._shake_dir.is_equal_approx(Vector3.LEFT), "Vista normal: shake aponta para a esquerda")
	await _wait_real(0.90)
	bs._interrupt_batch.clear()
	bs._interrupt_flush_queued = false
	bs._interrupt_slowmo_active = false
	Engine.time_scale = 1.0
	bs.director._shake_trauma = 0.0
	mirror_source.pos = Vector3(5, 0, -30)
	mirror_victim.pos = Vector3(-5, 0, -30)
	bs._on_interrupted_windup(mirror_victim, mirror_source)
	bs._flush_interruptions()
	_expect(bs.director._shake_dir.is_equal_approx(Vector3.RIGHT), "Vista espelhada: shake aponta para a direita")

	bs.free()
	Engine.time_scale = 1.0
	print("=================================================================")
	if failures == 0:
		print("D1129_INTERRUPTION_FEEL_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)


func _start_windup(battle: Battle, actor: Combatant, skill: Skill, target: Combatant) -> bool:
	actor.atb = 3.0
	return battle.use_skill(actor, skill, target)
