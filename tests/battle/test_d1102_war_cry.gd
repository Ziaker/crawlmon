extends SceneTree
## D-1102: War Cry (3 ATB / 3 MP, wind-up 0,3 s, STATUS, Neutral).
## Interrompe somente inimigos em WINDUP, sem dano/STUN/empurrão; +1 Burst único por execução
## se ao menos um inimigo for interrompido.
## D-1127: War Cry NÃO pausa o motor (exceção experimental à D-031); o dado status_pause = 1,3 s
## continua na ficha, mas não é aplicado.
## Roda com: godot --headless --path . --script res://tests/battle/test_d1102_war_cry.gd


func _init() -> void:
	print("\n=================================================================")
	print("   CRAWLMON — TESTES DO WAR CRY (D-1102)")
	print("=================================================================")

	var b := Battle.new()
	var hero := Combatant.new("Orc", 100, 10, 0.45, true)
	hero.max_mp = 20
	hero.mp = 20
	var war := Skill.from_id(&"war_cry")
	assert(war != null, "War Cry existe no catálogo")
	hero.skills.append(war)
	var foe1 := Combatant.new("Slime", 50, 8, 0.40, false)
	var foe2 := Combatant.new("Cyclops", 80, 9, 0.40, false)
	var party: Array[Combatant] = [hero]
	var foes: Array[Combatant] = [foe1, foe2]
	b.start(party, foes)
	b.debug_roll = 1

	# 1. Ficha: 3 ATB / 3 MP / 0,3 s / STATUS / Neutral / AoE inimiga / pausa 1,3 s.
	assert(war.cost == 3, "War Cry custa 3 ATB")
	assert(war.mp_cost == 3, "War Cry custa 3 MP")
	assert(is_equal_approx(war.windup, 0.3), "Wind-up de 0,3 s")
	assert(war.kind == Skill.Kind.STATUS, "War Cry é STATUS")
	assert(war.element == Element.Type.FISICO, "Elemento Neutral/FISICO")
	assert(war.is_aoe and not war.is_friendly, "AoE inimiga")
	assert(war.data != null and is_equal_approx(war.data.status_pause, 1.3), "Pausa total de 1,3 s")
	assert(war.effect_line().to_lower().contains("interrupt"), "A ficha descreve a interrupção")
	print("  [PASS] Ficha: 3 ATB / 3 MP / 0,3 s / STATUS / Neutral / AoE inimiga / pausa 1,3 s.")

	# 2. Dois inimigos em WINDUP: os dois são cancelados, sem dano nem empurrão; +1 Burst único.
	var tackle := Skill.new("Tackle", 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.5)
	foe1.atb = 3.0
	foe2.atb = 3.0
	assert(b.use_skill(foe1, tackle, hero), "Inimigo 1 inicia o wind-up")
	assert(b.use_skill(foe2, tackle, hero), "Inimigo 2 inicia o wind-up")
	assert(b.incoming.size() == 2, "Os dois ataques estão em WINDUP")
	var inc1: Incoming = b.incoming[0]
	var inc2: Incoming = b.incoming[1]
	var pos1 := foe1.pos
	var pos2 := foe2.pos
	var interrupted_actors: Array[Combatant] = []
	b.action_interrupted.connect(func(c: Combatant) -> void: interrupted_actors.append(c))
	hero.atb = 3.0
	hero.mp = 3
	assert(b.use_skill(hero, war, foe1), "War Cry começa")
	assert(is_equal_approx(hero.atb, 0.0) and hero.mp == 0, "Paga 3 ATB e 3 MP")
	assert(b._status_pause == null, "D-1127: War Cry não pausa o motor")
	var paused := 0.0
	while not b._war_cry_active.is_empty() and paused < 5.0:
		b._process(0.01)
		paused += 0.01
	assert(paused >= 1.00 and paused <= 1.60, "War Cry termina em ~1,2 s sem pausa (medido %.2f)" % paused)
	assert(not b.incoming.has(inc1) and not b.incoming.has(inc2), "Os dois wind-ups saíram da fila")
	assert(inc1.interrupted and inc2.interrupted, "Os dois foram interrompidos")
	assert(foe1.pos.is_equal_approx(pos1) and foe2.pos.is_equal_approx(pos2), "Sem empurrão")
	assert(foe1.hp == 50 and foe2.hp == 80, "Sem dano")
	assert(interrupted_actors.size() == 2 and interrupted_actors.has(foe1) and interrupted_actors.has(foe2), "D-1105: cada interrompido emite action_interrupted")
	assert(hero.burst == 1, "+1 Burst, mesmo com dois inimigos")
	var burst_tokens := 0
	for r in b.rewards:
		if r.kind == "burst":
			burst_tokens += 1
			assert(r.source == foe1, "O Burst nasce no inimigo interrompido, não no lançador")
			assert(r.float_time < 0.2 and r.fly_time < 0.2, "O Burst voa rápido até o slot")
	assert(burst_tokens == 1, "Um único token de Burst")
	print("  [PASS] Dois wind-ups cancelados, sem dano/empurrão, +1 Burst único (sem pausa, %.2f s)." % paused)

	# 3. Ninguém em WINDUP: paga o custo, não interrompe e não dá Burst.
	hero.atb = 3.0
	hero.mp = 3
	hero.burst = 0
	hero.pending_burst = 0
	b.rewards.clear()
	assert(b.use_skill(hero, war, foe1), "War Cry começa sem alvo em wind-up")
	assert(b._status_pause == null, "D-1127: War Cry não pausa o motor")
	paused = 0.0
	while not b._war_cry_active.is_empty() and paused < 5.0:
		b._process(0.01)
		paused += 0.01
	assert(hero.burst == 0, "Sem interrupção, sem Burst")
	assert(b.rewards.is_empty(), "Nenhum token de recompensa")
	print("  [PASS] Sem wind-up: paga o custo e não faz nada (sem Burst).")

	# 4. Ataque já resolvido (TRAVEL/STRIKE) não é cancelado.
	foe1.atb = 3.0
	foe1.speed_buff = 0
	assert(b.use_skill(foe1, tackle, hero), "Inimigo 1 inicia outro wind-up")
	var late_inc: Incoming = b.incoming[b.incoming.size() - 1]
	foe1.atb = 0.0
	foe2.atb = 0.0
	for i in 220:  # 2,2 s: o wind-up termina e o ataque entra em _landing.
		b._process(0.01)
	var still_incoming := false
	for inc in b.incoming:
		if inc == late_inc:
			still_incoming = true
	assert(not still_incoming, "O ataque já saiu do WINDUP")
	hero.atb = 3.0
	hero.mp = 3
	assert(b.use_skill(hero, war, foe1), "War Cry começa com o ataque já resolvido")
	assert(b._status_pause == null, "D-1127: War Cry não pausa o motor")
	var late_wait := 0.0
	while not b._war_cry_active.is_empty() and late_wait < 5.0:
		b._process(0.01)
		late_wait += 0.01
	assert(not late_inc.interrupted, "War Cry não cancela ataque fora do WINDUP")
	print("  [PASS] Ataque fora do WINDUP não é cancelado.")

	print("\n  TODOS OS TESTES DO WAR CRY PASSARAM.\n")
	quit()
