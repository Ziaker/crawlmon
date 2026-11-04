class_name MotionLab
extends Node3D
## Laboratório visual do Motion Composer (Etapa 5, fatia 1, D-305): cena 3D com câmera e eixos de
## referência, catálogo dos 20 comportamentos, camadas ordenadas (D-043), parâmetros, linha do tempo,
## toggle de edição (D-042), presets (D-045) e inspeção. Independente do combate. Disposição e aparência
## da interface são propostas do agente (P-08 em aberto).
##
## Rodar:  godot --path . res://scenes/motion_lab/motion_lab.tscn
## Captura: ... -- --capture=C:/pasta/saida.png --t=1.2 --frames=6 [--preset=nome]

const PANEL_WIDTH := 372.0

var session: MotionLabSession = MotionLabSession.new()
var points: MotionPointsView
var ribbons: MotionRibbonsView
var fragments: MotionFragmentsView
var smoke: MotionSmokeView
## 0 = pontos, 1 = fitas, 2 = pontos + fitas, 3 = fragmentos, 4 = fumaça/billboards (a troca conserva a composição).
var representation: int = 0

var _cam: Camera3D
var _yaw: float = 0.6
var _pitch: float = 0.35
var _dist: float = 3.2
var _target: Vector3 = Vector3(0.0, 0.0, 0.5)

var _dirty: bool = true
var _selected: StringName = &""
var _last_time: float = -1.0
var _capture_path: String = ""
var _capture_frames: int = 6

# widgets
var _stats: Label
var _diag: Label
var _time_slider: HSlider
var _time_label: Label
var _play_btn: Button
var _loop_check: CheckBox
var _speed_opt: OptionButton
var _edit_check: CheckButton
var _emitter_opt: OptionButton
var _filter: LineEdit
var _catalog_list: ItemList
var _catalog_desc: Label
var _add_op: OptionButton
var _layers_list: ItemList
var _solo_btn: Button
var _params_box: VBoxContainer
var _preset_name: LineEdit
var _preset_opt: OptionButton
var _preset_status: Label
var _size_slider: HSlider
var _width_slider: HSlider
var _rep_opt: OptionButton
var _catalog_ids: Array[StringName] = []


func _ready() -> void:
	_parse_args()
	_build_world()
	_build_ui()
	if _arg_text("--demo=") == "receita":
		_recipe_composition()
	elif _arg_text("--demo=") == "estilhacos":
		_shards_composition()
	elif _arg_text("--demo=") == "fumaca":
		_smoke_composition()
	elif not _load_startup_preset():
		_default_composition()
	_refresh_layers()
	_refresh_presets()
	set_representation(representation)
	session.clock.playing = _capture_path == ""
	if _capture_path != "":
		session.clock.seek(_arg_float("--t=", 1.2))
	_dirty = true


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			_capture_path = a.substr(10)
		elif a.begins_with("--frames="):
			_capture_frames = int(a.substr(9))
		elif a.begins_with("--rep="):
			representation = {"pontos": 0, "fitas": 1, "ambos": 2, "fragmentos": 3, "fumaca": 4}.get(a.substr(6), 0)


