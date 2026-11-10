class_name AbraMoveVfx
extends Node3D
## Abra's move VFX, ported element by element from the HTML prototype v9 (D-170):
## Confusion, Psybeam, Shock Wave and Teleport. One node is one stage of one move:
## WINDUP (lives until the telegraph is cleared), TRAVEL (driven by the projectile phase)
## or IMPACT (self-timed). It only draws and never touches the combat timeline (D-019).
##
## Geometry uses the prototype's own coordinates in a local frame: the caster stands at
## the origin and the target at (0, y, -D) for WINDUP/TRAVEL; for IMPACT the target is the
## origin. Proto y = 0 sits 0.22 above the floor (the prototype's ground is y = -0.22).
## Teleport keeps D-034 (arrival behind the target) and swaps the prism for rising purple
## speed lines, as the creator asked.

enum Stage { WINDUP, TRAVEL, IMPACT }

const RUBY := Color("ff1744")
const MAGENTA := Color("e056fd")
const PINK := Color("ff66b2")
const VIOLET := Color("b666ff")
const ROSE := Color("ff94cc")
const INK := Color("12243a")
const YELLOW := Color("ffea00")
const BURNT := Color("e67e00")
const HOT := Color("fff8d6")
const LAVENDER := Color("dcc2ff")
const PAL := {
	"ruby": Color("ff1744"), "pink": Color("ff66b2"), "violet": Color("b666ff"), "magenta": Color("e056fd"),
	"ink": Color("12243a"), "deepPurple": Color("2a1642"), "white": Color("f4ecda"), "rose": Color("ff94cc"),
}
const CONF_BLOCKS := 6  ## cubes of Confusion (wind-up and shot); fewer, larger
const SHOCK_OPACITY := 0.7  ## Shock Wave overall opacity
const SHOCK_SPEED := 1.35  ## Shock Wave after the wind-up plays 35% faster (visual only; the game timeline is untouched)
const PSY_RELEASE := 0.75  ## seconds the Psybeam charge pose takes to expand and fade out after the shot
const PSY_BEAM_FADE := 1.1  ## seconds the Psybeam laser takes to dissipate after it lands
const PSY_AHEAD := 1.45  ## Psybeam crystal, lenses and beam start this much further in front of the caster
const GROUND := 0.22  ## Prototype y = -0.22 is the floor.
const FLOOR_Y := -0.26
const REF_H := 700.0  ## Screen height the prototype's pixel sizes were authored for.
const LIGHT_DIR := Vector3(-0.5, 0.85, 0.48)

class Pt:
	var p := Vector3.ZERO
	var v := Vector3.ZERO
	var drag := 0.96
	var gravity := 0.0
	var swirl := 0.0
	var swirl_c := Vector3.ZERO
	var orbit := false
	var o_c := Vector3.ZERO
	var o_r := 0.0
	var o_a := 0.0
	var o_s := 0.0
	var o_l := 0.0
	var turb := 0.0
	var life := 0.0
	var max_life := 0.65
	var size := 0.18
	var alpha_scale := 1.0
	var stretch := 0.0
	var mode := "trail"
	var sprite := ""
	var color := Color.WHITE
	var core := Color.WHITE
	var bounce := false
	var seed_ := 0.0
	var trail: Array[Vector3] = []
	var max_trail := 7

var fx: BattleFx
var move_id := ""
var stage := Stage.WINDUP
var life := 1.0  ## WINDUP: wind-up length. IMPACT/TRAVEL: seconds until freed.
var span := 1.0  ## IMPACT: seconds the main choreography is scaled to (the game's time, D-170).
var t := 0.0
var src := Vector3.ZERO
var dst := Vector3.ZERO
var ext_p := 0.0
var ext_returning := false
var big := false
var dir := Vector3.FORWARD

var _canvas: AbraCanvas  ## additive glow layer (lines, particles, 2D passes)
var _solid: AbraCanvas  ## alpha-blended solid layer (3D meshes of the prototype)
var _rng := RandomNumberGenerator.new()
var _dt := 0.016
var _D := 30.0
var _frame_basis := Basis.IDENTITY
var _light := Vector3.UP
var _pts: Array[Pt] = []
var _sprites: Array[MeshInstance3D] = []
var _sprite_used := 0
var _storm: Array = []
var _storm_for := ""
var _streaks: Array = []
var _fired := false
var _t_shift := 0.0
var _acy := 1.6  ## caster body centre / top / radius (proto y; measured from the real model)
var _atop := 2.3
var _ar := 0.9
var _tcy := 1.45  ## target body centre / top / radius
var _ttop := 2.3
var _tr := 0.9
var held := false  ## wind-up over, waiting for the move to leave (the charge stays at full strength)
var _keep_windup := false  ## draw the wind-up pose at full charge on top of the flight layer
var _hold_at := 0.0
var _last_blocks: Array[Vector3] = []
var _last_tess := Vector3.ZERO
var _w_mul := 1.0
var _op := 1.0  ## overall opacity of the move (Shock Wave: 70%, creator's order)
var _bolts: Array[MeshInstance3D] = []  ## lightning-shader quads (Shock Wave)
var _bolt_used := 0
var _beams: Array[MeshInstance3D] = []  ## laser quads (Psybeam)
var _beam_used := 0
var _hexes: Array[MeshInstance3D] = []  ## spinning hexagon plates (Psybeam impact)
var _hex_used := 0
var _psy_rel := 0.0  ## 0..1: the Psybeam charge pose expanding and fading after the shot (PSY_RELEASE)
var _psy_t0 := -1.0
var _beam_fade_t0 := -1.0
var _rings: Array[MeshInstance3D] = []  ## flat shock rings (`ring` shader)
var _ring_used := 0
var _cloud: Array[MeshInstance3D] = []  ## smoke-flipbook storm cloud puffs
var _crackle: Array = []
var _crackle_left := 0.0  ## width multiplier for 2D-pass bolts (the prototype is thin at game distance)

static var _tex_cache: Dictionary = {}
static var _held: Dictionary = {}  ## attacker -> wind-up layer waiting to become the shot


# --- Factories ----------------------------------------------------------------------


static func windup(p_fx: BattleFx, p_move: String, p_src: Vector3, p_dst: Vector3, duration: float) -> AbraMoveVfx:
	return _spawn(p_fx, p_move, Stage.WINDUP, p_src, p_dst, maxf(duration, 0.05), 1.0, false, Vector3.FORWARD)


static func travel(p_fx: BattleFx, p_move: String, p_from: Vector3, p_to: Vector3) -> AbraMoveVfx:
	return _spawn(p_fx, p_move, Stage.TRAVEL, p_from, p_to, INF, 1.0, false, Vector3.FORWARD)


static func impact(p_fx: BattleFx, p_move: String, pos: Vector3, p_big: bool, p_dir := Vector3.FORWARD) -> AbraMoveVfx:
	var p_span := 1.1
	var p_life := 1.4
	match p_move:
		"raio_psiquico":
			p_span = 0.75
			p_life = 1.15
		"onda_choque":
			p_span = 1.0
			p_life = 1.0
		"teleporte_rapido":
			p_span = 0.7
			p_life = 1.1
	return _spawn(p_fx, p_move, Stage.IMPACT, pos, pos, p_life, p_span, p_big, p_dir)


static func _spawn(p_fx: BattleFx, p_move: String, p_stage: Stage, p_src: Vector3, p_dst: Vector3, p_life: float, p_span: float, p_big: bool, p_dir: Vector3) -> AbraMoveVfx:
	var v := AbraMoveVfx.new()
	v.name = "Abra%s%s" % [p_move.capitalize().replace(" ", ""), Stage.keys()[p_stage].capitalize()]
	v.fx = p_fx
	v.move_id = p_move
	v.stage = p_stage
	v.src = p_src
	v.dst = p_dst
	v.life = p_life
	v.span = p_span
	v.big = p_big
	if p_dir.length_squared() > 0.001:
		v.dir = p_dir.normalized()
	p_fx.add_child(v)
	return v


## The wind-up ends but the energy stays (Confusion): it holds full charge until the shot leaves.
func hold(attacker: Object) -> bool:
	if not (move_id in ["confusao", "raio_psiquico", "onda_choque", "teleporte_rapido"]) or stage != Stage.WINDUP:
		return false
	held = true
	_hold_at = t
	_held[attacker] = self
	return true


## Teleport: the arrival seal and charge stay until Abra appears behind the target.
static func release_held(attacker: Object) -> void:
	var n: Variant = _held.get(attacker)
	_held.erase(attacker)
	if is_instance_valid(n):
		(n as AbraMoveVfx).queue_free()


static func take_held(attacker: Object) -> AbraMoveVfx:
	var n: Variant = _held.get(attacker)
	_held.erase(attacker)
	return n as AbraMoveVfx if is_instance_valid(n) else null


## The shot leaves: the held wind-up node turns into the flight layer (same cubes, same Tesseract).
func launch(p_from: Vector3, p_to: Vector3) -> void:
	held = false
	stage = Stage.TRAVEL
	life = INF
	_fired = false
	_keep_windup = move_id != "confusao"  # Psybeam / Shock Wave keep their charge drawn under the flight
	set_travel(p_from, p_to, 0.0, false)


func set_travel(p_from: Vector3, p_to: Vector3, progress: float, returning: bool) -> void:
	src = p_from
	dst = p_to
	ext_p = progress
	ext_returning = returning


# --- Lifecycle -----------------------------------------------------------------------


func _ready() -> void:
	_rng.randomize()
	_op = SHOCK_OPACITY if move_id == "onda_choque" else 1.0
	_solid = AbraCanvas.new(false)
	_solid.name = "SolidCanvas"
	_solid.energy = 1.0
	add_child(_solid)
	_canvas = AbraCanvas.new(true)
	_canvas.name = "NeonCanvas"
	_canvas.energy = 1.0
	add_child(_canvas)
	_update_frame()
	_probe_bodies()
	if stage == Stage.IMPACT:
		_setup_impact()
		_world_extras()
	elif stage == Stage.WINDUP and move_id == "teleporte_rapido":
		_teleport_windup_world()


func _process(delta: float) -> void:
	if move_id == "onda_choque" and stage != Stage.WINDUP:
		delta *= SHOCK_SPEED
	_dt = delta
	t += delta
	_update_frame()
	if held and t - _hold_at > 6.0:
		queue_free()  # the shot never came (safety)
		return
	_canvas.clear()
	_solid.clear()
	_sprite_used = 0
	_bolt_used = 0
	_ring_used = 0
	_beam_used = 0
	_hex_used = 0
	for c in _cloud:
		c.visible = false
	match stage:
		Stage.WINDUP:
			match move_id:
				"confusao": _confusion_windup()
				"raio_psiquico": _psybeam_windup()
				"onda_choque": _shock_windup()
				"teleporte_rapido": _teleport_windup()
		Stage.TRAVEL:
			match move_id:
				"confusao": _confusion_travel()
				"raio_psiquico": _psybeam_travel()
				"onda_choque": _shock_travel()
		Stage.IMPACT:
			match move_id:
				"confusao": _confusion_impact()
				"raio_psiquico": _psybeam_impact()
				"onda_choque": _shock_impact()
				"teleporte_rapido": _teleport_impact()
	_particles_update(delta)
	_particles_draw()
	_solid.flush()
	_canvas.flush()
	for i in range(_sprite_used, _sprites.size()):
		_sprites[i].visible = false
	for i in range(_bolt_used, _bolts.size()):
		_bolts[i].visible = false
	for i in range(_beam_used, _beams.size()):
		_beams[i].visible = false
	for i in range(_hex_used, _hexes.size()):
		_hexes[i].visible = false
	for i in range(_ring_used, _rings.size()):
		_rings[i].visible = false
	if stage == Stage.IMPACT and t >= life:
		queue_free()


## Local frame: -Z points from the caster to the target; origin on the floor + GROUND.
## Measures the real caster and target models so effects sit on their bodies, not on proto constants.
func _probe_bodies() -> void:
	var a := _body_at(src) if stage != Stage.IMPACT else {}
	var t := _body_at(dst)
	if not a.is_empty():
		_acy = a["cy"]
		_atop = a["top"]
		_ar = a["r"]
	if not t.is_empty():
		_tcy = t["cy"]
		_ttop = t["top"]
		_tr = t["r"]


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
	if best.has_meta("abra_body"):
		return best.get_meta("abra_body")
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
	var info := {"cy": box.get_center().y - GROUND, "top": box.end.y - GROUND, "r": clampf(minf(box.size.x, box.size.z) * 0.5, 0.5, 3.0)}
	best.set_meta("abra_body", info)
	return info


