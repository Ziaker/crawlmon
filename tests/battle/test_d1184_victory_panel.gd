extends SceneTree
## D-1184: VictoryPanel opens on every victory; the old LevelUpModal follows
## only when the leader has points to distribute; then the battle returns.
##
##   Godot_v4.7.2-stable_win64_console.exe --path . --position -4000,0 \
##       --script res://tests/battle/test_d1184_victory_panel.gd -- --shots=<dir>
##
## Without --shots it runs headless-safe and only checks the flow.

const BATTLE := "res://scenes/battle.tscn"

var _fail := 0
var _shots := ""


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			_shots = a.substr(8)
	call_deferred("_run")


func _run() -> void:
	print("== D-1184 victory panel ==")
	await _case("sem_level_up", false)
	await _case("com_level_up", true)
	print("D1184_VICTORY_PANEL: ", "OK" if _fail == 0 else "%d FALHAS" % _fail)
	quit(0 if _fail == 0 else 1)


func _case(tag: String, level_up: bool) -> void:
	print("- caso ", tag)
	var gs = root.get_node_or_null("GameState")
	gs.set("return_scene", "")
	change_scene_to_file(BATTLE)
	var bs = await _wait_battle_running(900)
	if bs == null:
		_check(false, "battle running (%s)" % tag)
		return
	var leader = bs.leader
	var start_level: int = leader.level
	leader.distributable_points = 0
	if level_up:
		leader.xp = CrawlmonAttributeMath.get_xp_for_level_transition(leader.level) - 1
	else:
		# Guarantee no level up for anyone: the battle XP must not complete a level.
		var total := 0
		for e in bs.battle.enemies:
			total += CrawlmonAttributeMath.get_enemy_xp_drop(e.base_experience, e.level)
		for m in bs.battle.party:
			m.xp = 0
			while CrawlmonAttributeMath.get_xp_for_level_transition(m.level) <= total:
				m.level += 1
		start_level = leader.level
	for e in bs.battle.enemies:
		e.hp = 0
	bs.battle._check_end()

	var panel = await _wait_node(bs.ui, "VictoryPanel", 600)
	_check(panel != null, "VictoryPanel abriu (%s)" % tag)
	if panel == null:
		return
	_check(bs.ui.find_children("*", "LevelUpHUD", true, false).is_empty(), "Level Up HUD nao abriu (%s)" % tag)
	await _frames(150)
	await _shot("%s_1_painel" % tag)
	await _frames(450)
	await _shot("%s_1b_painel_final" % tag)
	if not level_up:
		_check(leader.level == start_level, "ninguem subiu de nivel no caso sem level up")
	_press(KEY_Z)
	await _frames(10)

	# Without points the battle may already have left the scene (bs freed).
	var modal = _find(bs.ui, "LevelUpModal") if is_instance_valid(bs) else null
	if level_up:
		_check(leader.level > start_level, "lider subiu de nivel")
		_check(modal != null, "LevelUpModal abriu com pontos do lider")
		if modal != null:
			await _frames(40)
			await _shot("%s_2_modal" % tag)
			var pts: int = leader.distributable_points
			for i in pts:
				_press(KEY_RIGHT)  # MAG? no: first row is STR; any row is fine for the flow
				await _frames(2)
			modal.set("_selected_row", 6)
			_press(KEY_Z)
			await _frames(10)
			_check(leader.distributable_points == 0, "pontos alocados antes de sair")
	else:
		_check(modal == null, "sem pontos, nenhum modal")

	var left := false
	for i in 600:
		if current_scene == null or current_scene.scene_file_path != BATTLE:
			left = true
			break
		await process_frame
	_check(left, "batalha terminou e saiu da cena (%s)" % tag)
	_check(not paused, "arvore despausada (%s)" % tag)
	await _frames(5)


func _wait_battle_running(max_frames: int):
	for i in max_frames:
		var s = current_scene
		if s != null and s.scene_file_path == BATTLE and s.get("battle") != null and s.battle.running:
			return s
		await process_frame
	return null


func _wait_node(parent: Node, cls: String, max_frames: int):
	for i in max_frames:
		var n = _find(parent, cls)
		if n != null:
			return n
		await process_frame
	return null


func _find(parent: Node, cls: String):
	for c in parent.get_children():
		if c.get_script() != null and c.get_script().get_global_name() == cls:
			return c
	return null


func _press(key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = key
		ev.physical_keycode = key
		ev.pressed = pressed
		Input.parse_input_event(ev)
	await process_frame


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	if _shots == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_shots.path_join(name + ".png"))
	print("  shot ", name)


func _check(ok: bool, msg: String) -> void:
	print("  [", "PASS" if ok else "FAIL", "] ", msg)
	if not ok:
		_fail += 1
