class_name Combatant
extends RefCounted
## A participant in an ATB battle. The ATB gauge is measured in blocks (0..5)
## and fills continuously; actions spend whole blocks from it.

signal damaged(combatant: Combatant, amount: int)
signal died(combatant: Combatant)

enum Act { ATTACK, SKILL, HOLD }  ## Tactics: what an AI ally does with its blocks.
enum React { NONE, EVADE }  ## Tactics: how an AI ally reacts to incoming attacks.

const BLOCKS := 5.0
const BURST_MAX := 1

var name: String
var max_hp: int
var hp: int
var base_attack: int
var base_speed: float  ## Blocks per second.
var is_player: bool
var skills: Array[Skill] = []
var held_item_id := ""
var act_policy := Act.ATTACK
var react_policy := React.NONE
var atb := 0.0
var burst := 0

var attack: int:
	get:
		return base_attack

var speed: float:
	get:
		return base_speed


func _init(p_name: String, p_hp: int, p_attack: int, p_speed: float, p_is_player: bool) -> void:
	name = p_name
	max_hp = p_hp
	hp = p_hp
	base_attack = p_attack
	base_speed = p_speed
	is_player = p_is_player


func get_held_item() -> Item:
	return Item.get_item(held_item_id) if held_item_id != "" else null


func is_alive() -> bool:
	return hp > 0


func tick(delta: float) -> void:
	if is_alive():
		atb = minf(atb + speed * delta, BLOCKS)


## A burst charge pays for any one action for free.
func can_pay(cost: float) -> bool:
	return burst > 0 or atb >= cost


func pay(cost: float) -> void:
	if burst > 0:
		burst -= 1
	else:
		atb -= cost


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	damaged.emit(self, amount)
	if hp == 0:
		died.emit(self)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
