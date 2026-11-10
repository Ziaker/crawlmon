extends MoveBehavior
## Regra própria do Media (D-1079, Fase 2 do pacote de Move). Extraída de
## move_behaviors.gd sem mudar comportamento: cura todos os aliados vivos por
## 10 + MAG e a IA valoriza quando alguém está abaixo do limiar.

func on_status(inc: Incoming, battle: Battle) -> bool:
	var team: Array[Combatant] = battle.party if inc.attacker.is_player else battle.enemies
	var heal_amount := 10 + inc.attacker.mag
	battle.log_message.emit("%s usa Media! A equipe recupera HP!" % inc.attacker.name)
	for ally in team:
		if ally.is_alive():
			var before_hp := ally.hp
			ally.heal(heal_amount)
			battle.healed.emit(inc.attacker, ally, ally.hp - before_hp)
			battle.hit_resolved.emit(inc.attacker, ally, inc.element, {
				"status": true, "evaded": false, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
				"skill_name": inc.label, "heal": true
			})
	return true

func ai_status_value(c: Combatant, _target: Combatant, battle: Battle) -> float:
	var team: Array[Combatant] = battle.party if c.is_player else battle.enemies
	var total := 0.0
	var worst := 0.0
	for ally in team:
		if ally.is_alive():
			var missing := 1.0 - float(ally.hp) / float(ally.max_hp)
			total += missing
			worst = maxf(worst, missing)
	return total * 110.0 if worst >= BattleAI.MIN_MISSING_TO_HEAL else 0.0
