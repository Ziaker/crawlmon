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
const ENEMY_SCALE := 2.16  ## Extra scale on enemy models so they read at 30 units (D-339: 1.8 +20%).
const ACT_NAMES := ["Atacar", "Habilidades", "Segurar"]
const REACT_NAMES := ["Nada", "Esquivar"]
const BattleArena = preload("res://scripts/combat/battle_arena.gd")
const BattleFx = preload("res://scripts/combat/battle_fx.gd")
const BattleCamera = preload("res://scripts/combat/battle_camera.gd")
const BattleHud = preload("res://scripts/ui/battle_hud.gd")
const SmtBuffController = preload("res://scripts/vfx/smt/smt_buff_controller.gd")

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

var _slow_token := 0
var _shown_queue: Skill = null  ## The queued move the menu title shows now (D-161).
var _fight_sig: Array = []  ## See _fight_signature().
var _decision_slowmo_available := true  ## Reset to true whenever the player performs an action (D-047).
var _decision_slowmo_active := false
var _decision_slowmo_time_left := 0.0
var _decision_slowmo_token := 0
var _status_unit: Combatant
var _saved_anim: Dictionary = {}  ## AnimationPlayer -> [name, position]

var _menu: FanMenu
var _last_main := 0  ## Last command picked on the main menu (it reopens there).
var _fight_target: Combatant  ## The opponent highlighted while the move list is open.
var _last_skill := ""  ## Last Fight skill and target, by name.
var _last_target := ""
var _tactic_rows: Array = []  ## {unit, kind: act | react | pos} per Tactics row
var _fight_skills: Array[Skill] = []
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
	var enemies: Array[Combatant] = [_new_gible()]
	if has_meta("vfx_room_mirror"):  # Sala de VFX: times espelhados (Gible aliado; Abra e Pancham inimigos).
		party = _debug_mirror_party()
		enemies = _debug_mirror_enemies()
	# Crossover pilot: --dqt puts the DQT trio on the player's side; --dqt-mirror
	# puts them on the enemy side so their fronts face the camera.
	if "--dqt-mirror" in OS.get_cmdline_user_args():
		var solo: Array[Combatant] = [GameState.party[0]]
		party = solo
		enemies = DqtTestParty.build(false)
	elif DqtTestParty.enabled or "--dqt" in OS.get_cmdline_user_args():
		party = DqtTestParty.build(true, GameState.inventory)
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
	battle.hit_resolved.connect(fx.play_hit)
	battle.guard_started.connect(fx.fx_guard.start)  # D-272
	battle.guard_ended.connect(fx.fx_guard.stop)
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
	# 1-9 use that move of the list on the current target; R repeats the last move.
	if event is InputEventKey and event.pressed and not event.echo and battle.running and leader.is_alive() \
			and (state == S.MAIN or state == S.FIGHT):
		var slot: int = event.keycode - KEY_1
		var skill: Skill = null
		_build_fight_skills()
		if slot >= 0 and slot < 9 and slot < _fight_skills.size():
			skill = _fight_skills[slot]
		elif event.keycode == KEY_R:
			skill = _move_by_name(_last_skill)
		if skill != null:
			var target := _fight_target if state == S.FIGHT and _fight_target != null and _fight_target.is_alive() else _default_target()
			if _use_move(skill, target):
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
	var e := Combatant.new("Gible", 38, 9, 0.42, false)
	e.weaknesses.assign([Element.Type.AGUA_GELO])
	e.skills.assign([
		Skill.new("Bite", 1.3, 2, Element.Type.TREVAS, Skill.Kind.MELEE, false, false, false, 1.2),
		Skill.new("Sand Attack", 0.0, 1, Element.Type.TERRA, Skill.Kind.PROJECTILE, true, false, false, 0.75),
		Skill.new("Dragon Rage", 1.6, 3, Element.Type.FISICO, Skill.Kind.PROJECTILE, false, false, false, 2.0, true),
		Skill.new("Dig", 1.5, 2, Element.Type.TERRA, Skill.Kind.MELEE, true, false, false, 1.0),
		Skill.new("Dragon Claw", 1.6, 3, Element.Type.FISICO, Skill.Kind.MELEE, false, false, false, 1.5),
		Skill.new("Rakunda", 0.0, 1, Element.Type.TREVAS, Skill.Kind.STATUS, false, false, false, 0.5),
		Skill.new("Mabufula", 1.35, 2, Element.Type.AGUA_GELO, Skill.Kind.PROJECTILE, false, true, false, 1.5),
		Skill.new("Titanomachia", 1.5, 3, Element.Type.TERRA, Skill.Kind.MELEE, false, true, false, 1.5),
	])
	e.inventory = {"potion": 1}
	return e


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
		if not c.is_player:
			model.scale = Vector3.ONE * ENEMY_SCALE
		else:  # D-342: some DQT models read too small on the player's side
			var dqt_prof := DqtModelProfiles.get_profile(c.species_id.to_lower())
			if dqt_prof.has("ally_scale"):
				model.scale = Vector3.ONE * float(dqt_prof["ally_scale"])
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


