class_name GameFxBridge
extends Node3D
## Ponte SOMENTE DE USO entre o laboratório do Motion Composer e os efeitos que o jogo já tem (D-307).
## Dispara os efeitos existentes do `BattleFx` (sem editá-lo: D-003, D-019, D-020) entre um ATACANTE e um ALVO
## do laboratório. Nada aqui conhece personagem, time, lado ou coordenada fixa (D-235): posição, direção, altura e
## lado vêm dos dois marcadores configuráveis (distância, altura, espelhar).
##
## Tempo: os efeitos do jogo disparam em tempo real (tweens e temporizadores). A ponte controla o ritmo por
## `Engine.time_scale` (0 = pausa), que vale para o laboratório inteiro. BUSCA (`seek`): reinicia o efeito com a mesma
## semente e o avança por quadros acelerados (escala = passo / duração real prevista do quadro), contando o tempo
## avançado pelo `delta` já escalado do próprio quadro; ao chegar em t, pausa. Precisão: um quadro de jitter por salto
## de temporizador encadeado; não é exata como o `--fixed-fps`.

## Efeitos disparáveis (id do Move → rótulo). O comportamento é por `move_id`, nunca por personagem.
const EFFECTS: Array[String] = ["tackle", "megido", "mabufula", "hassou_tobi", "titanomachia", "media", "tarukaja", "rakunda", "sukunda"]
const SPEEDS: Array[float] = [0.0, 0.1, 0.25, 0.5, 1.0]
const TACKLE_IMPACT_DELAY := 0.24
## Maior passo de tempo de efeito por quadro durante a busca (um passo por quadro de 1/60 s, como o jogo; mais largo encadearia menos saltos de temporizador).
const SEEK_MAX_STEP := 1.0 / 60.0
const DEFAULT_SEED := 1234

## Em quem o efeito acontece: o alvo ou o próprio atacante.
const ON_TARGET := 0
const ON_CASTER := 1

## Pedidos à cena do laboratório (a ponte não mexe na câmera nem na composição por conta própria).
signal framing_requested(center: Vector3, camera_distance: float)
signal composition_visible_requested(on: bool)

var distance: float = 8.4
var attacker_height: float = 2.0
var target_height: float = 2.4
var mirrored: bool = false
## Semente do RNG global usada ao disparar (mesmo efeito + mesma semente = mesmo resultado).
var rng_seed: int = DEFAULT_SEED

signal seek_finished(advanced: float)
var _seek_target: float = -1.0
var _seek_advanced: float = 0.0
var _seek_pending: float = -1.0
var _seek_real: float = 1.0 / 60.0
## Quadros iniciais da busca em câmera quase parada: o primeiro desenho de um efeito (carregar, compilar) pode levar
## centenas de ms e, no ritmo normal, avançaria o efeito por esse tempo todo.
var _seek_warm: int = 0
var _seek_warm_total: int = 0
var _seek_calm: int = 0
const SEEK_WARM_FRAMES := 3
const SEEK_WARM_SCALE := 0.001
var _ui_time: HSlider

var fx: BattleFx
var _markers := {}
var _pending: Tween
var _fired_at_usec: int = 0
var _peak := {}
var _ui_stats: Label
var _ui_effect: OptionButton
var _ui_speed: OptionButton
var _ui_mirror: CheckBox
var _active_effect: String = ""


func _init() -> void:
	fx = BattleFx.new()
	add_child(fx)
	for who in ["attacker", "target"]:
		var m := MeshInstance3D.new()
		m.mesh = CapsuleMesh.new()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.35, 0.6, 1.0, 0.35) if who == "attacker" else Color(1.0, 0.55, 0.25, 0.35)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.material_override = mat
		add_child(m)
		_markers[who] = m
	_update_markers()


func _exit_tree() -> void:
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0


## Posições derivadas dos parâmetros: {attacker, target, attacker_center, target_center, dir}. Sem nada fixo.
func layout() -> Dictionary:
	var side := -1.0 if mirrored else 1.0
	var a := Vector3(-side * distance * 0.5, 0.0, 0.0)
	var t := Vector3(side * distance * 0.5, 0.0, 0.0)
	var dir := (t - a)
	dir.y = 0.0
	dir = dir.normalized()
	return {
		"attacker": a, "target": t,
		"attacker_center": a + Vector3(0, attacker_height * 0.5, 0),
		"target_center": t + Vector3(0, target_height * 0.5, 0),
		"dir": dir,
	}


