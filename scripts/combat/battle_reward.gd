class_name BattleReward
extends RefCounted
## A reward token: logic credits the block at once (so a counter-attack is never delayed)
## and keeps this record so the HUD can fly it to its slot on the same clock.

var id := 0
var kind := "atb"  ## "atb" or "burst"
var owner: Combatant
var source: Combatant  ## Where the token is born (who was hit, interrupted or evaded).
var slot := 0  ## Normal ATB slot 0..4, or the extra index when `extra`.
var extra := false
var delay := 0.0  ## Seconds before it spawns (staggers several tokens).
var float_time := 0.6  ## Seconds it hovers over `source` before flying.
var fly_time := 0.25  ## Seconds it takes to fly to its HUD slot.
var t := 0.0
var landed := false


## Seconds since it spawned (negative while it is still waiting).
func age() -> float:
	return t - delay
