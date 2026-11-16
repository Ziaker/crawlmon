extends Control
## D-1229 (Phase 5): plain placeholder shown while an Employ attempt is open and the battle is
## frozen. It only marks where the dialogue, the rhythm minigame and the cutscenes of Phase 6 will
## go: no final text or look lives here. D-1240: confirm rolls the real chance; cancel forces a failure (debug).

signal decided(success: bool)  ## forced result (debug)
signal roll_requested  ## roll the real Employ chance

var _label: Label


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # The attempt pauses the tree.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.offset_top = 96.0
	add_child(_label)
	hide()


func open(actor_name: String, target_name: String) -> void:
	_label.text = "EMPLOY: %s > %s\n[PLACEHOLDER] CONFIRM = ROLL THE CHANCE / CANCEL = FORCE FAILURE" % [actor_name, target_name]
	show()


func close() -> void:
	hide()


func text() -> String:
	return _label.text


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		roll_requested.emit()
	elif event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		decided.emit(false)
