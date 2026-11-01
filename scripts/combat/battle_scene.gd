extends Node3D
## 3D battle stage. Combatants are shown as placeholder capsules; replace
## _make_model() with an instantiated glTF scene once real models exist.

@onready var battle: Battle = $Battle
@onready var status: Label = $UI/Status
@onready var log_label: RichTextLabel = $UI/Log
@onready var actions: HBoxContainer = $UI/Actions

var models: Dictionary = {}  ## Combatant -> Node3D


func _ready() -> void:
	_add_floor()
	var party: Array[Combatant] = [
		Combatant.new("Herói", 40, 8, 30.0, true),
		Combatant.new("Mago", 28, 11, 22.0, true),
	]
	var enemies: Array[Combatant] = [
		Combatant.new("Slime", 25, 5, 20.0, false),
		Combatant.new("Goblin", 30, 7, 26.0, false),
	]
	_spawn(party, -3.0, Color(0.3, 0.6, 0.9))
	_spawn(enemies, 3.0, Color(0.85, 0.3, 0.3))
	battle.log_message.connect(func(t: String) -> void: log_label.append_text(t + "\n"))
	battle.state_changed.connect(_refresh)
	battle.battle_ended.connect(_on_battle_ended)
	battle.start(party, enemies)


func _add_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 12)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	floor_mesh.material_override = mat
	add_child(floor_mesh)


func _spawn(list: Array[Combatant], x: float, color: Color) -> void:
	for i in list.size():
		var c := list[i]
		var model := _make_model(c, color)
		model.position = Vector3(x, 0.0, (i - (list.size() - 1) / 2.0) * 3.0)
		model.rotation.y = PI / 2.0 if x < 0 else -PI / 2.0
		add_child(model)
		models[c] = model
		c.damaged.connect(_on_damaged)
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
	var label := Label3D.new()
	label.text = c.name
	label.position.y = 2.6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)
	return root


func _on_damaged(c: Combatant, _amount: int) -> void:
	var model: Node3D = models[c]
	var base := model.position
	var tween := create_tween()
	tween.tween_property(model, "position", base + Vector3(0, 0, 0.3), 0.05)
	tween.tween_property(model, "position", base, 0.1)


func _on_died(c: Combatant) -> void:
	var tween := create_tween()
	tween.tween_property(models[c], "scale", Vector3.ZERO, 0.4)


func _on_battle_ended(player_won: bool) -> void:
	await get_tree().create_timer(1.5).timeout
	GameState.end_battle(player_won)


func _refresh() -> void:
	var lines := PackedStringArray()
	for c in battle.party + battle.enemies:
		lines.append("%s  HP %d/%d  ATB %d%%" % [c.name, c.hp, c.max_hp, int(c.gauge)])
	status.text = "\n".join(lines)
	for b in actions.get_children():
		b.queue_free()
	if battle.active != null:
		for e in battle.enemies:
			if e.is_alive():
				var btn := Button.new()
				btn.text = "%s ataca %s" % [battle.active.name, e.name]
				btn.pressed.connect(battle.player_attack.bind(e))
				actions.add_child(btn)
