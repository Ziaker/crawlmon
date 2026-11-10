extends SceneTree
## D-160 KO launch direction, D-161 move buffer, D-162 Fight slow-motion,
## D-163 wind-up loop, D-164 counter-attack after every perfect Evade.

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


func _skill(c: Combatant, skill_name: String) -> Skill:
	for s in c.skills:
		if s.display_name == skill_name:
			return s
	# D-1079: the move catalog is the single source; tests must use the new layer.
	for s in Skill.all_catalog_skills():
		if s.display_name == skill_name:
			return s
	return Skill.basic()


func _end(bs: Node3D) -> void:
	Engine.time_scale = 1.0
	bs.free()


func _ko_goes_back(attacker_i: int, move: String) -> void:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var e: Combatant = b.enemies[0]
	var a: Combatant = b.party[attacker_i]
	var m: Node3D = bs.models[e]
	Engine.time_scale = 1.0
	# A IA em HOLD ainda bebe poção quando está ferida; sem inventário o alvo de 1 HP não se cura
	# no meio do wind-up (era a causa de hp 1 -> 31 e do K.O. que nunca acontecia). Só os inimigos:
	# a party é persistente entre cenas e não deve perder inventário por causa deste teste.
	for c in b.party + b.enemies:
		c.queued_skill = null
		c.queued_target = null
	for c in b.enemies:
		c.inventory.clear()
	var center := Vector3.ZERO
	for p in b.party:
		center += p.home
	center /= float(b.party.size())
	var away := e.home - center
	away.y = 0.0
	away = away.normalized()
	var before := m.position
	var dead := false
	var used_any := false
	for tries in 8:
		# Wait for the attacker and the status engine; a shot sent during a return would be refused.
		var idle_deadline := Time.get_ticks_msec() + 3000
		while Time.get_ticks_msec() < idle_deadline and (b.is_attacking(a) or b.is_winding_up(a) or b.is_attacking(e) or b.is_winding_up(e) or b._status_pause != null):
			await process_frame
		if b.is_attacking(a) or b.is_winding_up(a) or b.is_attacking(e) or b.is_winding_up(e) or b._status_pause != null:
			print("    [KO] %s: atacante/alvo não ficou ocioso (attacking=%s/%s winding=%s/%s pause=%s)" % [move, b.is_attacking(a), b.is_attacking(e), b.is_winding_up(a), b.is_winding_up(e), b._status_pause != null])
			break
		if not b.running or not e.is_alive():
			break
		# Reassert the target state before every attempt: no Guard, ARMOR, shield, blind, stun or invulnerability.
		e.hp = 1
		e.guard_timer = 0.0
		e.armor_timer = 0.0
		e.shield_timer = 0.0
		e.shield_hp = 0
		e.is_invulnerable = false
		e.blind_timer = 0.0
		e.stun_timer = 0.0
		e.clear_burn()  # D-238: Burn kills without K.O. launch; the target must die from the hit.
		e.taunted_by = null
		e.taunt_atk_bonus = false
		e.queued_skill = null
		e.queued_target = null
		a.atb = 5.0
		a.mp = a.max_mp  # D-413: retries must not run out of MP
		a.queued_skill = null
		a.queued_target = null
		b.debug_roll = 1  # force the hit; this test is about the KO launch, not dodge RNG
		before = m.position
		var used := b.use_skill(a, _skill(a, move), e)
		used_any = used_any or used
		if not used:
			print("    [KO] %s: use_skill=false (attacking=%s winding=%s pause=%s atb=%.1f mp=%d)" % [move, b.is_attacking(a), b.is_winding_up(a), b._status_pause != null, a.blocks(), a.mp])
			await process_frame
			continue
		# Wait for the hit/death in real time; the frame count is not a clock without --fixed-fps.
		var hit_deadline := Time.get_ticks_msec() + 5000
		while e.is_alive() and Time.get_ticks_msec() < hit_deadline:
			await process_frame
			if e.is_alive():
				before = m.position
		if not e.is_alive():
			dead = true
			break
	# The K.O. starts the victory slow-motion (D-400), so the 1.05 s launch takes longer in real
	# time. Wait for the body to travel, with a bounded deadline, instead of a fixed wall-clock wait.
	var flight_deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < flight_deadline:
		await process_frame
		var flown := m.position - before
		flown.y = 0.0
		if flown.length() > 9.0:
			break
	var d := m.position - before
	d.y = 0.0
	if not dead and e.is_alive():
		print("    [KO] %s: o alvo não morreu após 8 tentativas (hp=%d, use_skill=%s)" % [move, e.hp, used_any])
	if dead and d.length() <= 8.0:
		print("    [KO] %s: o alvo morreu mas o lançamento não afastou (final=%s, before=%s)" % [move, m.position, before])
	_expect(not e.is_alive() and d.length() > 8.0 and d.normalized().dot(away) > 0.5, "KO com %s voa para longe dos jogadores (dot %.2f, dist %.2f)" % [move, d.normalized().dot(away), d.length()])
	_end(bs)


