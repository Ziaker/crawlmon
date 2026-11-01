class_name BattleFx
extends Node3D
## Placeholder battle visuals built only from primitives and CPU particles:
## attack telegraphs, lunges/casts, per-element impact effects, evade
## sidesteps with afterimages, floating numbers and camera shake.

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
const FLY_TIME := 0.25
const TELEGRAPH_COLOR := Color(1.0, 0.2, 0.15)
const ALLY_COLOR := Color(0.3, 0.7, 1.0)
const DODGE_COLOR := Color(0.5, 0.9, 1.0)
const GOLD := Color(1.0, 0.8, 0.1)

var cam: BattleCamera

var _models: Dictionary = {}  ## Combatant -> Node3D
var _home: Dictionary = {}  ## Combatant -> Vector3
var _tweens: Dictionary = {}  ## Combatant -> Tween (movement)
var _telegraphs: Dictionary = {}  ## Battle.Incoming -> Array[Node]


func setup(p_camera: Camera3D) -> void:
	cam = BattleCamera.new()
	add_child(cam)
	cam.setup(p_camera)


func register(c: Combatant, model: Node3D) -> void:
	_models[c] = model
	_home[c] = model.position


# --- Battle events ---------------------------------------------------------

## An enemy starts winding up: it rears back and a shrinking red ring + line
## shows who it will hit and when.
func telegraph(inc) -> void:
	var m: Node3D = _models[inc.attacker]
	var a_home: Vector3 = _home[inc.attacker]
	var t_home: Vector3 = _home[inc.target]
	var dir := _flat_dir(a_home, t_home)
	var warn := TELEGRAPH_COLOR if not inc.attacker.is_player else ALLY_COLOR
	var tw := _move(inc.attacker)
	tw.set_parallel(true)
	tw.tween_property(m, "position", a_home - dir * 0.6, 0.3)
	tw.tween_property(m, "scale", Vector3(1.15, 0.8, 1.15), 0.3)
	var ring := _ring(t_home + Vector3(0, 0.05, 0), warn, Vector3(2.6, 1, 2.6), Vector3.ONE, Battle.WINDUP, Vector3.ZERO, 0.0, false)
	var line := _line(a_home + Vector3(0, 1, 0), t_home + Vector3(0, 1, 0), Color(warn, 0.45), 0.05)
	_telegraphs[inc] = [ring, line]
	# Slow push-in: over the target's shoulder toward an enemy attacker, or
	# behind a party attacker looking down the line at its target.
	var perp := _perp(dir)
	if inc.attacker.is_player:
		cam.frame(a_home - dir * 3.2 + perp * 1.6 + Vector3(0, 1.0, 0), t_home + Vector3(0, 1.2, 0), 46.0, 0.0, 0.7, 1, 0.9)
	else:
		var tilt := 3.0 if perp.z > 0 else -3.0
		cam.frame(t_home + dir * 3.4 + perp * 1.8 + Vector3(0, 2.0, 0), a_home.lerp(t_home, 0.15) + Vector3(0, 1.2, 0), 48.0, tilt, 0.7, 1, 0.9)


func clear_telegraph(inc) -> void:
	if _telegraphs.has(inc):
		for n in _telegraphs[inc]:
			if is_instance_valid(n):
				n.queue_free()
		_telegraphs.erase(inc)


## The wind-up ends: the attacker lunges at the target's spot. If the attack
## was evaded the target stays displaced until the lunge has passed.
func resolve_attack(inc) -> void:
	clear_telegraph(inc)
	var element: Element.Type = inc.element
	var t_home: Vector3 = _home[inc.target]
	var mid: Vector3 = (_home[inc.attacker] + t_home) * 0.5
	cam.frame(mid + _perp(_flat_dir(_home[inc.attacker], t_home)) * 6.5 + Vector3(0, 1.8, 0), mid + Vector3(0, 1.2, 0), 50.0, 0.0, 0.12, 2, 0.6)
	if element == Element.Type.FISICO:
		lunge(inc.attacker, t_home)
	else:
		cast(inc.attacker, t_home, COLORS[element])
	if inc.dodged:
		var from: Vector3 = _home[inc.attacker] + Vector3(0, 1, 0)
		var to := t_home + Vector3(0, 1, 0)
		if _has_projectile(element):
			await get_tree().create_timer(0.12).timeout
			_projectile(from, to + _flat_dir(from, to) * 7.0, COLORS[element], element)
		await get_tree().create_timer(0.4).timeout
		settle(inc.target)


