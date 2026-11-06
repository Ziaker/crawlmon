class_name AbraCanvas
extends MeshInstance3D
## Neon ribbon canvas for the Abra move VFX (D-170): one dynamic ImmediateMesh that is
## rebuilt every frame from line segments, wire cubes, rings, a 4D tesseract and bolts.
## Each segment is two crossed quads, so it reads from any camera angle. Purely visual.

var energy := 1.6  ## Vertex colours are multiplied by this (additive HDR look).
var _im := ImmediateMesh.new()
var _segs: Array = []  ## [a, b, width_a, width_b, color_a, color_b]
var _tris: Array = []  ## [a, b, c, color]


func _init(additive := true) -> void:
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 4096.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material_override = m


func clear() -> void:
	_segs.clear()
	_tris.clear()


## Filled triangle (flat colour).
func tri(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	if color.a > 0.01:
		_tris.append([a, b, c, color])


## The prototype's rotation order: X, then Y, then Z, all about the world axes.
static func rot(v: Vector3, r: Vector3) -> Vector3:
	var x := v.x
	var y := v.y
	var z := v.z
	if r.x != 0.0:
		var c := cos(r.x)
		var s := sin(r.x)
		var ny := y * c - z * s
		z = y * s + z * c
		y = ny
	if r.y != 0.0:
		var c := cos(r.y)
		var s := sin(r.y)
		var nx := x * c + z * s
		z = -x * s + z * c
		x = nx
	if r.z != 0.0:
		var c := cos(r.z)
		var s := sin(r.z)
		var nx := x * c - y * s
		y = x * s + y * c
		x = nx
	return Vector3(x, y, z)


func line(a: Vector3, b: Vector3, width: float, color: Color) -> void:
	if color.a <= 0.01 or width <= 0.0:
		return
	_segs.append([a, b, width, width, color, color])


## Open polyline. `taper` shrinks the width and `fade` the alpha towards the last point.
func polyline(points: PackedVector3Array, width: float, color: Color, taper := 0.0, fade := 0.0) -> void:
	var n := points.size()
	if n < 2 or color.a <= 0.01:
		return
	for i in n - 1:
		var f0 := float(i) / float(n - 1)
		var f1 := float(i + 1) / float(n - 1)
		var c0 := Color(color.r, color.g, color.b, color.a * (1.0 - fade * f0))
		var c1 := Color(color.r, color.g, color.b, color.a * (1.0 - fade * f1))
		_segs.append([points[i], points[i + 1], width * (1.0 - taper * f0), width * (1.0 - taper * f1), c0, c1])


## Closed polygon ring in the local XY plane of `basis` (its Z axis is the ring normal).
## `segs` of 6 gives the hexagonal "prism" rings of the prototype.
func ring(center: Vector3, basis: Basis, radius: float, segs: int, width: float, color: Color, phase := 0.0) -> void:
	if radius <= 0.001 or color.a <= 0.01:
		return
	var pts := PackedVector3Array()
	for i in segs + 1:
		var a := phase + float(i) * TAU / float(segs)
		pts.append(center + basis * Vector3(cos(a) * radius, sin(a) * radius, 0.0))
	polyline(pts, width, color)


func wire_cube(center: Vector3, size: float, basis: Basis, width: float, color: Color) -> void:
	if size <= 0.001 or color.a <= 0.01:
		return
	var corners: Array[Vector3] = []
	for i in 8:
		var v := Vector3(1.0 if (i & 1) != 0 else -1.0, 1.0 if (i & 2) != 0 else -1.0, 1.0 if (i & 4) != 0 else -1.0)
		corners.append(center + basis * (v * size * 0.5))
	for e in _edges(3):
		line(corners[e[0]], corners[e[1]], width, color)


## Octahedron (a gem) drawn as a wire frame.
func wire_gem(center: Vector3, size: float, basis: Basis, width: float, color: Color, stretch := 1.35) -> void:
	if size <= 0.001 or color.a <= 0.01:
		return
	var top := center + basis * Vector3(0, size * stretch, 0)
	var bottom := center + basis * Vector3(0, -size * stretch, 0)
	var eq: Array[Vector3] = []
	for i in 6:
		var a := float(i) * TAU / 6.0
		eq.append(center + basis * Vector3(cos(a) * size * 0.62, 0.0, sin(a) * size * 0.62))
	for i in 6:
		line(top, eq[i], width, color)
		line(bottom, eq[i], width, color)
		line(eq[i], eq[(i + 1) % 6], width, color)


## 4D hypercube projected to 3D (the prototype's Tesseract): `col_a` for the outer cell,
## `col_b` for the inner one.
func tesseract(center: Vector3, scale: float, t: float, alpha: float, col_a: Color, col_b: Color) -> void:
	if alpha <= 0.02 or scale <= 0.001:
		return
	var c_xw := cos(t * 2.2)
	var s_xw := sin(t * 2.2)
	var c_yw := cos(t * 1.7)
	var s_yw := sin(t * 1.7)
	var c_zw := cos(t * 2.9)
	var s_zw := sin(t * 2.9)
	var c_xy := cos(t * 1.3)
	var s_xy := sin(t * 1.3)
	var pts: Array[Vector3] = []
	var ws: Array[float] = []
	for i in 16:
		var x := 1.0 if (i & 1) != 0 else -1.0
		var y := 1.0 if (i & 2) != 0 else -1.0
		var z := 1.0 if (i & 4) != 0 else -1.0
		var w := 1.0 if (i & 8) != 0 else -1.0
		var nx := x * c_xw - w * s_xw
		w = x * s_xw + w * c_xw
		x = nx
		var ny := y * c_yw - w * s_yw
		w = y * s_yw + w * c_yw
		y = ny
		var nz := z * c_zw - w * s_zw
		w = z * s_zw + w * c_zw
		z = nz
		var nx2 := x * c_xy - y * s_xy
		y = x * s_xy + y * c_xy
		x = nx2
		var persp := 1.0 / (2.35 - w * 0.65)
		pts.append(center + Vector3(x, y, z) * scale * persp)
		ws.append(w)
	for e in _edges(4):
		var inner: bool = ws[e[0]] + ws[e[1]] > 0.0
		var col := col_a if inner else col_b
		var a := alpha * (0.95 if inner else 0.68)
		var width := scale * (0.085 if inner else 0.05) + 0.01
		line(pts[e[0]], pts[e[1]], width, Color(col.r, col.g, col.b, a))


## Jagged bolt between a and b (midpoint displacement).
static func bolt_points(a: Vector3, b: Vector3, generations: int, amplitude: float, rng: RandomNumberGenerator) -> PackedVector3Array:
	var pts := PackedVector3Array([a, b])
	var disp := amplitude
	for g in generations:
		var out := PackedVector3Array()
		for i in pts.size() - 1:
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var d := (p1 - p0).normalized()
			var side := d.cross(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)))
			if side.length() < 0.001:
				side = d.cross(Vector3.RIGHT)
			out.append(p0)
			out.append((p0 + p1) * 0.5 + side.normalized() * rng.randf_range(-1.0, 1.0) * disp)
		out.append(pts[pts.size() - 1])
		pts = out
		disp *= 0.55
	return pts


