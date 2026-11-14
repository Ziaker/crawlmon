extends Node3D

const COUNT := 120
const CONE_HALF := 0.48
const DRAG := 0.98
const BASE_TIME := 1.55
const RAMP := 0.14

var _cam: Camera3D
var _shader: Shader
var _parts: Array = []
var _meshes: Array = []

func setup(camera: Camera3D) -> void:
	_cam = camera
	_shader = load("res://content/moves/mabufula/snow.gdshader") as Shader

	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5F3A2B

	var quad := QuadMesh.new()
	quad.size = Vector2.ONE

	for i in range(COUNT):
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false

		var mat := ShaderMaterial.new()
		mat.shader = _shader
		mi.material_override = mat
		add_child(mi)

		_meshes.append(mi)
		_parts.append({
			"theta": rng.randf() * TAU,
			"ar": rng.randf(),
			"offset": rng.randf_range(0.0, 1.8),
			"speed": rng.randf_range(9.5, 16.5),
			"life": rng.randf_range(0.65, 1.25),
			"stagger": float(i) / float(COUNT) * 0.45,
			"size": rng.randf_range(0.45, 0.95),
			"spin": rng.randf_range(-4.0, 4.0),
		})

func draw(s: Dictionary) -> void:
	if not is_instance_valid(_cam):
		return

	var origin: Vector3 = s.front
	var geo: float = float(s.scale)
	var fade: float = float(s.fade)
	var t: float = clampf(float(s.travel), 0.0, 1.0) * BASE_TIME + maxf(float(s.impact), 0.0)

	var axis: Vector3 = (s.axis - Vector3.UP * 0.08 - s.right * 0.15).normalized()
	var ref: Vector3 = Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var tx: Vector3 = axis.cross(ref).normalized()
	var ty: Vector3 = axis.cross(tx).normalized()

	var cam_basis: Basis = _cam.global_transform.basis.orthonormalized()
	var white := Color("#ffffff")
	var cyan := Color("#2de2e6")

	for i in range(COUNT):
		var p: Dictionary = _parts[i]
		var mi: MeshInstance3D = _meshes[i]

		var age: float = t - float(p.stagger)
		if age < 0.0 or age > float(p.life):
			mi.visible = false
			continue

		var life: float = p.life
		var k: float = age / life
		var size: float = float(p.size) * sin(PI * k) * geo
		if size <= 0.0:
			mi.visible = false
			continue

		var ang: float = CONE_HALF * float(p.ar)
		var st: float = sin(ang)
		var dir: Vector3 = (
			tx * (st * cos(float(p.theta)))
			+ ty * (st * sin(float(p.theta)))
			+ axis * cos(ang)
		).normalized()

		var dist: float = float(p.offset) + float(p.speed) * (1.0 - pow(DRAG, age * 60.0)) / 1.2
		var pos: Vector3 = origin + dir * dist * geo

		var alpha: float = (k / RAMP if k < RAMP else pow(1.0 - (k - RAMP) / (1.0 - RAMP), 1.35)) * fade
		var col: Color = white.lerp(cyan, k)

		var b: Basis = Basis(cam_basis.z, float(p.spin) * age) * cam_basis
		b = b.scaled(Vector3(size, size, size))
		mi.visible = true
		mi.global_transform = Transform3D(b, pos)

		var mat: ShaderMaterial = mi.material_override
		mat.set_shader_parameter("color", col)
		mat.set_shader_parameter("alpha", alpha)