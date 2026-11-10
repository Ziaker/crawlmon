class_name ElectricBeamVfx
extends ProjectileLibVfx
## D-957: Electric of the projectile library: a continuous golden beam from the caster to each target, with electric
## filaments, like Zeri's W (Immortal Journey). Golden to the end, no Glow (D-337). The hero (charge orb, beam,
## filaments, flashes, impact arcs) is hand-made geometry with `lib_electric_beam.gdshader` (D-954/D-956); the
## Composer only paints the secondary sparks (MotionPresets.electric_beam_effect, V1.11). Fixed metres (D-308 item 6).

const IDS := ["electric_beam"]
const WIDTH := 0.34  ## beam core diameter, metres, the same in both views
const SHADER := preload("res://shaders/lib_electric_beam.gdshader")
const JAG := 0.08  ## core zig-zag amplitude (m)
const FIL_JAG := 0.28  ## filament zig-zag amplitude (m)
const FILAMENTS := 2
const IMPACT_ARCS := 6
const POST_WINDUP_R := 0.95  ## D-968: bigger final size  ## D-965: radius reached at the end of the held charge (m)
const POST_WINDUP_GROW := 0.8
const ORB_FADE_AFTER_SHOT := 0.6  ## D-968: the sphere keeps its size and fades naturally 0.6 s after the shot  ## s: measured held time of the projectile Moves (D-957)
const ORB_PULSE := 0.25  ## D-974
const ORB_PULSE_MAX := 1.4  ## D-974: m, not immense
const GROUND_RING_LEN := 0.35  ## D-974
const BOLT_SEG := 2.6  ## D-966: zig-zag segment length along the beam (m)
const BOLT_AMP := 1.0  ## D-966: zig-zag sideways amplitude (m), sharp bends
const BOLT_HZ := 6.0  ## D-966: the bolt snaps to a new path this many times per second
const GLOW_BEAM_SIZE := 1.6
const GLOW_BEAM_A := 0.32
const GLOW_COLOR := Color(1.0, 0.82, 0.12)  # D-967: saturated yellow
const GLOW_MAX := 400
const THICK := 1.8  ## D-960: thicker rays (still fixed metres, the same in both views) so they read at ~37 m

var _beam_nodes: Array = []  ## one MeshInstance3D (ImmediateMesh) per beam: core + filaments
var _arc_node: MeshInstance3D  ## charge arcs + impact arcs
var _crown_node: MeshInstance3D  ## D-958: release crown that splits backward in 5 parts
var _burst_node: MeshInstance3D  ## D-959: 0.2 s electric burst at the shot
var _burst_flash: MeshInstance3D
var _orb: MeshInstance3D
var _flashes: Array = []  ## one per beam (impact flash) + index 0.. ; release flash is _rel_flash
var _rel_flash: MeshInstance3D
var _start_flash: MeshInstance3D
var _light: OmniLight3D  ## D-962: real golden light on the charge / shot (lights the caster and the floor)
var _impact_lights: Array = []  ## D-962: one per beam
var _flash_models: Dictionary = {}  ## D-962: beam index -> hit model (white-gold hit flash, 2-3 frames)
const LIGHT_COLOR := Color(1.0, 0.82, 0.38)
const HIT_FLASH_LEN := 0.1
var _glow: MultiMeshInstance3D  ## D-966: fake glow sprites (additive, camera-facing)
var _glow_n := 0
var _painter: MotionPainter
# D-969: flipbooks driven by the effect's own clock (ring + star at each impact, animated sparks).
const USE_COMPOSER_SPARKS := false  ## D-969: replaced by the flipbook sparks (creator to confirm)
const FB_SHADER := preload("res://shaders/flipbook.gdshader")
const RING_LEN := 0.7  ## D-972: longer
const RING_SIZE := 5.0  ## D-972: bigger
const STAR_LEN := 0.4
const STAR_SIZE := 3.6
const FB_COLOR := Color(1.0, 0.86, 0.1)
const SPARKS_IMPACT := 10
const SPARK_IMPACT_LEN := 0.45
const SPARKS_WINDUP := 6
const SPARK_WINDUP_LEN := 0.3
const SPARK_SIZE := 0.45
var _rings: Array = []
var _stars: Array = []
var _sparks_hit: Array = []  ## per beam: Array of MeshInstance3D
var _sparks_wind: Array = []
# D-970: trail left in the air along the beam + shock pillar around each target.
const TRAIL_N := 12  ## drop points along each beam
const TRAIL_LIFE := 0.45
const PILLAR_BOLTS := 6
const PILLAR_LEN := 1.0  ## D-973: resolution of the impact crowns (no own post-impact)
const PILLAR_EMERGE := 0.25  ## D-975
const NO_STUN_SIZE := 0.75  ## D-978: 25% smaller without STUN
const NO_STUN_TIME := 0.65  ## D-978: 35% shorter without STUN
var _stun: Dictionary = {}  ## beam index -> true when that hit stunned (full pillar)
const PILLAR_EXPAND := 0.6
const PILLAR_CROWNS := 4
const PILLAR_PARTS := 5
const PILLAR_OPEN := 0.55  ## D-974: smaller opening  ## crowns open to (1 + this) x their start radius
const PILLAR_RISE := 0.7  ## m the crowns climb while opening
const PILLAR_OVER := 0.35  ## m above the head ("um pouco acima")
const PILLAR_GAP := 0.3  ## m outside the body
const PILLAR_SIDE := 3  ## subtle side discharges per frame
var _extras: MeshInstance3D
# D-971: head on the tip + staggered impact (flash 0, star, pillar, ring + sparks).
const HEAD_R := 0.38
const STAR_DELAY := 0.03
const RING_DELAY := 0.09
var _heads: Array = []
# D-972: animated shock-burst pillar (ref. Zio, P5R).
const COL_SLAM := 0.1
const COL_HOLD := 0.45
const COL_BREAK := 0.75
const SIDE_SPARKS := 14
var _side_sparks: Array = []
var _trail_born: Array = []  ## per beam: Array[float] birth time per drop (-1 = not yet)
var _trail_sparks: Array = []  ## per beam: Array of flipbook sparks
var _bodies: Dictionary = {}  ## beam -> body_of() measured at the hit
var _effect: MotionEffect


