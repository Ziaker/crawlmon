class_name Combatant
extends RefCounted
## A participant in an ATB battle. The gauge fills with time, scaled by speed.

signal gauge_full(combatant: Combatant)
signal damaged(combatant: Combatant, amount: int)
signal died(combatant: Combatant)

const GAUGE_MAX := 100.0

var name: String
var max_hp: int
var hp: int
var attack: int
var speed: float
var is_player: bool
var gauge := 0.0
var ready_to_act := false


func _init(p_name: String, p_hp: int, p_attack: int, p_speed: float, p_is_player: bool) -> void:
	name = p_name
	max_hp = p_hp
	hp = p_hp
	attack = p_attack
	speed = p_speed
	is_player = p_is_player


func is_alive() -> bool:
	return hp > 0


func tick(delta: float) -> void:
	if not is_alive() or ready_to_act:
		return
	gauge = minf(gauge + speed * delta, GAUGE_MAX)
	if gauge >= GAUGE_MAX:
		ready_to_act = true
		gauge_full.emit(self)


func end_turn() -> void:
	gauge = 0.0
	ready_to_act = false


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	damaged.emit(self, amount)
	if hp == 0:
		died.emit(self)
