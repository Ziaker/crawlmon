extends SceneTree
## D-1203: the Dread only shows while the leader can pay the Evade (ATB blocks >= cost). Visual rule only.

class FakeBattle:
	var cost := 3.0
	func evade_cost(_a) -> float:
		return cost

class FakeLeader:
	var b := 0.0
	func blocks() -> float:
		return b


func _init() -> void:
	var bt := FakeBattle.new()
	var l := FakeLeader.new()
	var ok := true
	for case in [[0.0, 3.0, false], [2.9, 3.0, false], [3.0, 3.0, true], [5.0, 3.0, true], [1.9, 2.0, false], [2.0, 2.0, true]]:
		l.b = case[0]
		bt.cost = case[1]
		var got: bool = FxEvadeFlash.leader_can_afford_dodge(bt, l)
		if got != case[2]:
			ok = false
			print("FAIL blocks=%s cost=%s expected=%s got=%s" % [case[0], case[1], case[2], got])
	if not FxEvadeFlash.leader_can_afford_dodge(bt, null) or not FxEvadeFlash.leader_can_afford_dodge(null, l):
		ok = false
		print("FAIL null leader/battle must keep the old behavior (shown)")
	print("TEST_DREAD_ATB_D1203 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
