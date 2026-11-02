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
	nodes.append_array(_ground_telegraph(a_home, t_home, warn, elem_col, w, not inc.attacker.is_player))
	nodes.append_array(_charge_aura(inc.attacker, a_home, warn, elem_col, w))
	_telegraphs[inc] = nodes


## Projects a 3D ground danger lane/cone and target danger reticle directly onto the arena floor.
func _ground_telegraph(from: Vector3, to: Vector3, warn: Color, elem_col: Color, duration: float, is_enemy_threat: bool) -> Array[Node]:
	var nodes: Array[Node] = []
	var dist := from.distance_to(to)
	var dir := fx._flat_dir(from, to)
	var mid := (from + to) * 0.5
	var yaw := atan2(dir.x, dir.z)

	# 1. Flat ground danger strip (Ground Decal)
	var lane_w := 1.45 if is_enemy_threat else 0.95
	var lane_mesh := PlaneMesh.new()
	lane_mesh.size = Vector2(lane_w, maxf(dist - 1.2, 1.0))
	var lane := fx._node(lane_mesh, Color(warn.r, warn.g, warn.b, 0.24), Vector3(mid.x, 0.03, mid.z))
	lane.rotation.y = yaw
	nodes.append(lane)

	# 2. Glowing side rails framing the ground lane
	var right := Vector3(dir.z, 0.0, -dir.x)
	for side in [-1.0, 1.0]:
		var s_val: float = float(side)
		var rail_mesh := PlaneMesh.new()
		rail_mesh.size = Vector2(0.11, maxf(dist - 1.2, 1.0))
		var rail_pos: Vector3 = mid + right * (s_val * lane_w * 0.5)
		var rail := fx._node(rail_mesh, Color(warn.r, warn.g, warn.b, 0.78), Vector3(rail_pos.x, 0.035, rail_pos.z))
		rail.rotation.y = yaw
		nodes.append(rail)

	# 3. Animated charge wave sweeping along the ground lane toward the target
	var fill_mesh := PlaneMesh.new()
	fill_mesh.size = Vector2(lane_w * 0.88, 0.6)
	var start_pos := from + dir * 1.0
	var end_pos := to - dir * 1.0
	var sweep := fx._node(fill_mesh, Color(elem_col.r, elem_col.g, elem_col.b, 0.65), Vector3(start_pos.x, 0.04, start_pos.z))
	sweep.rotation.y = yaw
	var tw_sweep := sweep.create_tween().set_parallel(true)
	tw_sweep.tween_property(sweep, "position", Vector3(end_pos.x, 0.04, end_pos.z), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_sweep.tween_property(sweep, "scale:z", maxf(dist * 0.45, 1.5), duration)
	nodes.append(sweep)

	# 4. Target ground hazard zone + shrinking timing ring (turns fx.GOLD in Perfect Evade window)
	var outer_ring := fx._ring(to + Vector3(0, 0.04, 0), Color(warn, 0.7), Vector3(2.3, 1, 2.3), Vector3(2.3, 1, 2.3), duration, Vector3.ZERO, 0.0, false)
	var shrink_ring := fx._ring(to + Vector3(0, 0.05, 0), warn, Vector3(2.5, 1, 2.5), Vector3(0.85, 1, 0.85), duration, Vector3.ZERO, 0.0, false)
	nodes.append(outer_ring)
	nodes.append(shrink_ring)
	return nodes


## Spawns a concentration aura on the attacker: eye/head flare, rising vapor/sparks, and ground ring.
func _charge_aura(attacker: Combatant, pos: Vector3, warn: Color, elem_col: Color, duration: float) -> Array[Node]:
	var nodes: Array[Node] = []
	var m: Node3D = fx._models.get(attacker)
	var head_y: float = m.get_meta("head_y") if m != null and m.has_meta("head_y") else 1.8
	# Eye / head concentration flare
	VfxLib.flash_star(fx, pos + Vector3(0, head_y * 0.78, 0), warn.lerp(Color.WHITE, 0.35), 2.4, minf(duration, 0.45))
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
	var a_home: Vector3 = fx._home[a]
	var t_home: Vector3 = fx._home[t]
	var total: float = fx.fx_motion.begin_attack(inc)
	if fx.cam != null and (a == fx.leader or t == fx.leader):
		if inc.element == Element.Type.FISICO:
			fx.cam.action((a_home + t_home) * 0.5, 0.65)
		else:
			fx.cam.action(t_home, 0.65)
	fx._busy_for(a, total + 0.35)
	fx._busy_for(t, total + 0.65)
