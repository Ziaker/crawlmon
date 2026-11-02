class_name FxImpacts
extends RefCounted
## Per-element impact effects and their particle helpers.
## Part of BattleFx (see battle_fx.gd): the shared state lives in `fx`.

var fx: BattleFx
var _brick_barriers: Dictionary = {}  ## Combatant -> Node3D, survives windup cleanup until contact.


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


func _tackle_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = energy
	return mat


func spawn_brick_barrier(target: Combatant, pos: Vector3, strike_dir: Vector3) -> Node3D:
	clear_brick_barrier(target)
	var root := Node3D.new()
	root.name = "BrickHexBarrier"
	root.position = pos
	var dir := strike_dir.normalized() if strike_dir.length_squared() > 0.001 else Vector3.FORWARD
	root.quaternion = Quaternion(Vector3.UP, dir)
	fx.add_child(root)
	var cells := [Vector2(0, 0), Vector2(-0.78, 0), Vector2(0.78, 0), Vector2(-0.39, -0.68), Vector2(0.39, -0.68), Vector2(-0.39, 0.68), Vector2(0.39, 0.68)]
	for i in cells.size():
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.48
		mesh.bottom_radius = 0.48
		mesh.height = 0.055
		mesh.radial_segments = 6
		var tile := MeshInstance3D.new()
		tile.name = "HexTile%d" % i
		tile.mesh = mesh
		tile.position = Vector3(cells[i].x, 0, cells[i].y)
		tile.material_override = _tackle_material(Color("63d9ec", 0.30), 2.1)
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(tile)
	_brick_barriers[target] = root
	return root


func clear_brick_barrier(target: Combatant) -> void:
	var barrier: Variant = _brick_barriers.get(target)  # May already be freed: keep it untyped.
	if is_instance_valid(barrier):
		(barrier as Node3D).queue_free()
	_brick_barriers.erase(target)


func shatter_brick_barrier(target: Combatant, pos: Vector3, strike_dir: Vector3) -> Node3D:
	clear_brick_barrier(target)
	var root := Node3D.new()
	root.name = "BrickBarrierShards"
	root.position = pos
	fx.add_child(root)
	var dir := strike_dir.normalized() if strike_dir.length_squared() > 0.001 else Vector3.FORWARD
	var right := Vector3(dir.z, 0, -dir.x)
	for i in 15:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.16 + float(i % 4) * 0.035
		mesh.height = 0.34 + float(i % 3) * 0.08
		mesh.radial_segments = 3
		var shard := MeshInstance3D.new()
		shard.name = "BarrierShard%02d" % i
		shard.mesh = mesh
		shard.material_override = _tackle_material(Color("63d9ec", 0.78) if i % 3 else Color("ff624f", 0.85), 2.5)
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(shard)
		var side := (float(i % 5) - 2.0) * 0.62
		var lift := 0.8 + float(i % 4) * 0.42
		var out := dir * (0.8 + float(i % 3) * 0.35) + right * side + Vector3.UP * lift
		var tw := shard.create_tween().set_parallel(true)
		tw.tween_method(func(k: float) -> void:
			shard.position = out * k + Vector3.DOWN * 3.8 * k * k,
			0.0, 1.0, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(shard, "rotation", Vector3(3.0 + i, 5.0 - i * 0.2, 2.0 + i * 0.3), 0.62)
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.68)
	cleanup.tween_callback(root.queue_free)
	return root


func _tackle_torus(name_: String, pos: Vector3, color: Color, energy: float, scale_from: float, scale_to: float, duration: float, normal: Vector3) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 12
	var node := MeshInstance3D.new()
	node.name = name_
	node.mesh = torus
	node.material_override = _tackle_material(color, energy)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = pos
	node.quaternion = Quaternion(Vector3.UP, normal.normalized())
	node.scale = Vector3.ONE * scale_from
	fx.add_child(node)
	var mat := node.material_override as StandardMaterial3D
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "scale", Vector3.ONE * scale_to, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration * 0.58).set_delay(duration * 0.42)
	tw.chain().tween_callback(node.queue_free)
	return node


