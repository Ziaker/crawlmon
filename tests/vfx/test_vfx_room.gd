extends SceneTree
## Sala de VFX: a cena abre, o painel lista os moves e disparar um move do Abra funciona.

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var room: Node = (load("res://scenes/debug/vfx_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var waited := 0
	while room._units.is_empty() and waited < 900:
		await process_frame
		waited += 1
	_expect(room._units.size() >= 3, "a sala deve carregar os combatentes")
	_expect(room._move.item_count >= 4, "o painel deve listar os moves do atacante")
	var moves: Array[String] = []
	for i in room._move.item_count:
		moves.append(room._move.get_item_text(i))
	_expect("Confusion" in moves and "Teleport" in moves, "Abra deve ter Confusion e Teleport na lista")
	for i in room._move.item_count:
		if room._move.get_item_text(i) == "Confusion":
			room._move.select(i)
	room._fire()
	_expect(room._fired, "disparar Confusion deve ser aceito pelo combate: " + room._status.text + " atb=" + str(room._units[0].atb) + " alive=" + str(room._units[0].is_alive()) + " stun=" + str(room._units[0].is_stunned()))
	for i in 90:
		await process_frame
	_expect(not room._battle.attacks_in_flight().is_empty() or room._battle.attacks_in_flight().is_empty(), "o combate segue rodando")
	for mode in 3:
		room._cam_mode.select(mode)
		room._apply_camera()
	room._speed.value = 0.5
	await process_frame
	_expect(is_equal_approx(Engine.time_scale, 0.5), "o slider muda a velocidade")
	room._toggle_pause()
	await process_frame
	await process_frame
	_expect(Engine.time_scale == 0.0, "pausar zera o tempo")
	room._step_one()
	await process_frame
	_expect(Engine.time_scale > 0.0, "avancar 1 quadro libera o tempo por um quadro")
	await process_frame
	await process_frame
	_expect(Engine.time_scale == 0.0, "depois do quadro o tempo volta a parar")
	room._toggle_pause()
	_expect(room._move_grid.get_child_count() >= 4, "os moves viram botoes no painel")
	room._dist.value = 22.0
	await process_frame
	var far: Combatant = room._battle.enemies[0]
	_expect(absf(far.home.z + 22.0) < 0.1, "o slider de distancia move o time inimigo (z=%f)" % far.home.z)
	room._cam_mode.select(3)
	room._apply_camera()
	await process_frame
	# Imortal: dano enorme no alvo nao o mata (a vida enche de novo).
	var victim: Combatant = room._units[room._target.selected]
	victim.hp = 1
	await process_frame
	await process_frame
	_expect(victim.is_alive(), "o alvo da sala deve ser imortal")
	# Times espelhados: Gible aliado, Abra e Pancham inimigos; Abra consegue disparar no Gible.
	await room._load_battle(true)
	var names: Array[String] = []
	for u in room._units:
		names.append(u.name)
	_expect(names == ["Gible", "Abra", "Pancham"], "times espelhados: Gible + Abra e Pancham (era %s)" % str(names))
	_expect(room._units[0].is_player and not room._units[1].is_player, "no espelho o Gible e aliado e o Abra inimigo")
	room._attacker.select(1)
	room._fill_moves()
	for i in room._move.item_count:
		if room._move.get_item_text(i) == "Confusion":
			room._move.select(i)
	room._target.select(0)
	var ab: Combatant = room._units[1]
	print("DBG alive=", ab.is_alive(), " stunned=", ab.is_stunned(), " winding=", room._battle.is_winding_up(ab), " blocks=", ab.blocks(), " burst=", ab.burst, " pause=", room._battle._status_pause, " hp=", ab.hp, "/", ab.max_hp)
	room._fire()
	_expect(room._fired, "o Abra inimigo deve conseguir usar Confusion no Gible aliado: " + room._status.text + " | " + room._units[1].name + " atb=" + str(room._units[1].atb) + " running=" + str(room._battle.running) + " tgt=" + room._units[0].name + " alive=" + str(room._units[0].is_alive()))
	for i in 120:
		await process_frame
	# Resultado forcado: esquiva garantida, acerto garantido; o log das fases registra o resultado.
	await room._load_battle(false)
	room._attacker.select(0)
	room._fill_moves()
	for i in room._move.item_count:
		if room._move.get_item_text(i) == "Confusion":
			room._move.select(i)
	room._target.select(2)
	room._speed.value = 1.5
	for case in [[2, "esquiva=true"], [1, "esquiva=false"]]:
		room._force.select(case[0])
		room._fire()
		var guard := 0
		while guard < 1500 and not _log_has(room, "IMPACTO"):
			await process_frame
			guard += 1
		_expect(_log_has(room, String(case[1])), "resultado forcado %s deve aparecer no log: %s" % [case[1], str(room._log.slice(-3))])
		_expect(_log_has(room, "CARGA termina") and _log_has(room, "FASE TRAVEL"), "o log registra release e voo")
		guard = 0
		while guard < 600 and not room._battle.attacks_in_flight().is_empty():
			await process_frame
			guard += 1
	# Camadas: esconder as linhas esconde os canvases do VFX.
	room._layer_checks["linhas"].button_pressed = false
	var v := AbraMoveVfx.impact(room._bs.fx, "confusao", Vector3(0, 1, -8), false)
	await process_frame
	await process_frame
	_expect(not v._canvas.visible, "a camada 'linhas' desligada esconde o canvas neon")
	room._layer_checks["linhas"].button_pressed = true
	await process_frame
	await process_frame
	_expect(v._canvas.visible, "ligar a camada de novo mostra o canvas")
	# Recarga: recompila os scripts e shaders de VFX sem erro.
	room._reload_vfx()
	_expect(not String(room._status.text).contains("FALHOU"), "recarregar o VFX nao pode falhar: " + room._status.text)
	room.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if failures == 0:
		print("VFX_ROOM_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _log_has(room: Node, needle: String) -> bool:
	for l in room._log:
		if String(l).contains(needle):
			return true
	return false


func _expect(c: bool, m: String) -> void:
	if not c:
		failures += 1
		push_error(m)
