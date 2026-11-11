extends MoveBehavior
## Regra própria do Bubble Shield (D-1079, pacote do Move): aplica o mesmo
## escudo sem tipo a todos os aliados vivos do lado do lançador. O VFX só
## desenha o que o Battle/Combatant mandam (D-019/D-1040).


func on_status(inc: Incoming, battle: Battle) -> bool:
	var team: Array[Combatant] = battle.party if inc.attacker.is_player else battle.enemies
	var amount := 25 + inc.attacker.mag
	battle.log_message.emit("%s usa Bubble Shield! A equipe recebe %d de escudo por 8 s." % [inc.attacker.name, amount])
	for ally in team:
		if ally.is_alive():
			ally.apply_shield(amount, 8.0)
			battle.hit_resolved.emit(inc.attacker, ally, inc.element, {
				"status": true, "evaded": false, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
				"skill_name": inc.label, "shield": true,
				"shield_amount": amount, "shield_seconds": 8.0
			})
	return true


func ai_status_value(c: Combatant, _target: Combatant, battle: Battle) -> float:
	var team: Array[Combatant] = battle.party if c.is_player else battle.enemies
	for ally in team:
		if ally.is_alive() and not ally.is_shielded():
			return 80.0
	return 0.0
