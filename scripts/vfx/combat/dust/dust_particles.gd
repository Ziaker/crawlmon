class_name DustParticles
extends Node3D
## Babylon.js `ParticleSystem` port of the option-A Dig / Sand Attack dust (D-1196).
## Every number comes from prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html:
## `spawnBabylonDirtAndDustParticles` (lines 1726-1823) and the two canvas textures it generates
## (`getDustParticleTexture`, lines 1688-1704; `getDirtClodTexture`, lines 1706-1723).
##
## Three own pools drawn with MultiMeshInstance3D billboard quads: dust (150*k), ground haze (95*k)
## and dirt clods (32*k), with k = intensity_scale. No GPUParticles, no decals, no sub-emitters and no
## new shaders; the dust shaders of this folder are untouched.
##
## TIME MAPPING: these systems run with Babylon's default updateSpeed = 0.01 (the HTML never changes
## it, line 1730), so one wall-clock second advances 0.01 * 60 = 0.6 "age units":
##   age += 0.6*dt; pos += dir*0.6*dt; dir += gravity*0.6*dt; angle += angular*0.6*dt;
##   real lifetime = lifeTime/0.6; emission = 0.6*emitRate particles/s; real acceleration = 0.36*gravity.
##
## INDEPENDENCE (D-235): nothing here reads a character, a team, `is_player` or a fixed camera side.
## The emitter is the world position the caller passes, the emit boxes are axis-aligned world offsets
## and the clod quads face the real camera. Sizes are world units (D-334); opacity is the fixed 0.85
## of D-1196 (MATERIALS.BASE_OPACITY).

const MATERIALS := preload("res://scripts/vfx/combat/dust/dust_materials.gd")
const SCALED_UPDATE_PER_SECOND := 0.6  ## updateSpeed 0.01 (Babylon default) * 60 frames; line 1730.
const STOP_AFTER_SEC := 0.240  ## scheduleAfter(240) that stops all three emitters; lines 1813-1817.
const FREE_AFTER_EXTRA_SEC := 1.35  ## dispose at durationSec + 1.35; lines 1818-1822.
const SAND_JET_STOP_AFTER_SEC := 0.340  ## scheduleAfter(340) that stops the sand jet emitters; HTML 2470-2474.
const SAND_JET_FREE_AFTER_EXTRA_SEC := 1.25  ## dispose at durationSec + 1.25; HTML 2475-2480.
const DUST_EMITTER_Y := 0.15  ## emitterPos = pos + (0, 0.15, 0); line 1727.
const HAZE_EMITTER_Y := 0.08  ## haze emitter = pos + (0, 0.08, 0); line 1762.

const DUST_TEXTURE_PX := 128  ## DynamicTexture 128x128; line 1690.
const DUST_TEXTURE_CENTER := 64.0  ## gradient centered at (64, 64); line 1692.
const DUST_GRADIENT_INNER_RADIUS := 8.0  ## createRadialGradient(..., 8, 64, 64, 60); line 1692.
const DUST_GRADIENT_OUTER_RADIUS := 60.0  ## outer radius / arc radius; lines 1692 and 1699.
const CLOD_TEXTURE_PX := 64  ## DynamicTexture 64x64; line 1708.
const CLOD_TEXTURE_SUBSAMPLES := 4  ## our anti-aliasing of the canvas polygon fill; see NOTES.


