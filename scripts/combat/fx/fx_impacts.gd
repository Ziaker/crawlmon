class_name FxImpacts
extends RefCounted
## Per-element impact effects and their particle helpers.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx


func _init(p_fx: BattleFx) -> void:
	fx = p_fx


## Flat shockwave ring on the floor.
func _shock(ground: Vector3, color: Color, size: float, duration := 0.55) -> void:
	var q := VfxLib.animated_quad(fx, Vector2(size, size), "ring", {"color": color, "energy": 2.2}, duration)
	q.position = ground + Vector3(0, 0.06, 0)
	q.rotation_degrees = Vector3(-90, 0, 0)


## Vertical ring facing the camera.
func _ring_cam(pos: Vector3, color: Color, size: float, duration := 0.5, delay := 0.0) -> void:
	if delay > 0.0:
		await fx.get_tree().create_timer(delay, false).timeout
	var q := VfxLib.animated_quad(fx, Vector2(size, size), "ring", {"color": color, "energy": 2.2}, duration)
	q.position = pos
	fx._face_camera(q)


func _slash(pos: Vector3, color: Color, size: float, roll_deg: float, duration := 0.28, delay := 0.0) -> void:
	if delay > 0.0:
		await fx.get_tree().create_timer(delay, false).timeout
	var q := VfxLib.animated_quad(fx, Vector2(size, size), "slash", {"color": color, "energy": 2.4}, duration)
	q.position = pos
	fx._face_camera(q)
	q.rotate_object_local(Vector3.BACK, deg_to_rad(roll_deg))


func _sparks(pos: Vector3, color: Color, amount: int, speed := Vector2(5.0, 12.0), gravity := Vector3(0, -10, 0)) -> void:
	VfxLib.burst(fx, pos, {
		"amount": amount, "life": 0.55, "speed": speed, "gravity": gravity,
		"size": Vector2(0.14, 0.3), "end_scale": 0.2,
		"ramp": VfxLib.ramp([Color(1, 1, 1, 1), color, Color(color, 0)], [0.0, 0.3, 1.0])})


func _glow(pos: Vector3, color: Color, amount: int, size: Vector2, life: float, speed: Vector2, gravity := Vector3.ZERO, end_scale := 0.0, radius := 0.0) -> void:
	VfxLib.burst(fx, pos, {
		"amount": amount, "life": life, "speed": speed, "gravity": gravity, "size": size,
		"end_scale": end_scale, "radius": radius,
		"ramp": VfxLib.ramp([Color(1, 1, 1, 1), color, Color(color, 0)], [0.0, 0.25, 1.0])})


func _smoke(pos: Vector3, color: Color, amount: int, size: Vector2, life: float, rise := 1.5, additive := false) -> void:
	if amount >= 5:
		VfxLib.flipbook(fx, pos + Vector3(0, 0.35, 0), "smoke", color, maxf(size.y * 1.35, 2.2), clampf(life * 0.75, 0.35, 0.75), randf_range(-25.0, 25.0), 1.3, additive)
	VfxLib.burst(fx, pos, {
		"tex": VfxLib.smoke_tex(), "additive": additive, "amount": amount, "life": life,
		"speed": Vector2(0.5, 3.0), "gravity": Vector3(0, rise, 0), "size": size, "end_scale": 1.8,
		"damping": 1.5, "radius": 0.4,
		"ramp": VfxLib.ramp([Color(color, 0.0), Color(color, 0.75), Color(color, 0.0)], [0.0, 0.2, 1.0])})


