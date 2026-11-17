extends SceneTree
## D-1204: cenário de debug do ataque do jogador no overworld (alvo < 10 s).
##
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script res://tests/overworld/attack_reach_scenario.gd -- \
##       [--species=abra,dqt_orc,dqt_cyclops] [--targets=dqt_cyclops,dqt_orc,gible,slime] \
##       [--gaps=0.3,1.5,3.0,3.7,4.5,7.5] [--stdout-trace] [--strict]
##
## Para cada atacante (jogador do lab), alvo, lado (+x / -x) e folga de borda (distância
## entre as bordas dos corpos), dispara o ataque real e imprime uma linha
## `ATTACK_JSON: {...}` com: distância centro a centro, borda, alcance usado, se o alvo foi
## adquirido, acerto sim/não, quadro físico do acerto, folga final (negativa = atravessou) e se
## o texto "HIT" apareceu. D-235: nada depende de espécie, time ou lado; o cenário só varia
## quem ataca, quem apanha e o lado. Sai com código 1 se --strict e algum caso violar a regra.

const LAB := "res://scenes/debug/murky_forest_3d_lab.tscn"
const ORIGIN := Vector3(500.0, 0.0, 500.0)  ## céu aberto: sem paredes, sem piso, sem linha de visão bloqueada
const FAR := 5000.0
const MAX_FRAMES := 240

var _impact_frame := -1
var _battle_frame := -1
var _impact_contacts := 0
var _impact_adv := -1


func _init() -> void:
	call_deferred("_run")


func _arg(name: String, fallback: String) -> String:
	var prefix := "--%s=" % name
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return fallback


func _expand(value: String, all: Array) -> PackedStringArray:
	if value == "all":
		return PackedStringArray(all)
	return value.split(",", false)


func _flag(name: String) -> bool:
	return OS.get_cmdline_user_args().has("--" + name)


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var species := _expand(_arg("species", "abra,dqt_orc"), ["abra", "pancham", "gible", "dqt_slime", "dqt_orc", "dqt_cyclops"])
	var targets := _expand(_arg("targets", "dqt_cyclops,gible"), ["dqt_cyclops", "dqt_orc", "gible", "slime"])
	var gaps: Array[float] = []
	for g in _arg("gaps", "0.3,3.0,3.7,4.5,7.5").split(",", false):
		gaps.append(float(g))
	var strict := _flag("strict")
	var violations := 0
	var cases := 0
	var hits := 0
	for sp in species:
		var res := await _run_species(sp, targets, gaps)
		violations += int(res["violations"])
		cases += int(res["cases"])
		hits += int(res["hits"])
	print("ATTACK_SUMMARY: {\"cases\":", cases, ",\"hits\":", hits, ",\"violations\":", violations,
		",\"ms\":", Time.get_ticks_msec() - t0, "}")
	quit(1 if (strict and violations > 0) else 0)


func _run_species(species_id: String, targets: PackedStringArray, gaps: Array[float]) -> Dictionary:
	var lab := (load(LAB) as PackedScene).instantiate()
	lab.set("player_species", species_id)
	root.add_child(lab)
	current_scene = lab
	await physics_frame
	await physics_frame
	# O lab inteiro fica parado (sem IA, sem câmera); só o controlador de ataque corre.
	lab.set_physics_process(false)
	lab.set_process(false)
	var ctrl: Node = lab.get("_attack_controller")
	var player: CharacterBody3D = lab.get("player")
	for c in ctrl.battle_requested.get_connections():
		ctrl.battle_requested.disconnect(c["callable"])
	ctrl.impact_requested.connect(func(_p, _d, adv, contacts: Array) -> void:
		_impact_adv = int(adv)
		_impact_frame = Engine.get_physics_frames()
		_impact_contacts = contacts.size())
	ctrl.battle_requested.connect(func(_a) -> void:
		_battle_frame = Engine.get_physics_frames())

	var pool := {}
	var rooms: Array = lab.get("_room_enemies")
	for entry in rooms:
		var body: CharacterBody3D = entry["node"]
		pool[str(body.name).trim_prefix("RoomEnemy_")] = body
	pool["gible"] = lab.get("_second_enemy_body")
	pool["slime"] = lab.get("_enemy_body")

	var violations := 0
	var cases := 0
	var hits := 0
	for target_id in targets:
		var target: CharacterBody3D = pool.get(target_id)
		if target == null:
			print("ATTACK_JSON: {\"error\":\"unknown_target\",\"target\":\"", target_id, "\"}")
			continue
		for side in [1.0, -1.0]:
			for gap in gaps:
				var r := await _run_case(lab, ctrl, player, pool, target, side, gap)
				r["species"] = species_id
				r["target"] = target_id
				r["side"] = "+x" if side > 0.0 else "-x"
				cases += 1
				if bool(r["hit"]):
					hits += 1
				var bad := _violations(r)
				r["violations"] = bad
				violations += bad.size()
				print("ATTACK_JSON: ", JSON.stringify(r))
	if _flag("duel"):
		violations += await _run_duels(lab, ctrl, player, pool)
	lab.queue_free()
	await process_frame
	return {"violations": violations, "cases": cases, "hits": hits}


func _violations(r: Dictionary) -> Array:
	var bad: Array = []
	# Regra D-1262: adquirido => o avanço chega à borda => acerto, para qualquer tamanho.
	if bool(r["acquired"]) and not bool(r["hit"]):
		bad.append("acquired_but_no_hit")
	if bool(r["hit"]) and float(r["final_gap"]) < -0.05:
		bad.append("passed_through_target")
	if bool(r["hit"]) and not bool(r["hit_text"]):
		bad.append("no_hit_text")
	return bad


