class_name FxProjectiles
extends RefCounted
## Projectiles and their trails.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx
const TELEPORT_PINCH_PROGRESS := BattleSpace.TELEPORT_PINCH


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## The projectile leaves when Battle enters the TRAVEL phase; it ends on the target, or
## sails past it if the attack was dodged. Its position is drawn from the phase progress.
func spawn(inc) -> void:
	var move_id := String(inc.data.get("move_id", BattleFx.normalize_move_id(inc.label)))
	var lift := Vector3(0, 0.35 if inc.ground else 1.0, 0)  # A ground shot rolls along the floor.
	var from: Vector3 = inc.from + lift
	var end: Vector3 = inc.aim + lift
	var missed: bool = inc.dodged or inc.auto_dodged
	var node := _spawn_move(inc, move_id, from, end, fx.COLORS[inc.element])
	if node == null:
		node = _make_ground_shot(from, end, fx.COLORS[inc.element]) if inc.ground else _make_projectile(from, end, fx.COLORS[inc.element], inc.element)
	# A shot that will hit is guided: it follows the target's body (it may be running or
	# hopping itself), so it always lands on it. A missed one sails past the spot it aimed at.
	inc.data["proj"] = {"node": node, "from": from, "to": end, "lift": lift, "homing": not missed}
	# D-170: extra prototype-v9 layer (cubes, helix, prisms) that follows the same projectile phase.
	if move_id in ["confusao", "raio_psiquico", "onda_choque"]:
		var held := AbraMoveVfx.take_held(inc.attacker)
		if held != null:
			held.launch(from, end)  # the wind-up cubes and Tesseract fly off from where they gathered
			inc.data["proj"]["abra"] = held
		else:
			inc.data["proj"]["abra"] = AbraMoveVfx.travel(fx, move_id, from, end)
	elif move_id in ElementMoveVfx.IDS:
		# D-308: the element flight layer (release blast, Motion Composer body, head); the impact is its own layer.
		var charged := ElementMoveVfx.take_held(inc.attacker)
		if charged != null:
			charged.launch(from, end)  # the charge itself leaves: same fireball, no cut between wind-up and shot
		else:
			charged = ElementMoveVfx.travel(fx, move_id, from, end)
		inc.data["proj"]["element"] = charged
	elif move_id in FireMoveVfx.IDS:
		# D-236: the fire hand becomes the flight layer: bullet, three fire rings and a trail that turns to ash.
		var fire := FireMoveVfx.take_held(inc.attacker)
		if fire != null:
			fire.launch(from, end)
		else:
			fire = FireMoveVfx.travel(fx, move_id, from, end)
		inc.data["proj"]["fire"] = fire


func drive(inc) -> void:
	var move_id := String(inc.data.get("move_id", ""))
	if move_id in FireMoveVfx.IDS and inc.phase == Battle.Phase.STRIKE:
		# D-236: the held fire hand learns how long is left before the shot (its spark rings appear a little earlier)
		FireMoveVfx.notify_launch_in(inc.attacker, float(inc.plan[inc.plan_i][1]) - float(inc.phase_time))
	if move_id == "teleporte_rapido":
		_drive_rapid_teleport(inc, {}, null)
		return
	var p: Dictionary = inc.data.get("proj", {})
	if p.is_empty() or not is_instance_valid(p["node"]):
		return
	var node := p["node"] as Node3D
	var to: Vector3 = inc.aim + (p["lift"] as Vector3)  # The rules aim it (live target, or the spot it misses).
	var abra: Variant = p.get("abra")
	if is_instance_valid(abra):
		(abra as AbraMoveVfx).set_travel(p["from"], to, inc.progress(), inc.phase != Battle.Phase.TRAVEL)
	var element: Variant = p.get("element")
	if is_instance_valid(element):
		(element as ElementMoveVfx).set_travel(p["from"], to, inc.progress(), inc.phase != Battle.Phase.TRAVEL)
	var fire: Variant = p.get("fire")
	if is_instance_valid(fire):
		(fire as FireMoveVfx).set_travel(p["from"], to, inc.progress(), inc.phase != Battle.Phase.TRAVEL)
	if _drive_move(inc, move_id, p, node, to):
		return
	if inc.phase != Battle.Phase.TRAVEL:
		return
	var pos := (p["from"] as Vector3).lerp(to, inc.progress())
	if pos.distance_to(node.position) > 0.01:
		node.look_at_from_position(pos, pos + (pos - node.position))
	else:
		node.position = pos


