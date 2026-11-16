class_name FxMartialHand
extends Node3D
## White holo hand shared by Karate Chop and Brick Break (D-1209).
## Decorative only: it never decides a hit (D-1040/D-019) and there is no clock of its own —
## the caller poses it and sets the look every frame. Nothing here is per character or per
## side (D-235): everything comes from pos/fingers/cut_dir handed in by the caller.

const HAND_PATH := "res://assets/vfx/martial_hand.glb"  ## open flat knife-hand (made in Blender, D-1209); the Fire Bullet hand is a pointing hand
const SHADER_PATH := "res://shaders/holo_hand.gdshader"
const OUTLINE_SHADER_PATH := "res://shaders/holo_hand_outline.gdshader"  ## inverted hull ink line (D-1209)
const MAX_GHOSTS := 4

## Hand length in world metres; the caller derives it from the real body.
var unit := 1.0

static var _mesh_cache: Mesh = null
static var _shader_cache: Shader = null
static var _outline_shader_cache: Shader = null

var _mi: MeshInstance3D = null
var _mat: ShaderMaterial = null
var _outline_mat: ShaderMaterial = null
var _ghosts: Array[MeshInstance3D] = []
var _squash_z := 1.0
var _grow := 1.0
var _dead := false
var _form := 0.0  ## D-1218: last look handed to `set_look`, mirrored only for the telemetry
var _dissolve := 0.0
var _fade := 0.0


static func create(parent: Node, unit: float) -> FxMartialHand:
	var h := FxMartialHand.new()
	h.name = "FxMartialHand"
	h.unit = maxf(unit, 0.001)
	if parent != null:
		parent.add_child(h)
	h._ensure()
	return h


func _ready() -> void:
	_ensure()


## Orthonormal basis: mesh +Y = fingers, mesh +Z = back of the hand, +X = little-finger side.
## Robust to near-parallel inputs (the hint is re-orthogonalised, with any-perpendicular fallback).
static func _basis(fingers: Vector3, back: Vector3) -> Basis:
	var f := fingers.normalized()
	if f.length_squared() < 0.5:
		f = Vector3.UP
	var z := back - f * back.dot(f)
	if z.length_squared() < 1e-6:
		z = _any_perp(f)
	z = z.normalized()
	return Basis(f.cross(z), f, z)


static func _any_perp(v: Vector3) -> Vector3:
	var pick := Vector3.RIGHT if absf(v.x) < 0.9 else Vector3.UP
	return v.cross(pick).normalized()


func _ensure() -> void:
	if _dead or _mi != null:
		return
	if _mesh_cache == null:
		var scene := load(HAND_PATH) as PackedScene
		if scene == null:
			return
		var inst := scene.instantiate()
		for m in inst.find_children("*", "MeshInstance3D", true, false):
			_mesh_cache = (m as MeshInstance3D).mesh
			break
		inst.free()
	if _shader_cache == null:
		_shader_cache = load(SHADER_PATH) as Shader
	if _outline_shader_cache == null:
		_outline_shader_cache = load(OUTLINE_SHADER_PATH) as Shader
	if _mesh_cache == null or _shader_cache == null or _outline_shader_cache == null:
		return
	_mat = ShaderMaterial.new()
	_mat.shader = _shader_cache
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = _outline_shader_cache
	_mat.next_pass = _outline_mat  # inverted hull: ink line round every finger and the palm
	_mi = MeshInstance3D.new()
	_mi.name = "Holo"
	_mi.mesh = _mesh_cache
	_mi.material_override = _mat
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)
	_apply_scale()


func _apply_scale(widen := 1.0) -> void:
	if _mi == null:
		return
	var sc := unit * widen * _grow
	_mi.scale = Vector3(sc, sc, unit * _squash_z * _grow)


## Extra overall size on top of `unit` (>= 0.01); `set_look` and the poses never reset it.
func set_grow(g: float) -> void:
	_grow = maxf(g, 0.01)
	_ensure()
	_apply_scale(1.0 / sqrt(_squash_z))


func _place(pos: Vector3, b: Basis) -> void:
	transform = Transform3D(b, pos)


## Fingers point to `fingers`; the blade (little-finger side) leads along `cut_dir`.
## The palm plane contains fingers and cut_dir, so palm_normal = fingers x cut_dir.
func pose_knife(pos: Vector3, fingers: Vector3, cut_dir: Vector3) -> void:
	_ensure()
	if _dead:
		return
	var f := fingers.normalized()
	if f.length_squared() < 0.5:
		f = Vector3.UP
	var cut := cut_dir - f * cut_dir.dot(f)
	if cut.length_squared() < 1e-6:
		cut = _any_perp(f)
	cut = cut.normalized()
	var palm_normal := f.cross(cut).normalized()
	# +X (little finger) -> cut, +Y (fingers) -> f, +Z (back of the hand) -> -palm_normal
	_place(pos, Basis(cut, f, -palm_normal))


