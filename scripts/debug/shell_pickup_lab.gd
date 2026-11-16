extends Node3D
## D-1259 (teste): sala de debug dos Cascos. Fisica, brilho e coleta em < 15 s.
##   Godot ... res://scenes/debug/shell_pickup_lab.tscn -- --auto --stdout-trace --quit
##   --shot=<pasta> grava quadros (precisa de janela). Sem --auto: WASD move o coletor,
##   R refaz a cena.

const COIN := preload("res://scripts/exploration/shell_coin.gd")

var _collector: Node3D
var _coins: Array = []
var _t := 0.0
var _settled := 0
var _collected := {0: 0, 1: 0, 2: 0}
var _max_chain := 0
var _auto := false
var _trace := false
var _quit := false
var _shot_dir := ""
var _phase := "fall"
var _walk_i := 0
var _shots_done := {}
var _events: Array = []
const GOALS := [Vector3(-1.2, 0, 0.0), Vector3(0.0, 0, 0.0), Vector3(1.2, 0, 0.0)]


func _ready() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_auto = "--auto" in args
	_trace = "--stdout-trace" in args
	_quit = "--quit" in args
	for a in args:
		if a.begins_with("--shot="):
			_shot_dir = a.substr(7)
	var sd := 1259
	for a in args:
		if a.begins_with("--seed="):
			sd = int(a.substr(7))
	seed(sd)
	_build_world()
	_spawn_all()


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.07, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.4, 0.55)
	env.ambient_light_energy = 0.55
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	cs.shape = box
	cs.position.y = -0.5
	floor_body.add_child(cs)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.27, 0.15, 0.27)
	mat.roughness = 0.95
	mi.material_override = mat
	floor_body.add_child(mi)
	add_child(floor_body)
	var cam := Camera3D.new()
	cam.fov = 34
	cam.position = Vector3(0, 2.1, 3.3)
	add_child(cam)
	cam.look_at(Vector3(0, 0.0, 0.3), Vector3.UP)
	cam.current = true
	_collector = Node3D.new()
	_collector.name = "Collector"
	_collector.add_to_group("item_collector")
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.22
	cap.height = 1.1
	body.mesh = cap
	body.position.y = 0.55
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.15, 0.35, 0.4)
	body.material_override = bm
	_collector.add_child(body)
	_collector.position = Vector3(-1.2, 0, 4.0)
	add_child(_collector)


func _spawn_all() -> void:
	_spawn(ShellCoin.Denom.BRONZE, Vector3(-1.2, 0.5, 0.0))
	for i in 3:
		_spawn(ShellCoin.Denom.SILVER, Vector3(-0.15 + i * 0.15, 0.5 + i * 0.1, -0.15 + (i % 2) * 0.3))
	for i in 5:
		_spawn(ShellCoin.Denom.GOLD, Vector3(1.2 + randf_range(-0.05, 0.05), 0.45 + i * 0.14, randf_range(-0.05, 0.05)))


func _spawn(denom: int, pos: Vector3) -> void:
	var c := ShellCoin.spawn(self, denom, pos)
	c.settled.connect(_on_settled)
	c.collect_started.connect(func(d, ch): _log("collect_started", {"denom": d, "chain": ch}))
	c.collected.connect(_on_collected)
	_coins.append(c)


func _on_settled(d: int) -> void:
	_settled += 1
	_log("settled", {"denom": d, "n": _settled})


func _on_collected(d: int, ch: int) -> void:
	_collected[d] += 1
	_max_chain = maxi(_max_chain, ch)
	_log("collected", {"denom": d, "chain": ch})


func _log(ev: String, data: Dictionary) -> void:
	data["ev"] = ev
	data["t"] = snappedf(_t, 0.01)
	_events.append(data)
	if _trace:
		print("[SHELL] ", JSON.stringify(data))


func _physics_process(delta: float) -> void:
	_t += delta
	if _auto:
		_run_auto(delta)
	else:
		_manual(delta)


func _manual(delta: float) -> void:
	var v := Vector3(Input.get_axis("ui_left", "ui_right"), 0, Input.get_axis("ui_up", "ui_down"))
	_collector.position += v * 2.5 * delta
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()


func _run_auto(delta: float) -> void:
	match _phase:
		"fall":
			if _settled >= _coins.size() or _t > 5.0:
				_log("all_settled", {"settled": _settled, "of": _coins.size()})
				_shot("01_settled")
				_phase = "walk"
		"walk":
			var goal: Vector3 = GOALS[_walk_i] + Vector3(0, 0, 1.0)
			var d := goal - _collector.position
			d.y = 0
			if d.length() < 0.05:
				_phase = "wait"
				_wait_until = _t + (1.6 if _walk_i < 2 else 2.0)
			else:
				_collector.position += d.normalized() * minf(d.length(), 3.0 * delta)
		"wait":
			if _walk_i == 2 and not _shots_done.has("02"):
				_shot("02_gold_fly", 0.12)
			if _t >= _wait_until:
				_walk_i += 1
				if _walk_i >= 3:
					_finish()
				else:
					_phase = "walk"
		"done":
			pass


var _wait_until := 0.0
var _shot_pending := []


func _shot(label: String, delay := 0.0) -> void:
	_shots_done[label.substr(0, 2)] = true
	if _shot_dir == "":
		return
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_shot_dir)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shot_dir, label])


func _finish() -> void:
	_phase = "done"
	var remaining := get_tree().get_nodes_in_group("shell_coin").size()
	var min_y := 0.0
	for c in get_tree().get_nodes_in_group("shell_coin"):
		print("[SHELL] left ", c.name, " pos=", (c as Node3D).global_position, " state=", c.state, " coll=", _collector.global_position)
	for c in get_tree().get_nodes_in_group("shell_coin"):
		min_y = minf(min_y, (c as Node3D).global_position.y)
	var ok := _settled == _coins.size() and remaining == 0 and min_y > -0.05
	ok = ok and _collected[0] == 1 and _collected[1] == 3 and _collected[2] == 5 and _max_chain >= 2
	var summary := {"ev": "summary", "ok": ok, "settled": _settled, "collected": _collected,
		"max_chain": _max_chain, "remaining": remaining, "min_y": snappedf(min_y, 0.001), "t": snappedf(_t, 0.01)}
	print("[SHELL] ", JSON.stringify(summary))
	if _quit:
		await get_tree().create_timer(0.3).timeout
		get_tree().quit(0 if ok else 1)
