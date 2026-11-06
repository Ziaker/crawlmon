class_name ElementEffect
extends Node3D
## D-274: base of the element effects (fire, water, earth, air). An effect is built from a CONTEXT, never from a
## character, a team or a side (D-235):
##   ctx.parent       where to add it (the effect adds itself)
##   ctx.origin       where it is born (attacker side, world position)
##   ctx.dest         where it goes (target centre, world position)
##   ctx.target_height / ctx.target_radius   size of the target; scales the whole effect
##   ctx.seed         every random choice comes from this seed, so the same seed gives the same effect
## It is driven by an EXPLICIT time: `set_time(t)` (scrub, pause, slow motion, A/B) or autoplay. It only draws:
## damage, range and duration of an attack are never decided here (D-019).

signal finished

var duration := 1.5  ## Seconds until nothing is left on screen.
var t := 0.0
var autoplay := true
var free_when_done := true

var origin := Vector3.ZERO
var dest := Vector3.ZERO
var dir := Vector3.FORWARD  ## Unit, origin -> dest, flattened is `flat_dir`.
var flat_dir := Vector3.FORWARD
var right := Vector3.RIGHT  ## Unit, horizontal, perpendicular to flat_dir.
var dist := 1.0
var unit := 1.0  ## Size unit from the target (about its height), clamped.
var ground_y := 0.0
var rng := RandomNumberGenerator.new()
var seed_value := 1

var _done := false


## Builds and adds the effect. Subclasses implement _build().
func setup(ctx: Dictionary) -> ElementEffect:
	var parent: Node = ctx["parent"]
	origin = ctx["origin"]
	dest = ctx["dest"]
	var delta := dest - origin
	dist = maxf(delta.length(), 0.5)
	dir = delta / dist
	flat_dir = Vector3(delta.x, 0.0, delta.z)
	flat_dir = flat_dir.normalized() if flat_dir.length() > 0.001 else Vector3.FORWARD
	right = flat_dir.cross(Vector3.UP).normalized()
	unit = clampf(float(ctx.get("target_height", 1.4)), 0.8, 2.4)
	ground_y = float(ctx.get("ground_y", 0.0))
	seed_value = int(ctx.get("seed", 1))
	rng.seed = seed_value
	parent.add_child(self)
	_build()
	set_time(0.0)
	return self


func set_time(value: float) -> void:
	t = value
	_apply(t)
	if t >= duration and not _done:
		_done = true
		finished.emit()
		if free_when_done and autoplay:
			queue_free()


func _process(delta: float) -> void:
	if autoplay and not _done:
		set_time(t + delta)


func _build() -> void:
	pass


func _apply(_time: float) -> void:
	pass


# --- Helpers for the effects -------------------------------------------------

func _ribbon(shader_name: String, params: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mat := VfxLib.shader_mat(shader_name, params)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _particles(additive: bool, kind: int, energy := 1.0) -> ElementParticles:
	var p := ElementParticles.new()
	var mat := VfxLib.shader_mat("el_particle_add" if additive else "el_particle", {"kind": kind, "energy": energy})
	add_child(p)
	p.set_meta("material", mat)
	return p


func _finish_particles(p: ElementParticles) -> void:
	p.build(ElementParticles.quad(), p.get_meta("material") as Material)


## Smooth 0..1 ease used for travel (fast start, soft arrival).
static func ease_out(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return 1.0 - (1.0 - c) * (1.0 - c)


static func smooth(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)