## One Babylon `ParticleSystem`: the values copied from the HTML plus its live particle pool.
class DustSystem extends RefCounted:
	var node_name := ""
	var capacity := 0
	var intensity := 1.0
	var texture: Texture2D
	var emitter_position := Vector3.ZERO
	var box_min := Vector3.ZERO
	var box_max := Vector3.ZERO
	var color_stops := PackedFloat32Array()
	var colors := PackedColorArray()
	var size_stops := PackedFloat32Array()
	var sizes := PackedFloat32Array()
	var fixed_size_min := 0.0
	var fixed_size_max := 0.0
	var life_min := 0.0
	var life_max := 0.0
	var emit_rate := 0.0
	var gravity := Vector3.ZERO
	var dir_min := Vector3.ZERO
	var dir_max := Vector3.ZERO
	var angular_min := 0.0
	var angular_max := 0.0
	var power_min := 1.0
	var power_max := 1.0
	var billboard := true

	var multimesh_node: MultiMeshInstance3D

	var pos := PackedVector3Array()
	var dir := PackedVector3Array()
	var angle := PackedFloat32Array()
	var angular := PackedFloat32Array()
	var age := PackedFloat32Array()
	var life := PackedFloat32Array()
	var fixed_size := PackedFloat32Array()
	var alive := PackedByteArray()
	var alive_count := 0
	var emit_budget := 0.0

	func allocate() -> void:
		pos.resize(capacity)
		dir.resize(capacity)
		angle.resize(capacity)
		angular.resize(capacity)
		age.resize(capacity)
		life.resize(capacity)
		fixed_size.resize(capacity)
		alive.resize(capacity)


static var _dust_texture: ImageTexture
static var _clod_texture: ImageTexture
static var _quad: QuadMesh

var _systems: Array[DustSystem] = []
var _rng := RandomNumberGenerator.new()
var _elapsed := 0.0
var _stop_after := STOP_AFTER_SEC
var _free_after := 0.0


func _init() -> void:
	_rng.randomize()


## Spawns the HTML's three emitters at `pos` (world units) under `parent`.
## `intensity_scale` is the HTML's `intensityScale` (line 1726); `duration_sec` is the HTML's
## `durationSec`, used only for the dispose time (line 1818). Returns the node that owns the three
## pools, so the caller can watch or free it; it disposes itself at duration_sec + 1.35 s.
static func spawn_dig_dust(parent: Node3D, pos: Vector3, intensity_scale: float = 1.0, duration_sec: float = 0.85) -> DustParticles:
	if parent == null:
		return null
	var k := maxf(intensity_scale, 0.0)
	var sim := DustParticles.new()
	sim.name = "DigDustParticles"
	sim._free_after = duration_sec + FREE_AFTER_EXTRA_SEC
	sim._add_system(_make_dust(pos, k))
	sim._add_system(_make_haze(pos, k))
	sim._add_system(_make_clod(pos, k))
	# World-space particles: the HTML emitter is a plain world Vector3 (line 1727) and the effect must
	# not inherit the parent's scale (D-334).
	sim.top_level = true
	parent.add_child(sim)
	sim.global_position = Vector3.ZERO
	return sim


func _process(delta: float) -> void:
	if _elapsed >= _free_after:
		_stop_and_free()
		return
	var emitting := _elapsed < _stop_after
	_elapsed += delta
	var step := SCALED_UPDATE_PER_SECOND * delta
	var camera_basis := _camera_basis()
	for system in _systems:
		if emitting:
			_emit(system, delta)
		_advance(system, step)
		_draw(system, camera_basis)
	if _elapsed >= _free_after:
		_stop_and_free()
		return
	# Visually finished: emission stopped and every particle dead. The HTML keeps the stopped systems until
	# duration + 1.35 s only to dispose them; nothing is drawn after the last particle dies, so free now.
	if not emitting:
		var any_alive := false
		for system in _systems:
			if system.alive_count > 0:
				any_alive = true
				break
		if not any_alive:
			_stop_and_free()


func _stop_and_free() -> void:
	set_process(false)
	queue_free()


func _emit(system: DustSystem, delta: float) -> void:
	system.emit_budget += system.emit_rate * SCALED_UPDATE_PER_SECOND * delta
	while system.emit_budget >= 1.0:
		if system.alive_count >= system.capacity:
			system.emit_budget = 0.0  # Babylon drops the excess while the pool is full.
			return
		system.emit_budget -= 1.0
		_spawn(system)


