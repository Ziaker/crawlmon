class_name LevelUpModal
extends Control
## Modal obrigatorio de alocacao de atributos do lider ao subir de nivel (D-135, D-394, D-401).
## Bloqueia retorno ao jogo ate que todos os pontos livres disponiveis sejam alocados.

signal modal_closed

const STAT_NAMES: Array[String] = ["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]
const STAT_DESCRIPTIONS: Dictionary = {
	"STR": "Ataque Fisico",
	"MAG": "Ataque Magico",
	"VIT": "Vitalidade & HP Maximo (+2 HP/pt)",
	"WIS": "Defesa Magica & MP Maximo (+2 MP/pt)",
	"AGI": "Agilidade & Ritmo de Enchimento ATB",
	"LUK": "Sorte, Taxa Critica & Evasao Automatica"
}

const GOLD := Color("f7cb78")
const INK := Color("080e18")
const CREAM := Color("f0eedf")
const LIME := Color("d7fd6a")
const CYAN := Color("62d8e7")
const GRAY := Color("666666")
const DARK_BG := Color(0.04, 0.06, 0.10, 0.96)
const BORDER_COLOR := Color(0.35, 0.55, 0.85, 0.90)

var leader: Combatant
var initial_points: int = 0
var remaining_points: int = 0
var session_allocated: Dictionary = {
	"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0
}

var _selected_row: int = 0  ## 0..5 para os atributos; 6 para o botao Confirmar
var _anim_t: float = 0.0
var _font: Font
var _title_font: Font


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open(p_leader: Combatant) -> void:
	leader = p_leader
	initial_points = leader.distributable_points
	remaining_points = initial_points
	for s in STAT_NAMES:
		session_allocated[s] = 0
	_selected_row = 0
	_anim_t = 0.0
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_anim_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or leader == null:
		return

	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_selected_row = posmod(_selected_row - 1, 7)
		queue_redraw()
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_selected_row = posmod(_selected_row + 1, 7)
		queue_redraw()
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		if _selected_row >= 0 and _selected_row < 6:
			_increment_stat(STAT_NAMES[_selected_row])
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		if _selected_row >= 0 and _selected_row < 6:
			_decrement_stat(STAT_NAMES[_selected_row])
	elif event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _selected_row == 6:
			_try_confirm()
		elif _selected_row >= 0 and _selected_row < 6:
			# Pressionar confirmar na linha do atributo incrementa se houver pontos
			if remaining_points > 0:
				_increment_stat(STAT_NAMES[_selected_row])
			else:
				# Se nao ha pontos pendentes, move selecao para o botao confirmar
				_selected_row = 6
				queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			if _selected_row == 6:
				_try_confirm()


func _increment_stat(stat: String) -> void:
	if remaining_points > 0:
		remaining_points -= 1
		session_allocated[stat] = int(session_allocated.get(stat, 0)) + 1
		queue_redraw()


func _decrement_stat(stat: String) -> void:
	if int(session_allocated.get(stat, 0)) > 0:
		session_allocated[stat] = int(session_allocated.get(stat, 0)) - 1
		remaining_points += 1
		queue_redraw()


func _try_confirm() -> void:
	if remaining_points != 0:
		return  # D-401: Proibido confirmar com pontos pendentes

	# Aplica os pontos de progressao aos atributos do lider
	var total_allocated: int = 0
	for stat in STAT_NAMES:
		var delta_val: int = int(session_allocated.get(stat, 0))
		if delta_val > 0:
			leader.progression_points[stat] = int(leader.progression_points.get(stat, 0)) + delta_val
			total_allocated += delta_val

	leader.distributable_points = maxi(0, leader.distributable_points - total_allocated)
	leader.sync_effective_stats()
	leader.update_resource_maximums()

	visible = false
	modal_closed.emit()
	queue_free()


func _get_font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Arial", "Segoe UI", "Sans-Serif"])
		f.font_weight = 700
		_font = f
	return _font


func _get_title_font() -> Font:
	if _title_font == null:
		if ResourceLoader.exists("res://assets/fonts/kanit/Kanit-BlackItalic.ttf"):
			_title_font = load("res://assets/fonts/kanit/Kanit-BlackItalic.ttf") as Font
		else:
			_title_font = _get_font()
	return _title_font


func _draw() -> void:
	if not visible or leader == null:
		return

	var vp_size := get_viewport_rect().size
	# Fundo escuro modal com bloqueio de cliques
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.0, 0.0, 0.0, 0.80))

	var panel_w := minf(vp_size.x * 0.84, 620.0)
	var panel_h := minf(vp_size.y * 0.86, 510.0)
	var panel_rect := Rect2((vp_size.x - panel_w) * 0.5, (vp_size.y - panel_h) * 0.5, panel_w, panel_h)

	draw_rect(panel_rect, DARK_BG)
	draw_rect(panel_rect, BORDER_COLOR, false, 2.5)

	var font := _get_font()
	var title_font := _get_title_font()

	# Titulo
	var title_str := "LEVEL UP — ALOCAÇÃO DE ATRIBUTOS"
	draw_string(title_font, Vector2(panel_rect.position.x + 28, panel_rect.position.y + 44), title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD)

	var sub_str := "%s (Nível %d)" % [leader.name, leader.level]
	draw_string(font, Vector2(panel_rect.position.x + 28, panel_rect.position.y + 72), sub_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, CREAM)

	# Saldo de pontos restantes
	var pts_col := LIME if remaining_points > 0 else (CYAN if remaining_points == 0 else Color(0.9, 0.4, 0.4))
	var pts_str := "Pontos Disponíveis: %d" % remaining_points
	draw_string(font, Vector2(panel_rect.position.x + panel_w - 220, panel_rect.position.y + 60), pts_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 18, pts_col)

	# Linha divisoria
	var div_y := panel_rect.position.y + 88
	draw_line(Vector2(panel_rect.position.x + 20, div_y), Vector2(panel_rect.position.x + panel_w - 20, div_y), Color(1, 1, 1, 0.15), 1.5)

	# Linhas dos 6 atributos
	var row_y := div_y + 16
	var row_h := 46.0

	for i in range(STAT_NAMES.size()):
		var stat := STAT_NAMES[i]
		var cur_effective := leader.get_effective_stat(stat)
		var added := int(session_allocated.get(stat, 0))
		var is_selected := (_selected_row == i)

		var r_rect := Rect2(panel_rect.position.x + 24, row_y + (i * row_h), panel_w - 48, row_h - 6)
		if is_selected:
			draw_rect(r_rect, Color(0.2, 0.35, 0.55, 0.45))
			draw_rect(r_rect, GOLD, false, 1.5)
		else:
			draw_rect(r_rect, Color(0.08, 0.12, 0.18, 0.40))
			draw_rect(r_rect, Color(0.2, 0.3, 0.4, 0.25), false, 1.0)

		# Nome do atributo
		var label_col := GOLD if is_selected else CREAM
		draw_string(font, Vector2(r_rect.position.x + 16, r_rect.position.y + 26), stat, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, label_col)

		# Descricao
		var desc: String = str(STAT_DESCRIPTIONS.get(stat, ""))
		draw_string(font, Vector2(r_rect.position.x + 75, r_rect.position.y + 25), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.75, 0.8))

		# Botoes e Valores
		var val_str := "%d" % (cur_effective + added)
		var btn_x := r_rect.position.x + r_rect.size.x - 120

		# Botao [-]
		var minus_col := CYAN if added > 0 else GRAY
		draw_string(font, Vector2(btn_x, r_rect.position.y + 26), "[ - ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, minus_col)

		# Valor com destaque se aumentado
		var val_col := LIME if added > 0 else CREAM
		draw_string(font, Vector2(btn_x + 40, r_rect.position.y + 26), val_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, val_col)

		# Botao [+]
		var plus_col := CYAN if remaining_points > 0 else GRAY
		draw_string(font, Vector2(btn_x + 80, r_rect.position.y + 26), "[ + ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, plus_col)

	# Botao Confirmar
	var btn_confirm_rect := Rect2(panel_rect.position.x + (panel_w * 0.5) - 130, panel_rect.position.y + panel_h - 60, 260, 42)
	var can_confirm := (remaining_points == 0)
	var is_confirm_selected := (_selected_row == 6)

	var confirm_bg := Color(0.15, 0.45, 0.25, 0.9) if can_confirm else Color(0.12, 0.12, 0.12, 0.8)
	if is_confirm_selected:
		confirm_bg = Color(0.25, 0.65, 0.35, 1.0) if can_confirm else Color(0.25, 0.25, 0.25, 0.9)

	draw_rect(btn_confirm_rect, confirm_bg)
	var confirm_border := GOLD if is_confirm_selected else (Color(0.4, 0.8, 0.5) if can_confirm else GRAY)
	draw_rect(btn_confirm_rect, confirm_border, false, 2.0 if is_confirm_selected else 1.0)

	var confirm_text := "CONFIRMAR ALOCAÇÃO" if can_confirm else "DISTRIBUA TODOS OS PONTOS"
	var text_col := CREAM if can_confirm else Color(0.6, 0.6, 0.6)
	draw_string(font, Vector2(btn_confirm_rect.position.x, btn_confirm_rect.position.y + 27), confirm_text, HORIZONTAL_ALIGNMENT_CENTER, btn_confirm_rect.size.x, 15, text_col)
