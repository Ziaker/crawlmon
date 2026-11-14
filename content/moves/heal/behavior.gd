extends MoveBehavior
## Regra própria do Heal (D-1200): cura UM aliado vivo do mesmo time do lançador (o próprio
## lançador incluso) por 10 + MAG, a mesma quantidade do Media. Não depende de personagem,
## time nem lado (D-235): o time vem do Battle, o alvo vem do Incoming.

func on_status(inc: Incoming, battle: Battle) -> bool:
	var ally := inc.target
	if ally == null or not ally.is_alive():
		return true  # Alvo caiu durante o preparo: nada a curar.
	var heal_amount := 10 + inc.attacker.mag
	var before_hp := ally.hp
	ally.heal(heal_amount)
	battle.log_message.emit("%s usa Heal em %s!" % [inc.attacker.name, ally.name])
	battle.healed.emit(inc.attacker, ally, ally.hp - before_hp)
	battle.hit_resolved.emit(inc.attacker, ally, inc.element, {
		"status": true, "evaded": false, "dmg": 0, "weak": false,
		"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
		"skill_name": inc.label, "heal": true
	})
	return true


## Foco da IA ao escolher o aliado-alvo (D-1200): o de menor % de HP.
func ai_ally_focus() -> StringName:
	return &"hp"


## `target` é o aliado já escolhido pela IA; vale mais quanto mais HP falta a ele.
func ai_status_value(_c: Combatant, target: Combatant, _battle: Battle) -> float:
	if target == null or not target.is_alive():
		return 0.0
	var missing := 1.0 - float(target.hp) / float(target.max_hp)
	return missing * 110.0 if missing >= BattleAI.MIN_MISSING_TO_HEAL else 0.0
