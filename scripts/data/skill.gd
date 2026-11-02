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
var is_aoe := false  ## Hits all targets on the opposing team (or all allies if friendly).
var is_friendly := false  ## Targets self/allies (healing/buffs).


func _init(p_name: String, p_power: float, p_cost := 2, p_element := Element.Type.FISICO, p_kind := -1, p_ground := false, p_aoe := false, p_friendly := false) -> void:
	display_name = p_name
	power = p_power
	cost = p_cost
	element = p_element
	ground = p_ground
	is_aoe = p_aoe
	is_friendly = p_friendly
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


## 8 Shin Megami Tensei inspired moves (4 Status, 2 AoE Projectile, 2 AoE Physical).
static func smt_skills() -> Array[Skill]:
	return [
		# 4 Status (1 Heal/Support, Buffs, Debuffs)
		Skill.new("Media", 0.0, 2, Element.Type.LUZ, Kind.STATUS, false, true, true),
		Skill.new("Tarukaja", 0.0, 2, Element.Type.FOGO, Kind.STATUS, false, true, true),
		Skill.new("Rakunda", 0.0, 1, Element.Type.TREVAS, Kind.STATUS, false, false, false),
		Skill.new("Sukunda", 0.0, 1, Element.Type.VENTO, Kind.STATUS, false, false, false),
		# 2 AoE Projectiles
		Skill.new("Mabufula", 1.35, 2, Element.Type.AGUA_GELO, Kind.PROJECTILE, false, true, false),
		Skill.new("Megido", 1.6, 3, Element.Type.LUZ, Kind.PROJECTILE, false, true, false),
		# 2 AoE Physical
		Skill.new("Hassou Tobi", 1.4, 3, Element.Type.FISICO, Kind.MELEE, false, true, false),
		Skill.new("Titanomachia", 1.5, 3, Element.Type.TERRA, Kind.MELEE, false, true, false),
	]
