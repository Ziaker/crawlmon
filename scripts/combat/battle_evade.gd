class_name BattleEvade
extends RefCounted
## Evade (D-006 / D-027), plus the old interruption and engaged-state helpers (no longer
## triggered by an Evade). A helper of Battle: it reads and writes Battle's lists and emits its signals.

const Phase = Incoming.Phase

var b: Battle


func _init(p_battle: Battle) -> void:
	b = p_battle


## Evade cost (D-006 / D-027): 2 ATB while its own melee attack is running at a target,
## 3 ATB otherwise (standing still, or preparing/casting).
func cost(actor: Combatant) -> float:
	return Battle.EVADE_ON_RUN if own_run(actor) != null else Battle.EVADE_STILL


## Its own melee attack while it is still running (the trajectory), or null.
func own_run(actor: Combatant) -> Incoming:
	for inc in b._landing:
		if inc.attacker == actor and inc.motion == "melee" and inc.phase == Phase.TRAVEL and not inc.interrupted:
			return inc
	return null


## Standing still, preparing or casting, or running in its own melee attack. Not while
## its body is swinging or hopping back.
func _can_act(actor: Combatant) -> bool:
	if actor.is_guarding():
		return false  # D-272: a guarding character does nothing else.
	if actor.engaged_with != null:
		return false
	if own_run(actor) != null:
		return true
	if b.is_held(actor):
		return true  # D-282: held in its idle by an attack that is striking it, it may Evade
	for inc in b._landing:
		if inc.attacker == actor and AttackMotion.carries(inc):
			return false
	for inc in b._returning:
		if inc.attacker == actor and AttackMotion.carries(inc):
			return false
	return true


func find_evadable(actor: Combatant) -> Incoming:
	if not actor.is_alive() or actor.blocks() < cost(actor) or not _can_act(actor):
		return null
	# Only during the action (the run or the flight), never during the call (D-028).
	var fallback: Incoming = null
	for inc in b.active_attacks():
		if inc.target != actor or inc.dodged or inc.evade_tried or inc.interrupted or inc.is_friendly:
			continue
		if not inc.can_dodge_now():  # D-1006: from the wind-up to the contact
			continue
		# D-1168: if more than one attack is dodgeable, the one whose Dread is lit wins.
		# Without this, a wind-up earlier in the list could eat the press and cause a false WHIFF.
		if inc.can_evade_now():
			return inc
		if fallback == null:
			fallback = inc
	return fallback


## D-164: a PERFECT Evade (last PERFECT_WINDOW seconds of the Evade window) makes the next attack
## have no wind-up, wherever it was made. D-027: it only teleports when made while its own melee
## attack runs: then it appears in front of the attacker and its own attack carries on.
func try_evade(actor: Combatant, inc: Incoming) -> bool:
	if inc == null or inc.is_friendly or not actor.is_alive() or not _can_act(actor):
		return false
	var price := cost(actor)
	if actor.blocks() < price:
		return false
	if not inc.can_dodge_now():
		return false  # D-1006: the button works from the wind-up to the contact
	if not inc.can_evade_now():
		# D-1014: mistimed. The Evade is spent and the attack still lands: it did NOT dodge.
		# Return false: callers/tests must not treat this as a successful Evade (D-282/D-283).
		actor.spend(price)
		inc.evade_tried = true
		b.log_message.emit("%s tenta desviar de %s fora de hora e erra o timing!" % [actor.name, inc.attacker.name])
		b.evade_mistimed.emit(actor, inc)
		return false
	var run := own_run(actor)
	var is_perfect := inc.attacker.is_alive()  # D-283/D-987: an Evade inside the window is always perfect
	actor.spend(price)
	inc.evade_tried = true
	inc.dodged = true
	var burst_before := actor.burst
	actor.burst = mini(actor.burst + 1, Combatant.BURST_MAX)
	if actor.burst > burst_before:
		b.grant_burst(actor, actor)
	if is_perfect:
		inc.perfect = true
		actor.counter_ready = true
	if run != null and is_perfect:
		inc.evader_teleported = true
		var from := actor.pos
		_teleport_into_run(run, inc.attacker)
		b.log_message.emit("%s desvia perfeitamente e surge diante de %s! BURST!" % [actor.name, inc.attacker.name])
		b.evade_teleported.emit(actor, inc.attacker, from)
	elif run != null:
		# Not perfect during its own run: the run is cancelled (its ATB is lost) and it is
		# back at its spot at once (D-029).
		var from := actor.pos
		_cancel_run_home(run)
		inc.evader_home = true
		b.log_message.emit("%s desvia de %s e volta ao seu lugar! BURST!" % [actor.name, inc.attacker.name])
		b.evade_returned.emit(actor, from)
	elif is_perfect:
		b.log_message.emit("%s desvia perfeitamente de %s! BURST!" % [actor.name, inc.attacker.name])
	else:
		b.log_message.emit("%s desvia do ataque de %s! BURST!" % [actor.name, inc.attacker.name])
	b.manual_evaded.emit(actor, inc)
	return true


