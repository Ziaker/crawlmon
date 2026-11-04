class_name MotionPointsView
extends Node3D
## Representação "Pontos" (D-044): um MultiMeshInstance3D com ShaderMaterial (.gdshader). Só consome
## MotionSample; não decide nada do movimento (§2.1). Neutra: sem brilho nem partículas auxiliares.

const SHADER_PATH := "res://shaders/motion_lab/motion_point.gdshader"

## Raio de um ponto com largura 1, em metros.
var point_size: float = 0.02
## Quantas instâncias foram desenhadas no último quadro (inspeção).
var shown_count: int = 0

var _mmi: MultiMeshInstance3D
var _mm: MultiMesh
var _capacity: int = 0


func _init() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mesh.material = mat
	_mm.mesh = mesh
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)


## Matiz estável por ramo: ramos de uma bifurcação ficam distinguíveis a olho.
static func branch_color(branch: String) -> Color:
	if branch == "root":
		return Color(0.86, 0.92, 1.0)
	return Color.from_hsv(float(branch.hash() & 0xFFFF) / 65535.0, 0.6, 1.0)


func show_samples(samples: Array[MotionSample]) -> void:
	var need := samples.size()
	if need > _capacity:
		_capacity = maxi(need, _capacity * 2)
		_mm.instance_count = _capacity
	var n := 0
	for s in samples:
		var size := point_size * s.width
		if not s.visible or s.opacity <= 0.001 or size <= 1e-5:
			continue
		var c := branch_color(s.branch)
		var glow := clampf(s.intensity, 0.0, 1.5)
		c = Color(c.r * glow, c.g * glow, c.b * glow, clampf(s.opacity, 0.0, 1.0))
		_mm.set_instance_transform(n, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), s.position))
		_mm.set_instance_color(n, c)
		n += 1
	_mm.visible_instance_count = n
	shown_count = n
