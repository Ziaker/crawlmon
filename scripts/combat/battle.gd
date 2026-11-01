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
signal manual_evaded(actor: Combatant, inc)
signal hit_resolved(attacker: Combatant, target: Combatant, element: Element.Type, info: Dictionary)
signal healed(actor: Combatant, target: Combatant, amount: int)

class Incoming:
	var attacker: Combatant
	var target: Combatant
	var power := 1.0
	var element := Element.Type.FISICO
	var label := ""
	var time_left := 0.0
	var dodged := false
	var evade_tried := false

const SKILL_BLOCKS := 2.0
const ITEM_BLOCKS := 1.0
const EVADE_BLOCKS := 3.0
const WINDUP := 1.6  ## Seconds an attack takes to land.
const WEAKNESS_MULT := 1.5
const CRIT_CHANCE := 0.1
const CRIT_MULT := 2.0
const AI_HEAL_BELOW := 0.5  ## AI combatants drink a potion at or below this HP fraction.

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var incoming: Array[Incoming] = []
var running := false


func start(p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	party = p_party
	enemies = p_enemies
	for c in party + enemies:
		c.atb = 0.0
		c.burst = 0
	running = true
	log_message.emit("Batalha iniciada!")


func _process(delta: float) -> void:
	if not running:
		return
	for c in party + enemies:
		c.tick(delta)
	_run_ai()
	_resolve_incoming(delta)
	state_changed.emit()


# --- Actions (same for the player, allies and enemies) -----------------------

func use_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not actor.is_alive() or not target.is_alive() or is_winding_up(actor) or not actor.can_pay(skill.cost):
		return false
	actor.pay(skill.cost)
	var inc := Incoming.new()
	inc.attacker = actor
	inc.target = target
	inc.power = skill.power
	inc.element = skill.element
	inc.label = skill.display_name
	inc.time_left = WINDUP
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
	actor.remove_item(item.id)
	var before := target.hp
	target.heal(item.heal)
	healed.emit(actor, target, target.hp - before)
	log_message.emit("%s usa %s em %s" % [actor.name, item.display_name, target.name])
	return true


## The attack `actor` could still try to evade, or null.
func find_evadable(actor: Combatant) -> Incoming:
	if not actor.is_alive() or actor.atb < EVADE_BLOCKS:
		return null
	for inc in incoming:
		if inc.target == actor and not inc.dodged and not inc.evade_tried:
			return inc
	return null


func try_evade(actor: Combatant, inc: Incoming) -> bool:
	if inc == null or actor.atb < EVADE_BLOCKS:
		return false
	actor.atb -= EVADE_BLOCKS
	inc.evade_tried = true
	inc.dodged = true
	actor.burst = mini(actor.burst + 1, Combatant.BURST_MAX)
	log_message.emit("%s desvia do ataque de %s! BURST!" % [actor.name, inc.attacker.name])
	manual_evaded.emit(actor, inc)
	return true


func is_winding_up(c: Combatant) -> bool:
	for inc in incoming:
		if inc.attacker == c:
			return true
	return false


# --- AI (everyone except the player-controlled leader) -----------------------

func _run_ai() -> void:
	for c in party + enemies:
		if c == party[0] or not c.is_alive():
			continue
		var foes := enemies if c.is_player else party
		if c.react_policy == Combatant.React.EVADE:
			try_evade(c, find_evadable(c))
		if c.hp <= c.max_hp * AI_HEAL_BELOW and c.can_pay(ITEM_BLOCKS):
			var potion := _first_consumable(c)
			if potion != null and use_item(c, potion, c):
				continue
		if is_winding_up(c):
			continue
		if c.act_policy == Combatant.Act.HOLD or not c.can_pay(SKILL_BLOCKS):
			continue
		var target := _first_alive(foes)
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
		attack_resolved.emit(inc)
		if inc.dodged:
			log_message.emit("%s errou %s!" % [inc.attacker.name, inc.label])
		else:
			_hit(inc.attacker, inc.target, inc.power, inc.element, inc.label)
	_check_end()


# --- Helpers ---------------------------------------------------------------

func _hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String) -> void:
	var info := {"evaded": false, "dmg": 0, "weak": false, "crit": false, "gain": 0}
	# Automatic evade: chance equals the target's speed; success gives +1 ATB block.
	if randf() < target.speed:
		target.add_atb(1.0)
		info["evaded"] = true
		log_message.emit("%s esquiva de %s automaticamente! +1 bloco" % [target.name, label])
		hit_resolved.emit(attacker, target, element, info)
		return
	var weak := element in target.weaknesses
	var crit := randf() < CRIT_CHANCE
	var dmg := maxi(1, roundi(attacker.attack * power * (WEAKNESS_MULT if weak else 1.0) * (CRIT_MULT if crit else 1.0)))
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
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)
