class_name BattleFx
extends Node3D
## Battle visuals combining 3D curved slash/shock/ribbon meshes, 16-frame animated
## flipbook sprite sheets, screen-space impact post-processing, and weight/hit-stop
## choreography (zero camera shake).

const COLORS := {
	Element.Type.FISICO: Color(0.95, 0.95, 0.95),
	Element.Type.FOGO: Color(1.0, 0.45, 0.1),
	Element.Type.AGUA_GELO: Color(0.4, 0.8, 1.0),
	Element.Type.RAIO: Color(1.0, 0.95, 0.2),
	Element.Type.PSIQUICO: Color(0.9, 0.3, 0.9),
	Element.Type.VENENO: Color(0.5, 0.9, 0.2),
	Element.Type.SOM: Color(0.3, 1.0, 0.8),
	Element.Type.TERRA: Color(0.6, 0.4, 0.2),
	Element.Type.VENTO: Color(0.7, 1.0, 0.8),
	Element.Type.LUZ: Color(1.0, 1.0, 0.7),
	Element.Type.TREVAS: Color(0.4, 0.15, 0.55),
}
const STEP_DIST := 1.5  ## World units per position step (kept short: the party stands near the camera).
const FLY_TIME := 0.25
const TELEGRAPH_COLOR := Color(1.0, 0.22, 0.18)
const ALLY_COLOR := Color(0.3, 0.78, 1.0)
const DODGE_COLOR := Color(0.5, 0.9, 1.0)
const GOLD := Color(1.0, 0.82, 0.15)
const RUN_SPEED := 55.0  ## Units per second while running at a target.
const STAND_GAP := 2.6  ## Where a melee attacker stops, in front of its target.
const ANTICIP_T := 0.08  ## Brief crouch/pull-back anticipation before melee swing.
const HIT_AT := 0.45  ## Seconds into the attack clip when the strike lands.
const ATTACK_HOLD := 0.6  ## Time spent finishing the attack clip after the strike.
const READY_STEP := 0.9  ## How far a character steps forward while it can act.
const CAST_AT := 0.5  ## Seconds into a cast when the effect leaves the caster.


var cam: BattleCamera  ## Set by the battle scene; frames each attack.
var leader: Combatant  ## The player's character: the camera only follows actions involving it.
var battle: Battle  ## Set by the battle scene; drives the ready stance.

var _models: Dictionary = {}  ## Combatant -> Node3D
var _home: Dictionary = {}  ## Combatant -> Vector3
var _home_yaw: Dictionary = {}  ## Combatant -> float
var _tweens: Dictionary = {}  ## Combatant -> Tween (movement)
var _hit_at: Dictionary = {}  ## attacker -> seconds until its strike lands
var _slot: Dictionary = {}  ## Combatant -> Vector3 (spawn spot; wandering stays near it)
var _busy_until: Dictionary = {}  ## Combatant -> msec; no wandering before that
var _ready_off: Dictionary = {}  ## Combatant -> Vector3 (ready-stance offset from home)
var _base_speed: Dictionary = {}  ## Combatant -> idle animation speed
var _phase: Dictionary = {}  ## Combatant -> float (breathing phase)
var _origin: Dictionary = {}  ## Combatant -> Vector3: its spot at position step 0
var _stepping: Dictionary = {}  ## Combatant -> bool: walking a step
var _rest: Dictionary = {}  ## Combatant -> Vector3: where it stands while it is not at home (engaged / stunned)
var _base_scale: Dictionary = {}  ## Combatant -> Vector3 (as registered; enemies are scaled up)
var _displaced: Dictionary = {}  ## Combatant -> bool (standing off its home after a dodge)

## Modules (one file per responsibility, see scripts/combat/fx/):
var fx_telegraph: FxTelegraph
var fx_motion: FxMotion
var fx_dodge: FxDodge
var fx_impacts: FxImpacts
var fx_projectiles: FxProjectiles
var fx_text: FxText


func _init() -> void:
	fx_telegraph = FxTelegraph.new(self)
	fx_motion = FxMotion.new(self)
	fx_dodge = FxDodge.new(self)
	fx_impacts = FxImpacts.new(self)
	fx_projectiles = FxProjectiles.new(self)
	fx_text = FxText.new(self)