func _make_model(c: Combatant, color: Color) -> Node3D:
	var root := Node3D.new()
	var model_id := c.name.to_lower()
	if c.species_id != "":
		model_id = c.species_id.to_lower()
	var glb_path := "res://assets/modelos/%s/%s.glb" % [model_id, model_id]
	var dqt_profile := DqtModelProfiles.get_profile(model_id)

	var is_3d_pokemon := false
	if ResourceLoader.exists(glb_path):
		var glb_scene: PackedScene = load(glb_path)
		if glb_scene:
			var pokemon_instance := glb_scene.instantiate()
			# Pokemon GLBs come out of Blender Z-up: tip them upright and scale up.
			# DQT GLBs are already Y-up, so they only get the height fit.
			if dqt_profile.is_empty():
				pokemon_instance.rotation_degrees.x = 90.0
				pokemon_instance.scale = Vector3.ONE * MODEL_SCALE
			else:
				pokemon_instance.rotation_degrees = Vector3(
					0.0, float(dqt_profile.get("rotation_y", 0.0)), 0.0)
				var native_height := float(dqt_profile.get("native_height", 0.0))
				var target_height := float(dqt_profile.get("target_height", 0.0))
				if native_height > 0.001 and target_height > 0.001:
					pokemon_instance.scale = Vector3.ONE * (target_height / native_height)
				# The tactlib 2.x GLBs already carry glTF-correct UVs: no runtime V flip.
			if dqt_profile.is_empty():
				root.add_child(pokemon_instance)
			else:
				var breath := Node3D.new()
				breath.name = "DqtIdleBreath"
				breath.set_meta("height", float(dqt_profile.get("target_height", 2.0)))
				root.add_child(breath)
				breath.add_child(pokemon_instance)
			VfxLib.outline_model(pokemon_instance, 0.0035)
			is_3d_pokemon = true

			var anim_player: AnimationPlayer = _find_anim_player(pokemon_instance)
			if anim_player:
				if not dqt_profile.is_empty():
					DqtModelProfiles.apply_anim_aliases(anim_player, dqt_profile)
					DqtModelProfiles.setup_weapon_follow(pokemon_instance, anim_player, dqt_profile)
					# D-340: game eye rule (<X>_scale) + own blink.
					DqtEyes.attach(root, pokemon_instance, anim_player,
						str(dqt_profile.get("clip_prefix", "")) + "04")
					DqtModelProfiles.setup_run_stride(root, pokemon_instance, anim_player, dqt_profile)  # D-341
				root.set_meta("anim_player", anim_player)
				_strip_root_motion(anim_player)
				# Configure linear loops for resting animations
				for anim_name in ["idle", "battle_idle", "walk", "run", "charge"]:
					if anim_player.has_animation(anim_name):
						anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
				if not dqt_profile.is_empty() and dqt_profile.get("idle_full", false):
					if anim_player.has_animation("battle_idle"):
						anim_player.get_animation("battle_idle").loop_mode = Animation.LOOP_NONE
				if anim_player.has_animation("battle_idle"):
					anim_player.play("battle_idle")
				elif anim_player.has_animation("idle"):
					anim_player.play("idle")

	if not is_3d_pokemon:
		var mesh := MeshInstance3D.new()
		mesh.mesh = CapsuleMesh.new()
		mesh.position.y = 1.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mesh.material_override = mat
		root.add_child(mesh)
		root.set_meta("mesh", mesh)

	root.set_meta("color", color)

	var ring := MeshInstance3D.new()
	ring.name = "BurstRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.1
	ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.8, 0.1)
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_mat
	ring.position.y = 0.05
	ring.visible = false
	root.add_child(ring)
	root.set_meta("burst_ring", ring)
	return root


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
	Engine.time_scale = 1.0
	if is_inside_tree():
		get_tree().paused = false


