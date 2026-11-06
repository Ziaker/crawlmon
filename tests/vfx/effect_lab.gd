extends SceneTree
## D-332: laboratório genérico de um Move de elemento (MotionPresets.effect_for): desenha as quatro fases em instantes exatos, de duas
## câmeras (atrás do atacante e atrás do alvo = as duas vistas do jogo), em fundo escuro, sem a batalha. Acelera o ajuste; NÃO substitui a
## verificação na batalha real. Só observa.
##   Godot --path . --script res://tests/vfx/effect_lab.gd --resolution 1280x720 -- --move=splitter_flames --out=<pasta> [--dist=12]

var _out := ""
var _move := "splitter_flames"
var _dist := 12.0
var _cam: Camera3D
var _painter: MotionPainter
var _bg: Environment


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--move="):
			_move = a.substr(7)
		elif a.begins_with("--dist="):
			_dist = float(a.substr(7))
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	_bg = Environment.new()
	_bg.background_mode = Environment.BG_COLOR
	_bg.background_color = Color(0.05, 0.09, 0.13)
	var we := WorldEnvironment.new()
	we.environment = _bg
	root.add_child(we)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	fl.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.07, 0.13, 0.18)
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fl.material_override = fm
	root.add_child(fl)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	_cam.current = true
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return _cam.global_position
	_painter.cam_basis_fn = func() -> Basis: return _cam.global_transform.basis
	root.add_child(_painter)
	await process_frame
	var origin := Vector3(0, 1.5, 0)
	var dest := Vector3(0, 1.5, -_dist)
	var axis := Vector3(0, 0, -1)
	var views := {
		"normal": [origin + Vector3(1.6, 1.4, 4.0), origin + Vector3(0, -0.1, -4.0)],
		"espelhada": [dest + Vector3(-1.6, 1.4, -4.0), dest + Vector3(0, -0.2, 4.0)],
	}
	var jobs := [["windup", 0.1], ["windup", 0.35], ["windup", 0.7], ["windup", 1.0],
		["travel", 0.05], ["travel", 0.15], ["travel", 0.3], ["travel", 0.5],
		["impact", 0.05], ["impact", 0.2], ["impact", 0.5], ["impact", 0.9], ["impact", 1.4]]
	for vname in views.keys():
		_cam.global_position = views[vname][0]
		_cam.look_at(views[vname][1], Vector3.UP)
		for j in jobs:
			var fx := MotionPresets.effect_for(_move, 7)
			var ph: String = j[0]
			var t: float = j[1]
			_painter.time = t
			_painter.begin_frame()
			var geo := {"origin": origin, "dest": dest, "head": origin, "axis": axis, "k": clampf(t / 0.7, 0.0, 1.0), "p": 0.0, "scale": 1.0}
			if ph == "travel":
				# aquece o estado (as camadas "follow" congelam o quadro) e põe a cabeça no progresso do voo (0,63 s)
				var s := 0.0
				while s < t:
					var pp := clampf(s / 0.63, 0.0, 1.0)
					fx.draw(_painter, "travel", s, {"origin": origin, "dest": dest, "head": origin.lerp(dest, pp), "axis": axis, "k": pp, "p": pp, "scale": 1.0})
					s += 0.05
				_painter.begin_frame()
				var p2 := clampf(t / 0.63, 0.0, 1.0)
				geo = {"origin": origin, "dest": dest, "head": origin.lerp(dest, p2), "axis": axis, "k": p2, "p": p2, "scale": 1.0}
			elif ph == "impact":
				geo = {"origin": dest, "dest": dest + axis, "head": dest, "axis": axis, "k": clampf(t / 2.2, 0.0, 1.0), "p": 1.0, "scale": 1.0}
			fx.draw(_painter, ph, t, geo)
			_painter.end_frame()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("%s/%s_%s_%s_%.2f.png" % [_out, _move, vname, ph, t])
	quit(0)
