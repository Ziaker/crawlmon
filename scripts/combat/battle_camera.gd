class_name BattleCamera
extends Node
## Battle camera director. The base framing (CINEMA) is a diagonal view from
## the right-rear of the party looking toward the left of the field, with a
## fixed Dutch tilt. TATICA lifts the view while a target is picked; actions
## (a run, a cast) pan the aim along the field. There is never any zoom, shake
## or animated roll. A short burst of speed lines marks strong hits.

enum Mode { CINEMA, TATICA, IMPACTO, STATUS }
## D-015 experiment (debug toggle): how the framing keeps every living enemy in view.
enum FrameMode { OFF, SMOOTH, DEADZONE }

signal mode_changed(mode: Mode)

const CINEMA_POS := Vector3(3.8, 2.875, 7.0)
const CINEMA_LOOK := Vector3(-2.0, 0.0, -20.0)
const TATICA_POS := Vector3(3.0, 6.0, 9.5)
const FOV := 72.0  ## D-1048: creator chose 72 after the 80 x 60 fisheye test
const TILT_DEG := 4.0  ## Fixed Dutch angle (counter-clockwise).
const GLIDE := 1.0

## Framing (D-015): a safe border no living enemy may cross, as a share of the screen.
const FRAME_MARGIN := 0.06
const FRAME_DEADZONE := 0.10  ## Extra border before the DEADZONE framing reacts (hysteresis).
const FRAME_MAX_STEP := 0.30  ## Radians a single containment step may turn (avoids flipping).
const FRAME_FOLLOW := 9.0  ## SMOOTH: how fast the framing follows the enemies (1/s).
const FRAME_SNAP := 16.0  ## DEADZONE: how fast it settles after an enemy crosses the border.

## D-1010 safe-area framing (CINEMA only): the free rectangle of the HUD must hold every
## living unit (and the enemy tags above them). The camera dollies in as far as that fits;
## when even the base pose does not fit, the FOV opens instead.
const SA_MAX_DOLLY := 0.0  ## D-1060 (creator): the camera NEVER advances (it hid the view); it may only open the FOV, aim and rise. Was 12.0 (D-1010).
const SA_MIN_DIST := 5.0  ## Never closer than this (flat metres) to any unit.
const SA_MAX_FOV_ADD := 25.0  ## Degrees the FOV may open when nothing else makes it fit.
const SA_URGENT := 9.0  ## Same, when it has to pull back or open the FOV.
const ACTION_Y := 4.5  ## D-1012 (test): height of the action (IMPACTO) view.
const SA_ACTION_DOLLY := 0.0  ## D-1060: no dolly while the action view is up either. Was 4.0 (D-1012).
const SA_FOLLOW := 2.5  ## How fast the framing glides to its target (1/s).

var camera: Camera3D
var mode := Mode.CINEMA

## Debug toggles only (keys K/L/M in the battle debug panel). The shipped default
## stays exactly the framing of D-020 (fixed, no zoom, no shake).
var frame_mode := FrameMode.OFF
var react_in_tactica := false
var leader_priority := false

var _pos := CINEMA_POS
var _look := CINEMA_LOOK
var _fov := FOV
var _tween: Tween
var _token := 0
var _frame_points := Callable()  ## Provided by the battle scene: living enemies' torso points.
var _frame_offset := Vector3.ZERO  ## Shift the framing adds to the mode's own aim.
var _frame_active := false  ## DEADZONE: currently reacting to a crossing.
var _tactica_focus := Vector3.ZERO
var _has_tactica_focus := false
var _prio_until := 0
var _prio_weight := 0
var _lines: SpeedLines

## D-1010 safe-area framing state. `safe_area` is on by default; providers come from the scene.
var safe_area := true
var _sa_units := Callable()  ## -> Array of {"pts": Array[Vector3], "pad": Vector4(left, right, up, down) in 1280x720 px}
var _sa_rect := Callable()  ## -> Rect2 free of HUD, in 1280x720 px
var _sa_dolly := 0.0
var _sa_fov := 0.0
var _sa_look := Vector3.ZERO
var _sa_ready := false
var action_raise := true  ## D-1012 test switch
var _action_units: Array = []  ## Combatants the action view must keep in frame
var last_fit := {}  ## Debug/proof: what the last evaluation decided.

