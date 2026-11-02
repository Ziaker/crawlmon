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
const HIT_HOLD := 0.15


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
static func update(inc: Incoming) -> void:
	if not carries(inc):
		return
	var a := inc.attacker
	var e := inc.phase_time
	if inc.blink:
		a.pos = _blink_pos(inc)
		return
	match inc.phase:
		Phase.TRAVEL:
			_track(inc)
			if e <= RUN_START:
				a.pos = inc.from
			else:
				var k := clampf((e - RUN_START) / maxf(inc.run_t, 0.01), 0.0, 1.0)
				a.pos = inc.from.lerp(inc.stand, 0.5 - 0.5 * cos(k * PI))  # Sine in/out
		Phase.STRIKE:
			_track(inc)
			var coil := inc.stand if inc.antic <= 0.0 else inc.stand - inc.dir * COIL
			# The lunge is timed to END at the contact frame (antic + hit), when the damage lands.
			var lunge_t := maxf(minf(inc.hit, LUNGE_MAX), 0.001)
			var lunge_start := inc.antic + maxf(inc.hit - lunge_t, 0.0)
			if e < inc.antic:
				a.pos = inc.stand.lerp(coil, BattleSpace.ease_quad_out(e / inc.antic))
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
		_track(inc)
		inc.attacker.pos = inc.stand + inc.dir * LUNGE_OVERSHOOT


## Teleporte Rapido: the caster is at its spot until the pinch, at `dest` through the strike,
## and back at its spot once the return passes its own pinch.
static func _blink_pos(inc: Incoming) -> Vector3:
	var p := inc.progress()
	match inc.phase:
		Phase.TRAVEL:
			return inc.from if p < BattleSpace.TELEPORT_PINCH else inc.dest
		Phase.STRIKE:
			return inc.dest
		_:
			return inc.dest if p < 1.0 - BattleSpace.TELEPORT_PINCH else inc.from


## While it still runs or swings at a target that will really be hit, the stand spot follows
## the target's live position (so a target that moves is still reached, never struck air).
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
		var right := Vector3(attack_dir.z, 0.0, -attack_dir.x)
		inc.blink = true
		inc.dest = inc.from + right * 2.2 + attack_dir * 0.55


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
