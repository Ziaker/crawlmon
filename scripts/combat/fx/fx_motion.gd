class_name FxMotion
extends RefCounted
## Everything that moves the bodies: entrance, run, leap back, hit-stop, knockback, animations.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx
## Overlapping hit-stops share one saved speed per player (never capture 0 as "previous").
var _frozen: Dictionary = {}  # AnimationPlayer -> [saved speed, holders]
var _react_token: Dictionary = {}  ## Combatant -> int


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


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
	var tw_now: Tween = fx._tweens.get(c)
	if tw_now != null and tw_now.is_valid():
		return  # A scripted sequence (run, dodge...) owns it; let it finish.
	var m: Node3D = fx._models[c]
	m.rotation.y = fx._home_yaw[c]


## The character's current resting spot becomes its home.
func _rebase(c: Combatant) -> void:
	_stop_moving(c)


# --- Life: ready stance, breathing, reactions, intro and victory --------------------


## Battle start: everyone runs in from off-screen and brakes at its spot.
func intro() -> void:
	var order := 0
	var total := 0.0
	for c in fx._models:
		var m: Node3D = fx._models[c]
		var home: Vector3 = fx._home[c]
		# Straight line from behind the character to its spot, facing forward all the way.
		var yaw_dir: float = fx._home_yaw[c]
		var forward := Vector3(sin(yaw_dir), 0.0, cos(yaw_dir))
		var from := home - forward * (8.0 if c.is_player else 14.0)
		var delay := order * 0.15
		order += 1
		var yaw_in := yaw_dir
		var yaw_home: float = fx._home_yaw[c]
		var dur := clampf(from.distance_to(home) / 13.0, 0.9, 1.6)
		fx._busy_for(c, delay + dur + 0.6)
		total = maxf(total, delay + dur + 0.5)
		m.visible = false
		m.position = from
		m.rotation.y = yaw_in
		var tw := fx._move(c)
		tw.tween_interval(delay)
		tw.tween_callback(func() -> void:
			m.visible = true
			_play(c, "run")
			_dust_trail(m, dur))
		# Constant running speed (so the feet match the floor), then a very short brake:
		# the idle pose takes over the instant the braking starts.
		var base_speed: float = fx._base_speed.get(c, 1.0)
		var kb := clampf(0.07 / dur, 0.03, 0.2)  # Braking share of the run.
		var v0 := 1.0 / (1.0 - kb * 0.5)  # Normalized cruise speed.
		var braked := [false]
		tw.tween_method(func(k: float) -> void:
			var kc := 1.0 - kb
			var f := k * v0 if k <= kc else v0 * kc + v0 * (k - kc) * (1.0 - 0.5 * (k - kc) / kb)
			m.position = from.lerp(home, minf(f, 1.0))
			if k >= kc and not braked[0]:
				braked[0] = true
				var ap := _anim_player(c)
				if ap != null:
					ap.speed_scale = base_speed
					if ap.has_animation("battle_idle"):
						ap.play("battle_idle", 0.05)
					else:
						_reset_idle(c), 0.0, 1.0, dur)
		tw.tween_callback(func() -> void:
			var ap := _anim_player(c)
			if ap != null:
				ap.speed_scale = base_speed
			m.rotation.y = yaw_home
			fx._shock(home, Color(0.8, 0.95, 1.0), 2.8, 0.4)
			fx._smoke(home + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 8, Vector2(1.0, 1.8), 0.6, 0.4)
			_reset_idle(c))
	await fx.get_tree().create_timer(total, false).timeout


## Battle over: the winners strike their victory pose.
func finish(player_won: bool) -> void:
	if not player_won:
		return
	for c in fx._models:
		if c.is_player and c.is_alive():
			fx._busy_for(c, 60.0)
			_stop_moving(c)
			(fx._models[c] as Node3D).position = fx._home[c]
			_play(c, "victory")


# --- Character motion --------------------------------------------------------


func _clip_len(c: Combatant, anim: String) -> float:
	var ap := _anim_player(c)
	return ap.get_animation(anim).length if ap != null and ap.has_animation(anim) else 0.0