func _arg_text(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""


func _arg_float(prefix: String, fallback: float) -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return float(a.substr(prefix.length()))
	return fallback


func _load_startup_preset() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--preset="):
			var r := MotionPresets.load_preset(a.substr(9), session.catalog)
			if r["composition"] != null:
				session.composition = r["composition"]
				session.clock.duration = session.composition.duration
				return true
	return false


func _default_composition() -> void:
	var c := session.composition
	c.sample_count = 64
	var helix := MotionLayer.new()
	helix.id = &"helice"
	helix.behavior_id = &"M01"
	helix.op = MotionTypes.Op.REPLACE
	helix.params = {"radius": 0.25, "pitch": 0.5, "turns": 3.0, "spin_deg_s": 120.0}
	c.add_layer(helix)
	var trail := MotionLayer.new()
	trail.id = &"rastro"
	trail.behavior_id = &"M19"
	trail.op = MotionTypes.Op.PERSIST
	trail.params = {"duration": 0.6}
	c.add_layer(trail)
	_selected = &"helice"


## Demonstração para Fumaça: uma cabeça pequena (hélice curta) e, atrás dela, o rastro M19 preso ao MUNDO
## (world_space) com o emissor andando em linha: as baforadas ficam para trás, crescem (largura do rastro)
## e se dissipam, com um tremor de turbulência (M07). Não é um Move.
func _smoke_composition() -> void:
	var c := session.composition
	c.sample_count = 6
	c.duration = 3.0
	c.seed = 31
	var specs := [
		[&"cabeca", &"M01", MotionTypes.Op.REPLACE, {"radius": 0.06, "pitch": 0.05, "turns": 1.0, "spin_deg_s": 240.0}],
		[&"fumaca", &"M19", MotionTypes.Op.PERSIST, {"duration": 1.0, "sample_interval": 0.05, "world_space": true, "fade_curve": 1.2, "width_start": 1.0, "width_end": 1.0}],
		[&"tremor", &"M07", MotionTypes.Op.OFFSET, {"intensity": 0.04, "scale": 0.6, "time_hz": 1.0}],
	]
	for sp in specs:
		var l := MotionLayer.new()
		l.id = sp[0]
		l.behavior_id = sp[1]
		l.op = sp[2]
		l.params = sp[3]
		c.add_layer(l)
	session.emitter_mode = MotionLabSession.Emitter.LINE
	_emitter_opt.select(MotionLabSession.Emitter.LINE)
	_selected = &"fumaca"
	_target = Vector3(-0.8, 0.3, 0.0)
	_dist = 3.6
	_yaw = 0.35
	_pitch = 0.1
	_apply_camera()


## Demonstração para Fragmentos: uma hélice que nasce, explode para fora e se dissolve (ciclo de 2,4 s).
## Camadas reais da biblioteca (M01, M17, M16 duas vezes: deslocamento e dissipação); não é um Move.
func _shards_composition() -> void:
	var c := session.composition
	c.sample_count = 128
	c.duration = 2.4
	c.seed = 77
	session.clock.duration = 2.4
	var burst := {"radial": 1.0, "origin": Vector3(0, 0, 0.75), "cone_deg": 70.0, "distance": 1.1, "t_start": 0.8, "t_duration": 0.9, "curve": 2.0}
	var specs := [
		[&"helice", &"M01", MotionTypes.Op.REPLACE, {"radius": 0.3, "pitch": 0.5, "turns": 3.0, "spin_deg_s": 90.0}],
		[&"nasce", &"M17", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.6, "width": 0.15, "affect_opacity": true, "affect_width": false, "affect_visibility": false}],
		[&"explosao", &"M16", MotionTypes.Op.OFFSET, burst],
		[&"dissipa", &"M16", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"t_start": 0.8, "t_duration": 0.9, "curve": 0.5, "dissipate": 1.0}],
	]
	for sp in specs:
		var l := MotionLayer.new()
		l.id = sp[0]
		l.behavior_id = sp[1]
		l.op = sp[2]
		l.params = sp[3]
		c.add_layer(l)
	smoke.puff_size = 0.22
	smoke.puff_growth = 1.5
	smoke.puff_rise = 0.2
	smoke.puff_spread = 0.0
	_selected = &"explosao"
	_target = Vector3(0.0, 0.0, 0.75)
	_dist = 3.0
	_apply_camera()


