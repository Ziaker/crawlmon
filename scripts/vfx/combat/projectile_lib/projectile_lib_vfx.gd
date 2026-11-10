class_name ProjectileLibVfx
extends Node3D
## D-955/D-956: base of the projectile VFX library. Six visual phases: START (the effect that triggers the wind-up,
## inside the first instants of it) -> WINDUP (the charge, held until the shot, never cut) -> RELEASE -> TRAJECTORY ->
## IMPACT -> POST (the impact dissipating). One node per attack holds one beam/projectile per target, all fired at
## once (D-956). This base holds NO appearance: subclasses draw from the state below (D-954: the hero is hand-made).
## It only reads what the game gives (real positions and phase clocks) and never touches the combat timeline (D-019).
## Nothing depends on the character, the team or the side (D-235): sizes are fixed metres (D-308 item 6).

enum Phase { START, WINDUP, RELEASE, TRAJECTORY, IMPACT, POST }

const START_LEN := 0.15  ## START lives inside the first instants of the wind-up (creator: "Sim")
const RELEASE_LEN := 0.08
const IMPACT_LEN := 0.25
const POST_LEN := 0.45
const MISS_GRACE := 0.1  ## end_flight() without hit() within this time = a miss
const HOLD_SAFETY := 6.0
const FRONT_GAP := 1.1  ## D-964: metres between the body's front and the charge

static var _held: Dictionary = {}  ## attacker -> charge waiting to become the shot
static var _live: Array = []
static var _last_body_r := 0.8  ## D-960: radius of the attacker's body (front_of), read by _setup  ## active nodes, for the impact dispatch (by move_id and position)

var fx: BattleFx
var move_id := ""
var t := 0.0
var src := Vector3.ZERO
var windup_len := 0.5
var beams: Array = []  ## {from, to, p, state: "charge"|"fly"|"hit"|"miss", hit_t, hit_pos, hit_dir}
var body_r := 0.8  ## D-960: attacker body radius: crowns drift around it, never through it
var charge_pos := Vector3.ZERO  ## D-958: the charge is born IN FRONT of the real body, toward the target
var attacker_model: Node3D = null  ## D-1021: the real caster model handed by the combat (never the nearest one)
var target_models: Array = []  ## D-1021: per-beam real target models, same order as `beams`
var _release_t := -1.0
var _end_t := -1.0
var _impacts := 0
var _manual := false  ## tests drive time with advance()
var _built := false


static func _setup(v: ProjectileLibVfx, p_fx: BattleFx, p_move: String, p_src: Vector3, targets: Array, windup: float, parent: Node = null, p_attacker_model: Node3D = null, p_target_models: Array = []) -> ProjectileLibVfx:
	v.fx = p_fx
	v.move_id = p_move
	v.src = p_src
	v.windup_len = maxf(windup, START_LEN + 0.05)
	v.name = "Lib%s" % p_move.capitalize().replace(" ", "")
	v.attacker_model = p_attacker_model
	v.target_models = p_target_models
	var aim: Vector3 = (targets[0] as Vector3) if not targets.is_empty() else p_src + Vector3.FORWARD
	# D-1021: when the combat hands the real caster model, measure the charge in front of THAT body (audit 4.2).
	v.charge_pos = front_of_model(p_attacker_model, p_src, aim) if p_attacker_model != null else front_of(p_fx, p_src, aim)
	p_src = v.charge_pos
	v.body_r = _last_body_r if p_fx != null else 0.8
	for tg in targets:
		v.beams.append({"from": p_src, "to": tg as Vector3, "p": 0.0, "state": "charge", "hit_t": -1.0, "hit_pos": tg, "hit_dir": Vector3.FORWARD})
	var host: Node = parent if parent != null else p_fx
	if host == null:
		v._manual = true
	else:
		v._manual = parent != null and p_fx == null
		host.add_child(v)
	_live.append(v)
	return v


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_ensure_built()


func _exit_tree() -> void:
	_live.erase(self)
	for k in _held.keys():
		if _held[k] == self:
			_held.erase(k)


# --- Game hooks ------------------------------------------------------------------------


func hold(attacker: Object) -> void:
	_held[attacker] = self


static func take_held(attacker: Object) -> ProjectileLibVfx:
	var n: Variant = _held.get(attacker)
	_held.erase(attacker)
	return n as ProjectileLibVfx if is_instance_valid(n) else null


## The charge itself leaves: same node, no cut (D-308 item 5).
func release(from: Vector3, to: Array) -> void:
	_release_t = t
	for i in beams.size():
		beams[i]["from"] = charge_pos if fx != null else from  # D-958: the beam leaves from the charge in front of the body
		if i < to.size():
			beams[i]["to"] = to[i]
		beams[i]["state"] = "fly"


