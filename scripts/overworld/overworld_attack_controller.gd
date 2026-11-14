extends Node
class_name OverworldAttackController
## D-1100/D-1101: contextual overworld attack between the player and nearby enemies.
##
## The controller owns the short advances, the end-of-advance hit test and the
## encounter variant. It does not change battle rules: it only emits
## `battle_requested(advantage)` and the lab starts the battle through
## `GameState.start_battle_3d(...)`.
##
## D-235: nothing here depends on a character, a team or a side. Every distance,
## radius and direction is measured from the real attacker and target nodes.
## The enemy side uses the same rules as the player side, with the same code.
##
## Input is the lab's existing contextual action (`lab_interact`, E/Z). The lab
## calls `try_interact()`: an enemy in range always wins over an NPC/door.
##
## Prototype values (D-1100): the dash distance/time, the player cooldown and the
## exact speedline/trail/dust look are not canonical rules yet; they are tunable
## constants pending calibration with the creator.

signal battle_requested(advantage: int)
## True while an enemy is inside ATTACK_RANGE and the attack owns the input prompt.
signal attack_target_changed(available: bool)
## An enemy entered the 0.4 s telegraph (D-1100). Optional VFX/UI hook.
signal enemy_telegraph_started(enemy: Node3D)
## The player started the short advance. The lab can sync its own facing/yaw.
signal player_dash_started(target: Node3D, direction: Vector3)
## The enemy started the short advance (D-1100/D-1112); the lab plays its attack clip.
signal enemy_dash_started(enemy: Node3D, direction: Vector3)
## D-1115: contact impact; the lab plays the Tackle impact before the transition.
## `contacts` carries the REAL victims of this resolution (D-235): one entry per
## connected side, each `{actor, source, direction}`. The lab must react to those
## actors instead of guessing by proximity. A tie (NORMAL) has both entries.
signal impact_requested(pos: Vector3, direction: Vector3, advantage: int, contacts: Array)

const ATTACK_RANGE := 4.5  ## D-1100: nearest enemy in any direction.
const PROMPT_TEXT := "[Z] ATTACK"  ## D-1100: contextual prompt.

const ENEMY_TELEGRAPH := 0.4  ## D-1100: warning before the enemy advance.
const ENEMY_COOLDOWN := 4.0  ## D-1100: interval between enemy advances.
const PRE_DASH_TIME := 0.12  ## D-1120: enemy wait before moving.
const PLAYER_WINDUP_TIME := 0.14  ## Comic overhaul: player Z wind-up.
const ENEMY_WINDUP_TIME := 0.15  ## D-1142: enemy pre-advance (telegraph stays 0.4).
const DASH_TIME := 0.18  ## Enemy dash cap (D-1120).
const PLAYER_DASH_TIME := 0.10  ## Minimum player dash time; long lunges scale up.
const IMPACT_HOLD := 0.5  ## Knockback 0.5 s, then transition.
const PLAYER_ENDLAG_TIME := 0.0  ## D-1189: no lock after the advance (was 0.38 s).
const PLAYER_HIT_ACTIVE_TIME := 0.30  ## Hitbox stays live after the dash.

## Prototype only (D-1100 explicitly leaves these to calibration).
const PLAYER_COOLDOWN := 0.8
## D-1127: 30% shorter than the previous 3.5 m lunge; still a short lunge.
## D-1135: teto de 2,0 m para os dois lados (antes 2,45/2,38 da D-1127).
const PLAYER_DASH_MAX := 4.4
## D-1127: 30% shorter than the previous 3.4 m enemy lunge.
const ENEMY_DASH_MAX := 2.0

## Extra reach beyond the two measured bodies for the end-of-advance hit test.
const HIT_REACH := 0.55
const DEFAULT_BODY_RADIUS := 0.35
## D-1120: the 0.18 s is the maximum; a very close target must still feel like a
## dash, not a slow crawl. Below this speed the movement finishes at contact.
const MIN_DASH_SPEED := 8.0
const MIN_DASH_TIME := 0.06
## D-1189: friction + subtle slide, same code for the player and every enemy.
const SLIDE_DISTANCE := 0.3  ## metres covered in the braking tail of the advance
const SLIDE_TIME := 0.25  ## seconds that tail adds to the advance
const FRICTION_MIN_TRAVEL := 0.05  ## shorter advances keep the old constant speed
const FRICTION_PEAK_SPEED := 24.0  ## m/s: longer advances get a softer (longer) tail instead of exceeding it

enum Phase { NONE, TELEGRAPH, DASH, PRE_DASH, ENDLAG }

var _player: CharacterBody3D
var _camera: Camera3D
var _vfx_root: Node
var _vfx_by_actor: Dictionary = {}
var _enemies: Array[Dictionary] = []

var _npc_near: Node3D
var _interaction_blocked := false
var _battle_requested := false
var _target_available := false

var _player_phase := Phase.NONE
var _player_target: Node3D
var _player_dir := Vector3.ZERO
var _player_dash_left := 0.0
var _player_dash_speed := 0.0
var _player_dash_duration := 0.0
var _player_fric: Dictionary = {}  ## D-1189: friction profile of the current advance
var _player_endlag_left := 0.0
var _player_attack_elapsed := 0.0
var _player_attack_anim_length := 0.0
var _player_free_attack := false
var _player_pre_dash_left := 0.0
var _player_cooldown := 0.0

var _player_hit_frame := -1
var _enemy_hit_frame := -1
var _contact_grace := 0.0  ## D-1100: a missed advance must not become a normal contact.
var _impact_hold := 0.0  ## D-1115: 0.5 s of Tackle impact before the transition.
var _pending_advantage: int = EncounterRules.Advantage.NORMAL
var _player_hit_target: Node3D
var _player_active_target: Node3D
var _player_active_left := 0.0
var _enemy_hit_target: Node3D
var _player_attack_origin := Vector3.ZERO
var _player_attack_origin_yaw := 0.0
var _player_attack_origin_valid := false
## D-1045: the visual push must not move the logical return spot. When an enemy
## hit lands, the player's pre-reaction position becomes the enemy-first origin.
var _player_hit_origin := Vector3.ZERO
var _player_hit_origin_yaw := 0.0
var _player_hit_origin_valid := false