func _wp() -> float:
	return 1.0 if (held or _keep_windup) else clampf(t / life, 0.0, 1.0)


func _update_frame() -> void:
	var origin := Vector3.ZERO
	var fwd := Vector3.FORWARD
	if stage == Stage.IMPACT:
		origin = Vector3(dst.x, 0.0, dst.z)
		fwd = Vector3(dir.x, 0.0, dir.z)
	else:
		origin = Vector3(src.x, 0.0, src.z)
		fwd = Vector3(dst.x - src.x, 0.0, dst.z - src.z)
		_D = maxf(fwd.length(), 1.0)
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var yaw := atan2(-fwd.x, -fwd.z)
	_frame_basis = Basis(Vector3.UP, yaw)
	global_transform = Transform3D(_frame_basis, origin + Vector3(0, GROUND, 0))
	_light = (_frame_basis.inverse() * LIGHT_DIR).normalized()


# --- Camera / screen-space helpers ---------------------------------------------------


func _cam() -> Camera3D:
	if fx != null and fx.cam != null and fx.cam.camera != null:
		return fx.cam.camera
	return null


func _cam_pos() -> Vector3:
	return fx._cam_pos() if fx != null else Vector3(0, 3, 8)


func _f_px() -> float:
	var c := _cam()
	var fov := c.fov if c != null else 47.0
	return REF_H / (2.0 * tan(deg_to_rad(fov) * 0.5))


func _depth(lp: Vector3) -> float:
	return maxf((to_global(lp) - _cam_pos()).length(), 1.0)


## World units per prototype pixel at local point lp.
func _pxw(lp: Vector3) -> float:
	return _depth(lp) / _f_px()


func _scr_axes() -> Array:
	var cb := Basis.IDENTITY
	var c := _cam()
	if c != null:
		cb = c.global_transform.basis
	var inv := global_transform.basis.inverse()
	return [inv * cb.x, inv * cb.y]


## lp displaced on screen by (dx, dy) prototype pixels (y grows downwards).
func _scr(lp: Vector3, dx: float, dy: float) -> Vector3:
	var ax := _scr_axes()
	return lp + ((ax[0] as Vector3) * dx - (ax[1] as Vector3) * dy) * _pxw(lp)


func _R(key: String, light := 1.1, a := 1.0) -> Color:
	var c: Color = PAL.get(key, Color.WHITE)
	return Color(clampf(c.r * light, 0.0, 1.0), clampf(c.g * light, 0.0, 1.0), clampf(c.b * light, 0.0, 1.0), a)


func _px_chance(p: float) -> bool:
	return _rng.randf() < p * _dt * 60.0


static func _ease_io(x: float) -> float:
	return 4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0


static func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


static func _bezier(p0: Vector3, p1: Vector3, p2: Vector3, f: float) -> Vector3:
	var u := 1.0 - f
	return p0 * (u * u) + p1 * (2.0 * u * f) + p2 * (f * f)


static func _hex(s: String) -> Color:
	return Color(s)


# --- Prototype 3D primitives (solid layer) -------------------------------------------


func _ribbon(a: Vector3, b: Vector3, thick: float, key: String, alpha: float, wire := Color(0, 0, 0, 0)) -> void:
	if alpha <= 0.01 or a.distance_to(b) < 0.02:
		return
	_solid.line(a, b, thick, _R(key, 1.1, alpha))
	if wire.a > 0.0:
		_solid.line(a, b, thick * 0.45, Color(wire.r, wire.g, wire.b, alpha * 0.9))


func _gimbal(c: Vector3, r: float, angles: Vector3, key: String, alpha: float, segs: int, thick: float, wire := Color(0, 0, 0, 0)) -> void:
	if alpha <= 0.01 or r <= 0.05:
		return
	for i in segs:
		var a1 := float(i) / float(segs) * TAU
		var a2 := float(i + 1) / float(segs) * TAU
		var l1 := AbraCanvas.rot(Vector3(cos(a1) * r, 0, sin(a1) * r), angles)
		var l2 := AbraCanvas.rot(Vector3(cos(a2) * r, 0, sin(a2) * r), angles)
		_ribbon(c + l1, c + l2, thick, key, alpha, wire)


func _ring(c: Vector3, r: float, key: String, alpha: float, segs := 30, thick := 0.05) -> void:
	_gimbal(c, r, Vector3.ZERO, key, alpha, segs, thick)


## Box with flat-lit faces and a wire frame (the prototype's `draw('box', ...)`).
func _box(c: Vector3, size: Vector3, rotv: Vector3, key: String, alpha: float, emit: float, wire: Color) -> void:
	if alpha <= 0.01:
		return
	var vs: Array[Vector3] = []
	for i in 8:
		var v := Vector3(0.5 if (i & 1) != 0 else -0.5, 0.5 if (i & 2) != 0 else -0.5, 0.5 if (i & 4) != 0 else -0.5)
		vs.append(c + AbraCanvas.rot(v * size, rotv))
	var faces := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 2, 6, 4], [1, 5, 7, 3], [2, 3, 7, 6], [0, 4, 5, 1]]
	var cam_l := to_local(_cam_pos())
	for f in faces:
		var a := vs[f[0]]
		var b := vs[f[1]]
		var d := vs[f[2]]
		var n := (b - a).cross(d - a).normalized()
		if n.dot(cam_l - a) < 0.0:
			n = -n
		var lit := 0.68 + maxf(-0.4, n.dot(_light)) * 0.36 + emit * 0.42
		var col := _R(key, lit, alpha)
		_solid.tri(vs[f[0]], vs[f[1]], vs[f[2]], col)
		_solid.tri(vs[f[0]], vs[f[2]], vs[f[3]], col)
	if wire.a > 0.0:
		var w := Color(wire.r, wire.g, wire.b, alpha)
		for e in AbraCanvas._edges(3):
			_canvas.line(vs[e[0]], vs[e[1]], 0.022, w)


static var _ruby_v: Array[Vector3] = []
static var _ruby_f: Array = []


static func _ruby_mesh() -> void:
	if not _ruby_v.is_empty():
		return
	_ruby_v.append(Vector3(0, 0.78, 0))
	_ruby_v.append(Vector3(0, -0.78, 0))
	for i in 6:
		var a := float(i) * TAU / 6.0
		_ruby_v.append(Vector3(cos(a) * 0.48, 0.22, sin(a) * 0.48))
	for i in 6:
		var a := (float(i) + 0.5) * TAU / 6.0
		_ruby_v.append(Vector3(cos(a) * 0.48, -0.22, sin(a) * 0.48))
	for i in 6:
		var u1 := 2 + i
		var u2 := 2 + (i + 1) % 6
		var l1 := 8 + i
		var l2 := 8 + (i + 1) % 6
		_ruby_f.append([0, u1, u2])
		_ruby_f.append([1, l2, l1])
		_ruby_f.append([u1, l1, u2])
		_ruby_f.append([u2, l1, l2])


## Ruby crystal (hexagonal bipyramid) with a wire frame.
func _ruby(c: Vector3, size: Vector3, rotv: Vector3, key: String, alpha: float, emit: float, wire: Color) -> void:
	if alpha <= 0.01:
		return
	_ruby_mesh()
	var vs: Array[Vector3] = []
	for v in _ruby_v:
		vs.append(c + AbraCanvas.rot(v * size, rotv))
	var cam_l := to_local(_cam_pos())
	for f in _ruby_f:
		var a := vs[f[0]]
		var b := vs[f[1]]
		var d := vs[f[2]]
		var n := (b - a).cross(d - a).normalized()
		if n.dot(cam_l - a) < 0.0:
			n = -n
		var lit := 0.68 + maxf(-0.4, n.dot(_light)) * 0.36 + emit * 0.42
		_solid.tri(a, b, d, _R(key, lit, alpha))
		if wire.a > 0.0:
			var w := Color(wire.r, wire.g, wire.b, alpha)
			_canvas.line(a, b, 0.02, w)
			_canvas.line(b, d, 0.02, w)
			_canvas.line(d, a, 0.02, w)


## Sphere / dark slab as a screen-facing disc of ink (used for the Teleport blast).
func _tess(c: Vector3, scale: float, tt: float, alpha: float, key_outer: String, key_inner: String) -> void:
	if alpha <= 0.02:
		return
	var c_xw := cos(tt * 2.2)
	var s_xw := sin(tt * 2.2)
	var c_yw := cos(tt * 1.7)
	var s_yw := sin(tt * 1.7)
	var c_zw := cos(tt * 2.9)
	var s_zw := sin(tt * 2.9)
	var c_xy := cos(tt * 1.3)
	var s_xy := sin(tt * 1.3)
	var pts: Array[Vector3] = []
	var ws: Array[float] = []
	for i in 16:
		var x := 1.0 if (i & 1) != 0 else -1.0
		var y := 1.0 if (i & 2) != 0 else -1.0
		var z := 1.0 if (i & 4) != 0 else -1.0
		var w := 1.0 if (i & 8) != 0 else -1.0
		var nx := x * c_xw - w * s_xw
		w = x * s_xw + w * c_xw
		x = nx
		var ny := y * c_yw - w * s_yw
		w = y * s_yw + w * c_yw
		y = ny
		var nz := z * c_zw - w * s_zw
		w = z * s_zw + w * c_zw
		z = nz
		var nx2 := x * c_xy - y * s_xy
		y = x * s_xy + y * c_xy
		x = nx2
		var persp := 1.0 / (2.35 - w * 0.65)
		pts.append(c + Vector3(x, y, z) * scale * persp)
		ws.append(w)
	for e in AbraCanvas._edges(4):
		var inner: bool = ws[e[0]] + ws[e[1]] > 0.0
		_ribbon(pts[e[0]], pts[e[1]], 0.075 if inner else 0.045, key_outer if inner else key_inner, alpha * (0.95 if inner else 0.68), Color("ffd1fb") if inner else Color(0, 0, 0, 0))


func _gluon(pa: Vector3, pb: Vector3, tt: float, seed_: float, key: String, wire: Color, alpha: float) -> void:
	var prev := pa
	for s in range(1, 8):
		var f := float(s) / 7.0
		var env := sin(f * PI)
		var w1 := sin(f * PI * 3.0 + tt * 18.0 + seed_) * 0.24 * env
		var w2 := cos(f * PI * 3.0 - tt * 16.0 + seed_) * 0.24 * env
		var cur := Vector3(lerpf(pa.x, pb.x, f) + w1, lerpf(pa.y, pb.y, f) + w2, lerpf(pa.z, pb.z, f) - w1 * 0.5)
		_ribbon(prev, cur, 0.065 * (0.6 + env * 0.6), key, alpha, wire)
		prev = cur


# --- Prototype 2D post pass (glows, flares, spirals, bolts) as screen-facing additive ---


