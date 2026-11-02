extends SceneTree
## Rules-only checks of the battle space: positions are authoritative, attacks track a
## moving target, projectiles are guided, interception is decided when the attack is
## declared, and everyone ends up back on its step spot. No models, no FX.
##
##   godot --headless --path . --script res://tests/battle/test_attack_motion.gd

var failures := 0
const DT := 1.0 / 60.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_melee_reaches_and_returns()
	_test_melee_follows_a_target_that_moves()
	_test_projectile_is_guided()
	_test_interception_at_declaration()
	_test_teleport_is_the_rules_business()
	if failures == 0:
		print("BATTLE_MOTION_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + msg)


## Two teams facing each other: the player side at z = 0, the enemy side far behind.
func _arena(extra_ally := false) -> Dictionary:
	var battle := Battle.new()
	var leader := Combatant.new("Leader", 100, 10, 0.5, true)
	leader.place(Vector3(0, 0, 0), PI)
	var party: Array[Combatant] = [leader]
	if extra_ally:
		var ally := Combatant.new("Ally", 100, 10, 0.5, true)
		ally.place(Vector3(0, 0, -10), PI)  # Standing on the line between the enemy and the leader.
		party.append(ally)
	var foe := Combatant.new("Foe", 100, 10, 0.5, false)
	foe.place(Vector3(0, 0, -30), 0.0)
	var foes: Array[Combatant] = [foe]
	for c in party + foes:
		c.act_policy = Combatant.Act.HOLD
	battle.start(party, foes)
	return {"battle": battle, "leader": leader, "foe": foe, "ally": party[1] if extra_ally else null}


## Runs the battle clock until `inc` is done (or `limit` seconds). `on_frame` may move things.
func _run_until_done(battle: Battle, inc: Incoming, on_frame := Callable(), limit := 6.0) -> void:
	var t := 0.0
	while inc.phase != Incoming.Phase.DONE and t < limit:
		battle._process(DT)
		if on_frame.is_valid():
			on_frame.call(inc, t)
		t += DT


func _test_melee_reaches_and_returns() -> void:
	var w := _arena()
	var battle: Battle = w["battle"]
	var leader: Combatant = w["leader"]
	var foe: Combatant = w["foe"]
	var contact := [-1.0]
	battle.hit_resolved.connect(func(a: Combatant, t: Combatant, _e, _i) -> void:
		contact[0] = a.pos.distance_to(t.pos))
	_expect(battle.use_skill(leader, Skill.new("Tackle", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE), foe), "melee attack is accepted")
	var inc: Incoming = battle.incoming[0]
	_run_until_done(battle, inc)
	_expect(inc.phase == Incoming.Phase.DONE, "the attack finishes")
	_expect(absf(contact[0] - (BattleSpace.STAND_GAP - AttackMotion.LUNGE_OVERSHOOT)) < 0.05, "damage lands with the attacker at the contact distance (got %.2f)" % contact[0])
	_expect(leader.pos.distance_to(leader.stand_pos()) < 0.01, "the attacker is back on its step spot (at %s)" % leader.pos)
	battle.free()


func _test_melee_follows_a_target_that_moves() -> void:
	var w := _arena()
	var battle: Battle = w["battle"]
	var leader: Combatant = w["leader"]
	var foe: Combatant = w["foe"]
	var contact := [-1.0]
	battle.hit_resolved.connect(func(a: Combatant, t: Combatant, _e, _i) -> void:
		contact[0] = a.pos.distance_to(t.pos))
	battle.use_skill(leader, Skill.new("Tackle", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE), foe)
	var inc: Incoming = battle.incoming[0]
	var moved := [false]
	_run_until_done(battle, inc, func(i: Incoming, _t: float) -> void:
		# Mid-run the target is pushed 6 units to the side: the attacker must follow it.
		if not moved[0] and i.phase == Incoming.Phase.TRAVEL and i.progress() > 0.5:
			moved[0] = true
			foe.set_rest(foe.pos + Vector3(6, 0, 0)))
	_expect(moved[0], "the target did move during the run")
	_expect(absf(contact[0] - (BattleSpace.STAND_GAP - AttackMotion.LUNGE_OVERSHOOT)) < 0.1, "the attacker still reached the moved target (got %.2f)" % contact[0])
	battle.free()


func _test_projectile_is_guided() -> void:
	var w := _arena()
	var battle: Battle = w["battle"]
	var leader: Combatant = w["leader"]
	var foe: Combatant = w["foe"]
	var miss := [-1.0]
	battle.hit_resolved.connect(func(_a, t: Combatant, _e, info: Dictionary) -> void:
		if not info.get("evaded", false):
			var inc_now: Incoming = battle.attacks_in_flight()[0]
			miss[0] = BattleSpace.flat(inc_now.proj_pos).distance_to(BattleSpace.flat(t.pos)))
	battle.use_skill(leader, Skill.new("Bola", 1.0, 2, Element.Type.AGUA_GELO, Skill.Kind.PROJECTILE), foe)
	var inc: Incoming = battle.incoming[0]
	var moved := [false]
	_run_until_done(battle, inc, func(i: Incoming, _t: float) -> void:
		if not moved[0] and i.phase == Incoming.Phase.TRAVEL and i.progress() > 0.4:
			moved[0] = true
			foe.set_rest(foe.pos + Vector3(-5, 0, 3)))
	# The shot may be an automatic dodge (10%): then there is nothing to measure.
	if not inc.auto_dodged:
		_expect(moved[0], "the target did move during the flight")
		_expect(miss[0] >= 0.0 and miss[0] < 0.1, "the projectile arrives on the moved target (off by %.2f)" % miss[0])
	battle.free()


func _test_interception_at_declaration() -> void:
	var w := _arena(true)
	var battle: Battle = w["battle"]
	var leader: Combatant = w["leader"]
	var foe: Combatant = w["foe"]
	var ally: Combatant = w["ally"]
	# The foe aims at the leader but the ally stands exactly on the line.
	battle.use_skill(foe, Skill.new("Bola", 1.0, 2, Element.Type.AGUA_GELO, Skill.Kind.PROJECTILE), leader)
	var inc: Incoming = battle.incoming[0]
	_expect(inc.target == ally, "the blocker is the target from the moment the attack is declared")
	var aoe := Skill.new("Chuva", 1.0, 2, Element.Type.AGUA_GELO, Skill.Kind.PROJECTILE, false, true)
	battle.use_skill(foe, aoe, leader)
	battle.free()


func _test_teleport_is_the_rules_business() -> void:
	var w := _arena()
	var battle: Battle = w["battle"]
	var leader: Combatant = w["leader"]
	var foe: Combatant = w["foe"]
	battle.use_skill(leader, Skill.new("Teleporte Rápido", 1.1, 1, Element.Type.PSIQUICO, Skill.Kind.PROJECTILE), foe)
	var inc: Incoming = battle.incoming[0]
	var seen_dest := [false]
	_run_until_done(battle, inc, func(i: Incoming, _t: float) -> void:
		if i.blink and leader.pos.distance_to(i.dest) < 0.01:
			seen_dest[0] = true)
	_expect(inc.blink and inc.dest.distance_to(inc.from) > 1.0, "the blink has a destination of its own")
	_expect(seen_dest[0], "the rules put the caster at the blink destination")
	_expect(leader.pos.distance_to(leader.stand_pos()) < 0.01, "the caster is back on its step spot")
	battle.free()