func finish(inc) -> void:
	var p: Dictionary = inc.data.get("proj", {})
	if not p.is_empty() and is_instance_valid(p["node"]):
		(p["node"] as Node3D).queue_free()
	var abra: Variant = p.get("abra")
	if is_instance_valid(abra):
		var layer := abra as AbraMoveVfx
		if layer.move_id == "raio_psiquico":
			layer.ext_returning = true  # the laser dissipates slowly by itself (it frees itself when gone)
		else:
			layer.queue_free()
	var element: Variant = p.get("element")
	if is_instance_valid(element):
		(element as ElementMoveVfx).end_flight()
	var fire: Variant = p.get("fire")
	if is_instance_valid(fire):
		(fire as FireMoveVfx).end_flight()  # the bullet is gone; the trail and the ashes finish by themselves
	inc.data.erase("proj")


## Return a custom projectile root, or null to use the elemental fallback.
func _spawn_move(_inc, _move_id: String, _from: Vector3, _to: Vector3, _color: Color) -> Node3D:
	match _move_id:
		"confusao": return _empty_root("AbraConfusionTravel")
		"raio_psiquico": return _empty_root("AbraPsybeamTravel")
		"onda_choque": return _empty_root("AbraShockWaveTravel")
		"teleporte_rapido": return _empty_root("AbraTeleportTravel")
		"fire_bullet": return _empty_root("FireBulletTravel")
		"flame_stream": return _empty_root("ElementFlameStreamTravel")
		"splitter_flames": return _empty_root("ElementSplitterFlamesTravel")
		"tiro_areia": return _make_sand_spiral_jet(_from, _to)
		"furia_dragao": return _make_dragon_rage_comet(_from, _to)
		"provocacao": pass
		_: return null
	var root := Node3D.new()
	root.name = "TauntShockWaves"
	fx.add_child(root)
	var dir := fx._flat_dir(_from, _to)
	for i in 4:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.62 + float(i) * 0.06
		torus.outer_radius = 0.82 + float(i) * 0.06
		var ring := MeshInstance3D.new()
		ring.name = "TauntRing%d" % i
		ring.mesh = torus
		ring.material_override = fx.fx_impacts._tackle_material(Color("ff624f", 0.88) if i % 2 == 0 else Color("2b0938", 0.94), 2.6)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.quaternion = Quaternion(Vector3.UP, dir)
		ring.position = _from
		ring.visible = false
		root.add_child(ring)
	return root