## When the strike lands: the middle of the model's own clip (fallback: the constant).
func _clip_hit(c: Combatant, anim: String, fallback: float) -> float:
	var len := _clip_len(c, anim)
	return clampf(len * 0.5, 0.25, 0.8) if len > 0.0 else fallback


# --- Attack timeline: BattleFx only DRAWS what Battle's clock says -------------------
## Battle owns PREPARO -> TRAJETO -> GOLPE -> RETORNO (`Incoming.phase`, `phase_time`);
## nothing here decides when a hit, an arrival or a return happens.

## Fills the timeline of a resolved attack (seconds of logic time) and the drawing data.
## Returns the total duration.
func begin_attack(inc) -> float:
	var a: Combatant = inc.attacker
	var t: Combatant = inc.target
	var a_home: Vector3 = fx.rest_pos(a)  # Engaged characters stand away from home.
	var t_home: Vector3 = fx.rest_pos(t)
	var dir: Vector3 = fx._flat_dir(a_home, t_home)
	var P := Battle.Phase
	# Travel times start from the step-0 geometry and then lose 0.10 s per step.
	var a0: Vector3 = fx._origin[a]
	var t0: Vector3 = fx._origin[t]
	var m: Node3D = fx._models[a]
	var d := {"dir": dir, "base_scale": fx._base_scale.get(a, m.scale)}
	if inc.element == Element.Type.FISICO and a.engaged_with == t:
		# Already standing next to it: no travel, no return.
		var hit0 := _clip_hit(a, "attack", fx.HIT_AT)
		d.merge({"kind": "melee", "engaged": true, "stand": a_home, "run_t": 0.0, "hit": hit0, "hold": 0.0,
			"antic": 0.0, "hop_t": 0.3, "hop_h": 1.2, "yaw_out": atan2(dir.x, dir.z), "from": a_home})
		inc.plan = [[P.STRIKE, hit0]]
		inc.impact_phase = P.STRIKE
	elif inc.element == Element.Type.FISICO:
		var stand := t_home - dir * fx.STAND_GAP
		var stand0 := t0 - fx._flat_dir(a0, t0) * fx.STAND_GAP
		var run_t := Battle.travel_seconds(clampf(a0.distance_to(stand0) / fx.RUN_SPEED, 0.35, 0.8), a, t)
		var hop_dist := stand.distance_to(a_home)
		var antic := 0.0 if inc.instant else fx.ANTICIP_T
		var hit := _clip_hit(a, "attack", fx.HIT_AT)
		d.merge({"kind": "melee", "stand": stand, "run_t": run_t, "hit": hit, "hold": 0.2,
			"antic": antic, "hop_t": clampf(hop_dist / 70.0, 0.22, 0.4),
			"hop_h": clampf(hop_dist * 0.12, 1.2, 3.0), "yaw_out": atan2(dir.x, dir.z), "from": m.position})
		inc.plan = [[P.TRAVEL, 0.12 + run_t], [P.STRIKE, antic + hit], [P.RETURN, 0.2 + d["hop_t"]]]
		inc.impact_phase = P.STRIKE
	else:
		var hit := 0.15 if inc.instant else _clip_hit(a, "attack_special", fx.CAST_AT)
		var total := fx.CAST_AT + 0.42
		d["kind"] = "cast"
		if fx._has_projectile(inc.element):
			var fly := Battle.travel_seconds(clampf(a0.distance_to(t0) / 50.0, fx.FLY_TIME, 0.7), a, t)
			d["fly"] = fly
			inc.plan = [[P.STRIKE, hit], [P.TRAVEL, fly], [P.RETURN, maxf(total - hit - fly, 0.05)]]
			inc.impact_phase = P.TRAVEL
		else:
			inc.plan = [[P.STRIKE, hit], [P.RETURN, maxf(total - hit, 0.05)]]
			inc.impact_phase = P.STRIKE
	inc.data = d
	var sum := 0.0
	for seg in inc.plan:
		sum += seg[1]
	return sum


func is_driven(c: Combatant) -> bool:
	if fx.battle == null:
		return false
	for inc in fx.battle.attacks_in_flight():
		if inc.attacker == c and inc.data.get("kind", "") == "melee":
			return true
	return false


