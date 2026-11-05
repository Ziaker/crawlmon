class_name MotionFragmentsView
extends Node3D
## Representação "Fragmentos" (D-044): estilhaços angulares em um MultiMeshInstance3D com ShaderMaterial
## (.gdshader). Cada fragmento é orientado pela base da amostra (eixo longo = tangente) com um giro e uma
## inclinação fixos por elemento (hash do id: estável no tempo) e um tamanho de 60 % a 140 % do base.
## Só consome MotionSample; neutra: sem brilho nem partículas auxiliares (§8.3).

const SHADER_PATH := "res://shaders/motion_lab/motion_fragment.gdshader"

## Comprimento-base de um fragmento com largura de amostra 1, em metros (a malha tem 1,6 unidade).
var fragment_size: float = 0.05
var shown_count: int = 0

var _mmi: MultiMeshInstance3D
var _mm: MultiMesh
var _capacity: int = 0


func _init() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var mesh := make_shard_mesh()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mesh.surface_set_material(0, mat)
	_mm.mesh = mesh
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)


## Bipirâmide achatada (6 faces triangulares com vértices próprios e normais planas): comprida em Z,
## larga em X, fina em Y. Enrolamento horário (face frontal do Godot).
static func make_shard_mesh() -> ArrayMesh:
	var tip := Vector3(0, 0, 1.0)
	var tail := Vector3(0, 0, -0.6)
	var ring := [Vector3(0.35, 0.0, 0.0), Vector3(-0.25, 0.09, 0.0), Vector3(-0.25, -0.09, 0.0)]
	var tris: Array = []
	for i in 3:
		tris.append([tip, ring[i], ring[(i + 1) % 3]])
		tris.append([tail, ring[(i + 1) % 3], ring[i]])
	var center := Vector3.ZERO
	for t in tris:
		for v in t:
			center += v
	center /= float(tris.size() * 3)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for t in tris:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var c: Vector3 = t[2]
		var out_n := (c - a).cross(b - a).normalized()  # horário visto de fora
		if out_n.dot((a + b + c) / 3.0 - center) < 0.0:
			var tmp := b
			b = c
			c = tmp
			out_n = (c - a).cross(b - a).normalized()
		verts.append_array(PackedVector3Array([a, b, c]))
		for k in 3:
			normals.append(out_n)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Base de um fragmento: base da amostra × giro e inclinação por elemento × escala uniforme.
static func fragment_basis(s: MotionSample, size: float) -> Basis:
	var lo := s.element_id & 0xFFFFFFFF
	var hi := s.element_id >> 32
	var roll := TAU * MotionHash.float01(0, lo, hi, 21)
	var tilt := (MotionHash.float01(0, lo, hi, 22) - 0.5) * PI * 0.6
	var k := size * maxf(s.width, 0.0) * (0.6 + 0.8 * MotionHash.float01(0, lo, hi, 23))
	return s.basis.orthonormalized() * Basis(Vector3.BACK, roll) * Basis(Vector3.RIGHT, tilt) * Basis.from_scale(Vector3.ONE * k)


func show_samples(samples: Array[MotionSample]) -> void:
	var need := samples.size()
	if need > _capacity:
		_capacity = maxi(need, _capacity * 2)
		_mm.instance_count = _capacity
	var n := 0
	for s in samples:
		if not s.visible or s.opacity <= 0.001 or s.width * fragment_size <= 1e-5:
			continue
		var c := MotionPointsView.branch_color(s.branch)
		var glow := clampf(s.intensity, 0.0, 1.5)
		c = Color(c.r * glow, c.g * glow, c.b * glow, clampf(s.opacity, 0.0, 1.0))
		_mm.set_instance_transform(n, Transform3D(fragment_basis(s, fragment_size), s.position))
		_mm.set_instance_color(n, c)
		n += 1
	_mm.visible_instance_count = n
	shown_count = n
