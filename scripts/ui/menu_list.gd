class_name MenuList
extends VBoxContainer
## Vertical list driven by the game's buttons: arrows move, Z (confirm) picks,
## X (menu) cancels, left/right emit `side`. Entries are Strings or
## {"text": String, "enabled": bool}.

signal chosen(index: int)
signal cancelled
signal moved(index: int)
signal side(direction: int)

var index := 0

var _texts: Array[String] = []
var _enabled: Array[bool] = []
var _labels: Array[Label] = []


func set_entries(entries: Array, keep_index := false) -> void:
	for l in _labels:
		remove_child(l)
		l.queue_free()
	_labels.clear()
	_texts.clear()
	_enabled.clear()
	for e in entries:
		var label := Label.new()
		add_child(label)
		_labels.append(label)
		if e is Dictionary:
			_texts.append(e["text"])
			_enabled.append(e.get("enabled", true))
		else:
			_texts.append(str(e))
			_enabled.append(true)
	index = clampi(index if keep_index else 0, 0, maxi(_texts.size() - 1, 0))
	_redraw()
	moved.emit(index)


func set_enabled(i: int, value: bool) -> void:
	if i < _enabled.size() and _enabled[i] != value:
		_enabled[i] = value
		_redraw()


func _redraw() -> void:
	for i in _labels.size():
		_labels[i].text = ("> " if i == index else "   ") + _texts[i]
		if not _enabled[i]:
			_labels[i].modulate = Color(1, 1, 1, 0.4)
		else:
			_labels[i].modulate = Color(1, 0.9, 0.3) if i == index else Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("menu"):
		cancelled.emit()
	elif _texts.is_empty():
		return
	elif event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_left"):
		side.emit(-1)
	elif event.is_action_pressed("ui_right"):
		side.emit(1)
	elif event.is_action_pressed("confirm"):
		if _enabled[index]:
			chosen.emit(index)
	else:
		return
	get_viewport().set_input_as_handled()


func _move(step: int) -> void:
	index = posmod(index + step, _texts.size())
	_redraw()
	moved.emit(index)
