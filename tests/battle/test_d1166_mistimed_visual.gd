extends SceneTree
## D-1166: a mistimed Evade always shows WHIFF + dust, and a Pokemon model whose "down"
## clip does not drop the body gets a code-driven fall. Runs with:
## godot --headless --path . --script res://tests/battle/test_d1163_mistimed_visual.gd

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
	print("   CRAWMON — DODGE ERRADO: QUEDA + WHIFF + POEIRA (D-1166)")
	print("=================================================================")
	await _test_mistimed_visual()
	_test_mistimed_rules()
	print("=================================================================")
	if failures == 0:
		print("D1166_MISTIMED_VISUAL_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)


func _new_scene() -> Node3D:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	bs.set_meta("vfx_room", true)
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	await create_timer(1.5, true, false, true).timeout
	return bs


func _whiff_labels(fx: BattleFx) -> int:
	var n := 0
	var roots: Dictionary = fx.fx_dodge._whiff_labels
	for actor in roots.keys():
		var root: Node3D = roots[actor]
		if root == null or not is_instance_valid(root):
			continue
		var word := ""
		var letters := 0
		for child in root.get_children():
			if child is Label3D:
				word += String(child.text)
				letters += 1
		if letters == 5 and word == "WHIFF":
			n += 1
	return n


func _test_mistimed_visual() -> void:
	var bs: Node3D = await _new_scene()
	var leader: Combatant = bs.leader
	var fx: BattleFx = bs.fx
	var m: Node3D = fx._models[leader]
	var ap: AnimationPlayer = fx._anim_player(leader)
	var base_x := m.rotation.x
	var base_children := fx.get_child_count()
	_expect(not fx.fx_dodge._down_clip_falls(ap), "O clipe down do Pokémon não derruba o corpo sozinho")
	fx.fx_dodge.mistimed(leader, null)
	await process_frame
	_expect(_whiff_labels(fx) == 1, "WHIFF aparece acima do personagem")
	_expect(ap.current_animation == "damage", "Sem clipe de queda, o damage entra como fallback")
	await create_timer(0.35, true, false, true).timeout
	_expect(absf(m.rotation.x - (base_x - PI * 0.5)) < 0.12, "O corpo cai de verdade (assistência de código)")
	_expect(fx.get_child_count() > base_children + 1, "A poeira nasce no chão")
	var t_idle := Time.get_ticks_msec()
	while ap.current_animation != "battle_idle" and Time.get_ticks_msec() - t_idle < 3000:
		await process_frame
	_expect(absf(m.rotation.x - base_x) < 0.02, "O corpo volta a ficar em pé")
	_expect(ap.current_animation == "battle_idle", "Volta ao idle sozinho")
	bs.free()
	await process_frame


func _test_mistimed_rules() -> void:
	var b := Battle.new()
	var a := Combatant.new("Atacante", 100, 10, 0.5, true)
	var e := Combatant.new("Alvo", 100, 10, 0.5, false)
	b.start([a], [e])
	e.atb = 5.0
	var inc := Incoming.new()
	inc.attacker = a
	inc.target = e
	inc.kind = Skill.Kind.MELEE
	inc.label = "Teste"
	inc.resolved = true
	inc.motion = "melee"
	inc.phase = Incoming.Phase.STRIKE
	inc.plan = [[Incoming.Phase.STRIKE, 0.5]]
	inc.plan_i = 0
	inc.impact_phase = Incoming.Phase.STRIKE
	inc.phase_time = 0.5
	var events := [0]
	b.evade_mistimed.connect(func(_actor, _i) -> void: events[0] += 1)
	var before := e.atb
	var ok := b.try_evade(e, inc)
	_expect(not ok and events[0] == 1, "Evade fora da janela emite evade_mistimed")
	_expect(inc.evade_tried and not inc.dodged and e.atb < before, "O ATB é gasto e o golpe não é desviado")