func _spawn(system: DustSystem) -> void:
	var index := _free_slot(system)
	if index < 0:
		return
	var power := _rng.randf_range(system.power_min, system.power_max)
	system.pos[index] = system.emitter_position + Vector3(
		_rng.randf_range(system.box_min.x, system.box_max.x),
		_rng.randf_range(system.box_min.y, system.box_max.y),
		_rng.randf_range(system.box_min.z, system.box_max.z))
	system.dir[index] = Vector3(
		_rng.randf_range(system.dir_min.x, system.dir_max.x),
		_rng.randf_range(system.dir_min.y, system.dir_max.y),
		_rng.randf_range(system.dir_min.z, system.dir_max.z)) * power
	system.angle[index] = 0.0
	system.angular[index] = _rng.randf_range(system.angular_min, system.angular_max)
	system.age[index] = 0.0
	system.life[index] = _rng.randf_range(system.life_min, system.life_max)
	system.fixed_size[index] = _rng.randf_range(system.fixed_size_min, system.fixed_size_max)
	system.alive[index] = 1
	system.alive_count += 1


func _free_slot(system: DustSystem) -> int:
	for i in system.capacity:
		if system.alive[i] == 0:
			return i
	return -1


func _advance(system: DustSystem, step: float) -> void:
	var gravity_step := system.gravity * step
	for i in system.capacity:
		if system.alive[i] == 0:
			continue
		var new_age := system.age[i] + step
		if new_age >= system.life[i]:
			system.alive[i] = 0
			system.alive_count -= 1
			continue
		system.age[i] = new_age
		system.pos[i] += system.dir[i] * step  # Babylon moves with the pre-gravity direction.
		system.dir[i] += gravity_step
		system.angle[i] += system.angular[i] * step


func _draw(system: DustSystem, camera_basis: Basis) -> void:
	var mesh := system.multimesh_node.multimesh
	if mesh == null:
		return
	var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0.0, -100000.0, 0.0))
	var transparent := Color(0.0, 0.0, 0.0, 0.0)
	for i in system.capacity:
		if system.alive[i] == 0:
			mesh.set_instance_transform(i, hidden)
			mesh.set_instance_color(i, transparent)
			continue
		var ratio := system.age[i] / maxf(system.life[i], 0.0001)
		var size := _particle_size(system, i, ratio)
		var basis := Basis.from_scale(Vector3.ONE * size)
		if not system.billboard:
			# Godot's billboard modes drop the per-instance rotation, and the HTML spins the clods
			# (minAngularSpeed/maxAngularSpeed, lines 1809-1810), so this pool billboards by hand
			# against the real camera and then rolls in screen space.
			basis = camera_basis * Basis(Vector3(0.0, 0.0, 1.0), system.angle[i]) * basis
		mesh.set_instance_transform(i, Transform3D(basis, system.pos[i]))
		mesh.set_instance_color(i, _gradient_color(system.color_stops, system.colors, ratio))


func _camera_basis() -> Basis:
	if not is_inside_tree():
		return Basis()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Basis()
	return camera.global_transform.basis.orthonormalized()


func _add_system(system: DustSystem) -> void:
	if system.capacity <= 0:
		return
	var node := MultiMeshInstance3D.new()
	node.name = system.node_name
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.use_colors = true
	mesh.mesh = _unit_quad()
	mesh.instance_count = system.capacity
	node.multimesh = mesh
	node.material_override = _make_material(system.texture, system.billboard)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb = _world_bounds(system)
	system.multimesh_node = node
	system.allocate()
	var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0.0, -100000.0, 0.0))
	for i in system.capacity:
		mesh.set_instance_transform(i, hidden)
		mesh.set_instance_color(i, Color(0.0, 0.0, 0.0, 0.0))
	add_child(node)
	_systems.append(system)


