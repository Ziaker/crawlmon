class_name BubbleShotVfx
extends Node3D
## VFX 3D do Move "Bubble Shot" (D-1170 / D-308).
##
## Coreografia do protótipo "Bolha Gêiser de Pressão" com materiais Hydro (shaders
## `bubble_shot_bubble` e `bubble_shot_water`). Este nó só desenha: recebe do driver
## (`FxBubbleShot`) as âncoras reais e os relógios das fases do `Battle` (D-019/D-1040).
## Nada de `is_player`, nome, time, lado ou coordenada fixa (D-235). Sem GPUParticles
## (GL Compatibility): tudo é malha posicionada por função do tempo.

const BUBBLE_SHADER := preload("res://shaders/bubble_shot_bubble.gdshader")
const WATER_SHADER := preload("res://shaders/bubble_shot_water.gdshader")

const R_MAIN := 0.34
const MICRO_COUNT := 8
const GUIDE_COUNT := 10
const CROWN_COUNT := 14
const WAKE_COUNT := 10
const CREST_COUNT := 8
const BOUNCE_MINI_COUNT := 10
const BURST_MINI_COUNT := 20
const DROP_COUNT := 24
const RELEASE_LEN := 0.35
const BOUNCE_LEN := 0.45
const IMPACT_LEN := 0.80
const MISS_LEN := 0.24

var camera: Camera3D

var _sphere_hi: SphereMesh
var _sphere_lo: SphereMesh
var _torus_thin: TorusMesh
var _torus_oct: TorusMesh
var _cone: CylinderMesh

var _main: MeshInstance3D
var _core: MeshInstance3D
var _pressure: MeshInstance3D
var _micro: Array[MeshInstance3D] = []
var _guide: Array[MeshInstance3D] = []
var _marker: MeshInstance3D
var _crown: Array[MeshInstance3D] = []
var _crown_pop: Array[MeshInstance3D] = []
var _wake: Array[MeshInstance3D] = []
var _b_rings: Array[MeshInstance3D] = []
var _crests: Array[MeshInstance3D] = []
var _b_minis: Array[MeshInstance3D] = []
var _jets: Array[MeshInstance3D] = []
var _late_ring: MeshInstance3D
var _wet_ring: MeshInstance3D
var _burst_minis: Array[MeshInstance3D] = []
var _drops: Array[MeshInstance3D] = []
var _all: Array[MeshInstance3D] = []

var _launch_now := -1.0
var _launch_pos := Vector3.ZERO
var _launch_dir := Vector3.FORWARD
var _crown_adv := 0.0
var _bounce_now := -1.0
var _bounce_pos := Vector3.ZERO
var _bounce_vs := 1.0
var _wake_born: Array[float] = []
var _wake_pos: Array[Vector3] = []
var _last_stage := ""


func setup(p_camera: Camera3D) -> void:
	camera = p_camera
	_build()


# --------------------------------------------------------------------------- build

