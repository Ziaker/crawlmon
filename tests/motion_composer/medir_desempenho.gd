extends SceneTree
## Motion Composer V1 — Etapa 6: MEDIÇÃO de desempenho (D-306). Não aprova nem reprova: não há orçamento definido (P-07).
## Rodar COM janela (o desenho precisa do renderizador):
##   godot --path . --script res://tests/motion_composer/medir_desempenho.gd -- --out=<arquivo.csv>
## Mede, por estudo (M01–M20 e a receita): amostras, custo de avaliar (mediana de 41 instantes de 0 a 3 s),
## e, por representação, o custo de enviar as amostras ao desenho (CPU) e o tempo de quadro com o estudo em cena.

const REPS := ["pontos", "fitas", "pontos+fitas", "fragmentos", "fumaça"]
const EVAL_STEPS := 41
const FRAMES_PER_CASE := 20

var _cat: MotionCatalog
var _out_path := ""
var _rows: PackedStringArray = []
var _set: MotionViewSet
var _case_idx := 0
var _cases: Array = []
var _frame_in_case := 0
var _case_start_usec := 0
var _cur_comp: MotionComposition
var _cur_samples: Array[MotionSample] = []
var _cur_draw_ms := 0.0
var _started := false


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.substr(6)
	_cat = MotionCatalog.new()
	MotionBehaviors.register_all(_cat)
	print("Renderizador: ", ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		" | adaptador: ", RenderingServer.get_video_adapter_name(), " | Godot ", Engine.get_version_info()["string"])
	_rows.append("estudo,amostras_max,avaliar_ms_mediana,avaliar_ms_max,representacao,enviar_ms_mediana,quadro_ms_medio")
	for id in MotionStudies.ids():
		for r in REPS.size():
			_cases.append([id, r])
	_set = MotionViewSet.new()
	root.add_child(_set)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 1.0, 5.0)
	cam.current = true
	process_frame.connect(_on_frame)


func _eval(c: MotionComposition, t: float) -> MotionResult:
	var ctx := c.make_context(t)
	ctx.emitter_fn = func(tt: float) -> Transform3D: return MotionLabSession.emitter_transform(MotionLabSession.Emitter.STATIC, tt)
	return c.evaluate(_cat, ctx)


func _median(a: Array) -> float:
	var b := a.duplicate()
	b.sort()
	return float(b[b.size() / 2])


var _eval_cache := {}  # id -> [max_samples, med_ms, max_ms, samples_at_peak]


func _measure_eval(id: StringName) -> Array:
	if _eval_cache.has(id):
		return _eval_cache[id]
	var c := MotionStudies.build(id)
	_eval(c, 0.5)  # aquece
	var times: Array = []
	var max_n := 0
	var peak: Array[MotionSample] = []
	for i in EVAL_STEPS:
		var t := 3.0 * float(i) / float(EVAL_STEPS - 1)
		var t0 := Time.get_ticks_usec()
		var r := _eval(c, t)
		times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		if r.samples.size() > max_n:
			max_n = r.samples.size()
			peak = r.samples
	var res := [max_n, _median(times), times.max(), peak]
	_eval_cache[id] = res
	return res


func _on_frame() -> void:
	if _case_idx >= _cases.size():
		_finish()
		return
	var cs: Array = _cases[_case_idx]
	var id: StringName = cs[0]
	var rep: int = cs[1]
	if _frame_in_case == 0:
		var m: Array = _measure_eval(id)
		_cur_samples = m[3]
		_set.set_representation(rep)
		_set.visible = true
		# custo de enviar as amostras ao desenho (CPU), mediana de 9 repetições
		var times: Array = []
		for k in 9:
			var t0 := Time.get_ticks_usec()
			_set.draw_samples(_cur_samples, Vector3(0, 1.0, 5.0))
			times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		_cur_draw_ms = _median(times)
		_case_start_usec = Time.get_ticks_usec()
		_frame_in_case = 1
		return
	_set.draw_samples(_cur_samples, Vector3(0, 1.0, 5.0))
	_frame_in_case += 1
	if _frame_in_case > FRAMES_PER_CASE:
		var frame_ms := float(Time.get_ticks_usec() - _case_start_usec) / 1000.0 / float(FRAMES_PER_CASE)
		var m: Array = _eval_cache[id]
		_rows.append("%s,%d,%.3f,%.3f,%s,%.3f,%.2f" % [id, m[0], m[1], m[2], REPS[rep], _cur_draw_ms, frame_ms])
		_case_idx += 1
		_frame_in_case = 0


func _finish() -> void:
	var txt := "\n".join(_rows)
	print(txt)
	if _out_path != "":
		var f := FileAccess.open(_out_path, FileAccess.WRITE)
		if f:
			f.store_string(txt + "\n")
			f.close()
	quit(0)
