class_name ElEarthEruption
extends ElementEffect
## D-274: EARTH reference recipe, "fragment eruption". Along the line from the origin to the destination the
## ground erupts one spot after another (progressive emergence): cracks open, stone spikes shoot up and hold,
## chunks are thrown with weight and spin, dust puffs out; then everything lands, rests, and sinks away.
## The last spot, at the destination, is the biggest. Derived only from ctx (D-235); explicit time.

const SPOTS := 5
const EMERGE := 0.14  ## Seconds a spike takes to shoot up.
const HOLD := 0.75
const SINK := 0.45
const SPIKES_PER_SPOT := 3
const CHUNKS_PER_SPOT := 7

var _spot_t: PackedFloat32Array = PackedFloat32Array()
var _spot_pos: PackedVector3Array = PackedVector3Array()
var _spot_size: PackedFloat32Array = PackedFloat32Array()
var _spikes: MultiMeshInstance3D
var _spike_data: Array[Dictionary] = []
var _cracks: Array[MeshInstance3D] = []
var _crack_data: Array[Dictionary] = []
var _chunks: ElementParticles
var _dust: ElementParticles
var _tints: Array[Color] = [Color(0.55, 0.42, 0.28), Color(0.46, 0.36, 0.25), Color(0.62, 0.5, 0.34)]


func _build() -> void:
	duration = 2.0
	for k in SPOTS:
		var tau := lerpf(0.28, 1.0, float(k) / float(SPOTS - 1))
		var jitter := right * rng.randf_range(-0.12, 0.12) * unit
		_spot_pos.append(Vector3(lerpf(origin.x, dest.x, tau), ground_y, lerpf(origin.z, dest.z, tau)) + jitter)
		_spot_t.append(0.1 + 0.075 * float(k))
		_spot_size.append(lerpf(0.65, 1.25, float(k) / float(SPOTS - 1)))
	# Spikes: one MultiMesh, three shapes would need three meshes; one jittered spike mesh is shared.
	var spike_mesh := ElementShapes.spike_mesh(rng)
	_spikes = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = spike_mesh
	mm.instance_count = SPOTS * SPIKES_PER_SPOT
	_spikes.multimesh = mm
	_spikes.material_override = VfxLib.shader_mat("el_rock")
	_spikes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spikes.custom_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 80, 120))
	add_child(_spikes)
	for k in SPOTS:
		for j in SPIKES_PER_SPOT:
			var ang := TAU * (float(j) + rng.randf_range(-0.2, 0.2)) / float(SPIKES_PER_SPOT)
			var off := Vector3(cos(ang), 0.0, sin(ang)) * rng.randf_range(0.15, 0.38) * unit * float(_spot_size[k])
			_spike_data.append({
				"spot": k, "off": off, "height": rng.randf_range(0.7, 1.25) * unit * float(_spot_size[k]),
				"width": rng.randf_range(0.28, 0.42) * unit * float(_spot_size[k]),
				"tilt": Vector3(rng.randf_range(-0.28, 0.28), rng.randf() * TAU, rng.randf_range(-0.28, 0.28)),
				"tint": _tints[rng.randi() % _tints.size()], "delay": rng.randf_range(0.0, 0.06),
			})
	# Ground cracks: dark lines radiating from each spot.
	for k in SPOTS:
		for j in 3:
			var mi := _ribbon("el_line", {"flat_mode": true, "c_core": Vector3(0.08, 0.05, 0.03), "c_edge": Vector3(0.08, 0.05, 0.03), "energy": 1.0})
			_cracks.append(mi)
			var ang2 := TAU * (float(j) + rng.randf_range(-0.3, 0.3)) / 3.0 + rng.randf_range(-0.4, 0.4)
			_crack_data.append({"spot": k, "dir": Vector3(cos(ang2), 0.0, sin(ang2)), "len": rng.randf_range(0.55, 0.95) * unit * float(_spot_size[k])})
	# Thrown chunks with weight and spin; they land, rest and then shrink away.
	_chunks = ElementParticles.new()
	_chunks.billboard = false
	_chunks.gravity = Vector3(0.0, -15.0, 0.0)
	_chunks.floor_y = ground_y + 0.05
	_chunks.settle_after = 99.0
	add_child(_chunks)
	for k in SPOTS:
		for j in CHUNKS_PER_SPOT:
			var ang3 := rng.randf() * TAU
			var spd := rng.randf_range(0.8, 2.6) * unit
			var b := float(_spot_t[k]) + rng.randf_range(0.0, 0.05)
			var sz := rng.randf_range(0.1, 0.24) * unit * float(_spot_size[k])
			var tint: Color = _tints[rng.randi() % _tints.size()].lerp(Color.WHITE, rng.randf() * 0.12)
			_chunks.emit(_spot_pos[k] + Vector3(0, 0.1 * unit, 0), Vector3(cos(ang3) * spd, rng.randf_range(3.5, 6.5) * unit * float(_spot_size[k]), sin(ang3) * spd),
				b, rng.randf_range(1.1, 1.5), sz, sz * 0.15, tint, Color(tint.r, tint.g, tint.b, 1.0),
				Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)), rng.randf_range(-9.0, 9.0))
	_chunks.build(ElementShapes.chunk_mesh(rng), VfxLib.shader_mat("el_rock"))
	# Dust.
	_dust = _particles(false, 0)
	_dust.gravity = Vector3(0.0, 0.3, 0.0)
	_dust.drag = 1.8
	for k in SPOTS:
		for j in 4:
			var ang4 := rng.randf() * TAU
			_dust.emit(_spot_pos[k] + Vector3(0, 0.12 * unit, 0), Vector3(cos(ang4), 0.4, sin(ang4)) * unit * 1.2, float(_spot_t[k]) + rng.randf_range(0.0, 0.1),
				rng.randf_range(0.6, 0.95), 0.35 * unit * float(_spot_size[k]), 0.95 * unit * float(_spot_size[k]), Color(0.62, 0.52, 0.4, 0.5), Color(0.66, 0.56, 0.45, 0.0))
	_finish_particles(_dust)


