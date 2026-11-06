extends SceneTree
## D-332: laboratório do fogo estilizado (shader mc_fire_cel). Mostra uma fileira de chamas (sementes, tamanhos, fades e
## rotações diferentes) em fundo escuro e claro, e as chamas vistas de lado e de frente. Só observa.
##   Godot --path . --script res://tests/vfx/cel_fire_lab.gd --resolution 1280x720 -- --out=<pasta>

var _out := ""
var _cam: Camera3D
var _painter: MotionPainter
var _bg: Environment


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	_bg = Environment.new()
	_bg.background_mode = Environment.BG_COLOR
	var we := WorldEnvironment.new()
	we.environment = _bg
	root.add_child(we)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	_cam.current = true
	_cam.global_position = Vector3(0, 1.6, 9.0)
	_cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return _cam.global_position
	_painter.cam_basis_fn = func() -> Basis: return _cam.global_transform.basis
	root.add_child(_painter)
	await process_frame
	for light in [false, true]:
		_bg.background_color = Color(0.78, 0.82, 0.85) if light else Color(0.05, 0.09, 0.13)
		for t in [0.0, 0.25, 0.5, 0.75]:
			_painter.time = t
			_painter.begin_frame()
			var items := [
				# x, tamanho, semente, fade, rolagem
				[-6.0, 2.4, 1.0, 0.0, 0.0], [-3.0, 2.4, 2.0, 0.0, 0.0], [0.0, 2.4, 3.0, 0.0, 0.0], [3.0, 2.4, 4.0, 0.0, 0.0], [6.0, 2.4, 5.0, 0.0, 0.0],
				[-6.0, 1.3, 6.0, 0.0, 0.0], [-3.0, 1.3, 7.0, 0.35, 0.0], [0.0, 1.3, 8.0, 0.6, 0.0], [3.0, 1.0, 9.0, 0.0, 0.5], [6.0, 1.0, 10.0, 0.0, -0.5],
			]
			for i in items.size():
				var it: Array = items[i]
				var row := 1 if i < 5 else 0
				_painter.cel_flame(Vector3(it[0], 0.4 + (2.6 if row == 1 else 0.0) * 0.0 + (2.4 if row == 1 else 0.0), 0.0), it[1], it[3], it[2], it[4], t, {})
			_painter.end_frame()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("%s/cel_%s_%.2f.png" % [_out, "claro" if light else "escuro", t])
	quit(0)
