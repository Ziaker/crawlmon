class_name FxMotion
extends RefCounted
## Everything that moves the bodies: entrance, run, leap back, hit-stop, knockback, animations.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx
## Overlapping hit-stops share one saved speed per player (never capture 0 as "previous").
var _frozen: Dictionary = {}  # AnimationPlayer -> [saved speed, holders]
var _react_token: Dictionary = {}  ## Combatant -> int
var _interrupted_traj: Dictionary = {}  ## Combatant -> bool (hit while in attack trajectory)


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
	fx.prewarm()
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
			_victory_pose(c)


## Waits for a winner that is still hopping home from its last attack, then strikes the pose.
func _victory_pose(c: Combatant) -> void:
	var waited := 0.0
	while is_driven(c) and waited < 2.0:
		await fx.get_tree().create_timer(0.05, false).timeout
		waited += 0.05
		if fx == null:
			return
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


func is_driven(c: Combatant) -> bool:
	if fx.battle == null:
		return false
	for inc in fx.battle.attacks_in_flight():
		if inc.attacker == c and inc.data.get("kind", "") == "melee":
			return true
	return false


func _is_tackle(inc) -> bool:
	var move_id := BattleFx.normalize_move_id(inc.label)
	return move_id == "tackle" or move_id == "investida"


func _should_emit_travel_dust(inc) -> bool:
	var move_id := BattleFx.normalize_move_id(inc.label)
	return not (move_id == "investida" or move_id == "tackle")


## Return true when a move owns the phase's one-shot travel presentation.
func _on_travel_move(inc, _data: Dictionary, _model: Node3D) -> bool:
	match String(inc.data.get("move_id", "")):
		"investida", "tackle":
			return true  # Deliberately clean run: no dust, aura or afterimage.
		"soco_rapido":
			if not inc.data.has("quick_cone"):
				var cone := VfxLib.mesh_slash(fx, _model.position + Vector3(0, 0.9, 0), inc.data["dir"], Color("63d9ec"), 0.0, 1.35, inc.data["run_t"] + 0.12, "shock_cone", 3.2)
				cone.name = "QuickPunchTravelCone"
				inc.data["quick_cone"] = cone
			return true
		"investida_subterranea", "investida_escavadora":
			return true
		"mordida":
			if not inc.data.get("bite_miasma_spawned", false):
				inc.data["bite_miasma_spawned"] = true
				var target_pos := (fx._models[inc.target] as Node3D).position + Vector3.UP
				var dark_sphere := fx._node(fx._sphere(0.65), Color("2b0938", 0.55), target_pos)
				dark_sphere.name = "BiteGatheringMiasma"
				fx._pop(dark_sphere, float(inc.data.get("run_t", 0.24)) + 0.12, Vector3.ONE * 0.2, Vector3.ONE * 1.6)
			return false
		_:
			return false


## Return true when a move replaces the generic melee strike smear.
func _on_strike_move(inc, data: Dictionary, _model: Node3D) -> bool:
	match String(data.get("move_id", "")):
		"investida", "tackle":
			if not data.get("move_strike_started", false) and _should_start_strike_vfx(data, inc.phase_time):
				data["move_strike_started"] = true
				_tackle_strike_vfx(data["stand"], data["dir"])
			return true
		"soco_rapido", "golpe_carate", "quebra_telha", "mordida", "garra_dragao", "investida_subterranea", "investida_escavadora":
			if _should_start_strike_vfx(data, inc.phase_time):
				data["move_strike_started"] = true
			return true
		_:
			return false


## A2 lasts ~0.20 s, so its first frame is anchored to the animation's contact
## frame (`antic + hit`) rather than to the start of the attack clip.
func _should_start_strike_vfx(data: Dictionary, phase_time: float) -> bool:
	var start_at: float = float(data["antic"]) + maxf(float(data["hit"]) - 0.20, 0.02)
	return phase_time >= start_at


func _enter_strike_move(_inc, _data: Dictionary, _model: Node3D) -> void:
	pass


