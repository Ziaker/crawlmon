extends SceneTree
## D-1264: side-view render of each species on a y=0 line. Args after --: id[,id] out_dir
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var lab = load("res://scripts/debug/third_person_3d_lab.gd").new()
	var ids := ["gible", "abra"]
	var out := "res://tests/battle/_shots/"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
		if a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var vp := SubViewport.new()
	vp.size = Vector2i(900, 360)
	var front := OS.get_cmdline_user_args().has("--front")
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.25, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	vp.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(6, 0.02, 3)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.01
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 0.35, 0.2)
	floor_mesh.material_override = m
	vp.add_child(floor_mesh)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.45, 3.2)
	cam.fov = 28
	if front:
		cam.position = Vector3(0, 0.75, 1.5)
		cam.fov = 30
	vp.add_child(cam)
	for id in ids:
		var model: Node3D = lab.call("_make_model", id, 1.0)
		vp.add_child(model)
		var ap: AnimationPlayer = lab.call("_find_anim_player", model)
		var x := -2.0
		for clip in (["idle", "run"] if front else ["idle", "walk", "run"]):
			var a := ap.get_animation(clip)
			for f in (1 if front else 3):
				model.position = Vector3.ZERO
				model.rotation.y = 0.0 if front else PI * 0.5  # facing +X, side on
				ap.play(clip)
				ap.seek(a.length * float(f) / 3.0, true)
				ap.pause()
				for i in 4: await process_frame
				var img := vp.get_texture().get_image()
				img.save_png(ProjectSettings.globalize_path(out) + ("face_%s_%s_%d.png" if front else "feet_%s_%s_%d.png") % [id, clip, f])
		model.queue_free()
	quit(0)
