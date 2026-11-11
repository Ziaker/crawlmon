extends SceneTree
## Grava os 3 vídeos de demonstração do Bubble Shield no jogo real.
## Cada execução grava um cenário, com lado aliado e lado inimigo:
##   --scenario=bloqueio   dano absorvido (HP intacto)
##   --scenario=expiracao  bolha some sozinha no fim do prazo
##   --scenario=ruptura    reserva zerada, bolha estoura
## Rodar SEM --headless, com --write-movie:
##   Godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie <saida.avi>
##         --script res://tests/vfx/record_bubble_shield.gd -- --scenario=bloqueio

var scenario := "bloqueio"
var scenario_title := "BLOQUEIO DE DANO"
var bs: Node3D
var battle: Battle
var cam: Camera3D
var abra: Combatant
var pancham: Combatant
var gible: Combatant
var bubble_party: Skill
var bubble_enemy: Skill
var gible_projectile: Skill
var abra_projectile: Skill

var overlay: CanvasLayer
var fade: ColorRect
var intro_root: Control
var intro_title: Label
var intro_sub: Label
var title_band: ColorRect
var title_label: Label
var subtitle_label: Label


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenario="):
			scenario = a.substr(11)
	match scenario:
		"expiracao":
			scenario_title = "EXPIRAÇÃO NATURAL"
		"ruptura":
			scenario_title = "RUPTURA"
		_:
			scenario_title = "BLOQUEIO DE DANO"
	call_deferred("_run")


func _run() -> void:
	_build_overlay()
	var packed := load("res://scenes/battle.tscn") as PackedScene
	bs = packed.instantiate()
	root.add_child(bs)
	battle = bs.get_node("Battle")
	await process_frame
	await process_frame
	# Congela a IA antes de battle.start, para ninguém agir durante a intro.
	if bs.models != null:
		for c in bs.models.keys():
			c.act_policy = Combatant.Act.HOLD
			c.react_policy = Combatant.React.NONE
	battle.debug_roll = 1  # hit garantido, sem crítico
	Engine.time_scale = 1.0
	var guard := 0
	while not battle.running and guard < 1200:
		await process_frame
		guard += 1
	await _wait(0.55)
	_reset_all()
	bs.director.set_process(false)
	cam = bs.get_node("Camera3D")
	cam.current = true
	abra = battle.party[0]
	pancham = battle.party[1]
	gible = battle.enemies[0]
	bubble_party = _find_skill(abra, "Bubble Shield")
	bubble_enemy = Skill.new("Bubble Shield", 0.0, 3, Element.Type.AGUA_GELO, Skill.Kind.STATUS, false, true, true, 0.7)
	gible.skills.append(bubble_enemy)
	gible_projectile = _find_skill(gible, "Dragon Rage")
	abra_projectile = _find_skill(abra, "Psybeam")
	await process_frame
	await process_frame

	# Cartão de abertura sobre o preto; a batalha carrega atrás.
	intro_title.text = "BUBBLE SHIELD"
	intro_sub.text = scenario_title + "\nLADO ALIADO  ·  LADO INIMIGO"
	intro_root.visible = true
	await _wait(1.1)
	_set_title(scenario_title, "LADO ALIADO  ·  ALL ALLIES  ·  25 + MAG por aliado")
	await _fade_to(0.0, 0.55)
	intro_root.visible = false
	await _wait(0.35)

	await _party_segment()
	await _to_enemy_side()
	await _enemy_segment()

	await _fade_to(1.0, 0.55)
	intro_title.text = "BUBBLE SHIELD"
	intro_sub.text = scenario_title + "\nFIM"
	intro_root.visible = true
	await _wait(0.9)

	bs.queue_free()
	await process_frame
	quit(0)


# --- Cenários ---------------------------------------------------------------

func _party_segment() -> void:
	_set_camera_party()
	_reset_all()
	await _wait(0.35)
	await _cast_bubble(abra)
	if scenario == "expiracao":
		await _expire_shields([abra, pancham])
	elif scenario == "ruptura":
		await _break_attack(gible, abra, gible_projectile)
	else:
		await _block_attack(gible, abra, gible_projectile)
	await _wait(0.35)


