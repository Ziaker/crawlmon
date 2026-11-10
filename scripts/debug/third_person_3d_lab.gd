extends Node3D
## D-1023: lab 3D em terceira pessoa estilo SMT III.
##
## Um corredor em L, o jogador (Abra), Pancham e o Orc seguindo, um Slime
## parado e uma porta de saída. O objetivo é testar câmera, escala, colisão e
## movimento — não é uma dungeon final e não toca no jogo normal.
##
## Controles: WASD/setas andam e viram, Q/E ou botão direito do mouse olham,
## Esc sai. O mouse não é capturado.

const DQT_PROFILES := preload("res://scripts/combat/dqt_model_profiles.gd")
const VIGNETTE_SHADER := preload("res://shaders/vignette.gdshader")

const WALL_HEIGHT := 4.6
const SPEED := 3.2
const TURN_SPEED := 1.4
## D-1107: velocidade do giro do personagem para a direção do movimento.
const TURN_RATE := 10.0
const FOLLOW_SPEED := 3.8
const CATCH_UP_SPEED := 5.2
const CAM_DISTANCE := 3.4
const CAM_HEIGHT := 0.85
const CAM_FOV := 55.0
const PARTY_CAM_DISTANCE := 6.2
const PARTY_CAM_HEIGHT := 1.5
const PARTY_CAM_PITCH := 22.0
const SOLO_CAM_PITCH := 8.0
const NAV_Y := 0.05

enum AllyState { IDLE, FOLLOW, CATCH_UP, AVOID, RECOVER }
enum EnemyState { PATROL, CHASE, SEARCH, RETURN, FLEE }

## D-1086: protótipo do Medroso (D-310/D-315) no lab da Murky Forest.
## A fórmula final e as velocidades em px/s continuam pendentes; aqui o
## Slime foge devagar quando o grupo chega a 3 tiles (9 m, 1 tile = 3 m).
const MEDROSO_FLEE_RADIUS := 9.0
const MEDROSO_EXIT_RADIUS := 10.5
const MEDROSO_SPEED := 1.0

## Alturas provisórias do lab (metros). Não são regra de jogo.
const HEIGHTS := {
	"abra": 1.0,
	"pancham": 0.7,
	"dqt_orc": 2.1,
	"dqt_slime": 1.4,
}

## O recorder liga isso antes de add_child para o vídeo com os três.
@export var start_party := false
## D-1086: só o lab da Murky Forest liga o protótipo do Medroso.
@export var enable_threat_demo := false

var player: CharacterBody3D
var player_model: Node3D
var player_ap: AnimationPlayer
var player_yaw := PI  ## frente do modelo +Z; PI = olhando para -Z.

var _followers: Array[Dictionary] = []
var _party_visible := false
var _cam_yaw := PI
var _cam_pitch := SOLO_CAM_PITCH
var _last_look := -100.0
var _time := 0.0
var _cam_pivot := Vector3.ZERO
var _cam_probe := SphereShape3D.new()
var _camera: Camera3D
var _dialogue_focus: Node3D
var _dialogue_active := false
var _dialogue_blend := 0.0
var _torches: Array[OmniLight3D] = []
var _torch_base: Array[float] = []
var _enemy: Node3D
var _enemy_body: CharacterBody3D
var _enemy_agent: NavigationAgent3D
var _enemy_ap: AnimationPlayer
var _enemy_state := EnemyState.PATROL
var _enemy_patrol_i := 0
var _enemy_last_seen := Vector3.ZERO
var _enemy_threat_level := 2
var _enemy_alert_timer := 0.0
var _enemy_lost := 0.0
var _enemy_dust: CPUParticles3D
var _player_dust: CPUParticles3D
var _nav_region: NavigationRegion3D
var _door_prompt: Label
var _door_used := false
var _door_near := false


func _ready() -> void:
	_party_visible = start_party
	_cam_pitch = PARTY_CAM_PITCH if _party_visible else SOLO_CAM_PITCH
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_interaction_action()
	_build_environment()
	_build_navigation()
	_build_room()
	_build_player()
	_build_followers()
	_build_enemy()
	_build_exit()
	_build_vignette()
	_build_hud()


