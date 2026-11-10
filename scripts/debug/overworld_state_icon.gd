extends Node3D
## D-1098: Ã­cone de estado 3D (frente texturizada + lateral/fundo escuros).
##
## A frente mantÃ©m a arte 2D original (UV), mas o Ã­cone tem espessura real,
## laterais escuras e um leve yaw para o volume aparecer.

const ICON_DIR := "res://assets/ui/overworld_icons3d"
const YAW := deg_to_rad(-28.0)

var _front: MeshInstance3D
var _side: MeshInstance3D
var _front_mat: StandardMaterial3D
var _side_mat: StandardMaterial3D
var _texture: Texture2D
var _tint := Color.WHITE
var _time := 0.0
var _key := ""


func setup(texture: Texture2D, tint: Color) -> void:
	_front = MeshInstance3D.new()
	_front.name = "Front"
	_front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_front)

	_side = MeshInstance3D.new()
	_side.name = "Side"
	_side.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_side)

	_front_mat = StandardMaterial3D.new()
	_front_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_front_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_front_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_front_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_front.material_override = _front_mat

	_side_mat = StandardMaterial3D.new()
	_side_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_side_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_side_mat.albedo_color = Color(0.20, 0.16, 0.10)
	_side.material_override = _side_mat

	set_state(texture, tint)


func set_state(texture: Texture2D, tint: Color) -> void:
	if texture == null or _front == null:
		return
	var key := texture.resource_path.get_file().get_basename()
	if key != _key:
		var front := load("%s/%s_front.obj" % [ICON_DIR, key]) as Mesh
		var side := load("%s/%s_side.obj" % [ICON_DIR, key]) as Mesh
		if front == null or side == null:
			return
		_front.mesh = front
		_side.mesh = side
		_key = key
	_texture = texture
	_tint = tint
	_front_mat.albedo_texture = texture
	_front_mat.albedo_color = tint
	_side_mat.albedo_color = tint.darkened(0.55)


func _process(delta: float) -> void:
	_time += delta
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	look_at(cam.global_position, Vector3.UP)
	rotate_object_local(Vector3.UP, PI)
	rotate_object_local(Vector3.UP, YAW + sin(_time * 1.7 + position.x) * 0.035)
