extends SceneTree
## D-167 audit fixes and D-168 strategic AI.

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
	print("  [%s] %s" % ["PASS" if cond else "FAIL", msg])


func _scene() -> Node3D:
	var bs: Node3D = (load("res://scenes/battle.tscn") as PackedScene).instantiate()
	root.add_child(bs)
	var b: Battle = bs.get_node("Battle")
	while not b.running:
		await process_frame
	for c in b.party + b.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.atb = 5.0
	return bs


## Rules only: no drawing and no real time.
func _logic(enemy_count := 1) -> Battle:
	var party: Array[Combatant] = [_unit("Lider", true), _unit("Aliado", true)]
	var enemies: Array[Combatant] = []
	for i in enemy_count:
		enemies.append(_unit("Inimigo%d" % i, false))
	var b := Battle.new()
	root.add_child(b)
	b.set_process(false)
	for c in party + enemies:
		c.place(Vector3.ZERO if c.is_player else Vector3(8, 0, -30), PI if c.is_player else 0.0)
	b.start(party, enemies)
	return b


func _unit(n: String, is_player: bool) -> Combatant:
	var c := Combatant.new(n, 100, 10, 0.5, is_player)
	c.act_policy = Combatant.Act.SKILL
	c.react_policy = Combatant.React.EVADE
	# D-413: the fixture's Skills cost MP; without MP use_skill refuses
	# before the AI can choose a Move.
	c.max_mp = 999
	c.mp = 999
	return c


func _s(n: String, power: float, cost: int, kind: int, aoe := false, friendly := false) -> Skill:
	return Skill.new(n, power, cost, Element.Type.FISICO, kind, false, aoe, friendly, 1.0)


func _test_fixes() -> void:
	var c := Combatant.new("X", 10, 100, 0.5, true)
	c.atk_buff = 5
	c.taunt_atk_bonus = true
	_expect(c.attack == 225, "Taunt sobre +5 não passa do estágio +5 (%d)" % c.attack)

	var b := _logic()
	var logs: Array[String] = []
	b.log_message.connect(func(t: String) -> void: logs.append(t))
	var e: Combatant = b.enemies[0]
	e.max_hp = 99999
	e.set_hp_instant(99999)
	e.speed_buff = -5
	for i in 200:
		b._hit(b.party[1], e, 0.01, Element.Type.FISICO, "Karate Chop")
	_expect(logs.any(func(t: String) -> bool: return "patamar mínimo" in t), "Karate Chop em -5 avisa o limite")
	_expect(not logs.any(func(t: String) -> bool: return "foi reduzida" in t), "Karate Chop em -5 não diz que reduziu")

	var infos: Array[Dictionary] = []
	b.hit_resolved.connect(func(_a, _t, _el, info: Dictionary) -> void: infos.append(info))
	var inc := Incoming.new()
	inc.attacker = b.enemies[0]
	inc.target = b.party[0]
	inc.label = "Rakunda"
	b.party[0].def_buff = -5
	b._execute_status_move(inc)
	_expect(infos.back().get("capped", false), "Rakunda em -5 marca que não houve efeito")
	b.party[0].def_buff = -1
	b._execute_status_move(inc)
	_expect(not infos.back().get("capped", true), "Rakunda fora do limite tem efeito")

	# The end of a battle clears the survivors' stages.
	b.party[1].atk_buff = 3
	e.set_hp_instant(0)
	b._check_end()
	_expect(b.party[1].atk_buff == 0, "fim da batalha limpa os buffs de quem sobreviveu")
	b.free()


