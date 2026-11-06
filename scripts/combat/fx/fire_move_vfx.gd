class_name FireMoveVfx
extends Node3D
## Visual layer of the fire Moves (D-236). Fire Bullet today; Splitter Flames is the next stage.
## One node is one stage of one move: WINDUP (lives until the telegraph is cleared, then is held
## until the shot leaves), TRAVEL (driven by the projectile phase) or IMPACT (self-timed).
## It only draws and never touches the combat timeline (D-019), and it is independent of the
## character, the team and the side of the field (D-235): everything is derived from the real
## attacker and target bodies, the attacker -> target axis and the camera.
##
## Stylised fire (creator's order): cel-shaded yellow-orange bands (`fire_orb` on real 3D meshes,
## `fire_flame` on quads), a golden halo (`fire_glow`), spark rings (`fire_ring`), a scorched floor
## mark (`fire_scorch`) and grey ash (`fire_ash`), plus the game's fire flipbook and particle bursts.

enum Stage { WINDUP, TRAVEL, IMPACT }

const IDS := ["fire_bullet"]
const EMBER := Color("ffb03a")
const SPARK_HOT := Color(1.0, 0.62, 0.16)
const SPARK_MID := Color(1.0, 0.45, 0.08)
const SPARK_EDGE := Color(0.92, 0.18, 0.04)
const HAND_YAW := 0.0  ## the fire hand points straight at the target (creator: it must be fairly straight)
const HAND_PITCH := 1.3  ## at the shot the hand and its index finger swing up by this angle (radians)
const HAND_PITCH_T := 0.16  ## seconds that swing takes
const HAND_FORM := 0.3  ## the first 0.3 s of the wind-up: the hand forms out of the flames and appears
const RING_EARLY := 0.1  ## the rings APPEAR this long before the bullet leaves (creator: "surgir um pouco mais cedo")
const RING_SCALE := 0.8  ## and are 20% smaller (creator)
const HAND_FADE := 0.3  ## seconds the hand takes to vanish after the swing starts
const RING_COUNT := 3  ## spark rings that go with the bullet (sheet: three)
const RING_DECEL := 0.25  ## the rings brake hard and widen during the first 0.25 s of the flight (sheet)
const RING_STAGGER := 0.05
## Fingertip of the hand mesh in its own space (wrist at the origin, +Y towards the fingers, length 1).
const HAND_TIP := Vector3(-0.165, 1.0, -0.015)
const COCOON := 0.35  ## the ring burst of an interrupted target slams out in 0.35 s (the sheet's 0.35 s, as rings: creator)
## Ricochet: the sheet fixes only its shape (the bullet leaps spinning towards the floor, slow arc, fixed
## speed, high gravity). The creator asked for it to rise higher. Numbers PROVISIONAL (D-236, pending item 2).
const RICO_BACK := 2.5
const RICO_UP := 10.5
const RICO_GRAVITY := 24.0
const RICO_SPIN := 18.0

class Pt:
	var p := Vector3.ZERO
	var v := Vector3.ZERO
	var drag := 0.93
	var gravity := 0.0
	var life := 0.0
	var max_life := 0.5
	var size := 0.2
	var grow := 0.0
	var kind := "flame"  ## flame | spark | ash | bullet
	var seed_ := 0.0
	var to_ash := false

var fx: BattleFx
var move_id := ""
var stage := Stage.WINDUP
var life := 1.0  ## WINDUP: wind-up length. IMPACT: seconds until freed.
var t := 0.0
var src := Vector3.ZERO
var dst := Vector3.ZERO
var ext_p := 0.0
var ext_returning := false
var dir := Vector3.FORWARD
var big := false
var interrupted := false  ## IMPACT: the hit stopped an action of the target (the sheet's special impact)
var held := false

var _rng := RandomNumberGenerator.new()
var _dt := 0.016
var _pts: Array[Pt] = []
var _flames: Array[MeshInstance3D] = []
var _flame_used := 0
var _ashes: Array[MeshInstance3D] = []
var _ash_used := 0
var _rings: Array[MeshInstance3D] = []
var _ring_used := 0
var _orbs: Array[MeshInstance3D] = []  ## real 3D meshes with the fire shader
var _orb_used := 0
var _glows: Array[MeshInstance3D] = []
var _glow_used := 0
var _scorches: Array[MeshInstance3D] = []
var _scorch_used := 0
var _fwd := Vector3.FORWARD
var _right := Vector3.RIGHT
var _vr := Vector3.RIGHT  ## screen-right, flat and perpendicular to the shot axis
var _a := {"cy": 1.0, "top": 2.0, "r": 0.7}  ## attacker body (world): centre height, top, radius
var _g := {"cy": 1.0, "top": 2.0, "r": 0.7}  ## target body
var _u := 1.0  ## hand / bullet unit, from the real body and the camera distance
var _hl := 0.5  ## length of the fire hand (wrist to fingertip), world units
var _hand_mi: MeshInstance3D
var _hand_drawn := false
var _tip0 := Vector3.ZERO  ## fingertip while the hand points at the target: where the bullet leaves
var _had_hand := false
var _rel_t0 := -1.0
var _axis0 := Vector3.FORWARD
var _v0 := 0.0  ## measured speed of the bullet at launch (the rings start with it, then brake)
var _ring_sp := [false, false, false]
var _muzzled := false
var _formed := false
var _launch_in := INF  ## seconds until the bullet leaves (told by the projectile layer while the hand is held)
var _ring_t0 := -1.0  ## when the rings appeared
var _ring_start := Vector3.ZERO
var _fired := false
var _ended := false
var _end_t := 0.0
var _hold_at := 0.0

