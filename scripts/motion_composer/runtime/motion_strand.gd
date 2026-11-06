class_name MotionStrand
extends RefCounted
## D-308: the Motion Composer's runtime bridge to the game. A composition is pure data (samples along +Z); this
## places it in the world between two points and hands back ready-to-draw points, so a move's VFX can be BUILT
## ON the composer instead of beside it:
##   var strand := MotionStrand.new(MotionPresets.fire_body(seed), from, to)
##   var line := strand.points(time, u0, u1, 24)   # {points, widths, opacity} in world space
## The time comes from outside (the move's phase: wind-up, release, travel, impact), never from a clock here.
## It only shapes a line; damage, range and duration stay with the combat rules (D-019).

static var _catalog: MotionCatalog

var comp: MotionComposition
var frame := Transform3D.IDENTITY  ## strand space (+Z along the path) -> world
var length := 1.0


static func catalog() -> MotionCatalog:
	if _catalog == null:
		_catalog = MotionCatalog.new()
		MotionBehaviors.register_all(_catalog)
		MotionBehaviors.register_v12(_catalog)
	return _catalog


func _init(p_comp: MotionComposition, from: Vector3, to: Vector3) -> void:
	comp = p_comp
	retarget(from, to)


## Moves the strand to new end points (the target may be running): the shape stays, only the frame changes.
func retarget(from: Vector3, to: Vector3) -> void:
	var delta := to - from
	length = maxf(delta.length(), 0.1)
	var z := delta / length
	var up := Vector3.UP if absf(z.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	frame = Transform3D(Basis(x, y, z), from)
	comp.base_length = length
	comp.touch()


## Evaluates the composition at `time` and returns the part between u0 and u1 resampled to `count` points:
## {points: PackedVector3Array (world), widths: PackedFloat32Array (sample width), opacity: PackedFloat32Array}.
func points(time: float, u0: float, u1: float, count: int) -> Dictionary:
	var res := comp.evaluate(catalog(), comp.make_context(time))
	var pts := PackedVector3Array()
	var ws := PackedFloat32Array()
	var ops := PackedFloat32Array()
	if res.has_errors() or res.samples.size() < 2:
		return {"points": pts, "widths": ws, "opacity": ops, "errors": res.diagnostics.size()}
	var n := res.samples.size()
	for k in count:
		var u := lerpf(u0, u1, float(k) / float(maxi(count - 1, 1)))
		var f := clampf(u, 0.0, 1.0) * float(n - 1)
		var i := mini(int(f), n - 2)
		var a: MotionSample = res.samples[i]
		var b: MotionSample = res.samples[i + 1]
		var w := f - float(i)
		pts.append(frame * a.position.lerp(b.position, w))
		ws.append(lerpf(a.width, b.width, w))
		ops.append(lerpf(a.opacity, b.opacity, w))
	return {"points": pts, "widths": ws, "opacity": ops, "errors": 0}
