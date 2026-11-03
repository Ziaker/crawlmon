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
	inc.move_id = BattleSpace.move_id(inc.label)
	var a_home := a.rest_pos()  # Engaged characters stand away from their step spot.
	var t_home := t.rest_pos()
	inc.dir = BattleSpace.flat_dir(a_home, t_home)
	# Travel times start from the step-0 geometry and then lose 0.10 s per step.
	var a0 := a.home
	var t0 := t.home
	if inc.move_id == "furia_dragao":
		var rage_hit := 0.15 if inc.instant else clip_hit(a, "attack_special", BattleSpace.CAST_AT)
		inc.motion = "cast"
		inc.fly = Battle.travel_seconds(0.30, a, t)
		inc.plan = [[Phase.STRIKE, rage_hit], [Phase.TRAVEL, inc.fly], [Phase.RETURN, 0.16]]
		inc.impact_phase = Phase.TRAVEL
	elif inc.move_id == "teleporte_rapido":
		var attack_dir := BattleSpace.flat_dir(a_home, t_home)
		inc.motion = "cast"
		inc.blink = true
		inc.from = a_home
		inc.aim = t_home
		inc.dest = t_home + attack_dir * 1.35
		var hit := 0.22 if inc.instant else clip_hit(a, "attack", 0.22)
		inc.fly = 0.05
		inc.plan = [[Phase.TRAVEL, 0.05], [Phase.STRIKE, hit], [Phase.RETURN, 0.35]]
		inc.impact_phase = Phase.STRIKE
	elif inc.kind == Skill.Kind.MELEE and a.engaged_with == t:
		# Already standing next to it: no travel, no return.
		var hit0 := clip_hit(a, "attack", BattleSpace.HIT_AT)
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
		var stand := t_home - inc.dir * BattleSpace.STAND_GAP
		var run_t := Battle.travel_seconds(base_run(a0, t0), a, t)
		match inc.move_id:
			"soco_rapido": run_t = Battle.travel_seconds(0.18, a, t)
			"golpe_carate": run_t = Battle.travel_seconds(0.22, a, t)
			"quebra_telha": run_t = Battle.travel_seconds(0.24, a, t)
			"garra_dragao": run_t = Battle.travel_seconds(0.22, a, t)
			"investida_escavadora": run_t = Battle.travel_seconds(0.26, a, t)
			"hassou_tobi": run_t = Battle.travel_seconds(0.18, a, t)
			"titanomachia": run_t = Battle.travel_seconds(0.24, a, t)
		var hop_dist := stand.distance_to(a_home)
		inc.motion = "melee"
		inc.stand = stand
		inc.run_t = run_t
		inc.antic = 0.0 if inc.instant else BattleSpace.ANTICIP_T
		inc.hit = clip_hit(a, "attack", BattleSpace.HIT_AT)
		inc.hold = 0.2
		inc.hop_t = clampf(hop_dist / 70.0, 0.22, 0.4)
		inc.hop_h = clampf(hop_dist * 0.12, 1.2, 3.0)
		inc.from = a.pos
		inc.plan = [[Phase.TRAVEL, 0.12 + run_t], [Phase.STRIKE, inc.antic + inc.hit], [Phase.RETURN, 0.2 + inc.hop_t]]
		inc.impact_phase = Phase.STRIKE
	else:
		var hit := 0.15 if inc.instant else clip_hit(a, "attack_special", BattleSpace.CAST_AT)
		var total := BattleSpace.CAST_AT + 0.42
		inc.motion = "cast"
		if inc.move_id == "provocacao":
			inc.fly = 0.28
			inc.plan = [[Phase.STRIKE, hit], [Phase.TRAVEL, 0.28], [Phase.RETURN, 0.17]]
			inc.impact_phase = Phase.TRAVEL
		elif inc.move_id == "onda_choque":
			inc.fly = 0.24
			inc.plan = [[Phase.TRAVEL, 0.24], [Phase.STRIKE, hit], [Phase.RETURN, 0.20]]
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
	if BattleSpace.move_id(inc.label) in ["furia_dragao", "provocacao", "onda_choque", "teleporte_rapido"]:
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


## When the strike lands: the middle of the model's own clip (fallback: the constant).
static func clip_hit(c: Combatant, anim: String, fallback: float) -> float:
	var len := c.clip_len(anim)
	return clampf(len * 0.5, 0.25, 0.8) if len > 0.0 else fallback


static func base_run(a0: Vector3, t0: Vector3) -> float:
	var stand0 := t0 - BattleSpace.flat_dir(a0, t0) * BattleSpace.STAND_GAP
	return clampf(a0.distance_to(stand0) / BattleSpace.RUN_SPEED, 0.6, 1.1)


static func base_fly(a0: Vector3, t0: Vector3) -> float:
	return clampf(a0.distance_to(t0) / BattleSpace.FLY_SPEED, BattleSpace.FLY_TIME, 0.7)


## Seconds a move of `kind` would take to reach `t` from `a` (for the Fight menu); 0 = none.
static func preview_travel(a: Combatant, t: Combatant, kind: int) -> float:
	if kind == Skill.Kind.MELEE:
		return 0.12 + Battle.travel_seconds(base_run(a.home, t.home), a, t)
	if kind == Skill.Kind.PROJECTILE:
		return Battle.travel_seconds(base_fly(a.home, t.home), a, t)
	return 0.0
