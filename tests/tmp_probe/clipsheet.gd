extends SceneTree
## Renders frames of unused DQT clips (03, 04, 05, 50) to PNGs: res://tests/tmp_probe/out/<model>_<clip>_<i>.png
var _todo: Array = []
var _cam: Camera3D
var _cur: Node3D
var _ap: AnimationPlayer
var _out := ""

func _init() -> void:
	_out = OS.get_cmdline_user_args()[0]
	for f in ["dqt_orc", "dqt_cyclops"]:
		for c in ["03", "04", "05", "50", "12"]:
			_todo.append([f, c])
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
	_next.call_deferred()

func _next() -> void:
	if _todo.is_empty():
		quit()
		return
	var job: Array = _todo.pop_front()
	if _cur != null:
		_cur.queue_free()
	_cur = (load("res://assets/modelos/%s/%s.glb" % [job[0], job[0]]) as PackedScene).instantiate()
	root.add_child(_cur)
	_ap = _cur.find_children("*", "AnimationPlayer", true, false)[0]
	var name := ""
	for a in _ap.get_animation_list():
		if String(a).ends_with("_" + str(job[1])):
			name = a
	await process_frame
	var box := AABB()
	var first := true
	for m in _cur.find_children("*", "MeshInstance3D", true, false):
		var b := (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	var h := box.size.y
	var c := box.get_center()
	_cam.position = c + Vector3(h * 0.9, h * 0.2, -h * 1.3)
	_cam.look_at(c)
	var len := _ap.get_animation(name).length
	for i in 6:
		_ap.play(name)
		_ap.seek(len * float(i) / 5.0, true)
		_ap.pause()
		await process_frame
		await process_frame
		root.get_viewport().get_texture().get_image().save_png("%s/%s_%s_%d.png" % [_out, job[0], job[1], i])
	_next()
