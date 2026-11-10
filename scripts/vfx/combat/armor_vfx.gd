class_name ArmorVfx
extends Node3D
## D-1026: the particle layer of Armored Bulk (option A) and of the ARMOR break. It paints a MotionEffect (Motion Composer,
## D-308) and only supplies what the game knows: the real feet / chest of the real body, the clocks and the camera. It
## never touches the combat timeline (D-019) and knows no character, team or side (D-235): everything is derived from the body.

enum Mode { BULK, BREAK, AURA }

const RELEASE_AT := 0.38  ## the chrome wave reaches the head; the release (ring, flash, sparks) happens now
const LIFE_BULK := 2.0
const LIFE_BREAK := 1.0

var fx: BattleFx
var mode := Mode.BULK
var origin := Vector3.ZERO  ## BULK: the floor under the body; BREAK: the chest
var body_h := 1.6  ## measured height of the real body (m); the preset is authored for a 1.6 m body
var t := 0.0
var follow: Node3D = null  ## AURA: the real model it hangs on
var owner_c: Combatant = null  ## AURA: lives while this combatant is armored

var _effect: MotionEffect
var _painter: MotionPainter
var _sc := 1.0


static func spawn(p_fx: BattleFx, p_mode: Mode, p_origin: Vector3, p_body_h: float) -> ArmorVfx:
	var v := ArmorVfx.new()
	v.name = "ArmorVfx%s" % Mode.keys()[p_mode].capitalize()
	v.fx = p_fx
	v.mode = p_mode
	v.origin = p_origin
	v.body_h = p_body_h
	p_fx.add_child(v)
	return v


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return fx.cam.camera.global_position if fx != null and fx.cam != null and fx.cam.camera != null else Vector3(0, 3, 8)
	_painter.cam_basis_fn = func() -> Basis: return fx.cam.camera.global_transform.basis if fx != null and fx.cam != null and fx.cam.camera != null else Basis.IDENTITY
	add_child(_painter)
	_effect = MotionPresets.effect_for(["armored_bulk", "armor_break", "armor_aura"][mode], randi())
	# The preset is authored for a 1.6 m body: it scales with the REAL body (the far bodies of the field are already drawn bigger),
	# so the effect has the same proportion to the character in both views, whatever the character, team or side (D-235).
	_sc = clampf(body_h / 1.6, 0.5, 3.5)


func _process(delta: float) -> void:
	t += delta
	_painter.time = t
	_painter.begin_frame()
	if mode == Mode.AURA:
		if follow == null or not is_instance_valid(follow) or owner_c == null or not owner_c.is_armored():
			queue_free()
			return
		origin = Vector3(follow.global_position.x, 0.0, follow.global_position.z)
	var geo := {"origin": origin, "dest": origin, "head": origin, "axis": Vector3.FORWARD, "k": 0.0, "p": 0.0, "scale": _sc, "landed": false}
	if mode == Mode.BULK:
		if t < RELEASE_AT + 0.25:
			_effect.draw(_painter, "windup", t, geo)
		if t >= RELEASE_AT:
			var rt := t - RELEASE_AT
			geo["k"] = clampf(rt / 0.55, 0.0, 1.0)
			_effect.draw(_painter, "impact", rt, geo)
	elif mode == Mode.AURA:
		_effect.draw(_painter, "aura", t, geo)
	else:
		geo["k"] = clampf(t / 0.45, 0.0, 1.0)
		_effect.draw(_painter, "break", t, geo)
	_painter.end_frame()
	if mode != Mode.AURA and t >= (LIFE_BULK if mode == Mode.BULK else LIFE_BREAK):
		queue_free()


## The sparkles of the ARMOR aura: they follow the real model and stop when the badge ends.
static func spawn_aura(p_fx: BattleFx, c: Combatant, model: Node3D, p_body_h: float) -> ArmorVfx:
	var v := spawn(p_fx, Mode.AURA, Vector3(model.global_position.x, 0.0, model.global_position.z), p_body_h)
	v.follow = model
	v.owner_c = c
	return v
