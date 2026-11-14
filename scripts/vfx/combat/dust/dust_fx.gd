class_name DustFx
extends RefCounted
## Option-A Dig dust library (D-1196), ported literally from
## prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html.
##
## Each static function builds the effect under the received `parent`; `origin`/`pos` are positions
## in that parent's space. The subtree is driven by a local Driver that reproduces spawnAnimatedNode
## (HTML 1471) plus the lifecycle loop at HTML 3083-3096: it stays hidden until `delay`,
## progress = (age - delay) / duration, the update runs with (progress, driver, delta), and the
## driver queue_free()s itself and every child when the local age reaches the duration. The driver
## clock is the local replacement for the HTML's global `state.clockTime` used as uTime.
##
## Sizes, colors, counts and timings are the HTML's own (D-334/D-335/D-337/D-1196). Nothing is keyed
## to a character, team or side: every origin comes from the caller's real attacker/target points
## (D-235). Shaders and materials come from DustMaterials/DustMeshes and the emitters from
## DustParticles; none is recreated here. No GPUParticles, no decals and no sub-emitters.

const MATERIALS := preload("res://scripts/vfx/combat/dust/dust_materials.gd")
const MESHES := preload("res://scripts/vfx/combat/dust/dust_meshes.gd")
const PARTICLES := preload("res://scripts/vfx/combat/dust/dust_particles.gd")

## HTML 2198: BABYLON.StandardMaterial diffuseColor '#6b4c2b'.
const MOUND_COLOR := Color("#6b4c2b")
const RIDGE_SHADER := preload("res://shaders/dust_burrow_ridge.gdshader")
const RIDGE_WIDTH := 4.4  ## metros (escolha da IA por delegação do criador)
const RIDGE_HEIGHT := 1.8

## Generic animated driver: the Godot equivalent of spawnAnimatedNode (HTML 1471) and the
## lifecycle loop (HTML 3083-3096).
class Driver extends Node3D:
	var duration_sec: float = 1.0
	var delay_sec: float = 0.0
	var clock: float = 0.0
	var age: float = 0.0
	var started: bool = false
	var on_start: Callable = Callable()
	var on_update: Callable = Callable()

	func _ready() -> void:
		visible = delay_sec <= 0.0

	func _process(delta: float) -> void:
		clock += delta
		age += delta
		if not started:
			if age < delay_sec:
				return
			started = true
			visible = true
			if on_start.is_valid():
				on_start.call()
		var local_age: float = age - delay_sec
		var progress: float = clampf(local_age / duration_sec, 0.0, 1.0)
		if on_update.is_valid():
			on_update.call(progress, self, delta)
		if local_age >= duration_sec:
			queue_free()


