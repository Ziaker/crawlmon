extends SceneTree
## REJECTED (D-953, 2026-11-06): lab experiment only. The creator discarded the melee results and pointed
## to the procedural motion itself as the cause. No game code uses this scene.
##
## D-953: laboratório do Composer de Fases — MELEE (Tackle/Brick Break).
## Desenha o contrato visual em instantes exatos, nas duas vistas do jogo (normal e espelhada), com o
## atacante e o alvo como marcadores neutros. Não substitui o VFX do jogo e não lê nem altera o combate.
##   Godot --path . --script res://tests/vfx/melee_phase_lab.gd --resolution 1280x720 -- --out=<pasta>
##         [--run=0.8] [--strike=0.43] [--hold=0.7] [--hop=0.3] [--dist=8] [--brick=1]

var _out := "test_captures/melee_phase_lab"
var _run := 0.80
var _strike := 0.43
var _hold := 0.70
var _hop := 0.30
var _dist := 8.0
var _brick := false
var _times := [0.2, 0.8, 1.35, 1.48, 1.6, 1.9, 2.3, 2.44, 2.55, 2.75, 2.95, 3.2, 3.8]
var _video := ""
var _fps := 60.0
var _seconds := 4.0
var _cam: Camera3D
var _painter: MotionPainter
var _bg: Environment
var _floor_mat: StandardMaterial3D
var _mover_a: MeshInstance3D
var _mover_t: MeshInstance3D

const WINDUP := 1.5
const ANTIC := 0.08


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--run="):
			_run = float(a.substr(6))
		elif a.begins_with("--strike="):
			_strike = float(a.substr(9))
		elif a.begins_with("--hold="):
			_hold = float(a.substr(7))
		elif a.begins_with("--hop="):
			_hop = float(a.substr(6))
		elif a.begins_with("--dist="):
			_dist = float(a.substr(7))
		elif a.begins_with("--brick="):
			_brick = a.substr(8) != "0"
		elif a.begins_with("--times="):
			_times = []
			for t in a.substr(8).split(","):
				_times.append(float(t))
		elif a.begins_with("--video="):
			_video = a.substr(8)
		elif a.begins_with("--fps="):
			_fps = float(a.substr(6))
		elif a.begins_with("--seconds="):
			_seconds = float(a.substr(10))
	call_deferred("_run_lab")


