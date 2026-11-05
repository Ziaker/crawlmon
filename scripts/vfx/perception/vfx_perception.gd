class_name VfxPerception
extends RefCounted
## D-274 (item 6): perception tools for judging a visual effect without a human watching.
##
## Renders the SAME effect, from the same seed and the same fixed time step, on three backdrops:
##   beauty  neutral stage with floor and two stand-in characters (what a player would roughly see);
##   dark    black backdrop, no stage (shows glow / additive effects);
##   light   light backdrop, no stage (shows smoke / dark effects).
## From dark + light it builds a SILHOUETTE: white = visible on both, cyan = only visible on the dark
## backdrop, orange = only visible on the light one. It then measures coverage, bounding box, peak
## brightness, draw cost and node counts, warns about the usual problems, and writes contact sheets
## (rows = beauty / closeup on the effect / silhouette, columns = times) plus a JSON of the numbers.
##
## The tool only OBSERVES an effect: it never changes damage, range, duration or any combat rule. The
## effect is built by a factory Callable(ctx) so ANY effect works with ANY layout (D-235): the layout
## says where the attacker and target stand (left/right, near/far camera), the factory derives everything
## from ctx (origin, destination, direction, target size), never from a character or a fixed side.
##
## Needs a WINDOWED run with a fixed step (godot --path . --fixed-fps 30 --script ...): headless draws nothing.

const LAYOUTS := ["side_lr", "side_rl", "near_to_far", "far_to_near"]
const PASSES := ["beauty", "dark", "light"]
const ANALYSIS_SIZE := Vector2i(640, 360)
const THUMB_SIZE := Vector2i(320, 180)
const VISIBLE_THRESHOLD := 0.06  ## Per-channel difference from the backdrop that counts as "visible".
const WARN_EMPTY := 0.0005  ## Coverage below this: the effect is practically invisible.
const WARN_HIDES_FORM := 0.45  ## Coverage above this: so much of the frame that forms are lost.
const WARN_TRANSPARENT_NODES := 24  ## Many overlapping transparent nodes hide the shape and cost fill rate.

const DARK_BG := Color(0.0, 0.0, 0.0)
const LIGHT_BG := Color(0.88, 0.88, 0.9)
const STAGE_BG := Color(0.17, 0.19, 0.24)


## spec: {
##   out_dir: String, times: Array[float], fps: int = 30, seed: int = 1,
##   variants: [{name: String, factory: Callable(ctx), layout: String = "side_lr",
##               attacker_height: float = 1.4, target_height: float = 1.4, target_radius: float = 0.4}],
##   check_repeat: bool = false }
## Returns {ok, variants: {name: {times: [metrics...], warnings: [...], repeat_mismatch: float}}, sheet, json}.
static func run(tree: SceneTree, spec: Dictionary) -> Dictionary:
	var out_dir: String = spec["out_dir"]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var fps: int = spec.get("fps", 30)
	var times: Array = spec["times"]
	var rig := _build_rig(tree)
	var results := {}
	var sheet_rows: Array[Image] = []
	for v in spec["variants"]:
		var vname: String = v["name"]
		var frames := {}  # pass name -> Array of Images (one per time)
		var render_info := {}
		for p in PASSES:
			var got: Dictionary = await _render_pass(tree, rig, spec, v, p, times, fps)
			frames[p] = got["images"]
			if p == "beauty":
				render_info = got["info"]
		var analysed := _analyse(frames, times, render_info)
		var entry := {"times": analysed["metrics"], "warnings": analysed["warnings"], "layout": v.get("layout", "side_lr")}
		if spec.get("check_repeat", false):
			var again: Dictionary = await _render_pass(tree, rig, spec, v, "dark", times, fps)
			entry["repeat_mismatch"] = _repeat_mismatch(frames["dark"], again["images"])
		results[vname] = entry
		var closeup := _closeup_images(frames["beauty"], analysed["metrics"])
		sheet_rows.append(_row_image(frames["beauty"], times.size()))
		sheet_rows.append(_row_image(closeup, times.size()))
		sheet_rows.append(_row_image(analysed["silhouettes"], times.size()))
		_save_png(_row_image(closeup, times.size()), "%s/%s_closeup.png" % [out_dir, vname])
		_save_png(_row_image(frames["beauty"], times.size()), "%s/%s_beauty.png" % [out_dir, vname])
		_save_png(_row_image(analysed["silhouettes"], times.size()), "%s/%s_silhouette.png" % [out_dir, vname])
	var sheet := _stack(sheet_rows)
	var sheet_path := "%s/contact_sheet.png" % out_dir
	_save_png(sheet, sheet_path)
	var json_path := "%s/perception.json" % out_dir
	var f := FileAccess.open(json_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"times": times, "fps": fps, "variants": results}, "  "))
	f.close()
	rig["scene"].queue_free()
	return {"ok": true, "variants": results, "sheet": sheet_path, "json": json_path}


