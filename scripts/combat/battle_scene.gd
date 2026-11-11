extends Node3D
## 3D battle stage + command flow. The player's team stands near the camera
## facing away; the enemies are far ahead, offset diagonally to the right.
## The player controls party[0]; the others follow Tactics. All on-screen UI
## lives in BattleHud; BattleCamera frames the action.

enum S { MAIN, FIGHT, ITEMS, TARGET, TACTICS, STATUS }

const MODEL_SCALE := 2.5
const TEAM_DISTANCE := 30.0  ## Units between the two lines.
# The player's character is front-left, close to the camera; the ally stands back on the right.
const PARTY_SLOTS := [Vector3(0.6, 0, 1.5), Vector3(7.5, 0, -3.0), Vector3(-5.0, 0, -2.0)]
const SLOWMO_SCALE := 0.3  ## Game speed after a perfect Evade.
const SLOWMO_SECONDS := 2.0  ## Real seconds, or until the player's counter-action.
const TARGET_HEIGHT := 1.2  ## D-1013 (creator: "1,2"): every battle model reads at this height (m)
const CYCLOPS_HEIGHT := 4.0  ## D-1054: exact Cyclops height requested by the creator
const ENEMY_SCALE := 2.16  ## Extra scale on enemy models so they read at 30 units (D-339: 1.8 +20%).
const ACT_NAMES := ["Attack", "Skills", "Hold"]
const REACT_NAMES := ["None", "Evade"]
const FIGHT_SLOTS := 9  ## Number keys 1-9 per page; Q/E turn the page.
const BattleArena = preload("res://scripts/combat/battle_arena.gd")
const BattleFx = preload("res://scripts/combat/battle_fx.gd")
const BattleCamera = preload("res://scripts/combat/battle_camera.gd")
const BattleHud = preload("res://scripts/ui/battle_hud.gd")
const SmtBuffController = preload("res://scripts/vfx/smt/smt_buff_controller.gd")
const NatureData = preload("res://scripts/data/nature_data.gd")
const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")
const VictoryPanelScript = preload("res://scripts/ui/victory_panel.gd")
const LevelUpModalScript = preload("res://scripts/ui/level_up_modal.gd")
const EnemyFactory = preload("res://scripts/combat/enemy_factory.gd")

@onready var battle: Battle = $Battle
@onready var ui: CanvasLayer = $UI

var models: Dictionary = {}  ## Combatant -> Node3D
var fx: BattleFx
var director: BattleCamera
var smt_vfx: SmtBuffController
var hud: BattleHud
var state := S.MAIN
var _guard_mode := false  ## D-272: the Evade block is swapped for the Guard block (right = Guard, left = Evade).
var leader: Combatant

const DECISION_SLOWMO_SCALE := 0.2
const DECISION_SLOWMO_SECONDS := 3.0  ## Itens (D-047).
const FIGHT_SLOWMO_SECONDS := 2.0  ## Fight (D-162).
## D-1129: a real interruption briefly slows the whole game and shakes the camera.
const INTERRUPTION_SLOWMO_SCALE := 0.35
const INTERRUPTION_SLOWMO_SECONDS := 0.45  ## Real seconds at 0.35x.
const INTERRUPTION_SLOWMO_RETURN := 0.12  ## Real seconds easing back to 1.0x.
const INTERRUPTION_MULTI_COOLDOWN_MS := 6000  ## Only multi-target interruptions are throttled.

var _slow_token := 0
var _shown_queue: Skill = null  ## The queued move the menu title shows now (D-161).
var _fight_sig: Array = []  ## See _fight_signature().
var _decision_slowmo_available := true  ## Reset to true whenever the player performs an action (D-047).
var _decision_slowmo_active := false
var _decision_slowmo_time_left := 0.0
var _decision_slowmo_token := 0
## D-1129: interruptions that happen in the same frame are one event.
var _interrupt_batch: Dictionary = {}  ## Combatant -> {source: Combatant, already_shakes: bool}
var _interrupt_flush_queued := false
var _interrupt_multi_ready_at := 0  ## Time.get_ticks_msec() when the next multi-target event may play.
var _interrupt_slowmo_active := false
var _interrupt_slowmo_token := 0
var _interrupt_tween: Tween
var _status_unit: Combatant
var _saved_anim: Dictionary = {}  ## AnimationPlayer -> [name, position]

var _menu: FanMenu
var _last_main := 0  ## Last command picked on the main menu (it reopens there).
var _fight_target: Combatant  ## The opponent highlighted while the move list is open.
var _last_skill := ""  ## Last Fight skill and target, by name.
var _last_target := ""
var _tactic_rows: Array = []  ## {unit, kind: act | react | pos} per Tactics row
var _fight_skills: Array[Skill] = []
var _fight_page := 0  ## 9 slots per page (Q/E); 1-9 uses the current page.
var _item_list: Array[Item] = []
var _targets: Array[Combatant] = []
var _on_target: Callable
var _back: Callable
var _test_enemies: Array[Combatant] = []  ## Debug spawns (H): extra standing enemies for the camera test.