func set_travel(i: int, from: Vector3, to: Vector3, progress: float) -> void:
	if i < 0 or i >= beams.size() or beams[i]["state"] != "fly":
		return
	beams[i]["from"] = charge_pos if fx != null else from
	beams[i]["to"] = to
	beams[i]["p"] = clampf(progress, 0.0, 1.0)


func hit(i: int, pos: Vector3, dir: Vector3) -> void:
	if i < 0 or i >= beams.size() or beams[i]["state"] in ["hit", "miss"]:
		return
	beams[i]["state"] = "hit"
	beams[i]["p"] = 1.0
	beams[i]["hit_t"] = t
	beams[i]["hit_pos"] = pos
	beams[i]["hit_dir"] = dir.normalized() if dir.length_squared() > 0.0001 else Vector3.FORWARD
	_impacts += 1


func miss(i: int) -> void:
	if i >= 0 and i < beams.size() and beams[i]["state"] == "fly":
		beams[i]["state"] = "miss"
		beams[i]["hit_t"] = t


func end_flight() -> void:
	if _end_t < 0.0:
		_end_t = t


## The impact dispatch only knows move_id and position: find the live beam that ends there.
static func find_for_impact(p_move: String, pos: Vector3) -> Array:
	var best: ProjectileLibVfx = null
	var best_i := -1
	var best_d := 4.0
	for n in _live:
		if not is_instance_valid(n):
			continue
		var v := n as ProjectileLibVfx
		if v.move_id != p_move:
			continue
		for i in v.beams.size():
			if v.beams[i]["state"] in ["hit", "miss"]:
				continue
			var d := (v.beams[i]["to"] as Vector3).distance_to(pos)
			if d < best_d:
				best_d = d
				best = v
				best_i = i
	return [best, best_i]


# --- State read by subclasses and tests ------------------------------------------------


func phase() -> Phase:
	if _release_t < 0.0:
		return Phase.START if t < START_LEN else Phase.WINDUP
	var any_impact := false
	var all_done := true
	for b in beams:
		if b["state"] == "hit" and t - float(b["hit_t"]) < IMPACT_LEN:
			any_impact = true
		if b["state"] == "fly":
			all_done = false
	if any_impact:
		return Phase.IMPACT
	if all_done:
		return Phase.POST
	return Phase.RELEASE if t - _release_t < RELEASE_LEN else Phase.TRAJECTORY


func beam_count() -> int:
	return beams.size()


func beam_tip(i: int) -> Vector3:
	var b: Dictionary = beams[i]
	return (b["from"] as Vector3).lerp(b["to"], float(b["p"]))


func impacts_drawn() -> int:
	return _impacts


## 0..1 fade of beam i during POST (0 = solid). Before the end it is 0.
func beam_fade(i: int) -> float:
	var b: Dictionary = beams[i]
	if b["state"] == "hit":
		return clampf((t - float(b["hit_t"]) - IMPACT_LEN) / POST_LEN, 0.0, 1.0)
	if b["state"] == "miss":
		return clampf((t - float(b["hit_t"])) / POST_LEN, 0.0, 1.0)
	return 0.0


## Subclasses: fixed width in metres (D-308 item 6).
func beam_width() -> float:
	return 0.3


# --- Clock -----------------------------------------------------------------------------


func _ensure_built() -> void:
	if not _built:
		_built = true
		_build()


func advance(delta: float) -> void:
	_ensure_built()
	t += delta
	if _release_t < 0.0 and t > windup_len + HOLD_SAFETY:
		queue_free()  # the shot never came (safety)
		return
	if _end_t >= 0.0 and t - _end_t > MISS_GRACE:
		for i in beams.size():
			if beams[i]["state"] == "fly":
				miss(i)
	_render()
	if _release_t >= 0.0 and _finished():
		queue_free()


func _process(delta: float) -> void:
	if not _manual:
		advance(delta)


func _finished() -> bool:
	for i in beams.size():
		if beams[i]["state"] == "fly" or beams[i]["state"] == "charge":
			return false
		if beam_fade(i) < 1.0:
			return false
	return true


# --- To override -----------------------------------------------------------------------


func _build() -> void:
	pass


func _render() -> void:
	pass


## The camera, or a fallback when there is no battle (tests).
func cam_pos() -> Vector3:
	if fx != null and fx.cam != null and fx.cam.camera != null:
		return fx.cam.camera.global_position
	return Vector3(0, 3, 8)