func register(c: Combatant, model: Node3D) -> void:
	_models[c] = model
	_home[c] = model.position
	_origin[c] = model.position
	_home_yaw[c] = model.rotation.y
	_base_scale[c] = model.scale
	_slot[c] = model.position
	_phase[c] = randf() * TAU
	var ap := _anim_player(c)
	if ap != null:
		_base_speed[c] = randf_range(0.92, 1.08)  # Keep the idle breathing out of sync.
		ap.speed_scale = _base_speed[c]
	_add_ready_ring(model)


# --- Battle events ---------------------------------------------------------


## info keys: evaded, dmg, weak, crit, gain, whiffed, power.
func play_hit(attacker: Combatant, target: Combatant, element: Element.Type, info: Dictionary) -> void:
	var color: Color = COLORS[element]
	var a_home: Vector3 = rest_pos(attacker)
	var t_home: Vector3 = rest_pos(target)
	var to := t_home + Vector3(0, 1, 0)
	var evaded: bool = info["evaded"]
	# Called at the moment the strike lands (Battle waits for the animation).
	if evaded:
		_dodge_later(target, "ESQUIVOU! +1 ATB", 0.0, 0.3 if _has_projectile(element) else 0.35)
		return
	var weak: bool = info["weak"]
	var crit: bool = info["crit"]
	var power: float = info.get("power", 1.0)
	var heavy := weak or crit or power >= 1.4
	var strike_dir := _flat_dir(a_home, t_home)
	if heavy and cam != null and (attacker == leader or target == leader):
		cam.speed_lines()
	var impact_fx := _impact(element, to, color, heavy, strike_dir)
	flash(target)
	# Screen-space post-processing (chromatic aberration, radial blur, elemental tint) — ZERO camera shake
	if cam != null:
		cam.impact_post(to, color, heavy)
	# Micro-freeze (Hit Stop) with high-frequency vibration strictly on the target and impact effect
	await _hit_stop(attacker, target, heavy, strike_dir, impact_fx)
	var knock_mult := (1.55 if (weak or crit) else 1.0) * clampf(power, 0.85, 1.6)
	knock(target, a_home, knock_mult)
	_hit_react(target)
	var text := str(info["dmg"])
	var text_color := Color.WHITE
	var size := 56
	if crit:
		text = "CRÍTICO! " + text
		text_color = Color(1.0, 0.9, 0.2)
		size = 84
	if weak:
		text_color = Color(1.0, 0.5, 0.15)
		size += 12
		float_text(to + Vector3(0, 2.1, 0), "FRAQUEZA!", Color(1.0, 0.5, 0.15), 48)
	float_text(to + Vector3(0, 1.2, 0), text, text_color, size)


## Where the character stands now when it is not moving: its home, or the spot an
## Evade left it at (the evader next to its opponent, the stunned attacker where it stopped).
func rest_pos(c: Combatant) -> Vector3:
	return _rest.get(c, _home[c])


func _busy_for(c: Combatant, seconds: float) -> void:
	_busy_until[c] = maxi(_busy_until.get(c, 0), Time.get_ticks_msec() + int(seconds * 1000.0))


## Idle characters breathe (a slight sway) and step forward with a pulsing floor
## ring while they can act. Movement therefore always means something.
func _process(delta: float) -> void:
	fx_motion.drive()
	# Position steps: the home spot is the step-0 spot moved along the facing axis by
	# the logic's own (animated) step value; the run clip plays while it walks.
	for c in _models:
		var yaw0: float = _home_yaw[c]
		_home[c] = (_origin[c] as Vector3) + Vector3(sin(yaw0), 0.0, cos(yaw0)) * (STEP_DIST * c.visual_step())
		var walking: bool = c.step_t < 1.0
		if walking and not _stepping.get(c, false):
			_stepping[c] = true
			_play(c, "run")
		elif not walking and _stepping.get(c, false):
			_stepping[c] = false
			_reset_idle(c)
	var t := Time.get_ticks_msec() / 1000.0
	for c in _models:
		var m: Node3D = _models[c]
		if not _is_idle(c):
			_ready_off[c] = m.position - (_home[c] as Vector3)
			continue
		var yaw: float = _home_yaw[c]
		var ready: bool = battle != null and battle.running and c.can_pay(Battle.SKILL_BLOCKS) and not battle.is_winding_up(c)
		var want := Vector3(sin(yaw), 0.0, cos(yaw)) * READY_STEP if ready else Vector3.ZERO
		var off: Vector3 = (_ready_off.get(c, Vector3.ZERO) as Vector3).lerp(want, 1.0 - exp(-6.0 * delta))
		_ready_off[c] = off
		m.position = (_home[c] as Vector3) + off
		m.rotation.y = yaw + sin(t * 0.9 + float(_phase.get(c, 0.0))) * 0.04
		var ring: Node3D = m.get_node_or_null("ReadyRing")
		if ring != null:
			ring.visible = ready
			var pulse := 1.0 + 0.12 * sin(t * 6.0)
			ring.scale = Vector3(pulse, 1.0, pulse)