func _ready() -> void:
	add_child(BattleArena.new())
	fx = BattleFx.new()
	add_child(fx)
	director = BattleCamera.new()
	add_child(director)
	director.setup($Camera3D)
	fx.cam = director
	smt_vfx = SmtBuffController.new()
	smt_vfx.name = "SmtBuffController"
	add_child(smt_vfx)
	var party := GameState.party
	var enemies: Array[Combatant] = []
	if has_meta("vfx_room_mirror"):  # Sala de VFX: times espelhados (Gible aliado; Abra e Pancham inimigos).
		party = _debug_mirror_party()
		enemies = _debug_mirror_enemies()
	# Crossover pilot: --dqt puts the DQT trio on the player's side; --dqt-mirror
	# puts them on the enemy side so their fronts face the camera.
	elif "--dqt-mirror" in OS.get_cmdline_user_args():
		var solo: Array[Combatant] = [GameState.party[0]]
		party = solo
		enemies = DqtTestParty.build(false)
	elif DqtTestParty.enabled or "--dqt" in OS.get_cmdline_user_args():
		party = DqtTestParty.build(true, GameState.inventory)
		enemies = EnemyFactory.roll_encounter()
	else:
		enemies = EnemyFactory.roll_encounter()
	for e in enemies:  # Same Tactics the allies have: cast skills and evade when able.
		e.act_policy = Combatant.Act.SKILL
		e.react_policy = Combatant.React.EVADE
	if has_meta("vfx_room"):  # Sala de VFX: ninguém age sozinho (nem no primeiro frame da batalha).
		for c in party + enemies:
			c.act_policy = Combatant.Act.HOLD
			c.react_policy = Combatant.React.NONE
	leader = party[0]
	fx.leader = leader
	fx.battle = battle
	var party_slots: Array[Vector3] = []
	for i in party.size():
		party_slots.append(PARTY_SLOTS[mini(i, PARTY_SLOTS.size() - 1)])
	var enemy_slots: Array[Vector3] = []
	for i in enemies.size():
		enemy_slots.append(_enemy_slot(i))
	_spawn(party, party_slots, PI, Color(0.3, 0.6, 0.9))
	_spawn(enemies, enemy_slots, 0.0, Color(0.85, 0.3, 0.3))
	hud = BattleHud.new()
	ui.add_child(hud)
	hud.setup(battle, party, enemies, $Camera3D, models, director)
	var debug_panel := BattleDebug.new()  # F1: quick-test panel (hotkeys F2..F8, C, G, H, J, K..M)
	add_child(debug_panel)
	debug_panel.setup(battle, party, enemies, fx, $Camera3D, director)
	debug_panel.set_test_enemy_toggle(_debug_toggle_test_enemies)
	debug_panel.set_test_enemy_push(_debug_shift_test_enemy)
	_menu = hud.menu
	hud.status_closed.connect(_close_status)
	hud.status_unit_selected.connect(_on_status_unit)
	_menu.chosen.connect(_on_chosen)
	_menu.cancelled.connect(_on_cancel)
	_menu.moved.connect(_on_moved)
	_menu.side.connect(_on_menu_side)
	battle.state_changed.connect(_refresh)
	battle.battle_ended.connect(_on_battle_ended)
	battle.attack_telegraphed.connect(fx.telegraph)
	battle.status_pause_started.connect(fx.on_status_pause_started)
	battle.status_pause_ended.connect(fx.on_status_pause_ended)
	battle.attack_resolved.connect(fx.resolve_attack)
	battle.attack_phase.connect(fx.on_phase)
	battle.engaged.connect(fx.on_engaged)
	battle.evade_teleported.connect(fx.on_evade_teleported)
	battle.evade_returned.connect(fx.on_evade_returned)
	battle.attack_interrupted.connect(fx.on_attack_interrupted)
	battle.attack_interrupted.connect(_on_interrupted_by_hit)  # D-1129
	battle.windup_hit_interrupted.connect(_on_hit_interrupted_windup)  # D-1129
	battle.windup_interrupted.connect(_on_interrupted_windup)  # D-1129
	battle.action_interrupted.connect(fx.play_damage_reaction)  # D-1105
	battle.attack_clashed.connect(fx.on_attack_clashed)
	if BattleTrace.wanted():  # Flight recorder: every frame and event to user://battle_trace.jsonl
		var trace := BattleTrace.new()
		add_child(trace)
		trace.setup(battle, fx, models, party, enemies)
	battle.engage_ended.connect(fx.on_engage_ended)
	battle.engage_ended.connect(func(actor: Combatant, _o, _g, _s) -> void:
		if actor == leader:
			_end_slowmo())
	battle.attack_cancelled.connect(fx.on_attack_cancelled)
	battle.manual_evaded.connect(fx.manual_evade)
	battle.evade_whiffed.connect(fx.evade_whiff)
	battle.evade_mistimed.connect(fx.evade_mistimed)  # D-1015
	battle.hit_resolved.connect(fx.play_hit)
	battle.guard_started.connect(fx.fx_guard.start)  # D-272
	battle.guard_ended.connect(fx.fx_guard.stop)
	battle.armor_changed.connect(fx.fx_armor.on_armor_changed)  # D-1026
	battle.mp_regenerated.connect(fx.on_mp_regenerated)  # D-1062
	battle.hit_resolved.connect(smt_vfx.on_hit_resolved)
	battle.healed.connect(fx.heal_fx)
	battle.manual_evaded.connect(_on_manual_evaded)
	battle.attack_telegraphed.connect(func(inc) -> void:
		if inc.attacker == leader:
			_end_slowmo()
			_on_player_action_executed())
	battle.healed.connect(func(actor: Combatant, _t: Combatant, _n: int) -> void:
		if actor == leader:
			_end_slowmo())
	# The fight only starts once everybody has finished running in, so no attack
	# can interrupt the entrance.
	battle.party = party
	battle.enemies = enemies
	_menu.hide()  # No commands while the characters are still running in.
	var tr := GameState.transition
	if tr != null and tr.active and not tr.has_revealed:
		await tr.revealed  # The run-in plays while the panels open.
	await fx.intro()
	battle.start(party, enemies)
	# D-1101: encounter advantage applied after the base START_ATB (4 vs 2 for the winner).
	EncounterRules.apply_atb(party, enemies, GameState.encounter_advantage)
	GameState.encounter_advantage = EncounterRules.Advantage.NORMAL
	director.watch_safe_area(_safe_area_units, hud.free_rect)  # D-1010
	director.watch_enemies(_enemy_frame_points)  # D-015 test: the living enemies the framing must keep in view.
	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	# Debug: F11 toggles the DQT crossover trio and restarts the battle with it.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		DqtTestParty.enabled = not DqtTestParty.enabled
		print("DQT test party: ", DqtTestParty.enabled)
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
		return
	# Q/E turn the Fight page (QoL 5): slots 1-9 stay reachable past the ninth move.
	if event is InputEventKey and event.pressed and not event.echo and state == S.FIGHT \
			and (event.keycode == KEY_Q or event.keycode == KEY_E):
		_change_fight_page(-1 if event.keycode == KEY_Q else 1)
		get_viewport().set_input_as_handled()
		return
	# 1-9 use that move of the list on the current target; R repeats the last move.
	if event is InputEventKey and event.pressed and not event.echo and battle.running and leader.is_alive() \
			and (state == S.MAIN or state == S.FIGHT):
		var slot: int = event.keycode - KEY_1
		var offset := _fight_page * FIGHT_SLOTS if state == S.FIGHT else 0
		var skill: Skill = null
		_build_fight_skills()
		if slot >= 0 and slot < FIGHT_SLOTS and offset + slot < _fight_skills.size():
			skill = _fight_skills[offset + slot]
		elif event.keycode == KEY_R:
			skill = _move_by_name(_last_skill)
		if skill != null:
			if leader.mp < skill.mp_cost:
				get_viewport().set_input_as_handled()
				return
			var target := _fight_target if state == S.FIGHT and _fight_target != null and _fight_target.is_alive() else _default_target()
			if _use_move(skill, target):
				_leave_fight_camera()
				_show_main()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("guard") and battle.running and leader.is_alive():
		battle.use_guard(leader)  # D-272: own hotkey (Shift).
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("evade") and battle.running and leader.is_alive():
		if _guard_mode:  # D-272: while swapped, Space guards instead of dodging.
			battle.use_guard(leader)
			get_viewport().set_input_as_handled()
		elif battle.try_evade(leader, battle.find_evadable(leader)):
			get_viewport().set_input_as_handled()


## Debug/test tool (E selector). In S.FIGHT, E pages the move list and must stay
## there; in the paused Tactics/Status screens the selector would overlap a menu.
func debug_party_selector_blocked() -> bool:
	if not battle.running:
		return true
	if state == S.FIGHT:
		return true
	if get_tree().paused:
		return true
	if battle.is_status_paused():
		return true
	for c in battle.party + battle.enemies:
		if battle.is_in_action(c):
			return true
	return false


## The selector must list the real battle party (DQT/debug parties differ from
## GameState.party). Index i is the same index passed to debug_swap_party.
func debug_party_selector_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in battle.party.size():
		var c: Combatant = battle.party[i]
		entries.append({
			"name": str(c.name),
			"species": str(c.species_id),
			"leader": i == 0,
		})
	return entries


