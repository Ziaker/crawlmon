extends CanvasLayer
## Overlay menus (autoload). X: items / status / held items (map only).
## C: settings (map and battle). Pauses the tree while open.

enum Mode { NONE, TABS, PICK, SETTINGS }

const TABS := ["Itens", "Status", "Segurar"]

var mode := Mode.NONE
var tab := 0

var _root: Control
var _title: Label
var _list: MenuList
var _detail: Label
var _pick_action: Callable
var _shown_items: Array[Item] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.position = Vector2(200, 100)
	box.custom_minimum_size = Vector2(880, 0)
	_root.add_child(box)
	_title = Label.new()
	box.add_child(_title)
	_list = MenuList.new()
	box.add_child(_list)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(880, 0)
	box.add_child(_detail)
	_list.chosen.connect(_on_chosen)
	_list.cancelled.connect(_on_cancelled)
	_list.moved.connect(_on_moved)
	_list.side.connect(_on_side)


func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.NONE:
		if event.is_action_pressed("menu") and not GameState.in_battle:
			_open(Mode.TABS)
			_build_tab()
		elif event.is_action_pressed("settings"):
			_open(Mode.SETTINGS)
			_build_settings(false)
		else:
			return
	elif mode == Mode.SETTINGS and event.is_action_pressed("settings"):
		_close()
	else:
		return
	get_viewport().set_input_as_handled()


func _open(new_mode: Mode) -> void:
	mode = new_mode
	get_tree().paused = true
	_root.visible = true


func _close() -> void:
	mode = Mode.NONE
	_root.visible = false
	get_tree().paused = false


# --- Tabs: Itens / Status / Segurar ----------------------------------------

func _build_tab() -> void:
	mode = Mode.TABS
	var names := PackedStringArray()
	for i in TABS.size():
		names.append("[%s]" % TABS[i] if i == tab else TABS[i])
	_title.text = "  ".join(names) + "      (←/→ troca aba, Z escolhe, X fecha)"
	var entries: Array = []
	_shown_items.clear()
	match tab:
		0:
			_shown_items.assign(GameState.items_of_kind(Item.Kind.CONSUMABLE))
			for item in _shown_items:
				entries.append("%s x%d" % [item.display_name, GameState.item_count(item.id)])
			if entries.is_empty():
				entries.append({"text": "(vazio)", "enabled": false})
		1:
			for c in GameState.party:
				entries.append(c.name)
		2:
			_shown_items.assign(GameState.items_of_kind(Item.Kind.HELD))
			entries.append("Remover item")
			for item in _shown_items:
				entries.append("%s x%d" % [item.display_name, GameState.item_count(item.id)])
	_list.set_entries(entries)


func _build_pick() -> void:
	mode = Mode.PICK
	_title.text = "Escolha o personagem  (X volta)"
	var entries: Array = []
	for c in GameState.party:
		var held := c.get_held_item()
		entries.append("%s   HP %d/%d   [%s]" % [c.name, c.hp, c.max_hp, held.display_name if held else "-"])
	_list.set_entries(entries)


func _pick(action: Callable) -> void:
	_pick_action = action
	_build_pick()


func _use_consumable(item: Item, c: Combatant) -> void:
	if c.hp < c.max_hp and GameState.item_count(item.id) > 0:
		c.heal(item.heal)
		GameState.remove_item(item.id)


func _equip(c: Combatant, id: String) -> void:
	var old := c.held_item_id
	if id != "":
		GameState.remove_item(id)
	if old != "":
		GameState.add_item(old)
	c.held_item_id = id


func _status_text(c: Combatant) -> String:
	var held := c.get_held_item()
	var skill_names := PackedStringArray()
	for s in c.skills:
		skill_names.append(s.display_name)
	return "%s\nHP %d/%d    Ataque %d    ATB %.2f blocos/s\nItem: %s\nHabilidades: %s" % [
		c.name, c.hp, c.max_hp, c.attack, c.speed,
		held.display_name if held else "-", ", ".join(skill_names)]


# --- Settings --------------------------------------------------------------

func _build_settings(_keep_index: bool) -> void:
	mode = Mode.SETTINGS
	_title.text = "Configurações  (X ou C fecha)"
	_list.set_entries([{"text": "(vazio)", "enabled": false}])


# --- Signals ---------------------------------------------------------------

func _on_chosen(i: int) -> void:
	match mode:
		Mode.TABS:
			if tab == 0 and not _shown_items.is_empty():
				var item := _shown_items[i]
				_pick(func(c: Combatant) -> void: _use_consumable(item, c))
			elif tab == 2:
				var id := "" if i == 0 else _shown_items[i - 1].id
				_pick(func(c: Combatant) -> void: _equip(c, id))
		Mode.PICK:
			_pick_action.call(GameState.party[i])
			_build_tab()


func _on_cancelled() -> void:
	if mode == Mode.PICK:
		_build_tab()
	else:
		_close()


func _on_side(direction: int) -> void:
	if mode == Mode.TABS:
		tab = posmod(tab + direction, TABS.size())
		_build_tab()


func _on_moved(i: int) -> void:
	_detail.text = ""
	if mode != Mode.TABS:
		return
	match tab:
		0:
			if i < _shown_items.size():
				_detail.text = _shown_items[i].description
		1:
			_detail.text = _status_text(GameState.party[i])
		2:
			if i > 0 and i - 1 < _shown_items.size():
				_detail.text = _shown_items[i - 1].description
