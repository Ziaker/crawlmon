extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=================================================================")
	print("   GRAVANDO PROVAS VISUAIS D-041: RUN DUST & TACKLE HIT")
	print("=================================================================")
	DirAccess.make_dir_recursive_absolute("res://test_captures/d041_tackle")

	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)

	var battle: Battle = bs.get_node("Battle")
	var party: Array[Combatant] = battle.party
	var enemies: Array[Combatant] = battle.enemies
	var all_units: Array[Combatant] = []
	all_units.append_array(party)
	all_units.append_array(enemies)

	for c in all_units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.atb = 0.0

	while not battle.running:
		await process_frame

	for c in all_units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.atb = 0.0
	battle.incoming.clear()

	for i in 5:
		await process_frame

	var pancham: Combatant = all_units[1]
	var gible: Combatant = all_units[2]
	var gible_model: Node3D = bs.models[gible]
	var pancham_model: Node3D = bs.models[pancham]

	var tackle_skill := Skill.new("Tackle", 1.0, 1, Element.Type.FISICO, Skill.Kind.MELEE)
	pancham.atb = 5.0
	gible.hp = 100
	gible.max_hp = 100

	# 1. Câmera geral para a corrida e poeira no trajeto
	if bs.director != null:
		bs.director.set_process(false)
	var cam: Camera3D = bs.get_node("Camera3D")
	cam.current = true

	# Vista lateral ampla para ver a esteira de poeira desde a largada
	cam.global_position = Vector3(3.2, 2.0, 4.2)
	cam.look_at_from_position(cam.global_position, Vector3(0.5, 0.6, 0.0))

	print("[*] Pancham executando Tackle em Gible...")
	battle.use_skill(pancham, tackle_skill, gible)

	# F1: Windup
	await _wait_frames(8)

	# Aguarda entrada na fase TRAVEL
	var max_wait := 120
	while max_wait > 0:
		max_wait -= 1
		await process_frame
		var cur_inc: Incoming = _find_inc(battle, pancham)
		if cur_inc != null and cur_inc.phase == Incoming.Phase.TRAVEL:
			break
	print("[*] Gravando Takeoff Dust...")
	await _wait_frames(2)
	_capture("frame_01_takeoff_dust.png")

	# Meio da corrida (Ground Wake)
	await _wait_frames(6)
	print("[*] Gravando Run Dust Wake...")
	_capture("frame_02_run_sprint_wake.png")

	# Frenagem (Arrival Skid)
	await _wait_frames(6)
	print("[*] Gravando Arrival Skid...")
	_capture("frame_03_arrival_skid.png")

	# Reposiciona câmera para Close-Up dinâmico no ponto de impacto em Gible
	cam.global_position = gible_model.global_position + Vector3(1.6, 1.2, 2.2)
	cam.look_at_from_position(cam.global_position, gible_model.global_position + Vector3(-0.2, 0.65, 0.0))

	# Aguarda o momento exato do impacto (impacted == true)
	max_wait = 180
	while max_wait > 0:
		max_wait -= 1
		await process_frame
		var cur_inc: Incoming = _find_inc(battle, pancham)
		if cur_inc != null and cur_inc.impacted:
			break
	print("[*] IMPACTO LANDED! Gravando Tackle Strike & Shock Cone...")
	await _wait_frames(1)
	_capture("frame_04_tackle_impact_contact.png")

	# 2 frames depois: pico do Hit-Stop, Flipbook e deformação Squash & Stretch
	await _wait_frames(2)
	print("[*] Gravando Hit-Stop Peak, Flipbook & Squash...")
	_capture("frame_05_tackle_hitstop_burst.png")

	# 12 frames depois: expansão da poeira radial e faíscas
	await _wait_frames(6)
	_capture("frame_06_tackle_radial_dust.png")

	print("=================================================================")
	print("[SUCESSO] Gravação D-041 finalizada com sucesso!")
	print("=================================================================")
	bs.free()
	quit(0)

func _find_inc(battle: Battle, actor: Combatant) -> Incoming:
	for inc in battle.incoming:
		if inc.attacker == actor: return inc
	for inc in battle._landing:
		if inc.attacker == actor: return inc
	for inc in battle._returning:
		if inc.attacker == actor: return inc
	return null

func _wait_frames(n: int) -> void:
	for i in n:
		await process_frame

func _capture(filename: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img != null:
		img.save_png("res://test_captures/d041_tackle/%s" % filename)
		print("  -> Capturado: %s" % filename)
