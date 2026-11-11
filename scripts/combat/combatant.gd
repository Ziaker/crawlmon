class_name Combatant
extends RefCounted
## A participant in an ATB battle. The ATB gauge is measured in blocks (0..5)
## and fills continuously; actions spend whole blocks from it.

signal damaged(combatant: Combatant, amount: int)
signal died(combatant: Combatant)
signal buff_changed(combatant: Combatant, stat: String, new_val: int)  ## Visual and physical buff updates (D-158)
signal guard_ended(combatant: Combatant, reason: String)  ## D-272: "expired", "hit" or "broken".
signal shield_ended(combatant: Combatant, reason: String)  ## "expired", "broken", "hit" or "battle_end".
signal armor_changed(combatant: Combatant, state: String)  ## D-1026: "started", "extended", "hit", "expired" or "battle_end".
signal experience_gained(amount: int, current_xp: int, xp_required: int)
signal level_up_occurred(new_level: int, points_gained: int)

const CrawlmonAttributeMath = preload("res://scripts/combat/crawlmon_attribute_math.gd")

enum Act { ATTACK, SKILL, HOLD }  ## Tactics: what an AI ally does with its blocks.
enum React { NONE, EVADE }  ## Tactics: how an AI ally reacts to incoming attacks.

const BLOCKS := 5.0
const BURST_MAX := 5
const ATB_PACE_MULT := 1.0

var name: String
var species_id := ""  ## Overworld sprite id (e.g. "abra"); empty for enemies without one.
var max_hp: int
var hp: int
var base_attack: int
var uses_effective_strength := false  ## D-1143: normal characters derive attack from effective STR; test overrides keep an explicit attack.
var mag: int  ## Magic (MAG, D-122/D-131). Set from the innate attributes by CharacterFactory; scales magical damage (D-1140).
var base_speed: float  ## Blocks per second.
## Atributos permanentes canonicos (D-120, D-130, D-131, D-391).
var str: int = 0
var vit: int = 0
var wis: int = 0
## Alias de compatibilidade para referencias legadas a SPI (D-391).
var spi: int:
	get:
		return wis
	set(value):
		wis = value
var agi: int = 0
var luk: int = 0

## Recursos de combate e ficha (D-391, D-392).
var max_mp: int = 0
var mp: int = 0

## Individualidade, Natures e Progressao (D-393, D-394).
var nature_id: String = "hardy"
var individual_offsets: Dictionary = {}
var innate_stats: Dictionary = {"STR": 1, "MAG": 1, "VIT": 1, "WIS": 1, "AGI": 1, "LUK": 1}
var progression_points: Dictionary = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
var action_counts: Dictionary = {"PHYSICAL": 0, "MAGIC": 0, "GUARD": 0, "EVADE": 0}

## Progression fields (R13-Q4/R14-Q4/R26-Q3). XP/level-up rules (D-394, D-399, D-401, D-402).
var level: int = 1
var xp: int = 0
var distributable_points: int = 0
var base_experience: int = 30
var is_player: bool
var in_battle := false
var skills: Array[Skill] = []
var elements: Array[Element.Type] = []  ## Species innate element(s) (D-413).


func get_elements() -> Array[Element.Type]:
	if not elements.is_empty():
		return elements
	var sp := species_id.to_lower()
	if sp == "abra" or name.to_lower() == "abra":
		return [Element.Type.PSIQUICO]
	elif sp == "pancham" or name.to_lower() == "pancham":
		return [Element.Type.FISICO, Element.Type.TREVAS]
	elif sp == "dqt_slime" or sp == "slime":
		return [Element.Type.AGUA_GELO]
	elif sp == "gible":
		return [Element.Type.TERRA]
	elif sp == "cyclops":
		return [Element.Type.FISICO, Element.Type.TERRA]
	elif sp == "orc":
		return [Element.Type.FISICO]
	return [Element.Type.FISICO]