static func _world_bounds(system: DustSystem) -> AABB:
	var reach := 10.0 * system.intensity + 1.5
	var half := Vector3(reach, reach * 0.8, reach)
	var center := system.emitter_position + Vector3(0.0, half.y * 0.5, 0.0)
	return AABB(center - half, half * 2.0)


static func _make_material(texture: Texture2D, billboard: bool) -> StandardMaterial3D:
	# BLENDMODE_STANDARD of the HTML (lines 1750, 1779 and 1805) is plain alpha blending.
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.albedo_texture = texture
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true  # Babylon multiplies raw bytes (gamma space)
	if billboard:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.billboard_keep_scale = true
	return material


static func _unit_quad() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	return _quad


static func _particle_size(system: DustSystem, index: int, ratio: float) -> float:
	if system.size_stops.is_empty():
		return system.fixed_size[index]  # minSize/maxSize, constant per particle (lines 1800-1801).
	return _gradient_value(system.size_stops, system.sizes, ratio)


# --- systems, literally from the HTML ------------------------------------------------------------


static func _make_dust(pos: Vector3, k: float) -> DustSystem:
	var op := MATERIALS.BASE_OPACITY  # line 1728.
	var system := DustSystem.new()
	system.node_name = "DigDustPS"  # line 1730.
	system.intensity = k
	system.capacity = int(floor(150.0 * k))  # line 1730.
	system.texture = dust_texture()  # line 1731.
	system.emitter_position = pos + Vector3(0.0, DUST_EMITTER_Y, 0.0)  # line 1727.
	system.box_min = Vector3(-0.75 * k, 0.0, -0.75 * k)  # line 1733.
	system.box_max = Vector3(0.75 * k, 0.25, 0.75 * k)  # line 1734.
	system.color_stops = PackedFloat32Array([0.0, 0.10, 0.38, 0.72, 1.0])  # lines 1736-1740.
	system.colors = PackedColorArray([
		Color(0.92, 0.83, 0.68, 0.0),
		Color(0.90, 0.80, 0.64, 0.68 * op),
		Color(0.76, 0.62, 0.45, 0.46 * op),
		Color(0.54, 0.42, 0.28, 0.18 * op),
		Color(0.36, 0.27, 0.18, 0.0),
	])
	system.size_stops = PackedFloat32Array([0.0, 0.30, 0.70, 1.0])  # lines 1742-1745.
	system.sizes = PackedFloat32Array([0.42 * k, 1.05 * k, 1.75 * k, 2.35 * k])
	system.life_min = 0.55  # line 1747.
	system.life_max = 1.25  # line 1748.
	system.emit_rate = 280.0 * k  # line 1749.
	system.gravity = Vector3(0.0, 0.55, 0.0)  # line 1751.
	system.dir_min = Vector3(-2.8 * k, 1.4 * k, -2.8 * k)  # line 1752.
	system.dir_max = Vector3(2.8 * k, 3.8 * k, 2.8 * k)  # line 1753.
	system.angular_min = -1.8  # line 1754.
	system.angular_max = 1.8  # line 1755.
	system.power_min = 0.85  # line 1756.
	system.power_max = 2.15  # line 1757.
	system.billboard = true
	return system


