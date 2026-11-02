class_name Battle
extends Node
## ATB battle rules. Every combatant has a 5-block gauge that fills over time.
## Skills cost 2 blocks, items 1. Every attack, from either side, takes a moment
## to land; Evade (3 blocks) dodges one and grants a burst (free extra action).
## Every hit also has an automatic evade chance based on the target's speed
## (grants +1 ATB block). party[0] is the player-controlled leader; every other
## combatant, allies and enemies alike, follows its Tactics (act/react policy).

signal log_message(text: String)
signal battle_ended(player_won: bool)
signal state_changed
## Visual events (consumed by BattleFx). `inc` is an Incoming.
signal attack_telegraphed(inc)
signal attack_resolved(inc)
signal attack_cancelled(inc)
## One attack = one timeline owned by this node: PREPARO (WINDUP) -> TRAJETO (TRAVEL) ->
## GOLPE (STRIKE) -> RETORNO (RETURN). BattleFx only draws the progress it reads here.
signal attack_phase(inc, phase: int)  ## `inc` entered `phase` (Battle.Phase).
## A timed visual moment on the same clock (e.g. the evade starting just before the hit).
signal cue(kind: String, actor: Combatant, inc)
signal manual_evaded(actor: Combatant, inc)
signal stepped(actor: Combatant, to_pos: int)  ## `actor` started a position step.
## `actor` dodged `opponent`'s attack on its way in: the attack is interrupted and `actor`
## is now next to it. BattleFx draws the arrival.
signal engaged(actor: Combatant, opponent: Combatant, inc)
## The engaged state is over: `actor` (ghost) and the staggered attack (`staggered`, may be
## null) return home. BattleFx fills their `plan`.
signal engage_ended(actor: Combatant, opponent: Combatant, ghost, staggered)
signal evade_whiffed(actor: Combatant, inc)
signal hit_resolved(attacker: Combatant, target: Combatant, element: Element.Type, info: Dictionary)
signal healed(actor: Combatant, target: Combatant, amount: int)

class Incoming:
	var attacker: Combatant
	var target: Combatant
	var power := 1.0
	var element := Element.Type.FISICO
	var label := ""
	var time_left := 0.0
	var total_windup := 1.5
	var dodged := false
	var perfect_evaded := false
	var instant := false  ## A counter-attack after a Perfect Evade: no wind-up at all.
	var evade_tried := false
	var whiffed := false
	var auto_dodged := false  ## Decided when the wind-up ends so the visuals can play it out.
	var resolved := false  ## The wind-up is over: the attacker is on its way to hit.
	## Timeline after the wind-up, filled by BattleFx on attack_resolved:
	## [[Phase, seconds], ...] in order, and which phase ends with the hit.
	var plan: Array = []
	var impact_phase := 1  ## Phase.STRIKE
	var plan_i := -1
	var phase := 0  ## Phase.WINDUP
	var phase_time := 0.0  ## Seconds spent in the current phase.
	var impacted := false
	var interrupted := false  ## Stopped on its way by a manual Evade: it never hits.
	var void_miss := false  ## Left before the target went away (engaged): it strikes the empty spot.
	var ghost := false  ## Not an attack: only the return of an engaged character.
	var ai_evade_at := -1.0  ## Seconds into TRAVEL when an AI target will try to evade (-1: never).
	var data := {}  ## Drawing data owned by BattleFx (positions, clip times); logic never reads it.

	func phase_len() -> float:
		return plan[plan_i][1] if plan_i >= 0 and plan_i < plan.size() else 0.0

	## 0..1 inside the current phase.
	func progress() -> float:
		var l := phase_len()
		return clampf(phase_time / l, 0.0, 1.0) if l > 0.0 else 1.0

	## The manual Evade works only while the attack is on its way (the run or the projectile).
	func can_evade_now() -> bool:
		return resolved and not impacted and not interrupted and not ghost and phase == 1  ## Phase.TRAVEL

	## Seconds of travel left (the Evade window); large when it is not travelling.
	func travel_left() -> float:
		return phase_len() - phase_time if can_evade_now() else 99.0

	## Seconds until the hit reaches the target. Evading only counts near this moment.
	func eta() -> float:
		if not resolved:
			return time_left + 5.0
		if impacted:
			return 0.0
		var left := -phase_time
		var i := plan_i
		while i < plan.size():
			left += plan[i][1]
			if plan[i][0] == impact_phase:
				break
			i += 1
		return maxf(left, 0.0)