static func _make_radial(stops: Array, spikes: bool, size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := float(size) * 0.5
	for y in size:
		for x in size:
			var px := float(x) + 0.5 - half
			var py := float(y) + 0.5 - half
			var r := Vector2(px, py).length() / half
			var col := Color(0, 0, 0, 0)
			if r <= 1.0:
				col = (stops[stops.size() - 1] as Array)[1]
				for i in stops.size() - 1:
					var s0: Array = stops[i]
					var s1: Array = stops[i + 1]
					if r <= float(s1[0]):
						var k := clampf((r - float(s0[0])) / maxf(float(s1[0]) - float(s0[0]), 0.0001), 0.0, 1.0)
						col = (s0[1] as Color).lerp(s1[1] as Color, k)
						break
				if r < float(stops[0][0]):
					col = stops[0][1]
			if spikes:
				for axis in 2:
					var u := (px if axis == 0 else py) / half
					var v := (py if axis == 0 else px) / (float(size) * 0.045)
					var ell := (u / 0.96) * (u / 0.96) + v * v
					if ell <= 1.0:
						var g := clampf((u + 1.0) * 0.5, 0.0, 1.0)
						var a := 0.0
						if g < 0.42:
							a = g / 0.42 * 0.9
						elif g < 0.5:
							a = 0.9 + (g - 0.42) / 0.08 * 0.1
						elif g < 0.58:
							a = 1.0 - (g - 0.5) / 0.08 * 0.1
						else:
							a = 0.9 * (1.0 - (g - 0.58) / 0.42)
						var sc := Color.WHITE.lerp(stops[1][1] as Color, 1.0 - a)
						sc.a = a
						col = Color(maxf(col.r, sc.r * a), maxf(col.g, sc.g * a), maxf(col.b, sc.b * a), maxf(col.a, a))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func _tex_glow(inner: Color, outer: Color) -> ImageTexture:
	var key := "glow%s%s" % [inner.to_html(true), outer.to_html(true)]
	if not _tex_cache.has(key):
		_tex_cache[key] = _make_radial([[0.04, inner], [0.42, outer], [1.0, Color(outer, 0.0)]], false, 64)
	return _tex_cache[key]


static func _tex_star(name: String) -> ImageTexture:
	if not _tex_cache.has(name):
		var stops: Array = []
		match name:
			"starYellow":
				stops = [[0.0, Color(1, 1, 1, 1)], [0.20, Color("ffea00", 0.95)], [0.5, Color("ffa000", 0.35)], [1.0, Color("ff5a00", 0.0)]]
			"starAmber":
				stops = [[0.0, Color("fffadc", 1.0)], [0.22, Color("e67e00", 0.95)], [0.52, Color("b85d00", 0.40)], [1.0, Color("642300", 0.0)]]
			"glowYellow":
				stops = [[0.0, Color(1, 1, 1, 1)], [0.25, Color("fff58c", 0.95)], [0.58, Color("ffc800", 0.5)], [1.0, Color("ff7800", 0.0)]]
			_:
				stops = [[0.0, Color("fff8d2", 1.0)], [0.24, Color("ffaa00", 0.92)], [0.58, Color("d25f00", 0.52)], [1.0, Color("782800", 0.0)]]
		_tex_cache[name] = _make_radial(stops, name.begins_with("star"), 64)
	return _tex_cache[name]


static func _tex_flare(core: bool) -> ImageTexture:
	var key := "flare_core" if core else "flare_h"
	if not _tex_cache.has(key):
		var w := 128
		var h := 128
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var u := (float(x) + 0.5) / float(w) * 2.0 - 1.0
				var v := (float(y) + 0.5) / float(h) * 2.0 - 1.0
				var a := 0.0
				if u * u + v * v <= 1.0:
					if core:
						a = maxf(0.0, 1.0 - absf(v))
					else:
						var g := (u + 1.0) * 0.5
						a = clampf(g / 0.35, 0.0, 1.0) if g < 0.5 else clampf((1.0 - g) / 0.35, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_tex_cache[key] = ImageTexture.create_from_image(img)
	return _tex_cache[key]


func _sprite(tex: Texture2D, lp: Vector3, w: float, h: float, color: Color) -> void:
	if color.a <= 0.01 or w <= 0.001:
		return
	color.a *= _op
	if _sprite_used >= _sprites.size():
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		mi.mesh = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.billboard_keep_scale = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_sprites.append(mi)
	var node := _sprites[_sprite_used]
	_sprite_used += 1
	node.visible = true
	node.position = lp
	node.scale = Vector3(w, h, 1.0)
	var mat := node.material_override as StandardMaterial3D
	mat.albedo_texture = tex
	mat.albedo_color = color


## drawLocalizedGlow: radial blob, radius in prototype pixels.
func _blob(lp: Vector3, radius_px: float, inner: Color, outer: Color, alpha: float) -> void:
	if alpha <= 0.01 or radius_px <= 1.0:
		return
	var r := radius_px * _pxw(lp)
	_sprite(_tex_glow(inner, outer), lp, r * 2.0, r * 2.0, Color(1, 1, 1, clampf(alpha * _op, 0.0, 1.0)))


## drawAnamorphicFlare: horizontal streak with a vertical core.
func _flare(lp: Vector3, w_px: float, h_px: float, main: Color, alpha: float) -> void:
	if alpha <= 0.01 or w_px <= 1.0:
		return
	var k := _pxw(lp)
	var a := clampf(alpha * _op, 0.0, 1.0)
	_sprite(_tex_flare(false), lp, w_px * 2.0 * k, h_px * 2.0 * k, Color(main.r, main.g, main.b, a))
	_sprite(_tex_flare(false), lp, w_px * 2.0 * k * 0.55, h_px * 2.0 * k, Color(1, 1, 1, a))
	_sprite(_tex_flare(true), lp, h_px * 2.8 * k, h_px * 9.0 * k, Color(1, 1, 1, a))


func _scr_line(lp: Vector3, pts_px: Array, width_px: float, col: Color) -> void:
	var out := PackedVector3Array()
	for p in pts_px:
		out.append(_scr(lp, (p as Vector2).x, (p as Vector2).y))
	_canvas.polyline(out, width_px * _pxw(lp), col)


## drawQuarkBubbleSpirals.
func _spirals(lp: Vector3, scale_px: float, tt: float, alpha: float, c1: Color, c2: Color) -> void:
	if alpha <= 0.02:
		return
	for b in 3:
		var base_rot := tt * (3.2 if b % 2 == 1 else -3.2) + float(b) * 2.094
		var pts: Array = []
		for s in 29:
			var u := float(s) / 28.0
			var ang := base_rot + u * PI * 3.5
			var r := (1.0 - u) * scale_px
			pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.65))
		_scr_line(lp, pts, 1.8, Color(c1 if b % 2 == 0 else c2, alpha))


func _scr_ellipse(lp: Vector3, rx: float, ry: float, width_px: float, col: Color) -> void:
	var pts: Array = []
	for i in 41:
		var a := float(i) / 40.0 * TAU
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	_scr_line(lp, pts, width_px, col)


## drawRealLightningBolt2D (bolt points are local-frame 3D points).
func _bolt2d(pts: Array, outer: Color, mid: Color, core: Color, base_w: float, alpha: float, taper := false) -> void:
	if alpha <= 0.01 or pts.size() < 2:
		return
	var mid_pt: Vector3 = pts[int(pts.size() * 0.5)]
	var depth := _depth(mid_pt)
	var scale_d := clampf(18.0 / maxf(6.0, depth), 0.45, 2.2)
	var w := base_w * _w_mul * scale_d * (depth / _f_px())
	var arr := PackedVector3Array()
	for p in pts:
		arr.append(p as Vector3)
	if not taper:
		_canvas.polyline(arr, w * 3.4, Color(outer, minf(alpha * 0.75, 1.0)))
		_canvas.polyline(arr, w * 1.7, Color(mid, minf(alpha, 1.0)))
		_canvas.polyline(arr, w * 0.30, Color(core, minf(alpha, 1.0)))
	else:
		var n := arr.size()
		for i in n - 1:
			var f := 1.0 - float(i) / float(n - 1) * 0.82
			var seg_w := maxf(0.5 * depth / _f_px(), w * f)
			var a := arr[i]
			var b := arr[i + 1]
			_canvas.line(a, b, seg_w * 3.0, Color(outer, minf(alpha * 0.75 * f, 1.0)))
			_canvas.line(a, b, seg_w * 1.5, Color(mid, minf(alpha * f, 1.0)))
			_canvas.line(a, b, seg_w * 0.30, Color(core, minf(alpha * f, 1.0)))


## drawPerspectiveElectricWave2D.
func _wave2d(c: Vector3, radius: float, outer: Color, mid: Color, alpha: float, ripple: float, tphase: float) -> void:
	if alpha <= 0.01 or radius <= 0.05:
		return
	var pts: Array = []
	for i in 57:
		var a := float(i) / 56.0 * TAU
		var wr := radius + sin(a * 10.0 + tphase) * ripple * 0.45 + (_rng.randf() - 0.5) * ripple
		var wy := c.y + (_rng.randf() - 0.5) * ripple * 0.35
		pts.append(Vector3(c.x + cos(a) * wr, wy, c.z + sin(a) * wr))
	_bolt2d(pts, outer, mid, Color.WHITE, 4.5, alpha, false)


static func _subdivide(pa: Vector3, pb: Vector3, gens: int, jitter: float, rng: RandomNumberGenerator) -> Array:
	var pts: Array = [pa, pb]
	var cur := jitter
	for g in gens:
		var nxt: Array = [pts[0]]
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			nxt.append(Vector3((a.x + b.x) * 0.5 + (rng.randf() - 0.5) * cur, (a.y + b.y) * 0.5 + (rng.randf() - 0.5) * cur * 0.45, (a.z + b.z) * 0.5 + (rng.randf() - 0.5) * cur))
			nxt.append(b)
		pts = nxt
		cur *= 0.52
	return pts


# --- Particle engine (Quarks) ---------------------------------------------------------


func _spawn_pt(o: Dictionary) -> void:
	if _pts.size() > 650:
		_pts.remove_at(0)
	var p := Pt.new()
	p.p = o.get("p", Vector3.ZERO)
	p.v = o.get("v", Vector3.ZERO)
	p.drag = o.get("drag", 0.96)
	p.gravity = o.get("gravity", 0.0)
	p.swirl = o.get("swirl", 0.0)
	p.swirl_c = o.get("swirl_c", Vector3.ZERO)
	if o.has("orbit_c"):
		p.orbit = true
		p.o_c = o["orbit_c"]
		p.o_r = o["orbit_r"]
		p.o_a = o["orbit_a"]
		p.o_s = o["orbit_s"]
		p.o_l = o["orbit_l"]
	p.turb = o.get("turb", 0.0)
	p.max_life = o.get("life", 0.65)
	p.size = o.get("size", 0.18)
	p.alpha_scale = o.get("alpha", 1.0)
	p.stretch = o.get("stretch", 0.0)
	p.mode = o.get("mode", "trail")
	p.sprite = o.get("sprite", "")
	p.color = o.get("color", RUBY)
	p.core = o.get("core", Color.WHITE)
	p.bounce = o.get("bounce", false)
	p.seed_ = _rng.randf() * 100.0
	p.max_trail = o.get("max_trail", 7)
	p.trail = [p.p]
	_pts.append(p)


func _particles_update(dt: float) -> void:
	if dt <= 0.0:
		return
	for i in range(_pts.size() - 1, -1, -1):
		var p := _pts[i]
		p.life += dt
		if p.life >= p.max_life:
			_pts.remove_at(i)
			continue
		if p.orbit:
			var prev := p.p
			p.o_a += p.o_s * dt
			var cur_r := p.o_r * (1.0 + _ease_out(p.life / p.max_life) * 0.22)
			p.p.x = p.o_c.x + cos(p.o_a) * cur_r
			p.p.z = p.o_c.z + sin(p.o_a) * cur_r
			p.p.y += p.o_l * dt
			if p.bounce and p.p.y < -0.24:
				p.p.y = -0.24
				p.o_l = absf(p.o_l) * 0.65
			else:
				p.o_l -= 4.5 * dt
			p.v = (p.p - prev) / maxf(0.001, dt)
		else:
			var f_drag := pow(p.drag, dt * 60.0)
			p.v *= f_drag
			p.v.y -= p.gravity * dt
			if p.turb > 0.0:
				var tn := t * 8.0 + p.seed_
				p.v.x += sin(p.p.y * 1.8 + tn) * p.turb * dt
				p.v.y += cos(p.p.z * 1.8 - tn) * p.turb * 0.6 * dt
				p.v.z += sin(p.p.x * 1.8 + tn * 1.2) * p.turb * dt
			if p.swirl != 0.0:
				var dx := p.p.x - p.swirl_c.x
				var dz := p.p.z - p.swirl_c.z
				var dist := maxf(Vector2(dx, dz).length(), 0.001)
				var tx := -dz / dist
				var tz := dx / dist
				p.v.x += (tx * p.swirl - (dx / dist) * (p.swirl * 0.38)) * dt
				p.v.z += (tz * p.swirl - (dz / dist) * (p.swirl * 0.38)) * dt
			p.p += p.v * dt
			if p.bounce and p.p.y < FLOOR_Y:
				p.p.y = FLOOR_Y
				p.v.y = absf(p.v.y) * (0.48 + _rng.randf() * 0.25)
				p.v.x *= 0.8
				p.v.z *= 0.8
		p.trail.append(p.p)
		if p.trail.size() > p.max_trail:
			p.trail.remove_at(0)


