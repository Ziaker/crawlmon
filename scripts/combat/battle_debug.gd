class_name BattleDebug
extends CanvasLayer
## Estação de Debug e Inspeção Visual do Combate. F1 abre/fecha o painel.
## Permite avanço quadro a quadro (1/60s), câmera livre orbital 360°,
## gizmos 3D de trajetória/contato e disparo isolado de golpes/impactos de VFX.

const PHASES := ["PREPARO", "TRAJETO", "GOLPE", "RETORNO", "FIM", "ATORDOADO"]
const SPEEDS := [1.0, 0.5, 0.25, 0.1, 0.05, 2.0]

var _battle: Battle
var _party: Array[Combatant] = []
var _enemies: Array[Combatant] = []
var _fx: BattleFx
var _main_cam: Camera3D
var _director: BattleCamera

# UI
var _label: Label
var _bg: ColorRect
var _test_label: Label  ## Visible line with the camera test state (only while a test toggle is on).
var _overlay: CanvasLayer  ## Holds the test line so it shows even with the panel closed.

# Estado de Simulação & Tempo
var _god := false
var _ai_off := false
var _speed_i := 0
var _is_paused := false
var _note := ""
var _saved_policy := {}
var _test_enemy_toggle := Callable()  ## Set by the battle scene: adds/removes the test enemies (H).
var _test_enemy_push := Callable()  ## Set by the battle scene: slides a test enemy sideways (J).

# Seleção de Teste
var _attacker_idx := 0
var _target_idx := 0
var _skill_idx := 0

# Câmera Livre 360°
var _free_cam: Camera3D
var _free_cam_active := false
var _cam_yaw := 0.0
var _cam_pitch := 0.25
var _cam_dist := 12.0
var _cam_pivot := Vector3(0.0, 1.2, 0.0)
var _rmb_down := false

# Gizmos 3D
var _gizmos_enabled := true
var _gizmo_node: Node3D
var _gizmo_meshes: Array[MeshInstance3D] = []


