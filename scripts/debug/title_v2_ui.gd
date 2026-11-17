class_name TitleV2Ui
extends Control
## Debug wrapper around the shared v2 2D layer (PreGameTitleV2Draw): title + plates + hint.

const Draw = preload("res://scripts/ui/pre_game/pre_game_title_v2_draw.gd")

var t: float = 0.0
var menu_index: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	Draw.draw_backdrop_gradient(self, size)
	Draw.draw_title(self, size, t)
	Draw.draw_plates(self, size, t - 0.7, menu_index, func(_id: String, _xf: Transform2D, _sz: Vector2) -> void: pass)
	Draw.draw_enter_hint(self, size, t, false)
	PreGameDraw.draw_top_edge_rail(self, size.x)


const PreGameDraw = preload("res://scripts/ui/pre_game/pre_game_draw.gd")
