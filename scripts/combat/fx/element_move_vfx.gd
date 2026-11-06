class_name ElementMoveVfx
extends Node3D
## D-308: element Moves in the REAL pipeline, in the four phases the game has: WIND-UP (the charge, held until the
## shot), RELEASE (the shot leaves), TRAJETO (the flight, driven by the projectile phase) and IMPACTO (self-timed).
## The VFX itself is a MotionEffect (scripts/motion_composer/representations): compositions of the Motion Composer
## painted by representations. This node only supplies what the game knows: the real positions, the phase clocks and
## the camera. It never touches the combat timeline (D-019) and is independent of the character, the team and the
## side of the field (D-235): everything comes from the real attacker and target bodies and the shot axis. The size is
## FIXED, the same in both views, in world units (D-308 item 6, creator: "tamanho fixo ... para ambas posições"): it does
## not depend on the body, the character, the side or the camera distance. This node holds NO appearance (protocol, section 2).

enum Stage { WINDUP, TRAVEL, IMPACT }

const IDS := ["flame_stream", "splitter_flames"]
const WORLD_SCALE := 1.0  ## one fixed scale for every view (D-308 item 6); all sizes live in the preset, in metres

var fx: BattleFx
var move_id := ""
var stage := Stage.WINDUP
var life := 1.0
var t := 0.0
var src := Vector3.ZERO
var dst := Vector3.ZERO
var ext_p := 0.0
var ext_returning := false
var dir := Vector3.FORWARD
var big := false
var held := false
var is_ceremony := false  ## D-337: a self-timed STATUS choreography (Media), anchored on the real allies

var _effect: MotionEffect
var _painter: MotionPainter
var _a := {"cy": 1.0, "top": 2.0, "r": 0.7}
var _fwd := Vector3.FORWARD
var _right := Vector3.RIGHT
var _vr := Vector3.RIGHT
var _hold_at := 0.0
var _hand0 := Vector3.ZERO
var _had_charge := false
var _rel_t0 := -1.0
var _ended := false
var _end_t := 0.0
var _flashed := false
var _released := false
var _attacker: Object = null
var _wind := 0.5
var _anchors: Array = []
var _center := Vector3.ZERO
var _pulse_at := 1.4  ## D-019 / D-337: the heal pulse lands on the real heal of the Battle clock (fallback: the HTML's 1.4 s)
static var _held: Dictionary = {}  ## attacker -> wind-up layer waiting to become the shot


# --- Factories -------------------------------------------------------------------------


static func windup(p_fx: BattleFx, p_move: String, p_src: Vector3, p_dst: Vector3, duration: float) -> ElementMoveVfx:
	return _spawn(p_fx, p_move, Stage.WINDUP, p_src, p_dst, maxf(duration, 0.05), false, Vector3.FORWARD)


static func travel(p_fx: BattleFx, p_move: String, p_from: Vector3, p_to: Vector3) -> ElementMoveVfx:
	return _spawn(p_fx, p_move, Stage.TRAVEL, p_from, p_to, INF, false, Vector3.FORWARD)


static func impact(p_fx: BattleFx, p_move: String, pos: Vector3, p_big: bool, p_dir: Vector3) -> ElementMoveVfx:
	return _spawn(p_fx, p_move, Stage.IMPACT, pos, pos, 2.2, p_big, p_dir)


## D-337: a STATUS choreography (Media) lives on its own clock, anchored on the real allies (never a fixed team, D-235).
static func ceremony(p_fx: BattleFx, p_move: String, p_src: Vector3, p_dst: Vector3, windup: float, attacker: Object) -> ElementMoveVfx:
	return _spawn(p_fx, p_move, Stage.WINDUP, p_src, p_dst, 2.45, false, Vector3.FORWARD, {"ceremony": true, "attacker": attacker, "windup": windup})


