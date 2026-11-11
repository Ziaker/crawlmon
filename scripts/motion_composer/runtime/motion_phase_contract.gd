class_name MotionPhaseContract
extends RefCounted
## D-953: the visual phase contract of a Move. The Battle owns the logical timeline (D-019); this only maps the
## visual phases onto it. A phase window may overlap the next one, so the charge becomes the shot without a cut.
## Durations and geometry are supplied by the caller (the real Battle or a lab). Nothing here decides damage,
## hit, evade, range or duration: it only draws (D-019, D-235).
##
## phases: [{id, start, end, draw_phase}]
## `draw_phase` is the phase string used by MotionEffect (a Move may have two visual windows that reuse the same
## set of layers, e.g. windup and post-windup).

var id := ""
var effect: MotionEffect
var phases: Array = []
var total := 0.0


func add_phase(phase_id: String, start: float, end: float, draw_phase := "") -> void:
	var e := maxf(end, start)
	phases.append({"id": phase_id, "start": start, "end": e, "draw_phase": draw_phase if draw_phase != "" else phase_id})
	total = maxf(total, e)


func active_phases(t: float) -> Array:
	var out: Array = []
	for ph in phases:
		if t >= float(ph["start"]) and t <= float(ph["end"]):
			out.append(ph)
	return out


## Draws every phase whose window contains `t`. Each phase gets its own local clock and `k`, so two overlapping
## phases (windup + release) never share a progress value. `geo` carries the real positions of the current frame.
func draw(painter: MotionPainter, t: float, geo: Dictionary) -> void:
	if effect == null:
		return
	for ph in active_phases(t):
		var local := t - float(ph["start"])
		var g := geo.duplicate()
		g["k"] = clampf(local / maxf(float(ph["end"]) - float(ph["start"]), 0.001), 0.0, 1.0)
		g["phase_t"] = local
		effect.draw(painter, String(ph["draw_phase"]), local, g)