var weaknesses: Array[Element.Type] = []
var affinities: Dictionary = {}  ## D-1157: element int -> Affinity.Type int. WEAK active; the rest is schema.
var held_item_id := ""
var inventory: Dictionary = {}  ## item id -> count (the leader shares GameState.inventory).
var act_policy := Act.ATTACK
var react_policy := React.NONE
var atb := 0.0
var extra := 0.0  ## ATB blocks beyond the five normal ones (GDD: spent first, no cap).
var burst := 0
## Rewards credited to the logic whose token has not reached the HUD yet (the HUD shows
## those blocks as reserved until they land).
var pending_atb := 0
var pending_extra := 0
var pending_burst := 0
var counter_ready := false  ## True right after a perfect Evade: the next attack has no wind-up (D-164).
var queued_skill: Skill = null  ## The one move chosen while it could not start yet; paid when it starts (D-161).
var queued_target: Combatant = null
## Position steps (-2 behind .. +2 in front, 0 = middle). `pos_step` is the logic value;
## `step_from`/`step_t` animate the move on Battle's clock (BattleFx draws `visual_step()`).
var pos_step := 0
var step_from := 0.0
var step_t := 1.0
var tactic_pos := 0  ## Where an AI-controlled ally wants to stand (set in Tactics).
var engaged_with: Combatant = null  ## Standing next to the opponent it interrupted (Evade).
var engage_left := 0.0  ## Real seconds left of the engaged state (the Burst slow-motion).
## Where it stands (flat x/z, authoritative: models only follow it). `home` is the step-0 spot.
var home := Vector3.ZERO
var yaw := 0.0
var pos := Vector3.ZERO
var rest := Vector3.ZERO  ## Where it stands while it is not at its step spot (engaged / stunned).
var has_rest := false
var body_scale := 1.0  ## Model scale, used as its radius when something passes in front of it.
var travel_extra := 0.0  ## D-341 PROVISIONAL: extra seconds of the melee run to the target (slow character); replaced by AGI later (D-119/D-133).
var clips: Dictionary = {}  ## Animation name -> seconds; registered by whoever loads the model.

var atk_buff := 0   ## -5 .. +5 (Tarukaja / Tarunda, D-159)
var def_buff := 0   ## -5 .. +5 (Rakukaja / Rakunda, D-159)
var speed_buff := 0 ## -5 .. +5 (Sukukaja / Sukunda, D-159)
## Badge Steal (Drain Spear): a positive shield badge and a magic-immunity badge.
var shield_hp := 0
var shield_max := 0
var shield_timer := 0.0
var shield_seconds := 0.0
var magic_immune_timer := 0.0
var magic_immune_seconds := 0.0

# Novos estados de combate (D-032)
var is_invulnerable := false  ## Sumido em Teleport/Dig: imune a ataques direcionados.
var stun_timer := 0.0         ## Atordoamento em segundos: ATB pausado, ações bloqueadas.
var blind_timer := 0.0        ## Cegueira em segundos: 35% de chance de errar ações ofensivas.
var taunted_by: Combatant = null  ## Alvo único forçado pelo Taunt.
var taunt_atk_bonus := false  ## Bônus de +1 estágio de ATK exclusivo para a ação provocada.
var guard_timer := 0.0        ## D-272: segundos restantes de Guard. Enquanto > 0: sem outras ações e ATB pausado.
var armor_timer := 0.0        ## D-1026: segundos restantes da badge ARMOR (absorve o primeiro contato de Move sem interrupção).
var burn_ticks_left := 0      ## D-238: ticks de Burn que faltam (4 ao aplicar; 2 HP fixos cada).
var burn_clock := 0.0         ## D-238: segundos até o próximo tick (o primeiro vem 1 s depois da aplicação).

