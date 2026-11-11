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
var is_aoe := false
var is_friendly := false
var skill: Skill = null
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
## Mechanical stop: the action no longer advances its timeline. It is also set by ends that
## are NOT an interruption on screen (battle end, a non-perfect Evade cancelling its own run,
## a hit during the return). Do not use it alone for the HUD (D-1160).
var interrupted := false
## D-1160: the action was REALLY stopped in progress (hit before its impact, War Cry/status
## cancel, clash). Only this flag destroys the AttackTag; dodged/auto_dodged are misses
## (D-104/D-106) and the card leaves normally.
var interruption_feedback := false
var evader_home := false  ## Dodged by a non-perfect Evade during the evader's run: it went home (D-029).
var perfect := false  ## Dodged by a perfect Evade, standing still or on its own run (D-164).
var evader_teleported := false  ## The perfect Evade came during the evader's own run: it jumped to the opponent (D-027).
var ghost := false  ## Not an attack: only the return of an engaged character.
var ai_dodge_rolled := false  ## D-1007
var ai_dodge_armed := false  ## D-1014: the AI picked its moment inside the window
var ai_dodge_in := -1.0  ## D-1007: seconds until an AI target dodges (-1: it will not)
var ai_evade_at := -1.0  ## Seconds into TRAVEL when an AI target will try to evade (-1: never).
## Kinematics, planned by AttackPlanner when the wind-up ends (flat x/z, seconds):
var move_id := ""
var move_data: MoveData = null  ## D-1079: ficha canônica do Move (planejamento, regras e IA).
var motion := "cast"  ## "melee" (runs at the target), "engaged" (already next to it) or "cast"
var from := Vector3.ZERO  ## Where the attacker starts its run
var stand := Vector3.ZERO  ## Where it stops in front of the target (follows the target while it runs/strikes)
var stand_gap := BattleSpace.STAND_GAP  ## Contact distance of this Move (mid-range Moves stop far away).
var dir := Vector3.RIGHT
var run_t := 0.0
var antic := 0.0
var strike_speed := 1.0  ## D-241: playback speed of the attack clip during the strike, so its contact frame falls on `hit`
var hit := 0.0  ## Seconds into the strike phase after the anticipation when the clip makes contact
var hold := 0.0
var hop_t := 0.3
var hop_h := 1.2
var fly := 0.0
var lunged := Vector3.ZERO  ## Where the body was when the return started
var push := Vector3.ZERO  ## Knockback it takes before hopping home (an attacker hit on its way)
var aim := Vector3.ZERO  ## Where a projectile is heading now (the live target, or the spot it missed)
var proj_pos := Vector3.ZERO  ## Where the projectile is now
var blink := false  ## Teleporte Rapido: the caster itself blinks to `dest` and back.
var dest := Vector3.ZERO
var ai_guard_eta := -1.0  ## D-285: seconds before the impact when the AI target raises its Guard (-1: it will not)
var catching := false  ## D-286: the attacker is sliding to a target that moved during the strike
var clash := false  ## D-279: bumped into an opposing runner; the run is replaced by the bump hop.
var clash_start := 0.0  ## Seconds into TRAVEL when it bumped.
var clash_from := Vector3.ZERO
var clash_land := Vector3.ZERO
var clash_mode := ""  ## "strike" (both were running at each other: both strike from here) or "cancel" (different targets: back home)
var arrived := false  ## An engaged evader's first attack: the rules just moved it next to its opponent.
var data := {}  ## Drawing data owned by BattleFx (positions, clip times); logic never reads it.
## D-1025: Tidal Surge's bounce chain. The main Incoming is the root; each bounce is its own Incoming with its own
## travel, evade roll and hit, but no ATB/MP cost and no extra ATB/Burst. `bounce_targets` lives on the root and
## lists every target already hit by the chain (main + bounces), so the next nearest never repeats one.
var bounce_root: Incoming = null
var bounce_index := 0
var bounce_from_target: Combatant = null
var bounce_no_reward := false
var bounce_targets: Array = []


func phase_len() -> float:
	return plan[plan_i][1] if plan_i >= 0 and plan_i < plan.size() else 0.0


## 0..1 inside the current phase.
func progress() -> float:
	var l := phase_len()
	return clampf(phase_time / l, 0.0, 1.0) if l > 0.0 else 1.0


## The manual Evade works only while the attack is on its way (the run or the projectile).
func can_evade_now() -> bool:
	# D-988 (changes D-283/D-987): the PERFECT_WINDOW seconds that END Battle.PRELUDE_GAP seconds before the contact: the
	# moment the attacker rises into the blow (measured on the Tackle: rises at 0.37-0.63 s of a 0.88 s strike).
	# A strike shorter than both keeps a window from its start (never empty).
	if not in_strike_window():
		return false
	var left := phase_len() - phase_time
	return left > window_end() and left <= window_end() + Battle.PERFECT_WINDOW


## D-1014: seconds before the contact at which the valid window closes: a melee strike closes it at the
## prelude (PRELUDE_GAP before the contact, D-988); a projectile or an area spell closes it at the hit.
func window_end() -> float:
	if motion != "melee":
		return 0.0
	return minf(Battle.PRELUDE_GAP, maxf(phase_len() - Battle.PERFECT_WINDOW, 0.0))


## D-1014: seconds left until the valid window closes (<= 0 when it is closed or not reached).
func window_left() -> float:
	return phase_len() - phase_time - window_end()


## D-1006: the manual Evade works from the wind-up to the contact, and always counts as perfect.
func can_dodge_now() -> bool:
	if kind == Skill.Kind.STATUS or is_friendly or impacted or interrupted or ghost:
		return false
	return phase == Phase.WINDUP or phase == Phase.TRAVEL or phase == impact_phase


## The strike itself: the phase that ends with the hit (D-030), where the Evade prompt is shown. Status moves
## and friendly moves are never dodged (D-012).
func in_strike_window() -> bool:
	if kind == Skill.Kind.STATUS or is_friendly:
		return false
	return resolved and not impacted and not interrupted and not ghost and phase == impact_phase


## Seconds of travel left (the Evade window); large when it is not travelling.
func travel_left() -> float:
	return phase_len() - phase_time if in_strike_window() else 99.0


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
