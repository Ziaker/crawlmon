class_name BattleAI
extends RefCounted
## What computer-controlled combatants decide, allies and enemies alike (D-021, D-111, D-112,
## D-114, D-115, D-168). A helper of Battle: it reads Battle's state and acts through the same
## actions the player uses. The weights below are a first calibration (D-116).

const NatureData = preload("res://scripts/data/nature_data.gd")

const THINK_EVERY := 0.25  ## Seconds between decisions of one combatant.
const IDLE_RESERVE := 1.0  ## Blocks an evader keeps after acting when nothing threatens it.
const CLOSE_TO_BEST := 0.7  ## Moves scoring at least this share of the best one may be picked.
const REPEAT_MULT := 0.6  ## The move it used last time is worth less, so it varies.
const COST_WEIGHT := 0.35  ## Each block a move costs divides its value by this much more.
const KO_BONUS := 40.0
const WEAK_BONUS := 15.0  ## A weakness also pays the attacker ATB.
const INTERRUPT_BONUS := 18.0
const CONTACT_BONUS := {"mordida": 8.0, "golpe_carate": 6.0}  ## fallback for Skills without MoveData
const STRIKE_TIME := 0.7  ## About how long a melee strike takes after the run.
const UNRESOLVED_ETA := 0.7  ## About how long an attack takes to land once its wind-up ends.
const MIN_MISSING_TO_HEAL := 0.2  ## Below this share of missing HP, healing is not worth a turn.
const MIN_TARGET_HP_TO_DEBUFF := 0.3  ## A nearly dead target is finished, not weakened.

var b: Battle
var _think_left: Dictionary = {}  ## Combatant -> seconds until its next decision.
var _last_used: Dictionary = {}  ## Combatant -> display name of its last move.
var _plans: Dictionary = {}  ## Combatant -> the move it is saving ATB for ({skill or item, target, value}).


func _init(p_battle: Battle) -> void:
	b = p_battle


func reset() -> void:
	_think_left.clear()
	_last_used.clear()
	_plans.clear()


func run(delta: float) -> void:
	for c in b.party + b.enemies:
		if c == b.party[0] or not c.is_alive():
			continue
		if c.tactic_pos != c.pos_step and b.step(c, signi(c.tactic_pos - c.pos_step)):
			continue
		if c.is_stunned() or not b.can_start_now(c):
			continue
		_think_left[c] = float(_think_left.get(c, 0.0)) - delta
		if _think_left[c] > 0.0:
			continue
		_think_left[c] = THINK_EVERY
		if c.act_policy == Combatant.Act.HOLD:
			_hold(c)
		else:
			_decide(c)


## "Segurar" never attacks, but still drinks when badly hurt.
func _hold(c: Combatant) -> void:
	if c.hp <= c.max_hp * Battle.AI_HEAL_BELOW and c.can_pay(Battle.ITEM_BLOCKS):
		var potion := _first_consumable(c)
		if potion != null:
			b.use_item(c, potion, c)


## It picks what it wants first and saves ATB for it, instead of spending on whatever it can
## already pay. The plan is kept until it can be done or stops making sense.
func _decide(c: Combatant) -> void:
	var plan: Dictionary = _plans.get(c, {})
	if plan.is_empty() or not _still_worth_it(c, plan):
		plan = _new_plan(c)
		_plans[c] = plan
	if plan.is_empty():
		return
	var ko := _affordable_knock_out(c, plan["target"]) if not b.same_team(c, plan["target"]) else null
	if ko != null:
		_perform(c, ko, plan["target"])
		return
	if plan.has("item"):
		_plans.erase(c)
		b.use_item(c, plan["item"], c)
	elif _may_spend(c, plan["skill"], plan["target"]):
		_perform(c, plan["skill"], plan["target"])


func _new_plan(c: Combatant) -> Dictionary:
	var target := _pick_target(c)
	if target == null:
		return {}
	var options: Array[Dictionary] = []
	for skill in _moves_of(c):
		if skill.target_mode == MoveData.TargetMode.DUAL:
			continue  # D-1200: the dual-target structure exists, but its effects (and so its AI value) are undefined.
		var aim := target
		if skill.target_mode == MoveData.TargetMode.SINGLE_ALLY:
			aim = pick_ally_target(c, skill)
		var value := score_move(c, skill, aim)
		if value > 0.0:
			options.append({"skill": skill, "target": aim, "value": value * (REPEAT_MULT if _last_used.get(c, "") == skill.display_name else 1.0)})
	var potion := _first_consumable(c)
	if potion != null and c.can_pay(Battle.ITEM_BLOCKS) and c.blocks() - Battle.ITEM_BLOCKS >= _reserve(c):
		var value := score_potion(c, potion)
		if value > 0.0:
			options.append({"item": potion, "target": target, "value": value})
	return _weighted_pick(options)