static var _held: Dictionary = {}  ## attacker -> wind-up layer waiting to become the shot
static var _hand_mesh: Mesh  ## the downloaded low-poly hand (assets/vfx/fire_hand.glb, credits next to it)


# --- Factories ----------------------------------------------------------------------


static func windup(p_fx: BattleFx, p_move: String, p_src: Vector3, p_dst: Vector3, duration: float) -> FireMoveVfx:
	return _spawn(p_fx, p_move, Stage.WINDUP, p_src, p_dst, maxf(duration, 0.05), false, Vector3.FORWARD, false)


static func travel(p_fx: BattleFx, p_move: String, p_from: Vector3, p_to: Vector3) -> FireMoveVfx:
	return _spawn(p_fx, p_move, Stage.TRAVEL, p_from, p_to, INF, false, Vector3.FORWARD, false)


static func impact(p_fx: BattleFx, p_move: String, pos: Vector3, p_big: bool, p_dir: Vector3, p_interrupted: bool) -> FireMoveVfx:
	return _spawn(p_fx, p_move, Stage.IMPACT, pos, pos, 1.9, p_big, p_dir, p_interrupted)


static func _spawn(p_fx: BattleFx, p_move: String, p_stage: Stage, p_src: Vector3, p_dst: Vector3, p_life: float, p_big: bool, p_dir: Vector3, p_interrupted: bool) -> FireMoveVfx:
	var v := FireMoveVfx.new()
	v.name = "Fire%s%s" % [p_move.capitalize().replace(" ", ""), Stage.keys()[p_stage].capitalize()]
	v.fx = p_fx
	v.move_id = p_move
	v.stage = p_stage
	v.src = p_src
	v.dst = p_dst
	v.life = p_life
	v.big = p_big
	v.interrupted = p_interrupted
	if p_dir.length_squared() > 0.001:
		v.dir = p_dir.normalized()
	p_fx.add_child(v)
	return v


## The wind-up ends but the fire hand stays until the shot leaves.
func hold(attacker: Object) -> bool:
	if stage != Stage.WINDUP or not (move_id in IDS):
		return false
	held = true
	_hold_at = t
	_held[attacker] = self
	return true


## While the cast pose plays, the projectile layer tells the held hand how long is left before the shot.
static func notify_launch_in(attacker: Object, seconds: float) -> void:
	var n: Variant = _held.get(attacker)
	if is_instance_valid(n):
		(n as FireMoveVfx)._launch_in = seconds


static func take_held(attacker: Object) -> FireMoveVfx:
	var n: Variant = _held.get(attacker)
	_held.erase(attacker)
	return n as FireMoveVfx if is_instance_valid(n) else null


## The shot leaves: the held wind-up node becomes the flight layer (same hand, which swings up and vanishes).
func launch(p_from: Vector3, p_to: Vector3) -> void:
	held = false
	stage = Stage.TRAVEL
	life = INF
	_rel_t0 = t
	set_travel(p_from, p_to, 0.0, false)


func set_travel(p_from: Vector3, p_to: Vector3, progress: float, returning: bool) -> void:
	src = p_from
	dst = p_to
	ext_p = progress
	ext_returning = returning


## The projectile phase is over: the bullet is gone, the trail and the ashes finish on their own.
func end_flight() -> void:
	if not _ended:
		_ended = true
		_end_t = t


# --- Lifecycle -----------------------------------------------------------------------


func _ready() -> void:
	_rng.randomize()
	top_level = true
	global_transform = Transform3D.IDENTITY
	_probe()
	_frame()


func _process(delta: float) -> void:
	_dt = delta
	t += delta
	if held and t - _hold_at > 6.0:
		queue_free()  # the shot never came (safety)
		return
	_flame_used = 0
	_ash_used = 0
	_ring_used = 0
	_orb_used = 0
	_glow_used = 0
	_scorch_used = 0
	_hand_drawn = false
	_frame()
	match stage:
		Stage.WINDUP: _windup_draw()
		Stage.TRAVEL: _travel_draw()
		Stage.IMPACT: _impact_draw()
	_particles_update()
	_particles_draw()
	for i in range(_flame_used, _flames.size()):
		_flames[i].visible = false
	for i in range(_ash_used, _ashes.size()):
		_ashes[i].visible = false
	for i in range(_ring_used, _rings.size()):
		_rings[i].visible = false
	for i in range(_orb_used, _orbs.size()):
		_orbs[i].visible = false
	for i in range(_glow_used, _glows.size()):
		_glows[i].visible = false
	for i in range(_scorch_used, _scorches.size()):
		_scorches[i].visible = false
	if _hand_mi != null:
		_hand_mi.visible = _hand_drawn
	if stage == Stage.IMPACT and t >= life:
		queue_free()
	elif stage == Stage.TRAVEL and _ended and t >= _end_t + 1.3:
		queue_free()


