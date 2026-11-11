class_name MoveBehaviors
extends RefCounted
## Regras próprias de cada Move, fora do Battle/AttackPlanner/BattleAI (D-1079,
## Etapa 2). Cada classe só lê o estado do Battle e age pelos mesmos métodos que
## o resto do motor; nenhuma cria relógio paralelo (D-019/D-1040).

const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")


class DrainSpear extends MoveBehavior:
	func has_before_hit() -> bool:
		return true

	func before_hit(inc: Incoming, battle: Battle) -> Dictionary:
		inc.data["drain_steal"] = []
		var steal := func() -> void:
			inc.data["drain_steal"] = battle.steal_badges(inc.attacker, inc.target)
		var opts := {
			"magic_flat": data.magic_flat,
			"bypass_def": data.bypass_def,
			"before_damage": steal,
		}
		return battle.apply_hit(inc.attacker, inc.target, inc.power, inc.element, inc.label, inc.whiffed, inc.auto_dodged, opts)


class TidalSurge extends MoveBehavior:
	const BOUNCE_1_TIME := 0.3
	const BOUNCE_2_TIME := 0.6
	const BOUNCE_1_MULT := 0.75
	const BOUNCE_2_MULT := 0.5

	func on_hit(inc: Incoming, battle: Battle, info: Dictionary) -> void:
		if not bool(info.get("evaded", false)):
			_spawn_bounce(inc, inc.target, battle)

	## D-1025: one bounce of the chain. The main hit (or the previous bounce)
	## calls this after a successful hit; the chain stops on an evade, a target
	## that died before the hit, or after the second bounce.
	func _spawn_bounce(inc: Incoming, from_target: Combatant, battle: Battle) -> void:
		var root: Incoming = inc.bounce_root if inc.bounce_root != null else inc
		var idx := inc.bounce_index + 1
		if idx > 2:
			return
		if root.bounce_targets.is_empty():
			root.bounce_targets.append(inc.target)
		var next := _nearest_foe(root.attacker, from_target, root.bounce_targets, battle)
		if next == null:
			return
		root.bounce_targets.append(next)
		var b := Incoming.new()
		b.attacker = root.attacker
		b.target = next
		b.power = root.power * (BOUNCE_1_MULT if idx == 1 else BOUNCE_2_MULT)
		b.element = root.element
		b.kind = Skill.Kind.PROJECTILE
		b.label = root.label
		b.skill = root.skill
		b.move_id = root.move_id
		b.move_data = root.move_data
		b.is_aoe = false
		b.is_friendly = false
		b.ground = false
		b.resolved = true
		b.motion = "cast"
		b.total_windup = 0.0
		b.time_left = 0.0
		b.from = from_target.pos
		b.aim = next.pos
		b.stand = next.pos
		var d := Vector3(next.pos.x - from_target.pos.x, 0.0, next.pos.z - from_target.pos.z)
		b.dir = d.normalized() if d.length() > 0.01 else Vector3.RIGHT
		b.plan = [[Incoming.Phase.TRAVEL, BOUNCE_1_TIME if idx == 1 else BOUNCE_2_TIME], [Incoming.Phase.STRIKE, 0.01], [Incoming.Phase.RETURN, 0.0]]
		b.impact_phase = Incoming.Phase.TRAVEL
		b.plan_i = 0
		b.phase = Incoming.Phase.TRAVEL
		b.phase_time = 0.0
		b.bounce_root = root
		b.bounce_index = idx
		b.bounce_from_target = from_target
		b.bounce_no_reward = true
		b.auto_dodged = b.kind != Skill.Kind.STATUS and not b.dodged and not b.whiffed and (battle.debug_roll == 2 or (battle.debug_roll == 0 and randf() < Battle.AUTO_DODGE_CHANCE))
		battle.add_landing(b)
		battle.attack_resolved.emit(b)
		battle.attack_phase.emit(b, b.phase)
		battle.roll_ai_for(b)

	func _nearest_foe(attacker: Combatant, from_target: Combatant, exclude: Array, battle: Battle) -> Combatant:
		if attacker == null or from_target == null:
			return null
		var foes: Array[Combatant] = battle.enemies if attacker.is_player else battle.party
		var best: Combatant = null
		var best_d := INF
		for foe in foes:
			if foe == null or not foe.is_alive() or exclude.has(foe):
				continue
			var d := from_target.pos.distance_to(foe.pos)
			if d < best_d:
				best_d = d
				best = foe
		return best