func _test_windup_loop() -> void:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var e: Combatant = b.enemies[0]
	var l: Combatant = b.party[0]
	var ap: AnimationPlayer = (bs.models[e] as Node3D).get_meta("anim_player")
	_expect(ap.get_animation("charge").loop_mode == Animation.LOOP_LINEAR, "charge está em loop")
	b.use_skill(e, _skill(e, "Dragon Rage"), l)
	await create_timer(1.6, true, false, true).timeout
	_expect(ap.is_playing() and ap.current_animation == "charge", "charge segue tocando além do fim do clipe (1,6 s de 2 s)")
	var inc: Incoming = b.incoming[0]
	b.incoming.erase(inc)
	b.attack_cancelled.emit(inc)
	_expect(ap.current_animation != "charge", "wind-up cancelado volta ao idle")
	_end(bs)


func _test_slowmo() -> void:
	var bs: Node3D = await _scene()
	bs._show_fight()
	_expect(is_equal_approx(bs._decision_slowmo_time_left, 2.0), "Fight: 2 s de câmera lenta")
	bs._on_cancel()
	bs._decision_slowmo_available = true
	bs._show_items()
	_expect(is_equal_approx(bs._decision_slowmo_time_left, 3.0), "Itens: 3 s de câmera lenta")
	bs._on_cancel()
	_end(bs)


## The leader presses Evade with `left` seconds of the window remaining, standing still.
func _still_evade(left: float) -> Array:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var e: Combatant = b.enemies[0]
	var l: Combatant = b.party[0]
	b.use_skill(e, Skill.basic(), l)
	var inc: Incoming = b.incoming.back()
	while not inc.impacted:
		await process_frame
		if inc.can_evade_now():  # D-988: the window ends 0.25 s before the contact, not at travel_left 0.2
			b.try_evade(l, inc)
			break
	return [bs, b, e, l, inc]


func _test_perfect_counter() -> void:
	var r: Array = await _still_evade(0.2)  # inside the 0.25 s window
	var b: Battle = r[1]
	var l: Combatant = r[3]
	var inc: Incoming = r[4]
	_expect(inc.perfect and l.counter_ready and l.burst == 1, "desvio perfeito parado: Burst e contra-ataque pronto")
	_expect(not inc.evader_teleported and not l.has_rest, "desvio perfeito parado não teleporta")
	Engine.time_scale = 1.0
	await create_timer(0.3, true, false, true).timeout
	var ok: bool = b.use_skill(l, Skill.basic(), r[2])
	var n: Incoming = b.incoming.back()
	_expect(ok and n.instant and is_equal_approx(n.total_windup, Battle.COUNTER_WINDUP), "contra-ataque com wind-up de 0,3 s (D-284)")
	_expect(not l.counter_ready, "contra-ataque consumido")
	_end(r[0])

	# D-283: pressing before the last 0.25 s does nothing (there is no early Evade).
	var bs: Node3D = await _scene()
	var b2: Battle = bs.get_node("Battle")
	var e2: Combatant = b2.enemies[0]
	var l2: Combatant = b2.party[0]
	b2.use_skill(e2, Skill.basic(), l2)
	var inc2: Incoming = b2.incoming.back()
	var early_pressed := false
	var early_ok := true
	while not inc2.impacted:
		await process_frame
		if not early_pressed and inc2.in_strike_window() and inc2.travel_left() > 0.4:
			early_pressed = true
			early_ok = b2.try_evade(l2, inc2)
	_expect(early_pressed and not early_ok and not inc2.dodged and l2.burst == 0 and not l2.counter_ready, "Evade antes dos últimos 0,25 s não tem efeito (D-283)")
	_end(bs)