enum Phase { WINDUP, TRAVEL, STRIKE, RETURN, DONE, STAGGER }

const SKILL_BLOCKS := 2.0
const ITEM_BLOCKS := 1.0
const EVADE_BLOCKS := 2.0  ## Manual Evade (was 3 in the GDD; see report).
const WINDUP := 1.5  ## Every attack takes this long to land; the attacker's ATB is locked meanwhile.
const STEP_MAX := 2  ## Positions go from -STEP_MAX (behind) to +STEP_MAX (in front).
const STEP_COST := 1.0  ## ATB blocks per step; nothing else.
const STEP_TIME := 0.35  ## Seconds a step takes to walk.
const TRAVEL_PER_STEP := 0.10  ## Seconds off an attack's travel per step of attacker + target.
const TRAVEL_MIN := 0.25
const DMG_PER_STEP := 0.10  ## +10% dealt per step in front, -10% taken per step behind.
const ENGAGE_SECONDS := 2.0  ## Real seconds the evader stays next to the opponent (the Burst slow-motion).
const WEAKNESS_MULT := 1.5
const CRIT_CHANCE := 0.1
const CRIT_MULT := 2.0
const START_ATB := 3.0  ## Every combatant starts a battle with this many blocks.
const AI_HEAL_BELOW := 0.5  ## AI combatants drink a potion at or below this HP fraction.

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var incoming: Array[Incoming] = []
var running := false
var _landing: Array[Incoming] = []  ## Resolved attacks whose strike has not landed yet.
var _returning: Array[Incoming] = []  ## Struck already: only the return is left to play.
var _cues: Array[Dictionary] = []  ## {t, kind, actor, inc}
var _hop_back := 0.3  ## Placeholder; BattleFx decides how long a return takes.