## Volumetric dust cloud ring (spawn3DVolumetricDustCloudRing, HTML 1896-1960), including the
## DustParticles call of HTML 1953-1959. Puffs are segments-12 spheres; Godot's SphereMesh has no
## segment option, so radial_segments = rings = 12 (Babylon's 12 latitude strips).
static func cloud_ring(
	parent: Node3D,
	origin: Vector3,
	puff_count: int,
	ring_radius: float,
	puff_scale: float,
	duration: float,
	delay: float,
	palette: Dictionary
) -> Node3D:
	var driver := _make_driver(parent, origin, duration, delay, func() -> void:
		PARTICLES.spawn_dig_dust(parent, origin, puff_scale, duration)
	)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var puffs: Array[Dictionary] = []
	for i in range(puff_count):
		var seed_value: float = (i + 1) * 1.37
		var diameter: float = (0.85 + float(i % 3) * 0.25) * puff_scale
		var sphere := SphereMesh.new()
		sphere.radius = diameter * 0.5
		sphere.height = diameter
		sphere.radial_segments = 28  # Babylon CreateSphere segments=12: 14 latitude x 28 longitude steps (435 verts measured)
		sphere.rings = 14
		var puff := MeshInstance3D.new()
		puff.name = "DustPuff3D_%d" % i
		puff.mesh = sphere
		var mat: ShaderMaterial = MATERIALS.cloud(seed_value, palette)
		puff.material_override = mat
		driver.add_child(puff)
		puffs.append({
			"mesh": puff,
			"mat": mat,
			# HTML 1913: (Math.random() - 0.5) * 0.25 -> +-0.125 rad.
			"angle": (float(i) / float(puff_count)) * TAU + (rng.randf() - 0.5) * 0.25,
			"start_r": ring_radius * (0.45 + float(i % 2) * 0.25),
			"expand_speed": (1.35 + float(i % 3) * 0.45) * puff_scale,
			"rise_speed": (0.75 + float(i % 2) * 0.45) * puff_scale,
			"rot_speed": (1.0 if i % 2 == 0 else -1.0) * (1.2 + float(i % 3) * 0.5),
			"base_scale": (0.7 + float(i % 3) * 0.22) * puff_scale,
		})
	driver.on_update = func(progress: float, node: Driver, dt: float) -> void:
		for entry: Dictionary in puffs:
			var puff_mat: ShaderMaterial = entry["mat"]
			var puff_node: MeshInstance3D = entry["mesh"]
			puff_mat.set_shader_parameter("u_time", node.clock)
			puff_mat.set_shader_parameter("u_progress", progress)
			puff_mat.set_shader_parameter("u_base_opacity", MATERIALS.BASE_OPACITY)
			puff_mat.set_shader_parameter("u_edge_feather", MATERIALS.EDGE_FEATHER)
			var ease_out: float = 1.0 - pow(1.0 - progress, 2.2)
			var angle: float = entry["angle"]
			var start_r: float = entry["start_r"]
			var current_r: float = start_r + ease_out * float(entry["expand_speed"])
			var current_y: float = 0.28 * puff_scale + ease_out * float(entry["rise_speed"])
			puff_node.position = Vector3(cos(angle) * current_r, current_y, sin(angle) * current_r)
			var rot_speed: float = entry["rot_speed"]
			puff_node.rotation.z += dt * rot_speed
			puff_node.rotation.y += dt * (rot_speed * 0.6)
			var base_scale: float = entry["base_scale"]
			var grow: float = 0.35 + 0.85 * (progress / 0.22) if progress < 0.22 else 1.20 + (progress - 0.22) * 0.55
			puff_node.scale = Vector3(base_scale * grow * 1.15, base_scale * grow * 0.85, base_scale * grow * 1.15)
	return driver


