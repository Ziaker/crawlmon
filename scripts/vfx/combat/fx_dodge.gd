class_name FxDodge
extends RefCounted
## Evades: ground dash, vanish/reappear, ghosts, speed lines and the MISS! lettering.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx
var _vis_tweens: Dictionary = {}  ## Combatant -> Tween (dedicated vanish/appear timer; never killed by fx._move)


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


func _vis_tween(c: Combatant) -> Tween:
	if _vis_tweens.has(c) and (_vis_tweens[c] as Tween).is_valid():
		(_vis_tweens[c] as Tween).kill()
	var tw := fx.create_tween()
	_vis_tweens[c] = tw
	return tw


## Pressing Evade only clears the warning; the character actually dodges when the
## attack arrives (see fx.resolve_attack), never before the enemy has struck.
func manual_evade(actor: Combatant, inc) -> void:
	fx.clear_telegraph(inc)
	if not inc.evader_teleported and not inc.evader_home:
		dodge(actor, "", false)  # The usual dodge (or just MISS! while its own run owns the body).


## A perfect Evade during its own run (D-027): the rules already moved the body in front of
## the opponent; this only draws the jump (dash streak, ghost where it was, flashes, MISS!).
func teleport_flash(actor: Combatant, opponent: Combatant, from: Vector3) -> void:
	var m: Node3D = fx._models[actor]
	var spot := Vector3(actor.pos.x, 0.0, actor.pos.z)
	miss_text(from + Vector3(0, 1.4, 0))
	_dash_streak(from, spot)
	VfxLib.ghost(fx, m, fx.DODGE_COLOR, 0.55)
	VfxLib.flash_star(fx, from + Vector3(0, 1.1, 0), fx.DODGE_COLOR, 2.6, 0.2)
	VfxLib.flash_star(fx, spot + Vector3(0, 1.1, 0), fx.GOLD, 2.4, 0.2)
	var face: Vector3 = BattleSpace.flat_dir(spot, opponent.pos)
	m.rotation.y = atan2(face.x, face.z)


## A non-perfect Evade during its own run (D-029): it vanishes where it was and reappears
## at its spot (the rules already put it there and cancelled the run).
func return_flash(actor: Combatant, from: Vector3) -> void:
	var m: Node3D = fx._models[actor]
	var home := Vector3(actor.pos.x, 0.0, actor.pos.z)
	fx._stop_moving(actor)
	miss_text(from + Vector3(0, 1.4, 0))
	_vanish(actor, m, from, home, 0.11)
	var tw := _vis_tween(actor)
	tw.tween_interval(0.11)
	tw.tween_callback(func() -> void:
		if fx != null:
			_appear(actor, home, true))


## A manual Evade against a melee attack: the usual dodge (vanish, reappear aside, come back).
func engage_arrive(actor: Combatant, opponent: Combatant) -> void:
	# The evader dodges as always: it vanishes, shows up to the side and comes back. It only
	# teleports up to the interrupted attacker if and when it attacks (see arrive_to_attack).
	dodge(actor, "", false)  # (the rules already left the interrupted attacker where it stopped)


## Its first attack after the Evade: it vanishes and appears next to the interrupted attacker.
func arrive_to_attack(actor: Combatant, opponent: Combatant) -> void:
	fx._knock_home.erase(actor)  # D-1045: a real reposition cancels the recoil anchor.
	var m: Node3D = fx._models[actor]
	var from := Vector3(m.position.x, 0.0, m.position.z)
	var spot := actor.rest  # The rules already put it next to the opponent.
	var away: Vector3 = BattleSpace.flat_dir(opponent.rest, spot)
	fx._stop_moving(actor)
	fx._displaced[actor] = true
	_vanish(actor, m, from, spot)
	_appear(actor, spot, true)
	m.rotation.y = atan2(-away.x, -away.z)


## Visual feedback when the player presses Evade too early (Whiff state: vulnerable to critical hit).
## D-1015: a dodge pressed outside the valid window plays the fall ("down") clip on the one who
## mistimed it, then it goes back to its idle on its own. The hit still lands.
func mistimed(actor: Combatant, _inc) -> void:
	if not actor.is_alive() or fx.fx_motion.is_driven(actor):
		return  # Its own melee run owns the body (one timeline).
	var ap := fx._anim_player(actor)
	if ap == null or not ap.has_animation("down"):
		return
	var len := clampf(ap.get_animation("down").length, 0.4, 1.6)
	fx._busy_for(actor, len + 0.1)
	fx._play(actor, "down")
	await fx.get_tree().create_timer(len, false).timeout
	if is_instance_valid(fx) and actor.is_alive() and not fx.fx_motion.is_driven(actor):
		fx._reset_idle(actor)


