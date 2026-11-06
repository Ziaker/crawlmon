extends SceneTree
## D-343 — isolated look check for the option 2 heal gain and its green flipbook crosses.
##   Godot --path . --script res://tests/vfx/heal_gain_lab.gd --resolution 800x600
## Saves the mark's own viewport texture and a short frame sequence to test_captures/heal_gain_lab/.

const OUT := "res://test_captures/heal_gain_lab"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	RenderingServer.set_default_clear_color(Color(0.035, 0.055, 0.065))
	var scene := Node3D.new()
	root.add_child(scene)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.035, 0.055, 0.065)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.7, 0.65)
	e.ambient_light_energy = 0.7
	env.environment = e
	scene.add_child(env)

	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.position = Vector3(0.0, 1.7, 4.6)
	cam.look_at(Vector3(0.0, 1.45, 0.0))
	cam.fov = 45.0
	cam.current = true

	var light := DirectionalLight3D.new()
	scene.add_child(light)
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2

	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.2
	body.mesh = cap
	body.position = Vector3(0, 0.6, 0)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.18, 0.24, 0.24)
	body.material_override = bm
	scene.add_child(body)

	for i in 6:
		await process_frame

	var ui := CanvasLayer.new()
	scene.add_child(ui)
	var ui_root := Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(ui_root)
	var anchor := Vector3(0, 1.75, 0)
	var mark := HealGainMark.spawn(ui_root, Vector2(400, 200), 22, false, 1.0)
	var fx := HealGainFx.spawn(scene, anchor)

	# The mark's own texture, before the 3D compositing.
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var mark_img := mark._viewport.get_texture().get_image()
	if mark_img != null:
		mark_img.save_png(ProjectSettings.globalize_path(OUT + "/mark_texture.png"))

	for i in 18:
		await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		if img != null:
			img.save_png(ProjectSettings.globalize_path(OUT + "/f_%02d.png" % i))
		await create_timer(0.075).timeout

	print("heal gain lab saved to ", ProjectSettings.globalize_path(OUT))
	if is_instance_valid(fx):
		fx.queue_free()
	if is_instance_valid(mark):
		mark.queue_free()
	quit(0)