func _still_worth_it(c: Combatant, plan: Dictionary) -> bool:
	var target: Combatant = plan["target"]
	if not target.is_alive() or (c.engaged_with != null and c.engaged_with != target and not b.same_team(c, target)):
		return false
	return plan.has("item") or score_move(c, plan["skill"], target) > 0.0


func _affordable_knock_out(c: Combatant, target: Combatant) -> Skill:
	for skill in _moves_of(c):
		if skill.kind != Skill.Kind.STATUS and not skill.is_friendly and c.can_pay_skill(skill) \
				and score_move(c, skill, target) > 0.0 and _damage_to(c, skill, target) >= target.hp:
			return skill
	return null


func _moves_of(c: Combatant) -> Array[Skill]:
	var moves: Array[Skill] = [Skill.basic()]
	if c.act_policy == Combatant.Act.SKILL:
		moves.append_array(c.skills)
	return moves


func _perform(c: Combatant, skill: Skill, target: Combatant) -> void:
	_plans.erase(c)
	var aim := target if (not skill.is_friendly or skill.target_mode == MoveData.TargetMode.SINGLE_ALLY) else c  # D-1200
	if b.use_skill(c, skill, aim):
		_last_used[c] = skill.display_name


## Random among the living opponents, or the one it is engaged with (D-111).
func _pick_target(c: Combatant) -> Combatant:
	if c.engaged_with != null and c.engaged_with.is_alive():
		return c.engaged_with
	var foes := b.opponents_of(c).filter(func(f: Combatant) -> bool: return f.is_alive())
	return foes.pick_random() if not foes.is_empty() else null


## D-1200: the ally a single-ally Move is aimed at, by the Move's focus. "hp": the lowest HP share among
## allies missing at least MIN_MISSING_TO_HEAL. "str": the highest STR among allies that can still take the
## ATK buff. Ties and no candidate = the caster itself (the creator's "si mesmo se ambíguo").
func pick_ally_target(c: Combatant, skill: Skill) -> Combatant:
	var behavior := MoveBehaviorRegistry.for_skill(skill)
	var focus := behavior.ai_ally_focus()
	var best: Combatant = c
	var best_key := -INF
	for ally in b.team_of(c):
		if not ally.is_alive():
			continue
		var key := -INF
		if focus == &"hp":
			var missing := 1.0 - float(ally.hp) / float(maxi(ally.max_hp, 1))
			if missing >= MIN_MISSING_TO_HEAL:
				key = missing
		elif focus == &"str":
			if ally.can_buff("atk", 1):
				key = float(ally.str)
		if key == -INF:
			continue
		if key > best_key:
			best_key = key
			best = ally
		elif is_equal_approx(key, best_key) and ally == c:
			best = c  # Ambiguous: it prefers itself.
	return best


## Sorted by nothing: a weighted draw among the moves close enough to the best.
func _weighted_pick(options: Array[Dictionary]) -> Dictionary:
	var best := 0.0
	for o in options:
		best = maxf(best, o["value"])
	var pool := options.filter(func(o: Dictionary) -> bool: return o["value"] >= best * CLOSE_TO_BEST)
	var total := 0.0
	for o in pool:
		total += o["value"]
	var roll := randf() * total
	for o in pool:
		roll -= o["value"]
		if roll <= 0.0:
			return o
	return pool.back() if not pool.is_empty() else {}


# --- Saving ATB for an Evade ----------------------------------------------------

## A knock-out and a free (Burst) action never wait; anything else leaves the reserve intact.
## Subordinado as politicas de Tactics, com modulacao da Nature (D-001, D-393).
func _may_spend(c: Combatant, skill: Skill, target: Combatant) -> bool:
	if not c.can_pay_skill(skill):
		return false
	var eff_reserve := _reserve(c)
	if c.act_policy == Combatant.Act.SKILL and c.nature_id != "":
		var agg_mult: float = float(NatureData.get_nature(c.nature_id).get("aggression_mult", 1.0))
		eff_reserve /= maxf(agg_mult, 0.1)
	if c.burst > 0 or c.blocks() >= Combatant.BLOCKS or c.blocks() - skill.cost >= eff_reserve:
		return true
	return not skill.is_friendly and skill.kind != Skill.Kind.STATUS and _damage_to(c, skill, target) >= target.hp


