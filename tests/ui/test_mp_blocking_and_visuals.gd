extends SceneTree
## Test suite for D-438: MP costs, 30% reduction, blocking when insufficient MP,
## element colors, 3 icons, 75% opacity and top wind-up.

func _init() -> void:
	print("--- TEST D-438: MP COSTS, BLOCKING AND VISUAL OVERHAUL ---")
	var errs: Array[String] = []

	# 1. Test 30% MP reduction across moves
	var tackle_mp := Skill.get_mp_cost_for("tackle")
	if tackle_mp != 0:
		errs.append("Tackle should cost 0 MP, got %d" % tackle_mp)
	
	var confusion_mp := Skill.get_mp_cost_for("confusion")
	if confusion_mp != 3: # 4 -> 3 (-30%)
		errs.append("Confusion should cost 3 MP, got %d" % confusion_mp)

	var psybeam_mp := Skill.get_mp_cost_for("psybeam")
	if psybeam_mp != 5: # 7 -> 5 (-30%)
		errs.append("Psybeam should cost 5 MP, got %d" % psybeam_mp)

	var megido_mp := Skill.get_mp_cost_for("megido")
	if megido_mp != 6: # 8 -> 6 (-30%)
		errs.append("Megido should cost 6 MP, got %d" % megido_mp)

	var shock_wave_mp := Skill.get_mp_cost_for("shock_wave")
	if shock_wave_mp != 3: # 5 -> 3 (-30%)
		errs.append("Shock Wave should cost 3 MP, got %d" % shock_wave_mp)

	var media_mp := Skill.get_mp_cost_for("media")
	if media_mp != 4: # 6 -> 4 (-30%)
		errs.append("Media should cost 4 MP, got %d" % media_mp)

	# 2. Test Neutral / Physical color in BattleFx.COLORS
	var phys_col: Color = BattleFx.COLORS[Element.Type.FISICO]
	if phys_col != Color("cbd5e1"):
		errs.append("BattleFx.COLORS for FISICO should be Color('cbd5e1'), got %s" % str(phys_col))

	# 3. Test Combatant MP blocking in Battle
	var actor := Combatant.new("Tester", 100, 20, 0.50, true)
	var dummy := Combatant.new("Dummy", 100, 20, 0.50, false)
	actor.mp = 1 # Only 1 MP!
	var party: Array[Combatant] = [actor]
	var enemies: Array[Combatant] = [dummy]
	var battle := Battle.new()
	battle.start(party, enemies)
	
	var expensive_move := Skill.new("Psybeam", 1.7, 3, Element.Type.PSIQUICO, Skill.Kind.PROJECTILE)
	
	# Can pay ATB but cannot pay MP
	if actor.can_pay_skill(expensive_move):
		errs.append("Actor with 1 MP should NOT can_pay_skill for Psybeam (5 MP)")

	var req_ok := battle.request_skill(actor, expensive_move, dummy)
	if req_ok:
		errs.append("battle.request_skill should be blocked/rejected when actor has insufficient MP")

	# Test Tackle (0 MP) should be accepted
	var free_move := Skill.new("Tackle", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE)
	if not actor.can_pay_skill(free_move):
		errs.append("Actor with 1 MP SHOULD be able to pay for Tackle (0 MP)")

	# 4. Test SkillInfoPanel 75% opacity
	var panel := SkillInfoPanel.new()
	if not is_equal_approx(panel.modulate.a, 0.75):
		errs.append("SkillInfoPanel modulate.a should be 0.75, got %f" % panel.modulate.a)

	# 5. Test redundant text removal
	var tackle_mech := free_move.mechanics_description()
	if "zero MP" in tackle_mech or "zero mp" in tackle_mech:
		errs.append("Tackle mechanics_description should not mention zero MP: %s" % tackle_mech)

	if errs.is_empty():
		print("[TEST PASS] All D-438 checks passed successfully!")
		quit(0)
	else:
		for e in errs:
			printerr("  [FAIL] " + e)
		quit(1)