func evade_whiff(actor: Combatant, _inc) -> void:
	fx._knock_home.erase(actor)  # D-1045: a real reposition cancels the recoil anchor.
	var m: Node3D = fx._models.get(actor)
	var home: Vector3 = fx._home.get(actor, Vector3.ZERO)
	if m != null:
		var tw := fx._move(actor)
		tw.tween_property(m, "position", home + Vector3(0.35, 0.0, 0.25), 0.07)
		tw.tween_property(m, "position", home - Vector3(0.25, 0.0, 0.15), 0.08)
		tw.tween_property(m, "position", home, 0.12)
	fx._ring(home + Vector3(0, 0.2, 0), fx.TELEGRAPH_COLOR, Vector3.ONE * 1.6, Vector3.ONE * 0.6, 0.35)


## Vanish in a ground dash and reappear to the side/behind. `hold` keeps the
## character displaced until settle() is called.
func dodge(target: Combatant, _text: String, hold := false) -> void:
	fx._knock_home.erase(target)  # D-1045: a real reposition cancels the recoil anchor.
	if fx.fx_motion.is_driven(target):
		# Its own melee attack owns its body (one timeline): no dash that would pull it off the run.
		miss_text((fx._models[target] as Node3D).position + Vector3(0, 1.4, 0))
		return
	fx._stop_moving(target)
	fx._displaced[target] = true
	fx._busy_for(target, 1.4 if hold else 0.75)
	var m: Node3D = fx._models[target]
	var home: Vector3 = fx._home[target]
	home.y = 0.0
	var side := -1.0 if target.is_player else 1.0
	var spot := home + Vector3(side * 3.6, 0.0, 1.4)
	spot.y = 0.0
	_vanish(target, m, home, spot, 0.11)
	var tw := _vis_tween(target)
	tw.tween_interval(0.11)
	tw.tween_callback(func() -> void:
		if fx == null:
			return
		if fx.fx_motion.is_driven(target):
			m.visible = true
			fx._vanish_until.erase(target)
		else:
			_appear(target, spot, true))
	if not hold:
		tw.tween_interval(0.39)  # 0.5 s to the side in all, then back (D-029).
		tw.tween_callback(func() -> void:
			if fx != null:
				settle(target))
	miss_text(home + Vector3(0, 1.4, 0))


## Return to the home spot with another ground dash.
func settle(target: Combatant) -> void:
	fx._knock_home.erase(target)  # D-1045: a real reposition cancels the recoil anchor.
	if fx.fx_motion.is_driven(target):
		var m_drv: Node3D = fx._models.get(target)
		if m_drv != null:
			m_drv.visible = true
		fx._vanish_until.erase(target)
		return
	if not fx._displaced.get(target, false):
		var m_home: Node3D = fx._models.get(target)
		if m_home != null and not m_home.visible:
			m_home.visible = true
			fx._vanish_until.erase(target)
		return  # Already home (e.g. it went on to a counter-attack): nothing to undo.
	var m: Node3D = fx._models[target]
	var home: Vector3 = fx._home[target]
	home.y = 0.0
	var from := Vector3(m.position.x, 0.0, m.position.z)
	_vanish(target, m, from, home, 0.10)
	var tw := _vis_tween(target)
	tw.tween_interval(0.10)
	tw.tween_callback(func() -> void:
		if fx == null:
			return
		if fx.fx_motion.is_driven(target):
			m.visible = true
			fx._vanish_until.erase(target)
		else:
			_appear(target, home, false))


## "MISS!" spelled out in glowing letters: each pops in with an overshoot, shimmers
## white/gold in a travelling wave, then rises and fades.
func miss_text(pos: Vector3, word := "MISS!") -> void:
	var cam_p := fx._cam_pos()
	var yaw := atan2(cam_p.x - pos.x, cam_p.z - pos.z)
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var gap := 0.5
	for i in word.length():
		var l := Label3D.new()
		l.text = word[i]
		l.font_size = 96
		l.pixel_size = 0.01
		l.outline_size = 10
		l.outline_modulate = Color(0.04, 0.12, 0.25)
		l.modulate = Color.WHITE
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.shaded = false
		var base := pos + right * ((i - (word.length() - 1) * 0.5) * gap)
		l.position = base
		l.scale = Vector3.ZERO
		fx.add_child(l)
		var d := i * 0.05
		var tw := fx.create_tween()
		tw.tween_interval(d)
		tw.tween_property(l, "scale", Vector3.ONE * 1.5, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "scale", Vector3.ONE, 0.1)
		# Shimmer wave across the letters while it hangs in the air.
		var sh := fx.create_tween()
		sh.tween_method(func(k: float) -> void:
			var w := 0.5 + 0.5 * sin(k * 22.0 - i * 1.1)
			l.modulate = Color(1.0, 1.0, 0.85).lerp(Color(1.0, 0.8, 0.15), w)
			l.outline_modulate = Color(0.04, 0.12, 0.25).lerp(Color(0.35, 0.12, 0.02), w), 0.0, 1.0, 0.95)
		var fade := fx.create_tween().set_parallel(true)
		fade.tween_property(l, "position:y", base.y + 0.7, 0.95).set_delay(d)
		fade.tween_property(l, "modulate:a", 0.0, 0.25).set_delay(0.7 + d)
		fade.tween_property(l, "outline_modulate:a", 0.0, 0.25).set_delay(0.7 + d)
		fade.chain().tween_callback(l.queue_free)