func _test_visuals() -> void:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var fx: BattleFx = bs.fx
	var l: Combatant = b.party[0]
	var e: Combatant = b.enemies[0]
	var m: Node3D = bs.models[l]
	var s0 := m.scale.x
	e.max_hp = 9999
	e.set_hp_instant(9999)
	b.use_skill(l, Skill.new("Tackle", 0.1, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 0.05), e)
	while not b.incoming.is_empty():
		await process_frame
	await create_timer(0.1, true, false, true).timeout
	l.buff_stat("atk", 1)
	while b.is_in_action(l):
		await process_frame
	await create_timer(0.5, true, false, true).timeout
	_expect(is_equal_approx(m.scale.x, s0 * 1.15), "ATK+1 durante o próprio ataque mantém o tamanho (%.3f)" % m.scale.x)

	var line: ShaderMaterial = null
	for mi in VfxLib.meshes_of(m):
		if mi.name in ["BurstRing", "ReadyRing"] or mi.mesh == null:
			continue
		var mat := mi.get_surface_override_material(0)
		if mat is BaseMaterial3D and mat.next_pass is ShaderMaterial:
			line = mat.next_pass
			break
	_expect(line != null and line.next_pass is ShaderMaterial, "o modelo tem o passe de rachadura")
	if line != null and line.next_pass is ShaderMaterial:
		var crack: ShaderMaterial = line.next_pass
		l.def_buff = -3
		fx.apply_buff_visuals(l, false)
		_expect(is_equal_approx(crack.get_shader_parameter("amount"), 1.0), "-3 DEF: rachadura no máximo")
		var col: Color = line.get_shader_parameter("color")
		_expect(col.a >= 0.5 and col.a <= 1.0, "-3 DEF: cor do contorno sem passar do limite (alfa %.2f)" % col.a)
		l.def_buff = -5
		fx.apply_buff_visuals(l, false)
		_expect(is_equal_approx(crack.get_shader_parameter("amount"), 1.0), "-5 DEF: rachadura travada no teto de 3")
		l.def_buff = 2
		fx.apply_buff_visuals(l, false)
		_expect(is_equal_approx(crack.get_shader_parameter("amount"), 0.0), "+DEF: sem rachadura")
	Engine.time_scale = 1.0
	bs.free()


func _test_scores() -> void:
	var b := _logic(2)
	var ai: BattleAI = b._ai
	var a: Combatant = b.party[1]
	var t: Combatant = b.enemies[0]
	var weak := _s("Fraco", 0.3, 1, Skill.Kind.MELEE)
	var strong := _s("Forte", 1.5, 2, Skill.Kind.MELEE)
	_expect(ai.score_move(a, strong, t) > ai.score_move(a, weak, t), "golpe mais forte vale mais")
	var area := _s("Area", 1.5, 2, Skill.Kind.MELEE, true)
	_expect(ai.score_move(a, area, t) > ai.score_move(a, strong, t), "área com dois alvos vale mais")
	var before := ai.score_move(a, strong, t)
	t.set_hp_instant(5)
	_expect(ai.score_move(a, weak, t) > before * 0.5, "nocaute dá valor até a golpe fraco")
	t.set_hp_instant(100)
	t.is_invulnerable = true
	_expect(ai.score_move(a, strong, t) == 0.0, "alvo invulnerável não vale nada")
	t.is_invulnerable = false

	var media := _s("Media", 0.0, 2, Skill.Kind.STATUS, true, true)
	_expect(ai.score_move(a, media, a) == 0.0, "Media não vale nada com todos inteiros")
	a.set_hp_instant(30)
	_expect(ai.score_move(a, media, a) > ai.score_move(a, strong, t), "Media vale mais com aliado muito ferido")
	a.set_hp_instant(100)

	var rakunda := _s("Rakunda", 0.0, 1, Skill.Kind.STATUS)
	var first := ai.score_move(a, rakunda, t)
	t.def_buff = -2
	_expect(ai.score_move(a, rakunda, t) < first, "debuff repetido vale menos")
	t.def_buff = -5
	_expect(ai.score_move(a, rakunda, t) == 0.0, "debuff no limite não vale nada")
	t.def_buff = 0
	t.set_hp_instant(10)
	_expect(ai.score_move(a, rakunda, t) == 0.0, "não enfraquece quem está quase morto")
	t.set_hp_instant(100)

	var sand := Skill.new("Sand Attack", 0.0, 1, Element.Type.TERRA, Skill.Kind.PROJECTILE)
	var sand_before := ai.score_move(a, sand, t)
	t.blind_timer = 2.0
	_expect(sand_before > 0.0 and ai.score_move(a, sand, t) == 0.0, "não cega quem já está cego")
	t.blind_timer = 0.0

	var taunt := _s("Taunt", 0.0, 1, Skill.Kind.STATUS)
	var alone := ai.score_move(a, taunt, t)
	b.party[0].set_hp_instant(20)
	_expect(ai.score_move(a, taunt, t) > alone, "Taunt vale mais para proteger aliado ferido")
	b.party[0].set_hp_instant(100)

	# Reserve
	a.atb = 3.0
	_expect(ai._reserve(a) == BattleAI.IDLE_RESERVE, "sem ameaça, guarda 1 ATB")
	var inc := Incoming.new()
	inc.attacker = t
	inc.target = a
	inc.time_left = 1.0
	inc.kind = Skill.Kind.MELEE
	b.incoming.append(inc)
	_expect(ai._reserve(a) == Battle.EVADE_STILL, "sob ataque, guarda os 3 ATB do Evade")
	_expect(not ai._may_spend(a, strong, t), "não gasta a reserva do Evade")
	t.set_hp_instant(1)
	_expect(ai._may_spend(a, strong, t), "nocaute dispensa a reserva")
	t.set_hp_instant(100)
	a.burst = 1
	_expect(ai._may_spend(a, strong, t), "Burst dispensa a reserva")
	a.burst = 0
	b.incoming.clear()
	a.react_policy = Combatant.React.NONE
	_expect(ai._reserve(a) == 0.0, "quem não esquiva não guarda ATB")
	b.free()


