class_name Battle
extends Node
## ATB battle rules. Every combatant has a 5-block gauge that fills over time.
## Normal actions cost 2 blocks. Enemies telegraph attacks (a wind-up) which an
## ally can try to Evade for 3 blocks; a successful evade grants a free burst
## action. party[0] is the player-controlled leader, the rest follow Tactics.

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

const ACTION_BLOCKS := 2.0
const EVADE_BLOCKS := 3.0
const WINDUP := 1.6  ## Seconds an enemy attack takes to land.
const EVADE_CHANCE := 0.6

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var incoming: Array[Incoming] = []
var running := false
var menu_paused := false  ## Set by the UI while a submenu is open (if enabled).


func start(p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	party = p_party
	enemies = p_enemies
	for c in party:
		c.atb = 1.0
		c.burst = 0
	for e in enemies:
		e.atb = randf_range(0.5, 1.5)
	running = true
	log_message.emit("Batalha iniciada!")


func _process(delta: float) -> void:
	if not running or menu_paused:
		return
	delta *= GameState.settings["atb_speed"]
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
	_hit(actor, target, skill.power, skill.display_name)
	_check_end()
	return true


func use_item(actor: Combatant, item: Item, target: Combatant) -> bool:
	if item.kind != Item.Kind.CONSUMABLE or not actor.can_pay(ACTION_BLOCKS):
		return false
	if not actor.is_alive() or GameState.item_count(item.id) <= 0:
		return false
	actor.pay(ACTION_BLOCKS)
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
	if randf() < EVADE_CHANCE:
		inc.dodged = true
		actor.burst = mini(actor.burst + 1, Combatant.BURST_MAX)
		log_message.emit("%s desvia do ataque de %s! BURST!" % [actor.name, inc.attacker.name])
	else:
		log_message.emit("%s tenta desviar, mas falha." % actor.name)
	return true


# --- AI --------------------------------------------------------------------

func _enemy_ai() -> void:
	for e in enemies:
		if not e.is_alive() or e.atb < ACTION_BLOCKS or _is_winding_up(e):
			continue
		var target := _random_alive(party)
		if target == null:
			return
		e.pay(ACTION_BLOCKS)
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
		# Allies that react by evading keep a reserve: they only act on a full gauge.
		var threshold := Combatant.BLOCKS if a.react_policy == Combatant.React.EVADE else ACTION_BLOCKS
		if a.act_policy == Combatant.Act.HOLD or a.atb < threshold:
			continue
		var target := _random_alive(enemies)
		if target == null:
			return
		use_skill(a, _pick_skill(a), target)


func _pick_skill(a: Combatant) -> Skill:
	if a.act_policy == Combatant.Act.SKILL and not a.skills.is_empty():
		var skill: Skill = a.skills.pick_random()
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
			_hit(inc.attacker, inc.target, inc.power, "Ataque")
	_check_end()


# --- Helpers ---------------------------------------------------------------

func _is_winding_up(e: Combatant) -> bool:
	for inc in incoming:
		if inc.attacker == e:
			return true
	return false


func _hit(attacker: Combatant, target: Combatant, power: float, label: String) -> void:
	var dmg := maxi(1, roundi(attacker.attack * power) + randi_range(-2, 2))
	target.take_damage(dmg)
	log_message.emit("%s usa %s em %s (%d dano)" % [attacker.name, label, target.name, dmg])


func _random_alive(list: Array[Combatant]) -> Combatant:
	var alive := list.filter(func(c: Combatant) -> bool: return c.is_alive())
	return alive.pick_random() if not alive.is_empty() else null


func _check_end() -> void:
	if not running:
		return
	var enemies_dead := _random_alive(enemies) == null
	var party_dead := _random_alive(party) == null
	if not enemies_dead and not party_dead:
		return
	running = false
	incoming.clear()
	log_message.emit("Vitória!" if enemies_dead else "Derrota...")
	battle_ended.emit(enemies_dead)
