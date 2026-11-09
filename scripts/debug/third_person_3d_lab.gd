extends Node3D
## D-1023: lab 3D em terceira pessoa estilo SMT III.
##
## Um corredor em L, o jogador (Abra), Pancham e o Orc seguindo, um Slime
## parado e uma porta de saída. O objetivo é testar câmera, escala, colisão e
## movimento — não é uma dungeon final e não toca no jogo normal.
##
## Controles: WASD/setas andam e viram, mouse/Q/E olham, Esc solta o mouse.

const DQT_PROFILES := preload("res://scripts/combat/dqt_model_profiles.gd")

const WALL_HEIGHT := 4.6
const SPEED := 3.2
const TURN_SPEED := 1.4
const FOLLOW_SPEED := 4.5
const CAM_DISTANCE := 3.4
const CAM_HEIGHT := 0.85
const CAM_FOV := 55.0
const PARTY_CAM_DISTANCE := 5.4
const PARTY_CAM_HEIGHT := 1.0
const PARTY_CAM_PITCH := 14.0

## Alturas provisórias do lab (metros). Não são regra de jogo.
const HEIGHTS := {
	"abra": 1.0,
	"pancham": 1.1,
	"dqt_orc": 2.1,
	"dqt_slime": 1.4,
}

## O recorder liga isso antes de add_child para o vídeo com os três.
@export var start_party := false

var player: CharacterBody3D
var player_model: Node3D
var player_ap: AnimationPlayer
var player_yaw := PI  ## frente do modelo +Z; PI = olhando para -Z.

var _followers: Array[Dictionary] = []
var _party_visible := false
var _cam_yaw := PI
var _cam_pitch := 8.0
var _last_look := -100.0
var _time := 0.0
var _cam_pivot := Vector3.ZERO
var _camera: Camera3D
var _torches: Array[OmniLight3D] = []
var _torch_base: Array[float] = []


func _ready() -> void:
	_party_visible = start_party
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_environment()
	_build_room()
	_build_player()
	_build_followers()
	_build_enemy()
	_build_exit()
	_build_hud()


func _process(delta: float) -> void:
	_time += delta
	for i in _torches.size():
		var base: float = _torch_base[i]
		_torches[i].light_energy = base * (0.86 + 0.14 * sin(_time * 7.0 + float(i) * 1.7))


func _physics_process(delta: float) -> void:
	var turn := Input.get_axis("ui_left", "ui_right")
	if absf(turn) > 0.01:
		player_yaw -= turn * TURN_SPEED * delta
	var move := -Input.get_axis("ui_up", "ui_down")
	var dir := Vector3.ZERO
	if absf(move) > 0.01:
		dir = Vector3(sin(player_yaw), 0.0, cos(player_yaw)) * move
	player.velocity = dir * SPEED
	player.move_and_slide()
	player.rotation.y = player_yaw

	if Input.is_key_pressed(KEY_Q):
		_cam_yaw += 1.6 * delta
		_last_look = _time
	if Input.is_key_pressed(KEY_E):
		_cam_yaw -= 1.6 * delta
		_last_look = _time

	if _time - _last_look > 1.2:
		_cam_yaw = lerp_angle(_cam_yaw, player_yaw, clampf(delta * 5.0, 0.0, 1.0))

	_update_camera(delta)
	_update_followers(delta)
	_play_move(player_ap, dir.length_squared() > 0.01)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_cam_yaw -= motion.relative.x * 0.0025
		_cam_pitch = clampf(_cam_pitch - motion.relative.y * 0.0015, -8.0, 32.0)
		_last_look = _time
	elif event is InputEventKey and event.pressed:
		var key := (event as InputEventKey).keycode
		if key == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().quit()
		elif key == KEY_1:
			_party_visible = not _party_visible
			_cam_pitch = PARTY_CAM_PITCH if _party_visible else 14.0
			for f in _followers:
				(f["node"] as Node3D).visible = _party_visible


# --- Environment -------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.02, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.44, 0.56)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.08, 0.12)
	env.fog_density = 0.008
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key.light_color = Color(0.72, 0.80, 0.95)
	key.light_energy = 0.55
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 40.0
	add_child(key)


# --- Room --------------------------------------------------------------------

func _build_room() -> void:
	var floor_mat := _stone_mat(Color(0.18, 0.22, 0.28), 0.92)
	var wall_mat := _stone_mat(Color(0.22, 0.26, 0.32), 0.95)
	var dark_mat := _stone_mat(Color(0.10, 0.13, 0.17), 0.98)

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

	# Rodapé luminoso para leitura do piso.
	var trim := _emissive(Color(0.18, 0.65, 0.78), 0.9)
	_box(Vector3(0.08, 0.03, 20.0), Vector3(-3.9, 0.02, -4.0), trim, false)
	_box(Vector3(22.0, 0.03, 0.08), Vector3(7.0, 0.02, -13.9), trim, false)

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
	center_light.light_color = Color(0.38, 0.55, 0.80)
	center_light.light_energy = 1.0
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

	# Luz de recorte Presa ao jogador para ele não sumir no fundo escuro.
	var rim := OmniLight3D.new()
	rim.position = Vector3(0.0, 1.6, 1.1)
	rim.light_color = Color(0.55, 0.75, 1.0)
	rim.light_energy = 0.8
	rim.omni_range = 3.5
	player.add_child(rim)

	_camera = Camera3D.new()
	_camera.fov = CAM_FOV
	_camera.near = 0.05
	_camera.far = 100.0
	_camera.current = true
	add_child(_camera)
	_update_camera(0.0)


