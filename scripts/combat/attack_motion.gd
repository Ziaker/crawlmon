class_name AttackMotion
extends RefCounted
## Where an attacker is while its attack carries it: the run at the target, the swing and
## the hop back. Pure kinematics on Battle's clock (Incoming.phase / phase_time), so the
## position the rules use and the position the model is drawn at are the same number.
## Heights (hops, jumps) and squash are only drawing and stay in the FX.

const Phase = Incoming.Phase
const RUN_START := 0.12  ## Seconds of TRAVEL spent turning toward the target before the run.
const LUNGE_MAX := 0.18
const COIL := 0.38
const LUNGE_OVERSHOOT := 0.22
const PUSH_TIME := 0.11
const CATCHUP_SPEED := 45.0  ## D-286: top speed of the slide to a target that moved during the strike.
const CATCHUP_MIN := 1.0  ## D-286: it only slides when the contact spot moved farther than this (the strike's own lunge is smaller).
const HIT_STUN_EXTRA := 0.30  ## D-272: every hit recoil/stagger lasts this much longer, globally.
const HIT_HOLD := 0.15 + HIT_STUN_EXTRA


## True while this attack moves its attacker's body.
static func carries(inc: Incoming) -> bool:
	if not inc.resolved or inc.plan_i < 0 or inc.plan_i >= inc.plan.size():
		return false  # Not started, or its last phase already ended this frame.
	if inc.motion != "melee" and inc.motion != "engaged" and inc.motion != "return" and not inc.blink:
		return false
	return inc.phase == Phase.TRAVEL or inc.phase == Phase.STRIKE or inc.phase == Phase.RETURN


## A new phase began: remember where the body is when the return starts.
static func on_phase(inc: Incoming) -> void:
	if inc.phase == Phase.RETURN and inc.motion != "return":
		inc.lunged = inc.attacker.pos


## Moves inc.attacker.pos to where this attack puts it at inc.phase_time.
static func update(inc: Incoming, delta := 0.0) -> void:
	if not carries(inc):
		return
	var a := inc.attacker
	var e := inc.phase_time
	if inc.blink:
		a.pos = _blink_pos(inc)
		return
	match inc.phase:
		Phase.TRAVEL:
			if inc.clash:
				var kc := clampf((e - inc.clash_start) / BattleSpace.CLASH_HOP_T, 0.0, 1.0)
				a.pos = inc.clash_from.lerp(inc.clash_land, BattleSpace.ease_quad_out(kc))
				return
			_track(inc)
			if e <= RUN_START:
				a.pos = inc.from
			else:
				var k := clampf((e - RUN_START) / maxf(inc.run_t, 0.01), 0.0, 1.0)
				a.pos = inc.from.lerp(inc.stand, 0.5 - 0.5 * cos(k * PI))  # Sine in/out
		Phase.STRIKE:
			# D-054/D-280: the path is fixed during the strike, except for a capped slide when the target moved away (D-286);
			# the exact contact is corrected at the impact (arrive()).
			# The lunge is timed to END at the contact frame (antic + hit), when the damage lands.
			var lunge_t := maxf(minf(inc.hit, LUNGE_MAX), 0.001)
			var lunge_start := inc.antic + maxf(inc.hit - lunge_t, 0.0)
			if inc.clash_mode == "" and delta > 0.0:
				_catch_up(inc, delta)
			var st := inc.stand
			if inc.clash_mode == "strike":
				# D-279: after the bump it drifts slowly to the 2.6-unit contact spot while the move's animation plays.
				st = inc.clash_land.lerp(inc.stand, BattleSpace.ease_quad_out(clampf(e / maxf(lunge_start, 0.05), 0.0, 1.0)))
			var coil := st if inc.antic <= 0.0 else st - inc.dir * COIL
			if e < inc.antic:
				a.pos = st.lerp(coil, BattleSpace.ease_quad_out(e / inc.antic))
			elif e < lunge_start:
				a.pos = coil
			else:
				a.pos = coil.lerp(inc.stand + inc.dir * LUNGE_OVERSHOOT, BattleSpace.ease_expo_out(clampf((e - lunge_start) / lunge_t, 0.0, 1.0)))
		Phase.RETURN:
			var start := inc.lunged + inc.push
			if e < inc.hold:
				a.pos = inc.lunged.lerp(start, BattleSpace.ease_quad_out(clampf(e / PUSH_TIME, 0.0, 1.0))) if inc.push != Vector3.ZERO else inc.lunged
			else:
				var k := clampf((e - inc.hold) / maxf(inc.hop_t, 0.001), 0.0, 1.0)
				a.pos = start.lerp(a.stand_pos(), k)


## D-286: the target moved during the strike: the anchor slides to the new contact spot at a capped speed (never a jump).
static func _catch_up(inc: Incoming, delta: float) -> void:
	if inc.motion != "melee" or inc.dodged or inc.auto_dodged or inc.interrupted or inc.ghost or inc.impacted:
		return
	var goal := inc.target.pos - inc.dir * BattleSpace.STAND_GAP
	var gap := inc.stand.distance_to(goal)
	if not inc.catching and gap <= CATCHUP_MIN:
		return
	inc.catching = gap > 0.05
	inc.stand = inc.stand.move_toward(goal, CATCHUP_SPEED * delta)


