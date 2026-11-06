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
signal manual_evaded(actor: Combatant, inc)
## A status move paused the engine (D-031) / the engine runs again.
signal status_pause_started(inc)
signal status_pause_ended(inc)
## A perfect Evade during its own run: `actor` jumped from `from` to the front of `opponent`.
signal evade_teleported(actor: Combatant, opponent: Combatant, from: Vector3)
## A non-perfect Evade during its own run: the run was cancelled and `actor` is back home.
signal evade_returned(actor: Combatant, from: Vector3)
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
signal attack_clashed(inc_a, inc_b, point: Vector3, mutual: bool)  ## D-279: two opposing runners bumped into each other.
signal attack_interrupted(inc)  ## A hit stopped an attack on its way: BattleFx fills its recovery plan.
signal burn_applied(target: Combatant)  ## D-238
signal burn_ticked(target: Combatant, damage: int)  ## D-238: for the future HUD / VFX of the Burn
signal burn_ended(target: Combatant)  ## D-238: the Burn ran out (not when the target died)
signal guard_started(actor: Combatant)  ## D-272
signal guard_ended(actor: Combatant, reason: String)  ## D-272: "expired", "hit", "broken" or "battle_end".
signal reward_spawned(reward)
signal reward_landed(reward)

const Phase = Incoming.Phase

const REWARD_FLOAT := 0.6  ## Seconds a reward token floats over where it was earned.
const REWARD_FLY := 0.25  ## Seconds it flies to the HUD.
const REWARD_IMPACT := 0.46  ## Seconds of impact effect at the slot.
const SKILL_BLOCKS := 2.0
const ITEM_BLOCKS := 1.0
const GUARD_BLOCKS := 1.0  ## D-272: Guard costs 1 ATB; Burst does not pay it.
const GUARD_SECONDS := 2.0  ## D-272: no cancelling; ends by time, contact or Brick Break.
const GUARD_REDUCTION := 0.5  ## PROVISIONAL (D-272): until VIT/SPI exist. Damage taken = ceil(damage x (1 - this)).
const GUARD_BREAKERS := ["quebra_telha"]  ## D-272: moves with the guard-break trait (Brick Break).
const AI_GUARD_CHANCE := 0.25  ## D-272/D-116: chance an AI target guards when an attack is declared on it.

## Minimum ATB cost among the combatant's usable skills (or 0 if Burst is active) — D-040.
static func min_skill_cost(c: Combatant) -> float:
	if c == null:
		return SKILL_BLOCKS
	if c.burst > 0:
		return 0.0
	var min_cost := Skill.basic().cost
	for s in c.skills:
		if s.cost < min_cost:
			min_cost = s.cost
	return float(min_cost)
const EVADE_STILL := 3.0  ## Evade while standing still (not running in its own attack) — D-006.
const EVADE_ON_RUN := 2.0  ## Evade during the run of its own melee attack — D-006.
const PERFECT_WINDOW := 0.25  ## D-283: the Evade only works in the last seconds before the hit, inside the strike, and is always perfect (D-027, D-030).
const COUNTER_WINDUP := 0.3  ## D-284: wind-up of the counter-attack after a perfect Evade, whatever the move (a status move stays instant).
const AUTO_DODGE_CHANCE := 0.10  ## Automatic evade chance per hit, for every target.
var debug_roll := 0  ## Sala de VFX (debug): 0 = sorteio normal, 1 = acerto sem crítico, 2 = esquiva, 3 = acerto crítico.
const STATUS_WINDUP := 0.5  ## Status moves prepare faster, with the engine paused (D-031).
const STATUS_VFX_TAIL := 1.0  ## Seconds the engine stays paused after the status effect is applied.
const BURN_DMG := 2  ## D-238 (D-236 sheet): fixed damage of each Burn tick
const BURN_INTERVAL := 1.0  ## seconds between ticks; the first comes one interval after the hit
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
var rewards: Array[BattleReward] = []
var _reward_id := 0
var _landing: Array[Incoming] = []  ## Resolved attacks whose strike has not landed yet.
var _returning: Array[Incoming] = []  ## Struck already: only the return is left to play.
var _status_pause: Incoming = null  ## A status move is being performed: only it runs (D-031).
var _status_tail := -1.0
var _freeze_left := 0.0  ## Hit-stop: the whole battle clock holds still for this many seconds.
var _evade := BattleEvade.new(self)
var _ai := BattleAI.new(self)
var _planner := AttackPlanner.new(self)
var _hop_back := 0.3  ## Placeholder; BattleFx decides how long a return takes.


