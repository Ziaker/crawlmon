class_name BattleTrace
extends Node
## Flight recorder for the battle. When active it writes EVERYTHING that happens, every
## frame, to user://battle_trace.jsonl (one JSON object per line) and flags anything it
## cannot explain in user://battle_anomalies.txt. Nothing is ever "too small to notice":
## whoever debugs reads the files instead of guessing.
##
## Turn it on with the launch argument `-- --trace` (or the env var CRAWL_TRACE=1).
## Per frame, per combatant: position, speed, visibility, scale, yaw, animation, who is
## moving it (an attack timeline, a tween, or NOBODY), logic state (HP, ATB, Burst,
## engaged, steps, attack phase/progress) and the time scale. Every Battle signal is an
## event line. Detectors (see _detect) turn the stream into ANOMALY lines.

const MAX_SPEED := 110.0  ## Units/s any body may legitimately travel (the quick hop is ~70).
const MAX_STEP := 6.0  ## Units in one frame that no body may travel, whatever the speed.
const SNAP_TOLERANCE := 0.05

var battle: Battle
var fx: BattleFx
var models: Dictionary
var party: Array[Combatant]
var enemies: Array[Combatant]

var _file: FileAccess
var _anoms: FileAccess
var _t := 0.0
var _frame := 0
var _prev: Dictionary = {}  ## Combatant -> {pos, vis, scale, who}
var _vis_changes: Dictionary = {}
var anomaly_count := 0


static func wanted() -> bool:
	return OS.get_cmdline_user_args().has("--trace") or OS.get_environment("CRAWL_TRACE") == "1"


func setup(p_battle: Battle, p_fx: BattleFx, p_models: Dictionary, p_party: Array[Combatant], p_enemies: Array[Combatant]) -> void:
	battle = p_battle
	fx = p_fx
	models = p_models
	party = p_party
	enemies = p_enemies
	process_mode = Node.PROCESS_MODE_ALWAYS
	_file = FileAccess.open("user://battle_trace.jsonl", FileAccess.WRITE)
	_anoms = FileAccess.open("user://battle_anomalies.txt", FileAccess.WRITE)
	_connect_events()
	print("[trace] recording to ", ProjectSettings.globalize_path("user://"))


func _exit_tree() -> void:
	if _file != null:
		_file.close()
	if _anoms != null:
		_anoms.close()


func _connect_events() -> void:
	var b := battle
	b.log_message.connect(func(text: String) -> void: _event("log", {"text": text}))
	b.attack_telegraphed.connect(func(inc) -> void: _event("telegraphed", _inc(inc)))
	b.attack_resolved.connect(func(inc) -> void: _event("resolved", _inc(inc)))
	b.attack_cancelled.connect(func(inc) -> void: _event("cancelled", _inc(inc)))
	b.attack_phase.connect(func(inc, ph: int) -> void: _event("phase", _inc(inc, {"to": Battle.Phase.keys()[ph]})))
	b.attack_interrupted.connect(func(inc) -> void: _event("interrupted", _inc(inc)))
	b.manual_evaded.connect(func(actor: Combatant, inc) -> void: _event("manual_evade", _inc(inc, {"actor": actor.name})))
	b.evade_whiffed.connect(func(actor: Combatant, inc) -> void: _event("evade_whiff", _inc(inc, {"actor": actor.name})))
	b.engaged.connect(func(actor: Combatant, opp: Combatant, _inc2) -> void: _event("engaged", {"actor": actor.name, "opponent": opp.name}))
	b.engage_ended.connect(func(actor: Combatant, opp: Combatant, _g, _s) -> void: _event("engage_ended", {"actor": actor.name, "opponent": opp.name}))
	b.stepped.connect(func(actor: Combatant, to_pos: int) -> void: _event("step", {"actor": actor.name, "to": to_pos}))
	b.hit_resolved.connect(func(att: Combatant, tgt: Combatant, _el, info: Dictionary) -> void:
		_event("hit", {"attacker": att.name, "target": tgt.name, "info": info})
		_check_sync(att, tgt, info))
	b.healed.connect(func(a: Combatant, t: Combatant, amount: int) -> void: _event("heal", {"actor": a.name, "target": t.name, "amount": amount}))
	b.reward_spawned.connect(func(r) -> void: _event("reward_spawned", {"kind": r.kind, "owner": r.owner.name, "source": r.source.name, "slot": r.slot, "extra": r.extra}))
	b.reward_landed.connect(func(r) -> void: _event("reward_landed", {"kind": r.kind, "owner": r.owner.name, "slot": r.slot}))
	b.battle_ended.connect(func(won: bool) -> void: _event("battle_ended", {"player_won": won}))


