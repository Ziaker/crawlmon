class_name FxAttackPlan
extends RefCounted
## Builds the timeline of a resolved attack (travel, strike, return durations) from the
## scene geometry and the models' clips. Battle owns PREPARO -> TRAVEL -> STRIKE -> RETURN
## (`Incoming.phase`, `phase_time`); nothing here decides when a hit, an arrival or a
## return happens once the plan is written.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## Fills the timeline of a resolved attack (seconds of logic time) and the drawing data.
## Returns the total duration.
func begin_attack(inc) -> float:
	var a: Combatant = inc.attacker
	var t: Combatant = inc.target
	var a_home: Vector3 = fx.rest_pos(a)  # Engaged characters stand away from home.
	var t_home: Vector3 = fx.rest_pos(t)
	var dir: Vector3 = fx._flat_dir(a_home, t_home)
	var P := Battle.Phase
	# Travel times start from the step-0 geometry and then lose 0.10 s per step.
	var a0: Vector3 = fx._origin[a]
	var t0: Vector3 = fx._origin[t]
	var m: Node3D = fx._models[a]
	var d := {"dir": dir, "base_scale": fx._base_scale.get(a, m.scale), "move_id": BattleFx.normalize_move_id(inc.label)}
	if d["move_id"] == "furia_dragao":
		var rage_hit := 0.15 if inc.instant else fx.fx_motion._clip_hit(a, "attack_special", fx.CAST_AT)
		d.merge({"kind": "cast", "fly": Battle.travel_seconds(0.30, a, t)})
		inc.plan = [[P.STRIKE, rage_hit], [P.TRAVEL, d["fly"]], [P.RETURN, 0.16]]
		inc.impact_phase = P.TRAVEL
	elif inc.kind == Skill.Kind.MELEE and a.engaged_with == t:
		# Already standing next to it: no travel, no return.
		var hit0 := fx.fx_motion._clip_hit(a, "attack", fx.HIT_AT)
		# Its first action after the Evade: it appears next to the attacker it interrupted.
		# Later actions are already there.
		if not fx._rest.has(a):
			fx.fx_dodge.arrive_to_attack(a, t)
		var opp_pos: Vector3 = (fx._models[t] as Node3D).position
		var arrive_stand: Vector3 = fx.rest_pos(a)
		a_home = arrive_stand
		dir = fx._flat_dir(a_home, opp_pos)
		d["dir"] = dir
		d.merge({"kind": "melee", "engaged": true, "stand": a_home, "run_t": 0.0, "hit": hit0, "hold": 0.0,
			"antic": 0.0, "hop_t": 0.3, "hop_h": 1.2, "yaw_out": atan2(dir.x, dir.z), "from": a_home})
		inc.plan = [[P.STRIKE, hit0]]
		inc.impact_phase = P.STRIKE
	elif inc.kind == Skill.Kind.MELEE:
		var stand := t_home - dir * fx.STAND_GAP
		stand.y = 0.0
		var stand0 := t0 - fx._flat_dir(a0, t0) * fx.STAND_GAP
		var run_t := Battle.travel_seconds(_base_run(a0, t0), a, t)
		match String(d["move_id"]):
			"soco_rapido": run_t = Battle.travel_seconds(0.18, a, t)
			"golpe_carate": run_t = Battle.travel_seconds(0.22, a, t)
			"quebra_telha": run_t = Battle.travel_seconds(0.24, a, t)
			"garra_dragao": run_t = Battle.travel_seconds(0.22, a, t)
			"investida_subterranea", "investida_escavadora": run_t = Battle.travel_seconds(0.26, a, t)
		var hop_dist := stand.distance_to(a_home)
		var antic := 0.0 if inc.instant else fx.ANTICIP_T
		var hit := fx.fx_motion._clip_hit(a, "attack", fx.HIT_AT)
		var from_grounded := Vector3(m.position.x, 0.0, m.position.z)
		d.merge({"kind": "melee", "stand": stand, "run_t": run_t, "hit": hit, "hold": 0.2,
			"antic": antic, "hop_t": clampf(hop_dist / 70.0, 0.22, 0.4),
			"hop_h": clampf(hop_dist * 0.12, 1.2, 3.0), "yaw_out": atan2(dir.x, dir.z), "from": from_grounded})
		inc.plan = [[P.TRAVEL, 0.12 + run_t], [P.STRIKE, antic + hit], [P.RETURN, 0.2 + d["hop_t"]]]
		inc.impact_phase = P.STRIKE
	else:
		var hit := 0.15 if inc.instant else fx.fx_motion._clip_hit(a, "attack_special", fx.CAST_AT)
		var total := fx.CAST_AT + 0.42
		d["kind"] = "cast"
		if d["move_id"] == "provocacao":
			d["fly"] = 0.28
			inc.plan = [[P.STRIKE, hit], [P.TRAVEL, 0.28], [P.RETURN, 0.17]]
			inc.impact_phase = P.TRAVEL
		elif d["move_id"] == "onda_choque":
			d["fly"] = 0.24
			inc.plan = [[P.TRAVEL, 0.24], [P.STRIKE, hit], [P.RETURN, 0.20]]
			inc.impact_phase = P.TRAVEL
		elif d["move_id"] == "teleporte_rapido":
			d["fly"] = 0.22
			inc.plan = [[P.TRAVEL, 0.22], [P.STRIKE, hit], [P.RETURN, 0.30]]
			inc.impact_phase = P.STRIKE
		elif inc.kind == Skill.Kind.PROJECTILE:
			# Whoever stands exactly on the projectile's line is hit before the aimed target.
			var block := _interceptor(inc, a_home, t_home)
			if not block.is_empty():
				fx.battle.redirect(inc, block["c"])
				t = block["c"]
				t_home = fx.rest_pos(t)
				t0 = fx._origin[t]  # The flight now ends at the interceptor.
			var fly := Battle.travel_seconds(_base_fly(a0, t0), a, t)
			d["fly"] = fly
			inc.plan = [[P.STRIKE, hit], [P.TRAVEL, fly], [P.RETURN, maxf(total - hit - fly, 0.05)]]
			inc.impact_phase = P.TRAVEL
		else:
			inc.plan = [[P.STRIKE, hit], [P.RETURN, maxf(total - hit, 0.05)]]
			inc.impact_phase = P.STRIKE
	inc.data = d
	var sum := 0.0
	for seg in inc.plan:
		sum += seg[1]
	return sum


