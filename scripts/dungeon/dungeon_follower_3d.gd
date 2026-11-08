class_name DungeonFollower3D
extends DungeonFollower
## D-389: DQT Orc 3D como terceiro seguidor visual no overworld (lab).
##
## O rastro, o gap, a velocidade e a reposição continuam os de D-314/D-361/D-388.
## O visual é um GLB 3D renderizado num SubViewport ortográfico e exibido num
## Sprite2D; o modelo não entra em batalha, party, colisão ou regra.

const DqtModelProfiles := preload("res://scripts/combat/dqt_model_profiles.gd")
const VfxLib := preload("res://scripts/combat/vfx_lib.gd")

var _viewport: SubViewport
var _model_rig: Node3D
var _ap: AnimationPlayer
var _current_anim := ""
var _was_moving := false


## D-389: the DQT GLBs are ignored by Git, so the normal game only spawns the
## 3D follower when the asset exists on disk. A clone without it keeps the
## two 2D allies and no fallback capsule.
static func can_spawn(model_id: String = "dqt_orc") -> bool:
	return ResourceLoader.exists("res://assets/modelos/%s/%s.glb" % [model_id, model_id])


func _ready() -> void:
	_build_viewport()
	_sprite = Sprite2D.new()
	_sprite.name = "DqtSprite"
	_sprite.texture = _viewport.get_texture()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.centered = true
	_sprite.scale = Vector2(0.32, 0.32)
	_sprite.offset = Vector2(0, -3)
	add_child(_sprite)

	if leader != null:
		_trail.append(position)
		var dist := position.distance_to(leader.position)
		var steps := maxi(1, int(dist / TRAIL_STEP))
		for i in range(1, steps):
			_trail.append(position.lerp(leader.position, float(i) / steps))
		_trail.append(leader.position)

	_play_anim("idle")
	_face(_last_dir, 1.0)


func _build_viewport() -> void:
	var model_id := species_id if species_id != "" else "dqt_orc"
	var profile := DqtModelProfiles.get_profile(model_id)
	var target := float(profile.get("target_height", 2.0))

	_viewport = SubViewport.new()
	_viewport.name = "DqtViewport"
	_viewport.size = Vector2i(160, 160)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.own_world_3d = true
	add_child(_viewport)

	var world := Node3D.new()
	world.name = "DqtWorld"
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
	_model_rig.name = "DqtRig"
	world.add_child(_model_rig)

	var breath := Node3D.new()
	breath.name = "DqtIdleBreath"
	breath.set_meta("height", target)
	_model_rig.add_child(breath)

	var glb_path := "res://assets/modelos/%s/%s.glb" % [model_id, model_id]
	var packed := load(glb_path) as PackedScene
	if packed == null:
		push_error("DQT model not found: " + glb_path)
		var fallback := MeshInstance3D.new()
		fallback.mesh = CapsuleMesh.new()
		fallback.position.y = target * 0.5
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.55, 0.25)
		fallback.material_override = mat
		_model_rig.add_child(fallback)
	else:
		var model := packed.instantiate() as Node3D
		model.name = "DqtModel"
		model.rotation_degrees = Vector3(0, float(profile.get("rotation_y", 0.0)), 0)
		var native := float(profile.get("native_height", 0.0))
		if native > 0.001 and target > 0.001:
			model.scale = Vector3.ONE * (target / native)
		VfxLib.outline_model(model, 0.0035)
		breath.add_child(model)
		_ap = _find_anim_player(model)
		if _ap != null:
			DqtModelProfiles.apply_anim_aliases(_ap, profile)
			DqtModelProfiles.setup_weapon_follow(model, _ap, profile)
			_strip_root_motion(_ap)
			for anim_name in ["idle", "battle_idle", "walk", "run"]:
				if _ap.has_animation(anim_name):
					_ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
			if profile.get("idle_full", false) and _ap.has_animation("battle_idle"):
				_ap.get_animation("battle_idle").loop_mode = Animation.LOOP_NONE
		DqtModelProfiles.start_idle_breath(_model_rig)

	var camera := Camera3D.new()
	camera.name = "DqtCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = target * 1.55
	camera.position = Vector3(0, target * 1.02, target * 1.50)
	world.add_child(camera)
	camera.look_at(Vector3(0, target * 0.44, 0), Vector3.UP)
	camera.current = true


func _update_animation(movement: Vector2, delta: float) -> void:
	var moving := movement.length_squared() > 0.0001
	if moving:
		if absf(movement.x) > absf(movement.y):
			_last_dir = "right" if movement.x > 0 else "left"
		else:
			_last_dir = "down" if movement.y > 0 else "up"
	if moving != _was_moving:
		_was_moving = moving
		_play_anim("walk" if moving else "idle")
	_face(_last_dir, delta)


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
