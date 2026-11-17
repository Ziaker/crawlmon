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

const HITCH_MS := 34.0  ## a warm-up frame slower than this means something was still compiling
const MAX_WARM_PASSES := 10

const TUNING := {
	"fall_height_m": 9.0,        # D-1237 fall distance above the plaza floor
	"reveal_cam_dist_m": 1.5,    # D-1260 near-vertical (top-down) shot: tiny back offset avoids a degenerate look_at
	"reveal_cam_height_m": 16.0, # D-1260 top-down height until the leader lands
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
	"fall_look_mix": 0.0,        # D-1237 how much the FALL camera follows the comet (0 floor, 1 comet)
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
var _warming := false
var _probe_circle := false  ## --nht-circle: prints the circle screen offset per frame (debug)
var fade_occluders := true  ## D-1260: hide what covers the leader from the top-down camera
var _occ_meshes: Array[MeshInstance3D] = []
var _occ_state: Dictionary = {}
var _occ_orig: Dictionary = {}
var _dt := 0.016
var _anchor := Vector3.ZERO  ## D-1260: x/z where the leader arrives (hub plaza centre or the world's spawn)


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
	_probe_circle = _has_user_arg("--nht-circle")
	_player = hub_node.get("player") as CharacterBody3D
	if _player != null:
		_anchor = Vector3(_player.global_position.x, 0.0, _player.global_position.z)
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
	_player.global_position = _at(_ground_y)
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
	_player.global_position = _at(_ground_y + _fall_height())
	_fx = HubSummonFx.new()
	_fx.name = "SummonFx"
	add_child(_fx)
	_fx.global_position = _at(_ground_y)
	_fx.build(float(TUNING["circle_r_m"]) * _body_scale())


func _at(y: float) -> Vector3:
	return Vector3(_anchor.x, y, _anchor.z)


func _floor_y_at() -> float:
	if _player == null:
		return 0.0
	var world := _player.get_world_3d()
	if world == null:
		return _player.global_position.y
	var from := _at(_player.global_position.y + 3.0)
	var to := _at(_player.global_position.y - 5.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_player.get_rid()]
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return _player.global_position.y
	return float(hit["position"].y)


## Renders every shot of the cutscene once while the loading screen still covers the
## hub, so shaders, particles and meshes are already compiled when REVEAL starts and
## the game does not hitch after the loading (the loading exists for this).
## Cheap: about 8 frames. The hub calls it before notify_hub_ready.
func warm_up() -> void:
	if _fx == null or _camera == null or _player == null or _finished:
		return
	_warming = true
	var t := 0.0
	var shots: Array = [
		["REVEAL", 0.5, _reveal_pos(), _reveal_look(), false],
		["FALL", 0.6, _reveal_pos().lerp(_fall_cam_end(), 0.3), _fall_look(), false],
		["LAND", 0.1, _fall_cam_end(), _fall_look(), true],
		["LAND", 0.8, _final_cam.origin, _final_look, true],
	]
	# D-1267: repeat the whole warm-up (every cutscene shot, then a camera sweep around the landing
	# point) until a full pass runs with no frame over HITCH_MS, i.e. everything is compiled and the
	# cutscene and the first seconds of play will not hitch. Progress is reported to the loading bar.
	var frames_per_pass: int = shots.size() * 2 + 24 + 1
	var planned: int = frames_per_pass * 2
	var done := 0
	var clean_passes := 0
	var pass_no := 0
	var sweep_pos: Vector3 = _final_cam.origin
	while pass_no < MAX_WARM_PASSES and clean_passes < 2:
		var worst_ms := 0.0
		for shot in shots:
			var state_name: String = shot[0]
			var p: float = shot[1]
			var body_y := _ground_y if state_name == "LAND" else _ground_y + _fall_height() * 0.5
			_fx.pose(state_name, p, t, body_y)
			_place_camera(shot[2], shot[3])
			_set_player_visible(bool(shot[4]))
			_player.global_position = _at(_ground_y) if bool(shot[4]) else _at(_ground_y + _fall_height())
			t += 0.1
			for _f in 2:
				worst_ms = maxf(worst_ms, await _warm_frame())
				done += 1
				_report_warm(done, planned)
		_set_player_visible(true)
		_player.global_position = _at(_ground_y)
		for k in 12:
			var yaw: float = TAU * float(k) / 12.0
			for pitch_deg in [-8.0, -35.0]:
				var pitch: float = deg_to_rad(float(pitch_deg))
				var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
				_place_camera(sweep_pos, sweep_pos + dir * 10.0)
				worst_ms = maxf(worst_ms, await _warm_frame())
				done += 1
				_report_warm(done, planned)
		_place_camera(_final_cam.origin, _final_look)
		worst_ms = maxf(worst_ms, await _warm_frame())
		done += 1
		pass_no += 1
		clean_passes = clean_passes + 1 if worst_ms <= HITCH_MS else 0
		if clean_passes < 2 and pass_no < MAX_WARM_PASSES and done + frames_per_pass > planned:
			planned += frames_per_pass  # a pass still hitched: another one is needed
		_report_warm(done, planned)
		if _print_summary:
			print("NHT_WARM pass=", pass_no, " worst_ms=", snappedf(worst_ms, 0.1), " clean=", clean_passes)
	_report_warm(planned, planned)
	_fx.pose("EXIT", 0.0, 0.0, _ground_y + _fall_height())
	_set_player_visible(false)
	_player.global_position = _at(_ground_y + _fall_height())
	_warming = false


func _warm_frame() -> float:
	var t0 := Time.get_ticks_usec()
	await get_tree().process_frame
	return float(Time.get_ticks_usec() - t0) / 1000.0


func _report_warm(done: int, planned: int) -> void:
	if _transition != null and is_instance_valid(_transition):
		_transition.set("warm_progress", clampf(float(done) / float(maxi(planned, 1)), 0.0, 1.0))


## --nht-circle: prints any cutscene step that takes more than 6 ms (finds the exact hitch source).
func _prof(label: String, t0: int) -> void:
	if not _probe_circle:
		return
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	if ms > 6.0:
		print("NHT_PROF ", label, " ", snappedf(ms, 0.1), " ms at total_ms=", int(float(_transition.get("total_ms"))))


func apply(delta: float) -> void:
	_dt = delta
	if _finished or _warming:
		return
	_tick_kids()
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
		var _t0 := Time.get_ticks_usec()
		_fx.pose(state_name, p, float(_transition.get("total_ms")) / 1000.0, _fall_height() * (1.0 - fall_p * fall_p))
		_prof("fx.pose " + state_name, _t0)
	match state_name:
		"EXIT", "LOADING_LOOP":
			_hold_above()
		"REVEAL":
			_hold_above()
			_place_reveal_camera()
		"FALL":
			# The body is the comet inside the pillar: the model only appears at the impact.
			_set_player_visible(false)
			_player.global_position = _at(_ground_y + _fall_height() * (1.0 - p * p))
			_place_fall_camera(p)
		"LAND":
			var _t1 := Time.get_ticks_usec()
			_set_player_visible(p >= float(TUNING["body_at_land"]))
			_prof("set_visible", _t1)
			_player.global_position = _at(_ground_y)
			_t1 = Time.get_ticks_usec()
			_place_land_camera(p)
			_prof("land_camera", _t1)
			_t1 = Time.get_ticks_usec()
			_apply_squash(p)
			_prof("squash", _t1)
		"CONTROL":
			_player.global_position = _at(_ground_y)
			_finish()
	if _probe_circle and state_name in ["REVEAL", "FALL", "LAND"] and not _finished:
		var vp := _camera.get_viewport().get_visible_rect().size
		var off := _camera.unproject_position(_at(_ground_y)) - vp * 0.5
		print("NHT_CIRCLE ", state_name, " p=", snappedf(p, 0.01), " off_px=", Vector2(snappedf(off.x, 1.0), snappedf(off.y, 1.0)))


func _on_state_enter(state_name: String) -> void:
	if state_name == "REVEAL":
		_set_player_visible(false)
	elif state_name in ["FALL", "LAND"]:
		_peak_shake = 0.0


# --- Closed-form poses (all sizes from hub.player_height, D-235) --------------

func _forward() -> Vector3:
	return Vector3(sin(_base_yaw), 0.0, cos(_base_yaw))


func _centre() -> Vector3:
	return _at(_ground_y)


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
	return _reveal_pos()  # D-1260: stays top-down through FALL; LAND then travels to the normal camera


func _fall_look() -> Vector3:
	return _centre() + Vector3(0.0, _player_height * 0.45, 0.0)


func _place_camera(pos: Vector3, look: Vector3) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	_camera.global_position = pos
	_camera.look_at(look, Vector3.UP)
	_update_occluders(1.0 if _warming else _dt)


## D-1260: everything between the camera and the leader goes fully transparent (canopy,
## trunks, roofs) while the top-down shot lasts, then comes back when the cutscene ends.
func _collect_occluders() -> void:
	_occ_meshes.clear()
	var skip: Array = [_player, self]
	var followers: Variant = _hub.get("_followers")
	if followers is Array:
		for f in followers:
			if f is Dictionary and f.get("node") != null:
				skip.append(f["node"])
	_walk_occluders(_hub, skip)


func _walk_occluders(n: Node, skip: Array) -> void:
	if skip.has(n) or n is Camera3D or n is CanvasLayer:
		return
	if n is MeshInstance3D:
		var m := n as MeshInstance3D
		if m.mesh != null:
			var box: AABB = m.global_transform * m.get_aabb()
			if box.end.y > _ground_y + 0.25:  # floors never hide the leader
				_occ_meshes.append(m)
	for c in n.get_children():
		_walk_occluders(c, skip)


func _update_occluders(_dt_unused: float) -> void:
	if not fade_occluders or _camera == null:
		return
	if _occ_meshes.is_empty():
		_collect_occluders()
	var a := _camera.global_position
	var b := _centre() + Vector3(0.0, _player_height * 0.5, 0.0)
	for m in _occ_meshes:
		if not is_instance_valid(m):
			continue
		var box: AABB = (m.global_transform * m.get_aabb()).grow(0.3)
		var hide_it: bool = box.intersects_segment(a, b) != null
		var hidden_now: bool = _occ_state.get(m, 0.0) >= 1.0
		if hide_it == hidden_now:
			continue
		# D-1267: plain visibility toggle. The old gradual `transparency` fade made the GPU compile an
		# alpha-dither pipeline variant of every material the first time it was drawn: a hitch at REVEAL.
		if not _occ_orig.has(m):
			_occ_orig[m] = m.visible
		_occ_state[m] = 1.0 if hide_it else 0.0
		m.visible = bool(_occ_orig[m]) and not hide_it


func _restore_occluders() -> void:
	for m in _occ_state.keys():
		if is_instance_valid(m):
			m.visible = bool(_occ_orig.get(m, true))
	_occ_state.clear()


func _place_reveal_camera() -> void:
	_place_camera(_reveal_pos(), _reveal_look())


func _place_fall_camera(p: float) -> void:
	# The camera stays high while the body crosses the frame over the plaza,
	# and only dives after it near the end of the fall.
	var e := p * p * p
	var pos := _reveal_pos().lerp(_fall_cam_end(), e)
	var body_y := _ground_y + _fall_height() * (1.0 - p * p)
	var look_y := lerpf(_ground_y + _player_height * 0.45, body_y + _player_height * 0.45, float(TUNING["fall_look_mix"]) * (1.0 - p))
	_place_camera(pos, _at(look_y))


func _place_land_camera(p: float) -> void:
	# Hold the wide shot through the flare, then travel to the hub camera.
	var q := clampf((p - 0.22) / 0.78, 0.0, 1.0)
	var e := q * q * (3.0 - 2.0 * q)
	# D-1260: interpolate the whole camera transform (position + orientation) from the top-down
	# shot to the normal camera, so the circle slides smoothly with no overshoot.
	# The camera orbits the landing point (direction slerp, distance lerp) and keeps looking at it,
	# so the circle never leaves the frame while the shot settles.
	var pivot := _fall_look()
	var v0 := _fall_cam_end() - pivot
	var v1 := _final_cam.origin - pivot
	var dir := v0.normalized().slerp(v1.normalized(), e)
	var pos: Vector3 = pivot + dir * lerpf(v0.length(), v1.length(), e)
	var blend := Transform3D(Basis.IDENTITY, pos).looking_at(pivot.lerp(_final_look, e), Vector3.UP)
	var shake_end := maxf(float(TUNING["shake_end"]), 0.0001)
	var decay := clampf(1.0 - p / shake_end, 0.0, 1.0)
	decay *= decay
	if decay > 0.0:
		var amplitude := float(TUNING["shake_m"]) * _body_scale() * decay
		var phase := p * TAU * float(TUNING["shake_cycles"])
		var offset := Vector3(sin(phase), cos(phase * 1.7) * 0.6, cos(phase) * 0.5) * amplitude
		pos += offset
		_peak_shake = maxf(_peak_shake, offset.length())
	if _camera != null and is_instance_valid(_camera):
		_camera.global_transform = Transform3D(blend.basis, pos)
		_update_occluders(1.0 if _warming else _dt)


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


## D-1267: the leader is shown/hidden WITHOUT toggling `_player.visible` (toggling the whole body made
## a deterministic 60-120 ms hitch at the first frame it came back, measured: moved with the instant it
## was shown). The model is toggled alone; the other visual children (blob shadow, dust...) come back
## a few frames later, never in the same frame as the model.
var _kids_want_shown := false
var _kids_delay := 0


func _kids() -> Array[Node3D]:
	var out: Array[Node3D] = []
	if _player == null or not is_instance_valid(_player):
		return out
	for c in _player.get_children():
		if c is Node3D and c != _player_model and not (c is CollisionShape3D) and not (c is Camera3D):
			out.append(c as Node3D)
	return out


func _set_kids_visible(v: bool) -> void:
	for k in _kids():
		if k.visible != v:
			k.visible = v


func _set_player_visible(visible_now: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.visible:
		_player.visible = true
	if _player_model != null and is_instance_valid(_player_model) and _player_model.visible != visible_now:
		_player_model.visible = visible_now
	if not visible_now:
		_kids_want_shown = false
		_set_kids_visible(false)
	elif not _kids_want_shown:
		_kids_want_shown = true
		_kids_delay = 0 if (_warming or _finished) else 3


func _tick_kids() -> void:
	if _kids_want_shown and _kids_delay >= 0:
		if _kids_delay == 0:
			_set_kids_visible(true)
			_kids_delay = -1
		else:
			_kids_delay -= 1


func _hold_above() -> void:
	_set_player_visible(false)
	if _player != null and is_instance_valid(_player):
		_player.global_position = _at(_ground_y + _fall_height())


# --- Hand-back to the hub at CONTROL ----------------------------------------

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_restore_occluders()
	if _player_model != null and is_instance_valid(_player_model):
		_player_model.scale = _base_model_scale
	_set_player_visible(true)
	_set_kids_visible(true)
	if _player != null and is_instance_valid(_player):
		_player.velocity = Vector3.ZERO
		_player.global_position = _at(_ground_y)
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
	var off := _model_centre_offset_xz()
	var payload := {
		"model_off_xz": [off.x, off.y],
		"fall_start_y": _ground_y + _fall_height(),
		"land_y": _ground_y,
		"land_xz": [land_x, land_z],
		"peak_shake": _peak_shake,
		"cam_jump_m": cam_jump,
		"player_visible": visible_now,
		"leader": leader,
	}
	print("NHT_HUB ", JSON.stringify(payload))


## Horizontal offset (m) of the model's visual centre from the body origin, measured
## from the real meshes (D-235: no per-species numbers). 0,0 means centred.
func _model_centre_offset_xz() -> Vector2:
	if _player_model == null or not is_instance_valid(_player_model) or _player == null:
		return Vector2.ZERO
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for child in _player_model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.visible:
			continue
		var box := mi.mesh.get_aabb()
		for i in 8:
			var p: Vector3 = mi.global_transform * box.get_endpoint(i)
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	if lo.x == INF:
		return Vector2.ZERO
	var c := (lo + hi) * 0.5
	return c - Vector2(_player.global_position.x, _player.global_position.z)


func _has_user_arg(flag: String) -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == flag or arg.begins_with(flag + "="):
			return true
	return false


func _exit_tree() -> void:
	_restore_occluders()
