class_name HubAltar
extends Node3D
## D-1266: circular magic altar of grey stone for the hub centre, entrance and exit of the
## expeditions. Two stepped round tiers with sloped sides (walkable) and, carved INTO the top
## tier, the exact star (pentagram) of the summon circle (scripts/hub/hub_summon_fx.gd: first tip
## toward -Z, 72 degree steps). The star is a recess in the stone: not above it, not outside it.
## Procedural mesh + trimesh collision, no asset files.

const BASE_Y := 0.0  ## ground collision top: the altar rises from it
const INNER_RATIO := 0.381966  ## inner vertex radius / tip radius of a regular pentagram
const TIERS := [
	# [bottom radius, top radius, height, grey]
	[2.50, 2.22, 0.17, 0.62],
	[2.06, 1.86, 0.15, 0.72],
]
const STAR_TIP_R := 1.58  ## star tips stay well inside the top tier (radius 1.86)
const STAR_DEPTH := 0.05
const EDGE_SPLIT := 8  ## samples per star edge (also the angular samples of every circle)
const STONE_BASE := Color(0.50, 0.51, 0.53)

var top_y := 0.0
var forest_details := false  ## D-1266: moss, roots, cracks and rubble for the Murky Forest
var tone := 1.0  ## brightness multiplier of the stone (the forest's lights are much brighter than the hub's)
var _ang: PackedFloat32Array = PackedFloat32Array()
var _star: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	build()


func build() -> void:
	for child in get_children():
		child.queue_free()
	_sample_star()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := BASE_Y
	var last_r := 0.0
	for k in TIERS.size():
		var tier: Array = TIERS[k]
		_add_tier_sides(st, float(tier[0]), float(tier[1]), y, y + float(tier[2]), float(tier[3]))
		y += float(tier[2])
		last_r = float(tier[1])
		if k < TIERS.size() - 1:
			# Flat step between this top and the next tier's bottom (a visible ledge).
			_add_ring(st, last_r, float(TIERS[k + 1][0]), y, float(tier[3]) * 1.04)
	top_y = y
	_add_top_with_star(st, last_r, y, float(TIERS[TIERS.size() - 1][3]))
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "AltarStone"
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.WHITE
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.rim_enabled = true
	mat.rim = 0.12
	mat.rim_tint = 0.4
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	body.name = "AltarBody"
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)
	if forest_details:
		_add_forest_details()


## The 10-vertex star outline (tips and inner vertices alternating, first tip toward -Z) with each
## edge subdivided; `_ang` holds the angle of every sample so circles can share them (no cracks).
func _sample_star() -> void:
	_star = PackedVector2Array()
	_ang = PackedFloat32Array()
	var corners: Array[Vector2] = []
	for i in 10:
		var rr: float = STAR_TIP_R if i % 2 == 0 else STAR_TIP_R * INNER_RATIO
		corners.append(Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * rr)
	for i in 10:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 10]
		for s in EDGE_SPLIT:
			var p: Vector2 = a.lerp(b, float(s) / float(EDGE_SPLIT))
			_star.append(p)
			_ang.append(p.angle())


func _circle_pt(i: int, r: float) -> Vector2:
	return Vector2.from_angle(_ang[i]) * r


func _color(grey: float, k: int) -> Color:
	var v: float = 1.0 + 0.045 * sin(float(k) * 12.9898)  # faint per-face variation, deterministic
	var c := STONE_BASE * (grey / 0.5) * v * tone
	c.a = 1.0
	return c


func _add_tier_sides(st: SurfaceTool, r0: float, r1: float, y0: float, y1: float, grey: float) -> void:
	var n := _ang.size()
	for i in n:
		var j: int = (i + 1) % n
		var a := _v3(_circle_pt(i, r0), y0)
		var b := _v3(_circle_pt(j, r0), y0)
		var c := _v3(_circle_pt(j, r1), y1)
		var d := _v3(_circle_pt(i, r1), y1)
		var col := _color(grey * 0.9, i)
		_tri(st, a, b, c, col)
		_tri(st, a, c, d, col)


