extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTANDO CAPTURA REAL DE VIEWPORT PARA PNG ---")
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("test_captures"):
		dir.make_dir("test_captures")

	var scene := Node3D.new()
	root.add_child(scene)

	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.position = Vector3(0, 2, 5)
	cam.look_at(Vector3.ZERO)
	cam.current = true

	var light := DirectionalLight3D.new()
	scene.add_child(light)
	light.position = Vector3(5, 5, 5)
	light.look_at(Vector3.ZERO)

	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	cube.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#D7FD6A") # Verde-lima
	cube.material_override = mat
	scene.add_child(cube)

	for i in 10:
		await process_frame

	var vp := root.get_viewport()
	var tex := vp.get_texture()
	if tex == null:
		print("ERRO: get_texture() retornou null!")
		quit(1)
		return

	var img := tex.get_image()
	if img == null:
		print("ERRO: get_image() retornou null!")
		quit(1)
		return

	var path := "res://test_captures/test_frame.png"
	var err := img.save_png(path)
	if err != OK:
		print("ERRO ao salvar PNG: %d" % err)
		quit(1)
		return

	print("PASS: Imagem salva em %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	scene.free()
	quit(0)