## Impacto B1: four-axis starburst, central plasma and 18 high-contrast shards.
func _tackle_impact(pos: Vector3, strike_dir: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.45 if big else 1.0
	var dir := strike_dir.normalized() if strike_dir.length_squared() > 0.001 else Vector3.FORWARD
	var root := Node3D.new()
	root.name = "TackleImpactB1"
	root.position = pos
	root.quaternion = Quaternion(Vector3.FORWARD, dir)
	fx.add_child(root)
	var axes: Array[Vector3] = [
		Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK,
		Vector3(0.35, 0.75, 0.75).normalized(), Vector3(-0.35, -0.75, -0.75).normalized(),
		Vector3(0.35, 0.75, -0.75).normalized(), Vector3(-0.35, -0.75, 0.75).normalized()]
	for i in axes.size():
		var axis := axes[i]
		var length := (2.15 if i < 4 else 1.35) * k
		var spear_mesh := CylinderMesh.new()
		spear_mesh.top_radius = 0.0
		spear_mesh.bottom_radius = 0.26 if i < 4 else 0.16
		spear_mesh.height = length
		spear_mesh.radial_segments = 4
		var spear := MeshInstance3D.new()
		spear.name = "CrossSpear%02d" % i
		spear.mesh = spear_mesh
		spear.material_override = _tackle_material(Color.WHITE if i < 4 else Color("ffbe0b"), 3.4)
		spear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spear.position = axis * length * 0.5
		spear.quaternion = Quaternion(Vector3.UP, axis)
		spear.scale = Vector3.ONE * 0.35
		root.add_child(spear)
		var spear_mat := spear.material_override as StandardMaterial3D
		var spear_tw := spear.create_tween().set_parallel(true)
		spear_tw.tween_property(spear, "scale", Vector3.ONE, 0.44).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		spear_tw.tween_property(spear_mat, "albedo_color:a", 0.0, 0.24).set_delay(0.20)

	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.48
	core_mesh.height = 0.96
	var core := MeshInstance3D.new()
	core.name = "PlasmaCore"
	core.mesh = core_mesh
	core.material_override = _tackle_material(Color("ffbe0b", 0.95), 3.8)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.scale = Vector3.ONE * 0.35
	root.add_child(core)
	var core_mat := core.material_override as StandardMaterial3D
	var core_tw := core.create_tween().set_parallel(true)
	core_tw.tween_property(core, "scale", Vector3.ONE * 1.45 * k, 0.44).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	core_tw.tween_property(core_mat, "albedo_color:a", 0.0, 0.30).set_delay(0.14)

	for i in 18:
		var angle := float(i) / 18.0 * TAU + sin(float(i) * 3.1) * 0.20
		var shard_dir := Vector3(sin(angle) * 0.55, cos(angle), cos(angle * 1.7)).normalized()
		var shard_mesh := CylinderMesh.new()
		shard_mesh.top_radius = 0.0
		shard_mesh.bottom_radius = 0.18 + float(i % 3) * 0.07
		shard_mesh.height = 0.42 + float(i % 3) * 0.10
		shard_mesh.radial_segments = 3
		var shard := MeshInstance3D.new()
		shard.name = "ErodedShard%02d" % i
		shard.mesh = shard_mesh
		var shard_color := Color("3d0814") if i % 2 == 0 else Color("ffbe0b")
		shard.material_override = _tackle_material(shard_color, 1.6 if i % 2 == 0 else 2.8)
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard.quaternion = Quaternion(Vector3.UP, shard_dir)
		shard.scale = Vector3.ONE * 0.25
		root.add_child(shard)
		var shard_mat := shard.material_override as StandardMaterial3D
		var shard_tw := shard.create_tween().set_parallel(true)
		shard_tw.tween_property(shard, "position", shard_dir * (1.4 + float(i % 5) * 0.18) * k, 0.44).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		shard_tw.tween_property(shard, "scale", Vector3.ONE * (0.75 if i % 2 == 0 else 0.55), 0.44)
		shard_tw.tween_property(shard_mat, "albedo_color:a", 0.0, 0.22).set_delay(0.22)

	VfxLib.flash_star(fx, pos, Color.WHITE, 3.6 * k, 0.18)
	var gold_ring := _tackle_torus("TacklePlasmaGold", pos, Color("ffbe0b", 0.95), 3.2, 0.35, 1.60 * k, 0.44, dir)
	var orange_ring := _tackle_torus("TacklePlasmaOrange", pos, Color("ff5400", 0.88), 2.8, 0.25, 1.30 * k, 0.44, (dir + Vector3.UP).normalized())
	root.create_tween().tween_interval(0.44).finished.connect(root.queue_free)
	var nodes: Array[Node3D] = [root, gold_ring, orange_ring]
	return nodes


## Retained as an authored option for another move; Tackle routes to B1 above.
## Impacto B2: counter-pop, atmospheric dome and crossed concentric toroidal waves.
## Every principal node is returned so hit-stop can vibrate the whole contact shape.
func _tackle_impact_b2(pos: Vector3, strike_dir: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.45 if big else 1.0
	var dir := strike_dir.normalized() if strike_dir.length_squared() > 0.001 else Vector3.FORWARD
	var nodes: Array[Node3D] = []
	VfxLib.flash_star(fx, pos, Color.WHITE, 3.2 * k, 0.18)
	var counter := _tackle_torus("TackleCounterPop", pos, Color.WHITE, 3.5, 2.4, 0.25, 0.08, dir)
	nodes.append(counter)

	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 1.0
	sphere.radial_segments = 32
	sphere.rings = 16
	var dome := MeshInstance3D.new()
	dome.name = "TackleRefractionDome"
	dome.mesh = sphere
	dome.material_override = _tackle_material(Color("00f5d4", 0.32), 1.8)
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dome.position = pos
	dome.quaternion = Quaternion(Vector3.UP, dir)
	dome.scale = Vector3.ONE * 0.35
	fx.add_child(dome)
	var dome_mat := dome.material_override as StandardMaterial3D
	var dome_tw := dome.create_tween().set_parallel(true)
	dome_tw.tween_property(dome, "scale", Vector3.ONE * 2.8 * k, 0.34).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	dome_tw.tween_property(dome_mat, "albedo_color:a", 0.0, 0.24).set_delay(0.10)
	dome_tw.chain().tween_callback(dome.queue_free)
	nodes.append(dome)

	nodes.append(_tackle_torus("TackleToroVertical", pos, Color("00f5d4", 0.78), 2.8, 0.18, 3.6 * k, 0.38, dir))
	nodes.append(_tackle_torus("TackleToroVerticalCore", pos, Color.WHITE, 3.5, 0.12, 3.25 * k, 0.34, dir))
	var ground := Vector3(pos.x, 0.05, pos.z)
	nodes.append(_tackle_torus("TackleGroundWave", ground, Color("00bbf9", 0.82), 2.7, 0.20, 3.6 * k, 0.38, Vector3.UP))
	nodes.append(_tackle_torus("TackleGroundWaveCore", ground, Color("4361ee", 0.85), 2.5, 0.12, 2.9 * k, 0.34, Vector3.UP))
	return nodes


func _quick_punch_impact(pos: Vector3, dir: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.25 if big else 1.0
	var root := Node3D.new()
	root.name = "QuickPunchBarrage"
	root.position = pos
	fx.add_child(root)
	var nodes: Array[Node3D] = [root]

	# Floor shockwave ring
	var ground := Vector3(pos.x, 0.04, pos.z)
	_shock(ground, Color("63d9ec"), 5.2 * k, 0.38)

	# Primary shock cone and flipbook
	var cone := VfxLib.mesh_slash(fx, pos - dir * 0.15, dir, Color("63d9ec"), 0.0, 1.65 * k, 0.28, "shock_cone", 3.8)
	cone.name = "QuickPunchFinalCone"
	nodes.append(cone)
	VfxLib.flipbook(fx, pos, "impact", Color("d6fa66"), 5.0 * k, 0.32, 20.0, 3.8)
	VfxLib.flash_star(fx, pos, Color.WHITE, 3.2 * k, 0.18)

	# 6 rapid fist micro-bursts around contact point
	for i in 6:
		var off := Vector3(sin(float(i) * 2.4) * 0.55, cos(float(i) * 1.7) * 0.55, sin(float(i) * 1.15) * 0.35)
		var at := pos + off
		var fist := fx._node(fx._sphere(0.22 * k), Color.WHITE if i % 2 == 0 else Color("d6fa66"), at)
		fist.name = "QuickPunchFist%d" % i
		root.add_child(fist)
		nodes.append(fist)
		var delay := float(i) * 0.012
		fx._pop(fist, 0.14, Vector3.ONE * 0.3, Vector3.ONE * 1.6, delay)
		VfxLib.flash_star(fx, at, Color("63d9ec"), 1.2 * k, 0.12)

	VfxLib.burst(fx, pos, {"amount": 26, "life": 0.35, "speed": Vector2(4.0, 9.0), "size": Vector2(0.12, 0.28), "ramp": VfxLib.ramp([Color.WHITE, Color("d6fa66"), Color("63d9ec", 0.0)])})

	var cleanup := root.create_tween()
	cleanup.tween_interval(0.42)
	cleanup.tween_callback(root.queue_free)
	return nodes


func _karate_impact(pos: Vector3, dir: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.2 if big else 1.0
	var slash := VfxLib.mesh_slash(fx, pos + Vector3.UP * 0.45, dir, Color.WHITE, 90.0, 1.55 * k, 0.30, "slash_arc", 3.7)
	slash.name = "KarateGuillotine"
	var column_mesh := CylinderMesh.new()
	column_mesh.top_radius = 0.12
	column_mesh.bottom_radius = 0.62
	column_mesh.height = 5.2 * k
	column_mesh.radial_segments = 12
	var column := MeshInstance3D.new()
	column.name = "KarateLightColumn"
	column.mesh = column_mesh
	column.position = pos + Vector3.UP * 1.6
	column.material_override = _tackle_material(Color("ff624f", 0.70), 3.4)
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.scale = Vector3(0.22, 0.15, 0.22)
	fx.add_child(column)
	var column_mat := column.material_override as StandardMaterial3D
	var column_tw := column.create_tween().set_parallel(true)
	column_tw.tween_property(column, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	column_tw.tween_property(column_mat, "albedo_color:a", 0.0, 0.20).set_delay(0.10)
	column_tw.chain().tween_callback(column.queue_free)
	VfxLib.flipbook(fx, pos, "impact", Color.WHITE, 4.8 * k, 0.28, 0.0, 3.6)
	VfxLib.flipbook(fx, pos, "impact", Color("d6fa66"), 5.8 * k, 0.34, 55.0, 3.3)
	var cracks := Node3D.new()
	cracks.name = "KarateFloorCrack"
	cracks.position = Vector3(pos.x, 0.055, pos.z)
	fx.add_child(cracks)
	for i in 5:
		var line := fx._node(fx._box(Vector3(0.055, 0.025, 1.1 + i * 0.18)), Color("ff624f", 0.82), Vector3.ZERO)
		fx.remove_child(line)
		line.rotation.y = float(i) * TAU / 5.0
		line.position = Vector3(sin(line.rotation.y), 0, cos(line.rotation.y)) * 0.55
		cracks.add_child(line)
	var crack_tw := cracks.create_tween()
	crack_tw.tween_interval(0.38)
	crack_tw.tween_callback(cracks.queue_free)
	var nodes: Array[Node3D] = [slash, column, cracks]
	return nodes


func _brick_break_impact(pos: Vector3, _dir: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.25 if big else 1.0
	var root := Node3D.new()
	root.name = "BrickBreakImpact"
	root.position = pos
	fx.add_child(root)
	VfxLib.flash_star(fx, pos, Color.WHITE, 4.4 * k, 0.20)
	VfxLib.flipbook(fx, pos, "impact", Color("ff624f"), 6.2 * k, 0.38, 15.0, 3.8)
	_shock(Vector3(pos.x, 0.05, pos.z), Color("ff624f"), 6.0 * k, 0.42)
	var cone := VfxLib.mesh_slash(fx, pos + Vector3.UP * 0.4, Vector3.DOWN, Color("ff624f"), 0.0, 1.5 * k, 0.30, "shock_cone", 3.5)
	cone.name = "BrickDownwardCone"

	# 16 crystal glass shards bursting outward with ballistic tumble
	for i in 16:
		var shard := MeshInstance3D.new()
		shard.name = "BrickShard%d" % i
		var tri := PrismMesh.new()
		tri.size = Vector3(0.28 + float(i % 3) * 0.10, 0.38 + float(i % 2) * 0.12, 0.06)
		shard.mesh = tri
		shard.material_override = _tackle_material(Color("63d9ec") if i % 2 == 0 else Color.WHITE, 2.8)
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(shard)
		var angle := float(i) * TAU / 16.0 + sin(float(i) * 3.1) * 0.2
		var speed := randf_range(2.0, 4.2) * k
		var outward := Vector3(cos(angle) * speed, randf_range(0.8, 2.8), sin(angle) * speed)
		var tw_shard := shard.create_tween().set_parallel(true)
		tw_shard.tween_property(shard, "position", outward, 0.42).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw_shard.tween_property(shard, "rotation", Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6)), 0.42)
		tw_shard.tween_property((shard.material_override as StandardMaterial3D), "albedo_color:a", 0.0, 0.22).set_delay(0.20)

	var cleanup := root.create_tween()
	cleanup.tween_interval(0.45)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root, cone]
	return nodes


func _status_impact_move(move_id: String, pos: Vector3) -> bool:
	if BattleFx.normalize_move_id(move_id) != "provocacao":
		return false
	VfxLib.flipbook(fx, pos + Vector3.UP * 0.25, "smoke", Color("2b0938"), 3.8, 0.65, -12.0, 1.8, false)
	VfxLib.flipbook(fx, pos + Vector3.UP * 0.55, "smoke", Color("ff624f"), 3.0, 0.52, 18.0, 2.0)
	VfxLib.flipbook(fx, pos + Vector3.UP * 0.85, "fire", Color("ff4d6d"), 3.2, 0.45, 0.0, 2.4)
	for i in 3:
		var mark := Label3D.new()
		mark.name = "RageMark%d" % i
		mark.text = "💢"
		mark.font_size = 96
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mark.modulate = Color("ff4d6d")
		mark.outline_modulate = Color("2b0938")
		mark.outline_size = 18
		mark.position = pos + Vector3((float(i) - 1.0) * 0.55, 1.55 + float(i % 2) * 0.42, 0.08 * i)
		mark.scale = Vector3.ONE * 0.12
		fx.add_child(mark)
		var tw := mark.create_tween().set_parallel(true)
		tw.tween_property(mark, "scale", Vector3.ONE * 0.82, 0.28).set_delay(float(i) * 0.08).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(mark, "modulate:a", 0.0, 0.25).set_delay(0.48 + float(i) * 0.08)
		tw.chain().tween_callback(mark.queue_free)
	return true


func _confusion_impact(pos: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.2 if big else 1.0
	var root := Node3D.new()
	root.name = "ConfusionGravityField"
	root.position = pos
	fx.add_child(root)
	var nodes: Array[Node3D] = [root]
	for i in 3:
		var ring_pos := pos + Vector3.UP * (float(i) - 1.0) * 0.65
		var ring_color := Color("63d9ec", 0.82) if i % 2 == 0 else Color("bd9afd", 0.86)
		var ring := _tackle_torus("ConfusionCompressionRing%d" % i, ring_pos, ring_color, 2.8, 1.45 - i * 0.14, 0.45, 0.34, Vector3.UP)
		nodes.append(ring)
		var ring_tw := ring.create_tween()
		ring_tw.tween_property(ring, "position:y", pos.y, 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# 6 orbiting dizziness stars / psychic spheres above target's head
	for i in 6:
		var orb := fx._node(fx._sphere(0.18), Color("63d9ec") if i % 2 == 0 else Color("bd9afd"), Vector3.ZERO)
		orb.name = "PsychicOrb%d" % i
		fx.remove_child(orb)
		root.add_child(orb)
		var start_angle := float(i) * TAU / 6.0
		var tw := orb.create_tween()
		tw.tween_method(func(t: float) -> void:
			var angle := start_angle + t * TAU * 3.5
			var radius := 0.85 * k
			orb.position = Vector3(cos(angle) * radius, 1.45 + sin(t * TAU * 2.0 + float(i)) * 0.15, sin(angle) * radius),
			0.0, 1.0, 0.75).set_trans(Tween.TRANS_LINEAR)
		var tw_fade := orb.create_tween()
		tw_fade.tween_interval(0.55)
		tw_fade.tween_property((orb.material_override as StandardMaterial3D), "albedo_color:a", 0.0, 0.20)

	var finish := root.create_tween()
	finish.tween_interval(0.32)
	finish.tween_callback(func() -> void: VfxLib.flash_star(fx, root.global_position, Color("ff36ab"), 4.0 * k, 0.20))
	finish.tween_interval(0.48)
	finish.tween_callback(root.queue_free)
	return nodes


func _psybeam_impact(pos: Vector3, dir: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.25 if big else 1.0
	var root := Node3D.new()
	root.name = "PsybeamPrismImpact"
	root.position = pos
	fx.add_child(root)
	VfxLib.flash_star(fx, pos, Color.WHITE, 4.4 * k, 0.22)
	VfxLib.flipbook(fx, pos, "impact", Color("bd9afd"), 5.2 * k, 0.34, 12.0, 3.5)
	for i in 3:
		var col: Color = [Color("63d9ec"), Color("d6fa66"), Color("bd9afd")][i]
		var ring := _tackle_torus("PsybeamPrismRing%d" % i, pos, Color(col, 0.78), 2.8, 0.18 + i * 0.08, (2.0 + i * 0.38) * k, 0.36, dir)
		root.add_child(ring)
	VfxLib.burst(fx, pos, {"amount": 28, "life": 0.46, "speed": Vector2(4.0, 9.0), "size": Vector2(0.10, 0.28), "ramp": VfxLib.ramp([Color.WHITE, Color("63d9ec"), Color("d6fa66"), Color("bd9afd", 0.0)])})
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.42)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root]
	return nodes


func _add_lightning_path(root: Node3D, top: Vector3, bottom: Vector3, color: Color, offset: float) -> void:
	var points: Array[Vector3] = [top]
	for i in range(1, 8):
		var p := top.lerp(bottom, float(i) / 7.0)
		if i < 7:
			p += Vector3(sin(float(i) * 2.8 + offset) * 0.55, 0, cos(float(i) * 1.9 + offset) * 0.42)
		points.append(p)
	for i in range(1, points.size()):
		var glow := fx._line(points[i - 1], points[i], Color(color, 0.38), 0.42)
		var core := fx._line(points[i - 1], points[i], Color.WHITE, 0.11)
		for segment in [glow, core]:
			fx.remove_child(segment)
			root.add_child(segment)


func _shock_wave_impact(pos: Vector3, big: bool) -> Array[Node3D]:
	var k := 1.25 if big else 1.0
	var root := Node3D.new()
	root.name = "ShockWavePillar"
	fx.add_child(root)
	_add_lightning_path(root, pos + Vector3(-0.45, 8.0, 0.25), pos, Color("63d9ec"), 0.0)
	_add_lightning_path(root, pos + Vector3(0.55, 8.5, -0.35), pos, Color("d6fa66"), 1.7)
	for i in 3:
		var fb := VfxLib.flipbook(fx, pos + Vector3.UP * (0.35 + i * 0.55), "lightning", Color("d6fa66") if i % 2 == 0 else Color("63d9ec"), (4.8 + i * 0.55) * k, 0.30, i * 67.0, 3.8)
		fb.name = "ShockWaveFlipbook%d" % i
	_shock(Vector3(pos.x, 0.05, pos.z), Color("63d9ec"), 6.0 * k, 0.38)
	var cone := VfxLib.mesh_slash(fx, pos, Vector3.UP, Color("d6fa66"), 0.0, 1.55 * k, 0.28, "shock_cone", 3.8)
	cone.name = "ShockWaveUpCone"
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.34)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root, cone]
	return nodes


func _rapid_teleport_impact(pos: Vector3) -> Array[Node3D]:
	var root := Node3D.new()
	root.name = "RapidTeleportImpact"
	root.position = pos
	fx.add_child(root)
	VfxLib.flash_star(fx, pos, Color("63d9ec"), 3.2, 0.18)
	_tackle_torus("TeleportImpactRingCyan", pos, Color("63d9ec", 0.78), 2.8, 0.18, 2.2, 0.30, Vector3.FORWARD)
	_tackle_torus("TeleportImpactRingViolet", pos, Color("bd9afd", 0.78), 2.8, 0.14, 1.8, 0.28, Vector3.UP)
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.32)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root]
	return nodes


