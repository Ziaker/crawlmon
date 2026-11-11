extends Node
## D-1157: aliado vê um item, mostra "!", corre e coleta.
## Percepção curta + raycast de parede; o card azul é responsabilidade do lab.

enum State { SCAN, ALERT, RUN, COLLECTED }

const DETECT_RANGE := 6.0
const LEASH_RANGE := 8.0
const ALERT_TIME := 0.4
const RUN_SPEED := 5.2
const COLLECT_HOLD := 0.65
const PICKUP_RADIUS := 1.25
const ALERT_TEX := preload("res://assets/ui/overworld_icons/state_alert.png")

var _lab: Node3D
var _f: Dictionary
var _body: CharacterBody3D
var _player: Node3D
var _agent: NavigationAgent3D
var _ap: AnimationPlayer
var _dust: CPUParticles3D
var _height := 1.4
var _state := State.SCAN
var _timer := 0.0
var _target: Node3D
var _item_id := ""
var _alert_icon: Node3D


func setup(lab: Node3D, follower: Dictionary, player: Node3D) -> void:
	_lab = lab
	_f = follower
	_body = follower["node"]
	_player = player
	_agent = follower["agent"]
	_ap = follower["ap"]
	_dust = follower["dust"]
	_height = float(follower["height"])


func _physics_process(delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		return
	match _state:
		State.SCAN:
			if not bool(_f.get("busy", false)):
				var item := _find_item()
				if item != null:
					_target = item
					_item_id = str(item.get("item_id"))
					_state = State.ALERT
					_timer = ALERT_TIME
					_show_alert()
					print("[D-1157] ALERT item=", _item_id,
						" dist=", _flat_dist(item))
		State.ALERT:
			if not _valid_target():
				_abort()
				return
			_timer -= delta
			if _timer <= 0.0:
				_f["busy"] = true
				_state = State.RUN
				print("[D-1157] RUN item=", _item_id,
					" dist=", _flat_dist(_target))
		State.RUN:
			if not _valid_target():
				_on_collected()
				return
			var to := _target.global_position - _body.global_position
			to.y = 0.0
			var dist := to.length()
			if dist <= PICKUP_RADIUS + 0.05:
				_body.velocity = Vector3.ZERO
				_f["velocity"] = Vector3.ZERO
				_play_run(false)
				_dust.emitting = false
				return
			var dir := to.normalized()
			_body.velocity = dir * RUN_SPEED
			_body.move_and_slide()
			_f["velocity"] = _body.velocity
			var yaw := atan2(dir.x, dir.z)
			_body.rotation.y = lerp_angle(_body.rotation.y, yaw, clampf(delta * 12.0, 0.0, 1.0))
			_play_run(true)
			_dust.emitting = true
		State.COLLECTED:
			_body.velocity = Vector3.ZERO
			_f["velocity"] = Vector3.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_finish()


func _valid_target() -> bool:
	return _target != null and is_instance_valid(_target) \
		and not bool(_target.get("_taken"))


func _flat_dist(node: Node3D) -> float:
	var flat := node.global_position - _body.global_position
	flat.y = 0.0
	return flat.length()


func _find_item() -> Node3D:
	var best: Node3D = null
	var best_dist := DETECT_RANGE
	for node in get_tree().get_nodes_in_group("overworld_item"):
		if not node is Node3D:
			continue
		var item := node as Node3D
		if bool(item.get("_taken")):
			continue
		var dist := _flat_dist(item)
		if dist > DETECT_RANGE or dist <= PICKUP_RADIUS + 0.2 or dist >= best_dist:
			continue
		var leash := item.global_position.distance_to(_player.global_position)
		if leash > LEASH_RANGE:
			continue
		var player_dist := item.global_position.distance_to(_player.global_position)
		if player_dist <= PICKUP_RADIUS + 0.2:
			continue
		if not _has_los(item):
			continue
		best = item
		best_dist = dist
	return best


func _has_los(item: Node3D) -> bool:
	var from := _body.global_position + Vector3(0.0, _height * 0.6, 0.0)
	var to := item.global_position + Vector3(0.0, 0.1, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [_body.get_rid()]
	var space := _body.get_world_3d().direct_space_state
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return true
	var hit_pos: Vector3 = hit["position"]
	return from.distance_to(hit_pos) >= from.distance_to(to) - 0.15


func _show_alert() -> void:
	if _alert_icon == null:
		var entry: Dictionary = _lab.call("_add_state_icon", _body,
			Vector3(0.35, _height + 0.8, 0.0),
			clampf(_height / 1.2, 0.55, 1.0))
		entry["base_scale"] = 1.0
		_alert_icon = entry.get("sprite")
	if _alert_icon != null:
		_alert_icon.visible = true
		_alert_icon.call("set_state", ALERT_TEX, Color(1.0, 0.85, 0.25))


func _play_run(run: bool) -> void:
	_lab.call("_play_move", _ap, run)
	_ap.speed_scale = 1.45 if run else 1.0


func _on_collected() -> void:
	_state = State.COLLECTED
	_timer = COLLECT_HOLD
	_body.velocity = Vector3.ZERO
	_f["velocity"] = Vector3.ZERO
	_play_run(false)
	_dust.emitting = false
	_hide_alert()
	print("[D-1157] COLLECTED item=", _item_id)


func _abort() -> void:
	_target = null
	_item_id = ""
	_state = State.SCAN
	_f["busy"] = false
	_hide_alert()
	_play_run(false)
	_dust.emitting = false


func _finish() -> void:
	_target = null
	_item_id = ""
	_state = State.SCAN
	_f["busy"] = false
	_body.velocity = Vector3.ZERO
	_f["velocity"] = Vector3.ZERO
	_play_run(false)
	_dust.emitting = false
	_hide_alert()
	print("[D-1157] FOLLOW")


func _hide_alert() -> void:
	if _alert_icon != null and is_instance_valid(_alert_icon):
		_alert_icon.visible = false


func state_name() -> String:
	return State.keys()[_state]
