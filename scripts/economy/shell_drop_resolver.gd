class_name ShellDropResolver
extends RefCounted
## Resolve o sorteio de Cascos de um inimigo derrotado (D-1285, D-1286).
## Puro: sem combate, GameState, UI, quantidades ou carteira. Bronze, prata e ouro
## são sorteios independentes e podem cair juntos no mesmo inimigo. Só a vitória é
## elegível: fuga, recrutamento e derrota não geram drop. Cada inimigo resolve uma
## única vez, e nada consome o rng fora do sorteio.

const DropMath := preload("res://scripts/economy/shell_drop_math.gd")

const OUTCOME_VICTORY := "victory"


static func resolve(enemy_uid: String, outcome: String, leader_luk: float, rng: RandomNumberGenerator, resolved: Dictionary) -> Dictionary:
	if outcome != OUTCOME_VICTORY:
		return {"ok": true, "granted": false, "reason": "ineligible_outcome", "hits": _no_hits()}
	if enemy_uid.is_empty():
		return {"ok": false, "granted": false, "reason": "invalid_enemy", "hits": _no_hits()}
	if resolved.has(enemy_uid):
		return {"ok": true, "granted": false, "reason": "already_resolved", "hits": _no_hits()}
	var bronze := DropMath.roll_bronze(rng, leader_luk)
	var silver := DropMath.roll_silver(rng, leader_luk)
	var gold := DropMath.roll_gold(rng, leader_luk)
	resolved[enemy_uid] = true
	return {
		"ok": true,
		"granted": true,
		"reason": "",
		"hits": {"bronze": bronze, "silver": silver, "gold": gold},
	}


static func _no_hits() -> Dictionary:
	return {"bronze": false, "silver": false, "gold": false}