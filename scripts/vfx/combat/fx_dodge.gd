class_name FxDodge
extends RefCounted
## Evades: ground dash, vanish/reappear, flash + speed lines (D-322 redo), WHIFF and the MISS! lettering.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx
var _vis_tweens: Dictionary = {}  ## Combatant -> Tween (dedicated vanish/appear timer; never killed by fx._move)
var last_whiff: Dictionary = {}  ## D-1166/D-1167 debug audit: what the last mistimed Evade played.
var _whiff_labels: Dictionary = {}  ## Combatant -> Node3D (the last WHIFF lettering)
var _falling: Dictionary = {}  ## Combatant -> base rotation.x while the assisted fall owns it
var _mistimed_id: Dictionary = {}  ## Combatant -> token; invalidates an old fall coroutine after a valid Evade


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
	# A valid Evade overrides any leftover WHIFF/fall from an early press (D-1180).
	_cancel_mistimed_visual(actor)
	last_whiff = {}
	fx.clear_telegraph(inc)
	if not inc.evader_teleported and not inc.evader_home:
		dodge(actor, "", false)  # The usual dodge (or just MISS! while its own run owns the body).


## A perfect Evade during its own run (D-027): the rules already moved the body in front of
## the opponent; this only draws the jump (flash, rings, speed lines, MISS!).
func teleport_flash(actor: Combatant, opponent: Combatant, from: Vector3) -> void:
	var m: Node3D = fx._models[actor]
	var spot := Vector3(actor.pos.x, 0.0, actor.pos.z)
	miss_text(from + Vector3(0, 1.4, 0))
	_dodge_burst(from, spot - from)  # D-322 redo: flash + rings + speed lines along the jump.
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


## D-1180: removes the WHIFF text and restores the body rotation from a previous
## mistimed Evade. Call it when a valid Evade lands: an old mistake must not keep
## the character fallen or the WHIFF word on screen while the dodge actually worked.
func _cancel_mistimed_visual(actor: Combatant) -> void:
	_mistimed_id[actor] = int(_mistimed_id.get(actor, 0)) + 1
	_clear_whiff_label(actor)
	if not _falling.has(actor):
		return
	var m: Node3D = fx._models.get(actor)
	if m != null and is_instance_valid(m):
		m.rotation.x = float(_falling[actor])
	_falling.erase(actor)
	var tw: Tween = fx._tweens.get(actor)
	if tw != null and tw.is_valid():
		tw.kill()


func _clear_whiff_label(actor: Combatant) -> void:
	var label: Node3D = _whiff_labels.get(actor)
	if label != null and is_instance_valid(label):
		label.queue_free()
	_whiff_labels.erase(actor)


