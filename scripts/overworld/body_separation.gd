class_name BodySeparation
extends Node
## D-1269: no character model may enter another, in ANY overworld scene.
##
## One child node of the lab, nothing per scene. Every frame (after all the movement scripts)
## it gathers the visible actors (leader, allies, NPCs, enemies; plus anything in the group
## `body_actor`), takes the MEASURED footprint of each model (`BodyFootprint`: circle + height,
## no species number, D-235; circle around the VISUAL centre of the body, not the node origin) and pushes overlapping pairs apart on the floor plane until the
## circles only touch. Walls win: a shift is shape-cast against the world (mask 1) and the part a
## wall refused goes to the other actor. Heights are never touched (floor snapping stays theirs).
##
## Who yields (the push goes to whoever MOVED into the other; "solid" stays solid):
##  * the actor that moved more this frame yields in proportion to how much more it moved
##    (leader walking into a standing NPC is held back; an NPC patrolling into the standing leader
##    waits/slides around it);
##  * allies yield to everyone that is not an ally, so they go around the leader instead of
##    crossing it (D-314) and never block the leader;
##  * a tie (nobody moved: spawn overlap) is settled by rank: player > NPC = enemy > ally.
## Shifts are capped per frame, so an overlap created by a teleport is absorbed in a few frames
## instead of popping.
##
## Debug: `last_report()` -> the worst penetration measured this frame, per pair.

const Footprint := preload("res://scripts/overworld/body_footprint.gd")
const PROCESS_PRIORITY := 1000
const MAX_PASSES := 6
const SLOP := 0.002            ## penetration below this is ignored (float noise)
const MAX_SPEED := 9.0         ## m/s ceiling of the correction
const WALL_PROBE_LIFT := 0.35  ## the wall probe floats this much above the floor (ramps are not walls)
const SCRIPTED_STATES := ["entering_portal", "exiting_portal", "away_in_portal"]

enum Kind { PLAYER, ALLY, NPC, ENEMY, OTHER }
const RANK := {Kind.PLAYER: 3, Kind.NPC: 2, Kind.ENEMY: 2, Kind.OTHER: 2, Kind.ALLY: 1}

var lab: Node
var enabled := true
var _last_pos: Dictionary = {}  ## actor instance id -> flat position after the previous solve
var _report: Dictionary = {}
var _frame_stats := {"max_penetration": 0.0, "pairs": 0, "corrections": 0}


static func attach(host: Node) -> BodySeparation:
	for c in host.get_children():
		if c is BodySeparation:
			return c
	var sep: BodySeparation = load("res://scripts/overworld/body_separation.gd").new()
	sep.name = "BodySeparation"
	sep.lab = host
	sep.process_priority = PROCESS_PRIORITY
	sep.process_physics_priority = PROCESS_PRIORITY
	host.add_child(sep)
	return sep


func _physics_process(delta: float) -> void:
	if enabled:
		solve(maxf(delta, 0.0001))


func _process(delta: float) -> void:
	# NPC patrols move in _process (not in the physics step): solve again before the frame is drawn.
	if enabled:
		solve(maxf(delta, 0.0001))


func last_report() -> Dictionary:
	return _report


## Returns the actors currently subject to separation: [{node, kind, r, h, pos(Vector3), v(float)}].
func gather() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	if lab == null:
		return out
	var pl := lab.get("player") as CollisionObject3D
	if pl != null:
		pl.collision_mask &= ~(1 << 4)  # o NPC não é mais parede física do líder: a separação o empurra
	_add(out, seen, lab.get("player"), Kind.PLAYER, {})
	var followers = lab.get("_followers")
	if followers is Array:
		for f in followers:
			if f is Dictionary:
				_add(out, seen, f.get("node"), Kind.ALLY, f)
	var npcs = lab.get("_npcs")
	if npcs is Array:
		for n in npcs:
			if n is Dictionary:
				_add(out, seen, n.get("node"), Kind.NPC, n)
	_add(out, seen, lab.get("_enemy_body"), Kind.ENEMY, {})
	_add(out, seen, lab.get("_second_enemy_body"), Kind.ENEMY, {})
	var rooms = lab.get("_room_enemies")
	if rooms is Array:
		for e in rooms:
			if e is Dictionary:
				_add(out, seen, e.get("node"), Kind.ENEMY, e)
	for extra in lab.get_tree().get_nodes_in_group("body_actor"):
		_add(out, seen, extra, Kind.OTHER, {})
	return out


