extends SceneTree
## D-956/D-957: contract of the projectile library (phases, beams per target, lifetime, side independence).
## Run: Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/vfx/projectile_lib/test_contract.gd

var _fails := 0


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		_fails += 1
		print("  FAIL ", what)


func _step(v: ProjectileLibVfx, seconds: float) -> void:
	var n := int(ceil(seconds / 0.02))
	for i in n:
		if is_instance_valid(v):
			v.advance(0.02)


func _initialize() -> void:
	var root3d := Node3D.new()
	root.add_child(root3d)

	# 1. Phase order on one target.
	var v := ElectricBeamVfx.begin(null, "electric_beam", Vector3.ZERO, [Vector3(0, 0, -10)], 0.53, root3d)
	_check(v.phase() == ProjectileLibVfx.Phase.START, "starts in START")
	_step(v, 0.2)
	_check(v.phase() == ProjectileLibVfx.Phase.WINDUP, "START then WINDUP")
	_step(v, 1.0)
	_check(v.phase() == ProjectileLibVfx.Phase.WINDUP, "held charge stays in WINDUP until release (no cut)")
	v.release(Vector3.ZERO, [Vector3(0, 0, -10)])
	_check(v.phase() == ProjectileLibVfx.Phase.RELEASE, "release() enters RELEASE")
	_step(v, 0.1)
	v.set_travel(0, Vector3.ZERO, Vector3(0, 0, -10), 0.5)
	_check(v.phase() == ProjectileLibVfx.Phase.TRAJECTORY, "then TRAJECTORY")
	_check(is_equal_approx(v.beam_tip(0).z, -5.0), "beam tip follows travel progress")
	v.hit(0, Vector3(0, 0, -10), Vector3.FORWARD)
	_check(v.phase() == ProjectileLibVfx.Phase.IMPACT, "hit() enters IMPACT")
	_step(v, ProjectileLibVfx.IMPACT_LEN + 0.02)
	_check(v.phase() == ProjectileLibVfx.Phase.POST, "IMPACT then POST")
	_step(v, ProjectileLibVfx.POST_LEN + 0.1)
	_check(is_instance_valid(v) and not v.is_queued_for_deletion(), "D-973: still alive while the impact effects resolve")
	_step(v, ElectricBeamVfx.PILLAR_EMERGE + ElectricBeamVfx.PILLAR_LEN)
	_check(not is_instance_valid(v) or v.is_queued_for_deletion(), "D-973: frees itself once the impact effects have resolved")

	# 2. Several targets: one beam each, all at once.
	var targets: Array[Vector3] = [Vector3(-3, 0, -10), Vector3(0, 0, -12), Vector3(3, 0, -9)]
	var m := ElectricBeamVfx.begin(null, "electric_beam", Vector3.ZERO, targets, 0.53, root3d)
	_check(m.beam_count() == 3, "3 targets -> 3 beams")
	_step(m, 0.6)
	m.release(Vector3.ZERO, targets)
	for i in 3:
		m.set_travel(i, Vector3.ZERO, targets[i], 1.0)
	var all_full := true
	for i in 3:
		all_full = all_full and m.beam_tip(i).distance_to(targets[i]) < 0.001
	_check(all_full, "every beam reaches its own target")

	# 3. Miss: no impact burst.
	var w := ElectricBeamVfx.begin(null, "electric_beam", Vector3.ZERO, [Vector3(0, 0, -10)], 0.53, root3d)
	_step(w, 0.6)
	w.release(Vector3.ZERO, [Vector3(0, 0, -10)])
	w.set_travel(0, Vector3.ZERO, Vector3(0, 0, -10), 1.0)
	w.end_flight()
	_step(w, 0.2)
	_check(w.impacts_drawn() == 0, "a missed beam draws no impact")
	_check(w.phase() == ProjectileLibVfx.Phase.POST, "a missed beam still dissipates (POST)")

	# 4. Side independence: same sizes in metres when attacker and target swap sides.
	var a := ElectricBeamVfx.begin(null, "electric_beam", Vector3(0, 0, 0), [Vector3(0, 0, -30)], 0.53, root3d)
	var b := ElectricBeamVfx.begin(null, "electric_beam", Vector3(0, 0, -30), [Vector3(0, 0, 0)], 0.53, root3d)
	_check(is_equal_approx(a.beam_width(), b.beam_width()), "beam width is the same in both views (fixed metres)")

	print("FAILS: %d" % _fails)
	quit(1 if _fails > 0 else 0)
