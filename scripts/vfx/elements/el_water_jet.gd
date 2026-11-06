class_name ElWaterJet
extends ElementEffect
## D-274: WATER reference recipe, "jet with splash". A continuous curved stream shoots from the origin to the
## destination (it keeps its continuity, stretches and ripples), sheds ballistic drops, then breaks on contact
## into a flat ring, water blades that arc out and fall, a crown of drops and a little mist. The stream then
## retracts from the tail. Derived only from ctx (D-235); driven by explicit time.

const TRAVEL := 0.42
const HOLD_END := 0.8  ## The head has landed; the stream keeps flowing until here.
const RETRACT_END := 1.15
const POINTS := 26
const BLADES := 7
const RING_POINTS := 28

var _jet: MeshInstance3D
var _ring: MeshInstance3D
var _blades: Array[MeshInstance3D] = []
var _blade_data: Array[Dictionary] = []
var _drops: ElementParticles
var _crown: ElementParticles
var _mist: ElementParticles
var _c1: Vector3
var _c2: Vector3


func _build() -> void:
	duration = 1.7
	# The path bows up in the middle and a little to the side, so it reads as a stream, not a line.
	_c1 = origin.lerp(dest, 0.3) + Vector3(0, 0.9 * unit, 0) + right * (0.3 * unit)
	_c2 = origin.lerp(dest, 0.7) + Vector3(0, 0.75 * unit, 0) - right * (0.2 * unit)
	_jet = _ribbon("el_water", {"seed": rng.randf() * 10.0})
	_ring = _ribbon("el_water", {"seed": rng.randf() * 10.0, "flat_mode": true, "flow": 2.0})
	for i in BLADES:
		var mi := _ribbon("el_water", {"seed": rng.randf() * 10.0})
		_blades.append(mi)
		var ang := TAU * (float(i) + rng.randf_range(-0.2, 0.2)) / float(BLADES)
		_blade_data.append({"dir": flat_dir * cos(ang) + right * sin(ang), "reach": rng.randf_range(0.6, 1.0) * unit, "peak": rng.randf_range(0.5, 0.9) * unit, "delay": rng.randf_range(0.0, 0.06)})
	# Drops shed by the stream on the way: they fly out and fall.
	_drops = _particles(false, 1)
	_drops.gravity = Vector3(0.0, -9.0, 0.0)
	_drops.floor_y = ground_y
	for i in 34:
		var b := rng.randf_range(0.08, HOLD_END)
		var tau := clampf(_head(b) - rng.randf_range(0.0, 0.35), 0.0, 1.0)
		var p := _path(tau)
		var v := right * rng.randf_range(-1.2, 1.2) * unit + Vector3(0, rng.randf_range(0.4, 1.6), 0) * unit + dir * rng.randf_range(0.2, 1.0)
		_drops.emit(p + Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.05, 0.1), rng.randf_range(-0.1, 0.1)) * unit, v, b, rng.randf_range(0.4, 0.7),
			0.1 * unit, 0.06 * unit, Color(0.6, 0.88, 1.0, 1.0), Color(0.85, 0.97, 1.0, 0.0))
	_finish_particles(_drops)
	# The crown of drops that jumps at the contact.
	_crown = _particles(false, 1)
	_crown.gravity = Vector3(0.0, -12.0, 0.0)
	_crown.floor_y = ground_y
	for i in 30:
		var ang2 := rng.randf() * TAU
		var spd := rng.randf_range(1.8, 3.6) * unit
		_crown.emit(Vector3(dest.x, ground_y + 0.1, dest.z), Vector3(cos(ang2) * spd, rng.randf_range(3.0, 5.5) * unit, sin(ang2) * spd), TRAVEL + rng.randf_range(0.0, 0.08),
			rng.randf_range(0.55, 0.8), 0.13 * unit, 0.07 * unit, Color(0.7, 0.92, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0))
	_finish_particles(_crown)
	_mist = _particles(false, 0)
	_mist.gravity = Vector3(0.0, 0.4, 0.0)
	_mist.drag = 1.5
	for i in 9:
		var ang3 := rng.randf() * TAU
		_mist.emit(Vector3(dest.x, ground_y + 0.2, dest.z), Vector3(cos(ang3), 0.5, sin(ang3)) * unit, TRAVEL + rng.randf_range(0.0, 0.2), rng.randf_range(0.6, 0.9),
			0.35 * unit, 0.9 * unit, Color(0.85, 0.95, 1.0, 0.32), Color(0.9, 0.97, 1.0, 0.0))
	_finish_particles(_mist)