## Translucent dust curtain veil + ground dust shock ring
## (spawnTranslucentDustVeilAndShockRing, HTML 1826-1893). Two open cylinders with the veil shader
## and one flattened torus with the cloud shader, seed 4.2 (HTML 1865).
static func veil_and_shock_ring(
	parent: Node3D,
	origin: Vector3,
	radius: float,
	height: float,
	duration: float,
	delay: float,
	palette: Dictionary
) -> Node3D:
	var driver := _make_driver(parent, origin, duration, delay)

	# Open frustum with Babylon's UV convention (v = 0 at the bottom, 1 at the top): Godot's CylinderMesh
	# puts v in 0..0.5 from the top, which the veil shader's vertical profile would misread.
	var outer_mesh: ArrayMesh = MESHES.open_frustum(radius * 2.5, radius * 1.4, height, 32) # HTML 1830-1835.
	var veil_outer := MeshInstance3D.new()
	veil_outer.name = "DustVeilOuter"
	veil_outer.mesh = outer_mesh
	veil_outer.position.y = height * 0.48 # HTML 1838.
	var mat_outer: ShaderMaterial = MATERIALS.veil(palette)
	veil_outer.material_override = mat_outer
	driver.add_child(veil_outer)

	var inner_mesh: ArrayMesh = MESHES.open_frustum(radius * 1.6, radius * 1.9, height * 0.78, 28) # HTML 1843-1848.
	var veil_inner := MeshInstance3D.new()
	veil_inner.name = "DustVeilInner"
	veil_inner.mesh = inner_mesh
	veil_inner.position.y = height * 0.38 # HTML 1851.
	var mat_inner: ShaderMaterial = MATERIALS.veil(palette)
	veil_inner.material_override = mat_inner
	driver.add_child(veil_inner)

	var ring_mesh := TorusMesh.new()
	var ring_middle: float = radius * 1.5 * 0.5 # HTML 1857: diameter = radius * 1.5.
	ring_mesh.inner_radius = ring_middle - 0.24 * 0.5 # HTML 1858: thickness 0.24.
	ring_mesh.outer_radius = ring_middle + 0.24 * 0.5
	ring_mesh.rings = 36 # HTML 1859: tessellation 36.
	ring_mesh.ring_segments = 36 # Babylon's tessellation also sets the tube cross-section.
	var shock_ring := MeshInstance3D.new()
	shock_ring.name = "DustShockTorus"
	shock_ring.mesh = ring_mesh
	shock_ring.position.y = 0.12 # HTML 1862.
	shock_ring.scale = Vector3(1.0, 0.35, 1.0) # HTML 1863.
	var mat_ring: ShaderMaterial = MATERIALS.cloud(4.2, palette) # HTML 1865.
	shock_ring.material_override = mat_ring
	driver.add_child(shock_ring)

	driver.on_update = func(progress: float, node: Driver, dt: float) -> void:
		var veils: Array[ShaderMaterial] = [mat_outer, mat_inner]
		for index in range(veils.size()):
			var veil_mat: ShaderMaterial = veils[index]
			veil_mat.set_shader_parameter("u_time", node.clock + float(index) * 3.1) # HTML 1870.
			veil_mat.set_shader_parameter("u_progress", progress)
			veil_mat.set_shader_parameter("u_base_opacity", MATERIALS.BASE_OPACITY * (0.9 if index == 0 else 0.7)) # HTML 1873.
			veil_mat.set_shader_parameter("u_edge_feather", MATERIALS.EDGE_FEATHER)

		mat_ring.set_shader_parameter("u_time", node.clock) # HTML 1877.
		mat_ring.set_shader_parameter("u_progress", minf(1.0, progress * 1.15)) # HTML 1878.
		mat_ring.set_shader_parameter("u_base_opacity", MATERIALS.BASE_OPACITY * 0.55) # HTML 1880.
		mat_ring.set_shader_parameter("u_edge_feather", MATERIALS.EDGE_FEATHER)

		var radial_expand: float = 0.65 + pow(progress, 0.65) * 1.35 # HTML 1883.
		veil_outer.scale = Vector3(radial_expand, 0.8 + progress * 0.4, radial_expand) # HTML 1884.
		veil_outer.rotation.y += dt * 1.8 # HTML 1885.

		veil_inner.scale = Vector3(radial_expand * 0.9, 0.85 + progress * 0.3, radial_expand * 0.9) # HTML 1887.
		veil_inner.rotation.y -= dt * 2.4 # HTML 1888.

		var ring_expand: float = 0.6 + pow(progress, 0.58) * 2.1 # HTML 1890.
		shock_ring.scale = Vector3(ring_expand, 0.32 * (1.0 - progress * 0.6), ring_expand) # HTML 1891.
	return driver


## Lotus crown dust shell (createLotusCrownShellMesh at HTML 961-996). "entry" is the burrow entry
## (HTML 2134-2156) and "impact" is the eruption wave (HTML 2228-2249). `target_scale` only scales
## the impact wave, exactly as the HTML does; the entry ignores it.
static func lotus_crown(
	parent: Node3D,
	pos: Vector3,
	variant: String,
	target_scale: float,
	delay: float
) -> Node3D:
	match variant:
		"entry":
			return _lotus_crown_entry(parent, pos, delay)
		"impact":
			return _lotus_crown_impact(parent, pos, target_scale, delay)
	push_error("DustFx.lotus_crown: unknown variant '%s' (expected \"entry\" or \"impact\")." % variant)
	return null


static func _lotus_crown_entry(parent: Node3D, pos: Vector3, delay: float) -> Node3D:
	var driver := _make_driver(parent, pos, 0.68, delay) # HTML 2144: duration 0.68.
	var crown := MeshInstance3D.new()
	crown.name = "DigEntryDustCrown"
	crown.mesh = MESHES.lotus_crown(48, 28) # HTML 2134: 48 x 28.
	crown.position = Vector3(0.0, 0.04, 0.0) # HTML 2137.
	var mat: ShaderMaterial = MATERIALS.crown_shell(
		Color("#e6d2b5"), Color("#b39268"), Color("#634b30") # HTML 2139-2141.
	)
	crown.material_override = mat
	driver.add_child(crown)

	driver.on_update = func(progress: float, _node: Driver, dt: float) -> void:
		var burst: float = minf(1.0, progress / 0.35) # HTML 2145.
		var erode: float = maxf(0.0, (progress - 0.28) / 0.72) # HTML 2146.
		mat.set_shader_parameter("u_base_opacity", MATERIALS.BASE_OPACITY * 0.82) # HTML 2148.
		mat.set_shader_parameter("u_edge_feather", MATERIALS.EDGE_FEATHER) # HTML 2149.
		mat.set_shader_parameter("u_open_progress", burst) # HTML 2150.
		mat.set_shader_parameter("u_dissolve", erode * 0.92) # HTML 2151.
		mat.set_shader_parameter("u_master_alpha", 1.0 - pow(erode, 1.3)) # HTML 2152.
		crown.scale = Vector3(0.65 + burst * 0.75, 0.38 + burst * 0.45, 0.65 + burst * 0.75) # HTML 2153.
		crown.rotation.y += dt * 2.5 # HTML 2154.
	return driver