## A phase started: one-shot effects and animation changes.
func on_phase(inc, phase: int) -> void:
	var a: Combatant = inc.attacker
	var d: Dictionary = inc.data
	if d.is_empty():
		return
	var m: Node3D = fx._models[a]
	var P := Battle.Phase
	var melee: bool = d["kind"] == "melee"
	match phase:
		P.TRAVEL:
			if melee:
				fx._stop_moving(a)
				fx._displaced[a] = false  # A counter-attack starts from wherever the evade left it.
				m.visible = true
				d["from"] = m.position
				_play(a, "run")
				_dust_trail(m, d["run_t"] + 0.12)
			else:
				fx.fx_projectiles.spawn(inc)
		P.STRIKE:
			if melee:
				if d["antic"] > 0.0:
					fx._smoke(d["stand"] + Vector3(0, 0.15, 0), Color(0.82, 0.85, 0.88), 4, Vector2(0.7, 1.3), 0.35, 0.3)
			else:
				_play(a, "attack_special")
				fx._ring((fx._home[a] as Vector3) + Vector3(0, 1, 0), fx.COLORS[inc.element], Vector3.ONE * 1.8, Vector3.ONE * 0.3, fx.CAST_AT, Vector3(90, 0, 0))
		P.RETURN:
			fx.fx_projectiles.finish(inc)
		P.STAGGER:
			# Interrupted by an Evade: it stops right here and stumbles until the engagement ends.
			d["lunged"] = m.position
			fx._rest[a] = m.position
			if not melee:
				fx.fx_projectiles.finish(inc)
			_play(a, "damage")
		P.DONE:
			if melee and d.get("engaged", false):
				m.position = fx.rest_pos(a)
				m.scale = d["base_scale"]
			elif melee:
				m.position = fx._home[a]
				m.rotation.y = fx._home_yaw[a]
				m.scale = d["base_scale"]
				fx._rest.erase(a)
				fx._displaced[a] = false
				fx._shock(fx._home[a], Color(0.8, 0.95, 1.0), 2.2, 0.25)
				fx._smoke((fx._home[a] as Vector3) + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 6, Vector2(0.9, 1.5), 0.45, 0.3)
			else:
				fx._rest.erase(a)
			_reset_idle(a)
			fx.fx_projectiles.finish(inc)


## The engaged state ended: the evader hops home and the stunned attacker recovers
## (BattleFx only fills the plans; Battle runs them).
func on_engage_ended(_actor: Combatant, _opponent: Combatant, ghost, staggered) -> void:
	_plan_return(ghost)
	if staggered != null:
		_plan_return(staggered)


func _plan_return(inc) -> void:
	var a: Combatant = inc.attacker
	var m: Node3D = fx._models[a]
	var home: Vector3 = fx._home[a]
	var pos := m.position
	if not inc.ghost and inc.data.get("kind", "") == "cast":
		inc.plan = [[Battle.Phase.RETURN, 0.15]]  # A caster only recovers; it never left home.
		return
	var dist := pos.distance_to(home)
	var hop_t := clampf(dist / 70.0, 0.22, 0.4)
	inc.data = {"kind": "melee", "dir": fx._flat_dir(pos, home), "stand": pos, "lunged": pos, "hold": 0.0,
		"hop_t": hop_t, "hop_h": clampf(dist * 0.12, 1.2, 3.0), "yaw_out": m.rotation.y,
		"base_scale": fx._base_scale.get(a, m.scale)}
	inc.plan = [[Battle.Phase.RETURN, hop_t]]


func _ease_quad_out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)


func _ease_expo_out(k: float) -> float:
	return 1.0 if k >= 1.0 else 1.0 - pow(2.0, -10.0 * k)


func _ease_back_out(k: float) -> float:
	var c1 := 1.70158
	var x := k - 1.0
	return 1.0 + (c1 + 1.0) * x * x * x + c1 * x * x


