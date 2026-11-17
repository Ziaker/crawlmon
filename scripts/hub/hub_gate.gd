class_name HubGate
extends Node3D
## Expedition Gate (hub): hard-surface ring portal on a stepped dais, modelled in Blender
## (tools/blender/build_expedition_gate.py -> assets/hub/expedition_gate.glb, ~3.7 m tall).
## The model is split per material (Gate_Stone / Gate_Gold / Gate_Rune / Gate_Shard); this class
## swaps them for toon / emissive materials, builds the trimesh collision (the opening stays free),
## the circular portal film (dormant rim shimmer -> spiral surge when opened), the rune light,
## orbiting shards and motes. The player is never moved by the gate: it only opens (D-1273).

const MODEL := "res://assets/hub/expedition_gate.glb"
const SCALE := 2.0  ## creator: the portal at least 2x bigger, with all its effects (model is 3.67 m at 1x)
const RING_CENTER := Vector3(0.0, 1.47, 0.0) * SCALE  ## centre of the opening, relative to the node (dais centre on the floor)
const PORTAL_RADIUS := 1.25 * SCALE
const DAIS_TOP := 0.22 * SCALE
const SHARD_COUNT := 7
const IDLE_RUNE := Color(1.0, 0.62, 0.22)

var portal_mat: ShaderMaterial = null
var light: OmniLight3D = null
var open_amount := 0.0  ## 0 dormant .. 1 fully open
var pulse := 0.0  ## 0..2 transient boost (NPC cycle, entry)
var _rune_mat: StandardMaterial3D = null
var _gold_mat: StandardMaterial3D = null
var _rune_color := IDLE_RUNE
var _shards: Array[Node3D] = []
var _motes: CPUParticles3D = null
var _t := 0.0
var _portal_quad: MeshInstance3D = null
var _beam: MeshInstance3D = null
var _beam_mat: ShaderMaterial = null


func _ready() -> void:
	build()


func build() -> void:
	for child in get_children():
		child.queue_free()
	var scene := load(MODEL) as PackedScene
	if scene == null:
		push_warning("HubGate: model missing (%s)" % MODEL)
		return
	var root := scene.instantiate()
	root.name = "GateModel"
	root.scale = Vector3.ONE * SCALE
	add_child(root)
	_rune_mat = _make_rune_mat()
	_gold_mat = _make_toon(Color(0.84, 0.60, 0.22), Color(0.95, 0.58, 0.20), 0.35)
	var stone := _make_toon(Color(0.52, 0.48, 0.45))
	var dark := _make_toon(Color(0.30, 0.27, 0.26))
	var shard_mesh: Mesh = null
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var inst := mi as MeshInstance3D
		match _base_name(inst.name):
			"Gate_Stone":
				for s in inst.mesh.get_surface_count():
					var nm := _surface_name(inst.mesh, s)
					inst.set_surface_override_material(s, dark if nm.contains("dark") else stone)
				_add_collision(inst)
			"Gate_Gold":
				inst.material_override = _gold_mat
			"Gate_Rune":
				inst.material_override = _rune_mat
			"Gate_Shard":
				shard_mesh = inst.mesh
				inst.visible = false
	_build_portal()
	_build_beam()
	_build_light()
	_build_motes()
	if shard_mesh != null:
		for i in SHARD_COUNT:
			var sh := MeshInstance3D.new()
			sh.mesh = shard_mesh
			sh.material_override = _rune_mat
			sh.name = "Shard%d" % i
			add_child(sh)
			_shards.append(sh)
	_apply_state()


func _base_name(n: String) -> String:
	# Godot appends nothing to glTF node names, but keep it robust to "@" suffixes.
	var at := n.find("@")
	return n.substr(0, at) if at >= 0 else n


func _surface_name(mesh: Mesh, s: int) -> String:
	var m := mesh.surface_get_material(s)
	return m.resource_name if m != null else ""


func _make_toon(color: Color, emission := Color(0, 0, 0, 1), energy := 0.0) -> StandardMaterial3D:
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


func _make_rune_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.03, 0.02)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = IDLE_RUNE
	mat.emission_energy_multiplier = 1.6
	mat.albedo_color = IDLE_RUNE
	return mat


