extends Node3D
## Laboratório de paridade literal com o HTML Card C (D-1171).
##
## Reconstrói a cena do protótipo Three.js:
## - atores táticos `createTacticalActorRig` (Alpha 2,12 m / Beta 1,90 m);
## - arena `populateTacticalArena` (piso, grid, 4 monólitos, luzes, fog);
## - câmera `updateActorsAndCamera` (normal/espelhada/oblíqua, azimute/elevação);
## - VFX `JavelinThrowVfxHtml` com o mesmo timeline 0–1,85 s.
##
## Uso de captura:
## godot --path . --resolution 1280x720 --rendering-method gl_compatibility \
##   res://scenes/debug/javelin_html_parity_lab.tscn -- \
##   --parity-capture --parity-view=normal --parity-side=a \
##   --parity-times=0.30,0.60,... --parity-out=res://test_captures/html_parity

const VFX_SCRIPT = preload("res://scripts/vfx/combat/javelin_throw_vfx_html.gd")

const TIMELINE_WINDUP_END := 0.75
const TIMELINE_TRAJECTORY_END := 1.05
const TIMELINE_TOTAL := 1.85

const SLOT_FRONT := Vector3(-2.35, 0.0, 2.65)
const SLOT_BACK := Vector3(2.35, 0.0, -2.65)

class ActorRig:
	var root: Node3D
	var body_pivot: Node3D
	var right_arm_pivot: Node3D
	var hand_node: Node3D
	var chest_node: Node3D
	var feet_node: Node3D
	var height := 1.9
	var radius := 0.5


var _camera: Camera3D
var _vfx: JavelinThrowVfxHtml
var _alpha: ActorRig
var _beta: ActorRig
var _t := 0.0
var _capturing := false
var _capture_view := "normal"
var _capture_side := "a"
var _capture_times: Array = []
var _capture_out := "res://test_captures/html_parity"
var _ambient_energy := 0.68
var _key_energy := 1.95
var _rim_energy := 1.15
var _exposure := 1.18
var _bg_color := Color("#0B131B")
var _fog_density := 0.032
var _accent_emission := 0.45


func _ready() -> void:
	_parse_args()
	_build_environment()
	_camera = Camera3D.new()
	_camera.name = "ParityCamera"
	_camera.fov = 44.0
	_camera.near = 0.1
	_camera.far = 100.0
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(_camera)
	_camera.current = true

	_alpha = _build_actor("Actor_Alpha", Color("#29435C"), Color("#D4FF32"), 2.12, 0.54)
	_beta = _build_actor("Actor_Beta", Color("#3B2838"), Color("#FF5555"), 1.90, 0.47)
	add_child(_alpha.root)
	add_child(_beta.root)

	_vfx = VFX_SCRIPT.new()
	_vfx.name = "JavelinThrowVfx"
	add_child(_vfx)
	_vfx.setup(_camera)

	if _capturing:
		_capturing = true
		set_process(false)
		await _run_capture()
		get_tree().quit(0)
	else:
		set_process(true)


func _process(delta: float) -> void:
	_t = fmod(_t + delta, TIMELINE_TOTAL)
	_draw_at(_t)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--parity-capture":
			_capturing = true
		elif arg.begins_with("--parity-view="):
			_capture_view = arg.trim_prefix("--parity-view=")
		elif arg.begins_with("--parity-side="):
			_capture_side = arg.trim_prefix("--parity-side=").to_lower()
		elif arg.begins_with("--parity-times="):
			for s in arg.trim_prefix("--parity-times=").split(","):
				if s.strip_edges() != "":
					_capture_times.append(float(s))
		elif arg.begins_with("--parity-out="):
			_capture_out = arg.trim_prefix("--parity-out=")
		elif arg.begins_with("--parity-ambient="):
			_ambient_energy = float(arg.trim_prefix("--parity-ambient="))
		elif arg.begins_with("--parity-key="):
			_key_energy = float(arg.trim_prefix("--parity-key="))
		elif arg.begins_with("--parity-rim="):
			_rim_energy = float(arg.trim_prefix("--parity-rim="))
		elif arg.begins_with("--parity-exposure="):
			_exposure = float(arg.trim_prefix("--parity-exposure="))
		elif arg.begins_with("--parity-bg="):
			_bg_color = Color(arg.trim_prefix("--parity-bg="))
		elif arg.begins_with("--parity-fog="):
			_fog_density = float(arg.trim_prefix("--parity-fog="))
		elif arg.begins_with("--parity-accent="):
			_accent_emission = float(arg.trim_prefix("--parity-accent="))


