extends SceneTree
## D-1173: headless proof that the overworld walk/dash dust uses the combat
## recipe (smoke texture, smoke 0.82/0.78/0.72, gravel, alternating feet) and
## that the dash keeps alpha 0.22 (D-1100 item 12).

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const DASH_DUST := preload("res://scripts/overworld/vfx/overworld_dash_dust.gd")
const WALK_DUST := preload("res://scripts/overworld/vfx/overworld_walk_dust.gd")

var _checks := 0
var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("== OVERWORLD DUST MATCH (D-1173) ==")
	_expect(is_equal_approx(WALK_DUST.CADENCE, 0.218253),
		"walk rate is another 40% lower (0.218 s, D-1188)")
	await _walk_dust()
	await _dash_dust()
	print("OVERWORLD_DUST_MATCH_" + ("PASS" if _failures == 0 else "FAIL")
		+ " checks=%d failures=%d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _walk_dust() -> void:
	var lab := (load(LAB) as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for i in 30:
		await process_frame
	var player: CharacterBody3D = lab.get("player")
	var dust: CPUParticles3D = lab.get("_player_dust")
	_expect(dust != null, "lab has a FootDust")
	if dust == null:
		lab.queue_free()
		return
	_expect(dust.has_method("set_alpha_multiplier"), "FootDust is the combat-recipe ticker")
	_expect(dust.has_method("get_alpha_multiplier"), "FootDust exposes its peak alpha")
	player.global_position = Vector3(6.0, 0.25, 0.0)
	var gible: Node3D = lab.get("_second_enemy")
	if gible != null:
		gible.global_position = Vector3(32.0, 0.0, 32.0)
	lab.set("_cam_yaw", PI * 0.5)
	_send_key(KEY_W, true)
	for i in 72:  # D-1188: slower walk cadence (0.218 s) needs more frames to show the same bursts
		await physics_frame
	_expect(dust.emitting, "walking turns the FootDust on")
	_expect(dust.get_child_count() >= 7, "walking spawns smoke + gravel bursts")
	var smoke: CPUParticles3D = null
	var gravel: CPUParticles3D = null
	var sides := {}
	for child in dust.get_children():
		if not (child is CPUParticles3D):
			continue
		var p := child as CPUParticles3D
		if p.amount == 4 and smoke == null:
			smoke = p
		elif p.amount == 3 and gravel == null:
			gravel = p
		sides["+" if p.global_position.z - dust.global_position.z >= 0.0 else "-"] = true
	_expect(smoke != null, "walk dust has the 4-puff smoke burst")
	_expect(gravel != null, "walk dust has the 3-spec gravel burst")
	if smoke != null:
		var mesh := smoke.mesh as QuadMesh
		var mat := (mesh.material as StandardMaterial3D) if mesh != null else null
		_expect(mat != null and mat.albedo_texture == VfxLib.smoke_tex(),
			"walk smoke uses the combat smoke texture")
		_expect(smoke.lifetime > 0.37 and smoke.lifetime < 0.39, "walk smoke life matches combat (0.38)")
		_expect(smoke.scale_amount_min > 0.27 and smoke.scale_amount_max < 0.58,
			"walk smoke is 50% of the combat size (0.275-0.575)")
		var curve := smoke.scale_amount_curve
		_expect(curve != null, "walk smoke uses the combat burst scale curve")
		_expect(smoke.initial_velocity_max <= 1.5 and smoke.emission_sphere_radius < 0.2
			and smoke.spread <= 75.0,
			"normal walking smoke spreads less (speed/radius/cone)")
	if gravel != null:
		_expect(gravel.lifetime > 0.21 and gravel.lifetime < 0.23, "walk gravel life matches combat (0.22)")
		_expect(gravel.scale_amount_max < 0.15, "walk gravel size matches combat (0.06-0.14)")
		_expect(gravel.initial_velocity_max < 2.0 and gravel.spread < 20.0,
			"normal walking gravel spreads less")
	_expect(sides.has("+") and sides.has("-"), "walk dust alternates the feet (+/- offset)")
	dust.set_alpha_multiplier(0.22)
	_expect(is_equal_approx(dust.get_alpha_multiplier(), 0.22),
		"dash can lower the walk peak to 0.22")
	dust.set_alpha_multiplier(0.75)
	_expect(is_equal_approx(dust.get_alpha_multiplier(), 0.75),
		"walk peak returns to the combat 0.75")
	var followers: Array = lab.get("_followers")
	_expect(followers.size() > 0 and (followers[0].get("dust") as Node).has_method("set_alpha_multiplier"),
		"follower dust uses the same combat recipe")
	var enemy_dust: CPUParticles3D = lab.get("_second_enemy_dust")
	_expect(enemy_dust != null and enemy_dust.has_method("set_alpha_multiplier"),
		"enemy dust uses the same combat recipe")
	_send_key(KEY_W, false)
	lab.queue_free()
	await process_frame


func _dash_dust() -> void:
	var dust = DASH_DUST.new()
	root.add_child(dust)
	dust.begin(Vector3(0.0, 0.0, 0.0), Vector3.FORWARD)
	await process_frame
	_expect(is_equal_approx(dust.get_dust_alpha(), 0.22), "dash dust keeps alpha 0.22")
	var state: Dictionary = dust.get_debug_state()
	_expect(bool(state["emitting"]), "dash dust emits during the advance")
	var smoke: CPUParticles3D = null
	var gravel: CPUParticles3D = null
	var flipbook := false
	for child in dust.get_children():
		if child is MeshInstance3D:
			flipbook = true
		elif child is CPUParticles3D:
			var p := child as CPUParticles3D
			if p.amount == 8:
				smoke = p
			elif p.amount == 7:
				gravel = p
	_expect(flipbook, "dash takeoff spawns the smoke flipbook")
	_expect(smoke != null, "dash takeoff spawns the 8 smoke puffs")
	_expect(gravel != null, "dash takeoff spawns the 7 gravel specks")
	var steps: Array[CPUParticles3D] = []
	for child in dust.get_children():
		if child is CPUParticles3D and (child as CPUParticles3D).amount == 4:
			steps.append(child)
	_expect(steps.size() == 2, "dash start adds the walking puff on both feet")
	if steps.size() == 2:
		var sizes_ok := true
		var alpha_ok := true
		for p in steps:
			sizes_ok = sizes_ok and p.scale_amount_min > 0.65 and p.scale_amount_max < 1.39
			var ramp := p.color_ramp
			alpha_ok = alpha_ok and ramp != null and ramp.sample(0.2).a > 0.7
		_expect(sizes_ok, "dash start puff is 20% bigger (0.66-1.38)")
		_expect(alpha_ok, "dash start puff is at full walking opacity (0.75)")
	dust.set_dash_duration(0.10)
	dust.tick(0.02)
	await process_frame
	var walking_puffs := 0
	var continuation: CPUParticles3D = null
	for child in dust.get_children():
		var p := child as CPUParticles3D
		if p != null and p.amount == 4 and p.scale_amount_min < 0.3:
			walking_puffs += 1
			continuation = p
	_expect(walking_puffs >= 1, "first half of the dash keeps the walking puff at 50% size")
	if continuation != null:
		_expect(continuation.initial_velocity_max > 2.0 and continuation.spread > 100.0,
			"dash continuation keeps the original spread (only normal walking is tighter)")
	dust.tick(0.06)
	await process_frame
	var walking_after := 0
	for child in dust.get_children():
		var p := child as CPUParticles3D
		if p != null and p.amount == 4 and p.scale_amount_min < 0.3:
			walking_after += 1
	_expect(walking_after == walking_puffs, "walking puff stops after the first half of the dash")
	_expect(dust.get_child_count() >= 4, "dash tick spawns the run trail")
	dust.clear()
	await process_frame
	_expect(not bool(dust.get_debug_state()["emitting"]), "clear stops the dash dust")
	dust.queue_free()


func _send_key(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _expect(ok: bool, text: String) -> void:
	_checks += 1
	if ok:
		print("PASS  ", text)
	else:
		_failures += 1
		print("FAIL  ", text)