func _reserve(c: Combatant) -> float:
	if c.react_policy != Combatant.React.EVADE:
		return 0.0
	var nature_bias := 0.0
	if c.nature_id != "":
		nature_bias = float(NatureData.get_nature(c.nature_id).get("atb_reserve_bias", 0.0))
	for inc in b.active_attacks():
		if inc.target != c or inc.dodged or inc.is_friendly or inc.kind == Skill.Kind.STATUS:
			continue
		var eta: float = inc.eta() if inc.resolved else inc.time_left + UNRESOLVED_ETA
		if c.blocks() + c.speed * eta >= Battle.EVADE_STILL:
			return clampf(Battle.EVADE_STILL + nature_bias, 0.0, Combatant.BLOCKS)
	return clampf(IDLE_RESERVE + nature_bias, 0.0, Combatant.BLOCKS)


## On its own run a non-perfect Evade would throw that attack away (D-029): it waits for the
## perfect window instead. Otherwise it dodges at the moment it rolled (D-021).
func try_evade(inc: Incoming) -> void:
	var t := inc.target
	inc.ai_evade_at = -1.0
	if not t.is_alive() or inc.evade_tried or t.blocks() < b.evade_cost(t):
		return
	b.try_evade(t, inc)


# --- What a move is worth right now -----------------------------------------------

func score_move(c: Combatant, skill: Skill, target: Combatant) -> float:
	var move_id := String(skill.data.id) if skill.data != null else BattleSpace.move_id(skill.display_name)
	var behavior := MoveBehaviorRegistry.get_behavior(StringName(move_id))
	var value := 0.0
	if skill.kind == Skill.Kind.STATUS:
		var status_score := behavior.ai_status_value(c, target, b)
		value = status_score if status_score >= 0.0 else 8.0
	else:
		var attack_score := behavior.ai_attack_value(c, target, b)
		if attack_score >= 0.0:
			value = attack_score
		else:
			value = _damage_value(c, skill, move_id, target)
			if value > 0.0 and _would_interrupt(c, skill, target):
				value += INTERRUPT_BONUS
	return value if c.burst > 0 else value / (1.0 + COST_WEIGHT * float(skill.cost))


func _damage_value(c: Combatant, skill: Skill, move_id: String, target: Combatant) -> float:
	var hit_all := skill.is_aoe or skill.aoe_on_contact
	var value := 0.0
	for foe in (b.enemies if c.is_player else b.party):
		if not foe.is_alive() or (foe != target and not hit_all) or foe.is_invulnerable_target():
			continue
		var damage := _damage_to(c, skill, foe)
		value += minf(float(damage) / float(foe.hp), 1.0) * 100.0
		if damage >= foe.hp:
			value += KO_BONUS
		if foe.is_weak_to(skill.element):
			value += WEAK_BONUS
	var contact_bonus: float = float(CONTACT_BONUS.get(move_id, 0.0))
	if skill.data != null:
		contact_bonus = float(skill.data.ai_profile.get("contact_bonus", contact_bonus))
	return value + float(contact_bonus) if value > 0.0 else 0.0


## The hit's damage, including the target's defense stage (same numbers as take_damage).
func _damage_to(c: Combatant, skill: Skill, foe: Combatant) -> int:
	var damage := int(Battle.estimate_damage(c, foe, skill))
	var bypass_def := skill.data != null and skill.data.bypass_def
	if not bypass_def:
		bypass_def = BattleSpace.move_id(skill.display_name) == "drain_spear"  # fallback for Skills without MoveData
	return DamageMath.final_damage(damage, foe.def_buff, bypass_def, false)  # D-1153: same defense as take_damage; AI keeps the old 0 floor.


## Will this hit land while the target is still winding up its own attack?
func _would_interrupt(c: Combatant, skill: Skill, target: Combatant) -> bool:
	var own_windup := skill.windup if skill.windup >= 0.0 else Battle.WINDUP
	if c.counter_ready:
		own_windup = 0.0
	var arrival := own_windup + AttackPlanner.preview_travel(c, target, skill.kind)
	if skill.kind == Skill.Kind.MELEE:
		arrival += STRIKE_TIME
	for inc in b.incoming:
		if inc.attacker == target and inc.kind != Skill.Kind.STATUS and inc.time_left > arrival:
			return true
	return false


## Weighed against the moves, with no fixed HP line: it is worth what it would really heal,
## more the more HP is missing (D-115).
func score_potion(c: Combatant, potion: Item) -> float:
	var missing := 1.0 - float(c.hp) / float(c.max_hp)
	if missing < MIN_MISSING_TO_HEAL:
		return 0.0
	var healed := minf(float(potion.heal), float(c.max_hp - c.hp)) / float(c.max_hp)
	return healed * 100.0 * (1.0 + missing) / (1.0 + COST_WEIGHT * Battle.ITEM_BLOCKS)


func _first_consumable(c: Combatant) -> Item:
	for id in c.inventory:
		var item := Item.get_item(id)
		if item != null and item.kind == Item.Kind.CONSUMABLE and c.item_count(id) > 0:
			return item
	return null