func _update_markers() -> void:
	var l := layout()
	var a: MeshInstance3D = _markers["attacker"]
	var t: MeshInstance3D = _markers["target"]
	(a.mesh as CapsuleMesh).height = attacker_height
	(a.mesh as CapsuleMesh).radius = minf(0.45, attacker_height * 0.25)
	a.position = l["attacker_center"]
	(t.mesh as CapsuleMesh).height = target_height
	(t.mesh as CapsuleMesh).radius = minf(0.6, target_height * 0.25)
	t.position = l["target_center"]


func set_layout(dist: float, a_h: float, t_h: float, mirror: bool) -> void:
	distance = maxf(dist, 1.0)
	attacker_height = maxf(a_h, 0.4)
	target_height = maxf(t_h, 0.4)
	mirrored = mirror
	_update_markers()


## Pede à cena para enquadrar o atacante e o alvo (câmera a uma distância que cabe os dois).
func request_framing() -> void:
	var l := layout()
	var mid: Vector3 = ((l["attacker_center"] as Vector3) + (l["target_center"] as Vector3)) * 0.5
	framing_requested.emit(mid, maxf(distance * 2.1, 8.0))


## Remove tudo o que um efeito anterior deixou na cena (o BattleFx em si não é alterado).
func clear() -> void:
	if _pending != null and _pending.is_valid():
		_pending.kill()
	_pending = null
	for c in fx.get_children():
		c.queue_free()
	_active_effect = ""


## Dispara o efeito `effect` entre o atacante e o alvo atuais. Reinicia se já houver um.
func play(effect: String) -> bool:
	if not EFFECTS.has(effect):
		return false
	clear()
	seed(rng_seed)
	var l := layout()
	var dir: Vector3 = l["dir"]
	var target_c: Vector3 = l["target_center"]
	var caster_c: Vector3 = l["attacker_center"]
	match effect:
		"tackle":
			fx.fx_motion._tackle_strike_vfx(l["attacker"] + dir * 1.5, dir)
			_pending = create_tween()
			_pending.tween_interval(TACKLE_IMPACT_DELAY)
			_pending.tween_callback(func() -> void: fx.fx_impacts._tackle_impact(target_c, dir, false))
		"megido":
			fx.fx_impacts._impact_move("megido", target_c, Color.GOLD, true, dir)
		"mabufula":
			fx.fx_impacts._impact_move("mabufula", target_c, Color.CYAN, true, dir)
		"hassou_tobi":
			fx.fx_impacts._impact_move("hassou_tobi", target_c, Color.WHITE, true, dir)
		"titanomachia":
			fx.fx_impacts._impact_move("titanomachia", (l["target"] as Vector3) + Vector3(0, 0.1, 0), Color("ff8f00"), true, dir)
		"media":
			fx.fx_impacts._status_impact_move("media", caster_c)
		"tarukaja":
			fx.fx_impacts._status_impact_move("tarukaja", caster_c)
		"rakunda":
			fx.fx_impacts._status_impact_move("rakunda", target_c)
		"sukunda":
			fx.fx_impacts._status_impact_move("sukunda", target_c)
	_active_effect = effect
	if _ui_effect != null:
		_ui_effect.selected = EFFECTS.find(effect)
	_fired_at_usec = Time.get_ticks_usec()
	_peak = {"nodes": 0, "particles": 0, "meshes": 0, "draw_calls": 0, "primitives": 0, "objects": 0, "frame_ms": 0.0}
	return true


## Onde o efeito disparado está (centro dos nós 3D espaciais criados), para conferir o lado e o alvo.
func effect_centroid() -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for c in fx.get_children():
		if c is Node3D:
			sum += (c as Node3D).global_position
			n += 1
	return sum / float(n) if n > 0 else Vector3.INF