func _add(out: Array[Dictionary], seen: Dictionary, node, kind: int, data: Dictionary) -> void:
	var n := node as Node3D
	if n == null or not is_instance_valid(n) or not n.is_inside_tree():
		return
	if not n.is_visible_in_tree() or seen.has(n.get_instance_id()):
		return
	if bool(n.get_meta("body_ghost", false)):
		return
	if str(data.get("state", "")) in SCRIPTED_STATES:
		return
	var model := data.get("model") as Node3D
	if model != null and is_instance_valid(model) and model.scale.x < 0.9:
		return  # shrinking into / growing out of the portal
	var fp := Footprint.info(n)
	if not bool(fp["measured"]):
		return  # the model is not built yet
	seen[n.get_instance_id()] = true
	out.append({
		"node": n, "kind": kind, "r": float(fp["radius"]), "h": float(fp["height"]),
		"pos": n.global_position, "v": 0.0,
		"pushable": kind != Kind.NPC or (data.get("waypoints", []) as Array).size() > 1,
	})


func solve(_delta: float) -> void:
	var actors := gather()
	var cap := MAX_SPEED * _delta
	for a in actors:
		var id := (a["node"] as Node3D).get_instance_id()
		var p: Vector3 = a["pos"]
		a["v"] = Vector2(p.x, p.z).distance_to(_last_pos[id]) if _last_pos.has(id) else 0.0
	var budget := {}  ## id -> metres already moved this call (the cap is per actor and frame)
	for pass_i in MAX_PASSES:
		var moved_any := false
		for i in actors.size():
			for j in range(i + 1, actors.size()):
				if _resolve_pair(actors[i], actors[j], cap, budget):
					moved_any = true
		if not moved_any:
			break
	var worst := 0.0
	var worst_pair := ""
	var pairs := 0
	for i in actors.size():
		for j in range(i + 1, actors.size()):
			var dep := penetration(actors[i], actors[j])
			pairs += 1
			if dep > worst:
				worst = dep
				worst_pair = "%s|%s" % [(actors[i]["node"] as Node).name, (actors[j]["node"] as Node).name]
	_report = {"max_penetration": worst, "pair": worst_pair, "pairs": pairs, "actors": actors.size()}
	for a in actors:
		var n := a["node"] as Node3D
		var p := n.global_position
		_last_pos[n.get_instance_id()] = Vector2(p.x, p.z)


## Overlap depth (m, >= 0) of two gathered actors on the floor plane; 0 when apart or on
## different floors (their vertical ranges do not intersect).
static func penetration(a: Dictionary, b: Dictionary) -> float:
	var ca := Footprint.capsule_of(a["node"] as Node3D)
	var cb := Footprint.capsule_of(b["node"] as Node3D)
	if absf(float(ca["y"]) - float(cb["y"])) > minf(float(a["h"]), float(b["h"])):
		return 0.0
	var cp := Footprint.closest_points(ca["p0"], ca["p1"], cb["p0"], cb["p1"])
	return maxf(0.0, float(ca["r"]) + float(cb["r"]) - (cp[0] as Vector2).distance_to(cp[1]))