## Whole fights, rules only: what it does must vary, and it must dodge.
func _test_fights() -> void:
	var seen := {}
	var targets := {}
	var dodges := {"n": 0}
	seed(77)
	for n in 12:
		var b := _logic(2)
		var ally: Combatant = b.party[1]
		var foe: Combatant = b.enemies[0]
		for c in [ally, foe, b.enemies[1]]:
			c.skills.assign([
				_s("Fraco", 0.5, 1, Skill.Kind.MELEE),
				_s("Medio", 1.2, 2, Skill.Kind.MELEE),
				_s("Forte", 1.7, 3, Skill.Kind.MELEE),
				_s("Rakunda", 0.0, 1, Skill.Kind.STATUS),
				_s("Sukunda", 0.0, 1, Skill.Kind.STATUS),
			])
		b.attack_telegraphed.connect(func(inc) -> void:
			seen[inc.label] = true
			if not inc.attacker.is_player:
				targets[inc.target.name] = true)
		b.manual_evaded.connect(func(_a, _i) -> void: dodges["n"] += 1)
		var t := 0.0
		while b.running and t < 60.0:
			b.party[0].set_hp_instant(100)
			b._process(1.0 / 30.0)
			t += 1.0 / 30.0
		b.free()
	_expect(seen.size() >= 4, "a IA varia de golpe (%d diferentes)" % seen.size())
	_expect(targets.size() == 2, "o inimigo mira mais de um adversário")
	_expect(dodges["n"] > 0, "a IA desvia (%d desvios)" % dodges["n"])


func _test_own_run() -> void:
	var b := _logic()
	var a: Combatant = b.party[1]
	var e: Combatant = b.enemies[0]
	var own := Incoming.new()
	own.attacker = a
	own.target = e
	own.motion = "melee"
	own.phase = Battle.Phase.TRAVEL
	own.resolved = true
	own.plan = [[Battle.Phase.TRAVEL, 1.0]]
	own.plan_i = 0
	b._landing.append(own)
	var inc := Incoming.new()
	inc.attacker = e
	inc.target = a
	inc.kind = Skill.Kind.MELEE
	inc.motion = "melee"  # the real planner sets this; window_end() reads it (D-988/D-1014)
	inc.resolved = true
	inc.phase = Battle.Phase.STRIKE
	inc.impact_phase = Battle.Phase.STRIKE
	inc.plan = [[Battle.Phase.STRIKE, 1.0]]
	inc.plan_i = 0
	# D-1007/D-1014: the AI rolls once whether it will dodge; the scheduler picks the moment
	# INSIDE the valid window. It must never spend the Evade outside it.
	inc.ai_dodge_rolled = true
	inc.ai_dodge_in = 0.0
	a.atb = 5.0
	inc.phase_time = 0.1
	b._tick_ai_dodge(inc, 0.1)
	_expect(not inc.dodged and not inc.evade_tried and not inc.can_evade_now(), "no próprio trajeto espera a janela perfeita")
	# D-988: for a 1.0 s strike the window runs from 0.50 s to 0.75 s (0.25 s, ending 0.25 s before contact).
	inc.phase_time = 0.55
	b._tick_ai_dodge(inc, 1.0 / 60.0)  # arms inside the window
	inc.phase_time = 0.60
	b._tick_ai_dodge(inc, 0.25)  # the drawn delay always expires inside the window
	_expect(inc.dodged and inc.perfect, "desvia na janela perfeita")
	b.free()


func _run() -> void:
	_test_fixes()
	await _test_visuals()
	_test_scores()
	_test_fights()
	_test_own_run()
	print("D167_D168_TEST_PASS" if failures == 0 else "TESTES COM %d FALHAS" % failures)
	quit(1 if failures > 0 else 0)
