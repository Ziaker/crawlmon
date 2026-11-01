extends Node3D
## 3D battle stage + command UI. Combatants are placeholder capsules; replace
## _make_model() with an instantiated glTF scene once real models exist.
## The player controls party[0]; the others follow Tactics.

enum S { MAIN, FIGHT, ITEMS, TARGET, TACTICS }

const ACT_NAMES := ["Atacar", "Habilidades", "Segurar"]
const REACT_NAMES := ["Nada", "Esquivar"]

@onready var battle: Battle = $Battle
@onready var ui: CanvasLayer = $UI

var models: Dictionary = {}  ## Combatant -> Node3D
var fx: BattleFx
var state := S.MAIN
var leader: Combatant

var _rows: Array = []  ## [Combatant, Label]
var _menu: MenuList
var _log: RichTextLabel
var _alert: Label
var _marker: MeshInstance3D
var _fight_skills: Array[Skill] = []
var _item_list: Array[Item] = []
var _targets: Array[Combatant] = []
var _on_target: Callable
var _back: Callable


func _ready() -> void:
	fx = BattleFx.new()
	add_child(fx)
	fx.setup($Camera3D)
	_add_floor()
	var party := GameState.party
	var enemies: Array[Combatant] = [
		Combatant.new("Slime", 25, 5, 0.35, false),
		Combatant.new("Goblin", 30, 7, 0.45, false),
	]
	enemies[0].weaknesses.assign([Element.Type.FOGO])
	enemies[1].weaknesses.assign([Element.Type.RAIO])
	enemies[0].skills.assign([Skill.new("Gosma", 1.1, 2, Element.Type.VENENO), Skill.new("Investida Mole", 1.0)])
	enemies[1].skills.assign([Skill.new("Facada", 1.2), Skill.new("Tocha", 1.3, 2, Element.Type.FOGO)])
	enemies[1].inventory = {"potion": 1}
	for e in enemies:  # Same Tactics the allies have: cast skills and evade when able.
		e.act_policy = Combatant.Act.SKILL
		e.react_policy = Combatant.React.EVADE
	leader = party[0]
	_spawn(party, -3.0, Color(0.3, 0.6, 0.9))
	_spawn(enemies, 3.0, Color(0.85, 0.3, 0.3))
	_add_marker()
	_build_ui(party + enemies)
	battle.log_message.connect(func(t: String) -> void: _log.append_text(t + "\n"))
	battle.state_changed.connect(_refresh)
	battle.battle_ended.connect(_on_battle_ended)
	battle.attack_telegraphed.connect(fx.telegraph)
	battle.attack_resolved.connect(fx.resolve_attack)
	battle.attack_cancelled.connect(fx.clear_telegraph)
	battle.manual_evaded.connect(fx.manual_evade)
	battle.hit_resolved.connect(fx.play_hit)
	battle.healed.connect(fx.heal_fx)
	battle.start(party, enemies)
	_show_main()


# --- Stage -----------------------------------------------------------------

func _add_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 12)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	floor_mesh.material_override = mat
	add_child(floor_mesh)


func _add_marker() -> void:
	_marker = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	_marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.9, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker.material_override = mat
	_marker.visible = false
	add_child(_marker)


func _spawn(list: Array[Combatant], x: float, color: Color) -> void:
	for i in list.size():
		var c := list[i]
		var model := _make_model(c, color)
		model.position = Vector3(x, 0.0, (i - (list.size() - 1) / 2.0) * 3.0)
		model.rotation.y = PI / 2.0 if x < 0 else -PI / 2.0
		add_child(model)
		models[c] = model
		fx.register(c, model)
		c.died.connect(_on_died)


func _make_model(c: Combatant, color: Color) -> Node3D:
	var root := Node3D.new()
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
	torus.inner_radius = 1.0
	torus.outer_radius = 1.2
	ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.8, 0.1)
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_mat
	ring.position.y = 0.05
	ring.visible = false
	root.add_child(ring)
	var label := Label3D.new()
	label.text = c.name
	label.position.y = 2.6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)
	return root


func _on_died(c: Combatant) -> void:
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(models[c], "scale", Vector3.ZERO, 0.4)


func _on_battle_ended(player_won: bool) -> void:
	_menu.hide()
	_marker.hide()
	await get_tree().create_timer(1.5).timeout
	GameState.end_battle(player_won)


# --- UI --------------------------------------------------------------------

