extends SceneTree
## D-1103: Javelin Throw (2 ATB / 5 MP, wind-up 0,75 s, 1,2x ATK).
## Crítico = clamp(10% + (LUK atacante - LUK alvo) + 20% x vida perdida, 0..100).
## Roda com: godot --headless --path . --script res://tests/battle/test_d1103_javelin_crit.gd


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — TESTES DO JAVELIN THROW (D-1103)")
	print("=================================================================")

	var b := Battle.new()
	var attacker := Combatant.new("Orc", 100, 10, 0.45, true)
	var target := Combatant.new("Gible", 100, 10, 0.40, false)
	attacker.luk = 0
	target.luk = 0

	var javelin := Skill.from_id(&"javelin_throw")
	assert(javelin != null, "Javelin Throw existe no catálogo")
	assert(javelin.cost == 2, "2 ATB")
	assert(javelin.mp_cost == 5, "5 MP")
	assert(is_equal_approx(javelin.windup, 0.75), "Wind-up de 0,75 s")
	assert(is_equal_approx(javelin.power, 1.2), "Dano de 1,2x")
	assert(javelin.kind == Skill.Kind.PROJECTILE, "Projétil")
	assert(javelin.element == Element.Type.FISICO, "Elemento Neutral/FISICO")
	assert(not javelin.is_aoe and not javelin.is_friendly, "Alvo único inimigo")
	print("  [PASS] Ficha: 2 ATB / 5 MP / 0,75 s / 1,2x / projétil / Neutral / alvo único.")

	# 1. Vida cheia: 10% + LUK.
	assert(is_equal_approx(b.crit_chance_for(attacker, target, "Javelin Throw"), 0.10), "Vida cheia = 10%")
	print("  [PASS] Vida cheia: 10%.")

	# 2. Vida perdida entra linear: 50% de HP = +10 pp; perto de 0 = +20 pp.
	target.hp = 50
	assert(is_equal_approx(b.crit_chance_for(attacker, target, "Javelin Throw"), 0.20), "50% de HP = 20%")
	target.hp = 1
	var near_zero := b.crit_chance_for(attacker, target, "Javelin Throw")
	assert(near_zero > 0.29 and near_zero < 0.30, "Perto de 0% de HP = ~30% (" + String.num(near_zero, 4) + ")")
	print("  [PASS] Vida perdida: 50% = 20%; perto de 0% = " + String.num(near_zero * 100.0, 2) + "%.")

	# 3. LUK entra uma vez (D-150), sem escalar com a vida.
	target.hp = 100
	attacker.luk = 10
	assert(is_equal_approx(b.crit_chance_for(attacker, target, "Javelin Throw"), 0.20), "LUK +10 = +10 pp")
	target.hp = 50
	assert(is_equal_approx(b.crit_chance_for(attacker, target, "Javelin Throw"), 0.30), "LUK +10 e 50% de HP = 30%")
	target.hp = 1
	var with_luk := b.crit_chance_for(attacker, target, "Javelin Throw")
	assert(with_luk > 0.39 and with_luk < 0.40, "LUK +10 e perto de 0% = ~40% (" + String.num(with_luk, 4) + ")")
	print("  [PASS] LUK +10 soma 10 pp e não escala com a vida.")

	# 4. LUK negativa: o clamp é só no fim; a vida perdida não apaga a penalidade.
	attacker.luk = 0
	target.luk = 20
	target.hp = 50
	assert(is_equal_approx(b.crit_chance_for(attacker, target, "Javelin Throw"), 0.0), "LUK -20 e 50% de HP = 0%")
	target.hp = 1
	var negative_luk := b.crit_chance_for(attacker, target, "Javelin Throw")
	assert(negative_luk > 0.09 and negative_luk < 0.10, "LUK -20 e perto de 0% = ~9,8% (" + String.num(negative_luk, 4) + ")")
	print("  [PASS] LUK negativa: clamp só no fim, sem apagar a penalidade.")

	# 5. Teto de 100% e outras Moves intactas.
	attacker.luk = 1000
	target.hp = 1
	assert(is_equal_approx(b.crit_chance_for(attacker, target, "Javelin Throw"), 1.0), "Chance final limitada a 100%")
	attacker.luk = 0
	target.hp = 1
	assert(is_equal_approx(b.crit_chance_for(attacker, target, "Tackle"), 0.10), "Outras Moves continuam em 10%")
	print("  [PASS] Teto de 100% e outras Moves intactas.")

	print("\n  TODOS OS TESTES DO JAVELIN THROW PASSARAM.\n")
	quit()
