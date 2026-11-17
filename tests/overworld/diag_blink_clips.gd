extends SceneTree
## Eyes forced closed while a clip plays (damage/attack/victory): checks the shader lid follows the animated head. Args: --ids= --out=
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var ids := ["pikachu", "eevee"]
	var out := "res://tests/battle/_shots/"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
		if a.begins_with("--out="): out = a.substr(6)
	var lab = load("res://scripts/debug/third_person_3d_lab.gd").new()
	var vp := SubViewport.new()
	vp.size = Vector2i(420, 360)
	vp.own_world_3d = true
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
	var cam := Camera3D.new()
	cam.fov = 40
	vp.add_child(cam)
	for id in ids:
		var model: Node3D = lab.call("_make_model", id, 1.0)
		vp.add_child(model)
		var bl = model.find_child("EyeBlink", true, false)
		bl.set_process(false)
		bl.call("set_closed", 1.0)
		var ap: AnimationPlayer = lab.call("_find_anim_player", model)
		var idx := 0
		for clip in ["damage", "attack", "victory"]:
			var len := ap.get_animation(clip).length
			ap.play(clip); ap.seek(len * 0.4, true); ap.pause()
			for i in 5: await process_frame
			var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
			var hb := sk.find_bone("head")
			var head: Vector3 = sk.global_transform * sk.get_bone_global_pose(hb).origin
			var fwd: Vector3 = -(sk.global_transform.basis * sk.get_bone_global_pose(hb).basis).z
			cam.position = head + Vector3(0, 0.1, 1.1)
			cam.look_at(head + Vector3(0, 0.02, 0))
			for i in 3: await process_frame
			vp.get_texture().get_image().save_png(out.path_join("clip_%s_%s.png" % [id, clip]))
		model.queue_free()
	quit(0)
