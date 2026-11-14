extends Node3D

const SHARD_SHADER := "res://content/moves/mabufula/crystal.gdshader"
const SHARD_SEED := 0x5EED1CE
const GROUPS := 5
const TRAVEL_PER_GROUP := 42
const IMPACT_PER_GROUP := 48
const TOTAL_SHARDS := GROUPS * (TRAVEL_PER_GROUP + IMPACT_PER_GROUP)
const TRAVEL_SPAN := 1.55
const SIM_HZ := 60.0
const SIM_DT := 1.0 / SIM_HZ
const GROUND_Y := 0.0
const BOUNCE_HEIGHT := 0.08
const DRAG_PER_STEP := 0.98
const RESTITUTION_Y := 0.45
const RESTITUTION_XZ := 0.72
const DEAD_SCALE := 0.0001

var _rng := RandomNumberGenerator.new()
var _shards: Array[Dictionary] = []
var _built := false
var _cam: Camera3D
var _mmi: MultiMeshInstance3D

var _travel_color_a := Color(0.878431, 1.0, 1.0)
var _travel_color_b := Color(0.0, 0.658824, 1.0)
var _impact_color_a := Color(1.0, 1.0, 1.0)
var _impact_color_b := Color(0.0, 0.705882, 1.0)


func setup(camera: Camera3D) -> void:
	_cam = camera
	_create_multimesh()


func draw(s: Dictionary) -> void:
	if _mmi == null:
		return
	_ensure_built(s.get("clusters", []))

	var mm := _mmi.multimesh
	if mm == null:
		return

	var proto_time := float(s.get("travel", 0.0)) * TRAVEL_SPAN + maxf(float(s.impact), 0.0)
	var impact_time := float(s.get("impact", -1.0))
	var cam_basis := Basis.IDENTITY
	if is_instance_valid(_cam):
		cam_basis = _cam.global_transform.basis.orthonormalized()
	var dead_xf := Transform3D(Basis.from_scale(Vector3.ONE * DEAD_SCALE), Vector3.ZERO)
	var dead_col := Color(0.0, 0.0, 0.0, 0.0)

	for i in _shards.size():
		var sh: Dictionary = _shards[i]
		var elapsed := 0.0
		var alive := false
		if bool(sh["impact"]):
			if impact_time >= 0.0:
				elapsed = impact_time
				alive = elapsed <= float(sh["life"])
		else:
			elapsed = proto_time - float(sh["birth"])
			alive = elapsed >= 0.0 and elapsed <= float(sh["life"])

		if not alive:
			mm.set_instance_transform(i, dead_xf)
			mm.set_instance_color(i, dead_col)
			continue

		var path: PackedVector3Array = sh["path"]
		var cluster: Vector3 = s.clusters[sh["group"]]
		var pos := cluster + _sample(path, elapsed) * float(s.scale)
		var age := clampf(elapsed / float(sh["life"]), 0.0, 1.0)
		var col_a: Color = sh["color_a"]
		var col_b: Color = sh["color_b"]
		var spin := float(sh["spin"]) * elapsed
		var size := float(sh["size"]) * (1.0 - pow(age, 1.45)) * float(s.scale)
		var basis := cam_basis * Basis(Vector3.BACK, spin) * Basis.from_scale(Vector3.ONE * size)
		mm.set_instance_transform(i, Transform3D(basis, pos))
		var alpha: float = age / 0.14 if age < 0.14 else pow(1.0 - (age - 0.14) / 0.86, 1.35)
		mm.set_instance_color(i, Color(col_a.lerp(col_b, age), alpha * float(s.fade)))


func _create_multimesh() -> void:
	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Shards"
	_mmi.top_level = true
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _make_shard_mesh()
	mm.instance_count = TOTAL_SHARDS
	mm.visible_instance_count = TOTAL_SHARDS
	_mmi.multimesh = mm


func _make_shard_mesh() -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0.0, 0.5, 0.0),
		Vector3(0.25, -0.5, 0.0),
		Vector3(-0.25, -0.5, 0.0),
	])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3.BACK, Vector3.BACK, Vector3.BACK,
	])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _make_shard_material())
	return mesh