static func begin(p_fx: BattleFx, p_move: String, p_src: Vector3, targets: Array, windup: float, parent: Node = null) -> ElectricBeamVfx:
	return _setup(ElectricBeamVfx.new(), p_fx, p_move, p_src, targets, windup, parent) as ElectricBeamVfx


func beam_width() -> float:
	return WIDTH


# --- Build -----------------------------------------------------------------------------


func _mat(s: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("seed", s)
	return m


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


func _imm_node(n: String, s: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = ImmediateMesh.new()
	mi.material_override = _mat(s)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _cyl_node(n: String, s: float, a: float, core: float, mid: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = 20
	cm.rings = 1
	cm.cap_top = false
	cm.cap_bottom = false
	mi.mesh = cm
	var m := _mat(s)
	m.set_shader_parameter("alpha", a)
	m.set_shader_parameter("core_cut", core)
	m.set_shader_parameter("mid_cut", mid)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


func _jag_loop(c: Vector3, r: float, sd: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for k in 33:
		var a := float(k) / 32.0 * TAU
		out.append(c + Vector3(cos(a), 0.0, sin(a)) * (r + (rng.randf_range(-0.06, 0.06) if k % 32 != 0 else 0.0)))
	return out


func _circle(c: Vector3, r: float, n: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for k in n + 1:
		var a := float(k) / float(n) * TAU
		out.append(c + Vector3(cos(a), 0.0, sin(a)) * r)
	return out


func _fb_node(n: String, sheet: String, size: float, energy: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = FB_SHADER
	m.set_shader_parameter("sheet_tex", VfxLib.flipbook_tex(sheet))
	m.set_shader_parameter("color", FB_COLOR)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("h_frames", 4)
	m.set_shader_parameter("v_frames", 4)
	m.set_shader_parameter("progress", 0.0)
	mi.material_override = m
	mi.scale = Vector3.ONE * size
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


## D-969: show one flipbook at `pos`, `k` 0..1 through its frames (hidden outside), fading in the last third.
func _fb(mi: MeshInstance3D, pos: Vector3, k: float, size: float, roll: float) -> void:
	mi.visible = k >= 0.0 and k < 1.0
	if not mi.visible:
		return
	mi.position = pos
	mi.scale = Vector3.ONE * size
	var m := mi.material_override as ShaderMaterial
	m.set_shader_parameter("progress", k)
	m.set_shader_parameter("roll_rad", roll)
	m.set_shader_parameter("color", Color(FB_COLOR, clampf((1.0 - k) * 3.0, 0.0, 1.0)))


func _draw_flipbooks(c: Vector3, r: float, ph: Phase) -> void:
	for i in beams.size():
		var b: Dictionary = beams[i]
		var lt0 := t - float(b["hit_t"]) if b["state"] == "hit" else -1.0
		var hp: Vector3 = b["hit_pos"]
		var roll := float(i) * 1.7
		var lts := lt0 - STAR_DELAY if lt0 >= STAR_DELAY else -1.0
		var lt := lt0 - RING_DELAY if lt0 >= RING_DELAY else -1.0
		_fb(_rings[i], hp, lt / RING_LEN if lt >= 0.0 else -1.0, RING_SIZE * lerpf(0.8, 1.15, clampf(lt / RING_LEN, 0.0, 1.0)), roll)
		_fb(_stars[i], hp, lts / STAR_LEN if lts >= 0.0 else -1.0, STAR_SIZE, roll + 0.6)
		var row: Array = _sparks_hit[i]
		for k in row.size():
			var rng := RandomNumberGenerator.new()
			rng.seed = i * 977 + k * 31 + 5
			var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1), rng.randf_range(-1, 1)).normalized()
			var spd := rng.randf_range(3.0, 6.0)
			var life := SPARK_IMPACT_LEN * rng.randf_range(0.7, 1.0)
			var kk := lt / life if lt >= 0.0 else -1.0
			var tt := maxf(lt, 0.0)
			var p := hp + d * spd * tt + Vector3.DOWN * 4.0 * tt * tt
			_fb(row[k], p, kk, SPARK_SIZE * rng.randf_range(0.7, 1.2), rng.randf() * TAU)
	# Wind-up sparks: loose crackles around the growing sphere, each on its own loop (stop at the shot).
	for k in _sparks_wind.size():
		var on := ph in [Phase.START, Phase.WINDUP]
		var lt2 := fmod(t + float(k) * SPARK_WINDUP_LEN / float(SPARKS_WINDUP), SPARK_WINDUP_LEN)
		var cyc := int(floor((t + float(k) * SPARK_WINDUP_LEN / float(SPARKS_WINDUP)) / SPARK_WINDUP_LEN))
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = cyc * 53 + k * 7 + 3
		var d2 := Vector3(rng2.randf_range(-1, 1), rng2.randf_range(-0.6, 1), rng2.randf_range(-1, 1)).normalized()
		var p2 := c + d2 * (r * 1.1 + lt2 * 1.6)
		_fb(_sparks_wind[k], p2, lt2 / SPARK_WINDUP_LEN if on else -1.0, SPARK_SIZE * 0.8, rng2.randf() * TAU)


func _draw_trail_and_pillar() -> void:
	var im := _extras.mesh as ImmediateMesh
	im.clear_surfaces()
	(_extras.material_override as ShaderMaterial).set_shader_parameter("alpha", 1.0)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	var step := int(floor(t * 18.0))
	for i in beams.size():
		var b: Dictionary = beams[i]
		if b["state"] == "charge":
			continue
		var a: Vector3 = b["from"]
		var to: Vector3 = b["to"]
		var p := float(b["p"]) if b["state"] == "fly" else 1.0
		var hd := _heads[i] as MeshInstance3D
		hd.visible = b["state"] == "fly" and p > 0.02
		if hd.visible:
			var tip := beam_tip(i)
			hd.position = tip
			hd.scale = Vector3.ONE * HEAD_R * (1.0 + 0.15 * sin(t * 55.0 + float(i)))
			(hd.material_override as ShaderMaterial).set_shader_parameter("fade", 0.0)
			(hd.material_override as ShaderMaterial).set_shader_parameter("flicker", 1.0)
			_glow_add(tip, 2.4, 0.8)
		var axis := (to - a).normalized()
		var side := axis.cross(Vector3.UP).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		# Trail: each drop is born when the tip passes it, then crackles and fades in the air.
		for j in TRAIL_N:
			var f := (float(j) + 0.5) / float(TRAIL_N)
			if float(_trail_born[i][j]) < 0.0 and p >= f and b["state"] == "fly":
				_trail_born[i][j] = t
			var bt := float(_trail_born[i][j])
			var lt := t - bt if bt >= 0.0 else -1.0
			var rng := RandomNumberGenerator.new()
			rng.seed = i * 4099 + j * 61 + 9
			var off := side * rng.randf_range(-0.6, 0.6) + Vector3.UP * rng.randf_range(-0.4, 0.5)
			var base := a.lerp(to, f) + off
			var drift := Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-1.2, 0.4), rng.randf_range(-0.5, 0.5))
			var kk := lt / TRAIL_LIFE if lt >= 0.0 else -1.0
			_fb(_trail_sparks[i][j], base + drift * maxf(lt, 0.0), kk, SPARK_SIZE * rng.randf_range(0.6, 1.0), rng.randf() * TAU)
			if kk >= 0.0 and kk < 0.75 and (step + j) % 3 != 0:
				var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
				var ln := rng.randf_range(0.25, 0.5) * (1.0 - kk)
				_tube(im, _jag(base, base + d * ln, 0.08, step * 7 + j + i * 31, 0.12), 0.012 * THICK)
				any = true
		# D-973 pillar: stacked crowns of zig-zag rays, born AT the contact around the body, opening outward and upward
		# in 360 degrees and breaking into parts; short vertical links tie them in the first instants.
		if b["state"] != "hit":
			continue
		var full := bool(_stun.get(i, false))
		var tk := 1.0 if full else NO_STUN_TIME  # D-978
		var sk_size := 1.0 if full else NO_STUN_SIZE
		var lt_hit := (t - float(b["hit_t"])) / tk  # the whole pillar runs on a scaled clock
		var em := 1.0 - pow(1.0 - clampf(lt_hit / PILLAR_EMERGE, 0.0, 1.0), 2.0)  # D-975: out of the enemy in 0.25 s
		var lt2 := maxf(lt_hit - PILLAR_EMERGE, 0.0)
		if lt_hit > PILLAR_EMERGE + PILLAR_LEN:
			for sp in _side_sparks[i]:
				(sp as MeshInstance3D).visible = false
			continue
		if not _bodies.has(i):
			_bodies[i] = body_of(fx, b["hit_pos"])
		var body: Array = _bodies[i]
		var g: Vector3 = body[0]
		var rad := (float(body[1]) + PILLAR_GAP) * sk_size
		var top := (float(body[2]) + PILLAR_OVER) * sk_size
		var bs := clampf(float(body[2]) / 1.6, 0.45, 1.2) * sk_size  # D-974: body scale (1 = a 1.6 m tall body)
		# D-974: thin ground ring on contact, 0.35 s.
		var gk := lt_hit / GROUND_RING_LEN
		if gk < 1.0:
			_tube(im, _jag_loop(g + Vector3.UP * 0.05, lerpf(rad * 0.8, rad * 2.2, 1.0 - pow(1.0 - gk, 2.0)), step + i * 7), 0.03 * THICK * bs * (1.0 - gk))
		var ek := clampf(lt2 / PILLAR_EXPAND, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - ek, 2.5)
		var split := clampf((lt2 - 0.08) / 0.3, 0.0, 1.0)
		var dk := clampf((lt2 - PILLAR_EXPAND) / (PILLAR_LEN - PILLAR_EXPAND), 0.0, 1.0)
		var wk := (1.0 - dk) * (0.6 + 0.4 * float((step + i) % 2))  # thinning + crackle flicker
		if not full:
			# D-978: gradual opacity over the shorter life (the trail/pillar mesh dissolves as one).
			(_extras.material_override as ShaderMaterial).set_shader_parameter("alpha", 1.0 - clampf(lt_hit / (PILLAR_EMERGE + PILLAR_LEN), 0.0, 1.0))
		var heights: Array = []
		for ci in PILLAR_CROWNS:
			var f := (float(ci) + 0.3) / (float(PILLAR_CROWNS) - 0.7)
			var y := top * clampf(f, 0.0, 1.0) + PILLAR_RISE * bs * e * (0.6 + 0.4 * f)
			var cr := rad * (1.0 + PILLAR_OPEN * e) * lerpf(1.0, 0.8, f) * lerpf(0.12, 1.0, em)
			y = lerpf(float(body[2]) * 0.5, y, em)
			var spin := (1.0 if ci % 2 == 0 else -1.0) * 1.4
			heights.append([y, cr])
			for part in PILLAR_PARTS:
				var a0 := TAU * float(part) / PILLAR_PARTS + TAU * spin * lt2 + 0.7 * ci
				var a1 := a0 + TAU / PILLAR_PARTS - 0.05 - 0.45 * split
				var mid := (a0 + a1) * 0.5
				var out := Vector3(cos(mid), 0.0, sin(mid))
				var centre := g + Vector3.UP * y + out * (rad * 0.25 * split * e)
				var pts := PackedVector3Array()
				var rng5 := RandomNumberGenerator.new()
				rng5.seed = step * 31 + part + ci * 977 + i * 13
				for k in 7:
					var ang := lerpf(a0, a1, float(k) / 6.0)
					pts.append(centre + Vector3(cos(ang), 0.0, sin(ang)) * (cr + rng5.randf_range(-0.12, 0.12) * bs) + Vector3.UP * rng5.randf_range(-0.12, 0.12) * bs)
				_tube(im, pts, 0.045 * THICK * wk * bs)
				# a short ray kicked outward from each part (the 360-degree crackle)
				var base := centre + out * cr
				_tube(im, _jag(base, base + (out + Vector3.UP * 0.4).normalized() * 0.5 * bs * (1.0 - dk), 0.08 * bs, step * 7 + part + ci * 51, 0.14), 0.025 * THICK * wk * bs)
				_glow_add(base, 1.2 * bs, 0.35 * (1.0 - dk))
		# vertical links between crowns: the "pillar", only in the first instants, then they let go.
		var lk := 1.0 - clampf(lt2 / 0.25, 0.0, 1.0)
		if lk > 0.0:
			for ci in PILLAR_CROWNS - 1:
				for n in 4:
					var ang6 := TAU * (float(n) + 0.5 * ci) / 4.0 + t * 2.0
					var o6 := Vector3(cos(ang6), 0.0, sin(ang6))
					var p_lo: Vector3 = g + Vector3.UP * float(heights[ci][0]) + o6 * float(heights[ci][1])
					var p_hi: Vector3 = g + Vector3.UP * float(heights[ci + 1][0]) + o6 * float(heights[ci + 1][1])
					_tube(im, _jag(p_lo, p_hi, 0.15 * bs, step * 17 + n + ci * 7 + i * 3, 0.25), 0.035 * THICK * lk * bs)
		# Side sparks: burst out sideways from the base when the column breaks (subtle, D-970).
		var ssr: Array = _side_sparks[i]
		for k in ssr.size():
			var rng4 := RandomNumberGenerator.new()
			rng4.seed = i * 733 + k * 19 + 2
			var born := 0.1 + float(k) * 0.025
			var slt := lt2 - born
			var life := rng4.randf_range(0.35, 0.55)
			var ang4 := rng4.randf() * TAU
			var dir4 := Vector3(cos(ang4), rng4.randf_range(0.05, 0.35), sin(ang4))
			var p4 := g + Vector3(cos(ang4), 0.0, sin(ang4)) * rad + Vector3.UP * rng4.randf_range(0.1, top * 0.5)
			var tt4 := maxf(slt, 0.0)
			_fb(ssr[k], p4 + dir4 * rng4.randf_range(3.5, 6.5) * bs * tt4 + Vector3.DOWN * 2.0 * tt4 * tt4, slt / life if slt >= 0.0 else -1.0, SPARK_SIZE * rng4.randf_range(0.8, 1.3), rng4.randf() * TAU)
		any = true
	if any:
		im.surface_end()
	else:
		im.clear_surfaces()


func _build() -> void:
	_orb = _sphere_node("ChargeOrb", 1.0)
	_start_flash = _sphere_node("StartFlash", 2.0)
	_rel_flash = _sphere_node("ReleaseFlash", 3.0)
	_arc_node = _imm_node("Arcs", 4.0)
	_crown_node = _imm_node("ReleaseCrown", 5.0)
	_burst_node = _imm_node("ReleaseBurst", 6.0)
	_burst_flash = _sphere_node("BurstFlash", 7.0)
	for i in beams.size():
		_beam_nodes.append(_imm_node("Beam%d" % i, 10.0 + i))
		(_beam_nodes[i].material_override as ShaderMaterial).set_shader_parameter("core_cut", 0.35)  # D-965: wider bright core
		(_beam_nodes[i].material_override as ShaderMaterial).set_shader_parameter("mid_cut", 0.1)
		_flashes.append(_sphere_node("ImpactFlash%d" % i, 20.0 + i))
		_heads.append(_sphere_node("Head%d" % i, 40.0 + i))
		var ss: Array = []
		for k in SIDE_SPARKS:
			ss.append(_fb_node("SideSpark%d_%d" % [i, k], "lightning", SPARK_SIZE, 3.8))
		_side_sparks.append(ss)
		_rings.append(_fb_node("ImpactRing%d" % i, "lightning", RING_SIZE, 3.4))
		_stars.append(_fb_node("ImpactStar%d" % i, "impact", STAR_SIZE, 3.6))
		var row: Array = []
		for k in SPARKS_IMPACT:
			row.append(_fb_node("HitSpark%d_%d" % [i, k], "lightning", SPARK_SIZE, 3.8))
		_sparks_hit.append(row)
	_extras = _imm_node("TrailAndPillar", 30.0)
	for i in beams.size():
		var born: Array = []
		var sp: Array = []
		for j in TRAIL_N:
			born.append(-1.0)
			sp.append(_fb_node("TrailSpark%d_%d" % [i, j], "lightning", SPARK_SIZE, 3.8))
		_trail_born.append(born)
		_trail_sparks.append(sp)
	for k in SPARKS_WINDUP:
		_sparks_wind.append(_fb_node("WindSpark%d" % k, "lightning", SPARK_SIZE, 3.8))
	_light = _omni("ChargeLight")
	_glow = MultiMeshInstance3D.new()
	_glow.name = "FakeGlow"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mm.mesh = quad
	mm.instance_count = GLOW_MAX
	mm.visible_instance_count = 0
	_glow.multimesh = mm
	var gm := ShaderMaterial.new()
	gm.shader = preload("res://shaders/lib_glow_sprite.gdshader")
	_glow.material_override = gm
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)
	for i in beams.size():
		_impact_lights.append(_omni("ImpactLight%d" % i))
	if fx != null:
		_painter = MotionPainter.new()
		_painter.cam_pos_fn = func() -> Vector3: return cam_pos()
		_painter.cam_basis_fn = func() -> Basis: return fx.cam.camera.global_transform.basis if fx.cam != null and fx.cam.camera != null else Basis.IDENTITY
		add_child(_painter)
		_effect = MotionPresets.effect_for(move_id, randi())


func _omni(n: String) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = n
	l.light_color = LIGHT_COLOR
	l.omni_range = 4.5
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	l.light_energy = 0.0
	l.visible = false
	add_child(l)
	return l


func _set_light(l: OmniLight3D, pos: Vector3, energy: float) -> void:
	l.visible = energy > 0.01
	l.position = pos
	l.light_energy = energy


## D-962: the body that was hit flashes white-gold for 2-3 frames (the game's flash overlay, VfxLib.ensure_flash).
func _hit_flash(i: int, hp: Vector3, lt: float) -> void:
	if fx == null:
		return
	if not _flash_models.has(i):
		var best: Node3D = null
		var best_d := 4.0
		for m in fx._models.values():
			if is_instance_valid(m):
				var d := Vector2((m as Node3D).global_position.x - hp.x, (m as Node3D).global_position.z - hp.z).length()
				if d < best_d:
					best_d = d
					best = m
		_flash_models[i] = best
	var model: Variant = _flash_models[i]
	if model == null or not is_instance_valid(model):
		return
	var mat := VfxLib.ensure_flash(model)
	if lt < HIT_FLASH_LEN:
		mat.set_shader_parameter("color", Color(1.0, 0.95, 0.72))
		mat.set_shader_parameter("amount", 0.85)
	elif lt < HIT_FLASH_LEN + 0.1:
		mat.set_shader_parameter("amount", 0.0)
		mat.set_shader_parameter("color", Color(1, 1, 1))  # shared overlay: leave it as the game expects


# --- Geometry --------------------------------------------------------------------------


static func _perp(axis: Vector3) -> Array:
	var a := axis.normalized() if axis.length() > 0.0001 else Vector3.FORWARD
	var u := a.cross(Vector3.UP)
	if u.length() < 0.01:
		u = a.cross(Vector3.RIGHT)
	u = u.normalized()
	return [u, a.cross(u).normalized()]


## A zig-zag polyline from a to b; the bends change in steps (`rate` per second), ends pinned.
static func _jag(a: Vector3, b: Vector3, amp: float, step_seed: int, seg_len := 0.6) -> PackedVector3Array:
	var out := PackedVector3Array()
	var d := b - a
	var n := clampi(int(d.length() / seg_len), 2, 80)
	var pp := _perp(d)
	var rng := RandomNumberGenerator.new()
	rng.seed = step_seed
	for i in n + 1:
		var u := float(i) / float(n)
		var p := a.lerp(b, u)
		if i > 0 and i < n:
			p += (pp[0] as Vector3) * rng.randf_range(-amp, amp) + (pp[1] as Vector3) * rng.randf_range(-amp, amp)
		out.append(p)
	return out


## A 6-sided tube along a polyline (volume, so it never disappears edge-on; protocol, section 6).
static func _tube(im: ImmediateMesh, pts: PackedVector3Array, radius: float) -> void:
	if pts.size() < 2 or radius <= 0.0005:
		return
	const SIDES := 6
	var rings: Array = []
	for i in pts.size():
		var tan := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)])
		var pp := _perp(tan)
		var ring := []
		for k in SIDES:
			var ang := TAU * float(k) / float(SIDES)
			var nrm: Vector3 = (pp[0] as Vector3) * cos(ang) + (pp[1] as Vector3) * sin(ang)
			ring.append([pts[i] + nrm * radius, nrm])
		rings.append(ring)
	for i in pts.size() - 1:
		var u0 := float(i) / float(pts.size() - 1)
		var u1 := float(i + 1) / float(pts.size() - 1)
		for k in SIDES:
			var k1 := (k + 1) % SIDES
			var v0: Array = rings[i][k]
			var v1: Array = rings[i][k1]
			var v2: Array = rings[i + 1][k]
			var v3: Array = rings[i + 1][k1]
			var vk := float(k) / SIDES
			var vk1 := float(k + 1) / SIDES
			for v in [[v0, u0, vk], [v2, u1, vk], [v1, u0, vk1], [v1, u0, vk1], [v2, u1, vk], [v3, u1, vk1]]:
				im.surface_set_normal((v[0] as Array)[1])
				im.surface_set_uv(Vector2(v[1], v[2]))
				im.surface_add_vertex((v[0] as Array)[0])


