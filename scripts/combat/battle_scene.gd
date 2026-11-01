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
const ENEMY_SCALE := 1.8  ## Extra scale on enemy models so they read at 30 units.
const ACT_NAMES := ["Atacar", "Habilidades", "Segurar"]
const REACT_NAMES := ["Nada", "Esquivar"]

@onready var battle: Battle = $Battle
@onready var ui: CanvasLayer = $UI

var models: Dictionary = {}  ## Combatant -> Node3D
var fx: BattleFx
var director: BattleCamera
var hud: BattleHud
var state := S.MAIN
var leader: Combatant

var _slow_token := 0
var _status_unit: Combatant
var _saved_anim: Dictionary = {}  ## AnimationPlayer -> [name, position]

var _menu: FanMenu
var _fight_skills: Array[Skill] = []
var _item_list: Array[Item] = []
var _targets: Array[Combatant] = []
var _on_target: Callable
var _back: Callable


func _ready() -> void:
	add_child(BattleArena.new())
	fx = BattleFx.new()
	add_child(fx)
	director = BattleCamera.new()
	add_child(director)
	director.setup($Camera3D)
	fx.cam = director
	var party := GameState.party
	var enemies: Array[Combatant] = [
		Combatant.new("Gible", 38, 9, 0.42, false),
	]
	enemies[0].weaknesses.assign([Element.Type.AGUA_GELO])
	enemies[0].skills.assign([
		Skill.new("Mordida", 1.2, 1, Element.Type.TREVAS),
		Skill.new("Tiro de Areia", 1.3, 2, Element.Type.TERRA),
		Skill.new("Fúria do Dragão", 1.6, 3, Element.Type.FISICO),
	])
	enemies[0].inventory = {"potion": 1}
	for e in enemies:  # Same Tactics the allies have: cast skills and evade when able.
		e.act_policy = Combatant.Act.SKILL
		e.react_policy = Combatant.React.EVADE
	leader = party[0]
	fx.leader = leader
	var party_slots: Array[Vector3] = []
	for i in party.size():
		party_slots.append(PARTY_SLOTS[mini(i, PARTY_SLOTS.size() - 1)])
	var enemy_slots: Array[Vector3] = []
	for i in enemies.size():
		enemy_slots.append(Vector3(8.0 + i * 5.0, 0.0, -TEAM_DISTANCE - i * 2.0))
	_spawn(party, party_slots, PI, Color(0.3, 0.6, 0.9))
	_spawn(enemies, enemy_slots, 0.0, Color(0.85, 0.3, 0.3))
	hud = BattleHud.new()
	ui.add_child(hud)
	hud.setup(battle, party, enemies, $Camera3D, models, director)
	_menu = hud.menu
	hud.status_closed.connect(_close_status)
	hud.status_unit_selected.connect(_on_status_unit)
	_menu.chosen.connect(_on_chosen)
	_menu.cancelled.connect(_on_cancel)
	_menu.moved.connect(_on_moved)
	battle.state_changed.connect(_refresh)
	battle.battle_ended.connect(_on_battle_ended)
	battle.attack_telegraphed.connect(fx.telegraph)
	battle.attack_resolved.connect(fx.resolve_attack)
	battle.attack_cancelled.connect(fx.clear_telegraph)
	battle.manual_evaded.connect(fx.manual_evade)
	battle.hit_resolved.connect(fx.play_hit)
	battle.healed.connect(fx.heal_fx)
	battle.manual_evaded.connect(_on_manual_evaded)
	battle.attack_telegraphed.connect(func(inc) -> void:
		if inc.attacker == leader:
			_end_slowmo())
	battle.healed.connect(func(actor: Combatant, _t: Combatant, _n: int) -> void:
		if actor == leader:
			_end_slowmo())
	battle.start(party, enemies)
	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("evade") and battle.running and leader.is_alive():
		if battle.try_evade(leader, battle.find_evadable(leader)):
			get_viewport().set_input_as_handled()