## The opponent of the attacker standing on the flat line a_pos -> t_pos, nearest first.
func _interceptor(inc, a_pos: Vector3, t_pos: Vector3) -> Dictionary:
	if fx.battle == null:
		return {}
	var a: Combatant = inc.attacker
	var foes: Array[Combatant] = fx.battle.enemies if a.is_player else fx.battle.party
	var line := Vector2(t_pos.x - a_pos.x, t_pos.z - a_pos.z)
	var len2 := line.length_squared()
	if len2 < 0.01:
		return {}
	var best := {}
	for c in foes:
		if c == inc.target or not c.is_alive():
			continue
		var p: Vector3 = fx.rest_pos(c)
		var rel := Vector2(p.x - a_pos.x, p.z - a_pos.z)
		var k := rel.dot(line) / len2
		if k <= 0.05 or k >= 1.0:
			continue
		var off := (rel - line * k).length()
		var m: Node3D = fx._models[c]
		if off < 1.2 * maxf(m.scale.x, 1.0) and (best.is_empty() or k < best["k"]):
			best = {"c": c, "k": k}
	return best


func _base_run(a0: Vector3, t0: Vector3) -> float:
	var stand0 := t0 - fx._flat_dir(a0, t0) * fx.STAND_GAP
	return clampf(a0.distance_to(stand0) / fx.RUN_SPEED, 0.6, 1.1)


func _base_fly(a0: Vector3, t0: Vector3) -> float:
	return clampf(a0.distance_to(t0) / 50.0, fx.FLY_TIME, 0.7)


## Seconds a move of `kind` would take to reach `t` from `a` (for the Fight menu); 0 = none.
func preview_travel(a: Combatant, t: Combatant, kind: int) -> float:
	var a0: Vector3 = fx._origin[a]
	var t0: Vector3 = fx._origin[t]
	if kind == Skill.Kind.MELEE:
		return 0.12 + Battle.travel_seconds(_base_run(a0, t0), a, t)
	if kind == Skill.Kind.PROJECTILE:
		return Battle.travel_seconds(_base_fly(a0, t0), a, t)
	return 0.0