## Cancels the runner's own attack and puts it back at its step spot this very frame.
func _cancel_run_home(run: Incoming) -> void:
	var a := run.attacker
	b._landing.erase(run)
	run.interrupted = true  # D-1160: the Evade is a miss, not an interruption (D-104/D-106).
	run.impacted = true
	a.has_rest = false
	a.pos = a.stand_pos()
	run.plan_i = run.plan.size()
	run.phase = Phase.DONE
	b.attack_cancelled.emit(run)
	b.attack_phase.emit(run, Phase.DONE)


## Puts the runner in front of `opponent` and lets its own run carry on from there: the run's
## start point is moved so the body is at the new spot at the current moment of the run.
func _teleport_into_run(run: Incoming, opponent: Combatant) -> void:
	var a := run.attacker
	var spot := opponent.pos + BattleSpace.flat_dir(opponent.pos, a.pos) * BattleSpace.STAND_GAP
	spot.y = 0.0
	var e := run.phase_time
	if e <= AttackMotion.RUN_START:
		run.from = spot
	else:
		var k := clampf((e - AttackMotion.RUN_START) / maxf(run.run_t, 0.01), 0.0, 1.0)
		var w := 0.5 - 0.5 * cos(k * PI)
		run.from = spot if w >= 0.98 else (spot - run.stand * w) / (1.0 - w)
	a.pos = spot


## The attack stops where it is and never hits.
func _interrupt(inc: Incoming) -> void:
	b._landing.erase(inc)
	inc.attacker.set_rest(inc.attacker.pos)  # It stops right where it is.
	inc.interrupted = true  # D-1160: legacy mechanical stop, not interruption feedback.
	inc.plan = [[Phase.STAGGER, 9999.0]]
	inc.plan_i = 0
	inc.phase = Phase.STAGGER
	inc.phase_time = 0.0
	if not b._returning.has(inc):
		b._returning.append(inc)
	b.attack_phase.emit(inc, Phase.STAGGER)


func _engage(actor: Combatant, opponent: Combatant, inc: Incoming) -> void:
	actor.engaged_with = opponent
	actor.engage_left = Battle.ENGAGE_SECONDS
	b.engaged.emit(actor, opponent, inc)


func step_engage(delta: float) -> void:
	for c in b.party + b.enemies:
		if c.engaged_with == null:
			continue
		if not c.is_alive() or not c.engaged_with.is_alive():
			_end_engage(c)
			continue
		if b.is_winding_up(c):
			continue
		c.engage_left -= delta / maxf(Engine.time_scale, 0.01)  # Real seconds, like the slow-motion.
		if c.engage_left <= 0.0:
			_end_engage(c)


## The evader goes back home with the quick leap, and the interrupted attacker recovers.
func _end_engage(actor: Combatant) -> void:
	var opponent := actor.engaged_with
	actor.engaged_with = null
	actor.counter_ready = false  # The free counter ends with the engagement; it never lingers.
	actor.counter_ready = false  # The free instant action was only for the engaged state.
	var staggered: Incoming = null
	for inc in b._returning:
		if inc.attacker == opponent and inc.phase == Phase.STAGGER:
			staggered = inc
	var ghost := Incoming.new()
	ghost.attacker = actor
	ghost.target = opponent
	ghost.ghost = true
	ghost.resolved = true
	ghost.impacted = true
	# The rules plan both hops home; the drawing only fills in how they look.
	AttackMotion.begin_plain_return(ghost, actor.pos)
	if staggered != null:
		AttackMotion.begin_plain_return(staggered, staggered.attacker.pos)
	b.engage_ended.emit(actor, opponent, ghost, staggered)
	for inc in [ghost, staggered]:
		if inc == null or inc.plan.is_empty() or (inc == staggered and inc.phase != Phase.STAGGER):
			continue
		inc.plan_i = 0
		inc.phase = inc.plan[0][0]
		inc.phase_time = 0.0
		if inc == ghost:
			b._returning.append(inc)
		b.attack_phase.emit(inc, inc.phase)