# --- Measuring the real bodies (D-235: nothing is tied to a character or a side) ---------


func _probe() -> void:
	var a := _body_at(src) if stage != Stage.IMPACT else {}
	var g := _body_at(dst)
	if not a.is_empty():
		_a = a
	if not g.is_empty():
		_g = g
	_u = clampf(float(_a["top"]) * 0.62, 0.9, 2.6) * clampf(_dist_k(src), 1.0, 2.2)
	_hl = clampf(float(_a["top"]) * 0.36, 0.5, 1.1) * clampf(_dist_k(src), 1.0, 1.8) * 1.15 * 1.2  # +15%, then +20% more (creator)
	if big:
		_u *= 1.2
		_hl *= 1.2


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
		if m3.mesh == null or String(m3.name) in ["BurstRing", "ReadyRing"]:
			continue
		var b := m3.global_transform * m3.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first or box.size.y < 0.3:
		return {}
	return {"cy": box.get_center().y, "top": box.end.y, "r": clampf(minf(box.size.x, box.size.z) * 0.5, 0.5, 3.0)}


func _dist_k(world_p: Vector3) -> float:
	return fx.vfx_scale_at(world_p) if fx != null and fx.is_inside_tree() else 1.0


## Flat attacker -> target axis (the impact stage receives it directly), and the screen side across it.
func _frame() -> void:
	var f := Vector3(dir.x, 0.0, dir.z) if stage == Stage.IMPACT else Vector3(dst.x - src.x, 0.0, dst.z - src.z)
	_fwd = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	_right = _fwd.cross(Vector3.UP).normalized()
	var cb := _cam_basis()
	var vr := cb.x - _fwd * cb.x.dot(_fwd)
	vr.y = 0.0
	_vr = vr.normalized() if vr.length() > 0.1 else _right


func _cam_basis() -> Basis:
	if fx != null and fx.cam != null and fx.cam.camera != null:
		return fx.cam.camera.global_transform.basis
	return Basis.IDENTITY


## Roll that makes a flame's tip (+Y of the quad) point along `world_dir` on screen.
func _roll_for(world_dir: Vector3) -> float:
	var cb := _cam_basis()
	return atan2(-world_dir.dot(cb.x), world_dir.dot(cb.y))


static func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


func _px_chance(p: float) -> bool:
	return _rng.randf() < p * _dt * 60.0


# --- Shader quad / mesh pools ------------------------------------------------------------


func _quad(pool: Array[MeshInstance3D], used: int, shader_name: String) -> MeshInstance3D:
	if used >= pool.size():
		var made := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		made.mesh = q
		made.material_override = VfxLib.shader_mat(shader_name, {})
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(made)
		pool.append(made)
	return pool[used]


## One stylised flame quad (camera-facing). `blob` 1 = round puff, 0 = teardrop whose tip points along `roll`.
## `spark` paints it in the red / orange sparks palette instead of the yellow-orange fire palette.
func _flame(pos: Vector3, size: float, intensity: float, roll: float, fade: float, blob: float, seed_ := 0.0, spark := false) -> void:
	if size <= 0.02 or intensity <= 0.02 or fade >= 0.99:
		return
	var mi := _quad(_flames, _flame_used, "fire_flame")
	_flame_used += 1
	mi.visible = true
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", t)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("roll", roll)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("blob", blob)
	mat.set_shader_parameter("seed", seed_)
	if spark:
		mat.set_shader_parameter("core", SPARK_HOT)
		mat.set_shader_parameter("hot", SPARK_HOT)
		mat.set_shader_parameter("mid", SPARK_MID)
		mat.set_shader_parameter("edge", SPARK_EDGE)


## Soft golden-orange halo.
func _glow(pos: Vector3, size: float, intensity: float) -> void:
	if size <= 0.05 or intensity <= 0.02:
		return
	var mi := _quad(_glows, _glow_used, "fire_glow")
	_glow_used += 1
	mi.visible = true
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	(mi.material_override as ShaderMaterial).set_shader_parameter("intensity", intensity)


func _ash(pos: Vector3, size: float, alpha: float, seed_: float) -> void:
	if alpha <= 0.02:
		return
	var mi := _quad(_ashes, _ash_used, "fire_ash")
	_ash_used += 1
	mi.visible = true
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", t)
	mat.set_shader_parameter("alpha", alpha)
	mat.set_shader_parameter("seed", seed_)


