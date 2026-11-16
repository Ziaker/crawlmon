class_name HubSummonFx
extends Node3D
## Summoning effect of the hub arrival (prototype): a neon circle with a
## pentagram traces itself on the plaza floor, rings rise from it, a pillar of
## light comes down from the sky with a comet inside, and the impact reveals the
## leader. Reference line chosen by the creator: circle, rings and pillar.
##
## It keeps no clock: HubArrivalCutscene calls pose(state, p, time_s) every frame
## with the transition state and progress (D-1040). Every size derives from the
## radius given by the cutscene, which derives from the leader height (D-235).
## Nothing here covers the screen (D-418): all light stays on the circle.

const NEON := Color("d6fa66")  # roulette accent, chosen by the creator
const GOLD := Color("f0c57e")

const TUNING := {
	"ring_heights": [0.55, 1.45, 2.5],  # D-1237 ring heights, in circle radii x 0.5
	"ring_radii": [0.78, 0.6, 0.42],    # D-1237 ring radii, in circle radii
	"ring_turns": 0.75,                 # D-1237 turns each ring makes during FALL
	"pillar_h_m": 32.0,                 # D-1237 pillar height
	"pillar_r": 0.2,                    # D-1237 pillar radius at the end of FALL, in circle radii
	"flare_r": 0.42,                    # D-1237 pillar radius at the impact, in circle radii
	"shock_r": 3.8,                     # D-1237 final shockwave radius, in circle radii
	"light_peak": 3.2,                  # D-1237 light energy at the impact
	"spark_count": 70,                  # D-1237 sparks at the impact
}

const GLYPH_SHADER := "
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.84, 0.98, 0.4, 1.0);
uniform float draw = 1.0;
uniform float alpha = 1.0;
uniform float energy = 1.0;
void fragment() {
	if (UV.x > draw) { discard; }
	float edge = 1.0 - abs(UV.y * 2.0 - 1.0);
	float core = smoothstep(0.5, 1.0, edge) * COLOR.r;
	float body = smoothstep(0.0, 0.7, edge);
	float head = smoothstep(0.05, 0.0, draw - UV.x) * step(draw, 0.999);
	vec3 col = mix(tint.rgb, vec3(1.0), clamp(core * 0.45 + head, 0.0, 1.0));
	ALBEDO = col * energy * (1.0 + head * 2.0);
	ALPHA = alpha * body * COLOR.a;
}
"

const BEAM_SHADER := "
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.84, 0.98, 0.4, 1.0);
uniform float alpha = 1.0;
uniform float t = 0.0;
uniform float streaks = 1.0;
void fragment() {
	float f = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float beam = pow(f, 2.2);
	float streak = mix(1.0, 0.7 + 0.3 * sin(UV.x * 44.0 + UV.y * 9.0 - t * 22.0), streaks);
	vec3 col = mix(tint.rgb, vec3(1.0), pow(f, 6.0) * 0.55);
	ALBEDO = col * 1.25;
	ALPHA = alpha * beam * streak;
}
"

var _r := 2.0
var _glyph_mat: ShaderMaterial
var _rings: Array[MeshInstance3D] = []
var _ring_mats: Array[ShaderMaterial] = []
var _pillar: MeshInstance3D
var _pillar_mat: ShaderMaterial
var _comet: MeshInstance3D
var _comet_mat: ShaderMaterial
var _shock: MeshInstance3D
var _shock_mat: ShaderMaterial
var _light: OmniLight3D
var _sparks: CPUParticles3D
var _last_state := ""