## Every frame: pose the attackers (and projectiles) from the logic progress.
func drive() -> void:
	if fx.battle == null:
		return
	for inc in fx.battle.attacks_in_flight():
		var d: Dictionary = inc.data
		if d.is_empty() or inc.phase == Battle.Phase.DONE:
			continue
		var a: Combatant = inc.attacker
		var m: Node3D = fx._models[a]
		if d["kind"] == "cast":
			fx.fx_projectiles.drive(inc)
			continue
		if fx._displaced.get(a, false) and not d.get("engaged", false) and not inc.ghost:
			continue
		var home: Vector3 = fx._home[a]
		var stand: Vector3 = d["stand"]
		var dir: Vector3 = d["dir"]
		var base_scale: Vector3 = d["base_scale"]
		var e: float = inc.phase_time
		match inc.phase:
			Battle.Phase.TRAVEL:
				var yaw_home: float = fx._home_yaw[a]
				m.rotation.y = lerp_angle(yaw_home, d["yaw_out"], clampf(e / 0.12, 0.0, 1.0))
				if e > 0.12:
					var k := clampf((e - 0.12) / d["run_t"], 0.0, 1.0)
					m.position = (d["from"] as Vector3).lerp(stand, 0.5 - 0.5 * cos(k * PI))  # Sine in/out
			Battle.Phase.STRIKE:
				m.rotation.y = d["yaw_out"]
				var antic: float = d["antic"]
				var coil := stand if antic <= 0.0 else stand - dir * 0.38
				var pos := stand
				if e < antic:
					pos = stand.lerp(coil, _ease_quad_out(e / antic))
				else:
					if not d.get("swung", false):
						d["swung"] = true
						_play(a, "attack")
					var lunge_t: float = minf(d["hit"], 0.18)
					pos = coil.lerp(stand + dir * 0.22, _ease_expo_out(clampf((e - antic) / lunge_t, 0.0, 1.0)))
					# Blade/claw trail slightly before the contact frame.
					if not d.get("slashed", false) and e - antic >= maxf(d["hit"] - 0.06, 0.02):
						d["slashed"] = true
						VfxLib.mesh_slash(fx, stand + dir * 1.35 + Vector3(0, 1.0, 0), dir, Color(1.0, 0.96, 0.86), 24.0, 1.15, 0.25, "slash_arc")
				m.position = pos
				# Squash on the coil, then spring back.
				var sq := antic * 0.7
				if antic > 0.0 and e < sq + 0.09:
					if e < sq:
						m.scale = base_scale.lerp(base_scale * Vector3(1.12, 0.86, 1.12), _ease_quad_out(e / sq))
					else:
						m.scale = (base_scale * Vector3(1.12, 0.86, 1.12)).lerp(base_scale, _ease_back_out((e - sq) / 0.09))
				else:
					m.scale = base_scale
			Battle.Phase.RETURN:
				m.rotation.y = d["yaw_out"]
				var hold: float = d["hold"]
				var lunged: Vector3 = d.get("lunged", stand + dir * 0.22)
				if e < hold:
					m.position = lunged
				else:
					if not d.get("hopped", false):
						d["hopped"] = true
						m.scale = base_scale
						_play(a, "battle_idle")
						fx._smoke(stand + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 5, Vector2(0.8, 1.4), 0.4, 0.3)
					var k := clampf((e - hold) / d["hop_t"], 0.0, 1.0)
					m.position = lunged.lerp(home, k) + Vector3(0, sin(k * PI) * d["hop_h"], 0)


## Micro-freeze (Hit Stop) on the exact frame of contact.
## Vibrates strictly the target model and the impact effect (never the camera).
func _hit_stop(attacker: Combatant, target: Combatant, heavy: bool, strike_dir := Vector3.FORWARD, impact_fx: Array[Node3D] = []) -> void:
	var stop_dur := 0.115 if heavy else 0.07
	var ap_a := _anim_player(attacker)
	var ap_t := _anim_player(target)
	_freeze(ap_a)
	if ap_t != ap_a:
		_freeze(ap_t)
	var mt: Node3D = fx._models.get(target)
	var base_pos := mt.position if mt != null else Vector3.ZERO
	var perp := Vector3(strike_dir.z, 0.0, -strike_dir.x)
	var amp := 0.22 if heavy else 0.12
	var step := 0.016
	var elapsed := 0.0
	var sign_k := 1.0
	while elapsed < stop_dur:
		var decay := 1.0 - clampf(elapsed / stop_dur, 0.0, 1.0)
		if mt != null and is_instance_valid(mt):
			var vib := (perp * sign_k * amp + strike_dir * (amp * 0.45)) * decay
			mt.position = base_pos + vib
		for node in impact_fx:
			if is_instance_valid(node):
				node.position += perp * (sign_k * 0.06 * decay)
		sign_k = -sign_k
		await fx.get_tree().create_timer(step, false).timeout
		elapsed += step
	if mt != null and is_instance_valid(mt) and target.is_alive():
		mt.position = base_pos
	_unfreeze(ap_a)
	if ap_t != ap_a:
		_unfreeze(ap_t)