## A real 3D mesh of stylised fire. `axis` is the long axis of a spindle (`length` > 0) or ignored for a sphere.
func _orb(pos: Vector3, radius: float, intensity: float, fade := 0.0, axis := Vector3.UP, length := 0.0, seed_ := 0.0, flow := 3.0) -> void:
	if radius <= 0.01 or intensity <= 0.02 or fade >= 0.99:
		return
	if _orb_used >= _orbs.size():
		var made := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.5
		sph.height = 1.0
		sph.radial_segments = 24
		sph.rings = 14
		made.mesh = sph
		made.material_override = VfxLib.shader_mat("fire_orb", {})
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(made)
		_orbs.append(made)
	var mi := _orbs[_orb_used]
	_orb_used += 1
	mi.visible = true
	var ax := axis.normalized()
	var basis := Basis(Quaternion(Vector3.UP, ax)) if absf(ax.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if ax.y > 0.0 else Basis(Vector3.RIGHT, PI))
	mi.transform = Transform3D(basis, pos)
	mi.scale = Vector3(radius * 2.0, maxf(length, radius * 2.0), radius * 2.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", t)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("flow", flow)


## A scorched mark on the floor: dark burn with glowing cracks that cool and fade.
func _scorch(center: Vector3, radius: float, fade: float, intensity: float, seed_ := 0.0) -> void:
	if radius <= 0.05 or fade >= 0.99:
		return
	var mi := _quad(_scorches, _scorch_used, "fire_scorch")
	_scorch_used += 1
	mi.visible = true
	mi.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(center.x, 0.04, center.z))
	mi.scale = Vector3(radius * 2.0, radius * 2.0, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", t)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("seed", seed_)


## A ring of sparks lying in the plane whose normal is `normal`; `radius` is the ring itself.
func _spark_ring(center: Vector3, normal: Vector3, radius: float, fade: float, intensity: float, seed_ := 0.0, thick := 0.05) -> void:
	if radius <= 0.02 or fade >= 0.99:
		return
	var mi := _quad(_rings, _ring_used, "fire_ring")
	_ring_used += 1
	mi.visible = true
	var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	mi.transform = Transform3D(Basis.looking_at(normal, up), center)
	mi.scale = Vector3(radius / 0.78 * 2.0, radius / 0.78 * 2.0, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", t)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("thick", thick)


# --- Particles (flames that turn into ash, sparks) -----------------------------------------


func _spawn_pt(kind: String, p: Vector3, v: Vector3, life_s: float, size: float, gravity := 0.0, drag := 0.93, to_ash := false, grow := 0.0) -> Pt:
	var q := Pt.new()
	q.kind = kind
	q.p = p
	q.v = v
	q.max_life = life_s
	q.size = size
	q.gravity = gravity
	q.drag = drag
	q.to_ash = to_ash
	q.grow = grow
	q.seed_ = _rng.randf() * 40.0
	_pts.append(q)
	return q


func _particles_update() -> void:
	var i := _pts.size() - 1
	while i >= 0:
		var q := _pts[i]
		q.v.y -= q.gravity * _dt
		q.v *= pow(q.drag, _dt * 60.0)
		q.p += q.v * _dt
		q.life += _dt
		var dead := q.life >= q.max_life
		if q.kind == "bullet" and q.p.y <= 0.18 and q.v.y < 0.0:
			dead = true
			_ricochet_lands(q.p)
		if dead:
			if q.to_ash and _rng.randf() < 0.6:
				_spawn_pt("ash", q.p, Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.4, 1.0), _rng.randf_range(-0.3, 0.3)), 0.7 + _rng.randf() * 0.4, q.size * 1.2, 0.0, 0.96, false, 0.8)
			_pts.remove_at(i)
		i -= 1


func _particles_draw() -> void:
	for q in _pts:
		var k := clampf(q.life / q.max_life, 0.0, 1.0)
		match q.kind:
			"flame":
				_flame(q.p, q.size * (1.0 - k * 0.45 + q.grow * k), 0.95, 0.0, smoothstep(0.2, 1.0, k), 0.45, q.seed_)
			"spark":
				_flame(q.p, q.size * (1.0 - k * 0.8), 1.0, 0.0, 0.0, 1.0, q.seed_, true)
			"ash":
				_ash(q.p, q.size * (1.0 + q.grow * k), 0.55 * pow(1.0 - k, 1.2), q.seed_)
			"bullet":
				_bullet(q.p, q.v, q.life * RICO_SPIN, 0.8 * q.size)
				if _px_chance(1.4):
					_spawn_pt("flame", q.p, Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.2, 0.9), _rng.randf_range(-0.3, 0.3)), 0.3 + _rng.randf() * 0.2, q.size * 0.6, 0.0, 0.9, true)
				if _px_chance(1.0):
					_spawn_pt("spark", q.p, Vector3(_rng.randf_range(-2.0, 2.0), _rng.randf_range(0.0, 2.5), _rng.randf_range(-2.0, 2.0)), 0.3, 0.09, 0.0, 0.92)