## Contadores do que o efeito colocou na cena agora (só nós vivos sob o BattleFx).
func scene_stats() -> Dictionary:
	var nodes := 0
	var particles := 0
	var meshes := 0
	var stack: Array[Node] = []
	for c in fx.get_children():
		if not c.is_queued_for_deletion():
			stack.append(c)
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		nodes += 1
		if n is GPUParticles3D or n is CPUParticles3D:
			particles += 1
		elif n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
			meshes += 1
		for ch in n.get_children():
			if not ch.is_queued_for_deletion():
				stack.append(ch)
	return {"nodes": nodes, "particles": particles, "meshes": meshes}


## Reinicia o efeito (mesma semente) e o avança até `t` segundos de tempo de efeito; depois pausa
## (`Engine.time_scale` 0). `t` ≤ 0 deixa o efeito recém-disparado e pausado.
func seek(effect: String, t: float) -> bool:
	_seek_target = -1.0
	Engine.time_scale = 1.0
	if not play(effect):
		return false
	_seek_advanced = 0.0
	if _ui_time != null:
		_ui_time.set_value_no_signal(clampf(t, _ui_time.min_value, _ui_time.max_value))
	if t <= 0.0005:
		Engine.time_scale = 0.0
		seek_finished.emit(0.0)
		return true
	_seek_target = t
	_seek_real = 1.0 / 60.0
	_seek_warm = SEEK_WARM_FRAMES
	_seek_warm_total = 0
	_seek_calm = 0
	Engine.time_scale = SEEK_WARM_SCALE
	return true


## Passo de tempo de efeito pedido para o próximo quadro da busca: no máximo um quadro do jogo (1/60 s).
static func seek_step(remaining: float) -> float:
	return minf(SEEK_MAX_STEP, maxf(remaining, 0.0))


func is_seeking() -> bool:
	return _seek_target >= 0.0


func is_active() -> bool:
	return _active_effect != "" and fx.get_child_count() > 0


func set_speed(s: float) -> void:
	Engine.time_scale = maxf(s, 0.0)


