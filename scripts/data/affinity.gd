class_name Affinity
extends RefCounted
## D-1157/D-1158: WEAK and RESIST are active. NULL/REPEL are reserved
## (D-1161) and must not be used; DRAIN is not implemented.
enum Type { NEUTRAL, WEAK, RESIST, NULL, REPEL, DRAIN }

const WEAK_MULT := 1.5
const RESIST_MULT := 0.5

const NAMES := {
	Type.NEUTRAL: "Neutral",
	Type.WEAK: "Weak",
	Type.RESIST: "Resist",
	Type.NULL: "Null",
	Type.REPEL: "Repel",
	Type.DRAIN: "Drain",
}


static func name_of(kind: int) -> String:
	return String(NAMES.get(kind, "Neutral"))


## D-1157/D-1158/D-1161: only NEUTRAL, WEAK and RESIST are active.
## NULL, REPEL and DRAIN are reserved in the enum and must not be used.
static func damage_multiplier(kind: int) -> float:
	if kind == Type.WEAK:
		return WEAK_MULT
	if kind == Type.RESIST:
		return RESIST_MULT
	return 1.0
