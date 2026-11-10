class_name BattleBadges
extends RefCounted
## Drain Spear badge steal and the 0.30 s flight of the stolen badges. Extracted
## from battle.gd in Etapa 4; Battle keeps the public steal_badges() API and the
## step is still driven by the single Battle clock (D-019/D-1040).

var battle
var transfers: Array[Dictionary] = []


func _init(p_battle) -> void:
	battle = p_battle


## Removes every positive badge from `target` and queues it for `attacker` after the
## 0.30 s transfer. Debuffs are never stolen. Returns one entry per badge (also used
## by the VFX). Called by DrainSpear's behavior (D-1079).
func steal(attacker: Combatant, target: Combatant) -> Array:
	var stolen: Array[Dictionary] = []
	for item in [
		{"stat": "atk", "amount": target.atk_buff, "label": "ATK +%d" % target.atk_buff},
		{"stat": "def", "amount": target.def_buff, "label": "DEF +%d" % target.def_buff},
		{"stat": "speed", "amount": target.speed_buff, "label": "VEL +%d" % target.speed_buff},
	]:
		var amount := int(item["amount"])
		if amount <= 0:
			continue
		target.buff_stat(String(item["stat"]), -amount)  # back to 0 (positive stage moved)
		stolen.append({"kind": "stat", "stat": item["stat"], "amount": amount, "label": item["label"]})
	if target.is_shielded():
		stolen.append({
			"kind": "shield", "hp": target.shield_hp, "max": target.shield_max,
			"seconds": target.shield_seconds, "label": "ESCUDO %d" % target.shield_hp,
		})
		target.end_shield("stolen")
	if target.is_magic_immune():
		stolen.append({
			"kind": "magic_immune", "seconds": target.magic_immune_seconds,
			"label": "IMUN. MÁGICA",
		})
		target.clear_magic_immunity()
	if stolen.is_empty():
		battle.log_message.emit("Drain Spear atinge %s, mas não há badges positivos para roubar." % target.name)
		return stolen
	var labels: Array[String] = []
	for b in stolen:
		labels.append(String(b["label"]))
	battle.log_message.emit("%s rouba %s de %s antes do dano!" % [attacker.name, ", ".join(labels), target.name])
	var drain_data := MoveCatalog.get_move(&"drain_spear")
	var transfer_time := drain_data.transfer_time if drain_data != null and drain_data.transfer_time >= 0.0 else 0.30
	transfers.append({
		"attacker": attacker,
		"payload": stolen,
		"time": transfer_time,
	})
	return stolen


## The 0.30 s flight of the stolen badges. Only a living attacker receives them; the
## shield keeps the reserve it had and gets a fresh duration.
func step(delta: float) -> void:
	for item in transfers.duplicate():
		item["time"] = float(item["time"]) - delta
		if float(item["time"]) > 0.0:
			continue
		transfers.erase(item)
		var receiver: Combatant = item["attacker"]
		if receiver == null or not receiver.is_alive():
			continue
		var labels: Array[String] = []
		for b in item["payload"]:
			match String(b["kind"]):
				"stat":
					receiver.buff_stat(String(b["stat"]), int(b["amount"]))
					labels.append(String(b["label"]))
				"shield":
					receiver.adopt_shield(int(b["hp"]), int(b["max"]), float(b["seconds"]))
					labels.append(String(b["label"]))
				"magic_immune":
					receiver.apply_magic_immunity(float(b["seconds"]))
					labels.append(String(b["label"]))
		if not labels.is_empty():
			battle.log_message.emit("%s recebe %s (transferência de 0,30 s; duração reiniciada)." % [receiver.name, ", ".join(labels)])


func clear() -> void:
	transfers.clear()