## Flat annulus between two radii at height y (the ledge of a step).
func _add_ring(st: SurfaceTool, r_out: float, r_in: float, y: float, grey: float) -> void:
	var n := _ang.size()
	for i in n:
		var j: int = (i + 1) % n
		var col := _color(grey, i + 7)
		_tri(st, _v3(_circle_pt(i, r_in), y), _v3(_circle_pt(i, r_out), y), _v3(_circle_pt(j, r_out), y), col)
		_tri(st, _v3(_circle_pt(i, r_in), y), _v3(_circle_pt(j, r_out), y), _v3(_circle_pt(j, r_in), y), col)


## Top disc with the star carved in: stone between the star outline and the circle, a lowered
## star floor, and the walls of the recess.
func _add_top_with_star(st: SurfaceTool, r: float, y: float, grey: float) -> void:
	var n := _ang.size()
	var floor_y: float = y - STAR_DEPTH
	for i in n:
		var j: int = (i + 1) % n
		var pi_: Vector2 = _star[i]
		var pj: Vector2 = _star[j]
		var ci: Vector2 = _circle_pt(i, r)
		var cj: Vector2 = _circle_pt(j, r)
		var col := _color(grey, i + 3)
		_tri(st, _v3(pi_, y), _v3(ci, y), _v3(cj, y), col)
		_tri(st, _v3(pi_, y), _v3(cj, y), _v3(pj, y), col)
		var wall := _color(grey * 0.78, i)
		_tri(st, _v3(pi_, y), _v3(pj, y), _v3(pj, floor_y), wall)
		_tri(st, _v3(pi_, y), _v3(pj, floor_y), _v3(pi_, floor_y), wall)
		_tri(st, Vector3(0.0, floor_y, 0.0), _v3(pi_, floor_y), _v3(pj, floor_y), _color(grey * 0.7, i + 11))


func _v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)


## Adds a triangle with Godot's clockwise-front winding, facing up (flat faces) or away from
## the axis (sloped and vertical faces; recess walls are vertical and face the star axis).
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a)
	var pts := [a, b, c]
	if absf(n.y) > 0.5 * n.length():
		if n.y < 0.0:
			pts = [a, c, b]
	else:
		var centre := (a + b + c) / 3.0
		if n.dot(Vector3(centre.x, 0.0, centre.z)) < 0.0:
			pts = [a, c, b]
	pts.reverse()
	for p in pts:
		st.set_color(col)
		st.add_vertex(p)


# --- Forest weathering (purely visual, no collision) --------------------------------------