static func _make_haze(pos: Vector3, k: float) -> DustSystem:
	var op := MATERIALS.BASE_OPACITY  # line 1728.
	var system := DustSystem.new()
	system.node_name = "DigGroundHazePS"  # line 1760.
	system.intensity = k
	system.capacity = int(floor(95.0 * k))  # line 1760.
	system.texture = dust_texture()  # line 1761.
	system.emitter_position = pos + Vector3(0.0, HAZE_EMITTER_Y, 0.0)  # line 1762.
	system.box_min = Vector3(-1.05 * k, 0.0, -1.05 * k)  # line 1763.
	system.box_max = Vector3(1.05 * k, 0.15, 1.05 * k)  # line 1764.
	system.color_stops = PackedFloat32Array([0.0, 0.16, 0.50, 0.82, 1.0])  # lines 1766-1770.
	system.colors = PackedColorArray([
		Color(0.86, 0.76, 0.60, 0.0),
		Color(0.84, 0.73, 0.56, 0.34 * op),
		Color(0.68, 0.55, 0.40, 0.22 * op),
		Color(0.48, 0.38, 0.26, 0.08 * op),
		Color(0.35, 0.27, 0.18, 0.0),
	])
	system.size_stops = PackedFloat32Array([0.0, 0.50, 1.0])  # lines 1772-1774.
	system.sizes = PackedFloat32Array([0.85 * k, 1.85 * k, 2.75 * k])
	system.life_min = 0.75  # line 1776.
	system.life_max = 1.48  # line 1777.
	system.emit_rate = 180.0 * k  # line 1778.
	system.gravity = Vector3(0.0, 0.12, 0.0)  # line 1780.
	system.dir_min = Vector3(-3.4 * k, 0.2, -3.4 * k)  # line 1781; the 0.2 is not scaled.
	system.dir_max = Vector3(3.4 * k, 0.9, 3.4 * k)  # line 1782; the 0.9 is not scaled.
	system.angular_min = -0.9  # line 1783.
	system.angular_max = 0.9  # line 1784.
	system.power_min = 0.6  # line 1785.
	system.power_max = 1.5  # line 1786.
	system.billboard = true
	return system


static func _make_clod(pos: Vector3, k: float) -> DustSystem:
	var op := MATERIALS.BASE_OPACITY  # line 1728.
	var system := DustSystem.new()
	system.node_name = "DigClodPS"  # line 1789.
	system.intensity = k
	system.capacity = int(floor(32.0 * k))  # line 1789.
	system.texture = clod_texture()  # line 1790.
	system.emitter_position = pos + Vector3(0.0, DUST_EMITTER_Y, 0.0)  # lines 1727 and 1791.
	system.box_min = Vector3(-0.4 * k, 0.0, -0.4 * k)  # line 1792.
	system.box_max = Vector3(0.4 * k, 0.2, 0.4 * k)  # line 1793.
	system.color_stops = PackedFloat32Array([0.0, 0.12, 0.60, 1.0])  # lines 1795-1798.
	system.colors = PackedColorArray([
		Color(0.68, 0.52, 0.34, 0.0),
		Color(0.65, 0.48, 0.30, 0.58 * op),
		Color(0.45, 0.32, 0.19, 0.24 * op),
		Color(0.28, 0.19, 0.11, 0.0),
	])
	system.fixed_size_min = 0.06 * k  # line 1800.
	system.fixed_size_max = 0.13 * k  # line 1801.
	system.life_min = 0.42  # line 1802.
	system.life_max = 0.82  # line 1803.
	system.emit_rate = 90.0 * k  # line 1804.
	system.gravity = Vector3(0.0, -14.5, 0.0)  # line 1806.
	system.dir_min = Vector3(-2.6 * k, 3.2 * k, -2.6 * k)  # line 1807.
	system.dir_max = Vector3(2.6 * k, 6.2 * k, 2.6 * k)  # line 1808.
	system.angular_min = -6.0  # line 1809.
	system.angular_max = 6.0  # line 1810.
	system.power_min = 1.0  # lines 1789-1811 never set emitPower: Babylon's default is 1.
	system.power_max = 1.0
	system.billboard = false  # manual billboard so the HTML spin survives; see _draw.
	return system