## Spawns per-element impact VFX and returns the primary 3D nodes so `fx._hit_stop`
## can vibrate them in sync with the target model.
func _impact(element: Element.Type, pos: Vector3, color: Color, big: bool, dir := Vector3.FORWARD, move_id := "") -> Array[Node3D]:
	var authored := _impact_move(BattleFx.normalize_move_id(move_id), pos, color, big, dir)
	if authored.get("handled", false):
		return authored.get("nodes", []) as Array[Node3D]
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


## Move-authored impacts run before the elemental library. `handled` lets a move
## intentionally return no nodes without accidentally falling through.
func _impact_move(move_id: String, pos: Vector3, _color: Color, big: bool, dir: Vector3) -> Dictionary:
	match move_id:
		"investida", "tackle":
			return {"handled": true, "nodes": _tackle_impact(pos, dir, big)}
		"soco_rapido":
			return {"handled": true, "nodes": _quick_punch_impact(pos, dir, big)}
		"golpe_carate":
			return {"handled": true, "nodes": _karate_impact(pos, dir, big)}
		"quebra_telha":
			return {"handled": true, "nodes": _brick_break_impact(pos, dir, big)}
		"confusao":
			return {"handled": true, "nodes": _confusion_impact(pos, big)}
		"raio_psiquico":
			return {"handled": true, "nodes": _psybeam_impact(pos, dir, big)}
		"onda_choque":
			return {"handled": true, "nodes": _shock_wave_impact(pos, big)}
		"teleporte_rapido":
			return {"handled": true, "nodes": _rapid_teleport_impact(pos)}
		"mordida":
			return {"handled": true, "nodes": _bite_impact(pos, dir)}
		"tiro_areia":
			return {"handled": true, "nodes": _sand_attack_impact(pos, dir)}
		"garra_dragao":
			return {"handled": true, "nodes": _dragon_claw_impact(pos, dir, big)}
		"furia_dragao":
			return {"handled": true, "nodes": _dragon_rage_impact(pos, big)}
		"investida_subterranea", "investida_escavadora":
			return {"handled": true, "nodes": _dig_rush_impact(pos, big)}
		_:
			return {"handled": false, "nodes": []}


