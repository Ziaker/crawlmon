class_name DustFxGround
extends RefCounted
## Physical ground pieces of the option-A Dig dust (D-1196), ported literally from
## prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html:
##   boulder_barrage -> spawn3DBoulderBarrage (HTML 1962-2025) + createChunkyRockMesh (HTML 1675-1683)
##   crater          -> spawnPhysicalCraterDecal (HTML 2027-2074)
##
## The three flat-shaded Babylon polyhedra (type0 tetrahedron, type1 octahedron, type2 dodecahedron,
## size 1) are read once at runtime from prototypes/vfx_atelier/babylon_polyhedra.json and multiplied
## by each rock's size; that file lives under prototypes/, inside res://, and is never copied here.
## If it cannot be read the rocks are skipped and an error is reported instead of inventing vertices.
##
## Each function adds one Driver under `parent` (DustFx._make_driver) and returns it: hidden until
## `delay`, progress = (age - delay) / duration, motion in on_update(progress, node, dt), freed at the
## end. Sizes, colors, counts, alpha and timings are the HTML's own (D-334/D-335/D-337/D-1196);
## opacity 0.85 and feather 0.22 are the fixed values of D-1196.
##
## Independence (D-235): nothing here reads a character, a team, `is_player` or a fixed side; the only
## inputs are `parent`, the `origin`/`pos` in that parent's space and the numbers below.
## No GPUParticles, no CPUParticles, no decals and no sub-emitters.

const DUST_FX := preload("res://scripts/vfx/combat/dust/dust_fx.gd")
const MATERIALS := preload("res://scripts/vfx/combat/dust/dust_materials.gd")

## Babylon.js polyhedra used by createChunkyRockMesh (size 1, multiplied by each rock's size).
const POLYHEDRA := preload("res://scripts/vfx/combat/dust/dust_polyhedra.gd")

## HTML 1966: rockColors, picked per rock by i % 4 (HTML 1979).
const ROCK_COLOR_0 := Color("#5c4028")
const ROCK_COLOR_1 := Color("#785638")
const ROCK_COLOR_2 := Color("#4a3520")
const ROCK_COLOR_3 := Color("#69594a")
const ROCK_SPECULAR := 0.06  ## HTML 1970: specularColor (0.06, 0.05, 0.04).
const GRAVITY := 22.0  ## HTML 2005.
const BOUNCE_Y := -0.44  ## HTML 2010.
const BOUNCE_XZ := 0.68  ## HTML 2011-2012.
const SHRINK_START := 0.72  ## HTML 2019: shrink starts after 0.72.
const ALPHA_START := 0.58  ## HTML 2020: alpha fade starts after 0.58.

## HTML 2042-2044: craterRimDirtMat (#5c4028, specular 0.04 / 0.03 / 0.02).
const CRATER_COLOR := Color("#5c4028")
const CRATER_SPECULAR := 0.04
const CRATER_GROUND_Y := 0.03  ## HTML 2037.
const RIM_ROCK_COUNT := 6  ## HTML 2047.


