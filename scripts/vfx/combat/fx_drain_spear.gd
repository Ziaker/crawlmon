extends RefCounted
## Drain Spear (move_drain_spear) in the real battle: the existing Motion Composer effect
## (DrainSpearVfx / MotionPresets.drain_spear_effect) driven by the attack's own phases.
## Every position comes from the live attacker and target (D-235); no character, team, side
## or fixed coordinate is read here.

const DrainSpearVfx = preload("res://scripts/vfx/drain_spear_vfx.gd")
const DrainSpearBadgeLights = preload("res://scripts/vfx/drain_spear_badge_lights.gd")
const SPEAR_LENGTH := 2.7
const FORM_END := 0.8
const TURN_END := 1.0
const IMPACT_TIME := 0.80
const STEAL_TIME := 0.69
const DISSOLVE_TIME := 0.55

var fx: BattleFx
var _active: Dictionary = {}   ## Incoming -> DrainSpearVfx
var _hand: Dictionary = {}     ## Incoming -> Vector3 at the strike
var _contact: Dictionary = {}  ## Incoming -> Vector3 at the strike
var _lights_spawned: Dictionary = {}  ## Incoming -> true
var _lights: Array = []
var _seed := 0


func _init(p_fx: BattleFx) -> void:
	fx = p_fx
	_seed = randi() % 900000 + 1


## A new Drain Spear was declared (wind-up start). The spear forms during the wind-up.
func start(inc) -> void:
	if inc == null or BattleFx.normalize_move_id(inc.label) != "drain_spear":
		return
	if _active.has(inc):
		return
	var cam: Camera3D = fx.cam.camera if fx.cam != null else null
	var node := DrainSpearVfx.new()
	node.name = "DrainSpearVfx"
	node.crown = false  # the eight blue lights replace the crown/orbit in battle
	fx.add_child(node)
	node.setup(cam, _seed)
	_active[inc] = node
	_seed = (_seed + 7919) % 1000000


func cancel(inc) -> void:
	_stop(inc)


func clear_all() -> void:
	for inc in _active.keys():
		_stop(inc)
	for lights in _lights:
		if lights != null and is_instance_valid(lights):
			lights.queue_free()
	_lights.clear()
	_active.clear()
	_hand.clear()
	_contact.clear()
	_lights_spawned.clear()


func _stop(inc) -> void:
	var node = _active.get(inc)
	if node != null and is_instance_valid(node):
		node.end()
		node.queue_free()
	_active.erase(inc)
	_lights_spawned.erase(inc)


## The eight blue lights of the Badge Steal leave the impact point and form the static
## ring where the old crown was. They live on their own clock, so the attack's return can
## end before their slow fade.
func _spawn_lights(contact: Vector3, attacker: Combatant) -> void:
	# D-1019: the Badge Steal is a reverse pulse (wave out, rewound into a sphere, pulled to the attacker, aura burst);
	# it replaces the eight lights / chains (D-441, D-1014).
	var pulse := DrainSpearReversePulse.new()
	pulse.name = "DrainSpearReversePulse"
	fx.add_child(pulse)
	var center_fn := func() -> Vector3:
		if not is_instance_valid(attacker) or fx == null:
			return contact
		return fx.drawn_body_center(attacker)
	pulse.spawn(contact, center_fn)
	_lights.append(pulse)


## Draws every active Drain Spear at its current attack phase.
func process(_delta: float) -> void:
	for inc in _active.keys().duplicate():
		var node = _active[inc]
		if not is_instance_valid(node):
			_active.erase(inc)
			continue
		if inc.phase == Incoming.Phase.DONE or inc.phase == Incoming.Phase.STAGGER or not inc.attacker.is_alive() or not inc.target.is_alive():
			_stop(inc)
			continue
		_draw(inc, node)


