extends SceneTree
## D-1173: windowed proof of the overworld dust match.
## Walk: real lab with the attack controller frozen (no encounter transition).
## Dash: isolated OverworldDashVfx harness, normal and mirror sides.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 \
##       --position -4000,0 --fixed-fps 60 \
##       --script res://tests/overworld/capture_dust_match.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const DASH_VFX := preload("res://scripts/overworld/vfx/overworld_dash_vfx.gd")
const OUT := "res://test_captures"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _walk_case()
	await _dash_case(1.0)
	await _dash_case(-1.0)
	Engine.time_scale = 1.0
	quit(0)


func _walk_case() -> void:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(30)
	for child in lab.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	# Freeze the encounter logic so the Gible cannot start a battle during the
	# capture; the walk dust runs on its own.
	var controller = lab.get("_attack_controller")
	if controller != null:
		controller.process_mode = Node.PROCESS_MODE_DISABLED
	var player: CharacterBody3D = lab.get("player")
	player.global_position = Vector3(8.0, 0.25, -6.0)
	player.velocity = Vector3.ZERO
	var yaw := PI * 0.5
	lab.set("player_yaw", yaw)
	lab.set("_cam_yaw", yaw)
	player.rotation.y = yaw
	var cam := Camera3D.new()
	cam.fov = 58.0
	lab.add_child(cam)
	cam.global_position = Vector3(10.0, 1.35, -2.2)
	cam.look_at(Vector3(10.0, 0.45, -6.0), Vector3.UP)
	cam.current = true
	await _frames(8)
	_press(KEY_W, true)
	await _seconds(0.5)
	_save("d1173_walk_dust.png")
	await _seconds(0.4)
	_press(KEY_W, false)
	await _seconds(0.3)
	lab.queue_free()
	await _frames(3)


func _dash_case(side: float) -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	# Floor (the VFX ground probe needs a collider).
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30.0, 0.2, 30.0)
	floor_shape.shape = box
	floor_shape.position = Vector3(0.0, -0.1, 0.0)
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30.0, 30.0)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)

	var actor := Node3D.new()
	actor.position = Vector3(0.0, 0.0, 0.0)
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.0
	capsule.radius = 0.3
	body_mesh.mesh = capsule
	body_mesh.position = Vector3(0.0, 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.80, 0.25)
	body_mesh.material_override = mat
	actor.add_child(body_mesh)
	world.add_child(actor)
	var target := Node3D.new()
	target.position = Vector3(0.0, 0.0, -5.0)
	world.add_child(target)

	var cam := Camera3D.new()
	cam.fov = 55.0
	world.add_child(cam)
	cam.global_position = Vector3(3.8 * side, 1.25, -2.2)
	cam.look_at(Vector3(0.0, 0.45, -2.2), Vector3.UP)
	cam.current = true

	var vfx = DASH_VFX.new()
	world.add_child(vfx)
	vfx.setup(actor, target)
	vfx.begin_dash(1)
	var tag := "normal" if side > 0.0 else "mirror"
	var start := Vector3.ZERO
	var dt := 1.0 / 60.0
	for i in 7:
		actor.global_position = start + Vector3(0.0, 0.0, -4.4 * float(i + 1) / 7.0)
		vfx.tick(dt)
		await process_frame
		if i == 1:
			_save("d1173_dash_dust_%s_takeoff.png" % tag)
		elif i == 4:
			_save("d1173_dash_dust_%s_trail.png" % tag)
	await _seconds(0.45)
	_save("d1173_dash_dust_%s_after.png" % tag)
	world.queue_free()
	await _frames(3)


func _press(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(file_name))
	print("saved ", file_name)


func _frames(count: int) -> void:
	for i in count:
		await process_frame
