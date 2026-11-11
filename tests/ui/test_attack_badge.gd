extends SceneTree
## D-1134: headless checks for the attack badge prototype and its reticle.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/ui/test_attack_badge.gd
##
## Headless does not draw; the look itself is covered by
## tests/ui/capture_attack_badges.gd (windowed, 4 styles + states).

const BadgeScript := preload("res://scripts/ui/attack_badge.gd")
const ReticleScript := preload("res://scripts/ui/attack_target_reticle.gd")

const SIZE := Vector2(380.0, 58.0)

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== Attack badge prototype (D-1134) ==")
	_test_styles()
	await _test_context_clamp()
	await _test_press_signal()
	await _test_press_ignored_without_target()
	await _test_reticle()
	print("ATTACK_BADGE_TEST_" + ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)


func _test_styles() -> void:
	_expect(BadgeScript.style_name(0) == "ATTACK CARD", "style 0 = ATTACK CARD")
	_expect(BadgeScript.style_name(1) == "COMMAND STRIP", "style 1 = COMMAND STRIP")
	_expect(BadgeScript.style_name(2) == "SMT UPLINK", "style 2 = SMT UPLINK")
	_expect(BadgeScript.style_name(3) == "Z-POW", "style 3 = Z-POW")
	_expect(BadgeScript.style_name(99) == "?", "unknown style has a safe label")


func _test_context_clamp() -> void:
	var badge = BadgeScript.new()
	root.add_child(badge)
	await process_frame
	_expect(badge.size == SIZE, "badge size is 380x58")
	badge.set_context("SLIME", 99.0, BadgeScript.State.READY, 5.0)
	_expect(is_equal_approx(badge.distance, 4.5), "distance clamps to the 4.5 m range")
	_expect(is_equal_approx(badge.cooldown, 1.0), "cooldown clamps to 1.0")
	badge.set_context("GIBLE", 2.25, BadgeScript.State.RECHARGING, -3.0)
	_expect(is_equal_approx(badge.distance, 2.25), "distance keeps a valid value")
	_expect(is_equal_approx(badge.cooldown, 0.0), "cooldown clamps to 0.0")
	_expect(badge.state == BadgeScript.State.RECHARGING, "state accepts RECHARGING")
	badge.queue_free()
	await process_frame


func _test_press_signal() -> void:
	var badge = BadgeScript.new()
	root.add_child(badge)
	await process_frame
	var count := [0]
	badge.badge_pressed.connect(func() -> void: count[0] += 1)
	badge.set_context("SLIME", 3.0, BadgeScript.State.READY)
	badge.play_press()
	_expect(count[0] == 1, "play_press emits badge_pressed once")
	_expect(badge._press > 0.0, "play_press starts the press animation")
	badge.set_style(BadgeScript.Style.Z_POW)
	badge.play_press()
	_expect(count[0] == 2, "play_press emits for every style")
	_expect(badge._pow > 0.0, "Z-POW press starts the POW burst")
	badge.queue_free()
	await process_frame


func _test_press_ignored_without_target() -> void:
	var badge = BadgeScript.new()
	root.add_child(badge)
	await process_frame
	var count := [0]
	badge.badge_pressed.connect(func() -> void: count[0] += 1)
	badge.set_context("", 3.0, BadgeScript.State.NO_TARGET)
	badge.play_press()
	_expect(count[0] == 0, "NO_TARGET ignores the press")
	badge.queue_free()
	await process_frame


func _test_reticle() -> void:
	var reticle = ReticleScript.new()
	root.add_child(reticle)
	await process_frame
	reticle.set_target(Vector2(640.0, 360.0), true)
	_expect(reticle.active, "reticle becomes active")
	_expect(reticle.center == Vector2(640.0, 360.0), "reticle keeps the projected target")
	reticle.set_target(Vector2(10.0, 20.0), false)
	_expect(not reticle.active, "reticle deactivates")
	reticle.queue_free()
	await process_frame


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		_failures += 1