func start(p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	party = p_party
	enemies = p_enemies
	for c in party + enemies:
		c.atb = START_ATB
		c.burst = 0
		c.clear_pending()
		c.engaged_with = null
		c.pos_step = 0
		c.step_from = 0.0
		c.step_t = 1.0
	_landing.clear()
	_ai.reset()
	_status_pause = null
	_returning.clear()
	rewards.clear()
	running = true
	log_message.emit("Batalha iniciada!")


## Debug aid: is an attack (pending or still playing out) using this combatant?
## The test spawns must not be removed while one is.
func is_in_action(c: Combatant) -> bool:
	for inc in incoming + _landing + _returning:
		if inc.attacker == c or inc.target == c:
			return true
	return _status_pause != null and (_status_pause.attacker == c or _status_pause.target == c)


## Everyone not carried by an attack's motion stands at its rest spot.
func _update_positions() -> void:
	var carried := {}
	for inc in _landing + _returning:
		if AttackMotion.carries(inc):
			carried[inc.attacker] = true
	for c in party + enemies:
		if not carried.has(c):
			c.pos = c.rest_pos()


## Holds the battle clock for `seconds` (the contact freeze), so movement, rules and the
## frozen animations stay on the same frame.
func freeze(seconds: float) -> void:
	_freeze_left = maxf(_freeze_left, seconds)


func _process(delta: float) -> void:
	if _freeze_left > 0.0:
		_freeze_left -= delta
		return
	if not running:
		if not _returning.is_empty():
			_step_attacks(delta)  # The winners' leaps back still play out after the last hit.
		return
	if _status_pause != null:
		_step_status_pause(delta)
		state_changed.emit()
		return
	for c in party + enemies:
		if not is_winding_up(c):  # ATB stays locked until the action finishes.
			c.tick(delta)
		_tick_burn(c, delta)  # D-238: burns on, also while it winds up
	for c in party + enemies:
		if c.step_t < 1.0:
			c.step_t = minf(c.step_t + delta / STEP_TIME, 1.0)
	_update_positions()
	_ai.run(delta)
	_resolve_incoming(delta)
	_step_attacks(delta)
	_run_queued()
	_step_rewards(delta)
	_evade.step_engage(delta)
	state_changed.emit()


# --- Actions (same for the player, allies and enemies) -----------------------

func use_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not actor.is_alive() or actor.is_stunned() or actor.is_guarding() or is_winding_up(actor) or not actor.can_pay(skill.cost):
		return false
	if _status_pause != null:
		return false  # The engine is paused by a status move (D-031).
	if skill.is_friendly:
		if target == null or not target.is_alive() or target.is_player != actor.is_player:
			target = actor
	else:
		if target == null or not target.is_alive():
			return false
		if actor.engaged_with != null and target != actor.engaged_with:
			return false  # Engaged: it only acts on the opponent it is standing next to.
	actor.pay(skill.cost)
	var inc := Incoming.new()
	inc.attacker = actor
	inc.target = target
	inc.power = skill.power
	inc.element = skill.element
	inc.kind = skill.kind
	inc.ground = skill.ground
	inc.label = skill.display_name
	inc.is_aoe = skill.is_aoe
	inc.is_friendly = skill.is_friendly
	inc.skill = skill
	# After a perfect Evade during its own run, the next attack is immediate (D-027).
	inc.instant = (actor.engaged_with != null or actor.counter_ready) and not skill.is_friendly
	if not skill.is_friendly:
		actor.counter_ready = false
	if actor.engaged_with != null and not skill.is_friendly:
		actor.engage_left = ENGAGE_SECONDS  # Acting keeps it engaged.

	# Taunt redirection (D-032)
	if actor.taunted_by != null and actor.taunted_by.is_alive() and not skill.is_friendly and not skill.is_aoe and inc.kind != Skill.Kind.STATUS:
		target = actor.taunted_by
		inc.target = target
		actor.taunt_atk_bonus = true

	# Individual windup overrides (D-032 / D-034)
	var mid := BattleSpace.move_id(skill.display_name)
	var w_override := skill.windup if skill.windup >= 0.0 else (STATUS_WINDUP if inc.kind == Skill.Kind.STATUS else WINDUP)
	inc.total_windup = ((0.0 if inc.kind == Skill.Kind.STATUS else COUNTER_WINDUP) if inc.instant else w_override)  # D-284
	inc.time_left = inc.total_windup

	incoming.append(inc)
	if inc.kind == Skill.Kind.STATUS:
		_status_pause = inc  # From the wind-up until its effect has played (D-031).
		_status_tail = -1.0
		status_pause_started.emit(inc)
	log_message.emit("%s prepara %s em %s..." % [actor.name, skill.display_name, target.name])
	_planner.redirect_if_blocked(inc)
	attack_telegraphed.emit(inc)
	_roll_ai_guard(inc)
	return true


## A player's move: it starts now if it can; otherwise it waits in the one slot, replacing
## whatever was there. Nothing is paid until it starts (D-161).
func request_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not running or not actor.is_alive() or actor.is_stunned() or actor.is_guarding():
		return false
	if can_start_now(actor):
		return _start_move(actor, skill, target)
	if not skill.is_friendly and (target == null or not target.is_alive()):
		return false
	actor.queued_skill = skill
	actor.queued_target = target
	log_message.emit("%s guarda %s para em seguida." % [actor.name, skill.display_name])
	return true


## False during a status pause (D-031) and until its own attack has ended, return included.
func can_start_now(actor: Combatant) -> bool:
	return _status_pause == null and not is_attacking(actor) and not actor.is_guarding()


func _start_move(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if actor.is_stunned() or actor.is_guarding() or not actor.can_pay(skill.cost):
		return false
	if not skill.is_friendly and (target == null or not target.is_alive()):
		return false
	return use_skill(actor, skill, target)


## A queued move starts as soon as nothing holds it; without ATB, a living target or the
## ability to act at that moment, it is dropped (D-161).
func _run_queued() -> void:
	for c in party + enemies:
		if c.queued_skill == null or not can_start_now(c):
			continue
		var skill := c.queued_skill
		var target := c.queued_target
		_clear_queued(c)
		if not c.is_alive():
			continue
		if not _start_move(c, skill, target):
			log_message.emit("%s não pôde usar %s." % [c.name, skill.display_name])


func _clear_queued(c: Combatant) -> void:
	c.queued_skill = null
	c.queued_target = null


func use_item(actor: Combatant, item: Item, target: Combatant) -> bool:
	if item.kind != Item.Kind.CONSUMABLE or actor.is_stunned() or actor.is_guarding() or not actor.can_pay(ITEM_BLOCKS):
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


# --- Guard (D-272) -----------------------------------------------------------

## Why `actor` cannot Guard right now ("" when it can).
func guard_block_reason(actor: Combatant) -> String:
	if not running or not actor.is_alive():
		return "fora de combate"
	if actor.is_guarding():
		return "em Guard"
	if actor.is_stunned():
		return "atordoado"
	if actor.engaged_with != null:
		return "engajado"
	if _status_pause != null or (is_attacking(actor) and not is_held(actor)):  # D-282: held in its idle it may Guard
		return "em ação"
	if actor.blocks() < GUARD_BLOCKS:
		return "falta ATB"  # Burst never pays the Guard (D-272).
	return ""


func can_guard(actor: Combatant) -> bool:
	return guard_block_reason(actor) == ""


## 1 ATB, 2 s, no cancelling: the actor can do nothing else and its ATB is paused until the
## Guard expires or is hit/broken.
func use_guard(actor: Combatant) -> bool:
	if not can_guard(actor):
		return false
	if not actor.guard_ended.is_connected(_on_guard_ended):
		actor.guard_ended.connect(_on_guard_ended)
	actor.spend(GUARD_BLOCKS)
	actor.guard_timer = GUARD_SECONDS
	_clear_queued(actor)
	log_message.emit("%s entra em Guard!" % actor.name)
	guard_started.emit(actor)
	return true


func _on_guard_ended(actor: Combatant, reason: String) -> void:
	guard_ended.emit(actor, reason)


## An AI-controlled target may raise a Guard when an attack is declared on it (D-272, D-116).
func _roll_ai_guard(inc: Incoming) -> void:
	var t := inc.target
	if inc.is_friendly or inc.kind == Skill.Kind.STATUS or t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if t.is_player == inc.attacker.is_player:
		return
	if randf() < AI_GUARD_CHANCE:
		inc.ai_guard_eta = randf_range(0.8, 1.3)  # D-285: it raises the shield near the impact, not at the start of the wind-up


# --- Position steps ----------------------------------------------------------

## Travel time of an attack: the base minus 0.10 s per step of attacker and target.
static func travel_seconds(base: float, attacker: Combatant, target: Combatant) -> float:
	return maxf(base - TRAVEL_PER_STEP * float(attacker.pos_step + target.pos_step), TRAVEL_MIN)


## No step while preparing/executing its own attack, while an attack involves it (as
## attacker or target), while engaged, while still walking a step, or without 1 ATB.
func can_step(c: Combatant, dir: int) -> bool:
	if not running or not c.is_alive() or dir == 0 or c.is_stunned() or c.is_guarding():
		return false
	var to := c.pos_step + dir
	if to < -STEP_MAX or to > STEP_MAX or c.blocks() < STEP_COST:
		return false
	if c.engaged_with != null or c.step_t < 1.0 or is_winding_up(c) or c.is_stunned():
		return false
	for list in [incoming, _landing, _returning]:
		for inc in list:
			if inc.attacker == c or inc.target == c:
				return false
	return true


## Short reason a step is not possible right now ("" when it is).
func step_block_reason(c: Combatant) -> String:
	if not running or not c.is_alive():
		return ""
	if c.is_guarding():
		return "em Guard"
	if c.engaged_with != null:
		return "engajado"
	if c.step_t < 1.0:
		return "andando"
	if is_winding_up(c):
		return "em ação"
	for list in [incoming, _landing, _returning]:
		for inc in list:
			if inc.attacker == c or inc.target == c:
				return "ataque em curso"
	if c.blocks() < STEP_COST:
		return "falta ATB"
	return ""


func step(c: Combatant, dir: int) -> bool:
	if not can_step(c, dir):
		return false
	c.spend(STEP_COST)
	c.step_from = c.visual_step()
	c.pos_step += dir
	c.step_t = 0.0
	log_message.emit("%s dá um passo %s." % [c.name, "à frente" if dir > 0 else "atrás"])
	stepped.emit(c, c.pos_step)
	return true


## The attack `actor` may press Evade against: one on its way in (works), otherwise one
## still winding up (pressing then is the "too early" whiff).
## Damage a move would deal now (no crit), same formula as a hit; 0 for status moves.
static func estimate_damage(attacker: Combatant, target: Combatant, skill: Skill) -> int:
	if skill.kind == Skill.Kind.STATUS:
		return 0
	var weak := skill.element in target.weaknesses
	var step_mult := (1.0 + DMG_PER_STEP * maxi(attacker.pos_step, 0)) * (1.0 - DMG_PER_STEP * maxi(-target.pos_step, 0))
	return maxi(1, roundi(attacker.attack * skill.power * (WEAKNESS_MULT if weak else 1.0) * step_mult))


## A projectile that meets another opponent on its way hits that one instead.
func redirect(inc: Incoming, new_target: Combatant) -> void:
	log_message.emit("%s intercepta %s de %s (era para %s)!" % [new_target.name, inc.label, inc.attacker.name, inc.target.name])
	inc.target = new_target


## True while `c` is itself attacking, returning from an attack or stunned.
func is_attacking(c: Combatant) -> bool:
	if is_winding_up(c):
		return true
	for inc in _returning:
		if inc.attacker == c:
			return true
	return false


func evade_cost(actor: Combatant) -> float:
	return _evade.cost(actor)


func find_evadable(actor: Combatant) -> Incoming:
	return _evade.find_evadable(actor)


func try_evade(actor: Combatant, inc: Incoming) -> bool:
	return _evade.try_evade(actor, inc)


## Attacks still able to hurt: winding up, or already on their way to land.
func active_attacks() -> Array[Incoming]:
	var list: Array[Incoming] = []
	list.append_array(incoming)
	list.append_array(_landing)
	return list


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


func _resolve_incoming(delta: float, only: Incoming = null) -> void:
	for inc in incoming.duplicate():
		if only != null and inc != only:
			continue
		if inc.attacker.is_alive() and not inc.target.is_alive():
			_retarget_aoe(inc)
		if not inc.attacker.is_alive() or not inc.target.is_alive():
			attack_cancelled.emit(inc)
			incoming.erase(inc)
			continue
		inc.time_left -= delta
		if inc.time_left > 0.0:
			continue
		incoming.erase(inc)
		var mid := BattleSpace.move_id(inc.label)
		if mid in ["investida_subterranea", "investida_escavadora", "teleporte_rapido"]:
			inc.attacker.is_invulnerable = true
		inc.auto_dodged = inc.kind != Skill.Kind.STATUS and not inc.dodged and not inc.whiffed and (debug_roll == 2 or (debug_roll == 0 and randf() < AUTO_DODGE_CHANCE))
		inc.resolved = true
		_planner.plan(inc)
		attack_resolved.emit(inc)  # BattleFx prepares the drawing of the planned attack.
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
func _step_attacks(delta: float, only: Incoming = null) -> void:
	if only == null:
		_detect_clashes()
	for inc in _landing.duplicate() + _returning.duplicate():
		if only != null and inc != only:
			continue
		if inc.phase == Phase.STAGGER:
			inc.phase_time += delta
			continue
		var before: float = inc.phase_time
		inc.phase_time += delta
		# D-282: in its idle after a melee strike it does not hop home while another melee attack is striking it.
		if inc.phase == Phase.RETURN and inc.hold > 0.0 and before <= inc.hold and inc.phase_time >= inc.hold and _holds_idle(inc, true):
			inc.phase_time = inc.hold - 0.0005
		while inc.plan_i < inc.plan.size() and inc.phase_time >= inc.plan[inc.plan_i][1]:
			inc.phase_time -= inc.plan[inc.plan_i][1]
			var ended: int = inc.plan[inc.plan_i][0]
			if ended == inc.impact_phase and not inc.impacted:
				_strike(inc)
			inc.plan_i += 1
			if inc.plan_i < inc.plan.size():
				inc.phase = inc.plan[inc.plan_i][0]
				var mid_flight := BattleSpace.move_id(inc.label)
				if inc.phase == Phase.STRIKE:
					if mid_flight in ["investida_subterranea", "investida_escavadora", "teleporte_rapido"]:
						inc.attacker.is_invulnerable = false
				elif inc.phase == Phase.RETURN:
					if mid_flight == "teleporte_rapido":
						inc.attacker.is_invulnerable = true
				AttackMotion.on_phase(inc)
				attack_phase.emit(inc, inc.phase)
				_roll_ai_evade(inc)
		AttackMotion.update(inc, delta)
		if inc.ai_guard_eta >= 0.0 and inc.resolved and not inc.impacted and not inc.interrupted and not inc.dodged and inc.eta() <= inc.ai_guard_eta:
			inc.ai_guard_eta = -1.0
			if inc.target.is_alive() and can_guard(inc.target):
				use_guard(inc.target)
		AttackMotion.update_projectile(inc)
		if inc.can_evade_now() and inc.ai_evade_at >= 0.0 and inc.phase_time >= inc.ai_evade_at:
			_ai.try_evade(inc)
		if inc.plan_i >= inc.plan.size():
			if not inc.impacted:
				_strike(inc)
			inc.phase = Phase.DONE
			if BattleSpace.move_id(inc.label) in ["investida_subterranea", "investida_escavadora", "teleporte_rapido"]:
				inc.attacker.is_invulnerable = false
			_returning.erase(inc)
			if inc.motion != "engaged" and inc.attacker.is_alive():
				inc.attacker.clear_rest()  # Back at its step spot.
				inc.attacker.pos = inc.attacker.rest_pos()
			attack_phase.emit(inc, Phase.DONE)
	_check_end()


## D-282: `c` is in its post-strike idle (before the hop home) and held there by an attack that is striking it.
func is_held(c: Combatant) -> bool:
	for inc in _returning:
		if inc.attacker == c and _holds_idle(inc):
			return true
	return false


## D-282: this returning melee attack is still in its idle and another melee attack is in its strike against its attacker.
func _holds_idle(ret: Incoming, crossing := false) -> bool:
	if ret.ghost or ret.interrupted or ret.kind != Skill.Kind.MELEE or ret.motion != "melee" or ret.hold <= 0.0:
		return false
	if ret.phase != Phase.RETURN or (not crossing and ret.phase_time > ret.hold + 0.001):
		return false  # already hopping
	for x in _landing:
		if x.target == ret.attacker and x.attacker != ret.attacker and x.attacker.is_alive() and x.phase == Phase.STRIKE 				and (x.motion == "melee" or x.motion == "engaged") and x.kind == Skill.Kind.MELEE 				and not x.impacted and not x.interrupted and not x.dodged and not x.auto_dodged and not x.ghost and not x.is_friendly:
			return true
	return false


## D-279: two runners of opposing teams that meet bump back with a hop. If they were running at each
## other, both then strike at once from there (each with its own move's timing, so the faster one hits
## first and the existing interruption rule applies); with different targets both give up and go home.
func _detect_clashes() -> void:
	var runners: Array[Incoming] = []
	for inc in _landing:
		if inc.motion == "melee" and inc.phase == Phase.TRAVEL and not inc.clash and not inc.blink and not inc.interrupted 				and not inc.dodged and not inc.auto_dodged and not inc.ghost and inc.phase_time > AttackMotion.RUN_START 				and not inc.attacker.is_invulnerable:
			runners.append(inc)
	for i in runners.size():
		var ia := runners[i]
		if ia.clash:
			continue
		for j in range(i + 1, runners.size()):
			var ib := runners[j]
			if ib.clash or ia.attacker.is_player == ib.attacker.is_player:
				continue
			if ia.attacker.pos.distance_to(ib.attacker.pos) > BattleSpace.CLASH_DIST:
				continue
			_clash(ia, ib)
			break


func _clash(ia: Incoming, ib: Incoming) -> void:
	var pa := ia.attacker.pos
	var pb := ib.attacker.pos
	var axis := BattleSpace.flat_dir(pa, pb)  # from a to b
	var center := (pa + pb) * 0.5
	var mutual := ia.target == ib.attacker and ib.target == ia.attacker
	attack_clashed.emit(ia, ib, center, mutual)
	log_message.emit("%s e %s se chocam!" % [ia.attacker.name, ib.attacker.name])
	var sides := [[ia, axis], [ib, -axis]]
	for s in sides:
		var inc: Incoming = s[0]
		var toward: Vector3 = s[1]  # where the opponent is, seen from this runner
		if mutual:
			inc.clash = true
			inc.clash_mode = "strike"
			inc.clash_start = inc.phase_time
			inc.clash_from = inc.attacker.pos
			inc.clash_land = inc.attacker.pos - toward * BattleSpace.CLASH_BACK
			inc.dir = toward
			inc.stand = center - toward * (BattleSpace.STAND_GAP * 0.5)  # a gap of 2.6 between the two
			inc.plan[inc.plan_i][1] = inc.phase_time + BattleSpace.CLASH_HOP_T  # the run ends with the hop
		else:
			_landing.erase(inc)
			inc.interrupted = true
			AttackMotion.begin_hit_return(inc, -toward * BattleSpace.CLASH_BACK)
			attack_interrupted.emit(inc)
			_returning.append(inc)
			attack_phase.emit(inc, inc.phase)


## The engine is paused: only the status move runs (wind-up, cast, effect), then the engine
## waits STATUS_VFX_TAIL more seconds for its visual effect before everything resumes.
func _step_status_pause(delta: float) -> void:
	var inc := _status_pause
	if incoming.has(inc):
		_resolve_incoming(delta, inc)
	elif _landing.has(inc) or _returning.has(inc):
		_step_attacks(delta, inc)
	elif _status_tail < 0.0:
		_status_tail = STATUS_VFX_TAIL  # Done (or cancelled): let its effect finish.
	else:
		_status_tail -= delta
		if _status_tail <= 0.0:
			_status_pause = null
			status_pause_ended.emit(inc)


## A computer-controlled target reacts on the way in with a chance equal to its speed.
func _roll_ai_evade(inc: Incoming) -> void:
	if inc.phase != inc.impact_phase or inc.ghost or inc.is_friendly:
		return  # (a buff or a heal is not something to dodge)
	var t := inc.target
	if t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if randf() < t.speed:
		inc.ai_evade_at = maxf(inc.phase_len() - randf_range(0.03, PERFECT_WINDOW - 0.03), 0.0)  # D-283: inside the final window


func _strike(inc: Incoming) -> void:
	AttackMotion.arrive(inc)
	inc.impacted = true
	_landing.erase(inc)
	if not _returning.has(inc):
		_returning.append(inc)
	if inc.ghost or inc.interrupted:
		return
	if not inc.target.is_alive():
		_retarget_aoe(inc)
	if inc.dodged:
		if inc.attacker.taunt_atk_bonus:
			inc.attacker.taunt_atk_bonus = false
			inc.attacker.taunted_by = null
		log_message.emit("%s esquivou de %s!" % [inc.target.name, inc.label])
	elif inc.attacker.is_alive() and inc.kind == Skill.Kind.STATUS:
		_execute_status_move(inc)
	elif inc.target.is_alive() and (inc.attacker.is_alive() or inc.kind == Skill.Kind.PROJECTILE):
		var mid := BattleSpace.move_id(inc.label)
		if mid in ["tiro_areia", "sand_attack"]:
			if inc.attacker.taunt_atk_bonus:
				inc.attacker.taunt_atk_bonus = false
				inc.attacker.taunted_by = null
			if inc.attacker.is_blind() and randf() < 0.35:
				log_message.emit("%s erra o Sand Attack devido à cegueira! (MISS!)" % inc.attacker.name)
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": true, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": inc.whiffed, "power": 0.0,
					"skill_name": inc.label
				})
			elif inc.auto_dodged or inc.dodged or inc.target.is_invulnerable_target():
				if inc.auto_dodged:
					grant_atb(inc.target, 1, inc.target)
					log_message.emit("%s esquiva do Sand Attack automaticamente! +1 bloco (MISS!)" % inc.target.name)
				elif inc.target.is_invulnerable_target():
					log_message.emit("%s não está lá e o Sand Attack erra completamente! (MISS!)" % inc.target.name)
				else:
					log_message.emit("%s esquivou do Sand Attack! (MISS!)" % inc.target.name)
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": true, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": inc.whiffed, "power": 0.0,
					"skill_name": inc.label
				})
			else:
				inc.target.blind_timer = 4.0
				log_message.emit("%s foi atingido pela areia e fica cego por 4 segundos!" % inc.target.name)
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": inc.whiffed, "power": 0.0,
					"skill_name": inc.label, "blind": true
				})
		else:
			var hit_info := _hit(inc.attacker, inc.target, inc.power, inc.element, inc.label, inc.whiffed, inc.auto_dodged)
			var foes: Array[Combatant] = enemies if inc.attacker.is_player else party  # The attacker's opponents.
			if inc.is_aoe:
				for foe in foes:
					if foe.is_alive() and foe != inc.target:
						_hit(inc.attacker, foe, inc.power * 0.85, inc.element, inc.label, inc.whiffed, false)
			elif (inc.skill != null and inc.skill.aoe_on_contact) or mid in ["furia_dragao", "dragon_rage"]:
				# D-032: Se o alvo principal foi atingido (não esquivou / não invulnerável), aliados sofrem dano total (1.6x)
				if not hit_info.get("evaded", false):
					for foe in foes:
						if foe.is_alive() and foe != inc.target:
							_hit(inc.attacker, foe, inc.power, inc.element, inc.label, inc.whiffed, false)