## Debug/test tool (E selector): swaps party[0] with party[i] and makes the two
## Combatants trade places. The battle is not restarted; rules, ATB and damage
## are untouched. All position/step fields move together so each body keeps its
## own numeric state under the other character.
func debug_swap_party(i: int) -> Dictionary:
	if not battle.running:
		return {"ok": false, "message": "A batalha não está rodando."}
	if i <= 0 or i >= battle.party.size():
		return {"ok": false, "message": "Índice de aliado inválido."}
	if state == S.STATUS or state == S.TACTICS:
		return {"ok": false, "message": "Feche o menu de pausa antes de trocar."}
	var a: Combatant = battle.party[0]
	var b: Combatant = battle.party[i]
	if a == null or b == null:
		return {"ok": false, "message": "Combatente inválido."}
	if not b.is_alive():
		return {"ok": false, "message": "%s está fora de combate." % str(b.name)}
	if battle.is_in_action(a) or battle.is_in_action(b):
		return {"ok": false, "message": "Aguarde o golpe atual terminar."}

	battle.party[0] = b
	battle.party[i] = a
	leader = battle.party[0]
	if fx != null:
		fx.leader = leader

	for field in ["home", "pos", "rest", "has_rest", "yaw", "pos_step", "step_from", "step_t"]:
		var tmp: Variant = a.get(field)
		a.set(field, b.get(field))
		b.set(field, tmp)
	if fx != null:
		# BattleFx rebuilds _home from stand_pos() each frame; update its yaw and
		# immediate home/slot so the models do not take a one-frame detour.
		fx._home[a] = a.stand_pos()
		fx._home[b] = b.stand_pos()
		fx._home_yaw[a] = a.yaw
		fx._home_yaw[b] = b.yaw
		fx._slot[a] = a.home
		fx._slot[b] = b.home
	if hud != null:
		hud.debug_rebind_party(battle.party)
	if state == S.FIGHT:
		_leave_fight_camera()
	_end_decision_slowmo()
	_show_main()
	_refresh()

	var message := "%s agora controla; %s ficou no lugar." % [str(b.name), str(a.name)]
	print("[DebugPartySwap] ", message)
	return {"ok": true, "message": message}


# --- Stage -----------------------------------------------------------------

## The battle's enemy, exactly as it has always been. The debug spawns (H) copy it:
## same stats, same moves, nothing new in the game.
## Sala de VFX (debug): Gible joga no time aliado e novas cópias de Abra e Pancham no inimigo.
func _debug_mirror_party() -> Array[Combatant]:
	var g := _new_gible()
	g.is_player = true
	g.act_policy = Combatant.Act.SKILL
	g.react_policy = Combatant.React.EVADE
	var out: Array[Combatant] = [g]
	return out


func _debug_mirror_enemies() -> Array[Combatant]:
	var saved: Array[Combatant] = GameState.party.duplicate()
	GameState._build_party()
	var fresh: Array[Combatant] = GameState.party.duplicate()
	GameState.party.assign(saved)
	for c in fresh:
		c.is_player = false
		c.act_policy = Combatant.Act.SKILL
		c.react_policy = Combatant.React.EVADE
	return fresh


func _new_gible() -> Combatant:
	return EnemyFactory.create_enemy("gible", null, "adamant")


## Debug panel (H adds two standing enemies, Shift+H removes them). Returns the note
## shown in the panel. They are real combatants (take a slot, can be targeted), but
## they only stand there: the test is about the camera, not about the fight.
func _debug_toggle_test_enemies(remove: bool) -> String:
	return _debug_remove_test_enemies() if remove else _debug_add_test_enemies()


func _debug_add_test_enemies() -> String:
	if not battle.running:
		return "Inimigos de teste: a batalha não está rodando"
	if not _test_enemies.is_empty():
		return "Inimigos de teste: já estão em cena (Shift+H remove)"
	for i in 2:
		var c := _new_gible()
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
		c.atb = 0.0
		var slot := battle.enemies.size()
		battle.enemies.append(c)
		var one: Array[Combatant] = [c]
		var spots: Array[Vector3] = [_enemy_slot(slot)]
		_spawn(one, spots, 0.0, Color(0.85, 0.3, 0.3))
		hud.add_enemy(c)
		_test_enemies.append(c)
	return "Inimigos de teste: +2 parados (K liga o enquadramento | Shift+H remove)"


## Debug (J / Shift+J): slide the first test enemy 5 units to one side so the framing
## can be seen acting. Only touches the debug spawns, never a real combatant.
func _debug_shift_test_enemy(left: bool) -> String:
	if _test_enemies.is_empty():
		return "Inimigos de teste: aperte H para criar os 2 primeiro"
	var c: Combatant = _test_enemies[0]
	var spot: Vector3 = c.home + Vector3(-5.0 if left else 5.0, 0.0, 0.0)
	fx.debug_move_home(c, spot)
	return "Inimigo de teste em x=%.0f (K liga o enquadramento | Shift+J vai para o outro lado)" % spot.x


func _debug_remove_test_enemies() -> String:
	if _test_enemies.is_empty():
		return "Inimigos de teste: nenhum em cena"
	if state == S.FIGHT and _fight_target in _test_enemies:
		return "Inimigos de teste: saia da escolha de alvo antes de remover"
	for c in _test_enemies:
		if battle.is_in_action(c):
			return "Inimigos de teste: espere o golpe atual terminar"
	for c in _test_enemies:
		battle.enemies.erase(c)
		var m: Node3D = models.get(c)
		models.erase(c)
		fx.unregister(c)
		if smt_vfx != null:
			smt_vfx.unregister_model(c)
		hud.remove_enemy(c)
		if m != null:
			m.queue_free()
	_test_enemies.clear()
	return "Inimigos de teste: removidos"


## D-338: the first enemy keeps its spot (x=8); each next one stands 10 to its left
## (camera view) instead of to its right, 2 units deeper as before.
func _enemy_slot(i: int) -> Vector3:
	return Vector3(8.0 - i * 10.0, 0.0, -TEAM_DISTANCE - i * 2.0)


func _spawn(list: Array[Combatant], slots: Array[Vector3], yaw: float, color: Color) -> void:
	for i in list.size():
		var c := list[i]
		var model := _make_model(c, color)
		# D-1013: every character is scaled to one target height, the same as ally or enemy (D-339 ENEMY_SCALE and
		# D-342 ally_scale removed). Measured from the model's real meshes, never per species.
		_fit_height.call_deferred(c, model)  # D-1013: measured once the idle pose is applied (bind pose can be folded)
		model.position = slots[i]
		model.rotation.y = yaw
		add_child(model)
		DqtModelProfiles.start_idle_breath(model)
		model.set_meta("head_y", _measure_head(model))
		models[c] = model
		fx.register(c, model)
		if smt_vfx != null:
			smt_vfx.register_model(c, model)
		c.died.connect(_on_died)


## D-015 test: where each living enemy's torso is drawn (the camera keeps these in view).
func _enemy_frame_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for c in battle.enemies:
		var m: Node3D = models.get(c)
		if m == null or not c.is_alive():
			continue
		var head_y: float = m.get_meta("head_y") if m.has_meta("head_y") else 1.8
		points.append(m.global_position + Vector3(0, head_y * 0.5 * m.scale.y, 0))
	return points