func setup(battle: Battle, party: Array[Combatant], enemies: Array[Combatant], p_fx: BattleFx = null, p_cam: Camera3D = null, p_director: BattleCamera = null) -> void:
	_battle = battle
	_party = party
	_enemies = enemies
	_fx = p_fx
	_main_cam = p_cam
	_director = p_director
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_bg = ColorRect.new()
	_bg.color = Color(0.02, 0.04, 0.07, 0.82)
	_bg.position = Vector2(10, 10)
	_bg.size = Vector2(980, 240)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_bg.name = "Bg"

	_label = Label.new()
	_label.position = Vector2(18, 14)
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color("d7fd6a"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_test_label = Label.new()
	_test_label.position = Vector2(0, 684)
	_test_label.size = Vector2(1280, 22)
	_test_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_test_label.add_theme_font_size_override("font_size", 12)
	_test_label.add_theme_color_override("font_color", Color("d7fd6a"))
	_test_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_test_label.visible = false
	# Own CanvasLayer: it must stay visible while the panel itself is closed.
	_overlay = CanvasLayer.new()
	_overlay.layer = layer + 1
	add_child(_overlay)
	_overlay.add_child(_test_label)

	_setup_free_cam()
	_setup_gizmos()


## The battle scene owns the spawn: H asks it to add two standing test enemies.
func set_test_enemy_toggle(cb: Callable) -> void:
	_test_enemy_toggle = cb


## J / Shift+J: the battle scene slides a test enemy to one side (D-015 test).
func set_test_enemy_push(cb: Callable) -> void:
	_test_enemy_push = cb


func _setup_free_cam() -> void:
	_free_cam = Camera3D.new()
	_free_cam.name = "DebugFreeCam3D"
	_free_cam.fov = 45.0
	_free_cam.current = false
	if is_instance_valid(_fx):
		_fx.add_child(_free_cam)
	else:
		add_child(_free_cam)


func _setup_gizmos() -> void:
	_gizmo_node = Node3D.new()
	_gizmo_node.name = "DebugGizmos3D"
	if is_instance_valid(_fx):
		_fx.add_child(_gizmo_node)
	else:
		add_child(_gizmo_node)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				visible = not visible
			KEY_P:  # (Space is the Evade key of the game)
				_toggle_pause()
			KEY_N, KEY_PERIOD:
				_step_one_frame()
			KEY_F7:
				_speed_i = (_speed_i + 1) % SPEEDS.size()
				Engine.time_scale = SPEEDS[_speed_i] if not _is_paused else 0.0
				_note = "Velocidade x%.2f" % SPEEDS[_speed_i]
			KEY_C, KEY_F12:
				_toggle_free_cam()
			KEY_G:
				_gizmos_enabled = not _gizmos_enabled
				_note = "Gizmos 3D: %s" % ("LIGADOS" if _gizmos_enabled else "desligados")
			KEY_TAB:
				_cycle_attacker(1 if not event.shift_pressed else -1)
			KEY_F2:
				_fill_all_atb()
			KEY_BRACKETRIGHT:  # D-1070: ATB of the selected fighter (Tab cycles): ] +1 block, Shift+] full
				_set_atb(_current_attacker(), 99.0 if event.shift_pressed else 1.0, true)
			KEY_BRACKETLEFT:  # [ -1 block, Shift+[ zero
				_set_atb(_current_attacker(), 0.0 if event.shift_pressed else -1.0, event.shift_pressed == false)
			KEY_F3:
				if _enemies.size() > 0 and _party.size() > 0:
					_force_attack(_enemies[0], _party[0])
			KEY_F4:
				if _enemies.size() > 0:
					_force_attack(_enemies[0], _party[1] if _party.size() > 1 else _party[0])
			KEY_F8:
				if _party.size() > 1 and _enemies.size() > 0:
					_force_attack(_party[1], _enemies[0])
			KEY_F5:
				_god = not _god
				_note = "Modo Deus: %s" % ("ON" if _god else "off")
			KEY_F6:
				_toggle_ai()
			KEY_V:
				_trigger_strike_vfx_only()
			KEY_B:
				_trigger_impact_vfx_only()
			KEY_K:
				_toggle_frame_mode()
			KEY_L:
				_toggle_react_in_tactica()
			KEY_M:
				_toggle_leader_priority()
			KEY_H:
				_toggle_test_enemies(event.shift_pressed)
			KEY_J:
				_push_test_enemy(event.shift_pressed)
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
				var idx: int = event.keycode - KEY_1
				_select_skill(idx)
			KEY_F9:
				_apply_test_damage(10, event.shift_pressed)
			KEY_F10:
				_apply_test_ko()

	# Controles de mouse da Câmera Livre
	if _free_cam_active:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_rmb_down = event.pressed
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_cam_dist = maxf(_cam_dist - 1.2, 1.5)
				_update_free_cam_transform()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_cam_dist = minf(_cam_dist + 1.2, 45.0)
				_update_free_cam_transform()
		elif event is InputEventMouseMotion and _rmb_down:
			_cam_yaw -= event.relative.x * 0.006
			_cam_pitch = clampf(_cam_pitch - event.relative.y * 0.006, -1.35, 1.35)
			_update_free_cam_transform()


func _toggle_pause() -> void:
	_is_paused = not _is_paused
	if _is_paused:
		Engine.time_scale = 0.0
		_note = "PAUSA DE DEBUG (P retoma, N avança 1 frame)"
	else:
		Engine.time_scale = SPEEDS[_speed_i]
		_note = "CONTINUANDO (x%.2f)" % SPEEDS[_speed_i]


func _step_one_frame() -> void:
	if not _is_paused:
		_toggle_pause()
	Engine.time_scale = 1.0
	await get_tree().process_frame
	if _is_paused:
		Engine.time_scale = 0.0
	_note = "AVANÇOU 1 QUADRO FÍSICO (1/60s)"


func _toggle_free_cam() -> void:
	_free_cam_active = not _free_cam_active
	if _free_cam_active:
		if _main_cam != null:
			_cam_pivot = _main_cam.global_position + _main_cam.global_transform.basis * Vector3(0, 0, -10.0)
			_cam_dist = _main_cam.global_position.distance_to(_cam_pivot)
		_free_cam.make_current()
		_update_free_cam_transform()
		_note = "CÂMERA LIVRE ATIVA (Segure Botão Direito do Mouse + WASD)"
	else:
		if _main_cam != null:
			_main_cam.make_current()
		_note = "Câmera de combate restaurada"


func _update_free_cam_transform() -> void:
	if not _free_cam_active or _free_cam == null:
		return
	var rot := Basis(Vector3.UP, _cam_yaw) * Basis(Vector3.RIGHT, _cam_pitch)
	var offset := rot * Vector3(0.0, 0.0, _cam_dist)
	_free_cam.global_position = _cam_pivot + offset
	_free_cam.look_at(_cam_pivot, Vector3.UP)


func _cycle_attacker(dir: int) -> void:
	var total := _all_combatants()
	if total.is_empty():
		return
	_attacker_idx = posmod(_attacker_idx + dir, total.size())
	_skill_idx = 0
	var c: Combatant = total[_attacker_idx]
	_note = "Atacante selecionado: %s" % c.name


func _select_skill(idx: int) -> void:
	var actor := _current_attacker()
	if actor == null:
		return
	var skills: Array[Skill] = [Skill.basic()]
	skills.append_array(actor.skills)
	if idx < skills.size():
		_skill_idx = idx
		_note = "Habilidade: %s (%s)" % [skills[_skill_idx].display_name, Skill.kind_name(skills[_skill_idx].kind)]


func _current_attacker() -> Combatant:
	var total := _all_combatants()
	return total[_attacker_idx] if _attacker_idx < total.size() else null


func _current_target() -> Combatant:
	var actor := _current_attacker()
	if actor == null:
		return null
	var foes := _enemies if actor.is_player else _party
	for f in foes:
		if f.is_alive():
			return f
	return null


func _all_combatants() -> Array[Combatant]:
	var list: Array[Combatant] = []
	list.append_array(_party)
	list.append_array(_enemies)
	return list


## D-1070: ATB of one fighter. `amount` is added (relative) or set (absolute); 99 means full. Clamped to 0..5 blocks.
func _set_atb(c: Combatant, amount: float, relative: bool) -> void:
	if c == null:
		return
	c.atb = clampf(c.atb + amount if relative else amount, 0.0, Combatant.BLOCKS)
	_note = "ATB de %s: %.1f" % [c.name, c.atb]


func _fill_all_atb() -> void:
	for c in _all_combatants():
		c.atb = Combatant.BLOCKS
	if _party.size() > 0:
		_party[0].burst = mini(_party[0].burst + 1, Combatant.BURST_MAX)
	_note = "ATB cheio para todos e +1 Burst no líder"


## D-1042 / D-1044: aplica dano de teste passando pelo pipeline real de hit_resolved (animação damage, flash, hit-stop, recuo e texto flutuante).
func _apply_test_damage(amount: int, is_crit := false) -> void:
	var att := _current_attacker()
	var tgt := _current_target()
	if tgt == null:
		return
	if att == null:
		att = tgt
	var guard_res := ""
	if tgt.is_guarding():
		guard_res = "absorbed"
		amount = DamageMath.apply_guard(amount)
		tgt.end_guard("hit")
	var armor_res := ""
	if tgt.is_armored() and guard_res == "":
		armor_res = "hit"
		tgt.end_armor("hit")
	tgt.take_damage(amount)
	if _battle != null:
		_battle.hit_resolved.emit(att, tgt, Element.Type.FISICO, {
			"evaded": false, "dmg": amount, "weak": false, "crit": is_crit,
			"gain": 1 if is_crit else 0, "whiffed": false, "power": 1.0,
			"skill_name": "Tackle", "guard": guard_res, "armor": armor_res,
		})
	_note = "Dano de Teste: %s levou %d dano%s (HP %d/%d)" % [tgt.name, amount, " CRÍTICO!" if is_crit else "", tgt.hp, tgt.max_hp]


## D-1042 / D-1044: aplica K.O. de teste passando por hit_resolved para disparar o lançamento balístico de K.O. (D-049/D-160/D-166).
func _apply_test_ko() -> void:
	var att := _current_attacker()
	var tgt := _current_target()
	if tgt == null:
		return
	if att == null:
		att = tgt
	var fatal := maxi(1, tgt.hp)
	tgt.take_damage(fatal, true)
	if _battle != null:
		_battle.hit_resolved.emit(att, tgt, Element.Type.FISICO, {
			"evaded": false, "dmg": fatal, "weak": false, "crit": true,
			"gain": 0, "whiffed": false, "power": 1.5, "skill_name": "Tackle",
		})
	_note = "K.O. de Teste (com lançamento): %s eliminado" % tgt.name


func _force_attack(actor: Combatant, target: Combatant) -> void:
	var skills: Array[Skill] = [Skill.basic()]
	skills.append_array(actor.skills)
	var sk := skills[_skill_idx % skills.size()]
	actor.atb = Combatant.BLOCKS
	var ok := _battle.use_skill(actor, sk, target)
	_note = "%s usa %s em %s: %s" % [actor.name, sk.display_name, target.name, "OK" if ok else "bloqueado (ocupado/engajado)"]


## Dispara isoladamente apenas a animação e o VFX de golpe no atacante selecionado.
func _trigger_strike_vfx_only() -> void:
	var actor := _current_attacker()
	var target := _current_target()
	if actor == null or target == null or _fx == null:
		return
	var skills: Array[Skill] = [Skill.basic()]
	skills.append_array(actor.skills)
	var sk := skills[_skill_idx % skills.size()]
	var mid := BattleFx.normalize_move_id(sk.display_name)
	var from_pos := actor.pos
	var to_pos := target.pos
	var dir := (to_pos - from_pos).normalized()
	if dir.length_squared() < 0.01:
		dir = Vector3.FORWARD

	if mid in ["tackle", "investida"]:
		_fx.fx_motion._tackle_strike_vfx(from_pos + dir * 0.8, dir)
	else:
		_fx.flash(actor)
	_fx._play(actor, "attack")
	_note = "VFX de Golpe isolado: %s (%s)" % [sk.display_name, sk.visual_phase_text("strike")]


## Dispara isoladamente apenas o VFX de impacto no alvo selecionado.
func _trigger_impact_vfx_only() -> void:
	var actor := _current_attacker()
	var target := _current_target()
	if actor == null or target == null or _fx == null:
		return
	var skills: Array[Skill] = [Skill.basic()]
	skills.append_array(actor.skills)
	var sk := skills[_skill_idx % skills.size()]
	var mid := BattleFx.normalize_move_id(sk.display_name)
	var to_pos := target.pos + Vector3(0, 1.0, 0)
	var color: Color = _fx.COLORS.get(sk.element, Color.WHITE)

	_fx.fx_impacts._impact(sk.element, to_pos, color, true, Vector3.FORWARD, mid)
	_fx.flash(target)
	_fx.float_text(to_pos + Vector3(0, 1.8, 0), sk.display_name.to_upper(), color, 42)
	if _director != null:
		_director.impact_post(to_pos, color, true, BattleFx.move_uses_bw_pulse(mid))
	_note = "VFX de Impacto isolado: %s (%s)" % [sk.display_name, sk.visual_phase_text("impact")]


func _toggle_ai() -> void:
	_ai_off = not _ai_off
	for c in _party.slice(1) + _enemies:
		if _ai_off:
			_saved_policy[c] = c.act_policy
			c.act_policy = Combatant.Act.HOLD
		else:
			c.act_policy = _saved_policy.get(c, c.act_policy)
	_note = "IA: %s" % ("PARADA (HOLD)" if _ai_off else "LIGADA")


## D-015 test: cycle the enemy framing (fixed -> smooth follow -> deadzone).
func _toggle_frame_mode() -> void:
	if _director == null:
		return
	_director.set_frame_mode((_director.frame_mode + 1) % 3)
	var names := ["OFF (enquadramento fixo de hoje)", "SUAVE (segue todos os inimigos)", "ZONA MORTA (só mexe quando sai do quadro)"]
	_say("Câmera D-015: %s" % names[_director.frame_mode])


## Test: should the camera lean toward a hit while the target menu is open?
func _toggle_react_in_tactica() -> void:
	if _director == null:
		return
	_director.react_in_tactica = not _director.react_in_tactica
	_say("Câmera reage com o menu de alvo aberto: %s" % ("LIGADA" if _director.react_in_tactica else "desligada"))


## Test: a hit on the leader outranks other camera intents until its framing ends.
func _toggle_leader_priority() -> void:
	if _director == null:
		return
	_director.leader_priority = not _director.leader_priority
	_say("Prioridade da câmera para o líder: %s" % ("LIGADA" if _director.leader_priority else "desligada"))


## Test (D-015): the battle scene adds/removes two standing test enemies.
func _toggle_test_enemies(remove: bool) -> void:
	if not _test_enemy_toggle.is_valid():
		return
	_say(String(_test_enemy_toggle.call(remove)))


## Panel note plus a console line: the panel may be closed while a test key is pressed.
func _say(text: String) -> void:
	_note = text
	print("[debug] ", text)


## Test (D-015): slide the first test enemy sideways so the framing can be seen acting.
func _push_test_enemy(left: bool) -> void:
	if not _test_enemy_push.is_valid():
		return
	_say(String(_test_enemy_push.call(left)))


func _process(delta: float) -> void:
	if _battle == null:
		return
	if _god:
		for c in _party:
			c.set_hp_instant(c.max_hp)

	_process_free_cam_motion(delta)
	_update_gizmos()
	_update_test_banner()

	if not visible:
		return

	_update_hud_text()


## Small always-visible line while a camera test toggle is on (the panel may be closed).
func _update_test_banner() -> void:
	if _test_label == null:
		return
	var on := _director != null and (_director.frame_mode != 0 or _director.react_in_tactica or _director.leader_priority)
	_test_label.visible = on
	if not on:
		return
	_test_label.text = "TESTE DE CÂMERA — enquadramento: %s   |   reage com menu de alvo: %s   |   prioridade do líder: %s   |   [K] [L] [M] trocam" % [
		["OFF", "SUAVE", "ZONA MORTA"][_director.frame_mode],
		"ON" if _director.react_in_tactica else "off",
		"ON" if _director.leader_priority else "off",
	]


func _process_free_cam_motion(delta: float) -> void:
	if not _free_cam_active:
		return
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): move.z -= 1.0
	if Input.is_key_pressed(KEY_S): move.z += 1.0
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if Input.is_key_pressed(KEY_Q): move.y -= 1.0
	if Input.is_key_pressed(KEY_E): move.y += 1.0

	if move.length_squared() > 0.01:
		var rot := Basis(Vector3.UP, _cam_yaw)
		var trans := rot * move.normalized() * (14.0 * delta)
		_cam_pivot += trans
		_update_free_cam_transform()