func _draw(inc, node) -> void:
	var scale := _scale_at(_contact.get(inc, _body_center(inc.target)))
	if inc.phase == Incoming.Phase.WINDUP:
		var t: float = clampf(float(inc.total_windup) - maxf(float(inc.time_left), 0.0), 0.0, float(inc.total_windup))
		var st := _windup_state(inc, t)
		node.begin(fx.clock)
		node.draw_phase("windup", t, st["base"], st["tip"], st["tip"], st["axis"], st["reveal"], 0.0, false)
		node.end()
		return
	if inc.phase == Incoming.Phase.TRAVEL:
		var t: float = float(inc.total_windup) + float(inc.phase_time)
		var st := _windup_state(inc, t)
		# D-1015: upright while moving; it lies down toward the target only once the attacker reaches its spot.
		var arrive := 0.12 + float(inc.run_t)
		var lie := clampf((float(inc.phase_time) - arrive) / 0.2, 0.0, 1.0)
		var hand_t := _hand_point(inc)
		var aim_t := _axis(hand_t, _body_center(inc.target))
		st["base"] = hand_t
		st["axis"] = Vector3.UP  # D-1016: upright until the prelude
		st["tip"] = hand_t + (st["axis"] as Vector3) * SPEAR_LENGTH
		node.begin(fx.clock)
		node.draw_phase("windup", t, st["base"], st["tip"], st["tip"], st["axis"], 1.0, 0.0, false)
		node.end()
		return
	if inc.phase == Incoming.Phase.STRIKE:
		var hand := _hand_point(inc)
		var contact := _contact_point(inc)
		_hand[inc] = hand
		_contact[inc] = contact
		var axis := _axis(hand, contact)
		var t_raw: float = float(inc.phase_time)
		var phase_len_raw := maxf(float(inc.phase_len()), 0.01)
		# D-1015: the prelude (anticipation + most of the blow) keeps the spear held, aimed; the shot and its drill
		# start with the swing, timed to end exactly on the contact.
		# D-1017: the prelude is the spear lying down (0.2 s); the shot starts 0.20 s after it, while the attacker is
		# still in its thrust-ready pose, and grows until the contact.
		var shot_at := minf(0.2 + 0.2, phase_len_raw - 0.1)
		var shot_len := maxf(phase_len_raw - shot_at, 0.1)
		if t_raw < shot_at:
			var lie0 := clampf(t_raw / 0.2, 0.0, 1.0)
			var aim0 := Vector3.UP.slerp(_axis(hand, contact), lie0 * lie0 * (3.0 - 2.0 * lie0)).normalized()  # D-1016
			node.begin(fx.clock)
			node.draw_phase("windup", float(inc.total_windup) + 2.0, hand, hand + aim0 * SPEAR_LENGTH, hand + aim0 * SPEAR_LENGTH, aim0, 1.0, 0.0, false)
			node.end()
			return
		var t: float = t_raw - shot_at
		var phase_len := shot_len
		var p := clampf(t / phase_len, 0.0, 1.0)
		# The shaft grows through the thrust and reaches the target at the contact frame. It must
		# not pop from the carried 2.7 m to the full 16.3 m at the start of the strike.
		var grow := clampf(t / phase_len, 0.0, 1.0)
		var full := hand.distance_to(contact)
		var tip := hand + axis * lerpf(SPEAR_LENGTH, full, grow)
		node.begin(fx.clock)
		node.draw_phase("thrust", t, hand, tip, tip, axis, 1.0, p, false, scale)
		if t <= 0.60:
			node.draw_phase("drill", t, hand, tip, tip, axis, clampf(t / 0.28, 0.0, 1.0), 0.0, false, scale)
		node.end()
		return
	if inc.phase == Incoming.Phase.RETURN:
		var hand: Vector3 = _hand.get(inc, _hand_point(inc))
		var contact: Vector3 = _contact.get(inc, _contact_point(inc))
		var axis := _axis(hand, contact)
		var t: float = float(inc.phase_time)
		var stolen: Array = inc.data.get("drain_steal", [])
		var to_attacker: Vector3 = _body_center(inc.attacker)
		# With Badge Steal the SAME shotgun impact still happens, but the fan is oriented
		# from the target back to the attacker. Without it, the fan keeps the forward axis.
		var hit_axis := _axis(contact, to_attacker) if not stolen.is_empty() else axis
		if not stolen.is_empty() and not _lights_spawned.has(inc):
			_lights_spawned[inc] = true
			_spawn_lights(contact, inc.attacker)
		node.begin(fx.clock)
		if t <= IMPACT_TIME:
			var k := clampf(t / 0.55, 0.0, 1.0)
			node.draw_phase("impact_flash", t, contact, contact + hit_axis * 0.1, contact, hit_axis, k, 0.0, true, scale)
			node.draw_phase("impact", t, contact, contact + hit_axis * 10.0, contact, hit_axis, k, 0.0, true, scale)
		if not stolen.is_empty() and t >= 0.05 and t <= 0.05 + STEAL_TIME:
			# The siphon (reverse streaks + badge orbs) is kept; only its crown/orbit is off.
			var st := clampf((t - 0.05) / STEAL_TIME, 0.0, 1.0)
			node.draw_phase("steal", t - 0.05, contact, to_attacker, contact, hit_axis, st, 0.0, true, scale)
		if t >= 0.05 and t <= 0.05 + DISSOLVE_TIME:
			var dk := clampf((t - 0.05) / DISSOLVE_TIME, 0.0, 1.0)
			node.draw_phase("dissolve", t - 0.05, hand, contact, contact, axis, dk, 0.0, true, scale)
		node.end()