var attack: int:
	get:
		var extra_stage := 1 if taunt_atk_bonus else 0
		var total_stage := mini(atk_buff + extra_stage, 5)  # Never past the +5 limit (D-167).
		var mult: float
		if total_stage >= 0:
			mult = 1.0 + float(total_stage) * 0.25
		else:
			mult = 1.0 / (1.0 + float(abs(total_stage)) * 0.25)
		return maxi(1, roundi(float(base_attack) * mult))

var speed: float:
	get:
		var mult: float
		if speed_buff >= 0:
			mult = 1.0 + float(speed_buff) * 0.25
		else:
			mult = 1.0 / (1.0 + float(abs(speed_buff)) * 0.25)
		var rate := base_speed
		if agi > 0:
			rate = CrawlmonAttributeMath.natural_atb_increment(1.0, float(agi))
		return maxf(0.1, rate * mult)


func is_stunned() -> bool:
	return stun_timer > 0.0


func is_blind() -> bool:
	return blind_timer > 0.0


## Drain Spear / Badge Steal: the shield and magic-immunity badges.
func is_shielded() -> bool:
	return shield_timer > 0.0 and shield_hp > 0


func apply_shield(amount: int, seconds: float) -> void:
	shield_hp = maxi(amount, 1)
	shield_max = shield_hp
	shield_seconds = maxf(seconds, 0.01)
	shield_timer = shield_seconds


func absorb_shield(amount: int) -> int:
	if not is_shielded() or amount <= 0:
		return 0
	var absorbed := mini(amount, shield_hp)
	shield_hp -= absorbed
	return absorbed


func end_shield(reason := "") -> void:
	var was_active := shield_timer > 0.0 or shield_hp > 0
	shield_hp = 0
	shield_timer = 0.0
	if was_active:
		shield_ended.emit(self, reason)


func tick_shield(delta: float) -> void:
	if shield_timer <= 0.0:
		return
	shield_timer = maxf(shield_timer - delta, 0.0)
	if shield_timer <= 0.0:
		shield_hp = 0
		shield_ended.emit(self, "expired")


## Receives a shield taken by Badge Steal: current reserve preserved, duration reset.
func adopt_shield(p_hp: int, p_max: int, p_seconds: float) -> void:
	shield_hp = maxi(p_hp, 1)
	shield_max = maxi(p_max, shield_hp)
	shield_seconds = maxf(p_seconds, 0.01)
	shield_timer = shield_seconds


func is_magic_immune() -> bool:
	return magic_immune_timer > 0.0


func apply_magic_immunity(seconds: float) -> void:
	magic_immune_seconds = maxf(seconds, 0.01)
	magic_immune_timer = magic_immune_seconds


func clear_magic_immunity() -> void:
	magic_immune_timer = 0.0
	magic_immune_seconds = 0.0


func tick_magic_immunity(delta: float) -> void:
	if magic_immune_timer <= 0.0:
		return
	magic_immune_timer = maxf(magic_immune_timer - delta, 0.0)
	if magic_immune_timer <= 0.0:
		magic_immune_seconds = 0.0


## D-238: queimando. Dura 4 s (4 ticks de 2 HP, o primeiro 1 s depois). Aplicar de novo renova os 4 ticks e mantém a cadência.
func is_burning() -> bool:
	return burn_ticks_left > 0


func apply_burn(ticks := 4) -> void:
	if burn_ticks_left <= 0:
		burn_clock = 1.0
	burn_ticks_left = ticks


func clear_burn() -> void:
	burn_ticks_left = 0
	burn_clock = 0.0


## D-1026: ARMOR badge. Reapplying only adds seconds to what is left (the badge never stacks).
func is_armored() -> bool:
	return armor_timer > 0.0


func apply_armor(seconds: float) -> void:
	var extended := armor_timer > 0.0
	armor_timer += maxf(seconds, 0.0)
	armor_changed.emit(self, "extended" if extended else "started")


