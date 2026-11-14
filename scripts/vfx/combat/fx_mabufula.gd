extends RefCounted
## D-1191: only reads Incoming and BattleFx's clock. Never changes the combat.
const Visual = preload("res://content/moves/mabufula/vfx.gd")
var fx: BattleFx
var _active: Dictionary = {}

func _init(p_fx: BattleFx) -> void:
	fx = p_fx

func start(inc) -> void:
	if String(inc.move_id) != "mabufula" and BattleFx.normalize_move_id(inc.label) != "mabufula":
		return
	if _active.has(inc):
		return
	var targets: Array = []
	# Membership of the actual target supplies the group; no species/side assumptions.
	var group: Array = fx.battle.party if fx.battle.party.has(inc.target) else fx.battle.enemies
	for c in group:
		if c.is_alive():
			targets.append(c)
	var node := Visual.new()
	node.name = "MabufulaVfx"
	fx.add_child(node)
	node.setup(fx.cam.camera if fx.cam != null else null)
	_active[inc] = {"node": node, "targets": targets, "hit_clock": -1.0, "cancel_clock": -1.0, "frame": {}, "last": {}}

func on_hit(attacker: Combatant, _target: Combatant, info: Dictionary) -> void:
	if bool(info.get("evaded", false)):
		return
	for inc in _active:
		if inc.attacker == attacker and float(_active[inc]["hit_clock"]) < 0.0 and not inc.interrupted:
			_active[inc]["hit_clock"] = fx.clock

func cancel(inc) -> void:
	if _active.has(inc):
		_active[inc]["cancel_clock"] = fx.clock

func clear_all() -> void:
	for inc in _active.keys():
		_stop(inc)

func _stop(inc) -> void:
	var node = _active[inc]["node"]
	if is_instance_valid(node):
		node.queue_free()
	_active.erase(inc)

func process(delta: float) -> void:
	for inc in _active.keys():
		var e: Dictionary = _active[inc]
		if not is_instance_valid(e["node"]):
			_active.erase(inc)
			continue
		# Status pause freezes this attack's presentation as well as Incoming.
		if fx.battle != null and fx.battle._status_pause != null:
			for key in ["hit_clock", "cancel_clock", "miss_clock"]:
				if float(e.get(key, -1.0)) >= 0.0:
					e[key] = float(e[key]) + delta
			continue
		if (e["frame"] as Dictionary).is_empty() or inc.phase == Incoming.Phase.WINDUP:
			e["frame"] = _frame(inc, e["targets"])
		var s: Dictionary = (e["frame"] as Dictionary).duplicate()
		s["wind"] = clampf(1.0 - inc.time_left / maxf(inc.total_windup, 0.01), 0.0, 1.0) if inc.phase == Incoming.Phase.WINDUP else 1.0
		s["travel"] = 0.0
		s["impact"] = -1.0
		s["fade"] = 1.0
		s["time"] = s["wind"] * inc.total_windup
		if float(e["cancel_clock"]) >= 0.0:
			var ct: float = fx.clock - float(e["cancel_clock"])
			if ct >= 0.45:
				_stop(inc)
				continue
			s = (e["last"] as Dictionary).duplicate()
			if s.is_empty():
				_stop(inc)
				continue
			s["fade"] = 1.0 - smoothstep(0.0, 0.45, ct)
		elif float(e["hit_clock"]) >= 0.0:
			s["impact"] = maxf(fx.clock - float(e["hit_clock"]), 0.0)
			s["travel"] = 1.0
			s["time"] = inc.total_windup + float(inc.plan[0][1]) + inc.fly + float(s["impact"])
			if float(s["impact"]) >= Visual.TAIL:
				_stop(inc)
				continue
		elif inc.phase == Incoming.Phase.TRAVEL:
			s["travel"] = clampf(inc.progress(), 0.0, 1.0)
			s["time"] = inc.total_windup + float(inc.plan[0][1]) + inc.phase_time
		elif inc.phase == Incoming.Phase.STRIKE:
			s["wind"] = 1.0
			s["time"] = inc.total_windup + inc.phase_time
		elif inc.phase != Incoming.Phase.WINDUP:
			if not e.has("miss_clock"):
				e["miss_clock"] = fx.clock
			var mt: float = fx.clock - float(e["miss_clock"])
			if mt >= 0.45:
				_stop(inc)
				continue
			s["travel"] = 1.0
			s["fade"] = 1.0 - smoothstep(0.0, 0.45, mt)
			s["time"] = inc.total_windup + float(inc.plan[0][1]) + inc.fly
		e["last"] = s
		e["node"].draw(s)

func _body(c: Combatant) -> AABB:
	var m = fx._models.get(c)
	if is_instance_valid(m):
		return fx.fx_armor.body_box_of(m)
	return AABB(c.pos, Vector3(0.6, 1.2, 0.6))

func _frame(inc, targets: Array) -> Dictionary:
	var a := _body(inc.attacker)
	var center := Vector3.ZERO
	var positions: Array[Vector3] = []
	var height := 0.0
	for c in targets:
		var b := _body(c)
		positions.append(Vector3(b.get_center().x, b.position.y, b.get_center().z))
		center += positions.back()
		height += b.size.y
	if positions.is_empty():
		positions.append(inc.target.pos)
		center = inc.target.pos
		height = 1.2
	center /= float(positions.size())
	height /= float(positions.size())
	var axis := center - a.get_center()
	axis.y = 0.0
	axis = axis.normalized() if axis.length_squared() > 0.001 else Vector3.FORWARD
	var right := axis.cross(Vector3.UP).normalized()
	positions.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.dot(right) < q.dot(right))
	var k := clampf(height / 1.2, 0.7, 2.0)
	var clusters: Array[Vector3] = []
	for i in 5:
		if positions.size() == 1:
			clusters.append(center + right * (float(i) - 2.0) * 0.85 * k + axis * (0.2 * cos(float(i) * 1.7) * k))
		else:
			var f := float(i) / 4.0 * float(positions.size() - 1)
			var j := mini(int(f), positions.size() - 2)
			clusters.append(positions[j].lerp(positions[j + 1], f - float(j)))
	var front := a.get_center() + axis * (maxf(a.size.x, a.size.z) * 0.55 + 0.45 * k)
	front.y = a.position.y + 0.10
	return {"front": front, "center": center, "axis": axis, "right": right, "clusters": clusters, "scale": k,
		"width": maxf(clusters[0].distance_to(clusters[4]) + 2.0 * k, 4.0 * k)}
