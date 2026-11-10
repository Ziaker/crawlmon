extends Node

const DrainSpearMove = preload("res://scripts/data/drain_spear_move.gd")
## Sala de VFX: abre a batalha real sem IA e sem menu, e um painel na tela dispara qualquer move
## em qualquer alvo, com loop, pausa, quadro a quadro, câmera lenta, câmera de órbita, distância
## entre os times, times espelhados (Gible aliado; Abra e Pancham inimigos), resultado forçado
## (acerto, esquiva, crítico, fraqueza), pausa automática em eventos, log das fases com tempos,
## gravação de quadros, camadas ligáveis e recarga dos scripts/shaders de VFX.
## Os efeitos rodam pelo mesmo código do jogo.
##
## Abrir: scenes/debug/vfx_room.tscn (F6 no editor) ou  Godot --path . res://scenes/debug/vfx_room.tscn
## Atalhos: 1..9 dispara o move N | Enter repete o último | P pausa | N avança 1 quadro | L loop
##          Q/E troca o alvo | R recarrega o VFX e repete | F2 esconde o painel
##          Órbita: arrastar = girar, roda = zoom
##
## Linha de comando (tudo depois de "--"), por exemplo:
##   Godot --path . res://scenes/debug/vfx_room.tscn --fixed-fps 60 -- --move=Confusion --force=hit \
##     --cam=1 --speed=0.5 --record=3 --step=0.05 --quit
##   --scenario=choque|choque_atraso|cruzamento|persegue|morre_windup|morre_corrida|evade_perfeito|guard|interrompe --windup=
##   --move= --attacker=player|enemy|NOME --target=opponent|NOME --mirror --cam=0..3 --speed= --distance= --force=random|hit|dodge|crit|weak
##   --preflight=SEGUNDOS (checagem rápida: dispara, imprime [vfx_room] preflight result=... e sai)
##   --real-mp (não completa MP: expõe recusa real; o padrão da sala continua completando)
##   (--dqt/--dqt-mirror não são lidos aqui: o BattleScene os lê de OS.get_cmdline_user_args())
##   --pause-at=release|travel|strike|impact --pause-delay= --shot=arquivo.png
##   --hide=linhas,particulas,shaders,sprites,malhas --record=SEGUNDOS --step=SEGUNDOS --out=pasta
##   --log=arquivo.txt --quit

const PANEL_W := 560.0  ## largura do painel, em pixels
## Cenários prontos em scripts/debug/vfx_room_scenarios.gd (VfxRoomScenarios.SCENARIOS).
const LOOP_GAP := 0.8  ## segundos depois do golpe terminar antes de repetir
const TEAM_DISTANCE := 30.0
const FORCE_LABELS := ["Sorteio normal", "Acerto (sem crítico)", "Esquiva", "Crítico", "Fraqueza (acerto)"]
const FORCE_KEYS := ["random", "hit", "dodge", "crit", "weak"]
const FORCE_ROLL := [0, 1, 2, 3, 1]
const PAUSE_LABELS := ["Não pausar", "Início do preparo (wind-up)", "Fim da carga (release)", "Disparo (voo)", "Golpe", "Impacto", "Retorno"]
const PAUSE_KEYS := ["", "windup", "release", "travel", "strike", "impact", "return"]
const LAYER_KEYS := ["linhas", "particulas", "shaders", "sprites", "malhas"]
const LAYER_LABELS := ["Linhas neon e sólidos", "Partículas", "Flipbooks e shaders", "Sprites e brilhos", "Malhas simples"]
const RELOAD_DIRS := ["res://scripts/vfx/combat/", "res://scripts/vfx/smt/"]
const RELOAD_FILES := ["res://scripts/combat/vfx_lib.gd", "res://scripts/combat/battle_fx.gd"]

var _args := {}
var _bs: Node3D
var _battle: Battle
var _units: Array[Combatant] = []
var _panel: PanelContainer
var _tabs: TabContainer
var _svc: SubViewportContainer  ## a cena do combate; ocupa a tela menos o painel (o painel nunca cobre a cena)
var _sv: SubViewport
var _attacker: OptionButton
var _multi_box: GridContainer  ## D-980
var _multi_checks: Array = []  ## D-980: one CheckBox per unit
var _move: OptionButton
var _target: OptionButton
var _move_grid: GridContainer
var _cam_mode: OptionButton
var _focus: OptionButton
var _speed: HSlider
var _speed_label: Label
var _dist: HSlider
var _dist_label: Label
var _force: OptionButton
var _pause_event: OptionButton
var _pause_delay: HSlider
var _pause_delay_label: Label
var _loop: CheckButton
var _hud: CheckButton
var _immortal: CheckButton
var _mirror_btn: CheckButton
var _channel: CheckButton  ## o alvo começa um ataque (canalização) antes do disparo: o acerto o interrompe
var _pause_btn: Button
var _status: Label
var _log_label: Label
var _layer_checks: Dictionary = {}
var _idle_for := 0.0
var _fired := false
var _mirror := false
var _paused := false
var _step := 0
var _clock := 0.0  ## segundos de jogo (já na escala de velocidade) desde que a sala abriu
var _fire_clock := 0.0
var _pause_due := -1.0
var _log: Array[String] = []
var _base_hp: Dictionary = {}
var _weak_added: Array = []  ## [alvo, elemento] adicionados pelo "Fraqueza" e devolvidos no próximo disparo
var _orbit_yaw := 0.0
var _orbit_pitch := 0.3
var _orbit_dist := 14.0
var _dragging := false
var _rec_request := 0.0  ## segundos a gravar no próximo disparo (0 = nada)
var _rec_step := 0.05
var _rec: Dictionary = {}
var _shot_path := ""
var _shot_taken := false
var _quit_flag := false
var _hidden_prev: Dictionary = {}
# --- Cenários (vários ataques, evade, morte, posição) ---
var _a2_on: CheckButton  ## segundo ataque junto com o primeiro
var _attacker2: OptionButton
var _move2: OptionButton
var _target2: OptionButton
var _delay2: HSlider  ## segundos entre os dois disparos (negativo: o segundo sai antes)
var _delay2_label: Label
var _windup_ovr: HSlider  ## 0 = wind-up do Move; senão força esse tempo nos dois ataques
var _windup_label: Label
var _atb_slider: HSlider
var _atb_label: Label
var _hp_slider: HSlider
var _hp_label: Label
var _guard_target: CheckButton  ## o alvo do ataque 1 abre Guard antes do disparo
var _evade_unit: OptionButton
var _evade_mode: OptionButton
var _evade_at: HSlider
var _evade_label: Label
var _kill_on: CheckButton
var _kill_unit: OptionButton
var _kill_at: HSlider
var _kill_label: Label
var _buff_unit: OptionButton
var _buff_stat: OptionButton
var _pos_unit: OptionButton
var _pos_x: HSlider
var _pos_z: HSlider
var _pos_label: Label
var _unit_opts: Array[OptionButton] = []  ## seletores de unidade que se refazem quando as unidades mudam
var _sched: Array = []  ## ações marcadas para t segundos depois do disparo: {at, kind, ...}
var _evade_done := false
var _panel_user_hidden := false  ## F2
var _autohide: CheckButton  ## esconde o painel durante o golpe
var _delay1: HSlider  ## atraso do ataque 1 (os dois ataques saem esse tempo depois do disparo)
var _delay1_label: Label
var _act_unit: OptionButton  ## ação agendada à mão (aba Ações)
var _act_kind: OptionButton
var _act_at: HSlider
var _act_label: Label
var _polls: Array = []  ## tentativas de Evade em curso (cada uma tenta até a janela final)
var _manual_acts: Array = []  ## ações agendadas à mão; valem em todo disparo até limpar
var _scn_search: LineEdit
var _scn_count: Label
var _scn_view: VBoxContainer
var _scn_items: ItemList
var _scn_group_opt: OptionButton
var _scn_detail: Label
var _scn_ids: Array[String] = []  ## id do cenário de cada linha da lista ("" = título de grupo)
var _scn_cur := ""
var _speed_quick: OptionButton
var _scn_group := "Todos"
var _scn_on := false  ## há um cenário pronto montado (os Moves disparados à mão o esquecem)
var _scn_name := ""
var _scn_atk: Array = []
var _scn_acts: Array = []
var _scn_pos: Dictionary = {}
var _need_enemies := 1  ## 3 = os 2 inimigos extras entram junto
var _catalog: Dictionary = {}  ## todo Move conhecido por nome: qualquer unidade pode usar qualquer Move (D-235)
var _killed := false  ## alguém morreu de propósito: o próximo disparo recarrega a batalha
# --- Telemetria de Combate e 10 Ferramentas de Análise de VFX (D-1042 / D-1044) ---
var _tick_from_fire := 0
var _step_ticks_limit := -1
var _baseline_fx_ids: Dictionary = {}
var _audit_done := false
var _last_leaks: Array[String] = []
var _telemetry: Dictionary = {}
var _ficha_label: Label
var _analysis_overlay: Control
var _scale_overlay_on := false
var _bone_probe_on := false
var _overdraw_on := false
var _envelope_graph_on := false
var _audit_leaks_on := false
var _bg_mode := "arena"
var _bg_canvas_rect: ColorRect
var _solo_node_pattern := ""
var _mute_node_pattern := ""
var _bone_prev_pos := Vector3.ZERO
var _bone_has_prev := false
var _bone_cur_speed := 0.0
var _bone_peak_speed := 0.0
var _bone_name_tracked := ""
var _bone_trail: Array[Vector3] = []
var _envelope_samples: Array[Dictionary] = []
var _prev_node_alphas: Dictionary = {}
var _envelope_pops: Array[String] = []
var _overdraw_mat: StandardMaterial3D
var _orig_materials: Dictionary = {}
var _macro_slow_until := -1.0
var _analysis: VfxRoomAnalysis


func _ready() -> void:
	_parse_args()
	_analysis = VfxRoomAnalysis.new(self)
	add_child(_analysis)
	_seed_full_catalog()
	RenderingServer.set_default_clear_color(Color(0.03, 0.06, 0.1))  # o fundo atrás do painel
	_build_view()
	_build_panel()
	_build_analysis_overlay()
	await _load_battle(_args.has("mirror"))
	if _args.has("mirror"):
		_mirror_btn.set_pressed_no_signal(true)
	if _args.has("channel"):
		_channel.button_pressed = true
	await _run_cli()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1] if kv.size() > 1 else "true"


## A cena do combate numa área própria: o painel fica ao lado dela, nunca por cima.
func _build_view() -> void:
	_svc = SubViewportContainer.new()
	_svc.stretch = true
	_svc.mouse_filter = Control.MOUSE_FILTER_IGNORE  # o mouse (órbita da câmera) segue para a sala
	_svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_svc)
	_sv = SubViewport.new()
	_sv.handle_input_locally = false
	_svc.add_child(_sv)


## Reserva a faixa do painel (direita ou esquerda) enquanto ele está visível.
func _layout_view() -> void:
	if _svc == null or _panel == null:
		return
	var w := (PANEL_W + 16.0) if _panel.visible else 0.0
	var right := _panel.anchor_left > 0.5
	_svc.offset_left = 0.0 if right else w
	_svc.offset_right = -w if right else 0.0
	_svc.offset_top = 0.0
	_svc.offset_bottom = 0.0


## (Re)abre a batalha real. `mirror`: Gible aliado e Abra/Pancham inimigos.
func _load_battle(mirror: bool) -> void:
	_mirror = mirror
	_fired = false
	_units.clear()
	_base_hp.clear()
	if _bs != null:
		_retire_scene(_bs)
		await get_tree().process_frame
	_bs = (load("res://scenes/battle.tscn") as PackedScene).instantiate()
	_bs.set_meta("vfx_room", true)
	if mirror:
		_bs.set_meta("vfx_room_mirror", true)
	_sv.add_child(_bs)
	_battle = _bs.get_node("Battle")
	while not _battle.running:
		await get_tree().process_frame
	for i in 10:
		await get_tree().process_frame
	_units.append_array(_battle.party)
	_units.append_array(_battle.enemies)
	_killed = false
	_sched.clear()
	for c in _units:
		_prepare_unit(c)
	_share_catalog()
	_fill_units()
	_apply_distance(_dist.value)
	_connect_events()
	var ui := _bs.get_node_or_null("UI") as CanvasLayer
	if ui != null and _hud != null:
		ui.visible = not _hud.button_pressed
	_status.text = "Pronto (%s). Clique num move ou use 1..9." % ("times espelhados" if mirror else "times normais")


## A batalha antiga sai de cena sem ser apagada na hora: timers e efeitos dela ainda disparam e não podem achar nós já liberados.
func _retire_scene(old: Node3D) -> void:
	# D-1042/D-1044: a batalha antiga pode emitir FASE TRAVEL/IMPACTO depois do reload. Sem soltar os
	# ouvintes da sala nela, essas linhas entram no log da medição nova (test_melee_timers).
	var old_battle := old.get_node_or_null("Battle") as Battle
	if old_battle != null:
		for sig in ["attack_telegraphed", "attack_resolved", "attack_phase", "hit_resolved", "attack_cancelled", "battle_ended"]:
			for conn in old_battle.get_signal_connection_list(sig):
				# A cena antiga está sendo aposentada: nenhum ouvinte dela pode escrever no log novo.
				old_battle.disconnect(sig, conn["callable"])
	# A party persiste entre as recargas: solta os sinais dela que a cena antiga ouvia, para não chamarem uma cena morta.
	for c in _units:
		for sig in c.get_signal_list():
			for conn in c.get_signal_connection_list(sig["name"]):
				c.disconnect(sig["name"], conn["callable"])  # tudo que ouvia a party era da cena antiga (a nova se liga de novo)
	old.visible = false
	old.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := old.get_node_or_null("UI") as CanvasLayer
	if ui != null:
		ui.visible = false
	var cam := old.get_node_or_null("Camera3D") as Camera3D
	if cam != null:
		cam.current = false
	get_tree().create_timer(8.0, false).timeout.connect(old.queue_free)