## Builds the effect centred on this node's origin (the floor point), radius in metres.
func build(radius_m: float) -> void:
	_r = maxf(radius_m, 0.2)
	var glyph_shader := Shader.new()
	glyph_shader.code = GLYPH_SHADER
	var beam_shader := Shader.new()
	beam_shader.code = BEAM_SHADER

	_glyph_mat = _mat(glyph_shader, NEON)
	var glyph := MeshInstance3D.new()
	glyph.mesh = _build_glyph_mesh()
	glyph.material_override = _glyph_mat
	glyph.position.y = 0.16  # just above the plaza medallion (top at 0.13)
	glyph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glyph)

	var radii: Array = TUNING["ring_radii"]
	for k in radii.size():
		var ring := MeshInstance3D.new()
		ring.mesh = _build_band_mesh(_r * float(radii[k]), _r * 0.07)
		var ring_mat := _mat(glyph_shader, GOLD if k == 1 else NEON)
		ring.material_override = ring_mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)
		_ring_mats.append(ring_mat)

	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	cyl.radial_segments = 28
	cyl.rings = 1
	cyl.cap_top = false
	cyl.cap_bottom = false
	_pillar_mat = _mat(beam_shader, NEON)
	_pillar = MeshInstance3D.new()
	_pillar.mesh = cyl
	_pillar.material_override = _pillar_mat
	_pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pillar)

	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 20
	ball.rings = 10
	_comet_mat = _mat(beam_shader, NEON)
	_comet_mat.set_shader_parameter("streaks", 0.0)
	_comet = MeshInstance3D.new()
	_comet.mesh = ball
	_comet.material_override = _comet_mat
	_comet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_comet)

	_shock_mat = _mat(glyph_shader, NEON)
	_shock = MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ribbon(st, _circle_pts(1.0, 64), 0.16, 0.0, 0.0, true, 1.0, 1.0)
	_shock.mesh = st.commit()
	_shock.material_override = _shock_mat
	_shock.position.y = 0.17
	_shock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shock)

	_light = OmniLight3D.new()
	_light.light_color = NEON
	_light.omni_range = _r * 5.0
	_light.light_energy = 0.0
	_light.shadow_enabled = false
	_light.position.y = _r * 0.5
	add_child(_light)

	_sparks = CPUParticles3D.new()
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 0.92
	_sparks.amount = int(TUNING["spark_count"])
	_sparks.lifetime = 0.9
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sparks.emission_sphere_radius = _r * 0.35
	_sparks.direction = Vector3.UP
	_sparks.spread = 70.0
	_sparks.initial_velocity_min = _r * 1.2
	_sparks.initial_velocity_max = _r * 3.4
	_sparks.gravity = Vector3(0.0, -_r * 2.2, 0.0)
	_sparks.scale_amount_min = 0.5
	_sparks.scale_amount_max = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.012, 0.07) * _r
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	spark_mat.albedo_color = NEON.lerp(Color.WHITE, 0.15)
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	_sparks.scale_amount_curve = shrink
	quad.material = spark_mat
	_sparks.mesh = quad
	_sparks.position.y = _r * 0.2
	add_child(_sparks)

	visible = false


