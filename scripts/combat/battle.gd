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
signal evade_mistimed(actor: Combatant, inc)  ## D-1015: a dodge pressed outside the valid window (it did not dodge)
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
signal mp_regenerated(actor: Combatant, amount: int)  ## D-1062: a unit recovered MP (the amount really gained)
signal armor_changed(actor: Combatant, state: String)  ## D-1026: "started", "extended", "hit", "expired" or "battle_end".
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
const AI_GUARD_CHANCE := 0.25  ## D-272/D-116: chance an AI target guards when an attack is declared on it.


func _init() -> void:
	_reward_queue = BattleRewards.new(self)
	_badges = BattleBadges.new(self)

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
const PRELUDE_GAP := 0.25  ## D-988: the Evade window closes this long before the contact (the attacker's rise)
const PERFECT_WINDOW := 0.25  ## D-283: the Evade only works in the last seconds before the hit, inside the strike, and is always perfect (D-027, D-030).
const COUNTER_WINDUP := 0.3  ## D-284: wind-up of the counter-attack after a perfect Evade, whatever the move (a status move stays instant).
const AUTO_DODGE_CHANCE := 0.10  ## Automatic evade chance per hit, for every target.
var debug_roll := 0  ## Sala de VFX (debug): 0 = sorteio normal, 1 = acerto sem crítico, 2 = esquiva, 3 = acerto crítico.
const STATUS_WINDUP := 0.5  ## Status moves prepare faster, with the engine paused (D-031).
const STATUS_VFX_TAIL := 1.0  ## Seconds the engine stays paused after the status effect is applied.
const ARMORED_BULK := "armored_bulk"  ## D-1026: SELF status move, instant wind-up.
const ARMORED_BULK_PAUSE := 1.5  ## D-1026: kept for FX timing; the rule reads MoveData.status_pause.
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
var _reward_queue: BattleRewards
var rewards: Array[BattleReward]:
	get:
		return _reward_queue.items
var _badges: BattleBadges
var _landing: Array[Incoming] = []  ## Resolved attacks whose strike has not landed yet.
var _returning: Array[Incoming] = []  ## Struck already: only the return is left to play.
var _status_pause: Incoming = null  ## A status move is being performed: only it runs (D-031).
var _status_tail := -1.0
var _status_total := 0.0  ## D-1026: when > 0 the move fixes the TOTAL length of the pause (no default tail).
var _status_elapsed := 0.0
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
		if not c.armor_changed.is_connected(_on_armor_changed):
			c.armor_changed.connect(_on_armor_changed)  # D-1026
		if not c.mp_regenerated.is_connected(_on_mp_regenerated):
			c.mp_regenerated.connect(_on_mp_regenerated)  # D-1062
	_landing.clear()
	_ai.reset()
	_status_pause = null
	_returning.clear()
	rewards.clear()
	_badges.clear()
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
	_badges.step(delta)
	if not running:
		if not _returning.is_empty():
			_step_attacks(delta)  # The winners' leaps back still play out after the last hit.
		return
	if _status_pause != null:
		_step_status_pause(delta)
		state_changed.emit()
		return
	for c in party + enemies:
		c.tick_shield(delta)  # Drain Spear / Badge Steal: the shield badge has its own clock.
		c.tick_magic_immunity(delta)
		c.tick_armor(delta)  # D-1026: counts down also during a Guard; frozen by a status pause like every duration
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
	_reward_queue.step(delta)
	_evade.step_engage(delta)
	state_changed.emit()


# --- Actions (same for the player, allies and enemies) -----------------------