func _build() -> void:
	_sphere_hi = SphereMesh.new()
	_sphere_hi.radius = 1.0
	_sphere_hi.height = 2.0
	_sphere_hi.radial_segments = 48
	_sphere_hi.rings = 24
	_sphere_lo = SphereMesh.new()
	_sphere_lo.radius = 1.0
	_sphere_lo.height = 2.0
	_sphere_lo.radial_segments = 20
	_sphere_lo.rings = 10
	_torus_thin = TorusMesh.new()
	_torus_thin.inner_radius = 0.90
	_torus_thin.outer_radius = 1.0
	_torus_thin.rings = 48
	_torus_thin.ring_segments = 8
	_torus_oct = TorusMesh.new()
	_torus_oct.inner_radius = 0.86
	_torus_oct.outer_radius = 1.0
	_torus_oct.rings = 8
	_torus_oct.ring_segments = 6
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 1.0
	_cone.height = 1.0
	_cone.radial_segments = 10
	_cone.rings = 4

	_main = _bubble(_sphere_hi, "MainBubble", 0.0)
	_core = _bubble(_sphere_lo, "PressureCore", 3.1)
	_pressure = _water(_torus_thin, "PressureRing", 0.7, {"band_scale": 25.0, "flow_speed": 9.0, "foam": 0.9})
	for i in MICRO_COUNT:
		_micro.append(_bubble(_sphere_lo, "MicroBubble%d" % i, float(i) * 1.3))
	for i in GUIDE_COUNT:
		_guide.append(_water(_sphere_lo, "GuideDash%d" % i, float(i), {"band_scale": 6.0, "foam": 0.2, "tip_fade": 1.0}))
	_marker = _water(_torus_oct, "BounceMarker", 2.0, {"band_scale": 16.0, "flow_speed": 4.0, "foam": 0.8})
	for i in CROWN_COUNT:
		_crown.append(_bubble(_sphere_lo, "CrownBubble%d" % i, float(i) * 0.9))
		_crown_pop.append(_water(_torus_thin, "CrownPop%d" % i, float(i), {"foam": 1.0, "band_scale": 20.0}))
	for i in WAKE_COUNT:
		_wake.append(_bubble(_sphere_lo, "WakeBubble%d" % i, float(i) * 2.1))
		_wake_born.append(-1.0)
		_wake_pos.append(Vector3.ZERO)
	for i in 2:
		_b_rings.append(_water(_torus_thin, "BounceRing%d" % i, float(i) * 4.0, {"band_scale": 30.0, "flow_speed": 5.0, "foam": 0.9}))
	for i in CREST_COUNT:
		_crests.append(_water(_cone, "GeyserCrest%d" % i, float(i) * 1.7, {"band_scale": 10.0, "flow_speed": 12.0, "foam": 0.7}))
	for i in BOUNCE_MINI_COUNT:
		_b_minis.append(_bubble(_sphere_lo, "BounceMini%d" % i, float(i) * 1.9))
	for i in 3:
		_jets.append(_water(_sphere_lo, "HydroJet%d" % i, float(i) * 2.3, {"band_scale": 14.0, "flow_speed": 16.0, "foam": 0.8, "tip_fade": 1.0}))
	_late_ring = _water(_torus_thin, "DelayedWaterRing", 5.0, {"band_scale": 34.0, "flow_speed": 7.0, "foam": 0.9})
	_wet_ring = _water(_torus_thin, "WetRing", 6.0, {"band_scale": 30.0, "flow_speed": 3.0, "foam": 0.5})
	for i in BURST_MINI_COUNT:
		_burst_minis.append(_bubble(_sphere_lo, "BurstMini%d" % i, float(i) * 1.1))
	for i in DROP_COUNT:
		_drops.append(_water(_sphere_lo, "WaterDrop%d" % i, float(i) * 0.8, {"band_scale": 5.0, "foam": 0.3}))


func _mi(mesh: Mesh, node_name: String, mat: ShaderMaterial) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	_all.append(mi)
	return mi


func _bubble(mesh: Mesh, node_name: String, seed_value: float) -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = BUBBLE_SHADER
	mat.set_shader_parameter("seed", seed_value)
	return _mi(mesh, node_name, mat)


func _water(mesh: Mesh, node_name: String, seed_value: float, params: Dictionary) -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("seed", seed_value)
	for k in params:
		mat.set_shader_parameter(k, params[k])
	return _mi(mesh, node_name, mat)


# ---------------------------------------------------------------------------- draw

## `s`: stage ("windup" | "flight" | "impact" | "miss"), now, front, chest, ground_y,
## vs_front, vs_chest, impact_scale, windup_t, windup_total, flight_u, flight_duration,
## since_impact, impact_chest, miss_t.
func draw(s: Dictionary) -> void:
	var stage := String(s.get("stage", "windup"))
	var now := float(s.get("now", 0.0))
	var front: Vector3 = s.get("front", Vector3.ZERO)
	var chest: Vector3 = s.get("chest", Vector3.ZERO)
	var ground := float(s.get("ground_y", 0.0))
	var vs_f := float(s.get("vs_front", 1.0))
	var vs_c := float(s.get("vs_chest", 1.0))
	var axis := chest - front
	axis = axis.normalized() if axis.length_squared() > 0.0001 else Vector3.FORWARD
	var vs_mid := (vs_f + vs_c) * 0.5

	for mi in _all:
		(mi.material_override as ShaderMaterial).set_shader_parameter("time_s", now)

	# The single bounce spot is live until the bubble actually bounces (D-235).
	var bounce := front.lerp(chest, 0.5)
	bounce.y = ground + R_MAIN * vs_mid * 0.42
	if _bounce_now >= 0.0:
		bounce = _bounce_pos

	var u := clampf(float(s.get("flight_u", 0.0)), 0.0, 1.0)
	var flight_len := maxf(float(s.get("flight_duration", 0.30)), 0.01)
	if stage == "flight" or stage == "impact" or stage == "miss":
		if _launch_now < 0.0:
			_launch_now = now - u * flight_len
			_launch_pos = front
			_launch_dir = _path(0.02, front, bounce, chest, vs_f, vs_c) - front
			_launch_dir = _launch_dir.normalized() if _launch_dir.length_squared() > 0.000001 else axis
		if _bounce_now < 0.0 and (u >= 0.5 or stage != "flight"):
			_bounce_now = now - maxf(u - 0.5, 0.0) * flight_len
			_bounce_pos = bounce
			_bounce_vs = vs_mid

	var bubble_pos := _draw_main(stage, s, now, front, chest, bounce, axis, u, flight_len, vs_f, vs_c)
	_draw_micro(stage, s, now, front, axis, vs_f)
	_draw_guide(stage, s, front, chest, bounce, ground, vs_f, vs_c, vs_mid)
	_draw_crown(stage, now, bubble_pos, vs_f)
	_draw_wake(stage, now, u, front, bounce, chest, vs_f, vs_c)
	_draw_bounce(now, ground)
	_draw_impact(stage, s, ground, axis, float(s.get("vs_impact", vs_c)))
	_last_stage = stage