static func _lotus_crown_impact(parent: Node3D, pos: Vector3, target_scale: float, delay: float) -> Node3D:
	var driver := _make_driver(parent, pos, 0.88, delay) # HTML 2238: duration 0.88.
	var crown := MeshInstance3D.new()
	crown.name = "DigEruptDustWaveA"
	crown.mesh = MESHES.lotus_crown(64, 34) # HTML 2228: 64 x 34.
	crown.position = Vector3(0.0, 0.05, 0.0) # HTML 2231.
	var mat: ShaderMaterial = MATERIALS.crown_shell(
		Color("#f0dfc8"), Color("#c2a278"), Color("#6e5233") # HTML 2233-2235.
	)
	crown.material_override = mat
	driver.add_child(crown)

	driver.on_update = func(progress: float, _node: Driver, dt: float) -> void:
		var burst: float = minf(1.0, progress / 0.32) # HTML 2239.
		var erode: float = maxf(0.0, (progress - 0.25) / 0.75) # HTML 2240.
		mat.set_shader_parameter("u_base_opacity", MATERIALS.BASE_OPACITY * 0.85) # HTML 2242.
		mat.set_shader_parameter("u_edge_feather", MATERIALS.EDGE_FEATHER) # HTML 2243.
		mat.set_shader_parameter("u_open_progress", burst) # HTML 2244.
		mat.set_shader_parameter("u_dissolve", erode * 0.92) # HTML 2245.
		mat.set_shader_parameter("u_master_alpha", 1.0 - pow(erode, 1.35)) # HTML 2246.
		crown.scale = Vector3(
			(0.75 + burst * 0.95) * target_scale,
			(0.42 + burst * 0.55) * target_scale,
			(0.75 + burst * 0.95) * target_scale
		) # HTML 2247.
		crown.rotation.y -= dt * 2.2 # HTML 2248.
	return driver


## Burrow ridge along the Dig's path (D-1196, trajeto): the ground strip from `start` to `end` rises into a mound that
## travels with the hidden digger (head reaches `end` after `travel_time`), splits into a trench behind it and leaves
## churned soil that fades over `tail_time`. Shader: shaders/dust_burrow_ridge.gdshader. Not in the HTML.
static func burrow_ridge(parent: Node3D, start: Vector3, end: Vector3, travel_time: float, tail_time: float, delay: float) -> Node3D:
	var flat := Vector3(end.x - start.x, 0.0, end.z - start.z)
	var length := maxf(flat.length(), 0.5)
	var yaw := atan2(flat.x, flat.z)
	var total := travel_time + tail_time
	var driver := _make_driver(parent, Vector3(start.x, 0.02, start.z), total, delay)
	driver.rotation.y = yaw
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "BurrowRidge"
	mesh_node.mesh = MESHES.ribbon_grid(RIDGE_WIDTH, length, 14, int(ceil(length * 5.0)))
	var mat := ShaderMaterial.new()
	mat.shader = RIDGE_SHADER
	mat.set_shader_parameter("u_length", length)
	mat.set_shader_parameter("u_width", RIDGE_WIDTH)
	mat.set_shader_parameter("u_height", RIDGE_HEIGHT)
	mesh_node.material_override = mat
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	driver.add_child(mesh_node)
	driver.on_update = func(progress: float, node: Driver, _dt: float) -> void:
		var t: float = progress * total
		mat.set_shader_parameter("u_head", clampf(t / travel_time, 0.0, 1.0))
		mat.set_shader_parameter("u_time", node.clock)
		var fade_start := travel_time + tail_time * 0.35
		mat.set_shader_parameter("u_fade", 1.0 - smoothstep(fade_start, total, t))
	return driver


