class_name MotionEffect
extends RefCounted
## D-308: a complete VFX built on the Motion Composer: a set of LAYERS, each one a composition (pure motion data)
## plus the representations that paint it, grouped by the four phases of a Move: windup, release, travel, impact.
## The game gives it an explicit time per phase and the real positions (origin, destination, head); it returns
## nothing: it paints through a MotionPainter. It never decides damage, range or duration (D-019, D-235).
##
## A layer: { phase, comp, reps, frame, back, length, window, slide, follow_until, start }
##   frame         "origin" | "head" | "dest": where the layer's local frame (+Z = axis) sits
##   back          true: the axis points backward (a strand trailing behind the head)
##   length        base length of the composition in meters (number) or "dest" (origin -> dest distance)
##   window        Vector2(u0, u1): which part of the strand is shown
##   slide         Vector2: the window's start moves from window.x to slide.y over `follow_until` seconds
##   follow_until  the frame follows the head until this local time, then stays where it was
##   start         the layer starts at this phase time (relative)
##   trail         true: the strand trails BEHIND the head (u = 0 at the head, u = 1 `length` metres back); only the part already travelled is shown
##   trail_dt      seconds back in time: every item also gets `prev` = where the same sample was `trail_dt` ago (a motion streak, spec M19 by re-evaluation)
##   z_offset      meters along the axis (x scale) added to the frame origin (center a helix on the ball)
##   scalable      false: the frame is not scaled (a strand between two points keeps its real length)
##   until_landed  the layer stops being drawn once the shot has landed (geo.landed)
##   local_offset  Vector3 (meters, in the layer frame): shifts the layer (two hands side by side)
##   side_start/arc_rel/arc_up  frame "head" only: a curved shot (lateral start offset, bow x distance, rise)
##   ground        true: the frame sits on the floor (y = 0) under the anchor (a pillar of fire)
##   dir           "axis" (default) | "up": the local +Z follows the shot axis or points straight up (fire rises)
## V1.6 (D-332) -- a layer can be a LIFE CYCLE of many different compositions (every flame is its own composition):
##   factory       Callable(cycle:int) -> MotionComposition: builds the composition of that cycle (own seed, own behavior parameters)
##   loop          seconds of one cycle; the layer repeats it (a new composition every cycle, so no two flames are alike)
##   cycle_phase   0..1: where in the cycle this layer starts (de-synchronizes flames)
##   once          true: only the first cycle (an impact does not repeat)
##   offset_fn     Callable(cycle) -> Vector3: local offset of this cycle's strand (meters, in the layer frame)
##   rot_fn        Callable(cycle) -> Basis: local rotation of this cycle's strand (tilts a flame)
##   length        "keep": do not overwrite comp.base_length (the factory sets each flame's own height)

var layers: Array = []
var _frozen: Dictionary = {}  ## layer index -> Transform3D
var _cycles: Dictionary = {}  ## layer index * 100000 + cycle -> MotionComposition (factory layers)
var _last_items: Dictionary = {}


func add(phase: String, comp: MotionComposition, reps: Array, opts := {}) -> void:
	var l := {"phase": phase, "comp": comp, "reps": reps, "frame": "origin", "back": false, "length": 1.0, "window": Vector2(0.0, 1.0),
		"slide": Vector2(-1.0, -1.0), "follow_until": -1.0, "start": 0.0}
	for k in opts.keys():
		l[k] = opts[k]
	layers.append(l)


