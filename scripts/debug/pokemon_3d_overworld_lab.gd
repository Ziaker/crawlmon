extends Node
## D-991 lab: troca os sprites de Abra, Pancham e do Orc pelos modelos 3D.
## O jogo normal continua com os sprites; esta cena é só para testar.
##
## Abra no jogador, Pancham no seguidor e o Orc atrás dele. O Orc usa a mesma
## lógica de rastro 2D de D-314/D-361/D-388, mas com o visual 3D; ele não entra
## em `followers`.

const EXPLORATION := preload("res://scenes/exploration.tscn")
const FOLLOWER := preload("res://scripts/dungeon/follower.gd")
const FOLLOWER_3D := preload("res://scripts/dungeon/dungeon_follower_3d.gd")
const VIEW := preload("res://scripts/debug/dungeon_model_3d_view.gd")

const PIXEL_HEIGHT := {"abra": 25.0, "pancham": 24.0, "dqt_orc": 30.0}

var exploration: Node
var orc: Node2D
var views: Array[Node] = []


func _ready() -> void:
	var weather_script = load("res://scripts/dungeon/weather_controller.gd")
	weather_script.debug_disable = true
	# O laboratório cria o próprio Orc, então a exploração não deve criar outro.
	FOLLOWER_3D.enabled = false

	exploration = EXPLORATION.instantiate()
	add_child(exploration)

	var leader: Node2D = exploration.player
	if not exploration.followers.is_empty():
		leader = exploration.followers[-1]
	orc = FOLLOWER.new()
	orc.setup("dqt_orc", leader)
	orc.position = exploration._follower_spawn(leader.position)
	exploration.entities.add_child(orc)

	_attach(exploration.player, "abra")
	for follower in exploration.followers:
		_attach(follower, str(follower.species_id))
	_attach(orc, "dqt_orc")

	_add_overlay()


func _attach(target: Node2D, model_id: String) -> void:
	var view = VIEW.new()
	view.setup(model_id, float(PIXEL_HEIGHT.get(model_id, 32.0)))
	target.add_child(view)
	views.append(view)


func _add_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	var label := Label.new()
	label.text = "Modelos 3D - estilo: %s\nSetas para andar; Abra, Pancham e Orc em 3D." % VIEW.current_style
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	add_child(layer)
