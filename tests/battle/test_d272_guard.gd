extends SceneTree
## D-272: Guard (1 ATB, 2 s, sem cancelar, ATB pausado, Burst não paga, reduz o dano com arredondamento
## para cima e termina no contato; Brick Break quebra, causa dano normal e dá 1 ATB) e hit stun +0,30 s.
## Roda com: godot --headless --path . --script res://tests/battle/test_d272_guard.gd


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — TESTES DO GUARD (D-272)")
	print("=================================================================")

	var b := Battle.new()
	var hero := Combatant.new("Pancham", 100, 10, 0.45, true)
	hero.skills.append(Skill.new("Mach Punch", 1.0, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 0.2))
	var foe := Combatant.new("Gible", 100, 10, 0.42, false)
	var party: Array[Combatant] = [hero]
	var foes: Array[Combatant] = [foe]
	b.start(party, foes)
	b.debug_roll = 1  # No random critical hit in the numbers below.
	var ended: Array[String] = []
	b.guard_ended.connect(func(_c: Combatant, reason: String) -> void: ended.append(reason))

	# 1. Cost: 1 ATB; Burst does not pay it.
	hero.atb = 0.0
	hero.extra = 0.0
	hero.burst = 1
	assert(not b.can_guard(hero), "Sem ATB, o Burst não paga o Guard")
	assert(b.guard_block_reason(hero) == "falta ATB")
	hero.burst = 0
	hero.atb = 3.0
	assert(b.use_guard(hero), "Com ATB suficiente o Guard começa")
	assert(is_equal_approx(hero.atb, 2.0), "O Guard custa exatamente 1 ATB")
	assert(hero.is_guarding() and is_equal_approx(hero.guard_timer, Battle.GUARD_SECONDS))
	print("  [PASS] Guard custa 1 ATB e o Burst não o paga.")

	# 2. While guarding: no other action, and the ATB is paused.
	assert(Battle.GUARD_SECONDS == 2.0, "O Guard dura 2 segundos")
	assert(not b.use_skill(hero, hero.skills[0], foe), "Em Guard, nenhum Move")
	assert(not b.request_skill(hero, hero.skills[0], foe), "Em Guard, nem enfileirar Move")
	assert(not b.can_step(hero, 1), "Em Guard, nenhum passo")
	assert(not b.can_guard(hero), "Em Guard, não renova")
	var atb_before := hero.atb
	hero.tick(0.5)
	assert(is_equal_approx(hero.atb, atb_before), "O ATB fica pausado durante o Guard")
	print("  [PASS] Em Guard não há outra ação e o ATB não sobe.")

	# 3. Expires after 2 s, with no way to cancel it.
	hero.tick(0.5)
	hero.tick(0.5)
	assert(hero.is_guarding())
	hero.tick(0.5)
	assert(not hero.is_guarding() and ended == ["expired"], "O Guard expira em 2 s")
	hero.tick(1.0)
	assert(hero.atb > atb_before, "Depois do Guard o ATB volta a subir")
	print("  [PASS] O Guard expira em 2 s e o ATB volta a subir.")

	# 4. Contact: damage reduced (rounded up) and the Guard ends.
	ended.clear()
	hero.set_hp_instant(100)
	hero.atb = 3.0
	assert(b.use_guard(hero))
	var info := b._hit(foe, hero, 1.0, Element.Type.FISICO, "Tackle")
	assert(int(info["dmg"]) == 5, "10 de dano com redução provisória de 50% = 5")
	assert(info["guard"] == "absorbed")
	assert(not hero.is_guarding() and ended == ["hit"], "O contato destrói o Guard")
	assert(hero.hp == 95, "O HP do jogador desce imediatamente (D-347): 95")
	# Rounded up: 3 of damage -> ceil(1.5) = 2.
	hero.atb = 3.0
	foe.base_attack = 3
	assert(b.use_guard(hero))
	info = b._hit(foe, hero, 1.0, Element.Type.FISICO, "Tackle")
	assert(int(info["dmg"]) == 2, "3 de dano com 50%% = 1,5 arredondado para cima = 2")
	foe.base_attack = 10
	print("  [PASS] O contato reduz o dano (arredondando para cima) e termina o Guard.")

	# 5. Without Guard the same hit is normal.
	info = b._hit(foe, hero, 1.0, Element.Type.FISICO, "Tackle")
	assert(int(info["dmg"]) == 10 and info["guard"] == "", "Sem Guard o dano é normal")
	print("  [PASS] Sem Guard o dano não muda.")

	# 6. Brick Break: breaks the Guard, deals the normal damage, +1 ATB to the attacker.
	ended.clear()
	hero.set_hp_instant(100)
	hero.atb = 3.0
	foe.atb = 0.0
	foe.extra = 0.0
	assert(b.use_guard(hero))
	info = b._hit(foe, hero, 1.0, Element.Type.FISICO, "Brick Break")
	assert(int(info["dmg"]) == 10, "Brick Break causa o dano normal")
	assert(info["guard"] == "broken" and ended == ["broken"] and not hero.is_guarding())
	assert(is_equal_approx(foe.blocks(), 1.0), "Brick Break dá 1 ATB a quem quebra")
	print("  [PASS] Brick Break quebra o Guard, causa dano normal e dá 1 ATB.")

	# 7. The battle end clears the Guard.
	hero.atb = 3.0
	assert(b.use_guard(hero))
	foe.hp = 0
	b._check_end()
	assert(not hero.is_guarding(), "Fim da batalha limpa o Guard")
	print("  [PASS] O fim da batalha limpa o Guard.")

	# 8. Hit stun +0.30 s, globally.
	assert(is_equal_approx(AttackMotion.HIT_STUN_EXTRA, 0.30))
	assert(is_equal_approx(AttackMotion.HIT_HOLD, 0.45), "HIT_HOLD 0,15 + 0,30")
	print("  [PASS] O hit stun ganhou +0,30 s.")

	print("\n=== TODOS OS TESTES D-272 PASSARAM ===\n")
	quit()
