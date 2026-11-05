extends SceneTree
## Motion Composer V1 — Etapa 6: MEDIÇÃO de desempenho (D-306). Não aprova nem reprova: não há orçamento definido (P-07).
## Rodar COM janela (o desenho precisa do renderizador):
##   godot --path . --script res://tests/motion_composer/medir_desempenho.gd -- --out=<arquivo.csv>
## Mede, por estudo (M01–M20 e a receita): amostras, custo de avaliar (mediana de 41 instantes de 0 a 3 s),
## e, por representação, o custo de enviar as amostras ao desenho (CPU) em TODOS os 41 instantes e o tempo de quadro no instante
## em que mais geometria é efetivamente desenhada. Só entram na estatística de desenho instantes com algo desenhado
## (contador da própria representação > 0); a coluna `instantes_com_desenho` mostra a cobertura.
## Caso extra RECEITA+M19: a receita da §6 mais a camada M19 (pior caso: rastro ativo no ciclo todo), montada AQUI, sem alterar o estudo.

const REPS := ["pontos", "fitas", "pontos+fitas", "fragmentos", "fumaça"]
const EXTRA := &"RECEITA+M19"
const EVAL_STEPS := 41
const FRAMES_PER_CASE := 20
const CAM := Vector3(0, 1.0, 5.0)

var _cat: MotionCatalog
var _out_path := ""
var _rows: PackedStringArray = []
var _set: MotionViewSet
var _case_idx := 0
var _cases: Array = []
var _frame_in_case := 0
var _case_start_usec := 0
var _peak_samples: Array[MotionSample] = []
var _pending: Array = []  # linha parcial à espera do tempo de quadro


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.substr(6)
	_cat = MotionCatalog.new()
	MotionBehaviors.register_all(_cat)
	print("Renderizador: ", ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		" | adaptador: ", RenderingServer.get_video_adapter_name(), " | Godot ", Engine.get_version_info()["string"])
	_rows.append("estudo,amostras_max,visiveis_no_pico,avaliar_ms_mediana,avaliar_ms_max,representacao,desenhado_no_pico,instantes_com_desenho,enviar_ms_mediana,enviar_ms_max,quadro_ms_medio")
	var ids: Array = MotionStudies.ids().duplicate()
	ids.append(EXTRA)
	for id in ids:
		for r in REPS.size():
			_cases.append([id, r])
	_set = MotionViewSet.new()
	root.add_child(_set)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = CAM
	cam.current = true
	process_frame.connect(_on_frame)


func _build(id: StringName) -> MotionComposition:
	if id != EXTRA:
		return MotionStudies.build(id)
	var c := MotionStudies.build(MotionStudies.RECIPE)
	var l := MotionLayer.new()
	l.id = &"rastro"
	l.behavior_id = &"M19"
	l.op = MotionTypes.Op.PERSIST
	l.params = {"duration": 0.8, "sample_interval": 0.05}
	c.add_layer(l)
	return c


func _eval(c: MotionComposition, t: float) -> MotionResult:
	var ctx := c.make_context(t)
	ctx.emitter_fn = func(tt: float) -> Transform3D: return MotionLabSession.emitter_transform(MotionLabSession.Emitter.STATIC, tt)
	return c.evaluate(_cat, ctx)


func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return float(b[b.size() / 2])


func _visible_count(samples: Array[MotionSample]) -> int:
	var n := 0
	for s in samples:
		if s.visible and s.opacity > 0.001 and s.width > 1e-5:
			n += 1
	return n


## Por estudo: [lista de amostras por instante, mediana ms, máx ms, máx de amostras].
var _eval_cache := {}


func _measure_eval(id: StringName) -> Array:
	if _eval_cache.has(id):
		return _eval_cache[id]
	var c := _build(id)
	var diags := c.validate(_cat)
	if not diags.is_empty():
		push_error("composição inválida %s: %s" % [id, diags[0]])
	_eval(c, 0.5)  # aquece
	var times: Array = []
	var per_t: Array = []
	var max_n := 0
	for i in EVAL_STEPS:
		var t := 3.0 * float(i) / float(EVAL_STEPS - 1)
		var t0 := Time.get_ticks_usec()
		var r := _eval(c, t)
		times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		per_t.append(r.samples)
		max_n = maxi(max_n, r.samples.size())
	var res := [per_t, _median(times), times.max(), max_n]
	_eval_cache[id] = res
	return res


func _drawn(rep: int) -> int:
	var n := 0
	if rep == 0 or rep == 2:
		n += _set.points.shown_count
	if rep == 1 or rep == 2:
		n += _set.ribbons.triangle_count
	if rep == 3:
		n += _set.fragments.shown_count
	if rep == 4:
		n += _set.smoke.shown_count
	return n


func _on_frame() -> void:
	if _case_idx >= _cases.size():
		_finish()
		return
	var cs: Array = _cases[_case_idx]
	var id: StringName = cs[0]
	var rep: int = cs[1]
	if _frame_in_case == 0:
		var m: Array = _measure_eval(id)
		var per_t: Array = m[0]
		_set.set_representation(rep)
		_set.visible = true
		var times: Array = []
		var drawn_t := 0
		var peak_drawn := -1
		var peak_i := 0
		for i in per_t.size():
			var smp: Array[MotionSample] = per_t[i]
			var reps: Array = []
			for k in 3:
				var t0 := Time.get_ticks_usec()
				_set.draw_samples(smp, CAM)
				reps.append(float(Time.get_ticks_usec() - t0) / 1000.0)
			var d := _drawn(rep)
			if d > 0:
				drawn_t += 1
				times.append(_median(reps))
			if d > peak_drawn:
				peak_drawn = d
				peak_i = i
		_peak_samples = per_t[peak_i]
		_pending = [id, m[3], _visible_count(_peak_samples), m[1], m[2], REPS[rep], maxi(peak_drawn, 0), drawn_t,
			_median(times), (times.max() if not times.is_empty() else 0.0)]
		_case_start_usec = Time.get_ticks_usec()
		_frame_in_case = 1
		return
	_set.draw_samples(_peak_samples, CAM)
	_frame_in_case += 1
	if _frame_in_case > FRAMES_PER_CASE:
		var frame_ms := float(Time.get_ticks_usec() - _case_start_usec) / 1000.0 / float(FRAMES_PER_CASE)
		var p := _pending
		_rows.append("%s,%d,%d,%.3f,%.3f,%s,%d,%d,%.3f,%.3f,%.2f" % [p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], frame_ms])
		_case_idx += 1
		_frame_in_case = 0


func _finish() -> void:
	var txt := "
".join(_rows)
	print(txt)
	if _out_path != "":
		var f := FileAccess.open(_out_path, FileAccess.WRITE)
		if f:
			f.store_string(txt + "
")
			f.close()
	quit(0)
