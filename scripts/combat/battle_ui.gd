extends Control
## Minimal placeholder UI: status labels, log, and an attack button per enemy.

@onready var battle: Battle = $Battle
@onready var status: Label = $Status
@onready var log_label: RichTextLabel = $Log
@onready var actions: HBoxContainer = $Actions


func _ready() -> void:
	var party: Array[Combatant] = [
		Combatant.new("Herói", 40, 8, 30.0, true),
		Combatant.new("Mago", 28, 11, 22.0, true),
	]
	var enemies: Array[Combatant] = [
		Combatant.new("Slime", 25, 5, 20.0, false),
		Combatant.new("Goblin", 30, 7, 26.0, false),
	]
	battle.log_message.connect(func(t: String) -> void: log_label.append_text(t + "\n"))
	battle.state_changed.connect(_refresh)
	battle.start(party, enemies)


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