# --- Stage -----------------------------------------------------------------

func _spawn(list: Array[Combatant], slots: Array[Vector3], yaw: float, color: Color) -> void:
	for i in list.size():
		var c := list[i]
		var model := _make_model(c, color)
		if not c.is_player:
			model.scale = Vector3.ONE * ENEMY_SCALE
		model.position = slots[i]
		model.rotation.y = yaw
		add_child(model)
		model.set_meta("head_y", _measure_head(model))
		models[c] = model
		fx.register(c, model)
		c.died.connect(_on_died)


func _make_model(c: Combatant, color: Color) -> Node3D:
	var root := Node3D.new()
	var lower_name := c.name.to_lower()
	var glb_path := "res://assets/modelos/%s/%s.glb" % [lower_name, lower_name]

	var is_3d_pokemon := false
	if ResourceLoader.exists(glb_path):
		var glb_scene: PackedScene = load(glb_path)
		if glb_scene:
			var pokemon_instance := glb_scene.instantiate()
			# The GLBs come out of Blender Z-up: tip them upright, and scale up to read
			# from the wide battle camera.
			pokemon_instance.rotation_degrees.x = 90.0
			pokemon_instance.scale = Vector3.ONE * MODEL_SCALE
			root.add_child(pokemon_instance)
			VfxLib.outline_model(pokemon_instance, 0.0035)
			is_3d_pokemon = true

			var anim_player: AnimationPlayer = _find_anim_player(pokemon_instance)
			if anim_player:
				root.set_meta("anim_player", anim_player)
				# Configure linear loops for resting animations
				for anim_name in ["idle", "battle_idle", "walk", "run", "charge"]:
					if anim_player.has_animation(anim_name):
						anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
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


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var res := _find_anim_player(child)
		if res:
			return res
	return null


func _on_died(c: Combatant) -> void:
	var model: Node3D = models.get(c)
	if model and model.has_meta("anim_player"):
		var ap: AnimationPlayer = model.get_meta("anim_player")
		if ap.has_animation("down"):
			ap.play("down")
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(models[c], "scale", Vector3.ZERO, 0.4)


## A perfect (manual) Evade by the leader slows the whole game until the
## player acts again or the time runs out.
func _on_manual_evaded(actor: Combatant, _inc) -> void:
	if actor != leader:
		return
	_slow_token += 1
	var token := _slow_token
	Engine.time_scale = SLOWMO_SCALE
	await get_tree().create_timer(SLOWMO_SECONDS, true, false, true).timeout
	if token == _slow_token:
		_end_slowmo()


func _end_slowmo() -> void:
	_slow_token += 1
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if is_inside_tree():
		get_tree().paused = false


func _on_battle_ended(player_won: bool) -> void:
	_end_slowmo()
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


func _set_state(s: S) -> void:
	var was_target := state == S.TARGET
	state = s
	# Tactics and Status pause the whole game while they are open.
	get_tree().paused = s == S.TACTICS or s == S.STATUS
	if was_target and s != S.TARGET:
		hud.set_target(null)
		director.cinema()


func _consumables() -> Array[Item]:
	return GameState.items_of_kind(Item.Kind.CONSUMABLE)


func _show_main() -> void:
	_set_state(S.MAIN)
	hud.set_menu_style(FanMenu.Style.FAN, "01 / ESCOLHA SUA AÇÃO")
	_menu.set_entries([
		{"text": "Fight", "detail": "%d ATB" % int(Battle.SKILL_BLOCKS)},
		{"text": "Itens", "detail": "%d ATB" % int(Battle.ITEM_BLOCKS)},
		{"text": "Evade", "detail": "%d ATB" % int(Battle.EVADE_BLOCKS)},
		{"text": "Tactics", "detail": "PAUSA"},
		{"text": "Status", "detail": "PAUSA"},
	])
	_refresh()


