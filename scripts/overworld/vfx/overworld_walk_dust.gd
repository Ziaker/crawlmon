class_name OverworldWalkDust
extends CPUParticles3D
## D-1173: the combat run-trail dust (`fx_motion._dust_trail`) reused at the
## overworld actor's feet.
##
## Exact recipe per step (0.0917 s = 40% fewer steps/s than the combat 0.055 s,
## alternating feet by +/-0.22 m):
##   - 4 smoke puffs: `0.82, 0.78, 0.72`, size 0.275-0.575 m (50% of the
##     combat 0.55-1.15 m, creator's 2026-11-11 adjustment), rise 0.25,
##     damping 1.5, end scale 1.8, peak alpha 0.75;
##   - 3 gravel specks: additive, size 0.06-0.14 m, end scale 0, peak alpha 0.9.
##
## The node itself is an invisible ticker so the lab keeps the same `emitting`
## API and the dash can lower the alpha to 0.22 (D-1100 item 12) through
## `set_alpha_multiplier()`. Spawned particles are `top_level` so they stay in
## the world while the actor keeps walking (the combat dust does the same by
## living on the static BattleFx host).

const CADENCE := 0.091667  ## 40% fewer generations/s than the combat 0.055.
const SMOKE_COLOR := Color(0.82, 0.78, 0.72)
const SMOKE_PEAK_ALPHA := 0.75
const GRAVEL_PEAK_ALPHA := 0.9
const SIDE_OFFSET := 0.22
## D-1173: the walking trail is 50% smaller than the combat size; the dash
## start puff keeps the current full size (creator's 2026-11-11 retification)
## and is 20% larger than that (next creator adjustment).
const SMOKE_SIZE_WALK := Vector2(0.275, 0.575)
const SMOKE_SIZE_DASH := Vector2(0.55, 1.15)
const SMOKE_SIZE_DASH_START := Vector2(0.66, 1.38)

var _alpha_scale := 1.0
var _t := 0.0
var _step := 0
var _dir := Vector3.FORWARD
var _last_world := Vector3.ZERO
var _has_last := false


func _ready() -> void:
	# The ticker must not draw anything: its children carry the visible bursts.
	amount = 1
	lifetime = 0.05
	one_shot = false
	emitting = false
	local_coords = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = QuadMesh.new()
	(mesh as QuadMesh).size = Vector2(0.001, 0.001)
	var hidden := StandardMaterial3D.new()
	hidden.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hidden.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hidden.albedo_color = Color(0.0, 0.0, 0.0, 0.0)
	material_override = hidden
	visibility_aabb = AABB(Vector3(-8.0, -2.0, -8.0), Vector3(16.0, 8.0, 16.0))


func _physics_process(delta: float) -> void:
	if not emitting:
		_t = 0.0
		_has_last = false
		return
	var now := global_position
	if _has_last:
		var moved := now - _last_world
		moved.y = 0.0
		if moved.length_squared() > 0.0004:
			_dir = moved.normalized()
	_last_world = now
	_has_last = true
	_t += delta
	while _t >= CADENCE:
		_t -= CADENCE
		# The node already sits at the feet (+0.08 local); do not add it again.
		_emit_step(now)


## `peak` is the final peak alpha of the smoke puffs. The combat recipe peaks
## at 0.75; the dash passes 0.22 and the gravel follows proportionally.
func set_alpha_multiplier(peak: float) -> void:
	_alpha_scale = clampf(peak / SMOKE_PEAK_ALPHA, 0.0, 2.0)


func get_alpha_multiplier() -> float:
	return SMOKE_PEAK_ALPHA * _alpha_scale


func _emit_step(base: Vector3) -> void:
	_step += 1
	var side := -SIDE_OFFSET if (_step % 2 == 0) else SIDE_OFFSET
	var side_vec := Vector3(-_dir.z, 0.0, _dir.x)
	var foot := base + side_vec * side
	spawn_effect(self, foot, _dir, _alpha_scale, SMOKE_SIZE_WALK)


## The walking puff recipe (4 smoke + 3 gravel). `smoke_size` lets the dash
## reuse the same look at its current full size, while the walking trail uses
## the 50% size (creator's 2026-11-11 retification).
static func spawn_effect(host: Node, foot: Vector3, dir: Vector3,
		alpha_scale: float, smoke_size: Vector2) -> void:
	var smoke_alpha := clampf(SMOKE_PEAK_ALPHA * alpha_scale, 0.0, 1.0)
	var gravel_alpha := clampf(GRAVEL_PEAK_ALPHA * alpha_scale, 0.0, 1.0)
	# `fx_motion._smoke(..., amount 4, ...)` -> no flipbook (only amount >= 5
	# gets one), so the run trail is exactly these two bursts.
	var smoke := VfxLib.burst(host, foot, {
		"tex": VfxLib.smoke_tex(), "additive": false, "amount": 4, "life": 0.38,
		"speed": Vector2(0.5, 3.0), "gravity": Vector3(0.0, 0.25, 0.0),
		"size": smoke_size, "end_scale": 1.8, "damping": 1.5, "radius": 0.4,
		"ramp": VfxLib.ramp([
			Color(SMOKE_COLOR, 0.0),
			Color(SMOKE_COLOR, smoke_alpha),
			Color(SMOKE_COLOR, 0.0),
		], [0.0, 0.2, 1.0]),
	})
	_world(smoke, foot)
	var gravel := VfxLib.burst(host, foot, {
		"amount": 3, "life": 0.22, "speed": Vector2(1.2, 3.2),
		"dir": -dir + Vector3.UP * 0.3, "spread": 30.0,
		"size": Vector2(0.06, 0.14), "end_scale": 0.0,
		"ramp": VfxLib.ramp([
			Color(0.88, 0.84, 0.76, gravel_alpha),
			Color(0.70, 0.65, 0.55, 0.0),
		]),
	})
	_world(gravel, foot)


static func _world(p: CPUParticles3D, world_pos: Vector3) -> void:
	# VfxLib.burst turns emission on before it is parented. Stop it, place the
	# emitter in world space, then restart so the one-shot is born at the feet
	# instead of at the old local transform.
	p.emitting = false
	p.top_level = true
	p.local_coords = false
	p.global_position = world_pos
	p.restart()
	p.emitting = true
