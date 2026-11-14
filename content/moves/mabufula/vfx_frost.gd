extends Node3D

const TAIL := 1.5

var mesh: MeshInstance3D
var mat: ShaderMaterial

func setup(_camera: Camera3D) -> void:
	mat = ShaderMaterial.new()
	mat.shader = preload("res://content/moves/mabufula/frost.gdshader")
	mesh = MeshInstance3D.new()
	mesh.name = "Frost"
	mesh.mesh = PlaneMesh.new()
	mesh.material_override = mat
	add_child(mesh)

func draw(s: Dictionary) -> void:
	mesh.global_position = s.front
	mesh.scale = Vector3.ONE * s.scale
	mat.set_shader_parameter("progress", s.wind)
	mat.set_shader_parameter("fade", s.fade * (1.0 - s.travel))
	mat.set_shader_parameter("phase_time", s.time)