func _bite_impact(pos: Vector3, dir: Vector3) -> Array[Node3D]:
	var root := Node3D.new()
	root.name = "BiteSpectralJaw"
	root.position = pos
	fx.add_child(root)
	root.look_at(pos + dir, Vector3.UP)
	var miasma := MeshInstance3D.new()
	miasma.name = "BiteMiasma"
	var sphere := SphereMesh.new()
	sphere.radius = 1.45
	sphere.height = 2.9
	miasma.mesh = sphere
	miasma.material_override = _tackle_material(Color("2b0938", 0.58), 1.7)
	miasma.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	miasma.scale = Vector3.ONE * 0.25
	root.add_child(miasma)
	var miasma_tw := miasma.create_tween().set_parallel(true)
	miasma_tw.tween_property(miasma, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	miasma_tw.tween_property((miasma.material_override as StandardMaterial3D), "albedo_color:a", 0.0, 0.30).set_delay(0.12)

	# Dark shadow gullet inside the jaw
	var throat := MeshInstance3D.new()
	throat.name = "BiteThroat"
	var throat_box := BoxMesh.new()
	throat_box.size = Vector3(2.5, 1.6, 0.35)
	throat.mesh = throat_box
	throat.material_override = _tackle_material(Color("16051f", 0.95), 1.2)
	throat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	throat.position = Vector3(0, 0, -0.15)
	throat.scale = Vector3(0.2, 0.2, 0.2)
	root.add_child(throat)
	var tw_throat := throat.create_tween().set_parallel(true)
	tw_throat.tween_property(throat, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw_throat.tween_property(throat, "scale:y", 0.05, 0.18).set_delay(0.14)
	tw_throat.tween_property((throat.material_override as StandardMaterial3D), "albedo_color:a", 0.0, 0.16).set_delay(0.18)

	for row in 2:
		for i in 5:
			var fang := MeshInstance3D.new()
			fang.name = ("UpperFang%d" if row == 0 else "LowerFang%d") % i
			var tooth := CylinderMesh.new()
			tooth.radial_segments = 4
			tooth.top_radius = 0.04
			tooth.bottom_radius = 0.26
			tooth.height = 1.15
			fang.mesh = tooth
			fang.material_override = _tackle_material(Color("ff624f", 0.96), 3.4)
			fang.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Offset lower fangs along X to interlock with upper fangs
			var x_offset := 0.26 if row == 1 else 0.0
			var x := (float(i) - 2.0) * 0.52 + x_offset
			var open_y := 1.75 if row == 0 else -1.75
			var closed_y := 0.15 if row == 0 else -0.15
			fang.position = Vector3(x, open_y, 0.08 + absf(x) * 0.08)
			fang.rotation.z = PI if row == 0 else 0.0
			root.add_child(fang)
			var tw := fang.create_tween()
			tw.tween_property(fang, "position:y", closed_y, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	VfxLib.flipbook(fx, pos, "impact", Color("ff624f"), 4.4, 0.28, 0.0, 3.4)
	VfxLib.flash_star(fx, pos, Color("ff624f"), 3.2, 0.16)
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.36)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root]
	return nodes


func spawn_bite_windup(pos: Vector3, dir: Vector3, duration: float) -> Node3D:
	var root := Node3D.new()
	root.name = "BiteJawWindup"
	root.position = pos
	root.look_at(pos + dir, Vector3.UP)
	fx.add_child(root)
	var haze := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.25
	sphere.height = 2.5
	haze.mesh = sphere
	haze.material_override = _tackle_material(Color("2b0938", 0.30), 1.2)
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(haze)
	for row in 2:
		for i in 5:
			var fang := MeshInstance3D.new()
			var tooth := CylinderMesh.new()
			tooth.radial_segments = 4
			tooth.top_radius = 0.04
			tooth.bottom_radius = 0.22
			tooth.height = 0.92
			fang.mesh = tooth
			fang.position = Vector3((float(i) - 2.0) * 0.48, 1.55 if row == 0 else -1.55, 0.0)
			fang.rotation.z = PI if row == 0 else 0.0
			fang.material_override = _tackle_material(Color("ff624f", 0.58), 2.2)
			root.add_child(fang)
	root.scale = Vector3.ONE * 0.2
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, minf(duration * 0.70, 0.30)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(duration - minf(duration * 0.70, 0.30), 0.03))
	tw.tween_callback(root.queue_free)
	return root


