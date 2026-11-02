extends CharacterBody2D
## Top-down player. Built in code by exploration.gd.

const SPEED := 180.0

var can_move := true
var _sprite: Sprite2D
var _last_dir := "down"
var _anim_timer := 0.0
var _anim_frame := 1


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	
	var cam := Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)
	
	# Sprite do protagonista (Pikachu ou fallback gráfico)
	if ResourceLoader.exists("res://personagens/overworld/down/pikachu.png"):
		_sprite = Sprite2D.new()
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.scale = Vector2(1.2, 1.2)
		_sprite.texture = load("res://personagens/overworld/down/pikachu.png")
		add_child(_sprite)


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return
		
	var input_vec := _cardinal_input()
	velocity = input_vec * SPEED
	move_and_slide()
	
	if _sprite:
		_update_animation(input_vec, delta)


## The GDD locks exploration to the four cardinal directions (no diagonals).
## When two axes are held, the stronger one wins; on a tie, horizontal wins.
func _cardinal_input() -> Vector2:
	var x := Input.get_axis("ui_left", "ui_right")
	var y := Input.get_axis("ui_up", "ui_down")
	if absf(x) >= absf(y):
		return Vector2(signf(x), 0.0)
	return Vector2(0.0, signf(y))


func _update_animation(input_vec: Vector2, delta: float) -> void:
	if input_vec.length_squared() > 0.01:
		if abs(input_vec.x) > abs(input_vec.y):
			_last_dir = "right" if input_vec.x > 0 else "left"
		else:
			_last_dir = "down" if input_vec.y > 0 else "up"
			
		_anim_timer += delta
		if _anim_timer >= 0.2:
			_anim_timer = 0.0
			_anim_frame = 2 if _anim_frame == 1 else 1
	else:
		_anim_timer = 0.0
		_anim_frame = 1
		
	var frame_suffix := "frame2/" if _anim_frame == 2 else ""
	var path := "res://personagens/overworld/%s/%s%s.png" % [_last_dir, frame_suffix, "pikachu"]
	if ResourceLoader.exists(path):
		_sprite.texture = load(path)


func _draw() -> void:
	if _sprite == null:
		draw_circle(Vector2.ZERO, 14.0, Color(0.3, 0.8, 0.4))