## The bullet itself: an ovoid fire mesh (long axis along its velocity) with a hot inner mesh, a golden halo,
## flames streaming off it and two sparks circling it.
func _bullet(pos: Vector3, vel: Vector3, spin: float, size: float) -> void:
	var dirv := vel.normalized() if vel.length() > 0.01 else _fwd
	var back := -dirv
	_glow(pos, size * 4.2, 0.8)
	_orb(pos, size * 0.5, 1.0, 0.0, dirv, size * 1.7, spin * 0.01, 4.0)
	_orb(pos + dirv * size * 0.1, size * 0.27, 1.15, 0.0, dirv, size * 0.9, 7.0, 5.0)
	_flame(pos + back * size * 0.85, size * 1.6, 1.0, _roll_for(back), 0.0, 0.0, 3.0)
	for i in 2:
		var a := spin + float(i) * PI
		var off := (_right * cos(a) + Vector3.UP * sin(a)) * size * 0.66
		_flame(pos + off, size * 0.22, 1.0, 0.0, 0.0, 1.0, float(i) * 9.0, true)


# --- WINDUP: a hand made only of fire, pointing (sheet) ---------------------------------------------


func _hand_base() -> Vector3:
	var flat := Vector3(src.x, 0.0, src.z)
	return flat + _fwd * (float(_a["r"]) + 0.9 * _hl) + _vr * (float(_a["r"]) * 0.6 + 0.5 * _hl) + Vector3.UP * (float(_a["cy"]) + 0.15 * _hl)


## The finger direction F and the hand's "up" U. The hand is turned HAND_YAW towards the screen side, so it is
## seen three-quarter on instead of foreshortened; `pitch` swings both up (the swing at the shot).
func _hand_axes(pitch: float) -> Array:
	var f0 := (_fwd * cos(HAND_YAW) + _vr * sin(HAND_YAW) + Vector3.UP * 0.1).normalized()
	var f := (f0 * cos(pitch) + Vector3.UP * sin(pitch)).normalized()
	var u := (Vector3.UP * cos(pitch) - f0 * sin(pitch)).normalized()
	return [f, u]


func _windup_draw() -> void:
	# First HAND_FORM seconds: the hand forms. It grows from nothing with a little overshoot, burns in from the
	# edges (the shader's `fade` erodes it away until it is whole) and flings sparks and flame puffs as it appears.
	var form := clampf(t / HAND_FORM, 0.0, 1.0)
	var gs := _ease_out(form) * (1.0 + 0.1 * sin(form * PI))
	var base := _hand_base()
	if not _formed:
		_formed = true
		for i in 18:
			var d := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.2, 1.0), _rng.randf_range(-1.0, 1.0)).normalized()
			_spawn_pt("spark", base + d * 0.2 * _hl, d * _rng.randf_range(2.0, 5.0), 0.35 + _rng.randf() * 0.2, 0.09 * _hl, 0.0, 0.92)
		for i in 6:
			var d := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(0.0, 1.0), _rng.randf_range(-1.0, 1.0)).normalized()
			_spawn_pt("flame", base + d * 0.15 * _hl, d * _rng.randf_range(0.8, 2.0), 0.4 + _rng.randf() * 0.2, 0.5 * _hl, 0.0, 0.9, true)
	if form < 1.0:
		_glow(base, 3.2 * _hl * form, 0.8 * (1.0 - form))  # a flash of light where it forms
	_hand(gs, pow(1.0 - _ease_out(form), 2.0) * 0.92, 0.0)
	if held and _ring_t0 < 0.0 and _launch_in <= RING_EARLY:
		_ring_t0 = t  # the spark rings appear a little before the bullet leaves
		_ring_start = _tip0
	if _ring_t0 >= 0.0:
		_draw_rings(_tip0, (dst - _tip0).normalized(), 0.6 * clampf(_dist_k(_tip0), 1.0, 2.0) * (1.2 if big else 1.0), t - _ring_t0)


