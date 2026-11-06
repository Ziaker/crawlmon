class_name ElAirGust
extends ElementEffect
## D-274: AIR reference recipe, "curved gust". Tapered streamers accelerate from the origin to the destination
## on curved, twisting paths, with gaps that run along them (wind is intermittent), while light motes spiral
## around the flow so the air itself becomes visible. At the destination the gust bursts into a ring of dust
## motes. Derived only from ctx (D-235); driven by explicit time.

const TRAVEL := 0.55
const STREAMERS := 5
const POINTS := 30
const MOTES := 46

var _lines: Array[MeshInstance3D] = []
var _data: Array[Dictionary] = []
var _motes: ElementParticles
var _burst: ElementParticles


func _build() -> void:
	duration = 1.5
	for i in STREAMERS:
		var side_k := (float(i) - float(STREAMERS - 1) * 0.5)
		var wide := i == 0
		var mi := _ribbon("el_line", {
			"seed": rng.randf(), "gaps": rng.randf_range(10.0, 16.0), "flow": rng.randf_range(9.0, 14.0),
			"energy": 1.0, "c_core": Vector3(1.0, 1.0, 1.0), "c_edge": Vector3(0.62, 0.9, 1.0),
		})
		_lines.append(mi)
		_data.append({
			"bulge_side": side_k * 0.5 * unit + rng.randf_range(-0.12, 0.12) * unit,
			"bulge_up": rng.randf_range(0.1, 0.6) * unit, "turns": rng.randf_range(0.8, 1.6),
			"radius": rng.randf_range(0.2, 0.45) * unit, "phase": rng.randf() * TAU,
			"delay": 0.04 * float(i) + rng.randf_range(0.0, 0.03), "length": rng.randf_range(0.4, 0.55),
			"width": (0.5 if wide else rng.randf_range(0.18, 0.3)) * unit,
		})
	# Motes that orbit the flow.
	_motes = _particles(false, 0)
	_motes.pos_fn = Callable(self, "_mote_pos")
	for i in MOTES:
		var b := rng.randf_range(0.0, TRAVEL * 0.9)
		_motes.emit(Vector3.ZERO, Vector3(rng.randf_range(0.0, 1.0), rng.randf_range(0.25, 0.6) * unit, rng.randf() * TAU), b, rng.randf_range(0.5, 0.8),
			0.1 * unit, 0.03 * unit, Color(1, 1, 1, 0.7), Color(0.85, 0.97, 1.0, 0.0))
	_finish_particles(_motes)
	# At the end of the path: a ring of dust motes blown outward along the ground.
	_burst = _particles(false, 1)
	_burst.gravity = Vector3(0.0, -0.6, 0.0)
	_burst.drag = 2.5
	_burst.floor_y = ground_y
	for i in 18:
		var ang := TAU * float(i) / 18.0 + rng.randf_range(-0.15, 0.15)
		var spd := rng.randf_range(2.0, 3.6) * unit
		_burst.emit(Vector3(dest.x, ground_y + 0.15, dest.z), Vector3(cos(ang) * spd, rng.randf_range(0.2, 0.9), sin(ang) * spd), TRAVEL * 0.9 + rng.randf_range(0.0, 0.06),
			rng.randf_range(0.45, 0.7), 0.09 * unit, 0.04 * unit, Color(0.92, 0.97, 1.0, 0.85), Color(1, 1, 1, 0.0))
	_finish_particles(_burst)


## Centre line of streamer `i` at progress tau: a bezier that bulges to one side, with a helical twist.
func _line_point(i: int, tau: float, time: float) -> Vector3:
	var d := _data[i]
	var c1 := origin.lerp(dest, 0.33) + right * float(d["bulge_side"]) + Vector3(0, float(d["bulge_up"]), 0)
	var c2 := origin.lerp(dest, 0.7) + right * float(d["bulge_side"]) * 0.4 + Vector3(0, float(d["bulge_up"]) * 0.6, 0)
	var p := ElementShapes.bezier(origin, c1, c2, dest, clampf(tau, 0.0, 1.0))
	var phi := tau * TAU * float(d["turns"]) + float(d["phase"]) + time * 3.0
	var r := float(d["radius"]) * sin(PI * clampf(tau, 0.0, 1.0))
	return p + right * cos(phi) * r + Vector3(0, sin(phi) * r * 0.8, 0)


func _mote_pos(i: int, age: float) -> Vector3:
	# Each mote rides the flow (progress grows with age) and circles it.
	var spec: Vector3 = _motes._v0[i]
	var tau := clampf(spec.x * 0.5 + age * 1.1, 0.0, 1.0)
	var c1 := origin.lerp(dest, 0.33) + Vector3(0, 0.3 * unit, 0)
	var c2 := origin.lerp(dest, 0.7) + Vector3(0, 0.2 * unit, 0)
	var p := ElementShapes.bezier(origin, c1, c2, dest, tau)
	var phi := spec.z + age * 9.0
	var r := spec.y * sin(PI * tau)
	return p + right * cos(phi) * r + Vector3(0, sin(phi) * r, 0)


func _apply(time: float) -> void:
	for i in STREAMERS:
		var d := _data[i]
		var a := (time - float(d["delay"])) / TRAVEL
		var mi := _lines[i]
		if a <= 0.0 or time - float(d["delay"]) > TRAVEL + 0.55:
			mi.visible = false
			continue
		var head := ease_out(a) if a < 1.0 else 1.0
		var tail_a := smooth((time - float(d["delay"]) - TRAVEL * 0.55) / 0.55)
		var tail := clampf(head - float(d["length"]), 0.0, 1.0)
		tail = maxf(tail, tail_a * head)
		var pts := PackedVector3Array()
		var ws := PackedFloat32Array()
		for k in POINTS:
			var s := float(k) / float(POINTS - 1)
			var tau := lerpf(tail, head, s)
			pts.append(_line_point(i, tau, time))
			ws.append(float(d["width"]) * pow(sin(PI * clampf(s, 0.02, 0.98)), 0.8) + 0.001)
		ElementShapes.set_ribbon(mi, pts, ws)
		var m := mi.material_override as ShaderMaterial
		m.set_shader_parameter("time", time)
		m.set_shader_parameter("fade", smooth((time - float(d["delay"]) - TRAVEL - 0.15) / 0.4))
	_motes.update(time)
	_burst.update(time)
