class_name AtbBar
extends Control
## Draws a combatant's ATB gauge as 5 blocks plus a burst marker.

const BLOCK_W := 22.0
const GAP := 3.0

var combatant: Combatant


func _init() -> void:
	custom_minimum_size = Vector2(5 * (BLOCK_W + GAP) + 20, 16)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if combatant == null:
		return
	for i in int(Combatant.BLOCKS):
		var rect := Rect2(i * (BLOCK_W + GAP), 2, BLOCK_W, 12)
		draw_rect(rect, Color(0.12, 0.12, 0.18))
		var fill := clampf(combatant.atb - i, 0.0, 1.0)
		if fill > 0.0:
			var color := Color(0.3, 0.9, 1.0) if fill >= 1.0 else Color(0.2, 0.4, 0.8)
			draw_rect(Rect2(rect.position, Vector2(BLOCK_W * fill, rect.size.y)), color)
	if combatant.burst > 0:
		draw_rect(Rect2(5 * (BLOCK_W + GAP) + 4, 2, 12, 12), Color(1.0, 0.8, 0.1))