func _run_capture() -> void:
	var dir := DirAccess.open("res://")
	if dir != null and not dir.dir_exists(_capture_out):
		dir.make_dir_recursive_absolute(_capture_out)
	for i in range(3):
		await get_tree().process_frame
	for t in _capture_times:
		_draw_at(t)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := "%s/godot_%s_%s_t%04.2f.png" % [_capture_out, _capture_view, _capture_side, t]
		img.save_png(path)
		print("[html_parity] saved ", path, " t=", t)
		await get_tree().process_frame


func _draw_at(t: float) -> void:
	_t = clampf(t, 0.0, TIMELINE_TOTAL)
	var attacker: ActorRig = _alpha
	var target: ActorRig = _beta
	if _capture_side == "b":
		attacker = _beta
		target = _alpha
	_alpha.root.global_position = SLOT_FRONT
	_beta.root.global_position = SLOT_BACK
	if _capture_side == "b":
		_beta.root.global_position = SLOT_BACK
		_alpha.root.global_position = SLOT_FRONT

	_update_actors_and_camera(attacker, target, _t)

	if OS.get_cmdline_user_args().has("--parity-debug") and absf(_t - 1.5) < 0.01:
		var head := attacker.body_pivot.find_child("Head", true, false) as Node3D
		var visor := attacker.body_pivot.find_child("Visor", true, false) as Node3D
		print("[parity_debug] atk_z=", attacker.root.global_transform.basis.z,
			" to_target=", (target.root.global_position - attacker.root.global_position).normalized(),
			" cam=", _camera.global_position,
			" head=", head.global_position if head != null else Vector3.ZERO,
			" visor=", visor.global_position if visor != null else Vector3.ZERO)

	var hand := attacker.hand_node.global_position
	var chest := target.chest_node.global_position
	var feet := target.feet_node.global_position
	var axis := (chest - hand)
	if axis.length_squared() < 1e-8:
		axis = Vector3(0.0, 0.0, 1.0)
	else:
		axis = axis.normalized()
	var distance := hand.distance_to(chest)

	var stage := "windup"
	var windup_t := 0.0
	var flight_u := 0.0
	var release_t := -1.0
	var since_impact := -1.0
	if _t < TIMELINE_WINDUP_END:
		stage = "windup"
		windup_t = _t
	elif _t < TIMELINE_TRAJECTORY_END:
		stage = "flight"
		release_t = _t - TIMELINE_WINDUP_END
		flight_u = clampf(release_t / (TIMELINE_TRAJECTORY_END - TIMELINE_WINDUP_END), 0.0, 1.0)
	else:
		stage = "impact"
		release_t = _t - TIMELINE_WINDUP_END
		flight_u = 1.0
		since_impact = _t - TIMELINE_TRAJECTORY_END

	_vfx.draw({
		"stage": stage,
		"hand": hand,
		"chest": chest,
		"feet": feet,
		"axis": axis,
		"distance": distance,
		"target_radius": target.radius,
		"view_scale": 1.0,
		"windup_t": windup_t,
		"windup_total": TIMELINE_WINDUP_END,
		"flight_u": flight_u,
		"flight_t": maxf(release_t, 0.0),
		"flight_duration": TIMELINE_TRAJECTORY_END - TIMELINE_WINDUP_END,
		"release_t": release_t,
		"since_impact": since_impact,
		"impact_chest": chest,
		"crit": true,
	})