func _build_followers() -> void:
	# Formação em V à frente do jogador. No vídeo solo eles ficam escondidos;
	# no vídeo de grupo, a câmera recua para os três aparecerem.
	_add_follower("pancham", -1.1, 1.6, Vector3(-1.1, 0.0, -1.6))
	_add_follower("dqt_orc", 1.3, 2.8, Vector3(1.3, 0.0, -2.8))


func _add_follower(model_id: String, side: float, ahead: float, start: Vector3) -> void:
	var node := Node3D.new()
	node.name = "%sFollower" % model_id.capitalize()
	node.position = start
	node.visible = _party_visible
	add_child(node)
	var model := _make_model(model_id, float(HEIGHTS[model_id]))
	node.add_child(model)
	var ap := _anim_player(model)
	_play(ap, "idle")
	_followers.append({
		"node": node,
		"model": model,
		"ap": ap,
		"ahead": ahead,
		"side": side,
		"moving": false,
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

	var ap := _find_anim_player(glb)
	if ap != null:
		if not dqt.is_empty():
			DQT_PROFILES.apply_anim_aliases(ap, dqt)
			DQT_PROFILES.setup_weapon_follow(glb, ap, dqt)
		_strip_root_motion(ap)
		for anim_name in ["idle", "walk", "run"]:
			if ap.has_animation(anim_name):
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
	var enemy := Node3D.new()
	enemy.name = "SlimeEnemy"
	enemy.position = Vector3(-2.8, 0.0, -6.5)
	enemy.rotation.y = 0.0
	add_child(enemy)
	var model := _make_model("dqt_slime", float(HEIGHTS["dqt_slime"]))
	enemy.add_child(model)
	var ap := _anim_player(model)
	_play_idle(ap)
	var tag := Label3D.new()
	tag.text = "SLIME"
	tag.font_size = 42
	tag.modulate = Color(0.85, 0.95, 1.0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.2, 0)
	tag.no_depth_test = true
	enemy.add_child(tag)


func _build_exit() -> void:
	var gate_mat := _emissive(Color(0.25, 0.85, 0.78), 1.4)
	_box(Vector3(0.3, 3.2, 0.3), Vector3(17.7, 1.6, -11.4), gate_mat, false)
	_box(Vector3(0.3, 3.2, 0.3), Vector3(17.7, 1.6, -8.6), gate_mat, false)
	_box(Vector3(0.3, 0.3, 3.2), Vector3(17.7, 3.2, -10.0), gate_mat, false)
	_box(Vector3(0.15, 2.6, 2.6), Vector3(17.85, 1.4, -10.0), _stone_mat(Color(0.03, 0.05, 0.07), 1.0), false)
	var tag := Label3D.new()
	tag.text = "SAÍDA"
	tag.font_size = 46
	tag.modulate = Color(0.55, 1.0, 0.9)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(17.5, 3.8, -10.0)
	tag.no_depth_test = false
	add_child(tag)


# --- Camera and followers ----------------------------------------------------

func _update_camera(_delta: float) -> void:
	var distance := PARTY_CAM_DISTANCE if _party_visible else CAM_DISTANCE
	var height := PARTY_CAM_HEIGHT if _party_visible else CAM_HEIGHT
	_cam_pivot = player.global_position + Vector3(0.0, height, 0.0)
	var forward := Vector3(sin(_cam_yaw), 0.0, cos(_cam_yaw))
	var pitch := deg_to_rad(_cam_pitch)
	var desired := _cam_pivot - forward * (cos(pitch) * distance) + Vector3(0.0, sin(pitch) * distance, 0.0)
	var query := PhysicsRayQueryParameters3D.create(_cam_pivot, desired, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		desired = (hit["position"] as Vector3) + (hit["normal"] as Vector3) * 0.25
	_camera.global_position = desired
	_camera.look_at(_cam_pivot + Vector3(0.0, 0.1, 0.0), Vector3.UP)


func _update_followers(delta: float) -> void:
	var forward := Vector3(sin(player_yaw), 0.0, cos(player_yaw))
	var right := Vector3(-cos(player_yaw), 0.0, sin(player_yaw))
	for f in _followers:
		var node: Node3D = f["node"]
		var ahead := float(f["ahead"])
		var side := float(f["side"])
		var target := player.position + forward * ahead + right * side
		target.y = 0.0
		var to := target - node.position
		to.y = 0.0
		var moving := to.length() > 0.08
		f["moving"] = moving
		if moving:
			var step := to.normalized() * minf(FOLLOW_SPEED * delta, to.length())
			node.position += step
			node.rotation.y = atan2(step.x, step.z)
		else:
			node.position = target
			var face := player.position - node.position
			face.y = 0.0
			if face.length_squared() > 0.001:
				node.rotation.y = atan2(face.x, face.z)
		_play_move(f["ap"], moving and _party_visible)


# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var label := Label.new()
	label.text = "Lab 3D — terceira pessoa (SMT III)\nWASD/setas: andar e virar · mouse/Q/E: câmera · 1: aliados · Esc: sair"
	label.position = Vector2(20, 16)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	add_child(layer)
