extends SceneTree
## D-977: Electric Beam costs 8 MP and, on a successful hit, has 20% + LUK difference to STUN the target for 4 s.
## godot --headless --path . --script res://tests/battle/test_d977_electric_beam.gd

var _fails := 0


func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c:
		_fails += 1


func _arena() -> Array:
	var b := Battle.new()
	var p := Combatant.new("A", 999, 10, 0.5, true)
	p.place(Vector3.ZERO, PI)
	var e := Combatant.new("B", 999, 10, 0.5, false)
	e.place(Vector3(0, 0, -10), 0.0)
	for c in [p, e]:
		c.act_policy = Combatant.Act.HOLD
	b.start([p], [e])
	return [b, p, e]


func _init() -> void:
	var sk: Skill = null
	for s in Skill.library_skills():
		if s.display_name == "Electric Beam":
			sk = s
	ok(sk != null and sk.mp_cost == 6, "Electric Beam costs 6 MP (D-1081)")
	ok(sk.element == Element.Type.RAIO and sk.kind == Skill.Kind.PROJECTILE, "Electric, projectile (magical, Long)")
	ok(sk.tactical_summary().contains("STUN"), "sheet line 1 states the STUN")
	# LUK +100 over the target: chance 100% -> always stuns for 4 s.
	var a := _arena()
	(a[1] as Combatant).luk = 100
	(a[2] as Combatant).luk = 0
	var info: Dictionary = (a[0] as Battle)._hit(a[1], a[2], 1.0, Element.Type.RAIO, "Electric Beam")
	ok(bool(info.get("stun", false)) and is_equal_approx((a[2] as Combatant).stun_timer, 4.0), "LUK +100: stuns for 4 s")
	# LUK -100: chance 0% -> never stuns.
	var never := true
	for i in 50:
		var z := _arena()
		(z[1] as Combatant).luk = 0
		(z[2] as Combatant).luk = 100
		(z[0] as Battle)._hit(z[1], z[2], 1.0, Element.Type.RAIO, "Electric Beam")
		never = never and not (z[2] as Combatant).is_stunned()
	ok(never, "LUK -100: never stuns")
	# Equal LUK: about 20%.
	var n := 0
	for i in 2000:
		var q := _arena()
		(q[0] as Battle)._hit(q[1], q[2], 1.0, Element.Type.RAIO, "Electric Beam")
		if (q[2] as Combatant).is_stunned():
			n += 1
	ok(n > 320 and n < 480, "equal LUK: ~20%% stun rate (%d / 2000)" % n)
	print("D977_%s" % ("PASS" if _fails == 0 else "FAIL"))
	quit(1 if _fails > 0 else 0)