## Flat-shaded boulders with gravity, floor bounce, tumble and alpha fade
## (spawn3DBoulderBarrage, HTML 1962-2025). The HTML root has no position (HTML 1964), so the driver
## stays at Vector3.ZERO and every rock moves in absolute parent-space coordinates, exactly like
## `root` plus the absolute `b.pos` of the HTML.
static func boulder_barrage(
	parent: Node3D,
	origin: Vector3,
	count: int,
	speed_range: Vector2,
	size_range: Vector2,
	duration: float,
	delay: float
) -> Node3D:
	var driver: Node3D = DUST_FX._make_driver(parent, Vector3.ZERO, duration, delay)  # HTML 1964 / 2003.

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var boulders: Array[Dictionary] = []
	for i in range(count):
		var sz: float = size_range.x + rng.randf() * (size_range.y - size_range.x)  # HTML 1976.
		var rock := MeshInstance3D.new()
		rock.name = "boulder3D-%d" % i  # HTML 1977.
		rock.mesh = _chunky_rock_mesh(sz, i)  # createChunkyRockMesh, HTML 1675-1683.
		var mat: StandardMaterial3D = _rock_material(_rock_color(i % 4), ROCK_SPECULAR)  # HTML 1967-1972 / 1979.
		rock.material_override = mat
		driver.add_child(rock)

		var sx: float = 0.75 + rng.randf() * 0.65  # HTML 1982.
		var sy: float = 0.65 + rng.randf() * 0.65  # HTML 1983.
		var sz_axis: float = 0.75 + rng.randf() * 0.65  # HTML 1984.
		rock.scale = Vector3(sx, sy, sz_axis)  # HTML 1985.

		var theta: float = (float(i) / float(count)) * TAU + (rng.randf() - 0.5) * 0.45  # HTML 1987.
		var h_speed: float = speed_range.x + rng.randf() * (speed_range.y - speed_range.x)  # HTML 1988.
		var vy: float = 5.2 + rng.randf() * 7.2  # HTML 1989.
		var start: Vector3 = origin + Vector3(
			(rng.randf() - 0.5) * 0.7,
			0.22 + rng.randf() * 0.35,
			(rng.randf() - 0.5) * 0.7
		)  # HTML 1996.
		boulders.append({
			"mesh": rock,
			"mat": mat,
			"base_scale": Vector3(sx, sy, sz_axis),  # HTML 1994.
			"radius": sz * 0.7,  # HTML 1995.
			"pos": start,
			"vel": Vector3(cos(theta) * h_speed * 0.58, vy, sin(theta) * h_speed * 0.58),  # HTML 1997.
			"rot_vel": Vector3(
				(rng.randf() - 0.5) * 14,
				(rng.randf() - 0.5) * 14,
				(rng.randf() - 0.5) * 14
			),  # HTML 1998: +-7 rad/s per axis.
		})

	driver.on_update = func(progress: float, _node: Node3D, dt: float) -> void:
		for entry: Dictionary in boulders:
			var vel: Vector3 = entry["vel"]
			var pos: Vector3 = entry["pos"]
			vel.y -= GRAVITY * dt  # HTML 2005.
			pos += vel * dt  # HTML 2006.

			var radius: float = entry["radius"]
			if pos.y < radius and vel.y < 0.0:  # HTML 2008.
				pos.y = radius  # HTML 2009.
				vel.y *= BOUNCE_Y  # HTML 2010.
				vel.x *= BOUNCE_XZ  # HTML 2011.
				vel.z *= BOUNCE_XZ  # HTML 2012.

			entry["vel"] = vel
			entry["pos"] = pos

			var rock_node: MeshInstance3D = entry["mesh"]
			rock_node.position = pos  # HTML 2016.
			var rot_vel: Vector3 = entry["rot_vel"]
			rock_node.rotation += rot_vel * dt  # HTML 2017.

			var shrink: float = maxf(0.01, 1.0 - (progress - SHRINK_START) / 0.28) if progress > SHRINK_START else 1.0  # HTML 2019.
			var alpha_fade: float = maxf(0.0, 1.0 - (progress - ALPHA_START) / 0.42) if progress > ALPHA_START else 1.0  # HTML 2020.

			var rock_mat: StandardMaterial3D = entry["mat"]
			var color := rock_mat.albedo_color
			color.a = alpha_fade * MATERIALS.BASE_OPACITY  # HTML 2021.
			rock_mat.albedo_color = color

			var base_scale: Vector3 = entry["base_scale"]
			rock_node.scale = base_scale * shrink  # HTML 2022.
	return driver