func use_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not actor.is_alive() or actor.is_stunned() or actor.is_guarding() or is_winding_up(actor) or not actor.can_pay_skill(skill):
		return false
	if _status_pause != null:
		return false  # The engine is paused by a status move (D-031).
	if (skill.data != null and skill.data.has_tag(&"self_status")) or BattleSpace.move_id(skill.display_name) == ARMORED_BULK:
		target = actor  # D-1026: SELF
	elif skill.is_friendly:
		if target == null or not target.is_alive() or target.is_player != actor.is_player:
			target = actor
	else:
		if target == null or not target.is_alive():
			return false
		if actor.engaged_with != null and target != actor.engaged_with:
			return false  # Engaged: it only acts on the opponent it is standing next to.
	actor.pay_skill(skill)
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
	# D-1079: one stable move id + canonical sheet for the planner, rules and AI.
	inc.move_id = BattleSpace.move_id(skill.display_name)
	inc.move_data = MoveCatalog.get_move(StringName(inc.move_id))
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
	var w_override := skill.windup if skill.windup >= 0.0 else (STATUS_WINDUP if inc.kind == Skill.Kind.STATUS else WINDUP)
	inc.total_windup = ((0.0 if inc.kind == Skill.Kind.STATUS else COUNTER_WINDUP) if inc.instant else w_override)  # D-284
	inc.time_left = inc.total_windup

	incoming.append(inc)
	if inc.kind == Skill.Kind.STATUS:
		_status_pause = inc  # From the wind-up until its effect has played (D-031).
		_status_tail = -1.0
		var status_pause := inc.move_data.status_pause if inc.move_data != null and inc.move_data.status_pause >= 0.0 else 0.0
		if status_pause <= 0.0 and BattleSpace.move_id(inc.label) == ARMORED_BULK:
			status_pause = ARMORED_BULK_PAUSE  # compatibility for Skills without MoveData
		_status_total = status_pause  # D-1026
		_status_elapsed = 0.0
		status_pause_started.emit(inc)
	log_message.emit("%s prepara %s em %s..." % [actor.name, skill.display_name, target.name])
	_planner.redirect_if_blocked(inc)
	attack_telegraphed.emit(inc)
	_roll_ai_guard(inc)
	return true


## A player's move: it starts now if it can; otherwise it waits in the one slot, replacing
## whatever was there. Nothing is paid until it starts (D-161).
func request_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not running or not actor.is_alive() or actor.is_stunned() or actor.is_guarding() or actor.mp < skill.mp_cost:
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
	if actor.is_stunned() or actor.is_guarding() or not actor.can_pay_skill(skill):
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


func _on_mp_regenerated(actor: Combatant, amount: int) -> void:
	mp_regenerated.emit(actor, amount)


func _on_armor_changed(actor: Combatant, state: String) -> void:
	armor_changed.emit(actor, state)


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
	var move_data: MoveData = skill.data
	if move_data == null:
		move_data = MoveCatalog.get_move(StringName(BattleSpace.move_id(skill.display_name)))
	var flat := move_data.magic_flat if move_data != null else -1
	if flat >= 0:
		# Drain Spear: magic damage 5 + MAG, mitigated by SPI (never by DEF/crit/weakness).
		return maxi(1, flat + attacker.mag - target.spi)
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
		_roll_ai_dodge(inc)  # D-1007
		_tick_ai_dodge(inc, delta)
		inc.time_left -= delta
		if inc.time_left > 0.0:
			continue
		incoming.erase(inc)
		if move_is_untargetable(inc):
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
				if inc.phase == Phase.STRIKE:
					if move_is_untargetable(inc):
						inc.attacker.is_invulnerable = false
				elif inc.phase == Phase.RETURN:
					if move_teleports(inc):
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
		_tick_ai_dodge(inc, delta)  # D-1007: the AI dodges at its random moment (wind-up to contact)
		if inc.plan_i >= inc.plan.size():
			if not inc.impacted:
				_strike(inc)
			inc.phase = Phase.DONE
			if move_is_untargetable(inc):
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
	_status_elapsed += delta
	if incoming.has(inc):
		_resolve_incoming(delta, inc)
	elif _landing.has(inc) or _returning.has(inc):
		_step_attacks(delta, inc)
	elif _status_tail < 0.0:
		# Done (or cancelled): let its effect finish. A move with a fixed total pause keeps the engine paused up to that total.
		_status_tail = maxf(_status_total - _status_elapsed, 0.01) if _status_total > 0.0 else STATUS_VFX_TAIL
	else:
		_status_tail -= delta
		if _status_tail <= 0.0:
			_status_pause = null
			status_pause_ended.emit(inc)


## A computer-controlled target reacts on the way in with a chance equal to its speed.
## D-1007/D-1014: an AI target decides here (chance = SPD) whether it will Evade; the moment is a random one INSIDE the valid window.
func _roll_ai_dodge(inc: Incoming) -> void:
	if inc.ai_dodge_rolled:
		return
	inc.ai_dodge_rolled = true
	var t := inc.target
	if inc.ghost or inc.is_friendly or inc.kind == Skill.Kind.STATUS or t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if randf() < t.speed:
		inc.ai_dodge_in = 0.0  # D-1014: it will try; the moment is picked once the valid window opens


