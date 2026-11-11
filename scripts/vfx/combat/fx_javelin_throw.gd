extends RefCounted
## Driver de batalha do VFX "Javelin Throw" (D-1162/D-308).
##
## O `Battle`/`Incoming` continua dono do relógio (D-019/D-1040): este módulo só lê
## `phase`, `phase_time`, `time_left`, `progress()`, `aim` e `impacted` e entrega esses
## números ao `JavelinThrowVfx`. Nada de `is_player`, nome de personagem, time, lado ou
## coordenada fixa (D-235): mão, peito, pés e escala saem do modelo real.

const JavelinThrowVfxScript = preload("res://scripts/vfx/combat/javelin_throw_vfx_html.gd")
const MOVE_ID := "javelin_throw"

var fx: BattleFx
var _active: Dictionary = {}  ## Incoming -> {node, launch_clock, hit_clock, hit_chest, hit_crit}


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## Chamado no telegraph: o Move foi declarado e o wind-up começou.
func start(inc) -> void:
	if inc == null:
		return
	if BattleFx.normalize_move_id(String(inc.label)) != MOVE_ID and String(inc.move_id) != MOVE_ID:
		return
	if _active.has(inc):
		return
	var node := JavelinThrowVfxScript.new()
	node.name = "JavelinThrowVfx"
	fx.add_child(node)
	node.setup(_camera())
	if inc.data is Dictionary:
		inc.data["javelin"] = node
	_active[inc] = {
		"node": node,
		"launch_clock": -1.0,
		"hit_clock": -1.0,
		"hit_chest": Vector3.ZERO,
		"hit_crit": false,
		"flight_duration": 0.30,
	}


func cancel(inc) -> void:
	_stop(inc)


func clear_all() -> void:
	for inc in _active.keys().duplicate():
		_stop(inc)
	_active.clear()


## O `BattleFx.play_hit` chama isto no contato real (mesmo frame do dano).
func on_hit(attacker: Combatant, target: Combatant, info: Dictionary) -> void:
	for inc in _active.keys():
		if inc.attacker != attacker or inc.target != target:
			continue
		var e: Dictionary = _active[inc]
		if float(e.get("hit_clock", -1.0)) >= 0.0:
			continue
		e["hit_clock"] = fx.clock
		e["hit_chest"] = _chest_of(target)
		e["hit_crit"] = bool(info.get("crit", false))
		_active[inc] = e
		return