func _path(u: float, front: Vector3, bounce: Vector3, chest: Vector3, vs_f: float, vs_c: float) -> Vector3:
	var p: Vector3
	if u <= 0.5:
		var u1 := clampf(u / 0.5, 0.0, 1.0)
		p = front.lerp(bounce, u1)
		p.y = lerpf(front.y, bounce.y, u1 * u1) + 0.35 * minf(vs_f, 2.0) * sin(u1 * PI)
	else:
		var u2 := clampf((u - 0.5) / 0.5, 0.0, 1.0)
		p = bounce.lerp(chest, u2)
		p.y = lerpf(bounce.y, chest.y, u2) + 0.55 * minf(vs_c, 2.0) * sin(u2 * PI)
	return p


func _draw_main(stage: String, s: Dictionary, now: float, front: Vector3, chest: Vector3, bounce: Vector3,
		axis: Vector3, u: float, flight_len: float, vs_f: float, vs_c: float) -> Vector3:
	var pos := front
	var scale3 := Vector3.ONE
	var basis := _basis_z(axis)
	var r := R_MAIN * vs_f
	var alpha := 1.0
	var wobble := 0.03
	var flare := 0.0
	var inner := 1.0  # visibility of the pressure core/ring
	match stage:
		"windup":
			var total := maxf(float(s.get("windup_total", 0.7)), 0.01)
			var wt := clampf(float(s.get("windup_t", 0.0)), 0.0, total)
			var p := clampf(wt / (total * 0.9), 0.0, 1.0)
			var grow := lerpf(0.05, 1.0, _elastic_out(p))
			wobble = lerpf(0.08, 0.03, p)
			var q := clampf((wt - total * 0.9) / (total * 0.1), 0.0, 1.0)
			pos = front - axis * 0.20 * vs_f * q
			scale3 = Vector3(1.0 - 0.10 * q, 1.0 - 0.10 * q, 1.0 + 0.18 * q) * grow
			inner = p
		"flight":
			pos = _path(u, front, bounce, chest, vs_f, vs_c)
			var vel := _path(minf(u + 0.02, 1.0), front, bounce, chest, vs_f, vs_c) - _path(maxf(u - 0.02, 0.0), front, bounce, chest, vs_f, vs_c)
			if vel.length_squared() > 0.000001:
				basis = _basis_z(vel.normalized())
			r = R_MAIN * lerpf(vs_f, vs_c, u)
			scale3 = Vector3(0.92, 0.92, 1.14)
			var dt_b := (u - 0.5) * flight_len
			var k := 1.0 - smoothstep(0.0, 0.045, absf(dt_b))
			if k > 0.0:
				basis = Basis.IDENTITY if k > 0.5 else basis
				scale3 = scale3.lerp(Vector3(1.52, 0.42, 1.52), k)
			elif dt_b > 0.0 and dt_b < 0.22:
				var ring := sin(dt_b * 42.0) * exp(-dt_b * 15.0) * 0.16
				scale3 = Vector3(0.92 - ring, 0.92 + ring * 1.4, 1.14 - ring)
			wobble = 0.035
		"impact":
			var si := maxf(float(s.get("since_impact", 0.0)), 0.0)
			pos = s.get("impact_chest", chest)
			r = R_MAIN * vs_c
			var e := clampf(si / 0.06, 0.0, 1.0)
			scale3 = Vector3.ONE * lerpf(1.0, 1.68, _ease_out(e))
			flare = e * 1.6
			alpha = 1.0 - smoothstep(0.05, 0.11, si)
			inner = 0.0
			wobble = 0.09
		"miss":
			var mt := maxf(float(s.get("miss_t", 0.0)), 0.0)
			pos = chest
			r = R_MAIN * vs_c
			scale3 = Vector3.ONE * lerpf(1.0, 1.28, clampf(mt / 0.05, 0.0, 1.0))
			flare = clampf(mt / 0.05, 0.0, 1.0)
			alpha = 1.0 - smoothstep(0.04, 0.14, mt)
			inner = 0.0
	_place(_main, pos, basis, scale3 * r, alpha)
	var mat := _main.material_override as ShaderMaterial
	mat.set_shader_parameter("wobble", wobble)
	mat.set_shader_parameter("flare", flare)
	# Pressurised core and hydraulic ring ride inside the bubble.
	_place(_core, pos, basis, scale3 * r * (0.13 / R_MAIN), alpha * inner)
	(_core.material_override as ShaderMaterial).set_shader_parameter("wobble", 0.05)
	var spin := Basis.from_euler(Vector3(now * 5.2, now * 3.7, 0.0))
	_place(_pressure, pos, basis * spin, scale3 * r * 0.62, alpha * inner * 0.9)
	return pos


