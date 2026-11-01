class_name BattleFx
extends Node3D
## Placeholder battle visuals built only from primitives and CPU particles:
## attack telegraphs, lunges/casts, per-element impact effects, evade
## sidesteps with afterimages and floating numbers.

const COLORS := {
	Element.Type.FISICO: Color(0.95, 0.95, 0.95),
	Element.Type.FOGO: Color(1.0, 0.45, 0.1),
	Element.Type.AGUA_GELO: Color(0.4, 0.8, 1.0),
	Element.Type.RAIO: Color(1.0, 0.95, 0.2),
	Element.Type.PSIQUICO: Color(0.9, 0.3, 0.9),
	Element.Type.VENENO: Color(0.5, 0.9, 0.2),
	Element.Type.SOM: Color(0.3, 1.0, 0.8),
	Element.Type.TERRA: Color(0.6, 0.4, 0.2),
	Element.Type.VENTO: Color(0.7, 1.0, 0.8),
	Element.Type.LUZ: Color(1.0, 1.0, 0.7),
	Element.Type.TREVAS: Color(0.4, 0.15, 0.55),
}
const FLY_TIME := 0.25
const TELEGRAPH_COLOR := Color(1.0, 0.2, 0.15)
const ALLY_COLOR := Color(0.3, 0.7, 1.0)
const DODGE_COLOR := Color(0.5, 0.9, 1.0)
const GOLD := Color(1.0, 0.8, 0.1)
const RUN_SPEED := 55.0  ## Units per second while running at a target.
const STAND_GAP := 2.6  ## Where a melee attacker stops, in front of its target.
const HIT_AT := 0.45  ## Seconds into the attack clip when the strike lands.
const ATTACK_HOLD := 0.6  ## Time spent finishing the attack clip after the strike.
const READY_STEP := 0.9  ## How far a character steps forward while it can act.
const CAST_AT := 0.5  ## Seconds into a cast when the effect leaves the caster.


var cam: BattleCamera  ## Set by the battle scene; frames each attack.
var leader: Combatant  ## The player's character: the camera only follows actions involving it.
var battle: Battle  ## Set by the battle scene; drives the ready stance.

var _models: Dictionary = {}  ## Combatant -> Node3D
var _home: Dictionary = {}  ## Combatant -> Vector3
var _home_yaw: Dictionary = {}  ## Combatant -> float
var _tweens: Dictionary = {}  ## Combatant -> Tween (movement)
var _telegraphs: Dictionary = {}  ## Battle.Incoming -> Array[Node]
var _hit_at: Dictionary = {}  ## attacker -> seconds until its strike lands
var _react_token: Dictionary = {}  ## Combatant -> int
var _slot: Dictionary = {}  ## Combatant -> Vector3 (spawn spot; wandering stays near it)
var _busy_until: Dictionary = {}  ## Combatant -> msec; no wandering before that
var _ready_off: Dictionary = {}  ## Combatant -> Vector3 (ready-stance offset from home)
var _phase: Dictionary = {}  ## Combatant -> float (breathing phase)
var _displaced: Dictionary = {}  ## Combatant -> bool (standing off its home after a dodge)


func register(c: Combatant, model: Node3D) -> void:
	_models[c] = model
	_home[c] = model.position
	_home_yaw[c] = model.rotation.y
	_slot[c] = model.position
	_phase[c] = randf() * TAU
	var ap := _anim_player(c)
	if ap != null:
		ap.speed_scale = randf_range(0.92, 1.08)  # Keep the idle breathing out of sync.
	_add_ready_ring(model)


# --- Battle events ---------------------------------------------------------

## An attack starts winding up: the attacker plays its charge pose and a
## shrinking ring + line shows who will be hit and when.
func telegraph(inc) -> void:
	_rebase(inc.attacker)
	_rebase(inc.target)
	_busy_for(inc.attacker, Battle.WINDUP + 1.0)
	_busy_for(inc.target, Battle.WINDUP + 1.2)
	var a_home: Vector3 = _home[inc.attacker]
	var t_home: Vector3 = _home[inc.target]
	var warn := TELEGRAPH_COLOR if not inc.attacker.is_player else ALLY_COLOR
	_play(inc.attacker, "charge")
	_brace(inc)
	var ring := _ring(t_home + Vector3(0, 0.05, 0), warn, Vector3(2.6, 1, 2.6), Vector3.ONE, Battle.WINDUP, Vector3.ZERO, 0.0, false)
	var line := _line(a_home + Vector3(0, 1, 0), t_home + Vector3(0, 1, 0), Color(warn, 0.45), 0.05)
	_telegraphs[inc] = [ring, line]


func clear_telegraph(inc) -> void:
	if _telegraphs.has(inc):
		for n in _telegraphs[inc]:
			if is_instance_valid(n):
				n.queue_free()
		_telegraphs.erase(inc)


