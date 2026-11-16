class_name HubArrivalCutscene
extends Node
## Hub arrival cutscene: the leader falls from the sky onto the plaza centre.
##
## Created by HubArrivalCutscene.attach(hub, transition). The partner node
## NatureHubTransition (group "nature_hub_transition") owns the clock and the
## state (D-1040); this node has no timer of its own and only reads `state`
## and `progress()` each physics frame to pose the leader and the camera.
##
## D-1214: the transition layer draws the letterbox bars.
## D-418: no full-screen flash anywhere in here.
## D-1060: the body stays fully in frame. D-235: every size derives from
## hub.player_height, never from the species.
##
## With no transition node the hub never creates this node, so the normal game
## flow is exactly the old one.

const TUNING := {
	"fall_height_m": 9.0,        # D-1237 fall distance above the plaza floor
	"reveal_cam_dist_m": 11.0,   # D-1237 distance of the open reveal shot
	"reveal_cam_height_m": 8.0,  # D-1237 height of the open reveal shot
	"fall_cam_lag_m": 1.6,       # D-1237 extra camera height at the end of FALL
	"shake_m": 0.09,             # D-1237 peak camera shake at the landing
	"shake_cycles": 3.0,         # D-1237 oscillating cycles of the landing shake
	"shake_end": 0.55,           # D-1237 LAND progress where the shake is gone
	"squash_y": 0.72,            # D-1237 vertical model scale at the landing
	"squash_xz": 1.12,           # D-1237 horizontal model scale at the landing
	"squash_at": 0.18,           # D-1237 LAND progress of the deepest squash
	"squash_end": 0.55,          # D-1237 LAND progress where the model is back
	"circle_r_m": 2.1,           # D-1237 summoning circle radius on the floor
	"body_at_land": 0.07,        # D-1237 LAND progress where the body appears in the flare
	"fall_look_mix": 0.4,        # D-1237 how much the FALL camera follows the comet (0 floor, 1 comet)
}

var _hub: Node = null
var _transition: Node = null
var _player: CharacterBody3D = null
var _player_model: Node3D = null
var _camera: Camera3D = null
var _player_height := 1.0
var _base_yaw := PI
var _base_model_scale := Vector3.ONE
var _ground_y := 0.0
var _final_cam := Transform3D.IDENTITY
var _final_look := Vector3.ZERO
var _last_state := ""
var _peak_shake := 0.0
var _finished := false
var _print_summary := false
var _fx: HubSummonFx = null


static func attach(hub_node: Node, transition_node: Node) -> HubArrivalCutscene:
	var cutscene := HubArrivalCutscene.new()
	cutscene.name = "HubArrivalCutscene"
	hub_node.add_child(cutscene)
	cutscene._setup(hub_node, transition_node)
	return cutscene


func _setup(hub_node: Node, transition_node: Node) -> void:
	_hub = hub_node
	_transition = transition_node
	_print_summary = _has_user_arg("--nht-summary")
	_player = hub_node.get("player") as CharacterBody3D
	_player_model = hub_node.get("player_model") as Node3D
	_camera = hub_node.get("_camera") as Camera3D
	var height_value: Variant = hub_node.get("player_height")
	if height_value != null:
		_player_height = maxf(float(height_value), 0.1)
	var yaw_value: Variant = hub_node.get("player_yaw")
	if yaw_value != null:
		_base_yaw = float(yaw_value)
	if _player == null or _camera == null:
		return
	if _player_model != null:
		_base_model_scale = _player_model.scale
	_ground_y = _floor_y_at()
	_player.global_position = Vector3(0.0, _ground_y, 0.0)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = _base_yaw
	# The hub computes the pose its own _update_camera produces for the leader
	# standing on the plaza centre, so LAND can end exactly on it (no jump).
	hub_node.set("_cam_yaw", _base_yaw)
	hub_node.set("_cam_smooth_ready", false)
	hub_node.call("_update_camera", 0.0)
	_final_cam = _camera.global_transform
	_final_look = _final_cam.origin + (-_final_cam.basis.z) * 10.0
	_set_player_visible(false)
	_player.global_position = Vector3(0.0, _ground_y + _fall_height(), 0.0)
	_fx = HubSummonFx.new()
	_fx.name = "SummonFx"
	add_child(_fx)
	_fx.global_position = Vector3(0.0, _ground_y, 0.0)
	_fx.build(float(TUNING["circle_r_m"]) * _body_scale())


