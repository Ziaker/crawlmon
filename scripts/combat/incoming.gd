class_name Incoming
extends RefCounted
## One attack = one timeline owned by Battle: PREPARO (WINDUP) -> TRAJETO (TRAVEL) ->
## GOLPE (STRIKE) -> RETORNO (RETURN). BattleFx only draws the progress it reads here.

enum Phase { WINDUP, TRAVEL, STRIKE, RETURN, DONE, STAGGER }

var attacker: Combatant
var target: Combatant
var power := 1.0
var element := Element.Type.FISICO
var kind := 0  ## Skill.Kind.MELEE
var ground := false
var label := ""
var time_left := 0.0
var total_windup := 1.5
var dodged := false
var instant := false  ## A counter-attack after a Perfect Evade: no wind-up at all.
var evade_tried := false
var whiffed := false
var auto_dodged := false  ## Decided when the wind-up ends so the visuals can play it out.
var resolved := false  ## The wind-up is over: the attacker is on its way to hit.
## Timeline after the wind-up, filled by BattleFx on attack_resolved:
## [[Phase, seconds], ...] in order, and which phase ends with the hit.
var plan: Array = []
var impact_phase := Phase.STRIKE
var plan_i := -1
var phase := Phase.WINDUP
var phase_time := 0.0  ## Seconds spent in the current phase.
var impacted := false
var interrupted := false  ## Stopped on its way by a manual Evade: it never hits.
var ghost := false  ## Not an attack: only the return of an engaged character.
var ai_evade_at := -1.0  ## Seconds into TRAVEL when an AI target will try to evade (-1: never).
var data := {}  ## Drawing data owned by BattleFx (positions, clip times); logic never reads it.


func phase_len() -> float:
	return plan[plan_i][1] if plan_i >= 0 and plan_i < plan.size() else 0.0


## 0..1 inside the current phase.
func progress() -> float:
	var l := phase_len()
	return clampf(phase_time / l, 0.0, 1.0) if l > 0.0 else 1.0


## The manual Evade works only while the attack is on its way (the run or the projectile).
func can_evade_now() -> bool:
	return resolved and not impacted and not interrupted and not ghost and phase == Phase.TRAVEL


## Seconds of travel left (the Evade window); large when it is not travelling.
func travel_left() -> float:
	return phase_len() - phase_time if can_evade_now() else 99.0


## Seconds until the hit reaches the target. Evading only counts near this moment.
func eta() -> float:
	if not resolved:
		return time_left + 5.0
	if impacted:
		return 0.0
	var left := -phase_time
	var i := plan_i
	while i < plan.size():
		left += plan[i][1]
		if plan[i][0] == impact_phase:
			break
		i += 1
	return maxf(left, 0.0)