# --- Render ----------------------------------------------------------------------------


func _charge_point() -> Vector3:
	return (beams[0]["from"] as Vector3) if not beams.is_empty() else src


func _pop(mi: MeshInstance3D, pos: Vector3, k: float, r_max: float) -> void:
	if k < 0.0 or k >= 1.0:
		mi.visible = false
		return
	mi.visible = true
	mi.position = pos
	var r := r_max * sin(PI * clampf(k, 0.0, 1.0)) + 0.02
	mi.scale = Vector3.ONE * r
	(mi.material_override as ShaderMaterial).set_shader_parameter("fade", clampf((k - 0.6) / 0.4, 0.0, 1.0))


func _render() -> void:
	_glow_n = 0
	var ph := phase()
	var c := _charge_point()
	var step := int(floor(t * 20.0))
	# START: the snap that triggers the wind-up (inside its first instants).
	_pop(_start_flash, c, t / START_LEN, 0.6)
	# WINDUP -> held -> muzzle while flying: the same orb, never cut (D-308 item 5).
	var post_k := 0.0
	if _release_t >= 0.0:
		var done := true
		var max_fade := 1.0
		for i in beams.size():
			done = done and beams[i]["state"] in ["hit", "miss"]
			max_fade = minf(max_fade, beam_fade(i))
		post_k = max_fade if done else 0.0
	var grow := clampf(t / windup_len, 0.0, 1.0)
	var r := lerpf(0.1, 0.32, 1.0 - pow(1.0 - grow, 2.0)) + 0.03 * sin(t * 40.0)
	if _release_t < 0.0 and t > windup_len:
		# D-965: post-wind-up (the prelude of the release): the shock sphere keeps growing until the shot.
		r = lerpf(0.32, POST_WINDUP_R, clampf((t - windup_len) / POST_WINDUP_GROW, 0.0, 1.0)) + 0.04 * sin(t * 40.0)
	var orb_fade := post_k
	if _release_t >= 0.0:
		# D-968: no shrink at the shot: the sphere keeps the size it reached and dissolves over 0.6 s.
		r = lerpf(0.32, POST_WINDUP_R, clampf((_release_t - windup_len) / POST_WINDUP_GROW, 0.0, 1.0))
		# D-974: swell to 2x (max 1.4 m) and back within 0.25 s, then dissolve until 0.6 s after the shot.
		var pk := clampf((t - _release_t) / ORB_PULSE, 0.0, 1.0)
		r += (minf(r * 2.0, ORB_PULSE_MAX) - r) * sin(PI * pk)
		orb_fade = clampf((t - _release_t - ORB_PULSE) / (ORB_FADE_AFTER_SHOT - ORB_PULSE), 0.0, 1.0)
	_orb.visible = orb_fade < 1.0
	_orb.position = c
	_orb.scale = Vector3.ONE * r
	var om := _orb.material_override as ShaderMaterial
	om.set_shader_parameter("fade", orb_fade * orb_fade)
	om.set_shader_parameter("flicker", 1.0)
	# RELEASE flash at the muzzle.
	_pop(_rel_flash, c, (t - _release_t) / 0.16 if _release_t >= 0.0 else -1.0, 0.7)
	_draw_crown(c)
	_draw_burst(c)
	# Arcs: crackle around the charge (wind-up and while firing), radial arcs at each impact.
	var arcs := _arc_node.mesh as ImmediateMesh
	arcs.clear_surfaces()
	arcs.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	if post_k < 0.6:
		var rng := RandomNumberGenerator.new()
		rng.seed = step * 7 + 1
		for k in 3:
			var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1), rng.randf_range(-1, 1)).normalized()
			_tube(arcs, _jag(c + d * r, c + d * (r + rng.randf_range(0.3, 0.6)), 0.08, step * 13 + k, 0.12), 0.02 * THICK)
			any = true
	for i in beams.size():
		var b: Dictionary = beams[i]
		if b["state"] != "hit":
			continue
		var lt := t - float(b["hit_t"])
		if lt > IMPACT_LEN + POST_LEN * 0.5:
			continue
		var hp: Vector3 = b["hit_pos"]
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = step * 11 + i * 101
		var shrink := 1.0 - clampf((lt - IMPACT_LEN) / (POST_LEN * 0.5), 0.0, 1.0)
		for k in IMPACT_ARCS:
			var d2 := Vector3(rng2.randf_range(-1, 1), rng2.randf_range(-0.4, 1), rng2.randf_range(-1, 1)).normalized()
			_tube(arcs, _jag(hp, hp + d2 * rng2.randf_range(0.8, 1.4) * shrink, 0.14, step * 17 + k + i * 7, 0.2), 0.03 * THICK)
			any = true
	if any:
		arcs.surface_end()
	else:
		arcs.clear_surfaces()
	# Beams: core + filaments, from the muzzle to the tip; each dissolves golden in its own POST.
	for i in beams.size():
		var b: Dictionary = beams[i]
		var node := _beam_nodes[i] as MeshInstance3D
		var im := node.mesh as ImmediateMesh
		im.clear_surfaces()
		if b["state"] == "charge":
			continue
		var fade := beam_fade(i)
		if fade >= 1.0:
			continue
		var a: Vector3 = b["from"]
		var tip := beam_tip(i)
		if a.distance_to(tip) < 0.05:
			continue
		var mat := node.material_override as ShaderMaterial
		mat.set_shader_parameter("fade", fade)
		mat.set_shader_parameter("flicker", 1.0)
		var bolt := _bolt(a, b["to"], float(b["p"]) if b["state"] == "fly" else 1.0, int(floor(t * BOLT_HZ)) * 7 + i * 1000)
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_tube(im, bolt, WIDTH * 0.5 * (1.0 - 0.4 * fade))
		for k in FILAMENTS:
			_tube(im, _around(bolt, FIL_JAG, int(floor(t * 16.0)) * 5 + k * 77 + i * 1000), 0.035 * THICK)
		im.surface_end()
		for q in range(0, bolt.size(), 1):
			_glow_add(bolt[q], GLOW_BEAM_SIZE, GLOW_BEAM_A * (1.0 - fade))
		# D-967: the translucent halo tube was removed (it read as a mustard overlay); the glow sprites do its job.
		# IMPACT flash on this target.
		var fl := _flashes[i] as MeshInstance3D
		_pop(fl, b["hit_pos"], (t - float(b["hit_t"])) / 0.18 if b["state"] == "hit" else -1.0, 0.85)
	# D-962 lights: charge grows, the shot spikes (with the 0.2 s burst), flying keeps a glow, POST dims it.
	var le := 2.4 * grow
	if _release_t >= 0.0:
		var rk := (t - _release_t) / BURST_LEN
		le = 7.5 * (1.0 - clampf(rk, 0.0, 1.0)) + 2.4
	_set_light(_light, c, le * (1.0 - post_k))
	for i in beams.size():
		var bb: Dictionary = beams[i]
		if bb["state"] == "hit":
			var ltt := t - float(bb["hit_t"])
			_set_light(_impact_lights[i], bb["hit_pos"], 9.0 * clampf(1.0 - ltt / 0.35, 0.0, 1.0))
			_hit_flash(i, bb["hit_pos"], ltt)
		else:
			_set_light(_impact_lights[i], Vector3.ZERO, 0.0)
	# D-966 fake glow on the charge, the shot burst and each impact (the beam's own glow was added with the bolt).
	if orb_fade < 1.0:
		_glow_add(c, r * 5.0, 0.55 * (1.0 - orb_fade))
	if _release_t >= 0.0:
		var bk := (t - _release_t) / BURST_LEN
		if bk < 1.0:
			_glow_add(c, lerpf(1.5, 4.0, bk), 0.9 * (1.0 - bk))
	for i in beams.size():
		var bh: Dictionary = beams[i]
		if bh["state"] == "hit":
			var hk := (t - float(bh["hit_t"])) / 0.45
			if hk < 1.0:
				_glow_add(bh["hit_pos"], lerpf(2.2, 4.2, hk), 0.85 * (1.0 - hk))
	_draw_trail_and_pillar()
	_glow.multimesh.visible_instance_count = _glow_n
	_draw_flipbooks(c, r, ph)
	# Composer secondary: crackle sparks on the charge, burst sparks on each impact.
	if _painter != null and USE_COMPOSER_SPARKS:
		_painter.time = t
		_painter.begin_frame()
		var axis := ((beams[0]["to"] as Vector3) - c).normalized() if not beams.is_empty() else Vector3.FORWARD
		if ph in [Phase.START, Phase.WINDUP]:
			_effect.draw(_painter, "windup", fmod(t, 0.35), {"origin": c, "dest": c + axis, "head": c, "axis": axis, "k": grow, "p": 0.0, "scale": 1.0})
		for i in beams.size():
			var b: Dictionary = beams[i]
			if b["state"] == "hit":
				var hp2: Vector3 = b["hit_pos"]
				var hd: Vector3 = -(b["hit_dir"] as Vector3)
				_effect.draw(_painter, "impact", t - float(b["hit_t"]), {"origin": hp2, "dest": hp2 + hd, "head": hp2, "axis": hd, "k": 1.0, "p": 1.0, "scale": 1.0})
		_painter.end_frame()


