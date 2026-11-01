class_name Battle
extends Node
## ATB battle loop. Gauges fill in real time; the first ready player
## character waits for a command (the clock pauses while choosing).
## Enemies act automatically as soon as their gauge is full.

signal log_message(text: String)
signal battle_ended(player_won: bool)
signal state_changed

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var active: Combatant = null  ## Player combatant awaiting a command.
var running := false


func start(p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	party = p_party
	enemies = p_enemies
	running = true
	log_message.emit("Batalha iniciada!")


func _process(delta: float) -> void:
	if not running or active != null:
		return
	for c in party + enemies:
		c.tick(delta)
	for c in party + enemies:
		if c.ready_to_act and c.is_alive():
			_handle_ready(c)
			break
	state_changed.emit()


func _handle_ready(c: Combatant) -> void:
	if c.is_player:
		active = c
		log_message.emit("%s está pronto!" % c.name)
	else:
		_attack(c, _first_alive(party))
		c.end_turn()
		_check_end()


func player_attack(target: Combatant) -> void:
	if active == null:
		return
	_attack(active, target)
	active.end_turn()
	active = null
	_check_end()


func _attack(attacker: Combatant, target: Combatant) -> void:
	var dmg := maxi(1, attacker.attack + randi_range(-2, 2))
	target.take_damage(dmg)
	log_message.emit("%s ataca %s (%d dano)" % [attacker.name, target.name, dmg])


func _first_alive(list: Array[Combatant]) -> Combatant:
	for c in list:
		if c.is_alive():
			return c
	return null


func _check_end() -> void:
	if _first_alive(enemies) == null:
		running = false
		log_message.emit("Vitória!")
		battle_ended.emit(true)
	elif _first_alive(party) == null:
		running = false
		log_message.emit("Derrota...")
		battle_ended.emit(false)