## reason: "hit" (first contact of a Move), "expired" or "battle_end".
func end_armor(reason: String) -> void:
	if armor_timer <= 0.0:
		return
	armor_timer = 0.0
	armor_changed.emit(self, reason)


## It keeps counting down during a Guard (D-1026). Called from the battle clock, which does not run while a status pause holds the engine.
func tick_armor(delta: float) -> void:
	if armor_timer <= 0.0:
		return
	armor_timer = maxf(armor_timer - delta, 0.0)
	if armor_timer <= 0.0:
		armor_changed.emit(self, "expired")


func is_guarding() -> bool:
	return guard_timer > 0.0


## D-272: ends the Guard (reason: "hit", "broken" or "expired").
func end_guard(reason: String) -> void:
	if guard_timer <= 0.0:
		return
	guard_timer = 0.0
	guard_ended.emit(self, reason)


func is_invulnerable_target() -> bool:
	return is_invulnerable


func _init(p_name: String, p_hp: int, p_attack: int, p_speed: float, p_is_player: bool, p_mag := -1) -> void:
	name = p_name
	max_hp = p_hp
	hp = p_hp
	base_attack = p_attack
	mag = p_mag if p_mag > 0 else p_attack  # PROVISIONAL until the D-120/D-131 attribute table is wired in.
	base_speed = p_speed
	is_player = p_is_player


## Retorna o valor efetivo de um atributo (inato consolidado + pontos de progressao) (D-390, D-394).
func get_effective_stat(stat: String) -> int:
	var s := stat.to_upper()
	if s == "SPI":
		s = "WIS"
	return int(innate_stats.get(s, 1)) + int(progression_points.get(s, 0))


## Sincroniza as variaveis diretas com os status efetivos e atualiza a velocidade base de ATB.
func sync_effective_stats() -> void:
	str = get_effective_stat("STR")
	mag = get_effective_stat("MAG")
	vit = get_effective_stat("VIT")
	wis = get_effective_stat("WIS")
	agi = get_effective_stat("AGI")
	luk = get_effective_stat("LUK")
	if uses_effective_strength:
		base_attack = str  # D-1143: STR allocated on level-up must reach the physical damage.
	base_speed = CrawlmonAttributeMath.natural_atb_increment(1.0, float(agi))


## Identifica se este combatente e o lider ativo da equipe com guarda estrita contra party vazia.
func is_party_leader() -> bool:
	if not is_player:
		return false
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root and tree.root.has_node("GameState"):
		var gs: Node = tree.root.get_node("GameState")
		var p: Variant = gs.get("party")
		if p is Array and not (p as Array).is_empty():
			return (p as Array)[0] == self
		return false
	# Em testes unitarios isolados sem a cena GameState ativa, considera lider por padrao se is_player for true.
	return true


## Concede experiencia, processa transicoes de nivel e recalcula atributos maximos (D-394, D-399, D-400, D-402).
func add_experience(amount: int) -> Dictionary:
	var old_level: int = level
	var old_xp: int = xp
	var current_req: int = CrawlmonAttributeMath.get_xp_for_level_transition(level)

	if amount <= 0:
		return {
			"old_level": old_level,
			"new_level": level,
			"levels_gained": 0,
			"points_gained": 0,
			"old_xp": old_xp,
			"current_xp": xp,
			"xp_required": current_req,
			"transitions": []
		}

	xp += amount
	var levels_gained: int = 0
	var total_points: int = 0
	var transitions: Array[Dictionary] = []

	while true:
		var req: int = CrawlmonAttributeMath.get_xp_for_level_transition(level)
		if xp >= req:
			xp -= req
			level += 1
			levels_gained += 1
			var pts: int = CrawlmonAttributeMath.get_stat_points_for_level(level)
			total_points += pts
			if is_party_leader():
				distributable_points += pts
			update_resource_maximums()
			transitions.append({"level": level, "points": pts, "xp_required": req})
			level_up_occurred.emit(level, pts)
		else:
			break

	experience_gained.emit(amount, xp, CrawlmonAttributeMath.get_xp_for_level_transition(level))
	return {
		"old_level": old_level,
		"new_level": level,
		"levels_gained": levels_gained,
		"points_gained": total_points,
		"old_xp": old_xp,
		"current_xp": xp,
		"xp_required": CrawlmonAttributeMath.get_xp_for_level_transition(level),
		"transitions": transitions
	}