func _particles_draw() -> void:
	var f := _f_px()
	for p in _pts:
		var raw := 1.0 - p.life / p.max_life
		if raw <= 0.0:
			continue
		var ratio := raw * p.alpha_scale * _op
		var depth := _depth(p.p)
		var screen_scale := clampf(p.size * f / depth, 1.5, 28.0)
		var pxw := depth / f
		if p.mode == "star_sprite" and p.sprite != "":
			var sz := screen_scale * 2.4 * sin((1.0 - raw) * PI) * pxw
			_sprite(_tex_star(p.sprite), p.p, sz, sz, Color(1, 1, 1, clampf(ratio / maxf(_op, 0.01), 0.0, 1.0)))
		elif p.mode == "micro_arc":
			var pts := PackedVector3Array([p.p])
			var cur := p.p
			var ax := _scr_axes()
			for s in 3:
				cur += ((ax[0] as Vector3) * (_rng.randf() - 0.5) + (ax[1] as Vector3) * (_rng.randf() - 0.5)) * screen_scale * 1.6 * pxw
				pts.append(cur)
			_canvas.polyline(pts, clampf(screen_scale * 0.28, 1.2, 3.5) * pxw, Color(p.color, ratio * 0.95))
			_canvas.polyline(pts, clampf(screen_scale * 0.12, 0.7, 1.6) * pxw, Color(1, 1, 1, ratio * 0.95))
		elif p.mode == "stretched_billboard":
			var s := p.stretch if p.stretch > 0.0 else 0.045
			var tail := p.p - p.v * s
			_canvas.line(tail, p.p, clampf(screen_scale * 0.52, 1.6, 8.0) * pxw, Color(p.color, ratio * 0.88))
			_canvas.line(tail.lerp(p.p, 0.35), p.p, clampf(screen_scale * 0.22, 0.8, 3.5) * pxw, Color(p.core, ratio))
		elif p.trail.size() > 1:
			var arr := PackedVector3Array()
			for q in p.trail:
				arr.append(q)
			var w := clampf(p.size * f / depth, 1.2, 9.5) * pxw
			_canvas.polyline(arr, w, Color(p.color, ratio * 0.85))
			_canvas.polyline(arr, w * 0.42, Color(p.core, ratio * 0.95))


# --- CONFUSION -----------------------------------------------------------------------


func _confusion_windup() -> void:
	var wp := _wp()
	var we := _ease_io(wp)
	var hero := Vector3.ZERO
	var enemy := Vector3(0, 0, -_D)
	var center_y := _atop + 0.45 + we * 0.5
	_tess(Vector3(0, center_y, 0), 0.95 * we, t, wp * 0.92, "ruby", "violet")
	var blocks: Array[Vector3] = []
	for k in CONF_BLOCKS:
		var layer := k % 3
		var seed_a := float(k) * (TAU / float(CONF_BLOCKS)) + t * (2.4 if k % 2 == 1 else -2.1)
		var orbit_r := (_ar + 0.35 + float(layer) * 0.5) * (0.35 + 0.65 * we)
		var rise := clampf(wp * 1.4 - float(k % 4) * 0.08, 0.0, 1.0)
		var cy := -0.22 + _ease_out(rise) * (0.55 + float(k % 4) * 0.62) * (_atop / 2.3) + sin(t * 5.0 + float(k)) * 0.14
		var sz := (0.24 + float(layer) * 0.11) * 1.35 * minf(1.0, wp * 2.2)
		var pos := Vector3(cos(seed_a) * orbit_r, cy, sin(seed_a) * orbit_r)
		blocks.append(pos)
		var key := "ruby" if k % 3 == 0 else ("ink" if k % 2 == 0 else "deepPurple")
		var wire := Color("ff8a9f") if k % 3 == 0 else (Color("ff66b2") if k % 2 == 0 else Color("d68fff"))
		_box(pos + hero, Vector3.ONE * sz, Vector3(t * 3.2 + float(k), seed_a, t * 2.5 - float(k)), key, 0.92 * minf(1.0, wp * 1.8), 0.95, wire)
	for g in CONF_BLOCKS / 2:
		_gluon(blocks[g * 2], blocks[(g * 2 + 3) % CONF_BLOCKS], t, float(g), "ruby" if g % 2 == 1 else "magenta", Color("ffd1fb"), wp * 0.85)
	_last_blocks = blocks.duplicate()
	_last_tess = Vector3(0, center_y, 0)
	if _px_chance(0.75):
		var ang := _rng.randf() * TAU
		var rad := _ar + 1.0 + _rng.randf() * 1.2
		_spawn_pt({"p": Vector3(cos(ang) * rad, 0.2 + _rng.randf() * 2.4, sin(ang) * rad), "v": Vector3(-cos(ang) * 2.5, 1.4 + _rng.randf() * 1.5, -sin(ang) * 2.5),
			"swirl": 9.5, "swirl_c": Vector3(0, center_y, 0), "life": 0.55, "size": 0.14, "color": RUBY if _rng.randf() < 0.5 else MAGENTA, "core": Color.WHITE, "max_trail": 8})
	if wp > 0.35:
		var tp := (wp - 0.35) / 0.65
		for b in 3:
			var ba := float(b) * (TAU / 3.0) - t * 3.2
			var br := (_tr + 0.3 + float(b % 2) * 0.65) * tp
			var bs := (0.22 + float(b % 3) * 0.08) * tp
			_box(enemy + Vector3(cos(ba) * br, _tcy - 0.5 + tp * 0.5 + sin(t * 6.0 + float(b)) * 0.1, sin(ba) * br), Vector3.ONE * bs, Vector3(t * 4.0, ba, t * 3.0),
				"ruby" if b % 2 == 1 else "ink", tp * 0.9, 0.95, Color("ff8a9f") if b % 2 == 1 else MAGENTA)
	# 2D pass
	var hero_p := Vector3(0, _atop + 0.1, 0)
	_blob(_scr(hero_p, 0, 24), 45.0 + wp * 15.0, RUBY, Color(1.0, 0.09, 0.27, 0.25), wp * 0.16)
	_flare(_scr(hero_p, 0, 18), 55.0 * wp, 2.6, RUBY, wp * 0.30)
	_spirals(_scr(hero_p, 0, 22), 62.0 * wp, t, wp * 0.75, RUBY, MAGENTA)


## The shot itself: muzzle flash, forward-facing shock rings, a cone of sparks (VFX skill: layers).
func _confusion_launch() -> void:
	var aim := Vector3(dst.x - src.x, 0.0, dst.z - src.z)
	aim = aim.normalized() if aim.length() > 0.01 else Vector3.FORWARD
	VfxLib.flash_star(fx, src, Color.WHITE, 3.0, 0.14)
	VfxLib.flash_star(fx, src, RUBY, 3.5, 0.18)
	# One small ring in front of the caster that grows for 0.4 s, facing the shot direction.
	var ring := VfxLib.animated_quad(fx, Vector2(5.0, 5.0), "ring", {"color": Color("ff5a7a"), "energy": 3.6}, 0.4)
	ring.position = src + aim * (_ar + 0.5)
	ring.look_at(ring.position + aim)
	VfxLib.burst(fx, src, {"amount": 40, "life": 0.45, "speed": Vector2(8.0, 22.0), "dir": aim, "spread": 28.0, "damping": 1.0, "size": Vector2(0.14, 0.32), "end_scale": 0.0,
		"ramp": VfxLib.ramp([Color.WHITE, RUBY, Color(MAGENTA, 0.0)], [0.0, 0.3, 1.0])})


func _confusion_travel() -> void:
	if not _fired:
		_fired = true
		_confusion_launch()
	if ext_returning:
		return
	# The wind-up energy IS the shot: the Tesseract and the 16 cubes leave from where they gathered.
	var enemy_c := Vector3(0, _tcy, -_D)
	var starts := _last_blocks
	var blocks_now: Array[Vector3] = []
	for k in CONF_BLOCKS:
		var layer := k % 3
		var lag := float(k) * 0.05
		var head := clampf(ext_p * 1.3 - lag, 0.0, 1.0)
		var sz := (0.24 + float(layer) * 0.11) * 1.35 * 1.4
		var p0: Vector3 = starts[k] if k < starts.size() else Vector3(0, 1.6, 0)
		var side := (float(k) - float(CONF_BLOCKS - 1) * 0.5) * 1.3
		var p1 := Vector3(side, maxf(4.1, _ttop + 1.8) + float(k % 4) * 0.9, -_D * 0.5)
		var p2 := enemy_c + Vector3(cos(float(k) * 1.05) * _tr * 0.6, sin(float(k) * 2.1) * _tr * 0.35, sin(float(k) * 1.05) * _tr * 0.6)
		var cur := _bezier(p0, p1, p2, _ease_io(head))
		if head >= 1.0:
			continue
		blocks_now.append(cur)
		var key := "ruby" if k % 3 == 0 else ("ink" if k % 2 == 0 else "deepPurple")
		var wire := Color("ff8a9f") if k % 3 == 0 else (Color("ff66b2") if k % 2 == 0 else Color("d68fff"))
		_box(cur, Vector3.ONE * sz, Vector3(t * 9.0 + float(k), float(k), t * 7.0), key, 0.96, 0.95, wire)
		_blob(cur, 32.0, Color.WHITE, Color(1.0, 0.09, 0.27, 0.35), 0.28 if head > 0.0 else 0.0)
		if head > 0.0:
			_spawn_pt({"p": cur, "v": Vector3(_rng.randf() - 0.5, _rng.randf() - 0.2, _rng.randf() - 0.5) * 2.0, "life": 0.3, "size": 0.2, "color": RUBY if k % 2 == 0 else MAGENTA, "core": Color.WHITE, "max_trail": 6})
			for s in 5:
				var ta := clampf(head - float(s) * 0.03, 0.0, 1.0)
				var tb := clampf(head - float(s + 1) * 0.03, 0.0, 1.0)
				if ta > tb:
					_ribbon(_bezier(p0, p1, p2, _ease_io(ta)), _bezier(p0, p1, p2, _ease_io(tb)), 0.34 * (1.0 - float(s) / 5.0), "ruby" if k % 3 == 0 else ("magenta" if k % 2 == 1 else "violet"), 0.9 * (1.0 - float(s) / 5.0))
	# Tesseract rides ahead of the cubes and shrinks into the target.
	var te := _ease_io(clampf(ext_p * 1.1, 0.0, 1.0))
	var tess_pos := _last_tess.lerp(enemy_c, te)
	_tess(tess_pos, lerpf(0.95, 0.5, te), t, (1.0 - maxf(0.0, ext_p - 0.8) / 0.2) * 0.92, "ruby", "violet")
	for g in mini(8, blocks_now.size() / 2):
		_gluon(blocks_now[g * 2], blocks_now[(g * 2 + 1) % blocks_now.size()], t, float(g), "ruby" if g % 2 == 1 else "magenta", Color("ffd1fb"), 0.8)