func _draw_micro(stage: String, s: Dictionary, now: float, front: Vector3, axis: Vector3, vs_f: float) -> void:
	if stage != "windup":
		for mi in _micro:
			mi.visible = false
		return
	var total := maxf(float(s.get("windup_total", 0.7)), 0.01)
	var wn := clampf(float(s.get("windup_t", 0.0)) / total, 0.0, 1.0)
	var right := _side_of(axis)
	var up := right.cross(axis).normalized()
	for i in MICRO_COUNT:
		var p := clampf((wn - float(i) / float(MICRO_COUNT) * 0.42) / 0.5, 0.0, 1.0)
		if p <= 0.0 or p >= 1.0:
			_micro[i].visible = false
			continue
		var ang := float(i) * TAU / float(MICRO_COUNT) + p * 5.0 + _h(i, 1.0)
		var rad := 0.65 * vs_f * (1.0 - _ease_in(p))
		var pos := front + (right * cos(ang) + up * sin(ang)) * rad - axis * 0.12 * vs_f * (1.0 - p)
		var size := lerpf(0.045, 0.075, _h(i, 2.0)) * vs_f * sin(p * PI * 0.92 + 0.08)
		_place(_micro[i], pos, Basis.IDENTITY, Vector3.ONE * maxf(size, 0.001), 1.0)
		(_micro[i].material_override as ShaderMaterial).set_shader_parameter("wobble", 0.05)


func _draw_guide(stage: String, s: Dictionary, front: Vector3, chest: Vector3, bounce: Vector3,
		ground: float, vs_f: float, vs_c: float, vs_mid: float) -> void:
	var reveal := 0.0
	if stage == "windup":
		var total := maxf(float(s.get("windup_total", 0.7)), 0.01)
		reveal = clampf((float(s.get("windup_t", 0.0)) / total - 0.2) / 0.5, 0.0, 1.0)
	for i in GUIDE_COUNT:
		var frac := (float(i) + 0.5) / float(GUIDE_COUNT)
		if stage != "windup" or reveal * 1.02 < frac:
			_guide[i].visible = false
			continue
		var p0 := _path(frac * 0.5, front, bounce, chest, vs_f, vs_c)
		var p1 := _path(minf(frac * 0.5 + 0.01, 0.5), front, bounce, chest, vs_f, vs_c)
		var dir := (p1 - p0).normalized() if (p1 - p0).length_squared() > 0.0000001 else Vector3.DOWN
		var vs := lerpf(vs_f, vs_mid, frac)
		_place(_guide[i], p0, _basis_y(dir), Vector3(0.028, 0.11, 0.028) * vs, 0.62)
	# The marker stays until the bubble lands on it; the bounce rings take over there.
	if (stage == "windup" and reveal > 0.0) or (stage == "flight" and _bounce_now < 0.0):
		var a := reveal * 0.85 if stage == "windup" else 0.85
		var spot := Vector3(bounce.x, ground + 0.03, bounce.z)
		var yaw := Basis(Vector3.UP, float(s.get("now", 0.0)) * 1.4)
		_place(_marker, spot, yaw, Vector3(0.34, 0.5, 0.34) * vs_mid, a)
	else:
		_marker.visible = false