## Recalcula o HP e MP maximos com base em VIT/WIS e nivel (D-391, D-392),
## preservando deltas no valor atual e mantendo o estado de K.O. intacto (hp == 0 continua 0).
func update_resource_maximums() -> void:
	var old_max_hp := max_hp
	var old_max_mp := max_mp
	max_hp = CrawlmonAttributeMath.calculate_max_hp(level, vit)
	max_mp = CrawlmonAttributeMath.calculate_max_mp(level, wis)
	if species_id.to_lower() == "abra" or name.to_lower() == "abra":
		max_mp = maxi(max_mp, 20)  # D-413: Abra minimum MP floor of 20
	if hp > 0:
		hp = clampi(hp + (max_hp - old_max_hp), 1, max_hp)
	if mp > 0:
		mp = clampi(mp + (max_mp - old_max_mp), 0, max_mp)
	elif mp == 0 and old_max_mp == 0:
		mp = max_mp

## MP Regeneration: 4 points every 8 seconds, individual timer, resets on MP skills (D-413).
var mp_regen_timer: float = 0.0
const MP_REGEN_INTERVAL := 8.0
const MP_REGEN_FULL_ATB_MULT := 1.75  ## D-1070: with the ATB full, the MP pulse timer runs this much faster
const MP_REGEN_AMOUNT := 10  ## D-1062: the base of one pulse; the real value also scales with MAG (mp_regen_amount())

signal mp_regenerated(combatant: Combatant, amount: int)


## D-1062: MP gained per pulse: 10 + MAG / 5 up to MAG 25 (at most +5), then +1 per 10 MAG above 25. Same for every combatant.
func mp_regen_amount() -> int:
	var m := maxi(mag, 0)
	var bonus := m / 5 if m <= 25 else 5 + (m - 25) / 10
	return MP_REGEN_AMOUNT + bonus


## D-1070: all five ATB blocks are full.
func atb_full() -> bool:
	return atb >= BLOCKS - 0.001


## D-1070: how fast the MP pulse timer runs now (1.75x with the ATB full).
func mp_regen_rate() -> float:
	return MP_REGEN_FULL_ATB_MULT if atb_full() else 1.0


## D-1070: real seconds until the next MP pulse, counting the rate.
func mp_regen_left() -> float:
	return maxf(MP_REGEN_INTERVAL - mp_regen_timer, 0.0) / mp_regen_rate()


func tick_mp_regen(delta: float) -> bool:
	if not is_alive():
		return false
	if mp >= max_mp:
		mp_regen_timer = 0.0
		return false
	mp_regen_timer += delta
	if mp_regen_timer >= MP_REGEN_INTERVAL:
		mp_regen_timer = 0.0
		var gained := mini(mp_regen_amount(), max_mp - mp)
		mp += gained
		mp_regenerated.emit(self, gained)
		return true
	return false


func can_pay_skill(sk: Skill) -> bool:
	if not can_pay(sk.cost):
		return false
	if mp < sk.mp_cost:
		return false
	return true


func pay_skill(sk: Skill) -> void:
	pay(sk.cost)
	if sk.mp_cost > 0:
		mp = maxi(0, mp - sk.mp_cost)
		mp_regen_timer = 0.0  # timer resets whenever using an MP-consuming move (D-413)




## The (fractional) step the body is drawn at while it moves between two positions.
func visual_step() -> float:
	var k := clampf(step_t, 0.0, 1.0)
	return lerpf(step_from, float(pos_step), k * k * (3.0 - 2.0 * k))


