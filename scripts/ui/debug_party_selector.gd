extends CanvasLayer
## Debug/test tool (not a game rule): press E to choose which party member the
## player controls. The current scene implements `debug_swap_party(i)`; choosing
## an ally calls it without restarting the scene.
##
## The list is the real `GameState.party`. It does not pause the game unless the
## scene is already paused by its own menu. The UI is keyboard-only and does not
## use the battle/overworld HUD.

const PANEL_MIN_WIDTH := 620.0
const FONT_SIZE_TITLE := 24
const FONT_SIZE_ROW := 17
const FONT_SIZE_HINT := 13

var _open := false
var _selected := 0
var _members: Array[Dictionary] = []
var _was_paused := false
var _root: Control
var _title: Label
var _leader_label: Label
var _rows_box: VBoxContainer
var _row_labels: Array[Label] = []
var _hint: Label
var _feedback: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_build_ui()
	_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "DebugPartySelectorRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_MIN_WIDTH, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101b28")
	style.border_color = Color("62d8e7")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	_title = Label.new()
	_title.text = "TROCA DE PERSONAGEM"
	_title.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	_title.add_theme_color_override("font_color", Color("eae9d9"))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_title)

	_leader_label = Label.new()
	_leader_label.add_theme_font_size_override("font_size", 14)
	_leader_label.add_theme_color_override("font_color", Color("9cb4bb"))
	_leader_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_leader_label)

	var separator := HSeparator.new()
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(separator)

	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 4)
	_rows_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_rows_box)

	_feedback = Label.new()
	_feedback.text = ""
	_feedback.add_theme_font_size_override("font_size", 14)
	_feedback.add_theme_color_override("font_color", Color("ff8a72"))
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_feedback)

	_hint = Label.new()
	_hint.text = "Cima/Baixo ou 1-9: escolher   ·   Enter: trocar de lugar   ·   E/Esc: fechar"
	_hint.add_theme_font_size_override("font_size", FONT_SIZE_HINT)
	_hint.add_theme_color_override("font_color", Color("b5c3c2"))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hint)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var key := key_event.keycode
	if key == 0:
		key = key_event.physical_keycode

	if _open:
		if key == KEY_E or key_event.physical_keycode == KEY_E or key == KEY_ESCAPE:
			_close_selector()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_UP:
			_select(_selected - 1)
			get_viewport().set_input_as_handled()
			return
		if key == KEY_DOWN:
			_select(_selected + 1)
			get_viewport().set_input_as_handled()
			return
		if key >= KEY_1 and key <= KEY_9:
			_select(key - KEY_1)
			get_viewport().set_input_as_handled()
			return
		if key == KEY_ENTER or key == KEY_KP_ENTER:
			_confirm()
			get_viewport().set_input_as_handled()
			return
		# The list owns the keyboard while it is open; do not let a global menu
		# (X/C) open on top of it.
		get_viewport().set_input_as_handled()
		return

	if key == KEY_E or key_event.physical_keycode == KEY_E:
		if _can_open():
			_open_selector()
			get_viewport().set_input_as_handled()


## The scene can refuse E (lab talk/door, battle Fight page/pause, etc.).
func _can_open() -> bool:
	if get_tree().current_scene == null:
		return false
	if get_tree().paused:
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if gs.get("transition") != null and bool(gs.get("transition").active):
		return false
	var scene := get_tree().current_scene
	if scene.has_method("debug_party_selector_blocked"):
		return not bool(scene.call("debug_party_selector_blocked"))
	return true


func _open_selector() -> void:
	_members.clear()
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("debug_party_selector_entries"):
		var entries: Array = scene.call("debug_party_selector_entries")
		for entry in entries:
			if entry is Dictionary:
				_members.append(entry)
	else:
		var gs := get_node_or_null("/root/GameState")
		if gs != null:
			for member in gs.get("party"):
				if member == null:
					continue
				_members.append({
					"name": str(member.name),
					"species": str(member.species_id),
					"leader": _members.is_empty(),
				})
	_selected = clampi(_selected, 0, maxi(_members.size() - 1, 0))
	_open = true
	# The 2D map and the 3D lab read the same arrow keys used by this list, so the
	# game must not move while choosing. This is the allowed pause fallback; the
	# selector is PROCESS_MODE_ALWAYS and closing restores the previous state.
	_was_paused = get_tree().paused
	get_tree().paused = true
	_feedback.text = ""
	_refresh_title()
	_rebuild_rows()
	_root.visible = true


func _close_selector() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	get_tree().paused = _was_paused


func _exit_tree() -> void:
	if _open:
		get_tree().paused = _was_paused


func is_open() -> bool:
	return _open


func _refresh_title() -> void:
	var leader_name := "—"
	if not _members.is_empty():
		leader_name = str(_members[0].get("name", "—")).to_upper()
	_leader_label.text = "LÍDER ATUAL: %s   ·   %d controláveis" % [leader_name, _members.size()]


func _rebuild_rows() -> void:
	for child in _rows_box.get_children():
		_rows_box.remove_child(child)
		child.queue_free()
	_row_labels.clear()
	for i in _members.size():
		var label := Label.new()
		label.add_theme_font_size_override("font_size", FONT_SIZE_ROW)
		label.custom_minimum_size = Vector2(PANEL_MIN_WIDTH - 48.0, 28.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rows_box.add_child(label)
		_row_labels.append(label)
	_refresh_rows()


func _refresh_rows() -> void:
	for i in _row_labels.size():
		var member: Dictionary = _members[i]
		var name := str(member.get("name", "?")).to_upper()
		var species := str(member.get("species", ""))
		if species == "":
			species = name.to_lower()
		var role := "LÍDER" if bool(member.get("leader", i == 0)) else "ALIADO"
		var marker := "▶ " if i == _selected else "  "
		var row := _row_labels[i]
		row.text = "%s[%d] %s  (%s)   · %s" % [marker, i + 1, name, species, role]
		row.add_theme_color_override(
			"font_color", Color("d7fd6a") if i == _selected else Color("eae9d9"))


func _select(index: int) -> void:
	if _members.is_empty():
		return
	_selected = clampi(index, 0, _members.size() - 1)
	_feedback.text = ""
	_refresh_rows()


func _confirm() -> void:
	if _members.is_empty():
		return
	if _selected <= 0:
		_feedback.text = "Esse já é o líder."
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("debug_swap_party"):
		_feedback.text = "Esta cena não permite trocar o personagem."
		return
	var result: Variant = scene.call("debug_swap_party", _selected)
	var ok := true
	var message := ""
	if result is Dictionary:
		ok = bool(result.get("ok", true))
		message = str(result.get("message", ""))
	elif result is bool:
		ok = bool(result)
	if not ok:
		_feedback.text = message if message != "" else "Não foi possível trocar."
		return
	if message != "":
		print("[DebugPartySelector] ", message)
	var menus := get_node_or_null("/root/Menus")
	if menus != null and message != "":
		menus.call("toast", message, Color("d7fd6a"), 2.0)
	_close_selector()
