extends SceneTree
## Motion Composer V1.2 (D-323): LABORATÓRIO DE AVALIAÇÃO. Renderiza a galeria (8 amostras neutras, não são Moves) de cada
## elemento em instantes exatos, em fundo escuro e claro, na vista normal e espelhada, com a mesma semente (A/B), e mede:
## tempo de avaliação, nós, triângulos e repetibilidade. Só observa: não altera nenhum efeito nem regra.
##   Godot --path . --script res://tests/vfx/mc_lab.gd --resolution 1280x720 -- --out=<pasta> [--elements=fire,water,earth,air] [--times=0.15,0.4,0.8,1.3]
## Janela (não headless): headless não desenha. Saída: PNGs inteiros 1280x720 + lab.json.

var _out := ""
var _elements := ["fire", "water", "earth", "air"]
var _times := [0.15, 0.4, 0.8, 1.3]
var _cam: Camera3D
var _painter: MotionPainter
var _bg: Environment
var _floor_mat: StandardMaterial3D
var _report := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--elements="):
			_elements = a.substr(11).split(",")
		elif a.begins_with("--times="):
			_times = []
			for t in a.substr(8).split(","):
				_times.append(float(t))
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	_bg = Environment.new()
	_bg.background_mode = Environment.BG_COLOR
	var we := WorldEnvironment.new()
	we.environment = _bg
	root.add_child(we)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	floor_mi.mesh = pm
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mi.material_override = _floor_mat
	root.add_child(floor_mi)
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)
	_cam.current = true
	_cam.global_position = Vector3(4.5, 4.6, 11.5)  # em diagonal: formas redondas (arco, hélice) não ficam de perfil
	_cam.look_at(Vector3(0, 2.2, 0), Vector3.UP)
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return _cam.global_position
	_painter.cam_basis_fn = func() -> Basis: return _cam.global_transform.basis
	root.add_child(_painter)
	await process_frame
	for el in _elements:
		await _element(String(el))
	var f := FileAccess.open(_out + "/lab.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_report, "  "))
	f.close()
	quit(0)


func _set_bg(light: bool) -> void:
	_bg.background_color = Color(0.78, 0.82, 0.85) if light else Color(0.05, 0.09, 0.13)
	_floor_mat.albedo_color = Color(0.7, 0.74, 0.77) if light else Color(0.07, 0.13, 0.18)


## Desenha a galeria inteira num instante. Devolve {ms, nodes, tris, by_cell}.
func _draw_gallery(cells: Dictionary, t: float, mirror: bool) -> Dictionary:
	_painter.time = t
	_painter.begin_frame()
	var total_us := 0
	var by_cell := {}
	var i := 0
	for name in MotionGallery.CELLS:
		var col := i % 4
		var row := i / 4
		var x := (float(col) - 1.5) * 3.8 + (1.5 if mirror else -1.5)
		var origin := Vector3(x, 4.0 - float(row) * 2.6, 0.0)
		var axis := Vector3(-1, 0, 0) if mirror else Vector3(1, 0, 0)
		var t0 := Time.get_ticks_usec()
		(cells[name] as MotionEffect).draw(_painter, "impact", t, {"origin": origin, "dest": origin + axis * 3.0, "head": origin, "axis": axis, "k": clampf(t / 1.5, 0.0, 1.0), "p": 1.0, "scale": 1.0})
		var us := Time.get_ticks_usec() - t0
		total_us += us
		by_cell[name] = us / 1000.0
		i += 1
	_painter.end_frame()
	var st := _painter.stats()
	return {"ms": total_us / 1000.0, "nodes": st["nodes"], "tris": st["tris"], "by_cell": by_cell, "by_key": st["by_key"]}


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


func _element(el: String) -> void:
	var rep := {"frames": [], "ab_same_seed": -1.0, "ab_other_seed": -1.0}
	var cells := MotionGallery.build(el, 11)
	for mirror in [false, true]:
		for light in [false, true]:
			_set_bg(light)
			for t in _times:
				cells = MotionGallery.build(el, 11)  # estado limpo por quadro: os tempos são absolutos
				var st := _draw_gallery(cells, float(t), mirror)
				var name := "%s_%s_%s_%.2f.png" % [el, "espelhada" if mirror else "normal", "claro" if light else "escuro", float(t)]
				await _shot(_out + "/" + name)
				(rep["frames"] as Array).append({"file": name, "t": t, "ms": st["ms"], "nodes": st["nodes"], "tris": st["tris"], "by_cell_ms": st["by_cell"], "by_key": st["by_key"]})
	# A/B: mesma semente = imagens idênticas; semente diferente = imagens diferentes
	_set_bg(false)
	cells = MotionGallery.build(el, 11)
	_draw_gallery(cells, 0.5, false)
	var a := await _shot("")
	cells = MotionGallery.build(el, 11)
	_draw_gallery(cells, 0.5, false)
	var b := await _shot("")
	cells = MotionGallery.build(el, 12)
	_draw_gallery(cells, 0.5, false)
	var c := await _shot("")
	rep["ab_same_seed"] = _diff(a, b)
	rep["ab_other_seed"] = _diff(a, c)
	# Nada sobra depois do fim: no instante final todas as amostras deveriam ter sumido ou estar quase
	cells = MotionGallery.build(el, 11)
	var end_st := _draw_gallery(cells, 4.0, false)
	rep["nodes_at_4s"] = end_st["nodes"]
	_report[el] = rep
