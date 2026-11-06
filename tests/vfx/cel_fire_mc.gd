extends SceneTree
## D-332: o fogo estilizado CONDUZIDO PELO MOTION COMPOSER: um rastro de chamas (M03 serpentina + M24 turbulência coerente, nasce
## M17, se apaga M18), brasas (M16 + M22 + M23) e um flipbook (sheet fire_cel) no impacto. Fundo escuro e claro. Só observa.
##   Godot --path . --script res://tests/vfx/cel_fire_mc.gd --resolution 1280x720 -- --out=<pasta>

var _out := ""
var _cam: Camera3D
var _painter: MotionPainter
var _bg: Environment


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	call_deferred("_run")


func _effect() -> MotionEffect:
	var fx := MotionEffect.new()
	# rastro: 14 chamas ao longo de uma serpentina; nascem (M17) e se apagam (M18); o corpo tem turbulência coerente
	var trail := MotionPresets._c(&"cel_trail", 5, 14, [
		MotionPresets._layer(&"snake", &"M03", MotionTypes.Op.OFFSET, {"amplitude": 0.28, "wavelength": 2.2, "speed": 2.0, "axis_deg": 90.0}),
		MotionPresets._layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 1.4, "intensity": 0.12, "time_hz": 0.5, "seed": 1}),
		MotionPresets._grow(0.4), MotionPresets._dissolve(0.6, 0.6, 0.5)] as Array[MotionLayer])
	fx.add("impact", trail, [MotionRep.make("cel_flame", {"size": 1.3})], {"length": 6.0})
	# brasas: explosão direcional + arrasto + queda
	var em_layers: Array[MotionLayer] = MotionPresets._burst(26, 55.0, 2.4, 1.1, 1.5, 0.9)
	em_layers.append(MotionPresets._layer(&"gravity", &"M23", MotionTypes.Op.OFFSET, {"direction": Vector3(0, -1, 0), "gravity": -1.5, "spread": 0.3, "t_start": 0.0}))
	var embers := MotionPresets._c(&"cel_embers", 7, 26, em_layers)
	fx.add("impact", embers, [MotionRep.make("spark", {"element": "fire", "size": 0.09, "stretch": 3.0, "size_jitter": 0.5})], {"length": 0.01, "z_offset": 0.0})
	# flipbook do jogo (assado do mesmo shader) numa amostra só, avançando pelos quadros
	var fb := MotionPresets._c(&"cel_flipbook", 9, 2, [MotionPresets._dissolve(1.0, 0.6)] as Array[MotionLayer])
	fx.add("impact", fb, [MotionRep.make("sprite", {"sheet": "fire_cel", "size": 2.4, "energy": 1.0, "sway_speed": 1.2})], {"length": 0.01})
	return fx


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
	_cam.global_position = Vector3(0, 1.8, 11.0)
	_cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return _cam.global_position
	_painter.cam_basis_fn = func() -> Basis: return _cam.global_transform.basis
	root.add_child(_painter)
	await process_frame
	for light in [false, true]:
		_bg.background_color = Color(0.78, 0.82, 0.85) if light else Color(0.05, 0.09, 0.13)
		for t in [0.2, 0.5, 0.8, 1.2, 1.6]:
			var fx := _effect()
			_painter.time = t
			_painter.begin_frame()
			var origin := Vector3(-3.4, 0.5, 0)
			var axis := Vector3(1, 0, 0)
			fx.draw(_painter, "impact", t, {"origin": origin, "dest": origin + axis * 6.0, "head": origin, "axis": axis, "k": clampf(t / 1.6, 0, 1), "p": 1.0, "scale": 1.0})
			# flipbook e brasas ficam na direita (origem própria)
			_painter.end_frame()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("%s/mc_%s_%.2f.png" % [_out, "claro" if light else "escuro", t])
	quit(0)
