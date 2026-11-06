extends SceneTree
## Logic-only battles (no drawing, no real time) that count what the AI does.
## Run: Godot --headless --path . --script res://tests/battle/sim_ai_stats.gd

const BATTLES := 40
const STEP := 1.0 / 30.0
const MAX_TIME := 90.0


func _init() -> void:
	call_deferred("_run")


func _gible(scene: Object) -> Combatant:
	var e: Combatant = scene._new_gible()
	e.act_policy = Combatant.Act.SKILL
	e.react_policy = Combatant.React.EVADE
	return e


func _run() -> void:
	var gs: Object = root.get_node("GameState")
	var scene: Object = (load("res://scripts/combat/battle_scene.gd") as GDScript).new()
	var moves := {}  # name -> {move -> count}
	var evades := {}
	var perfect := {}
	var targets := {}
	var potions := {}
	var instant := {}
	var total_time := 0.0
	for n in BATTLES:
		seed(1000 + n)
		gs._build_party()
		var party: Array[Combatant] = []
		party.assign(gs.party)
		var enemies: Array[Combatant] = [_gible(scene), _gible(scene)]
		# The leader is the player, so it stands still here; its HP is refilled so it survives.
		party[0].act_policy = Combatant.Act.HOLD
		var b := Battle.new()
		root.add_child(b)
		b.set_process(false)
		for c in party + enemies:
			c.place(Vector3(0, 0, 0) if c.is_player else Vector3(8, 0, -30), PI if c.is_player else 0.0)
			moves[c.name] = moves.get(c.name, {})
			targets[c.name] = targets.get(c.name, {})
		b.attack_telegraphed.connect(func(inc) -> void:
			var a: Combatant = inc.attacker
			moves[a.name][inc.label] = moves[a.name].get(inc.label, 0) + 1
			if not inc.is_friendly:
				targets[a.name][inc.target.name] = targets[a.name].get(inc.target.name, 0) + 1
			if inc.instant:
				instant[a.name] = instant.get(a.name, 0) + 1)
		b.manual_evaded.connect(func(actor: Combatant, inc) -> void:
			evades[actor.name] = evades.get(actor.name, 0) + 1
			if inc.perfect:
				perfect[actor.name] = perfect.get(actor.name, 0) + 1)
		b.healed.connect(func(actor: Combatant, _t: Combatant, _a: int) -> void:
			potions[actor.name] = potions.get(actor.name, 0) + 1)
		b.start(party, enemies)
		var t := 0.0
		while b.running and t < MAX_TIME:
			party[0].set_hp_instant(party[0].max_hp)
			b._process(STEP)
			t += STEP
		total_time += t
		b.free()
	scene.free()
	print("batalhas=%d tempo_medio=%.1fs" % [BATTLES, total_time / float(BATTLES)])
	for who in moves:
		var list: Dictionary = moves[who]
		var total := 0
		for k in list:
			total += list[k]
		var parts := PackedStringArray()
		var keys: Array = list.keys()
		keys.sort_custom(func(x, y) -> bool: return list[x] > list[y])
		for k in keys:
			parts.append("%s %d%%" % [k, roundi(100.0 * list[k] / maxf(total, 1.0))])
		print("%s: %d golpes | desvios %d (perfeitos %d) | instantaneos %d | curas %d | alvos %s" % [who, total, evades.get(who, 0), perfect.get(who, 0), instant.get(who, 0), potions.get(who, 0), str(targets[who])])
		print("   ", ", ".join(parts))
	print("SIM_AI_END")
	quit(0)