## Poses the whole effect. `body_y` is the height of the falling body above the floor.
func pose(state: String, p: float, time_s: float, body_y: float) -> void:
	if state != _last_state:
		_last_state = state
		if state == "LAND" and _sparks != null:
			_sparks.restart()
			_sparks.emitting = true
	_pillar_mat.set_shader_parameter("t", time_s)
	match state:
		"REVEAL":
			visible = true
			_glyph_mat.set_shader_parameter("draw", _smooth(clampf((p - 0.12) / 0.88, 0.0, 1.0)))
			_glyph_mat.set_shader_parameter("alpha", 1.0)
			_glyph_mat.set_shader_parameter("energy", 1.0)
			_set_rings(0.0, 0.0, 0.0)
			_set_pillar(0.0, 0.0, 0.0)
			_comet.visible = false
			_shock.visible = false
			_light.light_energy = 0.9 * p
		"FALL":
			visible = true
			_glyph_mat.set_shader_parameter("draw", 1.0)
			_glyph_mat.set_shader_parameter("alpha", 1.0)
			_glyph_mat.set_shader_parameter("energy", 1.0 + 0.5 * p + 0.25 * sin(time_s * 14.0))
			_set_rings(clampf(p / 0.2, 0.0, 1.0), 1.0 - (1.0 - p) * (1.0 - p), p * TAU * float(TUNING["ring_turns"]))
			var reach: float = clampf(p / 0.3, 0.0, 1.0)
			_set_pillar(clampf(p / 0.12, 0.0, 1.0), _r * lerpf(0.035, float(TUNING["pillar_r"]), p * p), reach)
			_comet.visible = true
			_comet.position = Vector3(0.0, body_y + _r * 0.25, 0.0)
			_comet.scale = Vector3.ONE * _r * lerpf(0.16, 0.3, p)
			_comet_mat.set_shader_parameter("alpha", clampf(p / 0.1, 0.0, 1.0))
			_shock.visible = false
			_light.light_energy = lerpf(0.9, 2.6, p)
		"LAND":
			visible = true
			var flare: float = sin(clampf(p / 0.3, 0.0, 1.0) * PI)
			var gone: float = smoothstep(0.28, 0.6, p)
			_glyph_mat.set_shader_parameter("draw", 1.0)
			_glyph_mat.set_shader_parameter("alpha", 1.0 - smoothstep(0.5, 1.0, p))
			_glyph_mat.set_shader_parameter("energy", 1.0 + 1.8 * (1.0 - clampf(p / 0.4, 0.0, 1.0)))
			_set_rings(1.0 - clampf(p / 0.32, 0.0, 1.0), 1.0 - _smooth(clampf(p / 0.3, 0.0, 1.0)), TAU * float(TUNING["ring_turns"]) + p * TAU)
			_set_pillar(1.0 - gone, _r * (float(TUNING["pillar_r"]) + float(TUNING["flare_r"]) * flare) * (1.0 - gone), 1.0)
			_comet.visible = false
			var wave: float = clampf(p / 0.55, 0.0, 1.0)
			_shock.visible = wave < 1.0
			_shock.scale = Vector3.ONE * _r * lerpf(0.4, float(TUNING["shock_r"]), 1.0 - (1.0 - wave) * (1.0 - wave))
			_shock_mat.set_shader_parameter("alpha", 1.0 - wave)
			_light.light_energy = float(TUNING["light_peak"]) * (1.0 - p) * (1.0 - p)
		_:
			visible = false


func _set_rings(alpha: float, rise: float, spin: float) -> void:
	var heights: Array = TUNING["ring_heights"]
	for k in _rings.size():
		var ring: MeshInstance3D = _rings[k]
		ring.visible = alpha > 0.01
		ring.position.y = 0.1 + _r * 0.5 * float(heights[k]) * rise
		ring.rotation.y = spin * (1.0 if k % 2 == 0 else -1.3)
		ring.rotation.x = deg_to_rad(6.0) * sin(spin + float(k)) * rise
		_ring_mats[k].set_shader_parameter("alpha", alpha)
		_ring_mats[k].set_shader_parameter("energy", 1.3)


## `reach` 0..1: how far the pillar has come down from the sky to the floor.
func _set_pillar(alpha: float, radius: float, reach: float) -> void:
	_pillar.visible = alpha > 0.01 and radius > 0.001
	var top: float = float(TUNING["pillar_h_m"])
	var bottom: float = lerpf(top, 0.0, reach)
	var height: float = maxf(top - bottom, 0.01)
	_pillar.position = Vector3(0.0, bottom + height * 0.5, 0.0)
	_pillar.scale = Vector3(maxf(radius, 0.001), height, maxf(radius, 0.001))
	_pillar_mat.set_shader_parameter("alpha", alpha)