## Receita de teste da §6 (sem M19, que é a Etapa 4): compressão → crescimento → zigue-zague + torção →
## bifurcação em 3 → serpentina + turbulência → recombinação → onda radial + explosão → dissolução.
## Não é um Move do Crawlmon; janelas em segundos por defasagem de camada (ciclo de 3 s).
func _recipe_composition() -> void:
	var c := session.composition
	c.sample_count = 96
	c.seed = 2026
	var specs := [
		[&"compressao", &"M11", MotionTypes.Op.DEFORM, {"strength": 0.8, "center": 0.5, "extent": 0.5, "softness": 0.2}, 0.0],
		[&"crescimento", &"M17", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.45, "width": 0.1}, 0.0],
		[&"zigzag", &"M02", MotionTypes.Op.OFFSET, {"amplitude": 0.06, "frequency": 6.0}, 0.45],
		[&"torcao", &"M08", MotionTypes.Op.DEFORM, {"amount_deg": 120.0}, 0.45],
		[&"bifurcacao", &"M14", MotionTypes.Op.BRANCH, {"branches": 3, "split_u": 0.3, "angle_deg": 35.0, "distance": 0.4}, 1.05],
		[&"serpentina", &"M03", MotionTypes.Op.OFFSET, {"amplitude": 0.03, "wavelength": 0.3}, 1.5],
		[&"turbulencia", &"M07", MotionTypes.Op.OFFSET, {"intensity": 0.02}, 1.5],
		[&"recombinacao", &"M15", MotionTypes.Op.MERGE, {"merge_start": 0.6, "merge_end": 0.9, "t_duration": 0.3}, 1.95],
		[&"onda", &"M13", MotionTypes.Op.OFFSET, {"speed": 1.5, "amplitude": 0.05}, 2.25],
		[&"explosao", &"M16", MotionTypes.Op.OFFSET, {"distance": 0.3, "t_duration": 0.3}, 2.25],
		[&"dissolucao", &"M18", MotionTypes.Op.MULTIPLY_ATTRIBUTE, {"t_duration": 0.45}, 2.55],
	]
	for sp in specs:
		var l := MotionLayer.new()
		l.id = sp[0]
		l.behavior_id = sp[1]
		l.op = sp[2]
		l.params = sp[3]
		l.time_offset = sp[4]
		c.add_layer(l)
	_selected = &"bifurcacao"
	_target = Vector3(0.0, 0.0, 0.5)
	_dist = 2.6
	_apply_camera()


# ------------------------------------------------------------------ mundo 3D
func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.10)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.current = true
	add_child(_cam)
	_apply_camera()

	points = MotionPointsView.new()
	add_child(points)
	ribbons = MotionRibbonsView.new()
	add_child(ribbons)
	fragments = MotionFragmentsView.new()
	add_child(fragments)
	smoke = MotionSmokeView.new()
	add_child(smoke)

	add_child(_make_lines(_grid_lines(), true))
	add_child(_make_lines(_axis_lines(), true))


func _grid_lines() -> Array:
	var out := []
	var col := Color(0.22, 0.25, 0.30)
	var half := 2.0
	var step := 0.25
	var i := -half
	while i <= half + 0.001:
		out.append([Vector3(i, -0.001, -half), Vector3(i, -0.001, half), col])
		out.append([Vector3(-half, -0.001, i), Vector3(half, -0.001, i), col])
		i += step
	return out


func _axis_lines() -> Array:
	# X vermelho, Y verde, Z azul (+Z = eixo longitudinal dos movimentos)
	return [
		[Vector3.ZERO, Vector3(1, 0, 0), Color(0.95, 0.30, 0.30)],
		[Vector3.ZERO, Vector3(0, 1, 0), Color(0.35, 0.90, 0.40)],
		[Vector3.ZERO, Vector3(0, 0, 1), Color(0.35, 0.55, 1.00)],
	]


func _make_lines(lines: Array, unshaded: bool) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for l in lines:
		im.surface_set_color(l[2])
		im.surface_add_vertex(l[0])
		im.surface_set_color(l[2])
		im.surface_add_vertex(l[1])
	im.surface_end()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.vertex_color_use_as_albedo = true
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	return mi