func _toon(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Height of the altar surface at radius r (profile of the two tiers).
func _height_at(r: float) -> float:
	var r0: float = float(TIERS[0][0])
	var r1: float = float(TIERS[0][1])
	var h0: float = float(TIERS[0][2])
	var r2: float = float(TIERS[1][0])
	var r3: float = float(TIERS[1][1])
	var h1: float = h0 + float(TIERS[1][2])
	if r >= r0:
		return 0.0
	if r >= r1:
		return h0 * (r0 - r) / (r0 - r1)
	if r >= r2:
		return h0
	if r >= r3:
		return h0 + (h1 - h0) * (r2 - r) / (r2 - r3)
	return h1


func _add_forest_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261116
	var moss_a := _toon(Color(0.12, 0.42, 0.26))
	var moss_b := _toon(Color(0.18, 0.55, 0.34))
	var root_m := _toon(Color(0.13, 0.08, 0.075))
	var crack_m := _toon(Color(0.09, 0.09, 0.11))
	var rubble_m := _toon(Color(0.30, 0.31, 0.33))
	# Moss patches: flat noisy blobs on the ledge, the top ring and the sloped sides' lower edge.
	for i in 22:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(1.64, 2.46)
		if r > 1.86 and r < 2.06:
			r = rng.randf_range(2.06, 2.2)  # keep patches on the flat ledge, not mid-slope
		var size: float = rng.randf_range(0.10, 0.34)
		_add_blob(Vector2.from_angle(ang) * r, _height_at(r) + 0.012, size, moss_a if i % 2 == 0 else moss_b, rng)
	# Roots crawling in from outside, over both tiers, then fading into the top ring.
	for k in 6:
		_add_root(rng.randf() * TAU, root_m, rng)
	# Cracks across the top ring (away from the star recess).
	for k in 5:
		_add_crack(rng.randf() * TAU, crack_m, rng)
	# Rubble at the foot.
	for k in 9:
		var a: float = rng.randf() * TAU
		var rr: float = rng.randf_range(2.6, 3.3)
		var box := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var sz: float = rng.randf_range(0.10, 0.26)
		bm.size = Vector3(sz, sz * rng.randf_range(0.5, 0.9), sz * rng.randf_range(0.8, 1.2))
		box.mesh = bm
		box.material_override = rubble_m
		box.position = Vector3(cos(a) * rr, sz * 0.3, sin(a) * rr)
		box.rotation = Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4)
		add_child(box)


func _add_blob(centre: Vector2, y: float, size: float, mat: Material, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 12
	var pts: Array[Vector3] = []
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var rr: float = size * rng.randf_range(0.6, 1.0)
		pts.append(Vector3(centre.x + cos(a) * rr, y, centre.y + sin(a) * rr))
	var mid := Vector3(centre.x, y + 0.025, centre.y)
	for i in n:
		st.add_vertex(mid)
		st.add_vertex(pts[(i + 1) % n])
		st.add_vertex(pts[i])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)


func _add_root(ang: float, mat: Material, rng: RandomNumberGenerator) -> void:
	var dir := Vector2.from_angle(ang)
	var side := Vector2(-dir.y, dir.x)
	var wob: float = rng.randf_range(0.0, TAU)
	var amp: float = rng.randf_range(0.10, 0.28)
	var steps := 14
	var prev := Vector3.ZERO
	for i in steps + 1:
		var t: float = float(i) / float(steps)
		var r: float = lerpf(3.1, 1.72, t)
		var lat: float = sin(wob + t * 7.0) * amp
		var p2: Vector2 = dir * r + side * lat
		var p := Vector3(p2.x, _height_at(r) + 0.045 * (1.0 - t) + 0.03, p2.y)
		if i > 0:
			var seg := p - prev
			var cyl := CylinderMesh.new()
			var th: float = lerpf(0.075, 0.025, t)
			cyl.top_radius = th * 0.85
			cyl.bottom_radius = th
			cyl.height = seg.length() * 1.15
			cyl.radial_segments = 6
			var mi := MeshInstance3D.new()
			mi.mesh = cyl
			mi.material_override = mat
			mi.position = (p + prev) * 0.5
			var up := seg.normalized()
			var axis := Vector3.UP.cross(up)
			if axis.length() > 0.001:
				mi.basis = Basis(axis.normalized(), Vector3.UP.angle_to(up))
			add_child(mi)
		prev = p


func _add_crack(ang: float, mat: Material, rng: RandomNumberGenerator) -> void:
	var r: float = 1.85
	var a: float = ang
	var last := Vector2.from_angle(a) * r
	for i in 5:
		r -= rng.randf_range(0.04, 0.07)
		a += rng.randf_range(-0.06, 0.06)
		var nxt := Vector2.from_angle(a) * r
		var d := nxt - last
		var box := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.018, 0.006, d.length() * 1.1)
		box.mesh = bm
		box.material_override = mat
		var mid := (last + nxt) * 0.5
		box.position = Vector3(mid.x, _height_at(r) + 0.004, mid.y)
		box.rotation.y = atan2(d.x, d.y)
		add_child(box)
		last = nxt