class SandAttack extends MoveBehavior:
	func on_strike(inc: Incoming, battle: Battle) -> bool:
		if inc.attacker.taunt_atk_bonus:
			inc.attacker.taunt_atk_bonus = false
			inc.attacker.taunted_by = null
		if inc.attacker.is_blind() and randf() < 0.35:
			battle.log_message.emit("%s erra o Sand Attack devido à cegueira! (MISS!)" % inc.attacker.name)
			battle.hit_resolved.emit(inc.attacker, inc.target, inc.element, {
				"status": true, "evaded": true, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": inc.whiffed, "power": 0.0,
				"skill_name": inc.label
			})
		elif inc.auto_dodged or inc.dodged or inc.target.is_invulnerable_target():
			if inc.auto_dodged:
				battle.grant_atb(inc.target, 1, inc.target)
				battle.log_message.emit("%s esquiva do Sand Attack automaticamente! +1 bloco (MISS!)" % inc.target.name)
			elif inc.target.is_invulnerable_target():
				battle.log_message.emit("%s não está lá e o Sand Attack erra completamente! (MISS!)" % inc.target.name)
			else:
				battle.log_message.emit("%s esquivou do Sand Attack! (MISS!)" % inc.target.name)
			battle.hit_resolved.emit(inc.attacker, inc.target, inc.element, {
				"status": true, "evaded": true, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": inc.whiffed, "power": 0.0,
				"skill_name": inc.label
			})
		else:
			inc.target.blind_timer = 4.0
			battle.log_message.emit("%s foi atingido pela areia e fica cego por 4 segundos!" % inc.target.name)
			battle.hit_resolved.emit(inc.attacker, inc.target, inc.element, {
				"status": true, "evaded": false, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": inc.whiffed, "power": 0.0,
				"skill_name": inc.label, "blind": true
			})
		return true

	func ai_attack_value(c: Combatant, target: Combatant, _battle: Battle) -> float:
		return 0.0 if target.is_blind() or target.is_invulnerable_target() else 22.0


class KarateChop extends MoveBehavior:
	func on_contact(attacker: Combatant, target: Combatant, info: Dictionary, battle: Battle) -> void:
		if randf() < 0.30:
			if target.can_buff("speed", -1):
				target.buff_stat("speed", -1)
				battle.log_message.emit("Karate Chop atinge um ponto vital! A velocidade de %s foi reduzida (-1 VEL)!" % target.name)
			else:
				battle.log_message.emit("Karate Chop atinge um ponto vital, mas a velocidade de %s já está no patamar mínimo (-5)!" % target.name)
			return
		super.on_contact(attacker, target, info, battle)


class Bite extends MoveBehavior:
	func on_contact(attacker: Combatant, target: Combatant, info: Dictionary, battle: Battle) -> void:
		if randf() < 0.30:
			target.stun_timer = 2.0
			battle.log_message.emit("%s foi atordoado pela Mordida por 2 segundos!" % target.name)
			var had_interrupted := false
			for inc_check in battle.incoming.duplicate():
				if inc_check.attacker == target:
					had_interrupted = true
					break
			if had_interrupted:
				battle.grant_atb(attacker, 1, target)
				battle.log_message.emit("%s interrompeu a ação de %s com o atordoamento! (+1 ATB)" % [attacker.name, target.name])
			info["interrupted"] = battle.interrupt_attacks_of(target, attacker, 1.8)
			return
		super.on_contact(attacker, target, info, battle)


class BoulderSmash extends MoveBehavior:
	const DEF_CHANCE := 0.20  ## D-1005

	func on_contact(attacker: Combatant, target: Combatant, info: Dictionary, battle: Battle) -> void:
		super.on_contact(attacker, target, info, battle)
		if not target.is_alive() or String(info.get("armor", "")) != "":
			return
		if randf() < CrawlmonAttributeMath.status_application_chance(DEF_CHANCE, attacker.luk, target.luk) and target.can_buff("def", -1):
			target.buff_stat("def", -1)
			info["debuff"] = "def"
			info["def_down_proc"] = true
			battle.log_message.emit("Boulder Smash lowers %s's DEF (-1)!" % target.name)


