extends SceneTree
## Automated visual verification of Dig (D-032):
## 1. Windup: model visible on surface.
## 2. Travel: model dives underground and becomes hidden (visible = false) while traveling under the arena.
## 3. Strike: model emerges directly at the target, becomes visible (visible = true) and delivers impact.
## 4. Return: model returns on the surface.

const DT := 1.0 / 60.0
var failures := 0

func _expect(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		print("  [FAIL] %s" % msg)
	else:
		print("  [PASS] %s" % msg)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=================================================================")
	print("   TESTE VISUAL E CINEMÁTICO DE DIG / SUBTERRÂNEO (D-032)")
	print("=================================================================")

	var root_node := Node3D.new()
	root.add_child(root_node)

	var battle := Battle.new()
	root_node.add_child(battle)

	var fx := BattleFx.new()
	root_node.add_child(fx)
	fx.battle = battle

	var p1 := Combatant.new("Pancham", 100, 10, 0.5, true)
	var e1 := Combatant.new("Gible", 100, 10, 0.5, false)

	var m_pancham := Node3D.new()
	m_pancham.name = "PanchamModel"
	root_node.add_child(m_pancham)
	m_pancham.position = Vector3(0, 0, 0)
	var ap_pancham := AnimationPlayer.new()
	m_pancham.add_child(ap_pancham)
	m_pancham.set_meta("anim_player", ap_pancham)

	var m_gible := Node3D.new()
	m_gible.name = "GibleModel"
	root_node.add_child(m_gible)
	m_gible.position = Vector3(0, 0, -10)
	var ap_gible := AnimationPlayer.new()
	m_gible.add_child(ap_gible)
	m_gible.set_meta("anim_player", ap_gible)

	fx.register(p1, m_pancham)
	fx.register(e1, m_gible)
	fx.leader = p1

	battle.attack_telegraphed.connect(fx.telegraph)
	battle.attack_resolved.connect(fx.resolve_attack)
	battle.attack_phase.connect(fx.on_phase)

	battle.start([p1], [e1])
	p1.add_atb(3.0)

	var sk := Skill.new("Dig", 1.5, 2, Element.Type.TERRA, Skill.Kind.MELEE, true, false, false, 1.0)
	battle.use_skill(p1, sk, e1)
	var inc: Incoming = battle.incoming[0]

	# 1. Windup
	_expect(inc.total_windup == 1.0, "Dig tem 1.0s de windup")
	_expect(m_pancham.visible, "No windup, combatente permanece visível na superfície")

	while inc.phase == Incoming.Phase.WINDUP:
		battle._process(DT)
		fx._process(DT)

	# 2. Travel: dives and disappears underground
	_expect(inc.phase == Incoming.Phase.TRAVEL, "Entrou em fase de TRAVEL")
	var was_hidden_underground := false
	while inc.phase == Incoming.Phase.TRAVEL:
		if not m_pancham.visible:
			was_hidden_underground = true
		battle._process(DT)
		fx._process(DT)

	_expect(was_hidden_underground, "Durante o deslocamento subterrâneo, o modelo fica 100% oculto sob a terra")

	# 3. Strike: emerges at the target!
	_expect(inc.phase == Incoming.Phase.STRIKE, "Entrou em fase de STRIKE no alvo")
	_expect(m_pancham.visible, "Ao chegar no alvo (STRIKE), o modelo EMERGE visível do chão")
	_expect(m_pancham.position.distance_to(m_gible.position) < 3.5, "Modelo emergiu na posição do alvo (distância = %.2f)" % m_pancham.position.distance_to(m_gible.position))

	# 4. Return: finishes and returns
	while inc.phase == Incoming.Phase.STRIKE:
		battle._process(DT)
		fx._process(DT)

	_expect(inc.phase == Incoming.Phase.RETURN, "Entrou em fase de RETURN")
	_expect(m_pancham.visible, "No RETURN, modelo permanece visível na superfície voltando à base")

	while inc.phase == Incoming.Phase.RETURN:
		battle._process(DT)
		fx._process(DT)

	print("-----------------------------------------------------------------")
	if failures == 0:
		print("DIG_VISUAL_PASS")
		print("[SUCESSO] Dig funciona perfeitamente: mergulha sob o solo, viaja oculto e emerge no alvo!")
	else:
		print("[ERRO] Falha em %d verificações!" % failures)
	quit(1 if failures > 0 else 0)