func _process(delta: float) -> void:
	_time += delta
	for i in _torches.size():
		var base: float = _torch_base[i]
		_torches[i].light_energy = base * (0.86 + 0.14 * sin(_time * 7.0 + float(i) * 1.7))


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	var dialogue_locked := _dialogue_focus != null and is_instance_valid(_dialogue_focus)
	if dialogue_locked:
		# D-1088: durante a conversa o jogador fica parado, virado para o NPC.
		var face := _dialogue_focus.global_position - player.global_position
		face.y = 0.0
		if face.length_squared() > 0.001:
			player_yaw = lerp_angle(player_yaw, atan2(face.x, face.z), clampf(delta * 4.0, 0.0, 1.0))
		player.velocity = Vector3.ZERO
		player.move_and_slide()
		player.rotation.y = player_yaw
		if _player_dust != null:
			_player_dust.emitting = false
	else:
		var input := Vector2(
			Input.get_axis("ui_left", "ui_right"),
			-Input.get_axis("ui_up", "ui_down"))
		if input.length_squared() > 0.001:
			# D-1107: WASD relativo à câmera; o personagem vira para a direção.
			var cam_forward := Vector3(sin(_cam_yaw), 0.0, cos(_cam_yaw))
			var cam_right := Vector3(-cos(_cam_yaw), 0.0, sin(_cam_yaw))
			dir = (cam_forward * input.y + cam_right * input.x).normalized()
			var target_yaw := atan2(dir.x, dir.z)
			player_yaw = lerp_angle(player_yaw, target_yaw, clampf(delta * TURN_RATE, 0.0, 1.0))
		player.velocity = dir * SPEED
		player.move_and_slide()
		player.rotation.y = player_yaw
		if _player_dust != null:
			_player_dust.emitting = dir.length_squared() > 0.01 and player.velocity.length() > 0.1

		if Input.is_key_pressed(KEY_Q):
			_cam_yaw += 1.6 * delta
		if Input.is_key_pressed(KEY_E):
			_cam_yaw -= 1.6 * delta

	_update_camera(delta)
	_update_followers(delta)
	_update_enemy(delta)
	_update_door_prompt()
	_play_move(player_ap, dir.length_squared() > 0.01)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _dialogue_focus != null:
			return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var motion := event as InputEventMouseMotion
			_cam_yaw -= motion.relative.x * 0.0025
			_cam_pitch = clampf(_cam_pitch - motion.relative.y * 0.0015, -8.0, 32.0)
			_last_look = _time
	elif event is InputEventKey and event.pressed:
		var key := (event as InputEventKey).keycode
		if key == KEY_ESCAPE:
			get_tree().quit()
		elif key == KEY_1:
			_party_visible = not _party_visible
			_cam_pitch = PARTY_CAM_PITCH if _party_visible else SOLO_CAM_PITCH
			for f in _followers:
				(f["node"] as Node3D).visible = _party_visible


# --- Environment -------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.018, 0.015)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.50, 0.44)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.07, 0.06)
	env.fog_density = 0.008
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key.light_color = Color(0.85, 0.80, 0.72)
	key.light_energy = 0.55
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 40.0
	add_child(key)


# --- Navigation --------------------------------------------------------------

## Malha de navegação em L feita à mão para o lab (duas salas retangulares com
## arestas compartilhadas). Numa dungeon real, isto vira um bake.
func _build_navigation() -> void:
	var nav := NavigationMesh.new()
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	nav.agent_radius = 0.45
	nav.agent_height = 2.1
	nav.agent_max_climb = 0.3
	nav.agent_max_slope = 45.0
	nav.set_vertices(PackedVector3Array([
		Vector3(-3.7, NAV_Y, 5.7),    # 0
		Vector3(3.7, NAV_Y, 5.7),     # 1
		Vector3(3.7, NAV_Y, -6.3),    # 2
		Vector3(-3.7, NAV_Y, -6.3),   # 3
		Vector3(17.7, NAV_Y, -6.3),   # 4
		Vector3(17.7, NAV_Y, -13.7),  # 5
		Vector3(3.7, NAV_Y, -13.7),   # 6
		Vector3(-3.7, NAV_Y, -13.7),  # 7
	]))
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nav.add_polygon(PackedInt32Array([3, 2, 6, 7]))
	nav.add_polygon(PackedInt32Array([2, 4, 5, 6]))
	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "Navigation"
	_nav_region.navigation_mesh = nav
	add_child(_nav_region)


# --- Room --------------------------------------------------------------------

func _build_room() -> void:
	var floor_mat := _stone_mat(Color(0.24, 0.22, 0.20), 0.92)
	var wall_mat := _stone_mat(Color(0.28, 0.26, 0.24), 0.95)
	var dark_mat := _stone_mat(Color(0.12, 0.11, 0.10), 0.98)

	# Piso em L: corredor norte-sul + corredor leste-oeste.
	_box(Vector3(8.0, 0.4, 20.0), Vector3(0.0, -0.2, -4.0), floor_mat)
	_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, -0.2, -10.0), floor_mat)
	# Teto.
	_box(Vector3(8.0, 0.4, 20.0), Vector3(0.0, 4.6, -4.0), dark_mat)
	_box(Vector3(22.0, 0.4, 8.0), Vector3(7.0, 4.6, -10.0), dark_mat)

	# Paredes externas do L.
	_box(Vector3(8.5, WALL_HEIGHT, 0.5), Vector3(0.0, 2.3, 6.25), wall_mat)
	_box(Vector3(0.5, WALL_HEIGHT, 20.0), Vector3(-4.25, 2.3, -4.0), wall_mat)
	_box(Vector3(0.5, WALL_HEIGHT, 12.0), Vector3(4.25, 2.3, 0.0), wall_mat)
	_box(Vector3(22.5, WALL_HEIGHT, 0.5), Vector3(7.0, 2.3, -14.25), wall_mat)
	_box(Vector3(14.5, WALL_HEIGHT, 0.5), Vector3(11.0, 2.3, -5.75), wall_mat)
	_box(Vector3(0.5, WALL_HEIGHT, 8.0), Vector3(18.25, 2.3, -10.0), wall_mat)

	# Pilares.
	for p in [
		Vector3(-3.0, 2.2, -2.0), Vector3(3.0, 2.2, -7.0),
		Vector3(7.0, 2.2, -13.0), Vector3(13.0, 2.2, -7.0),
	]:
		_box(Vector3(0.55, 4.4, 0.55), p, dark_mat)

	# Tochas.
	for t in [
		Vector3(-3.9, 2.9, 0.0), Vector3(3.9, 2.9, -2.0),
		Vector3(-3.9, 2.9, -8.0), Vector3(6.0, 2.9, -13.7),
		Vector3(12.0, 2.9, -13.7), Vector3(6.0, 2.9, -6.3),
		Vector3(12.0, 2.9, -6.3), Vector3(17.8, 2.9, -10.0),
	]:
		_add_torch(t)

	var center_light := OmniLight3D.new()
	center_light.position = Vector3(8.0, 3.2, -10.0)
	center_light.light_color = Color(1.0, 0.88, 0.72)
	center_light.light_energy = 0.7
	center_light.omni_range = 14.0
	add_child(center_light)


