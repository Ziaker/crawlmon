class_name DungeonModel3DView
extends Node2D
## D-991/D-1016: shows a GLB in the 2D overworld.
##
## The model is rendered in a transparent SubViewport with an orthographic 3/4
## camera and drawn by a Sprite2D, exactly like the DQT Orc of D-389. This node
## is attached as a child of an existing player/follower; it hides that node's
## 2D sprite and follows its movement for the idle/walk animation and facing.
##
## Pokemon GLBs are Z-up (rotate X 90); DQT GLBs are Y-up and use the profile
## rotation. Every model is normalised to height 1 and its feet are put at
## y=0, so the camera, pixel height and ground alignment are the same for all.

const DqtModelProfiles := preload("res://scripts/combat/dqt_model_profiles.gd")
const STYLE_SHADER := preload("res://shaders/overworld_model_style.gdshader")

const STYLES := {
	"none": {
		"render_size": 160,
		"filter": "linear",
		"msaa": true,
		"levels": 0,
		"saturation": 1.0,
		"contrast": 1.0,
		"toon_bands": 0,
		"toon_strength": 0.0,
		"outline": 0.0,
	},
	"pixel": {
		"render_size": 64,
		"filter": "nearest",
		"msaa": false,
		"levels": 6,
		"saturation": 1.15,
		"contrast": 1.08,
		"toon_bands": 0,
		"toon_strength": 0.0,
		"outline": 0.5,
	},
	"toon": {
		"render_size": 160,
		"filter": "linear",
		"msaa": true,
		"levels": 12,
		"saturation": 1.08,
		"contrast": 1.04,
		"toon_bands": 3,
		"toon_strength": 0.75,
		"outline": 0.55,
	},
	"both": {
		"render_size": 64,
		"filter": "nearest",
		"msaa": false,
		"levels": 6,
		"saturation": 1.12,
		"contrast": 1.06,
		"toon_bands": 3,
		"toon_strength": 0.55,
		"outline": 0.5,
	},
}

## D-991: world-pixel height that matches each overworld sprite (D-1016 keeps
## the same sizes; the dungeon-tile overhaul is a later decision).
const PIXEL_HEIGHTS := {"abra": 25.0, "pancham": 24.0, "dqt_orc": 30.0}
## D-1018: lab-only multiplier for the scale test. The normal game keeps 1.0.
static var height_scale := 1.0

static func has_model(model_id: String) -> bool:
	return PIXEL_HEIGHTS.has(model_id) and ResourceLoader.exists(
		"res://assets/modelos/%s/%s.glb" % [model_id, model_id])


static func pixel_height_for(model_id: String) -> float:
	return float(PIXEL_HEIGHTS.get(model_id, 32.0)) * height_scale


## Set before the scene is instantiated; every view reads it on _ready.
## D-1016: the normal game uses the pixel style chosen by the creator.
static var current_style := "pixel"

var model_id := ""
var pixel_height := 32.0
## Empty = use the global `current_style`; set before add_child to compare
## several styles side by side in the same scene.
var style_name := ""

var _viewport: SubViewport
var _sprite: Sprite2D
var _model_rig: Node3D
var _ap: AnimationPlayer
var _current_anim := ""
var _last_dir := "down"
var _prev_pos := Vector2.ZERO
var _has_prev := false
var _z_up := false


func setup(p_model_id: String, p_pixel_height: float) -> void:
	model_id = p_model_id
	pixel_height = p_pixel_height


func _ready() -> void:
	var parent := get_parent() as Node2D
	if parent != null:
		_prev_pos = parent.global_position
		_has_prev = true
		var old_sprite = parent.get("_sprite")
		if old_sprite is CanvasItem:
			(old_sprite as CanvasItem).visible = false
	_build()
	_play_anim("idle")


func _process(delta: float) -> void:
	var parent := get_parent() as Node2D
	if parent == null:
		return
	var p := parent.global_position
	var movement := Vector2.ZERO
	if _has_prev:
		movement = p - _prev_pos
	_prev_pos = p
	_has_prev = true

	var moving := movement.length_squared() > 0.0004
	if moving:
		if absf(movement.x) > absf(movement.y):
			_last_dir = "right" if movement.x > 0.0 else "left"
		else:
			_last_dir = "down" if movement.y > 0.0 else "up"
	_play_anim("walk" if moving else "idle")
	_face(_last_dir, delta)


