extends SceneTree
## D-1062: MP regen = 10 + MAG / 5 up to MAG 25 (at most +5), then +1 per 10 MAG above 25; 8 s pulse; limited to the max MP.
## Roda com: godot --headless --path . --script res://tests/battle/test_d1062_mp_regen.gd


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — REGENERAÇÃO DE MP (D-1062)")
	print("=================================================================")
	var c := Combatant.new("Teste", 100, 10, 0.5, true, 10)
	c.max_mp = 100
	var table := {0: 10, 4: 10, 5: 11, 10: 12, 12: 12, 24: 14, 25: 15, 26: 15, 34: 15, 35: 16, 45: 17, 100: 22}
	for m in table:
		c.mag = int(m)
		assert(c.mp_regen_amount() == int(table[m]), "MAG %d deve dar %d (deu %d)" % [m, table[m], c.mp_regen_amount()])
	print("  [PASS] Fórmula: 10 + MAG/5 até MAG 25, depois +1 a cada 10 MAG.")

	var got: Array[int] = []
	c.mp_regenerated.connect(func(_c: Combatant, n: int) -> void: got.append(n))
	c.mag = 12
	c.mp = 50
	c.in_battle = true
	c.tick_mp_regen(7.9)
	assert(c.mp == 50 and got.is_empty(), "Antes de 8 s nada acontece")
	c.tick_mp_regen(0.2)
	assert(c.mp == 62 and got == [12], "Em 8 s recupera 12 (10 + 12/5)")
	print("  [PASS] O pulso de 8 s recupera o valor escalado e emite a quantia.")

	c.mp = 95
	got.clear()
	c.tick_mp_regen(8.1)
	assert(c.mp == 100 and got == [5], "Limitado ao MP máximo: recebeu só 5")
	c.tick_mp_regen(8.1)
	assert(got == [5], "Com o MP cheio não há pulso")
	print("  [PASS] Limitado ao MP máximo e sem pulso com o MP cheio.")

	print("\n=== TODOS OS TESTES D-1062 PASSARAM ===\n")
	quit()
