class_name ElFireStream
extends ElementEffect
## D-274: FIRE reference recipe, "projected flame". A teardrop mass of flame flies from the origin to the
## destination, sheds tongues that rise and die, throws embers, then spreads low flames across the ground and
## leaves smoke and ash. Layers: main body, hot core, tongues, embers, contact spread, smoke, ash.
## Derived only from ctx (D-235); driven by explicit time.

const TRAVEL := 0.5
const SPREAD_LIFE := 0.55
const BODY_POINTS := 22
const TONGUES := 7
const GROUND_TONGUES := 5

var _body: MeshInstance3D
var _core: MeshInstance3D
var _tongues: Array[MeshInstance3D] = []
var _tongue_data: Array[Dictionary] = []
var _ground: Array[MeshInstance3D] = []
var _ground_data: Array[Dictionary] = []
var _embers: ElementParticles
var _flash: ElementParticles
var _smoke: ElementParticles
var _ash: ElementParticles


func _build() -> void:
	duration = 1.7
	_body = _ribbon("el_flame", {"seed": rng.randf() * 10.0})
	_core = _ribbon("el_flame", {
		"seed": rng.randf() * 10.0, "energy": 1.7,
		"c_core": Vector3(1.0, 1.0, 0.85), "c_mid": Vector3(1.0, 0.92, 0.45), "c_edge": Vector3(1.0, 0.7, 0.2),
	})
	for i in TONGUES:
		var mi := _ribbon("el_flame", {"seed": rng.randf() * 10.0, "wobble": 0.7})
		_tongues.append(mi)
		_tongue_data.append({
			"born": rng.randf_range(0.04, TRAVEL * 0.85), "life": rng.randf_range(0.3, 0.45),
			"back": rng.randf_range(0.02, 0.18), "drift": right * rng.randf_range(-0.35, 0.35) * unit,
			"rise": rng.randf_range(0.5, 0.9) * unit,
		})
	for i in GROUND_TONGUES:
		var mi := _ribbon("el_flame", {"seed": rng.randf() * 10.0, "flat_mode": true, "wobble": 0.4})
		_ground.append(mi)
		var ang := TAU * (float(i) + rng.randf_range(-0.25, 0.25)) / float(GROUND_TONGUES)
		_ground_data.append({"dir": (flat_dir * cos(ang) + right * sin(ang)), "len": rng.randf_range(0.7, 1.2) * unit, "delay": rng.randf_range(0.0, 0.08)})
	# Embers: they leave the flame while it flies.
	_embers = _particles(true, 2, 1.4)
	_embers.gravity = Vector3(0.0, 0.9, 0.0)
	_embers.drag = 1.2
	for i in 36:
		var b := rng.randf_range(0.03, TRAVEL)
		var p := _path(_head(b))
		var v := Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.5, 1.6), rng.randf_range(-0.6, 0.6)) * unit
		_embers.emit(p + Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.08, 0.1), rng.randf_range(-0.12, 0.12)) * unit,
			v, b, rng.randf_range(0.5, 0.9), 0.11 * unit, 0.0, Color(1.0, 0.75, 0.25, 1.0), Color(1.0, 0.25, 0.05, 0.0))
	for i in 10:  # More at the contact.
		var b2 := TRAVEL + rng.randf_range(0.0, 0.25)
		var ang2 := rng.randf() * TAU
		_embers.emit(dest + Vector3(0, -0.2 * unit, 0), Vector3(cos(ang2) * 1.8, rng.randf_range(1.0, 2.6), sin(ang2) * 1.8) * unit, b2,
			rng.randf_range(0.5, 0.9), 0.1 * unit, 0.0, Color(1.0, 0.8, 0.3, 1.0), Color(1.0, 0.3, 0.05, 0.0))
	_finish_particles(_embers)
	# Flash at the contact.
	_flash = _particles(true, 0, 1.2)
	_flash.pos_fn = Callable()
	_flash.emit(dest, Vector3.ZERO, TRAVEL - 0.03, 0.22, 0.9 * unit, 2.2 * unit, Color(1.0, 0.85, 0.45, 0.9), Color(1.0, 0.4, 0.1, 0.0))
	_finish_particles(_flash)
	# Smoke rises after the contact; ash falls slowly.
	_smoke = _particles(false, 0)
	_smoke.gravity = Vector3(0.0, 0.7, 0.0)
	_smoke.drag = 1.0
	for i in 12:
		var b3 := TRAVEL + 0.1 + rng.randf_range(0.0, 0.45)
		_smoke.emit(dest + Vector3(rng.randf_range(-0.4, 0.4), -0.3 * unit, rng.randf_range(-0.4, 0.4)) * unit, Vector3(0, 0.6, 0) * unit, b3,
			rng.randf_range(0.7, 1.0), 0.3 * unit, 0.9 * unit, Color(0.2, 0.18, 0.18, 0.5), Color(0.3, 0.28, 0.28, 0.0))
	_finish_particles(_smoke)
	_ash = _particles(false, 1)
	_ash.gravity = Vector3(0.0, -0.5, 0.0)
	_ash.drag = 1.5
	for i in 14:
		var b4 := TRAVEL + 0.05 + rng.randf_range(0.0, 0.5)
		var ang4 := rng.randf() * TAU
		_ash.emit(dest + Vector3(0, 0.1 * unit, 0), Vector3(cos(ang4), rng.randf_range(0.8, 2.0), sin(ang4)) * unit, b4,
			rng.randf_range(0.7, 1.0), 0.05 * unit, 0.03 * unit, Color(0.25, 0.22, 0.22, 0.9), Color(0.25, 0.22, 0.22, 0.0))
	_finish_particles(_ash)


