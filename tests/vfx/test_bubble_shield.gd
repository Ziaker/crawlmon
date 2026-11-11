extends SceneTree
## D-323: Bubble Shield no jogo real.
## - ALL ALLIES do lado do lançador, 25 + MAG por aliado, 8 s, reaplicação reseta.
## - Absorve antes do HP, rompe ao zerar e expira pelo relógio.
## - O ponto do splash fica no hemisfério da câmera (nunca no lado oposto).
## Rodar: Godot --headless --path . --script res://tests/vfx/test_bubble_shield.gd

var failures := 0


func _init() -> void:
	call_deferred("_run")


func ok(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] ", msg)
	else:
		failures += 1
		print("  [FAIL] ", msg)


func _run() -> void:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	var guard := 0
	while not battle.running and guard < 600:
		await process_frame
		guard += 1
	for c in battle.party + battle.enemies:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	await process_frame
	print("--- BUBBLE SHIELD ---")
	var abra: Combatant = battle.party[0]
	var gible: Combatant = battle.enemies[0]
	var skill: Skill = null
	for s in abra.skills:
		if s.display_name == "Bubble Shield":
			skill = s
	if skill == null:
		# O teste é de VFX/efeito; injeta o Move no cenário sem mudar o loadout canônico.
		skill = Skill.from_id(&"bubble_shield")
		if skill != null:
			abra.skills.append(skill)
	abra.max_mp = maxi(abra.max_mp, 99)
	abra.mp = 99
	ok(skill != null, "Abra possui Bubble Shield (injetado no teste)")
	if skill == null:
		_finish()
		return
	ok(skill.cost == 3 and skill.kind == Skill.Kind.STATUS and skill.is_friendly and skill.is_aoe, "ficha: status, ALL ALLIES, 3 ATB")
	ok(is_equal_approx(skill.windup, 0.5), "ficha: wind-up 0,5 s (move.tres)")

	var fx: BattleFx = bs.fx
	var has_bubble_fx := false
	for p in fx.get_property_list():
		if String(p.get("name", "")) == "fx_bubble":
			has_bubble_fx = true
	if not has_bubble_fx:
		ok(false, "BattleFx.fx_bubble não existe no jogo atual; Bubble Shield não está integrado")
		_finish()
		return
	abra.atb = 5.0
	var started := battle.use_skill(abra, skill, abra)
	ok(started, "o combate aceita Bubble Shield")
	await process_frame
	ok(fx.fx_bubble._windup_list.size() == battle.party.size(), "uma coroa de papel por aliado vivo")
	ok(is_equal_approx(BubbleShieldWindup.RELEASE_SECONDS, 2.45), "wind-up visual some 1 s mais devagar (2,45 s)")
	guard = 0
	while guard < 900 and not abra.is_shielded():
		await process_frame
		guard += 1
	ok(abra.is_shielded(), "escudo aplicado após o wind-up")
	var expected := 25 + abra.mag
	var all_ok := true
	for c in battle.party:
		if not c.is_shielded() or c.shield_hp != expected:
			all_ok = false
	ok(all_ok, "25 + MAG (%d) em cada aliado, incluindo o lançador" % expected)
	ok(fx.fx_bubble._bubbles.size() == battle.party.size(), "uma bolha visual por aliado")
	var bubble_visual = fx.fx_bubble._bubbles[abra]
	ok(is_equal_approx(bubble_visual.root.scale.x / bubble_visual.root.scale.y, 1.15), "bolha 15% mais larga no diâmetro (X/Z), altura intacta")
	ok(is_equal_approx(abra.shield_timer, 8.0), "duração inicial de 8 s")

	# O splash tem de cair no lado da câmera.
	var visual = fx.fx_bubble._bubbles[abra]
	var cam: Vector3 = fx._cam_pos()
	var to_cam := Vector3(cam.x - visual.center.x, 0.0, cam.z - visual.center.z).normalized()
	var point: Vector3 = fx.fx_bubble.camera_hit_point(visual.center, visual.radius)
	var to_point := Vector3(point.x - visual.center.x, 0.0, point.z - visual.center.z).normalized()
	ok(to_point.dot(to_cam) > 0.85, "ponto de impacto no hemisfério da câmera (frente visível)")

	var hp_before := abra.hp
	var fx_nodes_before := fx.get_child_count()
	var pops_before: int = bs.hud._pops.size()
	var info1 := battle._hit(gible, abra, 0.5, Element.Type.FISICO, "Tackle")
	await process_frame
	ok(fx.last_hit_info == info1, "impacto do Move continua quando a bolha absorve tudo (D-1113)")
	ok(fx.get_child_count() > fx_nodes_before, "o VFX de impacto do Move foi criado")
	ok(bs.hud._pops.size() == pops_before, "sem número de dano 0 quando a bolha absorve tudo")
	ok(int(info1.get("shield_absorbed", 0)) > 0, "o golpe consome a reserva")
	ok(int(info1.get("dmg", -1)) == 0, "com reserva suficiente, nenhum dano vai ao HP")
	ok(abra.hp == hp_before, "HP intacto quando a bolha segura tudo")
	ok(int(abra.shield_hp) < expected, "reserva diminuiu")

	# Força a reserva a 1 para conferir a ruptura e o excedente. Poder 2 garante
	# dano maior que 1 sem matar o alvo (com 0,5 o excedente podia arredondar para 0).
	abra.shield_hp = 1
	var info2 := battle._hit(gible, abra, 2.0, Element.Type.FISICO, "Tackle")
	ok(bool(info2.get("shield_broke", false)), "reserva zerada rompe a bolha")
	ok(int(info2.get("dmg", 0)) > 0, "o excedente vai para o HP")
	ok(not abra.is_shielded(), "sem reserva, o escudo deixa de estar ativo")
	await process_frame
	ok(visual.breaking, "a bolha entra na animação de ruptura")

	# Reaplicação reseta valor e prazo.
	abra.atb = 5.0
	guard = 0
	while guard < 900 and battle._status_pause != null:
		await process_frame
		guard += 1
	abra.shield_timer = 1.0
	var refreshed := battle.use_skill(abra, skill, abra)
	ok(refreshed, "reaplicação aceita")
	guard = 0
	while guard < 900 and not abra.is_shielded():
		await process_frame
		guard += 1
	ok(abra.is_shielded() and abra.shield_hp == expected and is_equal_approx(abra.shield_timer, 8.0), "reaplicação reseta reserva e duração")

	# Expiração pelo relógio.
	var expired_reason := [""]
	abra.shield_ended.connect(func(_c, reason): expired_reason[0] = reason)
	abra.tick_shield(8.0)
	ok(expired_reason[0] == "expired" and not abra.is_shielded(), "expira ao fim dos 8 s e emite expired")
	await process_frame
	var current = fx.fx_bubble._bubbles.get(abra)
	if current != null:
		ok(current.expiring, "a bolha entra na dissolução de expiração")

	fx.fx_bubble.clear_all("battle_end")
	bs.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	Engine.time_scale = 1.0
	if failures == 0:
		print("BUBBLE_SHIELD_TEST_PASS")
	else:
		print("BUBBLE_SHIELD_TEST_FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