## The hit lands this very frame: put the striker (or the projectile) exactly at the contact
## point, so the damage never happens a frame short of it.
static func arrive(inc: Incoming) -> void:
	if inc.interrupted or inc.ghost:
		return
	if inc.motion == "cast":
		if not (inc.dodged or inc.auto_dodged):
			inc.aim = inc.target.pos
		inc.proj_pos = inc.aim
	elif (inc.motion == "melee" or inc.motion == "engaged") and inc.phase == Phase.STRIKE and not inc.blink:
		if inc.clash_mode != "":
			return  # D-279: after a clash the contact spot is the one agreed in the bump; nothing snaps at the impact.
		_track(inc)
		inc.attacker.pos = inc.stand + inc.dir * LUNGE_OVERSHOOT


## Teleporte Rapido: the caster is at its spot until the pinch, at `dest` through the strike,
## and back at its spot once the return passes its own pinch.
static func _blink_pos(inc: Incoming) -> Vector3:
	var p := inc.progress()
	match inc.phase:
		Phase.TRAVEL:
			return inc.from
		Phase.STRIKE:
			return inc.dest
		_:
			return inc.dest if p < 0.35 else inc.from


## While it runs (TRAVEL) at a target that will really be hit, the stand spot follows the
## target's live position (D-044). In the strike it is called only by arrive(): the contact
## is corrected at the impact instant, never continuously (D-054).
static func _track(inc: Incoming) -> void:
	if inc.motion != "melee" or inc.dodged or inc.auto_dodged or inc.interrupted or inc.ghost or inc.impacted:
		return
	var tpos := inc.target.pos
	if inc.phase == Phase.TRAVEL:
		inc.dir = BattleSpace.flat_dir(inc.from, tpos)
	inc.stand = tpos - inc.dir * BattleSpace.STAND_GAP


## The attacker was hit on its way (or while it hopped back): it is knocked back by `push`
## and hops home from there.
static func begin_hit_return(inc: Incoming, push: Vector3) -> void:
	var a := inc.attacker
	inc.motion = "return"
	inc.lunged = a.pos
	inc.push = push
	var dist := (inc.lunged + push).distance_to(a.stand_pos())
	inc.hold = HIT_HOLD
	inc.hop_t = clampf(dist / 52.0, 0.26, 0.44)
	inc.hop_h = clampf(dist * 0.10, 0.9, 2.2)
	inc.plan = [[Phase.RETURN, inc.hold + inc.hop_t]]
	inc.plan_i = 0
	inc.phase = Phase.RETURN
	inc.phase_time = 0.0


## The hop back to its step spot of a body standing at `from` (an evader that leaves its
## opponent, or an attacker that was stunned). Short hops are a blink.
static func begin_plain_return(inc: Incoming, from: Vector3) -> void:
	var a := inc.attacker
	var home := a.stand_pos()
	var dist := from.distance_to(home)
	inc.motion = "return"
	inc.lunged = from
	inc.push = Vector3.ZERO
	inc.hold = 0.0
	if dist < 0.35:
		inc.hop_t = 0.05
		inc.hop_h = 0.0
	else:
		inc.hop_t = clampf(dist / 70.0, 0.22, 0.4)
		inc.hop_h = clampf(dist * 0.12, 1.2, 3.0)
	inc.plan = [[Phase.RETURN, inc.hop_t]]


## A projectile (or any cast that travels) leaves the attacker's spot. It sails past when the
## attack was already decided to miss; otherwise it is guided to the target's live position.
static func start_projectile(inc: Incoming) -> void:
	var to := inc.target.rest_pos()
	inc.aim = to + BattleSpace.flat_dir(inc.from, to) * 7.0 if (inc.dodged or inc.auto_dodged) else to
	inc.proj_pos = inc.from
	if inc.move_id == "teleporte_rapido":
		var attack_dir := BattleSpace.flat_dir(inc.from, inc.aim)
		inc.blink = true
		inc.dest = inc.aim + attack_dir * 1.35


## Each frame: the guided projectile follows the target until the attack is evaded (then it
## keeps its last aim point, so its path stays continuous) and sits at its share of the flight.
static func update_projectile(inc: Incoming) -> void:
	if inc.motion != "cast" or not inc.resolved or inc.ghost:
		return
	if not (inc.dodged or inc.auto_dodged or inc.interrupted) and inc.phase != Phase.RETURN:
		inc.aim = inc.target.pos
	var k := 1.0
	if inc.phase == Phase.TRAVEL:
		k = inc.progress()
	else:
		for i in inc.plan.size():
			if inc.plan[i][0] == Phase.TRAVEL:
				k = 0.0 if i > inc.plan_i else 1.0  # Not left yet, or already arrived.
	inc.proj_pos = inc.from.lerp(inc.aim, k)