func _resolve_pair(a: Dictionary, b: Dictionary, cap: float, budget: Dictionary) -> bool:
	var na := a["node"] as Node3D
	var nb := b["node"] as Node3D
	var ca := Footprint.capsule_of(na)
	var cb := Footprint.capsule_of(nb)
	if absf(float(ca["y"]) - float(cb["y"])) > minf(float(a["h"]), float(b["h"])):
		return false
	var cp := Footprint.closest_points(ca["p0"], ca["p1"], cb["p0"], cb["p1"])
	var delta2: Vector2 = (cp[0] as Vector2) - (cp[1] as Vector2)
	var dist := delta2.length()
	var need := float(ca["r"]) + float(cb["r"]) - dist
	if need <= SLOP:
		return false
	var dir := Vector3.ZERO
	if dist > 0.0001:
		dir = Vector3(delta2.x, 0.0, delta2.y) / dist
	else:
		var ax: Vector2 = ca["axis"]
		dir = Vector3(-ax.y, 0.0, ax.x)  # crossed segments: leave sideways of A
	var share_a := _yield_share(a, b)  # fraction of the correction moved by A (B moves the rest)
	var ida := na.get_instance_id()
	var idb := nb.get_instance_id()
	var step := need
	var cap_a := maxf(cap - float(budget.get(ida, 0.0)), 0.0)
	var cap_b := maxf(cap - float(budget.get(idb, 0.0)), 0.0)
	var want_a := minf(step * share_a, cap_a)
	var want_b := minf(step * (1.0 - share_a), cap_b)
	var applied_a := _shift(na, dir * want_a, float(a["r"]))
	var applied_b := _shift(nb, -dir * want_b, float(b["r"]))
	# A wall refused part of one shift: the other actor makes up for it (still capped).
	var short_a := want_a - applied_a.length()
	var short_b := want_b - applied_b.length()
	if short_a > 0.0005 and cap_b - applied_b.length() > 0.0:
		applied_b += _shift(nb, -dir * minf(short_a, cap_b - applied_b.length()), float(b["r"]))
	if short_b > 0.0005 and cap_a - applied_a.length() > 0.0:
		applied_a += _shift(na, dir * minf(short_b, cap_a - applied_a.length()), float(a["r"]))
	budget[ida] = float(budget.get(ida, 0.0)) + applied_a.length()
	budget[idb] = float(budget.get(idb, 0.0)) + applied_b.length()
	return applied_a.length() + applied_b.length() > 0.0001


## Share of the correction that A moves (0..1).
func _yield_share(a: Dictionary, b: Dictionary) -> float:
	var ka: int = a["kind"]
	var kb: int = b["kind"]
	# Criador (D-1269): NPC que NÃO se move é imóvel (segura quem anda contra ele); NPC que se move
	# (patrulha) pode ser empurrado e abre espaço para o líder, que nunca cede a ele.
	var ia: bool = ka == Kind.NPC and not bool(a.get("pushable", false))
	var ib: bool = kb == Kind.NPC and not bool(b.get("pushable", false))
	if ia and ib:
		return 0.5
	if ia:
		return 0.0
	if ib:
		return 1.0
	if ka == Kind.PLAYER and kb == Kind.NPC:
		return 0.0
	if kb == Kind.PLAYER and ka == Kind.NPC:
		return 1.0
	if ka == Kind.ALLY and kb != Kind.ALLY:
		return 1.0
	if kb == Kind.ALLY and ka != Kind.ALLY:
		return 0.0
	var va: float = a["v"]
	var vb: float = b["v"]
	if va + vb > 0.0005:
		return clampf(va / (va + vb), 0.0, 1.0)
	var ra: int = RANK[ka]
	var rb: int = RANK[kb]
	if ra == rb:
		return 0.5
	return 1.0 if ra < rb else 0.0


## Moves `node` by `v` on the floor plane, shortened by the world geometry. Returns what was applied.
func _shift(node: Node3D, v: Vector3, radius: float) -> Vector3:
	if v.length() < 0.00001:
		return Vector3.ZERO
	var world := node.get_world_3d()
	var applied := v
	if world != null:
		var probe_r := clampf(radius, 0.15, 0.45)
		var sphere := SphereShape3D.new()
		sphere.radius = probe_r
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = sphere
		q.transform = Transform3D(Basis(), node.global_position + Vector3(0.0, probe_r + WALL_PROBE_LIFT, 0.0))
		q.motion = v
		q.collision_mask = 1
		q.collide_with_bodies = true
		q.collide_with_areas = false
		var res := world.direct_space_state.cast_motion(q)
		if res.size() >= 2:
			applied = v * clampf(float(res[0]), 0.0, 1.0)
	node.global_position += applied
	return applied