## An area attack whose aimed target is gone aims at the next opponent still standing, so the
## rest of the team does not escape it. (Single-target attacks are simply lost.)
func _retarget_aoe(inc: Incoming) -> void:
	if not inc.is_aoe or inc.is_friendly:
		return
	var foes: Array[Combatant] = enemies if inc.attacker.is_player else party
	var next := _first_alive(foes)
	if next != null:
		inc.target = next


func _execute_status_move(inc: Incoming) -> void:
	var mid := BattleSpace.move_id(inc.label)
	match mid:
		"media":
			var team: Array[Combatant] = party if inc.attacker.is_player else enemies
			var heal_amount := 10 + inc.attacker.mag  # creator (2026-11-05): Media heals 10 + MAG
			log_message.emit("%s usa Media! A equipe recupera HP!" % inc.attacker.name)
			for ally in team:
				if ally.is_alive():
					var before_hp := ally.hp
					ally.heal(heal_amount)
					healed.emit(inc.attacker, ally, ally.hp - before_hp)
					hit_resolved.emit(inc.attacker, ally, inc.element, {
						"status": true, "evaded": false, "dmg": 0, "weak": false,
						"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
						"skill_name": inc.label, "heal": true
					})
		"tarukaja":
			var team: Array[Combatant] = party if inc.attacker.is_player else enemies
			var any_increased := false
			for ally in team:
				if ally.is_alive():
					var capped := not ally.can_buff("atk", 1)
					if not capped:
						ally.buff_stat("atk", 1)
						any_increased = true
					hit_resolved.emit(inc.attacker, ally, inc.element, {
						"status": true, "evaded": false, "dmg": 0, "weak": false,
						"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
						"skill_name": inc.label, "buff": "atk", "capped": capped
					})
			if any_increased:
				log_message.emit("%s usa Tarukaja! O ataque da equipe aumentou!" % inc.attacker.name)
			else:
				log_message.emit("%s usa Tarukaja! O ataque da equipe já está no patamar máximo (+5)!" % inc.attacker.name)
		"rakunda":
			if inc.target.is_alive():
				var capped := not inc.target.can_buff("def", -1)
				if not capped:
					inc.target.buff_stat("def", -1)
					log_message.emit("%s usa Rakunda! A defesa de %s foi reduzida!" % [inc.attacker.name, inc.target.name])
				else:
					log_message.emit("%s usa Rakunda! A defesa de %s já está no patamar mínimo (-5)!" % [inc.attacker.name, inc.target.name])
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label, "debuff": "def", "capped": capped
				})
		"sukunda":
			if inc.target.is_alive():
				var capped := not inc.target.can_buff("speed", -1)
				if not capped:
					inc.target.buff_stat("speed", -1)
					log_message.emit("%s usa Sukunda! A agilidade de %s foi reduzida!" % [inc.attacker.name, inc.target.name])
				else:
					log_message.emit("%s usa Sukunda! A agilidade de %s já está no patamar mínimo (-5)!" % [inc.attacker.name, inc.target.name])
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label, "debuff": "spd", "capped": capped
				})
		"provocacao", "taunt":
			if inc.target.is_alive():
				inc.target.taunted_by = inc.attacker
				inc.target.taunt_atk_bonus = true
				log_message.emit("%s usa Taunt em %s! %s é provocado a atacar %s!" % [inc.attacker.name, inc.target.name, inc.target.name, inc.attacker.name])
				for other in incoming:
					if other.attacker == inc.target and not other.is_friendly and not other.is_aoe and other.kind != Skill.Kind.STATUS:
						other.target = inc.attacker
						log_message.emit("O ataque de %s foi redirecionado para %s pelo Taunt!" % [inc.target.name, inc.attacker.name])
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label, "taunt": true
				})
		_:
			if inc.target.is_alive():
				log_message.emit("%s usa %s em %s" % [inc.attacker.name, inc.label, inc.target.name])
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label
				})