func _add_torch(pos: Vector3) -> void:
	_box(Vector3(0.16, 0.55, 0.16), pos - Vector3(0, 0.2, 0), _stone_mat(Color(0.1, 0.08, 0.06), 0.9))
	var flame := _emissive(Color(1.0, 0.55, 0.18), 2.2)
	_box(Vector3(0.18, 0.32, 0.18), pos + Vector3(0, 0.18, 0), flame, false)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0.25, 0)
	light.light_color = Color(1.0, 0.62, 0.30)
	light.light_energy = 2.2
	light.omni_range = 7.5
	add_child(light)
	_torches.append(light)
	_torch_base.append(2.2)


func _box(size: Vector3, pos: Vector3, mat: Material, collide := true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.position = pos
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		add_child(body)
	return mi


func _stone_mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic_specular = 0.15
	return mat


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.6
	return mat


func _shadow_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 64
	tex.height = 64
	return tex


## Sombra de contato (blob) no chão. Funciona no Compatibility e não depende
## do shadow map direcional.
func _add_blob_shadow(parent: Node3D, width: float, depth: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, depth)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.rotation.x = -PI / 2.0
	mi.position.y = 0.04
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _shadow_texture()
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.45)
	mi.material_override = mat
	parent.add_child(mi)


func _add_footstep_dust(parent: Node3D) -> CPUParticles3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.11, 0.11)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _shadow_texture()
	mat.albedo_color = Color(0.62, 0.52, 0.40, 0.42)
	var dust := CPUParticles3D.new()
	dust.name = "FootDust"
	dust.position = Vector3(0.0, 0.08, 0.0)
	dust.amount = 6
	dust.lifetime = 0.45
	dust.emitting = false
	dust.local_coords = false
	dust.mesh = quad
	dust.material_override = mat
	dust.direction = Vector3(0.0, 1.0, 0.0)
	dust.spread = 35.0
	dust.initial_velocity_min = 0.15
	dust.initial_velocity_max = 0.5
	dust.gravity = Vector3(0.0, -0.6, 0.0)
	dust.scale_amount_min = 0.4
	dust.scale_amount_max = 0.8
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.12
	parent.add_child(dust)
	return dust


# --- Player and models -------------------------------------------------------

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 0.0)
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_snap_length = 0.3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.0
	shape.shape = capsule
	shape.position.y = 0.5
	player.add_child(shape)
	add_child(player)
	player_yaw = PI
	player.rotation.y = player_yaw

	player_model = _make_model("abra", float(HEIGHTS["abra"]))
	player.add_child(player_model)
	player_ap = _anim_player(player_model)
	_play(player_ap, "idle")
	_add_blob_shadow(player, 0.9, 0.6)

	# Luz de recorte Presa ao jogador para ele não sumir no fundo escuro.
	var rim := OmniLight3D.new()
	rim.position = Vector3(0.0, 1.6, 1.1)
	rim.light_color = Color(1.0, 0.82, 0.60)
	rim.light_energy = 0.5
	rim.omni_range = 3.5
	player.add_child(rim)
	_player_dust = _add_footstep_dust(player)

	_camera = Camera3D.new()
	_camera.fov = CAM_FOV
	_camera.near = 0.05
	_camera.far = 100.0
	_camera.current = true
	_cam_probe.radius = 0.18
	add_child(_camera)
	_update_camera(0.0)


func _build_followers() -> void:
	# Triângulo com o jogador na ponta: aliados um pouco atrás e aos lados.
	# No vídeo solo eles ficam escondidos; no grupo, andam com walk e sombra.
	_add_follower("pancham", -0.9, 1.3, Vector3(-0.9, 0.0, 1.3))
	_add_follower("dqt_orc", 1.7, 2.0, Vector3(1.7, 0.0, 2.0))


func _add_follower(model_id: String, side: float, behind: float, start: Vector3) -> void:
	var body := CharacterBody3D.new()
	body.name = "%sFollower" % model_id.capitalize()
	body.position = start
	body.visible = _party_visible
	body.collision_layer = 4
	body.collision_mask = 1
	body.floor_snap_length = 0.3
	body.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	var height := float(HEIGHTS[model_id])
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = clampf(height * 0.28, 0.2, 0.45)
	capsule.height = maxf(height, capsule.radius * 2.0 + 0.05)
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	body.add_child(shape)
	add_child(body)
	var agent := NavigationAgent3D.new()
	agent.path_desired_distance = 0.4
	agent.target_desired_distance = 0.35
	agent.radius = capsule.radius
	agent.height = capsule.height
	agent.max_speed = CATCH_UP_SPEED
	agent.avoidance_enabled = false
	body.add_child(agent)
	var model := _make_model(model_id, height)
	body.add_child(model)
	_add_blob_shadow(body, 0.7 if model_id == "pancham" else 1.3, 0.45 if model_id == "pancham" else 0.85)
	var dust := _add_footstep_dust(body)
	var ap := _anim_player(model)
	_play(ap, "idle")
	_followers.append({
		"node": body,
		"model": model,
		"ap": ap,
		"agent": agent,
		"dust": dust,
		"behind": behind,
		"side": side,
		"height": height,
		"model_id": model_id,
		"velocity": Vector3.ZERO,
		"last_pos": start,
		"stuck": 0.0,
		"state": AllyState.IDLE,
	})