func _freeze(ap: AnimationPlayer) -> void:
	if ap == null:
		return
	if _frozen.has(ap):
		_frozen[ap][1] += 1
	else:
		_frozen[ap] = [ap.speed_scale, 1]
	ap.speed_scale = 0.0


func _unfreeze(ap: AnimationPlayer) -> void:
	if ap == null or not _frozen.has(ap):
		return
	_frozen[ap][1] -= 1
	if _frozen[ap][1] <= 0:
		if is_instance_valid(ap):
			ap.speed_scale = _frozen[ap][0]
		_frozen.erase(ap)


## Plays the authentic "damage" reaction clip with a sharp upper-body flinch tilt.
## Never uses "down" (which is strictly reserved for K.O. when HP reaches 0).
func _hit_react(c: Combatant) -> void:
	if not c.is_alive():
		return
	var m: Node3D = fx._models.get(c)
	var ap := _anim_player(c)
	_stop_moving(c)
	fx._busy_for(c, 0.42)
	var token: int = _react_token.get(c, 0) + 1
	_react_token[c] = token
	# Quick torso/root flinch tilt
	if m != null:
		var tilt_tw := fx.create_tween()
		var tilt_sign := 1.0 if c.is_player else -1.0
		tilt_tw.tween_property(m, "rotation:x", 0.18 * tilt_sign, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tilt_tw.tween_property(m, "rotation:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if ap != null:
		if ap.has_animation("damage"):
			ap.play("damage", 0.04)
		var dur := 0.36
		if ap.has_animation("damage"):
			dur = clampf(ap.get_animation("damage").length, 0.25, 0.55)
		await fx.get_tree().create_timer(dur, false).timeout
	else:
		await fx.get_tree().create_timer(0.3, false).timeout
	if token == _react_token.get(c, 0) and c.is_alive():
		_reset_idle(c)


func _play(c: Combatant, anim: String) -> void:
	var ap := _anim_player(c)
	if ap != null and ap.has_animation(anim):
		ap.play(anim, 0.08)


func _anim_player(c: Combatant) -> AnimationPlayer:
	var m: Node3D = fx._models.get(c)
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
		ap.play("battle_idle", 0.15)
	elif ap.has_animation("idle"):
		ap.play("idle", 0.15)


## Tells the HUD to keep the HP bar where it is until the strike lands.
func _hold_hp(c: Combatant, seconds: float) -> void:
	c.set_meta("hp_hold_until", Time.get_ticks_msec() + int((seconds + 0.14) * 1000.0))


## Physical knockback proportional to the hit's force (`mult`), with foot skid dust.
func knock(target: Combatant, from_pos: Vector3, mult := 1.0) -> void:
	if is_driven(target):
		return  # Its own attack is posing it; no knockback tween fighting that.
	var m: Node3D = fx._models[target]
	var home: Vector3 = fx.rest_pos(target)
	var dir := fx._flat_dir(from_pos, home)
	var dist := clampf(0.78 * mult, 0.55, 1.55)
	var push_pos := home + dir * dist
	fx._smoke(home + Vector3(0, 0.12, 0), Color(0.75, 0.85, 0.9), 5 if mult > 1.2 else 3, Vector2(0.7, 1.3), 0.35, 0.28)
	var tw := fx._move(target)
	tw.tween_property(m, "position", push_pos, 0.07).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "position", home, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Short dust puffs along the floor while a character runs.
func _dust_trail(m: Node3D, duration: float) -> void:
	var t := 0.0
	while t < duration:
		fx._smoke(m.global_position + Vector3(0, 0.15, 0), Color(0.75, 0.82, 0.85), 3, Vector2(0.8, 1.5), 0.6, 0.4)
		await fx.get_tree().create_timer(0.07, false).timeout
		t += 0.07
