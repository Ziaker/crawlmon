extends Node
## D-389 lab: DQT Orc 3D atrás do Pancham no overworld real.
## O jogo normal não spawna este seguidor; abra esta cena com F6 para testar.

const EXPLORATION := preload("res://scenes/exploration.tscn")
const Follower3D := preload("res://scripts/dungeon/dungeon_follower_3d.gd")

var exploration: Node
var orc: Node2D


func _ready() -> void:
	var weather_script = load("res://scripts/dungeon/weather_controller.gd")
	weather_script.debug_disable = true
	exploration = EXPLORATION.instantiate()
	add_child(exploration)
	await get_tree().process_frame

	var leader: Node2D = exploration.player
	if not exploration.followers.is_empty():
		leader = exploration.followers[0]

	orc = Follower3D.new()
	orc.setup("dqt_orc", leader)
	orc.position = leader.position + Vector2(0, 32)
	exploration.entities.add_child(orc)

	_add_overlay()


func _add_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	var label := Label.new()
	label.text = "DQT Orc — lab do overworld\nSetas para andar; o Orc segue o Pancham (gap 32, 180 px/s)."
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	add_child(layer)
