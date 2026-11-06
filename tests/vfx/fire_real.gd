extends SceneTree
## D-332: FOGO COMO EFEITO (não modelo): corpo turbulento em degraus chapados (amarelo, laranja, vermelho, queimado, fuligem preta),
## faíscas com RASTRO, fumaça de fuligem e halo, tudo conduzido pelo Motion Composer. Fundo escuro e claro. Só observa.
##   Godot --path . --script res://tests/vfx/fire_real.gd --resolution 1280x720 -- --out=<pasta>

var _out := ""
var _cam: Camera3D
var _painter: MotionPainter
var _bg: Environment


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	call_deferred("_run")


## Corpo do fogo: o eixo é a horizontal (as línguas se espalham em X); halo atrás.
func _body_effect() -> MotionEffect:
	var fx := MotionEffect.new()
	var halo := MotionPresets._c(&"fr_halo", 1, 2, [] as Array[MotionLayer])
	fx.add("impact", halo, [MotionRep.make("halo", {"element": "fire", "size": 7.0, "strength": 0.5})], {"length": 0.01})
	var base_glow := MotionPresets._c(&"fr_base", 3, 3, [
		MotionPresets._layer(&"spread", &"M03", MotionTypes.Op.OFFSET, {"amplitude": 0.4, "wavelength": 1.2, "speed": 0.0, "axis_deg": 90.0})] as Array[MotionLayer])
	fx.add("impact", base_glow, [MotionRep.make("fire_flow", {"size": 3.0, "look": {"turbulence": 0.8, "soot": 0.6}})], {"length": 1.6, "z_offset": -0.8})
	var body := MotionPresets._c(&"fr_body", 11, 22, [
		MotionPresets._layer(&"spread", &"M03", MotionTypes.Op.OFFSET, {"amplitude": 0.2, "wavelength": 1.7, "speed": 0.0, "axis_deg": 90.0}),
		MotionPresets._layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 1.2, "intensity": 0.18, "time_hz": 0.6, "seed": 3})] as Array[MotionLayer])
	fx.add("impact", body, [MotionRep.make("flame_life", {"size": 2.3, "rate": 0.8, "rise": 0.7, "sway": 0.3})], {"length": 2.6, "z_offset": -1.3})
	return fx


## Subida: o eixo é para CIMA (o cone de M16 e o arrasto M22 sobem); fuligem e faíscas com rastro.
func _rise_effect() -> MotionEffect:
	var fx := MotionEffect.new()
	var smoke_layers: Array[MotionLayer] = MotionPresets._burst(7, 22.0, 2.2, 2.0, 1.4, 0.7)
	smoke_layers.append(MotionPresets._layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 1.5, "intensity": 0.35, "time_hz": 0.4, "seed": 2}))
	var smoke := MotionPresets._c(&"fr_smoke", 5, 7, smoke_layers)
	fx.add("impact", smoke, [MotionRep.make("puff", {"element": "fire", "size": 1.5, "drift": Vector3(0, 0.3, 0), "look": {"light_col": Color(0.24, 0.22, 0.22), "mid_col": Color(0.12, 0.11, 0.11), "dark_col": Color(0.04, 0.035, 0.035), "alpha": 0.6}})], {"length": 0.01})
	var sp_layers: Array[MotionLayer] = MotionPresets._burst(36, 30.0, 3.0, 1.4, 1.2, 0.95)
	sp_layers.append(MotionPresets._layer(&"drag", &"M22", MotionTypes.Op.OFFSET, {"direction": Vector3(0, 0, 1), "speed": 3.0, "drag": 1.6, "spread": 0.6, "t_start": 0.0}))
	sp_layers.append(MotionPresets._layer(&"curl", &"M24", MotionTypes.Op.OFFSET, {"scale": 0.9, "intensity": 0.3, "time_hz": 0.9, "seed": 8}))
	var sparks := MotionPresets._c(&"fr_sparks", 7, 52, sp_layers)
	fx.add("impact", sparks, [MotionRep.make("spark", {"element": "fire", "size": 0.07, "size_jitter": 0.5, "trail": true, "trail_gain": 0.7})], {"length": 0.01, "trail_dt": 0.05})
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
	_cam.global_position = Vector3(0, 2.6, 10.0)
	_cam.look_at(Vector3(0, 2.5, 0), Vector3.UP)
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return _cam.global_position
	_painter.cam_basis_fn = func() -> Basis: return _cam.global_transform.basis
	root.add_child(_painter)
	await process_frame
	if OS.get_cmdline_user_args().has("--video"):
		_bg.background_color = Color(0.05, 0.09, 0.13)
		for i in 90:
			var tv := float(i) / 30.0
			_painter.time = tv
			_painter.begin_frame()
			_body_effect().draw(_painter, "impact", tv, {"origin": Vector3(0, 1.7, 0), "dest": Vector3(1, 1.7, 0), "head": Vector3(0, 1.7, 0), "axis": Vector3(1, 0, 0), "k": 0.5, "p": 1.0, "scale": 1.0})
			_rise_effect().draw(_painter, "impact", fposmod(tv, 1.6), {"origin": Vector3(0, 1.6, 0), "dest": Vector3(0, 2.6, 0), "head": Vector3(0, 1.6, 0), "axis": Vector3(0, 1, 0), "k": 0.5, "p": 1.0, "scale": 1.0})
			_painter.end_frame()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("%s/v_%03d.png" % [_out, i])
		quit(0)
		return
	for light in [false, true]:
		_bg.background_color = Color(0.78, 0.82, 0.85) if light else Color(0.05, 0.09, 0.13)
		for t in [0.3, 0.6, 0.9, 1.3]:
			_painter.time = t
			_painter.begin_frame()
			_body_effect().draw(_painter, "impact", t, {"origin": Vector3(0, 1.7, 0), "dest": Vector3(1, 1.7, 0), "head": Vector3(0, 1.7, 0), "axis": Vector3(1, 0, 0), "k": clampf(t / 1.6, 0, 1), "p": 1.0, "scale": 1.0})
			_rise_effect().draw(_painter, "impact", t, {"origin": Vector3(0, 1.6, 0), "dest": Vector3(0, 2.6, 0), "head": Vector3(0, 1.6, 0), "axis": Vector3(0, 1, 0), "k": clampf(t / 1.6, 0, 1), "p": 1.0, "scale": 1.0})
			_painter.end_frame()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("%s/fogo_%s_%.2f.png" % [_out, "claro" if light else "escuro", t])
	quit(0)
