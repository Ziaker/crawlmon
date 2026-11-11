extends SceneTree
## D-1025: Tidal Surge is the Slime's Water bounce. Main hit 100%; up to two bounces (75% after 0.3 s, 50% after
## 0.6 s) to the nearest living enemy measured from the last target. Each bounce is a normal hit (weakness, crit,
## manual/auto evade), stops the chain if evaded, stops if the target died before the hit and continues if the target
## died from the hit. No extra ATB/Burst.
## godot --headless --path . --script res://tests/battle/test_d1025_tidal_surge.gd

var _fails := 0
var _hits: Array = []
var _time := 0.0


func ok(c: bool, m: String) -> void:
	print("  [PASS] " if c else "  [FAIL] ", m)
	if not c:
		_fails += 1


func _on_hit(att: Combatant, tgt: Combatant, _el: Element.Type, info: Dictionary) -> void:
	_hits.append({"at": _time, "attacker": att, "target": tgt, "info": info, "atb": att.atb, "burst": att.burst})


func _skill() -> Skill:
	for s in Skill.library_skills():
		if s.display_name == "Tidal Surge":
			return s
	return null


func _arena(n: int, hp := 999) -> Array:
	var b := Battle.new()
	var p := Combatant.new("Slime", 999, 10, 0.5, true)
	p.place(Vector3.ZERO, PI)
	var es: Array[Combatant] = []
	var positions := [Vector3(0, 0, -5), Vector3(4, 0, -10), Vector3(-4, 0, -12)]
	for i in n:
		var e := Combatant.new("E%d" % i, hp, 1, 0.5, false)
		e.place(positions[i], 0.0)
		e.weaknesses.clear()
		es.append(e)
	for c in [p] + es:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	b.start([p], es)
	b.debug_roll = 1  # hit, no crit, no automatic evade
	p.max_mp = 20
	p.mp = 20
	p.add_atb(5.0)
	_hits.clear()
	_time = 0.0
	b.hit_resolved.connect(_on_hit)
	return [b, p, es]


func _advance(b: Battle, seconds: float) -> void:
	var n := int(ceil(seconds / 0.02))
	for i in n:
		b._process(0.02)
		_time += 0.02
		if _hits.size() >= 3:
			break


func _advance_until_bounce(b: Battle, index: int, window: float) -> Incoming:
	for i in 400:
		b._process(0.02)
		_time += 0.02
		for inc in b._landing:
			if inc.bounce_index == index and inc.phase == Incoming.Phase.TRAVEL and (inc.phase_len() - inc.phase_time) <= window:
				return inc
		if _hits.size() >= 3:
			break
	return null