## Tremor soil mound (HTML 2187-2206): a flat-shaded sphere calotte with diameterX/Z 1.15,
## diameterY 0.55 and slice 0.55. Slicing at 0.55 of PI is slightly past a hemisphere, so the rim
## sits just under the ground (y = 0.275 * cos(0.55 * PI) = -0.043), exactly like Babylon's open
## slice mesh. Duração 0.52, escala e alpha literais (HTML 2202-2205).
static func soil_mound(parent: Node3D, pos: Vector3, delay: float) -> Node3D:
	var driver := _make_driver(parent, pos, 0.52, delay) # HTML 2202: duration 0.52.
	var mound := MeshInstance3D.new()
	mound.name = "SoilMound"
	mound.mesh = _babylon_sphere_slice(8, 1.15, 0.55, 1.15, 0.55) # HTML 2187-2193.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = MOUND_COLOR # HTML 2198.
	mat.metallic_specular = 0.04 # Babylon specularColor (0.04, 0.03, 0.02), HTML 2199.
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mound.material_override = mat
	driver.add_child(mound)

	driver.on_update = func(progress: float, _node: Driver, _dt: float) -> void:
		var env: float = sin(progress * PI) # HTML 2203.
		mound.scale = Vector3(0.85 + progress * 0.35, maxf(0.02, env), 0.85 + progress * 0.35) # HTML 2204.
		var color := MOUND_COLOR
		color.a = env * MATERIALS.BASE_OPACITY # HTML 2205.
		mat.albedo_color = color
	return driver


## Creates the driver, sets its local space and parents it. `origin` is in the parent's space.
static func _make_driver(
	parent: Node3D,
	origin: Vector3,
	duration: float,
	delay: float,
	on_start: Callable = Callable()
) -> Driver:
	var driver := Driver.new()
	driver.name = "DustFxDriver"
	driver.duration_sec = duration
	driver.delay_sec = delay
	driver.on_start = on_start
	driver.position = origin
	parent.add_child(driver)
	return driver


## Babylon MeshBuilder.CreateSphere with diameterX/Y/Z and slice, read from SphereBuilder:
## angleZ = normalizedZ * PI * slice, totalZRotationSteps = 2 + segments and
## totalYRotationSteps = 2 * totalZRotationSteps. The HTML calls convertToFlatShadedMesh
## (HTML 2194), so every triangle gets its own outward face normal.
static func _babylon_sphere_slice(
	segments: int,
	diameter_x: float,
	diameter_y: float,
	diameter_z: float,
	slice: float
) -> ArrayMesh:
	var rx: float = diameter_x * 0.5
	var ry: float = diameter_y * 0.5
	var rz: float = diameter_z * 0.5
	var lat_steps: int = 2 + segments
	var lon_steps: int = 2 * lat_steps
	var rows: Array[PackedVector3Array] = []
	for i in range(lat_steps + 1):
		var angle_z: float = float(i) / float(lat_steps) * PI * slice
		var row := PackedVector3Array()
		for j in range(lon_steps + 1):
			var angle_y: float = float(j) / float(lon_steps) * TAU
			row.append(Vector3(
				rx * sin(angle_z) * cos(angle_y),
				ry * cos(angle_z),
				-rz * sin(angle_z) * sin(angle_y)
			))
		rows.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(lat_steps):
		for j in range(lon_steps):
			var a: Vector3 = rows[i][j]
			var b: Vector3 = rows[i][j + 1]
			var c: Vector3 = rows[i + 1][j]
			var d: Vector3 = rows[i + 1][j + 1]
			_add_flat_triangle(st, a, b, c, _ellipsoid_normal((a + b + c) / 3.0, rx, ry, rz))
			_add_flat_triangle(st, c, b, d, _ellipsoid_normal((c + b + d) / 3.0, rx, ry, rz))
	return st.commit()


static func _ellipsoid_normal(point: Vector3, rx: float, ry: float, rz: float) -> Vector3:
	return Vector3(point.x / (rx * rx), point.y / (ry * ry), point.z / (rz * rz)).normalized()


## Flat triangle with an outward normal. The order is flipped to clockwise when needed (Godot's
## front-face convention), as in HtmlMeshLib._tri, so back-face culling keeps the mound closed.
static func _add_flat_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 1e-14:
		return
	if normal.dot(outward) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	normal = normal.normalized()
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(c)
	st.set_normal(normal)
	st.add_vertex(b)