# D-049: Epic K.O. directional trauma shake and FOV punch
var _shake_trauma := 0.0
var _shake_decay := 3.0
var _shake_dir := Vector3.ZERO
var _fov_kick := 0.0
var _post_rect: ColorRect
var _post_mat: ShaderMaterial
var _post_tw: Tween


func setup(p_camera: Camera3D) -> void:
	camera = p_camera
	var layer := CanvasLayer.new()
	layer.layer = 0  # Above the 3D scene, below the battle UI.
	add_child(layer)
	_post_rect = ColorRect.new()
	_post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = VfxLib.shader_mat("impact_post", {
		"strength": 0.0,
		"monochrome": 0.0,
		"center": Vector2(0.5, 0.45),
		"tint_color": Color(1.0, 0.9, 0.7, 1.0),
	})
	_post_rect.material = _post_mat
	layer.add_child(_post_rect)
	_post_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lines = SpeedLines.new()
	layer.add_child(_lines)
	_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply()


func _process(delta: float) -> void:
	_apply(delta)


## Screen-space impact post-processing (subtle chromatic aberration, radial blur
## and elemental color grade strictly during the strike frame — zero camera shake).
func impact_post(world_pos: Vector3, elem_color: Color, heavy := false, monochrome_pulse := false) -> void:
	if _post_mat == null or camera == null or not camera.is_inside_tree():
		return
	var uv := Vector2(0.5, 0.45)
	if not camera.is_position_behind(world_pos):
		var sp := camera.unproject_position(world_pos)
		var vp := camera.get_viewport().get_visible_rect().size
		if vp.x > 1.0 and vp.y > 1.0:
			uv = Vector2(clampf(sp.x / vp.x, 0.1, 0.9), clampf(sp.y / vp.y, 0.1, 0.9))
	_post_mat.set_shader_parameter("center", uv)
	_post_mat.set_shader_parameter("tint_color", elem_color)
	var peak := 0.88 if heavy else 0.52
	_post_mat.set_shader_parameter("strength", peak)
	_post_mat.set_shader_parameter("monochrome", 1.0 if monochrome_pulse else 0.0)
	if _post_tw != null and _post_tw.is_valid():
		_post_tw.kill()
	_post_tw = create_tween().set_parallel(true)
	_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("strength", v), peak, 0.0, 0.24 if heavy else 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if monochrome_pulse:
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("monochrome", v), 1.0, 0.0, 0.045)