func manual_evade(actor: Combatant, inc) -> void:
	clear_telegraph(inc)
	dodge(actor, "EVADE! BURST", true)
	_dodge_shot(actor, 6.0)
	var home: Vector3 = _home[actor]
	_ring(home + Vector3(0, 1, 0), GOLD, Vector3.ONE * 0.5, Vector3.ONE * 2.5, 0.5, Vector3(90, 0, 0))
	_burst(home + Vector3(0, 1, 0), GOLD, 20, 4.0, Vector3(0, 2, 0), 0.08, 0.6)


## info keys: evaded, dmg, weak, crit, gain.
func play_hit(attacker: Combatant, target: Combatant, element: Element.Type, info: Dictionary) -> void:
	var color: Color = COLORS[element]
	var a_home: Vector3 = _home[attacker]
	var t_home: Vector3 = _home[target]
	var from := a_home + Vector3(0, 1, 0)
	var to := t_home + Vector3(0, 1, 0)
	var physical := element == Element.Type.FISICO
	await get_tree().create_timer(0.12).timeout
	var evaded: bool = info["evaded"]
	if evaded:
		_dodge_later(target, "ESQUIVOU! +1 ATB", 0.1)
		_dodge_shot(target, 0.0)
	if _has_projectile(element):
		var end := to + _flat_dir(from, to) * 7.0 if evaded else to
		await _projectile(from, end, color, element)
	elif physical:
		await get_tree().create_timer(0.06).timeout
	if evaded:
		return
	var weak: bool = info["weak"]
	var crit: bool = info["crit"]
	var perp := _perp(_flat_dir(a_home, t_home))
	var strong := weak or crit
	cam.frame(t_home - _flat_dir(a_home, t_home) * 1.5 + perp * 3.8 + Vector3(0, 1.5, 0), to,
		34.0 if strong else 40.0, (5.0 if perp.z > 0 else -5.0) if strong else 0.0, 0.1, 3, 0.8)
	if strong:
		cam.flash(0.45)
		cam.hit_stop(0.2, 0.14)
	_impact(element, to, color, weak or crit)
	flash(target)
	knock(target, a_home)
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
	var gain: int = info["gain"]
	if gain > 0 and attacker.is_alive():
		float_text(a_home + Vector3(0, 3.0, 0), "+%d ATB" % gain, DODGE_COLOR, 44)
	shake(0.4 if (weak or crit) else 0.12)


func heal_fx(_actor: Combatant, target: Combatant, amount: int) -> void:
	var home: Vector3 = _home[target]
	var green := Color(0.3, 1.0, 0.4)
	cam.frame(home + _perp(Vector3.RIGHT) * 4.0 + Vector3(0, 1.8, 0), home + Vector3(0, 1.2, 0), 45.0, 0.0, 0.4, 1, 0.8)
	_ring(home + Vector3(0, 0.05, 0), green, Vector3.ONE * 2.0, Vector3.ONE * 0.5, 0.6)
	_burst(home + Vector3(0, 0.3, 0), green, 22, 2.0, Vector3(0, 4, 0), 0.08, 0.9)
	float_text(home + Vector3(0, 2.4, 0), "+%d" % amount, green, 64)


# --- Character motion --------------------------------------------------------

func lunge(attacker: Combatant, toward: Vector3) -> void:
	var m: Node3D = _models[attacker]
	var home: Vector3 = _home[attacker]
	var dir := _flat_dir(home, toward)
	var tw := _move(attacker)
	tw.tween_property(m, "scale", Vector3.ONE, 0.04)
	tw.tween_property(m, "position", home + dir * 3.8, 0.1)
	tw.tween_property(m, "position", home, 0.3)


func cast(attacker: Combatant, toward: Vector3, color: Color) -> void:
	var m: Node3D = _models[attacker]
	var home: Vector3 = _home[attacker]
	var dir := _flat_dir(home, toward)
	var tw := _move(attacker)
	tw.tween_property(m, "position", home - dir * 0.5 + Vector3(0, 0.4, 0), 0.12)
	tw.tween_property(m, "position", home, 0.25)
	_ring(home + Vector3(0, 1, 0), color, Vector3.ONE * 1.8, Vector3.ONE * 0.3, 0.25, Vector3(90, 0, 0))


## Sidestep toward the camera leaving a cyan afterimage. `hold` keeps the
## character displaced until settle() is called.
func dodge(target: Combatant, text: String, hold := false) -> void:
	var m: Node3D = _models[target]
	var home: Vector3 = _home[target]
	var ghost := _node(CapsuleMesh.new(), Color(0.5, 0.9, 1.0, 0.5), home + Vector3(0, 1, 0))
	_pop(ghost, 0.45, Vector3.ONE, Vector3.ONE * 1.1)
	var tw := _move(target)
	tw.tween_property(m, "position", home + Vector3(0, 0.3, 2.0), 0.1)
	if not hold:
		tw.tween_interval(0.35)
		tw.tween_property(m, "position", home, 0.2)
	_burst(home + Vector3(0, 0.2, 0), DODGE_COLOR, 14, 3.0, Vector3(0, -2, 0), 0.08, 0.4)
	float_text(home + Vector3(0, 3.0, 0), text, DODGE_COLOR, 56)