## The wind-up ends. Physical attacks run to the target, strike and run back;
## the rest are cast on the spot. The impact lands at the strike frame.
func resolve_attack(inc) -> void:
	clear_telegraph(inc)
	var a: Combatant = inc.attacker
	var t: Combatant = inc.target
	var element: Element.Type = inc.element
	var a_home: Vector3 = _home[a]
	var t_home: Vector3 = _home[t]
	var dir := _flat_dir(a_home, t_home)
	var total := 0.0
	if element == Element.Type.FISICO:
		var stand := t_home - dir * STAND_GAP
		var run_t := clampf(a_home.distance_to(stand) / RUN_SPEED, 0.35, 0.8)
		_hit_at[a] = run_t + HIT_AT
		total = _melee(a, stand, dir, run_t)
		if cam != null and (a == leader or t == leader):
			cam.action((a_home + t_home) * 0.5)
	else:
		_hit_at[a] = CAST_AT
		total = _cast(a, dir, COLORS[element])
		if cam != null and (a == leader or t == leader):
			cam.action(t_home)
	_hold_hp(t, float(_hit_at[a]) + 0.3)
	_busy_for(a, total + 0.8)
	_busy_for(t, total + 1.6)
	_unbrace_later(a, total + 0.1)
	_unbrace_later(t, total + 0.1)
	if inc.dodged:
		# The target already vanished (manual Evade); the attacker whiffs.
		var to := t_home + Vector3(0, 1, 0)
		if _has_projectile(element):
			await get_tree().create_timer(CAST_AT, false).timeout
			_projectile(a_home + Vector3(0, 1, 0), to + _flat_dir(a_home, t_home) * 7.0, COLORS[element], element)
			total -= CAST_AT
		await get_tree().create_timer(maxf(total, 0.3), false).timeout
		settle(t)


func manual_evade(actor: Combatant, inc) -> void:
	clear_telegraph(inc)
	dodge(actor, "EVADE! BURST", true)
	var home: Vector3 = _home[actor]
	_ring(home + Vector3(0, 1, 0), GOLD, Vector3.ONE * 0.5, Vector3.ONE * 2.5, 0.5, Vector3(90, 0, 0))
	_burst(home + Vector3(0, 1, 0), GOLD, 20, 4.0, Vector3(0, 2, 0), 0.08, 0.6)


## info keys: evaded, dmg, weak, crit, gain.
func play_hit(attacker: Combatant, target: Combatant, element: Element.Type, info: Dictionary) -> void:
	var color: Color = COLORS[element]
	var a_home: Vector3 = _home[attacker]
	var t_home: Vector3 = _home[target]
	var from := a_home + Vector3(0, 1, 0)
	var to := t_home + Vector3(0, 1, 0)
	var delay: float = _hit_at.get(attacker, 0.12)
	_hit_at.erase(attacker)
	var evaded: bool = info["evaded"]
	if _has_projectile(element):
		await get_tree().create_timer(delay, false).timeout
		if evaded:
			_dodge_later(target, "ESQUIVOU! +1 ATB", 0.0, 0.7)
		var end := to + _flat_dir(from, to) * 7.0 if evaded else to
		await _projectile(from, end, color, element)
	else:
		if evaded:
			_dodge_later(target, "ESQUIVOU! +1 ATB", maxf(delay - 0.12, 0.0), 0.9)
		await get_tree().create_timer(delay, false).timeout
	if evaded:
		return
	var weak: bool = info["weak"]
	var crit: bool = info["crit"]
	if (weak or crit) and cam != null and (attacker == leader or target == leader):
		cam.speed_lines()
	_impact(element, to, color, weak or crit)
	flash(target)
	knock(target, a_home)
	_hit_react(target)
	var text := str(info["dmg"])
	var text_color := Color.WHITE
	var size := 56
	if crit:
		text = "CRÍTICO! " + text
		text_color = Color(1.0, 0.9, 0.2)
		size = 84
	if weak:
		text_color = Color(1.0, 0.5, 0.15)
		size += 12
		float_text(to + Vector3(0, 2.1, 0), "FRAQUEZA!", Color(1.0, 0.5, 0.15), 48)
	float_text(to + Vector3(0, 1.2, 0), text, text_color, size)
	var gain: int = info["gain"]
	if gain > 0 and attacker.is_alive():
		float_text(_models[attacker].position + Vector3(0, 3.0, 0), "+%d ATB" % gain, DODGE_COLOR, 44)


func heal_fx(_actor: Combatant, target: Combatant, amount: int) -> void:
	var home: Vector3 = _home[target]
	var green := Color(0.3, 1.0, 0.4)
	_ring(home + Vector3(0, 0.05, 0), green, Vector3.ONE * 2.0, Vector3.ONE * 0.5, 0.6)
	_burst(home + Vector3(0, 0.3, 0), green, 22, 2.0, Vector3(0, 4, 0), 0.08, 0.9)
	float_text(home + Vector3(0, 2.4, 0), "+%d" % amount, green, 64)


func _busy_for(c: Combatant, seconds: float) -> void:
	_busy_until[c] = maxi(_busy_until.get(c, 0), Time.get_ticks_msec() + int(seconds * 1000.0))


## Cancel any walk in progress and face the opponent again.
func _add_ready_ring(model: Node3D) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "ReadyRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.08
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.45, 0.92, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.92, 1.0)
	mat.emission_energy_multiplier = 1.5
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position.y = 0.05
	ring.visible = false
	model.add_child(ring)


func _stop_moving(c: Combatant) -> void:
	var tw_now: Tween = _tweens.get(c)
	if tw_now != null and tw_now.is_valid():
		return  # A scripted sequence (run, dodge...) owns it; let it finish.
	var m: Node3D = _models[c]
	m.rotation.y = _home_yaw[c]


## The character's current resting spot becomes its home.
func _rebase(c: Combatant) -> void:
	_stop_moving(c)


# --- Life: ready stance, breathing, reactions, intro and victory --------------------