const CROWN_EXPAND := 0.16  ## s: the crown opens
const CROWN_SPLIT := 0.9  ## s: the 5 parts drift backward and fade slowly
const CROWN_PARTS := 5


## D-958/D-959 release: three crowns of jagged rays around the shot (planes across it). Layer 0 at the muzzle; layer 1
## farther along the shot and smaller, turning clockwise; layer 2 farther and smaller still, turning counter-clockwise.
## Each opens, then splits into 5 parts that drift BACKWARD (against the shot) and outward, fading slowly. Fixed metres;
## axis from the real shot (D-235).
const CROWN_LAYERS := [
	{"ahead": 0.0, "size": 1.0, "spin": 0.0},
	{"ahead": 0.55, "size": 0.72, "spin": -1.6},  # turns/s, negative = clockwise seen from the caster
	{"ahead": 1.05, "size": 0.5, "spin": 1.6},
]
const BURST_LEN := 0.2  ## D-959: the electric energy burst at the shot, 0.2 s
const BURST_RAYS := 14


func _draw_crown(c: Vector3) -> void:
	var im := _crown_node.mesh as ImmediateMesh
	im.clear_surfaces()
	if _release_t < 0.0 or beams.is_empty():
		return
	var lt := t - _release_t
	if lt > CROWN_EXPAND + CROWN_SPLIT:
		return
	var axis := ((beams[0]["to"] as Vector3) - c).normalized()
	var pp := _perp(axis)
	var e := 1.0 - pow(1.0 - clampf(lt / CROWN_EXPAND, 0.0, 1.0), 3.0)
	var sk := clampf((lt - CROWN_EXPAND) / CROWN_SPLIT, 0.0, 1.0)
	var back := -axis * (1.8 * (1.0 - pow(1.0 - sk, 2.0)))
	(_crown_node.material_override as ShaderMaterial).set_shader_parameter("fade", sk * sk)
	var step := int(floor(t * 20.0))
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for li in CROWN_LAYERS.size():
		var layer: Dictionary = CROWN_LAYERS[li]
		var size := float(layer["size"])
		var radius := (lerpf(0.25, 1.0, e) + 0.5 * sk) * size
		var turn := TAU * float(layer["spin"]) * lt
		for part in CROWN_PARTS:
			var a0 := TAU * float(part) / CROWN_PARTS + 0.12 + turn + 0.3 * li
			var a1 := a0 + TAU / CROWN_PARTS - 0.24 - 0.25 * sk  # the gaps open as the parts separate
			var mid := (a0 + a1) * 0.5
			var outward: Vector3 = (pp[0] as Vector3) * cos(mid) + (pp[1] as Vector3) * sin(mid)
			var centre := c + axis * float(layer["ahead"]) + back + outward * ((body_r + 0.6) * sk)  # D-960: wide enough to go AROUND the body
			var pts := PackedVector3Array()
			var rng := RandomNumberGenerator.new()
			rng.seed = step * 31 + part + li * 977
			for k in 7:
				var ang := lerpf(a0, a1, float(k) / 6.0)
				var dir: Vector3 = (pp[0] as Vector3) * cos(ang) + (pp[1] as Vector3) * sin(ang)
				pts.append(centre + dir * (radius + rng.randf_range(-0.09, 0.09) * size) + axis * rng.randf_range(-0.07, 0.07))
			_tube(im, pts, 0.045 * size * (1.0 - 0.5 * sk) * THICK)
			for sp in 2:
				var ang2 := lerpf(a0, a1, 0.3 + 0.4 * sp)
				var d2: Vector3 = (pp[0] as Vector3) * cos(ang2) + (pp[1] as Vector3) * sin(ang2)
				var base := centre + d2 * radius
				_tube(im, _jag(base, base + d2 * 0.45 * size * (1.0 - sk) + axis * -0.15, 0.06, step * 7 + part * 3 + sp + li * 51, 0.12), 0.03 * size * THICK)
	im.surface_end()


