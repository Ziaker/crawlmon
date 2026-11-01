extends CharacterBody2D
## Top-down player. Built in code by exploration.gd.

const SPEED := 180.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	var cam := Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
	add_child(cam)


func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
	move_and_slide()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.3, 0.8, 0.4))