func _draw_crown(stage: String, now: float, bubble_pos: Vector3, vs_f: float) -> void:
	if _launch_now < 0.0:
		for i in CROWN_COUNT:
			_crown[i].visible = false
			_crown_pop[i].visible = false
		return
	var rt := now - _launch_now
	if rt <= 0.15 and stage == "flight":
		_crown_adv = maxf(_crown_adv, (bubble_pos - _launch_pos).dot(_launch_dir))
	var cam_pos := _cam_pos(_launch_pos)
	var cb := _camera_aware_basis(_launch_dir, cam_pos, _launch_pos)
	for b in CROWN_COUNT:
		var layer := 1 if b >= 7 else 0
		var i := b % 7
		var pop_t := 0.20 + 0.14 * _h(b, 3.0)
		var t := minf(rt, pop_t)
		var e1 := _ease_out(clampf(t / 0.15, 0.0, 1.0))
		var e2 := _ease_out(clampf((t - 0.15) / 0.20, 0.0, 1.0))
		var ang := float(i) * TAU / 7.0 + float(layer) * 0.22
		var radial := lerpf(0.08, 0.62 if layer == 1 else 0.42, e1) * vs_f
		var along := _crown_adv * 0.35 * e1 - 0.42 * vs_f * e1 - float(layer) * 0.08 * vs_f
		var pos := _launch_pos + cb.x * cos(ang) * radial + cb.y * sin(ang) * radial + cb.z * along
		pos += Vector3.UP * 0.38 * vs_f * e2
		pos += cb.x * sin(t * 9.0 + float(b) * 1.7) * 0.04 * vs_f * e2
		var base := (lerpf(0.060, 0.090, _h(b, 4.0)) if layer == 1 else lerpf(0.085, 0.115, _h(b, 4.0))) * vs_f
		if rt < pop_t:
			var swell := lerpf(1.0, 1.28, clampf((rt - (pop_t - 0.04)) / 0.04, 0.0, 1.0))
			var born := clampf(rt / 0.04, 0.0, 1.0)
			_place(_crown[b], pos, Basis.IDENTITY, Vector3.ONE * base * swell * maxf(born, 0.05), 1.0)
			(_crown[b].material_override as ShaderMaterial).set_shader_parameter("wobble", 0.05)
			(_crown[b].material_override as ShaderMaterial).set_shader_parameter("flare", clampf((rt - (pop_t - 0.04)) / 0.04, 0.0, 1.0))
			_crown_pop[b].visible = false
		else:
			_crown[b].visible = false
			var pp := (rt - pop_t) / 0.14
			if pp < 1.0:
				var face := _basis_y((cam_pos - pos).normalized())
				_place(_crown_pop[b], pos, face, Vector3(1.0, 0.6, 1.0) * base * lerpf(1.0, 2.4, _ease_out(pp)), 1.0 - pp)
			else:
				_crown_pop[b].visible = false


func _draw_wake(stage: String, now: float, u: float, front: Vector3, bounce: Vector3, chest: Vector3, vs_f: float, vs_c: float) -> void:
	for i in WAKE_COUNT:
		var u_i := (float(i) + 0.5) / float(WAKE_COUNT)
		if _wake_born[i] < 0.0 and stage == "flight" and u >= u_i:
			_wake_born[i] = now
			var side := Vector3(_h(i, 5.0) - 0.5, _h(i, 6.0) * 0.4, _h(i, 7.0) - 0.5) * 0.22 * lerpf(vs_f, vs_c, u_i)
			_wake_pos[i] = _path(u_i, front, bounce, chest, vs_f, vs_c) + side
		if _wake_born[i] < 0.0:
			_wake[i].visible = false
			continue
		var life := 0.30 + 0.14 * _h(i, 8.0)
		var age := now - _wake_born[i]
		if age >= life:
			_wake[i].visible = false
			continue
		var p := age / life
		var vs := lerpf(vs_f, vs_c, u_i)
		var size := lerpf(0.045, 0.085, _h(i, 9.0)) * vs * minf(p / 0.15, 1.0) * lerpf(1.0, 1.25, smoothstep(0.85, 1.0, p))
		_place(_wake[i], _wake_pos[i] + Vector3.UP * 0.30 * vs * p, Basis.IDENTITY, Vector3.ONE * size, 1.0 - smoothstep(0.8, 1.0, p))
		(_wake[i].material_override as ShaderMaterial).set_shader_parameter("flare", smoothstep(0.85, 1.0, p))


