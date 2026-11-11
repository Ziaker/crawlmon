extends SceneTree
## Checks headless do novo HUD de ataque (4 conceitos sem bloco).
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/ui/test_attack_hud.gd

const HudScript := preload("res://scripts/ui/attack_hud.gd")

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== Attack HUD (4 conceitos sem bloco) ==")
	await _test_modes()
	await _test_context()
	await _test_press()
	await _test_projection_anchors()
	print("ATTACK_HUD_TEST_" + ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)


func _test_modes() -> void:
	_expect(HudScript.mode_name(0) == "MIRA", "mode 0 = MIRA")
	_expect(HudScript.mode_name(1) == "SELO", "mode 1 = SELO")
	_expect(HudScript.mode_name(2) == "GLIFO", "mode 2 = GLIFO")
	_expect(HudScript.mode_name(3) == "FITA", "mode 3 = FITA")
	var hud = HudScript.new()
	root.add_child(hud)
	await process_frame
	_expect(hud.size.x > 0.0, "HUD fills the viewport")
	for i in 4:
		hud.set_mode(i)
		_expect(hud.mode == i, "set_mode(%d) applies" % i)
	hud.set_mode(99)
	_expect(hud.mode == 3, "mode clamps to 3")
	hud.queue_free()
	await process_frame


func _test_context() -> void:
	var hud = HudScript.new()
	root.add_child(hud)
	await process_frame
	hud.set_context("SLIME", 99.0, HudScript.State.READY, 5.0)
	_expect(is_equal_approx(hud.distance, 4.5), "distance clamps to 4.5 m")
	_expect(is_equal_approx(hud.cooldown, 1.0), "cooldown clamps to 1.0")
	hud.set_context("GIBLE", 2.2, HudScript.State.RECHARGING, -1.0)
	_expect(is_equal_approx(hud.distance, 2.2), "valid distance is kept")
	_expect(is_equal_approx(hud.cooldown, 0.0), "cooldown clamps to 0.0")
	_expect(hud.state == HudScript.State.RECHARGING, "state accepts RECHARGING")
	hud.queue_free()
	await process_frame


func _test_press() -> void:
	var hud = HudScript.new()
	root.add_child(hud)
	await process_frame
	var count := [0]
	hud.hud_pressed.connect(func() -> void: count[0] += 1)
	hud.set_context("SLIME", 3.0, HudScript.State.READY)
	hud.play_press()
	_expect(count[0] == 1, "press emits hud_pressed")
	_expect(hud._press > 0.0, "press starts the impact animation")
	hud.set_context("SLIME", 3.0, HudScript.State.NO_TARGET)
	hud._press = 0.0
	hud.play_press()
	_expect(count[0] == 1, "NO_TARGET ignores the press")
	_expect(is_equal_approx(hud._press, 0.0), "NO_TARGET does not start the impact")
	hud.queue_free()
	await process_frame


func _test_projection_anchors() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 1.2, 6.0)
	root.add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	cam.current = true

	var player := _actor("Player", Vector3(-1.5, 0.0, 0.0), 1.0)
	var target := _actor("Enemy", Vector3(1.5, 0.0, 0.0), 1.2)
	root.add_child(player)
	root.add_child(target)

	var hud = HudScript.new()
	root.add_child(hud)
	await process_frame
	hud.set_projection(cam, player, target)
	for i in 4:
		hud.set_mode(i)
		var head = hud._target_head()
		var anchor = hud._target_anchor()
		_expect(head != Vector2.INF and anchor != Vector2.INF,
			"mode %d projects the target anchors" % i)
		_expect(head.y < anchor.y, "mode %d head is above the body anchor" % i)
	_expect(hud._find_effect_anchor(target, "eff_head") != null,
		"eff_head anchor is found by name, not by character")
	_expect(hud._find_effect_anchor(player, "eff_floor") != null,
		"eff_floor anchor is found for the player")
	var bounds: Vector2 = hud._visual_bounds(target)
	_expect(bounds.y > bounds.x, "visual bounds are valid")
	hud.queue_free()
	player.queue_free()
	target.queue_free()
	cam.queue_free()
	await process_frame


func _actor(node_name: String, pos: Vector3, height: float) -> Node3D:
	var body := Node3D.new()
	body.name = node_name
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, height, 0.8)
	mesh.mesh = box
	mesh.position.y = height * 0.5
	body.add_child(mesh)
	var head := Node3D.new()
	head.name = "eff_head"
	head.position.y = height
	body.add_child(head)
	var floor_node := Node3D.new()
	floor_node.name = "eff_floor"
	body.add_child(floor_node)
	var body_node := Node3D.new()
	body_node.name = "eff_body"
	body_node.position.y = height * 0.5
	body.add_child(body_node)
	return body


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		_failures += 1