## Puts the combatant on the floor at `p_home`, facing `p_yaw`.
func place(p_home: Vector3, p_yaw: float) -> void:
	in_battle = true
	home = BattleSpace.flat(p_home)
	yaw = p_yaw
	pos = home
	has_rest = false


## The spot of its current position step (what the old "home" meant).
func stand_pos() -> Vector3:
	return home + Vector3(sin(yaw), 0.0, cos(yaw)) * (BattleSpace.STEP_DIST * visual_step())


## Where it waits when no attack moves it: the rest spot if it has one, else its step spot.
func rest_pos() -> Vector3:
	return rest if has_rest else stand_pos()


func set_rest(p: Vector3) -> void:
	rest = BattleSpace.flat(p)
	has_rest = true


func clear_rest() -> void:
	has_rest = false


func clip_len(anim: String) -> float:
	return float(clips.get(anim, 0.0))


func get_held_item() -> Item:
	return Item.get_item(held_item_id) if held_item_id != "" else null


func is_alive() -> bool:
	return hp > 0


func tick(delta: float) -> void:
	if stun_timer > 0.0:
		stun_timer = maxf(stun_timer - delta, 0.0)
	if blind_timer > 0.0:
		blind_timer = maxf(blind_timer - delta, 0.0)
	if is_alive() and in_battle:
		tick_mp_regen(delta * mp_regen_rate())  # D-1070
	if guard_timer > 0.0:
		# D-272: the ATB is paused while guarding.
		guard_timer = maxf(guard_timer - delta, 0.0)
		if guard_timer <= 0.0:
			guard_ended.emit(self, "expired")
		return
	if is_alive() and stun_timer <= 0.0:
		atb = minf(atb + speed * ATB_PACE_MULT * delta, BLOCKS)


## A burst charge pays for any one action for free.
func can_pay(cost: float) -> bool:
	return burst > 0 or blocks() >= cost


func pay(cost: float) -> void:
	if burst > 0:
		burst -= 1
	else:
		spend(cost)


func set_hp_instant(value: int) -> void:
	hp = clampi(value, 0, max_hp)


## R23-Q3/R33-Q1: restaura o membro para uma nova expedição depois da derrota.
## XP/nível ficam intactos; só o estado transitório de batalha é limpo.
func revive_full() -> void:
	set_hp_instant(max_hp)
	atb = 0.0
	extra = 0.0
	burst = 0
	counter_ready = false
	clear_pending()
	clear_buffs()
	in_battle = false


## `fixed` (D-238, Burn): o dano não passa por Defense nem por estágios de buff e não tem o mínimo de 1.
func take_damage(amount: int, fixed := false) -> void:
	var final_dmg := DamageMath.final_damage(amount, def_buff, fixed)  # D-1153: single defense formula.

	# D-347: the rolling odometer is archived; HP changes immediately.
	hp = maxi(hp - final_dmg, 0)
	damaged.emit(self, final_dmg)
	if hp == 0:
		died.emit(self)


func can_buff(stat: String, delta: int) -> bool:
	match stat.to_lower():
		"attack", "atk":
			return (delta > 0 and atk_buff < 5) or (delta < 0 and atk_buff > -5)
		"defense", "def":
			return (delta > 0 and def_buff < 5) or (delta < 0 and def_buff > -5)
		"speed", "spd":
			return (delta > 0 and speed_buff < 5) or (delta < 0 and speed_buff > -5)
	return false


func buff_stat(stat: String, delta: int) -> int:
	var res := 0
	match stat.to_lower():
		"attack", "atk":
			atk_buff = clampi(atk_buff + delta, -5, 5)
			res = atk_buff
		"defense", "def":
			def_buff = clampi(def_buff + delta, -5, 5)
			res = def_buff
		"speed", "spd":
			speed_buff = clampi(speed_buff + delta, -5, 5)
			res = speed_buff
	buff_changed.emit(self, stat.to_lower(), res)
	return res