## Return true when a move has positioned its projectile for this Battle frame.
func _drive_move(_inc, _move_id: String, _projectile: Dictionary, _node: Node3D, _to: Vector3) -> bool:
	if _move_id == "fire_bullet" or _move_id in ElementMoveVfx.IDS:
		return true  # FireMoveVfx / ElementMoveVfx draw the whole flight; the empty root stays put
	if _move_id == "confusao":
		if _inc.phase != Battle.Phase.TRAVEL:
			return true
		for i in _node.get_child_count():
			var ring := _node.get_child(i) as Node3D
			var p := clampf(_inc.progress() * 1.45 - float(i) * 0.16, 0.0, 1.0)
			ring.visible = p > 0.0 and p < 1.0
			ring.global_position = (_projectile["from"] as Vector3).lerp(_to, p)
			ring.scale = Vector3.ONE * (0.35 + p * 1.15)
		return true
	if _move_id == "raio_psiquico":
		if _inc.phase == Battle.Phase.TRAVEL:
			_node.scale = Vector3(1.0, maxf(_inc.progress(), 0.01), 1.0)
		elif _inc.phase == Battle.Phase.RETURN:
			var fade: float = 1.0 - _inc.progress()
			_node.scale = Vector3(fade, 1.0, fade)
			if _inc.progress() >= 0.95 and is_instance_valid(_node):
				_node.queue_free()
		return true
	if _move_id == "onda_choque":
		if _inc.phase == Battle.Phase.TRAVEL:
			_node.visible = int(_inc.phase_time * 42.0) % 2 == 0
		else:
			_node.visible = false
		return true
	if _move_id == "teleporte_rapido":
		return _drive_rapid_teleport(_inc, _projectile, _node)
	if _move_id == "tiro_areia":
		if _inc.phase == Battle.Phase.TRAVEL:
			var p: float = _inc.progress()
			var pos := (_projectile["from"] as Vector3).lerp(_to, p)
			pos.y += sin(p * PI) * 0.25
			_node.look_at_from_position(pos, _to)
			_node.rotate_object_local(Vector3.FORWARD, 0.22)
		return true
	if _move_id == "furia_dragao":
		if _inc.phase == Battle.Phase.TRAVEL:
			var p: float = _inc.progress()
			var from: Vector3 = _projectile["from"]
			var delta := _to - from
			var dir := delta.normalized()
			var right := Vector3(dir.z, 0, -dir.x).normalized()
			var up := Vector3.UP
			for i in _node.get_child_count():
				var orb := _node.get_child(i) as Node3D
				var seg_p := clampf(p - float(i) * 0.038, 0.0, 1.0)
				var pt := from.lerp(_to, seg_p)
				pt.y += sin(seg_p * PI) * 0.85
				var roll := (p * 18.0 - float(i) * 0.8)
				var wave_r := 0.22 * (1.0 - float(i) / 9.0)
				pt += (right * cos(roll) + up * sin(roll)) * wave_r
				orb.global_position = pt
		return true
	if _move_id != "provocacao":
		return false
	var from: Vector3 = _projectile["from"]
	for i in _node.get_child_count():
		var ring := _node.get_child(i) as Node3D
		var p := clampf(_inc.progress() * 1.65 - float(i) * 0.18, 0.0, 1.0)
		ring.visible = p > 0.0 and p < 1.0
		ring.global_position = from.lerp(_to, p)
		ring.scale = Vector3.ONE * (0.65 + sin(p * PI) * 0.55)
	return true


func _teleport_scale(progress: float) -> Vector3:
	var pinch := Vector3(0.06, 2.1, 0.06)
	if progress <= TELEPORT_PINCH_PROGRESS:
		return Vector3.ONE.lerp(pinch, clampf(progress / TELEPORT_PINCH_PROGRESS, 0.0, 1.0))
	return pinch.lerp(Vector3.ONE, clampf((progress - TELEPORT_PINCH_PROGRESS) / (1.0 - TELEPORT_PINCH_PROGRESS), 0.0, 1.0))


func _drive_rapid_teleport(inc, _projectile: Dictionary = {}, _node: Node3D = null) -> bool:
	var model: Node3D = fx._models.get(inc.attacker)
	if model == null:
		return true
	var a: Combatant = inc.attacker
	var origin: Vector3 = inc.from
	var target_pos: Vector3 = inc.target.pos
	var attack_dir := BattleSpace.flat_dir(origin, target_pos)
	var dest: Vector3 = target_pos + attack_dir * 1.35
	inc.dest = dest
	var base_scale: Vector3 = fx._base_scale.get(inc.attacker, Vector3.ONE)
	inc.data["teleport_origin"] = origin
	fx._displaced[a] = true

	if inc.phase == Battle.Phase.TRAVEL:
		if not inc.data.get("teleport_vanish_flash", false):
			inc.data["teleport_vanish_flash"] = true
			AbraPops.teleport_pop(fx, Vector3(origin.x, 0.0, origin.z), true, model)
		model.visible = false
	elif inc.phase == Battle.Phase.STRIKE:
		model.visible = true
		model.position = dest
		model.rotation.y = atan2(-attack_dir.x, -attack_dir.z)
		model.scale = base_scale
		if not inc.data.get("teleport_arrival_flash", false):
			inc.data["teleport_arrival_flash"] = true
			AbraPops.teleport_pop(fx, Vector3(dest.x, 0.0, dest.z), false, model)
			AbraMoveVfx.release_held(inc.attacker)  # the arrival seal ends when Abra appears
			fx._play(inc.attacker, "attack")
	elif inc.phase == Battle.Phase.RETURN:
		var p: float = inc.progress()
		if p < 0.35:
			if not inc.data.get("teleport_exit_flash", false):
				inc.data["teleport_exit_flash"] = true
				AbraPops.teleport_pop(fx, Vector3(dest.x, 0.0, dest.z), true, model)
			model.visible = false
		else:
			model.visible = true
			model.position = origin
			model.rotation.y = fx._home_yaw[inc.attacker]
			model.scale = base_scale
			if not inc.data.get("teleport_home_flash", false):
				inc.data["teleport_home_flash"] = true
				AbraPops.teleport_pop(fx, Vector3(origin.x, 0.0, origin.z), false, model)
				fx._displaced[a] = false
				fx._reset_idle(inc.attacker)
	return true


