class_name FxTelegraph
extends RefCounted
## Attack warnings (ground lane, charge aura) and the start of the strike.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx
var _telegraphs: Dictionary = {}  ## Battle.Incoming -> Array[Node]


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## An attack starts winding up: the attacker plays its charge pose with a
## concentration aura (eye flare, rising sparks, ground energy) while 3D ground
## decals (danger lane/cone + target reticle) project the threat onto the arena floor.
func telegraph(inc) -> void:
	fx._rebase(inc.attacker)
	fx._rebase(inc.target)
	var w: float = inc.total_windup if inc.total_windup > 0.05 else Battle.WINDUP
	fx._busy_for(inc.attacker, w + 0.5)
	fx._busy_for(inc.target, w + 0.6)
	if inc.instant:
		return  # Counter-attacks have no charge pose, aura or danger markers.
	var a_home: Vector3 = fx._home[inc.attacker]
	var t_home: Vector3 = fx._home[inc.target]
	var warn := fx.TELEGRAPH_COLOR if not inc.attacker.is_player else fx.ALLY_COLOR
	var elem_col: Color = fx.COLORS.get(inc.element, warn)
	fx._play(inc.attacker, "charge")
	var nodes: Array[Node] = []
	var move_id := BattleFx.normalize_move_id(inc.label)
	var authored := _telegraph_move(inc, move_id, a_home, t_home, warn, elem_col, w)
	nodes.append_array(authored.get("nodes", []))
	if not authored.get("handled", false):
		nodes.append_array(_ground_telegraph(a_home, t_home, warn, elem_col, w, not inc.attacker.is_player))
		nodes.append_array(_charge_aura(inc.attacker, a_home, warn, elem_col, w))
	_telegraphs[inc] = nodes


## Move telegraphs can replace the elemental/default warning without changing wind-up time.
func _telegraph_move(_inc, _move_id: String, _from: Vector3, _to: Vector3, _warn: Color, _elem_col: Color, _duration: float) -> Dictionary:
	var authored_nodes: Array[Node] = []
	if _move_id == "quebra_telha":
		var barrier := fx.fx_impacts.spawn_brick_barrier(_inc.target, _to + Vector3(0, 1.15, 0), fx._flat_dir(_from, _to))
		if barrier != null:
			authored_nodes.append(barrier)
	elif _move_id == "teleporte_rapido":
		var ring := fx._ring(_from + Vector3(0, 0.05, 0), Color("63d9ec"), Vector3(2.0, 1, 2.0), Vector3(0.3, 1, 0.3), _duration, Vector3.ZERO, 0.0, false)
		authored_nodes.append(ring)
	return {"handled": false, "nodes": authored_nodes}


## Target danger reticle directly under the target on the arena floor (no rectangular trajeto lane per D-026).
func _ground_telegraph(_from: Vector3, to: Vector3, warn: Color, _elem_col: Color, duration: float, _is_enemy_threat: bool) -> Array[Node]:
	var nodes: Array[Node] = []
	var outer_ring := fx._ring(to + Vector3(0, 0.04, 0), Color(warn, 0.7), Vector3(2.3, 1, 2.3), Vector3(2.3, 1, 2.3), duration, Vector3.ZERO, 0.0, false)
	var shrink_ring := fx._ring(to + Vector3(0, 0.05, 0), warn, Vector3(2.5, 1, 2.5), Vector3(0.85, 1, 0.85), duration, Vector3.ZERO, 0.0, false)
	nodes.append(outer_ring)
	nodes.append(shrink_ring)
	return nodes

func _charge_aura(attacker: Combatant, pos: Vector3, warn: Color, elem_col: Color, duration: float) -> Array[Node]:
	var nodes: Array[Node] = []
	# Ground concentration ring under attacker
	var foot_ring := fx._ring(pos + Vector3(0, 0.04, 0), elem_col, Vector3(1.8, 1, 1.8), Vector3(0.7, 1, 0.7), duration, Vector3.ZERO, 0.0, false)
	nodes.append(foot_ring)
	# Rising concentration sparks & vapor
	fx._glow(pos + Vector3(0, 0.25, 0), elem_col.lerp(warn, 0.4), 14, Vector2(0.25, 0.55), minf(duration, 0.55), Vector2(1.5, 3.8), Vector3(0, 5.0, 0), 0.15, 0.9)
	return nodes


func clear_telegraph(inc) -> void:
	if _telegraphs.has(inc):
		for n in _telegraphs[inc]:
			if is_instance_valid(n):
				n.queue_free()
		_telegraphs.erase(inc)


## The wind-up ends: Battle plays the attack out (travel, strike, return) from the plan
## built here; the drawing follows its progress (see FxMotion.drive).
func resolve_attack(inc) -> void:
	clear_telegraph(inc)
	var a: Combatant = inc.attacker
	var t: Combatant = inc.target
	var total: float = fx.fx_attack_plan.begin_attack(inc)
	if fx.cam != null and (a == fx.leader or t == fx.leader):
		# Aim at where the hit lands (the target's live body), not at the middle of the
		# empty run: the Impacto framing must put the contact in frame (REGRAS §11).
		# A hit on the leader is offered with weight 2 for the camera priority test (F11).
		fx.cam.action(t.pos, 0.65, 2 if t == fx.leader else 1)
	fx._busy_for(a, total + 0.35)
	fx._busy_for(t, total + 0.65)