## Trimesh of the stone only: the opening between the ring blocks stays free, the dais slopes walk.
func _add_collision(inst: MeshInstance3D) -> void:
	var body := StaticBody3D.new()
	body.name = "GateBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	# Faces baked at the final size: no scaled collision shapes.
	var xf := Transform3D(Basis.from_scale(Vector3.ONE * SCALE)) * inst.transform
	var faces := inst.mesh.get_faces()
	for i in faces.size():
		faces[i] = xf * faces[i]
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _build_portal() -> void:
	_portal_quad = MeshInstance3D.new()
	_portal_quad.name = "PortalFilm"
	var qm := QuadMesh.new()
	qm.size = Vector2(PORTAL_RADIUS * 2.0 + 0.06, PORTAL_RADIUS * 2.0 + 0.06)
	_portal_quad.mesh = qm
	_portal_quad.position = RING_CENTER
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform float pulse_boost : hint_range(0.0, 2.0) = 0.0;
uniform float open : hint_range(0.0, 1.0) = 0.0;
uniform vec3 col_void = vec3(0.04, 0.025, 0.035);
uniform vec3 col_mid = vec3(0.72, 0.34, 0.10);
uniform vec3 col_bright = vec3(1.00, 0.78, 0.32);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float angle = atan(uv.y, uv.x);
	// Two counter-rotating spiral arms and a bright vortex core.
	float s1 = sin(r * 11.0 - TIME * 2.6 + angle * 3.0 + sin(TIME * 0.9 + r * 4.0) * 0.8);
	float s2 = cos(r * 15.0 - TIME * 3.3 - angle * 2.0);
	float stream = smoothstep(0.15, 0.85, s1 * 0.6 + s2 * 0.4);
	float disc = 1.0 - smoothstep(0.93, 1.0, r);
	float core = exp(-r * (2.4 - pulse_boost * 0.6));
	float ring = exp(-pow((r - 0.72) * 6.0, 2.0));
	vec3 col = mix(col_void, col_mid, clamp(0.40 + stream * 0.6 + pulse_boost * 0.2, 0.0, 1.0));
	col = mix(col, col_bright, clamp(core * (0.9 + pulse_boost * 0.5) + ring * 0.55 + stream * 0.3, 0.0, 1.0));
	// Spiral surge: a spiralling front opens from the centre outwards.
	float spiral = r + 0.22 * sin(angle * 2.0 + r * 7.0 - open * 6.0);
	float reveal = 1.0 - smoothstep(open * 1.4 - 0.3, open * 1.4, spiral);
	// Dormant: only a faint shimmer hugging the rim (and a flash when something pulses).
	float rim = exp(-pow((r - 0.93) * 11.0, 2.0)) * (0.30 + 0.25 * sin(TIME * 1.7 + angle * 4.0));
	float dormant = (rim + core * pulse_boost * 0.35) * disc;
	float a = max(reveal * disc, dormant * (1.0 - open));
	ALBEDO = col;
	EMISSION = col * (0.9 + pulse_boost * 0.7);
	ALPHA = clamp(a, 0.0, 1.0);
}
"""
	portal_mat = ShaderMaterial.new()
	portal_mat.shader = sh
	_portal_quad.material_override = portal_mat
	add_child(_portal_quad)


## Soft light column rising from the dais: makes the gate readable from across the plaza (the old arch
## was a landmark because of its height; this one is low, so the light does that job).
func _build_beam() -> void:
	_beam = MeshInstance3D.new()
	_beam.name = "GateBeam"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.75 * SCALE
	cm.bottom_radius = 1.45 * SCALE
	cm.height = 7.0 * SCALE
	cm.radial_segments = 24
	cm.rings = 1
	cm.cap_top = false
	cm.cap_bottom = false
	_beam.mesh = cm
	_beam.position = Vector3(0.0, DAIS_TOP + 3.5 * SCALE, 0.0)
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec3 tint = vec3(1.0, 0.62, 0.22);
uniform float strength = 0.15;
void fragment() {
	float up = clamp(1.0 - UV.y, 0.0, 1.0);          // 1 at the dais, 0 at the top
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.6);
	float bands = 0.8 + 0.2 * sin(UV.x * 40.0 + TIME * 1.4 + up * 6.0);
	ALBEDO = tint * strength * pow(up, 1.7) * edge * bands;
	ALPHA = 1.0;
}
"""
	_beam_mat = ShaderMaterial.new()
	_beam_mat.shader = sh
	_beam.material_override = _beam_mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)


func _build_light() -> void:
	light = OmniLight3D.new()
	light.name = "GateLight"
	light.position = RING_CENTER + Vector3(0.0, 0.0, 1.6 * SCALE)
	light.light_color = IDLE_RUNE
	light.light_energy = 0.3
	light.omni_range = 6.5 * SCALE
	add_child(light)