func _confusion_impact() -> void:
	var ep := clampf(t / span, 0.0, 1.0)
	var out := _ease_out(ep)
	var fade := 1.0 if ep < 0.74 else (1.0 - ep) / 0.26
	if ep >= 1.0:
		return
	_ring(Vector3(0, -0.19, 0), maxf(2.15, _tr * 1.4) * sin(ep * PI * 0.88), "ink", 0.95 * fade, 28, 0.42)
	_tess(Vector3(0, _tcy - 0.1 + out * 0.55, 0), 1.25 * fade, t * 1.4, fade * 0.92, "ruby", "magenta")
	_ribbon(Vector3(0, -0.2, 0), Vector3(0, 4.8 * out, 0), 0.42 * fade, "ruby", 0.78 * fade, Color("ffd1fb"))
	var blocks: Array[Vector3] = []
	for k in 20:
		var seed_a := float(k) * (TAU / 20.0) + ep * (2.6 if k % 2 == 1 else -2.6)
		var orbit_r := _tr * 0.8 + float(k % 4) * 0.55 + out * 0.75
		var max_h := 1.1 + float(k % 5) * 0.62
		var cy := -0.25 + _ease_out(clampf(ep * 1.4 - float(k % 4) * 0.05, 0.0, 1.0)) * max_h * (_ttop / 2.3) + sin(t * 4.5 + float(k)) * 0.14
		var sz := (0.28 + float(k % 3) * 0.15) * fade
		var pos := Vector3(cos(seed_a) * orbit_r, cy, sin(seed_a) * orbit_r)
		blocks.append(pos)
		var key := "ruby" if k % 3 == 0 else ("ink" if k % 2 == 0 else "deepPurple")
		var wire := Color("ff8a9f") if k % 3 == 0 else (Color("ff66b2") if k % 2 == 0 else Color("d68fff"))
		_box(pos, Vector3.ONE * sz, Vector3(t * 2.8 + float(k), seed_a, t * 2.0 - float(k)), key, 0.92 * fade, 0.92, wire)
	for g in 8:
		_gluon(blocks[g * 2], blocks[(g * 2 + 5) % 20], t, float(g), "ruby" if g % 2 == 1 else "violet", Color("ffd1fb"), 0.82 * fade)
	for r in 4:
		var rp := clampf((ep - float(r) * 0.10) / 0.72, 0.0, 1.0)
		if rp > 0.0 and rp < 1.0:
			var re := _ease_out(rp)
			var key := "ruby" if r % 3 == 0 else ("magenta" if r % 2 == 0 else "violet")
			_gimbal(Vector3(0, -0.17 + float(r % 2) * re * 1.45, 0), _tr * 0.9 + re * 3.8, Vector3((0.2 if r % 2 == 1 else -0.2) * (1.0 - rp), t * 2.5, 0.0), key, (1.0 - rp) * 0.96, 28, 0.09, Color("ffd1fb"))
	# 2D pass
	var e_sin := sin(ep * PI)
	var ground_p := Vector3(0, 0.1, 0)
	var enemy_p := Vector3(0, _tcy, 0)
	_blob(ground_p, 130.0 * e_sin, Color(1.0, 0.09, 0.27, 0.85), Color("b666ff", 0.45), e_sin * 0.78)
	_flare(enemy_p, 165.0 * e_sin, 4.2, RUBY, e_sin * 0.88)
	_spirals(enemy_p, 88.0 * e_sin, t * 1.5, e_sin * 0.85, RUBY, MAGENTA)
	_scr_ellipse(ground_p, 36.0 + out * 105.0, 16.0 + out * 46.0, 2.6 * (1.0 - ep), Color(RUBY, (1.0 - ep) * 0.9))


# --- PSYBEAM -------------------------------------------------------------------------


func _psybeam_windup() -> void:
	var wp := _wp()
	var fw := 1.0 - _psy_rel  # fades out while it expands after the shot
	var ex := 1.0 + 1.4 * _psy_rel
	if fw <= 0.01:
		return
	var we := _ease_io(wp)
	var hero_c := Vector3(0, _acy + 0.1, 0)
	var enemy_c := Vector3(0, _tcy, -_D)
	var aim := (enemy_c - hero_c).normalized()
	var yaw := atan2(aim.x, aim.z)
	var ruby_pos := hero_c + aim * (_ar + 0.45 + PSY_AHEAD)
	var rs := (0.65 + sin(t * 16.0) * 0.08) * we * (1.0 + 0.5 * _psy_rel)
	_ruby(ruby_pos, Vector3(rs, rs * 1.35, rs), Vector3(t * 2.5, t * 5.5, 0.3), "ruby", 0.96 * fw, 1.0, Color("ffb8d1"))
	_ruby(ruby_pos, Vector3(rs * 0.55, rs * 0.85, rs * 0.55), Vector3(-t * 4.0, -t * 6.0, 0.0), "white", 0.98 * fw, 1.0, Color(0, 0, 0, 0))
	for i in 5:
		var dist := (_ar + 0.6 + PSY_AHEAD + float(i) * 1.0) * we
		var lp := hero_c + aim * dist
		var lens_r := (1.42 - float(i) * 0.15) * we * ex
		var spin := t * (3.6 if i % 2 == 1 else -3.6) + float(i) * 0.7
		var key := "ruby" if (i == 0 or i == 3) else ("magenta" if i % 2 == 1 else "violet")
		var wire := Color("ff8a9f") if (i == 0 or i == 3) else Color("ffd1fb")
		_gimbal(lp, lens_r, Vector3(PI * 0.5, yaw, spin), key, 0.95 * fw, 6, 0.095, wire)
		if i < 2:
			for v in 3:
				var va := spin + float(v) * (TAU / 3.0)
				var voff := AbraCanvas.rot(Vector3(cos(va) * lens_r, sin(va) * lens_r, 0.0), Vector3(0, yaw, 0))
				_ruby(lp + voff, Vector3(0.22, 0.32, 0.22) * we, Vector3(t * 6.0, va, 0.0), "ruby", 0.92 * fw, 1.0, Color.WHITE)
	if _psy_rel <= 0.0 and _px_chance(0.85):
		var a := _rng.randf() * TAU
		var r := 1.8 + _rng.randf() * 1.0
		_spawn_pt({"p": ruby_pos + Vector3(cos(a) * r, (_rng.randf() - 0.5) * 1.8, sin(a) * r), "v": Vector3(-cos(a) * 4.5, 0, -sin(a) * 4.5), "swirl": 11.0, "swirl_c": ruby_pos,
			"life": 0.42, "size": 0.15, "color": RUBY if _rng.randf() < 0.6 else PINK, "core": Color.WHITE, "max_trail": 7})
	_ribbon(ruby_pos, ruby_pos.lerp(enemy_c, we), 0.09 * wp, "ruby", 0.88 * fw, Color("ff8a9f"))
	_gimbal(enemy_c, 2.05 - we * 0.75, Vector3(PI * 0.5, yaw, -t * 4.5), "ruby", wp * 0.94 * fw, 6, 0.085, Color("ffb8d1"))
	# 2D pass
	var hero_p := Vector3(0, _atop + 0.1, 0)
	_blob(_scr(hero_p, 0, 24), 80.0 + wp * 36.0, RUBY, Color(1.0, 0.09, 0.27, 0.42), wp * 0.65 * fw)
	_flare(_scr(hero_p, 0, 18), 95.0 * wp, 3.2, RUBY, wp * 0.72 * fw)
	var enemy_p := Vector3(0, _tcy, -_D)
	_flare(enemy_p, 75.0 * wp, 2.5, RUBY, wp * 0.68 * fw)
	var rr := 56.0 - _ease_out(wp) * 24.0
	for corner in 4:
		var rot_a := PI * 0.5 * float(corner + 1)
		var pts: Array = []
		for q in [Vector2(-rr, -rr + 12), Vector2(-rr, -rr), Vector2(-rr + 12, -rr)]:
			var v := q as Vector2
			pts.append(Vector2(v.x * cos(rot_a) - v.y * sin(rot_a), v.x * sin(rot_a) + v.y * cos(rot_a)))
		_scr_line(enemy_p, pts, 2.2, Color(RUBY, wp * 0.92 * fw))


func _psybeam_ap() -> float:
	return (0.5 * ext_p) if not ext_returning else (0.5 + 0.5 * ext_p)


# Psybeam shot and impact use the game's own systems (D-170, item 19): the laser is a shader quad
# (`abra_beam`), the impact is a ring of spinning shader hexagons (`abra_hexagon`) around the target's
# body plus the impact flipbook, a flash and textured sparks. The charge pose is untouched.


## The game's distance factor at a world point (effects authored for ~12 units read at the camera's distance).
func _dist_k(world_p: Vector3) -> float:
	return fx.vfx_scale_at(world_p) if fx != null and fx.is_inside_tree() else 1.0


## One laser quad from the muzzle `a` (UV.y = 0) to the target `b`, turned to face the camera around its axis.
func _beam(a: Vector3, b: Vector3, width: float, intensity: float, reveal: float, dissolve := 0.0) -> void:
	if intensity <= 0.02 or a.distance_to(b) < 0.1:
		return
	if _beam_used >= _beams.size():
		var made := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		made.mesh = q
		made.material_override = VfxLib.shader_mat("abra_beam", {})
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(made)
		_beams.append(made)
	var mi := _beams[_beam_used]
	_beam_used += 1
	mi.visible = true
	var mid := (a + b) * 0.5
	var y_axis := (a - b).normalized()
	var to_cam := to_local(_cam_pos()) - mid
	var z_axis := to_cam - y_axis * to_cam.dot(y_axis)
	z_axis = z_axis.normalized() if z_axis.length() > 0.001 else Vector3.BACK
	var x_axis := y_axis.cross(z_axis).normalized()
	mi.transform = Transform3D(Basis(x_axis * width, y_axis * a.distance_to(b), z_axis), mid)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("tt", t)
	mat.set_shader_parameter("reveal", reveal)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("beam_len", a.distance_to(b))
	mat.set_shader_parameter("dissolve", dissolve)


## One spinning hexagon plate. `yaw` turns it about the vertical axis (it faces outward, then flips as it spins).
func _hexagon(pos: Vector3, yaw: float, size: float, tilt: float, color: Color, color2: Color, intensity: float) -> void:
	if intensity <= 0.02:
		return
	if _hex_used >= _hexes.size():
		var made := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		made.mesh = q
		made.material_override = VfxLib.shader_mat("abra_hexagon", {})
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(made)
		_hexes.append(made)
	var mi := _hexes[_hex_used]
	_hex_used += 1
	mi.visible = true
	mi.transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt), pos)
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("color2", color2)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("tt", t)


## The shot leaving the crystal: muzzle flash, a forward ring and a cone of sparks.
func _psybeam_launch(p_start: Vector3, aim: Vector3) -> void:
	var w_start := to_global(p_start)
	var w_aim := (global_transform.basis * aim).normalized()
	VfxLib.flash_star(fx, w_start, Color.WHITE, 3.5, 0.14)
	VfxLib.flash_star(fx, w_start, PINK, 6.0, 0.26)
	var ring := VfxLib.animated_quad(fx, Vector2(4.2, 4.2), "ring", {"color": PINK, "energy": 3.2}, 0.4)
	ring.position = w_start + w_aim * 0.8
	ring.look_at(ring.position + w_aim)
	VfxLib.burst(fx, w_start, {"amount": 36, "life": 0.4, "speed": Vector2(8.0, 22.0), "dir": w_aim, "spread": 20.0, "damping": 1.0, "size": Vector2(0.14, 0.3), "end_scale": 0.0,
		"ramp": VfxLib.ramp([Color.WHITE, PINK, Color(VIOLET, 0.0)], [0.0, 0.3, 1.0])})


func _psybeam_travel() -> void:
	if _psy_t0 < 0.0:
		_psy_t0 = t
	_psy_rel = clampf((t - _psy_t0) / PSY_RELEASE, 0.0, 1.0)  # the charge pose expands and fades out over PSY_RELEASE
	if _keep_windup:
		_psybeam_windup()
	var ap := _psybeam_ap()
	var p_start := Vector3(0, _acy + 0.1, -(_ar + 0.35 + PSY_AHEAD))
	var p_end := Vector3(0, _tcy, -_D)
	if not _fired:
		_fired = true
		_psybeam_launch(p_start, (p_end - p_start).normalized())
	# The laser front travels at the projectile's pace and reaches the target exactly when the hit lands
	# (end of the flight phase); it then stays lit until the return fades it.
	var reveal := 1.0 if ext_returning else clampf(ext_p, 0.0, 1.0)
	var power := 1.0
	var dissolve := 0.0
	if ext_returning:
		# Once it has landed the laser does not vanish: it narrows, frays and dissipates for PSY_BEAM_FADE seconds.
		if _beam_fade_t0 < 0.0:
			_beam_fade_t0 = t
		dissolve = clampf((t - _beam_fade_t0) / PSY_BEAM_FADE, 0.0, 1.0)
		power = 1.0 - dissolve * 0.5
		if dissolve >= 1.0:
			queue_free()
			return
		if _px_chance(0.9):
			var f := _rng.randf()
			var bp := p_start.lerp(p_end, f) + Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.4, 0.4))
			_spawn_pt({"p": bp, "v": Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(0.3, 1.6), _rng.randf_range(-0.6, 0.6)), "drag": 0.95, "life": 0.5 + _rng.randf() * 0.4,
				"size": 0.14, "alpha": 0.9 * (1.0 - dissolve), "stretch": 0.03, "mode": "stretched_billboard", "color": PINK if _rng.randf() < 0.6 else VIOLET, "core": Color.WHITE, "max_trail": 4})
	var flick := 0.9 + 0.1 * sin(t * 50.0)
	var kb := clampf(_dist_k(to_global(p_end)) * 0.6, 1.0, 2.2)  # keeps the laser readable at the camera's distance
	_beam(p_start, p_end, 2.6 * kb, power * flick, reveal, dissolve)  # body + strands
	_beam(p_start, p_end, 1.1 * kb, power, reveal, dissolve)  # thin hot core on top
	var glow := 1.0 - dissolve
	_blob(p_start, 70.0 * glow, Color.WHITE, Color(1.0, 0.4, 0.7, 0.5), glow * 0.6)
	_flare(p_start, 110.0 * glow, 3.4, PINK, glow * 0.7)
	if reveal >= 0.98:
		_blob(p_end, 80.0 * glow, Color("ffd6fa"), Color(0.88, 0.34, 0.99, 0.45), glow * 0.5)