func _process(delta: float) -> void:
	if _seek_pending >= 0.0:
		var t := _seek_pending
		_seek_pending = -1.0
		seek(EFFECTS[_ui_effect.selected] if _ui_effect != null else _active_effect, t)
		return
	if _seek_target >= 0.0:
		_seek_advanced += delta
		if _seek_warm > 0:
			# Aquecimento: segue em câmera quase parada até 2 quadros seguidos "normais" (< 40 ms reais), no mínimo
			# SEEK_WARM_FRAMES e no máximo 120 quadros; o primeiro desenho de um efeito pode levar centenas de ms.
			_seek_warm_total += 1
			var real_w := delta / SEEK_WARM_SCALE
			_seek_calm = _seek_calm + 1 if real_w < 0.04 else 0
			if (_seek_calm >= 2 and _seek_warm_total >= SEEK_WARM_FRAMES) or _seek_warm_total >= 120:
				_seek_warm = 0
				_seek_real = clampf(real_w, 0.0005, 0.04)
				Engine.time_scale = seek_step(_seek_target - _seek_advanced) / _seek_real
			return
		var scale := maxf(Engine.time_scale, 0.0001)
		_seek_real = clampf(delta / scale, 0.0005, 0.25)
		if _seek_advanced >= _seek_target - 0.0001:
			_seek_target = -1.0
			Engine.time_scale = 0.0
			seek_finished.emit(_seek_advanced)
			if _ui_speed != null:
				_ui_speed.selected = 0
		else:
			Engine.time_scale = seek_step(_seek_target - _seek_advanced) / _seek_real
	if not is_active():
		if _active_effect != "" and fx.get_child_count() == 0:
			_active_effect = ""
		_refresh_ui()
		return
	var st := scene_stats()
	_peak["nodes"] = maxi(_peak["nodes"], st["nodes"])
	_peak["particles"] = maxi(_peak["particles"], st["particles"])
	_peak["meshes"] = maxi(_peak["meshes"], st["meshes"])
	_peak["draw_calls"] = maxi(_peak["draw_calls"], int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_peak["primitives"] = maxi(_peak["primitives"], int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	_peak["objects"] = maxi(_peak["objects"], int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	_peak["frame_ms"] = maxf(_peak["frame_ms"], float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
	_refresh_ui()


## Seção de interface (um VBoxContainer qualquer). A ponte só desenha seus próprios controles.
func build_ui(box: VBoxContainer) -> void:
	box.add_child(_label("Efeitos do jogo (referência, uso do BattleFx)", 15))
	var note := _label("Tempo real, com busca pelo slider (aproximada). O ritmo e a pausa valem para o laboratório inteiro.", 12)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	_ui_effect = OptionButton.new()
	for e in EFFECTS:
		_ui_effect.add_item(e)
	box.add_child(_ui_effect)
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(_button("Disparar", fire_from_ui))
	row.add_child(_button("Limpar", clear))
	row.add_child(_button("Enquadrar", request_framing))
	var hide := CheckBox.new()
	hide.text = "Ocultar a composição"
	hide.toggled.connect(func(on: bool) -> void: composition_visible_requested.emit(not on))
	box.add_child(hide)
	_ui_speed = OptionButton.new()
	for s in SPEEDS:
		_ui_speed.add_item("pausa" if s == 0.0 else "%s×" % [s])
	_ui_speed.selected = SPEEDS.size() - 1
	_ui_speed.item_selected.connect(func(i: int) -> void: set_speed(SPEEDS[i]))
	box.add_child(_ui_speed)
	var tl := _label("Tempo do efeito (busca)", 12)
	box.add_child(tl)
	_ui_time = HSlider.new()
	_ui_time.min_value = 0.0
	_ui_time.max_value = 1.5
	_ui_time.step = 0.05
	_ui_time.value_changed.connect(func(v: float) -> void: _seek_pending = v)
	box.add_child(_ui_time)
	_ui_mirror = CheckBox.new()
	_ui_mirror.text = "Espelhar (atacante à direita)"
	_ui_mirror.toggled.connect(func(on: bool) -> void: set_layout(distance, attacker_height, target_height, on))
	box.add_child(_ui_mirror)
	_slider(box, "Distância", 3.0, 16.0, 0.2, distance, func(v: float) -> void: set_layout(v, attacker_height, target_height, mirrored))
	_slider(box, "Altura do atacante", 0.6, 5.0, 0.1, attacker_height, func(v: float) -> void: set_layout(distance, v, target_height, mirrored))
	_slider(box, "Altura do alvo", 0.6, 5.0, 0.1, target_height, func(v: float) -> void: set_layout(distance, attacker_height, v, mirrored))
	_ui_stats = _label("", 12)
	_ui_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_ui_stats)


## Botão Disparar: se o laboratório está pausado (time_scale 0, por exemplo depois de uma busca), volta a 1× para o
## efeito disparado andar em vez de nascer congelado.
func fire_from_ui() -> void:
	if _ui_effect == null:
		return
	_seek_target = -1.0
	if Engine.time_scale <= 0.0:
		set_speed(1.0)
		if _ui_speed != null:
			_ui_speed.selected = SPEEDS.size() - 1
	play(EFFECTS[_ui_effect.selected])


func _refresh_ui() -> void:
	if _ui_stats == null:
		return
	var st := scene_stats()
	var txt := "Agora: %d nós, %d partículas, %d malhas | quadro %d draw calls, %d primitivas, %d objetos" % [
		st["nodes"], st["particles"], st["meshes"],
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))]
	if not _peak.is_empty():
		txt += "\nPico do efeito (%s): %d nós, %d partículas, %d malhas | %d draw calls, %d primitivas, %d objetos, %.1f ms de processo" % [
			_active_effect if _active_effect != "" else "último", _peak["nodes"], _peak["particles"], _peak["meshes"],
			_peak["draw_calls"], _peak["primitives"], _peak["objects"], _peak["frame_ms"]]
	_ui_stats.text = txt


func _label(t: String, size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	return l


func _button(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(cb)
	return b


func _slider(box: VBoxContainer, label: String, lo: float, hi: float, step: float, value: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var l := _label(label, 12)
	l.custom_minimum_size.x = 120
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(cb)
	row.add_child(s)
	box.add_child(row)
