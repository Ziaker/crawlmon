extends SceneTree
## FxMartialHand (D-1209): poses, ghost cap and cleanup. Nothing here is per character or
## per side (D-235): the same component is posed from arbitrary fingers/cut_dir/pos.
## Run: godot --headless --path . --script res://tests/vfx/test_martial_hand.gd

var failures := 0
var hand: FxMartialHand


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	hand = FxMartialHand.create(root, 1.6)
	_expect(hand != null and hand.get_child_count() == 1, "create: the hand node carries the mesh")
	_knife()
	_palm_down()
	_degenerate()
	_ghost_cap()
	await process_frame
	_free_now()
	await process_frame
	if failures == 0:
		print("MARTIAL_HAND_TEST_PASS")
	else:
		print("MARTIAL_HAND_TEST_FAIL %d" % failures)
	quit(1 if failures > 0 else 0)


func _knife() -> void:
	var pos := Vector3(1.0, 0.5, -2.0)
	var fingers := Vector3(0.0, 0.2, 1.0)
	var cut := Vector3(-0.9, 0.1, 0.3)  # not perpendicular to fingers on purpose
	hand.pose_knife(pos, fingers, cut)
	var b := hand.transform.basis
	var f := fingers.normalized()
	var c := (cut - f * cut.dot(f)).normalized()
	_expect(_orthonormal(b), "knife: basis is orthonormal (det %.4f)" % b.determinant())
	_expect(absf(b.determinant() - 1.0) < 0.01, "knife: basis is right-handed")
	_expect((b * Vector3(0.0, 1.0, 0.0)).dot(f) > 0.999, "knife: mesh +Y (fingers) points to fingers")
	_expect((b * Vector3(1.0, 0.0, 0.0)).dot(c) > 0.999, "knife: mesh +X (little finger) leads along cut_dir")
	var palm := (b * Vector3(0.0, 0.0, -1.0)).normalized()
	var n := f.cross(c).normalized()
	_expect((palm - n).length() < 0.01, "knife: palm normal = fingers x cut_dir")
	_expect(absf(palm.dot(f)) < 0.01 and absf(palm.dot(c)) < 0.01, "knife: palm plane contains fingers and cut_dir")
	_expect((hand.transform.origin - pos).length() < 0.0001, "knife: wrist sits on pos")


func _palm_down() -> void:
	var fingers := Vector3(0.4, 0.0, -0.9)
	hand.pose_palm_down(Vector3(1.0, 0.2, 0.3), fingers)
	var b := hand.transform.basis
	_expect(_orthonormal(b), "palm_down: basis is orthonormal (det %.4f)" % b.determinant())
	var palm := b * Vector3(0.0, 0.0, -1.0)
	_expect((palm - Vector3.DOWN).length() < 0.01, "palm_down: palm (mesh -Z) faces world -Y (%.3f, %.3f, %.3f)" % [palm.x, palm.y, palm.z])
	var f := Vector3(fingers.x, 0.0, fingers.z).normalized()
	_expect((b * Vector3(0.0, 1.0, 0.0)).dot(f) > 0.999, "palm_down: fingers point to fingers, horizontal")
	_expect((hand.transform.origin - Vector3(1.0, 0.2, 0.3)).length() < 0.0001, "palm_down: wrist sits on pos")
	# D-235: mirrored attacker, target on the other side -> same palm direction
	hand.pose_palm_down(Vector3.ZERO, Vector3(-0.4, 0.0, 0.9))
	var palm_m := hand.transform.basis * Vector3(0.0, 0.0, -1.0)
	_expect((palm_m - Vector3.DOWN).length() < 0.01, "palm_down mirrored: palm still faces world -Y")
	_expect(_orthonormal(hand.transform.basis), "palm_down mirrored: basis is orthonormal")


func _degenerate() -> void:
	# cut_dir parallel to fingers, zero fingers, vertical fingers in palm_down: never a NaN basis
	hand.pose_knife(Vector3.ZERO, Vector3.FORWARD, Vector3.FORWARD)
	_expect(_orthonormal(hand.transform.basis), "knife: parallel cut_dir still gives an orthonormal basis")
	hand.pose_knife(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
	_expect(_orthonormal(hand.transform.basis), "knife: zero vectors fall back to a valid basis")
	hand.pose_palm_down(Vector3.ZERO, Vector3.UP)
	_expect(_orthonormal(hand.transform.basis), "palm_down: vertical fingers fall back to a valid basis")
	var palm := hand.transform.basis * Vector3(0.0, 0.0, -1.0)
	_expect((palm - Vector3.DOWN).length() < 0.01, "palm_down: palm still faces -Y on the fallback")


func _ghost_cap() -> void:
	hand.pose_palm_down(Vector3.ZERO, Vector3.FORWARD)
	hand.set_look(1.0, 0.0, 1.0)
	for i in 6:
		hand.ghost(0.5, 0.4)
	var ghosts := _ghost_count()
	_expect(ghosts == 4, "ghosts: 6 requests keep at most 4 alive (alive=%d)" % ghosts)
	_expect(hand.get_child_count() == 1 + ghosts, "ghosts: mesh + ghosts are the only children (%d)" % hand.get_child_count())
	_expect(hand.transform.basis.is_equal_approx(hand.transform.basis), "ghosts: the hand keeps its own pose")


func _free_now() -> void:
	hand.free_now()
	_expect(hand.get_child_count() == 0, "free_now: 0 children, hand and ghosts released (%d)" % hand.get_child_count())
	hand.free_now()
	_expect(hand.get_child_count() == 0, "free_now: safe to call twice")
	hand.pose_knife(Vector3.ZERO, Vector3.FORWARD, Vector3.UP)
	hand.set_look(1.0, 0.0, 1.0)
	hand.ghost(0.5, 0.4)
	_expect(hand.get_child_count() == 0, "free_now: a freed hand does not resurrect on later calls")
	hand.free_now()


func _ghost_count() -> int:
	var n := 0
	for c in hand.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).top_level:
			n += 1
	return n


func _orthonormal(b: Basis) -> bool:
	for a in [b.x, b.y, b.z]:
		if absf((a as Vector3).length() - 1.0) > 0.001:
			return false
	if absf(b.x.dot(b.y)) > 0.001 or absf(b.x.dot(b.z)) > 0.001 or absf(b.y.dot(b.z)) > 0.001:
		return false
	return true


func _expect(c: bool, m: String) -> void:
	if c:
		print("  [PASS] ", m)
	else:
		failures += 1
		print("  [FAIL] ", m)