func _enemy_segment() -> void:
	_reset_all()
	await _cast_bubble(gible)
	if scenario == "expiracao":
		await _expire_shields([gible])
	elif scenario == "ruptura":
		await _break_attack(abra, gible, abra_projectile)
	else:
		await _block_attack(abra, gible, abra_projectile)
	await _wait(0.35)


func _cast_bubble(actor: Combatant) -> void:
	var skill := bubble_enemy if actor == gible else bubble_party
	await _wait_until(func() -> bool:
		return battle._status_pause == null and not battle.is_winding_up(actor), 8.0)
	actor.atb = 5.0
	var ok := battle.use_skill(actor, skill, actor)
	if not ok:
		print("CAST_FAIL ", actor.name)
	await _wait_until(func() -> bool: return actor.is_shielded(), 5.0)
	await _wait(1.05)  # formação + cauda da pausa de status


func _block_attack(attacker: Combatant, target: Combatant, skill: Skill) -> void:
	await _wait_until(func() -> bool:
		return battle._status_pause == null and not battle.is_winding_up(attacker), 8.0)
	attacker.atb = 5.0
	target.hp = target.max_hp
	var before_shield := target.shield_hp
	var before_hp := target.hp
	var ok := battle.use_skill(attacker, skill, target)
	if not ok:
		print("ATTACK_FAIL ", attacker.name)
	await _wait_until(func() -> bool:
		return target.shield_hp < before_shield or not target.is_shielded(), 9.0)
	await _wait(0.65)
	print("BLOCK hp=", target.hp, "/", before_hp, " shield=", target.shield_hp, "/", before_shield)


func _expire_shields(targets: Array) -> void:
	for c in targets:
		if c.is_shielded():
			c.shield_timer = 1.7
	await _wait_until(func() -> bool: return not targets[0].is_shielded(), 6.0)
	await _wait(1.35)


func _break_attack(attacker: Combatant, target: Combatant, skill: Skill) -> void:
	await _wait_until(func() -> bool:
		return battle._status_pause == null and not battle.is_winding_up(attacker), 8.0)
	attacker.atb = 5.0
	target.hp = target.max_hp
	target.shield_hp = 6  # reserva baixa para a demonstração da ruptura
	await _wait(0.35)
	var ok := battle.use_skill(attacker, skill, target)
	if not ok:
		print("BREAK_ATTACK_FAIL ", attacker.name)
	await _wait_until(func() -> bool: return not target.is_shielded(), 9.0)
	await _wait(0.8)
	print("BREAK hp=", target.hp, " shielded=", target.is_shielded())


func _to_enemy_side() -> void:
	await _fade_to(1.0, 0.45)
	await _wait_until(func() -> bool:
		return battle.incoming.is_empty() and battle.attacks_in_flight().is_empty(), 9.0)
	_reset_all()
	_set_camera_enemy()
	_set_title(scenario_title, "LADO INIMIGO  ·  Gible recebe o mesmo Move")
	await _wait(0.3)
	await _fade_to(0.0, 0.5)
	await _wait(0.3)


# --- Câmera / overlay --------------------------------------------------------

func _set_camera_party() -> void:
	cam.global_position = Vector3(4.2, 3.0, 8.5)
	cam.look_at(Vector3(2.4, 1.35, -1.2))
	cam.rotate_object_local(Vector3.BACK, deg_to_rad(4.0))
	cam.fov = 68.0


func _set_camera_enemy() -> void:
	cam.global_position = Vector3(8.0, 3.0, -19.5)
	cam.look_at(Vector3(8.0, 1.7, -30.0))
	cam.rotate_object_local(Vector3.BACK, deg_to_rad(3.0))
	cam.fov = 50.0