## Torn-earth crater decal with subtle rim pebbles (spawnPhysicalCraterDecal, HTML 2027-2074).
## The HTML root carries `pos` (HTML 2030), so the driver sits at `pos` and every child keeps the
## HTML's local offsets; the ground disc is radius * 2.1 at y = 0.03 (HTML 2032-2037).
static func crater(
	parent: Node3D,
	pos: Vector3,
	radius: float,
	duration: float,
	delay: float = 0.0
) -> Node3D:
	var driver: Node3D = DUST_FX._make_driver(parent, pos, duration, delay)  # HTML 2029-2030 / 2061.

	var disc := MeshInstance3D.new()
	disc.name = "digCraterDisc"  # HTML 2033.
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.1, radius * 2.1)  # HTML 2032-2035.
	disc.mesh = plane
	disc.position = Vector3(0.0, CRATER_GROUND_Y, 0.0)  # HTML 2037.
	var crater_mat: ShaderMaterial = MATERIALS.crater()  # createDigCraterMaterial, HTML 2039.
	disc.material_override = crater_mat
	driver.add_child(disc)

	var rim_rocks: Array[Dictionary] = []
	for i in range(RIM_ROCK_COUNT):
		var ang: float = (float(i) / float(RIM_ROCK_COUNT)) * TAU + float(i % 2) * 0.2  # HTML 2049.
		var sz: float = 0.11 + float(i % 2) * 0.04  # HTML 2050.
		var rock := MeshInstance3D.new()
		rock.name = "craterRimRock-%d" % i  # HTML 2051.
		rock.mesh = _chunky_rock_mesh(sz, i)  # createChunkyRockMesh, HTML 1675-1683 / 2051.
		var dirt: StandardMaterial3D = _rock_material(CRATER_COLOR, CRATER_SPECULAR)  # HTML 2042-2044; one per rock (HTML 2052).
		rock.material_override = dirt
		var dist: float = radius * (0.48 + float(i % 2) * 0.08)  # HTML 2053.
		rock.position = Vector3(cos(ang) * dist, sz * 0.35, sin(ang) * dist)  # HTML 2054.
		rock.scale = Vector3(1.2, 0.65, 1.0)  # HTML 2055.
		rock.rotation = Vector3(float(i) * 0.4, ang, (float(i % 2) - 0.5) * 0.4)  # HTML 2056.
		driver.add_child(rock)
		rim_rocks.append({"mesh": rock, "mat": dirt})

	driver.on_update = func(progress: float, _node: Node3D, _dt: float) -> void:
		# HTML 2062 also sets uTime, but the ported dust_crater shader ignores it: left at its default.
		crater_mat.set_shader_parameter("u_progress", progress)  # HTML 2063.
		crater_mat.set_shader_parameter("u_base_opacity", MATERIALS.BASE_OPACITY)  # HTML 2064: 0.85.
		crater_mat.set_shader_parameter("u_edge_feather", MATERIALS.EDGE_FEATHER)  # HTML 2065: 0.22.

		var pop_in: float = progress / 0.12 if progress < 0.12 else 1.0  # HTML 2067.
		var sink_out: float = maxf(0.01, 1.0 - (progress - SHRINK_START) / 0.28) if progress > SHRINK_START else 1.0  # HTML 2068.
		var rim_alpha: float = sink_out * MATERIALS.BASE_OPACITY  # HTML 2069.

		for entry: Dictionary in rim_rocks:
			var rock_node: MeshInstance3D = entry["mesh"]
			rock_node.scale.y = 0.65 * pop_in * sink_out  # HTML 2071.

			var dirt_mat: StandardMaterial3D = entry["mat"]
			var color := dirt_mat.albedo_color
			color.a = rim_alpha
			dirt_mat.albedo_color = color
	return driver


