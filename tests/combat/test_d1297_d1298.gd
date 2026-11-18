extends SceneTree
## D-1297 (reward tokens ignore freeze/slow-motion) and D-1298 (a no-MP Move never pauses the MP pulse).
## Logic only, both sides (D-235): run with
##   Godot --headless --path . --script res://tests/combat/test_d1297_d1298.gd

var _fails := 0


func _init() -> void:
	for ally_side in [true, false]:
		_test_mp_regen(ally_side)
		_test_reward_real_time(ally_side)
		_test_steps(ally_side)
	print("RESULT: ", "PASS" if _fails == 0 else "FAIL (%d)" % _fails)
	Engine.time_scale = 1.0
	quit(1 if _fails > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	print(("  ok  " if cond else "  FAIL ") + msg)
	if not cond:
		_fails += 1


func _pair(actor_is_player: bool) -> Array:
	var actor := Combatant.new("Actor", 40, 3, 1.0, actor_is_player)
	var foe := Combatant.new("Foe", 400, 3, 1.0, not actor_is_player)
	actor.max_mp = 30
	actor.mp = 10
	var b := Battle.new()
	var team_a: Array[Combatant] = [actor if actor_is_player else foe]
	var team_b: Array[Combatant] = [foe if actor_is_player else actor]
	b.start(team_a, team_b)
	actor.atb = 5.0
	for c in [actor, foe]:
		c.in_battle = true  # the scene sets this when it places a model
	return [b, actor, foe]


func _test_mp_regen(actor_is_player: bool) -> void:
	print("MP regen, actor on ", "party" if actor_is_player else "enemy", " side")
	var s := _pair(actor_is_player)
	var b: Battle = s[0]
	var actor: Combatant = s[1]
	var foe: Combatant = s[2]
	var tackle := Skill.basic()
	_ok(tackle.mp_cost == 0, "Tackle costs 0 MP")
	_ok(b.use_skill(actor, tackle, foe), "Tackle started")
	_ok(b.is_winding_up(actor), "actor is winding up")
	var t0 := actor.mp_regen_timer
	b._process(0.5)
	_ok(actor.mp_regen_timer > t0 + 0.49, "MP timer advanced during the wind-up (%.2f -> %.2f)" % [t0, actor.mp_regen_timer])


func _test_reward_real_time(actor_is_player: bool) -> void:
	print("Reward tokens, owner on ", "party" if actor_is_player else "enemy", " side")
	var s := _pair(actor_is_player)
	var b: Battle = s[0]
	var owner: Combatant = s[1]
	var foe: Combatant = s[2]
	owner.atb = 1.0
	b.grant_atb(owner, 1, foe)
	var r: BattleReward = b.rewards[0]
	var total: float = r.float_time + r.fly_time
	# 0.25x slow-motion and a hit-stop together: 1.0 real second must still land it.
	Engine.time_scale = 0.25
	b.freeze(3.0)
	var real := 0.0
	var frames := 0
	while real < total + 0.05 and frames < 2000:
		b._process(0.01 * Engine.time_scale)  # Godot hands _process a scaled delta
		real += 0.01
		frames += 1
	Engine.time_scale = 1.0
	_ok(r.landed, "token landed after %.2f real s despite freeze + 0.25x (age %.2f / %.2f)" % [real, r.age(), total])
	_ok(owner.pending_atb == 0, "pending_atb released")


## D-1299: steps are free, never locked, queue while busy; the AI chooses a position by itself.
func _test_steps(actor_is_player: bool) -> void:
	print("Steps, actor on ", "party" if actor_is_player else "enemy", " side")
	var s := _pair(actor_is_player)
	var b: Battle = s[0]
	var actor: Combatant = s[1]
	var foe: Combatant = s[2]
	actor.atb = 0.0
	_ok(b.step(actor, 1) and actor.pos_step == 1, "step with 0 ATB works and costs nothing (atb=%.2f)" % actor.atb)
	# Busy: a Move is winding up, so the step waits in the queue.
	actor.atb = 5.0
	_ok(b.use_skill(actor, Skill.basic(), foe), "Tackle started")
	_ok(b.step(actor, 1) and actor.pos_step == 1 and actor.queued_step == 1, "step while winding up is queued, not refused")
	var guard := 0
	while actor.queued_step != 0 and guard < 400:
		b._process(0.05)
		guard += 1
	_ok(actor.pos_step == 2, "queued step ran once idle (pos %d after %d frames)" % [actor.pos_step, guard])
	_ok(not b.step(actor, 1), "beyond +2 is refused")
	# AI: nobody set tactic_pos; AI-controlled combatants of BOTH teams must walk by themselves (D-235).
	# (What position they pick and why is covered by test_d1299_positioning.gd.)
	var seen := {}
	var leader := Combatant.new("Lead", 400, 6, 1.0, true)  # party[0] is the player's menu owner, not AI
	var ally_ai := Combatant.new("AllyAI", 400, 20, 1.0, true)
	var enemy_ai := Combatant.new("EnemyAI", 400, 20, 1.0, false)
	var t1: Array[Combatant] = [leader, ally_ai]
	var t2: Array[Combatant] = [enemy_ai]
	var b2 := Battle.new()
	b2.start(t1, t2)
	b2.stepped.connect(func(c, _p): seen[c.name] = int(seen.get(c.name, 0)) + 1)
	for c in [leader, ally_ai, enemy_ai]:
		c.in_battle = true
	var t := 0.0
	while t < 60.0:
		b2._process(0.05)
		t += 0.05
	_ok(seen.has("EnemyAI") and b2._ai.positioning.scores.has(ally_ai) and b2._ai.positioning.scores.has(enemy_ai), "AI of both teams evaluates positions and the threatened one walked by itself: %s" % [seen])