func _draw_bounce(now: float, ground: float) -> void:
	var tb := now - _bounce_now if _bounce_now >= 0.0 else -1.0
	if tb < 0.0 or tb > BOUNCE_LEN:
		for mi in _b_rings:
			mi.visible = false
		for mi in _crests:
			mi.visible = false
		for mi in _b_minis:
			mi.visible = false
		return
	var vs := _bounce_vs
	var spot := Vector3(_bounce_pos.x, ground + 0.03, _bounce_pos.z)
	for i in 2:
		var p := clampf((tb - float(i) * 0.05) / (BOUNCE_LEN - 0.05), 0.0, 1.0)
		if p <= 0.0:
			_b_rings[i].visible = false
			continue
		var rad := lerpf(0.20, 1.15 if i == 0 else 0.92, _ease_out(p)) * vs
		_place(_b_rings[i], spot, Basis.IDENTITY, Vector3(rad, rad * 0.35, rad), 1.0 - p)
	# Mini-geyser: 8 crests leaning outward, born on contact, collapsed by 0.35 s.
	for i in CREST_COUNT:
		var ang := float(i) * TAU / float(CREST_COUNT) + 0.2
		var out := Vector3(cos(ang), 0.0, sin(ang))
		var rise := _ease_out(clampf(tb / 0.10, 0.0, 1.0)) * (1.0 - smoothstep(0.14, 0.35, tb))
		if rise <= 0.01:
			_crests[i].visible = false
			continue
		var h := 0.68 * vs * rise * lerpf(0.75, 1.0, _h(i, 10.0))
		var dir := (Vector3.UP + out * 0.55).normalized()
		var base := spot + out * 0.20 * vs
		_place(_crests[i], base + dir * h * 0.5, _basis_y(dir), Vector3(0.085 * vs, h, 0.085 * vs), 1.0 - smoothstep(0.22, 0.35, tb))
	for i in BOUNCE_MINI_COUNT:
		var pop_t := 0.20 + 0.22 * _h(i, 11.0)
		if tb >= pop_t:
			_b_minis[i].visible = false
			continue
		var ang := float(i) * TAU / float(BOUNCE_MINI_COUNT) + _h(i, 12.0)
		var out := Vector3(cos(ang), 0.0, sin(ang))
		var drag := (1.0 - exp(-4.0 * tb)) / 4.0
		var pos := spot + out * (1.6 + 1.2 * _h(i, 13.0)) * vs * drag + Vector3.UP * (0.10 + (1.4 * drag + 0.35 * tb)) * vs
		var size := lerpf(0.04, 0.07, _h(i, 14.0)) * vs * lerpf(1.0, 1.25, smoothstep(pop_t - 0.04, pop_t, tb))
		_place(_b_minis[i], pos, Basis.IDENTITY, Vector3.ONE * size, 1.0)
		(_b_minis[i].material_override as ShaderMaterial).set_shader_parameter("flare", smoothstep(pop_t - 0.04, pop_t, tb))