## Tactical time-dilation screen tone during menu decision slow-motion (D-047).
func set_decision_slowmo(active: bool) -> void:
	if _post_mat == null or camera == null or not camera.is_inside_tree():
		return
	if _post_tw != null and _post_tw.is_valid():
		_post_tw.kill()
	_post_tw = create_tween().set_parallel(true)
	if active:
		_post_mat.set_shader_parameter("center", Vector2(0.5, 0.46))
		_post_mat.set_shader_parameter("tint_color", Color("70d6ff"))
		_post_mat.set_shader_parameter("monochrome", 0.18)
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("strength", v), float(_post_mat.get_shader_parameter("strength")), 0.22, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("strength", v), float(_post_mat.get_shader_parameter("strength")), 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_post_tw.tween_method(func(v: float) -> void: _post_mat.set_shader_parameter("monochrome", v), float(_post_mat.get_shader_parameter("monochrome")), 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cinema(time := GLIDE) -> void:
	_action_units = []
	_go(Mode.CINEMA, CINEMA_POS, CINEMA_LOOK, time)


## High view looking toward `focus` (the highlighted target). `ignore_time_scale`
## keeps the glide at real speed during the menu decision slow-motion.
func tactical(focus: Vector3, time := GLIDE, ignore_time_scale := false) -> void:
	_tactica_focus = focus
	_has_tactica_focus = true
	_go(Mode.TATICA, TATICA_POS, focus.lerp(Vector3(2.0, 0.0, 0.0), 0.35), time, FOV, ignore_time_scale)


## An action is happening at `look_pos`: aim there (no dolly, no zoom), then
## settle back to CINEMA. Ignored while the player is picking a target, unless
## the debug toggle `react_in_tactica` is on (D-015 test): the high view then
## leans toward the action and returns to the highlighted target.
func action(look_pos: Vector3, hold := 1.2, weight := 1, from_pos := Vector3.INF, involved: Array = []) -> void:
	if leader_priority:
		var now := Time.get_ticks_msec()
		if now < _prio_until and weight < _prio_weight:
			return  # A hit on the leader keeps the camera until its framing ends.
		_prio_weight = weight
		_prio_until = now + int((hold + 1.0) * 1000.0)
	if mode == Mode.TATICA:
		if not react_in_tactica:
			return
		var focus := _tactica_focus if _has_tactica_focus else look_pos
		_go(Mode.TATICA, TATICA_POS, focus.lerp(look_pos, 0.45) + Vector3(0, 1.4, 0), 0.45)
		var tok_t := _token
		await get_tree().create_timer(hold + 0.6, false).timeout
		if tok_t == _token:
			tactical(focus, 0.6)
		return
	if action_raise and from_pos != Vector3.INF:
		# D-1012: higher view aimed at the middle between attacker and target.
		_action_units = involved
		var mid := from_pos.lerp(look_pos, 0.5)
		_go(Mode.IMPACTO, Vector3(CINEMA_POS.x, ACTION_Y, CINEMA_POS.z), mid + Vector3(0, 1.0, 0), 1.1)
	else:
		_action_units = []
		_go(Mode.IMPACTO, CINEMA_POS, look_pos + Vector3(0, 1.4, 0), 0.8)
	var token := _token
	await get_tree().create_timer(hold + 0.8, false).timeout
	if token == _token:
		cinema()


## Close framing of one character for the status view. The character ends up
## on the left of the frame (the card is on the right).
func status_shot(unit_pos: Vector3, faces_party_side: bool) -> void:
	var offset := Vector3(3.0, 1.5, -5.2) if faces_party_side else Vector3(-3.0, 1.8, 6.5)
	var pos := unit_pos + offset
	var look := unit_pos + Vector3(0, 1.1, 0)
	var right := (look - pos).cross(Vector3.UP).normalized()
	_go(Mode.STATUS, pos, look + right * 1.5, 0.7, 50.0)


## Brief static speed lines around the screen (strong hits only).
func speed_lines() -> void:
	_lines.burst()


func _go(new_mode: Mode, pos: Vector3, look: Vector3, time: float, fov := FOV, ignore_time_scale := false) -> void:
	_token += 1
	if new_mode != mode:
		mode = new_mode
		mode_changed.emit(mode)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if ignore_time_scale:
		_tween.set_ignore_time_scale(true)
	_tween.tween_property(self, "_pos", pos, time)
	_tween.tween_property(self, "_look", look, time)
	_tween.tween_property(self, "_fov", fov, time)


# --- D-015 experiment: keep every living enemy in view -----------------------


## The battle scene provides the on-screen anchors (torso) of the living enemies.
func watch_enemies(provider: Callable) -> void:
	_frame_points = provider


## Debug toggle order: OFF (today's fixed framing) -> SMOOTH -> DEADZONE.
func set_frame_mode(m: int) -> void:
	frame_mode = m
	_frame_offset = Vector3.ZERO
	_frame_active = false


## D-1010: the scene gives the units to keep in frame and the HUD's free rectangle.
func watch_safe_area(units: Callable, rect: Callable) -> void:
	_sa_units = units
	_sa_rect = rect


func _apply(delta := 0.0) -> void:
	if camera == null or not camera.is_inside_tree():
		return

	if delta > 0.0:
		if _shake_trauma > 0.0:
			_shake_trauma = maxf(_shake_trauma - _shake_decay * delta, 0.0)
		if _fov_kick > 0.0:
			_fov_kick = move_toward(_fov_kick, 0.0, 16.0 * delta)

	var shake_offset := Vector3.ZERO
	if _shake_trauma > 0.0:
		var amount := _shake_trauma * _shake_trauma
		var noise_t := Time.get_ticks_msec() * 0.045
		var jitter := Vector3(sin(noise_t * 2.1), cos(noise_t * 2.7), sin(noise_t * 3.3)) * 0.22
		shake_offset = (_shake_dir * 0.38 + jitter) * amount

	_safe_area_step(delta)
	camera.position = _pos + _sa_dir() * _sa_dolly + shake_offset
	camera.fov = _fov + _sa_fov  # D-1060: the FOV may only open; the hit/K.O. "push" (_fov_kick, narrower FOV) is no longer drawn
	# Measure the framing from the mode's own aim (no Dutch tilt yet), then apply
	# the final orientation once.
	camera.look_at(_look + _sa_look)
	var look := _look + _sa_look
	if frame_mode != FrameMode.OFF and mode != Mode.STATUS and _frame_points.is_valid():
		look = _framed_look(delta)
	camera.look_at(look)
	camera.rotate_object_local(Vector3.BACK, deg_to_rad(TILT_DEG))


# --- D-1010: safe-area framing (CINEMA only) ----------------------------------


## Dolly direction: toward the CINEMA aim, flat (no change of height).
func _sa_dir() -> Vector3:
	var d := CINEMA_LOOK - CINEMA_POS
	d.y = 0.0
	return d.normalized()


func _safe_area_step(delta: float) -> void:
	var want_dolly := 0.0
	var want_fov := 0.0
	var want_look := Vector3.ZERO
	var live := safe_area and (mode == Mode.CINEMA or (mode == Mode.IMPACTO and not _action_units.is_empty())) and frame_mode == FrameMode.OFF 			and _sa_units.is_valid() and _sa_rect.is_valid() and camera.get_viewport() != null
	if live:
		var fit := _sa_solve()
		if not fit.is_empty():
			want_dolly = fit["dolly"]
			want_fov = fit["fov"]
			want_look = fit["look"]
			last_fit = fit
			if not _sa_ready:
				_sa_dolly = want_dolly
				_sa_fov = want_fov
				_sa_look = want_look
				_sa_ready = true
				return
	if delta <= 0.0:
		return
	var real_dt := delta / maxf(Engine.time_scale, 0.05)  # The glide ignores the menu slow-motion.
	# D-1011: pulling back / opening is urgent (the leader may be running at the camera); approaching is slow.
	var urgent := want_dolly < _sa_dolly - 0.01 or want_fov > _sa_fov + 0.01
	var k := 1.0 - exp(-(SA_URGENT if urgent else SA_FOLLOW) * real_dt)
	_sa_dolly = lerpf(_sa_dolly, want_dolly, k)
	_sa_fov = lerpf(_sa_fov, want_fov, k)
	_sa_look = _sa_look.lerp(want_look, k)


## Largest dolly (or smallest FOV opening) that puts every unit inside the free rectangle.
func _sa_solve() -> Dictionary:
	var units: Array = _sa_units.call()
	if mode == Mode.IMPACTO:
		units = units.filter(func(u) -> bool: return _action_units.has(u.get("c")))
	var free: Rect2 = _sa_rect.call()
	if units.is_empty() or free.size.x < 50.0 or free.size.y < 50.0:
		return {}
	var dmax := SA_MAX_DOLLY if mode != Mode.IMPACTO else SA_ACTION_DOLLY
	var dir := _sa_dir()
	var step := 0.25
	var d := 0.0
	while d <= dmax:
		var cpos := _pos + dir * d
		var near := false
		for u in units:
			for p in u["pts"]:
				var q: Vector3 = p
				if Vector2(q.x - cpos.x, q.z - cpos.z).length() < SA_MIN_DIST and q.z < cpos.z + 0.01:
					near = true
		if near:
			dmax = maxf(d - step, 0.0)
			break
		d += step
	var base := _sa_eval(units, free, 0.0, 0.0)
	if base["fits"]:
		var lo := 0.0
		var hi := dmax
		var best := base
		if hi > 0.0 and _sa_eval(units, free, hi, 0.0)["fits"]:
			lo = hi
			best = _sa_eval(units, free, hi, 0.0)
		else:
			for i in 10:
				var mid := (lo + hi) * 0.5
				var e := _sa_eval(units, free, mid, 0.0)
				if e["fits"]:
					lo = mid
					best = e
				else:
					hi = mid
		return {"dolly": lo, "fov": 0.0, "look": best["look"] - _look, "fits": true, "ext": best["ext"]}
	var flo := 0.0
	var fhi := SA_MAX_FOV_ADD
	var fbest := _sa_eval(units, free, 0.0, fhi)
	if fbest["fits"]:
		for i in 10:
			var mid := (flo + fhi) * 0.5
			var e := _sa_eval(units, free, 0.0, mid)
			if e["fits"]:
				fhi = mid
				fbest = e
			else:
				flo = mid
	return {"dolly": 0.0, "fov": fhi, "look": fbest["look"] - _look, "fits": fbest["fits"], "ext": fbest["ext"]}


## Places the camera at dolly/fov, centres the units' box in the free rectangle by turning,
## and reports whether the box (units plus tag padding) fits inside it.
func _sa_eval(units: Array, free: Rect2, dolly: float, fov_add: float) -> Dictionary:
	var vp := camera.get_viewport().get_visible_rect().size
	var sc := Vector2(vp.x / 1280.0, vp.y / 720.0)
	camera.position = _pos + _sa_dir() * dolly
	camera.fov = _fov + fov_add
	var tan_v := tan(deg_to_rad(camera.fov) * 0.5)
	var tan_h := tan_v * (vp.x / maxf(vp.y, 1.0))
	var rc := (free.position + free.size * 0.5) * sc
	var look := _look
	var box := Rect2()
	var ok := true
	for pass_i in 3:
		camera.look_at(look)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		ok = true
		for u in units:
			var pad: Vector4 = u["pad"]
			for p in u["pts"]:
				var pt: Vector3 = p
				if camera.is_position_behind(pt):
					ok = false
					continue
				var sp := camera.unproject_position(pt)
				lo.x = minf(lo.x, sp.x - pad.x * sc.x)
				hi.x = maxf(hi.x, sp.x + pad.y * sc.x)
				lo.y = minf(lo.y, sp.y - pad.z * sc.y)
				hi.y = maxf(hi.y, sp.y + pad.w * sc.y)
		if lo.x > hi.x:
			return {"fits": false, "look": look, "ext": Vector2.ZERO}
		box = Rect2(lo, hi - lo)
		if pass_i == 2:
			break
		var c := box.position + box.size * 0.5
		var nx := (c.x / vp.x) * 2.0 - 1.0
		var ny := 1.0 - (c.y / vp.y) * 2.0
		var tx := (rc.x / vp.x) * 2.0 - 1.0
		var ty := 1.0 - (rc.y / vp.y) * 2.0
		var turn_x := atan(nx * tan_h) - atan(tx * tan_h)
		var turn_y := atan(ny * tan_v) - atan(ty * tan_v)
		var dv := look - camera.position
		dv = dv.rotated(Vector3.UP, -turn_x)
		var right := dv.cross(Vector3.UP).normalized()
		if right.length_squared() > 0.5:
			dv = dv.rotated(right, turn_y)
		look = camera.position + dv
	var fits := ok and box.size.x <= free.size.x * sc.x and box.size.y <= free.size.y * sc.y
	return {"fits": fits, "look": look, "ext": box.size / sc}


## Directional hit shake for regular attacks with lower intensity than K.O. (D-157).
func hit_shake(hit_dir: Vector3, heavy := false, mult := 1.0) -> void:
	if _shake_trauma >= 0.75:
		return  # Don't downgrade an active K.O. shake
	var base_trauma := 0.55 if heavy else 0.35
	_shake_trauma = maxf(_shake_trauma, clampf(base_trauma * mult, 0.25, 0.65))
	_shake_dir = -hit_dir.normalized() if hit_dir.length_squared() > 0.001 else Vector3.BACK
	# D-157: normal hits have no aggressive kick; heavy hits use the calibrated ~1.5°.
	_fov_kick = maxf(_fov_kick, 1.5 if heavy else 0.4)
	_shake_decay = 4.5


## Epic K.O. directional trauma shake and FOV punch (D-049 / D-157).
func ko_shake(hit_dir: Vector3, world_pos: Vector3, elem_color: Color) -> void:
	_shake_trauma = 1.0
	_shake_dir = -hit_dir.normalized() if hit_dir.length_squared() > 0.001 else Vector3.BACK
	_fov_kick = 4.5
	_shake_decay = 3.0
	impact_post(world_pos, elem_color, true, true)
	if _lines != null:
		_lines.burst()


## The look point that keeps every living enemy inside the safe border, smoothed.
## Pan and tilt only: position and FOV never change (D-020: no zoom, no shake).
## The smoothing applies to the *correction* over the mode's own aim, so the
## camera keeps its normal glide and only the framing part moves smoothly.
func _framed_look(delta: float) -> Vector3:
	var framed := _look + _frame_offset
	var target := Vector3.ZERO
	if frame_mode == FrameMode.DEADZONE:
		# Hysteresis: start when an enemy crosses the wide border, stop only when
		# every enemy is comfortably back inside it (the framing itself parks them
		# on the safe border, so a tighter release would chatter).
		var wide := FRAME_MARGIN + FRAME_DEADZONE
		var hold := FRAME_MARGIN + FRAME_DEADZONE * 0.5
		if not _frame_active and _worst_fraction(framed, wide).x >= 0.0:
			_frame_active = true
		elif _frame_active and _worst_fraction(framed, hold).x < 0.0:
			_frame_active = false
		if _frame_active:
			target = _contain(_look, FRAME_MARGIN) - _look
	else:
		target = _contain(_look, FRAME_MARGIN) - _look
	var rate := FRAME_FOLLOW if frame_mode == FrameMode.SMOOTH else FRAME_SNAP
	_frame_offset = _frame_offset.lerp(target, 1.0 - exp(-rate * delta))
	return _look + _frame_offset


## Turns `base` just enough for all points to sit inside the border. Iterative:
## each pass aims at the point that crosses the border the most and rotates the
## view by the exact angle its screen position asks for.
func _contain(base: Vector3, margin: float) -> Vector3:
	var look := base
	for pass_i in 3:
		var f := _worst_fraction(look, margin)
		if f.x < 0.0:
			break
		var vp := camera.get_viewport().get_visible_rect().size
		var tan_v := tan(deg_to_rad(_fov) * 0.5)
		var tan_h := tan_v * (vp.x / maxf(vp.y, 1.0))
		var lim := 1.0 - 2.0 * margin
		# Screen y grows downward: ny > 0 means the point sits above the centre.
		var nx := 2.0 * f.x - 1.0
		var ny := 1.0 - 2.0 * f.y
		var nxt := clampf(nx, -lim, lim)
		var nyt := clampf(ny, -lim, lim)
		var turn_x := atan(nx * tan_h) - atan(nxt * tan_h)  # positive = point is to the right
		var turn_y := atan(ny * tan_v) - atan(nyt * tan_v)  # positive = point is above
		turn_x = clampf(turn_x, -FRAME_MAX_STEP, FRAME_MAX_STEP)
		turn_y = clampf(turn_y, -FRAME_MAX_STEP, FRAME_MAX_STEP)
		var d := look - _pos
		d = d.rotated(Vector3.UP, -turn_x)  # Turn toward the point.
		var right := d.cross(Vector3.UP).normalized()
		if right.length_squared() > 0.5:
			d = d.rotated(right, turn_y)
		look = _pos + d
	return look


## Screen fraction (0..1) of the point that crosses the safe border the most, or
## (-1, -1) when every point is inside. Leaves the camera looking at `look`.
func _worst_fraction(look: Vector3, margin: float) -> Vector2:
	var worst := Vector2(-1.0, -1.0)
	if camera == null or not _frame_points.is_valid():
		return worst
	var vp := camera.get_viewport().get_visible_rect().size
	if vp.x < 2.0 or vp.y < 2.0:
		return worst
	camera.look_at(look)
	var worst_over := 0.0
	for p in _frame_points.call():
		var pt: Vector3 = p
		if camera.is_position_behind(pt):
			continue
		var sp := camera.unproject_position(pt)
		var f := Vector2(sp.x / vp.x, sp.y / vp.y)
		var ox := 0.0
		var oy := 0.0
		if f.x < margin:
			ox = margin - f.x
		elif f.x > 1.0 - margin:
			ox = f.x - (1.0 - margin)
		if f.y < margin:
			oy = margin - f.y
		elif f.y > 1.0 - margin:
			oy = f.y - (1.0 - margin)
		var over := maxf(ox, oy)
		if over > worst_over:
			worst_over = over
			worst = f
	return worst




class SpeedLines extends Control:
	var _alpha := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func burst() -> void:
		_alpha = 0.55
		create_tween().tween_property(self, "_alpha", 0.0, 0.35)

	func _process(_delta: float) -> void:
		if _alpha > 0.0:
			queue_redraw()

	func _draw() -> void:
		if _alpha <= 0.0:
			return
		var center := size * 0.5
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 40:
			var ang := rng.randf() * TAU
			var dir := Vector2(cos(ang), sin(ang))
			var r_out := size.length() * 0.6
			var r_in := r_out * rng.randf_range(0.62, 0.8)
			var width := rng.randf_range(3.0, 9.0)
			var perp := Vector2(-dir.y, dir.x) * width
			draw_colored_polygon(PackedVector2Array([center + dir * r_out, center + dir * r_in + perp, center + dir * r_in - perp]), Color(1, 1, 1, _alpha))