func _floor_y_at() -> float:
	if _player == null:
		return 0.0
	var world := _player.get_world_3d()
	if world == null:
		return _player.global_position.y
	var from := Vector3(0.0, _player.global_position.y + 3.0, 0.0)
	var to := Vector3(0.0, _player.global_position.y - 5.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_player.get_rid()]
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return _player.global_position.y
	return float(hit["position"].y)


func apply(_delta: float) -> void:
	if _finished:
		return
	if _transition == null or not is_instance_valid(_transition):
		_finish()
		return
	if _player == null or _camera == null:
		_finish()
		return
	var state_name := str(_transition.get("state"))
	if state_name != _last_state:
		_last_state = state_name
		_on_state_enter(state_name)
	var progress_value: Variant = _transition.call("progress")
	var p := 0.0
	if progress_value != null:
		p = clampf(float(progress_value), 0.0, 1.0)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = _base_yaw
	if _fx != null:
		var fall_p := p if state_name == "FALL" else (1.0 if state_name == "LAND" else 0.0)
		_fx.pose(state_name, p, float(_transition.get("total_ms")) / 1000.0, _fall_height() * (1.0 - fall_p * fall_p))
	match state_name:
		"EXIT", "LOADING_LOOP":
			_hold_above()
		"REVEAL":
			_hold_above()
			_place_reveal_camera()
		"FALL":
			# The body is the comet inside the pillar: the model only appears at the impact.
			_set_player_visible(false)
			_player.global_position = Vector3(0.0, _ground_y + _fall_height() * (1.0 - p * p), 0.0)
			_place_fall_camera(p)
		"LAND":
			_set_player_visible(p >= float(TUNING["body_at_land"]))
			_player.global_position = Vector3(0.0, _ground_y, 0.0)
			_place_land_camera(p)
			_apply_squash(p)
		"CONTROL":
			_player.global_position = Vector3(0.0, _ground_y, 0.0)
			_finish()


func _on_state_enter(state_name: String) -> void:
	if state_name == "REVEAL":
		_set_player_visible(false)
	elif state_name in ["FALL", "LAND"]:
		_peak_shake = 0.0


# --- Closed-form poses (all sizes from hub.player_height, D-235) --------------

func _forward() -> Vector3:
	return Vector3(sin(_base_yaw), 0.0, cos(_base_yaw))


func _centre() -> Vector3:
	return Vector3(0.0, _ground_y, 0.0)


func _body_scale() -> float:
	return clampf(_player_height, 1.0, 2.0)


func _fall_height() -> float:
	return float(TUNING["fall_height_m"]) * _body_scale()


func _reveal_pos() -> Vector3:
	var distance := float(TUNING["reveal_cam_dist_m"]) * _body_scale()
	var height := float(TUNING["reveal_cam_height_m"]) * _body_scale()
	return _centre() - _forward() * distance + Vector3(0.0, height, 0.0)


func _reveal_look() -> Vector3:
	return _centre() + Vector3(0.0, _player_height * 0.5, 0.0)


func _fall_cam_end() -> Vector3:
	# Still a wide shot when the pillar hits: the flare never fills the frame (D-418).
	return _reveal_pos().lerp(_final_cam.origin, 0.3) + Vector3(0.0, float(TUNING["fall_cam_lag_m"]) * _body_scale(), 0.0)


func _fall_look() -> Vector3:
	return _centre() + Vector3(0.0, _player_height * 0.45, 0.0)


func _place_camera(pos: Vector3, look: Vector3) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	_camera.global_position = pos
	_camera.look_at(look, Vector3.UP)


func _place_reveal_camera() -> void:
	_place_camera(_reveal_pos(), _reveal_look())


func _place_fall_camera(p: float) -> void:
	# The camera stays high while the body crosses the frame over the plaza,
	# and only dives after it near the end of the fall.
	var e := p * p * p
	var pos := _reveal_pos().lerp(_fall_cam_end(), e)
	var body_y := _ground_y + _fall_height() * (1.0 - p * p)
	var look_y := lerpf(_ground_y + _player_height * 0.45, body_y + _player_height * 0.45, float(TUNING["fall_look_mix"]) * (1.0 - p))
	_place_camera(pos, Vector3(0.0, look_y, 0.0))