func _update_main_enabled() -> void:
	_menu.set_enabled(0, leader.can_pay(Battle.SKILL_BLOCKS) and not battle.is_winding_up(leader))
	_menu.set_enabled(1, leader.can_pay(Battle.ITEM_BLOCKS) and not _consumables().is_empty())
	_menu.set_enabled(2, battle.find_evadable(leader) != null)


func _show_fight() -> void:
	_set_state(S.FIGHT)
	hud.set_menu_style(FanMenu.Style.DRAWER, "FIGHT // COMANDOS")
	_fight_skills.clear()
	_fight_skills.append(Skill.basic())
	_fight_skills.append_array(leader.skills)
	var entries: Array = []
	for s in _fight_skills:
		entries.append({
			"text": s.display_name,
			"detail": "%d ATB · %s" % [s.cost, Element.name_of(s.element)],
			"enabled": leader.can_pay(s.cost) and not battle.is_winding_up(leader)})
	_menu.set_entries(entries)


func _show_items() -> void:
	_set_state(S.ITEMS)
	hud.set_menu_style(FanMenu.Style.DRAWER, "ITENS // 1 ATB")
	_item_list = _consumables()
	var entries: Array = []
	for item in _item_list:
		entries.append({"text": item.display_name, "detail": "x%d" % leader.item_count(item.id)})
	if entries.is_empty():
		entries.append({"text": "(vazio)", "enabled": false})
	_menu.set_entries(entries)


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
	for i in range(1, battle.party.size()):
		var a := battle.party[i]
		entries.append({"text": "%s · Ação" % a.name, "detail": ACT_NAMES[a.act_policy]})
		entries.append({"text": "%s · Reação" % a.name, "detail": REACT_NAMES[a.react_policy]})
	if entries.is_empty():
		entries.append({"text": "(sem aliados)", "enabled": false})
	_menu.set_entries(entries, keep_index)


func _pick_target(candidates: Array[Combatant], on_target: Callable, back: Callable) -> void:
	_set_state(S.TARGET)
	hud.set_menu_style(FanMenu.Style.DRAWER, "ESCOLHA O ALVO")
	_targets.assign(candidates.filter(func(c: Combatant) -> bool: return c.is_alive()))
	_on_target = on_target
	_back = back
	var entries: Array = []
	for t in _targets:
		var weak := t.weakness_text()
		entries.append({"text": t.name, "detail": ("Fraq: " + weak) if weak != "" else "HP %d/%d" % [t.hp, t.max_hp]})
	_menu.set_entries(entries)


func _on_chosen(i: int) -> void:
	match state:
		S.MAIN:
			match i:
				0: _show_fight()
				1: _show_items()
				2: battle.try_evade(leader, battle.find_evadable(leader))
				3: _show_tactics()
				4: _show_status()
		S.FIGHT:
			var skill := _fight_skills[i]
			_pick_target(battle.enemies,
				func(t: Combatant) -> void: battle.use_skill(leader, skill, t), _show_fight)
		S.ITEMS:
			var item := _item_list[i]
			_pick_target(battle.party,
				func(t: Combatant) -> void: battle.use_item(leader, item, t), _show_items)
		S.TARGET:
			_on_target.call(_targets[i])
			if battle.running:
				_show_main()
		S.TACTICS:
			var ally := battle.party[1 + i / 2]
			if i % 2 == 0:
				ally.act_policy = (ally.act_policy + 1) % ACT_NAMES.size()
			else:
				ally.react_policy = (ally.react_policy + 1) % REACT_NAMES.size()
			_fill_tactics(true)


func _on_cancel() -> void:
	match state:
		S.FIGHT, S.ITEMS, S.TACTICS:
			_show_main()
		S.TARGET:
			_back.call()


func _on_moved(i: int) -> void:
	if state == S.TARGET and i < _targets.size():
		var target := _targets[i]
		hud.set_target(target)
		director.tactical((models[target] as Node3D).global_position)
