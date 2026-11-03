extends SceneTree
## Automated visual verification of Teleport (D-032):
## Verifies that:
## 1. During windup (0.5s), model is hidden (visible = false) and unit is invulnerable.
## 2. In TRAVEL, model remains hidden (visible = false) and does not run.
## 3. In STRIKE, model appears directly BEHIND the opponent (dest = opponent.pos + attack_dir * 1.35).
## 4. In STRIKE, model is NOT forcibly snapped back to home by _is_idle / battle_fx _process.
## 5. In RETURN, model vanishes from behind opponent, then reappears at home origin.

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
	print("   TESTE VISUAL E CINEMÁTICO DO TELEPORTE RÁPIDO (D-032)")
	print("=================================================================")

	var root_node := Node3D.new()
	root.add_child(root_node)

	var battle := Battle.new()
	root_node.add_child(battle)

	var fx := BattleFx.new()
	root_node.add_child(fx)
	fx.battle = battle

	var p1 := Combatant.new("Abra", 100, 10, 0.5, true)
	var e1 := Combatant.new("Gible", 100, 10, 0.5, false)

	var m_abra := Node3D.new()
	m_abra.name = "AbraModel"
	root_node.add_child(m_abra)
	m_abra.position = Vector3(0, 0, 0)
	var ap_abra := AnimationPlayer.new()
	m_abra.add_child(ap_abra)
	m_abra.set_meta("anim_player", ap_abra)

	var m_gible := Node3D.new()
	m_gible.name = "GibleModel"
	root_node.add_child(m_gible)
	m_gible.position = Vector3(0, 0, -10)
	var ap_gible := AnimationPlayer.new()
	m_gible.add_child(ap_gible)
	m_gible.set_meta("anim_player", ap_gible)

	fx.register(p1, m_abra)
	fx.register(e1, m_gible)
	fx.leader = p1

	battle.attack_telegraphed.connect(fx.telegraph)
	battle.attack_resolved.connect(fx.resolve_attack)
	battle.attack_phase.connect(fx.on_phase)

	battle.start([p1], [e1])
	p1.add_atb(3.0)

	var sk := Skill.new("Teleport", 0.7, 1, Element.Type.PSIQUICO, Skill.Kind.MELEE, false, false, false, 0.5)
	battle.use_skill(p1, sk, e1)

	var inc: Incoming = battle.incoming[0]

	# 1. Windup check: visible at home, NOT invulnerable during windup (D-034)
	_expect(not p1.is_invulnerable, "Abra NÃO fica invulnerável no windup de Teleport (D-034)")
	_expect(m_abra.visible, "Abra permanece visível durante o windup de Teleport (D-034)")

	# Step windup
	while inc.phase == Incoming.Phase.WINDUP:
		battle._process(DT)
		fx._process(DT)

	# 2. Travel check: vanishes AFTER windup, invulnerable while vanished, no displacement/run across floor
	_expect(inc.phase == Incoming.Phase.TRAVEL, "Após windup, entra em TRAVEL curto")
	_expect(not m_abra.visible, "Após o windup (TRAVEL), Abra some instantaneamente (sem correr na arena)")
	_expect(p1.is_invulnerable, "Após o windup (TRAVEL), Abra fica invulnerável enquanto sumido")

	# Step through TRAVEL to STRIKE
	while inc.phase == Incoming.Phase.TRAVEL:
		battle._process(DT)
		fx._process(DT)

	# 3. Strike check: Abra emerges behind Gible!
	_expect(inc.phase == Incoming.Phase.STRIKE, "Entrou em fase de STRIKE")
	_expect(m_abra.visible, "Em STRIKE, Abra surge visível atrás do oponente")
	_expect(not p1.is_invulnerable, "Em STRIKE, Abra perde invulnerabilidade para desferir o golpe")

	var expected_behind_z := -10.0 + (-1.0) * 1.35 # Gible is at z=-10, attack dir from (0,0,0) is (0,0,-1) -> behind is -11.35
	_expect(absf(m_abra.position.z - expected_behind_z) < 0.2, "Abra surgiu atrás do oponente (z ~= -11.35, atual = %.2f)" % m_abra.position.z)
	_expect(m_abra.position.distance_to(Vector3(0, 0, 0)) > 5.0, "Abra NÃO foi resetado para a base de origem (distância da base = %.2f)" % m_abra.position.distance_to(Vector3(0, 0, 0)))

	# Let STRIKE finish and enter RETURN
	while inc.phase == Incoming.Phase.STRIKE:
		battle._process(DT)
		fx._process(DT)

	# 4. Return check: Abra vanishes from behind and reappears at home
	_expect(inc.phase == Incoming.Phase.RETURN, "Entrou em fase de RETURN")
	var vanished_in_return := false
	while inc.phase == Incoming.Phase.RETURN:
		if not m_abra.visible:
			vanished_in_return = true
		battle._process(DT)
		fx._process(DT)

	_expect(vanished_in_return, "Abra sumiu de trás do oponente no início do RETURN")
	_expect(m_abra.visible, "Abra voltou a ficar visível na posição de origem ao fim do teleporte")
	_expect(not p1.is_invulnerable, "Ao fim do teleporte, Abra não está mais invulnerável")
	_expect(m_abra.position.distance_to(Vector3(0, 0, 0)) < 0.2, "Abra está de volta à posição de origem (dist = %.2f)" % m_abra.position.distance_to(Vector3(0, 0, 0)))

	print("-----------------------------------------------------------------")
	if failures == 0:
		print("TELEPORT_VISUAL_PASS")
		print("[SUCESSO] Teleporte funciona perfeitamente (D-034): visível no windup, some após windup, surge no ataque e ressurge na origem!")
	else:
		print("[ERRO] Falha em %d verificações!" % failures)
	quit(1 if failures > 0 else 0)