func _build_motes() -> void:
	_motes = CPUParticles3D.new()
	_motes.name = "GateMotes"
	_motes.position = Vector3(0.0, DAIS_TOP + 0.1 * SCALE, 0.0)
	_motes.amount = int(26.0 * SCALE * 1.5)
	_motes.lifetime = 2.6
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_motes.emission_sphere_radius = 1.5 * SCALE
	_motes.gravity = Vector3(0.0, 0.7 * SCALE, 0.0)
	_motes.initial_velocity_min = 0.05 * SCALE
	_motes.initial_velocity_max = 0.2 * SCALE
	_motes.scale_amount_min = 0.05 * SCALE
	_motes.scale_amount_max = 0.1 * SCALE
	var q := QuadMesh.new()
	q.size = Vector2(0.1, 0.1)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pm.vertex_color_use_as_albedo = true
	pm.albedo_color = Color(IDLE_RUNE.r, IDLE_RUNE.g, IDLE_RUNE.b, 0.85)
	q.material = pm
	_motes.mesh = q
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.0))
	grad.add_point(0.3, Color(1, 1, 1, 1.0))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	_motes.color_ramp = grad
	add_child(_motes)


## World palette (WorldDefs.world_colors: bright, mid, dark): portal, runes, light and motes follow it.
func set_world_colors(bright: Color, mid: Color, dark: Color) -> void:
	_rune_color = bright.lerp(Color.WHITE, 0.25)
	if portal_mat != null:
		portal_mat.set_shader_parameter("col_void", Vector3(dark.r * 0.35, dark.g * 0.35, dark.b * 0.35))
		portal_mat.set_shader_parameter("col_mid", Vector3(mid.r, mid.g, mid.b))
		portal_mat.set_shader_parameter("col_bright", Vector3(bright.r * 1.5, bright.g * 1.5, bright.b * 1.5))
	if light != null:
		light.light_color = bright
	if _motes != null and _motes.mesh is QuadMesh:
		var pm := (_motes.mesh as QuadMesh).material as StandardMaterial3D
		if pm != null:
			pm.albedo_color = Color(bright.r, bright.g, bright.b, 0.85)
	_apply_state()


func set_open(v: float) -> void:
	open_amount = clampf(v, 0.0, 1.0)
	_apply_state()


func set_pulse(v: float) -> void:
	pulse = clampf(v, 0.0, 2.0)
	if portal_mat != null:
		portal_mat.set_shader_parameter("pulse_boost", pulse)


func _apply_state() -> void:
	if portal_mat != null:
		portal_mat.set_shader_parameter("open", open_amount)
	if _rune_mat != null:
		_rune_mat.albedo_color = _rune_color
		_rune_mat.emission = _rune_color
	if _gold_mat != null:
		_gold_mat.emission = _rune_color.lerp(Color(0.95, 0.58, 0.20), 0.4)
	if _beam_mat != null:
		_beam_mat.set_shader_parameter("tint", Vector3(_rune_color.r, _rune_color.g, _rune_color.b))


func _process(delta: float) -> void:
	_t += delta
	var glow := 0.55 + 0.6 * open_amount + 0.4 * pulse
	if _rune_mat != null:
		_rune_mat.emission_energy_multiplier = glow * (1.0 + 0.18 * sin(_t * 2.1)) * (1.0 + 0.8 * open_amount)
	if _gold_mat != null:
		_gold_mat.emission_energy_multiplier = 0.25 + 0.5 * open_amount + 0.3 * pulse
	if light != null:
		light.light_energy = 0.3 + 0.95 * open_amount + 0.5 * pulse
	if _beam_mat != null:
		_beam_mat.set_shader_parameter("strength", (0.22 + 0.55 * open_amount + 0.5 * pulse) * (1.0 + 0.1 * sin(_t * 1.6)))
	if _motes != null:
		_motes.speed_scale = 0.8 + 1.4 * open_amount
	# Shards drift on a tilted orbit around the opening, faster when open.
	var spin := 0.35 + 0.9 * open_amount
	for i in _shards.size():
		var a := _t * spin + TAU * float(i) / float(_shards.size())
		var rr := PORTAL_RADIUS + (0.78 + 0.1 * sin(_t * 1.3 + float(i) * 2.0)) * SCALE
		var p := RING_CENTER + Vector3(cos(a) * rr, sin(a) * rr, 0.5 * SCALE * sin(a * 2.0 + float(i)))
		var sh: Node3D = _shards[i]
		sh.scale = Vector3.ONE * SCALE
		sh.position = p
		sh.rotation = Vector3(0.0, _t * (1.0 + 0.2 * float(i)), a + PI * 0.5)