func _build_overlay() -> void:
	# Faixa de título, abaixo do fade.
	var title_layer := CanvasLayer.new()
	title_layer.layer = 90
	root.add_child(title_layer)
	var title_root := Control.new()
	title_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_layer.add_child(title_root)
	title_band = ColorRect.new()
	title_band.color = Color(0.02, 0.05, 0.09, 0.86)
	title_band.position = Vector2(352, 10)
	title_band.size = Vector2(576, 44)
	title_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_root.add_child(title_band)
	var accent := ColorRect.new()
	accent.color = Color(1.0, 0.26, 0.20, 1.0)
	accent.position = Vector2.ZERO
	accent.size = Vector2(5, 44)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_band.add_child(accent)
	title_label = Label.new()
	title_label.position = Vector2(16, 1)
	title_label.size = Vector2(548, 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_font_override("font", FanMenu.title_font())
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.92, 1.0, 1.0))
	title_band.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.position = Vector2(16, 23)
	subtitle_label.size = Vector2(548, 18)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle_label.add_theme_font_override("font", FanMenu.body_font())
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.add_theme_color_override("font_color", Color(0.56, 0.91, 1.0))
	title_band.add_child(subtitle_label)
	title_band.modulate = Color(1, 1, 1, 0)

	# Fade + cartão de abertura/fecho, acima de tudo.
	overlay = CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(fade)
	intro_root = Control.new()
	intro_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_root.visible = false
	overlay.add_child(intro_root)
	intro_title = Label.new()
	intro_title.position = Vector2(0, 262)
	intro_title.size = Vector2(1280, 74)
	intro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_title.add_theme_font_override("font", FanMenu.title_font())
	intro_title.add_theme_font_size_override("font_size", 56)
	intro_title.add_theme_color_override("font_color", Color(0.92, 1.0, 1.0))
	intro_title.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.1))
	intro_title.add_theme_constant_override("outline_size", 8)
	intro_root.add_child(intro_title)
	intro_sub = Label.new()
	intro_sub.position = Vector2(0, 342)
	intro_sub.size = Vector2(1280, 60)
	intro_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_sub.add_theme_font_override("font", FanMenu.body_font())
	intro_sub.add_theme_font_size_override("font_size", 19)
	intro_sub.add_theme_color_override("font_color", Color(0.56, 0.91, 1.0))
	intro_root.add_child(intro_sub)
	var line := ColorRect.new()
	line.color = Color(1.0, 0.26, 0.20, 0.95)
	line.position = Vector2(540, 330)
	line.size = Vector2(200, 3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_root.add_child(line)


func _set_title(main: String, sub: String) -> void:
	title_label.text = main.to_upper()
	subtitle_label.text = sub
	title_band.modulate = Color(1, 1, 1, 1)


func _fade_to(alpha: float, duration: float) -> void:
	var from := fade.color.a
	var tw: Tween = root.create_tween()
	tw.tween_method(func(a: float) -> void: fade.color = Color(0, 0, 0, a), from, alpha, duration)
	await tw.finished


# --- Utilidades --------------------------------------------------------------

func _reset_all() -> void:
	for c in battle.party + battle.enemies:
		c.end_guard("battle_end")
		c.end_shield("battle_end")
		c.clear_pending()
		c.hp = c.max_hp
		c.atb = 0.0
		c.extra = 0.0
		c.burst = 0
		c.pos_step = 0
		c.step_from = 0.0
		c.step_t = 1.0
		c.clear_rest()
		c.engaged_with = null
		c.pos = c.home
		c.stun_timer = 0.0
		c.blind_timer = 0.0
		c.burn_ticks_left = 0
		c.burn_clock = 0.0
		c.taunted_by = null
	battle.incoming.clear()
	battle._update_positions()


func _find_skill(c: Combatant, name: String) -> Skill:
	for s in c.skills:
		if s.display_name == name:
			return s
	return null


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, false).timeout


func _wait_until(predicate: Callable, timeout: float) -> bool:
	var frames := int(timeout * 30.0)
	for i in frames:
		if predicate.call():
			return true
		await process_frame
	return predicate.call()
