class_name MeleePhaseVfx
extends Node3D
## REJECTED (D-953, 2026-11-06): the melee effect and its Hit-windup prelude were discarded by the creator
## ("o problema é o motion em si"). This file is kept only as a reference experiment; no battle code spawns it.
##
## D-953: the Composer de Fases in the REAL battle, for the debug melee Move "Melee Phase".
## It draws the same tackle_rush_effect used by the lab, driven by the real Incoming phases (D-019):
## wind-up → (post-wind-up) → release → travel → impact → return. It never decides damage, hit, evade or
## duration; it only reads the Battle clock and the real models (D-019, D-235). The generic melee VFX for
## this debug move is suppressed in FxMotion/BattleFx so the two layers do not stack.

const BODY := 1.2  ## fixed anchor height in metres (the effect size itself is fixed in the preset, D-334)

var fx: BattleFx
var inc: Object
var _effect: MotionEffect
var _painter: MotionPainter
var _t := 0.0
var _seed := 0
var _end_t := -1.0
var _skel: Skeleton3D
var _skel_model: Node3D


static func windup(p_fx: BattleFx, p_inc) -> MeleePhaseVfx:
	var v := MeleePhaseVfx.new()
	v.fx = p_fx
	v.inc = p_inc
	v._seed = randi()
	v.name = "MeleePhaseVfx"
	p_fx.add_child(v)
	return v


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3:
		return fx.cam.camera.global_position if fx != null and fx.cam != null and fx.cam.camera != null else Vector3(0, 3, 8)
	_painter.cam_basis_fn = func() -> Basis:
		return fx.cam.camera.global_transform.basis if fx != null and fx.cam != null and fx.cam.camera != null else Basis.IDENTITY
	add_child(_painter)
	_effect = MotionPresets.tackle_rush_effect(_seed)


func _process(delta: float) -> void:
	if fx == null or not is_instance_valid(fx) or inc == null or not is_instance_valid(inc):
		queue_free()
		return
	_t += delta
	if inc.phase == Battle.Phase.DONE:
		if _end_t < 0.0:
			_end_t = _t
		elif _t - _end_t > 1.3:
			queue_free()
			return
	_draw_frame()
	if _t > 10.0:
		queue_free()


func _draw_frame() -> void:
	var a_model: Node3D = fx._models.get(inc.attacker)
	var t_model: Node3D = fx._models.get(inc.target)
	if a_model == null or t_model == null or not is_instance_valid(a_model) or not is_instance_valid(t_model):
		return
	var a_pos := a_model.global_position
	var t_pos := t_model.global_position
	var axis := Vector3(t_pos.x - a_pos.x, 0.0, t_pos.z - a_pos.z)
	axis = axis.normalized() if axis.length() > 0.01 else Vector3.FORWARD
	var origin := Vector3(a_pos.x, BODY, a_pos.z)
	var dest := Vector3(t_pos.x, BODY, t_pos.z)
	# Provisional debug scale: a fixed 5 m burst is unreadable on the far enemy side (D-308's old problem).
	# It is derived from the real camera distance, never from a character/team/side (D-235). The lab keeps
	# the fixed-world version; this is a game-side readability choice to be confirmed.
	var sc := 1.0
	if fx.cam != null and fx.cam.camera != null:
		sc = clampf(fx.cam.camera.global_position.distance_to(dest) / 12.0, 1.0, 2.6)
	var head := origin
	var p := 0.0
	_painter.time = _t
	_painter.begin_frame()
	match inc.phase:
		Battle.Phase.WINDUP:
			var wt := float(inc.phase_time)
			var windup := maxf(float(inc.total_windup), 0.01)
			var kw := clampf(wt / windup, 0.0, 1.0)
			var geo := _geo(origin, dest, head, axis, p, false, kw, sc)
			_effect.draw(_painter, "windup", wt, geo)
			var rel_start := maxf(windup - 0.10, 0.0)
			if wt >= rel_start:
				_effect.draw(_painter, "release", wt - rel_start, geo)
		Battle.Phase.TRAVEL:
			var tt := float(inc.phase_time)
			var run_t := maxf(float(inc.run_t), 0.01)
			p = clampf((tt - 0.12) / run_t, 0.0, 1.0)
			head = origin.lerp(dest, p)
			var geo := _geo(origin, dest, head, axis, p, false, p, sc)
			_effect.draw(_painter, "travel", tt, geo)
			if tt <= 0.25:
				_effect.draw(_painter, "release", tt + 0.10, geo)
		Battle.Phase.STRIKE:
			var st := float(inc.phase_time)
			var strike := maxf(float(inc.antic) + float(inc.hit), 0.01)
			var start_at := maxf(strike - 0.25, 0.0)
			# The effect belongs in FRONT of the target body (toward the attacker), not inside it:
			# a big character would otherwise hide the whole burst (D-041 uses the contact point).
			var contact := dest - axis * 2.4
			var limb := _limb_pos(a_model, a_pos, axis)
			var aim := contact - limb
			aim = aim.normalized() if aim.length() > 0.05 else axis
			if st < start_at:
				# Hit-windup / dodge prelude: the 3D tube and charge follow the real limb while the
				# character prepares the strike at 2.6 units. This is the timing the Evade reads.
				var kg := clampf(st / maxf(start_at, 0.01), 0.0, 1.0)
				var pt := kg * 0.60  # the prelude lifecycle is 0.6 s, stretched over the real strike window
				var geo := _geo(limb, contact, limb, aim, 0.0, false, kg, sc)
				_effect.draw(_painter, "prelude", pt, geo)
			else:
				var local := st - start_at
				var ki := clampf(local / strike, 0.0, 1.0)
				var geo := _geo(contact, contact + aim, contact, aim, 1.0, true, ki, sc)
				_effect.draw(_painter, "impact", local, geo)
		Battle.Phase.RETURN:
			var rt := float(inc.phase_time)
			var total := maxf(float(inc.hold) + float(inc.hop_t), 0.01)
			p = clampf(rt / total, 0.0, 1.0)
			head = Vector3(a_pos.x, BODY, a_pos.z)
			var geo := _geo(dest, origin, head, axis, p, true, p, sc)
			_effect.draw(_painter, "return", rt, geo)
		_:
			pass
	_painter.end_frame()


## Real attacking limb: hand/weapon bone of the actual model, generic names only (D-235). If the model has
## no skeleton or no hand, a fixed torso-side fallback keeps the effect working for every character.
func _limb_pos(model: Node3D, body: Vector3, axis: Vector3) -> Vector3:
	if model != _skel_model:
		_skel_model = model
		_skel = null
		var found := model.find_children("*", "Skeleton3D", true, false)
		if not found.is_empty():
			_skel = found[0] as Skeleton3D
	if _skel != null and is_instance_valid(_skel):
		for bone_name in ["weapon", "hand_r", "hand_l", "hand", "j_te_r", "j_te_l", "arm_r", "arm_l", "j_arm_r", "j_arm_l"]:
			var b := _skel.find_bone(bone_name)
			if b >= 0:
				return _skel.global_transform * _skel.get_bone_global_pose(b).origin
	return Vector3(body.x, BODY + 0.35, body.z) + axis * 0.45


func _geo(origin: Vector3, dest: Vector3, head: Vector3, axis: Vector3, p: float, landed: bool, k: float, sc := 1.0) -> Dictionary:
	return {"origin": origin, "dest": dest, "head": head, "axis": axis, "k": clampf(k, 0.0, 1.0),
		"p": p, "scale": sc, "landed": landed}