func _update_gizmos() -> void:
	for m in _gizmo_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_gizmo_meshes.clear()

	if not _gizmos_enabled or _battle == null or not visible:
		return

	for inc in _battle.incoming + _battle.attacks_in_flight():
		if not is_instance_valid(inc.attacker) or not is_instance_valid(inc.target):
			continue
		var from_pos: Vector3 = inc.attacker.pos + Vector3(0, 0.4, 0)
		var to_pos: Vector3 = inc.target.pos + Vector3(0, 0.4, 0)
		_draw_debug_line(from_pos, to_pos, Color("00e5ff", 0.65))
		_draw_debug_marker(to_pos, Color("ff1744", 0.85), 0.35)


func _draw_debug_line(from: Vector3, to: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_LINES)
	imm.surface_set_color(color)
	imm.surface_add_vertex(from)
	imm.surface_set_color(color)
	imm.surface_add_vertex(to)
	imm.surface_end()
	mi.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	_gizmo_node.add_child(mi)
	_gizmo_meshes.append(mi)


func _draw_debug_marker(pos: Vector3, color: Color, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	mi.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = pos
	_gizmo_node.add_child(mi)
	_gizmo_meshes.append(mi)


func _update_hud_text() -> void:
	var lines := PackedStringArray()
	var speed_str := "PAUSADO" if _is_paused else ("x%.2f" % SPEEDS[_speed_i])
	lines.append("DEBUG VISUAL (F1 toggle) | Vel: %s (F7) | Cam 360°: %s (C) | Gizmos 3D: %s (G) | Deus: %s (F5)" % [
		speed_str, "ATIVA" if _free_cam_active else "Combate", "ON" if _gizmos_enabled else "OFF", "ON" if _god else "off"
	])
	lines.append("CONTROLES: [P] Pausa | [N/.] Quadro a quadro (1/60s) | [V] Só Golpe VFX | [B] Só Impacto VFX | [Tab] Cicla Lutador | [1..8] Habilidade")
	lines.append("ATALHOS: F2 ATB cheio (todos) | ] +1 ATB, Shift+] cheio, [ -1 ATB, Shift+[ zerado (lutador do Tab) | F3 Inimigo->Líder | F4 Inimigo->Aliado | F8 Aliado->Inimigo | F6 IA on/off | F9 Dano (Shift=Crit) | F10 KO")
	if _director != null:
		lines.append("CÂMERA (teste): [K] Enquadrar inimigos=%s | [L] Reage com menu de alvo=%s | [M] Prioridade do líder=%s" % [
			["OFF", "SUAVE", "ZONA MORTA"][_director.frame_mode],
			"ON" if _director.react_in_tactica else "off",
			"ON" if _director.leader_priority else "off",
		])
		lines.append("CÂMERA (teste): [H] +2 inimigos parados | [Shift+H] remove | [J] empurra o 1º para o lado | [Shift+J] para o outro")

	var cur_att := _current_attacker()
	var cur_tgt := _current_target()
	var skills: Array[Skill] = [Skill.basic()]
	if cur_att != null:
		skills.append_array(cur_att.skills)
	var active_sk := skills[_skill_idx % skills.size()] if not skills.is_empty() else null
	var sk_name := active_sk.display_name if active_sk != null else "-"

	lines.append("SELEÇÃO: Atacante=[%s]  Alvo=[%s]  Golpe Ativo=[%s (teclas 1..%d)]" % [
		cur_att.name if cur_att != null else "-", cur_tgt.name if cur_tgt != null else "-", sk_name, skills.size()
	])

	if _note != "":
		lines.append(">> " + _note)

	for c in _all_combatants():
		var eng := "-"
		if c.engaged_with != null:
			eng = "%s (%.1fs)" % [c.engaged_with.name, c.engage_left]
		var buff_str := ""
		if c.atk_buff != 0 or c.def_buff != 0 or c.speed_buff != 0:
			buff_str = " | ATK%+d DEF%+d VEL%+d" % [c.atk_buff, c.def_buff, c.speed_buff]
		lines.append("%-8s HP %2d/%2d  ATB %.1f  Burst %d  pos %+d  eng: %-12s%s" % [
			c.name, c.hp, c.max_hp, c.atb, c.burst, c.pos_step, eng, buff_str
		])

	var any := false
	for inc in _battle.incoming + _battle.attacks_in_flight():
		any = true
		var tag := ""
		if inc.interrupted:
			tag = " [INTERROMPIDO]"
		elif inc.can_evade_now():
			tag = " [JANELA EVADE: %.2fs]" % inc.travel_left()
		var prog := inc.progress() if inc.resolved else 1.0 - inc.time_left / maxf(inc.total_windup, 0.01)
		lines.append("  ATTACK: %s -> %s | %s (%s) | %s %d%% eta %.2fs%s" % [
			inc.attacker.name, inc.target.name, inc.label, Skill.kind_name(inc.kind),
			PHASES[inc.phase], int(prog * 100.0), inc.eta() if inc.resolved else inc.time_left, tag
		])
	if not any:
		lines.append("  (Nenhum ataque em execução)")

	_label.text = "\n".join(lines)