## The four Abra moves draw their flight in AbraMoveVfx; this root only carries the
## projectile bookkeeping (D-170: the old rings, beam and warp were removed).
func _empty_root(root_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	fx.add_child(root)
	return root


func _make_sand_spiral_jet(from: Vector3, to: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "SandSpiralJet"
	root.position = from
	fx.add_child(root)
	root.look_at(to, Vector3.UP)
	for i in 24:
		var t := float(i) / 23.0
		var angle := t * TAU * 3.5
		var radius := lerpf(0.08, 0.72, t)
		var grain := MeshInstance3D.new()
		grain.name = "SandGrain%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = lerpf(0.08, 0.18, t)
		sphere.height = sphere.radius * 2.0
		grain.mesh = sphere
		grain.position = Vector3(cos(angle) * radius, sin(angle) * radius, t * 3.0)
		grain.material_override = fx.fx_impacts._tackle_material(Color("f0c57e") if i % 2 == 0 else Color("d98a3c"), 1.8)
		grain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(grain)
	VfxLib.trail(root, {"tex": VfxLib.smoke_tex(), "amount": 48, "life": 0.34, "speed": Vector2(1.2, 4.5), "size": Vector2(0.18, 0.55), "radius": 0.32, "ramp": VfxLib.ramp([Color("f0c57e"), Color("d98a3c"), Color("d98a3c", 0.0)])})
	return root


func _make_dragon_rage_comet(from: Vector3, to: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "DragonRageComet"
	root.position = from
	fx.add_child(root)
	root.look_at(to, Vector3.UP)
	for i in 9:
		var orb := MeshInstance3D.new()
		orb.name = "DragonRageCore" if i == 0 else "DragonRageTail%d" % i
		var sphere := SphereMesh.new()
		var radius := 0.72 if i == 0 else lerpf(0.48, 0.10, float(i - 1) / 7.0)
		sphere.radius = radius
		sphere.height = radius * 2.0
		orb.mesh = sphere
		orb.position = Vector3.ZERO
		var color := Color("ff624f") if i == 0 else (Color("63d9ec") if i % 2 == 0 else Color("bd9afd"))
		orb.material_override = fx.fx_impacts._tackle_material(color, 3.6 if i == 0 else 2.6)
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(orb)
	return root


## A mound of sand and rock that skids along the floor, kicking up dust behind it.
func _make_ground_shot(from: Vector3, to: Vector3, color: Color) -> Node3D:
	var node := Node3D.new()
	node.position = from
	fx.add_child(node)
	node.look_at_from_position(from, to)
	var sand := Color(0.78, 0.62, 0.38)
	for i in 5:
		var size := randf_range(0.35, 0.7)
		var sph := SphereMesh.new()
		sph.radius = size * 0.38
		sph.height = size * 0.76
		sph.radial_segments = 5
		sph.rings = 3
		var rock := fx._node(sph, sand.darkened(randf_range(0.0, 0.35)),
			Vector3(randf_range(-0.7, 0.7), size * 0.35, randf_range(-0.6, 0.6)))
		rock.material_override.albedo_color.a = 1.0
		rock.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		fx.remove_child(rock)
		node.add_child(rock)
	var dust := VfxLib.ramp([Color(sand.r, sand.g, sand.b, 0.85), Color(sand.r * 0.8, sand.g * 0.7, sand.b * 0.55, 0.5), Color(sand.r, sand.g, sand.b, 0.0)], [0.0, 0.4, 1.0])
	VfxLib.trail(node, {"tex": VfxLib.smoke_tex(), "amount": 60, "life": 0.6, "speed": Vector2(0.3, 1.6), "size": Vector2(1.0, 1.9),
		"end_scale": 1.6, "radius": 0.5, "ramp": dust})
	return node


## A glowing orb (or an ice shard) flying from `from` to `to`, with a 3D twisted
## ribbon wake (`ribbon_trail.glb`) and particle trail.
func _make_projectile(from: Vector3, to: Vector3, color: Color, element: Element.Type) -> Node3D:
	var node := Node3D.new()
	node.position = from
	fx.add_child(node)
	node.look_at_from_position(from, to)
	if element == Element.Type.AGUA_GELO:
		var icicle := CylinderMesh.new()
		icicle.top_radius = 0.02
		icicle.bottom_radius = 0.20
		icicle.height = 1.35
		icicle.radial_segments = 4
		var shard := fx._node(icicle, Color(0.7, 0.95, 1.0, 0.95), Vector3.ZERO)
		shard.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
		shard.material_override.emission_enabled = true
		shard.material_override.emission = Color(0.4, 0.85, 1.0)
		shard.material_override.emission_energy_multiplier = 2.5
		fx.remove_child(shard)
		node.add_child(shard)
	else:
		for layer in [[2.2, color, 0.9], [1.0, Color(1, 1, 1), 1.0]]:
			var quad := QuadMesh.new()
			quad.size = Vector2.ONE * layer[0]
			var mat := VfxLib.particle_mat(VfxLib.glow_tex(), true)
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mat.vertex_color_use_as_albedo = false
			mat.albedo_color = Color(layer[1].r * 1.5, layer[1].g * 1.5, layer[1].b * 1.5, layer[2])
			quad.material = mat
			var mi := MeshInstance3D.new()
			mi.mesh = quad
			node.add_child(mi)
	# Attach 3D twisted ribbon wake (`ribbon_trail.glb`)
	var rib_mesh := VfxLib.vfx_mesh("ribbon_trail")
	if rib_mesh != null:
		var rib := MeshInstance3D.new()
		rib.mesh = rib_mesh
		rib.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rib_mat := VfxLib.shader_mat("mesh_slash", {
			"trail_tex": VfxLib.slash_trail_tex(),
			"color": color,
			"core_color": Color(1.0, 0.98, 0.92, 1.0),
			"energy": 3.0,
			"progress": 0.45,
		})
		rib.material_override = rib_mat
		rib.position = Vector3(0, 0, 1.8)
		node.add_child(rib)
	var trail_ramp := VfxLib.ramp([Color(1, 1, 1, 0.9), color, Color(color, 0)], [0.0, 0.3, 1.0])
	if element == Element.Type.FOGO:
		trail_ramp = VfxLib.ramp([Color(1, 0.9, 0.5, 0.9), Color(1, 0.45, 0.1, 0.8), Color(0.2, 0.08, 0.05, 0)], [0.0, 0.35, 1.0])
	VfxLib.trail(node, {"tex": VfxLib.smoke_tex() if element == Element.Type.FOGO else VfxLib.glow_tex(), "amount": 40, "life": 0.45,
		"speed": Vector2(0.2, 1.2), "size": Vector2(0.8, 1.4), "end_scale": 0.0, "radius": 0.15, "ramp": trail_ramp})
	return node


# --- Dodge visuals -------------------------------------------------------------------


func _has_projectile(element: Element.Type) -> bool:
	return not (element in [Element.Type.FISICO, Element.Type.RAIO, Element.Type.LUZ, Element.Type.TERRA])