func _sand_attack_impact(pos: Vector3, dir: Vector3) -> Array[Node3D]:
	var root := Node3D.new()
	root.name = "SandVortexImpact"
	root.position = Vector3(pos.x, 0.05, pos.z)
	fx.add_child(root)
	for i in 3:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.72 + i * 0.25
		torus.outer_radius = 0.82 + i * 0.25
		var ring := MeshInstance3D.new()
		ring.name = "EarthWindRing%d" % i
		ring.mesh = torus
		ring.position.y = 0.35 + i * 0.62
		ring.rotation.x = deg_to_rad(8.0 + i * 11.0)
		ring.material_override = _tackle_material(Color("d98a3c", 0.72), 1.8)
		root.add_child(ring)
		var tw := ring.create_tween().set_parallel(true)
		tw.tween_property(ring, "rotation:y", TAU * (1.0 if i % 2 == 0 else -1.0), 0.52)
		tw.tween_property(ring, "scale", Vector3.ONE * 1.8, 0.52).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	for i in 3:
		VfxLib.flipbook(fx, pos + Vector3(dir.x * i * 0.18, 0.35 + i * 0.58, dir.z * i * 0.18), "smoke", Color("f0c57e"), 2.5 + i * 0.45, 0.62, i * 38.0, 1.3, false)
	_smoke(pos, Color("d98a3c"), 22, Vector2(0.7, 1.8), 0.64, 2.0)

	# Blinding sand burst around target face
	var face_pos := pos + Vector3(0, 0.65, 0)
	var sand_ring := _tackle_torus("SandBlindRing", face_pos, Color("f0c57e", 0.85), 2.2, 0.45, 1.25, 0.48, Vector3.UP)
	root.add_child(sand_ring)
	VfxLib.burst(fx, face_pos, {"amount": 20, "life": 0.45, "speed": Vector2(1.5, 3.5), "size": Vector2(0.12, 0.30), "ramp": VfxLib.ramp([Color("f0c57e"), Color("d98a3c"), Color("d98a3c", 0.0)])})

	var cleanup := root.create_tween()
	cleanup.tween_interval(0.58)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root]
	return nodes


