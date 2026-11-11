extends SceneTree
## D-1070: with the ATB full (all 5 blocks) the MP pulse timer runs 1.75x faster; otherwise 1x.
## Roda com: godot --headless --path . --script res://tests/battle/test_d1070_atb_full_mp_regen.gd


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — ATB CHEIO ACELERA O MP (D-1070)")
	print("=================================================================")
	var c := Combatant.new("Teste", 100, 10, 0.5, true, 0)
	c.max_mp = 100
	c.in_battle = true
	c.mp = 10
	c.atb = 4.0
	assert(not c.atb_full() and is_equal_approx(c.mp_regen_rate(), 1.0), "ATB 4: ritmo normal")
	c.atb = Combatant.BLOCKS
	assert(c.atb_full() and is_equal_approx(c.mp_regen_rate(), 1.75), "ATB 5: ritmo 1,75x")
	print("  [PASS] Ritmo 1x sem ATB cheio e 1,75x com ATB cheio.")

	# 8 s / 1.75 = 4.571 s: the pulse comes then, not at 8 s.
	c.mp_regen_timer = 0.0
	c.atb = Combatant.BLOCKS
	var t := 0.0
	var got := [0]  # an array: a lambda copies plain variables but shares arrays
	c.mp_regenerated.connect(func(_c: Combatant, n: int) -> void: got[0] += n)
	while got[0] == 0 and t < 9.0:
		c.atb = Combatant.BLOCKS  # the ATB stays full in this test
		c.tick(0.05)
		t += 0.05
	assert(t > 4.4 and t < 4.8, "Com ATB cheio o pulso vem em ~4,57 s (veio em %.2f)" % t)
	print("  [PASS] Com ATB cheio o pulso de MP vem em %.2f s (8 / 1,75 = 4,57)." % t)

	# Without a full ATB it still takes 8 s (the tick does not fill the ATB faster than 5 blocks / enough here: keep it at 3).
	var d := Combatant.new("Teste2", 100, 10, 0.0001, true, 0)
	d.max_mp = 100
	d.in_battle = true
	d.mp = 10
	d.atb = 3.0
	var t2 := 0.0
	var got2 := [0]
	d.mp_regenerated.connect(func(_c: Combatant, n: int) -> void: got2[0] += n)
	while got2[0] == 0 and t2 < 9.0:
		d.tick(0.05)
		t2 += 0.05
	assert(t2 > 7.9 and t2 < 8.2, "Sem ATB cheio o pulso vem em 8 s (veio em %.2f)" % t2)
	print("  [PASS] Sem ATB cheio o pulso continua em %.2f s." % t2)

	assert(is_equal_approx(c.mp_regen_left(), maxf(Combatant.MP_REGEN_INTERVAL - c.mp_regen_timer, 0.0) / 1.75), "O tempo restante mostrado usa o ritmo")
	print("\n=== TODOS OS TESTES D-1070 PASSARAM ===\n")
	quit()