func _place_land_camera(p: float) -> void:
	# Hold the wide shot through the flare, then travel to the hub camera.
	var q := clampf((p - 0.22) / 0.78, 0.0, 1.0)
	var e := q * q * (3.0 - 2.0 * q)
	var pos := _fall_cam_end().lerp(_final_cam.origin, e)
	var look := _fall_look().lerp(_final_look, e)
	var shake_end := maxf(float(TUNING["shake_end"]), 0.0001)
	var decay := clampf(1.0 - p / shake_end, 0.0, 1.0)
	decay *= decay
	if decay > 0.0:
		var amplitude := float(TUNING["shake_m"]) * _body_scale() * decay
		var phase := p * TAU * float(TUNING["shake_cycles"])
		var offset := Vector3(sin(phase), cos(phase * 1.7) * 0.6, cos(phase) * 0.5) * amplitude
		pos += offset
		_peak_shake = maxf(_peak_shake, offset.length())
	_place_camera(pos, look)


func _apply_squash(p: float) -> void:
	if _player_model == null or not is_instance_valid(_player_model):
		return
	var hit_at := maxf(float(TUNING["squash_at"]), 0.0001)
	var back_at := maxf(float(TUNING["squash_end"]), hit_at + 0.0001)
	var down := clampf(p / hit_at, 0.0, 1.0)
	var up := clampf((p - hit_at) / (back_at - hit_at), 0.0, 1.0)
	var amount := (1.0 - cos(down * PI)) * 0.5
	amount *= 1.0 - (1.0 - cos(up * PI)) * 0.5
	var xz := 1.0 + (float(TUNING["squash_xz"]) - 1.0) * amount
	var sy := 1.0 + (float(TUNING["squash_y"]) - 1.0) * amount
	_player_model.scale = _base_model_scale * Vector3(xz, sy, xz)


func _set_player_visible(visible_now: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.visible == visible_now:
		return
	_player.visible = visible_now


func _hold_above() -> void:
	_set_player_visible(false)
	if _player != null and is_instance_valid(_player):
		_player.global_position = Vector3(0.0, _ground_y + _fall_height(), 0.0)


# --- Hand-back to the hub at CONTROL ----------------------------------------

func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _player_model != null and is_instance_valid(_player_model):
		_player_model.scale = _base_model_scale
	_set_player_visible(true)
	if _player != null and is_instance_valid(_player):
		_player.velocity = Vector3.ZERO
		_player.global_position = Vector3(0.0, _ground_y, 0.0)
	var last_cam := Vector3.ZERO
	if _camera != null and is_instance_valid(_camera):
		last_cam = _camera.global_position
	if _hub != null and is_instance_valid(_hub):
		_hub.set("_cam_smooth_ready", false)
		if _hub.has_method("_end_arrival"):
			_hub.call("_end_arrival")
		else:
			_hub.set("_arrival", null)
	if not _print_summary:
		queue_free()
		return
	await get_tree().physics_frame
	var jump := 0.0
	if _camera != null and is_instance_valid(_camera):
		jump = last_cam.distance_to(_camera.global_position)
	_print_summary_line(jump)
	queue_free()


func _print_summary_line(cam_jump: float) -> void:
	var land_x := 0.0
	var land_z := 0.0
	var visible_now := false
	var leader := ""
	if _player != null and is_instance_valid(_player):
		land_x = _player.global_position.x
		land_z = _player.global_position.z
		visible_now = _player.visible
	if _hub != null and is_instance_valid(_hub):
		leader = str(_hub.get("player_model_id"))
	var payload := {
		"fall_start_y": _ground_y + _fall_height(),
		"land_y": _ground_y,
		"land_xz": [land_x, land_z],
		"peak_shake": _peak_shake,
		"cam_jump_m": cam_jump,
		"player_visible": visible_now,
		"leader": leader,
	}
	print("NHT_HUB ", JSON.stringify(payload))


func _has_user_arg(flag: String) -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == flag or arg.begins_with(flag + "="):
			return true
	return false
