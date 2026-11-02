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
signal attack_interrupted(inc)  ## A hit stopped an attack on its way: BattleFx fills its recovery plan.
signal reward_spawned(reward)
signal reward_landed(reward)

const Phase = Incoming.Phase

const REWARD_FLOAT := 0.6  ## Seconds a reward token floats over where it was earned.
const REWARD_FLY := 0.25  ## Seconds it flies to the HUD.
const REWARD_IMPACT := 0.46  ## Seconds of impact effect at the slot.
const SKILL_BLOCKS := 2.0
const ITEM_BLOCKS := 1.0
const EVADE_BLOCKS := 2.0  ## Manual Evade (was 3 in the GDD; see report).
const AUTO_DODGE_CHANCE := 0.10  ## Automatic evade chance per hit, for every target.
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
var _freeze_left := 0.0  ## Hit-stop: the whole battle clock holds still for this many seconds.
var _evade := BattleEvade.new(self)
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
	_returning.clear()
	rewards.clear()
	running = true
	log_message.emit("Batalha iniciada!")


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
	for c in party + enemies:
		if not is_winding_up(c):  # ATB stays locked until the action finishes.
			c.tick(delta)
	for c in party + enemies:
		if c.step_t < 1.0:
			c.step_t = minf(c.step_t + delta / STEP_TIME, 1.0)
	_update_positions()
	_run_ai()
	_resolve_incoming(delta)
	_step_attacks(delta)
	_step_rewards(delta)
	_evade.step_engage(delta)
	state_changed.emit()


# --- Actions (same for the player, allies and enemies) -----------------------

func use_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not actor.is_alive() or is_winding_up(actor) or not actor.can_pay(skill.cost):
		return false
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
	# After a Perfect Evade the next attack is immediate: no wind-up, no preparation.
	# Instant (no wind-up, no travel) only while engaged next to the opponent it interrupted;
	# back at its original spot an attack is prepared and travels like any other.
	inc.instant = actor.engaged_with != null and not skill.is_friendly
	actor.counter_ready = false
	if actor.engaged_with != null and not skill.is_friendly:
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
	if to < -STEP_MAX or to > STEP_MAX or c.blocks() < STEP_COST:
		return false
	if c.engaged_with != null or c.step_t < 1.0 or is_winding_up(c):
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
		var sk := _pick_skill(c)
		var target := c if sk.is_friendly else (c.engaged_with if c.engaged_with != null and c.engaged_with.is_alive() else _first_alive(foes))
		if target == null:
			return
		use_skill(c, sk, target)


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
		inc.auto_dodged = inc.kind != Skill.Kind.STATUS and not inc.dodged and not inc.whiffed and randf() < AUTO_DODGE_CHANCE
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
				AttackMotion.on_phase(inc)
				attack_phase.emit(inc, inc.phase)
				_roll_ai_evade(inc)
		AttackMotion.update(inc)
		AttackMotion.update_projectile(inc)
		if inc.can_evade_now() and inc.ai_evade_at >= 0.0 and inc.phase_time >= inc.ai_evade_at:
			inc.ai_evade_at = -1.0
			if inc.target.is_alive() and inc.target.blocks() >= EVADE_BLOCKS and not inc.evade_tried:
				try_evade(inc.target, inc)
		if inc.plan_i >= inc.plan.size():
			if not inc.impacted:
				_strike(inc)
			inc.phase = Phase.DONE
			_returning.erase(inc)
			if inc.motion != "engaged":
				inc.attacker.clear_rest()  # Back at its step spot.
				inc.attacker.pos = inc.attacker.rest_pos()
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
	if inc.dodged:
		log_message.emit("%s esquivou de %s!" % [inc.target.name, inc.label])
	elif inc.attacker.is_alive() and inc.kind == Skill.Kind.STATUS:
		_execute_status_move(inc)
	elif inc.target.is_alive() and (inc.attacker.is_alive() or inc.kind == Skill.Kind.PROJECTILE):
		_hit(inc.attacker, inc.target, inc.power, inc.element, inc.label, inc.whiffed, inc.auto_dodged)
		if inc.is_aoe:
			var foes: Array[Combatant] = enemies if inc.target.is_player else party
			for foe in foes:
				if foe.is_alive() and foe != inc.target:
					_hit(inc.attacker, foe, inc.power * 0.85, inc.element, inc.label, inc.whiffed, false)


