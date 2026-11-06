extends SceneTree
## D-322: kit de olhar rápido do fogo (Motion Composer), FORA da batalha: roda MotionPresets.fire_effect em tempos
## exatos, de três câmeras (atrás do atacante = vista normal; atrás do alvo = espelhada; lado), e salva quadros inteiros.
## Não substitui a verificação na batalha real (protocolo VFX, seção 3): só acelera o ajuste.
##   Godot --path . --script res://tests/vfx/fire_lab.gd -- --out=<pasta> [--dist=9] [--only=windup|travel|impact]
## Janela (não headless): headless não desenha.

var _out := ""
var _dist := 9.0
var _only := ""
var _cam: Camera3D
var _painter: MotionPainter
var _fxeff: MotionEffect
var _origin := Vector3(0, 1.1, 0)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--dist="):
			_dist = float(a.substr(7))
		elif a.begins_with("--only="):
			_only = a.substr(7)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.09, 0.13)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.07, 0.13, 0.18)
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mi.material_override = fm
	root.add_child(floor_mi)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	_cam.current = true
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return _cam.global_position
	_painter.cam_basis_fn = func() -> Basis: return _cam.global_transform.basis
	root.add_child(_painter)
	_fxeff = MotionPresets.fire_effect(11)
	await process_frame
	var dest := _origin + Vector3(0, 0, -_dist)
	var views := {
		"normal": [_origin + Vector3(1.4, 1.2, 4.2), _origin + Vector3(0, 0.1, -3.0)],  # atrás do atacante, olhando o alvo
		"espelhada": [dest + Vector3(-1.4, 1.2, -4.2), dest + Vector3(0, -0.2, 3.0)],    # atrás do alvo, olhando o atacante
		"lado": [_origin.lerp(dest, 0.5) + Vector3(_dist * 0.6, 1.6, 0), _origin.lerp(dest, 0.5)],
	}
	var jobs := []
	if _only == "" or _only == "windup":
		for t in [0.15, 0.3, 0.5, 0.9]:
			jobs.append(["windup", t])
	if _only == "" or _only == "travel":
		for t in [0.04, 0.1, 0.2, 0.3, 0.45, 0.6]:
			jobs.append(["travel", t])
	if _only == "" or _only == "impact":
		for t in [0.05, 0.12, 0.25, 0.45, 0.8, 1.4]:
			jobs.append(["impact", t])
	for vname in views.keys():
		var vp: Array = views[vname]
		_cam.global_position = vp[0]
		_cam.look_at(vp[1], Vector3.UP)
		for j in jobs:
			_fxeff = MotionPresets.fire_effect(11)  # estado limpo por quadro (os tempos são absolutos)
			_painter.time = float(j[1])
			_painter.begin_frame()
			_draw(String(j[0]), float(j[1]), dest)
			_painter.end_frame()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_viewport().get_texture().get_image()
			img.save_png("%s/%s_%s_%.2f.png" % [_out, vname, j[0], float(j[1])])
	quit(0)


func _draw(phase: String, t: float, dest: Vector3) -> void:
	var axis := (dest - _origin).normalized()
	match phase:
		"windup":
			# varre o relógio inteiro do wind-up até t (as camadas guardam estado de quadro anterior)
			var k := clampf(t / 0.5, 0.0, 1.0)
			_fxeff.draw(_painter, "windup", t, {"origin": _origin, "dest": dest, "head": _origin, "axis": axis, "k": k, "p": 0.0, "scale": 1.0})
		"travel":
			var p := clampf(t / 0.63, 0.0, 1.0)
			var head := _origin.lerp(dest, p)
			# aquece o 'follow' dos vórtices (congelam o quadro depois de 0,2 s)
			var s := 0.0
			while s < t:
				_fxeff.draw(_painter, "travel", s, {"origin": _origin, "dest": dest, "head": _origin.lerp(dest, clampf(s / 0.63, 0.0, 1.0)), "axis": axis, "k": s / 0.63, "p": clampf(s / 0.63, 0.0, 1.0), "scale": 1.0})
				s += 0.05
			_painter.begin_frame()
			_fxeff.draw(_painter, "travel", t, {"origin": _origin, "dest": dest, "head": head, "axis": axis, "k": p, "p": p, "scale": 1.0})
		"impact":
			var fwd := (axis + Vector3.UP * 0.1).normalized()
			_fxeff.draw(_painter, "impact", t, {"origin": dest, "dest": dest + fwd, "head": dest, "axis": fwd, "k": clampf(t / 2.2, 0.0, 1.0), "p": 1.0, "scale": 1.0})