func flush() -> void:
	_im.clear_surfaces()
	var drawn: Array = []
	for s in _segs:
		if (s[1] as Vector3).distance_to(s[0] as Vector3) >= 0.0001:  # a zero-length cord has no direction
			drawn.append(s)
	if drawn.is_empty() and _tris.is_empty():
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for tr in _tris:
		var tc := tr[3] as Color
		var c2 := Color(tc.r * energy, tc.g * energy, tc.b * energy, tc.a)
		_vertex(tr[0] as Vector3, c2)
		_vertex(tr[1] as Vector3, c2)
		_vertex(tr[2] as Vector3, c2)
	for s in drawn:
		_emit(s[0] as Vector3, s[1] as Vector3, float(s[2]), float(s[3]), s[4] as Color, s[5] as Color)
	_im.surface_end()


func _emit(a: Vector3, b: Vector3, wa: float, wb: float, ca: Color, cb: Color) -> void:
	var d := b - a
	if d.length() < 0.0001:
		return
	d = d.normalized()
	var n1 := d.cross(Vector3.UP)
	if n1.length() < 0.01:
		n1 = d.cross(Vector3.RIGHT)
	n1 = n1.normalized()
	var n2 := d.cross(n1).normalized()
	var col_a := Color(ca.r * energy, ca.g * energy, ca.b * energy, ca.a)
	var col_b := Color(cb.r * energy, cb.g * energy, cb.b * energy, cb.a)
	for n in [n1, n2]:
		var off: Vector3 = n
		var v0 := a - off * wa * 0.5
		var v1 := a + off * wa * 0.5
		var v2 := b + off * wb * 0.5
		var v3 := b - off * wb * 0.5
		_vertex(v0, col_a)
		_vertex(v1, col_a)
		_vertex(v2, col_b)
		_vertex(v0, col_a)
		_vertex(v2, col_b)
		_vertex(v3, col_b)


func _vertex(p: Vector3, c: Color) -> void:
	_im.surface_set_color(c)
	_im.surface_add_vertex(p)


static var _edge_cache: Dictionary = {}


## Edges of an n-cube: vertex pairs that differ in exactly one bit.
static func _edges(bits: int) -> Array:
	if not _edge_cache.has(bits):
		var out: Array = []
		var count := 1 << bits
		for i in count:
			for j in range(i + 1, count):
				var diff := i ^ j
				if diff != 0 and (diff & (diff - 1)) == 0:
					out.append([i, j])
		_edge_cache[bits] = out
	return _edge_cache[bits]