func _is_idle(c: Combatant) -> bool:
	var m: Node3D = _models[c]
	if not c.is_alive() or not m.visible or _displaced.get(c, false) or fx_motion.is_driven(c):
		return false
	if Time.get_ticks_msec() < _busy_until.get(c, 0):
		return false
	var tw: Tween = _tweens.get(c)
	return tw == null or not tw.is_valid()


func _cam_pos() -> Vector3:
	if cam != null and cam.camera != null:
		return cam.camera.global_position
	return Vector3(0, 3, 8)


func _face_camera(node: Node3D) -> void:
	node.look_at(_cam_pos())


func flash(target: Combatant) -> void:
	var m: Node3D = _models[target]
	var mat := VfxLib.ensure_flash(m)
	mat.set_shader_parameter("amount", 1.0)
	create_tween().tween_method(func(v: float) -> void: mat.set_shader_parameter("amount", v), 1.0, 0.0, 0.3)


func _move(c: Combatant) -> Tween:
	if _tweens.has(c) and (_tweens[c] as Tween).is_valid():
		(_tweens[c] as Tween).kill()
	var tw := create_tween()
	_tweens[c] = tw
	return tw


func _flat_dir(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.RIGHT


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _node(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = _mat(color)
	n.position = pos
	add_child(n)
	return n


func _sphere(radius: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 10
	return c


func _cone(radius: float, height: float) -> CylinderMesh:
	var c := _cyl(radius, height)
	c.top_radius = 0.0
	return c


## Scales `node` from s0 to s1 while fading it out, then frees it.
func _pop(node: MeshInstance3D, time: float, s0: Vector3, s1: Vector3) -> void:
	node.scale = s0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(node, "scale", s1, time)
	tw.tween_property(node.material_override, "albedo_color:a", 0.0, time * 0.6).set_delay(time * 0.4)
	tw.chain().tween_callback(node.queue_free)


func _ring(pos: Vector3, color: Color, s0: Vector3, s1: Vector3, time: float, rot := Vector3.ZERO, delay := 0.0, free_after := true) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.85
	mesh.outer_radius = 1.0
	mesh.rings = 24
	mesh.ring_segments = 8
	var node := _node(mesh, color, pos)
	node.rotation_degrees = rot
	node.scale = s0
	var tw := create_tween().set_parallel(true)
	if delay > 0.0:
		node.visible = false
		tw.tween_callback(func() -> void: node.visible = true).set_delay(delay)
	tw.tween_property(node, "scale", s1, time).set_delay(delay)
	if free_after:
		tw.tween_property(node.material_override, "albedo_color:a", 0.0, time * 0.5).set_delay(delay + time * 0.5)
		tw.chain().tween_callback(node.queue_free)
	return node


func _line(a: Vector3, b: Vector3, color: Color, thick: float) -> MeshInstance3D:
	var node := _node(_box(Vector3(thick, thick, a.distance_to(b))), color, (a + b) * 0.5)
	var up := Vector3.RIGHT if absf((b - a).normalized().dot(Vector3.UP)) > 0.99 else Vector3.UP
	node.look_at(b, up)
	return node


# --- Forwarders to the modules ---------------------------------------------

func telegraph(inc) -> void:
	fx_telegraph.telegraph(inc)


func clear_telegraph(inc) -> void:
	fx_telegraph.clear_telegraph(inc)


func resolve_attack(inc) -> void:
	fx_telegraph.resolve_attack(inc)


func manual_evade(actor: Combatant, inc) -> void:
	fx_dodge.manual_evade(actor, inc)


func evade_whiff(actor: Combatant, _inc) -> void:
	fx_dodge.evade_whiff(actor, _inc)


func heal_fx(_actor: Combatant, target: Combatant, amount: int) -> void:
	fx_text.heal_fx(_actor, target, amount)


func _add_ready_ring(model: Node3D) -> void:
	fx_motion._add_ready_ring(model)


func _stop_moving(c: Combatant) -> void:
	fx_motion._stop_moving(c)


func _rebase(c: Combatant) -> void:
	fx_motion._rebase(c)


func intro() -> void:
	await fx_motion.intro()


func finish(player_won: bool) -> void:
	fx_motion.finish(player_won)


func _clip_hit(c: Combatant, anim: String, fallback: float) -> float:
	return fx_motion._clip_hit(c, anim, fallback)


func _hit_stop(attacker: Combatant, target: Combatant, heavy: bool, strike_dir := Vector3.FORWARD, impact_fx: Array[Node3D] = []) -> void:
	await fx_motion._hit_stop(attacker, target, heavy, strike_dir, impact_fx)


func dodge(target: Combatant, _text: String, hold := false) -> void:
	fx_dodge.dodge(target, _text, hold)


func _hit_react(c: Combatant) -> void:
	await fx_motion._hit_react(c)


func _play(c: Combatant, anim: String) -> void:
	fx_motion._play(c, anim)


func _anim_player(c: Combatant) -> AnimationPlayer:
	return fx_motion._anim_player(c)


func _reset_idle(c: Combatant) -> void:
	fx_motion._reset_idle(c)


func knock(target: Combatant, from_pos: Vector3, mult := 1.0) -> void:
	fx_motion.knock(target, from_pos, mult)


func float_text(pos: Vector3, text: String, color: Color, size := 48) -> void:
	fx_text.float_text(pos, text, color, size)


func _shock(ground: Vector3, color: Color, size: float, duration := 0.55) -> void:
	fx_impacts._shock(ground, color, size, duration)


func _glow(pos: Vector3, color: Color, amount: int, size: Vector2, life: float, speed: Vector2, gravity := Vector3.ZERO, end_scale := 0.0, radius := 0.0) -> void:
	fx_impacts._glow(pos, color, amount, size, life, speed, gravity, end_scale, radius)


func _smoke(pos: Vector3, color: Color, amount: int, size: Vector2, life: float, rise := 1.5, additive := false) -> void:
	fx_impacts._smoke(pos, color, amount, size, life, rise, additive)


func _impact(element: Element.Type, pos: Vector3, color: Color, big: bool, dir := Vector3.FORWARD) -> Array[Node3D]:
	return fx_impacts._impact(element, pos, color, big, dir)


func _burst(pos: Vector3, color: Color, amount: int, speed: float, gravity: Vector3, size: float, lifetime: float) -> void:
	fx_impacts._burst(pos, color, amount, speed, gravity, size, lifetime)


func _has_projectile(element: Element.Type) -> bool:
	return fx_projectiles._has_projectile(element)


func _dodge_later(target: Combatant, text: String, delay: float, hold_time: float) -> void:
	await fx_dodge._dodge_later(target, text, delay, hold_time)


func settle(target: Combatant) -> void:
	fx_dodge.settle(target)


func miss_text(pos: Vector3) -> void:
	fx_dodge.miss_text(pos)


## The modules point back at this node; cut the cycle so everything can be freed.
func _exit_tree() -> void:
	for mod in [fx_telegraph, fx_motion, fx_dodge, fx_impacts, fx_projectiles, fx_text]:
		mod.fx = null


func on_phase(inc, phase: int) -> void:
	fx_motion.on_phase(inc, phase)


func on_cue(kind: String, actor: Combatant, inc) -> void:
	fx_dodge.on_cue(kind, actor, inc)


func on_engaged(actor: Combatant, opponent: Combatant, _inc) -> void:
	fx_dodge.engage_arrive(actor, opponent)


func on_engage_ended(actor: Combatant, opponent: Combatant, ghost, staggered) -> void:
	fx_motion.on_engage_ended(actor, opponent, ghost, staggered)
