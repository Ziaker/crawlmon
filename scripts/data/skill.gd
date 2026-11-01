class_name Skill
extends RefCounted
## A Fight-menu attack. `cost` is in ATB blocks (normally 2).

var display_name: String
var power: float
var cost: int


func _init(p_name: String, p_power: float, p_cost := 2) -> void:
	display_name = p_name
	power = p_power
	cost = p_cost


## The generic physical attack always shown first in the Fight menu.
static func basic() -> Skill:
	return Skill.new("Ataque", 1.0, 2)