func _apply_camera() -> void:
	var dir := Vector3(cos(_pitch) * sin(_yaw), sin(_pitch), cos(_pitch) * cos(_yaw))
	_cam.position = _target + dir * _dist
	_cam.look_at(_target, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		_yaw -= event.relative.x * 0.008
		_pitch = clampf(_pitch + event.relative.y * 0.008, -1.4, 1.4)
		_apply_camera()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		var right := _cam.global_transform.basis.x
		var up := _cam.global_transform.basis.y
		_target += (-right * event.relative.x + up * event.relative.y) * 0.003 * _dist
		_apply_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(0.5, _dist * 0.9)
			_apply_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(20.0, _dist * 1.1)
			_apply_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				session.clock.toggle()
			KEY_R:
				session.clock.restart()
				_dirty = true
			KEY_PERIOD:
				session.clock.step(1)
			KEY_COMMA:
				session.clock.step(-1)


# ------------------------------------------------------------------ interface
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var left := _make_panel(layer, true)
	var right := _make_panel(layer, false)
	var box := left

	box.add_child(_title("Motion Composer — laboratório"))
	_stats = _small("")
	box.add_child(_stats)
	_diag = _small("")
	_diag.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	box.add_child(_diag)

	# --- linha do tempo
	box.add_child(_section("Linha do tempo (relógio local)"))
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(_btn("Reiniciar", func() -> void: session.clock.restart(); _dirty = true))
	row.add_child(_btn("−1 quadro", func() -> void: session.clock.step(-1)))
	_play_btn = _btn("Reproduzir", func() -> void: session.clock.toggle())
	row.add_child(_play_btn)
	row.add_child(_btn("+1 quadro", func() -> void: session.clock.step(1)))
	_time_slider = HSlider.new()
	_time_slider.min_value = 0.0
	_time_slider.max_value = session.clock.duration
	_time_slider.step = 1.0 / 60.0
	_time_slider.value_changed.connect(func(v: float) -> void:
		session.clock.pause()
		session.clock.seek(v)
		_dirty = true)
	box.add_child(_time_slider)
	_time_label = _small("")
	box.add_child(_time_label)
	var row2 := HBoxContainer.new()
	box.add_child(row2)
	_loop_check = CheckBox.new()
	_loop_check.text = "Laço"
	_loop_check.button_pressed = true
	_loop_check.toggled.connect(func(on: bool) -> void: session.clock.loop = on; _dirty = true)
	row2.add_child(_loop_check)
	row2.add_child(_small(" Vel. "))
	_speed_opt = OptionButton.new()
	for s in MotionClock.SPEEDS:
		_speed_opt.add_item("%sx" % str(s))
	_speed_opt.select(3)
	_speed_opt.item_selected.connect(func(i: int) -> void: session.clock.set_speed(MotionClock.SPEEDS[i]))
	row2.add_child(_speed_opt)
	_edit_check = CheckButton.new()
	_edit_check.text = "Reiniciar ao editar"
	_edit_check.tooltip_text = "Desligado: atualizar no instante atual e reconstruir os rastros (D-042)"
	_edit_check.toggled.connect(func(on: bool) -> void:
		session.edit_mode = MotionLabSession.EditMode.RESTART if on else MotionLabSession.EditMode.UPDATE_NOW)
	box.add_child(_edit_check)
	var row3 := HBoxContainer.new()
	box.add_child(row3)
	row3.add_child(_small("Emissor "))
	_emitter_opt = OptionButton.new()
	for n in ["Parado", "Em linha", "Em órbita"]:
		_emitter_opt.add_item(n)
	_emitter_opt.item_selected.connect(func(i: int) -> void: session.emitter_mode = i; _dirty = true)
	row3.add_child(_emitter_opt)

	# --- catálogo (painel da direita)
	box = right
	box.add_child(_section("Catálogo (M01–M20)"))
	_filter = LineEdit.new()
	_filter.placeholder_text = "buscar por nome ou id…"
	_filter.text_changed.connect(func(_t: String) -> void: _refresh_catalog())
	box.add_child(_filter)
	_catalog_list = ItemList.new()
	_catalog_list.custom_minimum_size.y = 190
	_catalog_list.item_selected.connect(_on_catalog_selected)
	box.add_child(_catalog_list)
	_catalog_desc = _small("")
	_catalog_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_catalog_desc)
	var row4 := HBoxContainer.new()
	box.add_child(row4)
	_add_op = OptionButton.new()
	row4.add_child(_add_op)
	row4.add_child(_btn("Adicionar camada", _on_add_layer))
	_refresh_catalog()

	# --- camadas
	box.add_child(_section("Camadas ordenadas (D-043)"))
	_layers_list = ItemList.new()
	_layers_list.custom_minimum_size.y = 120
	_layers_list.item_selected.connect(_on_layer_selected)
	box.add_child(_layers_list)
	var row5 := HBoxContainer.new()
	box.add_child(row5)
	row5.add_child(_btn("Subir", func() -> void: _move_selected(-1)))
	row5.add_child(_btn("Descer", func() -> void: _move_selected(1)))
	row5.add_child(_btn("Remover", _remove_selected))
	var row5b := HBoxContainer.new()
	box.add_child(row5b)
	row5b.add_child(_btn("Ligar/desligar", _toggle_selected))
	_solo_btn = _btn("Isolar camada", _toggle_solo)
	row5b.add_child(_solo_btn)

	# --- parâmetros
	box.add_child(_section("Parâmetros da camada"))
	_params_box = VBoxContainer.new()
	box.add_child(_params_box)

	# --- representação (painel da esquerda)
	box = left
	box.add_child(_section("Representação (D-044)"))
	var row6 := HBoxContainer.new()
	box.add_child(row6)
	_rep_opt = OptionButton.new()
	_rep_opt.add_item("Pontos (neutro, shader)")
	_rep_opt.add_item("Fitas (neutro, shader)")
	_rep_opt.add_item("Pontos + fitas")
	_rep_opt.add_item("Fragmentos (neutro, shader)")
	_rep_opt.add_item("Fumaça/billboards (neutro, shader)")
	_rep_opt.select(representation)
	_rep_opt.item_selected.connect(func(i: int) -> void: set_representation(i))
	row6.add_child(_rep_opt)
	box.add_child(_small("Tamanho do ponto (m)"))
	_size_slider = HSlider.new()
	_size_slider.min_value = 0.005
	_size_slider.max_value = 0.08
	_size_slider.step = 0.001
	_size_slider.value = points.point_size
	_size_slider.value_changed.connect(func(v: float) -> void: points.point_size = v; _dirty = true)
	box.add_child(_size_slider)
	box.add_child(_small("Tamanho do fragmento (m)"))
	var frag_slider := HSlider.new()
	frag_slider.min_value = 0.01
	frag_slider.max_value = 0.2
	frag_slider.step = 0.001
	frag_slider.value = fragments.fragment_size
	frag_slider.value_changed.connect(func(v: float) -> void: fragments.fragment_size = v; _dirty = true)
	box.add_child(frag_slider)
	_prop_slider(box, "Fumaça: tamanho da baforada (m)", 0.1, 0.8, 0.01, smoke.puff_size, func(v: float) -> void: smoke.puff_size = v)
	_prop_slider(box, "Fumaça: vida (s) até o tamanho final", 0.1, 3.0, 0.05, smoke.puff_life, func(v: float) -> void: smoke.puff_life = v)
	_prop_slider(box, "Fumaça: crescimento ao fim da vida (×)", 1.0, 3.0, 0.05, smoke.puff_growth, func(v: float) -> void: smoke.puff_growth = v)
	_prop_slider(box, "Fumaça: subida (m/s)", 0.0, 2.0, 0.05, smoke.puff_rise, func(v: float) -> void: smoke.puff_rise = v)
	_prop_slider(box, "Fumaça: abertura (m/s)", 0.0, 2.0, 0.05, smoke.puff_spread, func(v: float) -> void: smoke.puff_spread = v)
	box.add_child(_small("Largura da fita (m)"))
	_width_slider = HSlider.new()
	_width_slider.min_value = 0.005
	_width_slider.max_value = 0.15
	_width_slider.step = 0.001
	_width_slider.value = ribbons.ribbon_width
	_width_slider.value_changed.connect(func(v: float) -> void: ribbons.ribbon_width = v; _dirty = true)
	box.add_child(_width_slider)

	# --- presets
	box.add_child(_section("Presets (pasta fixa)"))
	box.add_child(_small(MotionPresets.DIR))
	var row7 := HBoxContainer.new()
	box.add_child(row7)
	_preset_name = LineEdit.new()
	_preset_name.placeholder_text = "nome (letras, números, _ e -)"
	_preset_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row7.add_child(_preset_name)
	row7.add_child(_btn("Salvar", _on_save_preset))
	var row8 := HBoxContainer.new()
	box.add_child(row8)
	_preset_opt = OptionButton.new()
	_preset_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row8.add_child(_preset_opt)
	row8.add_child(_btn("Carregar", _on_load_preset))
	_preset_status = _small("")
	_preset_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_preset_status)
	box.add_child(_small("Mouse: botão direito gira, meio move, roda aproxima. Teclas: espaço, R, vírgula, ponto."))


