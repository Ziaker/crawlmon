class_name HubBoard
extends Node3D
## Expedition Board (hub): the waystone kiosk that opens the Expedition Gate panel. Blender model
## (tools/blender/build_expedition_board.py -> assets/hub/expedition_board.glb, ~2 m, the old pole +
## panel reached 2.7 m). Toon materials, a slowly turning glowing compass on top, lantern lights, a soft
## amber light column so it reads from across the plaza, and a floating name tag.

const MODEL := "res://assets/hub/expedition_board.glb"
const GLOW := Color(1.0, 0.62, 0.22)

var _glow_mat: StandardMaterial3D = null
var _compass: Node3D = null
var _lights: Array[OmniLight3D] = []
var _beam_mat: ShaderMaterial = null
var _t := 0.0


func _ready() -> void:
	build()


func build() -> void:
	for child in get_children():
		child.queue_free()
	var scene := load(MODEL) as PackedScene
	if scene == null:
		push_warning("HubBoard: model missing (%s)" % MODEL)
		return
	var root := scene.instantiate()
	root.name = "BoardModel"
	add_child(root)
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.albedo_color = GLOW
	_glow_mat.emission_enabled = true
	_glow_mat.emission = GLOW
	_glow_mat.emission_energy_multiplier = 1.6
	var stone := _toon(Color(0.56, 0.51, 0.47))
	var dark := _toon(Color(0.30, 0.27, 0.25))
	var wood := _toon(Color(0.40, 0.27, 0.16))
	var gold := _toon(Color(0.86, 0.62, 0.22), Color(0.95, 0.58, 0.2), 0.3)
	var paper := _toon(Color(0.93, 0.86, 0.66), Color(0.9, 0.8, 0.5), 0.12)
	var wax := _toon(Color(0.70, 0.12, 0.10))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var inst := mi as MeshInstance3D
		match inst.name:
			"Board_Stone":
				for s in inst.mesh.get_surface_count():
					inst.set_surface_override_material(s, dark if _surf(inst.mesh, s).contains("dark") else stone)
				_add_collision()
			"Board_Wood":
				inst.material_override = wood
			"Board_Gold":
				inst.material_override = gold
			"Board_Paper":
				for s in inst.mesh.get_surface_count():
					inst.set_surface_override_material(s, wax if _surf(inst.mesh, s).contains("wax") else paper)
			"Board_Glow":
				inst.material_override = _glow_mat
			"Board_Compass":
				_compass = inst
				for s in inst.mesh.get_surface_count():
					inst.set_surface_override_material(s, _glow_mat if _surf(inst.mesh, s).contains("glow") else gold)
	for sx in [-0.78, 0.78]:
		var l := OmniLight3D.new()
		l.position = Vector3(sx, 1.15, 0.45)
		l.light_color = Color(1.0, 0.68, 0.30)
		l.light_energy = 0.55
		l.omni_range = 4.2
		add_child(l)
		_lights.append(l)
	var top := OmniLight3D.new()
	top.position = Vector3(0.0, 1.7, 0.9)
	top.light_color = GLOW
	top.light_energy = 0.45
	top.omni_range = 3.6
	add_child(top)
	_lights.append(top)
	_build_beam()


func _surf(mesh: Mesh, s: int) -> String:
	var m := mesh.surface_get_material(s)
	return m.resource_name if m != null else ""


func _toon(color: Color, emission := Color(0, 0, 0, 1), energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = 0.9
	mat.rim_enabled = true
	mat.rim = 0.2
	mat.rim_tint = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = energy
	return mat


func _add_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "BoardBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.98
	cyl.height = 1.5
	cs.shape = cyl
	cs.position = Vector3(0.0, 0.75, 0.0)
	body.add_child(cs)
	add_child(body)


func _build_beam() -> void:
	var beam := MeshInstance3D.new()
	beam.name = "BoardBeam"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.75
	cm.height = 3.2
	cm.radial_segments = 20
	cm.rings = 1
	cm.cap_top = false
	cm.cap_bottom = false
	beam.mesh = cm
	beam.position = Vector3(0.0, 0.24 + 1.6, 0.0)
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec3 tint = vec3(1.0, 0.62, 0.22);
uniform float strength = 0.2;
void fragment() {
	float up = clamp(1.0 - UV.y, 0.0, 1.0);
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.6);
	ALBEDO = tint * strength * pow(up, 1.6) * edge;
	ALPHA = 1.0;
}
"""
	_beam_mat = ShaderMaterial.new()
	_beam_mat.shader = sh
	beam.material_override = _beam_mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)


func _process(delta: float) -> void:
	_t += delta
	if _compass != null:
		_compass.rotation.z = _t * 0.6  # turns in its own plane (ring axis = Godot Z)
	if _glow_mat != null:
		_glow_mat.emission_energy_multiplier = 1.5 + 0.5 * sin(_t * 2.2)
	for i in _lights.size():
		_lights[i].light_energy = (0.55 if i < 2 else 0.45) * (1.0 + 0.12 * sin(_t * 3.1 + float(i) * 1.7))
	if _beam_mat != null:
		_beam_mat.set_shader_parameter("strength", 0.24 * (1.0 + 0.15 * sin(_t * 1.5)))