## Resolved attacks that FX still has to draw (landing or returning).
func attacks_in_flight() -> Array[Incoming]:
	var list: Array[Incoming] = []
	list.append_array(_landing)
	list.append_array(_returning)
	return list


# --- Rewards ------------------------------------------------------------------

## Credits `amount` ATB blocks to `owner` right now and queues one token per block.
func grant_atb(owner: Combatant, amount: int, source: Combatant) -> void:
	var before := owner.atb
	var extra_in_grant := 0
	for k in amount:
		var r := BattleReward.new()
		_reward_id += 1
		r.id = _reward_id
		r.owner = owner
		r.source = source
		r.delay = k * 0.09
		if before + float(k) >= Combatant.BLOCKS - 0.001:  # No room in the bar: an extra block.
			r.extra = true
			r.slot = int(owner.extra) + extra_in_grant
			extra_in_grant += 1
			owner.pending_extra += 1
		else:
			r.slot = clampi(int(floor(before + float(k))), 0, int(Combatant.BLOCKS) - 1)
			owner.pending_atb += 1
		rewards.append(r)
		reward_spawned.emit(r)
	owner.add_atb(float(amount))


func grant_burst(owner: Combatant, source: Combatant) -> void:
	var r := BattleReward.new()
	_reward_id += 1
	r.id = _reward_id
	r.kind = "burst"
	r.owner = owner
	r.source = source
	owner.pending_burst += 1
	rewards.append(r)
	reward_spawned.emit(r)


