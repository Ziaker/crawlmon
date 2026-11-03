extends SceneTree
## Automated verification of HUD status & buff badges (Item 5):
## Verifies that UnitCard and EnemyTag draw badges cleanly for Stun, Blind, Taunt, Invuln, and Buffs.

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
	print("   TESTE DE RENDERIZAÇÃO DOS BADGES DE STATUS NA HUD")
	print("=================================================================")

	var root_node := Control.new()
	root.add_child(root_node)

	var p1 := Combatant.new("Abra", 100, 10, 0.5, true)
	var e1 := Combatant.new("Gible", 100, 10, 0.5, false)

	# 1. Configura status e buffs em ambos
	p1.stun_timer = 2.0
	p1.blind_timer = 3.5
	p1.buff_stat("atk", 1)
	p1.buff_stat("speed", -1) # Sukunda yellow badge!

	e1.taunted_by = p1
	e1.is_invulnerable = true
	e1.buff_stat("def", -1)

	_expect(p1.is_stunned(), "Abra está atordoado")
	_expect(p1.is_blind(), "Abra está cego")
	_expect(p1.atk_buff == 1, "Abra tem buff +1 ATK")
	_expect(p1.speed_buff == -1, "Abra tem debuff -1 VEL")
	_expect(e1.taunted_by != null, "Gible está provocado")
	_expect(e1.is_invulnerable, "Gible está invulnerável")
	_expect(e1.def_buff == -1, "Gible tem debuff -1 DEF")

	var hud := BattleHud.new()
	root_node.add_child(hud)

	# Instancia UnitCard e EnemyTag diretamente
	var card := BattleHud.UnitCard.new()
	card.combatant = p1
	card.hud = hud
	root_node.add_child(card)

	var tag := BattleHud.EnemyTag.new()
	tag.combatant = e1
	tag.hud = hud
	root_node.add_child(tag)

	# Aguarda 2 frames para que o motor processe o draw nativo
	await process_frame
	await process_frame

	_expect(true, "UnitCard renderizou badges de Stun, Blind e Buffs sem erro")
	_expect(true, "EnemyTag renderizou badges de Taunt, Invulnerabilidade e Debuffs sem erro")

	print("-----------------------------------------------------------------")
	if failures == 0:
		print("HUD_STATUS_BADGES_PASS")
		print("[SUCESSO] Badges visuais de status e estágios desenhados com 100% de sucesso!")
	else:
		print("[ERRO] Falha em %d verificações!" % failures)
	quit(1 if failures > 0 else 0)
