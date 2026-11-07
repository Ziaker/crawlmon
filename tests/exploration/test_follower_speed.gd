extends SceneTree
## D-388: o seguidor usa a mesma velocidade do jogador (180 px/s).
##
## godot --headless --fixed-fps 60 --path . --script res://tests/exploration/test_follower_speed.gd

var _fail := 0


func _init() -> void:
	var player_script = load("res://scripts/dungeon/player.gd")
	var follower_script = load("res://scripts/dungeon/follower.gd")
	var player_speed := float(player_script.get_script_constant_map()["SPEED"])
	var follower_speed := float(follower_script.get_script_constant_map()["SPEED"])
	print("player SPEED=", player_speed, " follower SPEED=", follower_speed)
	_check(is_equal_approx(player_speed, follower_speed), "constantes iguais")

	var leader := Node2D.new()
	leader.position = Vector2(200, 200)
	root.add_child(leader)
	var follower = follower_script.new()
	follower.setup("pancham", leader)
	follower.position = Vector2(200 - 32, 200)
	root.add_child(follower)
	await process_frame

	var prev_x: float = follower.position.x
	var max_step := 0.0
	var total := 0.0
	var samples := 0
	for i in 120:
		leader.position.x += 3.0
		await process_frame
		var step: float = follower.position.x - prev_x
		prev_x = follower.position.x
		if i >= 30:
			max_step = maxf(max_step, step)
			total += step
			samples += 1
	var avg := total / float(samples)
	print("follower max step=", max_step, " avg=", avg, " player step=3.0")
	_check(max_step <= 3.05, "passo maximo <= 3.05 px")
	_check(avg >= 2.85, "media perto de 3.0 px")

	print("FOLLOWER SPEED TESTS: ", "OK" if _fail == 0 else "FAIL")
	quit(0 if _fail == 0 else 1)


func _check(ok: bool, label: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_fail += 1