# --- Rig ----------------------------------------------------------------------

static func _build_rig(tree: SceneTree) -> Dictionary:
	var scene := Node3D.new()
	tree.root.add_child(scene)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = STAGE_BG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.8)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.current = true
	scene.add_child(cam)
	cam.look_at_from_position(Vector3(0, 2.6, 10.5), Vector3(0, 1.0, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	scene.add_child(sun)
	var stage := Node3D.new()  # floor + stand-ins, visible only in the beauty pass
	scene.add_child(stage)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.32, 0.36)
	floor_mesh.material_override = floor_mat
	stage.add_child(floor_mesh)
	var attacker := _stand_in(Color(0.45, 0.62, 0.9))
	var target := _stand_in(Color(0.95, 0.6, 0.35))
	stage.add_child(attacker)
	stage.add_child(target)
	var fx_root := Node3D.new()
	scene.add_child(fx_root)
	return {"scene": scene, "env": env, "cam": cam, "stage": stage, "attacker": attacker, "target": target, "fx_root": fx_root}


static func _stand_in(color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = CapsuleMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	return mi


static func _place(rig: Dictionary, v: Dictionary) -> Dictionary:
	var layout: String = v.get("layout", "side_lr")
	var ah: float = v.get("attacker_height", 1.4)
	var th: float = v.get("target_height", 1.4)
	var tr: float = v.get("target_radius", 0.4)
	var a_pos := Vector3(-4.2, 0, 0)
	var t_pos := Vector3(4.2, 0, 0)
	match layout:
		"side_rl":
			a_pos = Vector3(4.2, 0, 0)
			t_pos = Vector3(-4.2, 0, 0)
		"near_to_far":
			a_pos = Vector3(0, 0, 3.5)
			t_pos = Vector3(0, 0, -3.5)
		"far_to_near":
			a_pos = Vector3(0, 0, -3.5)
			t_pos = Vector3(0, 0, 3.5)
	_size_stand_in(rig["attacker"], a_pos, ah, 0.4)
	_size_stand_in(rig["target"], t_pos, th, tr)
	var origin := a_pos + Vector3(0, ah * 0.6, 0)
	var dest := t_pos + Vector3(0, th * 0.5, 0)
	return {
		"attacker": rig["attacker"], "target": rig["target"],
		"origin": origin, "dest": dest, "dir": (dest - origin).normalized(),
		"attacker_height": ah, "target_height": th, "target_radius": tr, "layout": layout,
	}


static func _size_stand_in(mi: MeshInstance3D, pos: Vector3, height: float, radius: float) -> void:
	var m := mi.mesh as CapsuleMesh
	m.height = maxf(height, radius * 2.0 + 0.01)
	m.radius = radius
	mi.position = pos + Vector3(0, height * 0.5, 0)


# --- Rendering ------------------------------------------------------------------

static func _render_pass(tree: SceneTree, rig: Dictionary, spec: Dictionary, v: Dictionary, pass_name: String, times: Array, fps: int) -> Dictionary:
	var env: Environment = rig["env"]
	var fx_root: Node3D = rig["fx_root"]
	for c in fx_root.get_children():
		c.free()
	(rig["stage"] as Node3D).visible = pass_name == "beauty"
	env.background_color = {"beauty": STAGE_BG, "dark": DARK_BG, "light": LIGHT_BG}[pass_name]
	var ctx := _place(rig, v)
	ctx["parent"] = fx_root
	ctx["seed"] = spec.get("seed", 1)
	seed(int(ctx["seed"]))
	await tree.process_frame  # lets the stand-ins and backdrop settle before the effect is born
	(v["factory"] as Callable).call(ctx)
	var targets := {}
	for t in times:
		targets[maxi(1, int(round(float(t) * fps)))] = float(t)
	var last: int = targets.keys().max()
	var images: Array[Image] = []
	var info := {}
	for frame in range(1, last + 1):
		await tree.process_frame
		if targets.has(frame):
			await RenderingServer.frame_post_draw
			var vp := tree.root.get_viewport()
			images.append(vp.get_texture().get_image())
			if pass_name == "beauty":
				var rid := vp.get_viewport_rid()
				info[targets[frame]] = {
					"primitives": RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
					"draw_calls": RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
					"nodes": _count_nodes(fx_root),
				}
	return {"images": images, "info": info}


static func _count_nodes(root: Node) -> Dictionary:
	var meshes := 0
	var particles := 0
	var transparent := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and (n as MeshInstance3D).visible:
			meshes += 1
			var mat: Material = (n as MeshInstance3D).material_override
			if mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				transparent += 1
			elif mat is ShaderMaterial:
				transparent += 1  # Effect shaders are almost always blended.
		elif n is GPUParticles3D or n is CPUParticles3D:
			if n.get("emitting") == true:
				particles += 1
				transparent += 1
	return {"meshes": meshes, "particles": particles, "transparent": transparent}


# --- Analysis -------------------------------------------------------------------

static func _small(img: Image) -> Image:
	var c := img.duplicate() as Image
	c.convert(Image.FORMAT_RGB8)
	c.resize(ANALYSIS_SIZE.x, ANALYSIS_SIZE.y, Image.INTERPOLATE_BILINEAR)
	return c


static func _corner_bg(img: Image) -> Color:
	var w := img.get_width()
	var h := img.get_height()
	var acc := Color(0, 0, 0)
	for p in [Vector2i(1, 1), Vector2i(w - 2, 1), Vector2i(1, h - 2), Vector2i(w - 2, h - 2)]:
		acc += img.get_pixelv(p)
	return acc / 4.0


## Per time: coverage / bbox / brightness / cost, and a coloured silhouette image.
static func _analyse(frames: Dictionary, times: Array, info: Dictionary) -> Dictionary:
	var metrics: Array = []
	var warnings: Array = []
	var silhouettes: Array[Image] = []
	for i in times.size():
		var d := _small(frames["dark"][i])
		var l := _small(frames["light"][i])
		var bg_d := _corner_bg(d)
		var bg_l := _corner_bg(l)
		var dd := d.get_data()
		var ld := l.get_data()
		var w := ANALYSIS_SIZE.x
		var h := ANALYSIS_SIZE.y
		var sil := PackedByteArray()
		sil.resize(w * h * 3)
		var thr := int(VISIBLE_THRESHOLD * 255.0)
		var bd := [int(bg_d.r * 255.0), int(bg_d.g * 255.0), int(bg_d.b * 255.0)]
		var bl := [int(bg_l.r * 255.0), int(bg_l.g * 255.0), int(bg_l.b * 255.0)]
		var count := 0
		var min_x := w
		var min_y := h
		var max_x := -1
		var max_y := -1
		var peak := 0
		var luma_sum := 0
		for y in h:
			for x in w:
				var k := (y * w + x) * 3
				var on_dark := absi(dd[k] - bd[0]) > thr or absi(dd[k + 1] - bd[1]) > thr or absi(dd[k + 2] - bd[2]) > thr
				var on_light := absi(ld[k] - bl[0]) > thr or absi(ld[k + 1] - bl[1]) > thr or absi(ld[k + 2] - bl[2]) > thr
				if on_dark or on_light:
					count += 1
					min_x = mini(min_x, x)
					max_x = maxi(max_x, x)
					min_y = mini(min_y, y)
					max_y = maxi(max_y, y)
					if on_dark:
						var luma := (dd[k] * 3 + dd[k + 1] * 6 + dd[k + 2]) / 10
						peak = maxi(peak, luma)
						luma_sum += luma
					if on_dark and on_light:
						sil[k] = 255
						sil[k + 1] = 255
						sil[k + 2] = 255
					elif on_dark:
						sil[k] = 40
						sil[k + 1] = 220
						sil[k + 2] = 230
					else:
						sil[k] = 245
						sil[k + 1] = 150
						sil[k + 2] = 30
		var total := float(w * h)
		var cov := float(count) / total
		var m := {
			"t": times[i], "coverage": snappedf(cov, 0.00001),
			"bbox": [] if count == 0 else [snappedf(min_x / float(w), 0.001), snappedf(min_y / float(h), 0.001), snappedf((max_x + 1) / float(w), 0.001), snappedf((max_y + 1) / float(h), 0.001)],
			"peak_luma": peak / 255.0, "mean_luma": 0.0 if count == 0 else snappedf(float(luma_sum) / float(count) / 255.0, 0.001),
		}
		var inf: Dictionary = info.get(float(times[i]), {})
		m["primitives"] = inf.get("primitives", 0)
		m["draw_calls"] = inf.get("draw_calls", 0)
		m["nodes"] = inf.get("nodes", {})
		metrics.append(m)
		var nodes: Dictionary = m["nodes"]
		if cov > WARN_HIDES_FORM:
			warnings.append("t=%s: cobre %.0f%% do quadro; a forma se perde" % [times[i], cov * 100.0])
		if int(nodes.get("transparent", 0)) > WARN_TRANSPARENT_NODES:
			warnings.append("t=%s: %d nós transparentes sobrepostos (custo de preenchimento e forma escondida)" % [times[i], nodes["transparent"]])
		silhouettes.append(Image.create_from_data(w, h, false, Image.FORMAT_RGB8, sil))
	var any_visible := false
	for m in metrics:
		any_visible = any_visible or float(m["coverage"]) >= WARN_EMPTY
	if not any_visible:
		warnings.append("o efeito não aparece em nenhum dos instantes medidos")
	elif float(metrics[metrics.size() - 1]["coverage"]) >= WARN_EMPTY:
		warnings.append("no último instante (t=%s) o efeito ainda está visível: a dissipação não termina dentro da janela medida" % times[times.size() - 1])
	return {"metrics": metrics, "warnings": warnings, "silhouettes": silhouettes}


## Crops each beauty frame to the union of the effect's boxes (padded, 16:9), so small effects can be judged.
static func _closeup_images(beauty: Array, metrics: Array) -> Array[Image]:
	var x0 := 1.0
	var y0 := 1.0
	var x1 := 0.0
	var y1 := 0.0
	for m in metrics:
		var b: Array = m["bbox"]
		if b.is_empty():
			continue
		x0 = minf(x0, b[0])
		y0 = minf(y0, b[1])
		x1 = maxf(x1, b[2])
		y1 = maxf(y1, b[3])
	var out: Array[Image] = []
	for img in beauty:
		var im: Image = img
		if x1 <= x0 or y1 <= y0:
			out.append(im)
			continue
		var w := float(im.get_width())
		var h := float(im.get_height())
		var cx := (x0 + x1) * 0.5 * w
		var cy := (y0 + y1) * 0.5 * h
		var bw := maxf((x1 - x0) * w * 1.3, 64.0)
		var bh := maxf((y1 - y0) * h * 1.3, 36.0)
		var aspect := w / h
		if bw / bh < aspect:
			bw = bh * aspect
		else:
			bh = bw / aspect
		bw = minf(bw, w)
		bh = minf(bh, h)
		var rx := clampf(cx - bw * 0.5, 0.0, w - bw)
		var ry := clampf(cy - bh * 0.5, 0.0, h - bh)
		out.append(im.get_region(Rect2i(int(rx), int(ry), int(bw), int(bh))))
	return out


## Fraction of silhouette pixels that differ between two renders of the same effect (0 = identical).
static func _repeat_mismatch(a: Array, b: Array) -> float:
	var diff := 0
	var seen := 0
	for i in a.size():
		var da := _small(a[i]).get_data()
		var db := _small(b[i]).get_data()
		for k in range(0, da.size(), 3):
			var va := da[k] > 16 or da[k + 1] > 16 or da[k + 2] > 16
			var vb := db[k] > 16 or db[k + 1] > 16 or db[k + 2] > 16
			if va or vb:
				seen += 1
				if va != vb:
					diff += 1
	return 0.0 if seen == 0 else snappedf(float(diff) / float(seen), 0.0001)


# --- Sheets ---------------------------------------------------------------------

static func _row_image(images: Array, count: int) -> Image:
	var row := Image.create(THUMB_SIZE.x * count, THUMB_SIZE.y, false, Image.FORMAT_RGB8)
	for i in count:
		var t := (images[i] as Image).duplicate() as Image
		t.convert(Image.FORMAT_RGB8)
		t.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_BILINEAR)
		row.blit_rect(t, Rect2i(Vector2i.ZERO, THUMB_SIZE), Vector2i(i * THUMB_SIZE.x, 0))
		# A thin marker between tiles so the columns are easy to count.
		for y in THUMB_SIZE.y:
			row.set_pixel(i * THUMB_SIZE.x, y, Color(0.8, 0.2, 0.5))
	return row


static func _stack(rows: Array[Image]) -> Image:
	var w := 0
	var h := 0
	for r in rows:
		w = maxi(w, r.get_width())
		h += r.get_height() + 4
	var out := Image.create(w, h, false, Image.FORMAT_RGB8)
	out.fill(Color(0.5, 0.1, 0.1))
	var y := 0
	for r in rows:
		out.blit_rect(r, Rect2i(Vector2i.ZERO, r.get_size()), Vector2i(0, y))
		y += r.get_height() + 4
	return out


static func _save_png(img: Image, path: String) -> void:
	img.save_png(path)
