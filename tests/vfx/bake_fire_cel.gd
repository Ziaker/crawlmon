extends SceneTree
## D-332: assa o FLIPBOOK do fogo estilizado (shader mc_fire_cel): 16 quadros (4x4) de 256 px, ciclo PERIÓDICO (o último quadro
## volta ao primeiro sem salto), fundo transparente. Saída: assets/vfx/flipbook_fire_cel.png
##   Godot --path . --script res://tests/vfx/bake_fire_cel.gd --resolution 512x512

const FRAMES := 16
const CELL := 256
const OUT := "res://assets/vfx/flipbook_fire_cel.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(CELL, CELL)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.0
	vp.add_child(cam)
	cam.position = Vector3(0, 0, 3)
	cam.current = true
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2.ONE
	quad.mesh = qm
	var mat := VfxLib.shader_mat("mc_fire_cel", {"seed": 3.0, "energy": 1.0})
	quad.material_override = mat
	vp.add_child(quad)
	await process_frame
	var sheet := Image.create(CELL * 4, CELL * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in FRAMES:
		mat.set_shader_parameter("phase", float(i) / float(FRAMES))
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, CELL, CELL), Vector2i((i % 4) * CELL, (i / 4) * CELL))
	var path := ProjectSettings.globalize_path(OUT)
	sheet.save_png(path)
	print("flipbook salvo: ", path, " ", sheet.get_size())
	quit(0)