## Deixa um combatente pronto para a sala: ninguém age sozinho, todos têm o Tackle e os Moves de fogo, vida folgada.
func _prepare_unit(c: Combatant) -> void:
	c.act_policy = Combatant.Act.HOLD
	c.react_policy = Combatant.React.NONE
	c.inventory = {}  # sem poções: a IA em "segurar" bebe quando está ferida e estragaria os cenários de vida baixa (só nesta sala)
	if c.has_meta("room_no_heal"):
		c.remove_meta("room_no_heal")
	var has_tackle := false
	for sk in c.skills:
		if sk.display_name == "Tackle":
			has_tackle = true
	if not has_tackle:
		c.skills.append(Skill.basic())  # o Tackle básico (sempre no menu do jogo) também fica na lista da sala
	for fire_skill in Skill.fire_skills():  # D-236: only this room lists the fire Moves; any unit can use them (D-235)
		var listed := false
		for sk2 in c.skills:
			if sk2.display_name == fire_skill.display_name:
				listed = true  # a party persists between reloads: do not stack the same Move again
		if not listed:
			c.skills.append(fire_skill)
	for lib_skill in Skill.library_skills():  # D-956/D-957: the projectile library Moves, listed only here
		var lib_listed := false
		for skl in c.skills:
			if skl.display_name == lib_skill.display_name:
				lib_listed = true
		if not lib_listed:
			c.skills.append(lib_skill)
	for el_skill in Skill.element_skills():  # D-308: the element reference Moves, listed only here
		var el_listed := false
		for sk3 in c.skills:
			if sk3.display_name == el_skill.display_name:
				el_listed = true
		if not el_listed:
			c.skills.append(el_skill)
	# move_drain_spear: listed here for every unit (D-235), like the reference Moves above.
	var drain_listed := false
	for sk4 in c.skills:
		if BattleSpace.move_id(sk4.display_name) == "drain_spear":
			drain_listed = true
	if not drain_listed:
		c.skills.append(DrainSpearMove.make())
	for sk3 in c.skills:
		if not _catalog.has(sk3.display_name):
			_catalog[sk3.display_name] = sk3
	if not c.has_meta("room_base_hp"):
		c.set_meta("room_base_hp", c.max_hp)  # a party é a mesma entre as recargas: guarda a vida original uma vez só
	_base_hp[c] = int(c.get_meta("room_base_hp"))
	c.max_hp = int(c.get_meta("room_base_hp")) * 4  # imortal: um golpe nunca mata; a vida enche de novo abaixo de 55%
	c.set_hp_instant(c.max_hp)


## Todo Move conhecido entra na lista de todas as unidades da sala (D-235: não existe Move de um personagem só).
func _share_catalog() -> void:
	for c in _units:
		for skill_name in _catalog:
			var has := false
			for sk in c.skills:
				if sk.display_name == skill_name:
					has = true
					break
			if not has:
				c.skills.append(_catalog[skill_name])


## Refaz a lista de unidades (depois de entrarem ou saírem inimigos de teste) sem perder as escolhas.
func _refresh_units() -> void:
	var keep := [_attacker.selected, _target.selected, _attacker2.selected, _target2.selected]
	_units.clear()
	_units.append_array(_battle.party)
	_units.append_array(_battle.enemies)
	for c in _units:
		if not _base_hp.has(c):
			_prepare_unit(c)
	_share_catalog()
	_fill_units()
	var last := _units.size() - 1
	_attacker.select(clampi(keep[0], 0, last))
	_target.select(clampi(keep[1], 0, last))
	_attacker2.select(clampi(keep[2], 0, last))
	_target2.select(clampi(keep[3], 0, last))
	_fill_moves()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	_save_log()


# --- Linha de comando ------------------------------------------------------------------


func _run_cli() -> void:
	if _args.is_empty():
		return
	var attacker_ok := _select_attacker_arg()
	_fill_moves()
	print("[vfx_room] cli units: ", _units.map(func(u: Combatant) -> String: return u.name), " attacker=", _attacker.selected)
	if not attacker_ok:
		_preflight_fail("Atacante não encontrado: %s" % String(_args.get("attacker", "")))
		return
	if String(_args.get("target", "")) == "opponent":
		# The first unit on the other side of the attacker (D-235: never a fixed index, which may be an ally).
		var atk_side: bool = (_units[_attacker.selected] as Combatant).is_player
		var target_ok := false
		for i in _units.size():
			if (_units[i] as Combatant).is_player != atk_side and (_units[i] as Combatant).is_alive():
				_target.select(i)
				target_ok = true
				break
		if not target_ok:
			_preflight_fail("Alvo oponente não encontrado para %s" % (_units[_attacker.selected] as Combatant).name)
			return
	else:
		if not _select_by_name(_target, String(_args.get("target", ""))):
			_preflight_fail("Alvo não encontrado: %s" % String(_args.get("target", "")))
			return
	if _args.has("cam"):
		var cam_arg := String(_args["cam"]).to_lower()
		if cam_arg == "macro":
			_cam_mode.select(5)
		else:
			_cam_mode.select(clampi(int(cam_arg), 0, 5))
		_apply_camera()
	if _args.has("fov-test"):
		_apply_fov_test(float(_args["fov-test"]))
	if _args.has("scale-overlay"):
		_scale_overlay_on = true
	if _args.has("bone-probe"):
		_bone_probe_on = true
	if _args.has("overdraw"):
		_overdraw_on = true
	if _args.has("envelope-graph"):
		_envelope_graph_on = true
	if _args.has("audit-leaks"):
		_audit_leaks_on = true
	if _args.has("bg"):
		_apply_bg_mode(String(_args["bg"]).to_lower())
	if _args.has("solo-node"):
		_solo_node_pattern = String(_args["solo-node"]).to_lower()
	if _args.has("mute-node"):
		_mute_node_pattern = String(_args["mute-node"]).to_lower()
	if _args.has("step-ticks"):
		_step_ticks_limit = int(_args["step-ticks"])
	if _args.has("speed"):
		_speed.value = float(_args["speed"])
	if _args.has("distance"):
		_dist.value = float(_args["distance"])
	if _args.has("force"):
		var fi := FORCE_KEYS.find(String(_args["force"]))
		if fi >= 0:
			_force.select(fi)
	if _args.has("pause-at"):
		var pi := PAUSE_KEYS.find(String(_args["pause-at"]))
		if pi >= 0:
			_pause_event.select(pi)
	elif _args.has("phase"):
		var pi := PAUSE_KEYS.find(String(_args["phase"]).to_lower())
		if pi >= 0:
			_pause_event.select(pi)
	elif _args.has("isolate-phase"):
		var iso := String(_args["isolate-phase"]).to_lower()
		var pi2 := PAUSE_KEYS.find(iso)
		if pi2 >= 0:
			_pause_event.select(pi2)
			if iso == "windup" and not _args.has("windup"):
				_windup_ovr.value = 2.0
	if _args.has("pause-delay"):
		_pause_delay.value = float(_args["pause-delay"])
	for name in String(_args.get("hide", "")).split(",", false):
		if _layer_checks.has(name):
			(_layer_checks[name] as CheckButton).button_pressed = false
	if _args.has("shot"):
		_shot_path = String(_args["shot"])
	if _args.has("record"):
		_rec_request = float(_args["record"])
		_rec_step = float(_args.get("step", 0.05))
	_quit_flag = _args.has("quit")
	if _args.has("scale-test"):
		_apply_scale_test(float(_args["scale-test"]))
	if _args.has("record-idle"):
		# Test-only: record the loaded battle without firing a Move.
		_fired = true
		_start_record(float(_args["record-idle"]), float(_args.get("step", "0.0333333")))
		return
	if _args.has("tab"):
		for ti in _tabs.get_tab_count():
			if _tabs.get_tab_title(ti) == String(_args["tab"]):
				_tabs.current_tab = ti
				_show_view(true)
	if _args.has("windup"):
		_windup_ovr.value = float(_args["windup"])
	if _args.has("hp"):
		_hp_slider.value = clampf(float(_args["hp"]), 1.0, 100.0)  # life of every unit when the shot fires (VFX demos)
	if _args.has("test-d235"):
		await _run_test_d235()
		return
	if _args.has("test-all-moves-matrix"):
		await _run_test_all_moves_matrix()
		return
	if _args.has("proof-sheet"):
		await _run_proof_sheet(String(_args["proof-sheet"]))
		return
	if _args.has("scenario"):
		var scn_id := String(_args["scenario"])
		if _scenario_by_id(scn_id).is_empty():
			# D-1035: fail fast instead of leaving --record waiting for a timeout.
			_preflight_fail("Cenário não encontrado: %s" % scn_id)
			_quit_flag = true
			get_tree().quit()
			return
		await get_tree().process_frame
		await _run_scenario(scn_id)
		return
	if _args.has("move"):
		var want := String(_args["move"]).to_lower().replace(" ", "")
		var found := false
		for i in _move.item_count:
			if _move.get_item_text(i).to_lower().replace(" ", "") == want:
				_move.select(i)
				found = true
				break
		await get_tree().process_frame
		if not found:
			_preflight_fail("Move não encontrado: %s" % String(_args["move"]))
			return
		if _args.has("preflight"):
			# Fail-fast: the recorder needs to know within seconds whether the combat accepted the shot.
			# This only observes the real `_fire`; it does not change any rule or timing.
			await _fire()
			var wait := maxf(0.1, float(_args.get("preflight", "1.0")))
			await get_tree().create_timer(wait).timeout
			var atk := _units[_attacker.selected] if _attacker.selected >= 0 and _attacker.selected < _units.size() else null
			var tgt := _units[_target.selected] if _target.selected >= 0 and _target.selected < _units.size() else null
			var reason := _status.text.replace("\n", " | ")
			print("[vfx_room] preflight result=%s attacker=%s attacker_side=%s target=%s target_side=%s move=%s reason=%s" % [
				"ok" if _fired else "fail",
				atk.name if atk != null else "?",
				("player" if atk.is_player else "enemy") if atk != null else "?",
				tgt.name if tgt != null else "?",
				("player" if tgt.is_player else "enemy") if tgt != null else "?",
				_move.get_item_text(_move.selected) if _move.item_count > 0 else "?",
				reason,
			])
			_quit_flag = true
			get_tree().quit()
			return
		_fire()


## Attacker by role/side (D-235), never by a fixed index: player/ally = first alive ally;
## enemy = first alive enemy; any other value keeps the old name-prefix selection.
func _select_attacker_arg() -> bool:
	var arg := String(_args.get("attacker", ""))
	if arg == "":
		return true
	if arg == "player" or arg == "ally" or arg == "enemy":
		var want_player := arg != "enemy"
		for i in _units.size():
			var u := _units[i] as Combatant
			if u.is_player == want_player and u.is_alive():
				_attacker.select(i)
				return true
		return false
	return _select_by_name(_attacker, arg)


func _select_by_name(opt: OptionButton, name: String) -> bool:
	if name == "":
		return true
	for i in opt.item_count:
		if opt.get_item_text(i).to_lower().begins_with(name.to_lower()):
			opt.select(i)
			return true
	return false


## Prints the same fail-fast line used by the recorder and quits only in preflight mode.
## Outside preflight it leaves the room open for the operator to fix the fields.
func _preflight_fail(reason: String) -> void:
	_status.text = reason
	print("[vfx_room] ", reason)
	if _quit_flag and not _args.has("preflight"):
		get_tree().quit(1)
	if _args.has("preflight"):
		print("[vfx_room] preflight result=fail attacker=? attacker_side=? target=? target_side=? move=%s reason=%s" % [
			String(_args.get("move", "")), reason])
		get_tree().quit()


# --- Entrada -------------------------------------------------------------------------


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not (event as InputEventKey).pressed or (event as InputEventKey).echo:
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_9:
		var idx := key - KEY_1
		if idx < _move.item_count:
			_move.select(idx)
			_clear_scenario()
			_fire()
		return
	match key:
		KEY_ENTER, KEY_KP_ENTER:
			_fire()
		KEY_L:
			_loop.button_pressed = not _loop.button_pressed
		KEY_BRACKETLEFT:
			_step_scenario(-1)
		KEY_BRACKETRIGHT:
			_step_scenario(1)
		KEY_P:
			_toggle_pause()
		KEY_N:
			_step_one()
		KEY_Q:
			_cycle_target(-1)
		KEY_E:
			_cycle_target(1)
		KEY_R:
			_reload_vfx()
		KEY_F2:
			_panel_user_hidden = not _panel_user_hidden
			_panel.visible = not _panel_user_hidden


