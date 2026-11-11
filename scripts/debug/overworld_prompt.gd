extends Control
## D-1085: prompt de interação do NPC no mesmo visual torto dos cards.
## Keycap [Z] à esquerda, ação à direita e nome do NPC em linha menor.

const PLATE_SIZE := Vector2(380.0, 58.0)
const SHEAR := 8.0 / 82.0  ## mesmo shear dos cards D-1074

var _font: Font
var _time := 0.0
var _action := "TALK"
var _npc_name := ""
var _alt_key_visible := true
var _primary_key := "Z"
var _shown_once := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = PLATE_SIZE
	size = PLATE_SIZE
	visible = false
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Arial", "Segoe UI"])
	_font.font_weight = 800


func show_prompt(npc_name: String, action: String = "TALK", alt_key := true,
		primary_key := "Z") -> void:
	_npc_name = npc_name
	_action = action
	_alt_key_visible = alt_key
	_primary_key = primary_key
	if not visible:
		visible = true
		modulate.a = 0.0
		scale = Vector2(0.94, 0.94)
		pivot_offset = size * 0.5
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 1.0, 0.16)
		tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func hide_prompt() -> void:
	if visible:
		visible = false


func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var w := size.x
	var h := size.y
	var skew := h * SHEAR
	var plate := PackedVector2Array([
		Vector2(skew, 0.0),
		Vector2(w, 0.0),
		Vector2(w - skew, h),
		Vector2(0.0, h),
	])
	draw_colored_polygon(plate, Color(0.035, 0.025, 0.045, 0.94))
	draw_polyline(plate + PackedVector2Array([plate[0]]), Color(0.62, 0.88, 0.66, 0.98), 2.0, true)
	# fita âmbar no topo, para casar com o HUD
	draw_line(Vector2(skew + 2.0, 2.0), Vector2(w - 2.0, 2.0), Color(1.0, 0.72, 0.28, 0.9), 2.0)

	# keycap [Z]
	var kx := 12.0
	var ky := 10.0
	var kw := 46.0
	var kh := h - 20.0
	var kskew := kh * SHEAR
	var key := PackedVector2Array([
		Vector2(kx + kskew, ky),
		Vector2(kx + kw, ky),
		Vector2(kx + kw - kskew, ky + kh),
		Vector2(kx, ky + kh),
	])
	draw_colored_polygon(key, Color(0.12, 0.10, 0.14, 0.98))
	draw_polyline(key + PackedVector2Array([key[0]]), Color(1.0, 0.78, 0.35, 0.95), 2.0, true)
	var z_size := _font.get_string_size(_primary_key, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	draw_string(_font, Vector2(kx + (kw - z_size.x) * 0.5, ky + kh * 0.72),
		_primary_key, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.92, 0.70))
	if _alt_key_visible:
		draw_string(_font, Vector2(kx + kw + 5.0, ky + kh * 0.82),
			"E", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.84, 0.78, 0.9))

	# ação + nome
	var tx := kx + kw + (22.0 if _alt_key_visible else 12.0)
	draw_string(_font, Vector2(tx, 33.0), _action, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(0.97, 0.96, 0.90))
	var name_size := 12
	var shown := _npc_name
	if shown.length() > 24:
		shown = shown.substr(0, 23) + "…"
	draw_string(_font, Vector2(tx, 50.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size,
		Color(0.68, 1.0, 0.72, 0.92))

	# brilho de borda pulsando de leve
	var pulse := 0.65 + 0.35 * (0.5 + 0.5 * sin(_time * 3.2))
	draw_line(Vector2(w - 96.0, h - 7.0), Vector2(w - 18.0, h - 7.0),
		Color(1.0, 0.78, 0.35, 0.35 * pulse), 2.0)
