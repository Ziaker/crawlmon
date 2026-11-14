extends SceneTree
## Unit test de LÓGICA PURA para o ATB do Combatant (regeneração, blocks, spend,
## extra acima de 5 e o ganho de MP 1,75x com ATB cheio).
## Decisões aplicáveis: D-040, D-1070, D-413, D-1062.
## Roda com: godot --headless --path . --script res://tests/battle/unit/test_unit_atb.gd

var _failures := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] " + msg)
	else:
		_failures += 1
		print("  [FAIL] " + msg)


func _initialize() -> void:
	print("=================================================================")
	print("   CRAWMON — UNIT: ATB DO COMBATANT (D-040 / D-1070)")
	print("=================================================================")

	# --- Regeneração contínua, teto de 5 blocos ---
	var c := Combatant.new("ATB", 100, 10, 0.5, false)
	c.agi = 0
	c.speed_buff = 0
	c.atb = 0.0
	c.tick(1.0)
	_check(is_equal_approx(c.atb, 0.5), "regeneração: 0,5 bloco/s × 1 s = 0,5 (obtido %.3f)" % c.atb)
	c.tick(100.0)
	_check(is_equal_approx(c.atb, Combatant.BLOCKS), "regeneração para no teto de 5 blocos")

	# --- blocks() = atb + extra; spend() gasta o extra primeiro ---
	var d := Combatant.new("Blocos", 100, 10, 0.5, false)
	d.atb = 0.0
	d.extra = 0.0
	d.add_atb(7.0)
	_check(is_equal_approx(d.atb, 5.0) and is_equal_approx(d.extra, 2.0), "add_atb(7): 5 na barra + 2 extra")
	_check(is_equal_approx(d.blocks(), 7.0), "blocks() = 5 + 2 = 7 (extra acima de 5 blocos)")
	d.spend(3.0)
	_check(is_equal_approx(d.extra, 0.0) and is_equal_approx(d.atb, 4.0), "spend(3) gasta o extra primeiro: 2 extra + 1 da barra → barra 4")
	_check(is_equal_approx(d.blocks(), 4.0), "blocks() depois do spend = 4")

	var e := Combatant.new("Extra", 100, 10, 0.5, false)
	e.atb = 0.0
	e.extra = 0.0
	e.add_atb(12.0)
	_check(is_equal_approx(e.atb, 5.0) and is_equal_approx(e.extra, 7.0), "add_atb(12): barra 5 + 7 extra = 12 blocos")
	e.spend(9.0)
	_check(is_equal_approx(e.extra, 0.0) and is_equal_approx(e.atb, 3.0), "spend(9) com 7 extra: sobra 2 na barra → 5 - 2 = 3")

	var f := Combatant.new("Barra", 100, 10, 0.5, false)
	f.atb = 3.0
	f.extra = 0.0
	f.spend(2.0)
	_check(is_equal_approx(f.atb, 1.0) and is_equal_approx(f.extra, 0.0), "spend(2) sem extra: 3 → 1")
	f.spend(5.0)
	_check(is_equal_approx(f.atb, 0.0), "spend acima do saldo para em 0, sem negativo")

	# --- ATB cheio acelera o pulso de MP em 1,75x (D-1070) ---
	var g := Combatant.new("MP Cheio", 100, 10, 0.0, true, 0)
	g.mag = 0
	g.max_mp = 100
	g.mp = 0
	g.in_battle = true
	g.atb = Combatant.BLOCKS
	_check(g.atb_full() and is_equal_approx(g.mp_regen_rate(), 1.75), "ATB cheio: atb_full() e ritmo 1,75x")
	var got := [0]
	g.mp_regenerated.connect(func(_c: Combatant, n: int) -> void: got[0] += n)
	var t := 0.0
	while got[0] == 0 and t < 9.0:
		g.atb = Combatant.BLOCKS
		g.tick(0.05)
		t += 0.05
	_check(got[0] == 10, "pulso de MP com MAG 0 = 10")
	_check(t > 4.4 and t < 4.8, "com ATB cheio o pulso vem em ~4,57 s (veio %.2f)" % t)
	_check(is_equal_approx(g.mp_regen_left(), Combatant.MP_REGEN_INTERVAL / 1.75), "mp_regen_left() usa o ritmo 1,75x")

	var h := Combatant.new("MP Normal", 100, 10, 0.0, true, 0)
	h.mag = 0
	h.max_mp = 100
	h.mp = 0
	h.in_battle = true
	h.atb = 3.0
	var got2 := [0]
	h.mp_regenerated.connect(func(_c: Combatant, n: int) -> void: got2[0] += n)
	var t2 := 0.0
	while got2[0] == 0 and t2 < 9.0:
		h.tick(0.05)
		t2 += 0.05
	_check(t2 > 7.9 and t2 < 8.2, "sem ATB cheio o pulso continua em 8 s (veio %.2f)" % t2)
	_check(not h.atb_full(), "no pulso sem cheio o ATB segue abaixo de 5 (%.2f)" % h.atb)

	print("=================================================================")
	if _failures == 0:
		print("ATB_UNIT_TEST_PASS")
	else:
		print("ATB_UNIT_TEST_FAIL (%d falhas)" % _failures)
	print("=================================================================")
	quit(1 if _failures > 0 else 0)