func _head(time: float) -> float:
	return ease_out(time / TRAVEL)


func _path(tau: float) -> Vector3:
	return ElementShapes.bezier(origin, _c1, _c2, dest, clampf(tau, 0.0, 1.0))


func _apply(time: float) -> void:
	# The tail stays at the origin while water flows, then follows the head and retracts.
	var tail := smooth((time - HOLD_END) / (RETRACT_END - HOLD_END))
	var head := _head(time)
	var pts := PackedVector3Array()
	var ws := PackedFloat32Array()
	var thick := 0.5 * unit
	for k in POINTS:
		var s := float(k) / float(POINTS - 1)
		var tau := lerpf(tail, head, s)
		pts.append(_path(tau))
		var ripple := 1.0 + 0.16 * sin(tau * 24.0 - time * 16.0)
		var round_end := 1.0
		if s > 0.92:
			round_end = sqrt(maxf(1.0 - pow((s - 0.92) / 0.08, 2.0), 0.0))
		var taper_tail := smooth(s * 6.0)
		ws.append(thick * ripple * round_end * lerpf(0.35, 1.0, taper_tail) + 0.001)
	ElementShapes.set_ribbon(_jet, pts, ws)
	(_jet.material_override as ShaderMaterial).set_shader_parameter("time", time)
	_jet.visible = head > 0.02 and tail < 0.995
	# Ring on the ground.
	var ra := (time - TRAVEL) / 0.7
	if ra < 0.0 or ra > 1.0:
		_ring.visible = false
	else:
		var radius := (0.2 + 1.0 * ease_out(ra)) * unit
		var rp := PackedVector3Array()
		var rw := PackedFloat32Array()
		for k in RING_POINTS + 1:
			var ang := TAU * float(k) / float(RING_POINTS)
			rp.append(Vector3(dest.x + cos(ang) * radius, ground_y + 0.03, dest.z + sin(ang) * radius))
			rw.append(0.16 * unit * (1.0 - ra) + 0.001)
		ElementShapes.set_ribbon(_ring, rp, rw)
		var rm := _ring.material_override as ShaderMaterial
		rm.set_shader_parameter("time", time)
		rm.set_shader_parameter("fade", smooth((ra - 0.55) / 0.45))
	# Water blades: flat sheets that arc out and fall back.
	for i in _blades.size():
		var d := _blade_data[i]
		var a := (time - TRAVEL - float(d["delay"])) / 0.55
		var mi := _blades[i]
		if a < 0.0 or a > 1.0:
			mi.visible = false
			continue
		var bp := PackedVector3Array()
		var bw := PackedFloat32Array()
		for k in 8:
			var s := float(k) / 7.0
			var reach := float(d["reach"]) * s * ease_out(a * 1.6)
			var h := sin(PI * s) * float(d["peak"]) * sin(PI * a) * 0.9
			bp.append(Vector3(dest.x, ground_y + 0.05, dest.z) + Vector3(d["dir"]) * reach + Vector3(0, h, 0))
			bw.append(0.22 * unit * sin(PI * clampf(0.1 + 0.8 * s, 0.0, 1.0)) * (1.0 - a * 0.5) + 0.001)
		ElementShapes.set_ribbon(mi, bp, bw)
		var bm := mi.material_override as ShaderMaterial
		bm.set_shader_parameter("time", time)
		bm.set_shader_parameter("fade", smooth((a - 0.6) / 0.4))
	_drops.update(time)
	_crown.update(time)
	_mist.update(time)