# --- Element impacts ---------------------------------------------------------


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
		var q := VfxLib.animated_quad(fx, Vector2(width, from.distance_to(to)), "streak", {"color": fx.DODGE_COLOR, "energy": 2.6}, 0.55)
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var y_axis := (to - from).normalized()
		var z_axis := Vector3.UP
		var x_axis := y_axis.cross(z_axis)
		q.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (from + to) * 0.5 + Vector3(0, 0.07, 0))


func _vanish(c: Combatant, m: Node3D, from: Vector3, to: Vector3, dur := 0.11) -> void:
	from.y = 0.0
	to.y = 0.0
	_dash_streak(from, to)
	# Holographic afterimages: one where it stood, one halfway along the dash.
	VfxLib.ghost(fx, m, fx.DODGE_COLOR, 0.55)
	var mid := VfxLib.ghost(fx, m, Color(0.6, 0.8, 1.0), 0.4)
	mid.global_position = (from + to) * 0.5
	VfxLib.flash_star(fx, from + Vector3(0, 1.1, 0), fx.DODGE_COLOR, 2.6, 0.2)
	fx._glow(from + Vector3(0, 1.0, 0), fx.DODGE_COLOR, 22, Vector2(0.4, 0.9), 0.5, Vector2(2.0, 6.0), Vector3(0, 1, 0), 0.0, 0.5)
	fx._smoke(from + Vector3(0, 0.3, 0), Color(0.75, 0.85, 0.9), 8, Vector2(1.0, 1.8), 0.7, 0.5)
	m.visible = false
	fx._vanish_until[c] = fx.clock + dur + 0.06


func _appear(c: Combatant, pos: Vector3, mark_displaced := false) -> void:
	pos.y = 0.0
	var m: Node3D = fx._models[c]
	m.visible = true
	fx._vanish_until.erase(c)
	if not fx.fx_motion.is_driven(c):
		m.position = pos
		fx._displaced[c] = mark_displaced and pos.distance_to(fx._home[c]) > 0.5
	VfxLib.flash_star(fx, pos + Vector3(0, 1.1, 0), fx.DODGE_COLOR, 2.2, 0.18)
	fx._shock(pos, fx.DODGE_COLOR, 3.4, 0.45)
	fx._glow(pos + Vector3(0, 0.6, 0), fx.DODGE_COLOR, 16, Vector2(0.3, 0.7), 0.45, Vector2(1.5, 4.0), Vector3(0, 1, 0), 0.0, 0.4)
	if c.is_alive() and not fx.fx_motion.is_driven(c):
		fx._reset_idle(c)


## Automatic evade: the character does not move. It disappears behind a burst of
## vertical speed lines at its own spot and comes back in place.
func _dodge_later(target: Combatant, text: String, delay: float, hold_time: float) -> void:
	if delay > 0.0:
		await fx.get_tree().create_timer(delay, false).timeout
	if fx != null:
		_blink(target, text, hold_time)


func _blink(target: Combatant, _text: String, hold_time: float) -> void:
	var m: Node3D = fx._models[target]
	if fx.fx_motion.is_driven(target):
		var p_drv := Vector3(m.position.x, 0.0, m.position.z)
		_speed_lines_at(p_drv)
		VfxLib.flash_star(fx, p_drv + Vector3(0, 1.1, 0), fx.DODGE_COLOR, 2.4, 0.18)
		miss_text(p_drv + Vector3(0, 1.4, 0))
		return
	fx._stop_moving(target)
	var dur := clampf(hold_time, 0.08, 0.14)
	fx._busy_for(target, dur + 0.35)
	var pos := fx.rest_pos(target)
	pos.y = 0.0
	_speed_lines_at(pos)
	VfxLib.flash_star(fx, pos + Vector3(0, 1.1, 0), fx.DODGE_COLOR, 2.4, 0.18)
	m.visible = false
	fx._vanish_until[target] = fx.clock + dur + 0.06
	miss_text(pos + Vector3(0, 1.4, 0))
	var tw := _vis_tween(target)
	tw.tween_interval(dur)
	tw.tween_callback(func() -> void:
		if fx != null:
			_appear(target, pos, false))


## Streaks lying completely to the left (horizontal) around a spot, facing the camera.
func _speed_lines_at(pos: Vector3) -> void:
	var cam_p := fx._cam_pos()
	var yaw := atan2(cam_p.x - pos.x, cam_p.z - pos.z)
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	for i in 9:
		var len := randf_range(2.0, 3.4)
		var q := VfxLib.animated_quad(fx, Vector2(randf_range(0.14, 0.32), len), "streak", {"color": fx.DODGE_COLOR, "energy": 2.8}, randf_range(0.4, 0.65))
		q.position = pos + right * randf_range(-0.5, 0.5) + Vector3(0, randf_range(0.3, 2.8), 0)
		q.rotation.y = yaw
		q.rotate_object_local(Vector3.BACK, deg_to_rad(90.0))  # Lying down, pointing to the left.
	fx._shock(pos, fx.DODGE_COLOR, 3.0, 0.4)