func _unhandled_input(event: InputEvent) -> void:
	if _cam_mode == null or _cam_mode.selected != 3:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_dist = maxf(_orbit_dist * 0.9, 2.0)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_dist = minf(_orbit_dist * 1.1, 80.0)
	elif event is InputEventMouseMotion and _dragging:
		var rel := (event as InputEventMouseMotion).relative
		_orbit_yaw -= rel.x * 0.006
		_orbit_pitch = clampf(_orbit_pitch + rel.y * 0.006, -0.2, 1.4)


## --clean (D-965): proof frames without the battle HUD and the arena props (pillars, walls, debris, dust); the
## floor, lights and units stay. Only this debug room; the game is untouched.
func _apply_clean() -> void:
	if not _args.has("clean") or _bs == null:
		return
	if _bs.hud != null:
		_bs.hud.visible = false
	for n in _bs.get_children():
		if n.get_script() == preload("res://scripts/combat/battle_arena.gd"):
			for v in n.find_children("*", "GeometryInstance3D", true, false):
				var gi := v as GeometryInstance3D
				if gi is MeshInstance3D and (gi as MeshInstance3D).get_aabb().size.y < 0.6:
					continue  # floor tiles and slabs stay
				gi.visible = false


func _process(delta: float) -> void:
	_clock += delta
	_apply_clean()
	_enforce_time()
	if _immortal != null and _immortal.button_pressed and _hp_slider.value >= 100.0:
		for u in _units:
			if u.hp < u.max_hp * 0.55 and not u.has_meta("room_no_heal"):
				u.set_hp_instant(u.max_hp)
	if _cam_mode != null and _cam_mode.selected == 3 and not _units.is_empty():
		_update_orbit()
	elif _cam_mode != null and _cam_mode.selected == 4 and not _units.is_empty():
		_update_frame_cam(false)
	if _cam_mode != null and _cam_mode.selected == 5 and not _units.is_empty():
		_update_macro_cam()
	_auto_hide_panel()
	_layout_view()
	_sweep_layers()
	_tick_vfx_analysis(delta)
	if _fired and not _paused:
		_tick_from_fire += 1
		if _step_ticks_limit > 0 and _tick_from_fire >= _step_ticks_limit:
			_step_ticks_limit = -1
			_toggle_pause()
			print("[vfx_room] Pausado em step-ticks=%d (t=%.3f)" % [_tick_from_fire, _clock - _fire_clock])
			_emit_summary_json()
			if _quit_flag:
				get_tree().quit()
			return
	if _pause_due >= 0.0 and _clock >= _pause_due and not _paused:
		_pause_due = -1.0
		_toggle_pause()
		var pk := String(PAUSE_KEYS[_pause_event.selected])
		var cur_sk := _current_skill()
		var f_txt := cur_sk.visual_phase_text(pk) if cur_sk != null else ""
		_status.text = "Pausado: %s (t=%.3f)." % [PAUSE_LABELS[_pause_event.selected], _clock - _fire_clock]
		if f_txt != "":
			print("[vfx_room] FICHA_FASE [%s] (%s): %s" % [pk, cur_sk.display_name, f_txt])
			if _ficha_label != null:
				_ficha_label.text = "FICHA VISUAL [%s]: %s" % [pk.to_upper(), f_txt]
		print("[vfx_room] ", _status.text)
		await _take_shot()
		_emit_summary_json()
		if _quit_flag and (_shot_path == "" or _shot_taken):
			get_tree().quit()
	_tick_record()
	_run_schedule()
	if _battle == null or not _battle.running or not _fired:
		return
	if _busy() == false:  # (wind-up também conta como ação em curso)
		_idle_for += delta / maxf(Engine.time_scale, 0.01)
		if not _audit_done and _idle_for >= 0.35:
			_audit_done = true
			_audit_vfx_leaks()
		if _loop.button_pressed and _idle_for >= LOOP_GAP and _rec.is_empty():
			_fire()
		elif _quit_flag and _idle_for >= LOOP_GAP and _rec.is_empty() and _rec_request <= 0.0 and (_shot_path == "" or _shot_taken):
			_emit_summary_json()
			get_tree().quit()
	else:
		_idle_for = 0.0


## O jogo devolve Engine.time_scale a 1.0 sozinho (câmera lenta, hit-stop): a sala reaplica a velocidade.
func _enforce_time() -> void:
	if _speed == null:
		return
	if _paused:
		if _step > 0:
			_step -= 1
			Engine.time_scale = 1.0  # deixa passar exatamente este quadro
		else:
			Engine.time_scale = 0.0
		return
	if _macro_slow_until > 0.0 and _clock >= _macro_slow_until:
		_macro_slow_until = -1.0
		Engine.time_scale = _speed.value
	if _macro_slow_until > 0.0 and _clock < _macro_slow_until:
		Engine.time_scale = 0.05
		return
	if Engine.time_scale >= _speed.value * 0.5:
		Engine.time_scale = _speed.value


func _toggle_pause() -> void:
	_paused = not _paused
	_step = 0
	_pause_btn.text = "▶ Continuar (P)" if _paused else "⏸ Pausar (P)"
	if not _paused:
		Engine.time_scale = _speed.value


func _step_one() -> void:
	if not _paused:
		_toggle_pause()
	_step = 1


# --- Eventos do combate: log das fases e pausa automática --------------------------------


func _connect_events() -> void:
	_battle.attack_telegraphed.connect(func(inc) -> void:
		_note("CARGA começa: %s %s -> %s  (wind-up %.2fs)" % [inc.attacker.name, inc.label, inc.target.name, inc.total_windup])
		_record_phase("windup")
		_event("windup"))
	_battle.attack_resolved.connect(func(inc) -> void:
		_note("CARGA termina (release): %s" % inc.label)
		_record_phase("release")
		_event("release"))
	_battle.attack_phase.connect(func(inc, phase: int) -> void:
		var pname: String = Battle.Phase.keys()[phase]
		_note("FASE %s: %s" % [pname, inc.label])
		_record_phase(pname.to_lower())
		if phase == Battle.Phase.TRAVEL:
			_event("travel")
		elif phase == Battle.Phase.STRIKE:
			if _cam_mode != null and _cam_mode.selected == 5:
				_macro_slow_until = _clock + 0.025
			_event("strike")
		elif phase == Battle.Phase.RETURN:
			_event("return"))
	_battle.hit_resolved.connect(func(att: Combatant, tgt: Combatant, _el: int, info: Dictionary) -> void:
		_note("IMPACTO: %s -> %s  dano=%s esquiva=%s crítico=%s fraqueza=%s" % [att.name, tgt.name, str(info.get("dmg", 0)), str(info.get("evaded", false)), str(info.get("crit", false)), str(info.get("weak", false))])
		_record_phase("impact")
		_record_hit_telemetry(att, tgt, info)
		if _cam_mode != null and _cam_mode.selected == 5:
			_macro_slow_until = _clock + 0.025
		_event("impact"))
	_battle.attack_cancelled.connect(func(inc) -> void: _note("CANCELADO: %s" % inc.label))
	_battle.battle_ended.connect(func(won: bool) -> void:
		_note("BATALHA TERMINOU: %s" % ("vitória" if won else "derrota"))
		if _quit_flag:
			await get_tree().create_timer(1.2).timeout
			_emit_summary_json()
			get_tree().quit())
	_bs.fx.child_entered_tree.connect(func(n: Node) -> void:
		if not String(n.name).begins_with("@"):
			_note("VFX nasce: %s" % n.name)
		if _telemetry.has("vfx_spawns"):
			(_telemetry["vfx_spawns"] as Array).append(String(n.name)))


func _event(kind: String) -> void:
	if PAUSE_KEYS[_pause_event.selected] == kind:
		_pause_due = _clock + _pause_delay.value


func _note(text: String) -> void:
	_log.append("t=%7.3f  %s" % [_clock - _fire_clock, text])
	var tail := _log.slice(maxi(_log.size() - 7, 0))
	_log_label.text = "\n".join(tail)


func _save_log() -> void:
	if _log.is_empty():
		return
	var text := "\n".join(_log) + "\n"
	for path in ["user://vfx_room_log.txt", String(_args.get("log", ""))]:
		if path == "":
			continue
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(text)


# --- Gravação de quadros ----------------------------------------------------------------


## Test-only scale probe: shrink/grow every model so its visible body mesh reads target_h.
## Does not change the game scene; used to compare "before" and "after" in the VFX room.
func _apply_scale_test(target_h: float) -> void:
	if target_h <= 0.05:
		return
	for c in _units:
		var model: Node3D = _bs.models.get(c)
		if model == null or not is_instance_valid(model):
			continue
		var h := _visible_body_height(model)
		if h > 0.05:
			model.scale = model.scale * (target_h / h)
			if _bs.fx != null and _bs.fx._base_scale.has(c):
				_bs.fx._base_scale[c] = model.scale


func _visible_body_height(model: Node3D) -> float:
	var lo := INF
	var hi := -INF
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var low := String(mi.name).to_lower()
		if low in ["burstring", "readyring"] or low.begins_with("guard") or low.begins_with("shield") or low.begins_with("wmodel"):
			continue
		var b: AABB = mi.global_transform * mi.get_aabb()
		lo = minf(lo, b.position.y)
		hi = maxf(hi, b.position.y + b.size.y)
	if hi <= lo:
		return 0.0
	return hi - lo


func _start_record(seconds: float, step: float) -> void:
	var a := _units[_attacker.selected]
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "")
	var base := String(_args.get("out", ""))
	if base == "":
		base = "res://test_captures/vfx_room/%s_%s_%s" % [a.name, _move.get_item_text(_move.selected).replace(" ", ""), stamp]
	var abs_dir := ProjectSettings.globalize_path(base)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	_rec = {"dir": abs_dir, "step": maxf(step, 0.005), "length": seconds, "next": _clock, "t0": _clock, "idx": 0, "thumbs": [], "busy": 0}
	_panel.visible = false
	_status.text = "Gravando %.1fs a cada %.3fs em %s" % [seconds, step, abs_dir]


func _tick_record() -> void:
	if _rec.is_empty():
		return
	var t: float = _clock - float(_rec["t0"])
	if _clock + 0.00001 >= float(_rec["next"]) and t <= float(_rec["length"]) + 0.0001:
		_rec["next"] = float(_rec["next"]) + float(_rec["step"])
		_grab_frame(t)
	elif t > float(_rec["length"]) and int(_rec["busy"]) == 0:
		_finish_record()


func _grab_frame(t: float) -> void:
	_rec["busy"] = int(_rec["busy"]) + 1
	var idx: int = _rec["idx"]
	_rec["idx"] = idx + 1
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/f_%03d_t%.3f.png" % [_rec["dir"], idx, t])
	var th := img.duplicate() as Image
	th.convert(Image.FORMAT_RGB8)
	th.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	(_rec["thumbs"] as Array).append(th)
	_rec["busy"] = int(_rec["busy"]) - 1


func _finish_record() -> void:
	var thumbs: Array = _rec["thumbs"]
	var dir: String = _rec["dir"]
	if not thumbs.is_empty():
		var cols := 6
		var rows := int(ceil(float(thumbs.size()) / float(cols)))
		var sheet := Image.create(cols * 320, rows * 180, false, Image.FORMAT_RGB8)
		for i in thumbs.size():
			sheet.blit_rect(thumbs[i] as Image, Rect2i(0, 0, 320, 180), Vector2i((i % cols) * 320, (i / cols) * 180))
		sheet.save_png(dir + "/sheet.png")
	var count := thumbs.size()
	_rec = {}
	_rec_request = 0.0
	_panel.visible = true
	_note("GRAVAÇÃO: %d quadros em %s" % [count, dir])
	var logpath: String = String(_args.get("log", ""))
	if logpath == "":
		_args["log"] = dir + "/log.txt"
	_save_log()
	_status.text = "Gravação pronta: %d quadros + sheet.png em %s" % [count, dir]
	if _quit_flag:
		get_tree().quit()


func _take_shot() -> void:
	if _shot_path == "" or _shot_taken:
		return
	_shot_taken = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(_shot_path) if _shot_path.begins_with("res://") else _shot_path
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	_note("FOTO: %s" % path)
	if _args.has("diff-with"):
		_compare_images(path, String(_args["diff-with"]))
	if _quit_flag:
		_emit_summary_json()
		get_tree().quit()


# --- Camadas ligáveis --------------------------------------------------------------------


func _layer_of(n: Node) -> String:
	if n is AbraCanvas:
		return "linhas"
	if n is CPUParticles3D or n is GPUParticles3D:
		return "particulas"
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override is ShaderMaterial:
			return "shaders"
		if mi.mesh is QuadMesh:
			return "sprites"
		return "malhas"
	return ""


func _sweep_layers() -> void:
	if _bs == null or _layer_checks.is_empty():
		return
	if _solo_node_pattern != "" or _mute_node_pattern != "":
		for ch in _bs.fx.get_children():
			var cname := String(ch.name).to_lower()
			if cname in ["debugfreecam3d", "debuggizmos3d"] or cname.begins_with("fxlane"):
				continue
			if ch is Node3D:
				if _solo_node_pattern != "":
					(ch as Node3D).visible = _solo_node_pattern in cname
				elif _mute_node_pattern != "" and _mute_node_pattern in cname:
					(ch as Node3D).visible = false
	var off: Array[String] = []
	for k in LAYER_KEYS:
		if not (_layer_checks[k] as CheckButton).button_pressed:
			off.append(k)
	if off.is_empty() and _hidden_prev.is_empty():
		return
	for n in _bs.fx.find_children("*", "VisualInstance3D", true, false):
		var layer := _layer_of(n)
		if layer == "":
			continue
		if layer in off:
			(n as VisualInstance3D).visible = false
			_hidden_prev[n.get_instance_id()] = true
		elif _hidden_prev.has(n.get_instance_id()):
			(n as VisualInstance3D).visible = true
			_hidden_prev.erase(n.get_instance_id())
	if off.is_empty():
		_hidden_prev.clear()


