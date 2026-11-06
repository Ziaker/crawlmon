extends Node
## Demo para o criador ver o VFX de um move do Abra rodando na batalha real, em loop.
## Rodar a cena tests/vfx/abra_demo.tscn (F6). Move escolhido por DEMO_MOVE (padrão: Confusion).

const MOVE := "Confusion"


func _ready() -> void:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	var bs: Node3D = packed.instantiate()
	add_child(bs)
	var battle: Battle = bs.get_node("Battle")
	while not battle.running:
		await get_tree().process_frame
	for i in 10:
		await get_tree().process_frame
	var all_units: Array[Combatant] = []
	all_units.append_array(battle.party)
	all_units.append_array(battle.enemies)
	for c in all_units:
		c.act_policy = Combatant.Act.HOLD
		c.react_policy = Combatant.React.NONE
	var abra: Combatant = all_units[0]
	var gible: Combatant = all_units[2]
	var move := OS.get_environment("DEMO_MOVE") if OS.get_environment("DEMO_MOVE") != "" else MOVE
	while true:
		for u in all_units:
			u.hp = u.max_hp
			u.atb = 5
			u.stun_timer = 0.0
			u.engaged_with = null
		var skill: Skill
		for s in abra.skills:
			if s.display_name == move:
				skill = s
		print("[demo] ", move)
		battle.use_skill(abra, skill, gible)
		await get_tree().create_timer(7.0).timeout