func _on_battle_ended(player_won: bool) -> void:
	_end_decision_slowmo()
	_end_slowmo()
	fx.finish(player_won)
	_menu.hide()
	hud.set_target(null)
	await get_tree().create_timer(3.0, true, false, true).timeout
	GameState.end_battle(player_won)


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


func _set_state(s: S) -> void:
	var was_target := state == S.TARGET
	state = s
	# Tactics and Status pause the whole game while they are open.
	get_tree().paused = s == S.TACTICS or s == S.STATUS
	if s != S.TARGET and s != S.FIGHT:
		hud.set_target(null)  # The target tag stays lit while the move list is open.
	if was_target and s != S.TARGET:
		director.cinema()


func _consumables() -> Array[Item]:
	return GameState.items_of_kind(Item.Kind.CONSUMABLE)


## The move waiting in the slot, if any, is shown over the menu (D-161).
func _main_title() -> String:
	var title := "01 / ESCOLHA SUA AÇÃO"
	return title if leader.queued_skill == null else "%s · FILA: %s" % [title, leader.queued_skill.display_name]


## What the open move list depends on: it is redrawn when any of this changes.
func _fight_signature() -> Array:
	return [battle.can_start_now(leader), floori(leader.blocks()), leader.burst, leader.is_stunned()]


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
		{"text": "Itens", "detail": "%d ATB" % int(Battle.ITEM_BLOCKS)},
		third,
		{"text": "Tactics", "detail": "PAUSA"},
		{"text": "Status", "detail": "PAUSA"},
	]


func _update_main_enabled() -> void:
	var min_cost := Battle.min_skill_cost(leader)
	var waits := not battle.can_start_now(leader)  # Busy or paused: the choice goes to the slot (D-161).
	var can_fight := not leader.is_stunned() and (waits or leader.can_pay(min_cost))
	_menu.set_enabled(0, can_fight)
	var fight_detail := "fila" if can_fight and waits else (("GRÁTIS" if leader.burst > 0 else "%d ATB" % int(min_cost)) if can_fight else ("atordoado" if leader.is_stunned() else "falta ATB"))
	_menu.set_detail(0, fight_detail)
	var can_item := leader.can_pay(Battle.ITEM_BLOCKS) and not _consumables().is_empty()
	_menu.set_enabled(1, can_item)
	_menu.set_detail(1, "%d ATB" % int(Battle.ITEM_BLOCKS) if can_item else ("sem itens" if _consumables().is_empty() else "falta ATB"))
	if _guard_mode:
		var why_not := battle.guard_block_reason(leader)
		_menu.set_enabled(2, why_not == "")
		_menu.set_detail(2, "%d ATB" % int(Battle.GUARD_BLOCKS) if why_not == "" else why_not)
		return
	var can_evade := battle.find_evadable(leader) != null
	_menu.set_enabled(2, can_evade)
	var why := "%d ATB" % int(battle.evade_cost(leader))
	if not can_evade:
		why = "engajado" if leader.engaged_with != null else ("em ação" if battle.is_attacking(leader) else ("falta ATB" if leader.blocks() < battle.evade_cost(leader) else "nada a desviar"))
	_menu.set_detail(2, why)


func _show_fight() -> void:
	_set_state(S.FIGHT)
	_build_fight_skills()
	_fight_sig = _fight_signature()
	_fight_target = _default_target()
	hud.set_target(_fight_target)
	_fill_fight(false)
	for n in _fight_skills.size():
		if _fight_skills[n].display_name == _last_skill:
			_menu.select(n)
	if _decision_slowmo_available:
		_start_decision_slowmo(FIGHT_SLOWMO_SECONDS)
	_update_fight_header(_menu.index)


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
	var entries: Array = []
	var is_stunned := leader.is_stunned()
	for n in _fight_skills.size():
		var sk := _fight_skills[n]
		var waits := not battle.can_start_now(leader)  # Goes to the slot; paid when it starts (D-161).
		var affordable := not is_stunned and (waits or leader.can_pay(sk.cost))
		var price := "GRÁTIS" if leader.burst > 0 else "%d ATB" % sk.cost
		if is_stunned:
			price = "ATORDOADO (%.1fs)" % leader.stun_timer
		elif waits:
			price = "fila · " + price
		elif not leader.can_pay(sk.cost):
			price = "falta %d ATB" % int(ceilf(sk.cost - leader.blocks()))
		var tail := ""
		var accent := Color(0, 0, 0, 0)
		if sk.is_aoe:
			tail += " · [ÁREA]"
		elif sk.is_friendly:
			tail += " · [GRUPO]"
		if target != null:
			if sk.kind == Skill.Kind.STATUS:
				tail += " · sem dano"
			else:
				var weak := sk.element in target.weaknesses
				tail += " · ≈%d%s" % [Battle.estimate_damage(leader, target, sk), " FRAQ." if weak else ""]
				if weak:
					accent = Color("ffd45a")
		entries.append({
			"text": ("★ " if n == best else "") + sk.display_name,
			"detail": "%s · %s%s" % [price, Element.name_of(sk.element), tail],
			"enabled": affordable,
			"accent": accent})
	_menu.set_entries(entries, keep_index)