func clear_buffs() -> void:
	var had_buffs := atk_buff != 0 or def_buff != 0 or speed_buff != 0
	atk_buff = 0
	def_buff = 0
	speed_buff = 0
	if had_buffs:
		buff_changed.emit(self, "all", 0)


func heal(amount: int) -> void:
	# D-347: the rolling odometer is archived; healing is immediate.
	hp = mini(hp + amount, max_hp)


func item_count(id: String) -> int:
	return inventory.get(id, 0)


func remove_item(id: String) -> void:
	if item_count(id) <= 1:
		inventory.erase(id)
	else:
		inventory[id] -= 1


## Normal plus extra blocks.
func blocks() -> float:
	return atb + extra


## Extra blocks are spent first, then the normal ones.
func spend(cost: float) -> void:
	var from_extra := minf(extra, cost)
	extra -= from_extra
	atb = maxf(atb - (cost - from_extra), 0.0)


## Fills the bar; what does not fit becomes extra blocks.
func add_atb(amount: float) -> void:
	var in_bar := minf(amount, maxf(BLOCKS - atb, 0.0))
	atb += in_bar
	extra += amount - in_bar


## What the HUD shows: credited blocks whose token is still flying are not drawn yet.
func shown_atb() -> float:
	return maxf(atb - float(pending_atb), 0.0)


func shown_extra() -> float:
	return maxf(extra - float(pending_extra), 0.0)


func shown_burst() -> int:
	return maxi(burst - pending_burst, 0)


func clear_pending() -> void:
	pending_atb = 0
	pending_extra = 0
	pending_burst = 0
	extra = 0.0
	guard_timer = 0.0
	armor_timer = 0.0
	shield_hp = 0
	shield_max = 0
	shield_timer = 0.0
	shield_seconds = 0.0
	clear_magic_immunity()
	is_invulnerable = false
	stun_timer = 0.0
	blind_timer = 0.0
	clear_burn()
	taunted_by = null
	taunt_atk_bonus = false
	queued_skill = null
	queued_target = null
	clear_buffs()


## D-1157/D-1158: an explicit `affinities` entry wins, including NEUTRAL and WEAK.
## `weaknesses` is the legacy fallback for manual Combatants and old data.
func affinity_for(element: Element.Type) -> int:
	if affinities.has(element):
		return int(affinities[element])
	if element in weaknesses:
		return Affinity.Type.WEAK
	return Affinity.Type.NEUTRAL


func is_weak_to(element: Element.Type) -> bool:
	return affinity_for(element) == Affinity.Type.WEAK


func weakness_text() -> String:
	var names := PackedStringArray()
	for w in weaknesses:
		names.append(Element.name_of(w))
	return ", ".join(names)


## D-1165: afinidades nao neutras, na ordem dos elementos.
## Cada entrada: {"element": Element.Type, "type": Affinity.Type}.
func affinity_entries() -> Array:
	var entries: Array = []
	for element in Element.NAMES.keys():
		var kind := affinity_for(element)
		if kind != Affinity.Type.NEUTRAL:
			entries.append({"element": element, "type": kind})
	return entries


## D-1165: texto compacto para paineis/menus. Ex.: "W: Fire, Sound  ·  R: Water".
func affinity_text() -> String:
	var weak := PackedStringArray()
	var resist := PackedStringArray()
	for entry in affinity_entries():
		if int(entry["type"]) == Affinity.Type.WEAK:
			weak.append(Element.name_of(entry["element"]))
		else:
			resist.append(Element.name_of(entry["element"]))
	var parts := PackedStringArray()
	if not weak.is_empty():
		parts.append("W: " + ", ".join(weak))
	if not resist.is_empty():
		parts.append("R: " + ", ".join(resist))
	return "  ·  ".join(parts)