## Idle characters breathe (a slight sway) and step forward with a pulsing floor
## ring while they can act. Movement therefore always means something.
func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for c in _models:
		var m: Node3D = _models[c]
		if not _is_idle(c):
			_ready_off[c] = m.position - (_home[c] as Vector3)
			continue
		var yaw: float = _home_yaw[c]
		var ready: bool = battle != null and battle.running and c.can_pay(Battle.SKILL_BLOCKS) and not battle.is_winding_up(c)
		var want := Vector3(sin(yaw), 0.0, cos(yaw)) * READY_STEP if ready else Vector3.ZERO
		var off: Vector3 = (_ready_off.get(c, Vector3.ZERO) as Vector3).lerp(want, 1.0 - exp(-6.0 * delta))
		_ready_off[c] = off
		m.position = (_home[c] as Vector3) + off
		m.rotation.y = yaw + sin(t * 0.9 + float(_phase.get(c, 0.0))) * 0.04
		var ring: Node3D = m.get_node_or_null("ReadyRing")
		if ring != null:
			ring.visible = ready
			var pulse := 1.0 + 0.12 * sin(t * 6.0)
			ring.scale = Vector3(pulse, 1.0, pulse)


func _is_idle(c: Combatant) -> bool:
	var m: Node3D = _models[c]
	if not c.is_alive() or not m.visible or _displaced.get(c, false):
		return false
	if Time.get_ticks_msec() < _busy_until.get(c, 0):
		return false
	var tw: Tween = _tweens.get(c)
	return tw == null or not tw.is_valid()


## Marked characters turn to face the attacker and flinch back; the attacker
## rears back. Both settle again once the attack is over.
func _brace(inc) -> void:
	var a: Combatant = inc.attacker
	var t: Combatant = inc.target
	var a_home: Vector3 = _home[a]
	var t_home: Vector3 = _home[t]
	var dir := _flat_dir(a_home, t_home)
	var ma: Node3D = _models[a]
	var tw := _move(a)
	tw.tween_property(ma, "position", a_home - dir * 0.7, 0.3).set_trans(Tween.TRANS_SINE)
	if t == a:
		return
	var mt: Node3D = _models[t]
	var yaw_from := mt.rotation.y
	var yaw_att := atan2(-dir.x, -dir.z)
	var tw2 := _move(t)
	tw2.tween_property(mt, "position", t_home + dir * 0.5, 0.3).set_trans(Tween.TRANS_SINE)
	tw2.parallel().tween_method(func(k: float) -> void: mt.rotation.y = lerp_angle(yaw_from, yaw_att, k), 0.0, 1.0, 0.3)


