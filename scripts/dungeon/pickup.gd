class_name DungeonPickup
extends Node2D
## Poção coletável no mapa 2D (D-033).
##
## Fica no chão flutuando com um brilho suave e é recolhida automaticamente
## quando o jogador encosta. A exploração decide o que fazer com a coleta (somar
## ao inventário e registrar no GameState), então este nó só avisa.

signal collected(pickup)
signal blocked(pickup)  ## QoL: the player is on it, but the inventory is full.

const ITEM_ID := "potion"
const PICKUP_RADIUS := 24.0

var id := ""
var _player: Node2D
var _icon: Texture2D
var _time := 0.0
var _taken := false
var _blocked_near := false  ## Already warned while standing on it with a full bag.


func setup(p_id: String, player: Node2D) -> void:
	id = p_id
	_player = player
	_icon = Item.icon_of(ITEM_ID)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Desencontra a flutuação entre itens do mesmo andar.
	_time = float(absi(hash(id)) % 1000) * 0.01


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	queue_redraw()
	if _player != null and position.distance_to(_player.position) <= PICKUP_RADIUS:
		# R35-Q3: a full non-held inventory blocks the pickup; the item stays on
		# the floor and can be collected after the player frees a slot.
		if GameState.is_inventory_full():
			if not _blocked_near:  # One toast per approach, not every frame.
				_blocked_near = true
				blocked.emit(self)
			return
		_taken = true
		collected.emit(self)
		queue_free()
	else:
		_blocked_near = false


func _draw() -> void:
	var bob := sin(_time * 2.4) * 3.0
	_blob(Vector2(0, 14), 11.0, 4.0)
	var pulse := 0.5 + 0.5 * sin(_time * 2.4)
	draw_circle(Vector2(0, bob), 18.0, Color(1.0, 0.82, 0.32, 0.10 + 0.05 * pulse))
	draw_arc(Vector2(0, bob), 17.0, 0.0, TAU, 28, Color(1.0, 0.86, 0.38, 0.35 + 0.25 * pulse), 2.0)
	if _icon != null:
		draw_texture_rect(_icon, Rect2(Vector2(-15, -20 + bob), Vector2(30, 30)), false)
	else:
		# Fallback procedural: frasco simples.
		draw_rect(Rect2(Vector2(-7, -6 + bob), Vector2(14, 16)), Color(0.85, 0.2, 0.25))
		draw_rect(Rect2(Vector2(-4, -13 + bob), Vector2(8, 8)), Color(0.9, 0.9, 0.95))


func _blob(pos: Vector2, rx: float, ry: float) -> void:
	draw_set_transform(pos, 0.0, Vector2(rx, ry))
	draw_circle(Vector2.ZERO, 1.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
