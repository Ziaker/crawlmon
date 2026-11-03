class_name Combatant
extends RefCounted
## A participant in an ATB battle. The ATB gauge is measured in blocks (0..5)
## and fills continuously; actions spend whole blocks from it.

signal damaged(combatant: Combatant, amount: int)
signal died(combatant: Combatant)
signal odometer_ticked(combatant: Combatant, new_value: int)  ## Mother 3 rolling HP odometer tick (D-048)

static var rolling_hp_enabled: bool = true

enum Act { ATTACK, SKILL, HOLD }  ## Tactics: what an AI ally does with its blocks.
enum React { NONE, EVADE }  ## Tactics: how an AI ally reacts to incoming attacks.

const BLOCKS := 5.0
const BURST_MAX := 5
const ATB_PACE_MULT := 1.0

var name: String
var max_hp: int
var hp: int
var target_hp: int
var rolling_hp: float
var _last_int_rolling_hp: int
var base_attack: int
var base_speed: float  ## Blocks per second.
var is_player: bool
var in_battle := false
var skills: Array[Skill] = []
var weaknesses: Array[Element.Type] = []
var held_item_id := ""
var inventory: Dictionary = {}  ## item id -> count (the leader shares GameState.inventory).
var skill_cursor := 0  ## Next skill an AI on the SKILL policy tries.
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
var counter_ready := false  ## True right after a manual Evade: the next attack has no wind-up.
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
var clips: Dictionary = {}  ## Animation name -> seconds; registered by whoever loads the model.

var atk_buff := 0   ## -2 .. +2 (Tarukaja / Tarunda)
var def_buff := 0   ## -2 .. +2 (Rakukaja / Rakunda)
var speed_buff := 0 ## -2 .. +2 (Sukukaja / Sukunda)

# Novos estados de combate (D-032)
var is_invulnerable := false  ## Sumido em Teleport/Dig: imune a ataques direcionados.
var stun_timer := 0.0         ## Atordoamento em segundos: ATB pausado, ações bloqueadas.
var blind_timer := 0.0        ## Cegueira em segundos: 35% de chance de errar ações ofensivas.
var taunted_by: Combatant = null  ## Alvo único forçado pelo Taunt.
var taunt_atk_bonus := false  ## Bônus de +1 estágio de ATK exclusivo para a ação provocada.

var attack: int:
	get:
		var extra_stage := 1 if taunt_atk_bonus else 0
		var mult := 1.0 + float(atk_buff + extra_stage) * 0.25
		return maxi(1, roundi(base_attack * maxf(mult, 0.4)))

var speed: float:
	get:
		var mult := 1.0 + float(speed_buff) * 0.25
		return maxf(base_speed * maxf(mult, 0.3), 0.1)


func is_stunned() -> bool:
	return stun_timer > 0.0


func is_blind() -> bool:
	return blind_timer > 0.0


func is_invulnerable_target() -> bool:
	return is_invulnerable


func _init(p_name: String, p_hp: int, p_attack: int, p_speed: float, p_is_player: bool) -> void:
	name = p_name
	max_hp = p_hp
	hp = p_hp
	target_hp = p_hp
	rolling_hp = float(p_hp)
	_last_int_rolling_hp = p_hp
	base_attack = p_attack
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
	target_hp = hp
	rolling_hp = float(hp)
	_last_int_rolling_hp = hp


func take_damage(amount: int) -> void:
	var def_mult := 1.0 - float(def_buff) * 0.25
	var final_dmg := maxi(1, roundi(amount * maxf(def_mult, 0.4)))

	if not is_player or not rolling_hp_enabled:
		hp = maxi(hp - final_dmg, 0)
		target_hp = hp
		rolling_hp = float(hp)
		_last_int_rolling_hp = hp
		damaged.emit(self, final_dmg)
		if hp == 0:
			died.emit(self)
		return

	# D-048: Vida Rolante estilo Mother 3 / EarthBound
	# Dano fatal (dano >= vida restante): morte imediata sem odômetro conforme decisão do criador
	if final_dmg >= hp:
		hp = 0
		target_hp = 0
		rolling_hp = 0.0
		_last_int_rolling_hp = 0
		damaged.emit(self, final_dmg)
		died.emit(self)
		return

	# Dano não-fatal: atualiza o alvo e deixa o odômetro rolar com o tempo
	target_hp = maxi(target_hp - final_dmg, 1)
	damaged.emit(self, final_dmg)


func tick_rolling_hp(delta: float) -> void:
	if not is_player or not rolling_hp_enabled or hp == 0:
		return
	if is_equal_approx(rolling_hp, float(target_hp)):
		rolling_hp = float(target_hp)
		hp = target_hp
		_last_int_rolling_hp = hp
		return

	# Taxa proporcional à vida máxima: ~3.0s para percorrer 100% de max_hp (D-048)
	var drain_speed := maxf(float(max_hp) / 3.0, 5.0)
	rolling_hp = move_toward(rolling_hp, float(target_hp), drain_speed * delta)
	var new_int_hp := roundi(rolling_hp)
	if new_int_hp != _last_int_rolling_hp:
		_last_int_rolling_hp = new_int_hp
		hp = new_int_hp
		odometer_ticked.emit(self, new_int_hp)


func buff_stat(stat: String, delta: int) -> int:
	match stat.to_lower():
		"attack", "atk":
			atk_buff = clampi(atk_buff + delta, -2, 2)
			return atk_buff
		"defense", "def":
			def_buff = clampi(def_buff + delta, -2, 2)
			return def_buff
		"speed", "spd":
			speed_buff = clampi(speed_buff + delta, -2, 2)
			return speed_buff
	return 0


func clear_buffs() -> void:
	atk_buff = 0
	def_buff = 0
	speed_buff = 0


func heal(amount: int) -> void:
	if not is_player or not rolling_hp_enabled or not in_battle:
		hp = mini(hp + amount, max_hp)
		target_hp = hp
		rolling_hp = float(hp)
		_last_int_rolling_hp = hp
		return

	# D-048: Cura atualiza o alvo e inverte o rolamento suavemente
	target_hp = mini(target_hp + amount, max_hp)


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
	is_invulnerable = false
	stun_timer = 0.0
	blind_timer = 0.0
	taunted_by = null
	taunt_atk_bonus = false
	clear_buffs()


func weakness_text() -> String:
	var names := PackedStringArray()
	for w in weaknesses:
		names.append(Element.name_of(w))
	return ", ".join(names)
