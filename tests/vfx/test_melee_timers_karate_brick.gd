extends SceneTree
## Tempos de Mach Punch, Karate Chop e Brick Break feitos por Gible, Abra e Pancham (D-235: o tempo é do Move, não do personagem).
## Mede, pelo registro de fases da sala de VFX, o wind-up, a corrida (TRAVEL), a espera no alvo (STRIKE) e o total.
## Rodar: godot --headless --path . --script res://tests/vfx/test_melee_timers_karate_brick.gd

var room: Node
var failures := 0
var rows: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	room = (load("res://scenes/debug/vfx_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var waited := 0
	while room._units.is_empty() and waited < 900:
		await process_frame
		waited += 1
	var moves := {
		"Karate Chop": Skill.new("Karate Chop", 1.5, 2, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.0),
		"Brick Break": Skill.new("Brick Break", 1.8, 3, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.5),
		"Mach Punch": Skill.new("Mach Punch", 0.5, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 0.2),
	}
	# D-241: espera no alvo esperada (s): Mach Punch 0,20 (sem antecipação); Karate Chop e Brick Break 0,08 + 0,45
	var expected := {"Mach Punch": 0.20, "Karate Chop": 0.53, "Brick Break": 0.53}
	for move in moves:
		for pair in [["Gible", "Abra"], ["Gible", "Pancham"], ["Abra", "Gible"], ["Abra", "Pancham"], ["Pancham", "Gible"], ["Pancham", "Abra"]]:
			await _measure(String(move), moves[move], pair[0], pair[1])
	print("")
	print("%-12s %-8s %-8s %8s %8s %8s %8s" % ["Move", "Atac.", "Alvo", "wind-up", "corrida", "espera", "total"])
	for r in rows:
		print("%-12s %-8s %-8s %8.2f %8.2f %8.2f %8.2f" % r)
	# o wind-up e a espera no alvo são do Move: iguais para todo atacante; só a corrida muda (com a distância)
	for move in moves:
		var winds: Array[float] = []
		var waits: Array[float] = []
		for r in rows:
			if r[0] == move:
				winds.append(r[3])
				waits.append(r[5])
		_expect(winds.size() == 6, "%s: 6 medições" % move)
		_expect(_spread(winds) < 0.05, "%s: wind-up igual para todos (%s)" % [move, str(winds)])
		_expect(_spread(waits) < 0.05, "%s: espera no alvo igual para todos (%s)" % [move, str(waits)])
		_expect(absf(waits[0] - float(expected[move])) < 0.04, "%s: espera no alvo = %.2f s (D-241), medido %.2f s" % [move, float(expected[move]), waits[0]])
	# a corrida é simétrica: A->B igual a B->A (depende da distância do par, não de quem ataca)
	for move in moves:
		for pair in [["Gible", "Abra"], ["Gible", "Pancham"], ["Abra", "Pancham"]]:
			var ab := _run_of(String(move), pair[0], pair[1])
			var ba := _run_of(String(move), pair[1], pair[0])
			_expect(absf(ab - ba) < 0.05, "%s: corrida %s->%s (%.2f) = %s->%s (%.2f)" % [move, pair[0], pair[1], ab, pair[1], pair[0], ba])
	room.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if failures == 0:
		print("MELEE_TIMERS_TEST_PASS")
	quit(1 if failures > 0 else 0)


func _unit(name: String) -> int:
	for i in room._units.size():
		if room._units[i].name == name:
			return i
	return -1


func _measure(move_name: String, skill: Skill, attacker: String, target: String) -> void:
	for pc in root.get_node("/root/GameState").party:  # a party persiste entre as recargas da sala: volta a vida cheia
		pc.set_hp_instant(pc.max_hp)
	await room._load_battle(false)
	# A party canônica atual é Abra + Pancham; Gible não está nela. O teste de D-235 precisa
	# dos três atacantes, então usa o spawn de debug (dois Gible inimigos) e recalcula a lista.
	if _unit("Gible") < 0:
		room._add_test_enemies()
		room._units.clear()
		room._units.append_array(room._battle.party)
		room._units.append_array(room._battle.enemies)
		room._fill_units()
	room._speed.value = 1.5
	var ai := _unit(attacker)
	var ti := _unit(target)
	var a: Combatant = room._units[ai]
	var has := false
	for s in a.skills:
		if s.display_name == move_name:
			has = true
	if not has:
		a.skills.append(skill)  # qualquer personagem pode ter o Move (D-235)
	room._attacker.select(ai)
	room._fill_moves()
	for i in room._move.item_count:
		if room._move.get_item_text(i) == move_name:
			room._move.select(i)
	room._target.select(ti)
	room._force.select(1)  # acerto garantido
	room._channel.button_pressed = false
	await room._fire()
	var guard := 0
	while guard < 1800 and not _log_has("IMPACTO"):
		await process_frame
		guard += 1
	_expect(room._fired, "%s %s->%s: o combate aceitou o golpe (rodando=%s, status=%s)" % [move_name, attacker, target, str(room._battle.running), room._status.text])
	var t_start := _t("CARGA começa")
	var t_rel := _t("CARGA termina")
	var t_travel := _t("FASE TRAVEL")
	var t_strike := _t("FASE STRIKE")
	var t_hit := _t("IMPACTO")
	_expect(t_hit > 0.0, "%s %s->%s: houve impacto" % [move_name, attacker, target])
	rows.append([move_name, attacker, target, t_rel - t_start, t_strike - t_travel, t_hit - t_strike, t_hit - t_rel])
	guard = 0
	while guard < 600 and not room._battle.attacks_in_flight().is_empty():
		await process_frame
		guard += 1


func _log_has(needle: String) -> bool:
	for l in room._log:
		if String(l).contains(needle):
			return true
	return false


## Tempo (s) da primeira linha do registro com o texto; -1 se não achar.
func _t(needle: String) -> float:
	for l in room._log:
		var s := String(l)
		if s.contains(needle):
			var re := RegEx.new()
			re.compile("t=\\s*([0-9.]+)")
			var m := re.search(s)
			if m != null:
				return float(m.get_string(1))
	return -1.0


func _run_of(move: String, attacker: String, target: String) -> float:
	for r in rows:
		if r[0] == move and r[1] == attacker and r[2] == target:
			return r[4]
	return -1.0


func _spread(v: Array[float]) -> float:
	if v.is_empty():
		return 0.0
	return v.max() - v.min()


func _expect(c: bool, m: String) -> void:
	if c:
		print("  [PASS] ", m)
	else:
		failures += 1
		print("  [FAIL] ", m)