func _init() -> void:
	var sk := _skill()
	ok(sk != null, "Tidal Surge exists in the library")
	if sk != null:
		ok(sk.mp_cost == 5 and sk.cost == 2 and is_equal_approx(sk.windup, 0.8), "2 ATB + 5 MP, 0.8 s")
		ok(sk.power == 1.0 and sk.element == Element.Type.AGUA_GELO and sk.kind == Skill.Kind.PROJECTILE, "Water, magical projectile, power 1.0")
		ok(sk.mechanics_description().contains("75%") and sk.mechanics_description().contains("0.6s"), "sheet states 75% and the 0.6 s second bounce")

	# The DQT Slime owns it and has the 20 MP for it.
	var dqt := DqtTestParty.build(true)
	var slime: Combatant = dqt[1]
	var has_move := false
	for s in slime.skills:
		if s.display_name == "Tidal Surge":
			has_move = true
	ok(has_move, "DQT Slime lists Tidal Surge")
	ok(slime.max_mp >= 5, "DQT Slime has MP for the 5 MP move")

	# 1. Three living enemies: main + two bounces, in nearest order.
	var a := _arena(3)
	var b := a[0] as Battle
	var p := a[1] as Combatant
	var es: Array = a[2]
	b.use_skill(p, sk, es[0])
	_advance(b, 4.0)
	ok(_hits.size() == 3, "three hits (main + two bounces), got %d" % _hits.size())
	if _hits.size() == 3:
		ok((_hits[0]["target"] as Combatant) == es[0], "main hit on the declared target")
		ok((_hits[1]["target"] as Combatant) == es[1], "first bounce on the nearest enemy from the main target")
		ok((_hits[2]["target"] as Combatant) == es[2], "second bounce on the next nearest enemy")
		ok(is_equal_approx(float(_hits[0]["info"]["power"]), 1.0), "main power 100%")
		ok(is_equal_approx(float(_hits[1]["info"]["power"]), 0.75), "first bounce power 75%")
		ok(is_equal_approx(float(_hits[2]["info"]["power"]), 0.5), "second bounce power 50%")
		ok(bool(_hits[1]["info"].get("bounce", false)) and bool(_hits[2]["info"].get("bounce", false)), "bounces are flagged as bounces")
		ok(int(_hits[1]["info"].get("gain", -1)) == 0 and int(_hits[2]["info"].get("gain", -1)) == 0, "bounces grant no ATB")
		ok(is_equal_approx(float(_hits[1]["atb"]), float(_hits[0]["atb"])) and is_equal_approx(float(_hits[2]["atb"]), float(_hits[0]["atb"])), "attacker ATB unchanged by the bounces")
		ok(int(_hits[1]["burst"]) == int(_hits[0]["burst"]) and int(_hits[2]["burst"]) == int(_hits[0]["burst"]), "no extra Burst")
		var gap1: float = float(_hits[1]["at"]) - float(_hits[0]["at"])
		var gap2: float = float(_hits[2]["at"]) - float(_hits[1]["at"])
		ok(gap1 > 0.25 and gap1 < 0.45, "first bounce travels ~0.3 s (%.2f)" % gap1)
		ok(gap2 > 0.55 and gap2 < 0.75, "second bounce travels ~0.6 s (%.2f)" % gap2)

	# 2. One enemy: no bounce.
	var one := _arena(1)
	(one[0] as Battle).use_skill(one[1], sk, (one[2] as Array)[0])
	_advance(one[0], 3.0)
	ok(_hits.size() == 1, "one enemy: a single hit, no bounce")

	# 3. Main target evaded: no bounce at all.
	var ev := _arena(3)
	(ev[0] as Battle).debug_roll = 2  # automatic evade
	(ev[0] as Battle).use_skill(ev[1], sk, (ev[2] as Array)[0])
	_advance(ev[0], 2.0)
	ok(_hits.size() == 1 and bool(_hits[0]["info"].get("evaded", false)), "main evade: one evaded hit, no bounce")

	# 4. First bounce evaded manually: the chain stops.
	var me := _arena(3)
	var mb := me[0] as Battle
	var mes: Array = me[2]
	mb.use_skill(me[1], sk, mes[0])
	var binc := _advance_until_bounce(mb, 1, 0.24)
	ok(binc != null, "first bounce reached the manual-evade window")
	if binc != null:
		(mes[1] as Combatant).add_atb(3.0)
		ok(mb.try_evade(mes[1], binc), "manual Evade accepted on the first bounce")
		_advance(mb, 1.2)
		ok(_hits.size() == 1, "chain stops after the bounce is evaded")

	# 5. Target dies before the bounce lands: the chain stops.
	var db := _arena(3)
	var dbb := db[0] as Battle
	var dbe: Array = db[2]
	dbb.use_skill(db[1], sk, dbe[0])
	var dinc := _advance_until_bounce(dbb, 1, 0.20)
	ok(dinc != null, "first bounce created before the death test")
	if dinc != null:
		(dbe[1] as Combatant).take_damage(9999)
		_advance(dbb, 1.2)
		ok(_hits.size() == 1, "target dead before the hit: no bounce hit, no next bounce")

	# 6. Target dies from the hit: the chain continues.
	var dh := _arena(3, 1)
	(dh[0] as Battle).use_skill(dh[1], sk, (dh[2] as Array)[0])
	_advance(dh[0], 4.0)
	ok(_hits.size() == 3, "deaths from the move still let the chain continue (got %d)" % _hits.size())
	if _hits.size() == 3:
		ok(not (dh[2] as Array)[0].is_alive() and not (dh[2] as Array)[1].is_alive() and not (dh[2] as Array)[2].is_alive(), "all three died from the chain")

	print("D1025_%s" % ("PASS" if _fails == 0 else "FAIL"))
	quit(1 if _fails > 0 else 0)