static func _spawn(p_fx: BattleFx, p_move: String, p_stage: Stage, p_src: Vector3, p_dst: Vector3, p_life: float, p_big: bool, p_dir: Vector3, opts := {}) -> ElementMoveVfx:
	var v := ElementMoveVfx.new()
	v.is_ceremony = bool(opts.get("ceremony", false))
	v._attacker = opts.get("attacker", null)
	v._wind = float(opts.get("windup", 0.5))
	v.name = "Element%s%s" % [p_move.capitalize().replace(" ", ""), Stage.keys()[p_stage].capitalize()]
	v.fx = p_fx
	v.move_id = p_move
	v.stage = p_stage
	v.src = p_src
	v.dst = p_dst
	v.life = p_life
	v.big = p_big
	if p_dir.length_squared() > 0.001:
		v.dir = p_dir.normalized()
	p_fx.add_child(v)
	return v


## The wind-up ends but the charge stays (and keeps burning) until the shot leaves.
func hold(attacker: Object) -> bool:
	if stage != Stage.WINDUP or not (move_id in IDS):
		return false
	held = true
	_hold_at = t
	_held[attacker] = self
	return true


static func take_held(attacker: Object) -> ElementMoveVfx:
	var n: Variant = _held.get(attacker)
	_held.erase(attacker)
	return n as ElementMoveVfx if is_instance_valid(n) else null


## The wind-up node becomes the flight layer where the shot leaves (the RELEASE): same node, same effect.
func launch(p_from: Vector3, p_to: Vector3) -> void:
	held = false
	_had_charge = true
	stage = Stage.TRAVEL
	life = INF
	_rel_t0 = t
	set_travel(p_from, p_to, 0.0, false)


func set_travel(p_from: Vector3, p_to: Vector3, progress: float, returning: bool) -> void:
	src = p_from
	dst = p_to
	ext_p = progress
	ext_returning = returning


func end_flight() -> void:
	if not _ended:
		_ended = true
		_end_t = t


# --- Lifecycle -------------------------------------------------------------------------


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return fx.cam.camera.global_position if fx != null and fx.cam != null and fx.cam.camera != null else Vector3(0, 3, 8)
	_painter.cam_basis_fn = func() -> Basis: return fx.cam.camera.global_transform.basis if fx != null and fx.cam != null and fx.cam.camera != null else Basis.IDENTITY
	add_child(_painter)
	if is_ceremony:
		_collect_anchors()
		if fx != null and fx.battle != null:
			fx.battle.healed.connect(_on_healed)  # D-019: the pulse follows the real heal, not a guessed time
	_effect = MotionPresets.effect_for(move_id, randi(), _anchors, _center)  # one MotionEffect per move_id (D-235)
	_probe()
	_frame()


## D-337: the first real heal of this caster sets the exact instant of the 50-sparkle pulse (all allies heal together).
func _on_healed(actor, _target, _amount: int) -> void:
	if actor == _attacker:
		_pulse_at = t


## D-337: the anchors of a party-wide choreography are the real allies of the real attacker (party or enemies, any side).
func _collect_anchors() -> void:
	_anchors.clear()
	if fx == null or fx.battle == null:
		_anchors.append(Vector3(src.x, 0.0, src.z))
		_center = Vector3(src.x, 0.0, src.z)
		return
	var player := _attacker != null and bool(_attacker.get("is_player"))
	var team: Array = fx.battle.party if player else fx.battle.enemies
	var acc := Vector3.ZERO
	for c in team:
		if c == null or not c.is_alive():
			continue
		var p: Vector3 = c.pos
		var m: Variant = fx._models.get(c)
		if m != null and is_instance_valid(m):
			p = (m as Node3D).global_position
		var a := Vector3(p.x, 0.0, p.z)
		_anchors.append(a)
		acc += a
	if _anchors.is_empty():
		_anchors.append(Vector3(src.x, 0.0, src.z))
		_center = Vector3(src.x, 0.0, src.z)
	else:
		_center = acc / float(_anchors.size())


