class_name TidalSurgeVfx
extends ProjectileLibVfx
## D-1021: Water of the projectile library. Tidal Surge: START/WIND-UP is a water vortex on the floor IN FRONT of the
## caster; at RELEASE the vortex becomes the continuous water arc (the wide wave was discarded by the creator). The
## hero is hand-made (D-954); nothing depends on character, team or side (D-235).
## D-1077: visual overhaul WITH TEXTURES. The identity is still the V9 (tube arc + two strands + head, 3D crown of 16
## points, floor vortex, detaching tail consumed at the hit, bounce as a new wave); the meshes were refined and every
## water surface now uses the baked procedural texture `assets/vfx/water/water_flow.png` (caustic web, soft noise,
## foam breakup) through `lib_water_tex` / `lib_water_disc` / `lib_water_mist`. The crown and impact points are
## rounded water TONGUES, never sharp cones (they read as ice, D-397).

const IDS := ["tidal_surge"]
const SHADER := preload("res://shaders/lib_water_surface.gdshader")
const TEX_SHADER := preload("res://shaders/lib_water_tex.gdshader")
const DISC_SHADER := preload("res://shaders/lib_water_disc.gdshader")
const MIST_SHADER := preload("res://shaders/lib_water_mist.gdshader")
const FLOW_TEX := preload("res://assets/vfx/water/water_flow.png")

const WAVE_H := 5.2
const WAVE_W := 2.8
const DROPS := 14
const DROP_MIN := 0.035
const DROP_MAX := 0.075
## D-1021: the release is a continuous transition, never a cut. The vortex wears out while the jet ramps up.
const VORTEX_RELEASE_LEN := 0.40
const JET_RAMP := 0.22
const JET_BASE_R := 0.55
const JET_TAIL_SPAN := 0.55  ## D-1021: the tail is this fraction of the arc behind the head; it detaches after the peak.
const JET_SIDES := 12
## D-1078: the arc is 1.5x higher (was 0.24 / 2.2 / 7.0), for the main shot and for the bounces.
const ARC_PEAK_RATIO := 0.36
const ARC_PEAK_MIN := 3.3
const ARC_PEAK_MAX := 10.5
const JET_SPRAY := 26
const CROWN_LEN := 0.55
const CROWN_SPIKES := 16
const IMPACT_DROPS := 24
const IMPACT_MIST := 6
const GRAVITY := 13.0

const RING_CORE := Color(0.45, 0.90, 1.0)
const RING_MID := Color(0.08, 0.45, 0.95)
const RING_DEEP := Color(0.01, 0.10, 0.30)
const WAVE_CORE := Color(0.70, 0.96, 1.0)
const WAVE_MID := Color(0.12, 0.55, 0.95)
const WAVE_DEEP := Color(0.02, 0.12, 0.35)
const FOAM := Color(0.95, 1.0, 1.0)
const CORE_WHITE := Color(0.88, 1.0, 1.0)
const DROP_CORE := Color(0.65, 0.95, 1.0)
const DROP_MID := Color(0.15, 0.60, 0.98)
const DROP_DEEP := Color(0.02, 0.15, 0.45)

var _vortex_disc: MeshInstance3D
var _vortex_rim: MeshInstance3D
var _small_waves: MultiMeshInstance3D
var _small_mm: MultiMesh
var _core: MeshInstance3D
var _jet: MeshInstance3D
var _jet_heads: Array = []
var _crown_spikes: MultiMeshInstance3D
var _crown_mm: MultiMesh
var _crown_ring: MeshInstance3D
var _effect: MotionEffect
var _painter: MotionPainter
var _spray: MultiMeshInstance3D
var _spray_mm: MultiMesh
var _impact_spikes: MultiMeshInstance3D
var _impact_mm: MultiMesh
var _impact_flash: MeshInstance3D
var _impact_ring: MeshInstance3D
var _impact_drops: MultiMeshInstance3D
var _impact_drop_mm: MultiMesh
var _impact_mist: MultiMeshInstance3D
var _impact_mist_mm: MultiMesh
var _drops: Array = []
var bounce_visual := false  ## D-1021/D-1025: a bounce draws only the water body (no vortex/crown).
var _vortex_center := Vector3.ZERO
var _vortex_floor := 0.0
var _vortex_r := 0.9
var _vortex_h := 2.0


static func begin(p_fx: BattleFx, p_move: String, p_src: Vector3, targets: Array, windup: float,
		attacker: Combatant = null, target_list: Array = [], parent: Node = null) -> TidalSurgeVfx:
	var am: Node3D = null
	if p_fx != null and attacker != null:
		am = p_fx._models.get(attacker) as Node3D
	var tms: Array = []
	if p_fx != null:
		for t in target_list:
			tms.append(p_fx._models.get(t) as Node3D)
	# D-1021: the axis is measured from the real caster model, not from a remembered home point.
	var src := p_src
	if am != null and is_instance_valid(am):
		src = am.global_position
	var out := _setup(TidalSurgeVfx.new(), p_fx, p_move, src, targets, windup, parent, am, tms) as TidalSurgeVfx
	if am != null and is_instance_valid(am):
		# D-1021: the Water charge is the ground vortex at the FLOOR in front of the body. The base kept the centre
		# point for Electric and every other Move.
		var aim: Vector3 = (targets[0] as Vector3) if not targets.is_empty() else src + Vector3.FORWARD
		out.charge_pos = front_of_ground_model(am, src, aim)
		out.charge_pos.y = 0.0  # D-1021: the water charge sits on the arena floor, not on the model's AABB bottom.
		out.body_r = _last_body_r
		for b in out.beams:
			b["from"] = out.charge_pos
	return out


