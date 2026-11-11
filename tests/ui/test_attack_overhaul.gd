extends SceneTree
## Checks do laboratório dos 3 overhauls: perfis, input Z e retorno ao idle.
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 \
##       --script res://tests/ui/test_attack_overhaul.gd

const LAB := "res://scenes/debug/attack_overhaul_lab.tscn"

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== Attack overhaul lab ==")
	var lab = (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	await _frames(40)
	var constants: Dictionary = lab.get_script().get_script_constant_map()
	_expect(constants.has("PROFILES") and (constants["PROFILES"] as Array).size() == 3,
		"lab exposes the 3 profiles")
	_expect(int(lab.get("_profile")) == 0, "starts on Snap & Impact")
	_send_key(KEY_2)
	await _frames(2)
	_expect(int(lab.get("_profile")) == 1, "key 2 selects Duelist")
	_send_key(KEY_3)
	await _frames(2)
	_expect(int(lab.get("_profile")) == 2, "key 3 selects Comic Crash")
	_send_key(KEY_1)
	await _frames(2)
	_expect(int(lab.get("_profile")) == 0, "key 1 selects Snap")
	_send_key(KEY_Z)
	await _frames(3)
	_expect(int(lab.get("_phase")) != 0, "Z starts the attack")
	var guard := 0
	while int(lab.get("_phase")) != 0 and guard < 240:
		await _frames(1)
		guard += 1
	_expect(int(lab.get("_phase")) == 0, "attack returns to idle after the reset")
	print("ATTACK_OVERHAUL_TEST_" + ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)


func _send_key(keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.keycode = keycode
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventKey.new()
	up.physical_keycode = keycode
	up.keycode = keycode
	up.pressed = false
	Input.parse_input_event(up)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		_failures += 1
