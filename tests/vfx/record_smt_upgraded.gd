extends SceneTree

const SmtBuffController = preload("res://scripts/vfx/smt/smt_buff_controller.gd")
const SmtStageVfx = preload("res://scripts/vfx/smt/smt_stage_vfx.gd")

var _bs: Node3D
var _moves_to_record := [
	{"move": "tarukaja", "actor_idx": 0, "target_idx": 1, "name": "Tarukaja"}, # Abra -> Pancham
	{"move": "rakunda", "actor_idx": 0, "target_idx": 2, "name": "Rakunda"},   # Abra -> Gible
	{"move": "sukunda", "actor_idx": 1, "target_idx": 2, "name": "Sukunda"}    # Pancham -> Gible
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=================================================================")
	print("   CRAWLMON — GRAVADOR DE FRAMES SMT VOLUMÉTRICOS (D-036)")
	print("=================================================================")

	DirAccess.make_dir_recursive_absolute("res://test_captures/smt_upgraded")

	var packed := load("res://scenes/battle.tscn") as PackedScene
	_bs = packed.instantiate()
	root.add_child(_bs)

	# Desativa o director de câmera padrão para permitir enquadramento cinemático fixo no alvo
	if _bs.director:
		_bs.director.set_process(false)

	var battle: Battle = _bs.get_node("Battle")

	print("[*] Aguardando estabilização da batalha...")
	while not battle.running:
		await process_frame

	for i in 12:
		await process_frame

	var party: Array[Combatant] = battle.party
	var enemies: Array[Combatant] = battle.enemies
	var all_units: Array[Combatant] = []
	all_units.append_array(party)
	all_units.append_array(enemies)

	for c in all_units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE

	var cam: Camera3D = _bs.get_node("Camera3D")

	for item in _moves_to_record:
		var move_key: String = item["move"]
		var move_name: String = item["name"]
		var actor_idx: int = item["actor_idx"]
		var target_idx: int = item["target_idx"]

		var actor: Combatant = all_units[actor_idx]
		var target: Combatant = all_units[target_idx]

		print("\n>>> GRAVANDO VFX VOLUMÉTRICO: %s (%s -> %s) <<<" % [move_name, actor.name, target.name])
		var out_dir := "res://test_captures/smt_upgraded/%s" % move_key
		DirAccess.make_dir_recursive_absolute(out_dir)

		# Limpar filas de batalha
		battle.incoming.clear()
		battle._landing.clear()
		battle._returning.clear()
		battle._status_pause = null
		battle._status_tail = -1.0

		for u in all_units:
			u.is_invulnerable = false
			u.hp = u.max_hp
			u.atb = 5

		var target_model: Node3D = _bs.models.get(target)
		var t_pos: Vector3 = target_model.global_position if target_model else Vector3.ZERO

		# Enquadra a câmera em ângulo de perspectiva ótimo para ver tanto o chão (selo) quanto o modelo
		cam.global_position = t_pos + Vector3(-2.6, 2.9, 5.8)
		cam.look_at_from_position(cam.global_position, t_pos + Vector3(0.0, 1.0, 0.0))

		# Localizar a skill
		var skill: Skill = null
		for s in Skill.smt_skills():
			if BattleSpace.move_id(s.display_name) == move_key or s.display_name.to_lower() == move_key:
				skill = s
				break

		if skill == null:
			print("    [ERRO] Skill %s não encontrada!" % move_name)
			continue

		# Aguarda o sinal hit_resolved (momento exato em que o VFX de status é disparado)
		print("    Aguardando início do efeito visual via hit_resolved...")
		var hit_fired := false
		var on_hit := func(_a, _t, _e, _i):
			hit_fired = true
		battle.hit_resolved.connect(on_hit, CONNECT_ONE_SHOT)

		var ok := battle.use_skill(actor, skill, target)
		if not ok:
			print("    [ERRO] use_skill falhou para %s!" % move_name)
			continue

		var wait_timeout := 240
		while not hit_fired and wait_timeout > 0:
			wait_timeout -= 1
			await process_frame

		print("    Efeito visual ativo! Capturando 8 estágios de vida...")

		# Capturar 8 estágios ao longo do 1.00s de duração do VFX (a cada 7 frames)
		for f in range(1, 9):
			await _advance_frames(7)
			var phase_label: String = "step_%02d" % f
			_save_frame(out_dir, f, phase_label)

		print("    [PASS] 8 frames salvos em %s/" % out_dir)

		# Pequena pausa antes do próximo move
		await _advance_frames(20)

	print("\n=================================================================")
	print("[SUCESSO] Gravação SMT D-036 concluída!")
	print("=================================================================")
	_bs.free()
	quit(0)

func _advance_frames(count: int) -> void:
	for i in count:
		await process_frame

func _save_frame(dir_path: String, frame_num: int, label: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img != null:
		var file_name := "%s/frame_%02d_%s.png" % [dir_path, frame_num, label]
		img.save_png(file_name)