func _build_ui(everyone: Array[Combatant]) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 24)
	ui.add_child(box)
	for c in everyone:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(250, 0)
		var bar := AtbBar.new()
		bar.combatant = c
		row.add_child(label)
		row.add_child(bar)
		box.add_child(row)
		_rows.append([c, label])
	_alert = Label.new()
	_alert.position = Vector2(480, 24)
	_alert.modulate = Color(1, 0.4, 0.3)
	ui.add_child(_alert)
	_log = RichTextLabel.new()
	_log.position = Vector2(340, 520)
	_log.size = Vector2(600, 150)
	_log.scroll_following = true
	ui.add_child(_log)
	_menu = MenuList.new()
	_menu.position = Vector2(24, 520)
	ui.add_child(_menu)
	_menu.chosen.connect(_on_chosen)
	_menu.cancelled.connect(_on_cancel)
	_menu.moved.connect(_on_moved)
	var hint := Label.new()
	hint.text = "Setas: mover   Z: confirmar   X: voltar   C: configurações"
	hint.position = Vector2(24, 690)
	hint.modulate = Color(1, 1, 1, 0.6)
	ui.add_child(hint)


func _refresh() -> void:
	for r in _rows:
		var c: Combatant = r[0]
		(models[c].get_node("BurstRing") as Node3D).visible = c.burst > 0
		(r[1] as Label).text = "%s  HP %d/%d%s" % [c.name, c.hp, c.max_hp, "  BURST" if c.burst > 0 else ""]
	var lines := PackedStringArray()
	for inc in battle.incoming:
		if not inc.dodged:
			lines.append("! %s -> %s  %.1fs" % [inc.attacker.name, inc.target.name, inc.time_left])
	_alert.text = "\n".join(lines)
	_menu.visible = leader.is_alive() and battle.running
	if state == S.MAIN:
		_update_main_enabled()


func _set_state(s: S) -> void:
	state = s
	_marker.visible = s == S.TARGET


func _consumables() -> Array[Item]:
	return GameState.items_of_kind(Item.Kind.CONSUMABLE)


func _show_main() -> void:
	_set_state(S.MAIN)
	_menu.set_entries(["Fight", "Itens", "Evade (3)", "Tactics"])
	_refresh()


func _update_main_enabled() -> void:
	_menu.set_enabled(0, leader.can_pay(Battle.SKILL_BLOCKS) and not battle.is_winding_up(leader))
	_menu.set_enabled(1, leader.can_pay(Battle.ITEM_BLOCKS) and not _consumables().is_empty())
	_menu.set_enabled(2, battle.find_evadable(leader) != null)


func _show_fight() -> void:
	_set_state(S.FIGHT)
	_fight_skills.clear()
	_fight_skills.append(Skill.basic())
	_fight_skills.append_array(leader.skills)
	var entries: Array = []
	for s in _fight_skills:
		entries.append({"text": "%s (%d) - %s" % [s.display_name, s.cost, Element.name_of(s.element)], "enabled": leader.can_pay(s.cost)})
	_menu.set_entries(entries)


func _show_items() -> void:
	_set_state(S.ITEMS)
	_item_list = _consumables()
	var entries: Array = []
	for item in _item_list:
		entries.append("%s x%d" % [item.display_name, leader.item_count(item.id)])
	if entries.is_empty():
		entries.append({"text": "(vazio)", "enabled": false})
	_menu.set_entries(entries)


func _show_tactics() -> void:
	_set_state(S.TACTICS)
	_fill_tactics(false)


func _fill_tactics(keep_index: bool) -> void:
	var entries: Array = []
	for i in range(1, battle.party.size()):
		var a := battle.party[i]
		entries.append("%s - Ação: %s" % [a.name, ACT_NAMES[a.act_policy]])
		entries.append("%s - Reação: %s" % [a.name, REACT_NAMES[a.react_policy]])
	if entries.is_empty():
		entries.append({"text": "(sem aliados)", "enabled": false})
	_menu.set_entries(entries, keep_index)


func _pick_target(candidates: Array[Combatant], on_target: Callable, back: Callable) -> void:
	_set_state(S.TARGET)
	_targets.assign(candidates.filter(func(c: Combatant) -> bool: return c.is_alive()))
	_on_target = on_target
	_back = back
	var entries: Array = []
	for t in _targets:
		var weak := t.weakness_text()
		entries.append("%s  HP %d/%d%s" % [t.name, t.hp, t.max_hp, "   Fraqueza: " + weak if weak != "" else ""])
	_menu.set_entries(entries)


func _on_chosen(i: int) -> void:
	match state:
		S.MAIN:
			match i:
				0: _show_fight()
				1: _show_items()
				2: battle.try_evade(leader, battle.find_evadable(leader))
				3: _show_tactics()
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
		var model: Node3D = models[_targets[i]]
		_marker.global_position = model.global_position + Vector3(0, 3.2, 0)
