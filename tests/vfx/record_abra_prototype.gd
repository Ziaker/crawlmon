extends SceneTree
## D-170: grava quadros dos VFX do Abra (Confusion, Psybeam, Shock Wave) na batalha real.
## Rodar SEM --headless:  Godot --path . -s tests/vfx/record_abra_prototype.gd
## Saída: test_captures/abra_v9/<move>_<fase>_<n>.png

const OUT := "res://test_captures/abra_v9"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	root.add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await process_frame
	for i in 10:
		await process_frame
	var all_units: Array[Combatant] = []
	all_units.append_array(battle.party)
	all_units.append_array(battle.enemies)
	for c in all_units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	if bs.director != null:
		bs.director.set_process(false)
	var abra: Combatant = all_units[0]
	var gible: Combatant = all_units[2]
	var cam: Camera3D = bs.get_node("Camera3D")
	cam.current = true
	DirAccess.make_dir_recursive_absolute(OUT)
	var abra_model: Node3D = bs.models[abra]
	var gible_model: Node3D = bs.models[gible]

	for move in ["Confusion"]:
		var id := BattleSpace.move_id(move)
		_reset(battle, all_units, bs)
		var skill: Skill
		for s in abra.skills:
			if s.display_name == move:
				skill = s
		print("[*] ", move)
		battle.use_skill(abra, skill, gible)
		# Wind-up: camera next to Abra, looking down the lane.
		cam.fov = 50
		cam.global_position = abra_model.global_position + Vector3(-3.2, 2.6, 5.5)
		cam.look_at(abra_model.global_position + Vector3(3.0, 1.3, -6.0))
		var marks: Array = [0.55, 0.45, 0.35] if id != "teleporte_rapido" else [0.2, 0.15, 0.1]
		for n in 3:
			await create_timer(float(marks[n])).timeout
			_save("%s_windup_%d" % [id, n])
		cam.fov = 55
		cam.global_position = abra_model.global_position + Vector3(-6.0, 5.0, 8.0)
		cam.look_at(Vector3(4.0, 1.0, -14.0))
		var waited := 0.0
		while waited < 5.0 and not _has(bs, id, "Travel") and not _has(bs, id, "Impact"):
			await process_frame
			waited += 0.016
		Engine.time_scale = 0.12
		for n in 4:
			await process_frame
			await process_frame
			_save("%s_flight_%d" % [id, n])
		cam.fov = 45
		cam.global_position = gible_model.global_position + Vector3(-5.0, 3.0, 9.0)
		cam.look_at(gible_model.global_position + Vector3(0, 1.3, 0))
		for n in 30:
			await process_frame
			await process_frame
			await process_frame
			_save("%s_impact_%d" % [id, n])
		Engine.time_scale = 1.0
		await create_timer(1.2).timeout
	print("ABRA_V9_CAPTURES_DONE")
	quit(0)


func _reset(battle: Battle, all_units: Array[Combatant], bs: Node3D) -> void:
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
		u.atb = 5
		u.hp = u.max_hp
		u.engaged_with = null
		u.counter_ready = false
		var m: Node3D = bs.models.get(u)
		if m:
			m.visible = true
			if u.name == "Abra":
				m.position = Vector3(0.6, 0, 1.5)
			elif u.name == "Pancham":
				m.position = Vector3(7.5, 0, -3.0)
			elif u.name == "Gible":
				m.position = Vector3(8.0, 0, -30.0)


func _has(bs: Node, move_id: String, stage_word: String) -> bool:
	for n in bs.find_children("Abra*", "Node3D", true, false):
		if n is AbraMoveVfx and (n as AbraMoveVfx).move_id == move_id:
			if stage_word == "Travel" and (n as AbraMoveVfx).stage == AbraMoveVfx.Stage.TRAVEL:
				return true
			if stage_word == "Impact" and (n as AbraMoveVfx).stage == AbraMoveVfx.Stage.IMPACT:
				return true
	return false


func _save(file_name: String) -> void:
	var info := ""
	for n in root.find_children("Abra*", "Node3D", true, false):
		if n is AbraMoveVfx:
			info += " %s t=%.2f" % [n.name, (n as AbraMoveVfx).t]
	print(file_name, info, " ts=", Engine.time_scale)
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/%s.png" % [OUT, file_name])