## Fingers point to `fingers` (horizontal); the palm (mesh -Z) faces world -Y.
func pose_palm_down(pos: Vector3, fingers: Vector3) -> void:
	_ensure()
	if _dead:
		return
	var f := fingers
	f.y = 0.0
	if f.length_squared() < 1e-6:
		f = Vector3.FORWARD
	# mesh +Z is the back of the hand: pointing it to +Y puts the palm (-Z) down
	_place(pos, _basis(f.normalized(), Vector3.UP))


## Look of the frame: shader form/dissolve/fade plus the impact squash (0..1) along the
## palm normal, by non-uniform scale with the volume roughly preserved.
func set_look(form: float, dissolve: float, fade: float, squash: float = 0.0) -> void:
	_ensure()
	_form = clampf(form, 0.0, 1.0)  # D-1218: mirrored so the telemetry reads exactly what was drawn
	_dissolve = clampf(dissolve, 0.0, 1.0)
	_fade = clampf(fade, 0.0, 1.0)
	if _dead or _mat == null:
		return
	# the fill and its outline share form/dissolve/fade: the ink line lives exactly as long as the hand
	var mats: Array[ShaderMaterial] = [_mat, _outline_mat]
	for m in mats:
		if m == null:
			continue
		m.set_shader_parameter("form", _form)
		m.set_shader_parameter("dissolve", _dissolve)
		m.set_shader_parameter("fade", _fade)
	_mat.set_shader_parameter("tt", float(Time.get_ticks_msec()) * 0.001)
	_squash_z = 1.0 - 0.55 * clampf(squash, 0.0, 1.0)
	_apply_scale(1.0 / sqrt(_squash_z))


## D-1218: read-only snapshot of the mesh in world space ({} when there is no mesh).
## Telemetry only: it never poses, scales or frees anything.
func sample() -> Dictionary:
	if _dead or _mi == null or not is_instance_valid(_mi):
		return {}
	var t := global_transform  # the commanded pose (the wrist anchor), not the offset mesh child
	var e := t.basis.get_euler()
	var s := _mi.global_transform.basis.get_scale()
	return {
		"pos": [snappedf(t.origin.x, 0.001), snappedf(t.origin.y, 0.001), snappedf(t.origin.z, 0.001)],
		"rot": [snappedf(e.x, 0.001), snappedf(e.y, 0.001), snappedf(e.z, 0.001)],
		"scale": [snappedf(s.x, 0.001), snappedf(s.y, 0.001), snappedf(s.z, 0.001)],
	}


## D-1218: the look last handed to `set_look` (form, dissolve, fade).
func look() -> Dictionary:
	return {"form": _form, "dissolve": _dissolve, "fade": _fade}


## Static afterimage in the current pose. Purely decorative: the tween only fades it out.
func ghost(alpha: float, life: float) -> void:
	_ensure()
	if _dead or _mi == null:
		return
	while _ghosts.size() >= MAX_GHOSTS:
		var old: MeshInstance3D = _ghosts.pop_front()
		if is_instance_valid(old):
			old.free()
	var mat := ShaderMaterial.new()
	mat.shader = _shader_cache
	var out := ShaderMaterial.new()
	out.shader = _outline_shader_cache
	mat.next_pass = out
	for p in ["tint", "base_alpha", "rim_alpha", "rim_power", "bands", "scan", "form", "dissolve", "tt"]:
		var v: Variant = _mat.get_shader_parameter(p)
		if v != null:
			mat.set_shader_parameter(p, v)
	for p2 in ["tint", "width", "form", "dissolve"]:
		var v2: Variant = _outline_mat.get_shader_parameter(p2)
		if v2 != null:
			out.set_shader_parameter(p2, v2)
	mat.set_shader_parameter("fade", clampf(alpha, 0.0, 1.0))
	out.set_shader_parameter("fade", clampf(alpha, 0.0, 1.0))
	var g := MeshInstance3D.new()
	g.name = "HoloGhost"
	g.mesh = _mesh_cache
	g.material_override = mat
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)
	g.top_level = true  # keeps the pose frozen while the hand keeps moving
	g.global_transform = _mi.global_transform
	_ghosts.append(g)
	var tw := g.create_tween()
	tw.tween_property(mat, "shader_parameter/fade", 0.0, maxf(life, 0.01))
	tw.parallel().tween_property(out, "shader_parameter/fade", 0.0, maxf(life, 0.01))
	tw.tween_callback(_drop_ghost.bind(g))


func _drop_ghost(g: MeshInstance3D) -> void:
	_ghosts.erase(g)
	if is_instance_valid(g):
		g.queue_free()


## Releases the hand and every ghost at once (used on interruption). Safe to call any
## number of times; a freed hand stays freed and never resurrects on the next pose call.
func free_now() -> void:
	_dead = true
	for g in _ghosts.duplicate():
		if is_instance_valid(g):
			g.free()
	_ghosts.clear()
	if is_instance_valid(_mi):
		_mi.free()
	_mi = null
	_mat = null
	_outline_mat = null