## Snapshot e Rollback em memória para testes de ramificação por agentes de IA (D-1042 / D-1044).
func save_state() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp, "mp": mp, "max_mp": max_mp, "mp_regen_timer": mp_regen_timer,
		"atb": atb, "extra": extra, "burst": burst,
		"pending_atb": pending_atb, "pending_extra": pending_extra, "pending_burst": pending_burst,
		"counter_ready": counter_ready, "pos_step": pos_step, "step_from": step_from, "step_t": step_t,
		"home": home, "yaw": yaw, "pos": pos, "rest": rest, "has_rest": has_rest,
		"atk_buff": atk_buff, "def_buff": def_buff, "speed_buff": speed_buff,
		"shield_hp": shield_hp, "shield_max": shield_max, "shield_timer": shield_timer, "shield_seconds": shield_seconds,
		"magic_immune_timer": magic_immune_timer, "magic_immune_seconds": magic_immune_seconds,
		"is_invulnerable": is_invulnerable, "stun_timer": stun_timer, "blind_timer": blind_timer,
		"guard_timer": guard_timer, "armor_timer": armor_timer,
		"burn_ticks_left": burn_ticks_left, "burn_clock": burn_clock,
		"taunt_atk_bonus": taunt_atk_bonus,
		"queued_skill": queued_skill, "queued_target": queued_target,  # D-1146 / D-1042
	}


func restore_state(s: Dictionary) -> void:
	max_hp = int(s.get("max_hp", max_hp))
	hp = int(s.get("hp", hp))
	max_mp = int(s.get("max_mp", max_mp))
	mp = int(s.get("mp", mp))
	mp_regen_timer = float(s.get("mp_regen_timer", mp_regen_timer))
	atb = float(s.get("atb", atb))
	extra = float(s.get("extra", extra))
	burst = int(s.get("burst", burst))
	pending_atb = int(s.get("pending_atb", pending_atb))
	pending_extra = int(s.get("pending_extra", pending_extra))
	pending_burst = int(s.get("pending_burst", pending_burst))
	counter_ready = bool(s.get("counter_ready", counter_ready))
	pos_step = int(s.get("pos_step", pos_step))
	step_from = float(s.get("step_from", step_from))
	step_t = float(s.get("step_t", step_t))
	home = s.get("home", home)
	yaw = float(s.get("yaw", yaw))
	pos = s.get("pos", pos)
	rest = s.get("rest", rest)
	has_rest = bool(s.get("has_rest", has_rest))
	atk_buff = int(s.get("atk_buff", atk_buff))
	def_buff = int(s.get("def_buff", def_buff))
	speed_buff = int(s.get("speed_buff", speed_buff))
	shield_hp = int(s.get("shield_hp", shield_hp))
	shield_max = int(s.get("shield_max", shield_max))
	shield_timer = float(s.get("shield_timer", shield_timer))
	shield_seconds = float(s.get("shield_seconds", shield_seconds))
	magic_immune_timer = float(s.get("magic_immune_timer", magic_immune_timer))
	magic_immune_seconds = float(s.get("magic_immune_seconds", magic_immune_seconds))
	is_invulnerable = bool(s.get("is_invulnerable", is_invulnerable))
	stun_timer = float(s.get("stun_timer", stun_timer))
	blind_timer = float(s.get("blind_timer", blind_timer))
	guard_timer = float(s.get("guard_timer", guard_timer))
	armor_timer = float(s.get("armor_timer", armor_timer))
	burn_ticks_left = int(s.get("burn_ticks_left", burn_ticks_left))
	burn_clock = float(s.get("burn_clock", burn_clock))
	taunt_atk_bonus = bool(s.get("taunt_atk_bonus", taunt_atk_bonus))
	queued_skill = s.get("queued_skill", null)  # D-1146: snapshot keeps the one-slot queue
	queued_target = s.get("queued_target", null)