## Spawns per-element impact VFX and returns the primary 3D nodes so `fx._hit_stop`
## can vibrate them in sync with the target model.
func _impact(element: Element.Type, pos: Vector3, color: Color, big: bool, dir := Vector3.FORWARD) -> Array[Node3D]:
	var k := 1.45 if big else 1.0
	var ground := Vector3(pos.x, 0.0, pos.z)
	var fx_nodes: Array[Node3D] = []
	VfxLib.flash_star(fx, pos, color.lightened(0.45), 3.4 * k)
	_shock(ground, color, 5.0 * k)
	match element:
		Element.Type.FISICO:
			# 1. Multi-frame animated impact sprite sheet (16 frames)
			var fb_main := VfxLib.flipbook(fx, pos, "impact", Color(1.0, 0.96, 0.86), 4.6 * k, 0.30, randf_range(-20.0, 20.0), 3.2)
			fx_nodes.append(fb_main)
			if big:
				var fb_heavy := VfxLib.flipbook(fx, pos + Vector3(0, 0.2, 0), "impact", Color(1.0, 0.78, 0.38), 5.8, 0.36, 55.0, 3.6)
				fx_nodes.append(fb_heavy)
			# 2. 3D curved slash meshes (Blender `slash_arc.glb` + scrolling/distorting trail texture)
			var slash1 := VfxLib.mesh_slash(fx, pos, dir, Color(1.0, 0.97, 0.88), 32.0, 1.35 * k, 0.28, "slash_arc")
			var cone := VfxLib.mesh_slash(fx, pos - dir * 0.2, dir, Color(1.0, 0.92, 0.75), 0.0, 1.2 * k, 0.32, "shock_cone")
			fx_nodes.append(slash1)
			fx_nodes.append(cone)
			fx.get_tree().create_timer(0.05, false).timeout.connect(func() -> void:
				if not is_instance_valid(fx) or not fx.is_inside_tree():
					return
				VfxLib.mesh_slash(fx, pos, dir, Color(0.9, 0.96, 1.0), -44.0, 1.25 * k, 0.26, "slash_arc"))
			# 3. 16-frame animated dust/smoke flipbook + high-velocity sparks
			VfxLib.flipbook(fx, ground + Vector3(0, 0.55, 0), "smoke", Color(0.85, 0.82, 0.78), 3.4 * k, 0.52, randf_range(-15.0, 15.0), 1.4, false)
			_sparks(pos, Color(1.0, 0.85, 0.5), int(46 * k))
			_smoke(ground + Vector3(0, 0.3, 0), Color(0.75, 0.78, 0.8), 10, Vector2(1.2, 2.2), 0.8, 0.8)
		Element.Type.FOGO:
			# 1. Multi-layered 16-frame fire explosion sprite sheets
			var fb_fire1 := VfxLib.flipbook(fx, pos, "fire", Color(1.0, 0.78, 0.32), 4.8 * k, 0.46, randf_range(-18.0, 18.0), 3.2)
			var fb_fire2 := VfxLib.flipbook(fx, pos + Vector3(0, 0.65, 0), "fire", Color(1.0, 0.45, 0.12), 4.2 * k, 0.56, randf_range(-35.0, 35.0), 2.8)
			var fb_burst := VfxLib.flipbook(fx, pos, "impact", Color(1.0, 0.6, 0.18), 4.4 * k, 0.28, 15.0, 3.0)
			fx_nodes.append_array([fb_fire1, fb_fire2, fb_burst])
			# 2. 3D flame vortex cone & fire whip arc
			var fire_cone := VfxLib.mesh_slash(fx, pos, dir, Color(1.0, 0.48, 0.12), 0.0, 1.35 * k, 0.40, "shock_cone")
			var fire_arc := VfxLib.mesh_slash(fx, pos, dir, Color(1.0, 0.72, 0.22), 25.0, 1.25 * k, 0.34, "slash_arc")
			fx_nodes.append_array([fire_cone, fire_arc])
			# 3. 16-frame dark smoke plume flipbook + embers
			VfxLib.flipbook(fx, pos + Vector3(0, 0.95, 0), "smoke", Color(0.24, 0.18, 0.15), 4.2 * k, 0.72, 12.0, 1.2, false)
			_glow(pos, Color(1.0, 0.45, 0.1), int(26 * k), Vector2(1.0, 2.0), 0.75, Vector2(1.0, 4.5), Vector3(0, 4, 0), 1.2, 0.5)
			_sparks(pos, Color(1.0, 0.55, 0.15), int(34 * k), Vector2(3.0, 9.0), Vector3(0, 2, 0))
			_smoke(pos + Vector3(0, 0.5, 0), Color(0.12, 0.1, 0.1), 10, Vector2(1.6, 2.8), 1.4, 2.0)
		Element.Type.AGUA_GELO:
			for i in 7:
				var ang := i * TAU / 7.0 + 0.3
				var spike := fx._node(fx._cone(0.28, 2.0 * k), Color(0.65, 0.92, 1.0, 0.95), ground + Vector3(cos(ang) * 0.9, 1.0, sin(ang) * 0.9))
				spike.rotation = Vector3(sin(ang) * 0.35, 0, -cos(ang) * 0.35)
				spike.material_override.emission_enabled = true
				spike.material_override.emission = Color(0.4, 0.8, 1.0)
				spike.material_override.emission_energy_multiplier = 1.6
				fx._pop(spike, 0.7, Vector3(1, 0.05, 1), Vector3.ONE)
			_sparks(pos, Color(0.6, 0.9, 1.0), int(40 * k), Vector2(3.0, 9.0))
			_smoke(ground + Vector3(0, 0.4, 0), Color(0.75, 0.92, 1.0), 14, Vector2(1.4, 2.6), 1.1, 0.6, true)
		Element.Type.RAIO:
			# 1. Multi-layered 16-frame lightning arc sprite sheets
			var fb_bolt1 := VfxLib.flipbook(fx, pos, "lightning", Color(0.85, 0.96, 1.0), 5.0 * k, 0.32, randf_range(0.0, 360.0), 3.8)
			var fb_bolt2 := VfxLib.flipbook(fx, pos + Vector3(0, 0.7, 0), "lightning", Color(1.0, 0.95, 0.35), 4.4 * k, 0.38, randf_range(0.0, 360.0), 3.4)
			var fb_sky := VfxLib.flipbook(fx, pos + Vector3(0, 2.3, 0), "lightning", Color(0.9, 0.98, 1.0), 5.6 * k, 0.28, 90.0, 4.0)
			var fb_imp := VfxLib.flipbook(fx, pos, "impact", Color(1.0, 0.96, 0.45), 4.2 * k, 0.26, 0.0, 3.5)
			fx_nodes.append_array([fb_bolt1, fb_bolt2, fb_sky, fb_imp])
			# 2. 3D electric shockwave cone & arc slash
			var elec_cone := VfxLib.mesh_slash(fx, pos, Vector3.UP, Color(1.0, 0.95, 0.35), 0.0, 1.35 * k, 0.30, "shock_cone")
			var elec_arc := VfxLib.mesh_slash(fx, pos, dir, Color(0.8, 0.95, 1.0), -30.0, 1.25 * k, 0.26, "slash_arc")
			fx_nodes.append_array([elec_cone, elec_arc])
			# 3. 3D lightning bolts + high-velocity sparks
			_bolt(pos + Vector3(0, 9, 0), pos, color)
			_bolt(pos + Vector3(2.5, 8, 0.5), pos + Vector3(0.3, 0.2, 0), color, 0.6)
			_sparks(pos, Color(1.0, 0.95, 0.4), int(50 * k), Vector2(6.0, 14.0), Vector3(0, -6, 0))
			_ring_cam(pos, color, 4.0 * k, 0.4)
		Element.Type.PSIQUICO:
			for i in 3:
				_ring_cam(pos, color, (3.5 + i) * k, 0.55, i * 0.1)
			_glow(pos + Vector3(0, 0.2, 0), color, int(30 * k), Vector2(0.5, 1.0), 0.8, Vector2(0.5, 1.5), Vector3.ZERO, 0.0, 2.6)
			VfxLib.burst(fx, pos, {"amount": int(30 * k), "life": 0.7, "speed": Vector2(0.0, 1.0), "radial_accel": -14.0,
				"size": Vector2(0.5, 0.9), "radius": 2.8, "ramp": VfxLib.ramp([Color(1, 1, 1, 0), color, Color(1, 1, 1, 0)], [0.0, 0.5, 1.0])})
		Element.Type.VENENO:
			_smoke(ground + Vector3(0, 0.6, 0), Color(0.45, 0.2, 0.55), 22, Vector2(1.8, 3.2), 1.4, 1.2)
			_smoke(ground + Vector3(0, 0.5, 0), Color(0.5, 0.85, 0.2), 12, Vector2(1.2, 2.2), 1.2, 1.4, true)
			_glow(pos, Color(0.6, 0.95, 0.25), int(20 * k), Vector2(0.25, 0.55), 1.1, Vector2(0.5, 2.5), Vector3(0, 2.5, 0), 0.4, 0.6)
		Element.Type.SOM:
			for i in 3:
				_shock(ground, color, (4.0 + i * 2.0) * k, 0.5 + i * 0.12)
				_ring_cam(pos, color, (3.0 + i * 1.6) * k, 0.45, i * 0.1)
			_sparks(pos, color, int(26 * k), Vector2(4.0, 10.0), Vector3.ZERO)
		Element.Type.TERRA:
			for i in 6:
				var ang := i * TAU / 6.0 + 0.2
				var rock_h := (3.0 if i % 2 == 0 else 2.0) * k
				var rock := fx._node(fx._cone(0.55, rock_h), Color(0.52, 0.38, 0.26, 1.0), ground + Vector3(cos(ang) * 1.3, rock_h * 0.5, sin(ang) * 1.3))
				rock.mesh.radial_segments = 5
				rock.rotation = Vector3(sin(ang) * 0.3, 0, -cos(ang) * 0.3)
				fx._pop(rock, 0.9, Vector3(1, 0.05, 1), Vector3.ONE)
			_smoke(ground + Vector3(0, 0.3, 0), Color(0.55, 0.42, 0.3), 18, Vector2(1.6, 3.0), 1.1, 0.8)
			VfxLib.burst(fx, ground + Vector3(0, 0.5, 0), {"tex": VfxLib.glow_tex(), "additive": false, "amount": int(18 * k), "life": 0.8,
				"speed": Vector2(3.0, 8.0), "gravity": Vector3(0, -16, 0), "size": Vector2(0.18, 0.35), "end_scale": 0.6, "dir": Vector3(0, 1, 0), "spread": 60.0,
				"ramp": VfxLib.ramp([Color(0.55, 0.4, 0.28, 1), Color(0.35, 0.25, 0.18, 0.0)])})
		Element.Type.VENTO:
			for i in 3:
				VfxLib.mesh_slash(fx, pos, dir, Color(0.75, 1.0, 0.85), i * 120.0 + 20.0, 1.2 * k, 0.34, "slash_arc")
			_sparks(pos, Color(0.8, 1.0, 0.85), int(30 * k), Vector2(4.0, 10.0), Vector3(0, 1, 0))
			_smoke(ground + Vector3(0, 0.4, 0), Color(0.8, 0.95, 0.88), 12, Vector2(1.2, 2.4), 0.9, 0.5, true)
		Element.Type.LUZ:
			var beam := fx._node(fx._cyl(1.0, 14.0), Color(1.0, 0.95, 0.6, 0.35), Vector3(pos.x, 7.0, pos.z))
			beam.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			fx._pop(beam, 0.55, Vector3.ONE, Vector3(0.15, 1, 0.15))
			var core := fx._node(fx._cyl(0.4, 14.0), Color(1.0, 1.0, 0.9, 0.9), Vector3(pos.x, 7.0, pos.z))
			core.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			fx._pop(core, 0.4, Vector3.ONE, Vector3(0.1, 1, 0.1))
			_glow(pos, Color(1.0, 0.95, 0.6), int(30 * k), Vector2(0.5, 1.2), 0.9, Vector2(1.0, 4.0), Vector3(0, 3, 0), 0.0, 0.8)
			_ring_cam(pos, color, 5.0 * k, 0.5)
		Element.Type.TREVAS:
			var orb := fx._node(fx._sphere(1.1), Color(0.05, 0.02, 0.1, 1.0), pos)
			fx._pop(orb, 0.6, Vector3.ONE * 0.2, Vector3.ONE * 1.7 * k)
			VfxLib.burst(fx, pos, {"amount": int(36 * k), "life": 0.7, "speed": Vector2(0.0, 1.0), "radial_accel": -16.0, "radius": 3.2,
				"size": Vector2(0.4, 0.8), "ramp": VfxLib.ramp([Color(0.7, 0.35, 1.0, 0), Color(0.7, 0.35, 1.0, 1), Color(0.3, 0.1, 0.5, 0)], [0.0, 0.4, 1.0])})
			_glow(pos, Color(0.65, 0.3, 0.95), int(24 * k), Vector2(0.5, 1.0), 0.8, Vector2(3.0, 8.0))
			_shock(ground, Color(0.6, 0.25, 0.9), 6.0 * k, 0.65)
	return fx_nodes