func _test_status_pause_queue() -> void:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var e: Combatant = b.enemies[0]
	var l: Combatant = b.party[0]
	b.use_skill(e, _skill(e, "Rakunda"), l)
	await process_frame
	_expect(b._status_pause != null, "pausa de status ativa")
	var atb0 := l.atb
	_expect(bs._use_move(Skill.basic(), e), "move aceito durante a pausa")
	_expect(l.queued_skill != null and not b.is_winding_up(l), "o move espera: não fura a pausa")
	_expect(is_equal_approx(l.atb, atb0), "nada é pago ao escolher")
	while b._status_pause != null:
		await process_frame
	await process_frame
	await process_frame
	_expect(b.is_winding_up(l) and l.queued_skill == null, "o move começa quando a pausa acaba")
	_expect(l.atb < atb0, "pago ao executar")
	_end(bs)


func _test_action_queue() -> void:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var e: Combatant = b.enemies[0]
	var l: Combatant = b.party[0]
	e.max_hp = 9999
	e.hp = 9999
	var fast := Skill.new("Tackle", 0.1, 1, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 0.05)
	_expect(bs._use_move(fast, e), "primeiro move começa")
	_expect(l.queued_skill == null, "primeiro move não vai para a vaga")
	_expect(bs._use_move(_skill(l, "Sukunda"), e), "segundo move aceito durante a ação")
	_expect(bs._use_move(fast, e) and l.queued_skill == fast, "escolher outro substitui")
	await process_frame
	var first: Incoming = b.attacks_in_flight()[0] if not b.attacks_in_flight().is_empty() else b.incoming[0]
	while first.phase != Battle.Phase.RETURN:
		await process_frame
	_expect(l.queued_skill != null, "ainda espera logo depois do impacto")
	while first.phase_time < first.hold + 0.05:
		await process_frame
	_expect(l.queued_skill != null and first.phase == Battle.Phase.RETURN, "ainda espera durante o pulo de volta (opção A)")
	while l.queued_skill != null:
		await process_frame
	_expect(first.phase == Battle.Phase.DONE, "começa só com o retorno terminado")
	_expect(b.is_winding_up(l), "o move da vaga começou")

	# No ATB when its moment comes: it is dropped.
	while b.is_attacking(l):
		await process_frame
	var pricey := Skill.new("Brick Break", 0.1, 5, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 0.05)
	l.atb = 5.0
	b.use_skill(l, fast, e)
	l.atb = 0.0
	_expect(bs._use_move(pricey, e), "dá para escolher sem ter ATB")
	while b.is_attacking(l):
		l.atb = 0.0
		await process_frame
	await process_frame
	await process_frame
	_expect(l.queued_skill == null and not b.is_winding_up(l), "sem ATB na hora: descartado")
	_end(bs)


func _test_interrupt_drops_queue() -> void:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var e: Combatant = b.enemies[0]
	var l: Combatant = b.party[0]
	b.use_skill(l, Skill.basic(), e)
	bs._use_move(Skill.basic(), e)
	_expect(l.queued_skill != null, "move guardado durante o preparo")
	b._interrupt_attacks_of(l, e, 1.0)
	_expect(l.queued_skill == null, "interrupção descarta o move guardado")
	_end(bs)


func _test_tarukaja_keeps_size() -> void:
	var bs: Node3D = await _scene()
	var b: Battle = bs.get_node("Battle")
	var p: Combatant = b.party[1]
	var m: Node3D = bs.models[p]
	var s0 := m.scale.x
	b.use_skill(p, _skill(p, "Tarukaja"), p)
	await create_timer(3.0, true, false, true).timeout
	_expect(p.atk_buff == 1 and is_equal_approx(m.scale.x, s0 * 1.15), "Tarukaja: o tamanho fica depois do VFX (%.3f)" % m.scale.x)
	_end(bs)


func _run() -> void:
	await _test_tarukaja_keeps_size()
	await _ko_goes_back(0, "Tackle")
	await _ko_goes_back(0, "Confusion")
	await _ko_goes_back(1, "Karate Chop")
	await _test_windup_loop()
	await _test_slowmo()
	await _test_perfect_counter()
	await _test_status_pause_queue()
	await _test_action_queue()
	await _test_interrupt_drops_queue()
	print("D160_D164_COMBAT_FIXES_TEST_PASS" if failures == 0 else "TESTES COM %d FALHAS" % failures)
	quit(1 if failures > 0 else 0)
