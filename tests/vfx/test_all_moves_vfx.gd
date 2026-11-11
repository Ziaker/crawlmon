extends SceneTree
## Suite de Validação Visual de Todos os Movimentos do Jogo.
## Testa roteamento, instanciação de VFX (Golpe e Impacto), integridade de malhas e limpeza de memória.

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- INICIANDO TESTE VISUAL DE TODOS OS 22 MOVIMENTOS ---")
	var battle_fx := BattleFx.new()
	root.add_child(battle_fx)

	_test_tackle_vfx(battle_fx)
	_test_classic_moves_vfx(battle_fx)
	_test_smt_moves_vfx(battle_fx)
	_test_no_node_leaks(battle_fx)

	await process_frame
	battle_fx.queue_free()

	if failures == 0:
		print("ALL_MOVES_VFX_TEST_PASS")
	else:
		print("FALHAS ENCONTRADAS NO TESTE VISUAL: %d" % failures)
	quit(1 if failures > 0 else 0)


func _test_tackle_vfx(battle_fx: BattleFx) -> void:
	var pos := Vector3(0, 1, -5)
	# Golpe A2: D-990 removed the two flat smear arcs fixed in space; the SwingTrail follows the real limb.
	var smears := battle_fx.fx_motion._tackle_strike_vfx(pos, Vector3.FORWARD)
	_expect(smears.is_empty(), "Tackle golpe A2 nao deve recriar as laminas fixas removidas pela D-990")
	for s in smears:
		s.queue_free()

	# D-041: the approved Tackle impact is the multilayer shock-cone composition; the old B1/B2 nodes are gone.
	var impact := battle_fx.fx_impacts._tackle_impact(pos, Vector3.FORWARD, false)
	_expect(_has_named(impact, "TackleShockCone"), "Tackle impacto deve conter o cone de choque autoral")
	_expect(_has_named(impact, "TackleSlashArcA") and _has_named(impact, "TackleSlashArcB"), "Tackle impacto deve conter os dois arcos cineticos")
	_expect(_has_named(impact, "TackleFlipbookMain"), "Tackle impacto deve conter o flipbook principal")
	for node in impact:
		if is_instance_valid(node):
			node.queue_free()


func _test_classic_moves_vfx(battle_fx: BattleFx) -> void:
	var pos := Vector3(0, 1, -5)
	var dir := Vector3.FORWARD

	# Pancham moves
	var punch := battle_fx.fx_impacts._impact(Element.Type.FISICO, pos, Color.WHITE, false, dir, "soco_rapido")
	_expect(_has_named(punch, "QuickPunchBarrage"), "Soco Rapido deve ter QuickPunchBarrage")
	_clean(punch)

	var karate := battle_fx.fx_impacts._impact(Element.Type.FISICO, pos, Color.WHITE, false, dir, "golpe_carate")
	_expect(_has_named(karate, "KarateLightColumn"), "Golpe de Carate deve ter KarateLightColumn")
	_clean(karate)

	var brick := battle_fx.fx_impacts._impact(Element.Type.FISICO, pos, Color.WHITE, true, dir, "quebra_telha")
	_expect(_has_named(brick, "BrickBreakImpact"), "Quebra de Telha deve ter BrickBreakImpact")
	_clean(brick)

	var taunt_handled := battle_fx.fx_impacts._status_impact_move("provocacao", pos)
	_expect(taunt_handled, "Provocacao deve ser tratada como status visual")

	# Abra moves
	var conf := battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color.PURPLE, false, dir, "confusao")
	_expect(battle_fx.get_node_or_null("AbraConfusaoImpact") != null, "Confusao deve ter a camada AbraConfusaoImpact (D-170: efeitos antigos removidos)")
	_clean(conf)

	var beam := battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color.PURPLE, false, dir, "raio_psiquico")
	_expect(battle_fx.get_node_or_null("AbraRaioPsiquicoImpact") != null, "Raio Psiquico deve ter a camada AbraRaioPsiquicoImpact (D-170)")
	_clean(beam)

	var shock := battle_fx.fx_impacts._impact(Element.Type.RAIO, pos, Color.YELLOW, false, dir, "onda_choque")
	_expect(battle_fx.get_node_or_null("AbraOndaChoqueImpact") != null, "Onda de Choque deve ter a camada AbraOndaChoqueImpact (D-170)")
	_clean(shock)

	var tele := battle_fx.fx_impacts._impact(Element.Type.PSIQUICO, pos, Color.CYAN, false, dir, "teleporte_rapido")
	_expect(battle_fx.get_node_or_null("AbraTeleporteRapidoImpact") != null, "Teleporte Rapido deve ter a camada AbraTeleporteRapidoImpact (D-170)")
	_clean(tele)

	# Gible moves
	var bite := battle_fx.fx_impacts._impact(Element.Type.TREVAS, pos, Color("ff624f"), false, dir, "mordida")
	_expect(_has_named(bite, "BiteSpectralJaw"), "Mordida deve ter BiteSpectralJaw")
	_clean(bite)

	var sand := battle_fx.fx_impacts._impact(Element.Type.TERRA, pos, Color("f0c57e"), false, dir, "tiro_areia")
	_expect(_has_named(sand, "SandVortexImpact"), "Tiro de Areia deve ter SandVortexImpact")
	_clean(sand)

	var claw := battle_fx.fx_impacts._impact(Element.Type.FISICO, pos, Color("00f59b"), true, dir, "garra_dragao")
	_expect(_has_named(claw, "DragonClawImpact"), "Garra do Dragao deve ter DragonClawImpact")
	_clean(claw)

	var rage := battle_fx.fx_impacts._impact(Element.Type.FISICO, pos, Color("63d9ec"), true, dir, "furia_dragao")
	_expect(_has_named(rage, "DragonRageSupernova"), "Furia do Dragao deve ter DragonRageSupernova")
	_clean(rage)

	var dig := battle_fx.fx_impacts._impact(Element.Type.TERRA, pos, Color("f0c57e"), true, dir, "investida_escavadora")
	_expect(_has_named(dig, "DigRushEruption"), "Investida Escavadora deve ter DigRushEruption")
	_clean(dig)