func _step_rewards(delta: float) -> void:
	for r in rewards.duplicate():
		r.t += delta
		if not r.landed and r.age() >= REWARD_FLOAT + REWARD_FLY:
			r.landed = true
			_release_pending(r)
			reward_landed.emit(r)
		if r.age() >= REWARD_FLOAT + REWARD_FLY + REWARD_IMPACT:
			rewards.erase(r)


func _release_pending(r: BattleReward) -> void:
	if r.kind == "burst":
		r.owner.pending_burst = maxi(r.owner.pending_burst - 1, 0)
	elif r.extra:
		r.owner.pending_extra = maxi(r.owner.pending_extra - 1, 0)
	else:
		r.owner.pending_atb = maxi(r.owner.pending_atb - 1, 0)


# --- Helpers ---------------------------------------------------------------

func _hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String, whiffed := false, auto_dodged := false) -> Dictionary:
	var info := {"evaded": false, "dmg": 0, "weak": false, "crit": false, "gain": 0, "whiffed": whiffed, "power": power, "skill_name": label}

	# Consumo do bônus de ATK do Taunt (D-032: consumido na primeira ação ofensiva, mesmo se errar/desviar/alvo invulnerável)
	if attacker.taunt_atk_bonus:
		attacker.taunt_atk_bonus = false
		attacker.taunted_by = null

	# Invulnerabilidade (Teleport / Dig sob o chão — D-032)
	if target.is_invulnerable_target():
		info["evaded"] = true
		log_message.emit("%s não está lá e o ataque erra completamente! (MISS!)" % target.name)
		hit_resolved.emit(attacker, target, element, info)
		return info

	# Cegueira (Sand Attack — D-032: 35% de chance de errar)
	if attacker.is_blind() and randf() < 0.35:
		info["evaded"] = true
		log_message.emit("%s erra o ataque devido à cegueira! (MISS!)" % attacker.name)
		hit_resolved.emit(attacker, target, element, info)
		return info

	# Automatic evade: disabled if the target whiffed an early manual Evade!
	if auto_dodged:
		grant_atb(target, 1, target)
		info["evaded"] = true
		log_message.emit("%s esquiva de %s automaticamente! +1 bloco" % [target.name, label])
		hit_resolved.emit(attacker, target, element, info)
		return info
	var weak := element in target.weaknesses
	var crit := whiffed or debug_roll == 3 or (debug_roll == 0 and randf() < CRIT_CHANCE)
	# Position: +10% per step in front for the attacker, -10% per step behind for the target.
	var step_mult := (1.0 + DMG_PER_STEP * maxi(attacker.pos_step, 0)) * (1.0 - DMG_PER_STEP * maxi(-target.pos_step, 0))
	var dmg := maxi(1, roundi(attacker.attack * power * (WEAKNESS_MULT if weak else 1.0) * (CRIT_MULT if crit else 1.0) * step_mult))
	var mid := BattleSpace.move_id(label)
	# D-272: contact destroys the Guard. It cuts the damage (rounded up), except Brick Break, which
	# breaks it, deals the full damage and gives the attacker 1 ATB.
	var guard_result := ""
	if target.is_guarding():
		if mid in GUARD_BREAKERS:
			guard_result = "broken"
			grant_atb(attacker, 1, target)
			target.end_guard("broken")
		else:
			guard_result = "absorbed"
			dmg = maxi(1, ceili(float(dmg) * (1.0 - GUARD_REDUCTION)))
			target.end_guard("hit")
	info["guard"] = guard_result
	target.take_damage(dmg)
	if not target.is_alive():
		_drop_returns_of(target)
	var gain := (2 if weak else 0) + (1 if crit else 0)
	if gain > 0:
		grant_atb(attacker, gain, target)
	info["dmg"] = dmg
	info["weak"] = weak
	info["crit"] = crit
	info["gain"] = gain
	log_message.emit("%s usa %s (%s) em %s (%d dano)%s" % [
		attacker.name, label, Element.name_of(element), target.name, dmg,
		(" FRAQUEZA! +2 bloco(s)" if weak else "") + (" CRÍTICO! +1 bloco" if crit else "")])

	# Efeitos de contato adicionais (D-032)
	if mid == "golpe_carate" and randf() < 0.30:
		if target.can_buff("speed", -1):
			target.buff_stat("speed", -1)
			log_message.emit("Karate Chop atinge um ponto vital! A velocidade de %s foi reduzida (-1 VEL)!" % target.name)
		else:
			log_message.emit("Karate Chop atinge um ponto vital, mas a velocidade de %s já está no patamar mínimo (-5)!" % target.name)
	elif mid == "mordida" and randf() < 0.30:
		target.stun_timer = 2.0
		log_message.emit("%s foi atordoado pela Mordida por 2 segundos!" % target.name)
		var had_interrupted := false
		for inc_check in incoming.duplicate():
			if inc_check.attacker == target:
				had_interrupted = true
				break
		if had_interrupted:
			grant_atb(attacker, 1, target)
			log_message.emit("%s interrompeu a ação de %s com o atordoamento! (+1 ATB)" % [attacker.name, target.name])
		info["interrupted"] = _interrupt_attacks_of(target, attacker, 1.8)
	else:
		info["interrupted"] = _interrupt_attacks_of(target, attacker, (1.55 if (weak or crit) else 1.0) * clampf(power, 0.85, 1.6))

	# D-238: the Fire Bullet sets the target on fire when its hit interrupts an action of the target.
	if mid == "fire_bullet" and bool(info.get("interrupted", false)) and target.is_alive():
		var was_burning := target.is_burning()
		target.apply_burn()
		info["burn"] = true
		log_message.emit("%s %s!" % [target.name, "continua queimando (Burn renovado)" if was_burning else "está queimando"])
		burn_applied.emit(target)

	hit_resolved.emit(attacker, target, element, info)
	return info