func settle(target: Combatant) -> void:
	var m: Node3D = _models[target]
	var tw := _move(target)
	tw.tween_property(m, "position", _home[target], 0.2)


func flash(target: Combatant) -> void:
	var m: Node3D = _models[target]
	var mesh: MeshInstance3D = m.get_meta("mesh")
	var base: Color = m.get_meta("color")
	var mat: StandardMaterial3D = mesh.material_override
	mat.albedo_color = Color.WHITE
	create_tween().tween_property(mat, "albedo_color", base, 0.25)


func knock(target: Combatant, from_pos: Vector3) -> void:
	var m: Node3D = _models[target]
	var home: Vector3 = _home[target]
	var dir := _flat_dir(from_pos, home)
	var tw := _move(target)
	tw.tween_property(m, "position", home + dir * 0.6, 0.06)
	tw.tween_property(m, "position", home, 0.2)


func shake(strength: float) -> void:
	cam.shake(strength)


func float_text(pos: Vector3, text: String, color: Color, size := 48) -> void:
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.font_size = size
	l.pixel_size = 0.01
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + 1.5, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


# --- Element impacts ---------------------------------------------------------

func _impact(element: Element.Type, pos: Vector3, color: Color, big: bool) -> void:
	var ground := Vector3(pos.x, 0.0, pos.z)
	var k := 1.5 if big else 1.0
	match element:
		Element.Type.FISICO:
			for ang in [45.0, -45.0]:
				var slash := _node(_box(Vector3(0.1, 2.4 * k, 0.1)), color, pos)
				slash.rotation_degrees = Vector3(0, 0, ang)
				_pop(slash, 0.2, Vector3(1, 0.2, 1), Vector3.ONE)
			_burst(pos, color, 14, 5.0, Vector3(0, -8, 0), 0.06, 0.4)
		Element.Type.FOGO:
			_pop(_node(_sphere(0.6), color, pos), 0.35, Vector3.ONE * 0.4, Vector3.ONE * 2.2 * k)
			_burst(pos, Color(1.0, 0.6, 0.1), int(28 * k), 4.0, Vector3(0, 5, 0), 0.14, 0.7)
		Element.Type.AGUA_GELO:
			for i in 6:
				var ang := i * TAU / 6.0
				var spike := _node(_cone(0.2, 1.6 * k), color, ground + Vector3(cos(ang), 0.8, sin(ang)) * Vector3(0.7, 1, 0.7))
				_pop(spike, 0.5, Vector3(1, 0.1, 1), Vector3.ONE)
			_burst(pos, color, int(20 * k), 4.0, Vector3(0, -4, 0), 0.08, 0.6)
		Element.Type.RAIO:
			_bolt(pos + Vector3(0, 7, 0), pos, color)
			_burst(pos, color, int(20 * k), 6.0, Vector3(0, -3, 0), 0.06, 0.4)
		Element.Type.PSIQUICO:
			for i in 3:
				_ring(pos, color, Vector3.ONE * 0.3, Vector3.ONE * 2.2 * k, 0.5, Vector3(randf_range(0, 180), randf_range(0, 180), 0), i * 0.1)
			_pop(_node(_sphere(0.4), color, pos), 0.5, Vector3.ONE, Vector3.ONE * 1.8)
		Element.Type.VENENO:
			_pop(_node(_sphere(0.5), Color(0.35, 0.1, 0.45, 0.8), pos), 0.5, Vector3.ONE * 0.5, Vector3.ONE * 2.0 * k)
			_burst(pos, color, int(26 * k), 1.8, Vector3(0, 2, 0), 0.1, 1.0)
		Element.Type.SOM:
			for i in 3:
				_ring(pos, color, Vector3.ONE * 0.4, Vector3.ONE * 2.6 * k, 0.5, Vector3(90, 0, 0), i * 0.12)
		Element.Type.TERRA:
			for i in 3:
				var off := Vector3((i - 1) * 0.8, 1.0, randf_range(-0.4, 0.4))
				_pop(_node(_cyl(0.35, 2.0 * k), color, ground + off), 0.6, Vector3(1, 0.1, 1), Vector3.ONE)
			_burst(ground + Vector3(0, 0.3, 0), color, int(24 * k), 4.0, Vector3(0, -9, 0), 0.12, 0.7)
		Element.Type.VENTO:
			for i in 3:
				_ring(ground + Vector3(0, 0.3 + i * 0.5, 0), color, Vector3.ONE * 0.5, Vector3.ONE * 2.4 * k, 0.5, Vector3.ZERO, i * 0.08)
			_burst(pos, color, 16, 5.0, Vector3(0, 1, 0), 0.06, 0.6)
		Element.Type.LUZ:
			var beam := _node(_cyl(0.45, 9.0), Color(1.0, 1.0, 0.7, 0.85), Vector3(pos.x, 4.5, pos.z))
			_pop(beam, 0.4, Vector3.ONE, Vector3(0.1, 1, 0.1))
			_burst(pos, color, int(22 * k), 3.0, Vector3(0, 3, 0), 0.08, 0.8)
		Element.Type.TREVAS:
			_pop(_node(_sphere(0.9), color, pos), 0.5, Vector3.ONE * 0.2, Vector3.ONE * 1.8 * k)
			_burst(pos, Color(0.6, 0.3, 0.8), int(22 * k), 2.5, Vector3(0, -1, 0), 0.1, 0.8)