func _execute_status_move(inc: Incoming) -> void:
	var mid := BattleSpace.move_id(inc.label)
	match mid:
		"media":
			var team: Array[Combatant] = party if inc.attacker.is_player else enemies
			log_message.emit("%s usa Media! A equipe recupera HP!" % inc.attacker.name)
			for ally in team:
				if ally.is_alive():
					var heal_amount := maxi(12, roundi(ally.max_hp * 0.40))
					var before := ally.hp
					ally.heal(heal_amount)
					healed.emit(inc.attacker, ally, ally.hp - before)
					hit_resolved.emit(inc.attacker, ally, inc.element, {
						"status": true, "evaded": false, "dmg": 0, "weak": false,
						"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
						"skill_name": inc.label, "heal": true
					})
		"tarukaja":
			var team: Array[Combatant] = party if inc.attacker.is_player else enemies
			log_message.emit("%s usa Tarukaja! O ataque da equipe aumentou!" % inc.attacker.name)
			for ally in team:
				if ally.is_alive():
					ally.buff_stat("atk", 1)
					hit_resolved.emit(inc.attacker, ally, inc.element, {
						"status": true, "evaded": false, "dmg": 0, "weak": false,
						"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
						"skill_name": inc.label, "buff": "atk"
					})
		"rakunda":
			if inc.target.is_alive():
				inc.target.buff_stat("def", -1)
				log_message.emit("%s usa Rakunda! A defesa de %s foi reduzida!" % [inc.attacker.name, inc.target.name])
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label, "debuff": "def"
				})
		"sukunda":
			if inc.target.is_alive():
				inc.target.buff_stat("speed", -1)
				log_message.emit("%s usa Sukunda! A agilidade de %s foi reduzida!" % [inc.attacker.name, inc.target.name])
				hit_resolved.emit(inc.attacker, inc.target, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label, "debuff": "spd"
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

func _hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String, whiffed := false, auto_dodged := false) -> void:
	var info := {"evaded": false, "dmg": 0, "weak": false, "crit": false, "gain": 0, "whiffed": whiffed, "power": power, "skill_name": label}
	# Automatic evade: disabled if the target whiffed an early manual Evade!
	if auto_dodged:
		grant_atb(target, 1, target)
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
	_interrupt_attacks_of(target, attacker, (1.55 if (weak or crit) else 1.0) * clampf(power, 0.85, 1.6))
	hit_resolved.emit(attacker, target, element, info)


## A combatant that died while recovering from its own attack stops being driven by it.
func _drop_returns_of(c: Combatant) -> void:
	for inc in _returning.duplicate():
		if inc.attacker == c and not inc.ghost:
			_returning.erase(inc)
			attack_cancelled.emit(inc)


## Being hit before its own strike lands stops whatever `c` was doing: still winding up
## (cancelled) or already on its way (it stops where it is, never hits, then recovers).
func _interrupt_attacks_of(c: Combatant, hitter: Combatant, force: float) -> void:
	for inc in incoming.duplicate():
		if inc.attacker == c and not inc.ghost:
			incoming.erase(inc)
			inc.interrupted = true
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
		if inc.motion == "cast":
			inc.plan = [[Phase.RETURN, 0.55]]
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
			if inc.motion == "cast":
				inc.plan = [[Phase.RETURN, 0.55]]
				inc.plan_i = 0
				inc.phase_time = 0.0
			else:
				AttackMotion.begin_hit_return(inc, push)
			attack_interrupted.emit(inc)


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
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)