func _make_model(model_id: String, target_height: float) -> Node3D:
	var root := Node3D.new()
	var path := "res://assets/modelos/%s/%s.glb" % [model_id, model_id]
	if not ResourceLoader.exists(path):
		var mesh := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.4
		capsule.height = target_height
		mesh.mesh = capsule
		mesh.position.y = target_height * 0.5
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.55, 0.25)
		mesh.material_override = mat
		root.add_child(mesh)
		return root

	var glb := (load(path) as PackedScene).instantiate() as Node3D
	var dqt := DQT_PROFILES.get_profile(model_id)
	var parent: Node3D = root
	if dqt.is_empty():
		glb.rotation_degrees.x = 90.0
	else:
		glb.rotation_degrees.y = float(dqt.get("rotation_y", 0.0))
		var breath := Node3D.new()
		breath.name = "DqtIdleBreath"
		breath.set_meta("height", target_height)
		root.add_child(breath)
		parent = breath
	parent.add_child(glb)

	# Normaliza para a altura do lab e coloca os pés em y=0.
	var box := _aabb_in_parent(glb)
	if box.size.y > 0.001:
		glb.scale = Vector3.ONE * (target_height / box.size.y)
		box = _aabb_in_parent(glb)
	glb.position.y -= box.position.y

	const DQT_EYES := preload("res://scripts/combat/dqt_eyes.gd")
	var ap := _find_anim_player(glb)
	if ap != null:
		if not dqt.is_empty():
			DQT_PROFILES.apply_anim_aliases(ap, dqt)
			DQT_PROFILES.setup_weapon_follow(glb, ap, dqt)
			DQT_EYES.attach(root, glb, ap, str(dqt.get("clip_prefix", "")) + "04")
		_strip_root_motion(ap)
		for anim_name in ["idle", "walk", "run"]:
			if ap.has_animation(anim_name):
				# D-1084: idle_full (Orc/Cyclops/Slime) já vem LOOP_NONE do perfil;
				# walk/run continuam em loop.
				if anim_name == "idle" and not dqt.is_empty() and bool(dqt.get("idle_full", false)):
					continue
				ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	if not dqt.is_empty():
		DQT_PROFILES.start_idle_breath(root)
	return root


func _anim_player(root: Node3D) -> AnimationPlayer:
	return _find_anim_player(root)