## D-958 (general VFX rule): the point in front of the real body that stands at `pos`, on the axis toward `toward`:
## body radius + 0.45 m ahead, at the body's centre height. Without a battle (tests) it returns `pos`. Never depends on
## the character, the team or the side (D-235): only the nearest real model's bounds.
## D-1021: when the combat hands the real caster model, `front_of_model()` is used instead (audit 4.2).
static func front_of(p_fx: BattleFx, pos: Vector3, toward: Vector3) -> Vector3:
	if p_fx == null:
		return pos
	var best: Node3D = null
	var best_d := 3.0
	for m in p_fx._models.values():
		if not is_instance_valid(m):
			continue
		var d := Vector2((m as Node3D).global_position.x - pos.x, (m as Node3D).global_position.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = m
	return front_of_model(best, pos, toward)


## D-1021: the measurement from the model the combat handed to the effect (never the nearest one). Centre height,
## used by Electric and every other Move.
static func front_of_model(best: Node3D, pos: Vector3, toward: Vector3) -> Vector3:
	return front_of_model_at_height(best, pos, toward, false)


## D-1021: the point on the FLOOR in front of the body, on the shot axis. Water starts with a ground vortex and a wave
## that rises from it (Nami's R), so the base must be the floor, not the body's centre.
static func front_of_ground_model(best: Node3D, pos: Vector3, toward: Vector3) -> Vector3:
	return front_of_model_at_height(best, pos, toward, true)


static func front_of_model_at_height(best: Node3D, pos: Vector3, toward: Vector3, on_ground: bool) -> Vector3:
	var flat := Vector3(pos.x, 0.0, pos.z)
	var fwd := Vector3(toward.x - pos.x, 0.0, toward.z - pos.z)
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	if best == null or not is_instance_valid(best):
		return flat + fwd * 0.9 + Vector3.UP * (0.02 if on_ground else 1.0)
	var box := AABB()
	var first := true
	for mi in best.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or String(m3.name) in ["BurstRing", "ReadyRing"] or String(m3.name).begins_with("Guard") or String(m3.name).begins_with("Shield"):
			continue
		var b := m3.global_transform * m3.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return flat + fwd * 0.9 + Vector3.UP * (0.02 if on_ground else 1.0)
	var c := box.get_center()
	# D-960: the body's real half-extent ALONG the shot (a long body would otherwise swallow the charge) and across it.
	var r := absf(fwd.x) * box.size.x * 0.5 + absf(fwd.z) * box.size.z * 0.5
	var across := absf(fwd.z) * box.size.x * 0.5 + absf(fwd.x) * box.size.z * 0.5
	_last_body_r = maxf(r, across)
	# D-964: straight AHEAD of the body on the shot axis, never to the side (the camera never moves it), with a clear
	# gap from the body so it reads as in front from any angle.
	# D-965: centred on the model's own origin (its pivot), not on the bounding box (a tail skews the box).
	var o := best.global_position
	var r_o := r + absf((Vector3(c.x, 0.0, c.z) - Vector3(o.x, 0.0, o.z)).dot(fwd))
	var h := (box.position.y + 0.02) if on_ground else c.y
	return Vector3(o.x, 0.0, o.z) + fwd * (r_o + FRONT_GAP) + Vector3.UP * h


## D-970: the real body nearest to `pos` (a target): [floor centre, horizontal radius, height]. Never by character (D-235).
static func body_of(p_fx: BattleFx, pos: Vector3) -> Array:
	var fallback := [Vector3(pos.x, pos.y - 1.0, pos.z), 0.6, 1.6]
	if p_fx == null:
		return fallback
	var best: Node3D = null
	var best_d := 3.0
	for m in p_fx._models.values():
		if not is_instance_valid(m):
			continue
		var d := Vector2((m as Node3D).global_position.x - pos.x, (m as Node3D).global_position.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = m
	return body_of_model(best, pos)


## D-1021: the body measurement from the model the combat handed to the effect (never the nearest one).
static func body_of_model(best: Node3D, pos: Vector3) -> Array:
	var fallback := [Vector3(pos.x, pos.y - 1.0, pos.z), 0.6, 1.6]
	if best == null or not is_instance_valid(best):
		return fallback
	var box := AABB()
	var first := true
	for mi in best.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or String(m3.name) in ["BurstRing", "ReadyRing"] or String(m3.name).begins_with("Guard") or String(m3.name).begins_with("Shield"):
			continue
		var b := m3.global_transform * m3.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return fallback
	var o := best.global_position
	return [Vector3(o.x, box.position.y, o.z), maxf(box.size.x, box.size.z) * 0.5, box.size.y]