## The downloaded low-poly hand (fist, extended index finger, thumb up, three fingers in total plus the thumb),
## drawn with the stylised fire shader `fire_orb`. Flames lick from the wrist and the fingertip, and a golden
## halo sits behind it. It grows out of the fire while the move charges; at the shot it swings up with its index
## finger and vanishes.
func _hand(gs: float, fade: float, pitch: float) -> void:
	_had_hand = true
	var hl := _hl * gs
	var base := _hand_base()
	# The hand is alive: while it charges it bobs, sways and nods, and pushes towards the target in pulses (it is aiming);
	# when the shot leaves it kicks back before it swings up.
	var live := 1.0 - fade
	var swing := clampf(pitch / HAND_PITCH, 0.0, 1.0)
	var ax := _hand_axes(pitch + 0.14 * sin(t * 9.0) * live * (1.0 - swing))
	var f: Vector3 = (ax[0] as Vector3).rotated(Vector3.UP, 0.2 * sin(t * 5.0) * live * (1.0 - swing))
	var up: Vector3 = ax[1]
	up = (up - f * up.dot(f)).normalized()
	base += Vector3.UP * (0.09 * hl * sin(t * 7.0) * live) + f * (0.08 * hl * maxf(sin(t * 11.0), 0.0) * live * (1.0 - swing))
	base -= _fwd * (0.35 * hl * sin(swing * PI))  # recoil as the finger flicks up
	var zc := f.cross(up)  # the mesh's +Z (back of the hand)
	var bas := Basis(-up, f, zc)  # mesh -X (thumb) -> up, +Y (fingers) -> f
	var tip := base + bas * (HAND_TIP * hl)
	if pitch <= 0.0:
		_tip0 = tip
	_glow(base + f * (0.45 * hl), 2.6 * hl, 0.7 * (1.0 - fade))
	if gs > 0.02 and fade < 0.99:
		if _hand_mi == null:
			if _hand_mesh == null:
				var scene := load("res://assets/vfx/fire_hand.glb") as PackedScene
				if scene != null:
					var inst := scene.instantiate()
					for m in inst.find_children("*", "MeshInstance3D", true, false):
						_hand_mesh = (m as MeshInstance3D).mesh
						break
					inst.free()
			_hand_mi = MeshInstance3D.new()
			_hand_mi.mesh = _hand_mesh
			_hand_mi.material_override = VfxLib.shader_mat("fire_orb", {"lick": 0.04, "bias": -0.32})
			_hand_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(_hand_mi)
		_hand_drawn = true
		_hand_mi.transform = Transform3D(bas.scaled(Vector3.ONE * hl), base)
		var mat := _hand_mi.material_override as ShaderMaterial
		mat.set_shader_parameter("tt", t)
		mat.set_shader_parameter("intensity", 1.0)
		mat.set_shader_parameter("fade", fade)
		mat.set_shader_parameter("seed", 3.0)
	var pulse := 1.0 + 0.06 * sin(t * 22.0)
	var inten := 1.0 - fade * 0.3
	# tongues of flame licking from the wrist, the knuckles and the fingertip
	_flame(base - f * (0.05 * hl), 0.5 * hl, inten, _roll_for(-f + up * 0.6), fade, 0.0, 15.0)
	_flame(tip + f * (0.05 * hl), 0.34 * hl * pulse, inten, _roll_for(f + up * 0.6), fade, 0.0, 31.0)
	if fade < 0.9 and _px_chance(0.35 * (1.0 - fade)):
		var q := base + f * (_rng.randf_range(0.1, 0.9) * hl) + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.1, 0.4), _rng.randf_range(-0.3, 0.3)) * hl
		_spawn_pt("flame", q, Vector3(0.0, _rng.randf_range(1.0, 2.2), 0.0), 0.5 + _rng.randf() * 0.3, 0.2 * hl, 0.0, 0.94, true)
	if fade < 0.9 and _px_chance(2.0 * (1.0 - fade)):
		_spawn_pt("spark", tip, Vector3(_rng.randf_range(-1.2, 1.2), _rng.randf_range(2.0, 4.0), _rng.randf_range(-1.2, 1.2)), 0.4, 0.08 * hl, 0.0, 0.97)


# --- TRAVEL: bullet, three spark rings, trail of flames that become ash -------------------------


func _travel_draw() -> void:
	if _rel_t0 < 0.0:
		_rel_t0 = t
	var rel := t - _rel_t0
	if not _had_hand:
		_hand(1.0, 1.0, 0.0)  # a shot with no held wind-up (a counter-attack): only to learn where the fingertip is
	# the hand swings up with its index finger, then vanishes
	var hand_fade := clampf((rel - 0.04) / HAND_FADE, 0.0, 1.0)
	if hand_fade < 1.0:
		_hand(1.0, hand_fade, HAND_PITCH * _ease_out(clampf(rel / HAND_PITCH_T, 0.0, 1.0)))
	var start := _tip0
	var end := dst
	if not _muzzled:
		_muzzled = true
		_muzzle(start, (end - start).normalized())
	if rel <= _dt * 1.5 or _axis0 == Vector3.FORWARD:
		_axis0 = (end - start).normalized()
	var p := clampf(ext_p, 0.0, 1.0)
	var bpos := start.lerp(end, p)
	var ku := 0.6 * clampf(_dist_k(bpos), 1.0, 2.0) * (1.2 if big else 1.0)
	if not _ended and not ext_returning:
		var axis := (end - bpos).normalized() if end.distance_to(bpos) > 0.05 else _axis0
		_bullet(bpos, axis, t * 30.0, ku)
		for i in 2:
			if _px_chance(0.8):
				_spawn_pt("flame", bpos + Vector3(_rng.randf_range(-0.15, 0.15), _rng.randf_range(-0.15, 0.15), _rng.randf_range(-0.15, 0.15)) * ku,
				Vector3(0.0, _rng.randf_range(0.4, 1.4), 0.0) - axis * 1.2, 0.35 + _rng.randf() * 0.25, ku * 0.5, 0.0, 0.92, true)
		if _px_chance(1.2):
			_spawn_pt("spark", bpos, Vector3(_rng.randf_range(-2.0, 2.0), _rng.randf_range(0.0, 2.5), _rng.randf_range(-2.0, 2.0)) - axis * 2.0, 0.3, 0.1 * ku, 0.0, 0.93)
	# Three rings of sparks: they appear a little before the bullet leaves (see _windup_draw), start at its
	# speed, brake hard and keep widening where they are while the bullet leaves them behind (sheet; creator).
	if _ring_t0 < 0.0:
		_ring_t0 = t - rel
		_ring_start = start
	_draw_rings(_ring_start, _axis0 if _axis0 != Vector3.FORWARD else (end - start).normalized(), ku, t - _ring_t0)