func _process(delta: float) -> void:
	t += delta
	if is_ceremony:
		_frame()
		_painter.time = t
		_painter.begin_frame()
		var geo := {"origin": src, "dest": dst, "head": src, "axis": _fwd, "k": clampf(t / maxf(life, 0.05), 0.0, 1.0),
			"p": 0.0, "scale": WORLD_SCALE, "landed": false}
		_effect.draw(_painter, "windup", t, geo)
		if t >= _pulse_at:
			_effect.draw(_painter, "impact", t - _pulse_at, geo)
		_painter.end_frame()
		if t >= life:
			queue_free()
		return
	if held and t - _hold_at > 6.0:
		queue_free()  # the shot never came (safety)
		return
	_frame()
	_painter.time = t
	_painter.begin_frame()
	match stage:
		Stage.WINDUP: _windup_draw()
		Stage.TRAVEL: _travel_draw()
		Stage.IMPACT: _impact_draw()
	_painter.end_frame()
	if stage == Stage.WINDUP and t >= life + 0.8 and not held:
		queue_free()
	elif stage == Stage.IMPACT and t >= life:
		queue_free()
	elif stage == Stage.TRAVEL and _ended and t >= _end_t + 1.4:
		queue_free()


func _probe() -> void:
	var a := _body_at(src) if stage != Stage.IMPACT else {}
	if not a.is_empty():
		_a = a


func _body_at(p: Vector3) -> Dictionary:
	if fx == null:
		return {}
	var best: Node3D = null
	var best_d := 3.0
	for m in fx._models.values():
		if not is_instance_valid(m):
			continue
		var d := Vector2((m as Node3D).global_position.x - p.x, (m as Node3D).global_position.z - p.z).length()
		if d < best_d:
			best_d = d
			best = m
	if best == null:
		return {}
	var box := AABB()
	var first := true
	for mi in best.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or String(m3.name) in ["BurstRing", "ReadyRing"] or String(m3.name).begins_with("Guard") or String(m3.name).begins_with("Shield"):
			continue
		var b := m3.global_transform * m3.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first or box.size.y < 0.3:
		return {}
	return {"cy": box.get_center().y, "top": box.end.y, "r": clampf(minf(box.size.x, box.size.z) * 0.5, 0.5, 3.0)}


func _frame() -> void:
	var f := Vector3(dir.x, 0.0, dir.z) if stage == Stage.IMPACT else Vector3(dst.x - src.x, 0.0, dst.z - src.z)
	_fwd = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	_right = _fwd.cross(Vector3.UP).normalized()
	var cb := fx.cam.camera.global_transform.basis if fx != null and fx.cam != null and fx.cam.camera != null else Basis.IDENTITY
	var vr := cb.x - _fwd * cb.x.dot(_fwd)
	vr.y = 0.0
	_vr = vr.normalized() if vr.length() > 0.1 else _right


## Where the charge sits: in front of the attacker's chest, from the real body.
func _hand_base() -> Vector3:
	var flat := Vector3(src.x, 0.0, src.z)
	return flat + _fwd * (float(_a["r"]) + 0.5) + _vr * (float(_a["r"]) * 0.35) + Vector3.UP * (float(_a["cy"]) + 0.05)


## D-308 item 6: the same scale in every view (no camera distance, no body size).
func _scale_at(_pos: Vector3) -> float:
	return WORLD_SCALE


# --- The phases: each one hands the real positions and its clock to the MotionEffect ---------------------------


func _windup_draw() -> void:
	var hand := _hand_base()
	_hand0 = hand
	var axis := (dst - hand).normalized()
	var k := clampf(t / maxf(life, 0.05), 0.0, 1.0)
	_effect.draw(_painter, "windup", t, {"origin": hand, "dest": dst, "head": hand, "axis": axis, "k": k, "p": 0.0, "scale": _scale_at(hand)})


func _travel_draw() -> void:
	if _rel_t0 < 0.0:
		_rel_t0 = t
	var rel := t - _rel_t0
	var start := _hand0 if _had_charge else src
	var p := clampf(ext_p, 0.0, 1.0)
	var head := start.lerp(dst, p)
	var axis := (dst - start).normalized()
	_released = true
	_effect.draw(_painter, "travel", rel, {"origin": start, "dest": dst, "head": head, "axis": axis, "k": p, "p": p, "landed": _ended or ext_returning, "scale": _scale_at(head)})


func _impact_draw() -> void:
	var forward := (_fwd + Vector3.UP * 0.1).normalized()
	_flashed = true
	_effect.draw(_painter, "impact", t, {"origin": dst, "dest": dst + forward, "head": dst, "axis": forward, "k": clampf(t / life, 0.0, 1.0), "p": 1.0, "scale": _scale_at(dst)})


static func _ease(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)