func _draw_impact(stage: String, s: Dictionary, ground: float, axis: Vector3, vs: float) -> void:
	var si := float(s.get("since_impact", -1.0)) if stage == "impact" else -1.0
	if si < 0.0 or si > IMPACT_LEN:
		for mi in _jets:
			mi.visible = false
		for mi in _burst_minis:
			mi.visible = false
		for mi in _drops:
			mi.visible = false
		_late_ring.visible = false
		_wet_ring.visible = false
		return
	var c: Vector3 = s.get("impact_chest", Vector3.ZERO)
	var sc := float(s.get("impact_scale", 1.0))
	var cam_pos := _cam_pos(c)
	var to_cam := cam_pos - c
	to_cam = to_cam.normalized() if to_cam.length_squared() > 0.0001 else Vector3.BACK
	var right := Vector3.UP.cross(to_cam)
	right = right.normalized() if right.length_squared() > 0.0001 else Vector3.RIGHT
	var up := to_cam.cross(right).normalized()

	# Hydraulic cross: +45, -45 on the camera plane and one jet through the target.
	var dirs: Array[Vector3] = [(right + up).normalized(), (right - up).normalized(), axis]
	var pj := clampf(si / 0.45, 0.0, 1.0)
	for i in 3:
		if pj >= 1.0:
			_jets[i].visible = false
			continue
		var half := 2.35 * sc * vs * 0.5 * _ease_out(clampf(si / 0.08, 0.0, 1.0)) * lerpf(1.0, 1.12, pj)
		var thick := 0.17 * sc * vs * pow(1.0 - pj, 0.8)
		_place(_jets[i], c, _basis_y(dirs[i]), Vector3(thick, maxf(half, 0.001), thick), 1.0 - smoothstep(0.55, 1.0, pj))

	# Water ring, 0.08 s late, facing the camera.
	var pr := (si - 0.08) / 0.52
	if pr > 0.0 and pr < 1.0:
		var rad := lerpf(0.22, 1.75, _ease_out(pr)) * sc * vs
		_place(_late_ring, c, _basis_y(to_cam), Vector3(rad, rad * 0.45, rad), 1.0 - pr * pr)
	else:
		_late_ring.visible = false

	# 20 hollow mini-bubbles: air drag, a soft floor bounce and a staggered pop.
	for i in BURST_MINI_COUNT:
		var pop_t := 0.28 + 0.45 * _h(i, 15.0)
		if si >= pop_t:
			_burst_minis[i].visible = false
			continue
		var dir := _sphere_dir(i, BURST_MINI_COUNT, 0.25)
		var size := lerpf(0.05, 0.11, _h(i, 16.0)) * vs
		var drag := (1.0 - exp(-3.2 * si)) / 3.2
		var pos := c + dir * (2.2 + 1.8 * _h(i, 17.0)) * vs * drag + Vector3.UP * 0.25 * vs * si
		if pos.y < ground + size:
			pos.y = ground + size + (ground + size - pos.y) * 0.4
		var swell := smoothstep(pop_t - 0.04, pop_t, si)
		_place(_burst_minis[i], pos, Basis.IDENTITY, Vector3.ONE * size * lerpf(1.0, 1.25, swell) * minf(si / 0.04, 1.0), 1.0)
		(_burst_minis[i].material_override as ShaderMaterial).set_shader_parameter("flare", swell)
		(_burst_minis[i].material_override as ShaderMaterial).set_shader_parameter("wobble", 0.05)

	# 24 drops: real gravity, bounce on the arena floor (restitution 0.58).
	var g := 9.8 * minf(vs, 1.6)
	for i in DROP_COUNT:
		var dir := _sphere_dir(i, DROP_COUNT, 0.45)
		var v0 := dir * (2.4 + 2.6 * _h(i, 18.0)) * minf(vs, 1.6)
		var st := _bounce_ballistic(c, v0, si, ground + 0.04 * vs, g, 0.58)
		var pos: Vector3 = st[0]
		var vel: Vector3 = st[1]
		var speed := vel.length()
		var d := vel / speed if speed > 0.01 else Vector3.DOWN
		_place(_drops[i], pos, _basis_y(d), Vector3(0.034, 0.055 + minf(speed, 8.0) * 0.012, 0.034) * vs, 1.0 - smoothstep(0.55, 0.80, si))

	# Wet ring spreading at the target's feet once the first water lands.
	var pw := (si - 0.18) / 0.55
	if pw > 0.0 and pw < 1.0:
		var feet := Vector3(c.x, ground + 0.03, c.z)
		var rw := lerpf(0.20, 1.15, _ease_out(pw)) * sc * vs
		_place(_wet_ring, feet, Basis.IDENTITY, Vector3(rw, rw * 0.3, rw), (1.0 - pw) * 0.85)
	else:
		_wet_ring.visible = false


# ------------------------------------------------------------------------- helpers

func _place(mi: MeshInstance3D, pos: Vector3, basis: Basis, scale3: Vector3, alpha: float) -> void:
	if alpha <= 0.004 or scale3.x <= 0.0 or scale3.y <= 0.0 or scale3.z <= 0.0:
		mi.visible = false
		return
	mi.visible = true
	mi.global_transform = Transform3D(Basis(basis.x * scale3.x, basis.y * scale3.y, basis.z * scale3.z), pos)
	(mi.material_override as ShaderMaterial).set_shader_parameter("alpha", clampf(alpha, 0.0, 1.0))


func _cam_pos(fallback_near: Vector3) -> Vector3:
	if camera != null and is_instance_valid(camera):
		return camera.global_position
	return fallback_near + Vector3(0.0, 2.0, 8.0)


