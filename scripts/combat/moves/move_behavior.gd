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
	_apply_knockup(attacker, target, info, battle)


## D-1205: Knock-up genérico, ligado pelo MoveData (`knockup_height` e `knockup_air_time` > 0): stun com outro nome pelo tempo do voo,
## sempre que acerta (sem chance; ARMOR bloqueia). Funciona para qualquer Move, sem classe própria.
func _apply_knockup(_attacker: Combatant, target: Combatant, info: Dictionary, battle: Battle) -> void:
	if data == null or data.knockup_launch().is_empty() or not target.is_alive() or String(info.get("armor", "")) != "":
		return
	var air := data.knockup_air_time  # o status dura exatamente o tempo no ar
	target.stun_timer = maxf(target.stun_timer, air)
	target.stun_kind = "knockup"
	info["knockup"] = true
	battle.log_message.emit("%s is knocked up by %s for %.1f seconds!" % [target.name, data.display_name, air])


## Trata o ataque inteiro antes do hit padrão (ex.: Sand Attack). true = tratado.
func on_strike(_inc: Incoming, _battle: Battle) -> bool:
	return false


## Trata um Move de status. true = tratado.
func on_status(_inc: Incoming, _battle: Battle) -> bool:
	return false


## Valor tático de um Move de status para a IA; -1 = usa o fallback genérico.
func ai_status_value(_c: Combatant, _target: Combatant, _battle: Battle) -> float:
	return -1.0


## D-1200: como a IA escolhe o aliado-alvo de um Move de aliado único: &"hp" = o de menor % de
## HP; &"str" = o de maior STR que ainda pode receber o buff de ATK; vazio = o próprio lançador.
func ai_ally_focus() -> StringName:
	return &""


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
