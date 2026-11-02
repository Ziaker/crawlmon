class_name DungeonNPC
extends StaticBody2D
## NPC no mapa de exploração com sprite overworld animado e diálogo.
## Usa o retrato autêntico de Pokémon Mystery Dungeon (PMDCollab) na caixa de texto.

const NPCData = preload("res://scripts/dungeon/npc_data.gd")
const DialogueBoxScript = preload("res://scripts/ui/dialogue_box.gd")

var pokemon_name: String
var pokemon_id: String
var dialogue: String
var dialogue_box: CanvasLayer
var player: CharacterBody2D

var _sprite: Sprite2D
var _prompt: PanelContainer
var _tex_frame1: Texture2D
var _tex_frame2: Texture2D
var _pmd_portrait: Texture2D
var _anim_timer := 0.0
var _current_frame := 1
var _is_player_near := false


func setup(data: Dictionary, chosen_dialogue: String, box: CanvasLayer, p: CharacterBody2D) -> void:
	pokemon_id = data.get("id", "bulbasaur")
	pokemon_name = data.get("name", "Bulbasaur")
	dialogue = chosen_dialogue
	dialogue_box = box
	player = p
	_load_assets()


func _load_assets() -> void:
	var path_f1 := NPCData.get_sprite_path(pokemon_id, 1)
	var path_f2 := NPCData.get_sprite_path(pokemon_id, 2)
	var path_portrait := NPCData.get_pmd_portrait_path(pokemon_id)
	
	if ResourceLoader.exists(path_f1):
		_tex_frame1 = load(path_f1)
	if ResourceLoader.exists(path_f2):
		_tex_frame2 = load(path_f2)
	else:
		_tex_frame2 = _tex_frame1
		
	# Retrato de Mystery Dungeon (40x40 emotion portrait)
	if ResourceLoader.exists(path_portrait):
		_pmd_portrait = load(path_portrait)
	else:
		_pmd_portrait = _tex_frame1


func _ready() -> void:
	# Colisão física do NPC
	var col_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(28.0, 28.0)
	col_shape.shape = rect_shape
	add_child(col_shape)
	
	# Sprite do Overworld
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = _tex_frame1
	_sprite.scale = Vector2(1.2, 1.2)
	add_child(_sprite)
	
	# Área de Interação
	var area := Area2D.new()
	var area_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36.0
	area_shape.shape = circle
	area.add_child(area_shape)
	area.body_entered.connect(_on_area_entered)
	area.body_exited.connect(_on_area_exited)
	add_child(area)
	
	# Prompt flutuante estilo tático "[Z] FALAR"
	_prompt = PanelContainer.new()
	_prompt.position = Vector2(-34, -40)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.04, 0.08, 0.14, 0.94)
	p_style.border_color = Color(0.84, 0.99, 0.42, 0.90)  # Lime #d7fd6a
	p_style.set_border_width_all(1)
	p_style.set_corner_radius_all(4)
	p_style.content_margin_left = 7.0
	p_style.content_margin_right = 7.0
	p_style.content_margin_top = 2.0
	p_style.content_margin_bottom = 2.0
	p_style.shadow_color = Color(0, 0, 0, 0.6)
	p_style.shadow_size = 4
	_prompt.add_theme_stylebox_override("panel", p_style)
	
	var label := Label.new()
	label.text = "[Z] FALAR"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.84, 0.99, 0.42))
	_prompt.add_child(label)
	_prompt.visible = false
	add_child(_prompt)


func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 0.55:
		_anim_timer = 0.0
		_current_frame = 2 if _current_frame == 1 else 1
		_sprite.texture = _tex_frame2 if (_current_frame == 2 and _tex_frame2) else _tex_frame1


func _unhandled_input(event: InputEvent) -> void:
	if not _is_player_near:
		return
	if dialogue_box and "is_open" in dialogue_box and dialogue_box.is_open:
		return
		
	if event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_interact()


func _interact() -> void:
	if dialogue_box == null:
		return
		
	if player and "can_move" in player:
		player.can_move = false
		
	_prompt.visible = false
	dialogue_box.show_dialogue(
		pokemon_name,
		_pmd_portrait,
		dialogue,
		func() -> void:
			if player and "can_move" in player:
				player.can_move = true
			if _is_player_near:
				_prompt.visible = true
	)


func _on_area_entered(body: Node2D) -> void:
	if body == player:
		_is_player_near = true
		if dialogue_box and "is_open" in dialogue_box and not dialogue_box.is_open:
			_prompt.visible = true


func _on_area_exited(body: Node2D) -> void:
	if body == player:
		_is_player_near = false
		_prompt.visible = false