## D-1021/D-1025: the bounce of the Tidal chain. It draws only the water body (no vortex/crown) from the last target
## to the next; the tail detaches and follows the same arc. The hit itself is still decided by Battle.
static func bounce(p_fx: BattleFx, p_move: String, from: Vector3, to: Vector3, target: Combatant = null) -> TidalSurgeVfx:
	var tms: Array = []
	if p_fx != null and target != null:
		tms.append(p_fx._models.get(target))
	var out := _setup(TidalSurgeVfx.new(), p_fx, p_move, from, [to], 0.01, null, null, tms) as TidalSurgeVfx
	out.bounce_visual = true
	out.charge_pos = from
	for b in out.beams:
		b["from"] = from
	out.release(from, [to])
	return out


func beam_width() -> float:
	return 0.36


# --- Materials -------------------------------------------------------------------------


## The cel/fresnel water of small round things (droplets, the vortex core, the stream head).
func _mat(s: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("seed", s)
	m.render_priority = 2
	return m


func _tint(m: ShaderMaterial, core: Color, mid: Color, deep: Color) -> void:
	m.set_shader_parameter("core_color", core)
	m.set_shader_parameter("mid_color", mid)
	m.set_shader_parameter("deep_color", deep)


## D-1077: the textured water of every body, tongue and sheet.
func _tex_mat(s: float, uv_scale: Vector2, flow: Vector2, crest: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TEX_SHADER
	m.set_shader_parameter("flow_tex", FLOW_TEX)
	m.set_shader_parameter("seed", s)
	m.set_shader_parameter("deep_color", WAVE_DEEP)
	m.set_shader_parameter("mid_color", WAVE_MID)
	m.set_shader_parameter("core_color", WAVE_CORE)
	m.set_shader_parameter("foam_color", FOAM)
	m.set_shader_parameter("uv_scale", uv_scale)
	m.set_shader_parameter("flow", flow)
	m.set_shader_parameter("crest", crest)
	m.set_shader_parameter("alpha", 0.0)
	m.render_priority = 2
	return m


## D-1077: a quad lying on the floor that draws swirling water or a foam ring in polar coordinates.
func _disc_node(n: String, s: float, arms: float, swirl: float, spin: float, inflow: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0, 2.0)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = DISC_SHADER
	m.set_shader_parameter("flow_tex", FLOW_TEX)
	m.set_shader_parameter("seed", s)
	m.set_shader_parameter("deep_color", RING_DEEP)
	m.set_shader_parameter("mid_color", RING_MID)
	m.set_shader_parameter("core_color", RING_CORE)
	m.set_shader_parameter("foam_color", FOAM)
	m.set_shader_parameter("arms", arms)
	m.set_shader_parameter("swirl", swirl)
	m.set_shader_parameter("spin", spin)
	m.set_shader_parameter("inflow", inflow)
	m.set_shader_parameter("alpha", 0.0)
	m.render_priority = 1
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


func _sphere_node(n: String, s: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = _mat(s)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


func _mm_node(n: String, mesh: Mesh, count: int, mat: Material, custom := false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = custom
	mm.mesh = mesh
	mm.instance_count = count
	var mi := MultiMeshInstance3D.new()
	mi.name = n
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


func _drop_mesh() -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 8
	sm.rings = 4
	return sm


# --- Meshes ----------------------------------------------------------------------------


## D-1021: the cresting sheet mesh, used as the small water sheets of the vortex. UV = (across, height);
## UV2 is the texture space (D-1077).
func _make_wave_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := 14
	var rows := 12
	for r in rows + 1:
		var v := float(r) / float(rows)
		for c in cols + 1:
			var u := float(c) / float(cols)
			var profile := 0.30 + 0.70 * cos((u - 0.5) * PI)
			var x := (u - 0.5) * WAVE_W * (1.0 - 0.22 * v)
			var y := v * WAVE_H * profile
			var z := 0.95 * sin(PI * v) * (0.35 + 0.65 * (1.0 - absf(u - 0.5) * 2.0))
			st.set_uv(Vector2(u, v))
			st.set_uv2(Vector2(u * 1.4, v * 0.9))
			st.add_vertex(Vector3(x, y, z))
	for r in rows:
		for c in cols:
			var i0 := r * (cols + 1) + c
			var i1 := i0 + 1
			var i2 := i0 + cols + 1
			var i3 := i2 + 1
			st.add_index(i0)
			st.add_index(i2)
			st.add_index(i1)
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i3)
	st.generate_normals()
	return st.commit()


## D-1077: one rounded water TONGUE of the release crown and of the impact (it replaces the sharp cone, which read
## as an ice spike). A belly near the base, a round tip (never a point) and a curl outward (local -Z). Unit size:
## base diameter 1, height 1. UV.y is the height (0 base, 1 tip): the shader paints the foam tip there.
func _make_tongue_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 8
	const RINGS := 9
	for r in RINGS + 1:
		var v := float(r) / float(RINGS)
		# sin^0.6 closes with a vertical tangent: the tip is a dome, not a spike.
		var rad := 0.5 * pow(maxf(sin(PI * (0.15 + 0.85 * v)), 0.0), 0.6)
		var centre := Vector3(0.0, v, -0.34 * v * v)
		for k in SIDES + 1:
			var a := TAU * float(k) / float(SIDES)
			st.set_uv(Vector2(float(k) / float(SIDES), v))
			st.set_uv2(Vector2(float(k) / float(SIDES), v * 1.3))
			st.add_vertex(centre + Vector3(cos(a) * rad, 0.0, sin(a) * rad * 0.8))
	for r in RINGS:
		for k in SIDES:
			var i0 := r * (SIDES + 1) + k
			var i1 := i0 + 1
			var i2 := i0 + SIDES + 1
			var i3 := i2 + 1
			st.add_index(i0)
			st.add_index(i2)
			st.add_index(i1)
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i3)
	st.generate_normals()
	return st.commit()


# --- Build -----------------------------------------------------------------------------


func _build() -> void:
	# D-1021: the vortex is on the floor IN FRONT of the caster, sized like the Bubble Shield's body envelope.
	# `charge_pos` is the real front-of-body point on the shot axis.
	if attacker_model != null and is_instance_valid(attacker_model):
		var env := FxBubbleShield.body_envelope(attacker_model)
		_vortex_floor = 0.0  # D-1021: the arena floor is y = 0 (the model's AABB bottom floats above it).
		_vortex_center = Vector3(charge_pos.x, _vortex_floor, charge_pos.z)
		_vortex_r = maxf(float(env["radius"]), 0.45)
		_vortex_h = maxf(float(env["height"]), 0.8)
	else:
		_vortex_center = Vector3(charge_pos.x, 0.0, charge_pos.z)
		_vortex_floor = 0.0
		_vortex_r = 0.9
		_vortex_h = 2.0
	# START/WIND-UP: the swirling water on the floor (spiral arms pulled in) and a counter-turning foam rim.
	_vortex_disc = _disc_node("VortexDisc", 1.0, 3.0, 1.9, 1.15, 0.40)
	_vortex_rim = _disc_node("VortexRim", 2.0, 5.0, -0.6, -0.55, 0.0)
	(_vortex_rim.material_override as ShaderMaterial).set_shader_parameter("ring_inner", 0.66)
	(_vortex_rim.material_override as ShaderMaterial).set_shader_parameter("rim_foam", 0.16)
	(_vortex_rim.material_override as ShaderMaterial).render_priority = 2
	var small_mat := _tex_mat(6.5, Vector2(1.0, 1.0), Vector2(0.55, -0.35), 0.24)
	small_mat.set_shader_parameter("soft_base", 0.10)
	_small_waves = _mm_node("VortexWaveSheets", _make_wave_mesh(), 10, small_mat)
	_small_mm = _small_waves.multimesh
	_core = _sphere_node("VortexCore", 5.0)
	_tint(_core.material_override as ShaderMaterial, CORE_WHITE, RING_CORE, RING_DEEP)
	for i in DROPS:
		var d := _sphere_node("VortexDrop%d" % i, 10.0 + i)
		_tint(d.material_override as ShaderMaterial, DROP_CORE, DROP_MID, DROP_DEEP)
		_drops.append(d)
	# TRAJECTORY: the V9 water arc. UV2.x is METRES along the arc, so the caustic web flows toward the head.
	_jet = MeshInstance3D.new()
	_jet.name = "Jet"
	_jet.mesh = ImmediateMesh.new()
	var jet_mat := _tex_mat(7.0, Vector2(0.30, 1.0), Vector2(-1.25, 0.06), 0.34)
	jet_mat.set_shader_parameter("soft_tail", 0.26)
	_jet.material_override = jet_mat
	_jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_jet.visible = false
	add_child(_jet)
	var spray_mat := _mat(9.0)
	_tint(spray_mat, CORE_WHITE, RING_CORE, RING_MID)
	_spray = _mm_node("JetSpray", _drop_mesh(), JET_SPRAY, spray_mat)
	_spray_mm = _spray.multimesh
	# IMPACT/POST (D-1021/D-974): 16 water tongues opening in 360 degrees, a short foam burst, a foam ring on the
	# floor, droplets thrown on real arcs and a faint mist that evaporates. Nothing stays (no puddle/decal).
	var tongue := _make_tongue_mesh()
	var imat := _tex_mat(21.0, Vector2(1.0, 0.9), Vector2(0.10, -1.4), 0.30)
	imat.set_shader_parameter("soft_base", 0.14)
	imat.set_shader_parameter("use_instance", true)
	imat.set_shader_parameter("alpha", 1.0)
	_impact_spikes = _mm_node("ImpactCrown", tongue, CROWN_SPIKES, imat, true)
	_impact_mm = _impact_spikes.multimesh
	_impact_flash = _sphere_node("ImpactFoam", 22.0)
	_tint(_impact_flash.material_override as ShaderMaterial, FOAM, CORE_WHITE, RING_CORE)
	_impact_ring = _disc_node("ImpactRing", 23.0, 7.0, 0.25, 0.10, -0.55)
	(_impact_ring.material_override as ShaderMaterial).set_shader_parameter("rim_foam", 0.20)
	var dmat := _mat(24.0)
	_tint(dmat, DROP_CORE, DROP_MID, DROP_DEEP)
	_impact_drops = _mm_node("ImpactDrops", _drop_mesh(), IMPACT_DROPS, dmat)
	_impact_drop_mm = _impact_drops.multimesh
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var mist_mat := ShaderMaterial.new()
	mist_mat.shader = MIST_SHADER
	mist_mat.set_shader_parameter("flow_tex", FLOW_TEX)
	mist_mat.render_priority = 3
	_impact_mist = _mm_node("ImpactMist", quad, IMPACT_MIST, mist_mat, true)
	_impact_mist_mm = _impact_mist.multimesh
	# RELEASE (D-1021): the 3D water crown: 16 rounded water tongues around the vortex and a foam ring that opens on
	# the floor, plus the Motion Composer ring of water drops painted in `_paint_motion`. No 2D sprite.
	var cmat := _tex_mat(11.0, Vector2(1.0, 0.9), Vector2(0.10, -1.4), 0.30)
	cmat.set_shader_parameter("soft_base", 0.14)
	cmat.set_shader_parameter("use_instance", true)
	cmat.set_shader_parameter("alpha", 1.0)
	_crown_spikes = _mm_node("ReleaseCrown", tongue, CROWN_SPIKES, cmat, true)
	_crown_mm = _crown_spikes.multimesh
	_crown_ring = _disc_node("ReleaseRing", 12.0, 7.0, 0.25, 0.10, -0.55)
	(_crown_ring.material_override as ShaderMaterial).set_shader_parameter("rim_foam", 0.20)
	_painter = MotionPainter.new()
	_painter.cam_pos_fn = func() -> Vector3: return fx.cam.camera.global_position if fx != null and fx.cam != null and fx.cam.camera != null else Vector3(0, 3, 8)
	_painter.cam_basis_fn = func() -> Basis: return fx.cam.camera.global_transform.basis if fx != null and fx.cam != null and fx.cam.camera != null else Basis.IDENTITY
	_painter.visible = false
	add_child(_painter)
	_effect = _make_water_effect()
	for i in beams.size():
		var h := _sphere_node("JetHead%d" % i, 20.0 + i)
		_tint(h.material_override as ShaderMaterial, FOAM, WAVE_CORE, WAVE_MID)
		h.visible = false
		_jet_heads.append(h)


## D-1021: the Motion Composer drives the secondary water of the release: the crown ring is a 3D ring (M01) of small
## water drops. It never decides the hit or the path: the game hands origin/dest/head (D-019, D-235).
func _make_water_effect() -> MotionEffect:
	var fx_mc := MotionEffect.new()
	var crown := MotionComposition.new()
	crown.id = &"tidal_crown"
	crown.seed = 11
	crown.sample_count = 24
	crown.duration = 1.0
	var ring := MotionLayer.new()
	ring.id = &"ring"
	ring.behavior_id = &"M01"
	ring.op = MotionTypes.Op.REPLACE
	ring.params = {"radius": 1.25, "radius_growth": 0.0, "pitch": 0.0, "turns": 1.0, "direction": 1, "spin_deg_s": 50.0}
	crown.add_layer(ring)
	# D-1077: the drops vanish one by one (jitter), not as an arc swept from one side, and they are small: at 0.20 m
	# and scaled by the ring they read as flat white discs sliding on the floor.
	crown.add_layer(_dissolve_layer(0.04, 0.30, 0.8))
	fx_mc.add("release", crown, [
		MotionRep.make("drops", {"element": "water", "size": 0.075, "stretch": 1.6})
	], {"length": 0.01, "dir": "up", "ground": true, "z_offset": 0.25, "scalable": true})
	# D-1077: the travel wake of Composer drops was REMOVED by the creator ("remove isso"): it read as a row of flat
	# pale discs behind the head and stayed beside the target after the hit. The hand-made spray stays.
	return fx_mc


static func _dissolve_layer(p_start: float, p_len: float, p_jitter := 0.0) -> MotionLayer:
	var d := MotionLayer.new()
	d.id = &"dissolve"
	d.behavior_id = &"M18"
	d.op = MotionTypes.Op.MULTIPLY_ATTRIBUTE
	d.params = {"direction": 0, "t_start": p_start, "t_duration": p_len, "curve": 1.0, "width": 0.25, "jitter": p_jitter,
		"affect_visibility": false, "affect_width": false, "affect_intensity": false, "affect_opacity": true}
	return d


# --- Render ----------------------------------------------------------------------------


func _render() -> void:
	var c := charge_pos
	var released := _release_t >= 0.0
	if bounce_visual:
		_draw_jet()
		_paint_motion(c)
		_draw_impact()
		return
	var vk := clampf((t - _release_t) / VORTEX_RELEASE_LEN, 0.0, 1.0) if released else 0.0
	var appear := clampf(t / 0.12, 0.0, 1.0)
	var spin := t * 4.5
	if vk < 1.0:
		var va := 1.0 - vk
		# Vortex: swirling textured water on the floor with a foam rim; at the release it erodes, it is not cut.
		var breathe := 1.0 + 0.04 * sin(t * 5.0)
		_vortex_disc.visible = true
		_vortex_disc.position = _vortex_center + Vector3.UP * 0.03
		_vortex_disc.scale = Vector3.ONE * (_vortex_r * 1.12 * appear * breathe)
		var dm := _vortex_disc.material_override as ShaderMaterial
		dm.set_shader_parameter("alpha", 0.95)
		dm.set_shader_parameter("fade", vk)
		_vortex_rim.visible = true
		_vortex_rim.position = _vortex_center + Vector3.UP * 0.05
		_vortex_rim.scale = Vector3.ONE * (_vortex_r * 1.30 * appear * (2.0 - breathe))
		var rm := _vortex_rim.material_override as ShaderMaterial
		rm.set_shader_parameter("alpha", 0.9)
		rm.set_shader_parameter("fade", vk)
		var small_n := _small_mm.instance_count
		var small_s := clampf(_vortex_r * 0.065, 0.07, 0.16)
		for i in small_n:
			var ang := TAU * float(i) / float(small_n) + spin * 1.8
			# Uneven radius and height: a ring of water that laps, not a row of equal shells.
			var rr := _vortex_r * (1.0 + 0.10 * float(i % 2) + 0.06 * sin(t * 3.1 + float(i) * 2.2))
			var bob := 0.03 + 0.04 * sin(t * 6.0 + float(i) * 1.3)
			var tall := 1.0 + 0.35 * sin(t * 4.3 + float(i) * 1.9)
			var p := _vortex_center + Vector3(cos(ang), 0.0, sin(ang)) * rr + Vector3.UP * bob
			var yaw := atan2(cos(ang), sin(ang))
			var basis := Basis(Vector3.UP, yaw).scaled(Vector3(3.6, tall, 1.0) * small_s)
			_small_mm.set_instance_transform(i, Transform3D(basis, p))
		_small_waves.visible = appear > 0.05
		var sm := _small_waves.material_override as ShaderMaterial
		sm.set_shader_parameter("alpha", 0.95)
		sm.set_shader_parameter("fade", vk)
		_core.visible = true
		_core.position = _vortex_center + Vector3.UP * 0.16
		var cr := (0.16 + 0.04 * sin(t * 18.0)) * appear
		_core.scale = Vector3.ONE * cr
		(_core.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.95 * va)
		# Droplets: a rising, swirling veil around the vortex.
		var rise := maxf(_vortex_h * 0.8, 0.5)
		for i in _drops.size():
			var ang := TAU * float(i) / float(DROPS) + spin * 0.7
			var rr := _vortex_r * (0.22 + 0.68 * fmod(float(i) * 0.37 + t * 0.22, 1.0))
			var h := 0.06 + fmod(float(i) * 0.19 + t * 0.70, 1.0) * rise
			var p := _vortex_center + Vector3(cos(ang), 0.0, sin(ang)) * rr + Vector3.UP * h
			var s := lerpf(DROP_MAX, DROP_MIN, clampf(h / rise, 0.0, 1.0)) * appear
			var mi := _drops[i] as MeshInstance3D
			mi.visible = appear > 0.05
			mi.position = p
			mi.scale = Vector3(s, s * 1.5, s)
			(mi.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.9 * va)
			(mi.material_override as ShaderMaterial).set_shader_parameter("fade", clampf(h / (rise + 0.05), 0.0, 1.0))
	else:
		_hide_charge()
	if released:
		_draw_jet()
		_draw_crown(c)
		_paint_motion(c)
		_draw_impact()


## The continuous water jet born from the vortex at the release. The vortex erodes while this grows, so the charge
## does not disappear: it becomes the shot (D-308). The arc, the irregular water body and the spray are the hand-made
## hero (D-954).
func _draw_jet() -> void:
	var im := _jet.mesh as ImmediateMesh
	im.clear_surfaces()
	var any := false
	# D-1021: the jet does not pop in; it ramps up while the vortex pours into it.
	# A bounce flies for only 0.3 s (D-1025): the release ramp would hide most of it, so it is born almost solid.
	var alpha := smoothstep(0.0, 0.05 if bounce_visual else JET_RAMP, t - _release_t)
	var body_fade := 0.0
	var tail_soft := 0.26
	for i in beams.size():
		var b: Dictionary = beams[i]
		var head := _jet_heads[i] as MeshInstance3D
		if b["state"] == "charge":
			continue
		var a: Vector3 = charge_pos
		var bpos: Vector3 = b["to"]
		var p := clampf(float(b["p"]), 0.0, 1.0)
		var la := alpha * (1.0 - beam_fade(i))
		var consume := 0.0
		if b["state"] == "hit":
			consume = clampf((t - float(b["hit_t"])) / IMPACT_LEN, 0.0, 1.0)
		if p <= 0.01 or la <= 0.01 or consume >= 0.98:
			head.visible = false
			continue
		var dist := a.distance_to(bpos)
		var peak := _arc_peak(dist)
		var tail_p := maxf(0.0, p - JET_TAIL_SPAN)
		tail_p = lerpf(tail_p, p, consume)
		var path := _jet_path(a, bpos, peak, tail_p, p)
		var tip := path[path.size() - 1]
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_water_tube(im, path, JET_BASE_R, float(i) * 3.7, tail_p * dist, true)
		# Two water strands braided around the body: they break the pipe silhouette and read as flowing water.
		var pp := _perp(bpos - a)
		for s in 2:
			var strand := PackedVector3Array()
			for k in path.size():
				var u := float(k) / float(path.size() - 1)
				var ang := u * TAU * 1.55 + t * 3.6 + float(s) * PI
				var amp := (0.50 + 0.14 * sin(t * 5.0 + float(s) * 2.0 + u * 7.0)) * sin(PI * u)
				strand.append(path[k] + (pp[0] as Vector3) * cos(ang) * amp + (pp[1] as Vector3) * sin(ang) * amp)
			_water_tube(im, strand, 0.17, 10.0 + float(s), tail_p * dist + 1.7 * float(s + 1), false)
		im.surface_end()
		# The head is a small foam cap that closes the rounded front of the body, not a separate ball.
		head.visible = true
		head.position = tip
		head.scale = Vector3(0.40, 0.34, 0.40) * (1.0 + 0.06 * sin(t * 30.0)) * (1.0 - 0.6 * consume)
		(head.material_override as ShaderMaterial).set_shader_parameter("alpha", la * 0.92)
		if i == 0:
			_draw_spray(path, la)
		# A miss dissolves by erosion (the stream falls apart); a hit is consumed by its own tail.
		if b["state"] == "miss":
			body_fade = maxf(body_fade, beam_fade(i))
		# While the tail eats the body the ragged tail zone shrinks with it, or the whole stub would turn to foam.
		tail_soft = minf(tail_soft, 0.26 * (1.0 - consume))
		any = true
	_jet.visible = any
	var jm := _jet.material_override as ShaderMaterial
	jm.set_shader_parameter("alpha", alpha)
	jm.set_shader_parameter("fade", body_fade)
	jm.set_shader_parameter("soft_tail", tail_soft)
	if not any:
		_spray.visible = false


## One tongue of a crown (release or impact). `k` is the 0..1 life: it shoots up, leans outward and falls apart.
## `unit` is the size unit in metres (fixed at the release; the target body radius at the impact, D-974).
func _crown_instance(mm: MultiMesh, i: int, centre: Vector3, unit: float, k: float, spread: float) -> void:
	# Deterministic per-tongue variety: alternating tall/short, with a small delay, so it is a splash, not a gear.
	var h1 := fmod(float(i) * 0.618 + 0.13, 1.0)
	var h2 := fmod(float(i) * 0.371 + 0.47, 1.0)
	var big := 1.0 if i % 2 == 0 else 0.62
	var kk := clampf((k - h2 * 0.10) / 0.90, 0.0, 1.0)
	var rise := 1.0 - pow(1.0 - clampf(kk / 0.32, 0.0, 1.0), 3.0)
	var fall := smoothstep(0.30, 1.0, kk)
	var e := 1.0 - pow(1.0 - kk, 3.0)
	var a := TAU * (float(i) + (h1 - 0.5) * 0.5) / float(CROWN_SPIKES) + 0.15
	var out := Vector3(cos(a), 0.0, sin(a))
	var tilt := lerpf(0.22, 0.92, e) + (h1 - 0.5) * 0.25
	var axis := (out * sin(tilt) + Vector3.UP * cos(tilt)).normalized()
	var x := out.cross(Vector3.UP).normalized()
	var z := x.cross(axis).normalized()
	var length := unit * big * (0.35 + 1.25 * rise) * (1.0 - 0.70 * fall) * (0.85 + 0.30 * h2)
	var width := unit * (0.36 + 0.14 * h1) * (0.75 + 0.25 * big) * (1.0 + 0.25 * fall)
	var basis := Basis(x * width, axis * length, z * width)
	var base := Vector3(centre.x, 0.02, centre.z) + out * unit * lerpf(0.25, spread, e)
	mm.set_instance_transform(i, Transform3D(basis, base))
	# It erodes while it sinks and is fully gone before the end: no white shells left lying on the floor.
	var appear := smoothstep(0.0, 0.06, kk) * (1.0 - smoothstep(0.72, 0.92, kk))
	mm.set_instance_custom_data(i, Color(float(i) * 1.7, smoothstep(0.30, 0.86, kk), 0.0, appear))


## D-1021: the release water crown: 16 rounded water tongues expand around the vortex and a foam ring opens on the
## floor; the Motion Composer ring of drops is painted in `_paint_motion`. Everything erodes away. No 2D sprite.
func _draw_crown(c: Vector3) -> void:
	var ck := clampf((t - _release_t) / CROWN_LEN, 0.0, 1.0)
	var vis := ck < 1.0
	_crown_spikes.visible = vis
	_crown_ring.visible = vis
	if not vis:
		return
	for i in CROWN_SPIKES:
		_crown_instance(_crown_mm, i, c, 1.0, ck, 1.45)
	var e := 1.0 - pow(1.0 - ck, 3.0)
	_crown_ring.position = Vector3(c.x, 0.04, c.z)
	_crown_ring.scale = Vector3.ONE * lerpf(0.6, 2.9, e)
	var rm := _crown_ring.material_override as ShaderMaterial
	rm.set_shader_parameter("ring_inner", lerpf(0.30, 0.74, e))
	rm.set_shader_parameter("alpha", smoothstep(0.0, 0.08, ck) * 0.9)
	rm.set_shader_parameter("fade", smoothstep(0.30, 1.0, ck))


## D-1021/D-974: radial water impact at the target. The radius is measured from the real target body
## (height x 0.55, clamped 0.9..2.2 m), so it does not look like it hits the ally next to it.
func _draw_impact() -> void:
	var drawn := false
	var total := IMPACT_LEN + POST_LEN
	for i in beams.size():
		var b: Dictionary = beams[i]
		if b["state"] != "hit":
			continue
		var age := t - float(b["hit_t"])
		if age < 0.0 or age > total:
			continue
		var pos: Vector3 = b["hit_pos"]
		var ground := Vector3(pos.x, 0.0, pos.z)
		var tm: Node3D = null
		if i < target_models.size():
			tm = target_models[i] as Node3D
		var body := body_of_model(tm, pos)
		var h := maxf(float(body[2]), 0.8)
		var r := clampf(h * 0.55, 0.9, 2.2)
		var k := clampf(age / total, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		# Foam burst at the contact: small and short, it must not hide the target behind a white ball.
		var flash := smoothstep(0.0, 0.03, age) * (1.0 - smoothstep(0.04, 0.16, age))
		_impact_flash.visible = flash > 0.01
		if _impact_flash.visible:
			_impact_flash.position = pos
			_impact_flash.scale = Vector3(1.0, 0.7, 1.0) * r * lerpf(0.22, 0.42, clampf(age / 0.16, 0.0, 1.0))
			(_impact_flash.material_override as ShaderMaterial).set_shader_parameter("alpha", flash * 0.6)
		# Crown of water tongues opening in 360 degrees around the target.
		for j in CROWN_SPIKES:
			_crown_instance(_impact_mm, j, ground, r * 0.62, k, 2.3)
		_impact_spikes.visible = true
		# Foam ring racing over the floor, then eroding.
		_impact_ring.visible = true
		_impact_ring.position = ground + Vector3.UP * 0.04
		_impact_ring.scale = Vector3.ONE * r * lerpf(0.5, 2.5, e)
		var rm := _impact_ring.material_override as ShaderMaterial
		rm.set_shader_parameter("ring_inner", lerpf(0.25, 0.76, e))
		rm.set_shader_parameter("alpha", smoothstep(0.0, 0.04, age) * 0.9)
		rm.set_shader_parameter("fade", smoothstep(0.28, 1.0, k))
		# Droplets thrown outward on real arcs (launch speed + gravity); each one ends when it reaches the floor.
		for j in IMPACT_DROPS:
			var h1 := fmod(float(j) * 0.618 + 0.21, 1.0)
			var h2 := fmod(float(j) * 0.371 + 0.09, 1.0)
			var a2 := TAU * (float(j) + h1) / float(IMPACT_DROPS)
			var out2 := Vector3(cos(a2), 0.0, sin(a2))
			var vel := out2 * r * (1.8 + 2.6 * h2) + Vector3.UP * (3.2 + 3.4 * h1) * sqrt(r)
			var start := ground + Vector3.UP * (h * (0.30 + 0.35 * h2)) + out2 * r * 0.25
			var dp := start + vel * age + Vector3.DOWN * 0.5 * GRAVITY * age * age
			var now := vel + Vector3.DOWN * GRAVITY * age
			var ds := r * (0.035 + 0.035 * h1) * (1.0 - smoothstep(0.75, 1.0, k))
			if dp.y < 0.03:
				ds = 0.0
			var up := now.normalized() if now.length() > 0.01 else Vector3.UP
			var side := up.cross(Vector3.RIGHT)
			if side.length() < 0.01:
				side = up.cross(Vector3.FORWARD)
			side = side.normalized()
			var basis := Basis(side * ds, up * ds * 1.9, side.cross(up).normalized() * ds)
			_impact_drop_mm.set_instance_transform(j, Transform3D(basis, dp))
		_impact_drops.visible = true
		(_impact_drops.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.92)
		# Faint mist that lifts and evaporates.
		for j in IMPACT_MIST:
			var h3 := fmod(float(j) * 0.618 + 0.33, 1.0)
			var a3 := TAU * float(j) / float(IMPACT_MIST) + 0.6
			var out3 := Vector3(cos(a3), 0.0, sin(a3))
			var mp := ground + out3 * r * (0.35 + 0.55 * e) + Vector3.UP * (h * (0.25 + 0.30 * h3) + 0.55 * age)
			var ms := r * lerpf(0.35, 0.85, e) * (0.8 + 0.4 * h3)
			_impact_mist_mm.set_instance_transform(j, Transform3D(Basis().scaled(Vector3.ONE * ms), mp))
			_impact_mist_mm.set_instance_custom_data(j, Color(float(j) * 2.3, smoothstep(0.25, 1.0, k), 0.0,
				smoothstep(0.02, 0.12, age)))
		_impact_mist.visible = true
		drawn = true
	if not drawn:
		_impact_spikes.visible = false
		_impact_flash.visible = false
		_impact_ring.visible = false
		_impact_drops.visible = false
		_impact_mist.visible = false


## D-1021: Motion Composer layers for the release crown ring (3D) and the travel water wake. The game supplies the
## real positions and the phase clock; the effect only paints (D-019, D-235).
func _paint_motion(c: Vector3) -> void:
	if _painter == null or _effect == null:
		return
	_painter.visible = true
	_painter.time = t
	_painter.begin_frame()
	var rel := t - _release_t
	var rk := clampf(rel / CROWN_LEN, 0.0, 1.0)
	if not bounce_visual:
		_effect.draw(_painter, "release", rel, {"origin": c, "dest": c, "head": c, "axis": Vector3.UP,
			"k": rk, "p": 0.0, "scale": 1.0 + rk * 1.8, "landed": false})
	_painter.end_frame()


## Water droplets falling off the arc: they give the shot weight and an aquatic trail.
func _draw_spray(path: PackedVector3Array, alpha: float) -> void:
	if path.size() < 3:
		_spray.visible = false
		return
	var pp := _perp(path[path.size() - 1] - path[0])
	for i in JET_SPRAY:
		var u := fmod(float(i) * 0.173 + t * 0.55, 1.0)
		var idx := clampi(int(u * float(path.size() - 1)), 0, path.size() - 1)
		var base := path[idx]
		var ang := float(i) * 2.399
		var rad := 0.45 + 0.40 * fmod(float(i) * 0.37, 1.0)
		var off := (pp[0] as Vector3) * cos(ang) * rad + (pp[1] as Vector3) * sin(ang) * rad
		var fall := fmod(t * 1.4 + float(i) * 0.29, 1.0)
		# Teardrops: stretched while they fall, shrinking as they go.
		var s := (0.045 + 0.065 * fmod(float(i) * 0.61, 1.0)) * (1.0 - 0.6 * fall)
		var basis := Basis().scaled(Vector3(s, s * (1.2 + 1.2 * fall), s))
		_spray_mm.set_instance_transform(i, Transform3D(basis, base + off + Vector3.DOWN * fall * fall * 1.1))
	_spray.visible = alpha > 0.02
	(_spray.material_override as ShaderMaterial).set_shader_parameter("alpha", alpha * 0.85)
	(_spray.material_override as ShaderMaterial).set_shader_parameter("fade", 0.0)


func _hide_charge() -> void:
	_vortex_disc.visible = false
	_vortex_rim.visible = false
	_small_waves.visible = false
	_core.visible = false
	for d in _drops:
		(d as MeshInstance3D).visible = false



# --- Jet geometry ----------------------------------------------------------------------


## D-1021: a full ballistic arc: it rises from the caster, peaks at the middle and comes down on the target.
static func _arc_peak(dist: float) -> float:
	return clampf(dist * ARC_PEAK_RATIO, ARC_PEAK_MIN, ARC_PEAK_MAX)


func _arc_point(a: Vector3, b: Vector3, peak: float, u: float) -> Vector3:
	var p := a.lerp(b, u)
	p.y += peak * 4.0 * u * (1.0 - u)
	# A slow lateral undulation, zero at both ends, so the stream does not read as a straight pipe.
	var pp := _perp(b - a)
	var wave := sin(u * PI * 2.0 - t * 2.4) * 0.25 * sin(PI * u)
	p += (pp[0] as Vector3) * wave
	return p


## The arc between the moving tail (from_p) and the head (to_p). The body is a segment, not the whole caster->target
## line: after the head advances, the tail leaves the floor and follows it (D-1021).
func _jet_path(a: Vector3, b: Vector3, peak: float, from_p: float, to_p: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var span := maxf(to_p - from_p, 0.001)
	var n := clampi(int(a.distance_to(b) * span / 0.40), 6, 56)
	for k in n + 1:
		var u := lerpf(from_p, to_p, float(k) / float(n))
		out.append(_arc_point(a, b, peak, u))
	return out


## The water tube of the V9 body. UV = (0 tail .. 1 head, top side): the shader puts the broken foam crest on top of
## the arc and breaks the tail up. UV2 = (metres along the arc, around): the caustic web is anchored to the arc and
## flows to the head, so the body reads as running water and not as a striped pipe (D-1077).
## `shaped`: the main body thickens from a thin tail to a rounded, heavier front; the strands keep a simple belly.
func _water_tube(im: ImmediateMesh, pts: PackedVector3Array, base_r: float, seed: float, start_m: float, shaped: bool) -> void:
	if pts.size() < 2:
		return
	var sides := JET_SIDES if shaped else 6
	var rings: Array = []
	var metres := PackedFloat32Array()
	var run := start_m
	for i in pts.size():
		if i > 0:
			run += pts[i].distance_to(pts[i - 1])
		metres.append(run)
		var u := float(i) / float(pts.size() - 1)
		var tan := pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]
		var pp := _perp(tan)
		var prof := 0.62 + 0.38 * sin(PI * u)
		if shaped:
			prof = lerpf(0.34, 1.0, smoothstep(0.0, 0.62, u))
			prof *= 1.0 + 0.16 * smoothstep(0.55, 0.86, u)
			if u > 0.86:
				var w := (u - 0.86) / 0.14
				prof *= sqrt(maxf(1.0 - w * w * 0.90, 0.0))
		# Waves of thickness that travel down the body (anchored in metres, not in ring index).
		var rip := 1.0 + 0.11 * sin(run * 2.6 - t * 9.0 + seed) + 0.07 * sin(run * 1.1 + t * 5.0 + seed * 1.7)
		var rr := base_r * prof * rip
		var ring := []
		for k in sides:
			var ang := TAU * float(k) / float(sides)
			var nrm: Vector3 = (pp[0] as Vector3) * cos(ang) + (pp[1] as Vector3) * sin(ang)
			# The top bulges and breaks a little more than the belly: an uneven crest line.
			var crest := 1.0 + 0.10 * maxf(nrm.y, 0.0) * sin(run * 4.3 - t * 11.0 + seed * 2.3)
			ring.append([pts[i] + nrm * rr * crest, nrm, float(k) / float(sides)])
		rings.append(ring)
	for i in pts.size() - 1:
		var u0 := float(i) / float(pts.size() - 1)
		var u1 := float(i + 1) / float(pts.size() - 1)
		for k in sides:
			var k1 := (k + 1) % sides
			var v0: Array = rings[i][k]
			var v1: Array = rings[i][k1]
			var v2: Array = rings[i + 1][k]
			var v3: Array = rings[i + 1][k1]
			var a0 := float(k) / float(sides)
			var a1 := float(k + 1) / float(sides)
			for v in [[v0, u0, metres[i], a0], [v2, u1, metres[i + 1], a0], [v1, u0, metres[i], a1],
					[v1, u0, metres[i], a1], [v2, u1, metres[i + 1], a0], [v3, u1, metres[i + 1], a1]]:
				var nrm: Vector3 = (v[0] as Array)[1]
				im.surface_set_normal(nrm)
				im.surface_set_uv(Vector2(float(v[1]), 0.5 + 0.5 * nrm.y))
				im.surface_set_uv2(Vector2(float(v[2]), float(v[3])))
				im.surface_add_vertex((v[0] as Array)[0])


static func _perp(axis: Vector3) -> Array:
	var a := axis.normalized() if axis.length() > 0.0001 else Vector3.FORWARD
	var u := a.cross(Vector3.UP)
	if u.length() < 0.01:
		u = a.cross(Vector3.RIGHT)
	u = u.normalized()
	return [u, a.cross(u).normalized()]