## D-238: one Burn clock step. Each tick takes BURN_DMG fixed HP; it may kill (the death animation plays, no K.O. launch).
func _tick_burn(c: Combatant, delta: float) -> void:
	if not c.is_burning() or not c.is_alive():
		return
	c.burn_clock -= delta
	while c.burn_clock <= 0.0 and c.burn_ticks_left > 0 and c.is_alive():
		c.burn_clock += BURN_INTERVAL
		c.burn_ticks_left -= 1
		c.set_meta("died_by_burn", true)  # the scene reads it from `died` (no ballistic K.O. launch)
		c.take_damage(BURN_DMG, true)
		burn_ticked.emit(c, BURN_DMG)
		log_message.emit("%s sofre %d de Burn" % [c.name, BURN_DMG])
		if not c.is_alive():
			c.clear_burn()
			_drop_returns_of(c)
			_check_end()
			return
		c.set_meta("died_by_burn", false)
	if c.is_alive() and c.burn_ticks_left <= 0:
		c.burn_clock = 0.0
		burn_ended.emit(c)


## A combatant that died stops being driven by its own attacks in flight.
func _drop_returns_of(c: Combatant) -> void:
	c.set_rest(c.pos)
	c.is_invulnerable = false
	for inc in incoming.duplicate():
		if inc.attacker == c and not inc.ghost:
			incoming.erase(inc)
			attack_cancelled.emit(inc)
	for inc in _landing.duplicate():
		if inc.attacker == c and not inc.ghost:
			_landing.erase(inc)
			attack_cancelled.emit(inc)
	for inc in _returning.duplicate():
		if inc.attacker == c and not inc.ghost:
			_returning.erase(inc)
			attack_cancelled.emit(inc)


