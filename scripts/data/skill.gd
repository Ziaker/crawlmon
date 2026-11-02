class_name Skill
extends RefCounted
## A Fight-menu move. `cost` is in ATB blocks (normally 2). `kind` is how the move reaches
## its target and is separate from its element: MELEE runs at the target, PROJECTILE flies
## to it (`ground`: along the floor), CAST strikes from where the caster stands, STATUS
## deals no damage.

enum Kind { MELEE, PROJECTILE, CAST, STATUS }

var display_name: String
var power: float
var cost: int
var element: Element.Type
var kind: Kind
var ground := false  ## A projectile that travels along the floor.


func _init(p_name: String, p_power: float, p_cost := 2, p_element := Element.Type.FISICO, p_kind := -1, p_ground := false) -> void:
	display_name = p_name
	power = p_power
	cost = p_cost
	element = p_element
	ground = p_ground
	kind = (p_kind if p_kind >= 0 else default_kind(p_element)) as Kind


## Moves that do not say how they travel behave like their element used to.
static func default_kind(e: Element.Type) -> Kind:
	if e == Element.Type.FISICO:
		return Kind.MELEE
	if e in [Element.Type.RAIO, Element.Type.LUZ, Element.Type.TERRA]:
		return Kind.CAST
	return Kind.PROJECTILE


static func kind_name(k: Kind) -> String:
	return ["corpo a corpo", "projétil", "à distância", "status"][k]


## The generic physical attack always shown first in the Fight menu.
static func basic() -> Skill:
	return Skill.new("Tackle", 1.0, 2)