func process(_delta: float) -> void:
	var dbg := OS.get_cmdline_user_args().has("--javelin-debug")
	for inc in _active.keys().duplicate():
		var e: Dictionary = _active.get(inc, {})
		var node: JavelinThrowVfxHtml = e.get("node", null)
		if node == null or not is_instance_valid(node):
			_active.erase(inc)
			continue
		if inc.attacker == null or inc.target == null:
			_stop(inc)
			continue

		var anchors := _anchors(inc)
		var stage := "windup"
		var windup_t := 0.0
		var windup_total := maxf(float(inc.total_windup), 0.01)
		var flight_u := 0.0
		var flight_t := 0.0
		var flight_duration := 0.30
		var release_t := -1.0
		var since_impact := -1.0
		var impact_chest: Vector3 = anchors["chest"]
		var miss_t := 0.0
		var crit := bool(e.get("hit_crit", false))

		if float(e.get("hit_clock", -1.0)) >= 0.0:
			stage = "impact"
			since_impact = maxf(fx.clock - float(e["hit_clock"]), 0.0)
			impact_chest = e["hit_chest"]
			release_t = fx.clock - float(e["launch_clock"]) if float(e["launch_clock"]) >= 0.0 else -1.0
			flight_u = 1.0
			flight_t = float(inc.phase_time)
			flight_duration = maxf(float(e.get("flight_duration", 0.30)), 0.01)
			if since_impact > 0.86:
				_stop(inc)
				continue
		elif inc.phase == Incoming.Phase.WINDUP:
			stage = "windup"
			windup_t = clampf(windup_total - maxf(float(inc.time_left), 0.0), 0.0, windup_total)
		elif inc.phase == Incoming.Phase.TRAVEL:
			if float(e.get("launch_clock", -1.0)) < 0.0:
				e["launch_clock"] = fx.clock - maxf(float(inc.phase_time), 0.0)
				e["flight_duration"] = maxf(float(inc.phase_len()), 0.01)
				_active[inc] = e
			stage = "flight"
			flight_u = clampf(inc.progress(), 0.0, 1.0)
			flight_t = maxf(float(inc.phase_time), 0.0)
			flight_duration = maxf(float(e.get("flight_duration", 0.30)), 0.01)
			release_t = maxf(fx.clock - float(e["launch_clock"]), 0.0)
		elif inc.phase == Incoming.Phase.STRIKE:
			# O STRIKE de um projétil é o arremesso antes de o projétil nascer: a lança
			# continua montada e apontada; a coroa só começa quando o TRAVEL começa.
			stage = "windup"
			windup_t = windup_total
		elif inc.phase == Incoming.Phase.RETURN:
			# RETURN sem hit = esquiva/interrupção: o dardo passa e se dissolve.
			stage = "miss"
			miss_t = maxf(float(inc.phase_time), 0.0)
			if miss_t > 0.24:
				_stop(inc)
				continue
			if inc.aim != Vector3.ZERO:
				var miss_chest: Vector3 = inc.aim
				miss_chest.y = _chest_of(inc.target).y
				anchors["chest"] = miss_chest
				anchors["axis"] = ((anchors["chest"] as Vector3) - (anchors["hand"] as Vector3)).normalized()
				anchors["distance"] = (anchors["hand"] as Vector3).distance_to(anchors["chest"] as Vector3)
		else:
			_stop(inc)
			continue

		var view_scale := float(anchors["view_scale"])
		var target_view_scale := float(anchors["target_view_scale"])
		if stage == "impact":
			target_view_scale = _view_scale_at(impact_chest)
			view_scale = target_view_scale
		elif stage == "flight":
			var scale_pos: Vector3 = (anchors["hand"] as Vector3).lerp(
				anchors["chest"] as Vector3, flight_u)
			view_scale = _view_scale_at(scale_pos)

		node.draw({
			"stage": stage,
			"hand": anchors["hand"],
			"chest": anchors["chest"],
			"feet": anchors["feet"],
			"axis": anchors["axis"],
			"distance": anchors["distance"],
			"impact_scale": anchors["impact_scale"],
			"target_radius": anchors["target_radius"],
			"view_scale": view_scale,
			"target_view_scale": target_view_scale,
			"attacker_body_box": anchors["attacker_body_box"],
			"windup_t": windup_t,
			"windup_total": windup_total,
			"flight_u": flight_u,
			"flight_t": flight_t,
			"flight_duration": flight_duration,
			"release_t": release_t,
			"since_impact": since_impact,
			"impact_chest": impact_chest,
			"crit": crit,
			"miss_t": miss_t,
		})
		if dbg and stage == "impact" and since_impact >= 0.0 and since_impact <= 0.05:
			var ds: Dictionary = node.debug_state()
			print("[javelin_battle] stage=", stage, " since=", since_impact, " hand=", anchors["hand"],
				" chest=", anchors["chest"], " impact_chest=", impact_chest,
				" view=", view_scale, " target_view=", target_view_scale, " impact=", anchors["impact_scale"],
				" tip=", ds.get("tip"), " tail=", ds.get("tail"), " cam=", fx._cam_pos(),
				" spear_vis=", ds.get("spear_visible"), " p0=", ds.get("piece0_visible"),
				" p4=", ds.get("piece4_visible"), " a0=", ds.get("piece0_alpha"),
				" a4=", ds.get("piece4_alpha"), " cross=", ds.get("cross_vis"),
				" cscale=", ds.get("cross_scale"))


func _stop(inc) -> void:
	var e: Dictionary = _active.get(inc, {})
	var node = e.get("node", null)
	if node != null and is_instance_valid(node):
		node.queue_free()
	_active.erase(inc)


func _camera() -> Camera3D:
	if fx != null and fx.cam != null:
		return fx.cam.camera
	return null