## The lab calls this once after the player and camera exist. `vfx` is optional:
## either an OverworldDashVfx component or a holder that contains one.
func setup(player: CharacterBody3D, camera: Camera3D, vfx: Node = null) -> void:
	_player = player
	_camera = camera
	_vfx_root = vfx
	_vfx_by_actor.clear()
	_player_phase = Phase.NONE
	_player_target = null
	_player_dash_left = 0.0
	_player_dash_speed = 0.0
	_player_dash_duration = 0.0
	_player_cooldown = 0.0
	_player_hit_frame = -1
	_enemy_hit_frame = -1
	_player_attack_origin_valid = false
	_player_hit_origin_valid = false
	_battle_requested = false
	_target_available = false
	set_physics_process(true)


## Replaces the optional VFX component (Agent B). Safe to leave null.
func set_vfx(vfx: Node) -> void:
	_vfx_root = vfx
	_vfx_by_actor.clear()


## Binds a specific VFX component to one actor (D-235: the key is the real actor,
## never a team/side). The lab uses this to give the player and each enemy their
## own component, which is required when both advances run at the same time.
## `run_dust` is optional and is passed to OverworldDashVfx.set_run_dust().
func bind_dash_vfx(actor: Node3D, vfx: Node, run_dust: CPUParticles3D = null) -> void:
	if actor == null or vfx == null:
		return
	_vfx_by_actor[actor] = vfx
	if run_dust != null:
		_vfx_call_on(vfx, "set_run_dust", [run_dust])