func _psybeam_impact() -> void:
	var ep := clampf(t / span, 0.0, 1.0)
	if not _fired:
		_fired = true
		_impact_burst("raio_psiquico", Vector3(0, 0.45, 0))
	var fade := 1.0 if ep < 0.45 else clampf((1.0 - ep) / 0.55, 0.0, 1.0)
	var grow := _ease_out(clampf(ep / 0.25, 0.0, 1.0))
	var cy := _tcy
	var sc := clampf(_dist_k(global_position), 1.0, 2.0)  # keeps the hexagons readable at the camera's distance, without blowing up
	# A single target: one tight ring of six small hexagons spinning around the body, and a fainter one behind it.
	for k in 6:
		var a := float(k) / 6.0 * TAU + t * 3.0
		var r := (_tr + 0.4) * grow * sc
		var pos := Vector3(cos(a) * r, cy + sin(t * 4.0 + float(k)) * 0.12 * sc, sin(a) * r)
		_hexagon(pos, atan2(cos(a), sin(a)) + t * 4.0 + float(k), 0.7 * grow * sc, 0.0, PINK, VIOLET, fade)
	for k in 6:
		var a := float(k) / 6.0 * TAU - t * 2.0 + 0.5
		var r := (_tr + 1.0) * grow * sc
		var pos := Vector3(cos(a) * r, cy + (0.25 if k % 2 == 0 else -0.2) * sc, sin(a) * r)
		_hexagon(pos, atan2(cos(a), sin(a)) - t * 3.0 + float(k) * 0.7, 0.5 * grow * sc, 0.0, VIOLET, RUBY, fade * 0.7)
	_blob(Vector3(0, cy, 0), 85.0 * sin(ep * PI), Color("ffd6fa"), Color(0.88, 0.34, 0.99, 0.45), 0.4)


# --- Generic damage burst (44 particles of the prototype) ------------------------------


func _impact_burst(id: String, at: Vector3) -> void:
	var is_elec := id == "onda_choque"
	var count := 48 if is_elec else (26 if id == "raio_psiquico" else 44)
	for p in count:
		var a := _rng.randf() * TAU
		var elev := (_rng.randf() - 0.08) * PI * 0.65
		var spd := (6.5 + _rng.randf() * 14.5) if is_elec else ((5.0 + _rng.randf() * 11.0) * (0.75 if id == "raio_psiquico" else 1.0))
		var burnt := p % 2 == 0
		var col: Color = (BURNT if burnt else YELLOW) if is_elec else [RUBY, MAGENTA, PINK, VIOLET][p % 4]
		var mode := "trail"
		if is_elec:
			mode = "star_sprite" if p % 5 == 0 else ("micro_arc" if p % 4 == 0 else "stretched_billboard")
		var o := {
			"p": Vector3(at.x + (_rng.randf() - 0.5) * 0.4, (0.25 if (is_elec and p % 3 == 0) else _tcy - 0.3) + _rng.randf() * 0.6, at.z + (_rng.randf() - 0.5) * 0.4),
			"v": Vector3(cos(a) * cos(elev) * spd, sin(elev) * spd + (5.2 if is_elec else 3.5), sin(a) * cos(elev) * spd),
			"drag": 0.93 if is_elec else 0.96, "gravity": 19.5 if is_elec else 6.5, "turb": 14.0 if is_elec else 0.0, "bounce": true,
			"life": (0.40 + _rng.randf() * 0.35) if is_elec else (0.78 + _rng.randf() * 0.45),
			"size": (0.14 + _rng.randf() * 0.14) if is_elec else (0.16 + _rng.randf() * 0.13),
			"alpha": 0.44 if is_elec else 1.0, "stretch": 0.048 if is_elec else 0.0, "mode": mode,
			"sprite": "starAmber" if burnt else "starYellow", "color": col, "core": HOT if is_elec else Color.WHITE, "max_trail": 5 if is_elec else 9,
		}
		if id == "confusao":
			o["swirl"] = 7.5
			o["swirl_c"] = Vector3(0, _tcy, 0)
		_spawn_pt(o)


func _setup_impact() -> void:
	match move_id:
		"confusao":
			_impact_burst("confusao", Vector3.ZERO)
		"teleporte_rapido":
			# Palm burst: starts at the palm (behind the target) and flies on towards it (prototype vx +6.5).
			for p in 44:
				var a := _rng.randf() * TAU
				var elev := (_rng.randf() - 0.08) * PI * 0.65
				var spd := 5.0 + _rng.randf() * 11.0
				_spawn_pt({"p": Vector3((_rng.randf() - 0.5) * 0.4, 1.45 + _rng.randf() * 0.6, 0.8 + (_rng.randf() - 0.5) * 0.4),
					"v": Vector3(cos(a) * cos(elev) * spd, sin(elev) * spd + 3.5, sin(a) * cos(elev) * spd - 6.5),
					"drag": 0.96, "gravity": 6.5, "bounce": true, "life": 0.78 + _rng.randf() * 0.45, "size": 0.16 + _rng.randf() * 0.13,
					"color": [RUBY, MAGENTA, PINK, VIOLET][p % 4], "core": Color.WHITE, "max_trail": 9})


## One-shot world-space layers: flash, energy body, rings, flipbooks, sparks (VFX skill: layers).
func _world_extras() -> void:
	var chest := Vector3(dst.x, _tcy + GROUND, dst.z)
	var ground := Vector3(dst.x, 0.0, dst.z)
	var k := 1.25 if big else 1.0
	match move_id:
		"onda_choque":
			VfxLib.flash_star(fx, chest, Color.WHITE * SHOCK_OPACITY, 6.0 * k, 0.18 / SHOCK_SPEED)
			VfxLib.flash_star(fx, chest, YELLOW * SHOCK_OPACITY, 9.0 * k, 0.30 / SHOCK_SPEED)
			AbraPops.column(fx, ground, 0.75 * k, 6.5, YELLOW, Color("ff6a00"), 0.45 / SHOCK_SPEED, 0, 0.6 * SHOCK_OPACITY)
			AbraPops.column(fx, ground, 0.2 * k, 7.5, Color("ffd34a"), YELLOW, 0.4 / SHOCK_SPEED, 0, 0.45 * SHOCK_OPACITY)
			AbraPops.floor_ring(fx, ground, 10.0 * k, YELLOW, 0.5 / SHOCK_SPEED, 0.0, 3.0 * SHOCK_OPACITY)
			AbraPops.floor_ring(fx, ground, 15.0 * k, Color("ff8a00"), 0.62 / SHOCK_SPEED, 0.06 / SHOCK_SPEED, 3.0 * SHOCK_OPACITY)
			AbraPops.floor_ring(fx, ground, 21.0 * k, Color("ffb000"), 0.75 / SHOCK_SPEED, 0.13 / SHOCK_SPEED, 3.0 * SHOCK_OPACITY)
			for i in 3:
				var fb := VfxLib.flipbook(fx, chest + Vector3.UP * (0.3 + i * 0.7), "lightning", YELLOW if i % 2 == 0 else Color("ff9a00"), (6.0 + i * 0.8) * k, 0.34 / SHOCK_SPEED, i * 67.0, 4.2 * SHOCK_OPACITY)
				fb.name = "ShockFlipbook%d" % i
			VfxLib.flipbook(fx, chest, "impact", Color("fff2a0"), 8.0 * k, 0.30 / SHOCK_SPEED, 0.0, 4.0 * SHOCK_OPACITY)
			var cone := VfxLib.mesh_slash(fx, chest, Vector3.UP, YELLOW, 0.0, 2.2 * k, 0.32 / SHOCK_SPEED, "shock_cone", 4.2 * SHOCK_OPACITY)
			cone.name = "ShockCone"
			AbraPops.sparks_up(fx, chest, Color(YELLOW, SHOCK_OPACITY), 70, Vector2(8.0, 20.0))
			VfxLib.burst(fx, chest, {"amount": 60, "life": 0.55, "speed": Vector2(8.0, 20.0), "gravity": Vector3(0, -14, 0), "size": Vector2(0.18, 0.40), "end_scale": 0.0,
				"ramp": VfxLib.ramp([Color(1, 1, 1, SHOCK_OPACITY), Color(YELLOW, SHOCK_OPACITY), Color("ff6a00", 0.0)], [0.0, 0.3, 1.0])})
		"raio_psiquico":
			VfxLib.flash_star(fx, chest, Color.WHITE, 3.4, 0.14)
			VfxLib.flash_star(fx, chest, PINK, 5.6, 0.24)
			VfxLib.flipbook(fx, chest, "impact", Color("ff7ad9"), 4.8, 0.28, 10.0, 2.8)
			AbraPops.floor_ring(fx, ground, 7.0, PINK, 0.45, 0.0, 2.6)
			AbraPops.floor_ring(fx, ground, 10.0, VIOLET, 0.55, 0.06, 2.3)
			VfxLib.burst(fx, chest, {"amount": 22, "life": 0.42, "speed": Vector2(4.0, 11.0), "dir": dir, "spread": 60.0, "damping": 1.0, "size": Vector2(0.12, 0.28), "end_scale": 0.0,
				"ramp": VfxLib.ramp([Color.WHITE, PINK, Color(VIOLET, 0.0)], [0.0, 0.3, 1.0])})
		"teleporte_rapido":
			VfxLib.flash_star(fx, chest, Color.WHITE, 8.0, 0.2)
			VfxLib.flash_star(fx, chest, MAGENTA, 12.0, 0.32)
			VfxLib.flipbook(fx, chest, "impact", Color("ff7ad9"), 8.0, 0.32, 20.0, 4.0)
			var tcone := VfxLib.mesh_slash(fx, chest - dir * 0.4, dir, Color("e056fd"), 0.0, 2.0, 0.34, "shock_cone", 4.0)
			tcone.name = "TeleportCone"
			AbraPops.floor_ring(fx, ground, 10.0, MAGENTA, 0.5)
			AbraPops.floor_ring(fx, ground, 15.0, VIOLET, 0.62, 0.07)
			AbraPops.streaks_up(fx, ground, 16, VIOLET, 1.2, 0.5)


## Teleport wind-up, world layer: the energy columns swell where Abra stands and where it will appear.
func _teleport_windup_world() -> void:
	var fwd := Vector3(dst.x - src.x, 0.0, dst.z - src.z)
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var arrive := Vector3(dst.x, 0.0, dst.z) + fwd * 1.35
	var origin := Vector3(src.x, 0.0, src.z)
	AbraPops.column(fx, origin, maxf(0.9, _ar * 1.1), 5.5, MAGENTA, VIOLET, life * 2.4, 0, 1.4)
	AbraPops.column(fx, arrive, maxf(1.1, _tr * 1.1), 6.5, MAGENTA, VIOLET, life * 2.4, 0, 1.4)
	AbraPops.floor_ring(fx, arrive, 7.0, VIOLET, life * 1.6, 0.0, 2.6)


# --- SHOCK WAVE ----------------------------------------------------------------------


# Shock Wave is drawn with the game's own tools (D-170, item 19): the lightning shader for the bolts,
# the smoke flipbook for the storm cloud, the `ring` shader for the shock rings, and textured particles.
# It follows the prototype's sequence: crackle + ionisation + a growing leader bolt and a storm cloud
# (wind-up), the sky bolt striking down (0.18 s), then body arcs, the 16-spike star, ground feeders,
# the wide spark vortex and the ground waves (contact).


