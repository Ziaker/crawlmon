class_name AttackPlanner
extends RefCounted
## Plans a resolved attack in the rules: who is hit, where the attacker runs, how long every
## phase lasts. The result goes into the `Incoming` (plan + kinematics); the drawing only
## reads it. Durations that depend on a model's animation come from `Combatant.clips`.

const Phase = Incoming.Phase

var b: Battle


func _init(p_battle: Battle) -> void:
	b = p_battle


## Fills inc.plan, inc.impact_phase and the kinematic fields. Returns the total duration.
func plan(inc: Incoming) -> float:
	var a := inc.attacker
	var t := inc.target
	if inc.move_id.is_empty():
		inc.move_id = BattleSpace.move_id(inc.label)
	if inc.move_data == null:
		inc.move_data = MoveCatalog.get_move(StringName(inc.move_id))
	var move := inc.move_data
	var a_home := a.rest_pos()  # Engaged characters stand away from their step spot.
	var t_home := t.rest_pos()
	inc.dir = BattleSpace.flat_dir(a_home, t_home)
	# The contact distance comes from the Move's sheet (D-1079), not from its name.
	var is_dig := move != null and move.plan_profile == &"dig"  # D-1196: Dig timeline of the HTML; melee that emerges on top of the target.
	inc.stand_gap = move.stand_gap if move != null and (move.stand_gap > 0.0 or (is_dig and move.stand_gap >= 0.0)) else BattleSpace.STAND_GAP
	# Travel times start from the step-0 geometry and then lose 0.10 s per step.
	var a0 := a.home
	var t0 := t.home
	if move != null and move.plan_profile == &"cast_strike_travel":
		var cast_hit := 0.15 if inc.instant else clip_hit(a, "attack_special", BattleSpace.CAST_AT)
		inc.motion = "cast"
		var travel_base := move.plan_fly if move.plan_fly >= 0.0 else base_fly(a0, t0)
		inc.fly = Battle.travel_seconds(travel_base, a, t)
		var cast_return := move.plan_return if move.plan_return >= 0.0 else maxf(BattleSpace.CAST_AT + 0.42 - cast_hit - inc.fly, 0.05)
		inc.plan = [[Phase.STRIKE, cast_hit], [Phase.TRAVEL, inc.fly], [Phase.RETURN, cast_return]]
		inc.impact_phase = Phase.TRAVEL
	elif move != null and move.plan_profile == &"teleport":
		var attack_dir := BattleSpace.flat_dir(a_home, t_home)
		inc.motion = "cast"
		inc.blink = true
		inc.from = a_home
		inc.aim = t_home
		inc.dest = t_home + attack_dir * move.blink_distance
		var blink_hit := 0.22 if inc.instant else clip_hit(a, "attack", 0.22)
		inc.fly = 0.05
		inc.plan = [[Phase.TRAVEL, 0.05], [Phase.STRIKE, blink_hit], [Phase.RETURN, 0.35]]
		inc.impact_phase = Phase.STRIKE
	elif inc.kind == Skill.Kind.MELEE and a.engaged_with == t and inc.stand_gap <= BattleSpace.STAND_GAP + 0.01 and not is_dig:
		# Already standing next to it: no travel, no return.
		var hit0 := clip_hit(a, "attack", BattleSpace.HIT_AT)
		hit0 = _strike_override(inc, hit0)  # D-241
		# Its first action after the Evade: it appears next to the attacker it interrupted.
		# Later actions are already there.
		if not a.has_rest:
			arrive_next_to(a, t)
			inc.arrived = true
		var opp_pos := t.pos
		a_home = a.rest_pos()
		inc.dir = BattleSpace.flat_dir(a_home, opp_pos)
		inc.motion = "engaged"
		inc.stand = a_home
		inc.from = a_home
		inc.run_t = 0.0
		inc.hit = hit0
		inc.hold = 0.0
		inc.antic = 0.0
		inc.hop_t = 0.3
		inc.hop_h = 1.2
		inc.plan = [[Phase.STRIKE, hit0]]
		inc.impact_phase = Phase.STRIKE
	elif inc.kind == Skill.Kind.MELEE:
		var stand := t_home - inc.dir * inc.stand_gap
		var agi_f := Battle.agi_travel_factor(a)  # D-1194: AGI shortens the sheet's time first, then steps (D-018), then the floor
		var run_t := Battle.travel_seconds(base_run_for(a0, t0, inc.stand_gap) * agi_f, a, t)
		if move != null and move.run_fixed >= 0.0:
			run_t = move.run_fixed  # D-1014: a fixed short step, whatever the speed
		elif move != null and move.run_base >= 0.0:
			run_t = Battle.travel_seconds(move.run_base * agi_f, a, t)
		if not is_dig:  # D-1196: the Dig timeline is the HTML's, whatever the character
			run_t += a.travel_extra  # D-341: slow character, only the run to the target
		var hop_dist := stand.distance_to(a_home)
		inc.motion = "melee"
		inc.stand = stand
		inc.run_t = run_t
		inc.antic = 0.0 if inc.instant else BattleSpace.ANTICIP_T
		inc.hit = clip_hit(a, "attack", BattleSpace.HIT_AT)
		if move != null:
			inc.hit += move.hit_offset
		inc.hit = _strike_override(inc, inc.hit)  # D-241
		if is_dig:
			inc.hit = 0.0  # D-1196: the eruption and the damage are the same instant (HTML 1.38 s).
		if is_dig or (move != null and move.strike_time > 0.0 and move.strike_time <= 0.20):
			inc.antic = 0.0  # the jab lands straight on arrival
		inc.hold = move.hold if move != null and move.hold >= 0.0 else BattleSpace.RETURN_HOLD_DEFAULT  # D-281
		inc.hop_t = clampf(hop_dist / 70.0, 0.22, 0.4)
		if move != null and move.hop_time >= 0.0:
			inc.hop_t = move.hop_time  # D-1196
		inc.hop_h = clampf(hop_dist * 0.12, 1.2, 3.0)
		inc.from = a.pos
		var return_t: float = move.plan_return if is_dig and move.plan_return >= 0.0 else inc.hold + inc.hop_t
		inc.plan = [[Phase.TRAVEL, 0.12 + run_t], [Phase.STRIKE, inc.antic + inc.hit], [Phase.RETURN, return_t]]
		inc.impact_phase = Phase.STRIKE
	else:
		var hit := 0.15 if inc.instant else clip_hit(a, "attack_special", BattleSpace.CAST_AT)
		var total := BattleSpace.CAST_AT + 0.42
		inc.motion = "cast"
		if move != null and move.plan_profile == &"cast_strike_travel":
			inc.fly = move.plan_fly
			inc.plan = [[Phase.STRIKE, hit], [Phase.TRAVEL, inc.fly], [Phase.RETURN, move.plan_return]]
			inc.impact_phase = Phase.TRAVEL
		elif move != null and move.plan_profile == &"cast_travel_strike":
			inc.fly = move.plan_fly * (Battle.agi_travel_factor(a) if inc.kind == Skill.Kind.CAST else 1.0)  # D-1194: mid-range (CAST) only; projectiles ignore AGI
			inc.plan = [[Phase.TRAVEL, inc.fly], [Phase.STRIKE, hit], [Phase.RETURN, move.plan_return]]
			inc.impact_phase = Phase.STRIKE
		elif inc.kind == Skill.Kind.PROJECTILE:
			inc.fly = Battle.travel_seconds(base_fly(a0, t0), a, t)
			inc.plan = [[Phase.STRIKE, hit], [Phase.TRAVEL, inc.fly], [Phase.RETURN, maxf(total - hit - inc.fly, 0.05)]]
			inc.impact_phase = Phase.TRAVEL
		else:
			inc.plan = [[Phase.STRIKE, hit], [Phase.RETURN, maxf(total - hit, 0.05)]]
			inc.impact_phase = Phase.STRIKE
	if inc.motion == "cast":
		inc.from = a.rest_pos()
		AttackMotion.start_projectile(inc)
	var sum := 0.0
	for seg in inc.plan:
		sum += seg[1]
	return sum