## Being hit before its own strike lands stops whatever `c` was doing: still winding up
## (cancelled) or already on its way (it stops where it is, never hits, then recovers).
## Returns true when it really stopped an action of `c` (D-236: Fire Bullet draws another impact then; nothing else reads it).
func _interrupt_attacks_of(c: Combatant, hitter: Combatant, force: float) -> bool:
	var stopped := false
	if is_attacking(c):
		_clear_queued(c)  # Whatever it had lined up after this action is gone with it (D-161).
	for inc in incoming.duplicate():
		if inc.attacker == c and not inc.ghost:
			incoming.erase(inc)
			inc.interrupted = true
			stopped = true
			log_message.emit("%s é interrompido!" % c.name)
			attack_cancelled.emit(inc)
	# The knockback it takes: away from the hit, or straight back from its own facing.
	var own_back := -Vector3(sin(c.yaw), 0.0, cos(c.yaw))
	var hit_push := BattleSpace.flat_dir(hitter.pos, c.pos)
	var back := hit_push if (c.pos.distance_to(hitter.pos) > 0.25 and hit_push.dot(own_back) > 0.15) else own_back
	var push := back.normalized() * clampf(1.5 * force, 1.1, 2.4)
	for inc in _landing.duplicate():
		if inc.attacker != c or inc.impacted or inc.interrupted or inc.ghost:
			continue
		if inc.kind == Skill.Kind.PROJECTILE and inc.phase == Phase.TRAVEL:
			continue  # Projectile already fired and in flight: hitting the caster no longer destroys it.
		_landing.erase(inc)
		inc.interrupted = true
		stopped = true
		if not c.is_alive():
			c.set_rest(c.pos)  # It falls where it is: no hop home for a body.
			inc.motion = "cast"
			inc.plan = [[Phase.RETURN, 0.05]]
			inc.plan_i = 0
			inc.phase = Phase.RETURN
			inc.phase_time = 0.0
		elif inc.motion == "cast":
			inc.plan = [[Phase.RETURN, 0.55 + AttackMotion.HIT_STUN_EXTRA]]
			inc.plan_i = 0
			inc.phase = Phase.RETURN
			inc.phase_time = 0.0
		else:
			AttackMotion.begin_hit_return(inc, push)
		attack_interrupted.emit(inc)
		if not _returning.has(inc):
			_returning.append(inc)
		log_message.emit("%s é interrompido!" % c.name)
		attack_phase.emit(inc, inc.phase)
	for inc in _returning.duplicate():
		if inc.attacker == c and inc.phase == Phase.RETURN and not inc.interrupted and not inc.ghost and inc.kind == Skill.Kind.MELEE:
			inc.interrupted = true
			stopped = true
			if inc.motion == "cast":
				inc.plan = [[Phase.RETURN, 0.55 + AttackMotion.HIT_STUN_EXTRA]]
				inc.plan_i = 0
				inc.phase_time = 0.0
			else:
				AttackMotion.begin_hit_return(inc, push)
			attack_interrupted.emit(inc)
	return stopped


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
	# Winners caught mid-run or mid-swing hop home from where they are; nothing else lands.
	for inc in _landing.duplicate():
		if inc.attacker.is_alive() and AttackMotion.carries(inc):
			AttackMotion.begin_plain_return(inc, inc.attacker.pos)
			inc.impacted = true
			inc.interrupted = true
			inc.plan_i = 0
			inc.phase = Phase.RETURN
			inc.phase_time = 0.0
			_returning.append(inc)
			attack_phase.emit(inc, Phase.RETURN)
	_landing.clear()
	_update_positions()
	for r in rewards:
		_release_pending(r)
	rewards.clear()
	for c in party + enemies:
		c.engaged_with = null
		c.in_battle = false
		c.end_guard("battle_end")
		_clear_queued(c)
		if c.is_alive():
			c.clear_buffs()  # The drawing goes back to normal too (D-158); a launched body keeps its own (D-166).
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)
