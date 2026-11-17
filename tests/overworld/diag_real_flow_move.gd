extends SceneTree
## Real flow: roulette -> Nature->Hub cutscene -> CONTROL, then holds UP and prints how far the leader moves.
## Run: Godot --headless --path . --script res://tests/overworld/diag_real_flow_move.gd -- --nht-auto --nature=brave
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var pg: Node = (load("res://scenes/pre_game.tscn") as PackedScene).instantiate()
	root.add_child(pg)
	var hub: Node = null
	var t := 0
	while t < 2400:
		await physics_frame
		t += 1
		var cs := current_scene
		if cs != null and cs.get("_arrival") == null and cs.get("player") != null and cs.name != pg.name and cs.has_method("_end_arrival"):
			hub = cs
			if t > 60:
				break
	if hub == null:
		print("REAL_FLOW no hub reached")
		quit(1)
		return
	for i in 120: await physics_frame
	var player: CharacterBody3D = hub.get("player")
	var start := player.global_position
	var ev := InputEventKey.new()
	ev.keycode = KEY_UP
	ev.physical_keycode = KEY_UP
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 90: await physics_frame
	var p := player.global_position
	print("REAL_FLOW moved=%.2f visible=%s arrival=%s ui_open=%s npc_talking=%s" % [Vector2(p.x, p.z).distance_to(Vector2(start.x, start.z)), str(player.visible), str(hub.get("_arrival")), str(hub.get("_ui_open")), str(hub.get("_npc_talking"))])
	quit(0)
