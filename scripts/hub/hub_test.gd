extends Node2D
## Isolated 48 px hub test. No services, no combat, no new VFX.
## The background is the Time/Darkness Treasure Town sheet, cropped and with
## its white border removed. Player and NPCs use the same scripts as the
## exploration, so the scale can be judged in the real engine.

const BACKGROUND := preload("res://assets/pmd/hub/treasure_town.png")
const PLAYER_SCRIPT = preload("res://scripts/dungeon/player.gd")
const NPC_SCRIPT = preload("res://scripts/dungeon/npc.gd")
const DIALOGUE_SCRIPT = preload("res://scripts/ui/dialogue_box.gd")

const BG_RECT := Rect2(0, 0, 1157, 465)
const PLAYER_START := Vector2(720, 280)
const NPC_DATA := [
	{"cell": Vector2(555, 185), "id": "bulbasaur", "name": "Bulbasaur", "line": "Bem-vindo à base. Ainda é um teste, mas o portão já está de pé."},
	{"cell": Vector2(720, 240), "id": "charmander", "name": "Charmander", "line": "Quando as lojas e a equipe entrarem, este lugar vai ficar bem mais movimentado."},
]

var player: CharacterBody2D
var dialogue_box: CanvasLayer
var npcs: Array[Node2D] = []


func _ready() -> void:
	_build_background()
	_build_collisions()
	_build_player()
	_build_dialogue()
	_build_npcs()
	_build_hud()
	_fit_camera()


func _build_background() -> void:
	var clear := ColorRect.new()
	clear.color = Color("22301f")
	clear.position = BG_RECT.position
	clear.size = BG_RECT.size
	add_child(clear)

	var bg := Sprite2D.new()
	bg.texture = BACKGROUND
	bg.centered = false
	bg.region_enabled = true
	bg.region_rect = BG_RECT
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bg)


func _block(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _build_collisions() -> void:
	# Boundary of the cropped town sheet.
	_block(Rect2(0, 0, BG_RECT.size.x, 20))
	_block(Rect2(0, BG_RECT.size.y - 20, BG_RECT.size.x, 20))
	_block(Rect2(0, 0, 20, BG_RECT.size.y))
	_block(Rect2(BG_RECT.size.x - 20, 0, 20, BG_RECT.size.y))

	# Main buildings. Approximate rectangles from the sheet; refine after the
	# first playtest.
	_block(Rect2(95, 40, 200, 170))    # guild
	_block(Rect2(290, 45, 140, 120))   # green shop
	_block(Rect2(600, 45, 150, 120))   # yellow building
	_block(Rect2(950, 45, 150, 120))   # gray building
	_block(Rect2(715, 300, 110, 90))   # pink cafe
	_block(Rect2(930, 295, 170, 140))  # red/white building
	_block(Rect2(930, 180, 170, 60))   # training dummies

	# River, leaving the bridge gap at y 140..200; the lower waterfall is a
	# rough block for the test.
	_block(Rect2(500, 0, 60, 140))
	_block(Rect2(500, 200, 60, 100))
	_block(Rect2(560, 280, 140, 90))
	_block(Rect2(600, 330, 100, 135))


func _build_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(PLAYER_SCRIPT)
	player.position = PLAYER_START
	add_child(player)


func _build_dialogue() -> void:
	dialogue_box = DIALOGUE_SCRIPT.new()
	add_child(dialogue_box)


func _build_npcs() -> void:
	for data in NPC_DATA:
		var npc = NPC_SCRIPT.new()
		npc.position = data["cell"]
		npc.setup({"id": data["id"], "name": data["name"]}, data["line"], dialogue_box, player)
		add_child(npc)
		npcs.append(npc)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "HUB TEST — 48 px — setas/WASD — Z falar — ESC voltar"
	label.position = Vector2(12, 8)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	layer.add_child(label)


func _fit_camera() -> void:
	var cam: Camera2D = null
	for child in player.get_children():
		if child is Camera2D:
			cam = child
			break
	if cam == null:
		return
	# The town sheet is native-resolution pixel art; use an integer 2× test
	# camera so it stays crisp at 48 px. The dungeon camera uses 2.3× (D-344).
	cam.zoom = Vector2(2.0, 2.0)
	cam.limit_left = int(BG_RECT.position.x)
	cam.limit_top = int(BG_RECT.position.y)
	cam.limit_right = int(BG_RECT.end.x)
	cam.limit_bottom = int(BG_RECT.end.y)
	cam.reset_smoothing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file.call_deferred("res://scenes/exploration.tscn")