## Per-frame move hooks read Battle's phase clock; they never advance it.
func _drive_travel_move(inc, data: Dictionary, model: Node3D, phase_time: float) -> void:
	var run_t: float = maxf(float(data.get("run_t", 0.01)), 0.01)
	var k := clampf((phase_time - 0.12) / run_t, 0.0, 1.0)
	match String(data.get("move_id", "")):
		"soco_rapido":
			var cone: Node3D = data.get("quick_cone")
			if is_instance_valid(cone):
				cone.position = model.position + (data["dir"] as Vector3) * 0.9 + Vector3(0, 0.9, 0)
			for i in 3:
				var threshold := 0.22 + float(i) * 0.24
				var key := "quick_ghost_%d" % i
				if k >= threshold and not data.get(key, false):
					data[key] = true
					var ghost_color := Color("d6fa66") if i == 0 else Color("63d9ec")
					VfxLib.spawn_ghost_snapshot(fx, model, ghost_color, 0.20)
		"golpe_carate":
			var jump_k := clampf((k - 0.42) / 0.58, 0.0, 1.0)
			model.position.y += sin(jump_k * PI) * 1.8
			if jump_k >= 0.38 and not data.get("karate_hand_flash", false):
				data["karate_hand_flash"] = true
				VfxLib.flash_star(fx, model.position + (data["dir"] as Vector3) * 0.45 + Vector3(0, 1.25, 0), Color("d6fa66"), 1.4, 0.24)
		"quebra_telha":
			model.position.y += sin(k * PI) * 3.2
		"garra_dragao":
			model.position.y += sin(k * PI) * 2.25
			if k >= 0.28 and not data.get("dragon_claw_plasma", false):
				data["dragon_claw_plasma"] = true
				var hand := model.position + (data["dir"] as Vector3) * 0.55 + Vector3.UP * 1.0
				VfxLib.flash_star(fx, hand, Color("00f59b"), 1.8, 0.28)
				VfxLib.burst(fx, hand, {"amount": 18, "life": 0.30, "speed": Vector2(0.3, 2.4), "radius": 0.45, "size": Vector2(0.16, 0.34), "ramp": VfxLib.ramp([Color.WHITE, Color("00f59b"), Color("63d9ec", 0.0)])})
		"investida_subterranea", "investida_escavadora":
			if k > 0.16:
				var depth_k := clampf((k - 0.16) / 0.16, 0.0, 1.0)
				var rise_k := clampf((k - 0.88) / 0.12, 0.0, 1.0)
				model.position.y -= 1.45 * depth_k * (1.0 - rise_k)
			for i in 8:
				var threshold := 0.16 + float(i) * 0.095
				var key := "dig_mound_%d" % i
				if k >= threshold and not data.get(key, false):
					data[key] = true
					var from: Vector3 = data.get("from", model.position)
					var stand: Vector3 = data.get("stand", model.position)
					var ground_pos := from.lerp(stand, clampf((threshold - 0.16) / 0.67, 0.0, 1.0))
					ground_pos.y = 0.08
					var mound := Node3D.new()
					mound.name = "DigMound%d" % i
					mound.position = ground_pos
					fx.add_child(mound)
					VfxLib.flipbook(fx, ground_pos + Vector3.UP * 0.35, "smoke", Color("5c4033"), 1.5, 0.46, 0.0, 1.4, false)
					fx._shock(ground_pos, Color("f0c57e"), 1.8, 0.32)
					var cleanup := mound.create_tween()
					cleanup.tween_interval(0.55)
					cleanup.tween_callback(mound.queue_free)
		_:
			pass


func _drive_strike_move(_inc, _data: Dictionary, _model: Node3D, _phase_time: float) -> void:
	match String(_data.get("move_id", "")):
		"investida_subterranea", "investida_escavadora":
			var hit_dur: float = maxf(float(_data.get("hit", 0.35)), 0.05)
			var k := clampf(_phase_time / hit_dur, 0.0, 1.0)
			_model.position.y = sin(k * PI) * 1.55