func _test_smt_moves_vfx(battle_fx: BattleFx) -> void:
	var pos := Vector3(0, 1, -5)
	var dir := Vector3.FORWARD

	# 4 Status (Media, Tarukaja, Rakunda, Sukunda)
	# D-337: Media is carried by its own stage ritual; the legacy white status burst must not run.
	_expect(not battle_fx.fx_impacts._status_impact_move("media", pos), "Media nao deve usar o burst de status antigo (D-337)")
	_expect(MoveVfxRegistry.family(&"media") == &"media", "Media deve rotear para o ritual proprio de palco")
	_expect(battle_fx.fx_impacts._status_impact_move("tarukaja", pos), "Tarukaja deve ter tratamento visual de status")
	_expect(battle_fx.fx_impacts._status_impact_move("rakunda", pos), "Rakunda deve ter tratamento visual de status")
	_expect(battle_fx.fx_impacts._status_impact_move("sukunda", pos), "Sukunda deve ter tratamento visual de status")

	# 2 AoE Projéteis (Mabufula, Megido)
	var mabufula := battle_fx.fx_impacts._impact_move("mabufula", pos, Color.CYAN, true, dir)
	_expect(mabufula.get("handled", false), "Mabufula deve ser manipulado pelo _impact_move")

	var megido := battle_fx.fx_impacts._impact_move("megido", pos, Color.GOLD, true, dir)
	_expect(megido.get("handled", false), "Megido deve ser manipulado pelo _impact_move")

	# 2 AoE Físicos (Hassou Tobi, Titanomachia)
	var hassou := battle_fx.fx_impacts._impact_move("hassou_tobi", pos, Color.WHITE, true, dir)
	_expect(hassou.get("handled", false), "Hassou Tobi deve ser manipulado pelo _impact_move")

	var titano := battle_fx.fx_impacts._impact_move("titanomachia", pos, Color("ff8f00"), true, dir)
	_expect(titano.get("handled", false), "Titanomachia deve ser manipulado pelo _impact_move")


func _test_no_node_leaks(battle_fx: BattleFx) -> void:
	var before_count := battle_fx.get_child_count()
	# Dispara múltiplos efeitos de status e impacto
	battle_fx.fx_impacts._status_impact_move("media", Vector3.ZERO)
	battle_fx.fx_impacts._status_impact_move("tarukaja", Vector3.ZERO)
	battle_fx.fx_impacts._status_impact_move("rakunda", Vector3.ZERO)
	battle_fx.fx_impacts._status_impact_move("sukunda", Vector3.ZERO)
	battle_fx.fx_impacts._impact_move("mabufula", Vector3.ZERO, Color.CYAN, true, Vector3.FORWARD)
	battle_fx.fx_impacts._impact_move("megido", Vector3.ZERO, Color.GOLD, true, Vector3.FORWARD)

	# Aguarda limpeza dos tweens
	var timer := create_timer(1.2)
	await timer.timeout

	var after_count := battle_fx.get_child_count()
	_expect(after_count <= before_count + 8, "Efeitos visuais devem liberar seus nós temporarios apos a duracao")


func _has_named(nodes: Array[Node3D], wanted: String) -> bool:
	for node in nodes:
		if is_instance_valid(node) and node.name == wanted:
			return true
	return false


func _clean(nodes: Array[Node3D]) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