func _run_case(lab: Node, ctrl: Node, player: CharacterBody3D, pool: Dictionary,
		target: CharacterBody3D, side: float, gap: float) -> Dictionary:
	ctrl.reset_attack_state()
	# A reação de hit do caso anterior (tween de empurrão) não pode contaminar este caso.
	for tw in lab.get_tree().get_processed_tweens():
		tw.kill()
	var locks = lab.get("_hit_move_locks")
	if locks is Dictionary:
		(locks as Dictionary).clear()
	for k in pool:
		var other: Node3D = pool[k]
		if other != target:
			other.global_position = Vector3(FAR + float(hash(k) % 1000), 0.0, FAR)
	target.global_position = ORIGIN
	target.velocity = Vector3.ZERO
	var contact: float = ctrl.call("_contact_distance", player, target)
	var center := contact + gap
	player.global_position = ORIGIN + Vector3(side * center, 0.0, 0.0)
	player.velocity = Vector3.ZERO
	var to := ORIGIN - player.global_position
	player.rotation.y = atan2(to.x, to.z)
	await physics_frame
	_impact_frame = -1
	_battle_frame = -1
	_impact_contacts = 0
	var acquired: bool = ctrl.get_attack_target() == target
	var start_frame := Engine.get_physics_frames()
	var start_pos := player.global_position
	var info: Dictionary = ctrl.reach_info(target)
	ctrl.attack_anytime()
	var guard := 0
	var hit_text := false
	while guard < MAX_FRAMES:
		await physics_frame
		guard += 1
		if _flag("trace"):
			print("TRACE f=%d phase=%d edge_gap=%.3f player=%s target=%s" % [guard, int(ctrl.get("_player_phase")),
				float(ctrl.call("_edge_gap", player, target)), str(player.global_position), str(target.global_position)])
		if _impact_frame >= 0:
			hit_text = _has_hit_text(lab)
			break
		if not ctrl.is_player_attacking():
			break
	var final_gap: float = ctrl.call("_flat_distance", player.global_position, target.global_position) - contact
	var moved := start_pos.distance_to(player.global_position)
	return {
		"center_dist": snappedf(center, 0.001),
		"contact": snappedf(contact, 0.001),
		"start_gap": gap,
		"acquired": acquired,
		"free_attack": not acquired,
		"reach_gap_max": snappedf(float(info.get("max_gap", -1.0)), 0.001),
		"weapon_bonus": snappedf(float(info.get("weapon_bonus", 0.0)), 0.001),
		"travel": snappedf(moved, 0.001),
		"hit": _impact_frame >= 0,
		"hit_frame": (_impact_frame - start_frame) if _impact_frame >= 0 else -1,
		"final_gap": snappedf(final_gap, 0.001),
		"contacts": _impact_contacts,
		"hit_text": hit_text,
	}


func _has_hit_text(lab: Node) -> bool:
	for l in lab.find_children("*", "Label3D", true, false):
		if (l as Label3D).text == "HIT":
			return true
	return false


## D-1267: choque de dois ataques ativos. O inimigo arma (telegrafo 0,4 s) e o jogador ataca em
## `t_p` segundos. Se os dois avanços se tocam, vence quem começou o ataque antes; o cenário
## imprime quem ganhou e confere com a ordem de início (empate = contato normal).
func _run_duels(lab: Node, ctrl: Node, player: CharacterBody3D, pool: Dictionary) -> int:
	var bad := 0
	var enemy: CharacterBody3D = pool["gible"]
	for side in [1.0, -1.0]:
		for t_p in [0.20, 0.30, 0.40, 0.50, 0.60, 0.70]:
			ctrl.reset_attack_state()
			for tw in lab.get_tree().get_processed_tweens():
				tw.kill()
			(lab.get("_hit_move_locks") as Dictionary).clear()
			for k in pool:
				if pool[k] != enemy:
					(pool[k] as Node3D).global_position = Vector3(FAR + float(hash(k) % 1000), 0.0, FAR)
			enemy.global_position = ORIGIN
			var contact: float = ctrl.call("_contact_distance", player, enemy)
			player.global_position = ORIGIN + Vector3(side * (contact + 2.6), 0.0, 0.0)
			player.velocity = Vector3.ZERO
			_impact_frame = -1
			_impact_adv = -1
			_impact_contacts = 0
			await physics_frame
			ctrl.notify_enemy_state(enemy, "CHASE")
			var attack_frame := int(round(t_p * 60.0))
			var f := 0
			var attacked := false
			while f < 150 and _impact_frame < 0:
				if f == attack_frame:
					ctrl.attack_anytime()
					attacked = true
				await physics_frame
				f += 1
			var adv_name := "none"
			if _impact_adv >= 0:
				adv_name = str(EncounterRules.Advantage.keys()[_impact_adv])
			# O ataque do inimigo começa 0,4 s (telegrafo) depois do aviso; o do jogador em t_p.
			var expect := "PLAYER_FIRST" if t_p < 0.4 - 0.01 else ("ENEMY_FIRST" if t_p > 0.4 + 0.01 else "NORMAL")
			print("DUEL_JSON: ", JSON.stringify({"side": "+x" if side > 0.0 else "-x", "player_attack_s": t_p,
				"enemy_attack_s": 0.4, "advantage": adv_name, "expected_by_start": expect, "impact_frame": f}))
			# Os dois começam no mesmo quadro físico (t_p ~ 0,4 s): qualquer resultado vale.
			if adv_name != expect and absf(t_p - 0.4) > 0.02:
				bad += 1
	return bad