## Formation at the attacker's side: rises from the floor, turns to the target, then is
## carried. The same state is used during the wind-up and the run.
func _windup_state(inc, t: float) -> Dictionary:
	var hand := _hand_point(inc)
	var target: Vector3 = _body_center(inc.target)
	var aim := _axis(hand, target)
	var ground := Vector3(hand.x, 0.0, hand.z)
	var base := hand
	var axis := aim
	var reveal := clampf(t / FORM_END, 0.0, 1.0)
	if t < FORM_END:
		base = ground
		axis = Vector3.UP
	elif t < TURN_END:
		var u := clampf((t - FORM_END) / maxf(TURN_END - FORM_END, 0.01), 0.0, 1.0)
		var e := u * u * (3.0 - 2.0 * u)
		base = ground.lerp(hand, e)
		axis = Vector3.UP  # D-1016: stays upright; it lies down only in the attack's prelude
	else:
		base = hand
		axis = Vector3.UP  # D-1016
	return {"base": base, "axis": axis, "tip": base + axis * SPEAR_LENGTH, "reveal": reveal}


func _hand_point(inc) -> Vector3:
	var info: Dictionary = _body_info(inc.attacker)
	var center: Vector3 = info.get("center", inc.attacker.pos + Vector3.UP * 1.1)
	var radius := float(info.get("radius", 0.8))
	var right := Vector3.RIGHT
	if fx.cam != null and fx.cam.camera != null:
		right = fx.cam.camera.global_transform.basis.x
		right.y = 0.0
		if right.length() < 0.01:
			right = Vector3.RIGHT
		right = right.normalized()
	# D-1016: upright IN FRONT of the body (toward the target), a little to the screen side, so the player sees it.
	var fwd := _axis(Vector3(center.x, 0.0, center.z), Vector3(_body_center(inc.target).x, 0.0, _body_center(inc.target).z))
	# D-1018: beside the silhouette on the screen side (past the body's width), slightly forward, so the body never
	# hides it in either view (seen from behind it was occluded).
	return center + fwd * (radius * 0.45) + right * (radius * 1.15 + 0.35) + Vector3.UP * 0.1


func _contact_point(inc) -> Vector3:
	return _body_front(inc.target, _body_center(inc.attacker))


func _axis(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	return d.normalized() if d.length() > 0.001 else Vector3.FORWARD


func _scale_at(pos: Vector3) -> float:
	if fx.cam == null or fx.cam.camera == null:
		return 1.0
	return clampf(fx.cam.camera.global_position.distance_to(pos) / 16.0, 1.0, 1.8)


## Character-agnostic body anchors: the Combatant's authoritative position and body scale.
func _body_center(c: Combatant) -> Vector3:
	return c.pos + Vector3.UP * (1.1 * maxf(c.body_scale, 0.5))


func _body_radius(c: Combatant) -> float:
	return clampf(0.8 * c.body_scale, 0.5, 2.5)


func _body_info(c: Combatant) -> Dictionary:
	return {"center": _body_center(c), "radius": _body_radius(c)}


func _body_front(c: Combatant, toward: Vector3) -> Vector3:
	var center := _body_center(c)
	return center + BattleSpace.flat_dir(center, toward) * _body_radius(c)