## D-1010: every living unit as world points (feet, head) plus the screen padding of its
## enemy tag, so the camera keeps bodies and tags inside the HUD's free rectangle.
func _safe_area_units() -> Array:
	var out: Array = []
	for list in [battle.party, battle.enemies]:
		for c in list:
			var m: Node3D = models.get(c)
			if m == null or not c.is_alive():
				continue
			var head_y: float = m.get_meta("head_y") if m.has_meta("head_y") else 1.8
			var enemy: bool = list == battle.enemies
			# Body box: feet, head and the sides (half width ~ 0.45 x height, measured from the model height).
			var r := maxf(0.45 * head_y, 0.5)
			var top := m.global_position + Vector3(0, head_y + (0.4 if enemy else 0.0), 0)
			var pts: Array[Vector3] = [m.global_position, top,
					m.global_position + Vector3(-r, 0, 0), m.global_position + Vector3(r, 0, 0),
					m.global_position + Vector3(-r, head_y * 0.6, 0), m.global_position + Vector3(r, head_y * 0.6, 0)]
			out.append({"pts": pts, "pad": BattleHud.tag_pad() if enemy else Vector4(0, 0, 0, 0),
					"leader": c == battle.party[0], "c": c})
	return out


func _make_model(c: Combatant, color: Color) -> Node3D:
	return CharacterModelLoader.create_character_model(c, color, true)


## D-1047: back to the previous fit for everyone, except Cyclops and Slime.
## Those two keep the target_height already defined in their DQT profiles
## (Cyclops 3.22 m, Slime 1.40 m), which gives exactly the two requested fixes.
func _fit_height(c: Combatant, model: Node3D) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(model):
		return
	var sid := String(c.species_id).to_lower()
	if sid == "dqt_cyclops":
		var h_cyclops := _visible_body_height(model)
		if h_cyclops > 0.05:
			# 0.99: the idle pose settles slightly taller after the fit.
			model.scale = model.scale * ((CYCLOPS_HEIGHT * 0.99) / h_cyclops)
			if fx != null and fx._base_scale.has(c):
				fx._base_scale[c] = model.scale
				fx._orig_scale[c] = model.scale
			c.body_scale = model.scale.x
		model.set_meta("head_y", _measure_head(model))
		return
	if sid == "dqt_slime":
		model.set_meta("head_y", _measure_head(model))
		return
	var h_now := _posed_height(model)
	if h_now > 0.05:
		model.scale = model.scale * (TARGET_HEIGHT / h_now)
		if fx != null and fx._base_scale.has(c):
			fx._base_scale[c] = model.scale
			fx._orig_scale[c] = model.scale
		c.body_scale = model.scale.x
		model.set_meta("head_y", _measure_head(model))


## D-1053: visible body height, excluding weapon/helper meshes.
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
		return _posed_height(model)
	return hi - lo


## D-1013 fallback: height from the skeleton's bones in their current pose.
func _posed_height(model: Node3D) -> float:
	var lo := INF
	var hi := -INF
	for sk in model.find_children("*", "Skeleton3D", true, false):
		var s3 := sk as Skeleton3D
		for i in s3.get_bone_count():
			var p := s3.global_transform * s3.get_bone_global_pose(i).origin
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
	if hi > lo:
		return (hi - model.global_position.y) * 0.56  # D-1013: bone span reads ~1.8x the visible height (calibrated on Abra: mesh 1.12, bones 2.01)
	return _model_height(model)