## Golpe A2: two co-planar curved blades plus a short tangential spark burst.
func _tackle_strike_vfx(stand: Vector3, dir: Vector3) -> Array[Node3D]:
	var center := stand + dir * 1.15 + Vector3(0, 0.95, 0)
	var outer := VfxLib.mesh_slash(fx, center, dir, Color("fb5607"), 22.0, 1.30, 0.22, "slash_arc")
	outer.name = "TackleSmearOuter"
	var inner_color := Color("ffbe0b").lightened(0.35)
	var inner := VfxLib.mesh_slash(fx, center, dir, inner_color, 22.0, 1.05, 0.19, "slash_arc", 3.4)
	inner.name = "TackleSmearCore"
	var tangent := Vector3(-dir.z, 0.12, dir.x).normalized()
	VfxLib.burst(fx, center, {
		"tex": VfxLib.spark_tex(), "amount": 10, "life": 0.20,
		"speed": Vector2(4.0, 8.5), "dir": tangent, "spread": 32.0,
		"size": Vector2(0.10, 0.24), "end_scale": 0.0, "align_y": true,
		"ramp": VfxLib.ramp([Color("ffbe0b"), Color("fb5607"), Color("fb5607", 0.0)], [0.0, 0.55, 1.0])})
	var nodes: Array[Node3D] = [outer, inner]
	return nodes


## A phase started: one-shot effects and animation changes.
func on_phase(inc, phase: int) -> void:
	var a: Combatant = inc.attacker
	var d: Dictionary = inc.data
	if d.is_empty():
		return
	var m: Node3D = fx._models[a]
	m.visible = true
	fx._vanish_until.erase(a)
	var P := Battle.Phase
	var melee: bool = d["kind"] == "melee"
	match phase:
		P.TRAVEL:
			if melee:
				var move_owns_travel := _on_travel_move(inc, d, m)
				fx._stop_moving(a)
				fx._displaced[a] = false  # A counter-attack starts from wherever the evade left it.
				m.position.y = 0.0
				d["from"] = Vector3(m.position.x, 0.0, m.position.z)
				d["vis_off"] = (d["from"] as Vector3) - inc.from
				_play(a, "run")
				if not move_owns_travel:
					_dust_trail(m, d["run_t"] + 0.12)
			else:
				if d.get("move_id", "") in ["onda_choque", "teleporte_rapido"]:
					_play(a, "attack_special")
				fx.fx_projectiles.spawn(inc)
		P.STRIKE:
			if melee:
				_enter_strike_move(inc, d, m)
				m.position.y = 0.0
				var move_id := BattleFx.normalize_move_id(inc.label)
				if d["antic"] > 0.0 and move_id != "tackle" and move_id != "investida":
					fx._smoke(d["stand"] + Vector3(0, 0.15, 0), Color(0.82, 0.85, 0.88), 4, Vector2(0.7, 1.3), 0.35, 0.3)
			else:
				if d.get("move_id", "") not in ["onda_choque", "teleporte_rapido"]:
					_play(a, "attack_special")
				fx._ring((fx._home[a] as Vector3) + Vector3(0, 1, 0), fx.COLORS[inc.element], Vector3.ONE * 1.8, Vector3.ONE * 0.3, fx.CAST_AT, Vector3(90, 0, 0))
		P.RETURN:
			if melee:
				m.position.y = 0.0
			if d.get("move_id", "") not in ["teleporte_rapido", "raio_psiquico"]:
				fx.fx_projectiles.finish(inc)
		P.STAGGER:
			# Interrupted by an Evade: it stops right here and stumbles until the engagement ends.
			m.position.y = 0.0
			var grounded := Vector3(m.position.x, 0.0, m.position.z)
			d["lunged"] = grounded
			if not melee:
				fx.fx_projectiles.finish(inc)
			_play(a, "damage")
		P.DONE:
			if d.get("move_id", "") == "quebra_telha":
				fx.fx_impacts.clear_brick_barrier(inc.target)
			if d.get("move_id", "") == "teleporte_rapido":
				m.position = d.get("teleport_origin", fx._home[a])
				m.scale = d.get("teleport_base_scale", fx._base_scale.get(a, Vector3.ONE))
			if d["kind"] == "hit_interrupted":
				var tw_k: Tween = fx._tweens.get(a)
				if tw_k == null or not tw_k.is_valid() or not tw_k.is_running():
					var h_int: Vector3 = fx._home[a]
					m.position = Vector3(h_int.x, 0.0, h_int.z)
					m.rotation.y = fx._home_yaw[a]
					m.scale = d["base_scale"]
					a.clear_rest()
					fx._displaced[a] = false
					_reset_idle(a)
				fx.fx_projectiles.finish(inc)
				return
			if melee and d.get("engaged", false):
				m.position = fx.rest_pos(a)
				m.position.y = 0.0
				m.scale = d["base_scale"]
			elif melee:
				var h: Vector3 = fx._home[a]
				m.position = Vector3(h.x, 0.0, h.z)
				m.rotation.y = fx._home_yaw[a]
				m.scale = d["base_scale"]
				a.clear_rest()
				fx._displaced[a] = false
				fx._shock(fx._home[a], Color(0.8, 0.95, 1.0), 2.2, 0.25)
				fx._smoke((fx._home[a] as Vector3) + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 6, Vector2(0.9, 1.5), 0.45, 0.3)
			else:
				m.position.y = 0.0
				a.clear_rest()
			_reset_idle(a)
			fx.fx_projectiles.finish(inc)