func _make_panel(layer: CanvasLayer, on_left: bool) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0 if on_left else 1.0
	panel.anchor_right = 0.0 if on_left else 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 0.0 if on_left else -PANEL_WIDTH
	panel.offset_right = PANEL_WIDTH if on_left else 0.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.11, 0.14, 0.90)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = PANEL_WIDTH - 32.0
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	scroll.add_child(box)
	return box


func _prop_slider(box: VBoxContainer, label: String, lo: float, hi: float, step: float, value: float, setter: Callable) -> void:
	box.add_child(_small(label))
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = value
	sl.value_changed.connect(func(v: float) -> void:
		setter.call(v)
		_dirty = true)
	box.add_child(sl)


func _title(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 18)
	return l


func _section(t: String) -> Label:
	var l := Label.new()
	l.text = "— " + t
	l.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	return l


func _small(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 12)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 60
	return l


func _btn(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(cb)
	return b


# ------------------------------------------------------------------ catálogo e camadas
func _refresh_catalog() -> void:
	_catalog_list.clear()
	_catalog_ids.clear()
	var f := _filter.text.strip_edges().to_lower() if _filter != null else ""
	for id in MotionCatalog.V1_IDS:
		var b := session.catalog.get_behavior(id)
		if b == null:
			continue
		var text := "%s — %s" % [id, b.display_name]
		if f != "" and not (f in text.to_lower()):
			continue
		_catalog_list.add_item(text)
		_catalog_ids.append(id)


func _on_catalog_selected(i: int) -> void:
	var b := session.catalog.get_behavior(_catalog_ids[i])
	_catalog_desc.text = "%s\n%s | operações: %s" % [b.description, MotionTypes.Kind.keys()[b.kind], ", ".join(_op_names(b))]
	_add_op.clear()
	for n in _op_names(b):
		_add_op.add_item(n)


func _op_names(b: MotionBehavior) -> Array[String]:
	var out: Array[String] = []
	for o in b.accepted_operations:
		out.append(MotionTypes.Op.keys()[o])
	return out


func _on_add_layer() -> void:
	var sel := _catalog_list.get_selected_items()
	if sel.is_empty() or _add_op.item_count == 0:
		return
	var bid := _catalog_ids[sel[0]]
	var n := 1
	while session.composition.find_layer(StringName("%s_%d" % [bid, n])) != null:
		n += 1
	var l := MotionLayer.new()
	l.id = StringName("%s_%d" % [bid, n])
	l.behavior_id = bid
	l.op = MotionTypes.Op[_add_op.get_item_text(_add_op.selected)]
	var idx := -1
	var cur := _selected_index()
	if cur >= 0:
		idx = cur + 1
	session.composition.add_layer(l, idx)
	_selected = l.id
	_after_edit()
	_refresh_layers()


## Troca de representação: só muda o desenho; a composição, a revisão e o relógio não são tocados.
func set_representation(i: int) -> void:
	representation = clampi(i, 0, 4)
	points.visible = representation == 0 or representation == 2
	ribbons.visible = representation == 1 or representation == 2
	fragments.visible = representation == 3
	smoke.visible = representation == 4
	_dirty = true


func _selected_index() -> int:
	return session.composition.layer_ids().find(_selected)


func _refresh_layers() -> void:
	_layers_list.clear()
	var ids := session.composition.layer_ids()
	for l in session.composition.layers:
		var mark := "●" if l.enabled else "○"
		var solo := "  [isolada]" if session.solo_layer == l.id else ""
		_layers_list.add_item("%s  %s   %s  %s%s" % [mark, l.id, l.behavior_id, MotionTypes.Op.keys()[l.op], solo])
	var idx := ids.find(_selected)
	if idx < 0 and not ids.is_empty():
		idx = 0
		_selected = ids[0]
	if idx >= 0:
		_layers_list.select(idx)
	_rebuild_params()


func _on_layer_selected(i: int) -> void:
	_selected = session.composition.layers[i].id
	_rebuild_params()


func _move_selected(delta: int) -> void:
	var i := _selected_index()
	if i < 0:
		return
	session.composition.move_layer(_selected, i + delta)
	_after_edit()
	_refresh_layers()


func _toggle_selected() -> void:
	if _selected == &"":
		return
	var l := session.composition.find_layer(_selected)
	session.composition.set_enabled(_selected, not l.enabled)
	_after_edit()
	_refresh_layers()


func _toggle_solo() -> void:
	session.set_solo(&"" if session.solo_layer == _selected else _selected)
	_dirty = true
	_refresh_layers()


func _remove_selected() -> void:
	if _selected == &"":
		return
	var i := _selected_index()
	session.composition.remove_layer(_selected)
	if session.solo_layer == _selected:
		session.set_solo(&"")
	var ids := session.composition.layer_ids()
	_selected = ids[clampi(i, 0, ids.size() - 1)] if not ids.is_empty() else &""
	_after_edit()
	_refresh_layers()


func _after_edit() -> void:
	session.notify_edited()
	_time_slider.max_value = session.clock.duration
	_dirty = true


# ------------------------------------------------------------------ parâmetros
func _rebuild_params() -> void:
	for c in _params_box.get_children():
		c.queue_free()
	var l := session.composition.find_layer(_selected)
	if l == null:
		return
	var b := session.catalog.get_behavior(l.behavior_id)
	_params_box.add_child(_small("%s — %s  (v%d)" % [b.id, b.display_name, b.version]))
	_params_box.add_child(_layer_slider("intensidade da camada (0–1)", l.intensity, 0.0, 1.0, 0.01, func(v: float) -> void: l.intensity = v; session.composition.touch(); _after_edit()))
	_params_box.add_child(_layer_slider("defasagem (s)", l.time_offset, -3.0, 3.0, 0.01, func(v: float) -> void: l.time_offset = v; session.composition.touch(); _after_edit()))
	var space := OptionButton.new()
	for n in MotionTypes.Space.keys():
		space.add_item("espaço: " + n)
	space.select(l.space)
	space.item_selected.connect(func(i: int) -> void: l.space = i; session.composition.touch(); _after_edit())
	_params_box.add_child(space)
	for p in b.params:
		_params_box.add_child(_param_widget(l, p))


func _param_widget(l: MotionLayer, p: MotionParam) -> Control:
	var cur: Variant = l.params.get(String(p.name), p.default_value)
	var unit := (" (%s)" % p.unit) if p.unit != "" else ""
	match p.kind:
		MotionParam.Kind.FLOAT:
			var step := maxf((p.max_value - p.min_value) / 400.0, 0.0005)
			return _layer_slider("%s%s" % [p.name, unit], float(cur), p.min_value, p.max_value, step,
				func(v: float) -> void: session.composition.set_param(l.id, p.name, v); _after_edit())
		MotionParam.Kind.INT:
			var hb := HBoxContainer.new()
			hb.add_child(_small("%s%s " % [p.name, unit]))
			var sp := SpinBox.new()
			sp.min_value = p.min_value
			sp.max_value = p.max_value
			sp.step = 1
			sp.value = int(cur)
			sp.value_changed.connect(func(v: float) -> void: session.composition.set_param(l.id, p.name, int(v)); _after_edit())
			hb.add_child(sp)
			return hb
		MotionParam.Kind.BOOL:
			var cb := CheckBox.new()
			cb.text = String(p.name)
			cb.button_pressed = bool(cur)
			cb.toggled.connect(func(on: bool) -> void: session.composition.set_param(l.id, p.name, on); _after_edit())
			return cb
		MotionParam.Kind.VECTOR3:
			var hb := HBoxContainer.new()
			hb.add_child(_small("%s%s " % [p.name, unit]))
			var v3: Vector3 = cur
			for axis in 3:
				var sp := SpinBox.new()
				sp.min_value = p.min_value
				sp.max_value = p.max_value
				sp.step = 0.01
				sp.value = v3[axis]
				sp.custom_minimum_size.x = 80
				sp.value_changed.connect(func(v: float) -> void:
					var nv: Vector3 = l.params.get(String(p.name), p.default_value)
					nv[axis] = v
					session.composition.set_param(l.id, p.name, nv)
					_after_edit())
				hb.add_child(sp)
			return hb
	return Label.new()


func _layer_slider(label: String, value: float, lo: float, hi: float, step: float, cb: Callable) -> Control:
	var vb := VBoxContainer.new()
	var name_lbl := _small("%s = %s" % [label, _fmt(value)])
	vb.add_child(name_lbl)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = clampf(value, lo, hi)
	s.value_changed.connect(func(v: float) -> void:
		name_lbl.text = "%s = %s" % [label, _fmt(v)]
		cb.call(v))
	vb.add_child(s)
	return vb


func _fmt(v: float) -> String:
	return "%.3f" % v if absf(v) < 100.0 else "%.1f" % v


# ------------------------------------------------------------------ presets
func _refresh_presets() -> void:
	_preset_opt.clear()
	for n in MotionPresets.list_names():
		_preset_opt.add_item(n)


func _on_save_preset() -> void:
	var diags := MotionPresets.save(_preset_name.text.strip_edges(), session.composition, session.catalog)
	if diags.is_empty():
		_preset_status.text = "Salvo: %s" % MotionPresets.path_for(_preset_name.text.strip_edges())
		_refresh_presets()
	else:
		_preset_status.text = "Erro: %s" % diags[0].message


func _on_load_preset() -> void:
	if _preset_opt.item_count == 0:
		_preset_status.text = "Nenhum preset salvo."
		return
	var r := MotionPresets.load_preset(_preset_opt.get_item_text(_preset_opt.selected), session.catalog)
	if r["composition"] == null:
		_preset_status.text = "Erro (a composição aberta foi preservada): %s" % r["diagnostics"][0].message
		return
	session.composition = r["composition"]
	session.set_solo(&"")
	_selected = &""
	_after_edit()
	_refresh_layers()
	_preset_status.text = "Carregado."


# ------------------------------------------------------------------ quadro
func _process(delta: float) -> void:
	session.clock.advance(delta)
	if session.clock.time != _last_time:
		_dirty = true
	if _dirty:
		_dirty = false
		_last_time = session.clock.time
		var r := session.evaluate()
		if representation == 0 or representation == 2:
			points.show_samples(r.samples)
		if representation == 1 or representation == 2:
			ribbons.show_samples(r.samples)
		if representation == 3:
			fragments.show_samples(r.samples)
		if representation == 4:
			smoke.show_samples(r.samples, _cam.global_position)
		_update_readouts(r)
	_play_btn.text = "Pausar" if session.clock.playing else "Reproduzir"
	if _capture_path != "":
		_capture_frames -= 1
		if _capture_frames <= 0:
			_save_capture()


func _update_readouts(r: MotionResult) -> void:
	_stats.text = "amostras %d | históricas %d | pontos %d | fitas %d (%d tri) | fragmentos %d | fumaça %d | camadas ativas %d | avaliação %.1f ms | revisão %d" % [
		r.stats.get("samples", 0), r.stats.get("history_samples", 0), points.shown_count, ribbons.strip_count, ribbons.triangle_count, fragments.shown_count, smoke.shown_count,
		r.stats.get("layers_active", 0), float(r.stats.get("eval_usec", 0)) / 1000.0, r.revision]
	var lines: Array[String] = []
	for d in r.diagnostics:
		lines.append(str(d))
		if lines.size() >= 3:
			break
	_diag.text = "\n".join(lines)
	_time_label.text = "t = %.3f s / %.2f s%s" % [session.clock.time, session.clock.duration,
		"   (histórico desde %.2f s)" % session.clock.history_start() if session.clock.history_start() > 0.0 else ""]
	_time_slider.set_value_no_signal(session.clock.time)


func _save_capture() -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_capture_path)
	print("captura: ", _capture_path, " (", error_string(err), ") ", img.get_size())
	get_tree().quit(0 if err == OK else 1)
