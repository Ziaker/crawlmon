extends SceneTree
## Drain Spear (move_drain_spear): mid-range contact, Badge Steal before the damage, 0.30 s
## transfer, magic damage 5 + MAG - SPI, evade/auto-dodge cancelling the steal, and the same
## rules with the attacker on the enemy side.
##   godot --headless --path . --script res://tests/battle/test_drain_spear.gd

const DT := 1.0 / 60.0
const DrainSpearMove = preload("res://scripts/data/drain_spear_move.gd")
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(ok: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
	if not ok:
		failures += 1


func _mk(n: String, player: bool, p: Vector3, yaw: float, hp := 100, atk := 10, mag := 10, spi := 0) -> Combatant:
	var c := Combatant.new(n, hp, atk, 0.5, player, mag)
	c.spi = spi
	c.max_mp = 20
	c.mp = 20
	c.place(p, yaw)
	c.act_policy = Combatant.Act.HOLD
	c.react_policy = Combatant.React.NONE
	c.atb = 5.0
	c.clips = {"attack": 1.0}
	return c


func _world(attacker_player := true) -> Dictionary:
	var b := Battle.new()
	var attacker := _mk("Orc", attacker_player, Vector3(0, 0, 0), PI if attacker_player else 0.0, 100, 13, 10, 0)
	var target := _mk("Target", not attacker_player, Vector3(0, 0, -30), 0.0 if attacker_player else PI, 100, 10, 10, 3)
	var party: Array[Combatant] = []
	var foes: Array[Combatant] = []
	if attacker_player:
		party.append(attacker)
		foes.append(target)
	else:
		party.append(target)
		foes.append(attacker)
	b.start(party, foes)
	for c in party + foes:
		c.atb = 5.0
	b.debug_roll = 1
	return {"b": b, "a": attacker, "t": target}


func _give_badges(target: Combatant) -> void:
	target.buff_stat("atk", 2)
	target.buff_stat("def", -1)
	target.apply_shield(18, 8.0)
	# The move takes ~2.5 s to reach the target, so the badge must outlive the advance.
	target.apply_magic_immunity(10.0)


func _until_impact(b: Battle, inc: Incoming, limit := 8.0) -> float:
	var t := 0.0
	while t < limit and not inc.impacted:
		b._process(DT)
		t += DT
	return t


func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — DRAIN SPEAR (move_drain_spear)")
	print("=================================================================")
	_test_contract()
	_test_steal_before_damage()
	_test_transfer_delay()
	_test_no_badges()
	_test_auto_evade()
	_test_manual_evade()
	_test_mirrored()
	_test_different_target_size()
	print("-----------------------------------------------------------------")
	if failures == 0:
		print("DRAIN_SPEAR_TEST_PASS")
	else:
		print("DRAIN_SPEAR_TEST_FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func _test_contract() -> void:
	print("[*] Contrato do Move")
	var skill := DrainSpearMove.make()
	_expect(skill.cost == 2, "custa 2 ATB")
	_expect(is_equal_approx(DrainSpearMove.REACH, 16.3), "alcance de contato 16,3u")
	_expect(DrainSpearMove.badge_steal(skill), "tem Badge Steal")
	_expect(DrainSpearMove.magic_flat(skill) == 5, "dano mágico 5 + MAG - SPI")
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	_expect(Battle.estimate_damage(a, t, skill) == 12, "previsão 5 + 10 MAG - 3 SPI = 12")
	_expect(b.use_skill(a, skill, t), "a batalha aceita o Move")
	var inc: Incoming = b.incoming[0]
	_expect(is_equal_approx(inc.total_windup, 1.0), "wind-up 1,0 s")
	_until_impact(b, inc)
	_expect(inc.impacted, "o golpe chega")
	_expect(a.pos.distance_to(t.pos) >= 15.3 and a.pos.distance_to(t.pos) <= 17.3,
		"o atacante para na faixa 15,3–17,3u (%.2f)" % a.pos.distance_to(t.pos))


func _test_steal_before_damage() -> void:
	print("[*] Badge Steal antes do dano")
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	_give_badges(t)
	var skill := DrainSpearMove.make()
	b.use_skill(a, skill, t)
	var inc: Incoming = b.incoming[0]
	_until_impact(b, inc)
	_expect(t.hp == 88, "dano mágico 12 chegou ao HP (hp %d)" % t.hp)
	_expect(t.shield_hp == 0 and not t.is_shielded(), "o escudo foi roubado e não absorveu")
	_expect(t.atk_buff == 0, "ATK +2 saiu do alvo")
	_expect(t.def_buff == -1, "debuff DEF -1 NÃO foi roubado")
	_expect(not t.is_magic_immune(), "imunidade mágica saiu antes do dano")
	_expect(inc.data.get("drain_steal", []).size() == 3, "três badges elegíveis (ATK, escudo, imunidade)")
	_expect(a.atk_buff == 0, "o atacante ainda não recebeu (transferência de 0,30 s)")


func _test_transfer_delay() -> void:
	print("[*] Transferência de 0,30 s")
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	_give_badges(t)
	b.use_skill(a, DrainSpearMove.make(), t)
	var inc: Incoming = b.incoming[0]
	_until_impact(b, inc)
	for i in 6:  # 0,10 s: still flying
		b._process(DT)
	_expect(a.atk_buff == 0 and a.shield_hp == 0 and not a.is_magic_immune(), "aos 0,10 s nada chegou")
	for i in 15:  # +0,25 s: 0,35 s total
		b._process(DT)
	_expect(a.atk_buff == 2, "ATK +2 chega ao atacante")
	_expect(a.shield_hp == 18 and a.shield_timer > 7.5, "escudo 18 chega com duração reiniciada")
	_expect(a.is_magic_immune() and a.magic_immune_timer > 9.5, "imunidade mágica chega com duração máxima")


func _test_no_badges() -> void:
	print("[*] Alvo sem badges")
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	b.use_skill(a, DrainSpearMove.make(), t)
	var inc: Incoming = b.incoming[0]
	_until_impact(b, inc)
	_expect(t.hp == 88, "dano mágico normal")
	_expect(inc.data.get("drain_steal", []).is_empty(), "sem badges para roubar")
	for i in 30:
		b._process(DT)
	_expect(a.atk_buff == 0 and a.shield_hp == 0 and not a.is_magic_immune(), "nada é transferido")


func _test_auto_evade() -> void:
	print("[*] Esquiva automática")
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	_give_badges(t)
	b.debug_roll = 2
	b.use_skill(a, DrainSpearMove.make(), t)
	var inc: Incoming = b.incoming[0]
	_until_impact(b, inc)
	_expect(inc.auto_dodged, "a esquiva automática foi marcada")
	_expect(t.hp == 100, "0 dano")
	_expect(t.atk_buff == 2 and t.shield_hp == 18 and t.is_magic_immune(), "nenhum badge é roubado")
	_expect(inc.data.get("drain_steal", []).is_empty(), "lista de roubo vazia")


func _test_manual_evade() -> void:
	print("[*] Esquiva manual na janela")
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	_give_badges(t)
	b.use_skill(a, DrainSpearMove.make(), t)
	var inc: Incoming = b.incoming[0]
	var t0 := 0.0
	while t0 < 5.0 and not inc.can_evade_now():
		b._process(DT)
		t0 += DT
	var evaded := b.try_evade(t, inc)
	_expect(evaded and inc.dodged, "a esquiva manual é aceita na janela")
	_until_impact(b, inc)
	_expect(t.hp == 100, "0 dano")
	_expect(t.atk_buff == 2 and t.shield_hp == 18 and t.is_magic_immune(), "nenhum badge é roubado")


func _test_mirrored() -> void:
	print("[*] Lado espelhado (atacante inimigo)")
	var w := _world(false)
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	_give_badges(t)
	b.use_skill(a, DrainSpearMove.make(), t)
	var inc: Incoming = b.incoming[0]
	_until_impact(b, inc)
	_expect(t.hp == 88, "o dano é o mesmo do outro lado")
	_expect(a.pos.distance_to(t.pos) >= 15.3 and a.pos.distance_to(t.pos) <= 17.3,
		"o atacante inimigo também para na faixa (%.2f)" % a.pos.distance_to(t.pos))
	for i in 30:
		b._process(DT)
	_expect(a.atk_buff == 2 and a.shield_hp == 18 and a.is_magic_immune(), "os badges chegam ao atacante inimigo")


func _test_different_target_size() -> void:
	print("[*] Alvo de tamanho diferente")
	var w := _world()
	var b: Battle = w["b"]
	var a: Combatant = w["a"]
	var t: Combatant = w["t"]
	t.name = "Colossus"
	t.max_hp = 200
	t.hp = 200
	t.body_scale = 2.2
	_give_badges(t)
	b.use_skill(a, DrainSpearMove.make(), t)
	var inc: Incoming = b.incoming[0]
	_until_impact(b, inc)
	_expect(t.hp == 188, "o dano mágico não depende do tamanho do alvo")
	_expect(a.pos.distance_to(t.pos) >= 15.3 and a.pos.distance_to(t.pos) <= 17.3,
		"o contato continua na faixa de 16,3u (%.2f)" % a.pos.distance_to(t.pos))
	_expect(t.atk_buff == 0 and t.shield_hp == 0 and not t.is_magic_immune(), "os badges são roubados do alvo grande")
	for i in 30:
		b._process(DT)
	_expect(a.atk_buff == 2 and a.shield_hp == 18, "o atacante recebe os badges do alvo grande")
