class_name Combatant
extends RefCounted
## A participant in an ATB battle. The ATB gauge is measured in blocks (0..5)
## and fills continuously; actions spend whole blocks from it.

signal damaged(combatant: Combatant, amount: int)
signal died(combatant: Combatant)

enum Act { ATTACK, SKILL, HOLD }  ## Tactics: what an AI ally does with its blocks.
enum React { NONE, EVADE }  ## Tactics: how an AI ally reacts to incoming attacks.

const BLOCKS := 5.0
const BURST_MAX := 5
const ATB_PACE_MULT := 1.0

var name: String
var max_hp: int
var hp: int
var base_attack: int
var base_speed: float  ## Blocks per second.
var is_player: bool
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

var attack: int:
	get:
		return base_attack

var speed: float:
	get:
		return base_speed


func _init(p_name: String, p_hp: int, p_attack: int, p_speed: float, p_is_player: bool) -> void:
	name = p_name
	max_hp = p_hp
	hp = p_hp
	base_attack = p_attack
	base_speed = p_speed
	is_player = p_is_player


## The (fractional) step the body is drawn at while it moves between two positions.
func visual_step() -> float:
	var k := clampf(step_t, 0.0, 1.0)
	return lerpf(step_from, float(pos_step), k * k * (3.0 - 2.0 * k))


func get_held_item() -> Item:
	return Item.get_item(held_item_id) if held_item_id != "" else null


func is_alive() -> bool:
	return hp > 0


func tick(delta: float) -> void:
	if is_alive():
		atb = minf(atb + speed * ATB_PACE_MULT * delta, BLOCKS)


## A burst charge pays for any one action for free.
func can_pay(cost: float) -> bool:
	return burst > 0 or blocks() >= cost


func pay(cost: float) -> void:
	if burst > 0:
		burst -= 1
	else:
		spend(cost)


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	damaged.emit(self, amount)
	if hp == 0:
		died.emit(self)


func heal(amount: int) -> void:
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


func weakness_text() -> String:
	var names := PackedStringArray()
	for w in weaknesses:
		names.append(Element.name_of(w))
	return ", ".join(names)