func _draw_rings(start: Vector3, axis: Vector3, ku: float, age: float) -> void:
	if _v0 <= 0.0:
		_v0 = clampf(start.distance_to(dst) / 0.55, 12.0, 60.0)
	var td := 0.06
	for i in RING_COUNT:
		var tau := age - float(i) * RING_STAGGER
		if tau < 0.0:
			continue
		var sp := _v0 * td * (1.0 - exp(-minf(tau, RING_DECEL * 4.0) / td))
		var center := start + axis * sp
		var radius := RING_SCALE * ku * (0.4 + 0.85 * _ease_out(clampf(tau / 0.4, 0.0, 1.0)))
		_spark_ring(center, axis, radius, smoothstep(0.25, 0.65, tau), 1.0, float(i) * 13.0)
		if not _ring_sp[i]:
			_ring_sp[i] = true
			_ring_sparks(center, axis, ku)


## Sparks flung outward in the plane of a ring (red / orange, small and fast): the ring reads as sparks.
func _ring_sparks(center: Vector3, axis: Vector3, ku: float) -> void:
	var a1 := axis.cross(Vector3.UP).normalized() if absf(axis.dot(Vector3.UP)) < 0.95 else axis.cross(Vector3.RIGHT).normalized()
	var a2 := axis.cross(a1).normalized()
	for i in 14:
		var ang := float(i) / 14.0 * TAU + _rng.randf() * 0.3
		var d := a1 * cos(ang) + a2 * sin(ang)
		_spawn_pt("spark", center + d * ku * 0.5, d * _rng.randf_range(3.0, 7.0) + axis * _rng.randf_range(-1.0, 1.0), 0.28 + _rng.randf() * 0.2, 0.1 * ku, 0.0, 0.9)


## The release: a short muzzle flash at the fingertip, a cone of flames and smoke thrown along the shot, sparks.
func _muzzle(at: Vector3, axis: Vector3) -> void:
	var k := clampf(_u, 0.8, 3.0)
	VfxLib.flash_star(fx, at, Color(1.0, 0.62, 0.2), 1.4 * k, 0.1)
	VfxLib.flipbook(fx, at + axis * 0.4 * k, "fire", Color(1.0, 0.6, 0.12), 1.9 * k, 0.22, _rng.randf_range(-30.0, 30.0), 1.2)
	VfxLib.flipbook(fx, at, "smoke", Color(0.25, 0.2, 0.2), 1.6 * k, 0.6, 0.0, 0.8, false)
	VfxLib.burst(fx, at, {"amount": 18, "life": 0.4, "speed": Vector2(4.0, 12.0), "dir": axis, "spread": 28.0, "gravity": Vector3(0, -8, 0), "damping": 1.5,
		"size": Vector2(0.08, 0.2), "end_scale": 0.0, "ramp": VfxLib.ramp([Color(1.0, 0.8, 0.35), EMBER, Color(0.9, 0.2, 0.04, 0.0)], [0.0, 0.3, 1.0])})
	for i in 5:
		_spawn_pt("flame", at + axis * _rng.randf_range(0.0, 0.5) * k, axis * _rng.randf_range(2.0, 5.0) + Vector3(0, _rng.randf_range(0.0, 1.0), 0), 0.35 + _rng.randf() * 0.2, 0.55 * k, 0.0, 0.88, true)


# --- IMPACT -----------------------------------------------------------------------------------


func _impact_draw() -> void:
	var kd := clampf(_dist_k(dst), 1.0, 2.6) * (1.2 if big else 1.0)
	if not _fired:
		_fired = true
		_impact_burst(kd)
		if interrupted:
			var cc := Vector3(dst.x, float(_g["cy"]), dst.z)
			var brr := maxf(float(_g["r"]), 0.6) * clampf(kd, 1.0, 1.6)
			for n in 3:
				_ring_sparks(cc, _fwd, brr * 1.8)
		else:
			var back := (-_fwd * RICO_BACK + Vector3.UP * RICO_UP)
			_spawn_pt("bullet", dst, back, 2.0, 0.55 * kd, RICO_GRAVITY, 1.0, false)
	_glow(dst, 5.0 * kd * (1.0 - clampf(t / 0.5, 0.0, 1.0)), 0.9)
	if interrupted and t < 0.8:
		_ring_burst(kd)
	var sk := clampf(t / 1.4, 0.0, 1.0)
	_scorch(Vector3(dst.x, 0.0, dst.z), (1.6 + 0.6 * clampf(t / 0.2, 0.0, 1.0)) * kd * 0.8, smoothstep(0.35, 1.0, sk), 0.9, 3.0)