func _inc(inc, extra := {}) -> Dictionary:
	var d := {
		"attacker": inc.attacker.name, "target": inc.target.name, "label": inc.label, "kind": inc.kind,
		"phase": Battle.Phase.keys()[inc.phase], "progress": snappedf(inc.progress(), 0.001),
		"instant": inc.instant, "dodged": inc.dodged, "auto_dodged": inc.auto_dodged, "whiffed": inc.whiffed,
		"interrupted": inc.interrupted, "ghost": inc.ghost, "impacted": inc.impacted,
	}
	d.merge(extra)
	return d


func _event(kind: String, data: Dictionary) -> void:
	_write({"t": snappedf(_t, 0.001), "f": _frame, "ev": kind, "data": data})


func _write(d: Dictionary) -> void:
	if _file != null:
		_file.store_line(JSON.stringify(d))


func _anomaly(kind: String, c: Combatant, detail: String) -> void:
	anomaly_count += 1
	var line := "t=%.3f f=%d %s %s: %s" % [_t, _frame, kind, c.name if c != null else "-", detail]
	_write({"t": snappedf(_t, 0.001), "f": _frame, "ev": "ANOMALY", "data": {"kind": kind, "who": c.name if c != null else "", "detail": detail}})
	if _anoms != null:
		_anoms.store_line(line)
	print("[ANOMALY] ", line)


## What is moving this body right now: an attack timeline, a tween, or nobody.
func _mover(c: Combatant) -> String:
	var who: Array[String] = []
	if fx.fx_motion.is_driven(c):
		who.append("attack")
	var tw: Tween = fx._tweens.get(c)
	if tw != null and tw.is_valid():  # (a tween made this frame is valid before it first runs)
		who.append("tween")
	if fx._displaced.get(c, false):
		who.append("displaced")
	if c.engaged_with != null:
		who.append("engaged")
	return "+".join(who) if not who.is_empty() else "NOBODY"


func _process(delta: float) -> void:
	if battle == null or fx == null:
		return
	_frame += 1
	if _frame % 30 == 0 and _file != null:
		_file.flush()  # --quit-after never reaches _exit_tree: keep the tail on disk.
		_anoms.flush()
	var real_dt := delta
	_t += real_dt
	var rows := []
	for c in party + enemies:
		var m: Node3D = models.get(c)
		if m == null:
			continue
		var atk := {}
		for inc in battle.attacks_in_flight():
			if inc.attacker == c:
				atk = {"phase": Battle.Phase.keys()[inc.phase], "p": snappedf(inc.progress(), 0.001), "kind": inc.kind, "ghost": inc.ghost}
		var ap: AnimationPlayer = fx.fx_motion._anim_player(c)
		var row := {
			"n": c.name, "pos": _v(m.position), "yaw": snappedf(m.rotation.y, 0.01), "scale": _v(m.scale), "vis": m.visible,
			"anim": ap.current_animation if ap != null else "", "mover": _mover(c), "atk": atk,
			"hp": c.hp, "atb": snappedf(c.atb, 0.01), "extra": c.extra, "burst": c.burst, "step": c.pos_step,
			"eng": c.engaged_with.name if c.engaged_with != null else "", "counter": c.counter_ready,
			"pend": [c.pending_atb, c.pending_extra, c.pending_burst],
		}
		rows.append(row)
		_detect(c, m, row, real_dt)
	_write({"t": snappedf(_t, 0.001), "f": _frame, "dt": snappedf(real_dt, 0.0001), "ts": Engine.time_scale, "paused": get_tree().paused, "c": rows})