## One lightning quad from `a` (top) to `b` (bottom), turned to face the camera around its own axis.
func _bolt(a: Vector3, b: Vector3, width: float, color: Color, seed_: float, reveal := 1.0, intensity := 1.0, o := {}) -> void:
	intensity *= _op
	if intensity <= 0.02 or a.distance_to(b) < 0.05:
		return
	if _bolt_used >= _bolts.size():
		var made := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		made.mesh = q
		made.material_override = VfxLib.shader_mat("abra_lightning", {})
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(made)
		_bolts.append(made)
	var mi := _bolts[_bolt_used]
	_bolt_used += 1
	mi.visible = true
	var mid := (a + b) * 0.5
	var y_axis := (a - b).normalized()
	var to_cam := to_local(_cam_pos()) - mid
	var z_axis := to_cam - y_axis * to_cam.dot(y_axis)
	z_axis = z_axis.normalized() if z_axis.length() > 0.001 else Vector3.BACK
	var x_axis := y_axis.cross(z_axis).normalized()
	mi.transform = Transform3D(Basis(x_axis * width, y_axis * a.distance_to(b), z_axis), mid)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("core_color", color.lerp(Color.WHITE, 0.75))
	mat.set_shader_parameter("tt", t)
	mat.set_shader_parameter("seed", seed_)
	mat.set_shader_parameter("reveal", reveal)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("amp", o.get("amp", 0.30))
	mat.set_shader_parameter("thick", o.get("thick", 0.040))
	mat.set_shader_parameter("branches", o.get("branches", 2.0))
	mat.set_shader_parameter("spiral", o.get("spiral", 0.0))


## Flat shock ring (the project's `ring` shader) driven by `progress` 0..1.
func _ring_quad(pos: Vector3, size: float, progress: float, color: Color, intensity := 2.6) -> void:
	color.a *= _op
	if _ring_used >= _rings.size():
		var made := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2.ONE
		made.mesh = q
		made.material_override = VfxLib.shader_mat("ring", {})
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		made.rotation_degrees = Vector3(-90, 0, 0)
		add_child(made)
		_rings.append(made)
	var mi := _rings[_ring_used]
	_ring_used += 1
	mi.visible = true
	mi.position = pos
	mi.scale = Vector3(size, size, 1.0)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("progress", clampf(progress, 0.0, 0.999))
	mat.set_shader_parameter("energy", intensity)


## Storm cloud: smoke flipbook puffs tinted amber (the HTML's sky glow and cloud ring).
func _storm_cloud(center: Vector3, grow: float, alpha: float) -> void:
	alpha *= _op
	if alpha <= 0.02:
		return
	for i in 5:
		if i >= _cloud.size():
			var made := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2.ONE
			made.mesh = q
			made.material_override = VfxLib.shader_mat("flipbook", {"sheet_tex": VfxLib.flipbook_tex("smoke"), "h_frames": 4, "v_frames": 4, "energy": 1.4})
			made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(made)
			_cloud.append(made)
		var mi := _cloud[i]
		mi.visible = true
		var ang := float(i) / 5.0 * TAU + t * 0.6
		mi.position = center + Vector3(cos(ang) * 2.6 * grow, sin(ang * 1.7) * 0.5, sin(ang) * 2.6 * grow)
		var size := (6.0 + 5.0 * grow) * (0.85 + 0.3 * float(i % 3) / 2.0)
		mi.scale = Vector3(size, size, 1.0)
		var mat := mi.material_override as ShaderMaterial
		mat.set_shader_parameter("progress", fmod(t * 0.7 + float(i) * 0.21, 1.0))
		mat.set_shader_parameter("color", Color(1.0, 0.62 + 0.12 * float(i % 2), 0.12, clampf(alpha, 0.0, 1.0) * 0.8))
		mat.set_shader_parameter("roll_rad", ang * 0.5)


func _shock_windup() -> void:
	var wp := _wp()
	var enemy := Vector3(0, 0, -_D)
	# Static crackle: amber star sparks around the caster and ionisation streaming up from the target.
	if _px_chance(0.35):
		var a := _rng.randf() * TAU
		var r := 0.4 + _rng.randf() * 1.05
		var burnt := _rng.randf() < 0.52
		_spawn_pt({"p": Vector3(cos(a) * r, 0.15 + _rng.randf() * 1.9, sin(a) * r), "v": Vector3(-sin(a) * 1.8, 1.8 + _rng.randf() * 2.4, cos(a) * 1.8), "turb": 11.0,
			"life": 0.32 + _rng.randf() * 0.18, "size": 0.16 + _rng.randf() * 0.10, "alpha": 0.8, "mode": "star_sprite",
			"sprite": "starAmber" if burnt else "starYellow", "color": BURNT if burnt else YELLOW, "core": HOT})
	if _px_chance(0.55):
		var a := _rng.randf() * TAU
		var rad := (0.35 + _rng.randf() * 1.65) * (1.0 - wp * 0.35)
		var burnt := int(t * 20.0) % 2 == 0
		_spawn_pt({"p": enemy + Vector3(cos(a) * rad, -0.22 + _rng.randf() * 0.4, sin(a) * rad), "v": Vector3((_rng.randf() - 0.5) * 1.4, 6.8 + wp * 12.0 + _rng.randf() * 4.5, (_rng.randf() - 0.5) * 1.4),
			"swirl": 9.0, "swirl_c": enemy + Vector3(0, 3.5, 0), "turb": 10.0, "life": 0.36 + _rng.randf() * 0.20, "size": 0.13 + _rng.randf() * 0.10, "alpha": 0.7,
			"stretch": 0.042, "mode": "stretched_billboard", "sprite": "starAmber" if burnt else "starYellow", "color": BURNT if burnt else YELLOW, "core": HOT, "max_trail": 5})
	# Short arcs jumping around the caster (re-rolled ~8 times a second).
	_crackle_left -= _dt
	if _crackle_left <= 0.0:
		_crackle_left = 0.12
		_crackle.clear()
		for i in 3:
			var a := _rng.randf() * TAU
			var r := 0.5 + _rng.randf() * 0.8
			var start := Vector3(cos(a) * r, 0.4 + _rng.randf() * 1.6, sin(a) * r)
			var d := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.4, 1.0), _rng.randf_range(-1, 1)).normalized()
			_crackle.append([start + d * _rng.randf_range(0.8, 1.6), start])
	for i in _crackle.size():
		_bolt(_crackle[i][0], _crackle[i][1], 1.2, YELLOW if i % 2 == 0 else BURNT, float(i) * 3.0, 1.0, wp, {"amp": 0.28, "branches": 1.0})
	# Leader bolt growing up from the target's head, the storm cloud and the shock rings.
	var top := 1.65 + pow(wp, 1.85) * 7.8
	_bolt(enemy + Vector3(0, top, 0), enemy + Vector3(0, 1.45, 0), 2.4, Color("ffcc00"), 7.0, 1.0, wp, {"amp": 0.22, "branches": 1.0})
	_storm_cloud(enemy + Vector3(0, 9.5, 0), wp, wp)
	_blob(enemy + Vector3(0, 9.5, 0), 70.0 * wp, YELLOW, Color(0.82, 0.37, 0.0, 0.35), wp * 0.30)
	_ring_quad(enemy + Vector3(0, -0.18, 0), 7.0, fmod(t * 1.3, 1.0), YELLOW, 2.4 * wp)
	_ring_quad(enemy + Vector3(0, -0.18, 0), 11.0, fmod(t * 1.3 + 0.5, 1.0), BURNT, 2.0 * wp)
	_ring_quad(Vector3(0, -0.18, 0), 4.5, fmod(t * 1.6, 1.0), BURNT, 2.0 * wp)
	var hero_p := Vector3(0, 2.35, 0)
	_blob(_scr(hero_p, 0, 24), 45.0 + wp * 15.0, BURNT, Color(0.9, 0.49, 0.0, 0.28), wp * 0.25)


func _shock_travel() -> void:
	if _keep_windup:
		_shock_windup()
	# Prototype 0.00 s .. 0.18 s: the sky bolt strikes down onto the target's head.
	var enemy := Vector3(0, 0, -_D)
	var reveal := _ease_out(clampf(ext_p * SHOCK_SPEED, 0.0, 1.0))
	_storm_cloud(enemy + Vector3(0, 9.5, 0), 1.0, 1.0)
	for i in 3:
		_bolt(enemy + Vector3(float(i - 1) * 0.5, 11.2, 0), enemy + Vector3(0, 1.55, 0), 4.2 - float(i) * 0.9, YELLOW if i != 1 else BURNT, 11.0 + float(i) * 5.0, reveal, 1.0,
			{"amp": 0.24, "branches": 2.0, "spiral": 0.05 if i > 0 else 0.0})
	_blob(enemy + Vector3(0, 10.2, 0), 115.0 * reveal, YELLOW, Color(0.82, 0.37, 0.0, 0.35), 0.4)


