class_name MotionRibbonsView
extends Node3D
## Representação "Fitas" (D-044): um MeshInstance3D com ArrayMesh reconstruído por quadro e ShaderMaterial
## (.gdshader). Só consome MotionSample, via MotionRibbonBuilder. Neutra: sem brilho nem partículas.

const SHADER_PATH := "res://shaders/motion_lab/motion_ribbon.gdshader"

## Largura de uma fita com largura de amostra 1, em metros.
var ribbon_width: float = 0.03
var triangle_count: int = 0
var strip_count: int = 0

var _mi: MeshInstance3D
var _mesh: ArrayMesh


func _init() -> void:
	_mesh = ArrayMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	_mi = MeshInstance3D.new()
	_mi.mesh = _mesh
	_mi.material_override = mat
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)


func show_samples(samples: Array[MotionSample]) -> void:
	_mesh.clear_surfaces()
	var g := MotionRibbonBuilder.build(samples, ribbon_width)
	triangle_count = g["triangle_count"]
	strip_count = g["strip_count"]
	if triangle_count == 0:
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = g["vertices"]
	arrays[Mesh.ARRAY_COLOR] = g["colors"]
	arrays[Mesh.ARRAY_TEX_UV] = g["uvs"]
	arrays[Mesh.ARRAY_INDEX] = g["indices"]
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# A malha deforma por quadro: limites próprios, para a fita não sumir por corte de visibilidade.
	_mi.custom_aabb = (g["aabb"] as AABB).grow(0.1)
