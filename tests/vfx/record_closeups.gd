extends SceneTree

const SmtBuffController = preload("res://scripts/vfx/smt/smt_buff_controller.gd")
const SmtStageVfx = preload("res://scripts/vfx/smt/smt_stage_vfx.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- GRAVANDO CLOSE-UPS VISUAIS (TELEPORT ATRÁS DO ALVO E DIG ERUPÇÃO) ---")
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)

	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame

	for i in 10:
		await process_frame

	var party: Array[Combatant] = battle.party
	var enemies: Array[Combatant] = battle.enemies
	var all_units: Array[Combatant] = []
	all_units.append_array(party)
	all_units.append_array(enemies)

	for c in all_units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE

	# Desativa controle automático da câmera para permitir enquadramento livre nos close-ups
	if bs.director != null:
		bs.director.set_process(false)

	var abra: Combatant = all_units[0]
	var pancham: Combatant = all_units[1]
	var gible: Combatant = all_units[2]

	var cam: Camera3D = bs.get_node("Camera3D")
	cam.current = true
	var gible_model: Node3D = bs.models[gible]
	var abra_model: Node3D = bs.models[abra]
	var pancham_model: Node3D = bs.models[pancham]

	DirAccess.make_dir_recursive_absolute("res://test_captures/closeups")

	# =========================================================================
	# 1. TELEPORT CLOSE-UP: Câmera posicionada atrás do Gible olhando para trás
	# =========================================================================
	print("[*] Gravando Teleport Close-Up...")
	_reset_state(battle, all_units, bs)

	cam.global_position = gible_model.global_position + Vector3(0.0, 2.0, -4.5)
	cam.look_at_from_position(cam.global_position, gible_model.global_position + Vector3(0, 1.0, 0))

	var teleport_skill := _find_skill(all_units, "teleport")
	battle.use_skill(abra, teleport_skill, gible)

	# F1: Windup (Abra sumindo na origem)
	await _wait_frames(8)
	_save("test_captures/closeups/teleport_01_windup.png")

	# F2: Travel (vazio)
	await _wait_frames(14)
	_save("test_captures/closeups/teleport_02_vanished.png")

	# F3: Strike (Abra materializa atrás de Gible!)
	await _wait_frames(12)
	_save("test_captures/closeups/teleport_03_behind_strike.png")

	# F4: Impact Burst
	await _wait_frames(8)
	_save("test_captures/closeups/teleport_04_impact.png")

	# =========================================================================
	# 2. DIG CLOSE-UP: Câmera focada em Pancham para ver Gible emergindo do chão!
	# =========================================================================
	print("[*] Gravando Dig Close-Up...")
	_reset_state(battle, all_units, bs)

	cam.global_position = pancham_model.global_position + Vector3(3.0, 1.8, 3.5)
	cam.look_at_from_position(cam.global_position, pancham_model.global_position + Vector3(0, 0.8, 0))

	var dig_skill := _find_skill(all_units, "dig")
	battle.use_skill(gible, dig_skill, pancham)

	# F1: Submergindo no chão
	await _wait_frames(25)
	_save("test_captures/closeups/dig_01_submerged.png")

	# F2: Emergindo e golpeando Pancham
	await _wait_frames(40)
	_save("test_captures/closeups/dig_02_emerge_strike.png")

	print("=== CLOSE-UPS GRAVADOS COM SUCESSO! ===")
	bs.free()
	quit(0)

func _reset_state(battle: Battle, all_units: Array[Combatant], bs: Node3D) -> void:
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
		var m: Node3D = bs.models.get(u)
		if m:
			m.visible = true
			if u.name == "Abra": m.position = Vector3(0.6, 0, 1.5)
			elif u.name == "Pancham": m.position = Vector3(7.5, 0, -3.0)
			elif u.name == "Gible": m.position = Vector3(8.0, 0, -30.0)

func _find_skill(all_units: Array[Combatant], move_key: String) -> Skill:
	for u in all_units:
		for s in u.skills:
			if BattleSpace.move_id(s.display_name) == move_key or s.display_name.to_lower() == move_key:
				return s
	for s in Skill.smt_skills():
		if BattleSpace.move_id(s.display_name) == move_key or s.display_name.to_lower() == move_key:
			return s
	return Skill.new(move_key, 1.0, 1, Element.Type.FISICO, Skill.Kind.MELEE)

func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame

func _save(path: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img != null:
		img.save_png(path)