func _tick_ai_dodge(inc: Incoming, delta: float) -> void:
	if inc.ai_dodge_in < 0.0:
		return  # It will not dodge.
	# D-1014: the AI only dodges inside the valid window (physical: the prelude; projectile/area: the last 0.25 s).
	if not inc.can_evade_now():
		return
	if not inc.ai_dodge_armed:
		inc.ai_dodge_armed = true
		inc.ai_dodge_in = randf_range(0.0, maxf(inc.window_left() - 0.04, 0.0))
		return
	inc.ai_dodge_in -= delta
	if inc.ai_dodge_in <= 0.0:
		inc.ai_dodge_in = -1.0
		_ai.try_evade(inc)


func _roll_ai_evade(inc: Incoming) -> void:
	return  # D-1007: replaced by _roll_ai_dodge (random moment from the wind-up to the contact)
	if inc.phase != inc.impact_phase or inc.ghost or inc.is_friendly:
		return  # (a buff or a heal is not something to dodge)
	var t := inc.target
	if t == party[0] or t.react_policy != Combatant.React.EVADE:
		return
	if randf() < t.speed:
		var end_at := minf(PRELUDE_GAP, maxf(inc.phase_len() - PERFECT_WINDOW, 0.0))
		inc.ai_evade_at = maxf(inc.phase_len() - end_at - randf_range(0.03, PERFECT_WINDOW - 0.03), 0.0)  # D-988: inside the rise window




func _ensure_move_data(inc: Incoming) -> void:
	if inc.move_id.is_empty():
		inc.move_id = BattleSpace.move_id(inc.label)
	if inc.move_data == null:
		inc.move_data = MoveCatalog.get_move(StringName(inc.move_id))


func move_is_untargetable(inc: Incoming) -> bool:
	if inc.move_data != null and inc.move_data.untargetable:
		return true
	return BattleSpace.move_id(inc.label) in ["investida_subterranea", "investida_escavadora", "teleporte_rapido"]


func move_teleports(inc: Incoming) -> bool:
	if inc.move_data != null and inc.move_data.teleport:
		return true
	return BattleSpace.move_id(inc.label) == "teleporte_rapido"


func _strike(inc: Incoming) -> void:
	_ensure_move_data(inc)
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
		var behavior := MoveBehaviorRegistry.get_behavior(inc.move_id)
		if behavior.on_strike(inc, self):
			return
		var vpush := true
		if inc.skill != null:
			vpush = inc.skill.pushes_visually()  # D-1073: projectile does not shove; melee/CAST does.
		elif inc.kind == Skill.Kind.MELEE or inc.kind == Skill.Kind.CAST:
			vpush = true
		else:
			vpush = false
		var hit_info: Dictionary
		if behavior.has_before_hit():
			hit_info = behavior.before_hit(inc, self)
		else:
			var hit_opts := {"visual_push": vpush, "move_data": inc.move_data}
			if inc.bounce_no_reward:
				# D-1025: a bounce is a normal hit but never grants extra ATB/Burst, and the FX must not treat
				# it as the main beam's impact.
				hit_opts = {"no_gain": true, "bounce": true, "bounce_index": inc.bounce_index, "visual_push": vpush, "move_data": inc.move_data}
			hit_info = apply_hit(inc.attacker, inc.target, inc.power, inc.element, inc.label, inc.whiffed, inc.auto_dodged, hit_opts)
		var foes: Array[Combatant] = enemies if inc.attacker.is_player else party  # The attacker's opponents.
		if inc.is_aoe:
			for foe in foes:
				if foe.is_alive() and foe != inc.target:
					apply_hit(inc.attacker, foe, inc.power * 0.85, inc.element, inc.label, inc.whiffed, false, {"visual_push": vpush, "move_data": inc.move_data})
		elif (inc.move_data != null and inc.move_data.aoe_on_contact) or (inc.skill != null and inc.skill.aoe_on_contact):
			# D-032: Se o alvo principal foi atingido (não esquivou / não invulnerável), aliados sofrem dano total (1.6x)
			if not hit_info.get("evaded", false):
				for foe in foes:
					if foe.is_alive() and foe != inc.target:
						apply_hit(inc.attacker, foe, inc.power, inc.element, inc.label, inc.whiffed, false, {"visual_push": vpush, "move_data": inc.move_data})
		behavior.on_hit(inc, self, hit_info)


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
	_ensure_move_data(inc)
	var behavior := MoveBehaviorRegistry.get_behavior(inc.move_id)
	if behavior.on_status(inc, self):
		return
	# Fallback for status Moves that do not declare a behavior yet.
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
## The token flight lives in BattleRewards (Etapa 4); Battle keeps this API.
func grant_atb(owner: Combatant, amount: int, source: Combatant) -> void:
	_reward_queue.grant_atb(owner, amount, source)


