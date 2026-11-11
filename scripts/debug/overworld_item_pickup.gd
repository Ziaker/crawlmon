extends Node3D
## D-1143: item coletável no overworld 3D. Flutua, gira e entra no inventário
## quando o jogador chega perto; se a mochila estiver cheia, fica no chão.

signal collected(item_id: String)

const PICKUP_RADIUS := 1.25

var item_id := ""
var player: Node3D

var _sprite: Sprite3D
var _base_y := 0.0
var _time := 0.0
var _taken := false


func setup(p_item_id: String, p_player: Node3D) -> void:
	item_id = p_item_id
	player = p_player
	_base_y = position.y


func _ready() -> void:
	add_to_group("overworld_item")
	var texture := Item.icon_of(item_id)
	if texture != null:
		_sprite = Sprite3D.new()
		_sprite.texture = texture
		_sprite.pixel_size = 0.009
		_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_sprite.shaded = false
		_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(_sprite)
	else:
		var label := Label3D.new()
		label.text = item_id.to_upper()
		label.font_size = 42
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(1.0, 0.86, 0.42)
		add_child(label)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	position.y = _base_y + sin(_time * 2.4) * 0.07
	rotation.y += delta * 1.2
	if player == null or not is_instance_valid(player):
		return
	var flat := player.global_position - global_position
	flat.y = 0.0
	if flat.length() > PICKUP_RADIUS:
		return
	if not GameState.add_item(item_id):
		return
	_taken = true
	collected.emit(item_id)
	queue_free()