func _side_of(dir: Vector3) -> Vector3:
	var ref := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
	return ref.cross(dir).normalized()


## Orthonormal basis with +Z along `dir`.
func _basis_z(dir: Vector3) -> Basis:
	var z := dir.normalized()
	var x := _side_of(z)
	return Basis(x, z.cross(x).normalized(), z)


## Orthonormal basis with +Y along `dir` (cylinders, cones, torus normals, spindles).
func _basis_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.98 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	return Basis(x, y, x.cross(y).normalized())


## Basis perpendicular to the launch direction, rolled so the 7 radial groups never
## line up with the camera (same rule as the prototype's build_camera_aware_basis).
func _camera_aware_basis(forward_dir: Vector3, cam_pos: Vector3, origin: Vector3) -> Basis:
	var f := forward_dir.normalized()
	var right := _side_of(f)
	var up := f.cross(right).normalized()
	var to_cam := cam_pos - origin
	var proj := to_cam - f * to_cam.dot(f)
	var roll := 0.20
	if proj.length_squared() > 0.0001:
		proj = proj.normalized()
		roll = atan2(proj.dot(right), proj.dot(up)) + 0.20
	return Basis(right, up, f).rotated(f, roll)


func _sphere_dir(i: int, count: int, up_bias: float) -> Vector3:
	var y := 1.0 - 2.0 * (float(i) + 0.5) / float(count)
	var rad := sqrt(maxf(1.0 - y * y, 0.0))
	var ang := float(i) * 2.39996
	return (Vector3(cos(ang) * rad, y + up_bias, sin(ang) * rad)).normalized()


## Position and velocity after `t` seconds of ballistic flight with floor bounces.
func _bounce_ballistic(p0: Vector3, v0: Vector3, t: float, floor_y: float, g: float, restitution: float) -> Array:
	var p := p0
	var v := v0
	var left := t
	for _i in 5:
		var h := p.y - floor_y
		var disc := v.y * v.y + 2.0 * g * maxf(h, 0.0)
		var t_hit := (v.y + sqrt(disc)) / g
		if left < t_hit or t_hit <= 0.0001:
			break
		p += Vector3(v.x * t_hit, 0.0, v.z * t_hit)
		p.y = floor_y
		v = Vector3(v.x * 0.7, -(v.y - g * t_hit) * restitution, v.z * 0.7)
		left -= t_hit
		if v.y < 0.25:
			return [p + Vector3(v.x, 0.0, v.z) * minf(left, 0.1), Vector3(v.x, 0.0, v.z)]
	return [p + v * left + Vector3.DOWN * 0.5 * g * left * left, v + Vector3.DOWN * g * left]


func _h(i: int, k: float) -> float:
	return fposmod(sin(float(i) * 12.9898 + k * 78.233) * 43758.5453, 1.0)


func _ease_out(p: float) -> float:
	var q := 1.0 - clampf(p, 0.0, 1.0)
	return 1.0 - q * q * q


func _ease_in(p: float) -> float:
	var q := clampf(p, 0.0, 1.0)
	return q * q


func _elastic_out(p: float) -> float:
	if p <= 0.0:
		return 0.0
	if p >= 1.0:
		return 1.0
	return pow(2.0, -10.0 * p) * sin((p * 10.0 - 0.75) * (TAU / 3.0)) + 1.0


## For tests and the leak audit: how many pieces are on screen by group.
func debug_state() -> Dictionary:
	var count := func(arr: Array) -> int:
		var n := 0
		for mi in arr:
			if (mi as MeshInstance3D).visible:
				n += 1
		return n
	return {
		"main": _main.visible, "core": _core.visible, "pressure": _pressure.visible,
		"main_pos": _main.global_position, "main_scale": _main.global_transform.basis.get_scale(),
		"micro": count.call(_micro), "guide": count.call(_guide), "marker": _marker.visible,
		"crown": count.call(_crown), "crown_pop": count.call(_crown_pop), "wake": count.call(_wake),
		"bounce_rings": count.call(_b_rings), "crests": count.call(_crests), "bounce_minis": count.call(_b_minis),
		"jets": count.call(_jets), "late_ring": _late_ring.visible, "wet_ring": _wet_ring.visible,
		"burst_minis": count.call(_burst_minis), "drops": count.call(_drops),
		"visible_total": count.call(_all), "bounce_pos": _bounce_pos, "launched": _launch_now >= 0.0,
	}