func grant_burst(owner: Combatant, source: Combatant) -> void:
	_reward_queue.grant_burst(owner, source)


# --- Helpers ---------------------------------------------------------------

## Removes every positive badge from `target` and queues it for `attacker` after the 0.30 s
## transfer. Debuffs are never stolen. Returns one entry per badge (also used by the VFX).
## The transfer flight lives in BattleBadges (Etapa 4); Battle keeps this API.
func steal_badges(attacker: Combatant, target: Combatant) -> Array:
	return _badges.steal(attacker, target)


func _hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String, whiffed := false, auto_dodged := false, opts := {}) -> Dictionary:
	var info := {"evaded": false, "dmg": 0, "weak": false, "crit": false, "gain": 0, "whiffed": whiffed, "power": power, "skill_name": label}
	info["visual_push"] = bool(opts.get("visual_push", true))  # D-1073: the contact FX may skip the shove.
	if bool(opts.get("bounce", false)):
		# D-1025: a bounce hit is a normal hit for weakness/crit/evade, but the FX and the reward rules can tell it
		# apart from the main beam.
		info["bounce"] = true
		info["bounce_index"] = int(opts.get("bounce_index", 0))

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
	# Move-authored step between a confirmed contact and the damage (Drain Spear's Badge Steal).
	if opts.has("before_damage"):
		var before: Callable = opts["before_damage"]
		if before.is_valid():
			before.call()
	var magic_flat := int(opts.get("magic_flat", -1))
	if magic_flat >= 0 and target.is_magic_immune():
		info["immune"] = true
		log_message.emit("%s é imune ao dano mágico!" % target.name)
		hit_resolved.emit(attacker, target, element, info)
		return info
	var weak := false
	var crit := false
	var dmg := 0
	if magic_flat >= 0:
		# Drain Spear: 5 + MAG - SPI, minimum 1. No weakness, crit or position multiplier.
		dmg = maxi(1, magic_flat + attacker.mag - target.spi)
		info["magic"] = true
	else:
		weak = element in target.weaknesses
		crit = whiffed or debug_roll == 3 or (debug_roll == 0 and randf() < CRIT_CHANCE)
		# Position: +10% per step in front for the attacker, -10% per step behind for the target.
		var step_mult := (1.0 + DMG_PER_STEP * maxi(attacker.pos_step, 0)) * (1.0 - DMG_PER_STEP * maxi(-target.pos_step, 0))
		dmg = maxi(1, roundi(attacker.attack * power * (WEAKNESS_MULT if weak else 1.0) * (CRIT_MULT if crit else 1.0) * step_mult))
	var hit_move_data: MoveData = opts.get("move_data", null)
	var guard_break := false
	if hit_move_data != null:
		guard_break = hit_move_data.has_tag(&"guard_break")
	else:
		guard_break = BattleSpace.move_id(label) == "quebra_telha"  # compatibility for Skills without MoveData
	# D-272: contact destroys the Guard. It cuts the damage (rounded up), except Brick Break, which
	# breaks it, deals the full damage and gives the attacker 1 ATB.
	var guard_result := ""
	if target.is_guarding():
		if guard_break:
			guard_result = "broken"
			grant_atb(attacker, 1, target)
			target.end_guard("broken")
		else:
			guard_result = "absorbed"
			dmg = maxi(1, ceili(float(dmg) * (1.0 - GUARD_REDUCTION)))
			target.end_guard("hit")
	info["guard"] = guard_result
	# D-1026: ARMOR. The Guard has priority and keeps the badge. Otherwise the first contact of a Move destroys it: the
	# damage is normal, but there is no interruption, no contact effect and no knockback (the K.O. launch stays).
	var armor_result := ""
	if target.is_armored() and guard_result == "":
		armor_result = "hit"
		target.end_armor("hit")
	info["armor"] = armor_result
	# Badge Steal shield: a reserve absorbs before HP. The Drain Spear already removed the
	# target's shield before this point, so the stolen shield never absorbs its own hit.
	var shield_absorbed := 0
	if target.is_shielded():
		shield_absorbed = target.absorb_shield(dmg)
		dmg -= shield_absorbed
		info["shield_absorbed"] = shield_absorbed
		if target.shield_hp <= 0:
			target.end_shield("broken")
	if shield_absorbed > 0:
		info["shield_hit"] = true
	if dmg > 0:
		target.take_damage(dmg, bool(opts.get("bypass_def", false)))
	if not target.is_alive():
		_drop_returns_of(target)
	var gain := 0 if bool(opts.get("no_gain", false)) else (2 if weak else 0) + (1 if crit else 0)
	if gain > 0:
		grant_atb(attacker, gain, target)
	info["dmg"] = dmg
	info["weak"] = weak
	if weak and not target.is_player:  # D-981: a weakness hit reveals the species' elements
		var gst: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameState") if Engine.get_main_loop() is SceneTree else null
		if gst != null:
			gst.discovered_species[gst.species_key(target)] = true
	info["crit"] = crit
	info["gain"] = gain
	var element_name := "mágico" if magic_flat >= 0 else Element.name_of(element)
	log_message.emit("%s usa %s (%s) em %s (%d dano)%s%s" % [
		attacker.name, label, element_name, target.name, dmg,
		(" [escudo -%d]" % shield_absorbed if shield_absorbed > 0 else ""),
		(" FRAQUEZA! +2 bloco(s)" if weak else "") + (" CRÍTICO! +1 bloco" if crit else "")])

	# Efeitos de contato adicionais (D-032/D-1005/D-977/D-238), por Move (D-1079).
	if armor_result != "":
		info["interrupted"] = false  # D-1026: ARMOR absorbs the interruption and every contact effect
		log_message.emit("A ARMOR de %s absorve o impacto (sem interrupção nem efeitos de contato)!" % target.name)
	else:
		var behavior_id := hit_move_data.id if hit_move_data != null else StringName(BattleSpace.move_id(label))
		MoveBehaviorRegistry.get_behavior(behavior_id).on_contact(attacker, target, info, self)

	hit_resolved.emit(attacker, target, element, info)
	return info