## The engaged state ended: the evader hops home and the stunned attacker recovers
## (BattleFx only fills the plans; Battle runs them).
func on_engage_ended(_actor: Combatant, _opponent: Combatant, ghost, staggered) -> void:
	for inc in [ghost, staggered]:
		if inc == null:
			continue
		var m: Node3D = fx._models[inc.attacker]
		m.position.y = 0.0
		inc.data = _return_data(inc, m.rotation.y if inc.hop_h > 0.0 else fx._home_yaw[inc.attacker])


## Interrupted by taking a hit while in trajectory: stop driving the attack so _hit_stop
## and knock() can push the character backward from the impact spot and return it to origin.
func on_attack_interrupted(inc) -> void:
	var a: Combatant = inc.attacker
	var m: Node3D = fx._models[a]
	var y_at_hit: float = m.position.y
	m.position.y = 0.0
	m.scale = fx._base_scale.get(a, m.scale)
	if inc.data.has("quick_cone") and is_instance_valid(inc.data["quick_cone"]):
		(inc.data["quick_cone"] as Node).queue_free()
	if inc.data.get("move_id", "") == "quebra_telha":
		fx.fx_impacts.clear_brick_barrier(inc.target)
	fx.fx_projectiles.finish(inc)
	if inc.motion == "cast":
		inc.data = {"kind": "hit_interrupted", "base_scale": fx._base_scale.get(a, m.scale)}
	else:
		inc.data = _return_data(inc, m.rotation.y)
		inc.data["y0"] = y_at_hit