## Dense billowing golden-sand plume, the HTML's 'sandJetCloudPS' (189/2388-2418): unlike the Dig plume
## its direction is the real start->end axis scaled by `dist`, so the jet travels to the target and the
## result is the same from any attacker, team or side (D-235).
static func _make_sand_cloud(start: Vector3, aim: Vector3, dist: float) -> DustSystem:
	var op := MATERIALS.BASE_OPACITY  # HTML 2382: state.shaderOpacity.
	var system := DustSystem.new()
	system.node_name = "SandJetCloudPS"  # HTML 2388.
	system.intensity = 1.0
	system.capacity = 190  # HTML 2388.
	system.texture = dust_texture()  # HTML 2389.
	system.emitter_position = start  # HTML 2385: emitterNode at startPos.
	system.box_min = Vector3(-0.28, -0.15, -0.28)  # HTML 2391.
	system.box_max = Vector3(0.28, 0.25, 0.28)  # HTML 2392.
	system.color_stops = PackedFloat32Array([0.0, 0.10, 0.40, 0.75, 1.0])  # HTML 2394-2398.
	system.colors = PackedColorArray([
		Color(0.98, 0.92, 0.72, 0.0),
		Color(0.95, 0.84, 0.56, 0.66 * op),
		Color(0.84, 0.68, 0.42, 0.44 * op),
		Color(0.62, 0.48, 0.28, 0.18 * op),
		Color(0.42, 0.30, 0.18, 0.0),
	])
	system.size_stops = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])  # HTML 2400-2403.
	system.sizes = PackedFloat32Array([0.38, 1.05, 1.85, 2.45])
	system.life_min = 0.48  # HTML 2405.
	system.life_max = 0.92  # HTML 2406.
	system.emit_rate = 280.0  # HTML 2407.
	system.gravity = Vector3(0.0, 0.35, 0.0)  # HTML 2409.
	system.dir_min = aim * dist * 1.25 + Vector3(-1.65, -0.35, -1.65)  # HTML 2411-2412.
	system.dir_max = aim * dist * 1.75 + Vector3(1.65, 1.25, 1.65)  # HTML 2411 and 2413.
	system.angular_min = -2.2  # HTML 2414.
	system.angular_max = 2.2  # HTML 2415.
	system.power_min = 0.95  # HTML 2416.
	system.power_max = 1.45  # HTML 2417.
	system.billboard = true
	return system


## Lingering ground-skimming sand haze, the HTML's 'sandGroundHazePS' (110/2421-2443). Its emitter is
## the plain startPos (HTML 2423), not a TransformNode.
static func _make_sand_haze(start: Vector3, aim: Vector3, dist: float) -> DustSystem:
	var op := MATERIALS.BASE_OPACITY  # HTML 2382.
	var system := DustSystem.new()
	system.node_name = "SandGroundHazePS"  # HTML 2421.
	system.intensity = 1.0
	system.capacity = 110  # HTML 2421.
	system.texture = dust_texture()  # HTML 2422.
	system.emitter_position = start  # HTML 2423.
	system.box_min = Vector3(-0.6, -0.1, -0.6)  # HTML 2424.
	system.box_max = Vector3(0.6, 0.2, 0.6)  # HTML 2425.
	system.color_stops = PackedFloat32Array([0.0, 0.18, 0.55, 1.0])  # HTML 2427-2430.
	system.colors = PackedColorArray([
		Color(0.92, 0.82, 0.62, 0.0),
		Color(0.88, 0.76, 0.54, 0.34 * op),
		Color(0.72, 0.58, 0.38, 0.20 * op),
		Color(0.45, 0.34, 0.20, 0.0),
	])
	system.size_stops = PackedFloat32Array([0.0, 0.50, 1.0])  # HTML 2432-2434.
	system.sizes = PackedFloat32Array([0.75, 1.75, 2.65])
	system.life_min = 0.65  # HTML 2436.
	system.life_max = 1.30  # HTML 2437.
	system.emit_rate = 180.0  # HTML 2438.
	system.gravity = Vector3(0.0, 0.15, 0.0)  # HTML 2440.
	system.dir_min = aim * dist * 0.85 + Vector3(-2.2, 0.1, -2.2)  # HTML 2441.
	system.dir_max = aim * dist * 1.35 + Vector3(2.2, 0.85, 2.2)  # HTML 2442.
	system.angular_min = 0.0  # The HTML never sets angular speed here: Babylon's default is 0.
	system.angular_max = 0.0
	system.power_min = 1.0  # Neither emitPower is set in the HTML: Babylon's default is 1.
	system.power_max = 1.0
	system.billboard = true
	return system


