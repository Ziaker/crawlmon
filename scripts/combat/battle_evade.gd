class_name BattleEvade
extends RefCounted
## Evade, interruption and the engaged state that follows a successful Evade against a
## melee attack. A helper of Battle: it reads and writes Battle's lists and emits its signals.

const Phase = Incoming.Phase

var b: Battle


func _init(p_battle: Battle) -> void:
	b = p_battle


func find_evadable(actor: Combatant) -> Incoming:
	if not actor.is_alive() or actor.blocks() < Battle.EVADE_BLOCKS:
		return null
	# No Evade in the middle of its own attack (it would pull the body out of the run)
	# or while engaged next to an opponent.
	if actor.engaged_with != null or b.is_attacking(actor):
		return null
	var winding: Incoming = null
	for inc in b.active_attacks():
		if inc.target != actor or inc.dodged or inc.evade_tried or inc.interrupted or inc.is_friendly:
			continue
		if inc.can_evade_now():
			return inc
		if not inc.resolved and winding == null:
			winding = inc
	return winding


func try_evade(actor: Combatant, inc: Incoming) -> bool:
	if inc == null or inc.is_friendly or actor.blocks() < Battle.EVADE_BLOCKS or actor.engaged_with != null or b.is_attacking(actor):
		return false
	actor.spend(Battle.EVADE_BLOCKS)
	inc.evade_tried = true
	# Pressing before the attack is on its way (during the wind-up) is the early whiff.
	if not inc.can_evade_now():
		inc.whiffed = true
		b.log_message.emit("%s esquivou cedo demais! Vulnerável a crítico!" % actor.name)
		b.evade_whiffed.emit(actor, inc)
		return true
	inc.dodged = true
	var burst_before := actor.burst
	actor.burst = mini(actor.burst + 1, Combatant.BURST_MAX)
	if actor.burst > burst_before:
		b.grant_burst(actor, actor)
	if inc.kind == Skill.Kind.MELEE:
		# The attacker is running at it: the evader interrupts it and arrives next to it.
		actor.counter_ready = true
		b.log_message.emit("%s desvia de %s no caminho e o interrompe! BURST!" % [actor.name, inc.attacker.name])
		_interrupt(inc)
		_engage(actor, inc.attacker, inc)
	else:
		# A projectile or a cast: nobody is running, so there is no one to advance on.
		b.log_message.emit("%s desvia do ataque de %s! BURST!" % [actor.name, inc.attacker.name])
	b.manual_evaded.emit(actor, inc)
	return true


## The attack stops where it is and never hits.
func _interrupt(inc: Incoming) -> void:
	b._landing.erase(inc)
	inc.attacker.set_rest(inc.attacker.pos)  # It stops right where it is.
	inc.interrupted = true
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