func _mat(shader: Shader, tint: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("tint", tint)
	return m


static func _smooth(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


# --- Glyph geometry (flat ribbons on the floor, UV.x = drawing order 0..1) -------

func _build_glyph_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := _r
	# Soft halo first, sharp neon line on top: each stroke is added twice.
	for pass_id in 2:
		var halo: bool = pass_id == 0
		var wide: float = 4.5 if halo else 1.0
		var a: float = 0.22 if halo else 1.0
		var core: float = 0.0 if halo else 1.0
		# Outer double ring.
		_ribbon(st, _circle_pts(r, 96), r * 0.035 * wide, 0.0, 0.3, true, a, core)
		_ribbon(st, _circle_pts(r * 0.9, 96), r * 0.016 * wide, 0.08, 0.34, true, a, core)
		# Pentagram: five strokes, each tip joined to the second next one.
		var tips: Array[Vector2] = []
		for i in 5:
			tips.append(Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 5.0) * r * 0.9)
		for i in 5:
			var from: Vector2 = tips[(i * 2) % 5]
			var to: Vector2 = tips[(i * 2 + 2) % 5]
			var u0: float = 0.28 + 0.09 * float(i)
			_ribbon(st, PackedVector2Array([from, from.lerp(to, 0.5), to]), r * 0.03 * wide, u0, u0 + 0.09, false, a, core)
		# Inner pentagon ring and centre seal.
		_ribbon(st, _circle_pts(r * 0.34, 5, -PI * 0.5 + PI / 5.0), r * 0.014 * wide, 0.72, 0.82, true, a, core)
		_ribbon(st, _circle_pts(r * 0.2, 48), r * 0.014 * wide, 0.78, 0.88, true, a, core)
		# Small circles on the tips and rune ticks between the two outer rings.
		for i in 5:
			_ribbon(st, _circle_pts(r * 0.07, 20, 0.0, tips[i]), r * 0.012 * wide, 0.8 + 0.02 * float(i), 0.9 + 0.02 * float(i), true, a, core)
		for i in 30:
			var ang: float = TAU * float(i) / 30.0
			var dir := Vector2.from_angle(ang)
			var inner: float = 0.915 if i % 3 != 0 else 0.905
			var u: float = 0.86 + 0.14 * float(i) / 30.0
			_ribbon(st, PackedVector2Array([dir * r * inner, dir * r * 0.985]), r * (0.01 if i % 3 != 0 else 0.02) * wide, u - 0.02, u, false, a, core)
	return st.commit()


func _circle_pts(radius: float, count: int, phase: float = 0.0, centre: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in count:
		pts.append(centre + Vector2.from_angle(phase + TAU * float(i) / float(count)) * radius)
	return pts


## Adds a flat ribbon along `pts` (x, z on the floor). UV.x runs u0..u1 along it.
func _ribbon(st: SurfaceTool, pts: PackedVector2Array, width: float, u0: float, u1: float, closed: bool, a: float, core: float) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var count: int = n + 1 if closed else n
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in count:
		var k: int = i % n
		var prev: Vector2 = pts[(k - 1 + n) % n] if (closed or k > 0) else pts[k]
		var next: Vector2 = pts[(k + 1) % n] if (closed or k < n - 1) else pts[k]
		var tangent: Vector2 = (next - prev).normalized()
		var side := Vector2(-tangent.y, tangent.x) * width * 0.5
		left.append(Vector3(pts[k].x + side.x, 0.0, pts[k].y + side.y))
		right.append(Vector3(pts[k].x - side.x, 0.0, pts[k].y - side.y))
	var col := Color(core, 1.0, 1.0, a)
	for i in count - 1:
		var ua: float = lerpf(u0, u1, float(i) / float(count - 1))
		var ub: float = lerpf(u0, u1, float(i + 1) / float(count - 1))
		_quad(st, left[i], right[i], left[i + 1], right[i + 1], ua, ub, col)


## Vertical band (short open cylinder) used for the rising rings.
func _build_band_mesh(radius: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 64
	var col := Color(1.0, 1.0, 1.0, 1.0)
	for i in seg:
		# Dashed band: every fourth segment is left open, like rune gaps.
		if i % 8 == 7:
			continue
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var p0 := Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		var up := Vector3(0.0, height, 0.0)
		_quad(st, p0 + up, p0, p1 + up, p1, 0.0, 0.0, col)
	return st.commit()


func _quad(st: SurfaceTool, l0: Vector3, r0: Vector3, l1: Vector3, r1: Vector3, ua: float, ub: float, col: Color) -> void:
	var verts: Array[Vector3] = [l0, r0, l1, r0, r1, l1]
	var uvs: Array[Vector2] = [Vector2(ua, 0.0), Vector2(ua, 1.0), Vector2(ub, 0.0), Vector2(ua, 1.0), Vector2(ub, 1.0), Vector2(ub, 0.0)]
	for i in 6:
		st.set_color(col)
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
