class_name PerceptionGuardDriver
extends Node
## D-274: stands in for Battle's clock in the perception run. It counts the Guard down like
## Combatant.tick does and ends it the way Battle does: "expired" when the time runs out, or "hit" /
## "broken" at hit_at. Only drives the picture; no combat rule is involved.

var combatant: Combatant
var fx_guard: FxGuard
var end_reason := "expired"  ## "expired", "hit" or "broken"
var hit_at := -1.0  ## Seconds after the Guard starts (negative: no contact).
var _t := 0.0


func _process(delta: float) -> void:
	if combatant == null or combatant.guard_timer <= 0.0:
		return
	_t += delta
	if hit_at >= 0.0 and _t >= hit_at:
		combatant.guard_timer = 0.0
		fx_guard.stop(combatant, end_reason)
		return
	combatant.guard_timer = maxf(combatant.guard_timer - delta, 0.0)
	if combatant.guard_timer <= 0.0:
		fx_guard.stop(combatant, "expired")