## Registers an enemy node. Duplicate registrations are ignored.
func register_enemy(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	for entry in _enemies:
		if entry.get("node") == enemy:
			return
	_enemies.append({
		"node": enemy,
		"phase": Phase.NONE,
		"state": "",
		"cooldown": 0.0,
		"telegraph": 0.0,
		"pre_dash": 0.0,
		"dir": Vector3.ZERO,
		"dash_left": 0.0,
		"dash_start": Vector3.ZERO,
		"dash_end": Vector3.ZERO,
		"endlag_left": 0.0,
		"attack_elapsed": 0.0,
		"attack_anim_length": 0.0,
		"chase_announced": false,
	})


func unregister_enemy(enemy: Node3D) -> void:
	var entry := _find_enemy(enemy)
	if not entry.is_empty() and int(entry["phase"]) != Phase.NONE:
		_vfx_finish(enemy)
	for i in range(_enemies.size() - 1, -1, -1):
		if _enemies[i].get("node") == enemy:
			_enemies.remove_at(i)
	if _player_target == enemy:
		_cancel_player_dash()


## Informational only: the controller always gives the enemy priority over an NPC.
func set_npc_near(npc: Node3D = null) -> void:
	_npc_near = npc


## While blocked (dialogue/UI), the interaction belongs to the lab and no new
## attack starts. The lab passes its `_npc_talking` state here.
func set_interact_blocked(blocked: bool) -> void:
	if blocked == _interaction_blocked:
		return
	_interaction_blocked = blocked
	if blocked:
		_cancel_player_dash()
		for entry in _enemies:
			if int(entry["phase"]) != Phase.NONE:
				_vfx_finish(entry.get("node"))
				entry["phase"] = Phase.NONE
				entry["telegraph"] = 0.0
				entry["pre_dash"] = 0.0
				entry["dash_left"] = 0.0
				entry["cooldown"] = maxf(float(entry["cooldown"]), ENEMY_COOLDOWN)
	_emit_target_changed()


## D-1136: Z attacks even without a target. The free attack advances forward
## PLAYER_DASH_MAX and never starts a battle.
func attack_anytime() -> bool:
	if _battle_requested or _impact_hold > 0.0:
		return true
	if _player == null or not is_instance_valid(_player) or _interaction_blocked:
		return false
	if _player_phase != Phase.NONE or _player_cooldown > 0.0:
		return true
	var target := _nearest_reachable_enemy()
	if target != null:
		_start_player_windup(target)
	else:
		_start_player_free_attack()
	return true


## Contextual E/Z entry point. Returns true when the attack consumed the input:
## always true if an enemy is inside ATTACK_RANGE, even during dash/cooldown.
## Returns false when there is no enemy, so the lab handles NPC/door/dialogue.
func try_interact() -> bool:
	if _battle_requested:
		return true
	if _impact_hold > 0.0:
		return true
	if _player == null or not is_instance_valid(_player):
		return false
	if _interaction_blocked:
		return false
	var target := _nearest_reachable_enemy()
	if target == null:
		return false
	if _player_phase != Phase.NONE or _player_cooldown > 0.0:
		return true
	_start_player_windup(target)
	return true


## Nearest registered enemy inside `max_range`, in any direction.
func nearest_enemy(max_range: float = ATTACK_RANGE) -> Node3D:
	if _player == null or not is_instance_valid(_player):
		return null
	var best: Node3D = null
	var best_dist := INF
	for entry in _enemies:
		var enemy: Node3D = entry.get("node")
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		var dist := _flat_distance(_player.global_position, enemy.global_position)
		if dist <= max_range and dist < best_dist:
			best = enemy
			best_dist = dist
	return best


## True when the attack owns the contextual input/prompt.
func has_attack_target() -> bool:
	if _battle_requested or _interaction_blocked:
		return false
	return _nearest_reachable_enemy() != null


func get_attack_target() -> Node3D:
	return _nearest_reachable_enemy()


## Comic overhaul: only acquire a target the 2.0 m advance can actually reach.
## A far target makes Z a free attack instead of a whiff that gifts the enemy.
func _nearest_reachable_enemy() -> Node3D:
	var target := nearest_enemy(ATTACK_RANGE)
	if target == null:
		return null
	return target if can_player_reach(target) else null


func get_prompt_text() -> String:
	return PROMPT_TEXT if has_attack_target() else ""


func is_player_dashing() -> bool:
	return _player_phase == Phase.DASH


func is_player_attacking() -> bool:
	return _player_phase != Phase.NONE or _impact_hold > 0.0


func get_player_cooldown() -> float:
	return _player_cooldown


## 0..1 for the HUD (1 = just attacked). Read-only; does not change timing.
func get_player_cooldown_ratio() -> float:
	return clampf(_player_cooldown / PLAYER_COOLDOWN, 0.0, 1.0)


## Read-only: can the 2.0 m advance actually reach this target? Used by the HUD
## and the acquisition so Z does not start a targeted attack that cannot hit.
func can_player_reach(target: Node3D, margin := 0.0) -> bool:
	if target == null or _player == null or not is_instance_valid(target):
		return false
	if not target.is_inside_tree():
		return false
	var reach := PLAYER_DASH_MAX + HIT_REACH + _contact_distance(_player, target) - maxf(0.0, margin)
	return _flat_distance(_player.global_position, target.global_position) <= reach


## D-1138: planned duration of the current player dash (0 when idle).
func get_player_dash_duration() -> float:
	return _player_dash_duration


## Comic overhaul: total authored player attack (wind-up + dash + recovery).
func get_player_attack_total_time() -> float:
	var dash := _player_dash_duration if _player_dash_duration > 0.0 else PLAYER_DASH_TIME + SLIDE_TIME
	return PLAYER_WINDUP_TIME + dash + PLAYER_ENDLAG_TIME


## D-1141: length of the player's attack clip, used for the endlag.
func set_player_attack_length(seconds: float) -> void:
	_player_attack_anim_length = maxf(0.0, seconds)


## D-1142: per-enemy attack clip length, used for the same endlag rule.
func set_enemy_attack_length(enemy: Node3D, seconds: float) -> void:
	var entry := _find_enemy(enemy)
	if not entry.is_empty():
		entry["attack_anim_length"] = maxf(0.0, seconds)


## D-1100: where the battle should return to. If the player's own advance is the
## one that connected (or tied), this is the pre-advance spot/direction, so the
## return does not put the player inside the enemy. Enemy-first uses the current
## spot. The lab passes these to GameState.start_battle_3d().
func get_battle_origin() -> Vector3:
	if _player_attack_origin_valid:
		return _player_attack_origin
	if _player_hit_origin_valid:
		return _player_hit_origin
	if _player != null and is_instance_valid(_player):
		return _player.global_position
	return Vector3.ZERO


func get_battle_origin_yaw() -> float:
	if _player_attack_origin_valid:
		return _player_attack_origin_yaw
	if _player_hit_origin_valid:
		return _player_hit_origin_yaw
	if _player != null and is_instance_valid(_player):
		return _player.rotation.y
	return 0.0


## The lab skips its own enemy movement while the controller owns the advance.
func is_enemy_dashing(enemy: Node3D) -> bool:
	var entry := _find_enemy(enemy)
	return not entry.is_empty() and int(entry["phase"]) == Phase.DASH


## D-1114: the 0.2 s before the enemy move, while the attack clip plays.
func is_enemy_pre_dashing(enemy: Node3D) -> bool:
	var entry := _find_enemy(enemy)
	return not entry.is_empty() and int(entry["phase"]) == Phase.PRE_DASH


func is_enemy_attacking(enemy: Node3D) -> bool:
	var entry := _find_enemy(enemy)
	return (not entry.is_empty() and int(entry["phase"]) != Phase.NONE) or _impact_hold > 0.0


func get_enemy_telegraph_left(enemy: Node3D) -> float:
	var entry := _find_enemy(enemy)
	return float(entry.get("telegraph", 0.0)) if not entry.is_empty() else 0.0


func get_enemy_cooldown(enemy: Node3D) -> float:
	var entry := _find_enemy(enemy)
	return float(entry.get("cooldown", 0.0)) if not entry.is_empty() else 0.0


## The lab calls this every frame with the actual Slime state name
## ("PATROL", "CHASE", "SEARCH", "RETURN", "FLEE"). Only CHASE arms the attack;
## FLEE and every other state cancel a pending telegraph. D-1100.
func notify_enemy_state(enemy: Node3D, state_name: String) -> void:
	var entry := _find_enemy(enemy)
	if entry.is_empty():
		return
	entry["state"] = state_name
	if state_name != "CHASE":
		entry["chase_announced"] = false
		if int(entry["phase"]) == Phase.TELEGRAPH or int(entry["phase"]) == Phase.PRE_DASH:
			entry["phase"] = Phase.NONE
			entry["telegraph"] = 0.0
			entry["pre_dash"] = 0.0
		return
	# D-1100: the advance starts when the enemy ENTERS CHASE, not every frame.
	if bool(entry["chase_announced"]):
		return
	entry["chase_announced"] = true
	if _battle_requested or _interaction_blocked:
		return
	if int(entry["phase"]) != Phase.NONE or float(entry["cooldown"]) > 0.0:
		return
	_begin_enemy_telegraph(enemy, entry)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_emit_target_changed()
	if _battle_requested:
		return
	if _impact_hold > 0.0:
		# Real-time wait: the hit slow-motion must not stretch the 0.5 s window
		# into ~0.9 s of wall-clock time.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_impact_hold = maxf(0.0, _impact_hold - real_delta)
		if _impact_hold <= 0.0:
			_emit_battle(_pending_advantage)
		return
	_contact_grace = maxf(0.0, _contact_grace - delta)
	_tick_player(delta)
	_tick_enemies(delta)
	_resolve_pending_hits()
	_check_contact()


func _tick_player(delta: float) -> void:
	_player_cooldown = maxf(0.0, _player_cooldown - delta)
	if _player_phase == Phase.PRE_DASH or _player_phase == Phase.DASH or _player_phase == Phase.ENDLAG:
		_player_attack_elapsed += delta
	if _player_phase == Phase.PRE_DASH:
		if not _player_free_attack and (_player_target == null or not is_instance_valid(_player_target)):
			_cancel_player_dash()
			return
		_player_pre_dash_left = maxf(0.0, _player_pre_dash_left - delta)
		if _player_pre_dash_left <= 0.0:
			if _player_free_attack:
				_start_free_dash()
			else:
				_start_player_dash()
		return
	if _player_phase == Phase.ENDLAG:
		_player_endlag_left = maxf(0.0, _player_endlag_left - delta)
		if _player_hit_frame < 0 and _player_active_left > 0.0 and _player_active_target != null:
			_player_active_left = maxf(0.0, _player_active_left - delta)
			if is_instance_valid(_player_active_target) and _hit_landed(_player, _player_active_target):
				_player_hit_frame = Engine.get_physics_frames()
				_player_hit_target = _player_active_target
				_player_active_left = 0.0
		# D-1189: no lock after the advance; only the short live-hitbox window of a near miss can hold it.
		if _player_endlag_left <= 0.0 and _player_active_left <= 0.0:
			_finish_player_attack()
		return
	if _player_phase != Phase.DASH:
		return
	var has_target := _player_target != null
	if has_target:
		if not is_instance_valid(_player_target):
			_begin_player_endlag(false)
			return
		if _flat_distance(_player.global_position, _player_target.global_position) <= _contact_distance(_player, _player_target):
			_begin_player_endlag(true)
			return
	_advance(_player, _player_dir, _friction_speed(_player_fric, _player_dash_speed, delta))
	_vfx_tick(_player, delta)
	_player_dash_left -= delta
	if _player_dash_left <= 0.0:
		_begin_player_endlag(has_target)


func _tick_enemies(delta: float) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		var entry := _enemies[i]
		var enemy: Node3D = entry.get("node")
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_inside_tree():
			_enemies.remove_at(i)
			continue
		entry["cooldown"] = maxf(0.0, float(entry["cooldown"]) - delta)
		var phase := int(entry["phase"])
		if phase == Phase.TELEGRAPH:
			if _interaction_blocked:
				entry["phase"] = Phase.NONE
				entry["telegraph"] = 0.0
				continue
			entry["telegraph"] = maxf(0.0, float(entry["telegraph"]) - delta)
			if float(entry["telegraph"]) <= 0.0:
				_begin_enemy_pre_dash(enemy, entry)
		elif phase == Phase.PRE_DASH:
			entry["attack_elapsed"] = float(entry["attack_elapsed"]) + delta
			entry["pre_dash"] = maxf(0.0, float(entry["pre_dash"]) - delta)
			if float(entry["pre_dash"]) <= 0.0:
				_start_enemy_dash(enemy, entry)
		elif phase == Phase.DASH:
			_tick_enemy_dash(enemy, entry, delta)
		elif phase == Phase.ENDLAG:
			entry["attack_elapsed"] = float(entry["attack_elapsed"]) + delta
			entry["endlag_left"] = maxf(0.0, float(entry["endlag_left"]) - delta)
			if float(entry["endlag_left"]) <= 0.0:
				_finish_enemy_attack(enemy, entry)


func _tick_enemy_dash(enemy: Node3D, entry: Dictionary, delta: float) -> void:
	entry["attack_elapsed"] = float(entry["attack_elapsed"]) + delta
	if _player == null or not is_instance_valid(_player) or _battle_requested:
		_begin_enemy_endlag(enemy, entry, false)
		return
	if _flat_distance(enemy.global_position, _player.global_position) <= _contact_distance(enemy, _player):
		_begin_enemy_endlag(enemy, entry, true)
		return
	var fric: Dictionary = entry.get("fric", {})
	_advance(enemy, entry["dir"], _friction_speed(fric, float(entry["dash_speed"]), delta))
	_vfx_tick(enemy, delta)
	entry["dash_left"] = float(entry["dash_left"]) - delta
	if float(entry["dash_left"]) <= 0.0:
		_begin_enemy_endlag(enemy, entry, true)


func _start_player_windup(target: Node3D) -> void:
	var from := _player.global_position
	var dir := _flat_direction(from, target.global_position)
	if dir.length_squared() < 0.001:
		dir = Vector3(sin(_player.rotation.y), 0.0, cos(_player.rotation.y))
		if dir.length_squared() < 0.001:
			dir = Vector3.FORWARD
	dir = dir.normalized()
	_player_target = target
	_player_active_target = null
	_player_active_left = 0.0
	_player_dir = dir
	_player_free_attack = false
	_player_phase = Phase.PRE_DASH
	_player_pre_dash_left = PLAYER_WINDUP_TIME
	_player_attack_elapsed = 0.0
	_player_attack_origin = from
	_player_attack_origin_yaw = _player.rotation.y
	_player_attack_origin_valid = true
	_player.rotation.y = atan2(dir.x, dir.z)
	player_dash_started.emit(target, dir)


func _start_player_dash() -> void:
	if _player_target == null or not is_instance_valid(_player_target):
		_cancel_player_dash()
		return
	var from := _player.global_position
	var dir := _flat_direction(from, _player_target.global_position)
	if dir.length_squared() < 0.001:
		dir = Vector3(sin(_player.rotation.y), 0.0, cos(_player.rotation.y))
		if dir.length_squared() < 0.001:
			dir = Vector3.FORWARD
	dir = dir.normalized()
	_player_dir = dir
	var contact := _contact_distance(_player, _player_target)
	var travel := minf(
		maxf(0.0, _flat_distance(from, _player_target.global_position) - contact),
		PLAYER_DASH_MAX)
	var plan := _player_dash_plan(travel)
	_player_fric = _friction_plan(travel, float(plan["time"]))
	_player_dash_speed = float(plan["speed"])
	_player_dash_left = float(_player_fric["time"])
	_player_dash_duration = float(_player_fric["time"])
	_player_phase = Phase.DASH
	_player.rotation.y = atan2(dir.x, dir.z)
	var to := from + dir * travel
	_vfx_begin(_player, _player_target, EncounterRules.Advantage.PLAYER_FIRST, from, to,
		_player_dash_duration, float(_player_fric["slide"]))


## D-1136: attack with no enemy. Uses the real player facing and the same 2 m
## cap, animation signal and VFX; it never resolves a hit or requests a battle.
func _start_player_free_attack() -> void:
	var dir := Vector3(sin(_player.rotation.y), 0.0, cos(_player.rotation.y))
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	var from := _player.global_position
	_player_target = null
	_player_dir = dir
	_player_free_attack = true
	_player_phase = Phase.PRE_DASH
	_player_pre_dash_left = PLAYER_WINDUP_TIME
	_player_attack_elapsed = 0.0
	_player_attack_origin = from
	_player_attack_origin_yaw = _player.rotation.y
	_player_attack_origin_valid = true
	_player.rotation.y = atan2(dir.x, dir.z)
	player_dash_started.emit(null, dir)


func _start_free_dash() -> void:
	var from := _player.global_position
	var dir := _player_dir
	var plan := _player_dash_plan(PLAYER_DASH_MAX)
	_player_fric = _friction_plan(PLAYER_DASH_MAX, float(plan["time"]))
	_player_dash_speed = float(plan["speed"])
	_player_dash_left = float(_player_fric["time"])
	_player_dash_duration = float(_player_fric["time"])
	_player_phase = Phase.DASH
	var to := from + dir * PLAYER_DASH_MAX
	_vfx_begin(_player, null, EncounterRules.Advantage.PLAYER_FIRST, from, to,
		_player_dash_duration, float(_player_fric["slide"]))


## Comic overhaul: the player recovers for 0.38 s after the 0.10 s dash; the
## lab plays the clip fast enough to fill wind-up + dash + recovery (0.62 s).
func _begin_player_endlag(test_hit: bool) -> void:
	var target := _player_target
	var hit := test_hit and target != null and is_instance_valid(target) and _hit_landed(_player, target)
	_player_phase = Phase.ENDLAG
	_player_target = null
	_player_active_target = null
	_player_active_left = 0.0
	_player_dash_left = 0.0
	_player_dash_speed = 0.0
	_player_dash_duration = 0.0
	_player_endlag_left = PLAYER_ENDLAG_TIME
	_zero_horizontal_velocity(_player)
	_vfx_finish(_player)
	if hit:
		_player_hit_frame = Engine.get_physics_frames()
		_player_hit_target = target
	else:
		_player_attack_origin_valid = false
		_player_hit_target = null
		# Overhaul: the hitbox stays live for 0.30 s after the dash; a target
		# that is already close can still be caught by the recovery.
		if target != null and is_instance_valid(target):
			_player_active_target = target
			_player_active_left = PLAYER_HIT_ACTIVE_TIME


func _finish_player_attack() -> void:
	_player_phase = Phase.NONE
	_player_target = null
	_player_dash_left = 0.0
	_player_dash_speed = 0.0
	_player_dash_duration = 0.0
	_player_pre_dash_left = 0.0
	_player_endlag_left = 0.0
	_player_attack_elapsed = 0.0
	_player_free_attack = false
	_zero_horizontal_velocity(_player)
	_player_cooldown = PLAYER_COOLDOWN
	_contact_grace = 0.40
	_player_attack_origin_valid = false
	_player_hit_target = null
	_player_active_target = null
	_player_active_left = 0.0


func _begin_enemy_telegraph(enemy: Node3D, entry: Dictionary) -> void:
	entry["phase"] = Phase.TELEGRAPH
	entry["telegraph"] = ENEMY_TELEGRAPH
	entry["pre_dash"] = 0.0
	entry["dir"] = Vector3.ZERO
	_vfx_telegraph(enemy)
	enemy_telegraph_started.emit(enemy)


func _begin_enemy_pre_dash(enemy: Node3D, entry: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		entry["phase"] = Phase.NONE
		return
	var from := enemy.global_position
	var dir := _flat_direction(from, _player.global_position)
	if dir.length_squared() < 0.001:
		dir = Vector3(sin(enemy.rotation.y), 0.0, cos(enemy.rotation.y))
		if dir.length_squared() < 0.001:
			dir = Vector3.FORWARD
	dir = dir.normalized()
	entry["dir"] = dir
	entry["pre_dash"] = ENEMY_WINDUP_TIME
	entry["attack_elapsed"] = 0.0
	entry["endlag_left"] = 0.0
	entry["phase"] = Phase.PRE_DASH
	enemy.rotation.y = atan2(dir.x, dir.z)
	enemy_dash_started.emit(enemy, dir)


func _start_enemy_dash(enemy: Node3D, entry: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		entry["phase"] = Phase.NONE
		return
	var from := enemy.global_position
	var dir := _flat_direction(from, _player.global_position)
	if dir.length_squared() < 0.001:
		dir = Vector3(sin(enemy.rotation.y), 0.0, cos(enemy.rotation.y))
		if dir.length_squared() < 0.001:
			dir = Vector3.FORWARD
	dir = dir.normalized()
	entry["dir"] = dir
	entry["pre_dash"] = 0.0
	var contact := _contact_distance(enemy, _player)
	var travel := minf(
		maxf(0.0, _flat_distance(from, _player.global_position) - contact),
		ENEMY_DASH_MAX)
	var plan := _dash_plan(travel)
	var fric := _friction_plan(travel, float(plan["time"]))
	entry["fric"] = fric
	entry["dash_speed"] = float(plan["speed"])
	entry["dash_left"] = float(fric["time"])
	entry["endlag_left"] = 0.0  # D-1189: no lock after the advance
	entry["dash_start"] = from
	entry["dash_end"] = from + dir * travel
	entry["phase"] = Phase.DASH
	enemy.rotation.y = atan2(dir.x, dir.z)
	_vfx_begin(enemy, _player, EncounterRules.Advantage.ENEMY_FIRST, entry["dash_start"], entry["dash_end"],
		float(fric["time"]), float(fric["slide"]))


func _begin_enemy_endlag(enemy: Node3D, entry: Dictionary, test_hit: bool) -> void:
	var hit := test_hit and _player != null and is_instance_valid(_player) and _hit_landed(enemy, _player)
	if hit:
		# D-1045: capture the logical spot before the visual push starts.
		_player_hit_origin = _player.global_position
		_player_hit_origin_yaw = _player.rotation.y
		_player_hit_origin_valid = true
	entry["phase"] = Phase.ENDLAG
	entry["dir"] = Vector3.ZERO
	entry["dash_left"] = 0.0
	entry["pre_dash"] = 0.0
	entry["endlag_left"] = 0.0  # D-1189: no lock after the advance (was: until the clip ended)
	_zero_horizontal_velocity(enemy)
	_vfx_finish(enemy)
	if hit:
		_enemy_hit_frame = Engine.get_physics_frames()
		_enemy_hit_target = enemy
	else:
		# Only the enemy that owned the pending hit may clear it. Another enemy
		# finishing a miss in the same frame must not erase a real hit.
		if _enemy_hit_target == enemy:
			_enemy_hit_target = null


func _finish_enemy_attack(_enemy: Node3D, entry: Dictionary) -> void:
	entry["phase"] = Phase.NONE
	entry["dir"] = Vector3.ZERO
	entry["dash_left"] = 0.0
	entry["pre_dash"] = 0.0
	entry["endlag_left"] = 0.0
	entry["attack_elapsed"] = 0.0
	entry["cooldown"] = ENEMY_COOLDOWN
	_contact_grace = 0.40
	# Same owner rule: only this enemy's pending hit may be cleared.
	if _enemy_hit_target == _enemy:
		_enemy_hit_target = null


## Both advances resolve in the same physics step, so "same instant" is the same
## frame. A single hit is enough for that side; both are a normal contact (D-1100).
func _resolve_pending_hits() -> void:
	if _player_hit_frame < 0 and _enemy_hit_frame < 0:
		return
	var player_hit := _player_hit_frame >= 0
	var enemy_hit := _enemy_hit_frame >= 0
	_player_hit_frame = -1
	_enemy_hit_frame = -1
	var advantage := EncounterRules.resolve(true, player_hit, true, enemy_hit)
	var contact := _impact_contact(player_hit, enemy_hit)
	var reactions := _impact_reactions(player_hit, enemy_hit)
	_pending_advantage = advantage
	_impact_hold = IMPACT_HOLD
	# The transition starts after the real-time hit window; it cuts any enemy
	# endlag instead of waiting for the animation to finish.
	impact_requested.emit(contact["pos"], contact["dir"], advantage, reactions)


## D-235/D-1045: the real victims of the two advances, never a proximity guess.
## Each hit pushes the victim away from the actor that actually hit it, so the
## same code works for any character, team or side. A tie returns both victims.
func _impact_reactions(player_hit: bool, enemy_hit: bool) -> Array:
	var reactions: Array = []
	if player_hit and _player != null and is_instance_valid(_player) \
			and _player_hit_target != null and is_instance_valid(_player_hit_target):
		var enemy_dir := _flat_direction(_player.global_position, _player_hit_target.global_position)
		reactions.append({
			"actor": _player_hit_target,
			"source": _player,
			"direction": enemy_dir.normalized() if enemy_dir.length_squared() > 0.0001 else Vector3.FORWARD,
		})
	if enemy_hit and _player != null and is_instance_valid(_player) \
			and _enemy_hit_target != null and is_instance_valid(_enemy_hit_target):
		var player_dir := _flat_direction(_enemy_hit_target.global_position, _player.global_position)
		reactions.append({
			"actor": _player,
			"source": _enemy_hit_target,
			"direction": player_dir.normalized() if player_dir.length_squared() > 0.0001 else Vector3.FORWARD,
		})
	return reactions


## D-1115: world point/direction of the contact for the Tackle impact.
func _impact_contact(player_hit: bool, enemy_hit: bool) -> Dictionary:
	var pos := _player.global_position + Vector3.UP * 0.6
	var dir := Vector3.FORWARD
	var player_target := _player_hit_target
	var enemy_target := _enemy_hit_target
	if player_hit and enemy_hit:
		var foe: Node3D = enemy_target if enemy_target != null and is_instance_valid(enemy_target) else player_target
		if foe != null and is_instance_valid(foe):
			pos = (_player.global_position + foe.global_position) * 0.5 + Vector3.UP * 0.6
			dir = _flat_direction(_player.global_position, foe.global_position)
	elif player_hit and player_target != null and is_instance_valid(player_target):
		var to_target := _flat_direction(_player.global_position, player_target.global_position)
		var contact := player_target.global_position
		if to_target.length_squared() > 0.001:
			contact -= to_target.normalized() * _body_radius(player_target)
		var mid_y := clampf(_body_height(player_target) * 0.5, 0.25, 1.0)
		pos = contact + Vector3.UP * mid_y
		dir = to_target
	elif enemy_hit and enemy_target != null and is_instance_valid(enemy_target):
		var to_player := _flat_direction(enemy_target.global_position, _player.global_position)
		var contact := _player.global_position
		if to_player.length_squared() > 0.001:
			contact -= to_player.normalized() * _body_radius(_player)
		var mid_y := clampf(_body_height(_player) * 0.5, 0.25, 1.0)
		pos = contact + Vector3.UP * mid_y
		dir = to_player
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	return {"pos": pos, "dir": dir.normalized()}


## D-1100: walking into an enemy without attacking is the normal contact.
## It never steals the input from an attack in progress (the phase check).
func _check_contact() -> void:
	if _battle_requested or _interaction_blocked:
		return
	if _impact_hold > 0.0:
		return
	if _player_phase != Phase.NONE:
		return
	if _contact_grace > 0.0:
		return
	for entry in _enemies:
		if int(entry["phase"]) != Phase.NONE:
			continue
		var enemy: Node3D = entry.get("node")
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if _flat_distance(_player.global_position, enemy.global_position) <= _contact_distance(_player, enemy):
			_emit_battle(EncounterRules.resolve(false, false, false, false))
			return


func _emit_battle(advantage: int) -> void:
	if _battle_requested:
		return
	_battle_requested = true
	_impact_hold = 0.0
	_pending_advantage = EncounterRules.Advantage.NORMAL
	_player_hit_target = null
	_enemy_hit_target = null
	if advantage == EncounterRules.Advantage.ENEMY_FIRST:
		_player_attack_origin_valid = false
	_cancel_player_dash(false)
	for entry in _enemies:
		if int(entry["phase"]) != Phase.NONE:
			_vfx_finish(entry.get("node"))
		entry["phase"] = Phase.NONE
		entry["telegraph"] = 0.0
		entry["pre_dash"] = 0.0
		entry["dash_left"] = 0.0
	_emit_target_changed()
	battle_requested.emit(advantage)
	# The lab reads the origin synchronously in the signal handler; clear it after.
	_player_hit_origin_valid = false


func _cancel_player_dash(invalidate_origin := true) -> void:
	var was_dashing := _player_phase == Phase.DASH
	if _player_phase != Phase.NONE:
		_player_phase = Phase.NONE
		_player_target = null
		_player_active_target = null
		_player_active_left = 0.0
		_player_dash_left = 0.0
		_player_dash_speed = 0.0
		_player_pre_dash_left = 0.0
		_player_endlag_left = 0.0
		_player_attack_elapsed = 0.0
		_player_free_attack = false
		if invalidate_origin:
			_player_attack_origin_valid = false
		if _player != null and is_instance_valid(_player):
			_zero_horizontal_velocity(_player)
		if was_dashing:
			_vfx_finish(_player)


## End-of-advance hit test: measured bodies + HIT_REACH, then line of sight
## against the real world geometry. No fixed positions or character assumptions.
func _hit_landed(attacker: Node3D, target: Node3D) -> bool:
	if attacker == null or target == null:
		return false
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false
	if not attacker.is_inside_tree() or not target.is_inside_tree():
		return false
	var flat := _flat_distance(attacker.global_position, target.global_position)
	if flat > _contact_distance(attacker, target) + HIT_REACH:
		return false
	var world := attacker.get_world_3d()
	if world == null:
		return true
	var from := attacker.global_position + Vector3(0.0, _probe_height(attacker), 0.0)
	var to := target.global_position + Vector3(0.0, _probe_height(target), 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var exclude: Array[RID] = []
	if attacker is CollisionObject3D:
		exclude.append((attacker as CollisionObject3D).get_rid())
	if target is CollisionObject3D:
		exclude.append((target as CollisionObject3D).get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := world.direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _contact_distance(attacker: Node3D, target: Node3D) -> float:
	return _body_radius(attacker) + _body_radius(target)


## Line-of-sight probe at the middle of each real body (D-235), not a fixed eye
## height. Falls back to 0.5 m when the node has no collision shape.
func _probe_height(node: Node3D) -> float:
	return clampf(_body_height(node) * 0.5, 0.15, 1.2)


func _body_height(node: Node3D) -> float:
	if node == null or not is_instance_valid(node):
		return 1.0
	for child in node.find_children("*", "CollisionShape3D", true, false):
		var shape_node := child as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			continue
		var shape := shape_node.shape
		if shape is CapsuleShape3D:
			return (shape as CapsuleShape3D).height
		if shape is SphereShape3D:
			return (shape as SphereShape3D).radius * 2.0
		if shape is CylinderShape3D:
			return (shape as CylinderShape3D).height
		if shape is BoxShape3D:
			return (shape as BoxShape3D).size.y
	return 1.0


## Reads the real collision shape. Characters without a shape fall back to a
## neutral radius instead of assuming a species/model.
func _body_radius(node: Node3D) -> float:
	if node == null or not is_instance_valid(node):
		return DEFAULT_BODY_RADIUS
	for child in node.find_children("*", "CollisionShape3D", true, false):
		var shape_node := child as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			continue
		var shape := shape_node.shape
		if shape is CapsuleShape3D:
			return (shape as CapsuleShape3D).radius
		if shape is SphereShape3D:
			return (shape as SphereShape3D).radius
		if shape is CylinderShape3D:
			return (shape as CylinderShape3D).radius
		if shape is BoxShape3D:
			var size := (shape as BoxShape3D).size
			return maxf(size.x, size.z) * 0.5
	return DEFAULT_BODY_RADIUS


func _advance(actor: CharacterBody3D, dir: Vector3, speed: float) -> void:
	var velocity := actor.velocity
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	actor.velocity = velocity
	actor.move_and_slide()


## D-1120: duration capped at 0.18 s, but never slower than MIN_DASH_SPEED.
## A target already within reach finishes at contact (the controller checks it).
func _player_dash_plan(travel: float) -> Dictionary:
	var speed := clampf(travel / PLAYER_DASH_TIME, MIN_DASH_SPEED, 18.0)
	var duration := clampf(travel / speed, PLAYER_DASH_TIME, 0.30)
	return {"speed": speed, "time": duration}


func _dash_plan(travel: float, time_cap := DASH_TIME) -> Dictionary:
	var cap := maxf(MIN_DASH_TIME, time_cap)
	var speed := maxf(travel / cap, MIN_DASH_SPEED)
	var duration := clampf(travel / speed, MIN_DASH_TIME, cap)
	return {"speed": speed, "time": duration}


## D-1189: friction profile of an advance. Position s(u) = travel * (1 - (1-u)^p), u = t / total:
## it leaves fast and brakes smoothly, ending exactly at `travel` (the contact). The exponent makes
## the last `slide` seconds cover `slide_dist` metres (~0.3 m in ~0.25 s). Short advances scale the
## tail down (at most half the distance). Same for the player and every enemy (D-235).
func _friction_plan(travel: float, base_time: float) -> Dictionary:
	if travel < FRICTION_MIN_TRAVEL:
		return {"time": base_time, "slide": 0.0, "travel": travel, "p": 1.0, "elapsed": 0.0, "off": true}
	var slide_dist := minf(SLIDE_DISTANCE, travel * 0.5)
	var slide := SLIDE_TIME * slide_dist / SLIDE_DISTANCE
	var total := base_time + slide
	var p := clampf(log(slide_dist / travel) / log(slide / total), 1.2, 6.0)
	# The initial speed is travel * p / total. Cap it by lowering p (a longer, softer tail on long
	# lunges), never by stretching the advance: a later hit would let the other side tie (D-1189).
	p = clampf(minf(p, FRICTION_PEAK_SPEED * total / travel), 1.2, 6.0)
	return {"time": total, "slide": slide, "travel": travel, "p": p, "elapsed": 0.0, "off": false}


## Average speed over this physics frame (exact displacement of the profile), so the
## braking has no integration error. Falls back to the constant speed without a profile.
func _friction_speed(fric: Dictionary, fallback: float, delta: float) -> float:
	if fric.is_empty() or bool(fric["off"]) or delta <= 0.0:
		return fallback
	var total := float(fric["time"])
	var travel := float(fric["travel"])
	var p := float(fric["p"])
	var t0 := float(fric["elapsed"])
	var t1 := minf(t0 + delta, total)
	fric["elapsed"] = t1
	var s0 := travel * (1.0 - pow(1.0 - t0 / total, p))
	var s1 := travel * (1.0 - pow(1.0 - t1 / total, p))
	return (s1 - s0) / delta


func _zero_horizontal_velocity(actor: CharacterBody3D) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var velocity := actor.velocity
	velocity.x = 0.0
	velocity.z = 0.0
	actor.velocity = velocity


func _flat_direction(from: Vector3, to: Vector3) -> Vector3:
	var direction := to - from
	direction.y = 0.0
	return direction


func _flat_distance(from: Vector3, to: Vector3) -> float:
	return _flat_direction(from, to).length()


func _emit_target_changed() -> void:
	var available := has_attack_target()
	if available == _target_available:
		return
	_target_available = available
	attack_target_changed.emit(available)


func _find_enemy(enemy: Node3D) -> Dictionary:
	if enemy == null:
		return {}
	for entry in _enemies:
		if entry.get("node") == enemy:
			return entry
	return {}


# --- Optional Agent B VFX hooks (D-1100) -------------------------------------
# The component is discovered by method name and argument count; without it the
# attack works exactly the same, only without speedlines/trail/dust. Agent B's
# OverworldDashVfx is per actor (setup/begin_dash(advantage)/tick/finish), so the
# controller keeps one component per real actor and clones a sibling when two
# advances run at the same time.

func _vfx_begin(actor: Node3D, target: Node3D, advantage: int, from: Vector3, to: Vector3,
		duration := 0.0, slide := 0.0) -> void:
	var fx := _vfx_for(actor)
	if fx == null:
		return
	_vfx_call_on(fx, "setup", [actor, target])
	# D-1189: the braking tail of the advance raises only a little dust.
	_vfx_call_on(fx, "set_slide_time", [slide])
	# D-1173: the dust needs the real advance duration to keep the walking puffs
	# only through the first half of the dash.
	if duration > 0.0:
		_vfx_call_on(fx, "set_dash_duration", [duration])
	# Agent B: begin_dash(advantage).
	if _vfx_call_on(fx, "begin_dash", [advantage]):
		return
	# Earlier plan hook: begin_dash(actor, from, to).
	_vfx_call_on(fx, "begin_dash", [actor, from, to])


func _vfx_tick(actor: Node3D, delta: float) -> void:
	var fx := _bound_vfx(actor)
	if fx != null:
		_vfx_call_on(fx, "tick", [delta])


func _vfx_finish(actor: Node3D) -> void:
	var fx := _bound_vfx(actor)
	if fx == null:
		return
	if _vfx_call_on(fx, "finish_dash", [actor]):
		return
	if _vfx_call_on(fx, "end_dash", [actor]):
		return
	if _vfx_call_on(fx, "finish", []):
		return
	_vfx_call_on(fx, "finish", [actor])


func _vfx_telegraph(actor: Node3D) -> void:
	if _vfx_root != null and is_instance_valid(_vfx_root):
		_vfx_call_on(_vfx_root, "begin_telegraph", [actor])


## One component per real actor. If the supplied node is already claimed, a
## sibling is cloned from its script so simultaneous advances both get VFX.
func _vfx_for(actor: Node3D) -> Node:
	var bound := _bound_vfx(actor)
	if bound != null:
		return bound
	if _vfx_root == null or not is_instance_valid(_vfx_root):
		return null
	var template: Node = null
	if _vfx_root.has_method("begin_dash"):
		if not _vfx_by_actor.values().has(_vfx_root):
			_vfx_by_actor[actor] = _vfx_root
			return _vfx_root
		template = _vfx_root
	else:
		for child in _vfx_root.get_children():
			if child.has_method("begin_dash") and not _vfx_by_actor.values().has(child):
				_vfx_by_actor[actor] = child
				return child
		for child in _vfx_root.get_children():
			if child.has_method("begin_dash"):
				template = child
				break
	if template == null:
		return null
	var script: Script = template.get_script()
	if script == null or not script.can_instantiate():
		return null
	var clone: Node = script.new()
	var parent := template.get_parent()
	if parent == null:
		return null
	clone.name = "DashVfx_%s" % actor.name
	parent.add_child(clone)
	_vfx_by_actor[actor] = clone
	return clone


func _bound_vfx(actor: Node3D) -> Node:
	if actor == null:
		return null
	var bound: Node = _vfx_by_actor.get(actor)
	if bound != null and is_instance_valid(bound):
		return bound
	_vfx_by_actor.erase(actor)
	return null


func _vfx_call_on(node: Node, method: String, args: Array) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if not node.has_method(method):
		return false
	for info in node.get_method_list():
		if str(info.get("name", "")) != method:
			continue
		if (info.get("args", []) as Array).size() == args.size():
			node.callv(method, args)
			return true
	return false
