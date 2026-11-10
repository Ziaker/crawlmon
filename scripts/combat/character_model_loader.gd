class_name CharacterModelLoader
extends RefCounted

## Shared utility for instantiating and configuring 3D character models across battle scenes,
## isolated SubViewports (LevelUpHUD), and debug lab environments.

const MODEL_SCALE := 2.5


static func create_character_model(combatant: Combatant, color: Color = Color.WHITE, include_burst_ring: bool = false) -> Node3D:
	var root := Node3D.new()
	if combatant == null:
		return root

	var model_id := combatant.name.to_lower()
	if combatant.species_id != "":
		model_id = combatant.species_id.to_lower()
	var glb_path := "res://assets/modelos/%s/%s.glb" % [model_id, model_id]
	# D-1079: o perfil canônico do personagem vive no CharacterData; o dicionário
	# legado de DqtModelProfiles fica como fallback para modelos fora do catálogo.
	var character_data := CharacterCatalog.get_character(StringName(model_id))
	var dqt_profile: Dictionary = character_data.model_profile_dict() if character_data != null else {}
	if dqt_profile.is_empty():
		dqt_profile = DqtModelProfiles.get_profile(model_id)

	var is_3d_pokemon := false
	if ResourceLoader.exists(glb_path):
		var glb_scene: PackedScene = load(glb_path)
		if glb_scene:
			var pokemon_instance := glb_scene.instantiate()
			# Pokemon GLBs come out of Blender Z-up: tip them upright and scale up.
			# DQT GLBs are already Y-up, so they only get the height fit.
			if dqt_profile.is_empty():
				pokemon_instance.rotation_degrees.x = 90.0
				pokemon_instance.scale = Vector3.ONE * MODEL_SCALE
			else:
				pokemon_instance.rotation_degrees = Vector3(
					0.0, float(dqt_profile.get("rotation_y", 0.0)), 0.0)
				var native_height := float(dqt_profile.get("native_height", 0.0))
				var target_height := float(dqt_profile.get("target_height", 0.0))
				if native_height > 0.001 and target_height > 0.001:
					pokemon_instance.scale = Vector3.ONE * (target_height / native_height)
			if dqt_profile.is_empty():
				root.add_child(pokemon_instance)
			else:
				var breath := Node3D.new()
				breath.name = "DqtIdleBreath"
				breath.set_meta("height", float(dqt_profile.get("target_height", 2.0)))
				root.add_child(breath)
				breath.add_child(pokemon_instance)

			VfxLib.outline_model(pokemon_instance, 0.0035)
			is_3d_pokemon = true

			var anim_player: AnimationPlayer = find_anim_player(pokemon_instance)
			if anim_player:
				if not dqt_profile.is_empty():
					DqtModelProfiles.apply_anim_aliases(anim_player, dqt_profile)
					DqtModelProfiles.setup_weapon_follow(pokemon_instance, anim_player, dqt_profile)
					# D-340: game eye rule (<X>_scale) + own blink.
					DqtEyes.attach(root, pokemon_instance, anim_player,
						str(dqt_profile.get("clip_prefix", "")) + "04")
					DqtModelProfiles.setup_run_stride(root, pokemon_instance, anim_player, dqt_profile)  # D-341
				root.set_meta("anim_player", anim_player)
				strip_root_motion(anim_player)
				# Configure linear loops for resting animations
				for anim_name in ["idle", "battle_idle", "walk", "run", "charge"]:
					if anim_player.has_animation(anim_name):
						anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
				if not dqt_profile.is_empty() and dqt_profile.get("idle_full", false):
					if anim_player.has_animation("battle_idle"):
						anim_player.get_animation("battle_idle").loop_mode = Animation.LOOP_NONE
				if anim_player.has_animation("battle_idle"):
					anim_player.play("battle_idle")
				elif anim_player.has_animation("idle"):
					anim_player.play("idle")

	if not is_3d_pokemon:
		var mesh := MeshInstance3D.new()
		mesh.mesh = CapsuleMesh.new()
		mesh.position.y = 1.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mesh.material_override = mat
		root.add_child(mesh)
		root.set_meta("mesh", mesh)

	root.set_meta("color", color)

	if include_burst_ring:
		var ring := MeshInstance3D.new()
		ring.name = "BurstRing"
		var torus := TorusMesh.new()
		torus.inner_radius = 0.9
		torus.outer_radius = 1.1
		ring.mesh = torus
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = Color(1.0, 0.8, 0.1)
		ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = ring_mat
		ring.position.y = 0.05
		ring.visible = false
		root.add_child(ring)
		root.set_meta("burst_ring", ring)

	return root