# --- Recarga do VFX ----------------------------------------------------------------------


## Recompila os scripts e shaders de VFX do disco e repete o último golpe (sem fechar a janela).
func _reload_vfx() -> void:
	var paths: Array[String] = []
	for d in RELOAD_DIRS:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				paths.append(d + f)
	paths.append_array(RELOAD_FILES)
	var failed: Array[String] = []
	for p in paths:
		var s := load(p) as GDScript
		if s == null:
			continue
		s.source_code = FileAccess.get_file_as_string(p)
		if s.reload(true) != OK:
			failed.append(p.get_file())
	var shaders := 0
	for f in DirAccess.get_files_at("res://shaders/"):
		if f.ends_with(".gdshader"):
			var sh := load("res://shaders/" + f) as Shader
			if sh != null:
				sh.code = FileAccess.get_file_as_string("res://shaders/" + f)
				shaders += 1
	AbraMoveVfx._tex_cache.clear()
	VfxLib._tex.clear()
	_note("RECARGA: %d scripts, %d shaders%s" % [paths.size(), shaders, ("  FALHOU: " + ", ".join(failed)) if not failed.is_empty() else ""])
	_status.text = "VFX recarregado (%d scripts, %d shaders)%s" % [paths.size(), shaders, ("  FALHOU: " + ", ".join(failed)) if not failed.is_empty() else ""]
	if failed.is_empty() and _fired:
		_fire()


# --- Painel --------------------------------------------------------------------------