## D-959: a very fast burst of electric energy at the shot (0.2 s): jagged rays out in every direction from the muzzle
## and a white-gold flash that opens and dissolves. Fixed metres.
func _draw_burst(c: Vector3) -> void:
	var im := _burst_node.mesh as ImmediateMesh
	im.clear_surfaces()
	if _release_t < 0.0:
		_burst_flash.visible = false
		return
	var k := (t - _release_t) / BURST_LEN
	if k >= 1.0:
		_burst_flash.visible = false
		return
	_burst_flash.visible = true
	_burst_flash.position = c
	_burst_flash.scale = Vector3.ONE * lerpf(0.3, 1.1, 1.0 - pow(1.0 - k, 3.0))
	(_burst_flash.material_override as ShaderMaterial).set_shader_parameter("fade", clampf((k - 0.4) / 0.6, 0.0, 1.0))
	(_burst_node.material_override as ShaderMaterial).set_shader_parameter("fade", clampf((k - 0.5) / 0.5, 0.0, 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(floor(t * 40.0)) * 13 + 5
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in BURST_RAYS:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var length := rng.randf_range(0.7, 1.7) * (0.4 + 0.6 * minf(k * 3.0, 1.0))
		_tube(im, _jag(c + d * 0.2, c + d * length, 0.12, rng.randi(), 0.18), 0.035 * THICK)
	im.surface_end()


## D-966: a lightning path from a toward full_to: sharp sideways bends every BOLT_SEG metres (BOLT_AMP), pinned at
## both ends; only the part up to `p` (0..1) is returned, ending exactly at the current tip.
static func _bolt(a: Vector3, full_to: Vector3, p: float, step_seed: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var d := full_to - a
	var n := clampi(int(d.length() / BOLT_SEG), 2, 60)
	var pp := _perp(d)
	var rng := RandomNumberGenerator.new()
	rng.seed = step_seed
	var pts := PackedVector3Array()
	for i in n + 1:
		var u := float(i) / float(n)
		var q := a.lerp(full_to, u)
		if i > 0 and i < n:
			var side := 1.0 if i % 2 == 0 else -1.0  # alternate sides: a real zig-zag, not noise
			q += (pp[0] as Vector3) * side * rng.randf_range(0.45, 1.0) * BOLT_AMP + (pp[1] as Vector3) * rng.randf_range(-0.5, 0.5) * BOLT_AMP
		pts.append(q)
	var cut := clampf(p, 0.0, 1.0) * float(n)
	for i in pts.size():
		if float(i) <= cut:
			out.append(pts[i])
	var k := int(floor(cut))
	if k < n:
		out.append(pts[k].lerp(pts[k + 1], cut - float(k)))
	if out.size() < 2:
		out = PackedVector3Array([a, a.lerp(full_to, maxf(p, 0.001))])
	return out


## D-966: a thin filament that wanders around a bolt path (same bends, small offsets).
static func _around(path: PackedVector3Array, amp: float, step_seed: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = step_seed
	for i in path.size():
		var q := path[i]
		if i > 0 and i < path.size() - 1:
			q += Vector3(rng.randf_range(-amp, amp), rng.randf_range(-amp, amp), rng.randf_range(-amp, amp))
		out.append(q)
	return out


func _glow_add(pos: Vector3, size: float, strength: float) -> void:
	if strength <= 0.01 or _glow_n >= GLOW_MAX:
		return
	var mm := _glow.multimesh
	mm.set_instance_transform(_glow_n, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), pos))
	mm.set_instance_color(_glow_n, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, clampf(strength, 0.0, 1.0)))
	_glow_n += 1


## D-972: the node lives until the pillar and its side sparks have played out (longer than the beam's own POST).
func _finished() -> bool:
	if not super():
		return false
	for b in beams:
		if b["state"] == "hit" and t - float(b["hit_t"]) < (PILLAR_EMERGE + PILLAR_LEN) * (1.0 if bool(_stun.get(beams.find(b), false)) else NO_STUN_TIME) + 0.1:
			return false
	return true


## D-978: the combat says whether this hit stunned; that picks the full (stun) or the smaller impact.
func set_stun(i: int, stunned: bool) -> void:
	_stun[i] = stunned