## Called when an attack is declared: a plain projectile is hit by whoever stands exactly on
## its line before the aimed target, so the target is final from the start of the wind-up
## (the warning and the Evade window then belong to who will really be hit).
func redirect_if_blocked(inc: Incoming) -> void:
	if inc.kind != Skill.Kind.PROJECTILE or inc.is_aoe or inc.is_friendly:
		return
	if inc.move_data != null:
		if not inc.move_data.redirectable:
			return
	elif BattleSpace.move_id(inc.label) in ["furia_dragao", "provocacao", "onda_choque", "teleporte_rapido"]:
		return
	var block := interceptor(inc, inc.attacker.rest_pos(), inc.target.rest_pos())
	if block != null:
		b.redirect(inc, block)


## The first opponent of the attacker standing on the flat line a_pos -> t_pos, or null.
func interceptor(inc: Incoming, a_pos: Vector3, t_pos: Vector3) -> Combatant:
	var a := inc.attacker
	var foes: Array[Combatant] = b.enemies if a.is_player else b.party
	var line := Vector2(t_pos.x - a_pos.x, t_pos.z - a_pos.z)
	var len2 := line.length_squared()
	if len2 < 0.01:
		return null
	var best: Combatant = null
	var best_k := 0.0
	for c in foes:
		if c == inc.target or not c.is_alive():
			continue
		var p := c.rest_pos()
		var rel := Vector2(p.x - a_pos.x, p.z - a_pos.z)
		var k := rel.dot(line) / len2
		if k <= 0.05 or k >= 1.0:
			continue
		var off := (rel - line * k).length()
		if off < 1.2 * maxf(c.body_scale, 1.0) and (best == null or k < best_k):
			best = c
			best_k = k
	return best