## Drawing data of a hop home the rules planned (an evader leaving its opponent, a stunned
## attacker recovering, an attacker knocked back on its way).
func _return_data(inc, yaw: float) -> Dictionary:
	var a: Combatant = inc.attacker
	return {"kind": "melee", "dir": inc.dir, "stand": a.pos, "hold": inc.hold,
		"hop_t": inc.hop_t, "hop_h": inc.hop_h, "yaw_out": yaw,
		"base_scale": fx._base_scale.get(a, (fx._models[a] as Node3D).scale)}


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
		if d["kind"] != "melee":
			continue
		# The rules carry the body (AttackMotion); this only turns that position into a pose.
		var carried_stand: Vector3 = inc.stand
		var dir: Vector3 = inc.dir
		d["stand"] = carried_stand
		d["dir"] = dir
		if inc.phase != Battle.Phase.RETURN and inc.motion != "return":
			d["yaw_out"] = atan2(dir.x, dir.z)
		var base_scale: Vector3 = d["base_scale"]
		var e: float = inc.phase_time
		var body: Vector3 = a.pos
		match inc.phase:
			Battle.Phase.TRAVEL:
				var yaw_home: float = fx._home_yaw[a]
				m.rotation.y = lerp_angle(yaw_home, d["yaw_out"], clampf(e / 0.12, 0.0, 1.0))
				# The body was drawn a little off its rules position (ready stance): ease it in.
				var off: Vector3 = d.get("vis_off", Vector3.ZERO) * (1.0 - clampf(e / (0.12 + inc.run_t), 0.0, 1.0))
				m.position = Vector3(body.x + off.x, 0.0, body.z + off.z)
				_drive_travel_move(inc, d, m, e)
			Battle.Phase.STRIKE:
				m.rotation.y = d["yaw_out"]
				var antic: float = inc.antic
				m.position = Vector3(body.x, 0.0, body.z)
				if e >= antic:
					if not d.get("swung", false):
						d["swung"] = true
						_play(a, "attack")
					_on_strike_move(inc, d, m)
					# Blade/claw trail slightly before the contact frame.
					if not d.get("move_strike_started", false) and not d.get("slashed", false) and e - antic >= maxf(inc.hit - 0.06, 0.02):
						d["slashed"] = true
						VfxLib.mesh_slash(fx, carried_stand + dir * 1.35 + Vector3(0, 1.0, 0), dir, Color(1.0, 0.96, 0.86), 24.0, 1.15, 0.25, "slash_arc")
				# Squash on the coil, then spring back.
				var sq := antic * 0.7
				if antic > 0.0 and e < sq + 0.09:
					if e < sq:
						m.scale = base_scale.lerp(base_scale * Vector3(1.12, 0.86, 1.12), _ease_quad_out(e / sq))
					else:
						m.scale = (base_scale * Vector3(1.12, 0.86, 1.12)).lerp(base_scale, _ease_back_out((e - sq) / 0.09))
				else:
					m.scale = base_scale
				_drive_strike_move(inc, d, m, e)
			Battle.Phase.RETURN:
				m.rotation.y = d["yaw_out"]
				var hold: float = inc.hold
				m.position = Vector3(body.x, float(d.get("y0", 0.0)) * (1.0 - clampf(e / 0.11, 0.0, 1.0)) if e < hold else 0.0, body.z)
				if e >= hold:
					if not d.get("hopped", false):
						d["hopped"] = true
						m.scale = base_scale
						_play(a, "battle_idle")
						fx._smoke(body + Vector3(0, 0.2, 0), Color(0.75, 0.85, 0.9), 5, Vector2(0.8, 1.4), 0.4, 0.3)
					var k := clampf((e - hold) / maxf(inc.hop_t, 0.001), 0.0, 1.0)
					m.position.y = sin(k * PI) * inc.hop_h


