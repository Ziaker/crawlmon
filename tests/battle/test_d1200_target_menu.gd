extends SceneTree
## D-1200: the real battle scene (battle.tscn) driven headless: the S.TARGET picker for a
## single-ally Move (Heal) and the two chained pickers of a dual-target structure Move
## (throwaway Skill built here; no such Move exists). Reads scene state, draws nothing.
## Run with: godot --headless --path . --script res://tests/battle/test_d1200_target_menu.gd

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
	print("=== D-1200: menus de alvo na cena de batalha real ===")
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 900:
		await process_frame
		guard += 1
	for i in 4:
		await process_frame
	for c in bs.models.keys():
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	var leader: Combatant = battle.party[0]
	_expect(battle.party.size() >= 2, "a festa tem pelo menos 2 membros (%d)" % battle.party.size())
	var ally: Combatant = battle.party[1] if battle.party.size() > 1 else leader
	var heal := Skill.from_id(&"heal")
	var dual := Skill.new("DualTest", 1.0, 2, Element.Type.FISICO, Skill.Kind.CAST)
	dual.mp_cost = 0
	dual.target_mode = MoveData.TargetMode.DUAL
	leader.skills.append(heal)
	leader.skills.append(dual)
	leader.max_mp = maxi(leader.max_mp, 30)
	leader.mp = leader.max_mp
	leader.atb = 5.0
	ally.hp = maxi(1, ally.max_hp / 4)
	var wounded_hp := ally.hp
	var allies_alive := battle.party.filter(func(c: Combatant) -> bool: return c.is_alive()).size()

	var seen: Array = []  # every declared attack of the leader, in order
	battle.attack_telegraphed.connect(func(i) -> void:
		if i.attacker == leader:
			seen.append(i))

	# --- Heal: menu Fight -> Heal -> S.TARGET with allies only ---
	bs._show_fight()
	var idx := _fight_index(bs, "Heal")
	_expect(idx >= 0, "Heal aparece na lista do Fight")
	bs._fight_page = idx / bs.FIGHT_SLOTS
	bs._on_chosen(idx % bs.FIGHT_SLOTS)
	_expect(bs.state == bs.S.TARGET, "escolher o Heal abre o S.TARGET")
	var all_allies := true
	for t in bs._targets:
		if not battle.same_team(t, leader):
			all_allies = false
	_expect(all_allies and bs._targets.size() == allies_alive, "o menu lista so aliados vivos (%d)" % bs._targets.size())
	_expect(bs._targets.has(leader), "o proprio lancador esta na lista")
	_expect(_of(battle, leader) == null, "o lider nao lancou nada antes de escolher o alvo")
	# cancel goes back to the Fight list
	bs._on_cancel()
	_expect(bs.state == bs.S.FIGHT, "cancelar volta para a lista do Fight")
	# choose the wounded ally
	bs._on_chosen(idx % bs.FIGHT_SLOTS)
	var pick: int = bs._targets.find(ally)
	_expect(pick >= 0, "o aliado ferido esta na lista")
	bs._on_chosen(pick)
	_expect(bs.state == bs.S.MAIN, "confirmar o alvo volta ao menu principal")
	guard = 0
	while seen.is_empty() and guard < 600:  # the leader may still be busy: the move waits in the one slot (D-161)
		await process_frame
		guard += 1
	var inc: Incoming = seen.back() if not seen.is_empty() else null
	_expect(inc != null and inc.label == "Heal" and inc.target == ally, "o Heal foi lancado no aliado escolhido (%s)" % (inc.target.name if inc != null else "-"))
	guard = 0
	while ally.hp <= wounded_hp and guard < 600:
		await process_frame
		guard += 1
	_expect(ally.hp > wounded_hp, "o aliado escolhido foi curado em jogo (HP %d -> %d)" % [wounded_hp, ally.hp])

	# --- Hotkey path (1-9) goes through the same picker ---
	leader.atb = 5.0
	leader.mp = leader.max_mp
	guard = 0
	while battle.is_attacking(leader) and guard < 600:
		await process_frame
		guard += 1
	bs._show_fight()
	idx = _fight_index(bs, "Heal")
	bs._fight_page = idx / bs.FIGHT_SLOTS
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_1 + (idx % bs.FIGHT_SLOTS)
	bs._unhandled_input(ev)
	_expect(bs.state == bs.S.TARGET, "a tecla numerica do Heal tambem abre o S.TARGET (nao vai no lider)")
	bs._on_cancel()

	# --- Dual structure: two chained pickers ---
	guard = 0
	while (battle.is_attacking(leader) or battle.is_status_paused()) and guard < 900:
		await process_frame
		guard += 1
	for i in 20:  # the scene returns to the main menu a few frames after a status pause ends
		await process_frame
	leader.atb = 5.0
	dual.primary_side = MoveData.TargetSide.ENEMY  # this Move declares: primary = enemy, secondary = ally
	dual.secondary_side = MoveData.TargetSide.ALLY
	bs._show_fight()
	idx = _fight_index(bs, "DualTest")
	bs._fight_page = idx / bs.FIGHT_SLOTS
	bs._on_chosen(idx % bs.FIGHT_SLOTS)
	_expect(bs.state == bs.S.TARGET, "dual: 1o menu (primario) abre (state=%s idx=%d page=%d mp=%d atb=%.1f attacking=%s paused=%s skills=%s)" % [bs.state, idx, bs._fight_page, leader.mp, leader.atb, battle.is_attacking(leader), battle.is_status_paused(), bs._fight_skills.map(func(k): return k.display_name)])
	var foes_alive: int = battle.enemies.filter(func(c: Combatant) -> bool: return c.is_alive()).size()
	var first: Combatant = battle.enemies[0]
	if foes_alive >= 2:
		var only_foes := true
		for t in bs._targets:
			if battle.same_team(t, leader):
				only_foes = false
		_expect(only_foes and bs._targets.size() == foes_alive, "dual: 1o menu (primario ENEMY) lista so inimigos vivos (%d)" % bs._targets.size())
		bs._on_chosen(bs._targets.find(first))
	else:
		print("  [info] so 1 inimigo vivo: o primario e escolhido sozinho e o 2o menu ja abre")
	var only_allies := true
	for t in bs._targets:
		if not battle.same_team(t, leader):
			only_allies = false
	_expect(bs.state == bs.S.TARGET and only_allies and bs._targets.size() == allies_alive, "dual: o 2o menu (secundario ALLY) lista so aliados vivos (%d)" % bs._targets.size())
	bs._on_cancel()
	_expect(bs.state == bs.S.TARGET, "dual: cancelar no 2o menu volta a um menu de alvo")
	if foes_alive >= 2:
		bs._on_chosen(bs._targets.find(first))
	var second: Combatant = ally
	bs._on_chosen(bs._targets.find(second))
	_expect(bs.state == bs.S.MAIN, "dual: apos o 2o alvo volta ao menu principal")
	guard = 0
	while (seen.is_empty() or seen.back().label != "DualTest") and guard < 600:
		await process_frame
		guard += 1
	inc = seen.back() if not seen.is_empty() else null
	_expect(inc != null and inc.label == "DualTest" and inc.target == first and inc.target2 == second,
		"dual: Incoming com primario e secundario escolhidos")

	print("=================================================================")
	if failures == 0:
		print("D1200_TARGET_MENU_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	quit(1 if failures > 0 else 0)


func _fight_index(bs: Node, move_name: String) -> int:
	bs._build_fight_skills()
	for n in bs._fight_skills.size():
		if bs._fight_skills[n].display_name == move_name:
			return n
	return -1


func _of(battle: Battle, who: Combatant) -> Incoming:
	var found: Incoming = null
	if battle._status_pause != null and battle._status_pause.attacker == who:
		return battle._status_pause  # a status move (Heal) runs as the pause itself
	for i in battle.incoming:
		if i.attacker == who:
			found = i
	return found
