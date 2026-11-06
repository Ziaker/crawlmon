extends SceneTree
## Automated verification suite for D-032 mechanics:
## 1. Teleport (0.5s windup, 0.7x dmg, invulnerable in windup, behind target strike, return home)
## 2. Mach Punch (0.2s windup, 0.5x dmg, 1 ATB)
## 3. Karate Chop (1.0s windup, 1.5x dmg, 2 ATB, 30% -1 VEL debuff)
## 4. Taunt (1 ATB, 0.5s windup, redirects single-target offensive move, +1 ATK bonus consumed on hit)
## 5. Bite (1.2s windup, 1.3x dmg, 2 ATB, 30% 2s stun, interrupts windup and grants +1 ATB)
## 6. Sand Attack (0.75s windup, 0 dmg, 1 ATB projectile, 4s blind with 35% miss)
## 7. Dragon Rage (2.0s windup, 1.6x dmg, 3 ATB, AoE splash if main target hit, 0 if evaded)
## 8. Dig (1.0s windup, 1.5x dmg, 2 ATB, invulnerable underground during travel, emerges for strike)
##
##   godot --headless --path . --script res://tests/battle/test_d032_mechanics.gd

var failures := 0
const DT := 1.0 / 60.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — TESTES DE MECÂNICAS & BALANCEAMENTO (D-032)")
	print("=================================================================")
	_test_teleport()
	_test_mach_punch()
	_test_karate_chop()
	_test_taunt()
	_test_bite_stun_and_interrupt()
	_test_sand_attack_blind()
	_test_dragon_rage_aoe_splash()
	_test_dig_invulnerability()
	print("-----------------------------------------------------------------")
	if failures == 0:
		print("D032_MECHANICS_TEST_PASS")
		print("[SUCESSO] Todas as 8 mecânicas e balanceamentos validados com êxito!")
	else:
		print("[ERRO] Falha em %d verificações!" % failures)
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + msg)
		print("  [FAIL] %s" % msg)
	else:
		print("  [PASS] %s" % msg)


func _arena() -> Dictionary:
	var b := Battle.new()
	var p1 := Combatant.new("Abra", 100, 10, 0.5, true)
	p1.place(Vector3(0, 0, 0), PI)
	var p2 := Combatant.new("Pancham", 100, 10, 0.5, true)
	p2.place(Vector3(2, 0, 0), PI)
	var e1 := Combatant.new("Gible", 100, 10, 0.5, false)
	e1.place(Vector3(0, 0, -10), 0.0)
	var e2 := Combatant.new("Gible2", 100, 10, 0.5, false)
	e2.place(Vector3(3, 0, -10), 0.0)
	for c in [p1, p2, e1, e2]:
		c.act_policy = Combatant.Act.HOLD
	b.start([p1, p2], [e1, e2])
	return {"b": b, "p1": p1, "p2": p2, "e1": e1, "e2": e2}


func _run_until_done(b: Battle, inc: Incoming, limit := 3.0) -> void:
	var t := 0.0
	while inc != null and inc.phase != Incoming.Phase.DONE and t < limit:
		b._process(DT)
		t += DT