## Public wrappers used by MoveBehavior (D-1079, Etapa 2). They keep the same
## code paths the old inline move-specific branches used.
func apply_hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String, whiffed := false, auto_dodged := false, opts := {}) -> Dictionary:
	return _hit(attacker, target, power, element, label, whiffed, auto_dodged, opts)


func interrupt_attacks_of(c: Combatant, hitter: Combatant, force: float) -> bool:
	return _interrupt_attacks_of(c, hitter, force)


## Used by Tidal Surge's behavior to register a bounce without owning the
## Battle's landing list (D-1079).
func add_landing(inc: Incoming) -> void:
	_landing.append(inc)


func roll_ai_for(inc: Incoming) -> void:
	_roll_ai_evade(inc)
	_roll_ai_dodge(inc)


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
		_reward_queue.release_pending(r)
	rewards.clear()
	for c in party + enemies:
		c.engaged_with = null
		c.in_battle = false
		c.end_guard("battle_end")
		c.end_armor("battle_end")
		_clear_queued(c)
		if c.is_alive():
			c.clear_buffs()  # The drawing goes back to normal too (D-158); a launched body keeps its own (D-166).
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)


## Snapshot e Rollback em memória e avanço determinístico por ticks para agentes de IA (D-1042 / D-1044).
func save_state() -> Dictionary:
	var units_state := {}
	for c in party + enemies:
		units_state[c] = c.save_state()
	return {
		"running": running,
		"debug_roll": debug_roll,
		"freeze_left": _freeze_left,
		"units": units_state,
	}


func restore_state(state: Dictionary) -> void:
	running = bool(state.get("running", running))
	debug_roll = int(state.get("debug_roll", debug_roll))
	_freeze_left = float(state.get("freeze_left", 0.0))
	incoming.clear()
	_landing.clear()
	_returning.clear()
	_status_pause = null
	var units_state: Dictionary = state.get("units", {})
	for c in party + enemies:
		if units_state.has(c):
			c.restore_state(units_state[c])
	state_changed.emit()


func step_ticks(ticks: int, fixed_dt := 1.0 / 60.0) -> void:
	for _i in maxi(0, ticks):
		_process(fixed_dt)
