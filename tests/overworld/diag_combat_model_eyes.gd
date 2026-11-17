extends SceneTree
## Eye check through the COMBAT loader (CharacterModelLoader). Args: --ids=a,b --out=dir
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var ids := ["pikachu", "eevee"]
	var out := "res://tests/battle/_shots/"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
		if a.begins_with("--out="): out = a.substr(6)
	var vp := SubViewport.new()
	vp.size = Vector2i(500, 360)
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
	vp.add_child(cam)
	for id in ids:
		var c := Combatant.new(id.capitalize(), 10, 1, 1.0, true)
		c.species_id = id
		var model := CharacterModelLoader.create_character_model(c)
		vp.add_child(model)
		var box := AABB()
		var first := true
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			var b := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			box = b if first else box.merge(b)
			first = false
		var head := box.position + Vector3(box.size.x * 0.5, box.size.y * 0.58, box.size.z * 0.5)
		cam.position = head + Vector3(0, 0, box.size.y * 1.5)
		cam.fov = 30
		cam.look_at(head)
		for i in 6: await process_frame
		DirAccess.make_dir_recursive_absolute(out)
		vp.get_texture().get_image().save_png(out.path_join("combat_%s.png" % id))
		model.queue_free()
	quit(0)