func _dragon_claw_impact(pos: Vector3, dir: Vector3, big: bool) -> Array[Node3D]:
	var root := Node3D.new()
	root.name = "DragonClawImpact"
	root.position = pos
	fx.add_child(root)
	var right := Vector3(dir.z, 0.0, -dir.x).normalized()
	var nodes: Array[Node3D] = [root]
	for i in 3:
		var offset := right * (float(i) - 1.0) * 0.48
		var edge := VfxLib.mesh_slash(fx, pos + offset, dir, Color("63d9ec"), 28.0, 1.55 if big else 1.35, 0.30, "slash_arc", 3.4)
		edge.name = "DragonClawMark%d" % i
		var core := VfxLib.mesh_slash(fx, pos + offset, dir, Color("00f59b"), 28.0, 1.34 if big else 1.18, 0.24, "slash_arc", 4.0)
		core.name = "DragonClawCore%d" % i
		nodes.append_array([edge, core])
	VfxLib.flipbook(fx, pos, "fire", Color("00f59b"), 4.1, 0.42, -18.0, 3.2)
	VfxLib.flipbook(fx, pos + Vector3.UP * 0.4, "fire", Color("63d9ec"), 3.6, 0.38, 32.0, 2.8)
	VfxLib.flash_star(fx, pos, Color.WHITE, 3.4, 0.18)
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.34)
	cleanup.tween_callback(root.queue_free)
	return nodes