func _run_lab() -> void:
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
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = Color(0.07, 0.13, 0.18)
	_floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fl.material_override = _floor_mat
	root.add_child(fl)

	var attacker := Vector3(0.0, 1.2, 0.0)
	var target := Vector3(0.0, 1.2, -_dist)
	_mover_a = _add_marker(attacker)
	_mover_t = _add_marker(target)

	# The game's CINEMA camera (BattleCamera): same position, FOV and look direction.
	_cam = Camera3D.new()
	_cam.fov = 80.0
	root.add_child(_cam)
	_cam.global_position = Vector3(3.8, 2.875, 7.0)
	_cam.current = true
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return _cam.global_position
	_painter.cam_basis_fn = func() -> Basis: return _cam.global_transform.basis
	root.add_child(_painter)
	await process_frame

	if _video != "":
		await _record_video(attacker, target)
		quit(0)
		return

	# normal: the player attacks the far target. mirrored: the far enemy attacks the near target.
	# The camera stays put (the game has one camera); only the participants swap sides.
	var views := {
		"normal": [attacker, target],
		"espelhada": [target, attacker],
	}
	var report := {"phases": _phase_list(), "frames": [], "ab_same_seed": -1.0, "ab_other_seed": -1.0}
	for vname in views.keys():
		var a: Vector3 = views[vname][0]
		var tgt: Vector3 = views[vname][1]
		_mover_a.position = a
		_mover_t.position = tgt
		_cam.look_at(tgt + Vector3(0, 1.1, 0), Vector3.UP)
		for t in _times:
			var contract := _contract()
			_painter.time = float(t)
			_painter.begin_frame()
			contract.draw(_painter, float(t), _geo(float(t), a, tgt))
			_painter.end_frame()
			var st := _painter.stats()
			var file := "%s_%s_%.2f.png" % ["melee", vname, float(t)]
			await _shot(_out + "/" + file)
			(report["frames"] as Array).append({"file": file, "view": vname, "t": t, "nodes": st["nodes"], "tris": st["tris"], "by_key": st["by_key"]})

	# A/B no instante do impacto: mesma semente = igual; semente diferente = diferente.
	_mover_a.position = attacker
	_mover_t.position = target
	_cam.look_at(target + Vector3(0, 1.1, 0), Vector3.UP)
	report["ab_same_seed"] = await _ab(attacker, target, 2.55, 7, 7)
	report["ab_other_seed"] = await _ab(attacker, target, 2.55, 7, 8)
	report["leftovers_at_4s"] = _leftovers(attacker, target)
	var f := FileAccess.open(_out + "/lab.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	quit(0)


## D-308/D-953: every frame at `_fps`, both views, full resolution. The caller assembles the video with ffmpeg
## (normal on top, mirrored below) so the two game views are in ONE file.
func _record_video(attacker: Vector3, target: Vector3) -> void:
	var views := {"normal": [attacker, target], "espelhada": [target, attacker]}
	for vname in views.keys():
		var a: Vector3 = views[vname][0]
		var tgt: Vector3 = views[vname][1]
		_mover_a.position = a
		_mover_t.position = tgt
		_cam.look_at(tgt + Vector3(0, 1.1, 0), Vector3.UP)
		var dir := "%s/%s" % [_video, vname]
		DirAccess.make_dir_recursive_absolute(dir)
		var c := _contract()
		var n := int(_seconds * _fps)
		for f in n:
			var t := float(f) / _fps
			_painter.time = t
			_painter.begin_frame()
			c.draw(_painter, t, _geo(t, a, tgt))
			_painter.end_frame()
			await _shot("%s/f_%04d.png" % [dir, f])


func _phase_list() -> Array:
	return [
		{"id": "windup", "start": 0.0, "end": WINDUP},
		{"id": "post_windup", "start": WINDUP, "end": WINDUP},
		{"id": "release", "start": WINDUP - 0.1, "end": WINDUP + 0.25},
		{"id": "travel", "start": WINDUP, "end": WINDUP + 0.12 + _run},
		{"id": "impact", "start": WINDUP + 0.12 + _run, "end": WINDUP + 0.12 + _run + ANTIC + _strike},
		{"id": "return", "start": WINDUP + 0.12 + _run + ANTIC + _strike, "end": WINDUP + 0.12 + _run + ANTIC + _strike + _hold + _hop},
	]


func _contract() -> MotionPhaseContract:
	var c := MotionPhaseContract.new()
	c.id = "melee_tackle"
	c.effect = MotionPresets.tackle_rush_effect(7, _brick)
	var t0 := WINDUP
	var t1 := WINDUP + 0.12 + _run
	var t2 := t1 + ANTIC + _strike
	var t3 := t2 + _hold + _hop
	c.add_phase("windup", 0.0, t0, "windup")
	c.add_phase("post_windup", t0, t0, "post_windup")
	c.add_phase("release", t0 - 0.1, t0 + 0.25, "release")
	c.add_phase("travel", t0, t1, "travel")
	c.add_phase("impact", t1, t2, "impact")
	c.add_phase("return", t2, t3, "return")
	return c


func _geo(t: float, attacker: Vector3, target: Vector3) -> Dictionary:
	var t0 := WINDUP
	var t1 := WINDUP + 0.12 + _run
	var t2 := t1 + ANTIC + _strike
	var t3 := t2 + _hold + _hop
	var axis := (target - attacker).normalized()
	var p := 0.0
	if t >= t0 and t <= t1:
		p = clampf((t - t0 - 0.12) / maxf(_run, 0.01), 0.0, 1.0)
	var head := attacker
	if t >= t0 and t <= t1:
		head = attacker.lerp(target, p)
	elif t > t1 and t < t2:
		head = target
	elif t >= t2:
		var rp := clampf((t - t2) / maxf(_hold + _hop, 0.01), 0.0, 1.0)
		head = target.lerp(attacker, rp) + Vector3.UP * sin(PI * rp) * 1.6
	var origin := attacker if t < t1 else target
	var dest := target if t < t1 else attacker
	return {"origin": origin, "dest": dest, "head": head, "axis": axis, "k": 0.0,
		"p": p if t <= t1 else 1.0, "scale": 1.0, "landed": t >= t1}


func _add_marker(p: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.34
	cap.height = 2.0
	cap.radial_segments = 16
	cap.rings = 8
	mi.mesh = cap
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.19, 0.22, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.position = p
	root.add_child(mi)
	return mi


func _ab(attacker: Vector3, target: Vector3, t: float, seed_a: int, seed_b: int) -> float:
	var a: Image = await _render_ab(attacker, target, t, seed_a)
	var b: Image = await _render_ab(attacker, target, t, seed_b)
	return _diff(a, b)


func _render_ab(attacker: Vector3, target: Vector3, t: float, seed_value: int) -> Image:
	var c := MotionPhaseContract.new()
	c.id = "melee_tackle"
	c.effect = MotionPresets.tackle_rush_effect(seed_value, _brick)
	var t0 := WINDUP
	var t1 := WINDUP + 0.12 + _run
	var t2 := t1 + ANTIC + _strike
	var t3 := t2 + _hold + _hop
	c.add_phase("windup", 0.0, t0, "windup")
	c.add_phase("post_windup", t0, t0, "post_windup")
	c.add_phase("release", t0 - 0.1, t0 + 0.25, "release")
	c.add_phase("travel", t0, t1, "travel")
	c.add_phase("impact", t1, t2, "impact")
	c.add_phase("return", t2, t3, "return")
	_painter.time = t
	_painter.begin_frame()
	c.draw(_painter, t, _geo(t, attacker, target))
	_painter.end_frame()
	return await _shot("")


func _leftovers(attacker: Vector3, target: Vector3) -> int:
	var c := _contract()
	_painter.time = 4.0
	_painter.begin_frame()
	c.draw(_painter, 4.0, _geo(4.0, attacker, target))
	_painter.end_frame()
	return int(_painter.stats()["nodes"])


func _shot(path: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	if path != "":
		img.save_png(path)
	return img


func _diff(a: Image, b: Image) -> float:
	var sum := 0.0
	var n := 0
	for y in range(0, a.get_height(), 3):
		for x in range(0, a.get_width(), 3):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			sum += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			n += 1
	return sum / float(maxi(n, 1))