func _update_actors_and_camera(attacker: ActorRig, target: ActorRig, t: float) -> void:
	attacker.root.look_at(Vector3(target.root.global_position.x, attacker.root.global_position.y,
		target.root.global_position.z), Vector3.UP, true)
	target.root.look_at(Vector3(attacker.root.global_position.x, target.root.global_position.y,
		attacker.root.global_position.z), Vector3.UP, true)

	target.body_pivot.position = Vector3.ZERO
	target.body_pivot.quaternion = Quaternion.IDENTITY
	target.right_arm_pivot.quaternion = Quaternion.IDENTITY

	if t < TIMELINE_WINDUP_END:
		var w := ease_out_cubic(t / TIMELINE_WINDUP_END)
		attacker.body_pivot.quaternion = Quaternion(Vector3(1, 0, 0), -0.14 * w) * \
			Quaternion(Vector3(0, 1, 0), -0.35 * w)
		attacker.right_arm_pivot.quaternion = Quaternion(Vector3(1, 0, 0), -0.65 * w)
	elif t < TIMELINE_TRAJECTORY_END:
		var u := clampf((t - TIMELINE_WINDUP_END) / 0.14, 0.0, 1.0)
		var snap := ease_out_back(u)
		attacker.body_pivot.quaternion = Quaternion(Vector3(1, 0, 0), lerpf(-0.14, 0.22, snap)) * \
			Quaternion(Vector3(0, 1, 0), lerpf(-0.35, 0.28, snap))
		attacker.right_arm_pivot.quaternion = Quaternion(Vector3(1, 0, 0), lerpf(-0.65, 0.48, snap))
	else:
		var dt_imp := t - TIMELINE_TRAJECTORY_END
		var settle := clampf(dt_imp / 0.65, 0.0, 1.0)
		attacker.body_pivot.quaternion = Quaternion(Vector3(1, 0, 0), lerpf(0.22, 0.0, settle)) * \
			Quaternion(Vector3(0, 1, 0), lerpf(0.28, 0.0, settle))
		attacker.right_arm_pivot.quaternion = Quaternion(Vector3(1, 0, 0), lerpf(0.48, 0.0, settle))
		var hit_envelope := exp(-dt_imp * 8.5)
		target.body_pivot.quaternion = Quaternion(Vector3(1, 0, 0), -0.34 * hit_envelope)
		target.body_pivot.position = Vector3(0.0, 0.0, -0.22 * hit_envelope)

	attacker.root.force_update_transform()
	target.root.force_update_transform()

	var atk_pos := attacker.root.global_position
	var tgt_pos := target.root.global_position
	var dir := tgt_pos - atk_pos
	dir.y = 0.0
	dir = dir.normalized()
	var right := Vector3(-dir.z, 0.0, dir.x)
	var mid := atk_pos.lerp(tgt_pos, 0.5)
	var base_offset := Vector3.ZERO
	var look_target := Vector3.ZERO
	if _capture_view == "mirrored":
		base_offset = tgt_pos + dir * 3.35 + right * -2.15 - mid
		base_offset.y = 1.75
		look_target = tgt_pos.lerp(atk_pos, 0.42)
		look_target.y = 1.12
	elif _capture_view == "oblique":
		base_offset = mid + dir * -2.55 + right * 5.25 - mid
		base_offset.y = 2.15
		look_target = mid
		look_target.y = 1.15
	else:
		base_offset = atk_pos + dir * -3.55 + right * 2.25 - mid
		base_offset.y = 1.95
		look_target = atk_pos.lerp(tgt_pos, 0.52)
		look_target.y = 1.12

	var radius := base_offset.length()
	var base_theta := atan2(base_offset.x, base_offset.z)
	var theta := base_theta + deg_to_rad(0.0)
	var elev := deg_to_rad(12.0)
	var horiz := radius * cos(elev)
	var cam_pos := Vector3(
		mid.x + sin(theta) * horiz,
		look_target.y + radius * sin(elev),
		mid.z + cos(theta) * horiz)
	_camera.global_position = cam_pos
	_camera.look_at(look_target, Vector3.UP)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _bg_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#DBEAFE")
	env.ambient_light_energy = _ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = _exposure
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = _bg_color
	env.fog_density = _fog_density
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.light_color = Color("#FFF7ED")
	key.light_energy = _key_energy
	key.shadow_enabled = true
	key.position = Vector3(6.0, 12.0, 8.0)
	add_child(key)
	key.look_at(Vector3.ZERO, Vector3.UP)

	var rim := DirectionalLight3D.new()
	rim.name = "RimLight"
	rim.light_color = Color("#FF5555")
	rim.light_energy = _rim_energy
	rim.position = Vector3(-7.0, 5.0, -8.0)
	add_child(rim)
	rim.look_at(Vector3.ZERO, Vector3.UP)

	var floor := MeshInstance3D.new()
	floor.name = "Floor"
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(14.0, 0.4, 14.0)
	floor.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("#101B26")
	floor_mat.roughness = 0.85
	floor_mat.metallic = 0.2
	floor.material_override = floor_mat
	floor.position = Vector3(0.0, -0.2, 0.0)
	floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor)

	_build_grid()
	_build_pillars()


