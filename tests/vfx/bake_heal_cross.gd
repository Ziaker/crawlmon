extends SceneTree
## D-343: assa o FLIPBOOK das cruzes verdes do Heal Gain: 16 quadros (4x4) de 256 px, fundo transparente.
## Cada quadro é uma cruz em #A8FFC4 com núcleo branco, halo radial e faíscas; o Motion Composer usa a
## idade da partícula (M26) para escolher o quadro. Saída: assets/vfx/flipbook_heal_cross.png
##   Godot --path . --script res://tests/vfx/bake_heal_cross.gd --resolution 512x512

const FRAMES := 16
const CELL := 256
const OUT := "res://assets/vfx/flipbook_heal_cross.png"
const MINT := Color("78f0a4")
const CORE := Color("b7ffc9")
const WHITE := Color("f4fff7")
const GLOW := Color("53e28b")

var _vp: SubViewport
var _art: Node2D
var _frame := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(CELL, CELL)
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	root.add_child(_vp)
	_art = Node2D.new()
	_vp.add_child(_art)
	_art.draw.connect(_draw_art)
	await process_frame
	var sheet := Image.create(CELL * 4, CELL * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in FRAMES:
		_frame = i
		_art.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, CELL, CELL), Vector2i((i % 4) * CELL, (i / 4) * CELL))
	var path := ProjectSettings.globalize_path(OUT)
	sheet.save_png(path)
	print("flipbook de cura salvo: ", path, " ", sheet.get_size())
	quit(0)


func _draw_art() -> void:
	var t := float(_frame) / float(FRAMES - 1)
	var c := _art
	var center := Vector2(CELL * 0.5, CELL * 0.5)
	var appear := clampf(t / 0.16, 0.0, 1.0)
	var vanish := 1.0 - clampf((t - 0.74) / 0.26, 0.0, 1.0)
	var env := (0.28 + 0.72 * appear) * vanish
	var pulse := 0.86 + 0.14 * sin(t * TAU * 2.0)
	var grow := lerpf(0.58, 1.0, 1.0 - pow(1.0 - clampf(t / 0.24, 0.0, 1.0), 3.0))
	var shrink := 1.0 - 0.16 * clampf((t - 0.72) / 0.28, 0.0, 1.0)
	var k := grow * shrink
	var rot := deg_to_rad(lerpf(-7.0, 5.0, t))

	# Halo suave (textura radial branca, tingida de verde).
	var glow_r := 92.0 * k * (0.92 + 0.18 * pulse)
	c.draw_texture_rect(VfxLib.glow_tex(), Rect2(center - Vector2(glow_r, glow_r), Vector2(glow_r * 2.0, glow_r * 2.0)), false,
		Color(GLOW.r, GLOW.g, GLOW.b, 0.52 * env))

	# A cruz inteira gira levemente; as faíscas acompanham o mesmo referencial.
	c.draw_set_transform(center, rot, Vector2(k, k))
	# Halo da própria cruz: uma cópia maior e translúcida por baixo.
	_draw_cross(c, 122.0, 132.0, Color(MINT.r, MINT.g, MINT.b, 0.16 * env))
	# Corpo da cruz e núcleo branco-quente.
	_draw_cross(c, 96.0, 104.0, Color(MINT.r, MINT.g, MINT.b, 0.98 * env))
	_draw_cross(c, 58.0, 64.0, Color(CORE.r, CORE.g, CORE.b, 0.95 * env))

	# Diamante no ombro superior esquerdo, como na opção 2 do HTML.
	var d := 13.0 * (0.7 + 0.5 * pulse)
	var dx := -34.0
	var dy := -38.0
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(dx, dy - d), Vector2(dx + d * 0.72, dy), Vector2(dx, dy + d), Vector2(dx - d * 0.72, dy)
	]), Color(WHITE.r, WHITE.g, WHITE.b, 0.95 * env))

	# Quatro brilhos nos cantos, pulsando em fases diferentes.
	var star := VfxLib.star_tex()
	var tips := [
		Vector2(0.0, -58.0), Vector2(55.0, 0.0), Vector2(0.0, 58.0), Vector2(-55.0, 0.0)
	]
	for i in tips.size():
		var p: Vector2 = tips[i]
		var tw := 0.55 + 0.45 * maxf(0.0, sin(t * TAU * 2.0 + float(i) * 1.7))
		var s := (15.0 + 10.0 * tw) * (0.7 + 0.5 * pulse)
		c.draw_texture_rect(star, Rect2(p - Vector2(s, s), Vector2(s * 2.0, s * 2.0)), false,
			Color(1.0, 1.0, 1.0, tw * env))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Cruz da opção 2: barra vertical estreita + barra horizontal larga, ambas de bordas retas.
func _draw_cross(c: CanvasItem, w: float, h: float, col: Color) -> void:
	var vw := w * 0.26
	var bar_h := h * 0.24
	c.draw_rect(Rect2(-vw * 0.5, -h * 0.5, vw, h), col)
	c.draw_rect(Rect2(-w * 0.5, -bar_h * 0.5, w, bar_h), col)