## Visual feedback when the player presses Evade too early (Whiff state: vulnerable to critical hit).
## D-1015 + D-1166: a dodge pressed outside the valid window plays the fall ("down") clip on the one
## who mistimed it, shows WHIFF above it and kicks dust at its feet. Pokemon "down" clips barely
## drop the body, so those get a code-driven fall. The hit still lands and no rule changes.
func mistimed(actor: Combatant, _inc) -> void:
	if not actor.is_alive():
		return
	_cancel_mistimed_visual(actor)  # D-1180: a new mistake replaces the previous WHIFF/fall cleanly.
	var my_id := int(_mistimed_id.get(actor, 0)) + 1
	_mistimed_id[actor] = my_id
	if fx.fx_motion.is_driven(actor):
		# Its own melee run owns the body (one timeline): no fall, but the mistake is still shown.
		var text_driven := _whiff_text(actor)
		var dust_driven := _whiff_dust(actor)
		last_whiff = {"actor": actor.name, "clip": "", "fall_assist": false, "down_falls": false,
			"whiff_text": text_driven, "dust": dust_driven}
		return
	var ap := fx._anim_player(actor)
	var has_down := ap != null and ap.has_animation("down")
	var down_falls := has_down and _down_clip_falls(ap)
	var clip := ""
	if down_falls:
		clip = "down"
	elif ap != null and ap.has_animation("damage"):
		clip = "damage"  # D-1167: no usable fall clip -> use the damage clip.
	elif has_down:
		clip = "down"
	var dur := clampf(ap.get_animation(clip).length, 0.4, 1.6) if clip != "" else 0.9
	fx._busy_for(actor, dur + 0.1)
	if clip != "":
		fx._play(actor, clip)
	var assist := not down_falls
	var m: Node3D = fx._models.get(actor)
	var base_x := 0.0
	if assist and m != null:
		base_x = m.rotation.x
		_falling[actor] = base_x
		var tw := fx._move(actor)
		tw.tween_property(m, "rotation:x", base_x - PI * 0.5, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_interval(maxf(dur - 0.40, 0.0))
		tw.tween_property(m, "rotation:x", base_x, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var text_ok := _whiff_text(actor)
	# Dust when the body reaches the floor (the DQT fall clips land later than the assisted one).
	var dust_delay := 0.28 if assist else clampf(dur * 0.45, 0.3, 0.7)
	_whiff_dust_later(actor, dust_delay)
	last_whiff = {"actor": actor.name, "clip": clip, "fall_assist": assist, "down_falls": down_falls,
		"whiff_text": text_ok, "dust_scheduled": true, "dust_delay": dust_delay}
	await fx.get_tree().create_timer(dur, false).timeout
	if not is_instance_valid(fx):
		return
	if int(_mistimed_id.get(actor, -1)) != my_id:
		return  # A valid Evade or a new mistake took over; do not reset over it.
	if assist and is_instance_valid(m):
		m.rotation.x = base_x
	_falling.erase(actor)
	_mistimed_id.erase(actor)
	if actor.is_alive() and not fx.fx_motion.is_driven(actor):
		fx._reset_idle(actor)


## True when the model's "down" clip itself drops the body. The Pokemon clips only move
## limbs/head a little; the DQT "Die" clips rotate/translate the hip or root bone.
func _down_clip_falls(ap: AnimationPlayer) -> bool:
	if ap == null or not ap.has_animation("down"):
		return false
	var a := ap.get_animation("down")
	var max_y := 0.0
	var max_angle := 0.0
	for i in a.get_track_count():
		var path := str(a.track_get_path(i)).to_lower()
		var is_body := false
		for suffix in [":origin", ":root", ":waist", ":n_hara", ":j_kosi", ":hip", ":hips", ":pelvis", ":cog"]:
			if path.ends_with(suffix):
				is_body = true
				break
		if not is_body:
			continue
		var typ := a.track_get_type(i)
		var n := a.track_get_key_count(i)
		if n == 0:
			continue
		if typ == Animation.TYPE_POSITION_3D:
			var lo := INF
			var hi := -INF
			for k in n:
				var y: float = (a.track_get_key_value(i, k) as Vector3).y
				lo = minf(lo, y)
				hi = maxf(hi, y)
			max_y = maxf(max_y, hi - lo)
		elif typ == Animation.TYPE_ROTATION_3D:
			var first: Quaternion = a.track_get_key_value(i, 0)
			for k in n:
				max_angle = maxf(max_angle, first.angle_to(a.track_get_key_value(i, k)))
	return max_y > 0.25 or max_angle > 0.6


## D-1166: the exact word above the one who mistimed the Evade. D-322 redo, animated: a swing
## whooshes through empty air, "WHIFF" is whipped in letter by letter in the swing's wake
## (smeared, then snapping into line with overshoot), wobbles dizzily like a missed swing,
## and finally each letter is blown away spinning, last one first. Facing the camera, so it
## reads the same for any character, side or distance (D-235).
func _whiff_text(actor: Combatant) -> bool:
	var m: Node3D = fx._models.get(actor)
	if m == null:
		return false
	_clear_whiff_label(actor)
	var head := float(m.get_meta("head_y", 2.0)) if m.has_meta("head_y") else 2.0
	var base := fx.to_local(m.global_position) + Vector3(0, head + 0.45, 0)
	var cam_p := fx._cam_pos()
	var yaw := atan2(cam_p.x - base.x, cam_p.z - base.z)
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var z_axis := Vector3(sin(yaw), 0.0, cos(yaw))
	var root := Node3D.new()
	root.position = base
	root.rotation.y = yaw
	fx.add_child(root)
	_whiff_labels[actor] = root
	var word := "WHIFF"
	var gap := 0.74
	var amber := Color("ffb020")
	var cols := [Color("ffd23f"), Color("ffb020"), Color("ff9a1f"), Color("ff7a1a"), Color("ff5a1a")]
	# 1) The empty swing: two bright streaks cut across the spot, slightly tilted.
	for k in 2:
		var tilt := deg_to_rad(-14.0 + k * 9.0)
		var y_axis := (right * cos(tilt) + Vector3.UP * sin(tilt)).normalized()
		var q := VfxLib.animated_quad(fx, Vector2(0.14 - k * 0.05, 4.4), "streak", {"color": Color.WHITE if k == 0 else amber, "energy": 3.2}, 0.26)
		q.basis = Basis(y_axis.cross(z_axis).normalized(), y_axis, z_axis)
		var from_p := base - right * 3.4 + Vector3(0, -0.1 + k * 0.18, 0)
		q.position = from_p
		q.create_tween().tween_property(q, "position", from_p + right * 6.8, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# 2) Letters whipped in behind the swing, then dizzy, then blown away.
	var n := word.length()
	for i in n:
		var l := Label3D.new()
		l.text = word[i]
		l.font_size = 130
		l.pixel_size = 0.009
		l.outline_size = 24
		l.outline_modulate = Color(0.16, 0.05, 0.0)
		l.modulate = Color(1, 1, 1, 0)
		l.shaded = false
		l.no_depth_test = true
		var slot := Vector3((i - (n - 1) * 0.5) * gap, 0.0, 0.0)
		l.position = slot + Vector3(-2.6 + i * 0.2, 0.5, 0.0)
		l.scale = Vector3(3.2, 0.35, 1.0)
		l.rotation.z = deg_to_rad(-28.0)
		root.add_child(l)
		var d := 0.07 + i * 0.045
		var tw := l.create_tween()
		tw.tween_interval(d)
		# Whip in: fade up, ease from the smeared start to the slot with overshoot.
		tw.tween_property(l, "modulate", Color.WHITE, 0.04)
		tw.parallel().tween_property(l, "position", slot, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(l, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(l, "rotation:z", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "modulate", cols[i], 0.1)
		# Dizzy wobble of a missed swing: the whole word sways, letters out of phase.
		var ph := float(i) * 0.9
		tw.tween_method(func(k: float) -> void:
			var decay := 1.0 - k
			l.rotation.z = sin(k * 20.0 + ph) * deg_to_rad(11.0) * decay
			l.position = slot + Vector3(0.0, sin(k * 16.0 + ph) * 0.09 * decay, 0.0), 0.0, 1.0, 0.45)
		# Blown away: last letter first, spinning off up and to the side, shrinking out.
		tw.tween_interval((n - 1 - i) * 0.04)
		tw.tween_property(l, "position", slot + Vector3(2.2 + i * 0.25, 1.1 + i * 0.1, 0.0), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(l, "rotation:z", deg_to_rad(-380.0 - i * 40.0), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(l, "scale", Vector3.ONE * 0.2, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(l, "modulate:a", 0.0, 0.2).set_delay(0.14)
		tw.parallel().tween_property(l, "outline_modulate:a", 0.0, 0.2).set_delay(0.14)
	# 3) Spark kick on the first snap, and cleanup of the whole lettering.
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.2)
	cleanup.tween_callback(func() -> void:
		fx._burst(base, amber, 12, 3.0, Vector3(0, -6, 0), 0.07, 0.4))
	cleanup.tween_interval(1.25)
	cleanup.tween_callback(root.queue_free)
	return true


## D-1166 / D-322 redo: a flat dust ring races out along the floor, a plume of puffs rolls
## outward in all directions and loose grit hops off the ground.
func _whiff_dust(actor: Combatant) -> bool:
	var m: Node3D = fx._models.get(actor)
	if m == null:
		return false
	var p := fx.to_local(m.global_position)
	p.y = 0.0
	var earth := Color(0.72, 0.64, 0.5)
	fx._shock(p + Vector3(0, 0.05, 0), earth, 3.2, 0.5)
	fx._smoke(p + Vector3(0, 0.2, 0), earth, 18, Vector2(1.0, 2.2), 0.8, 0.5)
	fx._burst(p + Vector3(0, 0.15, 0), Color(0.55, 0.47, 0.36), 14, 3.0, Vector3(0, -12, 0), 0.1, 0.55)
	return true


func _whiff_dust_later(actor: Combatant, delay: float) -> void:
	await fx.get_tree().create_timer(delay, false).timeout
	if is_instance_valid(fx):
		_whiff_dust(actor)


## D-1166/D-1167 debug audit: the last mistimed Evade visual (clip, fall assist, WHIFF/dust).
func last_whiff_info() -> Dictionary:
	return last_whiff.duplicate(true)


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


## D-322 redo. The "impact frame" of a successful dodge, at the instant of the dodge:
## a hard flash, two shock rings facing the camera and speed lines. The lines run along
## `axis` (attacker -> target, or the dodge direction) projected onto the camera plane, so the
## effect reads the same for any attacker, side or camera distance (D-235).
func _dodge_burst(pos: Vector3, axis: Vector3) -> void:
	var center := pos + Vector3(0, 1.1, 0)
	var to_cam := fx._cam_pos() - center
	if to_cam.length() < 0.01:
		to_cam = Vector3.BACK
	var z := to_cam.normalized()
	var yaw_deg := rad_to_deg(atan2(z.x, z.z))
	var up := Vector3.UP
	# Direction of the lines on screen: the axis projected onto the camera plane.
	var along := axis - z * axis.dot(z)
	if along.length() < 0.15:
		along = up.cross(z)  # Axis points at the camera: fall back to camera-right.
	along = along.normalized()
	var perp := z.cross(along).normalized()
	# Flash: white core over a tinted bloom.
	VfxLib.flash_star(fx, center, Color.WHITE, 2.4, 0.12)
	VfxLib.flash_star(fx, center, fx.DODGE_COLOR, 4.2, 0.2)
	# Two thin rings facing the camera.
	fx._ring(center, Color(1, 1, 1, 0.95), Vector3.ONE * 0.3, Vector3.ONE * 2.8, 0.2, Vector3(90, yaw_deg, 0), 0.0, true, 0.93)
	fx._ring(center, fx.DODGE_COLOR, Vector3.ONE * 0.2, Vector3.ONE * 4.0, 0.3, Vector3(90, yaw_deg, 0), 0.04, true, 0.96)
	# Speed lines racing along the axis, staggered across the body.
	for i in 14:
		var length := randf_range(2.2, 4.2)
		var q := VfxLib.animated_quad(fx, Vector2(randf_range(0.05, 0.12), length), "streak", {"color": Color.WHITE if i % 3 == 0 else fx.DODGE_COLOR, "energy": 3.0}, randf_range(0.22, 0.34))
		var y_axis := along
		var x_axis := y_axis.cross(z).normalized()
		q.basis = Basis(x_axis, y_axis, z)
		var start := center + perp * randf_range(-1.5, 1.5) - along * randf_range(0.6, 1.8)
		q.position = start
		q.create_tween().tween_property(q, "position", start + along * randf_range(2.5, 4.0), 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Short radial burst lines around the flash.
	for i in 8:
		var ang := TAU * (float(i) + randf_range(-0.2, 0.2)) / 8.0
		var dir := along * cos(ang) + perp * sin(ang)
		var q := VfxLib.animated_quad(fx, Vector2(0.09, 1.1), "streak", {"color": Color.WHITE, "energy": 3.2}, 0.2)
		q.basis = Basis(dir.cross(z).normalized(), dir, z)
		var s0 := center + dir * 0.5
		q.position = s0
		q.create_tween().tween_property(q, "position", center + dir * 1.8, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _vanish(c: Combatant, m: Node3D, from: Vector3, to: Vector3, dur := 0.11) -> void:
	from.y = 0.0
	to.y = 0.0
	_dodge_burst(from, to - from)
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
	if c.is_alive() and not fx.fx_motion.is_driven(c):
		fx._reset_idle(c)


## Automatic evade: the character does not move. It disappears behind a burst of
## vertical speed lines at its own spot and comes back in place.
func _dodge_later(target: Combatant, text: String, delay: float, hold_time: float, axis := Vector3.ZERO) -> void:
	if delay > 0.0:
		await fx.get_tree().create_timer(delay, false).timeout
	if fx != null:
		_blink(target, text, hold_time, axis)


func _blink(target: Combatant, _text: String, hold_time: float, axis := Vector3.ZERO) -> void:
	var m: Node3D = fx._models[target]
	if fx.fx_motion.is_driven(target):
		var p_drv := Vector3(m.position.x, 0.0, m.position.z)
		_dodge_burst(p_drv, axis)
		miss_text(p_drv + Vector3(0, 1.4, 0))
		return
	fx._stop_moving(target)
	var dur := clampf(hold_time, 0.08, 0.14)
	fx._busy_for(target, dur + 0.35)
	var pos := fx.rest_pos(target)
	pos.y = 0.0
	_dodge_burst(pos, axis)
	m.visible = false
	fx._vanish_until[target] = fx.clock + dur + 0.06
	miss_text(pos + Vector3(0, 1.4, 0))
	var tw := _vis_tween(target)
	tw.tween_interval(dur)
	tw.tween_callback(func() -> void:
		if fx != null:
			_appear(target, pos, false))