func _build_grid() -> void:
	var size := 13.6
	var divisions := 16
	var half := size * 0.5
	var step := size / float(divisions)
	var accent_edges: Array = []
	var dark_edges: Array = []
	for i in range(divisions + 1):
		var p := -half + float(i) * step
		var ex: Array = [Vector3(-half, 0.01, p), Vector3(half, 0.01, p)]
		var ez: Array = [Vector3(p, 0.01, -half), Vector3(p, 0.01, half)]
		if absf(p) < 1e-5:
			accent_edges.append(ex)
			accent_edges.append(ez)
		else:
			dark_edges.append(ex)
			dark_edges.append(ez)

	var accent := MeshInstance3D.new()
	accent.name = "GridCenter"
	accent.mesh = HtmlMeshLib.lines(accent_edges)
	accent.material_override = _line_mat(Color("#FF5555"), 0.45)
	add_child(accent)

	var dark := MeshInstance3D.new()
	dark.name = "GridLines"
	dark.mesh = HtmlMeshLib.lines(dark_edges)
	dark.material_override = _line_mat(Color("#1F3244"), 0.45)
	add_child(dark)


func _build_pillars() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1B2B3B")
	mat.roughness = 0.6
	var positions := [
		[Vector3(-5.8, 1.4, -5.8), 1.0],
		[Vector3(5.8, 1.4, -5.8), 1.0],
		[Vector3(-5.8, 0.9, 5.8), 0.65],
		[Vector3(5.8, 0.9, 5.8), 0.65],
	]
	for i in range(positions.size()):
		var p: Array = positions[i]
		var m := MeshInstance3D.new()
		m.name = "Monolith%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(0.65, 2.8, 0.65)
		m.mesh = bm
		m.material_override = mat
		m.position = p[0]
		m.scale = Vector3(1.0, float(p[1]), 1.0)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)


