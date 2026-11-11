extends RefCounted
## Driver de batalha do VFX "Bubble Shot" (D-1170/D-308).
##
## O `Battle`/`Incoming` continua dono do relógio (D-019/D-1040): este módulo só lê
## `phase`, `phase_time`, `time_left`, `progress()`, `aim` e o contato real, e entrega
## esses números ao `BubbleShotVfx`. Nada de `is_player`, nome de personagem, time, lado
## ou coordenada fixa (D-235): frente do corpo, peito, chão e escala saem do modelo real.
## A bolha nasce à frente do corpo (D-958), não numa mão.

const BubbleShotVfxScript = preload("res://scripts/vfx/combat/bubble_shot_vfx.gd")
const MOVE_ID := "bubble_shot"

var fx: BattleFx
var _active: Dictionary = {}  ## Incoming -> {node, hit_clock, hit_chest, flight_duration, front}


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


static func is_move(inc) -> bool:
	if inc == null:
		return false
	return BattleFx.normalize_move_id(String(inc.label)) == MOVE_ID or String(inc.data.get("move_id", "")) == MOVE_ID


## Chamado no telegraph: o Move foi declarado e o wind-up começou.
func start(inc) -> void:
	if not is_move(inc) or _active.has(inc):
		return
	var node := BubbleShotVfxScript.new()
	node.name = "BubbleShotVfx"
	fx.add_child(node)
	node.setup(_camera())
	_active[inc] = {"node": node, "hit_clock": -1.0, "hit_chest": Vector3.ZERO, "flight_duration": 0.30}


func cancel(inc) -> void:
	_stop(inc)


func clear_all() -> void:
	for inc in _active.keys().duplicate():
		_stop(inc)
	_active.clear()


## O `BattleFx.play_hit` chama isto no contato real (mesmo quadro do dano).
func on_hit(attacker: Combatant, target: Combatant, _info: Dictionary) -> void:
	for inc in _active.keys():
		if inc.attacker != attacker or inc.target != target:
			continue
		var e: Dictionary = _active[inc]
		if float(e.get("hit_clock", -1.0)) >= 0.0:
			continue
		e["hit_clock"] = fx.clock
		e["hit_chest"] = _chest_of(target)
		_active[inc] = e
		return


func process(_delta: float) -> void:
	for inc in _active.keys().duplicate():
		var e: Dictionary = _active.get(inc, {})
		var node: BubbleShotVfx = e.get("node", null)
		if node == null or not is_instance_valid(node):
			_active.erase(inc)
			continue
		if inc.attacker == null or inc.target == null:
			_stop(inc)
			continue

		var chest := _chest_of(inc.target)
		var ground := _ground_of(inc.target)
		# The front point is frozen at launch so the crown and wake keep their origin.
		var front: Vector3 = e["front"] if e.has("front") else _front_of(inc.attacker, chest)
		var s := {
			"stage": "windup",
			"now": fx.clock,
			"front": front,
			"chest": chest,
			"ground_y": ground,
			"vs_front": _view_scale_at(front) * _body_k(inc.attacker),
			"vs_chest": _view_scale_at(chest) * _body_k(inc.target),
			"vs_impact": _view_scale_at(chest),  # impact_scale already measures the target's body
			"impact_scale": _impact_scale(inc.target),
			"windup_total": maxf(float(inc.total_windup), 0.01),
			"windup_t": 0.0,
			"flight_u": 0.0,
			"flight_duration": float(e.get("flight_duration", 0.30)),
			"since_impact": -1.0,
			"impact_chest": chest,
			"miss_t": 0.0,
		}

		if float(e.get("hit_clock", -1.0)) >= 0.0:
			s["stage"] = "impact"
			s["since_impact"] = maxf(fx.clock - float(e["hit_clock"]), 0.0)
			s["impact_chest"] = e["hit_chest"]
			s["flight_u"] = 1.0
			if float(s["since_impact"]) > BubbleShotVfx.IMPACT_LEN + 0.06:
				_stop(inc)
				continue
		elif inc.phase == Incoming.Phase.WINDUP:
			s["windup_t"] = clampf(float(s["windup_total"]) - maxf(float(inc.time_left), 0.0), 0.0, float(s["windup_total"]))
		elif inc.phase == Incoming.Phase.STRIKE:
			# Projectile STRIKE = the throw gesture before the shot is born: bubble stays full.
			s["windup_t"] = s["windup_total"]
		elif inc.phase == Incoming.Phase.TRAVEL:
			if not e.has("front"):
				e["front"] = front
				e["flight_duration"] = maxf(float(inc.phase_len()), 0.01)
				_active[inc] = e
				s["flight_duration"] = e["flight_duration"]
			s["stage"] = "flight"
			s["flight_u"] = clampf(inc.progress(), 0.0, 1.0)
		elif inc.phase == Incoming.Phase.RETURN:
			# RETURN with no hit = dodge/interruption: the bubble pops where it missed.
			s["stage"] = "miss"
			s["miss_t"] = maxf(float(inc.phase_time), 0.0)
			s["flight_u"] = 1.0
			if inc.aim != Vector3.ZERO:
				s["chest"] = Vector3(inc.aim.x, chest.y, inc.aim.z)
			if float(s["miss_t"]) > maxf(BubbleShotVfx.MISS_LEN, BubbleShotVfx.BOUNCE_LEN):
				_stop(inc)
				continue
		else:
			_stop(inc)
			continue
		node.draw(s)


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


func _body_box(c: Combatant) -> AABB:
	if c == null or fx == null:
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


func _ground_of(c: Combatant) -> float:
	var box := _body_box(c)
	return box.position.y if box.size.length() > 0.01 else 0.0


func _impact_scale(c: Combatant) -> float:
	var box := _body_box(c)
	var radius := 0.55
	if box.size.length() > 0.01:
		radius = clampf(maxf(box.size.x, box.size.z) * 0.5, 0.25, 1.5)
	return clampf(radius * 1.6, 0.75, 1.65)


## D-958: the charge is born in front of the body, on the attacker->target axis, clear
## of the silhouette, measured from the real model.
func _front_of(attacker: Combatant, chest: Vector3) -> Vector3:
	var box := _body_box(attacker)
	var center := fx.drawn_body_center(attacker) if attacker != null else Vector3.ZERO
	var radius := 0.5
	var height := 1.9
	var ground := 0.0
	if box.size.length() > 0.01:
		center = box.get_center()
		radius = clampf(maxf(box.size.x, box.size.z) * 0.5, 0.25, 1.8)
		height = box.size.y
		ground = box.position.y
	var dir := chest - center
	dir.y = 0.0
	dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector3.FORWARD
	var probe := Vector3(center.x, ground + height * 0.55, center.z) + dir * (radius + 0.6)
	var bubble_r := BubbleShotVfx.R_MAIN * _view_scale_at(probe) * _body_k(attacker)
	var y := maxf(ground + height * 0.55, ground + bubble_r * 1.15)
	return Vector3(center.x, y, center.z) + dir * (radius + bubble_r + 0.25)


func _view_scale_at(pos: Vector3) -> float:
	if fx == null:
		return 1.0
	return clampf(fx.vfx_scale_at(pos), 1.0, 3.2)


## The prototype's metres assume a ~1.95 m actor. Bodies in battle are larger, so the
## effect keeps the same proportion to the real body it is next to (measured, D-235).
func _body_k(c: Combatant) -> float:
	var box := _body_box(c)
	if box.size.length() <= 0.01:
		return 1.0
	return clampf(box.size.y / 1.95, 1.0, 2.2)