func _dragon_rage_impact(pos: Vector3, big: bool) -> Array[Node3D]:
	var root := Node3D.new()
	root.name = "DragonRageSupernova"
	root.position = pos
	fx.add_child(root)
	var dome := MeshInstance3D.new()
	dome.name = "DragonRageDome"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	dome.mesh = sphere
	dome.material_override = _tackle_material(Color("bd9afd", 0.46), 3.0)
	dome.scale = Vector3.ONE * 0.18
	root.add_child(dome)
	var tw := dome.create_tween().set_parallel(true)
	tw.tween_property(dome, "scale", Vector3.ONE * (3.2 if big else 2.7), 0.34).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property((dome.material_override as StandardMaterial3D), "albedo_color:a", 0.0, 0.34)
	VfxLib.flipbook(fx, pos, "fire", Color("63d9ec"), 5.6, 0.48, -24.0, 3.5)
	VfxLib.flipbook(fx, pos, "impact", Color("ff624f"), 5.0, 0.32, 31.0, 3.8)
	var ground := Vector3(pos.x, 0.05, pos.z)
	_shock(ground, Color("63d9ec"), 5.4, 0.38)
	_shock(ground, Color("bd9afd"), 7.0, 0.46)
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.42)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root]
	return nodes


func _dig_rush_impact(pos: Vector3, big: bool) -> Array[Node3D]:
	var ground := Vector3(pos.x, 0.0, pos.z)
	var root := Node3D.new()
	root.name = "DigRushEruption"
	root.position = ground
	fx.add_child(root)
	for i in 10:
		var angle := float(i) * TAU / 10.0
		var height := 1.6 + float(i % 3) * 0.48
		var monolith := MeshInstance3D.new()
		monolith.name = "BasaltMonolith%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(0.42 + float(i % 2) * 0.18, height, 0.52)
		monolith.mesh = box
		monolith.material_override = _tackle_material(Color("5c4033"), 0.65)
		monolith.position = Vector3(cos(angle) * 1.65, -height, sin(angle) * 1.65)
		monolith.rotation = Vector3(sin(angle) * 0.30, -angle, -cos(angle) * 0.30)
		root.add_child(monolith)
		var tw := monolith.create_tween()
		tw.tween_property(monolith, "position:y", height * 0.5, 0.24 + i * 0.008).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	VfxLib.flipbook(fx, ground + Vector3.UP * 1.0, "fire", Color("ff624f"), 5.2 if big else 4.5, 0.40, 0.0, 3.0)
	VfxLib.flipbook(fx, ground + Vector3.UP * 0.65, "smoke", Color("f0c57e"), 5.8, 0.54, 18.0, 1.8, false)
	VfxLib.burst(fx, ground + Vector3.UP * 0.35, {"amount": 34, "life": 0.68, "speed": Vector2(4.0, 10.0), "gravity": Vector3(0, -15, 0), "size": Vector2(0.16, 0.42), "ramp": VfxLib.ramp([Color("f0c57e"), Color("ff624f"), Color("5c4033", 0.0)])})
	_shock(ground, Color("f0c57e"), 6.5, 0.42)
	var cleanup := root.create_tween()
	cleanup.tween_interval(0.64)
	cleanup.tween_callback(root.queue_free)
	var nodes: Array[Node3D] = [root]
	return nodes


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