## Header strip: the highlighted move's category and travel time to the current target.
func _update_fight_header(i: int) -> void:
	if i < 0 or i >= _fight_skills.size():
		return
	var sk := _fight_skills[i]
	var text := Skill.kind_name(sk.kind).to_upper()
	if sk.is_aoe:
		text += " (ÁREA)"
	elif sk.is_friendly:
		text += " (SUPORTE)"
	if _fight_target != null and (sk.kind == Skill.Kind.MELEE or sk.kind == Skill.Kind.PROJECTILE):
		text += " %.2fs" % AttackPlanner.preview_travel(leader, _fight_target, sk.kind)
	if _decision_slowmo_active:
		text += " · ⏳ %.1fs" % maxf(_decision_slowmo_time_left, 0.0)
	hud.set_menu_style(FanMenu.Style.DRAWER, text)


## Uses a move on a target right now (Fight menu, number keys and Repeat all end here).
func _use_move(skill: Skill, target: Combatant) -> bool:
	if skill.is_friendly:
		if target == null or not target.is_alive() or target.is_player != leader.is_player:
			target = leader
	elif target == null or not target.is_alive():
		return false
	if leader.is_stunned() or (battle.can_start_now(leader) and not leader.can_pay(skill.cost)):
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
	for item in _item_list:
		var price := "x%d" % leader.item_count(item.id)
		if is_stunned:
			price += " · ATORDOADO"
		entries.append({"text": item.display_name, "detail": price, "enabled": not is_stunned and leader.can_pay(Battle.ITEM_BLOCKS)})
	if entries.is_empty():
		entries.append({"text": "(vazio)", "enabled": false})
	_menu.set_entries(entries)
	if _decision_slowmo_available:
		_start_decision_slowmo()
	_update_items_header()


func _update_items_header() -> void:
	var text := "ITENS // 1 ATB"
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
	hud.set_menu_style(FanMenu.Style.DRAWER, "TACTICS // IA DOS ALIADOS")
	_fill_tactics(false)


func _fill_tactics(keep_index: bool) -> void:
	var entries: Array = []
	_tactic_rows.clear()
	for i in battle.party.size():
		var a := battle.party[i]
		if i > 0:
			entries.append({"text": "%s · Ação" % a.name, "detail": ACT_NAMES[a.act_policy]})
			_tactic_rows.append({"unit": a, "kind": "act"})
			entries.append({"text": "%s · Reação" % a.name, "detail": REACT_NAMES[a.react_policy]})
			_tactic_rows.append({"unit": a, "kind": "react"})
		entries.append({"text": "%s · Posição  (←/→, 1 ATB)" % a.name, "detail": _pos_text(a, i == 0)})
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
	hud.set_menu_style(FanMenu.Style.DRAWER, "ESCOLHA O ALVO")
	_targets.assign(alive)
	_on_target = on_target
	_back = back
	var entries: Array = []
	for t in _targets:
		var weak := t.weakness_text()
		entries.append({"text": t.name, "detail": ("Fraq: " + weak) if weak != "" else "HP %d/%d" % [t.hp, t.max_hp]})
	_menu.set_entries(entries)
	for n in _targets.size():
		if _targets[n].name == _last_target:
			_menu.select(n)


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
			var sk := _fight_skills[i]
			var tgt: Combatant = leader if sk.is_friendly else (_fight_target if _fight_target != null and _fight_target.is_alive() else _default_target())
			if _use_move(sk, tgt):
				_show_main()
		S.ITEMS:
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
		S.FIGHT, S.ITEMS, S.TACTICS:
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