## D-1013: height of the visible meshes, in world units, at the model's current scale.
func _model_height(model: Node3D) -> float:
	var lo := INF
	var hi := -INF
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or mi.name == "BurstRing" or mi.name == "ReadyRing":
			continue
		var box: AABB = (model.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		lo = minf(lo, box.position.y)
		hi = maxf(hi, box.end.y)
	return (hi - lo) * model.scale.y if hi > lo else 0.0


## Top of the visible meshes in the model's own space (for floating tags).
func _measure_head(model: Node3D) -> float:
	var top := 0.0
	var inv := model.global_transform.affine_inverse()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.name == "BurstRing":
			continue
		var box: AABB = (inv * mi.global_transform) * mi.get_aabb()
		top = maxf(top, box.end.y)
	return top if top > 0.1 else 2.0


## The exported clips slide the "origin" bone forward (the run moves the body up to
## ~2.7 units per cycle). The script already moves the character, so that body
## drift made it run past its mark; keep only the vertical part of the root track.
func _strip_root_motion(ap: AnimationPlayer) -> void:
	for anim_name in ap.get_animation_list():
		var anim := ap.get_animation(anim_name)
		for i in anim.get_track_count():
			if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
				continue
			# ":origin" = Pokemon rigs; ":n_hara" = DQT hips (Y-up, same x/z lock).
			var track_path := str(anim.track_get_path(i))
			if not (track_path.ends_with(":origin") or track_path.ends_with(":n_hara")):
				continue
			var first: Vector3 = anim.track_get_key_value(i, 0)
			for k in anim.track_get_key_count(i):
				var v: Vector3 = anim.track_get_key_value(i, k)
				anim.track_set_key_value(i, k, Vector3(first.x, v.y, first.z))


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var res := _find_anim_player(child)
		if res:
			return res
	return null


func _on_died(c: Combatant) -> void:
	var by_burn: bool = c.has_meta("died_by_burn") and bool(c.get_meta("died_by_burn"))  # D-238
	if not c.is_player and not by_burn:
		# Inimigos são lançados balisticamente com VFX e shake épico via BattleFx (D-049);
		# quem morre queimado (D-238) só toca a animação de morte, sem lançamento.
		return
	var model: Node3D = models.get(c)
	if model and model.has_meta("anim_player"):
		var ap: AnimationPlayer = model.get_meta("anim_player")
		if ap.has_animation("down"):
			ap.play("down")
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(models[c], "scale", Vector3.ZERO, 0.4)


## A manual Evade by the leader slows the whole game (the Burst slow-motion) until the
## player executes the instant counter-action or the timer expires.
func _on_manual_evaded(actor: Combatant, inc) -> void:
	if actor != leader or not inc.perfect:
		return  # Slow-motion only with a perfect Evade, until the counter-attack (D-027).
	_slow_token += 1
	var token := _slow_token
	Engine.time_scale = SLOWMO_SCALE
	await get_tree().create_timer(SLOWMO_SECONDS, true, false, true).timeout
	if token == _slow_token:
		_end_slowmo()


func _end_slowmo() -> void:
	_slow_token += 1
	Engine.time_scale = 1.0


## D-1129: one hit interrupted an action. The hit itself already shakes the camera (D-157),
## so this event must not add a second shake.
func _on_interrupted_by_hit(inc) -> void:
	var actor: Combatant = inc.attacker if inc != null else null
	_note_interruption(actor, null, true)


func _on_hit_interrupted_windup(actor: Combatant, _source: Combatant) -> void:
	_note_interruption(actor, null, true)


## D-1129: War Cry (or another no-damage wind-up cancel) interrupted `actor`.
func _on_interrupted_windup(actor: Combatant, source: Combatant) -> void:
	_note_interruption(actor, source, false)


func _note_interruption(actor: Combatant, source: Combatant, already_shakes: bool) -> void:
	if actor == null:
		return
	if not _interrupt_batch.has(actor):
		_interrupt_batch[actor] = {"source": source, "already_shakes": already_shakes}
	else:
		var entry: Dictionary = _interrupt_batch[actor]
		entry["already_shakes"] = bool(entry.get("already_shakes", false)) or already_shakes
		if entry.get("source") == null:
			entry["source"] = source
	if not _interrupt_flush_queued:
		_interrupt_flush_queued = true
		call_deferred("_flush_interruptions")


## Every interruption this frame is one event: 2+ victims = multi-target (one effect, 6 s
## cooldown); a single victim always plays (even during the multi-target cooldown).
func _flush_interruptions() -> void:
	_interrupt_flush_queued = false
	var batch := _interrupt_batch
	_interrupt_batch = {}
	if batch.is_empty():
		return
	var now := Time.get_ticks_msec()
	var multi := batch.size() >= 2
	if multi and now < _interrupt_multi_ready_at:
		return
	var started := _start_interruption_slowmo()
	if multi and started:
		_interrupt_multi_ready_at = now + INTERRUPTION_MULTI_COOLDOWN_MS
	var already_shakes := false
	var source: Combatant = null
	var victim: Combatant = null
	for c in batch:
		var entry: Dictionary = batch[c]
		if bool(entry.get("already_shakes", false)):
			already_shakes = true
		if source == null and entry.get("source") != null:
			source = entry["source"]
			victim = c
	# Only the interruptions that had no shake of their own add one, and only once per event.
	if not already_shakes and source != null and victim != null and director != null:
		director.hit_shake(BattleSpace.flat_dir(source.pos, victim.pos), false, 1.0)


func _start_interruption_slowmo() -> bool:
	if _interrupt_slowmo_active or _decision_slowmo_active:
		return false
	if not is_equal_approx(Engine.time_scale, 1.0):
		return false  # Do not fight the Evade or menu slow-motion (D-027/D-047).
	_interrupt_slowmo_active = true
	_interrupt_slowmo_token += 1
	var token := _interrupt_slowmo_token
	Engine.time_scale = INTERRUPTION_SLOWMO_SCALE
	_run_interruption_slowmo(token)
	return true


func _run_interruption_slowmo(token: int) -> void:
	await get_tree().create_timer(INTERRUPTION_SLOWMO_SECONDS, true, false, true).timeout
	if token != _interrupt_slowmo_token or not _interrupt_slowmo_active:
		return
	if not is_equal_approx(Engine.time_scale, INTERRUPTION_SLOWMO_SCALE):
		_interrupt_slowmo_active = false  # Another slow-motion took over.
		return
	_interrupt_tween = create_tween().set_ignore_time_scale(true)
	_interrupt_tween.tween_property(Engine, "time_scale", 1.0, INTERRUPTION_SLOWMO_RETURN)
	_interrupt_tween.tween_callback(func() -> void:
		if token == _interrupt_slowmo_token:
			_interrupt_slowmo_active = false)


func _end_interruption_slowmo() -> void:
	_interrupt_slowmo_token += 1
	if _interrupt_tween != null and _interrupt_tween.is_valid():
		_interrupt_tween.kill()
	_interrupt_tween = null
	if _interrupt_slowmo_active:
		_interrupt_slowmo_active = false
		Engine.time_scale = 1.0


func _start_decision_slowmo(seconds := DECISION_SLOWMO_SECONDS) -> void:
	if not _decision_slowmo_available or _decision_slowmo_active:
		return
	_decision_slowmo_available = false
	_decision_slowmo_active = true
	_decision_slowmo_time_left = seconds
	_decision_slowmo_token += 1
	var token := _decision_slowmo_token
	Engine.time_scale = DECISION_SLOWMO_SCALE
	if director != null:
		director.set_decision_slowmo(true)
	_tick_decision_slowmo(token)


func _tick_decision_slowmo(token: int) -> void:
	while _decision_slowmo_active and token == _decision_slowmo_token:
		await get_tree().create_timer(0.05, true, false, true).timeout
		if not _decision_slowmo_active or token != _decision_slowmo_token:
			break
		_decision_slowmo_time_left -= 0.05
		if state == S.FIGHT:
			_update_fight_header(_menu.index)
		elif state == S.ITEMS:
			_update_items_header()
		if _decision_slowmo_time_left <= 0.0:
			_end_decision_slowmo()
			break


func _end_decision_slowmo() -> void:
	if not _decision_slowmo_active:
		return
	_decision_slowmo_active = false
	_decision_slowmo_time_left = 0.0
	_decision_slowmo_token += 1
	if Engine.time_scale == DECISION_SLOWMO_SCALE:
		Engine.time_scale = 1.0
	if director != null:
		director.set_decision_slowmo(false)
	if state == S.FIGHT:
		_update_fight_header(_menu.index)
	elif state == S.ITEMS:
		_update_items_header()


func _on_player_action_executed() -> void:
	_decision_slowmo_available = true
	_end_decision_slowmo()


func _exit_tree() -> void:
	_end_decision_slowmo()
	_end_interruption_slowmo()  # D-1129
	Engine.time_scale = 1.0
	if is_inside_tree():
		get_tree().paused = false


func _on_battle_ended(player_won: bool) -> void:
	_end_decision_slowmo()
	_end_interruption_slowmo()  # D-1129
	_end_slowmo()
	fx.finish(player_won)
	_menu.hide()
	hud.set_target(null)

	if player_won:
		_trigger_victory_flow()
	else:
		await get_tree().create_timer(3.0, true, false, true).timeout
		GameState.end_battle(false)


func _trigger_victory_flow() -> void:
	# 1. Desacelera suavemente o combate antes de abrir o painel (D-400)
	var tween := create_tween()
	tween.tween_property(Engine, "time_scale", 0.2, 0.6)
	await tween.finished

	# 2. Computa soma de XP dos inimigos abatidos (D-399)
	var total_xp: int = 0
	for enemy in battle.enemies:
		if enemy != null:
			total_xp += CrawlmonAttributeMath.get_enemy_xp_drop(enemy.base_experience, enemy.level)

	# 3. Concede XP apenas para membros sobreviventes (D-402)
	var party_summaries: Array[Dictionary] = []
	for member in battle.party:
		if member == null:
			continue
		if member.is_alive():
			var res: Dictionary = member.add_experience(total_xp)
			res["combatant"] = member
			res["is_alive"] = true
			party_summaries.append(res)
		else:
			party_summaries.append({
				"combatant": member,
				"is_alive": false,
				"old_level": member.level,
				"new_level": member.level,
				"levels_gained": 0,
				"points_gained": 0,
				"old_xp": member.xp,
				"current_xp": member.xp,
				"xp_required": CrawlmonAttributeMath.get_xp_for_level_transition(member.level),
				"transitions": []
			})

	# 4. Verifica se algum membro da equipe subiu de nivel (D-433)
	var any_leveled_up := false
	for s in party_summaries:
		if s.get("levels_gained", 0) > 0:
			any_leveled_up = true
			break

	if any_leveled_up:
		# Exibe o LevelUpHUD unificado (D-401, D-418, D-420, D-433)
		get_tree().paused = true
		var level_up_scene: PackedScene = load("res://scenes/ui/level_up_hud.tscn")
		var hud = level_up_scene.instantiate() as LevelUpHUD
		ui.add_child(hud)
		hud.open(party_summaries, total_xp)
		await hud.completed
		get_tree().paused = false

	# 5. Restaura escala de tempo e finaliza combate (se ninguem subiu de nivel, retorna direto para masmorra por D-433)
	Engine.time_scale = 1.0
	GameState.end_battle(true)


# --- Command flow ----------------------------------------------------------

func _refresh() -> void:
	for c in models:
		(models[c].get_node("BurstRing") as Node3D).visible = c.burst > 0
	_menu.visible = leader.is_alive() and battle.running
	if state == S.MAIN:
		_update_main_enabled()
		if leader.queued_skill != _shown_queue:
			_shown_queue = leader.queued_skill
			hud.set_menu_style(FanMenu.Style.FAN, _main_title())
	elif state == S.FIGHT:
		var sig := _fight_signature()
		if sig != _fight_sig:
			_fight_sig = sig
			_fill_fight(true)
			_update_fight_header(_menu.index)


func _set_state(s: S) -> void:
	var was_target := state == S.TARGET
	state = s
	# Tactics and Status pause the whole game while they are open.
	get_tree().paused = s == S.TACTICS or s == S.STATUS
	if s != S.TARGET and s != S.FIGHT:
		hud.set_target(null)  # The target tag stays lit while the move list is open.
	if s != S.FIGHT:
		hud.hide_skill_info()  # The move sheet belongs to the Fight list only.
		_menu.note = ""
	if was_target and s != S.TARGET:
		director.cinema()


func _consumables() -> Array[Item]:
	return GameState.items_of_kind(Item.Kind.CONSUMABLE)


## The move waiting in the slot, if any, is shown over the menu (D-161).
func _main_title() -> String:
	# D-982: the "01 / CHOOSE YOUR ACTION" title was removed; only the queued move is shown, when there is one.
	return "" if leader.queued_skill == null else "QUEUE: %s" % leader.queued_skill.display_name


## What the open move list depends on: it is redrawn when any of this changes.
func _fight_signature() -> Array:
	return [battle.can_start_now(leader), floori(leader.blocks()), leader.burst, leader.is_stunned(),
		leader.is_guarding(), battle.is_status_paused()]


func _show_main() -> void:
	_set_state(S.MAIN)
	_shown_queue = leader.queued_skill
	hud.set_menu_style(FanMenu.Style.FAN, _main_title())
	_menu.set_entries(_main_entries())
	_menu.select(_last_main)
	_refresh()


func _main_entries() -> Array:
	var third: Dictionary = {"text": "Evade", "detail": "%d ATB" % int(battle.evade_cost(leader))}
	if _guard_mode:  # D-272: blue block with a shield.
		third = {"text": "Guard", "detail": "%d ATB" % int(Battle.GUARD_BLOCKS), "hilite": FanMenu.GUARD_BLUE, "shield": true}
	return [
		{"text": "Fight", "detail": "%d ATB" % int(Battle.min_skill_cost(leader))},
		{"text": "Items", "detail": "%d ATB" % int(Battle.ITEM_BLOCKS)},
		third,
		{"text": "Tactics", "detail": "PAUSE"},
		{"text": "Status", "detail": "PAUSE"},
	]


func _update_main_enabled() -> void:
	var min_cost := Battle.min_skill_cost(leader)
	var guarding := leader.is_guarding()  # D-1146: Guard cannot hold a queue slot either.
	var waits := not battle.can_start_windup_now(leader, Skill.basic()) and not guarding  # D-1159: an attack may start during the pause
	var can_fight := not leader.is_stunned() and not guarding and (waits or leader.can_pay(min_cost))
	_menu.set_enabled(0, can_fight)
	var fight_detail := "queue" if can_fight and waits else (("FREE" if leader.burst > 0 else "%d ATB" % int(min_cost)) if can_fight else ("GUARD" if guarding else ("stunned" if leader.is_stunned() else "need ATB")))
	_menu.set_detail(0, fight_detail)
	var can_item := not guarding and not battle.is_status_paused() \
		and leader.can_pay(Battle.ITEM_BLOCKS) and not _consumables().is_empty()
	_menu.set_enabled(1, can_item)
	var item_why := "%d ATB" % int(Battle.ITEM_BLOCKS)
	if guarding:
		item_why = "GUARD"
	elif battle.is_status_paused():
		item_why = "PAUSE"
	elif _consumables().is_empty():
		item_why = "no items"
	elif not leader.can_pay(Battle.ITEM_BLOCKS):
		item_why = "need ATB"
	_menu.set_detail(1, item_why)
	if _guard_mode:
		var why_not := battle.guard_block_reason(leader)
		_menu.set_enabled(2, why_not == "")
		_menu.set_detail(2, "%d ATB" % int(Battle.GUARD_BLOCKS) if why_not == "" else why_not)
		return
	var can_evade := battle.find_evadable(leader) != null
	_menu.set_enabled(2, can_evade)
	var why := "%d ATB" % int(battle.evade_cost(leader))
	if not can_evade:
		why = "engaged" if leader.engaged_with != null else ("acting" if battle.is_attacking(leader) else ("need ATB" if leader.blocks() < battle.evade_cost(leader) else "nothing to dodge"))
	_menu.set_detail(2, why)


func _show_fight() -> void:
	_set_state(S.FIGHT)
	_build_fight_skills()
	_fight_sig = _fight_signature()
	_fight_target = _default_target()
	hud.set_target(_fight_target)
	_focus_fight_target()
	_fight_page = 0
	for n in _fight_skills.size():
		if _fight_skills[n].display_name == _last_skill:
			_fight_page = floori(float(n) / float(FIGHT_SLOTS))
	_fill_fight(false)
	for n in _fight_skills.size():
		if _fight_skills[n].display_name == _last_skill:
			_menu.select(n - _fight_page * FIGHT_SLOTS)
	if _decision_slowmo_available:
		_start_decision_slowmo(FIGHT_SLOWMO_SECONDS)
	_update_fight_header(_menu.index)


## The Fight menu uses the same high, wide TATICA framing as item target picking.
## The glide ignores the decision slow-motion so the camera does not crawl.
func _focus_fight_target() -> void:
	if _fight_target == null or not models.has(_fight_target):
		return
	var model: Node3D = models[_fight_target]
	if model != null and is_instance_valid(model):
		director.tactical(model.global_position, BattleCamera.GLIDE, true)


## Back to the base framing when the move list closes without a starting action.
func _leave_fight_camera() -> void:
	if not battle.is_attacking(leader):
		director.cinema()


func _build_fight_skills() -> void:
	_fight_skills.clear()
	_fight_skills.append(Skill.basic())
	_fight_skills.append_array(leader.skills)


## The opponent a move goes to when none was picked: the engaged one, the last target
## still alive, or the first one alive.
func _default_target() -> Combatant:
	if leader.engaged_with != null and leader.engaged_with.is_alive():
		return leader.engaged_with
	var first: Combatant = null
	for e in battle.enemies:
		if not e.is_alive():
			continue
		if first == null:
			first = e
		if e.name == _last_target:
			return e
	return first


## The move list with, for the current target: estimated damage, a weakness tag, the best
## move starred and the reason (or "free" with Burst) for the price.
func _fill_fight(keep_index: bool) -> void:
	var target := _fight_target
	var best := -1
	var best_dmg := -1
	for n in _fight_skills.size():
		var sk := _fight_skills[n]
		if target != null and leader.can_pay(sk.cost):
			var dmg := Battle.estimate_damage(leader, target, sk)
			if dmg > best_dmg:
				best_dmg = dmg
				best = n
	var pages := maxi(1, ceili(float(_fight_skills.size()) / float(FIGHT_SLOTS)))
	_fight_page = clampi(_fight_page, 0, pages - 1)
	var offset := _fight_page * FIGHT_SLOTS
	var entries: Array = []
	var is_stunned := leader.is_stunned()
	var guarding := leader.is_guarding()
	for n in range(offset, mini(offset + FIGHT_SLOTS, _fight_skills.size())):
		var sk := _fight_skills[n]
		var waits := not battle.can_start_windup_now(leader, sk) and not guarding  # D-1159: attacks start in the pause; status waits
		var has_mp := leader.mp >= sk.mp_cost
		var affordable := not is_stunned and not guarding and has_mp and (waits or leader.can_pay(sk.cost))
		var price := "FREE" if leader.burst > 0 else "%d ATB" % sk.cost
		if is_stunned:
			price = "STUNNED (%.1fs)" % leader.stun_timer
		elif guarding:
			price = "GUARD"
		elif not has_mp:
			price = "NEED %d MP" % (sk.mp_cost - leader.mp)
		elif waits:
			price = "queue | " + price
		elif not leader.can_pay(sk.cost):
			price = "need %d ATB" % int(ceilf(sk.cost - leader.blocks()))
		var mp_str := "%d MP" % sk.mp_cost
		var cost_str := "%s · %s" % [price, mp_str]
		var tail := ""
		var accent := Color(0, 0, 0, 0)
		if sk.is_aoe:
			tail += " | [AoE]"
		elif sk.is_friendly:
			tail += " | [TEAM]"
		if target != null:
			if sk.kind == Skill.Kind.STATUS:
				tail += " | status"
			else:
				var affinity := target.affinity_for(sk.element)
				var tag := ""
				if affinity == Affinity.Type.WEAK:
					tag = " WEAK"
				elif affinity == Affinity.Type.RESIST:
					tag = " RESIST"
				tail += " | ~%d%s" % [Battle.estimate_damage(leader, target, sk), tag]
				if affinity == Affinity.Type.WEAK:
					accent = Color("ffd45a")
		entries.append({
			"text": "%d %s%s" % [n - offset + 1, "★ " if n == best else "", sk.display_name],
			"detail": "%s%s" % [cost_str, tail],
			"enabled": affordable,
			"accent": accent,
			"skill": sk,
		})
	_menu.set_entries(entries, keep_index)


## Header strip: the highlighted move's category and travel time to the current target.
func _update_fight_header(i: int) -> void:
	var offset := _fight_page * FIGHT_SLOTS
	var idx := offset + i
	if i < 0 or idx < 0 or idx >= _fight_skills.size():
		return
	var sk := _fight_skills[idx]
	var text := Skill.kind_name(sk.kind).to_upper()
	if sk.is_aoe:
		text += " (AoE)"
	elif sk.is_friendly:
		text += " (SUPPORT)"
	if _fight_target != null and (sk.kind == Skill.Kind.MELEE or sk.kind == Skill.Kind.PROJECTILE):
		text += " %.2fs" % AttackPlanner.preview_travel(leader, _fight_target, sk.kind)
	var pages := maxi(1, ceili(float(_fight_skills.size()) / float(FIGHT_SLOTS)))
	var notes: Array[String] = []
	if pages > 1:
		notes.append("PAGE %d/%d | Q/E SWITCH" % [_fight_page + 1, pages])
	if _decision_slowmo_active:
		notes.append("⏳ %.1fs" % maxf(_decision_slowmo_time_left, 0.0))
	_menu.note = " · ".join(notes)
	hud.set_menu_style(FanMenu.Style.DRAWER, text)
	hud.show_skill_info(sk, _fight_target)


## Q/E: swap the Fight page and highlight its first row.
func _change_fight_page(step: int) -> void:
	var pages := maxi(1, ceili(float(_fight_skills.size()) / float(FIGHT_SLOTS)))
	if pages <= 1:
		return
	_fight_page = posmod(_fight_page + step, pages)
	_fill_fight(false)
	_menu.select(0)
	_update_fight_header(0)


## Uses a move on a target right now (Fight menu, number keys and Repeat all end here).
func _use_move(skill: Skill, target: Combatant) -> bool:
	if skill.is_friendly:
		if target == null or not target.is_alive() or target.is_player != leader.is_player:
			target = leader
	elif target == null or not target.is_alive():
		return false
	if leader.is_stunned() or leader.is_guarding() or (battle.can_start_windup_now(leader, skill) and not leader.can_pay(skill.cost)) or leader.mp < skill.mp_cost:
		return false
	_last_skill = skill.display_name
	_last_target = target.name
	var ok := battle.request_skill(leader, skill, target)
	if ok:
		_end_decision_slowmo()  # Confirmed. The next slow-motion comes once it really starts.
	return ok


func _move_by_name(skill_name: String) -> Skill:
	for sk in _fight_skills:
		if sk.display_name == skill_name:
			return sk
	return null


func _show_items() -> void:
	_set_state(S.ITEMS)
	_item_list = _consumables()
	var entries: Array = []
	var is_stunned := leader.is_stunned()
	var guarding := leader.is_guarding()
	var paused := battle.is_status_paused()
	for item in _item_list:
		var price := "x%d" % leader.item_count(item.id)
		if is_stunned:
			price += " · ATORDOADO"
		elif guarding:
			price += " · GUARD"
		elif paused:
			price += " · PAUSE"
		entries.append({"text": item.display_name, "detail": price, "enabled": not is_stunned and not guarding and not paused and leader.can_pay(Battle.ITEM_BLOCKS)})
	if entries.is_empty():
		entries.append({"text": "(vazio)", "enabled": false})
	_menu.set_entries(entries)
	if _decision_slowmo_available:
		_start_decision_slowmo()
	_update_items_header()


func _update_items_header() -> void:
	var text := "ITEMS // 1 ATB"
	if _decision_slowmo_active:
		text += " · ⏳ %.1fs" % maxf(_decision_slowmo_time_left, 0.0)
	hud.set_menu_style(FanMenu.Style.DRAWER, text)


func _show_status() -> void:
	_set_state(S.STATUS)
	director.process_mode = Node.PROCESS_MODE_ALWAYS  # The camera keeps gliding while paused.
	hud.open_status(battle.party, battle.enemies)


## Frame the selected unit; only its animation keeps playing while paused.
func _on_status_unit(c: Combatant) -> void:
	if _status_unit != null:
		_set_unit_animating(_status_unit, false)
	_status_unit = c
	_set_unit_animating(c, true)
	var model: Node3D = models[c]
	director.status_shot(model.global_position, c.is_player)


func _set_unit_animating(c: Combatant, on: bool) -> void:
	var model: Node3D = models.get(c)
	if model == null or not model.has_meta("anim_player"):
		return
	var ap: AnimationPlayer = model.get_meta("anim_player")
	if on:
		_saved_anim[ap] = [ap.current_animation, ap.current_animation_position]
		ap.process_mode = Node.PROCESS_MODE_ALWAYS
		if ap.has_animation("battle_idle"):
			ap.play("battle_idle", 0.2)
	else:
		ap.process_mode = Node.PROCESS_MODE_INHERIT
		var saved: Array = _saved_anim.get(ap, [])
		if saved.size() == 2 and saved[0] != "" and ap.has_animation(saved[0]):
			ap.play(saved[0])
			ap.seek(saved[1], true)
		_saved_anim.erase(ap)


func _close_status() -> void:
	if _status_unit != null:
		_set_unit_animating(_status_unit, false)
		_status_unit = null
	director.process_mode = Node.PROCESS_MODE_INHERIT
	director.cinema()
	_show_main()


func _show_tactics() -> void:
	_set_state(S.TACTICS)
	hud.set_menu_style(FanMenu.Style.DRAWER, "TACTICS // ALLY AI")
	_fill_tactics(false)


func _fill_tactics(keep_index: bool) -> void:
	var entries: Array = []
	_tactic_rows.clear()
	for i in battle.party.size():
		var a := battle.party[i]
		if i > 0:
			entries.append({"text": "%s | Action" % a.name, "detail": ACT_NAMES[a.act_policy]})
			_tactic_rows.append({"unit": a, "kind": "act"})
			entries.append({"text": "%s | Reaction" % a.name, "detail": REACT_NAMES[a.react_policy]})
			_tactic_rows.append({"unit": a, "kind": "react"})
		entries.append({"text": "%s | Position  (←/→, 1 ATB)" % a.name, "detail": _pos_text(a, i == 0)})
		_tactic_rows.append({"unit": a, "kind": "pos"})
	_menu.set_entries(entries, keep_index)


## "< - - O - - >": O = where it stands, o = where an AI ally is heading.
func _pos_text(c: Combatant, is_leader: bool) -> String:
	var marks := PackedStringArray()
	for p in range(-Battle.STEP_MAX, Battle.STEP_MAX + 1):
		marks.append("O" if p == c.pos_step else ("o" if not is_leader and p == c.tactic_pos else "-"))
	var text := "< " + " ".join(marks) + " >"
	var why := battle.step_block_reason(c) if is_leader else ""
	return text + ("  (%s)" % why if why != "" else "")


## Left/right on a Position row: the leader steps now (1 ATB); an ally's AI is told
## where to stand and walks there by itself.
func _on_menu_side(direction: int) -> void:
	if state == S.MAIN:
		# D-272: on the Evade block, right swaps it for the Guard block and left swaps it back.
		if _menu.index == 2 and (direction > 0) != _guard_mode:
			_guard_mode = direction > 0
			_menu.set_entries(_main_entries(), true)
			_refresh()
		return
	if state == S.FIGHT:
		# Left/right changes the target without leaving the move list.
		if leader.engaged_with != null:
			return  # Engaged: it can only act on that opponent.
		var alive: Array[Combatant] = []
		for e in battle.enemies:
			if e.is_alive():
				alive.append(e)
		if alive.size() > 1:
			_fight_target = alive[posmod(alive.find(_fight_target) + direction, alive.size())]
			hud.set_target(_fight_target)
			_fill_fight(true)
			_update_fight_header(_menu.index)
			_focus_fight_target()
		return
	if state != S.TACTICS or _menu.index >= _tactic_rows.size():
		return
	var row: Dictionary = _tactic_rows[_menu.index]
	if row["kind"] != "pos":
		return
	var u: Combatant = row["unit"]
	if u == leader:
		battle.step(leader, direction)
	else:
		u.tactic_pos = clampi(u.tactic_pos + direction, -Battle.STEP_MAX, Battle.STEP_MAX)
	_fill_tactics(true)


func _pick_target(candidates: Array[Combatant], on_target: Callable, back: Callable) -> void:
	if leader.engaged_with != null and leader.engaged_with.is_alive() and candidates == battle.enemies:
		var only: Array[Combatant] = [leader.engaged_with]  # Engaged: it can only act on that opponent.
		candidates = only
	var alive := candidates.filter(func(c: Combatant) -> bool: return c.is_alive())
	if alive.size() == 1 and alive[0] != leader and not alive[0].is_player:
		on_target.call(alive[0])  # Only one possible enemy: no need to pick.
		if battle.running:
			_show_main()
		return
	_set_state(S.TARGET)
	hud.set_menu_style(FanMenu.Style.DRAWER, "CHOOSE TARGET")
	_targets.assign(alive)
	_on_target = on_target
	_back = back
	var entries: Array = []
	for t in _targets:
		entries.append({"text": t.name, "detail": _target_brief(t)})
	_menu.set_entries(entries)
	for n in _targets.size():
		if _targets[n].name == _last_target:
			_menu.select(n)


## Compact target line for the picker: HP plus the statuses that change the choice.
func _target_brief(t: Combatant) -> String:
	var bits: Array[String] = ["HP %d/%d" % [t.hp, t.max_hp]]
	if t.is_shielded():
		bits.append("S%d" % t.shield_hp)
	if t.is_guarding():
		bits.append("G%.1fs" % t.guard_timer)
	if t.is_blind():
		bits.append("BLIND")
	if t.is_burning():
		bits.append("BURN")
	if t.is_stunned():
		bits.append("STUN")
	if t.queued_skill != null:
		bits.append("QUEUE")
	var has_weak := false
	for entry in t.affinity_entries():
		if int(entry["type"]) == Affinity.Type.WEAK:
			has_weak = true
			break
	if has_weak:
		bits.append("WEAK")
	return " · ".join(bits)


func _on_chosen(i: int) -> void:
	match state:
		S.MAIN:
			_last_main = i
			match i:
				0: _show_fight()
				1: _show_items()
				2:
					if _guard_mode:
						battle.use_guard(leader)
					else:
						battle.try_evade(leader, battle.find_evadable(leader))
				3: _show_tactics()
				4: _show_status()
		S.FIGHT:
			var idx := _fight_page * FIGHT_SLOTS + i
			if idx < 0 or idx >= _fight_skills.size():
				return
			var sk := _fight_skills[idx]
			if leader.mp < sk.mp_cost:
				return
			var tgt: Combatant = leader if sk.is_friendly else (_fight_target if _fight_target != null and _fight_target.is_alive() else _default_target())
			if _use_move(sk, tgt):
				_leave_fight_camera()
				_show_main()
		S.ITEMS:
			if leader.is_guarding() or battle.is_status_paused():  # D-1146
				_menu.note = "ITEMS BLOCKED NOW"
				return
			var item := _item_list[i]
			_pick_target(battle.party,
				func(t: Combatant) -> void:
					var ok := battle.use_item(leader, item, t)
					if ok:
						_on_player_action_executed(),
				_show_items)
		S.TARGET:
			_last_target = _targets[i].name
			_on_target.call(_targets[i])
			if battle.running:
				_show_main()
		S.TACTICS:
			var row: Dictionary = _tactic_rows[i]
			var ally: Combatant = row["unit"]
			if row["kind"] == "act":
				ally.act_policy = (ally.act_policy + 1) % ACT_NAMES.size()
			elif row["kind"] == "react":
				ally.react_policy = (ally.react_policy + 1) % REACT_NAMES.size()
			_fill_tactics(true)


func _on_cancel() -> void:
	_end_decision_slowmo()
	match state:
		S.FIGHT:
			_leave_fight_camera()
			_show_main()
		S.ITEMS, S.TACTICS:
			_show_main()
		S.TARGET:
			_back.call()


func _on_moved(i: int) -> void:
	if state == S.FIGHT:
		_update_fight_header(i)
	elif state == S.ITEMS:
		_update_items_header()
	if state == S.TARGET and i < _targets.size():
		var target := _targets[i]
		hud.set_target(target)
		director.tactical((models[target] as Node3D).global_position)