func _projectile(from: Vector3, to: Vector3, color: Color, element: Element.Type) -> void:
	var mesh: Mesh = _box(Vector3(0.25, 0.25, 0.7)) if element == Element.Type.AGUA_GELO else _sphere(0.25)
	var node := _node(mesh, color, from)
	if element == Element.Type.AGUA_GELO:
		node.look_at(to, Vector3.UP)
	var trail := CPUParticles3D.new()
	trail.local_coords = false
	trail.amount = 24
	trail.lifetime = 0.3
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.gravity = Vector3.ZERO
	trail.spread = 180.0
	trail.mesh = _sphere(0.1)
	trail.mesh.material = _mat(color)
	node.add_child(trail)
	var tw := create_tween()
	tw.tween_property(node, "position", to, FLY_TIME)
	await tw.finished
	node.queue_free()


# --- Primitives --------------------------------------------------------------

func _move(c: Combatant) -> Tween:
	if _tweens.has(c) and (_tweens[c] as Tween).is_valid():
		(_tweens[c] as Tween).kill()
	var tw := create_tween()
	_tweens[c] = tw
	return tw


## Camera helpers used by the battle scene.
func focus_target(c: Combatant) -> void:
	var home: Vector3 = _home[c]
	var side := 5.0 if c.is_player else -5.0
	cam.frame(home + Vector3(side, 2.2, 4.5), home + Vector3(0, 1.1, 0), 45.0, 0.0, 0.5, 1, 60.0)


func release_camera() -> void:
	cam.release()


func finish(player_won: bool) -> void:
	if player_won:
		cam.orbit(Vector3(-3, 1.2, 0), 7.0, 1.8, -30.0, 70.0, 2.5, 50.0)
	else:
		cam.frame(Vector3(0, 9, 9), Vector3.ZERO, 55.0, 0.0, 1.5, 9, 1000.0)


func _dodge_shot(c: Combatant, roll_deg: float) -> void:
	var home: Vector3 = _home[c]
	cam.frame(home + Vector3(0, 1.6, 6.0), home + Vector3(0, 1.0, 0), 44.0, roll_deg, 0.15, 3, 0.6)


## Flat vector perpendicular to `d`, on the camera's side (+z).
func _perp(d: Vector3) -> Vector3:
	var p := Vector3(-d.z, 0, d.x)
	return p if p.z >= 0.0 else -p


func _has_projectile(element: Element.Type) -> bool:
	return not (element in [Element.Type.FISICO, Element.Type.RAIO, Element.Type.LUZ, Element.Type.TERRA])


func _dodge_later(target: Combatant, text: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	dodge(target, text)


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


func _bolt(top: Vector3, bottom: Vector3, color: Color) -> void:
	var nodes: Array[MeshInstance3D] = []
	var prev := top
	for i in range(1, 7):
		var p := top.lerp(bottom, i / 6.0)
		if i < 6:
			p += Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		nodes.append(_line(prev, p, color, 0.14))
		prev = p
	var tw := create_tween()
	tw.tween_interval(0.2)
	tw.tween_callback(func() -> void:
		for n in nodes:
			n.queue_free()
	)


func _burst(pos: Vector3, color: Color, amount: int, speed: float, gravity: Vector3, size: float, lifetime: float) -> void:
	var p := CPUParticles3D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = lifetime
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = gravity
	var m := _sphere(size)
	m.radial_segments = 6
	m.rings = 3
	m.material = _mat(color)
	p.mesh = m
	add_child(p)
	p.emitting = true
	get_tree().create_timer(lifetime + 0.5).timeout.connect(p.queue_free)
