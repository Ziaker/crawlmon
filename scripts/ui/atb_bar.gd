class_name AtbBar
extends Control
## Draws a combatant's ATB gauge as 5 blocks plus an animated burst marker.

const BLOCK_W := 22.0
const GAP := 3.0

var combatant: Combatant

var _prev_atb := 0.0
var _prev_burst := 0
var _block_is_full: Array[bool] = [false, false, false, false, false]
var _block_fill_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var _extra_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var _burst_flash := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(5 * (BLOCK_W + GAP) + 24, 16)


func _process(delta: float) -> void:
	if combatant != null:
		var cur_atb := combatant.atb
		var cur_burst := combatant.burst
		if cur_atb - _prev_atb >= 0.7:
			var s := clampi(int(floor(_prev_atb)), 0, 4)
			var e := clampi(int(floor(cur_atb)), 0, 4)
			for b in range(s, e + 1):
				_extra_flash[b] = 1.0
		for i in 5:
			if cur_atb >= float(i + 1):
				if not _block_is_full[i]:
					_block_is_full[i] = true
					_block_fill_flash[i] = 1.0
			else:
				_block_is_full[i] = false
		if cur_burst > _prev_burst:
			_burst_flash = 1.0
		_prev_atb = cur_atb
		_prev_burst = cur_burst
		for i in 5:
			if _block_fill_flash[i] > 0.0:
				_block_fill_flash[i] = maxf(_block_fill_flash[i] - delta * 3.2, 0.0)
			if _extra_flash[i] > 0.0:
				_extra_flash[i] = maxf(_extra_flash[i] - delta * 2.2, 0.0)
		if _burst_flash > 0.0:
			_burst_flash = maxf(_burst_flash - delta * 2.5, 0.0)
	queue_redraw()


func _draw() -> void:
	if combatant == null:
		return
	var now := Time.get_ticks_msec()
	for i in int(Combatant.BLOCKS):
		var rect := Rect2(i * (BLOCK_W + GAP), 2, BLOCK_W, 12)
		draw_rect(rect, Color(0.12, 0.12, 0.18))
		var fill := clampf(combatant.atb - i, 0.0, 1.0)
		if fill > 0.0:
			var color := Color(0.3, 0.9, 1.0) if fill >= 1.0 else Color(0.2, 0.4, 0.8)
			if fill >= 1.0:
				var pulse := 0.5 + 0.5 * sin(now * 0.007 + i * 1.3)
				color = color.lightened(pulse * 0.15)
			draw_rect(Rect2(rect.position, Vector2(BLOCK_W * fill, rect.size.y)), color)
			if fill < 1.0:
				var edge_x := rect.position.x + BLOCK_W * fill
				draw_line(Vector2(edge_x, rect.position.y), Vector2(edge_x, rect.end.y), Color.WHITE, 1.5)
		if _extra_flash[i] > 0.0:
			draw_rect(rect, Color(1.0, 0.85, 0.2, _extra_flash[i] * 0.8))
		if _block_fill_flash[i] > 0.0:
			draw_rect(rect, Color(1, 1, 1, _block_fill_flash[i] * 0.85))

	var b_slot := Rect2(5 * (BLOCK_W + GAP) + 4, 2, 14, 12)
	if combatant.burst > 0:
		var bp := 0.5 + 0.5 * sin(now * 0.01)
		draw_rect(Rect2(b_slot.position - Vector2(1, 1), b_slot.size + Vector2(2, 2)), Color(1.0, 0.8, 0.1, 0.3 + bp * 0.3))
		draw_rect(b_slot, Color(1.0, 0.8, 0.1))
	else:
		draw_rect(b_slot, Color(0.1, 0.12, 0.16))
		draw_rect(b_slot, Color(0.25, 0.3, 0.4), false, 1.0)