func _make_shard_material() -> Material:
	if ResourceLoader.exists(SHARD_SHADER):
		var sh := load(SHARD_SHADER) as Shader
		if sh != null:
			var sm := ShaderMaterial.new()
			sm.shader = sh
			return sm
	var fallback := StandardMaterial3D.new()
	fallback.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fallback.vertex_color_use_as_albedo = true
	fallback.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	return fallback


func _ensure_built(clusters: Array) -> void:
	if _built or clusters.size() < GROUPS:
		return
	_built = true

	

	_rng.seed = SHARD_SEED
	_shards.clear()

	for g in GROUPS:
		var base := Vector3.ZERO
		var birth := 0.42 + 0.11 * float(g)
		for n in TRAVEL_PER_GROUP:
			var sh := _spawn_shard(g, base, false)
			sh["birth"] = birth
			_shards.append(sh)
		for n in IMPACT_PER_GROUP:
			var sh := _spawn_shard(g, base, true)
			sh["birth"] = -1.0
			_shards.append(sh)


func _spawn_shard(g: int, base: Vector3, impact: bool) -> Dictionary:
	var dir: Vector3
	var speed: float
	var gravity: float
	var life: float
	var size: float
	var spin: float
	var origin: Vector3
	var col_a: Color
	var col_b: Color

	if impact:
		dir = _sphere_dir()
		speed = _rng.randf_range(5.5, 13.5)
		gravity = 14.5
		life = _rng.randf_range(0.65, 1.25)
		size = _rng.randf_range(0.55, 1.15)
		spin = _rng.randf_range(-7.0, 7.0)
		origin = base + Vector3(0.0, 1.4, 0.0)
		col_a = _impact_color_a
		col_b = _impact_color_b
	else:
		dir = _hemisphere_dir()
		speed = _rng.randf_range(3.5, 8.2)
		gravity = 9.8
		life = _rng.randf_range(0.55, 0.95)
		size = _rng.randf_range(0.45, 0.95)
		spin = _rng.randf_range(-5.0, 5.0)
		origin = base + Vector3(0.0, 0.2, 0.0)
		col_a = _travel_color_a
		col_b = _travel_color_b

	var v0 := dir * speed
	return {
		"impact": impact,
		"group": g,
		"birth": -1.0,
		"origin": origin,
		"v0": v0,
		"gravity": gravity,
		"life": life,
		"size": size,
		"spin": spin,
		"path": _simulate(origin, v0, gravity, life),
		"color_a": col_a,
		"color_b": col_b,
	}


func _sphere_dir() -> Vector3:
	var z := _rng.randf_range(-1.0, 1.0)
	var a := _rng.randf_range(0.0, TAU)
	var r := sqrt(maxf(0.0, 1.0 - z * z))
	return Vector3(r * cos(a), z, r * sin(a))


func _hemisphere_dir() -> Vector3:
	var y := _rng.randf()
	var a := _rng.randf_range(0.0, TAU)
	var r := sqrt(maxf(0.0, 1.0 - y * y))
	return Vector3(r * cos(a), y, r * sin(a))


func _simulate(origin: Vector3, v0: Vector3, gravity: float, life: float) -> PackedVector3Array:
	var count := int(ceil(life * SIM_HZ)) + 1
	var path := PackedVector3Array()
	path.resize(count)
	var p := origin
	var v := v0
	path[0] = p

	for i in range(1, count):
		v.y -= gravity * SIM_DT
		v *= DRAG_PER_STEP
		p += v * SIM_DT

		if p.y < GROUND_Y + BOUNCE_HEIGHT:
			p.y = GROUND_Y + BOUNCE_HEIGHT
			if v.y < 0.0:
				v.y = -v.y * RESTITUTION_Y
			v.x *= RESTITUTION_XZ
			v.z *= RESTITUTION_XZ

		path[i] = p

	return path


func _sample(path: PackedVector3Array, t: float) -> Vector3:
	var n := path.size()
	if n == 0:
		return Vector3.ZERO
	var f := t * SIM_HZ
	var i := int(f)
	if i >= n - 1:
		return path[n - 1]
	return path[i].lerp(path[i + 1], f - float(i))