class ElectricBeam extends MoveBehavior:
	const STUN_CHANCE := 0.20  ## D-977
	const STUN_TIME := 4.0  ## D-977: seconds

	func on_contact(attacker: Combatant, target: Combatant, info: Dictionary, battle: Battle) -> void:
		super.on_contact(attacker, target, info, battle)
		if not target.is_alive() or String(info.get("armor", "")) != "":
			return
		var stun_chance := CrawlmonAttributeMath.status_application_chance(STUN_CHANCE, attacker.luk, target.luk)
		if randf() < stun_chance:
			target.stun_timer = maxf(target.stun_timer, STUN_TIME)
			info["stun"] = true
			battle.log_message.emit("%s is stunned by Electric Beam for %d seconds!" % [target.name, int(STUN_TIME)])


class FireBullet extends MoveBehavior:
	func on_contact(attacker: Combatant, target: Combatant, info: Dictionary, battle: Battle) -> void:
		super.on_contact(attacker, target, info, battle)
		if not bool(info.get("interrupted", false)) or not target.is_alive() or String(info.get("armor", "")) != "":
			return
		var was_burning := target.is_burning()
		target.apply_burn()
		info["burn"] = true
		battle.log_message.emit("%s %s!" % [target.name, "continua queimando (Burn renovado)" if was_burning else "está queimando"])
		battle.burn_applied.emit(target)


# Media: regra própria em res://content/moves/media/behavior.gd (D-1079, Fase 2).
class Tarukaja extends MoveBehavior:
	func on_status(inc: Incoming, battle: Battle) -> bool:
		var team: Array[Combatant] = battle.party if inc.attacker.is_player else battle.enemies
		var any_increased := false
		for ally in team:
			if ally.is_alive():
				var capped := not ally.can_buff("atk", 1)
				if not capped:
					ally.buff_stat("atk", 1)
					any_increased = true
				battle.hit_resolved.emit(inc.attacker, ally, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label, "buff": "atk", "capped": capped
				})
		if any_increased:
			battle.log_message.emit("%s usa Tarukaja! O ataque da equipe aumentou!" % inc.attacker.name)
		else:
			battle.log_message.emit("%s usa Tarukaja! O ataque da equipe já está no patamar máximo (+5)!" % inc.attacker.name)
		return true

	func ai_status_value(c: Combatant, _target: Combatant, battle: Battle) -> float:
		var team: Array[Combatant] = battle.party if c.is_player else battle.enemies
		var total := 0.0
		for ally in team:
			if ally.is_alive() and ally.can_buff("atk", 1):
				total += 22.0 * (1.0 - float(maxi(ally.atk_buff, 0)) / 5.0)
		return total


class Rakunda extends MoveBehavior:
	func on_status(inc: Incoming, battle: Battle) -> bool:
		if inc.target.is_alive():
			var capped := not inc.target.can_buff("def", -1)
			if not capped:
				inc.target.buff_stat("def", -1)
				battle.log_message.emit("%s usa Rakunda! A defesa de %s foi reduzida!" % [inc.attacker.name, inc.target.name])
			else:
				battle.log_message.emit("%s usa Rakunda! A defesa de %s já está no patamar mínimo (-5)!" % [inc.attacker.name, inc.target.name])
			battle.hit_resolved.emit(inc.attacker, inc.target, inc.element, {
				"status": true, "evaded": false, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
				"skill_name": inc.label, "debuff": "def", "capped": capped
			})
		return true

	func ai_status_value(_c: Combatant, target: Combatant, _battle: Battle) -> float:
		return _debuff_value(target, "def", target.def_buff, 34.0)


class Sukunda extends MoveBehavior:
	func on_status(inc: Incoming, battle: Battle) -> bool:
		if inc.target.is_alive():
			var capped := not inc.target.can_buff("speed", -1)
			if not capped:
				inc.target.buff_stat("speed", -1)
				battle.log_message.emit("%s usa Sukunda! A agilidade de %s foi reduzida!" % [inc.attacker.name, inc.target.name])
			else:
				battle.log_message.emit("%s usa Sukunda! A agilidade de %s já está no patamar mínimo (-5)!" % [inc.attacker.name, inc.target.name])
			battle.hit_resolved.emit(inc.attacker, inc.target, inc.element, {
				"status": true, "evaded": false, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
				"skill_name": inc.label, "debuff": "spd", "capped": capped
			})
		return true

	func ai_status_value(_c: Combatant, target: Combatant, _battle: Battle) -> float:
		return _debuff_value(target, "speed", target.speed_buff, 24.0)