func _bolt(top: Vector3, bottom: Vector3, color: Color, scale_k := 1.0) -> void:
	var points: Array[Vector3] = [top]
	for i in range(1, 8):
		var p := top.lerp(bottom, i / 7.0)
		if i < 7:
			p += Vector3(randf_range(-0.9, 0.9), 0, randf_range(-0.9, 0.9))
		points.append(p)
	var nodes: Array[MeshInstance3D] = []
	for i in range(1, points.size()):
		var glow_seg := fx._line(points[i - 1], points[i], Color(color, 0.35), 0.55 * scale_k)
		glow_seg.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		var core_seg := fx._line(points[i - 1], points[i], Color(1, 1, 1, 1), 0.12 * scale_k)
		core_seg.material_override.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		nodes += [glow_seg, core_seg]
	var tw := fx.create_tween()
	tw.tween_interval(0.08)
	tw.tween_callback(func() -> void:
		for n in nodes:
			n.visible = false
	)
	tw.tween_interval(0.05)
	tw.tween_callback(func() -> void:
		for n in nodes:
			n.visible = true
	)
	tw.tween_interval(0.12)
	tw.tween_callback(func() -> void:
		for n in nodes:
			n.queue_free()
	)


func _burst(pos: Vector3, color: Color, amount: int, speed: float, gravity: Vector3, size: float, lifetime: float) -> void:
	_glow(pos, color, amount, Vector2(size * 4.0, size * 8.0), lifetime, Vector2(speed * 0.4, speed), gravity)


# --- Primitives --------------------------------------------------------------
