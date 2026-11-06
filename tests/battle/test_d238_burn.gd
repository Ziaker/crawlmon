extends SceneTree
## D-238: Burn. 4 ticks de 2 HP fixos (1 s depois, depois a cada 1 s), reaplicação renova, o tick pode matar (sem
## lançamento), e o Fire Bullet aplica quando o golpe interrompe uma ação do alvo.
## Rodar: godot --headless --path . --script res://tests/battle/test_d238_burn.gd

var fails := 0


func ok(c: bool, m: String) -> void:
	if c:
		print("  [PASS] ", m)
	else:
		fails += 1
		print("  [FAIL] ", m)


func make() -> Array:
	var b := Battle.new()
	var p := Combatant.new("Abra", 32, 10, 0.5, true)
	p.skills.clear()
	p.skills.append(Skill.new("Fire Bullet", 1.0, 2, Element.Type.FOGO, Skill.Kind.PROJECTILE, false, false, false, 0.5))
	var e := Combatant.new("Gible", 38, 9, 0.42, false)
	e.skills.clear()
	e.skills.append(Skill.new("Bite", 1.2, 2, Element.Type.TREVAS, Skill.Kind.MELEE, false, false, false, 1.2))
	var e2 := Combatant.new("Pancham", 45, 10, 0.45, false)
	e2.skills.clear()
	var party: Array[Combatant] = [p]
	var foes: Array[Combatant] = [e, e2]
	b.start(party, foes)
	for c in [p, e, e2]:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	return [b, p, e, e2]


func run_for(b: Battle, seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		b._process(0.05)
		left -= 0.05


func _init() -> void:
	print("\n=== D-238: Burn ===")
	var s := make()
	var b: Battle = s[0]
	var e: Combatant = s[2]
	ok(not e.is_burning(), "ninguém começa queimando")
	e.apply_burn()
	ok(e.is_burning() and e.burn_ticks_left == 4, "aplicar Burn: 4 ticks")
	var hp0 := e.hp
	run_for(b, 0.9)
	ok(e.hp == hp0, "antes de 1 s não há dano (o primeiro tick vem 1 s depois)")
	run_for(b, 0.2)
	ok(e.hp == hp0 - 2, "1 s depois: -2 HP (tick 1)")
	run_for(b, 3.05)
	ok(e.hp == hp0 - 8 and not e.is_burning(), "4 ticks de 2 = 8 HP no total e o Burn acaba (hp %d)" % e.hp)
	run_for(b, 2.0)
	ok(e.hp == hp0 - 8, "depois de acabar não há mais dano")

	# Dano fixo: Defense não reduz o tick.
	s = make()
	b = s[0]
	e = s[2]
	e.def_buff = 5
	hp0 = e.hp
	e.apply_burn()
	run_for(b, 1.1)
	ok(e.hp == hp0 - 2, "dano fixo: +5 DEF não reduz o tick (hp %d)" % e.hp)

	# Reaplicação renova os 4 ticks e mantém a cadência (sem acumular dano por segundo).
	s = make()
	b = s[0]
	e = s[2]
	hp0 = e.hp
	e.apply_burn()
	run_for(b, 2.5)  # ticks 1 e 2
	ok(e.hp == hp0 - 4, "dois ticks até 2,5 s")
	e.apply_burn()
	ok(e.burn_ticks_left == 4, "reaplicar volta para 4 ticks")
	run_for(b, 4.2)
	ok(e.hp == hp0 - 4 - 8 and not e.is_burning(), "depois de renovar: mais 4 ticks de 2 (hp %d)" % e.hp)

	# O tick pode matar; sem lançamento (meta died_by_burn durante o sinal `died`) e a batalha pode acabar.
	s = make()
	b = s[0]
	e = s[2]
	var e2: Combatant = s[3]
	e.set_hp_instant(3)
	var flag := {"burn": false}
	e.died.connect(func(_c) -> void: flag["burn"] = bool(e.get_meta("died_by_burn", false)))
	e.apply_burn()
	run_for(b, 2.2)
	ok(not e.is_alive(), "o Burn derrota o alvo (hp %d)" % e.hp)
	ok(flag["burn"], "no sinal `died` o alvo está marcado como morto por Burn (sem lançamento)")
	ok(not e.is_burning(), "morto não continua queimando")
	ok(b.running, "ainda há um inimigo vivo: a batalha continua")
	e2.set_hp_instant(1)
	e2.apply_burn()
	run_for(b, 1.2)
	ok(not b.running, "o Burn mata o último inimigo e a batalha termina")

	# Aplicação pelo Fire Bullet: só quando o golpe interrompe uma ação do alvo.
	s = make()
	b = s[0]
	var p: Combatant = s[1]
	e = s[2]
	b.debug_roll = 1  # sem crítico nem esquiva
	var info: Dictionary = b._hit(p, e, 1.0, Element.Type.FOGO, "Fire Bullet")
	ok(not bool(info.get("interrupted", true)) and not e.is_burning(), "alvo parado: o acerto não interrompe e não queima")
	b.use_skill(e, e.skills[0], p)
	ok(b.is_winding_up(e), "o alvo está canalizando (wind-up)")
	info = b._hit(p, e, 1.0, Element.Type.FOGO, "Fire Bullet")
	ok(bool(info.get("interrupted", false)) and e.is_burning() and bool(info.get("burn", false)), "o acerto interrompe a canalização e o alvo queima")
	# Outro golpe interrompendo não queima.
	s = make()
	b = s[0]
	p = s[1]
	e = s[2]
	b.debug_roll = 1
	b.use_skill(e, e.skills[0], p)
	b._hit(p, e, 1.0, Element.Type.FISICO, "Tackle")
	ok(not e.is_burning(), "só o Fire Bullet aplica Burn por enquanto")

	print("\n  Resultado: %d falhas" % fails)
	quit(1 if fails > 0 else 0)