## Airborne silica clods and grains, the HTML's 'sandClodPS' (65/2446-2468). Like the Dig clods it
## billboards by hand so the HTML spin (HTML 2466-2467) survives; gravity is -9.5, not -14.5.
static func _make_sand_clod(start: Vector3, aim: Vector3, dist: float) -> DustSystem:
	var op := MATERIALS.BASE_OPACITY  # HTML 2382.
	var system := DustSystem.new()
	system.node_name = "SandClodPS"  # HTML 2446.
	system.intensity = 1.0
	system.capacity = 65  # HTML 2446.
	system.texture = clod_texture()  # HTML 2447.
	system.emitter_position = start  # HTML 2448.
	system.box_min = Vector3(-0.2, -0.1, -0.2)  # HTML 2449.
	system.box_max = Vector3(0.2, 0.2, 0.2)  # HTML 2450.
	system.color_stops = PackedFloat32Array([0.0, 0.12, 0.60, 1.0])  # HTML 2452-2455.
	system.colors = PackedColorArray([
		Color(0.98, 0.88, 0.52, 0.0),
		Color(0.92, 0.75, 0.38, 0.62 * op),
		Color(0.68, 0.50, 0.24, 0.24 * op),
		Color(0.42, 0.28, 0.12, 0.0),
	])
	system.fixed_size_min = 0.06  # HTML 2457.
	system.fixed_size_max = 0.13  # HTML 2458.
	system.life_min = 0.38  # HTML 2459.
	system.life_max = 0.72  # HTML 2460.
	system.emit_rate = 140.0  # HTML 2461.
	system.gravity = Vector3(0.0, -9.5, 0.0)  # HTML 2463.
	system.dir_min = aim * dist * 1.45 + Vector3(-1.4, 0.5, -1.4)  # HTML 2464.
	system.dir_max = aim * dist * 2.05 + Vector3(1.4, 2.2, 1.4)  # HTML 2465.
	system.angular_min = -7.0  # HTML 2466.
	system.angular_max = 7.0  # HTML 2467.
	system.power_min = 1.0  # emitPower is not set in the HTML: Babylon's default is 1.
	system.power_max = 1.0
	system.billboard = false  # Manual billboard so the HTML spin survives; see _draw.
	return system

## Sand Attack jet stream (spawnSilicaJetParticleStream, HTML 2378-2481): the same three pools as the Dig
## dust, re-pointed down the real start->end axis with the HTML's own counts (190 / 110 / 65), colors,
## sizes, lifetimes and emit rates. Stops at 0.340 s (HTML 2470) and frees itself at duration_sec + 1.25
## (HTML 2475), so nothing is left behind. `start` and `end` are in `parent`'s space.
static func spawn_sand_jet(parent: Node3D, start: Vector3, end: Vector3, duration: float = 0.92) -> void:
	if parent == null:
		return
	var offset := end - start
	var dist := offset.length()
	var aim := offset.normalized() if dist > 0.0001 else Vector3.ZERO
	var sim := DustParticles.new()
	sim.name = "SandJetParticleStream"
	sim._stop_after = SAND_JET_STOP_AFTER_SEC
	sim._free_after = duration + SAND_JET_FREE_AFTER_EXTRA_SEC
	sim._add_system(_make_sand_cloud(start, aim, dist))
	sim._add_system(_make_sand_haze(start, aim, dist))
	sim._add_system(_make_sand_clod(start, aim, dist))
	# World-space particles: the HTML emitter is a world position and the stream must not inherit the
	# parent's transform or scale (D-334).
	sim.top_level = true
	parent.add_child(sim)
	sim.global_position = Vector3.ZERO


# --- textures, generated in code (no files) -----------------------------------------------------


