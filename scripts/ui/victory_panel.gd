class_name VictoryPanel
extends Control
## Painel de vitoria pos-combate exibindo XP conquistado, barras de progresso animadas
## e alertas de LEVEL UP! (D-400, D-402).

signal victory_confirmed

const GOLD := Color("f7cb78")
const INK := Color("080e18")
const CREAM := Color("f0eedf")
const LIME := Color("d7fd6a")
const GRAY := Color("666666")
const DARK_BG := Color(0.04, 0.06, 0.10, 0.92)
const BORDER_COLOR := Color(0.25, 0.45, 0.65, 0.85)

var total_xp: int = 0
var summaries: Array[Dictionary] = []
var _anim_t: float = 0.0
var _can_confirm: bool = false
var _font: Font
var _title_font: Font


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open(p_total_xp: int, p_summaries: Array[Dictionary]) -> void:
	total_xp = p_total_xp
	summaries = p_summaries
	_anim_t = 0.0
	_can_confirm = false
	visible = true
	queue_redraw()

	# Apos breve intervalo permite confirmacao
	var timer := get_tree().create_timer(0.4, true, false, true)
	timer.timeout.connect(func(): _can_confirm = true)


func _process(delta: float) -> void:
	if not visible:
		return
	_anim_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _can_confirm:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirm_and_close()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_confirm_and_close()


func _confirm_and_close() -> void:
	visible = false
	victory_confirmed.emit()
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
	if not visible:
		return

	var vp_size := get_viewport_rect().size
	# Fundo escuro semi-transparente
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.0, 0.0, 0.0, 0.65))

	var panel_w := minf(vp_size.x * 0.82, 680.0)
	var panel_h := minf(vp_size.y * 0.80, 480.0)
	var panel_rect := Rect2((vp_size.x - panel_w) * 0.5, (vp_size.y - panel_h) * 0.5, panel_w, panel_h)

	# Moldura principal
	draw_rect(panel_rect, DARK_BG)
	draw_rect(panel_rect, BORDER_COLOR, false, 2.5)

	var font := _get_font()
	var title_font := _get_title_font()

	# Cabecalho
	var title_text := "VICTORY!"
	var title_size := 38
	draw_string(title_font, Vector2(panel_rect.position.x + 30, panel_rect.position.y + 48), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, GOLD)

	var xp_summary := "+%d XP" % total_xp
	draw_string(font, Vector2(panel_rect.position.x + panel_w - 180, panel_rect.position.y + 45), xp_summary, HORIZONTAL_ALIGNMENT_RIGHT, -1, 24, LIME)

	# Linha divisoria
	var div_y := panel_rect.position.y + 68
	draw_line(Vector2(panel_rect.position.x + 20, div_y), Vector2(panel_rect.position.x + panel_w - 20, div_y), Color(1, 1, 1, 0.15), 1.5)

	# Cards dos membros da equipe
	var start_y := div_y + 24
	var card_h := 82.0
	var card_gap := 16.0

	var prog := clampf(_anim_t / 1.2, 0.0, 1.0)
	# Curva de interpolacao suave (ease-out cubic)
	var eased := 1.0 - pow(1.0 - prog, 3.0)

	for i in range(summaries.size()):
		var s: Dictionary = summaries[i]
		var c = s.get("combatant")
		var is_alive: bool = bool(s.get("is_alive", true))
		var member_name: String = str(c.name) if c != null else "Combatant"
		var cur_y := start_y + (i * (card_h + card_gap))

		var card_rect := Rect2(panel_rect.position.x + 25, cur_y, panel_w - 50, card_h)
		draw_rect(card_rect, Color(0.08, 0.12, 0.18, 0.75))
		draw_rect(card_rect, Color(0.3, 0.4, 0.5, 0.35), false, 1.0)

		if not is_alive:
			# Membro derrotado (K.O.)
			draw_string(font, Vector2(card_rect.position.x + 16, card_rect.position.y + 32), member_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GRAY)
			draw_string(font, Vector2(card_rect.position.x + 220, card_rect.position.y + 32), "Lv. %d" % int(s.get("new_level", 1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GRAY)
			draw_string(font, Vector2(card_rect.position.x + card_rect.size.x - 140, card_rect.position.y + 48), "K.O. (+0 XP)", HORIZONTAL_ALIGNMENT_RIGHT, -1, 18, Color(0.85, 0.3, 0.3))
			continue

		var old_lvl: int = int(s.get("old_level", 1))
		var new_lvl: int = int(s.get("new_level", 1))
		var levels_gained: int = int(s.get("levels_gained", 0))
		var old_xp: int = int(s.get("old_xp", 0))
		var current_xp: int = int(s.get("current_xp", 0))
		var xp_req: int = int(s.get("xp_required", 50))

		# Nome e Nivel
		draw_string(font, Vector2(card_rect.position.x + 16, card_rect.position.y + 30), member_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, CREAM)
		var lvl_str := "Lv. %d" % (new_lvl if prog >= 0.8 else old_lvl)
		draw_string(font, Vector2(card_rect.position.x + 200, card_rect.position.y + 30), lvl_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD)

		# Badge de Level Up
		if levels_gained > 0 and prog >= 0.5:
			var blink := fmod(_anim_t * 4.0, 1.0) > 0.3
			var badge_col := LIME if blink else GOLD
			draw_string(font, Vector2(card_rect.position.x + 280, card_rect.position.y + 30), "LEVEL UP! +%d" % levels_gained, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, badge_col)

		# Barra de XP
		var bar_x := card_rect.position.x + 16
		var bar_y := card_rect.position.y + 44
		var bar_w := card_rect.size.x - 32
		var bar_h := 16.0

		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.04, 0.05, 0.08, 0.9))
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.2, 0.3, 0.4, 0.5), false, 1.0)

		# Calculo de preenchimento animado
		var target_ratio: float = clampf(float(current_xp) / maxf(float(xp_req), 1.0), 0.0, 1.0)
		var fill_ratio: float
		if levels_gained > 0:
			if prog < 0.5:
				# Preenche ate o teto do nivel anterior
				fill_ratio = lerpf(float(old_xp) / maxf(float(CrawlmonAttributeMath.get_xp_for_level_transition(old_lvl)), 1.0), 1.0, prog * 2.0)
			else:
				# Reseta e preenche o excedente no novo nivel
				fill_ratio = lerpf(0.0, target_ratio, (prog - 0.5) * 2.0)
		else:
			var start_ratio: float = float(old_xp) / maxf(float(xp_req), 1.0)
			fill_ratio = lerpf(start_ratio, target_ratio, eased)

		var fill_w := bar_w * clampf(fill_ratio, 0.0, 1.0)
		if fill_w > 0.0:
			draw_rect(Rect2(bar_x + 1, bar_y + 1, fill_w - 2, bar_h - 2), Color(0.25, 0.75, 0.95))

		# Texto de XP numerico na barra
		var xp_num_str := "%d / %d XP" % [current_xp, xp_req]
		draw_string(font, Vector2(bar_x + bar_w - 110, bar_y + 13), xp_num_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, CREAM)

	# Instrucao de confirmacao no rodape
	if _can_confirm:
		var blink_sub := fmod(_anim_t * 2.5, 1.0) > 0.35
		var sub_col := CREAM if blink_sub else Color(0.8, 0.8, 0.8, 0.6)
		draw_string(font, Vector2(panel_rect.position.x + (panel_w * 0.5) - 120, panel_rect.position.y + panel_h - 20), "[ Z / ENTER ]  CONTINUAR", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, sub_col)