func _build() -> void:
	var active_style := style_name if style_name != "" else current_style
	var style: Dictionary = STYLES.get(active_style, STYLES["none"])
	var render_size := int(style.get("render_size", 160))
	var dqt_profile := DqtModelProfiles.get_profile(model_id)
	_z_up = dqt_profile.is_empty()

	_viewport = SubViewport.new()
	_viewport.name = "ModelViewport"
	_viewport.size = Vector2i(render_size, render_size)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_2X if bool(style.get("msaa", true)) else Viewport.MSAA_DISABLED
	_viewport.own_world_3d = true
	add_child(_viewport)

	var world := Node3D.new()
	world.name = "ModelWorld"
	_viewport.add_child(world)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.80, 0.88)
	environment.ambient_light_energy = 0.65
	env.environment = environment
	world.add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -32, 0)
	light.light_energy = 1.15
	light.shadow_enabled = false
	world.add_child(light)

	_model_rig = Node3D.new()
	_model_rig.name = "ModelRig"
	world.add_child(_model_rig)

	var glb_path := "res://assets/modelos/%s/%s.glb" % [model_id, model_id]
	var model: Node3D
	if ResourceLoader.exists(glb_path):
		model = (load(glb_path) as PackedScene).instantiate() as Node3D
	else:
		push_error("3D model not found: " + glb_path)
		model = _fallback_model()

	if _z_up:
		model.rotation_degrees.x = 90.0
	else:
		model.rotation_degrees.y = float(dqt_profile.get("rotation_y", 0.0))
	# D-389: the DQT Orc idles with a subtle breathing tween. Keep it in the
	# shared view instead of dropping the behaviour the Orc already had.
	var model_parent: Node3D = _model_rig
	if not _z_up:
		var breath := Node3D.new()
		breath.name = "DqtIdleBreath"
		breath.set_meta("height", 1.0)
		_model_rig.add_child(breath)
		model_parent = breath
	model_parent.add_child(model)

	# Normalise to height 1 and put the feet on y=0. Measuring the mesh AABB
	# avoids per-model height tables and keeps every model at the same scale.
	var box := _aabb_in_parent(model)
	if box.size.y > 0.001:
		model.scale = Vector3.ONE * (1.0 / box.size.y)
		box = _aabb_in_parent(model)
	model.position.y -= box.position.y

	_flatten_materials(model)

	_ap = _find_anim_player(model)
	if _ap != null:
		if not _z_up:
			DqtModelProfiles.apply_anim_aliases(_ap, dqt_profile)
			DqtModelProfiles.setup_weapon_follow(model, _ap, dqt_profile)
		_strip_root_motion(_ap)
		for anim_name in ["idle", "walk", "run"]:
			if _ap.has_animation(anim_name):
				_ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	if not _z_up:
		DqtModelProfiles.start_idle_breath(_model_rig)

	var camera := Camera3D.new()
	camera.name = "ModelCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.5
	camera.position = Vector3(0.0, 1.35, 1.65)
	world.add_child(camera)
	camera.look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
	camera.current = true

	_sprite = Sprite2D.new()
	_sprite.name = "ModelSprite"
	_sprite.texture = _viewport.get_texture()
	_sprite.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
		if str(style.get("filter", "linear")) == "nearest"
		else CanvasItem.TEXTURE_FILTER_LINEAR
	)
	_sprite.scale = Vector2.ONE * (pixel_height * 1.5 / float(render_size))
	# The camera looks at y=0.5 with size 1.5, so the feet (y=0) sit 1/3 of the
	# texture below its centre. Offset is in texture pixels, before the scale.
	_sprite.offset = Vector2(0, -float(render_size) / 3.0)
	add_child(_sprite)

	if active_style != "none":
		var mat := ShaderMaterial.new()
		mat.shader = STYLE_SHADER
		mat.set_shader_parameter("color_levels", int(style.get("levels", 12)))
		mat.set_shader_parameter("saturation", float(style.get("saturation", 1.0)))
		mat.set_shader_parameter("contrast", float(style.get("contrast", 1.0)))
		mat.set_shader_parameter("toon_bands", int(style.get("toon_bands", 0)))
		mat.set_shader_parameter("toon_strength", float(style.get("toon_strength", 0.0)))
		mat.set_shader_parameter("outline_darkness", float(style.get("outline", 0.0)))
		mat.set_shader_parameter("outline_width", 1.0 if float(style.get("outline", 0.0)) > 0.0 else 0.0)
		_sprite.material = mat


## Matte, light-independent shading so the 3D model sits closer to the pixel
## art. The battle outline adds an inverted hull that reads as a dark disc under
## the feet in top-down, so the overworld view only flattens the materials.
func _flatten_materials(model: Node) -> void:
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			if src is BaseMaterial3D:
				var mat := (src as BaseMaterial3D).duplicate() as BaseMaterial3D
				mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
				mat.roughness = 0.9
				mat.metallic_specular = 0.1
				mi.set_surface_override_material(i, mat)


func _fallback_model() -> Node3D:
	var node := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new()
	mesh.position.y = 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.55, 0.25)
	mesh.material_override = mat
	node.add_child(mesh)
	return node


## AABB of the model's meshes in its parent space, including rotation/scale.
func _aabb_in_parent(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != null and n != node:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		xf = node.transform * xf
		var box: AABB = xf * mi.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


func _play_anim(anim_name: String) -> void:
	if _ap == null or not _ap.has_animation(anim_name):
		return
	if _current_anim == anim_name:
		return
	_current_anim = anim_name
	_ap.play(anim_name, 0.15)


func _face(dir: String, delta: float) -> void:
	if _model_rig == null:
		return
	var target := 0.0
	if _z_up:
		# Pokemon GLBs face +Z at yaw 0, i.e. toward the camera ("down").
		match dir:
			"up":
				target = 180.0
			"left":
				target = -90.0
			"right":
				target = 90.0
			_:
				target = 0.0
	else:
		# DQT profiles carry rotation_y=180, so yaw 0 already faces down.
		match dir:
			"up":
				target = 180.0
			"left":
				target = 90.0
			"right":
				target = -90.0
			_:
				target = 0.0
	_model_rig.rotation.y = lerp_angle(
		_model_rig.rotation.y, deg_to_rad(target), clampf(delta * 14.0, 0.0, 1.0))


func _strip_root_motion(ap: AnimationPlayer) -> void:
	for anim_name in ap.get_animation_list():
		var anim := ap.get_animation(anim_name)
		for i in anim.get_track_count():
			if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
				continue
			var track_path := str(anim.track_get_path(i))
			if not (track_path.ends_with(":origin") or track_path.ends_with(":n_hara")):
				continue
			var first: Vector3 = anim.track_get_key_value(i, 0)
			for k in anim.track_get_key_count(i):
				var v: Vector3 = anim.track_get_key_value(i, k)
				anim.track_set_key_value(i, k, Vector3(first.x, v.y, first.z))


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null