func start(p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	party = p_party
	enemies = p_enemies
	for c in party + enemies:
		c.atb = START_ATB
		c.burst = 0
		c.engaged_with = null
		c.pos_step = 0
		c.step_from = 0.0
		c.step_t = 1.0
	_landing.clear()
	_returning.clear()
	_cues.clear()
	running = true
	log_message.emit("Batalha iniciada!")


func _process(delta: float) -> void:
	if not running:
		if not _returning.is_empty():
			_step_attacks(delta)  # The winners' leaps back still play out after the last hit.
		return
	for c in party + enemies:
		if not is_winding_up(c):  # ATB stays locked until the action finishes.
			c.tick(delta)
	for c in party + enemies:
		if c.step_t < 1.0:
			c.step_t = minf(c.step_t + delta / STEP_TIME, 1.0)
	_run_ai()
	_resolve_incoming(delta)
	_step_attacks(delta)
	_step_engage(delta)
	_step_cues(delta)
	state_changed.emit()


# --- Actions (same for the player, allies and enemies) -----------------------

func use_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not actor.is_alive() or not target.is_alive() or is_winding_up(actor) or not actor.can_pay(skill.cost):
		return false
	if actor.engaged_with != null and target != actor.engaged_with:
		return false  # Engaged: it only acts on the opponent it is standing next to.
	actor.pay(skill.cost)
	var inc := Incoming.new()
	inc.attacker = actor
	inc.target = target
	inc.power = skill.power
	inc.element = skill.element
	inc.label = skill.display_name
	# After a Perfect Evade the next attack is immediate: no wind-up, no preparation.
	# Instant (no wind-up, no travel) only while engaged next to the opponent it interrupted;
	# back at its original spot an attack is prepared and travels like any other.
	inc.instant = actor.engaged_with != null
	actor.counter_ready = false
	if actor.engaged_with != null:
		actor.engage_left = ENGAGE_SECONDS  # Acting keeps it engaged.
	inc.total_windup = 0.0 if inc.instant else WINDUP
	inc.time_left = 0.0 if inc.instant else WINDUP
	incoming.append(inc)
	log_message.emit("%s prepara %s em %s..." % [actor.name, skill.display_name, target.name])
	attack_telegraphed.emit(inc)
	return true


func use_item(actor: Combatant, item: Item, target: Combatant) -> bool:
	if item.kind != Item.Kind.CONSUMABLE or not actor.can_pay(ITEM_BLOCKS):
		return false
	if not actor.is_alive() or actor.item_count(item.id) <= 0:
		return false
	actor.pay(ITEM_BLOCKS)
	if actor.engaged_with != null:
		actor.engage_left = ENGAGE_SECONDS
	actor.remove_item(item.id)
	var before := target.hp
	target.heal(item.heal)
	healed.emit(actor, target, target.hp - before)
	log_message.emit("%s usa %s em %s" % [actor.name, item.display_name, target.name])
	return true


# --- Position steps ----------------------------------------------------------

## Travel time of an attack: the base minus 0.10 s per step of attacker and target.
static func travel_seconds(base: float, attacker: Combatant, target: Combatant) -> float:
	return maxf(base - TRAVEL_PER_STEP * float(attacker.pos_step + target.pos_step), TRAVEL_MIN)


## No step while preparing/executing its own attack, while an attack involves it (as
## attacker or target), while engaged, while still walking a step, or without 1 ATB.
func can_step(c: Combatant, dir: int) -> bool:
	if not running or not c.is_alive() or dir == 0:
		return false
	var to := c.pos_step + dir
	if to < -STEP_MAX or to > STEP_MAX or c.atb < STEP_COST:
		return false
	if c.engaged_with != null or c.step_t < 1.0 or is_winding_up(c):
		return false
	for list in [incoming, _landing, _returning]:
		for inc in list:
			if inc.attacker == c or inc.target == c:
				return false
	return true


func step(c: Combatant, dir: int) -> bool:
	if not can_step(c, dir):
		return false
	c.atb -= STEP_COST
	c.step_from = c.visual_step()
	c.pos_step += dir
	c.step_t = 0.0
	log_message.emit("%s dá um passo %s." % [c.name, "à frente" if dir > 0 else "atrás"])
	stepped.emit(c, c.pos_step)
	return true


## The attack `actor` may press Evade against: one on its way in (works), otherwise one
## still winding up (pressing then is the "too early" whiff).
func find_evadable(actor: Combatant) -> Incoming:
	if not actor.is_alive() or actor.atb < EVADE_BLOCKS:
		return null
	var winding: Incoming = null
	for inc in active_attacks():
		if inc.target != actor or inc.dodged or inc.evade_tried or inc.interrupted:
			continue
		if inc.can_evade_now():
			return inc
		if not inc.resolved and winding == null:
			winding = inc
	return winding


## Attacks still able to hurt: winding up, or already on their way to land.
func active_attacks() -> Array[Incoming]:
	var list: Array[Incoming] = []
	list.append_array(incoming)
	list.append_array(_landing)
	return list


func try_evade(actor: Combatant, inc: Incoming) -> bool:
	if inc == null or actor.atb < EVADE_BLOCKS:
		return false
	actor.atb -= EVADE_BLOCKS
	inc.evade_tried = true
	# Pressing before the attack is on its way (during the wind-up) is the early whiff.
	if not inc.can_evade_now():
		inc.whiffed = true
		log_message.emit("%s esquivou cedo demais! Vulnerável a crítico!" % actor.name)
		evade_whiffed.emit(actor, inc)
		return true
	inc.dodged = true
	actor.burst = mini(actor.burst + 1, Combatant.BURST_MAX)
	actor.counter_ready = true
	log_message.emit("%s desvia de %s no caminho e o interrompe! BURST!" % [actor.name, inc.attacker.name])
	manual_evaded.emit(actor, inc)
	_interrupt(inc)
	_engage(actor, inc.attacker, inc)
	return true


## The attack stops where it is and never hits.
func _interrupt(inc: Incoming) -> void:
	_landing.erase(inc)
	inc.interrupted = true
	inc.plan = [[Phase.STAGGER, 9999.0]]
	inc.plan_i = 0
	inc.phase = Phase.STAGGER
	inc.phase_time = 0.0
	if not _returning.has(inc):
		_returning.append(inc)
	attack_phase.emit(inc, Phase.STAGGER)


func _engage(actor: Combatant, opponent: Combatant, inc: Incoming) -> void:
	actor.engaged_with = opponent
	actor.engage_left = ENGAGE_SECONDS
	# Attacks that already left aim at where `actor` was: they now strike the empty spot.
	for other in _landing:
		if other.target == actor and other != inc:
			other.void_miss = true
	engaged.emit(actor, opponent, inc)


func _step_engage(delta: float) -> void:
	for c in party + enemies:
		if c.engaged_with == null:
			continue
		if not c.is_alive() or not c.engaged_with.is_alive():
			_end_engage(c)
			continue
		if is_winding_up(c):
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
	for inc in _returning:
		if inc.attacker == opponent and inc.phase == Phase.STAGGER:
			staggered = inc
	var ghost := Incoming.new()
	ghost.attacker = actor
	ghost.target = opponent
	ghost.ghost = true
	ghost.resolved = true
	ghost.impacted = true
	engage_ended.emit(actor, opponent, ghost, staggered)
	for inc in [ghost, staggered]:
		if inc == null or inc.plan.is_empty() or (inc == staggered and inc.phase != Phase.STAGGER):
			continue
		inc.plan_i = 0
		inc.phase = inc.plan[0][0]
		inc.phase_time = 0.0
		if inc == ghost:
			_returning.append(inc)
		attack_phase.emit(inc, inc.phase)


func is_winding_up(c: Combatant) -> bool:
	for inc in incoming:
		if inc.attacker == c:
			return true
	for inc in _landing:
		if inc.attacker == c:
			return true
	for inc in _returning:
		if inc.attacker == c and inc.phase == Phase.STAGGER:
			return true  # Interrupted: stunned until the engaged state ends.
	return false


# --- AI (everyone except the player-controlled leader) -----------------------

func _run_ai() -> void:
	for c in party + enemies:
		if c == party[0] or not c.is_alive():
			continue
		var foes := enemies if c.is_player else party
		if c.tactic_pos != c.pos_step and step(c, signi(c.tactic_pos - c.pos_step)):
			continue
		if c.hp <= c.max_hp * AI_HEAL_BELOW and c.can_pay(ITEM_BLOCKS):
			var potion := _first_consumable(c)
			if potion != null and use_item(c, potion, c):
				continue
		if is_winding_up(c):
			continue
		if c.act_policy == Combatant.Act.HOLD or not c.can_pay(SKILL_BLOCKS):
			continue
		var target := c.engaged_with if c.engaged_with != null and c.engaged_with.is_alive() else _first_alive(foes)
		if target == null:
			return
		use_skill(c, _pick_skill(c), target)


func _first_consumable(c: Combatant) -> Item:
	for id in c.inventory:
		var item := Item.get_item(id)
		if item != null and item.kind == Item.Kind.CONSUMABLE and c.item_count(id) > 0:
			return item
	return null


## SKILL policy cycles through the combatant's skills; ATTACK uses the basic attack.
func _pick_skill(c: Combatant) -> Skill:
	if c.act_policy == Combatant.Act.SKILL and not c.skills.is_empty():
		for i in c.skills.size():
			var skill := c.skills[(c.skill_cursor + i) % c.skills.size()]
			if c.can_pay(skill.cost):
				c.skill_cursor = (c.skill_cursor + i + 1) % c.skills.size()
				return skill
	return Skill.basic()


func _resolve_incoming(delta: float) -> void:
	for inc in incoming.duplicate():
		if not inc.attacker.is_alive() or not inc.target.is_alive():
			attack_cancelled.emit(inc)
			incoming.erase(inc)
			continue
		inc.time_left -= delta
		if inc.time_left > 0.0:
			continue
		incoming.erase(inc)
		inc.auto_dodged = not inc.dodged and not inc.whiffed and randf() < inc.target.speed
		inc.resolved = true
		attack_resolved.emit(inc)  # BattleFx fills inc.plan here.
		if inc.plan.is_empty():
			inc.plan = [[Phase.STRIKE, 0.0]]
			inc.impact_phase = Phase.STRIKE
		inc.plan_i = 0
		inc.phase = inc.plan[0][0]
		inc.phase_time = 0.0
		_landing.append(inc)
		attack_phase.emit(inc, inc.phase)
		_roll_ai_evade(inc)
	_check_end()


## Advances every resolved attack along its timeline. The hit counts (damage, death) when
## the impact phase ends; the return is played out afterwards.
func _step_attacks(delta: float) -> void:
	for inc in _landing.duplicate() + _returning.duplicate():
		if inc.phase == Phase.STAGGER:
			inc.phase_time += delta
			continue
		inc.phase_time += delta
		while inc.plan_i < inc.plan.size() and inc.phase_time >= inc.plan[inc.plan_i][1]:
			inc.phase_time -= inc.plan[inc.plan_i][1]
			var ended: int = inc.plan[inc.plan_i][0]
			if ended == inc.impact_phase and not inc.impacted:
				_strike(inc)
			inc.plan_i += 1
			if inc.plan_i < inc.plan.size():
				inc.phase = inc.plan[inc.plan_i][0]
				attack_phase.emit(inc, inc.phase)
				_roll_ai_evade(inc)
		if inc.can_evade_now() and inc.ai_evade_at >= 0.0 and inc.phase_time >= inc.ai_evade_at:
			inc.ai_evade_at = -1.0
			if inc.target.is_alive() and inc.target.atb >= EVADE_BLOCKS and not inc.evade_tried:
				try_evade(inc.target, inc)
		if inc.plan_i >= inc.plan.size():
			if not inc.impacted:
				_strike(inc)
			inc.phase = Phase.DONE
			_returning.erase(inc)
			attack_phase.emit(inc, Phase.DONE)
	_check_end()


## A computer-controlled target reacts on the way in with a chance equal to its speed.
func _roll_ai_evade(inc: Incoming) -> void:
	if inc.phase != Phase.TRAVEL or inc.ghost:
		return
	var t := inc.target
	if t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if randf() < t.speed:
		inc.ai_evade_at = inc.phase_len() * randf_range(0.25, 0.75)


func _strike(inc: Incoming) -> void:
	inc.impacted = true
	_landing.erase(inc)
	if not _returning.has(inc):
		_returning.append(inc)
	if inc.ghost or inc.interrupted:
		return
	if inc.dodged or inc.void_miss:
		log_message.emit("%s errou %s!" % [inc.attacker.name, inc.label])
	elif inc.attacker.is_alive() and inc.target.is_alive():
		_hit(inc.attacker, inc.target, inc.power, inc.element, inc.label, inc.whiffed, inc.auto_dodged)


func _step_cues(delta: float) -> void:
	for c in _cues.duplicate():
		c["t"] -= delta
		if c["t"] <= 0.0:
			_cues.erase(c)
			cue.emit(c["kind"], c["actor"], c["inc"])


## Resolved attacks that FX still has to draw (landing or returning).
func attacks_in_flight() -> Array[Incoming]:
	var list: Array[Incoming] = []
	list.append_array(_landing)
	list.append_array(_returning)
	return list


# --- Helpers ---------------------------------------------------------------

func _hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String, whiffed := false, auto_dodged := false) -> void:
	var info := {"evaded": false, "dmg": 0, "weak": false, "crit": false, "gain": 0, "whiffed": whiffed, "power": power}
	# Automatic evade: disabled if the target whiffed an early manual Evade!
	if auto_dodged:
		target.add_atb(1.0)
		info["evaded"] = true
		log_message.emit("%s esquiva de %s automaticamente! +1 bloco" % [target.name, label])
		hit_resolved.emit(attacker, target, element, info)
		return
	var weak := element in target.weaknesses
	var crit := whiffed or (randf() < CRIT_CHANCE)
	# Position: +10% per step in front for the attacker, -10% per step behind for the target.
	var step_mult := (1.0 + DMG_PER_STEP * maxi(attacker.pos_step, 0)) * (1.0 - DMG_PER_STEP * maxi(-target.pos_step, 0))
	var dmg := maxi(1, roundi(attacker.attack * power * (WEAKNESS_MULT if weak else 1.0) * (CRIT_MULT if crit else 1.0) * step_mult))
	target.take_damage(dmg)
	var gain := (2 if weak else 0) + (1 if crit else 0)
	attacker.add_atb(float(gain))
	info["dmg"] = dmg
	info["weak"] = weak
	info["crit"] = crit
	info["gain"] = gain
	log_message.emit("%s usa %s (%s) em %s (%d dano)%s" % [
		attacker.name, label, Element.name_of(element), target.name, dmg,
		(" FRAQUEZA! +2 bloco(s)" if weak else "") + (" CRÍTICO! +1 bloco" if crit else "")])
	hit_resolved.emit(attacker, target, element, info)


func _first_alive(list: Array[Combatant]) -> Combatant:
	for c in list:
		if c.is_alive():
			return c
	return null


func _check_end() -> void:
	if not running:
		return
	var enemies_dead := _first_alive(enemies) == null
	var party_dead := _first_alive(party) == null
	if not enemies_dead and not party_dead:
		return
	running = false
	for inc in incoming:
		attack_cancelled.emit(inc)
	incoming.clear()
	_landing.clear()
	for c in party + enemies:
		c.engaged_with = null
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)
