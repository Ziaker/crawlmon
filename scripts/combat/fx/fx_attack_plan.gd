class_name FxAttackPlan
extends RefCounted
## Prepares the drawing of an attack the rules already planned (`AttackPlanner` filled the
## timeline and kinematics in the Incoming). Nothing here decides a duration or a position.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## Builds the drawing data of a planned attack and returns its total duration.
func begin_attack(inc) -> float:
	var a: Combatant = inc.attacker
	var m: Node3D = fx._models[a]
	var d := {"dir": inc.dir, "base_scale": fx._base_scale.get(a, m.scale), "move_id": inc.move_id}
	match String(inc.motion):
		"engaged":
			# Its first action after the Evade: it appears next to the attacker it interrupted
			# (the rules already put it there; this only draws the arrival).
			if inc.arrived:
				fx.fx_dodge.arrive_to_attack(a, inc.target)
			d.merge({"kind": "melee", "engaged": true, "stand": inc.stand, "run_t": 0.0, "hit": inc.hit, "hold": 0.0,
				"antic": 0.0, "hop_t": inc.hop_t, "hop_h": inc.hop_h, "yaw_out": atan2(inc.dir.x, inc.dir.z), "from": inc.from})
		"melee":
			d.merge({"kind": "melee", "stand": inc.stand, "run_t": inc.run_t, "hit": inc.hit, "hold": inc.hold,
				"antic": inc.antic, "hop_t": inc.hop_t, "hop_h": inc.hop_h, "yaw_out": atan2(inc.dir.x, inc.dir.z),
				"from": Vector3(m.position.x, 0.0, m.position.z)})
		_:
			d["kind"] = "cast"
			d["fly"] = inc.fly
	inc.data = d
	var sum := 0.0
	for seg in inc.plan:
		sum += seg[1]
	return sum