## Logic vs drawing at the instant the damage is applied: where the bodies and the projectile
## really are, and how far the attacker's animation is from the moment it was meant to land.
func _check_sync(att: Combatant, tgt: Combatant, info: Dictionary) -> void:
	if info.get("status", false):
		return
	var ma: Node3D = models.get(att)
	var mt: Node3D = models.get(tgt)
	if ma == null or mt == null:
		return
	var flat := func(v: Vector3) -> Vector3: return Vector3(v.x, 0.0, v.z)
	var inc = null
	for i in battle.attacks_in_flight():
		if i.attacker == att and i.target == tgt and not i.ghost:
			inc = i
	var ap: AnimationPlayer = fx.fx_motion._anim_player(att)
	var d := {
		"attacker": att.name, "target": tgt.name, "ts": Engine.time_scale, "evaded": info.get("evaded", false),
		"body_dist": snappedf((flat.call(ma.position) as Vector3).distance_to(flat.call(mt.position)), 0.01),
		"anim": ap.current_animation if ap != null else "", "anim_pos": snappedf(ap.current_animation_position, 0.001) if ap != null else -1.0,
		"anim_speed": ap.speed_scale if ap != null else -1.0,
	}
	if inc != null:
		var data: Dictionary = inc.data
		d["kind"] = inc.kind
		d["move"] = data.get("move_id", "")
		d["plan"] = inc.plan
		d["expected_hit"] = snappedf(float(data.get("hit", -1.0)), 0.001)
		var proj: Dictionary = data.get("proj", {})
		if not proj.is_empty() and is_instance_valid(proj["node"]):
			d["proj_dist"] = snappedf((flat.call((proj["node"] as Node3D).position) as Vector3).distance_to(flat.call(mt.position)), 0.01)
			if not info.get("evaded", false) and d["proj_dist"] > 2.0:
				_anomaly("PROJ_HIT_FAR", att, "damage applied with the projectile %.2f units from %s" % [d["proj_dist"], tgt.name])
		elif inc.kind == Skill.Kind.MELEE and not info.get("evaded", false) and not data.get("engaged", false) and d["body_dist"] > (fx.STAND_GAP + 1.5):
			_anomaly("MELEE_HIT_FAR", att, "damage applied with the attacker %.2f units from %s" % [d["body_dist"], tgt.name])
		if inc.kind == Skill.Kind.MELEE and d["expected_hit"] > 0.0 and ap != null and ap.current_animation == "attack":
			var drift: float = absf(d["anim_pos"] - d["expected_hit"])
			d["anim_drift"] = snappedf(drift, 0.001)
			if drift > 0.08:
				_anomaly("ANIM_DRIFT", att, "attack clip at %.3fs when damage landed (expected %.3fs, off by %.3fs)" % [d["anim_pos"], d["expected_hit"], drift])
	_event("sync", d)


func _v(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]


## Detectors: anything a human could call "weird" must trip one of these.
func _detect(c: Combatant, m: Node3D, row: Dictionary, dt: float) -> void:
	var prev: Dictionary = _prev.get(c, {})
	if not prev.is_empty() and dt > 0.0:
		var step: float = m.position.distance_to(prev["pos"])
		var speed := step / dt
		var mover: String = row["mover"]
		# A body that moves with nobody driving it, or faster than any motion allows.
		if step > MAX_STEP and prev["vis"] and m.visible:
			_anomaly("TELEPORT", c, "moved %.2f units in one frame (%.0f u/s), mover=%s, atk=%s, from %s to %s" % [step, speed, mover, row["atk"], prev["pos"], m.position])
		elif speed > MAX_SPEED and prev["vis"] and m.visible and step > 0.6:
			_anomaly("TOO_FAST", c, "%.0f u/s over %.2f units, mover=%s, atk=%s" % [speed, step, mover, row["atk"]])
		elif step > 0.05 and mover == "NOBODY" and not fx._is_idle(c):  # (the idle ready-stance sway is the one allowed free mover)
			_anomaly("UNEXPLAINED_MOVE", c, "moved %.2f units with no attack, tween, dodge or engagement driving it" % step)
		# A body that appears/disappears somewhere other than where it was.
		if prev["vis"] != m.visible:
			_vis_changes[c] = _frame
			if m.visible and step > MAX_STEP:
				_anomaly("REAPPEAR_FAR", c, "became visible %.2f units from where it vanished" % step)
		if m.scale.distance_to(prev["scale"]) > 0.6:
			_anomaly("SCALE_POP", c, "scale jumped from %s to %s" % [prev["scale"], m.scale])
		var yaw_d := absf(angle_difference(prev["yaw"], m.rotation.y))
		if yaw_d > 2.2 and mover != "NOBODY":
			_anomaly("YAW_SNAP", c, "turned %.0f degrees in one frame" % rad_to_deg(yaw_d))
	# Logic invariants.
	if c.atb < -0.001 or c.atb > Combatant.BLOCKS + 0.001 or c.extra < -0.001:
		_anomaly("ATB_RANGE", c, "atb=%.2f extra=%.2f" % [c.atb, c.extra])
	if c.burst < 0 or c.burst > Combatant.BURST_MAX:
		_anomaly("BURST_RANGE", c, "burst=%d" % c.burst)
	if c.pending_atb < 0 or c.pending_extra < 0 or c.pending_burst < 0:
		_anomaly("PENDING_NEGATIVE", c, "pending=%s" % [[c.pending_atb, c.pending_extra, c.pending_burst]])
	if c.engaged_with != null and not c.engaged_with.is_alive():
		_anomaly("ENGAGED_WITH_DEAD", c, "still engaged with a dead opponent")
	if c.hp < 0 or c.hp > c.max_hp:
		_anomaly("HP_RANGE", c, "hp=%d/%d" % [c.hp, c.max_hp])
	if not c.is_alive() and m.visible and row["atk"] != {}:
		_anomaly("DEAD_ATTACKING", c, "dead but still has an attack in flight: %s" % [row["atk"]])
	_prev[c] = {"pos": m.position, "vis": m.visible, "scale": m.scale, "yaw": m.rotation.y}
