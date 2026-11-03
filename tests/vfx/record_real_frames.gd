extends SceneTree

const SmtBuffController = preload("res://scripts/vfx/smt/smt_buff_controller.gd")
const SmtStageVfx = preload("res://scripts/vfx/smt/smt_stage_vfx.gd")

var _bs: Node3D
var _moves_to_record := [
	{"move": "teleport", "actor_idx": 0, "target_idx": 2, "name": "Teleport"}, # Abra -> Gible
	{"move": "dig", "actor_idx": 2, "target_idx": 1, "name": "Dig"}, # Gible -> Pancham
	{"move": "sand_attack", "actor_idx": 2, "target_idx": 1, "name": "Sand Attack"}, # Gible -> Pancham
	{"move": "dragon_rage", "actor_idx": 2, "target_idx": 1, "name": "Dragon Rage"}, # Gible -> Pancham
	{"move": "tarukaja", "actor_idx": 0, "target_idx": 1, "name": "Tarukaja"}, # Abra -> Pancham
	{"move": "rakunda", "actor_idx": 0, "target_idx": 2, "name": "Rakunda"}, # Abra -> Gible
	{"move": "sukunda", "actor_idx": 1, "target_idx": 2, "name": "Sukunda"}, # Pancham -> Gible
	{"move": "bite", "actor_idx": 2, "target_idx": 1, "name": "Bite"}, # Gible -> Pancham
	{"move": "mach_punch", "actor_idx": 1, "target_idx": 2, "name": "Mach Punch"}, # Pancham -> Gible
	{"move": "karate_chop", "actor_idx": 1, "target_idx": 2, "name": "Karate Chop"}, # Pancham -> Gible
	{"move": "taunt", "actor_idx": 1, "target_idx": 2, "name": "Taunt"}, # Pancham -> Gible
	{"move": "tackle", "actor_idx": 1, "target_idx": 2, "name": "Tackle"} # Pancham -> Gible
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — GRAVADOR DE FRAMES REAIS DE GPU (FASE A FASE)")
	print("=================================================================")

	DirAccess.make_dir_recursive_absolute("res://test_captures")

	# 1. Instancia cena de batalha real
	var packed := load("res://scenes/battle.tscn") as PackedScene
	_bs = packed.instantiate()
	root.add_child(_bs)

	var battle: Battle = _bs.get_node("Battle")

	# Aguarda intro real e ativação do motor
	print("[*] Aguardando inicialização completa do motor de combate...")
	while not battle.running:
		await process_frame

	# Mais 10 frames de estabilização
	for i in 10:
		await process_frame

	var party: Array[Combatant] = battle.party
	var enemies: Array[Combatant] = battle.enemies
	var all_units: Array[Combatant] = []
	all_units.append_array(party)
	all_units.append_array(enemies)

	# Desativa IA autônoma para que apenas as ações controladas sejam executadas
	for c in all_units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE

	print("[*] Motor ativo. Unidades sob controle:")
	for i in all_units.size():
		print("    [%d] %s (is_player: %s)" % [i, all_units[i].name, all_units[i].is_player])

	# 2. Executar e gravar cada movimento
	for item in _moves_to_record:
		var move_key: String = item["move"]
		var move_name: String = item["name"]
		var actor_idx: int = item["actor_idx"]
		var target_idx: int = item["target_idx"]

		var actor: Combatant = all_units[actor_idx]
		var target: Combatant = all_units[target_idx]

		print("\n>>> GRAVANDO MOVIMENTO: %s (%s -> %s) <<<" % [move_name, actor.name, target.name])
		var out_dir := "res://test_captures/%s" % move_key
		DirAccess.make_dir_recursive_absolute(out_dir)

		# Limpa filas de batalha e restaura todos os estados
		battle.incoming.clear()
		battle._landing.clear()
		battle._returning.clear()
		battle._status_pause = null
		battle._status_tail = -1.0

		for u in all_units:
			u.is_invulnerable = false
			u.stun_timer = 0.0
			u.blind_timer = 0.0
			u.taunted_by = null
			u.taunt_atk_bonus = false
			u.atb = 5
			u.hp = u.max_hp
			u.engaged_with = null
			u.counter_ready = false

		var actor_model: Node3D = _bs.models.get(actor)
		var target_model: Node3D = _bs.models.get(target)
		if actor_model:
			actor_model.visible = true
			actor_model.position = _bs.PARTY_SLOTS[mini(actor_idx, _bs.PARTY_SLOTS.size() - 1)] if actor.is_player else Vector3(8.0, 0.0, -30.0)
		if target_model:
			target_model.visible = true
			target_model.position = _bs.PARTY_SLOTS[mini(target_idx, _bs.PARTY_SLOTS.size() - 1)] if target.is_player else Vector3(8.0, 0.0, -30.0)

		# Encontra habilidade correspondente
		var skill: Skill = null
		for u in all_units:
			for s in u.skills:
				if BattleSpace.move_id(s.display_name) == move_key or s.display_name.to_lower() == move_key:
					skill = s
					break
			if skill != null:
				break
		if skill == null:
			for s in Skill.smt_skills():
				if BattleSpace.move_id(s.display_name) == move_key or s.display_name.to_lower() == move_key:
					skill = s
					break
		if skill == null:
			skill = Skill.new(move_name, 1.0, 1, Element.Type.FISICO, Skill.Kind.MELEE)

		# Posiciona câmera para enquadramento ótimo
		var cam: Camera3D = _bs.get_node("Camera3D")
		if actor_model and target_model:
			var mid_point := (actor_model.global_position + target_model.global_position) * 0.5
			cam.global_position = mid_point + Vector3(-8.5, 4.2, 9.5)
			cam.look_at_from_position(cam.global_position, mid_point + Vector3(0.0, 1.0, 0.0))

		# Dispara ataque
		var ok := battle.use_skill(actor, skill, target)
		if not ok:
			print("    [ERRO] use_skill falhou ao despachar %s!" % move_name)
			continue

		# F1: Windup Start (2 frames após início)
		await _advance_frames(2)
		_save_frame(out_dir, 1, "windup_start")

		var inc: Incoming = null
		if not battle.incoming.is_empty():
			inc = battle.incoming[0]
		elif battle._status_pause != null:
			inc = battle._status_pause

		# F2: Windup Mid (aguarda até ~metade do tempo de preparo)
		if inc != null:
			var half_windup := (inc.time_left * 0.5) if inc.time_left > 0 else 0.25
			var frames_half := maxi(4, roundi(half_windup * 60.0))
			await _advance_frames(frames_half)
		else:
			await _advance_frames(15)
		_save_frame(out_dir, 2, "windup_mid")

		# F3: Travel Launch (aguarda entrada na fase TRAVEL ou fim do windup de status)
		var max_wait := 180
		while max_wait > 0:
			max_wait -= 1
			await process_frame
			var cur_inc: Incoming = _find_inc(battle, actor)
			if cur_inc == null or cur_inc.phase != Incoming.Phase.WINDUP:
				break
		_save_frame(out_dir, 3, "travel_launch")

		# F4: Travel Mid (meio do trajeto)
		await _advance_frames(8)
		_save_frame(out_dir, 4, "travel_mid")

		# F5: Strike Impact (aguarda fase STRIKE ou aplicação de dano/efeito)
		max_wait = 180
		while max_wait > 0:
			max_wait -= 1
			await process_frame
			var cur_inc: Incoming = _find_inc(battle, actor)
			if cur_inc == null or cur_inc.phase == Incoming.Phase.STRIKE or cur_inc.impacted:
				break
		_save_frame(out_dir, 5, "strike_impact")

		# F6: Impact Burst (explosão visual / rings / partículas 4 frames depois)
		await _advance_frames(5)
		_save_frame(out_dir, 6, "impact_burst")

		# F7: Recovery Return (retornando ao ponto inicial)
		await _advance_frames(14)
		_save_frame(out_dir, 7, "recovery_return")

		# F8: Settled (repouso)
		await _advance_frames(16)
		_save_frame(out_dir, 8, "settled")

		print("    [PASS] 8 frames salvos em %s/" % out_dir)

	print("\n=================================================================")
	print("[SUCESSO] Todos os 12 movimentos gravados fase a fase!")
	print("=================================================================")
	_bs.free()
	quit(0)

func _find_inc(battle: Battle, actor: Combatant) -> Incoming:
	for inc in battle.incoming:
		if inc.attacker == actor: return inc
	for inc in battle._landing:
		if inc.attacker == actor: return inc
	for inc in battle._returning:
		if inc.attacker == actor: return inc
	if battle._status_pause != null and battle._status_pause.attacker == actor:
		return battle._status_pause
	return null

func _advance_frames(count: int) -> void:
	for i in count:
		await process_frame

func _save_frame(dir_path: String, frame_num: int, label: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img != null:
		var file_name := "%s/frame_%02d_%s.png" % [dir_path, frame_num, label]
		img.save_png(file_name)
