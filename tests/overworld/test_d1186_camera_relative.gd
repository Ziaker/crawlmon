extends SceneTree
## D-1186: movement must use the camera the player is actually seeing, not the old
## orbit yaw. Simulates a wall pushing the camera to the side.
## Runs with: godot --headless --path . --script res://tests/overworld/test_d1169_camera_relative.gd

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
	else:
		failures += 1
		print("  [FAIL] %s" % msg)


func _run() -> void:
	print("=================================================================")
	print("   CRAWMON — MOVIMENTO RELATIVO À CÂMERA REAL (D-1186)")
	print("=================================================================")
	var packed := load(LAB) as PackedScene
	var lab: Node3D = packed.instantiate()
	root.add_child(lab)
	for i in 20:
		await process_frame
	var player: CharacterBody3D = lab.get("player")
	var camera: Camera3D = lab.get("_camera")
	_expect(player != null and camera != null, "Lab carregou jogador e câmera")
	if player != null and camera != null:
		var cam_yaw_before: float = lab.get("_cam_yaw")
		var player_yaw_before: float = lab.get("player_yaw")
		for i in 30:
			await physics_frame
		_expect(is_equal_approx(float(lab.get("_cam_yaw")), cam_yaw_before), "A câmera não gira sozinha com o jogador parado")
		_expect(is_equal_approx(float(lab.get("player_yaw")), player_yaw_before), "A câmera parada não força o boneco a virar")
		# Simula a câmera empurrada para o lado por uma parede: o yaw antigo continua 0,
		# mas a câmera real olha para +X.
		lab.set("_cam_yaw", 0.0)
		var pivot := player.global_position + Vector3(0.0, 0.85, 0.0)
		camera.global_position = pivot + Vector3(-3.0, 1.2, 0.0)
		camera.look_at(pivot, Vector3.UP)
		var actual := -camera.global_transform.basis.z
		actual.y = 0.0
		actual = actual.normalized()
		var old_yaw := Vector3(sin(0.0), 0.0, cos(0.0))
		var used: Vector3 = lab._camera_ground_forward()
		_expect(used.dot(actual) > 0.999, "O movimento usa a direção real da câmera")
		_expect(used.dot(old_yaw) < 0.5, "O movimento não usa mais o yaw antigo da órbita")
		# A direita da tela é o eixo horizontal coerente com a câmera real.
		var right := used.cross(Vector3.UP).normalized()
		_expect(absf(right.dot(Vector3(0.0, 0.0, 1.0))) > 0.999, "A direita da câmera também segue a vista real")
	lab.queue_free()
	await process_frame
	print("=================================================================")
	if failures == 0:
		print("D1186_CAMERA_RELATIVE_TEST_PASS")
	else:
		print("TESTES COM %d FALHAS" % failures)
	print("=================================================================")
	quit(1 if failures > 0 else 0)