func _shock_impact() -> void:
	# elapsedActive = 0.18 s (contact) + game-scaled time.
	var scale_t := 1.22 / span
	var ea := 0.18 + t * scale_t
	var ap := clampf(ea / 1.4, 0.0, 1.0)
	var env := sin(ap * PI)
	var post := clampf((ea - 0.18) / 1.22, 0.0, 1.0)
	var pulse := 0.82 + 0.18 * cos(ea * 42.0)
	var power := (1.0 if ea < 0.6 else clampf(1.0 - (ea - 0.6) / 0.7, 0.0, 1.0)) * pulse
	if not _fired:
		_fired = true
		_impact_burst("onda_choque", Vector3.ZERO)
		for s in 28:
			var sa := float(s) / 28.0 * TAU + (_rng.randf() - 0.5) * 0.15
			var s_elev := float((s % 5) - 2) * 0.26 + (_rng.randf() - 0.5) * 0.2
			var s_spd := 15.0 + float(s % 3) * 4.5 + _rng.randf() * 5.0
			_spawn_pt({"p": Vector3(cos(sa) * 0.25, 1.40 + sin(s_elev) * 0.25, sin(sa) * 0.25), "v": Vector3(cos(sa) * cos(s_elev) * s_spd, sin(s_elev) * s_spd, sin(sa) * cos(s_elev) * s_spd),
				"drag": 0.86, "gravity": 0.0, "life": 0.20, "size": 0.22 + float(s % 2) * 0.08, "alpha": 0.9, "stretch": 0.088, "mode": "stretched_billboard",
				"color": BURNT if s % 2 == 0 else YELLOW, "core": Color.WHITE, "max_trail": 4})
	_storm_cloud(Vector3(0, 9.5, 0), 1.0, power)
	# The sky bolt keeps pounding the target while the contact effects play.
	for i in 3:
		_bolt(Vector3(float(i - 1) * 0.5, 11.2, 0), Vector3(0, 1.55, 0), 4.2 - float(i) * 0.9, YELLOW if i != 1 else BURNT, 11.0 + float(i) * 5.0, 1.0, power,
			{"amp": 0.24, "branches": 2.0, "spiral": 0.05 if i > 0 else 0.0})
	# Seven arcs hugging the body, head to floor.
	for m in 7:
		var ma := float(m) / 7.0 * TAU + float(m) * 0.31
		var body_r := 0.95 + float(m % 2) * 0.28
		_bolt(Vector3(cos(ma) * 0.25, 2.25, sin(ma) * 0.25), Vector3(cos(ma) * body_r, -0.22, sin(ma) * body_r), 1.6, YELLOW if m % 2 == 0 else BURNT, 40.0 + float(m) * 3.0,
			1.0, power * (1.0 - post * 0.45), {"amp": 0.35, "branches": 1.0})
	# 16-spike star for the first 0.2 s of contact.
	var spike_el := ea - 0.18
	if spike_el >= 0.0 and spike_el <= 0.20:
		var spike_p := spike_el / 0.20
		var reach := 0.25 + _ease_out(spike_p) * 0.95
		var fade_s := 1.0 if spike_p < 0.35 else 1.0 - (spike_p - 0.35) / 0.65
		for sp in 16:
			var sa := float(sp) / 16.0 * TAU + float(sp % 3) * 0.05
			var len := (2.45 + float(sp % 3) * 0.95) * reach
			var pitch := float((sp % 5) - 2) * 0.42
			var tip := Vector3(cos(sa) * len, 1.40 + pitch * reach, sin(sa) * len)
			_bolt(Vector3(0, 1.55, 0), tip, 1.5, BURNT if sp % 2 == 0 else YELLOW, 70.0 + float(sp) * 2.0, 1.0, fade_s, {"amp": 0.28, "branches": 0.0})
	# Six feeders running along the floor out to the vortex radius.
	for g in 6:
		var ga := float(g) / 6.0 * TAU + 0.3
		var run := clampf(post * 3.0, 0.0, 1.0)
		_bolt(Vector3(0, -0.1, 0), Vector3(cos(ga) * 3.0 * run, -0.1, sin(ga) * 3.0 * run), 1.4, YELLOW if g % 2 == 0 else BURNT, 90.0 + float(g) * 4.0, 1.0,
			power * (1.0 - post * 0.6), {"amp": 0.3, "branches": 1.0})
	var head_p := Vector3(0, 1.65, 0)
	var ground_p := Vector3(0, -0.22, 0)
	var hit_env := sin(clampf(post / 0.65, 0.0, 1.0) * PI)
	_blob(head_p, 100.0 * env, Color("fff0a0"), Color(1.0, 0.75, 0.0, 0.4), power * 0.35)
	_flare(head_p, 150.0 * hit_env, 3.2, YELLOW, power * 0.5)
	_blob(ground_p, 130.0 * env, Color("ffaa00"), Color(0.72, 0.36, 0.0, 0.35), power * 0.3)
	# Ground waves: the wide vortex ring (0.5 s) and two secondary waves.
	var vortex_el := ea - 0.18
	if vortex_el >= 0.0 and vortex_el <= 0.50:
		var vp := vortex_el / 0.50
		_ring_quad(Vector3(0, -0.2, 0), 2.0 * (2.85 + _ease_out(vp) * 0.9) * 1.25, vp, YELLOW, 3.0)
		for n in 12:
			var start_angle := ea * 22.0 + float(n) / 12.0 * TAU + (_rng.randf() - 0.5) * 0.20
			var wide := 2.85 + float(n % 3) * 0.32 + _ease_out(vp) * 0.45
			var start_y := -0.22 + float(n % 3) * 0.06
			var burnt2 := (n + int(ea * 40.0)) % 2 == 0
			_spawn_pt({"p": Vector3(cos(start_angle) * wide, start_y, sin(start_angle) * wide), "orbit_c": Vector3(0, start_y, 0), "orbit_r": wide, "orbit_a": start_angle,
				"orbit_s": 19.0 + float(n % 3) * 4.5, "orbit_l": 1.65 + float(n % 3) * 0.85, "bounce": true, "life": minf(0.24, 0.50 - vortex_el + 0.05), "size": 0.2 + float(n % 2) * 0.07,
				"alpha": 0.9, "stretch": 0.045, "mode": "star_sprite" if n % 3 == 0 else "stretched_billboard", "sprite": "starAmber" if burnt2 else "starYellow",
				"color": BURNT if burnt2 else YELLOW, "core": Color("fff9db"), "max_trail": 9})
	for r in 2:
		var rp := clampf((post - float(r) * 0.16) / 0.78, 0.0, 1.0)
		if rp > 0.0 and rp < 1.0:
			_ring_quad(Vector3(0, -0.22, 0), 2.0 * (1.40 + _ease_out(rp) * 5.2), rp, BURNT if r % 2 == 1 else YELLOW, 2.4)
	if ap < 0.78 and _px_chance(0.48):
		var ang := _rng.randf() * TAU
		var spd := 4.2 + _rng.randf() * 9.5
		var burnt3 := _rng.randf() < 0.5
		_spawn_pt({"p": Vector3(cos(ang) * 0.65, 0.35 + _rng.randf() * 1.75, sin(ang) * 0.65), "v": Vector3(cos(ang) * spd, 2.2 + _rng.randf() * 5.8, sin(ang) * spd),
			"drag": 0.93, "gravity": 18.5, "turb": 15.0, "bounce": true, "life": 0.32 + _rng.randf() * 0.24, "size": 0.18 + _rng.randf() * 0.13, "alpha": 0.8, "stretch": 0.048,
			"mode": "star_sprite" if _rng.randf() < 0.4 else "stretched_billboard", "sprite": "starAmber" if burnt3 else "starYellow", "color": BURNT if burnt3 else YELLOW, "core": HOT, "max_trail": 5})


# --- TELEPORT (D-034: arrival behind the target; prism replaced by rising purple speed lines) ---


func _teleport_windup() -> void:
	var wp := _wp()
	var we := _ease_io(wp)
	for i in 3:
		var scan_y := 0.25 + fmod(t * 2.8 + float(i) * 0.33, 1.0) * (_atop + 0.2)
		_ring(Vector3(0, scan_y, 0), (_ar + 0.3) * sin(wp * PI * 0.5), "ruby" if i == 0 else ("pink" if i == 1 else "violet"), 0.98, 20, 0.11)
	_gimbal(Vector3(0, 0.08, 0), (_ar + 0.35) * _ease_out(wp), Vector3(PI * 0.5, 0, t * 5.0), "pink", wp * 0.92, 24, 0.085, Color("ff66b2"))
	_streak_bundle(Vector3(0, -0.22, 0), wp, 12, 0.0)
	var arrive := Vector3(0, 0, -_D - 1.35)
	var seal := _ease_io(wp)
	_gimbal(arrive + Vector3(0, _tcy, 0), maxf(1.4, _tr + 0.4) * seal, Vector3(0, 0, PI * 0.5), "ruby", wp * 0.94, 8, 0.08, Color("ffb8d1"))
	_gimbal(arrive + Vector3(0, _tcy, 0), maxf(0.95, _tr * 0.7) * seal, Vector3(t * 4.2, 0, PI * 0.5), "magenta", wp * 0.95, 4, 0.075, Color("ffd1fb"))
	_ring(arrive + Vector3(0, -0.18, 0), 1.32 * seal, "pink", wp * 0.90, 16, 0.07)
	_gimbal(arrive + Vector3(0, _tcy, 0), maxf(1.1, _tr * 0.8) * seal, Vector3(0, PI * 0.5, -t * 4.0), "pink", wp * 0.94, 20, 0.075, Color("ff66b2"))
	_streak_bundle(Vector3(arrive.x, -0.22, arrive.z), wp, 10, 1.7)
	var flank_p := arrive + Vector3(0, _tcy, 0)
	_blob(flank_p, 72.0 * wp, RUBY, Color("e056fd", 0.45), wp * 0.72)
	_flare(flank_p, 82.0 * wp, 2.6, RUBY, wp * 0.75)
	var sz := 28.0 - _ease_out(wp) * 8.0
	var a := t * 2.8
	var sq: Array = []
	for q in [Vector2(-sz, -sz), Vector2(sz, -sz), Vector2(sz, sz), Vector2(-sz, sz), Vector2(-sz, -sz)]:
		var v := q as Vector2
		sq.append(Vector2(v.x * cos(a) - v.y * sin(a), v.x * sin(a) + v.y * cos(a)))
	_scr_line(flank_p, sq, 2.2, Color(RUBY, wp * 0.95))
	_scr_line(flank_p, [Vector2(-36, 0), Vector2(-14, 0)], 1.5, Color(PINK, wp * 0.95))
	_scr_line(flank_p, [Vector2(14, 0), Vector2(36, 0)], 1.5, Color(PINK, wp * 0.95))
	_scr_line(flank_p, [Vector2(0, -36), Vector2(0, -14)], 1.5, Color(PINK, wp * 0.95))
	_scr_line(flank_p, [Vector2(0, 14), Vector2(0, 36)], 1.5, Color(PINK, wp * 0.95))


func _teleport_impact() -> void:
	var ap := clampf(t / span, 0.0, 1.0)
	var bp := clampf((ap - 0.06) / 0.74, 0.0, 1.0)
	var out := _ease_out(bp)
	var fade := 1.0 if bp < 0.65 else (1.0 - bp) / 0.35
	var enemy_c := Vector3(0, _tcy, 0)
	# Local +Z points back at the attacker: the palm sits behind the target (D-034).
	var palm := Vector3(0, _tcy, _tr + 0.55)
	if ap > 0.06 and ap < 0.80:
		# Prototype x axis (strike direction) is local -Z here.
		var px := palm
		var sphere_r := 0.38 + out * 1.65
		_ink_sphere(Vector3(px.x, px.y, px.z - out * 0.45), sphere_r, fade * 0.90)
		_tess(Vector3(px.x, px.y, px.z - out * 0.65), (0.65 + out * 0.85) * fade, t * 2.2, fade * 0.95, "ruby", "magenta")
		for m in 7:
			var lag := clampf((bp - float(m) * 0.042) / 0.74, 0.0, 1.0)
			if lag > 0.0 and lag < 1.0:
				var re := _ease_out(lag)
				var ring_z := px.z - (float(m) * 0.44 + re * 2.35)
				var cone_r := 0.38 + float(m) * 0.30 + re * (0.98 + float(m) * 0.26)
				var key := "ruby" if m % 4 == 0 else ("magenta" if m % 3 == 0 else ("pink" if m % 2 == 0 else "violet"))
				_gimbal(Vector3(px.x, px.y, ring_z), cone_r, Vector3(t * (6.0 if m % 2 == 1 else -6.0), 0, PI * 0.5), key, (1.0 - lag) * 0.96, 26, 0.095, Color("ffd1fb") if m % 2 == 0 else Color("ff8a9f"))
		for k in 12:
			var ang := float(k) * (TAU / 12.0) + 0.25
			var r_start := 0.32 + out * 0.85
			var r_end := 0.98 + out * 2.25
			var z1 := px.z - out * 0.85
			var z2 := z1 - (1.5 + float(k % 2) * 0.95) * (1.0 - bp * 0.28)
			var key := "ruby" if k % 3 == 0 else ("pink" if k % 2 == 1 else "violet")
			_ribbon(Vector3(px.x + sin(ang) * r_start, px.y + cos(ang) * r_start, z1), Vector3(px.x + sin(ang) * r_end, px.y + cos(ang) * r_end, z2), 0.13 * fade, key, 0.94 * fade, Color("ffd1fb"))
		_ring(Vector3(0, -0.18, -out * 0.8), 0.85 + out * 3.1, "ruby", (1.0 - bp) * 0.92, 26, 0.09)
		_blob(px, 110.0 * sin(bp * PI), Color.WHITE, Color(1.0, 0.09, 0.27, 0.68), sin(bp * PI) * 0.90)
		_flare(px, 180.0 * sin(bp * PI), 4.8, RUBY, sin(bp * PI) * 0.95)
		_blob(enemy_c, 125.0 * sin(bp * PI), MAGENTA, Color("b666ff", 0.55), sin(bp * PI) * 0.86)
		_scr_ellipse(_scr(px, out * 44.0, 0), 20.0 + out * 38.0, 46.0 + out * 84.0, 3.2 * (1.0 - bp), Color(RUBY, (1.0 - bp) * 0.95))


func _ink_sphere(c: Vector3, r: float, alpha: float) -> void:
	# A dark screen-facing disc approximates the prototype's ink sphere.
	var pts: Array = []
	for i in 25:
		var a := float(i) / 24.0 * TAU
		pts.append(Vector2(cos(a) * r * 0.65, sin(a) * r) / _pxw(c))
	var prev := Vector3.ZERO
	for i in pts.size():
		var cur := _scr(c, (pts[i] as Vector2).x, (pts[i] as Vector2).y)
		if i > 0:
			_solid.tri(c, prev, cur, Color(INK, alpha))
		prev = cur


## Looping rising purple streaks (vertical, 90 degrees up) around a spot (replaces the prism).
func _streak_bundle(base: Vector3, alpha: float, count: int, seed_off: float) -> void:
	for i in count:
		var a := float(i) * 2.399 + seed_off
		var r := 0.15 + fmod(float(i) * 0.137, 0.55)
		var ph := fmod(t * (1.5 + float(i % 3) * 0.35) + float(i) * 0.29, 1.0)
		var h := 1.1 + float(i % 4) * 0.4
		var y0 := base.y + 0.1 + ph * 1.0
		var al := sin(ph * PI) * alpha
		var x := base.x + cos(a) * r
		var z := base.z + sin(a) * r
		var pts := PackedVector3Array([Vector3(x, y0, z), Vector3(x, y0 + h * (0.5 + 0.5 * sin(ph * PI)), z)])
		_canvas.polyline(pts, 0.30, Color(VIOLET, 1.0 * al), 0.8, 0.85)
		_canvas.polyline(pts, 0.07, Color(LAVENDER, 0.9 * al), 0.7, 0.6)
