class_name DustMeshes
extends RefCounted
## Meshes ported literally from prototypes/vfx_atelier/dig_sand_attack_unified_dust_shaders.html:
## createLotusCrownShellMesh (lines 961-996) and createDirectionalCryoConeMesh (lines 998-1034).
## No GPUParticles, decals or sub-emitters, and nothing keyed to character, team or side (D-235).
##
## AXIS CONVENTION: Babylon is left-handed (Z+ forward), Godot is right-handed (Z- forward).
## The LOCAL positions are copied exactly as the HTML writes them:
##   crown: (r*cos(phi), y, r*sin(phi))
##   cone:  (r*cos(phi), r*sin(phi), z)
## Nothing is mirrored, swapped or rotated here; the caller orients the node from the real
## attacker->target axis. Y is the only axis whose meaning is the same in both engines.
##
## WINDING / NORMALS: triangles keep the literal HTML order (a, b, d) and (b, c, d). The normals
## reproduce Babylon's VertexData.ComputeNormals exactly (verified against the HTML's own Babylon,
## max error 2e-16): the sum of UNIT face normals cross(p0 - p1, p2 - p1) per shared vertex,
## normalized. The shaders displace along NORMAL, so sign and weighting must match the HTML.

static func lotus_crown(radial_segs: int, tubular_segs: int) -> ArrayMesh:
	var positions := PackedVector3Array()
	var uvs := PackedVector2Array()
	for i in range(tubular_segs + 1):
		var u := float(i) / float(tubular_segs)
		var y := pow(u, 0.85) * 1.75
		var r := 0.55 + pow(u, 0.78) * 1.45 + sin(u * PI) * 0.18
		for j in range(radial_segs + 1):
			var v := float(j) / float(radial_segs)
			var phi := v * PI * 2.0
			positions.append(Vector3(r * cos(phi), y, r * sin(phi)))
			uvs.append(Vector2(u, v))
	var stride := radial_segs + 1
	var indices := PackedInt32Array()
	for i in range(tubular_segs):
		for j in range(radial_segs):
			var a: int = i * stride + j
			var b: int = (i + 1) * stride + j
			var c: int = (i + 1) * stride + (j + 1)
			var d: int = i * stride + (j + 1)
			indices.append_array(PackedInt32Array([a, b, d, b, c, d]))
	return _build(positions, uvs, indices)


static func directional_cone(radial_segs: int, tubular_segs: int) -> ArrayMesh:
	var positions := PackedVector3Array()
	var uvs := PackedVector2Array()
	var length := 2.45
	for i in range(tubular_segs + 1):
		var u := float(i) / float(tubular_segs)
		var z := (0.18 - u) * length
		var r := 0.16 + pow(u, 0.68) * 1.55 + sin(u * PI) * 0.22
		for j in range(radial_segs + 1):
			var v := float(j) / float(radial_segs)
			var phi := v * PI * 2.0
			positions.append(Vector3(r * cos(phi), r * sin(phi), z))
			uvs.append(Vector2(u, v))
	var stride := radial_segs + 1
	var indices := PackedInt32Array()
	for i in range(tubular_segs):
		for j in range(radial_segs):
			var a: int = i * stride + j
			var b: int = (i + 1) * stride + j
			var c: int = (i + 1) * stride + (j + 1)
			var d: int = i * stride + (j + 1)
			indices.append_array(PackedInt32Array([a, b, d, b, c, d]))
	return _build(positions, uvs, indices)


static func _build(positions: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var normals := _grid_normals(positions, indices)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _grid_normals(positions: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(positions.size())
	for k in range(0, indices.size(), 3):
		var i0: int = indices[k]
		var i1: int = indices[k + 1]
		var i2: int = indices[k + 2]
		var p0: Vector3 = positions[i0]
		var p1: Vector3 = positions[i1]
		var p2: Vector3 = positions[i2]
		var face := (p0 - p1).cross(p2 - p1)
		var face_len := face.length()
		if face_len > 0.0:
			face /= face_len  # Babylon adds UNIT face normals (not area weighted).
		normals[i0] = normals[i0] + face
		normals[i1] = normals[i1] + face
		normals[i2] = normals[i2] + face
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	return normals


## Open (NO_CAP) cone frustum like BABYLON.MeshBuilder.CreateCylinder({diameterTop, diameterBottom, height,
## tessellation, cap: NO_CAP}) with its UV convention: u around (0..1), v = 0 at the bottom ring and 1 at the
## top ring (verified in the HTML's own Babylon). Centered on its origin (y from -height/2 to +height/2).
## Normals are the outward slope normals. One height subdivision (Babylon's default).
static func open_frustum(top_diameter: float, bottom_diameter: float, height: float, tessellation: int) -> ArrayMesh:
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var top_r := top_diameter * 0.5
	var bottom_r := bottom_diameter * 0.5
	for ring in range(2):
		var y := -height * 0.5 + float(ring) * height
		var r := bottom_r if ring == 0 else top_r
		for j in range(tessellation + 1):
			var u := float(j) / float(tessellation)
			var a := u * TAU
			positions.append(Vector3(cos(a) * r, y, sin(a) * r))
			normals.append(Vector3(cos(a) * height, bottom_r - top_r, sin(a) * height).normalized())
			uvs.append(Vector2(u, float(ring)))
	var stride := tessellation + 1
	for j in range(tessellation):
		var a0 := j
		var b0 := stride + j
		var c0 := stride + j + 1
		var d0 := j + 1
		indices.append_array(PackedInt32Array([a0, b0, d0, b0, c0, d0]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Flat grid on the XZ plane: x across (-width/2..width/2), z along (0..length), y = 0, normals up. Used by the Dig
## burrow ridge, whose shader raises the vertices (D-1196).
static func ribbon_grid(width: float, length: float, across_steps: int, along_steps: int) -> ArrayMesh:
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(along_steps + 1):
		var v := float(i) / float(along_steps)
		for j in range(across_steps + 1):
			var u := float(j) / float(across_steps)
			positions.append(Vector3((u - 0.5) * width, 0.0, v * length))
			normals.append(Vector3.UP)
			uvs.append(Vector2(u, v))
	var stride := across_steps + 1
	for i in range(along_steps):
		for j in range(across_steps):
			var a := i * stride + j
			var b := (i + 1) * stride + j
			var c := (i + 1) * stride + j + 1
			var d := i * stride + j + 1
			indices.append_array(PackedInt32Array([a, d, b, b, d, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-width, -1.0, -1.0), Vector3(width * 2.0, 4.0, length + 2.0))
	return mesh
