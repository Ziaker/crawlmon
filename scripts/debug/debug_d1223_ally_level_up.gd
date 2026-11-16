extends SceneTree
## Debug visual interativo para D-1223 / D-1224:
## 0) Tela de Level Up do Líder Abra (Lv. 1 -> 2, pontos manuais).
## 1) Tela de Level Up do aliado Pancham (Lv. 1 -> 2, 1 ponto automático).
## 2) Marco de nível 10 do aliado Gible (Lv. 9 -> 10, 3 pontos em sequência).
## Atalhos: [R] Reexecuta a entrada/animações da etapa atual | [1][2][3] Troca etapa | [ESC] Sai.

class _KeyHook extends Node:
	signal action(id: int)
	func _input(event: InputEvent) -> void:
		if not (event is InputEventKey):
			return
		var ek := event as InputEventKey
		if not ek.pressed or ek.echo:
			return
		match ek.keycode:
			KEY_R:
				get_viewport().set_input_as_handled()
				action.emit(-1)
			KEY_1:
				get_viewport().set_input_as_handled()
				action.emit(0)
			KEY_2:
				get_viewport().set_input_as_handled()
				action.emit(1)
			KEY_3:
				get_viewport().set_input_as_handled()
				action.emit(2)
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				action.emit(-2)

var _stage := 0
var _screen: PostCombatScreen
var _hook: _KeyHook


func _init() -> void:
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_move_to_foreground()
	_hook = _KeyHook.new()
	_hook.action.connect(func(id: int) -> void:
		if id == -2:
			quit(0)
		elif id == -1:
			call_deferred("_open_stage", _stage)
		else:
			call_deferred("_open_stage", id))
	root.call_deferred("add_child", _hook)
	call_deferred("_open_stage", 0)


func _open_stage(stage: int) -> void:
	_stage = clampi(stage, 0, 2)
	if is_instance_valid(_screen):
		_screen.queue_free()
	var leader := CharacterFactory.create("abra", {"forced_nature": "modest"})
	leader.is_player = true
	leader.level = 1
	leader.xp = 0
	leader.update_resource_maximums()

	var ally: Combatant
	var xp_gain: int
	var step_idx := 1
	if _stage == 0:
		ally = CharacterFactory.create("pancham", {"forced_nature": "brave"})
		ally.is_player = false
		ally.level = 1
		ally.xp = 0
		ally.update_resource_maximums()
		xp_gain = CrawlmonAttributeMath.get_xp_for_level_transition(1)
		step_idx = 0
	elif _stage == 1:
		ally = CharacterFactory.create("pancham", {"forced_nature": "brave"})
		ally.is_player = false
		ally.level = 1
		ally.xp = 0
		ally.proficiency_points = {"STR": 9, "MAG": 0, "VIT": 3, "WIS": 0, "AGI": 0, "LUK": 0}
		ally.update_resource_maximums()
		xp_gain = CrawlmonAttributeMath.get_xp_for_level_transition(1)
	else:
		ally = CharacterFactory.create("gible", {"forced_nature": "hardy"})
		ally.is_player = false
		ally.level = 9
		ally.xp = 0
		ally.proficiency_points = {"STR": 6, "MAG": 0, "VIT": 4, "WIS": 0, "AGI": 4, "LUK": 0}
		ally.update_resource_maximums()
		xp_gain = CrawlmonAttributeMath.get_xp_for_level_transition(9)

	if root.has_node("GameState"):
		var party_arr: Array[Combatant] = [leader, ally]
		root.get_node("GameState").set("party", party_arr)

	var sums := PostCombatFlow.grant_xp([leader, ally], xp_gain)
	var steps: Array[Dictionary] = [{"kind": "lv", "index": step_idx}]
	_screen = PostCombatScreen.new()
	root.add_child(_screen)
	_screen.open(xp_gain, sums, steps)
	_screen.finished.connect(func() -> void:
		if _stage < 2:
			call_deferred("_open_stage", _stage + 1)
		else:
			quit(0)
	)