## `getDustParticleTexture` (lines 1688-1704): radial gradient on a 128x128 canvas.
static func dust_texture() -> ImageTexture:
	if _dust_texture != null:
		return _dust_texture
	var size := DUST_TEXTURE_PX
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var stops := PackedFloat32Array([0.0, 0.45, 0.80, 1.0])  # lines 1693-1696.
	var colors := PackedColorArray([
		Color(235.0 / 255.0, 214.0 / 255.0, 182.0 / 255.0, 0.95),
		Color(186.0 / 255.0, 154.0 / 255.0, 112.0 / 255.0, 0.65),
		Color(122.0 / 255.0, 94.0 / 255.0, 62.0 / 255.0, 0.22),
		Color(80.0 / 255.0, 58.0 / 255.0, 36.0 / 255.0, 0.0),
	])
	var inner := DUST_GRADIENT_INNER_RADIUS
	var outer := DUST_GRADIENT_OUTER_RADIUS
	var center := DUST_TEXTURE_CENTER
	for y in size:
		for x in size:
			var distance := Vector2(float(x) + 0.5 - center, float(y) + 0.5 - center).length()
			if distance > outer:  # ctx.arc(64, 64, 60, ...) clip; line 1699.
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue
			# The canvas gradient spans the annulus 8..60, not 0..60 (line 1692).
			var t := clampf((distance - inner) / (outer - inner), 0.0, 1.0)
			image.set_pixel(x, y, _gradient_color(stops, colors, t))
	image.generate_mipmaps()
	_dust_texture = ImageTexture.create_from_image(image)
	return _dust_texture


## `getDirtClodTexture` (lines 1706-1723): white hexagon on a 64x64 transparent canvas.
static func clod_texture() -> ImageTexture:
	if _clod_texture != null:
		return _clod_texture
	var size := CLOD_TEXTURE_PX
	var polygon := PackedVector2Array([  # lines 1712-1717, in canvas pixels.
		Vector2(14.0, 12.0),
		Vector2(48.0, 8.0),
		Vector2(58.0, 32.0),
		Vector2(44.0, 56.0),
		Vector2(18.0, 54.0),
		Vector2(6.0, 32.0),
	])
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var sub := CLOD_TEXTURE_SUBSAMPLES
	var samples := float(sub * sub)
	for y in size:
		for x in size:
			var covered := 0.0
			for sy in sub:
				for sx in sub:
					var point := Vector2(
						float(x) + (float(sx) + 0.5) / sub,
						float(y) + (float(sy) + 0.5) / sub)
					if Geometry2D.is_point_in_polygon(point, polygon):
						covered += 1.0
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, covered / samples))
	image.generate_mipmaps()
	_clod_texture = ImageTexture.create_from_image(image)
	return _clod_texture


# --- gradients (Babylon lerps linearly between stops) -------------------------------------------


static func _gradient_color(stops: PackedFloat32Array, colors: PackedColorArray, t: float) -> Color:
	var count := mini(stops.size(), colors.size())
	if count == 0:
		return Color(1.0, 1.0, 1.0, 1.0)
	if t <= stops[0]:
		return colors[0]
	for i in range(1, count):
		if t <= stops[i]:
			var span := stops[i] - stops[i - 1]
			if span <= 0.0:
				return colors[i]
			return colors[i - 1].lerp(colors[i], (t - stops[i - 1]) / span)
	return colors[count - 1]


static func _gradient_value(stops: PackedFloat32Array, values: PackedFloat32Array, t: float) -> float:
	var count := mini(stops.size(), values.size())
	if count == 0:
		return 0.0
	if t <= stops[0]:
		return values[0]
	for i in range(1, count):
		if t <= stops[i]:
			var span := stops[i] - stops[i - 1]
			if span <= 0.0:
				return values[i]
			return lerpf(values[i - 1], values[i], (t - stops[i - 1]) / span)
	return values[count - 1]
