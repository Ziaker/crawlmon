class_name ElementParticles
extends MultiMeshInstance3D
## D-274: deterministic particles for the element effects. Every particle is a pure function of the effect's time
## (ballistic with optional drag, or any Callable you give), so the effect can be scrubbed, replayed and A/B
## compared with the same result. One MultiMesh, no GPU simulation, works in GL Compatibility.

var gravity := Vector3(0.0, -9.8, 0.0)
var drag := 0.0  ## Linear drag coefficient (1/s). 0 = none.
var floor_y := -1000.0  ## Particles stop at this height (landed).
var billboard := true  ## Quads face the camera (the shader does it); false = rotate as a rigid piece.
var pos_fn := Callable()  ## Optional (index: int, age: float) -> Vector3, replaces the ballistic path.
var settle_after := -1.0  ## If >= 0: pieces that landed stop spinning.

var _p0 := PackedVector3Array()
var _v0 := PackedVector3Array()
var _birth := PackedFloat32Array()
var _life := PackedFloat32Array()
var _s0 := PackedFloat32Array()
var _s1 := PackedFloat32Array()
var _c0 := PackedColorArray()
var _c1 := PackedColorArray()
var _axis := PackedVector3Array()
var _spin := PackedFloat32Array()


func emit(pos: Vector3, vel: Vector3, birth: float, life: float, size0: float, size1: float, c0: Color, c1: Color, axis := Vector3.UP, spin := 0.0) -> void:
	_p0.append(pos)
	_v0.append(vel)
	_birth.append(birth)
	_life.append(life)
	_s0.append(size0)
	_s1.append(size1)
	_c0.append(c0)
	_c1.append(c1)
	_axis.append(axis.normalized() if axis.length() > 0.0001 else Vector3.UP)
	_spin.append(spin)


func count() -> int:
	return _birth.size()


## Call after all emit() calls. `mesh` is a unit QuadMesh for billboards, or a rock mesh.
func build(mesh: Mesh, material: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = _birth.size()
	multimesh = mm
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 80, 120))
	update(0.0)


static func quad() -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	return q


func update(t: float) -> void:
	var mm := multimesh
	if mm == null:
		return
	var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0.0, -200.0, 0.0))
	for i in _birth.size():
		var a := t - _birth[i]
		if a < 0.0 or a > _life[i]:
			mm.set_instance_transform(i, hidden)
			mm.set_instance_color(i, Color(0, 0, 0, 0))
			continue
		var f := a / maxf(_life[i], 0.0001)
		var pos: Vector3
		if pos_fn.is_valid():
			pos = pos_fn.call(i, a)
		elif drag > 0.0001:
			var k := drag
			var g := gravity / k
			pos = _p0[i] + g * a + (_v0[i] - g) * ((1.0 - exp(-k * a)) / k)
		else:
			pos = _p0[i] + _v0[i] * a + gravity * (0.5 * a * a)
		var landed := false
		if pos.y < floor_y:
			pos.y = floor_y
			landed = true
		var size := lerpf(_s0[i], _s1[i], f)
		var basis := Basis.from_scale(Vector3.ONE * size)
		if not billboard:
			var ang := _spin[i] * a
			if landed and settle_after >= 0.0:
				ang = _spin[i] * minf(a, settle_after)
			basis = Basis(_axis[i], ang).scaled(Vector3.ONE * size)
		mm.set_instance_transform(i, Transform3D(basis, pos))
		mm.set_instance_color(i, _c0[i].lerp(_c1[i], f))
