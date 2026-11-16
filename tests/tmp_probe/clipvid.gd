extends SceneTree
## Plays every DQT clip in sequence and saves frames: out/<model>_<clip>_<frame>.png (30 fps)
var _out := ""
var _todo: Array = []
var _cam: Camera3D
func _init() -> void:
	_out = OS.get_cmdline_user_args()[0]
	for f in ["dqt_slime"]:
		_todo.append(f)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.15, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	env.environment = e
	root.add_child(env)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, 30, 0)
	root.add_child(l)
	_cam = Camera3D.new()
	root.add_child(_cam)
	_run.call_deferred()
func _run() -> void:
	for f in _todo:
		var n := (load("res://assets/modelos/%s/%s.glb" % [f, f]) as PackedScene).instantiate() as Node3D
		root.add_child(n)
		var ap := n.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		await process_frame
		var box := AABB()
		var first := true
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var b := (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
			box = b if first else box.merge(b)
			first = false
		var h := box.size.y
		var c := box.get_center()
		_cam.position = c + Vector3(h * 1.0, h * 0.25, -h * 1.6)
		_cam.look_at(c)
		for a in ap.get_animation_list():
			var clip := String(a).get_slice("_", 3)
			var len := ap.get_animation(a).length
			var k := 0
			var t := 0.0
			while t <= len:
				ap.play(a)
				ap.seek(t, true)
				ap.pause()
				await process_frame
				root.get_viewport().get_texture().get_image().save_png("%s/%s_%s_%04d.png" % [_out, f, clip, k])
				k += 1
				t += 1.0 / 30.0
		n.queue_free()
	quit()
