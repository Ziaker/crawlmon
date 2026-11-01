class_name Battle
extends Node
## ATB battle rules. Every combatant has a 5-block gauge that fills over time.
## Skills cost 2 blocks, items 1. Enemy attacks take a moment to land; Evade
## (3 blocks) dodges one and grants a burst (free extra action). Every hit also
## has an automatic evade chance based on the target's speed (grants +1 ATB block). party[0] is the player-controlled leader, the rest follow Tactics.

signal log_message(text: String)
signal battle_ended(player_won: bool)
signal state_changed

class Incoming:
	var attacker: Combatant
	var target: Combatant
	var power := 1.0
	var time_left := 0.0
	var dodged := false
	var evade_tried := false

const SKILL_BLOCKS := 2.0
const ITEM_BLOCKS := 1.0
const EVADE_BLOCKS := 3.0
const WINDUP := 1.6  ## Seconds an enemy attack takes to land.
const WEAKNESS_MULT := 1.5
const CRIT_CHANCE := 0.1
const CRIT_MULT := 2.0

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var incoming: Array[Incoming] = []
var running := false


func start(p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	party = p_party
	enemies = p_enemies
	for c in party:
		c.atb = 0.0
		c.burst = 0
	for e in enemies:
		e.atb = 0.0
	running = true
	log_message.emit("Batalha iniciada!")


func _process(delta: float) -> void:
	if not running:
		return
	for c in party + enemies:
		c.tick(delta)
	_enemy_ai()
	_ally_ai()
	_resolve_incoming(delta)
	state_changed.emit()


# --- Player / ally actions -------------------------------------------------

func use_skill(actor: Combatant, skill: Skill, target: Combatant) -> bool:
	if not actor.is_alive() or not target.is_alive() or not actor.can_pay(skill.cost):
		return false
	actor.pay(skill.cost)
	_hit(actor, target, skill.power, skill.element, skill.display_name)
	_check_end()
	return true


func use_item(actor: Combatant, item: Item, target: Combatant) -> bool:
	if item.kind != Item.Kind.CONSUMABLE or not actor.can_pay(ITEM_BLOCKS):
		return false
	if not actor.is_alive() or GameState.item_count(item.id) <= 0:
		return false
	actor.pay(ITEM_BLOCKS)
	GameState.remove_item(item.id)
	target.heal(item.heal)
	log_message.emit("%s usa %s em %s" % [actor.name, item.display_name, target.name])
	return true


## The enemy attack `actor` could still try to evade, or null.
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
	return true


# --- AI --------------------------------------------------------------------

func _enemy_ai() -> void:
	for e in enemies:
		if not e.is_alive() or e.atb < SKILL_BLOCKS or _is_winding_up(e):
			continue
		var target := _first_alive(party)
		if target == null:
			return
		e.pay(SKILL_BLOCKS)
		var inc := Incoming.new()
		inc.attacker = e
		inc.target = target
		inc.time_left = WINDUP
		incoming.append(inc)
		log_message.emit("%s prepara um ataque em %s..." % [e.name, target.name])


func _ally_ai() -> void:
	for i in range(1, party.size()):
		var a := party[i]
		if not a.is_alive():
			continue
		if a.react_policy == Combatant.React.EVADE:
			try_evade(a, find_evadable(a))
		if a.act_policy == Combatant.Act.HOLD or a.atb < SKILL_BLOCKS:
			continue
		var target := _first_alive(enemies)
		if target == null:
			return
		use_skill(a, _pick_skill(a), target)


func _pick_skill(a: Combatant) -> Skill:
	if a.act_policy == Combatant.Act.SKILL and not a.skills.is_empty():
		for skill in a.skills:
			if a.can_pay(skill.cost):
				return skill
	return Skill.basic()


func _resolve_incoming(delta: float) -> void:
	for inc in incoming.duplicate():
		if not inc.attacker.is_alive() or not inc.target.is_alive():
			incoming.erase(inc)
			continue
		inc.time_left -= delta
		if inc.time_left > 0.0:
			continue
		incoming.erase(inc)
		if inc.dodged:
			log_message.emit("%s errou o ataque!" % inc.attacker.name)
		else:
			_hit(inc.attacker, inc.target, inc.power, Element.Type.FISICO, "Ataque")
	_check_end()


# --- Helpers ---------------------------------------------------------------

func _is_winding_up(e: Combatant) -> bool:
	for inc in incoming:
		if inc.attacker == e:
			return true
	return false


func _hit(attacker: Combatant, target: Combatant, power: float, element: Element.Type, label: String) -> void:
	# Automatic evade: chance equals the target's speed; success gives +1 ATB block.
	if randf() < target.speed:
		target.add_atb(1.0)
		log_message.emit("%s esquiva de %s automaticamente! +1 bloco" % [target.name, label])
		return
	var weak := element in target.weaknesses
	var crit := randf() < CRIT_CHANCE
	var dmg := maxi(1, roundi(attacker.attack * power * (WEAKNESS_MULT if weak else 1.0) * (CRIT_MULT if crit else 1.0)))
	target.take_damage(dmg)
	if weak:
		attacker.add_atb(2.0)
	if crit:
		attacker.add_atb(1.0)
	log_message.emit("%s usa %s (%s) em %s (%d dano)%s" % [
		attacker.name, label, Element.name_of(element), target.name, dmg, (" FRAQUEZA! +2 bloco(s)" if weak else "") + (" CRÍTICO! +1 bloco" if crit else "")])


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
	incoming.clear()
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)