## The contact: a flash, the game's fire flipbook, embers and sparks, a spark ring on the floor and a little smoke.
func _impact_burst(kd: float) -> void:
	var pos := dst
	var ground := Vector3(pos.x, 0.05, pos.z)
	VfxLib.flash_star(fx, pos, Color(1.0, 0.65, 0.25), 1.8 * kd, 0.12)
	VfxLib.flipbook(fx, pos, "fire", Color(1.0, 0.6, 0.12), 3.6 * kd, 0.34, _rng.randf_range(-25.0, 25.0), 1.4)
	VfxLib.flipbook(fx, pos + Vector3.UP * 0.2, "fire", Color(1.0, 0.42, 0.06), 2.5 * kd, 0.3, _rng.randf_range(60.0, 120.0), 1.1)
	VfxLib.flipbook(fx, pos + Vector3.UP * 0.4, "smoke", Color(0.25, 0.2, 0.2), 2.6 * kd, 0.7, 0.0, 0.8, false)
	VfxLib.burst(fx, pos, {"amount": 34, "life": 0.55, "speed": Vector2(3.0, 11.0), "dir": -_fwd + Vector3.UP * 0.6, "spread": 75.0, "gravity": Vector3(0, -14, 0), "damping": 1.0,
		"size": Vector2(0.1, 0.24), "end_scale": 0.0, "ramp": VfxLib.ramp([Color(1.0, 0.8, 0.35), EMBER, Color(0.9, 0.2, 0.04, 0.0)], [0.0, 0.3, 1.0])})
	for i in 16:
		var ang := float(i) / 16.0 * TAU
		_spawn_pt("spark", ground + Vector3(0, 0.3, 0), Vector3(cos(ang), 0.25, sin(ang)) * _rng.randf_range(3.0, 6.0), 0.4, 0.11 * kd, 0.0, 0.92)
	for i in 8:
		var d := (Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(0.2, 1.0), _rng.randf_range(-1.0, 1.0))).normalized()
		_spawn_pt("flame", pos, d * _rng.randf_range(1.5, 4.0), 0.45 + _rng.randf() * 0.3, 0.65 * kd, 0.0, 0.9, true, 0.3)


## The special impact (the hit interrupted an action of the target): no ricochet, a burst of rings. Rings of
## sparks facing the shot slam outward around the target one after another, a flat ring sweeps across the
## body and another across the floor. The Hit Shake and the push back are done by the hit itself (BattleFx).
func _ring_burst(kd: float) -> void:
	var c := Vector3(dst.x, float(_g["cy"]), dst.z)
	var br := maxf(float(_g["r"]), 0.6) * clampf(kd, 1.0, 1.25)
	for i in 4:
		var tau := t - float(i) * 0.05
		if tau < 0.0:
			continue
		var k := _ease_out(clampf(tau / COCOON, 0.0, 1.0))
		_spark_ring(c - _fwd * (0.1 * float(i)), _fwd, br * (0.35 + 0.95 * k) * (1.0 + 0.1 * float(i)), smoothstep(0.45, 1.0, tau / 0.7), 1.2, float(i) * 11.0, 0.06)
	var k2 := _ease_out(clampf(t / COCOON, 0.0, 1.0))
	_spark_ring(c, Vector3.UP, br * (0.5 + 1.3 * k2), smoothstep(0.45, 1.0, t / 0.7), 1.1, 5.0, 0.055)
	_spark_ring(Vector3(dst.x, 0.06, dst.z), Vector3.UP, br * (0.7 + 1.9 * k2), smoothstep(0.5, 1.0, t / 0.75), 1.0, 9.0, 0.055)


## The ricochet bullet reached the floor: a last puff of embers, sparks and ash.
func _ricochet_lands(p: Vector3) -> void:
	var pos := Vector3(p.x, 0.2, p.z)
	VfxLib.burst(fx, pos, {"amount": 10, "life": 0.35, "speed": Vector2(1.5, 5.0), "dir": Vector3.UP, "spread": 60.0, "gravity": Vector3(0, -10, 0), "damping": 1.0,
		"size": Vector2(0.08, 0.16), "end_scale": 0.0, "ramp": VfxLib.ramp([Color(1.0, 0.8, 0.35), EMBER, Color(0.9, 0.2, 0.04, 0.0)], [0.0, 0.3, 1.0])})
	for i in 3:
		_spawn_pt("flame", pos, Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(0.6, 1.4), _rng.randf_range(-0.6, 0.6)), 0.4 + _rng.randf() * 0.2, 0.32, 0.0, 0.92, true)