## The evader's first attack: it appears next to the attacker it interrupted, on the side
## away from its own step spot.
func arrive_next_to(actor: Combatant, opponent: Combatant) -> void:
	var opp_pos := opponent.pos
	var away := BattleSpace.flat_dir(opp_pos, actor.stand_pos())
	opponent.set_rest(opp_pos)
	actor.set_rest(opp_pos + away * BattleSpace.STAND_GAP)


## D-241: a Move with `strike_time` in its MoveData lands at that time; the attack clip then runs `hit / new`
## times faster so its contact frame falls on it. Moves without it keep the clip's own contact time.
func _strike_override(inc: Incoming, hit: float) -> float:
	var t: float = inc.move_data.strike_time if inc.move_data != null else -1.0
	if t <= 0.0:
		return hit
	inc.strike_speed = hit / t
	return t


## When the strike lands: the middle of the model's own clip (fallback: the constant).
static func clip_hit(c: Combatant, anim: String, fallback: float) -> float:
	var len := c.clip_len(anim)
	return clampf(len * 0.5, 0.25, 0.8) if len > 0.0 else fallback


static func base_run(a0: Vector3, t0: Vector3) -> float:
	return base_run_for(a0, t0, BattleSpace.STAND_GAP)


## Same run-time estimate, but for a Move that stops at `gap` from the target (Drain Spear).
static func base_run_for(a0: Vector3, t0: Vector3, gap: float) -> float:
	var stand0 := t0 - BattleSpace.flat_dir(a0, t0) * gap
	return clampf(a0.distance_to(stand0) / BattleSpace.RUN_SPEED, 0.6, 1.1)


static func base_fly(a0: Vector3, t0: Vector3) -> float:
	return clampf(a0.distance_to(t0) / BattleSpace.FLY_SPEED, BattleSpace.FLY_TIME, 0.7)


## Seconds a move of `kind` would take to reach `t` from `a` (for the Fight menu); 0 = none.
static func preview_travel(a: Combatant, t: Combatant, kind: int) -> float:
	if kind == Skill.Kind.MELEE:
		return 0.12 + Battle.travel_seconds(base_run(a.home, t.home) * Battle.agi_travel_factor(a), a, t) + a.travel_extra  # D-341, D-1194
	if kind == Skill.Kind.PROJECTILE:
		return Battle.travel_seconds(base_fly(a.home, t.home), a, t)
	return 0.0