## Paints every layer of `phase` at phase time `t`. geo: {origin, dest, head, axis, k, p}. `t` is the phase's own clock.
func draw(painter: MotionPainter, phase: String, t: float, geo: Dictionary) -> void:
	for i in layers.size():
		var l: Dictionary = layers[i]
		if l["phase"] != phase:
			continue
		var lt := t - float(l["start"])
		var comp: MotionComposition = l["comp"]
		var cyc_off := Vector3.ZERO
		var cyc_rot := Basis.IDENTITY
		var cseed := 0.0
		if l.has("factory"):  # life cycle: a different composition every cycle (V1.6)
			var loop := maxf(float(l["loop"]), 0.05)
			var raw := lt + float(l.get("cycle_phase", 0.0)) * loop
			if raw < 0.0:
				continue
			var cyc := int(floor(raw / loop))
			if bool(l.get("once", false)) and cyc > 0:
				continue
			lt = raw - float(cyc) * loop
			cseed = float((i * 131 + cyc * 17) % 997) * 0.37
			var key := i * 100000 + cyc
			if not _cycles.has(key):
				if _cycles.size() > 96:
					_cycles.clear()
				_cycles[key] = (l["factory"] as Callable).call(cyc)
			comp = _cycles[key]
			if l.has("offset_fn"):
				cyc_off = (l["offset_fn"] as Callable).call(cyc)
			if l.has("rot_fn"):
				cyc_rot = (l["rot_fn"] as Callable).call(cyc)
		elif lt < 0.0:
			continue
		if bool(l.get("until_landed", false)) and bool(geo.get("landed", false)):
			continue  # the body and the head end with the shot; the vortices and the like keep dissolving
		var axis: Vector3 = geo["axis"]
		var dest: Vector3 = geo["dest"]
		var origin: Vector3 = geo["origin"]
		var anchor: Vector3 = origin
		match str(l["frame"]):
			"head":
				anchor = geo["head"]
				if l.has("side_start") or l.has("arc_rel") or l.has("arc_up"):
					# V1.7: the head of a curved shot (an arc to each side, converging on the target): lateral offset = from the hand at p=0 to 0 at p=1,
					# plus a bow of `arc_rel` x distance and a rise of `arc_up` at the middle of the flight (the quadratic curves of the atelier)
					var hp := clampf(float(geo.get("p", 0.0)), 0.0, 1.0)
					var sd := axis.cross(Vector3.UP)
					sd = sd.normalized() if sd.length() > 0.01 else Vector3.RIGHT
					var dist_o := origin.distance_to(dest)
					var lat := float(l.get("side_start", 0.0)) * (1.0 - hp) + float(l.get("arc_rel", 0.0)) * dist_o * sin(PI * hp)
					anchor = origin.lerp(dest, hp) + sd * lat + Vector3.UP * float(l.get("arc_up", 0.0)) * sin(PI * hp)
			"dest": anchor = dest
		var z := -axis if bool(l["back"]) else axis
		if str(l.get("dir", "axis")) == "up":
			z = Vector3.UP
		var sc := float(geo.get("scale", 1.0))
		anchor += z * float(l.get("z_offset", 0.0)) * sc
		if bool(l.get("ground", false)):
			anchor.y = 0.0
		var frame := _frame(anchor, z)
		if l.has("world_anchor"):  # D-337: a layer pinned to a real world point (one heal circle per ally), not a character
			frame.origin = l["world_anchor"]
		frame.origin += frame.basis * (cyc_off + Vector3(l.get("local_offset", Vector3.ZERO))) * sc
		frame.basis = frame.basis * cyc_rot
		if bool(l.get("scalable", true)):  # bursts, vortices and heads grow with the camera distance; a strand keeps its real length
			frame.basis = frame.basis.scaled(Vector3.ONE * sc)
		var follow := float(l["follow_until"])
		if follow >= 0.0:
			if lt < follow:
				_frozen[i] = frame
			elif _frozen.has(i):
				frame = _frozen[i]
		var length: float = origin.distance_to(dest) if str(l["length"]) == "dest" else (comp.base_length if str(l["length"]) == "keep" else float(l["length"]))
		if str(l["length"]) != "keep":
			comp.base_length = maxf(length, 0.01)
		var res := comp.evaluate(MotionStrand.catalog(), comp.make_context(lt))
		if res.has_errors() or res.samples.is_empty():
			continue
		var w: Vector2 = l["window"]
		var slide: Vector2 = l["slide"]
		if slide.y >= 0.0 and follow > 0.0:
			var f := clampf(lt / follow, 0.0, 1.0)
			var width_u := w.y - w.x
			w.x = lerpf(w.x, slide.y, f)
			w.y = w.x + width_u
		if bool(l.get("trail", false)):
			var travelled := origin.distance_to(dest) * clampf(float(geo.get("p", 0.0)), 0.0, 1.0)
			w = Vector2(0.0, clampf(travelled / maxf(length, 0.01), 0.02, 1.0))
		if l.has("head_window"):  # the visible part of the strand is the stretch of `head_window` meters behind the head
			var dist := maxf(origin.distance_to(dest), 0.5)
			var pp := clampf(float(geo.get("p", 0.0)), 0.0, 1.0)
			w = Vector2(clampf(pp - float(l["head_window"]) / dist, 0.0, 1.0), pp)
		var items: Array = []
		var prev_res: MotionResult = null
		var tdt := float(l.get("trail_dt", 0.0))
		if tdt > 0.0:  # where each sample was `tdt` seconds ago: a motion streak by re-evaluation (the composition is deterministic)
			prev_res = comp.evaluate(MotionStrand.catalog(), comp.make_context(maxf(lt - tdt, 0.0)))
		for si in res.samples.size():
			var s: MotionSample = res.samples[si]
			if not s.visible or s.u < w.x or s.u > w.y:
				continue
			var ws: float = (s.u - w.x) / maxf(w.y - w.x, 0.0001)
			var item := {"pos": frame * s.position, "tan": (frame.basis * s.basis).z, "u": ws, "width": s.width, "opacity": s.opacity,
				"intensity": s.intensity, "id": s.element_id, "branch": s.branch, "cseed": cseed, "lt": lt}
			if prev_res != null and si < prev_res.samples.size():
				item["prev"] = frame * (prev_res.samples[si] as MotionSample).position
			items.append(item)
		for rep in l["reps"]:
			(rep as MotionRep).draw(painter, items, frame.origin, float(geo.get("k", 0.0)), sc)


static func _frame(origin: Vector3, z_axis: Vector3) -> Transform3D:
	var z := z_axis.normalized()
	var up := Vector3.UP if absf(z.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	return Transform3D(Basis(x, y, z), origin)