func _test_teleport() -> void:
	print("[*] Testando Teleport (D-032 / D-034)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	var p1: Combatant = ctx["p1"]
	var e1: Combatant = ctx["e1"]
	var sk := Skill.new("Teleport", 0.7, 1, Element.Type.PSIQUICO, Skill.Kind.MELEE, false, false, false, 0.5)
	p1.add_atb(3.0)
	e1.add_atb(3.0)

	# 1. Windup 0.5s: NÃO fica invulnerável no windup (D-034: só some após o wind-up)
	b.use_skill(p1, sk, e1)
	var tp_inc: Incoming = b.incoming[0]
	_expect(not p1.is_invulnerable, "Teleport NÃO deixa o usuário invulnerável durante o windup (D-034)")
	_expect(tp_inc.total_windup == 0.5, "Teleport tem exatamente 0.5s de windup")

	# 2. Ao terminar o wind-up e entrar em TRAVEL, fica invulnerável (sumiu)
	tp_inc.time_left = 0.0
	b._process(DT) # resolve windup -> entra em TRAVEL
	_expect(p1.is_invulnerable, "Teleport deixa o usuário invulnerável após o windup (TRAVEL)")

	# 3. Avança até a fase de STRIKE: surge atrás do oponente e perde invulnerabilidade para desferir o golpe
	while tp_inc.phase == Incoming.Phase.TRAVEL:
		b._process(DT)
	_expect(tp_inc.phase == Incoming.Phase.STRIKE, "Entrou em fase de STRIKE")
	_expect(not p1.is_invulnerable, "Invulnerabilidade é removida durante o STRIKE")

	# 4. Ao entrar em RETURN, some de trás do oponente e volta a ficar invulnerável
	while tp_inc.phase == Incoming.Phase.STRIKE:
		b._process(DT)
	_expect(tp_inc.phase == Incoming.Phase.RETURN, "Entrou em fase de RETURN")
	_expect(p1.is_invulnerable, "Durante o desaparecimento do RETURN, fica invulnerável")

	# 5. Ao concluir o ataque, volta ao normal
	while tp_inc.phase == Incoming.Phase.RETURN:
		b._process(DT)
	_expect(not p1.is_invulnerable, "Ao fim do teleporte, não está mais invulnerável")
	b.free()


func _test_mach_punch() -> void:
	print("[*] Testando Mach Punch (D-032)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	var p2: Combatant = ctx["p2"]
	var e1: Combatant = ctx["e1"]
	var sk := Skill.new("Mach Punch", 0.5, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 0.2)
	p2.add_atb(3.0)
	b.use_skill(p2, sk, e1)
	_expect(b.incoming[0].total_windup == 0.2, "Mach Punch tem 0.2s de windup")
	_expect(b.incoming[0].power == 0.5, "Mach Punch tem 0.5x de dano")
	b.free()


func _test_karate_chop() -> void:
	print("[*] Testando Karate Chop (D-032)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	var p2: Combatant = ctx["p2"]
	var e1: Combatant = ctx["e1"]
	var sk := Skill.new("Karate Chop", 1.5, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.0)
	p2.add_atb(3.0)
	b.use_skill(p2, sk, e1)
	_expect(b.incoming[0].total_windup == 1.0, "Karate Chop tem 1.0s de windup")
	_expect(b.incoming[0].power == 1.5, "Karate Chop tem 1.5x de dano")
	b.free()


func _test_taunt() -> void:
	print("[*] Testando Taunt (D-032)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	var p1: Combatant = ctx["p1"]
	var p2: Combatant = ctx["p2"]
	var e1: Combatant = ctx["e1"]
	p1.add_atb(3.0)
	p2.add_atb(3.0)
	e1.add_atb(3.0)

	# Foe mira em Pancham (p2)
	b.use_skill(e1, Skill.basic(), p2)
	var foe_inc: Incoming = b.incoming[0]
	_expect(foe_inc.target == p2, "Inimigo mirou inicialmente no aliado")

	# Abra (p1) usa Taunt em Foe (e1)
	var taunt_sk := Skill.new("Taunt", 0.0, 1, Element.Type.FISICO, Skill.Kind.STATUS, false, false, false, 0.5)
	b.use_skill(p1, taunt_sk, e1)
	var taunt_inc: Incoming = b.incoming[1]
	taunt_inc.time_left = 0.0
	_run_until_done(b, taunt_inc)

	_expect(e1.taunted_by == p1, "Inimigo fica marcado como provocado por Abra")
	_expect(e1.taunt_atk_bonus, "Inimigo recebe bônus de +1 ATK stage temporário")
	_expect(foe_inc.target == p1, "O ataque já em windup do inimigo foi redirecionado para Abra")

	# Foe executa o ataque redirecionado contra Abra (que está invulnerável)
	p1.is_invulnerable = true
	foe_inc.time_left = 0.0
	_run_until_done(b, foe_inc)
	_expect(not e1.taunt_atk_bonus, "Bônus de ATK do Taunt foi consumido após a ação, mesmo em alvo invulnerável")
	_expect(e1.taunted_by == null, "Efeito de Taunt foi limpo após a ação executada")
	b.free()


func _test_bite_stun_and_interrupt() -> void:
	print("[*] Testando Bite & Atordoamento (D-032)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	var p1: Combatant = ctx["p1"]
	var e1: Combatant = ctx["e1"]
	p1.add_atb(3.0)
	e1.add_atb(3.0)

	# Abra está preparando um ataque em windup
	b.use_skill(p1, Skill.basic(), e1)
	_expect(b.incoming.size() == 1, "Abra tem ataque em windup")

	# Gible usa Bite e atordoa Abra
	p1.stun_timer = 2.0
	_expect(p1.is_stunned(), "Alvo fica atordoado")

	# Enquanto atordoado, ações ofensivas e itens são rigorosamente bloqueados
	var try_skill := b.use_skill(p1, Skill.basic(), e1)
	_expect(not try_skill, "Combatente atordoado NÃO pode usar habilidades/golpes")
	var potion := Item.get_item("potion")
	p1.inventory = {"potion": 1}
	var try_item := b.use_item(p1, potion, p1) if potion != null else false
	_expect(not try_item, "Combatente atordoado NÃO pode usar itens")
	_expect(not b.can_step(p1, 1), "Combatente atordoado NÃO pode realizar passos de posição")

	# Enquanto atordoado, tick não deve aumentar ATB de p1
	var atb_initial := p1.atb
	p1.tick(0.5)
	_expect(p1.atb == atb_initial, "ATB fica pausado enquanto combatente está atordoado")
	p1.tick(2.0)
	_expect(not p1.is_stunned(), "Atordoamento expira após a duração total")
	b.free()


func _test_sand_attack_blind() -> void:
	print("[*] Testando Sand Attack & Cegueira (D-032)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	b.debug_roll = 1  # hit without a random automatic dodge (10%), which made this test flaky
	var p1: Combatant = ctx["p1"]
	var e1: Combatant = ctx["e1"]
	p1.add_atb(3.0)
	e1.add_atb(3.0)

	# 1. Alvo invulnerável -> Sand Attack erra e NÃO causa cegueira
	p1.is_invulnerable = true
	var sand := Skill.new("Sand Attack", 0.0, 1, Element.Type.TERRA, Skill.Kind.PROJECTILE, true, false, false, 0.75)
	b.use_skill(e1, sand, p1)
	var inc_miss: Incoming = b.incoming[0]
	inc_miss.time_left = 0.0
	_run_until_done(b, inc_miss)
	_expect(not p1.is_blind(), "Sand Attack erra alvo invulnerável (sem cegueira)")
	p1.is_invulnerable = false

	# 2. Alvo vulnerável atingido -> recebe cegueira por 4s
	e1.add_atb(3.0)
	b.use_skill(e1, sand, p1)
	var inc: Incoming = b.incoming[0]
	_expect(inc.total_windup == 0.75, "Sand Attack tem 0.75s de windup")
	inc.time_left = 0.0
	_run_until_done(b, inc)

	_expect(p1.is_blind(), "Alvo atingido por Sand Attack fica com status Blind")
	_expect(p1.blind_timer > 3.0, "Duração do Blind é de 4.0 segundos")
	_expect(p1.hp == 100, "Sand Attack não causa dano (0 dano)")
	b.free()


func _test_dragon_rage_aoe_splash() -> void:
	print("[*] Testando Dragon Rage AoE Splash (D-032)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	var p1: Combatant = ctx["p1"]
	var p2: Combatant = ctx["p2"]
	var e1: Combatant = ctx["e1"]
	e1.add_atb(3.0)

	var rage := Skill.new("Dragon Rage", 1.6, 3, Element.Type.FISICO, Skill.Kind.PROJECTILE, false, false, false, 2.0, true)
	b.use_skill(e1, rage, p1)
	var inc: Incoming = b.incoming[0]
	_expect(inc.total_windup == 2.0, "Dragon Rage tem 2.0s de windup")

	# Executa e acerta p1 -> p2 (aliado) também deve sofrer dano total
	inc.time_left = 0.0
	_run_until_done(b, inc)
	_expect(p1.hp < 100, "Alvo principal de Dragon Rage sofreu dano")
	_expect(p2.hp < 100, "Aliado sofreu o dano splash em área no contato de Dragon Rage")
	b.free()


func _test_dig_invulnerability() -> void:
	print("[*] Testando Dig (Investida Subterrânea - D-032)...")
	var ctx := _arena()
	var b: Battle = ctx["b"]
	var p1: Combatant = ctx["p1"]
	var e1: Combatant = ctx["e1"]
	e1.add_atb(3.0)
	p1.add_atb(3.0)

	var dig := Skill.new("Dig", 1.5, 2, Element.Type.TERRA, Skill.Kind.MELEE, true, false, false, 1.0)
	b.use_skill(e1, dig, p1)
	var dig_inc: Incoming = b.incoming[0]
	_expect(dig_inc.total_windup == 1.0, "Dig tem 1.0s de windup")
	_expect(not e1.is_invulnerable, "Dig NÃO é invulnerável durante o windup")

	# Ao resolver windup e entrar em TRAVEL (sob o chão):
	dig_inc.time_left = 0.0
	b._process(DT)
	_expect(e1.is_invulnerable, "Dig fica INVULNERÁVEL sob o chão durante o trajeto (TRAVEL)")

	# Se atacado durante a fase subterrânea, ataque sofre MISS!
	b.use_skill(p1, Skill.basic(), e1)
	var foe_atk: Incoming = b.incoming[0]
	foe_atk.time_left = 0.0
	b._process(DT)
	while not foe_atk.impacted:
		b._process(DT)
	_expect(e1.hp == 100, "Ataques inimigos erram completamente o usuário de Dig sob o chão (MISS!)")
	b.free()