func _build_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_panel = PanelContainer.new()
	# Largo e com abas: tudo cabe sem corte, e a altura se ajusta ao conteúdo (não cobre o campo inteiro).
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -PANEL_W - 8.0
	_panel.offset_right = -8.0
	_panel.offset_top = 8.0
	_panel.offset_bottom = -8.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.1, 0.82)
	sb.border_color = Color("d7fd6a")
	sb.border_width_top = 4
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(_panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	_panel.add_child(root)
	var head := HBoxContainer.new()
	root.add_child(head)
	var title := Label.new()
	title.text = "SALA DE VFX  (F2 esconde)"
	title.add_theme_color_override("font_color", Color("d7fd6a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_autohide = CheckButton.new()
	_autohide.text = "Ocultar no golpe"
	_autohide.button_pressed = false  # a cena já fica ao lado do painel; ligue para esconder o painel no golpe
	head.add_child(_autohide)
	var side := Button.new()
	side.text = "⇄ lado"
	side.tooltip_text = "Troca o painel de lado (esquerda/direita)"
	side.pressed.connect(_flip_panel_side)
	head.add_child(side)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(PANEL_W - 20.0, 0)
	_status.add_theme_font_size_override("font_size", 12)
	_status.text = "Carregando a batalha..."
	root.add_child(_status)
	# Barra de transporte: sempre visível, o que mais se usa.
	var transport := HBoxContainer.new()
	transport.add_theme_constant_override("separation", 4)
	root.add_child(transport)
	var rep_btn := Button.new()
	rep_btn.text = "↻ Repetir (Enter)"
	rep_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rep_btn.pressed.connect(_fire)
	transport.add_child(rep_btn)
	_pause_btn = Button.new()
	_pause_btn.text = "⏸ Pausar (P)"
	_pause_btn.pressed.connect(_toggle_pause)
	transport.add_child(_pause_btn)
	var step_btn := Button.new()
	step_btn.text = "⏭ 1 quadro (N)"
	step_btn.pressed.connect(_step_one)
	transport.add_child(step_btn)
	_speed_quick = OptionButton.new()
	for sp in ["0.10x", "0.25x", "0.50x", "1.00x"]:
		_speed_quick.add_item(sp)
	_speed_quick.select(3)
	_speed_quick.item_selected.connect(func(i: int) -> void: _speed.value = [0.1, 0.25, 0.5, 1.0][i])
	transport.add_child(_speed_quick)
	# Duas vistas: a lista de cenários (padrão) e os ajustes finos.
	var switch := HBoxContainer.new()
	root.add_child(switch)
	var view_group := ButtonGroup.new()
	for vd in [["Cenários", false], ["Ajustes", true]]:
		var vb := Button.new()
		vb.text = vd[0]
		vb.toggle_mode = true
		vb.button_group = view_group
		vb.button_pressed = not vd[1]
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.pressed.connect(_show_view.bind(vd[1]))
		switch.add_child(vb)
	_scn_view = VBoxContainer.new()
	_scn_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scn_view.add_theme_constant_override("separation", 6)
	root.add_child(_scn_view)
	_scn_search = LineEdit.new()
	_scn_search.placeholder_text = "Buscar cenário (choque, evade, morre, guard...)"
	_scn_search.clear_button_enabled = true
	_scn_search.text_changed.connect(func(_t: String) -> void: _rebuild_scn_list())
	_scn_view.add_child(_scn_search)
	var filter_row := HBoxContainer.new()
	_scn_view.add_child(filter_row)
	_scn_group_opt = OptionButton.new()
	_scn_group_opt.add_item("Todos os grupos")
	var seen_groups: Array[String] = []
	for sc0 in VfxRoomScenarios.SCENARIOS:
		if not (String(sc0["g"]) in seen_groups):
			seen_groups.append(String(sc0["g"]))
			_scn_group_opt.add_item(String(sc0["g"]))
	_scn_group_opt.item_selected.connect(func(i: int) -> void:
		_scn_group = "Todos" if i == 0 else _scn_group_opt.get_item_text(i)
		_rebuild_scn_list())
	filter_row.add_child(_scn_group_opt)
	_scn_count = Label.new()
	_scn_count.add_theme_font_size_override("font_size", 12)
	_scn_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_row.add_child(_scn_count)
	_scn_items = ItemList.new()
	_scn_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scn_items.custom_minimum_size = Vector2(0, 180)
	_scn_items.item_selected.connect(_on_scn_selected)
	_scn_items.item_clicked.connect(func(i: int, _pos: Vector2, btn: int) -> void:
		if btn == MOUSE_BUTTON_LEFT and i < _scn_ids.size() and _scn_ids[i] != "":
			_run_scenario(_scn_ids[i]))
	_scn_items.item_activated.connect(func(i: int) -> void:
		if i < _scn_ids.size() and _scn_ids[i] != "":
			_run_scenario(_scn_ids[i]))
	_scn_view.add_child(_scn_items)
	_scn_detail = Label.new()
	_scn_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scn_detail.custom_minimum_size = Vector2(PANEL_W - 20.0, 64)
	_scn_detail.add_theme_font_size_override("font_size", 12)
	_scn_detail.text = "Clique num cenário para rodar (setas escolhem, Enter roda, [ e ] trocam de cenário)."
	_scn_view.add_child(_scn_detail)
	var tabs := TabContainer.new()
	_tabs = tabs
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(PANEL_W - 20.0, 200)
	tabs.visible = false
	root.add_child(tabs)
	_log_label = Label.new()  # as fases do último golpe, sempre à vista
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.custom_minimum_size = Vector2(PANEL_W - 20.0, 92)
	_log_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_log_label.add_theme_font_size_override("font_size", 11)
	root.add_child(_log_label)

	# --- Aba Moves: o que se usa a cada disparo ---
	var box := _page(tabs, "Moves")
	_attacker = _option(box, "Atacante")
	_attacker.item_selected.connect(func(_i: int) -> void: _fill_moves())
	_target = _option(box, "Alvo  (Q/E troca)")
	_section(box, "MOVES  (1..9)")
	_move_grid = GridContainer.new()
	_move_grid.columns = 3
	_move_grid.add_theme_constant_override("h_separation", 4)
	_move_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(_move_grid)
	_move = OptionButton.new()  # guarda a seleção (os botões acima escolhem e disparam)
	_move.visible = false
	box.add_child(_move)
	var again := Button.new()
	again.text = "Repetir o último  (Enter)"
	again.pressed.connect(_fire)
	box.add_child(again)
	_loop = CheckButton.new()
	_loop.text = "Repetir em loop  (L)"
	box.add_child(_loop)
	_force = _option(box, "Resultado do golpe")
	for l in FORCE_LABELS:
		_force.add_item(l)
	_speed_label = Label.new()
	box.add_child(_speed_label)
	_speed = HSlider.new()
	_speed.min_value = 0.05
	_speed.max_value = 1.5
	_speed.step = 0.05
	_speed.value = 1.0
	_speed.value_changed.connect(_on_speed)
	box.add_child(_speed)
	_on_speed(1.0)

	# --- Aba Cenário: ataques simultâneos, wind-up, estado ---
	box = _page(tabs, "Cenário")
	_section(box, "ATAQUE 2 (sai junto com o da aba Moves)")
	_a2_on = CheckButton.new()
	_a2_on.text = "Ligar o segundo ataque"
	box.add_child(_a2_on)
	_attacker2 = _unit_option(box, "Atacante 2")
	_attacker2.item_selected.connect(func(_i: int) -> void: _fill_moves2())
	var l2 := Label.new()
	l2.text = "Move 2"
	box.add_child(l2)
	_move2 = OptionButton.new()
	box.add_child(_move2)
	_target2 = _unit_option(box, "Alvo 2")
	_delay2_label = Label.new()
	box.add_child(_delay2_label)
	_delay2 = HSlider.new()
	_delay2.min_value = -3.0
	_delay2.max_value = 3.0
	_delay2.step = 0.05
	_delay2.value_changed.connect(func(v: float) -> void:
		_delay2_label.text = "Disparo do ataque 2: %+.2f s  (negativo = sai antes do ataque 1)" % v)
	box.add_child(_delay2)
	_delay2_label.text = "Disparo do ataque 2: +0.00 s  (negativo = sai antes do ataque 1)"
	_section(box, "TEMPO, WIND-UP E ESTADO (valem para os dois ataques)")
	_delay1_label = Label.new()
	box.add_child(_delay1_label)
	_delay1 = HSlider.new()
	_delay1.min_value = 0.0
	_delay1.max_value = 4.0
	_delay1.step = 0.05
	_delay1.value_changed.connect(func(v: float) -> void: _delay1_label.text = "Os ataques saem %.2f s depois do disparo" % v)
	box.add_child(_delay1)
	_delay1_label.text = "Os ataques saem 0.00 s depois do disparo"
	_windup_label = Label.new()
	box.add_child(_windup_label)
	_windup_ovr = HSlider.new()
	_windup_ovr.min_value = 0.0
	_windup_ovr.max_value = 3.0
	_windup_ovr.step = 0.05
	_windup_ovr.value_changed.connect(func(v: float) -> void:
		_windup_label.text = "Wind-up: do Move" if v <= 0.0 else "Wind-up forçado: %.2f s" % v)
	box.add_child(_windup_ovr)
	_windup_label.text = "Wind-up: do Move"
	_atb_label = Label.new()
	box.add_child(_atb_label)
	_atb_slider = HSlider.new()
	_atb_slider.min_value = 0.0
	_atb_slider.max_value = 6.0
	_atb_slider.step = 1.0
	_atb_slider.value = 5.0
	_atb_slider.value_changed.connect(func(v: float) -> void: _atb_label.text = "ATB de todos ao disparar: %d" % int(v))
	box.add_child(_atb_slider)
	_atb_label.text = "ATB de todos ao disparar: 5"
	_hp_label = Label.new()
	box.add_child(_hp_label)
	_hp_slider = HSlider.new()
	_hp_slider.min_value = 1.0
	_hp_slider.max_value = 100.0
	_hp_slider.step = 1.0
	_hp_slider.value = 100.0
	_hp_slider.value_changed.connect(func(v: float) -> void:
		_hp_label.text = "Vida de todos ao disparar: %d%%  (abaixo de 100 desliga o 'imortal')" % int(v))
	box.add_child(_hp_slider)
	_hp_label.text = "Vida de todos ao disparar: 100%  (abaixo de 100 desliga o 'imortal')"
	_guard_target = CheckButton.new()
	_guard_target.text = "Alvo do ataque 1 abre Guard antes"
	box.add_child(_guard_target)

	# --- Aba Ações: evade, morte do alvo, buffs e status ---
	box = _page(tabs, "Ações")
	_section(box, "EVADE MANUAL (de quem for atingido)")
	_evade_unit = _unit_option(box, "Quem desvia")
	var le := Label.new()
	le.text = "Quando"
	box.add_child(le)
	_evade_mode = OptionButton.new()
	for m in ["Não desvia", "Desvia (últimos 0,25 s do golpe)"]:
		_evade_mode.add_item(m)
	box.add_child(_evade_mode)
	_evade_label = Label.new()
	box.add_child(_evade_label)
	_evade_at = HSlider.new()
	_evade_at.min_value = 0.0
	_evade_at.max_value = 6.0
	_evade_at.step = 0.05
	_evade_at.value_changed.connect(func(v: float) -> void: _evade_label.text = "Só tenta depois de t = %.2f s do disparo" % v)
	box.add_child(_evade_at)
	_evade_label.text = "Só tenta depois de t = 0.00 s do disparo"
	_section(box, "MORTE DE PROPÓSITO (testa o alvo morrer na ação)")
	_kill_on = CheckButton.new()
	_kill_on.text = "Matar uma unidade durante o ataque"
	box.add_child(_kill_on)
	_kill_unit = _unit_option(box, "Quem morre")
	_kill_label = Label.new()
	box.add_child(_kill_label)
	_kill_at = HSlider.new()
	_kill_at.min_value = 0.0
	_kill_at.max_value = 6.0
	_kill_at.step = 0.05
	_kill_at.value = 0.5
	_kill_at.value_changed.connect(func(v: float) -> void: _kill_label.text = "Morre em t = %.2f s (wind-up 1,5 s: 0,5 = no wind-up; 1,9 = na corrida)" % v)
	box.add_child(_kill_at)
	_kill_label.text = "Morre em t = 0.50 s (wind-up 1,5 s: 0,5 = no wind-up; 1,9 = na corrida)"
	_section(box, "BUFFS E STATUS (agora, na unidade escolhida)")
	_buff_unit = _unit_option(box, "Unidade")
	_buff_stat = OptionButton.new()
	for m in ["ATK (ataque)", "DEF (defesa)", "SPD (velocidade)"]:
		_buff_stat.add_item(m)
	box.add_child(_buff_stat)
	var brow := HBoxContainer.new()
	box.add_child(brow)
	for bd in [["+1", 1], ["−1", -1]]:
		var bb := Button.new()
		bb.text = bd[0]
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bb.pressed.connect(_buff.bind(bd[1]))
		brow.add_child(bb)
	var srow := GridContainer.new()
	srow.columns = 3
	box.add_child(srow)
	for sd in [["Queimar", "burn"], ["Atordoar 2s", "stun"], ["Cegar 3s", "blind"], ["Guard", "guard"], ["Escudo 18", "shield"], ["Imun. Mágica 10s", "magic_immune"], ["ATB +1", "atb_add"], ["ATB -1", "atb_sub"], ["ATB cheio", "atb_full"], ["ATB zerado", "atb_zero"], ["Limpar", "clear"]]:
		var sbt := Button.new()
		sbt.text = sd[0]
		sbt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sbt.pressed.connect(_status_effect.bind(sd[1]))
		srow.add_child(sbt)

	# D-980: apply a status to one or more characters at once.
	_section(box, "STATUS EM VÁRIOS (marque e aplique agora)")
	_multi_box = GridContainer.new()
	_multi_box.columns = 2
	box.add_child(_multi_box)
	var mrow := GridContainer.new()
	mrow.columns = 3
	box.add_child(mrow)
	for md in [["STUN 4s", "stun4"], ["Burn", "burn"], ["Blind 3s", "blind"], ["ATK +1", "b:atk:1"], ["ATK −1", "b:atk:-1"], ["DEF +1", "b:def:1"], ["DEF −1", "b:def:-1"], ["SPD +1", "b:speed:1"], ["SPD −1", "b:speed:-1"], ["Limpar", "clear"]]:
		var mb := Button.new()
		mb.text = md[0]
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.pressed.connect(_status_many.bind(md[1]))
		mrow.add_child(mb)

	_section(box, "AGENDAR UMA AÇÃO (vale em todo disparo até limpar)")
	_act_unit = _unit_option(box, "Quem")
	var lk := Label.new()
	lk.text = "Ação"
	box.add_child(lk)
	_act_kind = OptionButton.new()
	for m in ["Guard", "Evade (tenta até a janela final)", "Evade (aperta uma vez)", "Passo à frente", "Passo atrás", "Atordoar 2s", "Queimar", "Cegar 3s", "ATK +1", "DEF −1", "SPD +1", "Matar"]:
		_act_kind.add_item(m)
	box.add_child(_act_kind)
	_act_label = Label.new()
	box.add_child(_act_label)
	_act_at = HSlider.new()
	_act_at.min_value = 0.0
	_act_at.max_value = 8.0
	_act_at.step = 0.05
	_act_at.value_changed.connect(func(v: float) -> void: _act_label.text = "Em t = %.2f s depois do disparo" % v)
	box.add_child(_act_at)
	_act_label.text = "Em t = 0.00 s depois do disparo"
	var arow := HBoxContainer.new()
	box.add_child(arow)
	var abtn := Button.new()
	abtn.text = "Agendar"
	abtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	abtn.pressed.connect(_schedule_manual)
	arow.add_child(abtn)
	var cbtn := Button.new()
	cbtn.text = "Limpar agenda"
	cbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cbtn.pressed.connect(_clear_manual)
	arow.add_child(cbtn)

	# --- Aba Posição: onde cada um fica, passos e mais inimigos ---
	box = _page(tabs, "Posição")
	_pos_unit = _unit_option(box, "Unidade")
	_pos_unit.item_selected.connect(func(_i: int) -> void: _sync_pos_sliders())
	_pos_label = Label.new()
	box.add_child(_pos_label)
	var lx := Label.new()
	lx.text = "x (esquerda/direita)"
	box.add_child(lx)
	_pos_x = HSlider.new()
	_pos_x.min_value = -30.0
	_pos_x.max_value = 30.0
	_pos_x.step = 0.5
	_pos_x.value_changed.connect(_on_pos_changed)
	box.add_child(_pos_x)
	var lz := Label.new()
	lz.text = "z (profundidade)"
	box.add_child(lz)
	_pos_z = HSlider.new()
	_pos_z.min_value = -60.0
	_pos_z.max_value = 20.0
	_pos_z.step = 0.5
	_pos_z.value_changed.connect(_on_pos_changed)
	box.add_child(_pos_z)
	var prow := HBoxContainer.new()
	box.add_child(prow)
	for sd in [["Passo atrás", -1], ["Passo à frente", 1]]:
		var sb2 := Button.new()
		sb2.text = sd[0]
		sb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb2.pressed.connect(_step_unit.bind(sd[1]))
		prow.add_child(sb2)
	_section(box, "MAIS UNIDADES")
	var add := Button.new()
	add.text = "Adicionar 2 inimigos parados (Gible)"
	add.pressed.connect(_add_test_enemies)
	box.add_child(add)
	var rem := Button.new()
	rem.text = "Remover os inimigos extras"
	rem.pressed.connect(_remove_test_enemies)
	box.add_child(rem)

	# --- Aba Tempo: pausa automática ---
	box = _page(tabs, "Tempo")
	_pause_event = _option(box, "Pausar sozinho em")
	for l in PAUSE_LABELS:
		_pause_event.add_item(l)
	_pause_delay_label = Label.new()
	box.add_child(_pause_delay_label)
	_pause_delay = HSlider.new()
	_pause_delay.min_value = 0.0
	_pause_delay.max_value = 0.6
	_pause_delay.step = 0.02
	_pause_delay.value = 0.12
	_pause_delay.value_changed.connect(func(v: float) -> void: _pause_delay_label.text = "Atraso depois do evento: %.2fs" % v)
	box.add_child(_pause_delay)
	_pause_delay_label.text = "Atraso depois do evento: 0.12s"

	# --- Aba Câmera: modo, foco e camadas ---
	box = _page(tabs, "Câmera")
	_cam_mode = OptionButton.new()
	for label in ["Do jogo (automática)", "Zoom no alvo", "Visão do atirador", "Órbita (mouse)", "Lateral (enquadra todos)", "Macro Impacto (FOV 15°, 0.05x)"]:
		_cam_mode.add_item(label)
	_cam_mode.item_selected.connect(func(_i: int) -> void: _apply_camera())
	box.add_child(_cam_mode)
	_focus = _option(box, "Foco da órbita")
	for label in ["Meio (atacante e alvo)", "Atacante", "Alvo"]:
		_focus.add_item(label)
	_section(box, "CAMADAS (marcado = visível)")
	for i in LAYER_KEYS.size():
		var cb := CheckButton.new()
		cb.text = LAYER_LABELS[i]
		cb.button_pressed = true
		box.add_child(cb)
		_layer_checks[LAYER_KEYS[i]] = cb

	# --- Aba Campo: distância, times e estado ---
	box = _page(tabs, "Campo")
	_dist_label = Label.new()
	box.add_child(_dist_label)
	_dist = HSlider.new()
	_dist.min_value = 14.0
	_dist.max_value = 40.0
	_dist.step = 1.0
	_dist.value = TEAM_DISTANCE
	_dist.value_changed.connect(_apply_distance)
	box.add_child(_dist)
	_apply_distance(TEAM_DISTANCE)
	_immortal = CheckButton.new()
	_immortal.text = "Todos imortais"
	_immortal.button_pressed = true
	box.add_child(_immortal)
	_mirror_btn = CheckButton.new()
	_mirror_btn.text = "Times espelhados"
	_mirror_btn.toggled.connect(func(on: bool) -> void: _load_battle(on))
	box.add_child(_mirror_btn)
	_channel = CheckButton.new()
	_channel.text = "Alvo canalizando (testa a interrupção)"
	box.add_child(_channel)
	_hud = CheckButton.new()
	_hud.text = "Esconder HUD do jogo"
	_hud.toggled.connect(func(on: bool) -> void:
		var ui := _bs.get_node_or_null("UI") as CanvasLayer
		if ui != null:
			ui.visible = not on)
	box.add_child(_hud)
	var reset := Button.new()
	reset.text = "Resetar combatentes"
	reset.pressed.connect(_reset)
	box.add_child(reset)

	# --- Aba Gravar: gravação de quadros e recarga ---
	box = _page(tabs, "Gravar")
	var rec_row := HBoxContainer.new()
	box.add_child(rec_row)
	var rec3 := Button.new()
	rec3.text = "Gravar 3s"
	rec3.pressed.connect(func() -> void:
		_rec_request = 3.0
		_rec_step = 0.05
		_fire())
	rec_row.add_child(rec3)
	var rec6 := Button.new()
	rec6.text = "Gravar 6s"
	rec6.pressed.connect(func() -> void:
		_rec_request = 6.0
		_rec_step = 0.1
		_fire())
	rec_row.add_child(rec6)
	var reload := Button.new()
	reload.text = "Recarregar VFX e repetir  (R)"
	reload.pressed.connect(_reload_vfx)
	box.add_child(reload)
	_build_vfx_analysis_tab(tabs)
	_ficha_label = Label.new()
	_ficha_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ficha_label.custom_minimum_size = Vector2(PANEL_W - 20.0, 36)
	_ficha_label.add_theme_font_size_override("font_size", 11)
	_ficha_label.add_theme_color_override("font_color", Color("62d8e7"))
	root.add_child(_ficha_label)
	_rebuild_scn_list()


## Uma página de aba: coluna rolável só na vertical, que ocupa toda a largura.
func _page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	return box


## Troca o painel entre a borda direita e a esquerda da tela.
func _flip_panel_side() -> void:
	var left := _panel.anchor_left < 0.5
	_panel.anchor_left = 1.0 if left else 0.0
	_panel.anchor_right = 1.0 if left else 0.0
	_panel.offset_left = (-PANEL_W - 8.0) if left else 8.0
	_panel.offset_right = -8.0 if left else PANEL_W + 8.0


func _section(parent: Control, caption: String) -> void:
	var l := Label.new()
	l.text = caption
	l.add_theme_color_override("font_color", Color("62d8e7"))
	parent.add_child(l)


## Seletor de unidade que se refaz sozinho quando as unidades mudam.
func _unit_option(parent: Control, caption: String) -> OptionButton:
	var o := _option(parent, caption)
	_unit_opts.append(o)
	return o


func _option(parent: Control, caption: String) -> OptionButton:
	var l := Label.new()
	l.text = caption
	parent.add_child(l)
	var o := OptionButton.new()
	parent.add_child(o)
	return o


func _fill_units() -> void:
	_attacker.clear()
	_target.clear()
	for c in _units:
		_attacker.add_item("%s  (%s)" % [c.name, "aliado" if c.is_player else "inimigo"])
		_target.add_item("%s  (%s)" % [c.name, "aliado" if c.is_player else "inimigo"])
	_attacker.select(1 if _mirror else 0)
	_target.select(0 if _mirror else mini(2, _units.size() - 1))
	for opt in _unit_opts:  # os outros seletores de unidade (ataque 2, evade, matar, buffs, posição)
		var keep := opt.selected
		opt.clear()
		for c in _units:
			opt.add_item("%s  (%s)" % [c.name, "aliado" if c.is_player else "inimigo"])
		opt.select(clampi(keep, 0, maxi(_units.size() - 1, 0)))
	if _attacker2 != null:  # padrão do ataque 2: o alvo do 1 ataca o atacante do 1 (choque)
		_attacker2.select(_target.selected)
		_target2.select(_attacker.selected)
	_fill_moves()
	_fill_multi()  # D-980
	_sync_pos_sliders()


func _fill_moves() -> void:
	_move.clear()
	for ch in _move_grid.get_children():
		ch.queue_free()
	var c := _units[_attacker.selected]
	for i in c.skills.size():
		var s := c.skills[i]
		_move.add_item(s.display_name)
		var b := Button.new()
		b.text = "%d  %s" % [i + 1, s.display_name]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			_move.select(i)
			_clear_scenario()
			_fire())
		_move_grid.add_child(b)
	if _move.item_count > 0:
		_move.select(0)
	_fill_moves2()


func _fill_moves2() -> void:
	if _move2 == null or _attacker2 == null or _attacker2.selected < 0 or _attacker2.selected >= _units.size():
		return
	var prev := _move2.get_item_text(_move2.selected) if _move2.item_count > 0 and _move2.selected >= 0 else "Tackle"
	_move2.clear()
	var c := _units[_attacker2.selected]
	for s in c.skills:
		_move2.add_item(s.display_name)
		if s.display_name == prev:
			_move2.select(_move2.item_count - 1)
	if _move2.selected < 0 and _move2.item_count > 0:
		_move2.select(0)


func _cycle_target(step: int) -> void:
	if _units.size() < 2:
		return
	var i := _target.selected
	for n in _units.size():
		i = (i + step + _units.size()) % _units.size()
		if i != _attacker.selected:
			break
	_target.select(i)
	_apply_camera()


func _on_speed(v: float) -> void:
	_speed_label.text = "Velocidade: %.2fx" % v
	if not _paused:
		Engine.time_scale = v


## Afasta ou aproxima o time inimigo (o jogo normal usa 30). Só mexe nos combatentes inimigos.
func _apply_distance(d: float) -> void:
	_dist_label.text = "Distância entre os times: %d" % int(d)
	if _bs == null or _units.is_empty():
		return
	var i := 0
	for c in _battle.enemies:
		_bs.fx.debug_move_home(c, Vector3(c.home.x, 0.0, -d - i * 2.0))
		i += 1


# --- Ações ---------------------------------------------------------------------------


func _reset() -> void:
	_sched.clear()
	if _killed or not _battle.running:
		await _reload_keep_selection()
		_status.text = "Batalha recarregada."
		return
	_battle.incoming.clear()
	for u in _units:
		u.set_hp_instant(u.max_hp)
		u.atb = _atb_slider.value
		if not _args.has("real-mp") and u.mp < 20:
			u.max_mp = maxi(u.max_mp, 20)  # debug room only: a unit built without attributes (DQT test party) has 0 MP
			u.mp = u.max_mp
		u.stun_timer = 0.0
		u.clear_burn()  # D-238
		u.blind_timer = 0.0
		u.engaged_with = null
	_status.text = "Combatentes restaurados."


## Reabre a batalha (depois de uma morte de propósito ou do fim do combate) mantendo as escolhas do painel.
func _reload_keep_selection() -> void:
	var keep := [_attacker.selected, _target.selected, _attacker2.selected, _target2.selected]
	await _load_battle(_mirror)
	var last := _units.size() - 1
	_attacker.select(clampi(keep[0], 0, last))
	_target.select(clampi(keep[1], 0, last))
	_attacker2.select(clampi(keep[2], 0, last))
	_target2.select(clampi(keep[3], 0, last))
	_fill_moves()


func _restore_weakness() -> void:
	for pair in _weak_added:
		(pair[0] as Combatant).weaknesses.erase(pair[1])
	_weak_added.clear()


func _fire() -> void:
	if _units.is_empty():
		return
	if _killed or not _battle.running or _busy():
		await _reload_keep_selection()  # alguém morreu, o combate acabou ou ainda há golpe em curso: recomeça limpo
	if _scn_on:
		_prepare_world()  # a recarga tira os inimigos extras: o cenário os recoloca
		_apply_scenario_selections()
	var a := _units[_attacker.selected]
	var t := _units[_target.selected]
	var skill := _shaped(_find_skill(a, _move.get_item_text(_move.selected)))
	if skill == null:
		_status.text = "%s não tem o Move escolhido." % a.name
		print("[vfx_room] ", _status.text)
		return
	if a == t and not skill.is_friendly:  # (Moves amigáveis podem ter o próprio atacante como alvo)
		_status.text = "Atacante e alvo precisam ser diferentes."
		return
	var a2: Combatant = null
	var t2: Combatant = null
	var skill2: Skill = null
	if _a2_on.button_pressed:
		a2 = _units[_attacker2.selected]
		t2 = _units[_target2.selected]
		if _move2.item_count > 0:
			skill2 = _shaped(_find_skill(a2, _move2.get_item_text(_move2.selected)))
		if skill2 == null or (a2 == t2 and not skill2.is_friendly):
			_status.text = "Ataque 2: atacante e alvo precisam ser diferentes e ter Move."
			return
	_sched.clear()
	_polls.clear()
	for u in _units:
		u.set_hp_instant(1 if _hp_slider.value <= 1.0 else maxi(1, roundi(u.max_hp * _hp_slider.value / 100.0)))
		u.atb = _atb_slider.value
		if not _args.has("real-mp") and u.mp < 20:
			u.max_mp = maxi(u.max_mp, 20)  # debug room only: a unit built without attributes (DQT test party) has 0 MP
			u.mp = u.max_mp
		u.stun_timer = 0.0
		u.blind_timer = 0.0
		u.clear_burn()  # D-238
		u.engaged_with = null
	_restore_weakness()
	# Debug room only (D-978 review): --stun=always|never forces a chance-based status through the LUK difference.
	if String(_args.get("stun", "")) == "always":
		a.luk = 1000
		t.luk = 0
	elif String(_args.get("stun", "")) == "never":
		a.luk = 0
		t.luk = 1000
	_battle.debug_roll = int(FORCE_ROLL[_force.selected])
	if _force.selected == 4 and not (skill.element in t.weaknesses):
		t.weaknesses.append(skill.element)
		_weak_added.append([t, skill.element])
	_apply_camera()
	_fire_clock = _clock
	_log.clear()
	_pause_due = -1.0
	_shot_taken = false
	if _paused:
		_toggle_pause()
	var channeling := ""
	if _channel != null and _channel.button_pressed:
		channeling = _start_channel(t, a)
	if _guard_target.button_pressed:
		if not _battle.use_guard(t):
			_note("GUARD recusado para %s: %s" % [t.name, _battle.guard_block_reason(t)])
	var d := _delay2.value if a2 != null else 0.0
	var base := _delay1.value
	var ok := _queue_attack(base + maxf(-d, 0.0), a, skill, t)
	var ok2 := a2 != null and _queue_attack(base + maxf(d, 0.0), a2, skill2, t2)
	if _scn_on:  # os ataques do cenário pronto além dos dois dos campos
		for k in range(2, _scn_atk.size()):
			var e: Array = _scn_atk[k]
			var ea := _role(String(e[0]))
			var ets := _shaped(_find_skill(ea, String(e[1])))
			if ea != null and ets != null:
				_queue_attack(float(e[3]), ea, ets, _role(String(e[2])))
		for act in _scn_acts:
			_queue_act(act)
	for act in _manual_acts:
		_queue_act(act)
	if _kill_on.button_pressed:
		_queue_act([_kill_at.value, "kill", "#%d" % _kill_unit.selected])
	if _evade_mode.selected == 1:
		_queue_act([_evade_at.value, "evade", "#%d" % _evade_unit.selected])
	elif _evade_mode.selected == 2:
		_queue_act([_evade_at.value, "evade_once", "#%d" % _evade_unit.selected])
	if _args.has("acts-ticks"):
		_parse_acts_ticks(String(_args["acts-ticks"]))
	_fired = ok or ok2
	_idle_for = 0.0
	_tick_from_fire = 0
	_audit_done = false
	_init_fire_telemetry(a, t, skill)
	if _ficha_label != null and skill != null:
		var pk := String(PAUSE_KEYS[_pause_event.selected]) if _pause_event.selected > 0 else "impact"
		_ficha_label.text = "FICHA [%s — %s]: %s" % [skill.display_name, pk.to_upper(), skill.visual_phase_text(pk)]
	if _fired and _rec_request > 0.0:
		_start_record(_rec_request, _rec_step)
	var line := ("[%s] " % _scn_name if _scn_name != "" else "") + "%s: %s -> %s %s  [%s]" % [a.name, skill.display_name, t.name, ("" if ok else "(recusado pelo combate)") + ("  | alvo canalizando " + channeling if channeling != "" else ""), FORCE_LABELS[_force.selected]]
	if a2 != null:
		line += "\n+ %s: %s -> %s  (%+.2fs)%s" % [a2.name, skill2.display_name, t2.name, d, "" if ok2 else " (recusado)"]
	_status.text = line
	print("[vfx_room] ", line)


## Ainda há wind-up, golpe ou retorno em andamento (um disparo novo começaria sujo).
func _busy() -> bool:
	return not _battle.incoming.is_empty() or not _battle.attacks_in_flight().is_empty() or not _sched.is_empty() or not _polls.is_empty()


func _find_skill(c: Combatant, skill_name: String) -> Skill:
	if c == null:
		return null
	if skill_name == "Tackle":
		return Skill.basic()
	for s in c.skills:
		if s.display_name == skill_name:
			return s
	if _catalog.has(skill_name):
		return _catalog[skill_name]
	var want := skill_name.to_lower().replace(" ", "").replace("_", "")
	for k in _catalog:
		if String(k).to_lower().replace(" ", "").replace("_", "") == want:
			return _catalog[k]
	return _catalog.get(skill_name)  # qualquer unidade pode usar qualquer Move (D-235)


## Marca uma ação [segundos, ação, quem, ...] para depois do disparo.
func _queue_act(act: Array) -> void:
	var what := String(act[1])
	if what == "attack":
		what = "attackr"
	_sched.append({"at": float(act[0]), "kind": "act", "what": what, "role": String(act[2]), "args": act.slice(3)})


## Cópia do Move com o wind-up forçado pelo controle (0 = o do próprio Move).
func _shaped(s: Skill) -> Skill:
	if s == null or _windup_ovr.value <= 0.0:
		return s
	return Skill.new(s.display_name, s.power, s.cost, s.element, s.kind, s.ground, s.is_aoe, s.is_friendly, _windup_ovr.value, s.aoe_on_contact)


## Dispara agora (at <= 0) ou marca para `at` segundos depois do disparo.
func _queue_attack(at: float, a: Combatant, skill: Skill, t: Combatant) -> bool:
	if at <= 0.0001:
		var ok := _battle.use_skill(a, skill, t)
		if not ok:
			_note("RECUSADO: %s %s -> %s" % [a.name, skill.display_name, t.name])
		return ok
	_sched.append({"at": at, "kind": "attack", "a": a, "skill": skill, "t": t})
	return true


## Ações marcadas no tempo (segundo ataque, morte, Guard, Evade, passos, buffs...) e as tentativas de Evade em curso.
func _run_schedule() -> void:
	if _battle == null or _units.is_empty():
		return
	var t := _clock - _fire_clock
	for s in _sched.duplicate():
		if s.has("tick"):
			if _tick_from_fire < int(s["tick"]):
				continue
		elif t < float(s["at"]):
			continue
		_sched.erase(s)
		match String(s["kind"]):
			"attack":
				var ok := _battle.use_skill(s["a"], s["skill"], s["t"])
				_note("%s: %s %s -> %s" % ["ATAQUE" if ok else "ATAQUE RECUSADO", (s["a"] as Combatant).name, (s["skill"] as Skill).display_name, (s["t"] as Combatant).name])
				if ok:
					_fired = true
			"act":
				_do_act(String(s["what"]), _role(String(s["role"])), s["args"], t)
	for poll in _polls.duplicate():
		var u: Combatant = poll["u"]
		if t > float(poll["until"]) or not u.is_alive():
			_polls.erase(poll)
			continue
		var inc := _battle.find_evadable(u)
		if inc != null and inc.can_evade_now() and _battle.try_evade(u, inc):  # D-1014: o laboratório espera a janela válida
			_polls.erase(poll)
			_note("EVADE perfeito: %s (%s)" % [u.name, inc.label])


func _do_act(what: String, u: Combatant, args: Array, t: float) -> void:
	if u == null:
		return
	match what:
		"damage":
			var amt := int(args[0]) if args.size() > 0 else 10
			var att_u := _units[_attacker.selected] if not _units.is_empty() else u
			u.take_damage(amt)
			_battle.hit_resolved.emit(att_u, u, Element.Type.FISICO, {
				"evaded": false, "dmg": amt, "weak": false, "crit": false,
				"gain": 0, "whiffed": false, "power": 1.0, "skill_name": "Tackle",
			})
			_note("DANO: %s levou %d de dano (HP %d/%d)" % [u.name, amt, u.hp, u.max_hp])
		"kill":
			u.set_meta("room_no_heal", true)
			u.take_damage(u.hp, true)
			_killed = true
			_note("MORTE: %s" % u.name)
		"guard":
			var ok := _battle.use_guard(u)
			_note("GUARD %s: %s%s" % ["ok" if ok else "recusado", u.name, "" if ok else " (" + _battle.guard_block_reason(u) + ")"])
		"step":
			u.atb = maxf(u.atb, 2.0)
			var dir := int(args[0])
			var ok2 := _battle.step(u, dir)
			_note("PASSO %s: %s%s" % ["à frente" if dir > 0 else "atrás", u.name, "" if ok2 else " (recusado: " + _battle.step_block_reason(u) + ")"])
		"buff":
			var v := u.buff_stat(String(args[0]), int(args[1]))
			_note("BUFF %s %+d: %s agora em %+d" % [String(args[0]).to_upper(), int(args[1]), u.name, v])
		"status":
			_apply_status(u, String(args[0]))
			_note("STATUS %s: %s" % [String(args[0]), u.name])
		"attackr":
			var skill := _shaped(_find_skill(u, String(args[0])))
			var tgt := _role(String(args[1]))
			var ok3 := skill != null and tgt != null and _battle.use_skill(u, skill, tgt)
			_note("%s: %s %s -> %s" % ["CONTRA/AÇÃO" if ok3 else "AÇÃO RECUSADA", u.name, String(args[0]), tgt.name if tgt != null else "?"])
			if ok3:
				_fired = true
		"evade":
			_polls.append({"u": u, "until": t + 4.5})  # D-1014: a janela válida chega depois do wind-up
		"evade_once":
			var inc := _battle.find_evadable(u)
			var inside := inc != null and inc.can_evade_now()
			var done := inc != null and _battle.try_evade(u, inc)
			_note("EVADE %s: %s" % ["perfeito" if done and inside else ("FORA DE HORA (gastou e errou, D-1014)" if done else "SEM EFEITO (sem ataque a desviar)"), u.name])


## "A1", "A2", "E1".."E3" (papéis) ou "#n" (unidade n da lista).
func _role(r: String) -> Combatant:
	if r.begins_with("#"):
		var i := int(r.substr(1))
		return _units[i] if i >= 0 and i < _units.size() else null
	var list: Array[Combatant] = _battle.party if r.begins_with("A") else _battle.enemies
	if list.is_empty():
		return null
	var n := clampi(int(r.substr(1)) - 1, 0, list.size() - 1)
	return list[n]


# --- Cenários prontos e ajustes de estado --------------------------------------------------


func _reset_scenario() -> void:
	_a2_on.button_pressed = false
	_delay1.value = 0.0
	_delay2.value = 0.0
	_windup_ovr.value = 0.0
	_evade_mode.select(0)
	_evade_at.value = 0.0
	_kill_on.button_pressed = false
	_guard_target.button_pressed = false
	_channel.button_pressed = false
	_force.select(1)
	_atb_slider.value = 5
	_hp_slider.value = 100
	_dist.value = TEAM_DISTANCE
	_clear_scenario()
	_manual_acts.clear()


## Esquece o cenário pronto (os Moves disparados à mão não carregam os extras dele).
func _clear_scenario() -> void:
	_scn_on = false
	_scn_atk = []
	_scn_acts = []
	_scn_pos = {}
	_need_enemies = 1
	_scn_name = ""


func _pick(opt: OptionButton, name: String) -> void:
	for i in opt.item_count:
		if opt.get_item_text(i) == name:
			opt.select(i)
			return
	if name != "":
		opt.add_item(name)
		opt.select(opt.item_count - 1)


func _set_attack1(att: int, move_name: String, tgt: int) -> void:
	_attacker.select(att)
	_fill_moves()
	_pick(_move, move_name)
	_target.select(tgt)


func _set_attack2(att: int, move_name: String, tgt: int, delay: float) -> void:
	_a2_on.button_pressed = true
	_attacker2.select(att)
	_fill_moves2()
	_pick(_move2, move_name)
	_target2.select(tgt)
	_delay2.value = delay


## Acrescenta os inimigos extras e põe cada um onde o cenário pede (também depois de uma recarga).
func _prepare_world() -> void:
	if _need_enemies > _battle.enemies.size():
		_add_test_enemies()
	for r in _scn_pos:
		var c := _role(String(r))
		var spec: Array = _scn_pos[r]
		if c != null and spec.size() >= 4 and String(spec[0]) == "between":
			var pa := _role(String(spec[1])).home
			var pb := _role(String(spec[2])).home
			var p := pa.lerp(pb, float(spec[3]))
			_bs.fx.debug_move_home(c, Vector3(p.x, 0.0, p.z))
	_sync_pos_sliders()


## Troca entre a lista de cenários e os ajustes finos.
func _show_view(advanced: bool) -> void:
	_scn_view.visible = not advanced
	_tabs.visible = advanced


## Refaz a lista de cenários pelo grupo escolhido e pela busca (um título por grupo, uma linha por cenário).
func _rebuild_scn_list() -> void:
	if _scn_items == null:
		return
	_scn_items.clear()
	_scn_ids.clear()
	var q := _scn_search.text.strip_edges().to_lower()
	var last_group := ""
	var n := 0
	for sc in VfxRoomScenarios.SCENARIOS:
		var g := String(sc["g"])
		if _scn_group != "Todos" and g != _scn_group:
			continue
		if q != "" and not (q in String(sc["label"]).to_lower() or q in String(sc["id"]) or q in g.to_lower()):
			continue
		if g != last_group:
			last_group = g
			var h := _scn_items.add_item("— %s —" % g.to_upper(), null, false)
			_scn_items.set_item_custom_fg_color(h, Color("62d8e7"))
			_scn_ids.append("")
		var row := _scn_items.add_item("   " + String(sc["label"]))
		_scn_ids.append(String(sc["id"]))
		if String(sc["id"]) == _scn_cur:
			_scn_items.select(row)
		n += 1
	_scn_count.text = "%d cenários" % n if n > 0 else "Nenhum cenário com esse filtro."


func _on_scn_selected(i: int) -> void:
	if i < 0 or i >= _scn_ids.size() or _scn_ids[i] == "":
		return
	var sc := _scenario_by_id(_scn_ids[i])
	_scn_detail.text = "%s\n%s" % [String(sc["label"]), _scenario_summary(sc).replace("\n", "  ·  ")]


## [ e ] (ou os botões): roda o cenário anterior/seguinte da lista visível.
func _step_scenario(dir: int) -> void:
	var ids: Array[String] = []
	for id in _scn_ids:
		if id != "":
			ids.append(id)
	if ids.is_empty():
		return
	var at := ids.find(_scn_cur)
	var next := 0 if at < 0 else posmod(at + dir, ids.size())
	_run_scenario(ids[next])


## Marca o cenário rodando na lista e mostra o resumo dele.
func _mark_scenario(id: String) -> void:
	_scn_cur = id
	for i in _scn_ids.size():
		if _scn_ids[i] == id:
			_scn_items.select(i)
			_scn_items.ensure_current_is_visible()
			_on_scn_selected(i)
			return


## Resumo curto de um cenário (para a dica ao passar o mouse): quem ataca quem, em que tempo, e as ações marcadas.
func _scenario_summary(sc: Dictionary) -> String:
	var parts: Array[String] = []
	for a in sc.get("atk", []):
		parts.append("%s %s -> %s (t=%.1f)" % [a[0], a[1], a[2], float(a[3])])
	for act in sc.get("acts", []):
		parts.append("t=%.1f %s %s" % [float(act[0]), String(act[1]), String(act[2])])
	if int(sc.get("enemies", 1)) > 1:
		parts.append("+2 inimigos")
	if sc.has("hp"):
		parts.append("vida %d%%" % int(sc["hp"]))
	return "\n".join(parts)


func _scenario_by_id(id: String) -> Dictionary:
	for s in VfxRoomScenarios.SCENARIOS:
		if String(s["id"]) == id:
			return s
	return {}


## Cenário pronto: recarrega a batalha limpa (a câmera escolhida não muda), monta o cenário e dispara.
func _run_scenario(id: String) -> void:
	var spec := _scenario_by_id(id)
	if spec.is_empty() or _units.is_empty():
		return
	await _reload_keep_selection()
	_reset_scenario()
	_scn_on = true
	_scn_name = String(spec["label"])
	_mark_scenario(id)
	_need_enemies = int(spec.get("enemies", 1))
	_scn_pos = spec.get("pos", {})
	_scn_atk = spec.get("atk", [])
	_scn_acts = spec.get("acts", [])
	_dist.value = float(spec.get("dist", TEAM_DISTANCE))
	_hp_slider.value = float(spec.get("hp", 100))
	_windup_ovr.value = float(spec.get("windup", 0.0))
	_channel.button_pressed = bool(spec.get("channel", false))
	if spec.has("pause"):
		var pi := PAUSE_KEYS.find(String(spec["pause"]))
		if pi >= 0:
			_pause_event.select(pi)
	if spec.has("force"):
		_force.select(int(spec["force"]))
	if _args.has("move") and id.begins_with("fase_"):
		var custom_atk: Array = _scn_atk.duplicate(true)
		custom_atk[0][1] = String(_args["move"])
		_scn_atk = custom_atk
	_prepare_world()
	_apply_scenario_selections()
	_fire()


func _apply_scenario_selections() -> void:
	if _scn_atk.is_empty():
		return
	var atk: Array = _scn_atk
	var first: Array = atk[0]
	var d0 := float(first[3])
	if atk.size() > 1:
		var second: Array = atk[1]
		var d1 := float(second[3])
		_delay1.value = minf(d0, d1)
		_set_attack1(_units.find(_role(String(first[0]))), String(first[1]), _units.find(_role(String(first[2]))))
		_set_attack2(_units.find(_role(String(second[0]))), String(second[1]), _units.find(_role(String(second[2]))), d1 - d0)
	else:
		_delay1.value = d0
		_set_attack1(_units.find(_role(String(first[0]))), String(first[1]), _units.find(_role(String(first[2]))))


func _buff(delta: int) -> void:
	var u := _units[_buff_unit.selected]
	var stat: String = ["atk", "def", "spd"][_buff_stat.selected]
	var v := u.buff_stat(stat, delta)
	_status.text = "%s: %s agora em %+d" % [u.name, stat.to_upper(), v]


## D-980: the status buttons of "STATUS EM VÁRIOS" apply to every checked character.
func _status_many(kind: String) -> void:
	var names: Array[String] = []
	for i in _multi_checks.size():
		if not (_multi_checks[i] as CheckBox).button_pressed or i >= _units.size():
			continue
		var u: Combatant = _units[i]
		if kind.begins_with("b:"):
			var parts := kind.split(":")
			u.buff_stat(parts[1], int(parts[2]))
		else:
			_apply_status(u, kind)
		names.append(u.name)
	_status.text = ("%s: %s" % [kind, ", ".join(names)]) if not names.is_empty() else "Marque pelo menos um personagem."


func _fill_multi() -> void:
	if _multi_box == null:
		return
	var keep: Array = []
	for cb in _multi_checks:
		keep.append((cb as CheckBox).button_pressed)
	for ch in _multi_box.get_children():
		ch.queue_free()
	_multi_checks.clear()
	for i in _units.size():
		var c: Combatant = _units[i]
		var cb := CheckBox.new()
		cb.text = "%s (%s)" % [c.name, "aliado" if c.is_player else "inimigo"]
		cb.button_pressed = bool(keep[i]) if i < keep.size() else false
		_multi_box.add_child(cb)
		_multi_checks.append(cb)


func _status_effect(kind: String) -> void:
	var u := _units[_buff_unit.selected]
	if kind == "guard":
		if not _battle.use_guard(u):
			_status.text = "Guard recusado: %s" % _battle.guard_block_reason(u)
			return
	else:
		_apply_status(u, kind)
	_status.text = "%s: %s" % [u.name, kind]


func _apply_status(u: Combatant, kind: String) -> void:
	match kind:
		"burn":
			u.apply_burn()
		"stun":
			u.stun_timer = 2.0
		"stun4":
			u.stun_timer = maxf(u.stun_timer, 4.0)  # D-980: the length of the Electric Beam STUN (D-977)
		"blind":
			u.blind_timer = 3.0
		"shield":
			u.apply_shield(18, 8.0)
		"magic_immune":
			u.apply_magic_immunity(10.0)
		"atb_add":
			u.atb = minf(u.atb + 1.0, Combatant.BLOCKS)  # D-1070
		"atb_sub":
			u.atb = maxf(u.atb - 1.0, 0.0)
		"atb_full":
			u.atb = Combatant.BLOCKS
		"atb_zero":
			u.atb = 0.0
		"clear":
			u.clear_buffs()
			u.clear_burn()
			u.end_shield("clear")
			u.clear_magic_immunity()


## Agenda uma ação para t segundos depois do próximo disparo (aba Ações).
func _schedule_manual() -> void:
	var at := _act_at.value
	var who := "#%d" % _act_unit.selected
	var act: Array = []
	match _act_kind.selected:
		0: act = [at, "guard", who]
		1: act = [at, "evade", who]
		2: act = [at, "evade_once", who]
		3: act = [at, "step", who, 1]
		4: act = [at, "step", who, -1]
		5: act = [at, "status", who, "stun"]
		6: act = [at, "status", who, "burn"]
		7: act = [at, "status", who, "blind"]
		8: act = [at, "buff", who, "atk", 1]
		9: act = [at, "buff", who, "def", -1]
		10: act = [at, "buff", who, "spd", 1]
		11: act = [at, "kill", who]
	_manual_acts.append(act)
	_status.text = "Agendado (%d): %s em t=%.2f s para %s. Vale a partir do próximo disparo." % [_manual_acts.size(), _act_kind.get_item_text(_act_kind.selected), at, _units[_act_unit.selected].name]


func _clear_manual() -> void:
	_manual_acts.clear()
	_status.text = "Agenda limpa."


func _step_unit(dir: int) -> void:
	var u := _units[_pos_unit.selected]
	u.atb = maxf(u.atb, 2.0)
	if _battle.step(u, dir):
		_status.text = "%s: passo %s (posição %+d)" % [u.name, "à frente" if dir > 0 else "atrás", u.pos_step]
	else:
		_status.text = "%s não pode andar: %s" % [u.name, _battle.step_block_reason(u)]


var _syncing_pos := false


func _sync_pos_sliders() -> void:
	if _pos_unit == null or _pos_unit.selected < 0 or _pos_unit.selected >= _units.size():
		return
	var u := _units[_pos_unit.selected]
	_syncing_pos = true
	_pos_x.value = u.home.x
	_pos_z.value = u.home.z
	_syncing_pos = false
	_pos_label.text = "Casa de %s: x=%.1f  z=%.1f  (passo %+d)" % [u.name, u.home.x, u.home.z, u.pos_step]


func _on_pos_changed(_v: float) -> void:
	if _syncing_pos or _bs == null or _pos_unit.selected < 0 or _pos_unit.selected >= _units.size():
		return
	var u := _units[_pos_unit.selected]
	_bs.fx.debug_move_home(u, Vector3(_pos_x.value, 0.0, _pos_z.value))
	_pos_label.text = "Casa de %s: x=%.1f  z=%.1f  (passo %+d)" % [u.name, u.home.x, u.home.z, u.pos_step]


func _add_test_enemies() -> void:
	if _bs.has_method("_debug_add_test_enemies"):
		var msg: String = _bs._debug_add_test_enemies()
		_refresh_units()
		_status.text = msg


func _remove_test_enemies() -> void:
	if _bs.has_method("_debug_remove_test_enemies"):
		var msg: String = _bs._debug_remove_test_enemies()
		_refresh_units()
		_status.text = msg


## Faz o alvo começar a canalizar um ataque dele (wind-up longo) contra o atacante, para o golpe interrompê-lo.
## Devolve o nome do move usado ("" se não deu).
func _start_channel(c: Combatant, foe: Combatant) -> String:
	for s in c.skills:
		if s.kind == Skill.Kind.STATUS or s.is_friendly:
			continue
		if s.windup >= 0.0 and s.windup < 1.0:
			continue  # só moves de wind-up longo: dá tempo do golpe chegar
		if _battle.use_skill(c, s, foe):
			return s.display_name
	return ""


## Test-only FOV override: freeze the battle director and set the camera FOV.
func _apply_fov_test(fov_value: float) -> void:
	if _bs == null:
		return
	var director: BattleCamera = _bs.director
	if director != null:
		director.set_process(false)
	var cam := _bs.get_node_or_null("Camera3D") as Camera3D
	if cam != null:
		cam.current = true
		cam.fov = clampf(fov_value, 20.0, 110.0)


func _apply_camera() -> void:
	var director: BattleCamera = _bs.director
	var cam: Camera3D = _bs.get_node("Camera3D")
	if _cam_mode.selected == 0:
		if director != null:
			director.set_process(true)
		return
	if director != null:
		director.set_process(false)
	var a: Node3D = _bs.models.get(_units[_attacker.selected])
	var t: Node3D = _bs.models.get(_units[_target.selected])
	if a == null or t == null:
		return
	cam.current = true
	# As câmeras fixas seguem o eixo atacante -> alvo, então valem para qualquer lado do campo.
	var axis := t.global_position - a.global_position
	axis.y = 0.0
	axis = axis.normalized() if axis.length() > 0.01 else Vector3.FORWARD
	var side := Vector3(-axis.z, 0.0, axis.x)  # à esquerda de quem olha do atacante ao alvo
	match _cam_mode.selected:
		1:
			cam.fov = 45.0
			cam.global_position = t.global_position - axis * 9.0 + side * 5.0 + Vector3(0, 3.0, 0)
			cam.look_at(t.global_position + Vector3(0, 1.3, 0))
		2:
			cam.fov = 55.0
			cam.global_position = a.global_position - axis * 8.0 + side * 6.0 + Vector3(0, 5.0, 0)
			cam.look_at((a.global_position + t.global_position) * 0.5 + Vector3(0, 1.0, 0))
		4:
			_update_frame_cam(true)
		3:
			# começa olhando de lado, com a ação inteira no quadro
			_orbit_yaw = atan2(side.x, side.z)
			_orbit_pitch = 0.3
			_orbit_dist = clampf(a.global_position.distance_to(t.global_position) * 0.8, 10.0, 60.0)
			cam.fov = 50.0
			_update_orbit()
		5:
			_update_macro_cam()


## Câmera lateral que enquadra todos os envolvidos (atacantes e alvos dos dois ataques e de tudo em curso).
func _update_frame_cam(snap: bool) -> void:
	var cam: Camera3D = _bs.get_node("Camera3D")
	var a: Node3D = _bs.models.get(_units[_attacker.selected])
	var t: Node3D = _bs.models.get(_units[_target.selected])
	if a == null or t == null:
		return
	var axis := t.global_position - a.global_position
	axis.y = 0.0
	axis = axis.normalized() if axis.length() > 0.01 else Vector3.FORWARD
	var side := Vector3(-axis.z, 0.0, axis.x)
	var who: Array[Combatant] = [_units[_attacker.selected], _units[_target.selected]]
	if _a2_on.button_pressed:
		who.append(_units[_attacker2.selected])
		who.append(_units[_target2.selected])
	for inc in _battle.incoming:
		who.append(inc.attacker)
		who.append(inc.target)
	for inc in _battle.attacks_in_flight():
		who.append(inc.attacker)
		who.append(inc.target)
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for c in who:
		var m: Node3D = _bs.models.get(c)
		if m != null:
			lo = lo.min(m.global_position)
			hi = hi.max(m.global_position)
	var center := (lo + hi) * 0.5
	var extent := maxf((hi - lo).length(), 12.0)
	var dist := clampf(extent * 0.85 + 6.0, 16.0, 80.0)
	var pos := center + side * dist + Vector3(0.0, 4.0 + extent * 0.12, 0.0)
	cam.current = true
	cam.fov = 50.0
	cam.global_position = pos if snap else cam.global_position.lerp(pos, 0.12)
	cam.look_at(center + Vector3(0.0, 1.2, 0.0))


## O painel some enquanto há golpe em curso (para ver a ação) e volta quando tudo para ou pausa.
func _auto_hide_panel() -> void:
	if _panel == null or not _rec.is_empty():
		return
	var acting := _fired and _battle != null and (not _battle.attacks_in_flight().is_empty() or not _battle.incoming.is_empty() or not _sched.is_empty())
	var want := not _panel_user_hidden and not (_autohide.button_pressed and acting and not _paused)
	if _panel.visible != want:
		_panel.visible = want


func _update_orbit() -> void:
	var cam: Camera3D = _bs.get_node("Camera3D")
	var a: Node3D = _bs.models.get(_units[_attacker.selected])
	var t: Node3D = _bs.models.get(_units[_target.selected])
	if a == null or t == null:
		return
	var focus := (a.global_position + t.global_position) * 0.5
	if _focus.selected == 1:
		focus = a.global_position
	elif _focus.selected == 2:
		focus = t.global_position
	focus += Vector3(0, 1.3, 0)
	var off := Vector3(sin(_orbit_yaw) * cos(_orbit_pitch), sin(_orbit_pitch), cos(_orbit_yaw) * cos(_orbit_pitch)) * _orbit_dist
	cam.global_position = focus + off
	cam.look_at(focus)



# --- Catálogo Universal D-235, Telemetria JSON e 10 Ferramentas de Análise de VFX (D-1042 / D-1044) ---


func _seed_full_catalog() -> void:
	for sk in Skill.all_catalog_skills():
		if not _catalog.has(sk.display_name):
			_catalog[sk.display_name] = sk


func _current_skill() -> Skill:
	if _units.is_empty() or _attacker == null or _move == null or _move.selected < 0 or _move.item_count == 0:
		return null
	var a := _units[clampi(_attacker.selected, 0, _units.size() - 1)]
	return _find_skill(a, _move.get_item_text(_move.selected))


func _parse_acts_ticks(spec: String) -> void:
	for item in spec.split(",", false):
		var parts := item.split(":", false)
		if parts.size() >= 3:
			var tk := int(parts[0])
			var what := String(parts[1])
			if what == "attack":
				what = "attackr"
			var role := String(parts[2])
			var rest: Array = []
			for i in range(3, parts.size()):
				rest.append(parts[i])
			_sched.append({"tick": tk, "at": 0.0, "kind": "act", "what": what, "role": role, "args": rest})


func _init_fire_telemetry(a: Combatant, t: Combatant, skill: Skill) -> void:
	_baseline_fx_ids.clear()
	if _bs != null and _bs.fx != null:
		for ch in _bs.fx.get_children():
			_baseline_fx_ids[ch.get_instance_id()] = true
	_last_leaks.clear()
	_envelope_samples.clear()
	_prev_node_alphas.clear()
	_envelope_pops.clear()
	_bone_has_prev = false
	_bone_cur_speed = 0.0
	_bone_peak_speed = 0.0
	_bone_trail.clear()
	_telemetry = {
		"scenario": _scn_cur if _scn_on else "",
		"attacker": a.name if a != null else "",
		"attacker_side": ("player" if a.is_player else "enemy") if a != null else "",
		"target": t.name if t != null else "",
		"target_side": ("player" if t.is_player else "enemy") if t != null else "",
		"move": skill.display_name if skill != null else "",
		"hp_before": t.hp if t != null else 0,
		"hp_after": t.hp if t != null else 0,
		"damage_dealt": 0,
		"hits_count": 0,
		"crit_count": 0,
		"weak_count": 0,
		"evaded_count": 0,
		"guard_result": "",
		"armor_result": "",
		"stun_timer_after": 0.0,
		"ko_triggered": false,
		"phases_reached": [],
		"ficha_fases": skill.visual_phases() if skill != null else {},
		"vfx_spawns": [],
		"vfx_leaks": [],
		"envelope_pops": [],
		"bone_peak_speed": 0.0,
	}


func _record_phase(phase_name: String) -> void:
	if not _telemetry.has("phases_reached"):
		return
	var arr: Array = _telemetry["phases_reached"]
	if not arr.has(phase_name):
		arr.append(phase_name)


func _record_hit_telemetry(_att: Combatant, tgt: Combatant, info: Dictionary) -> void:
	if _telemetry.is_empty():
		return
	_telemetry["hits_count"] = int(_telemetry.get("hits_count", 0)) + 1
	_telemetry["damage_dealt"] = int(_telemetry.get("damage_dealt", 0)) + int(info.get("dmg", 0))
	if tgt != null:
		_telemetry["hp_after"] = tgt.hp
		_telemetry["stun_timer_after"] = snappedf(tgt.stun_timer, 0.01)
		if not tgt.is_alive():
			_telemetry["ko_triggered"] = true
	if bool(info.get("crit", false)):
		_telemetry["crit_count"] = int(_telemetry.get("crit_count", 0)) + 1
	if bool(info.get("weak", false)):
		_telemetry["weak_count"] = int(_telemetry.get("weak_count", 0)) + 1
	if bool(info.get("evaded", false)):
		_telemetry["evaded_count"] = int(_telemetry.get("evaded_count", 0)) + 1
	if String(info.get("guard", "")) != "":
		_telemetry["guard_result"] = String(info["guard"])
	if String(info.get("armor", "")) != "":
		_telemetry["armor_result"] = String(info["armor"])
	if _scale_overlay_on:
		_log_scale_metrics()


func _emit_summary_json() -> void:
	if not _args.has("summary-json"):
		return
	if _audit_leaks_on and not _audit_done:
		_audit_done = true
		_audit_vfx_leaks()
	if not _units.is_empty() and _target.selected >= 0 and _target.selected < _units.size():
		var tgt := _units[_target.selected]
		_telemetry["hp_after"] = tgt.hp
		_telemetry["stun_timer_after"] = snappedf(tgt.stun_timer, 0.01)
		if not tgt.is_alive():
			_telemetry["ko_triggered"] = true
	_telemetry["vfx_leaks"] = _last_leaks
	_telemetry["leaks_detected"] = _last_leaks.size()
	_telemetry["envelope_pops"] = _envelope_pops
	_telemetry["bone_peak_speed"] = snappedf(_bone_peak_speed, 0.01)
	print("[vfx_room] SUMMARY_JSON: ", JSON.stringify(_telemetry))




# --- Análise VFX: wrappers para o módulo VfxRoomAnalysis (Etapa 4) -------------

func _audit_vfx_leaks() -> void:
	_analysis._audit_vfx_leaks()


func _build_analysis_overlay() -> void:
	_analysis._build_analysis_overlay()


func _tick_vfx_analysis(delta: float) -> void:
	_analysis._tick_vfx_analysis(delta)


func _log_scale_metrics() -> void:
	_analysis._log_scale_metrics()


func _update_macro_cam() -> void:
	_analysis._update_macro_cam()


func _apply_bg_mode(mode: String) -> void:
	_analysis._apply_bg_mode(mode)


func _compare_images(shot_file: String, ref_arg: String) -> void:
	_analysis._compare_images(shot_file, ref_arg)


func _run_proof_sheet(out_arg: String) -> void:
	await _analysis._run_proof_sheet(out_arg)


func _run_test_d235() -> void:
	await _analysis._run_test_d235()


func _run_test_all_moves_matrix() -> void:
	await _analysis._run_test_all_moves_matrix()


func _build_vfx_analysis_tab(tabs: TabContainer) -> void:
	_analysis._build_vfx_analysis_tab(tabs)
