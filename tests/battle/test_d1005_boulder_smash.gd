extends SceneTree
var _f := 0
func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c: _f += 1
func _arena() -> Array:
	var b := Battle.new()
	var p := Combatant.new("A", 999, 10, 0.5, true)
	p.place(Vector3.ZERO, PI)
	var e := Combatant.new("B", 999, 10, 0.5, false)
	e.place(Vector3(0, 0, -10), 0.0)
	for c in [p, e]: c.act_policy = Combatant.Act.HOLD
	b.start([p], [e])
	return [b, p, e]
func _init() -> void:
	var a := _arena()
	(a[1] as Combatant).luk = 100
	var info: Dictionary = (a[0] as Battle)._hit(a[1], a[2], 1.2, Element.Type.FISICO, "Boulder Smash")
	ok((a[2] as Combatant).def_buff == -1 and info.get("def_down_proc", false), "LUK +100: always -1 DEF")
	var n := 0
	for i in 2000:
		var q := _arena()
		(q[0] as Battle)._hit(q[1], q[2], 1.2, Element.Type.FISICO, "Boulder Smash")
		if (q[2] as Combatant).def_buff == -1: n += 1
	ok(n > 320 and n < 480, "equal LUK: ~20%% (%d / 2000)" % n)
	print("D1005_%s" % ("PASS" if _f == 0 else "FAIL"))
	quit(1 if _f > 0 else 0)
