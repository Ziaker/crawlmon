extends SceneTree
## D-957 / Motion Composer V1.11: electric secondary (sparks) for the projectile library. The beam itself is hand-made
## (D-954/D-956); the Composer only paints the crackle around the charge and the impact sparks.
## godot --headless --path . --script res://tests/motion_composer/test_v111_electric.gd

var _fails := 0


func ok(cond: bool, name: String) -> void:
	print("  [PASS] " if cond else "  [FAIL] ", name)
	if not cond:
		_fails += 1


func _init() -> void:
	ok("electric" in MotionLooks.ELEMENTS, "electric is a Composer element")
	var el := MotionLooks.get_look("spark", "electric")
	var fi := MotionLooks.get_look("spark", "fire")
	ok(el["hot"] != fi["hot"] and el["cool"] != fi["cool"], "electric sparks have their own golden look")
	ok(float(el["hard"]) == 1.0, "electric sparks are hard-edged")
	var fx := MotionPresets.effect_for("electric_beam", 7)
	var phases := {}
	for l in fx.layers:
		phases[l["phase"]] = true
	ok(phases.has("windup") and phases.has("impact"), "electric preset has windup crackle and impact sparks")
	ok(not phases.has("travel"), "the travel is hand-made (no Composer layer)")
	print("MC_V111_ELECTRIC_%s" % ("PASS" if _fails == 0 else "FAIL"))
	quit(1 if _fails > 0 else 0)