## Progress of the head along the path: fast start, soft arrival, then stays.
func _head(time: float) -> float:
	return ease_out(time / TRAVEL)


func _path(tau: float) -> Vector3:
	var p := origin.lerp(dest, tau)
	p.y += sin(PI * tau) * 0.22 * unit
	return p


func _apply(time: float) -> void:
	var h := _head(time)
	var erode := smooth((time - TRAVEL) / 0.4)
	_set_body(_body, h, erode, 0.9 * unit, time, 1.0)
	_set_body(_core, h, minf(erode * 1.3, 1.0), 0.36 * unit, time, 0.8)
	_body.visible = erode < 0.98 and h > 0.01
	_core.visible = _body.visible
	for i in _tongues.size():
		var d := _tongue_data[i]
		var a := (time - float(d["born"])) / float(d["life"])
		var mi := _tongues[i]
		if a < 0.0 or a > 1.0:
			mi.visible = false
			continue
		var base := _path(clampf(_head(float(d["born"])) - float(d["back"]), 0.0, 1.0))
		var pts := PackedVector3Array()
		var ws := PackedFloat32Array()
		for k in 7:
			var s := float(k) / 6.0
			pts.append(base + Vector3(0, float(d["rise"]) * a * s, 0) + Vector3(d["drift"]) * a * s)
			ws.append(0.5 * unit * pow(1.0 - s, 0.6) * (1.0 - a * 0.4) + 0.001)
		ElementShapes.set_ribbon(mi, pts, ws)
		(mi.material_override as ShaderMaterial).set_shader_parameter("time", time)
		(mi.material_override as ShaderMaterial).set_shader_parameter("erode", a * a)
	for i in _ground.size():
		var d := _ground_data[i]
		var a := (time - TRAVEL - float(d["delay"])) / SPREAD_LIFE
		var mi := _ground[i]
		if a < 0.0 or a > 1.0:
			mi.visible = false
			continue
		var reach := float(d["len"]) * ease_out(a * 2.5)
		var pts := PackedVector3Array()
		var ws := PackedFloat32Array()
		for k in 8:
			var s := float(k) / 7.0
			pts.append(Vector3(dest.x, ground_y + 0.04, dest.z) + Vector3(d["dir"]) * (reach * s))
			ws.append(0.6 * unit * (0.35 + 0.65 * sin(PI * clampf(0.15 + 0.85 * s, 0.0, 1.0))) + 0.001)
		ElementShapes.set_ribbon(mi, pts, ws)
		(mi.material_override as ShaderMaterial).set_shader_parameter("time", time)
		(mi.material_override as ShaderMaterial).set_shader_parameter("erode", smooth((a - 0.35) / 0.65))
	_embers.update(time)
	_flash.update(time)
	_smoke.update(time)
	_ash.update(time)


## Fills a body ribbon: a teardrop trailing behind the head.
func _set_body(mi: MeshInstance3D, h: float, erode: float, base_w: float, time: float, len_k: float) -> void:
	var rel_len := clampf(1.5 * unit * len_k / dist, 0.25, 0.65)
	var tail := maxf(h - rel_len, 0.0)
	var pts := PackedVector3Array()
	var ws := PackedFloat32Array()
	for k in BODY_POINTS:
		var s := float(k) / float(BODY_POINTS - 1)  # 0 tail .. 1 head
		pts.append(_path(lerpf(tail, h, s)))
		var round_end := 1.0
		if s > 0.9:
			round_end = sqrt(maxf(1.0 - pow((s - 0.9) / 0.1, 2.0), 0.0))
		ws.append(base_w * pow(s, 0.6) * round_end + 0.001)
	ElementShapes.set_ribbon(mi, pts, ws)
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("time", time)
	mat.set_shader_parameter("erode", erode)
