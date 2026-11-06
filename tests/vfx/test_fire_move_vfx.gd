extends SceneTree
## D-236: Fire Bullet. Qualquer atacante (D-235), nos dois lados: o wind-up vira a mão de fogo, o tiro vira
## o voo (bala + 3 anéis) e o acerto cria o impacto; o impacto "interrompido" não faz ricochete.

var failures := 0
var room: Node
var stages_seen: Dictionary = {}
var last_info: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	room = (load("res://scenes/debug/vfx_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var waited := 0
	while room._units.is_empty() and waited < 900:
		await process_frame
		waited += 1
	room._speed.value = 1.5
	# (atacante, alvo, espelhado): o Abra e o Pancham atiram no Gible e o Gible atira de volta.
	for case in [[0, 2, false], [1, 0, false], [2, 0, false], [1, 0, true], [0, 2, true]]:
		await _shoot(case[0], case[1], case[2])
	await _channel_case()
	await _impact_variants()
	room.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if failures == 0:
		print("FIRE_MOVE_VFX_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _shoot(att: int, tgt: int, mirror: bool) -> void:
	await room._load_battle(mirror)
	room._speed.value = 1.5
	room._attacker.select(att)
	room._fill_moves()
	var found := false
	for i in room._move.item_count:
		if room._move.get_item_text(i) == "Fire Bullet":
			room._move.select(i)
			found = true
	var who := "%s -> %s%s" % [room._units[att].name, room._units[tgt].name, " (espelhado)" if mirror else ""]
	_expect(found, "Fire Bullet deve estar na lista de qualquer atacante da sala: " + who)
	if not found:
		return
	room._target.select(tgt)
	room._force.select(1)  # acerto garantido
	stages_seen.clear()
	last_info = {}
	var cb := func(_a, _t, _e, info) -> void: last_info = info
	room._battle.hit_resolved.connect(cb)
	room._fire()
	_expect(room._fired, "o combate deve aceitar Fire Bullet: " + who + " " + String(room._status.text))
	var guard := 0
	while guard < 900:
		await process_frame
		guard += 1
		for n in room._bs.fx.get_children():
			if n is FireMoveVfx:
				stages_seen[(n as FireMoveVfx).stage] = true
		if not last_info.is_empty() and room._battle.attacks_in_flight().is_empty() and guard > 240:
			break
	room._battle.hit_resolved.disconnect(cb)
	_expect(stages_seen.has(FireMoveVfx.Stage.WINDUP), "a mão de fogo (WINDUP) deve aparecer: " + who)
	_expect(stages_seen.has(FireMoveVfx.Stage.TRAVEL), "o voo (TRAVEL) deve aparecer: " + who)
	_expect(stages_seen.has(FireMoveVfx.Stage.IMPACT), "o impacto (IMPACT) deve aparecer: " + who)
	_expect(not last_info.is_empty() and last_info.has("interrupted"), "o acerto informa se interrompeu uma ação do alvo: " + who)
	# a camada acaba sozinha: nada de FireMoveVfx sobra depois do efeito
	guard = 0
	while guard < 400:
		await process_frame
		guard += 1
		var left := 0
		for n in room._bs.fx.get_children():
			if n is FireMoveVfx:
				left += 1
		if left == 0:
			break
	var leftover := 0
	for n in room._bs.fx.get_children():
		if n is FireMoveVfx:
			leftover += 1
	_expect(leftover == 0, "as camadas de fogo se liberam sozinhas (sobraram %d): %s" % [leftover, who])


## "Alvo canalizando" da sala: o acerto do Fire Bullet interrompe a ação do alvo (info["interrupted"]) e o
## impacto especial (sem ricochete) é o escolhido; sem canalizar, o acerto não interrompe nada.
func _channel_case() -> void:
	for channel in [true, false]:
		await room._load_battle(false)
		room._speed.value = 1.5
		room._attacker.select(0)
		room._fill_moves()
		for i in room._move.item_count:
			if room._move.get_item_text(i) == "Fire Bullet":
				room._move.select(i)
		room._target.select(2)
		room._force.select(1)
		room._channel.button_pressed = channel
		last_info = {}
		var cb := func(_a, _t, _e, info) -> void:
			if last_info.is_empty():
				last_info = info
		room._battle.hit_resolved.connect(cb)
		room._fire()
		var guard := 0
		while guard < 600 and last_info.is_empty():
			await process_frame
			guard += 1
		room._battle.hit_resolved.disconnect(cb)
		_expect(bool(last_info.get("interrupted", false)) == channel, "interrupted deve ser %s com o alvo %s (info=%s)" % [channel, "canalizando" if channel else "parado", str(last_info.get("interrupted"))])
		guard = 0
		while guard < 400 and not room._battle.attacks_in_flight().is_empty():
			await process_frame
			guard += 1


func _impact_variants() -> void:
	await room._load_battle(false)
	var fx: BattleFx = room._bs.fx
	var normal := FireMoveVfx.impact(fx, "fire_bullet", Vector3(0, 1, -8), false, Vector3(0, 0, -1), false)
	var cocoon := FireMoveVfx.impact(fx, "fire_bullet", Vector3(4, 1, -8), true, Vector3(0, 0, 1), true)
	for i in 6:
		await process_frame
	_expect(normal._pts.any(func(q) -> bool: return q.kind == "bullet") or normal._pts.size() > 0, "o impacto normal solta o ricochete da bala")
	_expect(not cocoon._pts.any(func(q) -> bool: return q.kind == "bullet"), "o impacto interrompido NÃO faz ricochete")
	_expect(cocoon._ring_used >= 4, "o impacto interrompido é um estouro em argolas (argolas desenhadas: %d)" % cocoon._ring_used)
	var guard := 0
	while (is_instance_valid(normal) or is_instance_valid(cocoon)) and guard < 400:
		await process_frame
		guard += 1
	_expect(not is_instance_valid(normal) and not is_instance_valid(cocoon), "os impactos se liberam sozinhos")


func _expect(c: bool, m: String) -> void:
	if not c:
		failures += 1
		push_error(m)