## Micro-freeze (Hit Stop) on the exact frame of contact.
## Vibrates strictly the target model and the impact effect (never the camera).
func _hit_stop(attacker: Combatant, target: Combatant, heavy: bool, strike_dir := Vector3.FORWARD, impact_fx: Array[Node3D] = [], duration_override := -1.0) -> void:
	var stop_dur: float = duration_override if duration_override > 0.0 else (0.115 if heavy else 0.07)
	if fx.battle != null:
		fx.battle.freeze(stop_dur)  # The rules' clock stops with the animations: no drift.
	# The whole battle clock holds still, so every animation holds with it.
	var frozen_aps: Array[AnimationPlayer] = []
	for c in fx._models:
		var ap_c := _anim_player(c)
		if ap_c != null and not frozen_aps.has(ap_c):
			frozen_aps.append(ap_c)
			_freeze(ap_c)
	var mt: Node3D = fx._models.get(target)
	var base_pos := Vector3(mt.position.x, 0.0, mt.position.z) if mt != null else Vector3.ZERO
	var perp := Vector3(strike_dir.z, 0.0, -strike_dir.x)
	var amp := 0.22 if heavy else 0.12
	var step := 0.016
	var elapsed := 0.0
	var sign_k := 1.0
	while elapsed < stop_dur:
		var decay := 1.0 - clampf(elapsed / stop_dur, 0.0, 1.0)
		if mt != null and is_instance_valid(mt) and not is_driven(target):
			var vib := (perp * sign_k * amp + strike_dir * (amp * 0.45)) * decay
			vib.y = 0.0
			mt.position = base_pos + vib
		for node in impact_fx:
			if is_instance_valid(node):
				node.position += perp * (sign_k * 0.06 * decay)
		sign_k = -sign_k
		await fx.get_tree().create_timer(step, false).timeout
		elapsed += step
	if mt != null and is_instance_valid(mt) and not is_driven(target):
		mt.position = base_pos
	for ap_c in frozen_aps:
		_unfreeze(ap_c)


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
## If the target was standing at its spot, pushes it backward and returns it there.
## If the target was hit in trajectory, pushes it backward from the impact point and returns it to its origin.
func knock(target: Combatant, from_pos: Vector3, mult := 1.0) -> void:
	if is_driven(target):
		return  # Its own attack is posing it; no knockback tween fighting that.
	var m: Node3D = fx._models[target]
	var start_pos := Vector3(m.position.x, 0.0, m.position.z)
	m.position = start_pos
	var rest_spot: Vector3 = fx.rest_pos(target)
	var home_spot := Vector3((fx._home[target] as Vector3).x, 0.0, (fx._home[target] as Vector3).z)
	var in_traj: bool = _interrupted_traj.get(target, false) or (target.engaged_with == null and start_pos.distance_to(rest_spot) > 1.35)
	_interrupted_traj.erase(target)
	var origin_pos := home_spot if in_traj else rest_spot
	origin_pos.y = 0.0
	if in_traj:
		target.clear_rest()
		fx._displaced[target] = false
	var yaw_home: float = fx._home_yaw[target]
	var own_back := -Vector3(sin(yaw_home), 0.0, cos(yaw_home))
	var hit_push := fx._flat_dir(from_pos, start_pos)
	var back_dir := hit_push if (start_pos.distance_to(from_pos) > 0.25 and hit_push.dot(own_back) > 0.15) else own_back
	back_dir.y = 0.0
	if back_dir.length() < 0.01:
		back_dir = own_back
	else:
		back_dir = back_dir.normalized()
	var dist := clampf(1.5 * mult, 1.1, 2.4)
	var push_pos := start_pos + back_dir * dist
	push_pos.y = 0.0
	fx._smoke(start_pos + Vector3(0, 0.12, 0), Color(0.75, 0.85, 0.9), 6 if mult > 1.2 else 4, Vector2(0.75, 1.35), 0.38, 0.28)
	var tw := fx._move(target)
	tw.tween_property(m, "position", push_pos, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.04)
	if in_traj and target.is_alive():
		var ret_dist := push_pos.distance_to(origin_pos)
		var ret_dur := clampf(ret_dist / 52.0, 0.26, 0.44)
		var hop_h := clampf(ret_dist * 0.10, 0.9, 2.2)
		fx._busy_for(target, 0.15 + ret_dur + 0.15)
		tw.tween_callback(func() -> void:
			if target.is_alive():
				_play(target, "battle_idle")
				fx._smoke(push_pos + Vector3(0, 0.15, 0), Color(0.75, 0.85, 0.9), 4, Vector2(0.7, 1.2), 0.35, 0.25))
		tw.tween_method(func(k: float) -> void:
			var p := push_pos.lerp(origin_pos, k)
			p.y = sin(k * PI) * hop_h
			m.position = p
			m.rotation.y = lerp_angle(m.rotation.y, yaw_home, k), 0.0, 1.0, ret_dur)
		tw.tween_callback(func() -> void:
			m.position = origin_pos
			m.rotation.y = yaw_home
			m.scale = fx._base_scale.get(target, m.scale)
			if target.is_alive():
				_reset_idle(target))
	else:
		fx._busy_for(target, 0.42)
		tw.tween_property(m, "position", origin_pos, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Short dust puffs along the floor while a character runs.
func _dust_trail(m: Node3D, duration: float) -> void:
	var t := 0.0
	while t < duration:
		fx._smoke(m.global_position + Vector3(0, 0.15, 0), Color(0.75, 0.82, 0.85), 3, Vector2(0.8, 1.5), 0.6, 0.4)
		await fx.get_tree().create_timer(0.07, false).timeout
		t += 0.07