func _anchors(inc) -> Dictionary:
	var tgt_box := _body_box(inc.target)
	var chest := Vector3.ZERO
	var radius := 0.55
	var height := 1.9
	var ground := 0.0
	if tgt_box.size.length() > 0.01:
		var c := tgt_box.get_center()
		height = tgt_box.size.y
		radius = clampf(maxf(tgt_box.size.x, tgt_box.size.z) * 0.5, 0.25, 1.5)
		chest = Vector3(c.x, lerpf(tgt_box.position.y, tgt_box.end.y, 0.62), c.z)
		ground = tgt_box.position.y
	else:
		chest = fx.drawn_body_center(inc.target)
		ground = 0.0
	# Socket real tem prioridade sobre a fração do AABB (D-235/prompt).
	var tgt_model = fx._models.get(inc.target)
	var chest_socket := _socket_named(tgt_model, ["ChestSocket", "TorsoSocket", "ImpactSocket", "Chest"])
	if chest_socket != null:
		chest = chest_socket.global_position

	var att_box := _body_box(inc.attacker)
	var hand := _hand_of(inc.attacker, chest, att_box)
	var axis := chest - hand
	if axis.length_squared() < 0.0001:
		axis = Vector3.FORWARD
	else:
		axis = axis.normalized()
	var distance := maxf(hand.distance_to(chest), 0.5)
	var impact_scale := clampf(radius * 1.6, 0.75, 1.65)
	return {
		"hand": hand,
		"chest": chest,
		"feet": Vector3(chest.x, ground, chest.z),
		"axis": axis,
		"distance": distance,
		"impact_scale": impact_scale,
		"target_radius": radius,
		# A javelin vive na mão do atacante: a escala dela vem da mão, não do alvo.
		# O alvo (retículo/impacto) tem a própria escala.
		"view_scale": _view_scale_at(hand),
		"target_view_scale": _view_scale_at(chest),
		"attacker_body_box": att_box,
	}


func _body_box(c: Combatant) -> AABB:
	if c == null:
		return AABB()
	var m = fx._models.get(c)
	if m == null or not is_instance_valid(m):
		return AABB()
	return fx.fx_armor.body_box_of(m)


func _chest_of(c: Combatant) -> Vector3:
	var box := _body_box(c)
	if box.size.length() > 0.01:
		var center := box.get_center()
		return Vector3(center.x, lerpf(box.position.y, box.end.y, 0.62), center.z)
	if c == null:
		return Vector3.ZERO
	return fx.drawn_body_center(c)


func _hand_of(attacker: Combatant, chest: Vector3, att_box: AABB) -> Vector3:
	var m = fx._models.get(attacker)
	if m != null and is_instance_valid(m):
		var sock := _socket_named(m, ["HandSocket", "WeaponSocket", "RightHand", "Hand"])
		if sock != null:
			return sock.global_position
		var sk := _skeleton_of(m)
		if sk != null:
			var idx := _hand_bone(sk)
			if idx >= 0:
				return sk.global_transform * sk.get_bone_global_pose(idx).origin

	var center := Vector3.ZERO
	var radius := 0.5
	var height := 1.9
	var ground := 0.0
	if att_box.size.length() > 0.01:
		center = att_box.get_center()
		radius = clampf(maxf(att_box.size.x, att_box.size.z) * 0.5, 0.25, 1.5)
		height = att_box.size.y
		ground = att_box.position.y
	elif attacker != null:
		center = fx.drawn_body_center(attacker)
		ground = 0.0
	var dir := chest - center
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	var right := Vector3.UP.cross(dir)
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	right = right.normalized()
	return Vector3(center.x, ground + height * 0.72, center.z) + right * (radius * 0.30)


func _socket_named(model: Node3D, names: Array) -> Node3D:
	if model == null or not is_instance_valid(model):
		return null
	for n in model.find_children("*", "Node3D", true, false):
		var nm := String(n.name).to_lower()
		for wanted in names:
			var w := String(wanted).to_lower()
			if nm == w or nm.begins_with(w):
				return n as Node3D
	return null


func _skeleton_of(model: Node3D) -> Skeleton3D:
	for n in model.find_children("*", "Skeleton3D", true, false):
		var sk := n as Skeleton3D
		if sk != null:
			return sk
	return null


func _hand_bone(sk: Skeleton3D) -> int:
	var best := -1
	var best_score := -100
	for i in range(sk.get_bone_count()):
		var n := sk.get_bone_name(i).to_lower()
		if not ("hand" in n or "wrist" in n or "palm" in n or "weapon" in n):
			continue
		if "finger" in n or "thumb" in n or "index" in n or "middle" in n or "ring" in n or "pinky" in n:
			continue
		var score := 0
		if "hand" in n:
			score += 4
		if "wrist" in n:
			score += 3
		if "weapon" in n:
			score += 2
		if "right" in n or n.ends_with("_r") or n.ends_with(".r") or n.ends_with(" r"):
			score += 2
		if "left" in n or n.ends_with("_l") or n.ends_with(".l") or n.ends_with(" l"):
			score -= 1
		if score > best_score:
			best_score = score
			best = i
	return best


func _view_scale_at(pos: Vector3) -> float:
	if fx == null:
		return 1.0
	return clampf(fx.vfx_scale_at(pos), 1.0, 3.2)