func _build_actor(actor_name: String, body_color: Color, accent_color: Color,
		height: float, radius: float) -> ActorRig:
	var rig := ActorRig.new()
	rig.height = height
	rig.radius = radius

	rig.root = Node3D.new()
	rig.root.name = actor_name

	rig.feet_node = Node3D.new()
	rig.feet_node.name = "FeetSocket"
	rig.feet_node.position = Vector3(0.0, 0.04, 0.0)
	rig.root.add_child(rig.feet_node)

	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color("#182634")
	base_mat.roughness = 0.6
	base_mat.metallic = 0.4
	var base_mesh := _mi(HtmlMeshLib.cylinder_y(radius * 1.15, radius * 1.3, 0.14, 6),
		base_mat, "Base")
	base_mesh.position = Vector3(0.0, 0.07, 0.0)
	rig.root.add_child(base_mesh)

	rig.body_pivot = Node3D.new()
	rig.body_pivot.name = "BodyPivot"
	rig.root.add_child(rig.body_pivot)

	var armor_mat := StandardMaterial3D.new()
	armor_mat.albedo_color = body_color
	armor_mat.roughness = 0.45
	armor_mat.metallic = 0.35
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color("#111922")
	dark_mat.roughness = 0.7
	dark_mat.metallic = 0.2
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = accent_color
	accent_mat.emission_enabled = true
	accent_mat.emission = accent_color
	accent_mat.emission_energy_multiplier = _accent_emission
	accent_mat.roughness = 0.3

	var leg_size := Vector3(radius * 0.42, height * 0.38, radius * 0.48)
	var left_leg := _box(leg_size, dark_mat, "LeftLeg")
	left_leg.position = Vector3(-radius * 0.36, height * 0.24, 0.0)
	left_leg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	rig.body_pivot.add_child(left_leg)
	var right_leg := _box(leg_size, dark_mat, "RightLeg")
	right_leg.position = Vector3(radius * 0.36, height * 0.24, 0.0)
	right_leg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	rig.body_pivot.add_child(right_leg)

	var torso := _mi(HtmlMeshLib.cylinder_y(radius * 0.82, radius * 0.62, height * 0.42, 6),
		armor_mat, "Torso")
	torso.position = Vector3(0.0, height * 0.62, 0.0)
	torso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	rig.body_pivot.add_child(torso)

	var core := _mi(HtmlMeshLib.octahedron(radius * 0.24, 0), accent_mat, "ChestCore")
	core.position = Vector3(0.0, height * 0.64, radius * 0.68)
	rig.body_pivot.add_child(core)

	rig.chest_node = Node3D.new()
	rig.chest_node.name = "ChestSocket"
	rig.chest_node.position = Vector3(0.0, height * 0.64, radius * 0.55)
	rig.body_pivot.add_child(rig.chest_node)

	var head := _mi(HtmlMeshLib.octahedron(radius * 0.42, 1), armor_mat, "Head")
	head.position = Vector3(0.0, height * 0.95, 0.0)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	rig.body_pivot.add_child(head)

	var visor := _box(Vector3(radius * 0.58, height * 0.06, radius * 0.35), accent_mat, "Visor")
	visor.position = Vector3(0.0, height * 0.96, radius * 0.32)
	rig.body_pivot.add_child(visor)

	var shoulder_size := Vector3(radius * 0.48, height * 0.22, radius * 0.56)
	var left_shoulder := _box(shoulder_size, armor_mat, "LeftShoulder")
	left_shoulder.position = Vector3(-radius * 0.96, height * 0.72, 0.0)
	rig.body_pivot.add_child(left_shoulder)

	rig.right_arm_pivot = Node3D.new()
	rig.right_arm_pivot.name = "RightArmPivot"
	rig.right_arm_pivot.position = Vector3(radius * 0.95, height * 0.76, 0.0)
	rig.body_pivot.add_child(rig.right_arm_pivot)
	var right_shoulder := _box(shoulder_size, armor_mat, "RightShoulder")
	rig.right_arm_pivot.add_child(right_shoulder)

	var forearm := _box(Vector3(radius * 0.32, radius * 0.32, height * 0.34), dark_mat, "Forearm")
	forearm.position = Vector3(0.0, 0.06 * (height * 0.5), radius * 0.55)
	rig.right_arm_pivot.add_child(forearm)

	var wrist := _mi(HtmlMeshLib.octahedron(radius * 0.18, 0), accent_mat, "Wrist")
	wrist.position = Vector3(0.0, 0.12 * (height * 0.5), radius * 0.95)
	rig.right_arm_pivot.add_child(wrist)

	rig.hand_node = Node3D.new()
	rig.hand_node.name = "HandSocket"
	rig.hand_node.position = Vector3(0.0, 0.15 * (height * 0.5), radius * 1.0)
	rig.right_arm_pivot.add_child(rig.hand_node)
	return rig


func _mi(mesh: Mesh, mat: Material, node_name: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = node_name
	m.mesh = mesh
	m.material_override = mat
	return m


func _box(size: Vector3, mat: Material, node_name: String) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _mi(bm, mat, node_name)


func _line_mat(color: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	return m


func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


func ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var p := clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + c3 * pow(p, 3.0) + c1 * pow(p, 2.0)
