class_name MoveBehavior
extends RefCounted
## Ganchos de regra de um Move (D-1079, Etapa 2). O `Battle`/`AttackPlanner`
## chamam estes hooks por `move_id`; nenhum deles pode criar relógio próprio
## (D-019/D-1040).

var data: MoveData = null


func setup(move_data: MoveData) -> void:
	data = move_data


## Antes do dano: devolve o resultado de um hit autoral, ou {} para o hit padrão.
func has_before_hit() -> bool:
	return false


func before_hit(_inc: Incoming, _battle: Battle) -> Dictionary:
	return {}


## Depois de um hit confirmado (ex.: Tidal Surge encadeia o bounce).
func on_hit(_inc: Incoming, _battle: Battle, _info: Dictionary) -> void:
	pass


## Efeito de contato dentro do hit padrão. A base aplica a interrupção padrão;
## as classes com efeito próprio chamam `super.on_contact(...)` quando aplicável.
func on_contact(attacker: Combatant, target: Combatant, info: Dictionary, battle: Battle) -> void:
	var weak_or_crit := bool(info.get("weak", false)) or bool(info.get("crit", false))
	var power := clampf(float(info.get("power", 1.0)), 0.85, 1.6)
	info["interrupted"] = battle.interrupt_attacks_of(target, attacker, (1.55 if weak_or_crit else 1.0) * power)


## Trata o ataque inteiro antes do hit padrão (ex.: Sand Attack). true = tratado.
func on_strike(_inc: Incoming, _battle: Battle) -> bool:
	return false


## Trata um Move de status. true = tratado.
func on_status(_inc: Incoming, _battle: Battle) -> bool:
	return false


## Valor tático de um Move de status para a IA; -1 = usa o fallback genérico.
func ai_status_value(_c: Combatant, _target: Combatant, _battle: Battle) -> float:
	return -1.0


## Valor tático de um Move de dano com regra própria; -1 = usa o cálculo padrão.
func ai_attack_value(_c: Combatant, _target: Combatant, _battle: Battle) -> float:
	return -1.0


func is_armor_worthy() -> bool:
	return data != null and data.has_tag(&"armor_worthy")


## Shared AI helper for debuff Moves.
func _debuff_value(target: Combatant, stat: String, stage: int, base: float) -> float:
	if not target.can_buff(stat, -1) or float(target.hp) / float(target.max_hp) < BattleAI.MIN_TARGET_HP_TO_DEBUFF:
		return 0.0
	return base * (1.0 - float(maxi(-stage, 0)) / 5.0)
