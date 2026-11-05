class_name GameFxBridge
extends Node3D
## Ponte SOMENTE DE USO entre o laboratório do Motion Composer e os efeitos que o jogo já tem (D-307).
## Dispara os efeitos existentes do `BattleFx` (sem editá-lo: D-003, D-019, D-020) entre um ATACANTE e um ALVO
## do laboratório. Nada aqui conhece personagem, time, lado ou coordenada fixa (D-235): posição, direção, altura e
## lado vêm dos dois marcadores configuráveis (distância, altura, espelhar).
##
## Tempo: os efeitos do jogo disparam em tempo real (tweens e temporizadores); a ponte controla o ritmo por
## `Engine.time_scale` (0 = pausa), que vale para o laboratório inteiro. Busca no tempo NÃO é oferecida nesta fatia.

## Efeitos disparáveis (id do Move → rótulo). O comportamento é por `move_id`, nunca por personagem.
const EFFECTS: Array[String] = ["tackle", "megido", "mabufula", "hassou_tobi", "titanomachia", "media", "tarukaja", "rakunda", "sukunda"]
const SPEEDS: Array[float] = [0.0, 0.1, 0.25, 0.5, 1.0]
const TACKLE_IMPACT_DELAY := 0.24

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


func is_active() -> bool:
	return _active_effect != "" and fx.get_child_count() > 0


func set_speed(s: float) -> void:
	Engine.time_scale = maxf(s, 0.0)


func _process(_delta: float) -> void:
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
	var note := _label("Tempo real; sem busca no tempo. O ritmo vale para o laboratório inteiro.", 12)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	_ui_effect = OptionButton.new()
	for e in EFFECTS:
		_ui_effect.add_item(e)
	box.add_child(_ui_effect)
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(_button("Disparar", func() -> void: play(EFFECTS[_ui_effect.selected])))
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
