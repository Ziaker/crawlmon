class_name Combatant
extends RefCounted
## A participant in an ATB battle. The ATB gauge is measured in blocks (0..5)
## and fills continuously; actions spend whole blocks from it.

signal damaged(combatant: Combatant, amount: int)
signal died(combatant: Combatant)
signal buff_changed(combatant: Combatant, stat: String, new_val: int)  ## Visual and physical buff updates (D-158)
signal guard_ended(combatant: Combatant, reason: String)  ## D-272: "expired", "hit" or "broken".

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
var mag: int  ## Magic (MAG, D-122/D-131). PROVISIONAL: mirrors base_attack until the real attribute data exists.
var base_speed: float  ## Blocks per second.
## Six permanent attributes (D-130/D-131). Not wired to combat yet (D-001); keep 0
## until the creator approves the conversion/base values (D-269/D-270).
var str: int = 0
var vit: int = 0
var spi: int = 0
var agi: int = 0
var luk: int = 0
## Progression fields (R13-Q4/R14-Q4/R26-Q3). XP/level-up rules are not active yet.
var level: int = 1
var xp: int = 0
var distributable_points: int = 0
var is_player: bool
var in_battle := false
var skills: Array[Skill] = []
var weaknesses: Array[Element.Type] = []
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

# Novos estados de combate (D-032)
var is_invulnerable := false  ## Sumido em Teleport/Dig: imune a ataques direcionados.
var stun_timer := 0.0         ## Atordoamento em segundos: ATB pausado, ações bloqueadas.
var blind_timer := 0.0        ## Cegueira em segundos: 35% de chance de errar ações ofensivas.
var taunted_by: Combatant = null  ## Alvo único forçado pelo Taunt.
var taunt_atk_bonus := false  ## Bônus de +1 estágio de ATK exclusivo para a ação provocada.
var guard_timer := 0.0        ## D-272: segundos restantes de Guard. Enquanto > 0: sem outras ações e ATB pausado.
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
		return maxf(0.1, base_speed * mult)


func is_stunned() -> bool:
	return stun_timer > 0.0


func is_blind() -> bool:
	return blind_timer > 0.0


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
	var final_dmg: int
	if fixed:
		final_dmg = amount
	elif def_buff >= 0:
		final_dmg = maxi(1, roundi(float(amount) / (1.0 + float(def_buff) * 0.25)))
	else:
		final_dmg = maxi(1, roundi(float(amount) * (1.0 + float(abs(def_buff)) * 0.25)))

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
	is_invulnerable = false
	stun_timer = 0.0
	blind_timer = 0.0
	clear_burn()
	taunted_by = null
	taunt_atk_bonus = false
	queued_skill = null
	queued_target = null
	clear_buffs()


func weakness_text() -> String:
	var names := PackedStringArray()
	for w in weaknesses:
		names.append(Element.name_of(w))
	return ", ".join(names)