func _unbrace_later(c: Combatant, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	if not c.is_alive() or _displaced.get(c, false):
		return
	var running: Tween = _tweens.get(c)
	if running != null and running.is_valid():
		return  # Another sequence owns it.
	var m: Node3D = _models[c]
	var yaw_from := m.rotation.y
	var yaw_home: float = _home_yaw[c]
	var tw := _move(c)
	tw.tween_property(m, "position", _home[c], 0.25)
	tw.parallel().tween_method(func(k: float) -> void: m.rotation.y = lerp_angle(yaw_from, yaw_home, k), 0.0, 1.0, 0.25)


## Battle start: everyone runs in from off-screen and brakes at its spot.
func intro() -> void:
	var order := 0
	var total := 0.0
	for c in _models:
		var m: Node3D = _models[c]
		var home: Vector3 = _home[c]
		# Straight line from behind the character to its spot, facing forward all the way.
		var yaw_dir: float = _home_yaw[c]
		var forward := Vector3(sin(yaw_dir), 0.0, cos(yaw_dir))
		var from := home - forward * (8.0 if c.is_player else 14.0)
		var delay := order * 0.15
		order += 1
		var yaw_in := yaw_dir
		var yaw_home: float = _home_yaw[c]
		var dur := clampf(from.distance_to(home) / 13.0, 0.9, 1.6)
		_busy_for(c, delay + dur + 0.6)
		total = maxf(total, delay + dur + 0.5)
		m.visible = false
		m.position = from
		m.rotation.y = yaw_in
		var tw := _move(c)
		tw.tween_interval(delay)
		tw.tween_callback(func() -> void:
			m.visible = true
			_play(c, "run")
			_dust_trail(m, dur))
		tw.tween_property(m, "position", home, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			m.rotation.y = yaw_home
			_shock(home, Color(0.8, 0.95, 1.0), 2.8, 0.4)
			_smoke(home + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 8, Vector2(1.0, 1.8), 0.6, 0.4)
			_reset_idle(c))
	await get_tree().create_timer(total, false).timeout


## Battle over: the winners strike their victory pose.
func finish(player_won: bool) -> void:
	if not player_won:
		return
	for c in _models:
		if c.is_player and c.is_alive():
			_busy_for(c, 60.0)
			_stop_moving(c)
			(_models[c] as Node3D).position = _home[c]
			_play(c, "victory")


# --- Character motion --------------------------------------------------------

## Run to `stand`, play the attack clip, run back. Returns the total duration.
func _melee(a: Combatant, stand: Vector3, dir: Vector3, run_t: float) -> float:
	var m: Node3D = _models[a]
	var home: Vector3 = _home[a]
	var yaw_home: float = _home_yaw[a]
	var yaw_out := atan2(dir.x, dir.z)
	var hop_dist := stand.distance_to(home)
	var hop_t := clampf(hop_dist / 45.0, 0.3, 0.6)
	var hop_h := clampf(hop_dist * 0.12, 1.2, 3.0)
	var tw := _move(a)
	tw.tween_callback(func() -> void:
		_play(a, "run")
		_dust_trail(m, run_t + 0.12))
	tw.tween_method(func(k: float) -> void: m.rotation.y = lerp_angle(yaw_home, yaw_out, k), 0.0, 1.0, 0.12)
	tw.tween_property(m, "position", stand, run_t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: _play(a, "attack"))
	tw.tween_interval(HIT_AT + ATTACK_HOLD)
	tw.tween_callback(func() -> void:
		_play(a, "battle_idle")
		_smoke(stand + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 6, Vector2(0.9, 1.6), 0.6, 0.4))
	tw.tween_method(func(k: float) -> void:
		m.position = stand.lerp(home, k) + Vector3(0, sin(k * PI) * hop_h, 0), 0.0, 1.0, hop_t)
	tw.tween_callback(func() -> void:
		m.position = home
		m.rotation.y = yaw_home
		_shock(home, Color(0.8, 0.95, 1.0), 2.6, 0.35)
		_smoke(home + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 8, Vector2(1.0, 1.8), 0.6, 0.4)
		_reset_idle(a))
	return 0.12 + run_t + HIT_AT + ATTACK_HOLD + hop_t + 0.05


## Cast on the spot with the special-attack clip. Returns the total duration.
func _cast(a: Combatant, _dir: Vector3, color: Color) -> float:
	var home: Vector3 = _home[a]
	var total := CAST_AT + 0.9
	var tw := _move(a)
	tw.tween_callback(func() -> void: _play(a, "attack_special"))
	tw.tween_interval(total)
	tw.tween_callback(func() -> void: _reset_idle(a))
	_ring(home + Vector3(0, 1, 0), color, Vector3.ONE * 1.8, Vector3.ONE * 0.3, CAST_AT, Vector3(90, 0, 0))
	return total


## Vanish in a ground dash and reappear to the side/behind. `hold` keeps the
## character displaced until settle() is called.
func dodge(target: Combatant, text: String, hold := false) -> void:
	_stop_moving(target)
	_displaced[target] = true
	_busy_for(target, 2.4)
	var m: Node3D = _models[target]
	var home: Vector3 = _home[target]
	var side := -1.0 if target.is_player else 1.0
	var spot := home + Vector3(side * 3.6, 0.0, 1.4)
	_vanish(target, m, home, spot)
	var tw := _move(target)
	tw.tween_interval(0.14)
	tw.tween_callback(func() -> void: _appear(target, spot))
	if not hold:
		tw.tween_interval(0.6)
		tw.tween_callback(func() -> void: settle(target))
	float_text(home + Vector3(0, 3.0, 0), text, DODGE_COLOR, 40)


## Return to the home spot with another ground dash.
func settle(target: Combatant) -> void:
	var m: Node3D = _models[target]
	var home: Vector3 = _home[target]
	_vanish(target, m, m.position, home)
	var tw := _move(target)
	tw.tween_interval(0.14)
	tw.tween_callback(func() -> void: _appear(target, home))


func _hit_react(c: Combatant) -> void:
	var ap := _anim_player(c)
	if ap == null or not ap.has_animation("down"):
		return
	_stop_moving(c)
	_busy_for(c, 1.6)
	var token: int = _react_token.get(c, 0) + 1
	_react_token[c] = token
	ap.play("down", 0.05)
	await get_tree().create_timer(0.7, false).timeout
	if token != _react_token[c] or not c.is_alive():
		return
	var pos := ap.current_animation_position
	ap.play_backwards("down", 0.0)
	ap.seek(pos, true)
	await get_tree().create_timer(pos, false).timeout
	if token == _react_token[c] and c.is_alive():
		_reset_idle(c)


func _play(c: Combatant, anim: String) -> void:
	var ap := _anim_player(c)
	if ap != null and ap.has_animation(anim):
		ap.play(anim, 0.12)


func _anim_player(c: Combatant) -> AnimationPlayer:
	var m: Node3D = _models.get(c)
	if m != null and m.has_meta("anim_player"):
		return m.get_meta("anim_player")
	return null


func _reset_idle(c: Combatant) -> void:
	if not c.is_alive():
		return
	var ap := _anim_player(c)
	if ap == null:
		return
	if ap.has_animation("battle_idle"):
		ap.play("battle_idle", 0.12)
	elif ap.has_animation("idle"):
		ap.play("idle", 0.12)


## Tells the HUD to keep the HP bar where it is until the strike lands.
func _hold_hp(c: Combatant, seconds: float) -> void:
	c.set_meta("hp_hold_until", Time.get_ticks_msec() + int((seconds + 0.2) * 1000.0))


func knock(target: Combatant, from_pos: Vector3) -> void:
	var m: Node3D = _models[target]
	var home: Vector3 = _home[target]
	var dir := _flat_dir(from_pos, home)
	var tw := _move(target)
	tw.tween_property(m, "position", home + dir * 0.6, 0.06)
	tw.tween_property(m, "position", home, 0.2)


func float_text(pos: Vector3, text: String, color: Color, size := 48) -> void:
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.font_size = size
	l.pixel_size = 0.01
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + 1.5, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


# --- Element impacts ---------------------------------------------------------

# --- Impacts ---------------------------------------------------------------------

func _cam_pos() -> Vector3:
	if cam != null and cam.camera != null:
		return cam.camera.global_position
	return Vector3(0, 3, 8)


func _face_camera(node: Node3D) -> void:
	node.look_at(_cam_pos())


## Flat shockwave ring on the floor.
func _shock(ground: Vector3, color: Color, size: float, duration := 0.55) -> void:
	var q := VfxLib.animated_quad(self, Vector2(size, size), "ring", {"color": color, "energy": 2.2}, duration)
	q.position = ground + Vector3(0, 0.06, 0)
	q.rotation_degrees = Vector3(-90, 0, 0)


## Vertical ring facing the camera.
func _ring_cam(pos: Vector3, color: Color, size: float, duration := 0.5, delay := 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	var q := VfxLib.animated_quad(self, Vector2(size, size), "ring", {"color": color, "energy": 2.2}, duration)
	q.position = pos
	_face_camera(q)


func _slash(pos: Vector3, color: Color, size: float, roll_deg: float, duration := 0.28, delay := 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	var q := VfxLib.animated_quad(self, Vector2(size, size), "slash", {"color": color, "energy": 2.4}, duration)
	q.position = pos
	_face_camera(q)
	q.rotate_object_local(Vector3.BACK, deg_to_rad(roll_deg))


func _sparks(pos: Vector3, color: Color, amount: int, speed := Vector2(5.0, 12.0), gravity := Vector3(0, -10, 0)) -> void:
	VfxLib.burst(self, pos, {
		"amount": amount, "life": 0.55, "speed": speed, "gravity": gravity,
		"size": Vector2(0.14, 0.3), "end_scale": 0.2,
		"ramp": VfxLib.ramp([Color(1, 1, 1, 1), color, Color(color, 0)], [0.0, 0.3, 1.0])})


func _glow(pos: Vector3, color: Color, amount: int, size: Vector2, life: float, speed: Vector2, gravity := Vector3.ZERO, end_scale := 0.0, radius := 0.0) -> void:
	VfxLib.burst(self, pos, {
		"amount": amount, "life": life, "speed": speed, "gravity": gravity, "size": size,
		"end_scale": end_scale, "radius": radius,
		"ramp": VfxLib.ramp([Color(1, 1, 1, 1), color, Color(color, 0)], [0.0, 0.25, 1.0])})


func _smoke(pos: Vector3, color: Color, amount: int, size: Vector2, life: float, rise := 1.5, additive := false) -> void:
	VfxLib.burst(self, pos, {
		"tex": VfxLib.smoke_tex(), "additive": additive, "amount": amount, "life": life,
		"speed": Vector2(0.5, 3.0), "gravity": Vector3(0, rise, 0), "size": size, "end_scale": 1.8,
		"damping": 1.5, "radius": 0.4,
		"ramp": VfxLib.ramp([Color(color, 0.0), Color(color, 0.75), Color(color, 0.0)], [0.0, 0.2, 1.0])})


func _impact(element: Element.Type, pos: Vector3, color: Color, big: bool) -> void:
	var k := 1.5 if big else 1.0
	var ground := Vector3(pos.x, 0.0, pos.z)
	VfxLib.flash_star(self, pos, color.lightened(0.45), 3.4 * k)
	_shock(ground, color, 5.0 * k)
	match element:
		Element.Type.FISICO:
			_slash(pos, Color(1, 0.97, 0.88), 5.5 * k, 35.0)
			_slash(pos, Color(0.9, 0.95, 1.0), 5.0 * k, -42.0, 0.26, 0.06)
			_sparks(pos, Color(1.0, 0.85, 0.5), int(46 * k))
			_smoke(ground + Vector3(0, 0.3, 0), Color(0.75, 0.78, 0.8), 10, Vector2(1.2, 2.2), 0.8, 0.8)
		Element.Type.FOGO:
			_glow(pos, Color(1.0, 0.45, 0.1), int(26 * k), Vector2(1.0, 2.0), 0.75, Vector2(1.0, 4.5), Vector3(0, 4, 0), 1.2, 0.5)
			VfxLib.burst(self, pos, {"tex": VfxLib.smoke_tex(), "amount": int(24 * k), "life": 0.9, "speed": Vector2(1.0, 4.0),
				"gravity": Vector3(0, 3, 0), "size": Vector2(1.1, 2.0), "end_scale": 1.4, "radius": 0.5,
				"ramp": VfxLib.ramp([Color(1, 0.95, 0.6, 0.0), Color(1, 0.6, 0.15, 0.9), Color(0.7, 0.15, 0.05, 0.6), Color(0.1, 0.05, 0.05, 0.0)], [0.0, 0.2, 0.6, 1.0])})
			_sparks(pos, Color(1.0, 0.55, 0.15), int(30 * k), Vector2(3.0, 9.0), Vector3(0, 2, 0))
			_smoke(pos + Vector3(0, 0.5, 0), Color(0.12, 0.1, 0.1), 10, Vector2(1.6, 2.8), 1.4, 2.0)
		Element.Type.AGUA_GELO:
			for i in 7:
				var ang := i * TAU / 7.0 + 0.3
				var spike := _node(_cone(0.28, 2.0 * k), Color(0.65, 0.92, 1.0, 0.95), ground + Vector3(cos(ang) * 0.9, 1.0, sin(ang) * 0.9))
				spike.rotation = Vector3(sin(ang) * 0.35, 0, -cos(ang) * 0.35)
				spike.material_override.emission_enabled = true
				spike.material_override.emission = Color(0.4, 0.8, 1.0)
				spike.material_override.emission_energy_multiplier = 1.6
				_pop(spike, 0.7, Vector3(1, 0.05, 1), Vector3.ONE)
			_sparks(pos, Color(0.6, 0.9, 1.0), int(40 * k), Vector2(3.0, 9.0))
			_smoke(ground + Vector3(0, 0.4, 0), Color(0.75, 0.92, 1.0), 14, Vector2(1.4, 2.6), 1.1, 0.6, true)
		Element.Type.RAIO:
			_bolt(pos + Vector3(0, 9, 0), pos, color)
			_bolt(pos + Vector3(2.5, 8, 0.5), pos + Vector3(0.3, 0.2, 0), color, 0.6)
			_sparks(pos, Color(1.0, 0.95, 0.4), int(50 * k), Vector2(6.0, 14.0), Vector3(0, -6, 0))
			_ring_cam(pos, color, 4.0 * k, 0.4)
		Element.Type.PSIQUICO:
			for i in 3:
				_ring_cam(pos, color, (3.5 + i) * k, 0.55, i * 0.1)
			_glow(pos + Vector3(0, 0.2, 0), color, int(30 * k), Vector2(0.5, 1.0), 0.8, Vector2(0.5, 1.5), Vector3.ZERO, 0.0, 2.6)
			VfxLib.burst(self, pos, {"amount": int(30 * k), "life": 0.7, "speed": Vector2(0.0, 1.0), "radial_accel": -14.0,
				"size": Vector2(0.5, 0.9), "radius": 2.8, "ramp": VfxLib.ramp([Color(1, 1, 1, 0), color, Color(1, 1, 1, 0)], [0.0, 0.5, 1.0])})
		Element.Type.VENENO:
			_smoke(ground + Vector3(0, 0.6, 0), Color(0.45, 0.2, 0.55), 22, Vector2(1.8, 3.2), 1.4, 1.2)
			_smoke(ground + Vector3(0, 0.5, 0), Color(0.5, 0.85, 0.2), 12, Vector2(1.2, 2.2), 1.2, 1.4, true)
			_glow(pos, Color(0.6, 0.95, 0.25), int(20 * k), Vector2(0.25, 0.55), 1.1, Vector2(0.5, 2.5), Vector3(0, 2.5, 0), 0.4, 0.6)
		Element.Type.SOM:
			for i in 3:
				_shock(ground, color, (4.0 + i * 2.0) * k, 0.5 + i * 0.12)
				_ring_cam(pos, color, (3.0 + i * 1.6) * k, 0.45, i * 0.1)
			_sparks(pos, color, int(26 * k), Vector2(4.0, 10.0), Vector3.ZERO)
		Element.Type.TERRA:
			for i in 6:
				var ang := i * TAU / 6.0 + 0.2
				var rock_h := (3.0 if i % 2 == 0 else 2.0) * k
				var rock := _node(_cone(0.55, rock_h), Color(0.52, 0.38, 0.26, 1.0), ground + Vector3(cos(ang) * 1.3, rock_h * 0.5, sin(ang) * 1.3))
				rock.mesh.radial_segments = 5
				rock.rotation = Vector3(sin(ang) * 0.3, 0, -cos(ang) * 0.3)
				_pop(rock, 0.9, Vector3(1, 0.05, 1), Vector3.ONE)
			_smoke(ground + Vector3(0, 0.3, 0), Color(0.55, 0.42, 0.3), 18, Vector2(1.6, 3.0), 1.1, 0.8)
			VfxLib.burst(self, ground + Vector3(0, 0.5, 0), {"tex": VfxLib.glow_tex(), "additive": false, "amount": int(18 * k), "life": 0.8,
				"speed": Vector2(3.0, 8.0), "gravity": Vector3(0, -16, 0), "size": Vector2(0.18, 0.35), "end_scale": 0.6, "dir": Vector3(0, 1, 0), "spread": 60.0,
				"ramp": VfxLib.ramp([Color(0.55, 0.4, 0.28, 1), Color(0.35, 0.25, 0.18, 0.0)])})
		Element.Type.VENTO:
			for i in 3:
				_slash(pos, Color(0.75, 1.0, 0.85), 5.0 * k, i * 120.0 + 20.0, 0.34, i * 0.06)
			_sparks(pos, Color(0.8, 1.0, 0.85), int(30 * k), Vector2(4.0, 10.0), Vector3(0, 1, 0))
			_smoke(ground + Vector3(0, 0.4, 0), Color(0.8, 0.95, 0.88), 12, Vector2(1.2, 2.4), 0.9, 0.5, true)
		Element.Type.LUZ:
			var beam := _node(_cyl(1.0, 14.0), Color(1.0, 0.95, 0.6, 0.35), Vector3(pos.x, 7.0, pos.z))
			beam.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			_pop(beam, 0.55, Vector3.ONE, Vector3(0.15, 1, 0.15))
			var core := _node(_cyl(0.4, 14.0), Color(1.0, 1.0, 0.9, 0.9), Vector3(pos.x, 7.0, pos.z))
			core.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			_pop(core, 0.4, Vector3.ONE, Vector3(0.1, 1, 0.1))
			_glow(pos, Color(1.0, 0.95, 0.6), int(30 * k), Vector2(0.5, 1.2), 0.9, Vector2(1.0, 4.0), Vector3(0, 3, 0), 0.0, 0.8)
			_ring_cam(pos, color, 5.0 * k, 0.5)
		Element.Type.TREVAS:
			var orb := _node(_sphere(1.1), Color(0.05, 0.02, 0.1, 1.0), pos)
			_pop(orb, 0.6, Vector3.ONE * 0.2, Vector3.ONE * 1.7 * k)
			VfxLib.burst(self, pos, {"amount": int(36 * k), "life": 0.7, "speed": Vector2(0.0, 1.0), "radial_accel": -16.0, "radius": 3.2,
				"size": Vector2(0.4, 0.8), "ramp": VfxLib.ramp([Color(0.7, 0.35, 1.0, 0), Color(0.7, 0.35, 1.0, 1), Color(0.3, 0.1, 0.5, 0)], [0.0, 0.4, 1.0])})
			_glow(pos, Color(0.65, 0.3, 0.95), int(24 * k), Vector2(0.5, 1.0), 0.8, Vector2(3.0, 8.0))
			_shock(ground, Color(0.6, 0.25, 0.9), 6.0 * k, 0.65)


func _bolt(top: Vector3, bottom: Vector3, color: Color, scale_k := 1.0) -> void:
	var points: Array[Vector3] = [top]
	for i in range(1, 8):
		var p := top.lerp(bottom, i / 7.0)
		if i < 7:
			p += Vector3(randf_range(-0.9, 0.9), 0, randf_range(-0.9, 0.9))
		points.append(p)
	var nodes: Array[MeshInstance3D] = []
	for i in range(1, points.size()):
		var glow_seg := _line(points[i - 1], points[i], Color(color, 0.35), 0.55 * scale_k)
		glow_seg.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		var core_seg := _line(points[i - 1], points[i], Color(1, 1, 1, 1), 0.12 * scale_k)
		core_seg.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		nodes += [glow_seg, core_seg]
	var tw := create_tween()
	tw.tween_interval(0.08)
	tw.tween_callback(func() -> void:
		for n in nodes:
			n.visible = false
	)
	tw.tween_interval(0.05)
	tw.tween_callback(func() -> void:
		for n in nodes:
			n.visible = true
	)
	tw.tween_interval(0.12)
	tw.tween_callback(func() -> void:
		for n in nodes:
			n.queue_free()
	)


## A glowing orb (or an ice shard) flying from `from` to `to`, with a trail.
func _projectile(from: Vector3, to: Vector3, color: Color, element: Element.Type) -> void:
	var node := Node3D.new()
	node.position = from
	add_child(node)
	var fly := clampf(from.distance_to(to) / 50.0, FLY_TIME, 0.7)
	if element == Element.Type.AGUA_GELO:
		var shard := _node(_box(Vector3(0.28, 0.28, 1.3)), Color(0.7, 0.95, 1.0, 0.95), Vector3.ZERO)
		shard.material_override.emission_enabled = true
		shard.material_override.emission = Color(0.4, 0.85, 1.0)
		shard.material_override.emission_energy_multiplier = 2.5
		remove_child(shard)
		node.add_child(shard)
		node.look_at_from_position(from, to)
	else:
		for layer in [[2.2, color, 0.9], [1.0, Color(1, 1, 1), 1.0]]:
			var quad := QuadMesh.new()
			quad.size = Vector2.ONE * layer[0]
			var mat := VfxLib.particle_mat(VfxLib.glow_tex(), true)
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mat.vertex_color_use_as_albedo = false
			mat.albedo_color = Color(layer[1].r * 1.5, layer[1].g * 1.5, layer[1].b * 1.5, layer[2])
			quad.material = mat
			var mi := MeshInstance3D.new()
			mi.mesh = quad
			node.add_child(mi)
	var trail_ramp := VfxLib.ramp([Color(1, 1, 1, 0.9), color, Color(color, 0)], [0.0, 0.3, 1.0])
	if element == Element.Type.FOGO:
		trail_ramp = VfxLib.ramp([Color(1, 0.9, 0.5, 0.9), Color(1, 0.45, 0.1, 0.8), Color(0.2, 0.08, 0.05, 0)], [0.0, 0.35, 1.0])
	VfxLib.trail(node, {"tex": VfxLib.smoke_tex() if element == Element.Type.FOGO else VfxLib.glow_tex(), "amount": 40, "life": 0.45,
		"speed": Vector2(0.2, 1.2), "size": Vector2(0.8, 1.4), "end_scale": 0.0, "radius": 0.15, "ramp": trail_ramp})
	var tw := create_tween()
	tw.tween_property(node, "position", to, fly)
	await tw.finished
	node.queue_free()


# --- Dodge visuals -------------------------------------------------------------------

## Glowing speed streaks on the floor between two spots.
func _dash_streak(a: Vector3, b: Vector3) -> void:
	var d := b - a
	d.y = 0.0
	if d.length() < 0.1:
		return
	var forward := d.normalized()
	var side := forward.cross(Vector3.UP)
	for off: float in [-0.7, 0.0, 0.7]:
		var width := 1.5 if off == 0.0 else 0.8
		var from := a + side * off
		var to := b + side * off
		var q := VfxLib.animated_quad(self, Vector2(width, from.distance_to(to)), "streak", {"color": DODGE_COLOR, "energy": 2.6}, 0.55)
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var y_axis := (to - from).normalized()
		var z_axis := Vector3.UP
		var x_axis := y_axis.cross(z_axis)
		q.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (from + to) * 0.5 + Vector3(0, 0.07, 0))


func _vanish(c: Combatant, m: Node3D, from: Vector3, to: Vector3) -> void:
	_dash_streak(from, to)
	# Holographic afterimages: one where it stood, one halfway along the dash.
	VfxLib.ghost(self, m, DODGE_COLOR, 0.55)
	var mid := VfxLib.ghost(self, m, Color(0.6, 0.8, 1.0), 0.4)
	mid.global_position = (from + to) * 0.5
	VfxLib.flash_star(self, from + Vector3(0, 1.1, 0), DODGE_COLOR, 2.6, 0.2)
	_glow(from + Vector3(0, 1.0, 0), DODGE_COLOR, 22, Vector2(0.4, 0.9), 0.5, Vector2(2.0, 6.0), Vector3(0, 1, 0), 0.0, 0.5)
	_smoke(from + Vector3(0, 0.3, 0), Color(0.75, 0.85, 0.9), 8, Vector2(1.0, 1.8), 0.7, 0.5)
	m.visible = false


func _appear(c: Combatant, pos: Vector3) -> void:
	var m: Node3D = _models[c]
	m.position = pos
	m.visible = true
	_displaced[c] = pos.distance_to(_home[c]) > 0.5
	VfxLib.flash_star(self, pos + Vector3(0, 1.1, 0), DODGE_COLOR, 2.2, 0.18)
	_shock(pos, DODGE_COLOR, 3.4, 0.45)
	_glow(pos + Vector3(0, 0.6, 0), DODGE_COLOR, 16, Vector2(0.3, 0.7), 0.45, Vector2(1.5, 4.0), Vector3(0, 1, 0), 0.0, 0.4)
	if c.is_alive():
		_reset_idle(c)


## Short dust puffs along the floor while a character runs.
func _dust_trail(m: Node3D, duration: float) -> void:
	var t := 0.0
	while t < duration:
		_smoke(m.global_position + Vector3(0, 0.15, 0), Color(0.75, 0.82, 0.85), 3, Vector2(0.8, 1.5), 0.6, 0.4)
		await get_tree().create_timer(0.07, false).timeout
		t += 0.07


func flash(target: Combatant) -> void:
	var m: Node3D = _models[target]
	var mat := VfxLib.ensure_flash(m)
	mat.set_shader_parameter("amount", 1.0)
	create_tween().tween_method(func(v: float) -> void: mat.set_shader_parameter("amount", v), 1.0, 0.0, 0.3)


func _burst(pos: Vector3, color: Color, amount: int, speed: float, gravity: Vector3, size: float, lifetime: float) -> void:
	_glow(pos, color, amount, Vector2(size * 4.0, size * 8.0), lifetime, Vector2(speed * 0.4, speed), gravity)


# --- Primitives --------------------------------------------------------------

func _move(c: Combatant) -> Tween:
	if _tweens.has(c) and (_tweens[c] as Tween).is_valid():
		(_tweens[c] as Tween).kill()
	var tw := create_tween()
	_tweens[c] = tw
	return tw


func _has_projectile(element: Element.Type) -> bool:
	return not (element in [Element.Type.FISICO, Element.Type.RAIO, Element.Type.LUZ, Element.Type.TERRA])


## Automatic evade: the character does not move. It disappears behind a burst of
## vertical speed lines at its own spot and comes back in place.
func _dodge_later(target: Combatant, text: String, delay: float, hold_time: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	_blink(target, text, hold_time)


func _blink(target: Combatant, text: String, hold_time: float) -> void:
	_stop_moving(target)
	_busy_for(target, hold_time + 1.0)
	var m: Node3D = _models[target]
	var pos := m.position
	_speed_lines_at(pos)
	VfxLib.flash_star(self, pos + Vector3(0, 1.1, 0), DODGE_COLOR, 2.4, 0.18)
	m.visible = false
	float_text(pos + Vector3(0, 3.0, 0), text, DODGE_COLOR, 40)
	var tw := _move(target)
	tw.tween_interval(hold_time)
	tw.tween_callback(func() -> void: _appear(target, pos))


## Vertical streaks standing around a spot, facing the camera.
func _speed_lines_at(pos: Vector3) -> void:
	var cam_p := _cam_pos()
	var yaw := atan2(cam_p.x - pos.x, cam_p.z - pos.z)
	for i in 9:
		var ang := i * TAU / 9.0 + randf_range(-0.2, 0.2)
		var r := randf_range(0.2, 1.1)
		var h := randf_range(2.0, 3.4)
		var q := VfxLib.animated_quad(self, Vector2(randf_range(0.14, 0.32), h), "streak", {"color": DODGE_COLOR, "energy": 2.8}, randf_range(0.4, 0.65))
		q.position = pos + Vector3(cos(ang) * r, h * 0.5, sin(ang) * r)
		q.rotation.y = yaw
	_shock(pos, DODGE_COLOR, 3.0, 0.4)


func _flat_dir(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.RIGHT


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _node(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = _mat(color)
	n.position = pos
	add_child(n)
	return n


func _sphere(radius: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 10
	return c


func _cone(radius: float, height: float) -> CylinderMesh:
	var c := _cyl(radius, height)
	c.top_radius = 0.0
	return c


## Scales `node` from s0 to s1 while fading it out, then frees it.
func _pop(node: MeshInstance3D, time: float, s0: Vector3, s1: Vector3) -> void:
	node.scale = s0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(node, "scale", s1, time)
	tw.tween_property(node.material_override, "albedo_color:a", 0.0, time * 0.6).set_delay(time * 0.4)
	tw.chain().tween_callback(node.queue_free)


func _ring(pos: Vector3, color: Color, s0: Vector3, s1: Vector3, time: float, rot := Vector3.ZERO, delay := 0.0, free_after := true) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.85
	mesh.outer_radius = 1.0
	mesh.rings = 24
	mesh.ring_segments = 8
	var node := _node(mesh, color, pos)
	node.rotation_degrees = rot
	node.scale = s0
	var tw := create_tween().set_parallel(true)
	if delay > 0.0:
		node.visible = false
		tw.tween_callback(func() -> void: node.visible = true).set_delay(delay)
	tw.tween_property(node, "scale", s1, time).set_delay(delay)
	if free_after:
		tw.tween_property(node.material_override, "albedo_color:a", 0.0, time * 0.5).set_delay(delay + time * 0.5)
		tw.chain().tween_callback(node.queue_free)
	return node


func _line(a: Vector3, b: Vector3, color: Color, thick: float) -> MeshInstance3D:
	var node := _node(_box(Vector3(thick, thick, a.distance_to(b))), color, (a + b) * 0.5)
	var up := Vector3.RIGHT if absf((b - a).normalized().dot(Vector3.UP)) > 0.99 else Vector3.UP
	node.look_at(b, up)
	return node


