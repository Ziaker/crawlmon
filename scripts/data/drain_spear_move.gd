extends RefCounted
## move_drain_spear: the Move's own contract, kept out of the generic Skill class so the
## Move can be equipped by any Combatant (D-235). The base Skill only carries the common
## fields (name, element, kind, ATB cost, wind-up); the behaviour below is routed by id.

const ID := "drain_spear"
const REACH := 16.3
const BAND := 1.0
const BASE_DAMAGE := 5
const TRANSFER := 0.30
const WINDUP := 1.0
const STRIKE_TIME := 0.45
const RETURN_HOLD := 0.75


static func make() -> Skill:
	return Skill.new("Drain Spear", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, WINDUP)


static func is_move(skill: Skill) -> bool:
	return skill != null and BattleSpace.move_id(skill.display_name) == ID


## Mid-range contact distance; -1 means "use the normal melee gap".
static func reach(skill: Skill) -> float:
	return REACH if is_move(skill) else -1.0


## Fixed magic damage; -1 means "use the normal physical formula".
static func magic_flat(skill: Skill) -> int:
	return BASE_DAMAGE if is_move(skill) else -1


static func badge_steal(skill: Skill) -> bool:
	return is_move(skill)
