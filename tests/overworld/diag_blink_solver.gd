extends SceneTree
## Renders eyes open vs closed (EyelidSolver prototype) for the given species. Args: --ids=a,b --out=dir
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var ids := ["pikachu", "eevee", "charmander"]
	var out := "res://tests/battle/_shots/"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="): ids = a.substr(6).split(",")
		if a.begins_with("--out="): out = a.substr(6)
	var lab = load("res://scripts/debug/third_person_3d_lab.gd").new()
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
	cam.fov = 22
	vp.add_child(cam)
	DirAccess.make_dir_recursive_absolute(out)
	for id in ids:
		var model: Node3D = lab.call("_make_model", id, 1.0)
		vp.add_child(model)
		var ap: AnimationPlayer = lab.call("_find_anim_player", model)
		ap.stop(); ap.active = false
		var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		sk.reset_bone_poses()
		var blinker = model.find_child("EyeBlink", true, false)
		print("BLINKER ", id, " ", blinker, " skin=", blinker._mats[0].get_shader_parameter("skin") if blinker else "-")
		if blinker: blinker.set_process(false)
		var head := sk.find_bone("head")
		var hp := sk.global_transform * sk.get_bone_global_pose(head).origin
		var h := 1.0
		cam.position = Vector3(0.0, 0.7, 1.4)
		for amt in [0.0, 1.0]:
			if blinker: blinker.set_closed(amt)
			for i in 5: await process_frame
			var face := Vector3.ZERO
			var n := 0
			for mi in model.find_children("*", "MeshInstance3D", true, false):
				var m := mi as MeshInstance3D
				if m.mesh == null or m.name.contains("_lod"): continue
				for si in m.mesh.get_surface_count():
					var mt := m.mesh.surface_get_material(si)
					if mt != null and str(mt.resource_name).ends_with("_eye"):
						var vs: PackedVector3Array = m.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
						var cc := Vector3.ZERO
						for v in vs: cc += v
						face += m.global_transform * (cc / vs.size()); n += 1
			face /= maxf(n, 1)
			var span := 0.0
			cam.position = face + Vector3(0, 0, 0.8)
			cam.look_at(face)
			for i in 4: await process_frame
			vp.get_texture().get_image().save_png(out.path_join("squash_%s_%d.png" % [id, int(amt)]))
		model.queue_free()
	quit(0)
