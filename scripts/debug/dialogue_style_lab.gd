extends Node
## D-1087: laboratório dos 3 HUDs de diálogo.
## Uso:
##   godot --path . --fixed-fps 30 --resolution 1280x720 \
##     scenes/debug/dialogue_style_lab.tscn -- --style=A --record
## Saída: frames_dialogue_A/f_0000.png ... (7 s a 30 fps).

const HUD := preload("res://scripts/debug/dialogue_hud_styles.gd")
const NPC_DATA := preload("res://scripts/dungeon/npc_data.gd")

@export var lab_scene: PackedScene

var _style := 0
var _record := false
var _out := "res://frames_dialogue_A"
var _lab: Node3D
var _hud: Control
var _frame := 0
var _rec_frame := -1
var _opened := false
var _line := ""


func _ready() -> void:
	var win := get_window()
	win.unfocusable = true
	win.position = Vector2i(-4000, 0)
	for arg in OS.get_cmdline_user_args():
		var a := str(arg).to_lower()
		if a.begins_with("--style="):
			match a.substr(8):
				"b":
					_style = 1
				"c":
					_style = 2
				_:
					_style = 0
		elif a == "--record":
			_record = true
		elif a.begins_with("--out="):
			_out = "res://" + str(arg).substr(6)
	_line = str(NPC_DATA.DIALOGUES[0])
	if lab_scene == null:
		print("DIALOGUE LAB: missing lab_scene")
		get_tree().quit()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_lab = lab_scene.instantiate() as Node3D
	_lab.start_party = true
	add_child(_lab)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var battle_hud := _lab.get_node_or_null("ExplorationBattleHud")
	if battle_hud != null:
		battle_hud.set_process(false)
		for entry in battle_hud.get("_cards"):
			var card := entry["control"] as Control
			if card != null:
				card.visible = false
	if _lab._npc_dialogue_panel != null:
		_lab._npc_dialogue_panel.visible = false
	if _lab._npc_prompt != null:
		_lab._npc_prompt.hide_prompt()
	_lab.player.global_position = Vector3(-1.2, 0.0, -2.6)
	var yaw := atan2(-1.4, -1.6)
	_lab.player_yaw = yaw
	_lab._cam_yaw = yaw
	for i in 60:
		await get_tree().physics_frame
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_hud = HUD.new()
	layer.add_child(_hud)
	_hud.setup(_style)
	if _record:
		_rec_frame = 0
	else:
		_open_hud()


func _open_hud() -> void:
	if _opened or _hud == null:
		return
	_opened = true
	_hud.open("BULBASAUR", _line)


func _process(_delta: float) -> void:
	# O lab não deve abrir o painel antigo nem o prompt enquanto o protótipo roda.
	if _lab != null:
		if _lab._npc_dialogue_panel != null:
			_lab._npc_dialogue_panel.visible = false
		if _lab._npc_prompt != null:
			_lab._npc_prompt.hide_prompt()
	_frame += 1
	if _rec_frame >= 0:
		if not _opened:
			_open_hud()
		var img := get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("%s/f_%04d.png" % [_out, _rec_frame])
		_rec_frame += 1
		if _rec_frame >= 210:
			print("DIALOGUE LAB DONE style=", _style, " frames=", _rec_frame)
			get_tree().quit()
	elif _frame > 330:
		get_tree().quit()
