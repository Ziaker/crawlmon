extends SceneTree
## D-1007: an AI target with React.EVADE dodges at a random moment between the wind-up and the contact
## (some during the wind-up, some after it). godot --headless --path . --script res://tests/battle/test_d1007_ai_dodge.gd
var _phases: Array = []


func _init() -> void:
	for i in 80:
		var b := Battle.new()
		var p := Combatant.new("P", 999, 10, 0.5, true)
		p.place(Vector3.ZERO, PI)
		var e := Combatant.new("E", 999, 10, 0.5, false)
		e.place(Vector3(0, 0, -10), 0.0)
		var ally := Combatant.new("A", 999, 10, 0.5, true)
		ally.place(Vector3(3, 0, 0), PI)
		for c in [p, e, ally]:
			c.act_policy = Combatant.Act.HOLD
		ally.react_policy = Combatant.React.EVADE
		b.start([p, ally], [e])
		ally.atb = 5.0
		e.atb = 5.0
		b.manual_evaded.connect(func(_a: Combatant, inc) -> void: _phases.append(int(inc.phase) if inc.resolved else -1))
		b.use_skill(e, Skill.basic(), ally)
		var t := 0.0
		while t < 5.0:
			b._process(1.0 / 30.0)
			t += 1.0 / 30.0
	var during := _phases.count(-1)
	var after := _phases.size() - during
	print("dodges=%d (wind-up %d, after %d) of 80" % [_phases.size(), during, after])
	print("D1007_%s" % ("PASS" if during > 0 and after > 0 else "FAIL"))
	quit()