class ArmoredBulk extends MoveBehavior:
	const ARMOR_SECONDS := 8.0  ## D-1026

	func on_status(inc: Incoming, battle: Battle) -> bool:
		var user := inc.attacker
		var was_armored := user.is_armored()
		user.apply_armor(ARMOR_SECONDS)
		battle.log_message.emit("%s usa Armored Bulk! %s" % [user.name, "ARMOR renovada (+8 s)." if was_armored else "ARMOR ativa por 8 s."])
		battle.hit_resolved.emit(user, user, inc.element, {
			"status": true, "evaded": false, "dmg": 0, "weak": false,
			"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
			"skill_name": inc.label, "armor": "started", "armor_extended": was_armored
		})
		return true

	func ai_status_value(c: Combatant, _target: Combatant, battle: Battle) -> float:
		if c.is_armored():
			return 0.0
		for incoming in battle.incoming:
			if incoming.target == c and not incoming.ghost and incoming.kind != Skill.Kind.STATUS and not incoming.is_friendly:
				var move := MoveCatalog.get_move(BattleSpace.move_id(incoming.label))
				if move != null and move.has_tag(&"armor_worthy"):
					return 60.0
		return 0.0


class Taunt extends MoveBehavior:
	func on_status(inc: Incoming, battle: Battle) -> bool:
		if inc.target.is_alive():
			inc.target.taunted_by = inc.attacker
			inc.target.taunt_atk_bonus = true
			battle.log_message.emit("%s usa Taunt em %s! %s é provocado a atacar %s!" % [inc.attacker.name, inc.target.name, inc.target.name, inc.attacker.name])
			for other in battle.incoming:
				if other.attacker == inc.target and not other.is_friendly and not other.is_aoe and other.kind != Skill.Kind.STATUS:
					other.target = inc.attacker
					battle.log_message.emit("O ataque de %s foi redirecionado para %s pelo Taunt!" % [inc.target.name, inc.attacker.name])
			battle.hit_resolved.emit(inc.attacker, inc.target, inc.element, {
				"status": true, "evaded": false, "dmg": 0, "weak": false,
				"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
				"skill_name": inc.label, "taunt": true
			})
		return true

	func ai_status_value(c: Combatant, target: Combatant, battle: Battle) -> float:
		if target.taunted_by != null:
			return 0.0
		var team: Array[Combatant] = battle.party if c.is_player else battle.enemies
		var own_share := float(c.hp) / float(c.max_hp)
		for ally in team:
			if ally != c and ally.is_alive() and float(ally.hp) / float(ally.max_hp) < minf(own_share, 0.5):
				return 40.0
		return 4.0


class WarCry extends MoveBehavior:
	## D-1102: interrupts every enemy still in WINDUP. No damage, STUN or push; the spent
	## ATB is not refunded. One Burst for the caster if at least one enemy is interrupted.
	func on_status(inc: Incoming, battle: Battle) -> bool:
		var foes: Array[Combatant] = battle.enemies if inc.attacker.is_player else battle.party
		var interrupted := 0
		var interrupted_at: Combatant = null
		for foe in foes:
			if not foe.is_alive():
				continue
			if battle.interrupt_windup_of(foe, inc.attacker):
				interrupted += 1
				if interrupted_at == null:
					interrupted_at = foe  # The Burst flies from where the rupture happened.
				battle.hit_resolved.emit(inc.attacker, foe, inc.element, {
					"status": true, "evaded": false, "dmg": 0, "weak": false,
					"crit": false, "gain": 0, "whiffed": false, "power": 0.0,
					"skill_name": inc.label, "interrupted": true
				})
		if interrupted > 0:
			var burst_before := inc.attacker.burst
			inc.attacker.burst = mini(inc.attacker.burst + 1, Combatant.BURST_MAX)
			var burst_gained := inc.attacker.burst > burst_before
			if burst_gained:
				battle.grant_burst(inc.attacker, interrupted_at, true)
			battle.log_message.emit("%s usa War Cry! %d inimigo(s) interrompido(s)! %s" % [
				inc.attacker.name, interrupted, "(+1 Burst)" if burst_gained else "(Burst já cheio)"])
		else:
			battle.log_message.emit("%s usa War Cry, mas ninguém estava em wind-up." % inc.attacker.name)
		return true

	func ai_status_value(c: Combatant, _target: Combatant, battle: Battle) -> float:
		var foes: Array[Combatant] = battle.enemies if c.is_player else battle.party
		var count := 0
		for foe in foes:
			if foe.is_alive() and battle.has_windup(foe):
				count += 1
		return 0.0 if count == 0 else 25.0 + 10.0 * float(count)