func _aabb_in_parent(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		if mi.name.contains("_tuta_"):
			mi.visible = false
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


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null


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


func _play(ap: AnimationPlayer, name: String) -> void:
	if ap == null or not ap.has_animation(name):
		return
	if ap.current_animation == name:
		return
	# D-1084: idle_full (Orc/Cyclops/Slime) é LOOP_NONE; depois que termina,
	# o current_animation fica vazio. Não reiniciar: segura o último quadro.
	if name == "idle" and ap.get_animation("idle").loop_mode == Animation.LOOP_NONE:
		if ap.current_animation == "" and bool(ap.get_meta("idle_held", false)):
			return
		ap.set_meta("idle_held", true)
	else:
		ap.set_meta("idle_held", false)
	ap.play(name, 0.15)


func _play_move(ap: AnimationPlayer, moving: bool) -> void:
	if ap == null:
		return
	if moving and ap.has_animation("walk"):
		_play(ap, "walk")
	elif not moving and ap.has_animation("idle"):
		_play(ap, "idle")


func _play_idle(ap: AnimationPlayer) -> void:
	if ap != null and ap.has_animation("idle"):
		_play(ap, "idle")


# --- Enemy and exit ----------------------------------------------------------

func _build_enemy() -> void:
	var body := CharacterBody3D.new()
	body.name = "SlimeEnemy"
	body.position = Vector3(12.0, 0.0, -10.0)
	body.collision_layer = 8
	body.collision_mask = 1
	body.floor_snap_length = 0.3
	body.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	var height := float(HEIGHTS["dqt_slime"])
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = height
	shape.shape = capsule
	shape.position.y = height * 0.5
	body.add_child(shape)
	add_child(body)
	_enemy_body = body
	_enemy = body
	var agent := NavigationAgent3D.new()
	agent.path_desired_distance = 0.4
	agent.target_desired_distance = 0.35
	agent.radius = 0.4
	agent.height = height
	agent.max_speed = 2.4
	agent.avoidance_enabled = false
	body.add_child(agent)
	_enemy_agent = agent
	var model := _make_model("dqt_slime", height)
	body.add_child(model)
	_add_blob_shadow(body, 1.2, 1.0)
	_enemy_dust = _add_footstep_dust(body)
	_enemy_ap = _anim_player(model)
	_play_idle(_enemy_ap)
	if enable_threat_demo:
		_enemy_threat_level = 0  # Medroso (D-1086)
	var tag := Label3D.new()
	tag.text = "SLIME"
	tag.font_size = 42
	tag.modulate = Color(0.85, 0.95, 1.0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 1.95, 0)
	tag.no_depth_test = false
	body.add_child(tag)


func _build_exit() -> void:
	var gate_mat := _emissive(Color(1.0, 0.72, 0.28), 1.4)
	_box(Vector3(0.3, 3.2, 0.3), Vector3(17.7, 1.6, -11.4), gate_mat, false)
	_box(Vector3(0.3, 3.2, 0.3), Vector3(17.7, 1.6, -8.6), gate_mat, false)
	_box(Vector3(0.3, 0.3, 3.2), Vector3(17.7, 3.2, -10.0), gate_mat, false)
	_box(Vector3(0.15, 2.6, 2.6), Vector3(17.85, 1.4, -10.0), _stone_mat(Color(0.03, 0.05, 0.07), 1.0), false)
	var tag := Label3D.new()
	tag.text = "SAÍDA"
	tag.font_size = 46
	tag.modulate = Color(1.0, 0.88, 0.55)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(17.5, 3.8, -10.0)
	tag.no_depth_test = false
	add_child(tag)


# --- Camera and followers ----------------------------------------------------

func _update_camera(delta: float) -> void:
	var distance := PARTY_CAM_DISTANCE if _party_visible else CAM_DISTANCE
	var height := PARTY_CAM_HEIGHT if _party_visible else CAM_HEIGHT
	_cam_pivot = player.global_position + Vector3(0.0, height, 0.0)
	var forward := Vector3(sin(_cam_yaw), 0.0, cos(_cam_yaw))
	var pitch := deg_to_rad(_cam_pitch)
	var desired := _cam_pivot - forward * (cos(pitch) * distance) + Vector3(0.0, sin(pitch) * distance, 0.0)
	var query := PhysicsRayQueryParameters3D.create(_cam_pivot, desired, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	# Só o cenário deve puxar a câmera; atores (jogador, aliados e inimigo)
	# nunca entram no raycast, senão a câmera cola no corpo.
	var actors: Array[RID] = [player.get_rid()]
	for f in _followers:
		actors.append((f["node"] as CollisionObject3D).get_rid())
	if _enemy_body != null:
		actors.append(_enemy_body.get_rid())
	query.exclude = actors
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		desired = (hit["position"] as Vector3) + (hit["normal"] as Vector3) * 0.4
	# Se o ponto final ainda raspa a parede, recua em direção ao pivô até folgar.
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = _cam_probe
	probe.collision_mask = 1
	probe.collide_with_bodies = true
	probe.collide_with_areas = false
	probe.exclude = actors
	var to_pivot := (_cam_pivot - desired).normalized()
	for i in 6:
		probe.transform = Transform3D(Basis(), desired)
		if get_world_3d().direct_space_state.intersect_shape(probe, 1).is_empty():
			break
		desired += to_pivot * 0.15

	# D-1088: mistura a câmera normal com o dois-shot do diálogo.
	var target_blend := 1.0 if _dialogue_active and _dialogue_focus != null and is_instance_valid(_dialogue_focus) else 0.0
	_dialogue_blend = move_toward(_dialogue_blend, target_blend, delta / 0.4)
	var final_pos := desired
	var look_target := _cam_pivot + Vector3(0.0, 0.1, 0.0)
	if _dialogue_focus != null and is_instance_valid(_dialogue_focus) and _dialogue_blend > 0.001:
		var pose := _dialogue_camera_pose(actors)
		final_pos = desired.lerp(pose["pos"], _dialogue_blend)
		look_target = look_target.lerp(pose["look"], _dialogue_blend)
	if _dialogue_blend <= 0.001 and not _dialogue_active:
		_dialogue_focus = null

	var to_look := (look_target - final_pos).normalized()
	for i in 6:
		probe.transform = Transform3D(Basis(), final_pos)
		if get_world_3d().direct_space_state.intersect_shape(probe, 1).is_empty():
			break
		final_pos += to_look * 0.15
	_camera.global_position = final_pos
	_camera.look_at(look_target, Vector3.UP)
	_camera.fov = lerpf(CAM_FOV, 45.0, _dialogue_blend)


func set_dialogue_focus(target: Node3D) -> void:
	_dialogue_focus = target
	_dialogue_active = true


func clear_dialogue_focus() -> void:
	_dialogue_active = false


func _dialogue_camera_pose(actors: Array[RID]) -> Dictionary:
	# D-1088/D-1092: três-quartos pela esquerda. A câmera orbita o ponto
	# médio jogador↔NPC a 50° para a esquerda, em vez de ficar atrás do
	# jogador; o jogador e o NPC ficam em quadro, acima do card.
	var focus := _dialogue_focus
	var axis := focus.global_position - player.global_position
	axis.y = 0.0
	if axis.length_squared() < 0.001:
		axis = Vector3(0.0, 0.0, -1.0)
	axis = axis.normalized()
	var mid := (player.global_position + focus.global_position) * 0.5 + Vector3(0.0, 1.0, 0.0)
	var left := -axis.cross(Vector3.UP)
	if left.length_squared() < 0.001:
		left = Vector3(-1.0, 0.0, 0.0)
	left = left.normalized()
	var angle := deg_to_rad(50.0)
	var back_left := (-axis * cos(angle) + left * sin(angle)).normalized()
	var back_right := (-axis * cos(angle) - left * sin(angle)).normalized()
	var dist := 3.9
	var left_pose := mid + back_left * dist + Vector3(0.0, 0.55, 0.0)
	var left_free := _camera_free_distance(mid, left_pose, actors)
	var chosen := left_pose
	var free := left_free
	if left_free < 2.2:
		var right_pose := mid + back_right * dist + Vector3(0.0, 0.55, 0.0)
		var right_free := _camera_free_distance(mid, right_pose, actors)
		if right_free > left_free:
			chosen = right_pose
			free = right_free
	var full := maxf(mid.distance_to(chosen), 0.001)
	var t := clampf((free - 0.25) / full, 0.35, 1.0)
	var pos := mid.lerp(chosen, t)
	var look := mid + Vector3(0.0, -0.35, 0.0)
	return {"pos": pos, "look": look}


func _camera_free_distance(from: Vector3, to: Vector3, actors: Array[RID]) -> float:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = actors
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return from.distance_to(to)
	return from.distance_to(hit["position"] as Vector3)


func _update_followers(delta: float) -> void:
	var forward := Vector3(sin(player_yaw), 0.0, cos(player_yaw))
	var right := Vector3(-cos(player_yaw), 0.0, sin(player_yaw))
	var player_moving := player.velocity.length() > 0.15
	for f in _followers:
		var body: CharacterBody3D = f["node"]
		var behind := float(f["behind"])
		var side := float(f["side"])
		var height := float(f["height"])
		var behind_point := player.global_position - forward * behind
		var side_sign := signf(side)
		var side_dir := right * side_sign
		var side_abs := absf(side)
		var side_from := behind_point + Vector3(0.0, 0.6, 0.0)
		var side_query := PhysicsRayQueryParameters3D.create(side_from, side_from + side_dir * side_abs, 1)
		var side_hit := get_world_3d().direct_space_state.intersect_ray(side_query)
		if not side_hit.is_empty():
			var side_dist := side_from.distance_to(side_hit["position"] as Vector3)
			side_abs = maxf(0.0, side_dist - 0.7)
		var target := behind_point + side_dir * side_abs
		target.y = 0.0
		target = _clamp_to_free(player.global_position, target)
		var to := target - body.global_position
		to.y = 0.0
		var dist := to.length()
		var agent: NavigationAgent3D = f["agent"]
		agent.target_position = target
		var desired := Vector3.ZERO
		var next := agent.get_next_path_position()
		if agent.is_navigation_finished():
			desired = to.normalized() if dist > 0.2 else Vector3.ZERO
		else:
			var to_next := next - body.global_position
			to_next.y = 0.0
			desired = to_next.normalized() if to_next.length() > 0.05 else to.normalized()
		var avoid := _wall_avoidance(body, desired, height)
		var sep := _separation(f)
		var state := AllyState.IDLE
		var speed := 0.0
		if dist > 1.6:
			state = AllyState.CATCH_UP
			speed = CATCH_UP_SPEED
		elif player_moving or dist > 0.15:
			state = AllyState.FOLLOW
			speed = FOLLOW_SPEED
		if avoid.length_squared() > 0.01:
			state = AllyState.AVOID
			speed = maxf(speed * 0.8, 4.2)
		var stuck := float(f["stuck"])
		if body.get_slide_collision_count() > 0 and dist > 0.3:
			stuck += delta
		else:
			stuck = maxf(0.0, stuck - delta * 2.0)
		if stuck > 1.2:
			state = AllyState.RECOVER
			target = player.global_position - forward * (behind * 0.45) + right * (side * 0.25)
			target.y = 0.0
			to = target - body.global_position
			to.y = 0.0
			desired = to.normalized() if to.length() > 0.05 else Vector3.ZERO
			speed = 2.4
			if stuck > 2.6:
				stuck = 0.0
		f["stuck"] = stuck
		f["state"] = state

		var steer := desired + avoid * 1.35 + sep * 0.9
		if steer.length_squared() > 0.001:
			steer = steer.normalized()
		else:
			steer = Vector3.ZERO
		var target_vel := steer * speed
		var vel: Vector3 = f["velocity"]
		vel = vel.lerp(target_vel, clampf(delta * 8.0, 0.0, 1.0))
		if vel.length() < 0.02:
			vel = Vector3.ZERO
		f["velocity"] = vel
		body.velocity = vel
		body.move_and_slide()
		f["velocity"] = body.velocity

		var hv := Vector3(body.velocity.x, 0.0, body.velocity.z)
		var moving := hv.length() > 0.12
		if moving:
			var yaw := atan2(hv.x, hv.z)
			body.rotation.y = lerp_angle(body.rotation.y, yaw, clampf(delta * 10.0, 0.0, 1.0))
		else:
			var face := player.global_position - body.global_position
			face.y = 0.0
			if face.length_squared() > 0.001:
				body.rotation.y = lerp_angle(
					body.rotation.y, atan2(face.x, face.z), clampf(delta * 4.0, 0.0, 1.0))
		_play_move(f["ap"], moving)
		var ap: AnimationPlayer = f["ap"]
		ap.speed_scale = clampf(hv.length() / 3.2, 0.75, 1.35) if moving else 1.0
		var dust: CPUParticles3D = f["dust"]
		dust.emitting = moving and _party_visible


## Se o alvo da formação cair atrás de uma parede, para no primeiro obstáculo.
func _clamp_to_free(origin: Vector3, target: Vector3) -> Vector3:
	var from := origin + Vector3(0.0, 0.6, 0.0)
	var to := target + Vector3(0.0, 0.6, 0.0)
	# Sonda um pouco além do alvo: se a parede está logo à frente, o alvo
	# também precisa recuar para o corpo do aliado caber.
	var dir := (to - from).normalized()
	to += dir * 0.6
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return target
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	normal.y = 0.0
	if normal.length_squared() < 0.001:
		return target
	return point + normal.normalized() * 0.6 - Vector3(0.0, 0.6, 0.0)


## Três raios (frente, esquerda, direita) para desviar de paredes e pilares.
func _wall_avoidance(body: CharacterBody3D, desired: Vector3, height: float) -> Vector3:
	if desired.length_squared() < 0.001:
		return Vector3.ZERO
	var origin := body.global_position + Vector3(0.0, height * 0.55, 0.0)
	var space := get_world_3d().direct_space_state
	var avoid := Vector3.ZERO
	for angle in [-32.0, 0.0, 32.0]:
		var dir := desired.rotated(Vector3.UP, deg_to_rad(angle)).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * 1.15, 1)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var normal: Vector3 = hit["normal"]
		normal.y = 0.0
		if normal.length_squared() < 0.001:
			continue
		var tangent := Vector3.UP.cross(normal).normalized()
		if tangent.dot(desired) < 0.0:
			tangent = -tangent
		var distance := origin.distance_to(hit["position"] as Vector3)
		var weight := 1.0 - clampf(distance / 1.15, 0.0, 1.0)
		avoid += tangent * weight
		if absf(angle) < 1.0:
			avoid += normal * weight * 0.7
	return avoid.limit_length(1.0)


## Evita empilhar nos outros aliados e no jogador.
func _separation(f: Dictionary) -> Vector3:
	var body: CharacterBody3D = f["node"]
	var push := Vector3.ZERO
	for other in _followers:
		if other == f:
			continue
		var d: Vector3 = body.global_position - (other["node"] as Node3D).global_position
		d.y = 0.0
		if d.length() < 0.9 and d.length_squared() > 0.0001:
			push += d.normalized() * (0.9 - d.length())
	var dp: Vector3 = body.global_position - player.global_position
	dp.y = 0.0
	if dp.length() < 0.8 and dp.length_squared() > 0.0001:
		push += dp.normalized() * (0.8 - dp.length())
	return push


## Inimigo simples de laboratório: patrulha, vê por raycast, persegue e volta.
## D-1086: com enable_threat_demo, o Slime vira Medroso (D-310/D-315) e foge.
func _update_enemy(delta: float) -> void:
	if _enemy_body == null:
		return
	_enemy_alert_timer = maxf(0.0, _enemy_alert_timer - delta)
	var body := _enemy_body
	var to_player := player.global_position - body.global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var target := player.global_position
	var speed := 2.4
	var patrol_points := [Vector3(10.0, 0.0, -10.0), Vector3(14.0, 0.0, -10.0)]

	if enable_threat_demo and _enemy_threat_level == 0:
		var was_flee := _enemy_state == EnemyState.FLEE
		if dist < MEDROSO_FLEE_RADIUS:
			if not was_flee:
				_enemy_alert_timer = 0.6
			_enemy_state = EnemyState.FLEE
		elif was_flee and dist > MEDROSO_EXIT_RADIUS:
			_enemy_state = EnemyState.RETURN
		elif _enemy_state != EnemyState.RETURN:
			_enemy_state = EnemyState.PATROL
		if _enemy_state == EnemyState.RETURN \
				and body.global_position.distance_to(Vector3(12.0, 0.0, -10.0)) < 0.6:
			_enemy_state = EnemyState.PATROL
		match _enemy_state:
			EnemyState.FLEE:
				var away := body.global_position - player.global_position
				away.y = 0.0
				if away.length_squared() < 0.001:
					away = Vector3(1.0, 0.0, 0.0)
				target = body.global_position + away.normalized() * 3.0
				target = _clamp_to_free(body.global_position, target)
				speed = MEDROSO_SPEED
			EnemyState.RETURN:
				target = Vector3(12.0, 0.0, -10.0)
				speed = 1.2
			_:
				target = patrol_points[_enemy_patrol_i]
				speed = 1.2
				if body.global_position.distance_to(target) < 0.45:
					_enemy_patrol_i = (_enemy_patrol_i + 1) % 2
	else:
		var was_chase := _enemy_state == EnemyState.CHASE
		var can_see := dist < 7.0 and _enemy_has_los()
		if can_see:
			if not was_chase:
				_enemy_alert_timer = 0.6
			_enemy_state = EnemyState.CHASE
			_enemy_last_seen = player.global_position
			_enemy_lost = 0.0
		else:
			match _enemy_state:
				EnemyState.CHASE:
					_enemy_lost += delta
					if _enemy_lost > 2.0:
						_enemy_state = EnemyState.SEARCH
						_enemy_lost = 0.0
				EnemyState.SEARCH:
					_enemy_lost += delta
					if _enemy_lost > 2.0:
						_enemy_state = EnemyState.RETURN
				EnemyState.RETURN:
					if body.global_position.distance_to(Vector3(12.0, 0.0, -10.0)) < 0.6:
						_enemy_state = EnemyState.PATROL
		match _enemy_state:
			EnemyState.PATROL:
				target = patrol_points[_enemy_patrol_i]
				speed = 1.2
				if body.global_position.distance_to(target) < 0.45:
					_enemy_patrol_i = (_enemy_patrol_i + 1) % 2
			EnemyState.SEARCH:
				target = _enemy_last_seen
				speed = 1.8
				if body.global_position.distance_to(target) < 0.45:
					_enemy_state = EnemyState.RETURN
			EnemyState.RETURN:
				target = Vector3(12.0, 0.0, -10.0)
				speed = 2.0
			EnemyState.CHASE:
				target = player.global_position
				speed = 2.4
	target.y = 0.0

	_enemy_agent.target_position = target
	var desired := Vector3.ZERO
	var next := _enemy_agent.get_next_path_position()
	var direct := target - body.global_position
	direct.y = 0.0
	if _enemy_agent.is_navigation_finished():
		desired = direct.normalized() if direct.length() > 0.2 else Vector3.ZERO
	else:
		var to_next := next - body.global_position
		to_next.y = 0.0
		desired = to_next.normalized() if to_next.length() > 0.05 else direct.normalized()
	var avoid := _wall_avoidance(body, desired, 1.4)
	var sep := _enemy_separation()
	var steer := desired + avoid * 1.2 + sep
	if steer.length_squared() > 0.001:
		steer = steer.normalized()
	var vel: Vector3 = body.velocity.lerp(steer * speed, clampf(delta * 7.0, 0.0, 1.0))
	body.velocity = vel
	body.move_and_slide()
	var hv := Vector3(body.velocity.x, 0.0, body.velocity.z)
	var moving := hv.length() > 0.1
	if moving:
		body.rotation.y = lerp_angle(
			body.rotation.y, atan2(hv.x, hv.z), clampf(delta * 8.0, 0.0, 1.0))
	_play_move(_enemy_ap, moving)
	_enemy_ap.speed_scale = clampf(hv.length() / 1.6, 0.75, 1.35) if moving else 1.0
	_enemy_dust.emitting = moving
	# Não deixar o inimigo gigante entre a câmera e o jogador (lab).
	var cam_delta := _camera.global_position - _enemy_body.global_position
	cam_delta.y = 0.0
	_enemy_body.visible = cam_delta.length() > 6.2


func _enemy_has_los() -> bool:
	var from := _enemy_body.global_position + Vector3(0.0, 0.9, 0.0)
	var to := player.global_position + Vector3(0.0, 0.8, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _enemy_separation() -> Vector3:
	var body := _enemy_body
	var push := Vector3.ZERO
	for f in _followers:
		var d: Vector3 = body.global_position - (f["node"] as Node3D).global_position
		d.y = 0.0
		if d.length() < 1.0 and d.length_squared() > 0.0001:
			push += d.normalized() * (1.0 - d.length())
	var dp: Vector3 = body.global_position - player.global_position
	dp.y = 0.0
	if dp.length() < 1.0 and dp.length_squared() > 0.0001:
		push += dp.normalized() * (1.0 - dp.length())
	return push


func _setup_interaction_action() -> void:
	if InputMap.has_action("lab_interact"):
		return
	InputMap.add_action("lab_interact")
	for key in [KEY_E, KEY_Z]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event("lab_interact", ev)


func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE_SHADER
	mat.set_shader_parameter("tint", Color(0.03, 0.02, 0.015, 1.0))
	mat.set_shader_parameter("strength", 0.30)
	mat.set_shader_parameter("softness", 0.60)
	mat.set_shader_parameter("dither_strength", 0.006)
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var label := Label.new()
	label.text = "Lab 3D — terceira pessoa (SMT III)\nWASD/setas: andar e virar · Q/E ou botão direito: câmera · 1: aliados · Esc: sair"
	label.position = Vector2(20, 16)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)

	_door_prompt = Label.new()
	_door_prompt.text = ""
	_door_prompt.position = Vector2(520, 660)
	_door_prompt.add_theme_font_size_override("font_size", 22)
	_door_prompt.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60))
	_door_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_door_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_door_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_door_prompt.visible = false
	layer.add_child(_door_prompt)
	add_child(layer)


func _update_door_prompt() -> void:
	if _door_prompt == null or player == null:
		return
	var from := player.global_position + Vector3(0.0, 0.9, 0.0)
	var forward := Vector3(sin(player_yaw), 0.0, cos(player_yaw))
	var query := PhysicsRayQueryParameters3D.create(from, from + forward * 3.2, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var near := false
	if not hit.is_empty():
		var point: Vector3 = hit["position"]
		near = point.distance_to(Vector3(17.7, 0.9, -10.0)) < 1.5
	_door_near = near
	if _door_used:
		_door_prompt.visible = near
		_door_prompt.text = "SAÍDA" if near else ""
		return
	_door_prompt.visible = near
	if near:
		_door_prompt.text = "Z/E: SAÍDA"
		if Input.is_action_pressed("lab_interact"):
			_door_used = true
			_door_prompt.text = "SAÍDA"
	else:
		_door_prompt.text = ""