static func get_anim_player(model: Node3D) -> AnimationPlayer:
	if model == null:
		return null
	if model.has_meta("anim_player"):
		return model.get_meta("anim_player") as AnimationPlayer
	return find_anim_player(model)


static func find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var res := find_anim_player(child)
		if res:
			return res
	return null


static func strip_root_motion(ap: AnimationPlayer) -> void:
	if ap == null:
		return
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


## Orchestrates a stylized squash-and-stretch victory jump (SMT III / Dragon Ball celebration).
static func play_victory_jump(model: Node3D, tween: Tween) -> void:
	if model == null or tween == null:
		return
	var orig_pos := model.position
	var orig_scale := model.scale

	# 1. Anticipation squash (0.08s)
	tween.tween_property(model, "scale", Vector3(orig_scale.x * 1.12, orig_scale.y * 0.85, orig_scale.z * 1.12), 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Upward jump + stretch (0.22s)
	tween.tween_property(model, "position:y", orig_pos.y + 0.65, 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(model, "scale", Vector3(orig_scale.x * 0.92, orig_scale.y * 1.15, orig_scale.z * 0.92), 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Fall & impact landing (0.18s)
	tween.tween_property(model, "position:y", orig_pos.y, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(model, "scale", Vector3(orig_scale.x * 1.08, orig_scale.y * 0.92, orig_scale.z * 1.08), 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 4. Settle back to original scale (0.07s)
	tween.tween_property(model, "scale", orig_scale, 0.07)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Calculates the composite AABB bounds of all visual MeshInstance3D nodes in the model.
static func calculate_model_bounds(model: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for mesh_inst in model.find_children("*", "MeshInstance3D", true, false):
		if mesh_inst is MeshInstance3D and mesh_inst.mesh:
			var xform: Transform3D = Transform3D.IDENTITY
			var cur: Node = mesh_inst
			while cur and cur != model:
				if cur is Node3D:
					xform = cur.transform * xform
				cur = cur.get_parent()
			var mesh_aabb: AABB = xform * mesh_inst.mesh.get_aabb()
			if first:
				aabb = mesh_aabb
				first = false
			else:
				aabb = aabb.merge(mesh_aabb)
	if first:
		aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1.0, 2.0, 1.0))
	return aabb


## Dynamically positions and orients the Camera3D based on measured model bounds (Rule 7, D-235).
## Parity with SMT III / HTML prototype: camera positioned at (0, 1.8, 4.2), tilted down ~15 deg
## looking at model center (~0.75m), grounding model at floor y=0 on blue anchor ring.
static func frame_model_camera(model: Node3D, camera: Camera3D, optical_offset_y: float = 0.0, optical_offset_x: float = 0.0) -> void:
	if model == null or camera == null:
		return
	var bounds := calculate_model_bounds(model)
	var height := bounds.size.y
	if height < 0.2 or height > 10.0:
		height = 1.6
	var center := bounds.get_center()
	if center.y < 0.1 or center.y > 5.0:
		center = Vector3(0.0, height * 0.5, 0.0)
	
	camera.fov = 40.0
	camera.position = Vector3(optical_offset_x, 1.8 + optical_offset_y, 4.2)
	camera.look_at(Vector3(0.0, center.y, 0.0))