func _apply(time: float) -> void:
	var mm := _spikes.multimesh
	var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, -200, 0))
	for i in _spike_data.size():
		var d := _spike_data[i]
		var k: int = d["spot"]
		var a := time - float(_spot_t[k]) - float(d["delay"])
		if a < 0.0 or a > EMERGE + HOLD + SINK:
			mm.set_instance_transform(i, hidden)
			continue
		var grow := 1.0
		if a < EMERGE:
			var x := a / EMERGE
			grow = 1.0 + 0.18 * sin(PI * x) * x  # Shoots up a bit past its height and settles.
			grow *= ease_out(x)
		var sink := smooth((a - EMERGE - HOLD) / SINK)
		var tilt: Vector3 = d["tilt"]
		var basis := Basis.from_euler(Vector3(tilt.x, tilt.y, tilt.z)).scaled(Vector3(float(d["width"]), float(d["height"]) * grow, float(d["width"])))
		var pos: Vector3 = Vector3(_spot_pos[k]) + Vector3(d["off"]) - Vector3(0, sink * float(d["height"]) * 1.05, 0)
		mm.set_instance_transform(i, Transform3D(basis, pos))
		mm.set_instance_color(i, Color(d["tint"]))
	for i in _cracks.size():
		var d := _crack_data[i]
		var k: int = d["spot"]
		var a := (time - float(_spot_t[k])) / 1.5
		var mi := _cracks[i]
		if a < 0.0 or a > 1.0:
			mi.visible = false
			continue
		var reach := float(d["len"]) * ease_out(a * 6.0)
		var pts := PackedVector3Array()
		var ws := PackedFloat32Array()
		for s in 6:
			var f := float(s) / 5.0
			var zig := Vector3(d["dir"]).cross(Vector3.UP) * sin(f * 9.0 + float(i)) * 0.05 * unit
			pts.append(_spot_pos[k] + Vector3(0, 0.03, 0) + Vector3(d["dir"]) * (reach * f) + zig)
			ws.append(0.07 * unit * (1.0 - f * 0.7) + 0.001)
		ElementShapes.set_ribbon(mi, pts, ws)
		(mi.material_override as ShaderMaterial).set_shader_parameter("fade", smooth((a - 0.6) / 0.4))
	_chunks.update(time)
	_dust.update(time)