## Earth ridge slab that rises and tilts along the Dig's path (ridgeWedge, HTML 2170-2185, option C of the
## HTML, chosen for the trajectory by the creator's delegation: "me surpreenda, sigo qualquer recomendação").
## Box 0.95 x 0.45 x 0.65 (times `scale_k`), color #6b4c2b, yaw toward `aim`, tilt 0.45 rad, env = sin(p*PI):
## y = env * 0.25 * scale_k and alpha = env * 0.85 over 0.55 s (HTML 2180-2184).
static func ridge_wedge(parent: Node3D, pos: Vector3, aim: Vector3, scale_k: float, delay: float) -> Node3D:
	var driver: Node3D = DUST_FX._make_driver(parent, pos, 0.55, delay)  # HTML 2180: duration 0.55.
	var wedge := MeshInstance3D.new()
	wedge.name = "ridgeWedge"
	var box := BoxMesh.new()
	box.size = Vector3(0.95, 0.45, 0.65) * scale_k  # HTML 2170.
	wedge.mesh = box
	var mat: StandardMaterial3D = _rock_material(Color("#6b4c2b"), 0.03)  # HTML 2177-2178.
	wedge.material_override = mat
	var flat := Vector3(aim.x - pos.x, 0.0, aim.z - pos.z)
	var yaw := atan2(flat.x, flat.z) if flat.length() > 0.001 else 0.0
	wedge.rotation = Vector3(0.45, yaw, 0.0)  # HTML 2174-2175: lookAt(end) then rotation.x = -0.45 (Godot sign).
	driver.add_child(wedge)
	driver.on_update = func(progress: float, _node: Node3D, _dt: float) -> void:
		var env: float = sin(progress * PI)  # HTML 2181.
		wedge.position.y = env * 0.25 * scale_k  # HTML 2182.
		var color := mat.albedo_color
		color.a = env * MATERIALS.BASE_OPACITY  # HTML 2183.
		mat.albedo_color = color
	return driver


## createChunkyRockMesh (HTML 1675-1683): one flat-shaded Babylon polyhedron of `size`. The type
## follows the HTML's own seed rule (HTML 1677): seed % 3 == 0 -> 2 (dodecahedron), else seed % 2 == 0
## -> 1 (octahedron), else 0 (tetrahedron). Vertices are multiplied by `size`, as the HTML passes
## `size` to CreatePolyhedron; each face is wound counter-clockwise seen from outside and gets one
## normal, through DustFx._add_flat_triangle with the face centroid as the outward direction (the
## polyhedra are convex around the origin, so the centroid points outwards).
static func _chunky_rock_mesh(size: float, seed_value: int) -> ArrayMesh:
	var kind: int = 2 if seed_value % 3 == 0 else (1 if seed_value % 2 == 0 else 0)  # HTML 1677.
	var data: Dictionary = _polyhedra_data()
	var key: String = "type%d" % kind
	if not data.has(key):
		push_error("DustFxGround: no '%s' polyhedron; the rock is skipped." % key)
		return ArrayMesh.new()
	var entry: Dictionary = data[key]
	var vertices: Array = entry["vertices"]
	var triangles: Array = entry["triangles"]

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var k: int = 0
	while k + 2 < triangles.size():
		var a: Vector3 = _vertex_at(vertices, int(triangles[k])) * size
		var b: Vector3 = _vertex_at(vertices, int(triangles[k + 1])) * size
		var c: Vector3 = _vertex_at(vertices, int(triangles[k + 2])) * size
		DUST_FX._add_flat_triangle(st, a, b, c, (a + b + c) / 3.0)
		k += 3
	return st.commit()


static func _vertex_at(vertices: Array, index: int) -> Vector3:
	var v: Array = vertices[index]
	return Vector3(float(v[0]), float(v[1]), float(v[2]))


## HTML 1966: the four rock colors, picked by i % 4 (HTML 1979).
static func _rock_color(index: int) -> Color:
	match index:
		0:
			return ROCK_COLOR_0
		1:
			return ROCK_COLOR_1
		2:
			return ROCK_COLOR_2
	return ROCK_COLOR_3


## Rock material (HTML 1967-1972 and 2042-2044): diffuse albedo, a low specular tint and ALPHA
## blending so the per-frame fade can write albedo_color.a (the HTML sets `mat.alpha`).
static func _rock_material(albedo: Color, specular: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic_specular = specular
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


## The three Babylon polyhedra, embedded in dust_polyhedra.gd (same data as babylon_polyhedra.json).
static func _polyhedra_data() -> Dictionary:
	return POLYHEDRA.DATA
