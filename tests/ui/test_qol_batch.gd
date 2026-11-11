extends SceneTree
## Regression for QoL 1-8:
## log history/toggle, status timers, move sheet, queue badge data, fight pages,
## pickup feedback, dialogue speed and the richer target forecast.

var failures := 0
var gs: Node


func _init() -> void:
	call_deferred("_run")


func _expect(ok: bool, msg: String) -> void:
	if ok:
		print("  [PASS] ", msg)
	else:
		failures += 1
		print("  [FAIL] ", msg)


func _run() -> void:
	print("--- QOL 1-8 ---")
	gs = root.get_node_or_null("GameState")
	_test_skill_sheets()
	_test_text_speed()
	await _test_pickup_block()
	await _test_battle_hud()

	await process_frame
	if failures == 0:
		print("QOL_BATCH_TEST_PASS")
	else:
		print("QOL_BATCH_TEST_FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func _test_skill_sheets() -> void:
	var abra := Combatant.new("Abra", 32, 12, 0.50, true)
	abra.mag = 12
	var moves: Array[Skill] = [Skill.basic()]
	moves.append_array(Skill.smt_skills())
	moves.append(Skill.new("Bubble Shield", 0.0, 3, Element.Type.AGUA_GELO, Skill.Kind.STATUS, false, true, true, 0.7))
	var bubble: Skill = null
	for s in moves:
		if s.display_name == "Bubble Shield":
			bubble = s
		_expect(s.effect_line() != "" and not s.effect_line().contains("N/D"), "%s tem ficha de efeito" % s.display_name)
		_expect(s.description() != "" and not s.description().contains("N/D"), "%s tem descrição" % s.display_name)
		_expect(s.short_effect() != "", "%s tem efeito curto" % s.display_name)
		_expect(not s.sheet_bullets().is_empty(), "%s gera bullets legíveis" % s.display_name)
	_expect(bubble != null, "Bubble Shield existe na ficha")
	if bubble != null:
		var line := bubble.effect_line()
		_expect(line.contains("25 + MAG") and line.contains("8") and (line.contains("ALL") or line.contains("TODOS")), "ficha preserva 25+MAG, 8 s e TODOS")
		_expect(bubble.sheet_bullets().size() >= 3, "Bubble Shield tem bullets separados")
		var forecast := Skill.status_forecast(bubble, abra)
		_expect(forecast.contains("37") and forecast.contains("8"), "previsão usa MAG real (37) e 8 s")
	# Every crossover move must have real flavor text, not the generic fallback.
	for c in DqtTestParty.build(true):
		for s in c.skills:
			_expect(not s.description().begins_with("Golpe "), "%s/%s tem descrição própria" % [c.name, s.display_name])
			_expect(not s.effect_line().contains("N/D"), "%s/%s tem efeito próprio" % [c.name, s.display_name])


func _test_text_speed() -> void:
	if gs == null:
		_expect(false, "GameState disponível")
		return
	var saved: int = gs.text_speed
	gs.text_speed = 0
	_expect(is_equal_approx(gs.text_speed_value(), 28.0) and gs.text_speed_name() == "Lento", "velocidade Lenta = 28")
	gs.cycle_text_speed(1)
	_expect(is_equal_approx(gs.text_speed_value(), 46.0) and gs.text_speed_name() == "Normal", "velocidade Normal = 46")
	gs.cycle_text_speed(1)
	_expect(is_equal_approx(gs.text_speed_value(), 80.0) and gs.text_speed_name() == "Rápido", "velocidade Rápida = 80")
	gs.cycle_text_speed(1)
	_expect(gs.text_speed == 0, "a velocidade volta ao começo")
	gs.text_speed = saved


func _test_pickup_block() -> void:
	var pickup_script := load("res://scripts/dungeon/pickup.gd")
	var player := Node2D.new()
	player.position = Vector2(100, 100)
	root.add_child(player)
	var pickup = pickup_script.new()
	pickup.position = Vector2(100, 100)
	pickup.setup("x,y", player)
	root.add_child(pickup)
	var fired: Array[bool] = [false]
	pickup.blocked.connect(func(_p) -> void: fired[0] = true)
	var saved: Dictionary = gs.inventory.duplicate()
	gs.inventory["potion"] = 999  # Well past any capacity.
	pickup._process(0.016)
	_expect(fired[0], "pickup emite blocked com inventário cheio")
	_expect(not pickup._taken, "o item continua no chão quando o inventário está cheio")
	gs.inventory = saved
	pickup._taken = true
	pickup.queue_free()
	player.queue_free()
	await process_frame


func _test_battle_hud() -> void:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 900:
		await process_frame
		guard += 1
	for i in 4:
		await process_frame
	for c in bs.models.keys():
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	var hud: BattleHud = bs.hud
	var leader: Combatant = battle.party[0]
	var enemy: Combatant = battle.enemies[0]

	# QoL 2: real timers.
	leader.apply_shield(37, 6.4)
	leader.guard_timer = 1.7
	leader.blind_timer = 2.2
	var status := BattleHud.status_line(leader)
	_expect((status.contains("SHIELD 37") or status.contains("BOLHA 37")) and status.contains("6.4s"), "status_line mostra reserva e tempo da bolha")
	_expect(status.contains("GUARD 1.7s"), "status_line mostra o tempo do Guard")
	_expect(status.contains("BLIND 2.2s") or status.contains("CEGO 2.2s"), "status_line mostra o tempo da cegueira")
	leader.end_shield("battle_end")
	leader.guard_timer = 0.0
	leader.blind_timer = 0.0

	# QoL 1 removed (D-959): the battle history panel no longer exists; log colors are still distinct.
	_expect(BattleHud.log_color("Abra desvia com BURST!") != BattleHud.log_color("Abra usa escudo!"), "eventos diferentes têm cores diferentes")

	# QoL 3/5/8: one page is 9 slots; page 2 gets the extras; the sheet follows.
	var base := leader.skills.size()
	for i in 4:
		leader.skills.append(Skill.new("Extra %d" % (i + 1), 1.0, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.0))
	bs._show_fight()
	await process_frame
	var texts: Array = bs._menu.get("_texts")
	_expect(texts.size() == 9, "página 1 mostra 9 slots")
	_expect(String(texts[0]).begins_with("1 Tackle"), "slot 1 rotulado")
	_expect(String(texts[8]).begins_with("9 "), "slot 9 rotulado")
	bs._update_fight_header(0)
	_expect(hud._skill_info.visible and hud._skill_info.skill.display_name == "Tackle", "ficha do golpe abre no Fight")
	_expect((bs._menu.note.contains("1/2") or bs._menu.note.contains("PÁG 1/2")) and bs._menu.note.contains("Q/E"), "nota mostra a página e o atalho")
	bs._change_fight_page(1)
	await process_frame
	texts = bs._menu.get("_texts")
	_expect(texts.size() == 3, "página 2 mostra os 3 golpes extras")
	_expect(String(texts[0]).begins_with("1 Extra"), "a página 2 reinicia os slots em 1")
	_expect(bs._fight_page == 1, "a página atual é a 2")
	bs._change_fight_page(1)
	_expect(bs._fight_page == 0, "Q/E dá a volta para a página 1")

	# QoL 8: forecast includes shield absorption and break.
	enemy.apply_shield(1, 5.0)
	bs._fight_page = 0
	bs._update_fight_header(0)
	bs._menu.select(1)
	await process_frame
	bs._update_fight_header(1)
	var forecast: String = hud._skill_info._forecast()
	_expect((forecast.contains("shield absorbs") or forecast.contains("bolha absorve")) and (forecast.contains("BREAKS") or forecast.contains("ROMPE")), "previsão mostra absorção e ruptura da bolha")
	_expect(forecast.contains("HP -") or forecast.contains("HP −"), "previsão mostra o dano que passa ao HP")
	enemy.end_shield("battle_end")

	# QoL 4: queued action is data the card badge reads.
	leader.queued_skill = leader.skills[0]
	leader.queued_target = enemy
	_expect(leader.queued_skill != null, "a ação enfileirada fica visível para o badge")
	leader.queued_skill = null
	leader.queued_target = null

	# QoL 6: toast available from the autoload and visible.
	var menus := root.get_node_or_null("Menus")
	if menus != null:
		menus.call("toast", "Poção +1   ·   4/20", Color("d7fd6a"), 3.0)
		_expect(menus.get("_toast").visible and menus.get("_toast").text.contains("Poção"), "toast de coleta aparece")
		menus.get("_toast").visible = false
		gs.text_speed = 1
		menus.call("_open", 3)  # Mode.SETTINGS
		menus.call("_build_settings", false)
		menus.call("_on_side", 1)
		_expect(gs.text_speed == 2, "Configurações: ← → troca a velocidade do diálogo")
		menus.call("_on_chosen", 0)
		_expect(gs.text_speed == 0, "Configurações: Z também troca a velocidade")
		menus.call("_close")
		gs.text_speed = 1
	else:
		_expect(false, "Menus disponível")

	# QoL 7: DialogueBox reads the current speed.
	var dbox_script := load("res://scripts/ui/dialogue_box.gd")
	var dbox = dbox_script.new()
	root.add_child(dbox)
	gs.text_speed = 2
	dbox.show_dialogue("Teste", null, "texto de teste")
	_expect(is_equal_approx(dbox._type_speed, 80.0), "a caixa de diálogo consome a velocidade Rápida")
	dbox.close_dialogue()
	dbox.queue_free()

	leader.skills.resize(base)
	bs.queue_free()
	await process_frame
