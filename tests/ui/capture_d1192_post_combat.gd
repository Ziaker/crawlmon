extends SceneTree
## D-1192: capturas 1280×720 do pós-combate novo, nas mesmas telas do protótipo D-1185
## (cenários A–E). Rodar com janela fora da tela:
##   Godot_v4.7.2-stable_win64.exe --path . --position -4000,0 --script tests/ui/capture_d1192_post_combat.gd
## Os Moves aprendidos usam PostCombatFlow.learnset_override (o learnset real está vazio).

const OUT := "test_captures/d1192/"

var screen: PostCombatScreen


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280, 720)
	await process_frame
	await _scen_a()
	await _scen_b()
	await _scen_c()
	await _scen_d()
	await _scen_d_skip()
	await _scen_e()
	print("[D1192_CAPTURES_DONE]")
	quit(0)


func _make(species: String, lv_up: bool, alive := true) -> Combatant:
	var c := CharacterFactory.create(species, {"forced_nature": "hardy"})
	c.is_player = true
	c.level = 2
	c.xp = CrawlmonAttributeMath.get_xp_for_level_transition(2) - 20 if lv_up else 20
	c.update_resource_maximums()
	if not alive:
		c.hp = 0
	return c


func _open(party: Array, learn: Dictionary) -> void:
	if root.has_node("GameState"):
		var arr: Array[Combatant] = []
		for c in party:
			arr.append(c)
		root.get_node("GameState").set("party", arr)
	PostCombatFlow.learnset_override = learn
	var sums := PostCombatFlow.grant_xp(party, 60)
	screen = PostCombatScreen.new()
	root.add_child(screen)
	screen.open(60, sums, PostCombatFlow.build_steps(sums))


func _close() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame


func _wait(t: float) -> void:
	await create_timer(t).timeout


func _key(k: String) -> void:
	screen._on_key(k)
	await process_frame


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	print("[CAPTURE] ", OUT + name + ".png")


func _lv_confirm_leader() -> void:
	await _key("right")
	for i in 6:
		await _key("down")


func _scen_a() -> void:
	_open([_make("abra", false), _make("pancham", false)], {})
	await _wait(3.2)
	await _shot("A_1_xp")
	await _close()


func _scen_b() -> void:
	_open([_make("abra", true), _make("pancham", false)], {})
	await _wait(3.2)
	await _shot("B_1_xp")
	await _key("z")
	await _wait(2.6)
	await _shot("B_2_lv_lider")
	await _key("right")
	await _wait(0.6)
	await _shot("B_2b_lv_lider_pontos_ok")
	await _close()


func _scen_c() -> void:
	var a := _make("abra", true)
	_open([a, _make("pancham", false)], {"abra": {3: [&"heal"]}})
	await _wait(3.2)
	await _shot("C_1_xp")
	await _key("z")
	await _wait(2.6)
	await _shot("C_2_lv_lider")
	await _lv_confirm_leader()
	await _wait(0.3)
	await _key("z")
	await _wait(1.75)
	await _shot("C_3_move_meio_chegada")
	await _wait(2.5)
	await _shot("C_3_move_novo")
	await _key("z")
	await _wait(2.0)
	await _shot("C_4_inspecao_move_novo")
	# pop-up do primeiro ícone do cabeçalho da inspeção
	for h in screen._hot:
		if screen._insp != null and screen._insp.is_ancestor_of(h["b"]):
			screen._show_tip(h)
			break
	await _wait(0.6)
	await _shot("C_5_popup_icone")
	await _close()


func _party_d() -> Array:
	var a := _make("abra", true)
	a.skills.append(Skill.from_id(&"heal"))
	return [a, _make("pancham", true)]


func _scen_d() -> void:
	_open(_party_d(), {"abra": {3: [&"electric_beam"]}, "pancham": {3: [&"war_cry"]}})
	await _wait(3.2)
	await _shot("D_1_xp")
	await _key("z")
	await _wait(2.6)
	await _shot("D_2_lv_lider")
	await _lv_confirm_leader()
	await _key("z")
	await _wait(2.6)
	await _shot("D_3_lv_aliado")
	await _key("z")
	await _wait(3.0)
	await _shot("D_4_move_cheio_lider")
	await _key("z")
	await _wait(2.0)
	await _shot("D_5_inspecao_esquecer")
	await _key("z")
	await _wait(0.45)
	await _shot("D_6_esqueceu_meio_chegada")
	await _wait(2.0)
	await _shot("D_6_esqueceu")
	await _key("z")
	await _wait(3.0)
	await _shot("D_7_move_aliado_vaga_livre")
	await _close()


func _scen_d_skip() -> void:
	_open(_party_d(), {"abra": {3: [&"electric_beam"]}, "pancham": {3: [&"war_cry"]}})
	await _wait(3.2)
	await _key("z")
	await _wait(2.6)
	await _lv_confirm_leader()
	await _key("z")
	await _wait(2.6)
	await _key("z")
	await _wait(3.0)
	screen._set_focus("skip")
	screen._activate("skip")
	await _wait(0.5)
	await _shot("D_8_confirmar_nao_aprender")
	await _key("z")
	await _wait(1.0)
	await _shot("D_9_nao_aprendeu")
	await _close()


func _scen_e() -> void:
	_open([_make("abra", true), _make("pancham", false, false)], {})
	await _wait(3.2)
	await _shot("E_1_xp_aliado_ko")
	await _close()
