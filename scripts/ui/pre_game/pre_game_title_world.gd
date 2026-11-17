class_name PreGameTitleWorld
extends SubViewportContainer
## D-1265: 3D world behind the v2 title/menu: real leader idle on the hub summon circle, spires,
## light slabs, motes, slow camera. Everything derives from the leader height (D-235).

const PreGameCatalog = preload("res://scripts/ui/pre_game/pre_game_catalog.gd")
const CharacterModelLoader = preload("res://scripts/combat/character_model_loader.gd")
## Models of the hub NPCs (HUB_NPC_SPECS in hub_3d_lab.gd): also part of the random title pool.
const NPC_IDS: Array[String] = ["bulbasaur", "pikachu", "squirtle", "charmander", "eevee",
	"dqt_healslime", "dqt_dracky", "dqt_sabrecub", "dqt_platypunk", "dqt_fungi"]
## Overworld heights in metres (copied from HUB_HEIGHTS in scripts/hub/hub_3d_lab.gd: lab values, D-1023).
const OVERWORLD_HEIGHTS := {
	"abra": 1.0, "pancham": 0.7, "gible": 0.85, "dqt_slime": 0.90, "dqt_orc": 2.1, "dqt_cyclops": 2.2,
	"bulbasaur": 0.78, "pikachu": 0.72, "squirtle": 0.72, "charmander": 0.78, "eevee": 0.62,
	"dqt_healslime": 1.15, "dqt_dracky": 0.95, "dqt_sabrecub": 0.85, "dqt_platypunk": 0.95, "dqt_fungi": 0.95,
}
## One fixed framing for everybody (so relative sizes are real): altar and camera do not follow the model.
const REF_RADIUS := 1.2
const HubAltarScript = preload("res://scripts/hub/hub_altar.gd")
const HubSummonFxScript = preload("res://scripts/hub/hub_summon_fx.gd")

const NAVY := Color("051322")
const LIME := Color("d6fa66")
const CORAL := Color("ff746c")
const CYAN := Color("63d9ec")
const PAPER := Color("f4eee1")
## Creator: BACKGROUND (floor, spires, slabs, sky) at least 45% darker; leader and effects untouched.
const BG_DARK := 0.5

const GRID_SHADER := "
shader_type spatial;
render_mode cull_back;
uniform float cell = 1.0;
uniform float fade = 30.0;
uniform vec4 line_col : source_color = vec4(0.39, 0.85, 0.93, 1.0);
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 g = wpos.xz / cell;
	vec2 w = fwidth(g) * 1.2;
	vec2 a = abs(fract(g - 0.5) - 0.5) / max(w, vec2(0.0001));
	float line = 1.0 - clamp(min(a.x, a.y), 0.0, 1.0);
	float big = 1.0 - clamp(min(abs(fract(g / 5.0 - 0.5) - 0.5).x, abs(fract(g / 5.0 - 0.5) - 0.5).y) / max(w.x * 0.2, 0.0001), 0.0, 1.0);
	float d = length(wpos.xz);
	float f = smoothstep(fade, 0.0, d);
	ALBEDO = vec3(0.035, 0.085, 0.13) * 0.55;
	ROUGHNESS = 0.55;
	METALLIC = 0.15;
	EMISSION = line_col.rgb * (line * 0.35 + big * 0.55) * f * 0.55;
}
"

const SLAB_SHADER := "
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.84, 0.98, 0.4, 1.0);
uniform float a = 0.5;
void fragment() {
	float e = smoothstep(0.0, 0.5, UV.y) * (1.0 - smoothstep(0.7, 1.0, UV.y));
	ALBEDO = tint.rgb;
	ALPHA = a * e;
}
"

var _cam: Camera3D
var _cam_target := Vector3.ZERO
var _fx: Node3D
var _leader: Node3D
var _ui: Control
var _H := 1.0
var _gen := 0
var _leader_id := ""
var _model_k := 1.0
var _live_lo := 0.0  ## live lowest point of the leader with its pivot at y=0
var _top := 0.0  ## altar top height (the leader and the circle stand on it)
var _R := 2.0
var _t := 0.0
var _slabs: Array[MeshInstance3D] = []
var _rim: SpotLight3D


var _vp: SubViewport
var _leader_idx := -1
var mirror := false
var active := true:
	set(v):
		active = v
		set_process(v)
		if _vp != null:
			_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if v else SubViewport.UPDATE_DISABLED


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	add_child(_vp)
	# Creator: the leader is random each time the title opens (unless set_leader() chose one).
	var first := _leader_idx if _leader_idx >= 0 else randi() % (PreGameCatalog.build_protagonist_list().size() + NPC_IDS.size())
	_leader_idx = -1
	set_leader(first)


## Rebuilds the world for another leader (all sizes derive from its measured height, D-235).
## The height and the floor level are measured LIVE on the idle pose (skinned vertices), because the
## bind-pose bounds are wrong for some rigs (huge Bulbasaur) and flyers hover while idling.
func set_leader(idx: int) -> void:
	if _vp == null:
		_leader_idx = idx
		return
	if idx == _leader_idx and _fx != null:
		return
	_leader_idx = idx
	_gen += 1
	var gen := _gen
	for c in _vp.get_children():
		c.queue_free()
	_slabs.clear()
	_fx = null
	_cam = null
	_leader = null
	_build_leader(idx)
	if _leader != null:
		# Measure a whole idle loop (seek through it): the floor is the LOWEST point of the loop
		# (a hopping Slime or a hovering flyer then touches the altar at its lowest), the height
		# is the mean body height.
		await get_tree().process_frame
		await get_tree().process_frame
		if gen != _gen or _leader == null:
			return
		var ap: AnimationPlayer = null
		for node in _leader.find_children("*", "AnimationPlayer", true, false):
			ap = node as AnimationPlayer
			break
		var length := 0.0
		if ap != null and ap.current_animation != "":
			length = ap.current_animation_length
		var lo := 1e9
		var hsum := 0.0
		var n := 0
		var steps := 12 if length > 0.0 else 1
		for k in steps:
			if length > 0.0:
				ap.seek(length * float(k) / float(steps), true)
			var e := _live_extent(_leader)
			if e.y > e.x:
				lo = minf(lo, e.x)
				hsum += e.y - e.x
				n += 1
		if length > 0.0:
			ap.seek(0.0, true)
		var body_h := _H  # static bounds unless the live measure is sane
		if n > 0:
			var live_h := hsum / float(n)
			# Rigs with absurd skinned extents keep the static bounds.
			if live_h > _H * 0.4 and live_h < _H * 2.5:
				_live_lo = lo
				body_h = maxf(0.05, live_h)
		# Creator: real overworld heights (HUB_HEIGHTS), so big characters stay big and small ones small.
		var target := float(OVERWORLD_HEIGHTS.get(_leader_id, body_h))
		_model_k = target / body_h
		_leader.scale = Vector3.ONE * _model_k
		_H = target
		_R = REF_RADIUS
	if gen != _gen:
		return
	_build_world()
	_build_lights()
	_build_motes()
	# UX: no pop when the world appears (the leader is measured first).
	var capturing := false
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if str(a).begins_with("--shot="):
			capturing = true
	if capturing:
		return
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.7)


## Lowest and highest world y of the skinned mesh in the current pose (x = low, y = high).
func _live_extent(root_node: Node3D) -> Vector2:
	var lo := 1e9
	var hi := -1e9
	for node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var sk: Skeleton3D = null
		if mi.skeleton != NodePath():
			sk = mi.get_node_or_null(mi.skeleton) as Skeleton3D
		var skin: Skin = mi.skin
		var bind_xf: Array[Transform3D] = []
		if sk != null and skin != null:
			for i in skin.get_bind_count():
				var bi := skin.get_bind_bone(i)
				if bi < 0:
					bi = sk.find_bone(skin.get_bind_name(i))
				bind_xf.append(sk.get_bone_global_pose(bi) * skin.get_bind_pose(i) if bi >= 0 else Transform3D.IDENTITY)
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if verts.is_empty():
				continue
			var bones: PackedInt32Array = PackedInt32Array()
			var weights: PackedFloat32Array = PackedFloat32Array()
			if arr[Mesh.ARRAY_BONES] != null and arr[Mesh.ARRAY_WEIGHTS] != null:
				bones = arr[Mesh.ARRAY_BONES]
				weights = arr[Mesh.ARRAY_WEIGHTS]
			var stride := bones.size() / verts.size() if not bones.is_empty() else 0
			var skinned := stride > 0 and not bind_xf.is_empty()
			for v in verts.size():
				var wp: Vector3
				if skinned:
					var acc := Vector3.ZERO
					var wsum := 0.0
					for k in stride:
						var w := weights[v * stride + k]
						if w <= 0.0:
							continue
						var bi2 := bones[v * stride + k]
						if bi2 < 0 or bi2 >= bind_xf.size():
							continue
						acc += w * (bind_xf[bi2] * verts[v])
						wsum += w
					if wsum <= 0.0:
						continue
					wp = sk.global_transform * (acc / wsum)
				else:
					wp = mi.global_transform * verts[v]
				lo = minf(lo, wp.y)
				hi = maxf(hi, wp.y)
	return Vector2(lo, hi)


func _build_leader(idx: int) -> void:
	var protos := PreGameCatalog.build_protagonist_list()
	var combatant: Combatant = null
	if idx < protos.size():
		combatant = PreGameCatalog.build_combatant_for_3d(protos[idx])
	else:
		# Creator: the hub NPC models are also valid title stars. Model comes from species_id only.
		var npc_id: String = NPC_IDS[clampi(idx - protos.size(), 0, NPC_IDS.size() - 1)]
		combatant = Combatant.new(npc_id, 1, 1, 1.0, false)
		combatant.species_id = npc_id
	_leader_id = str(combatant.species_id).to_lower() if combatant != null else ""
	var model := CharacterModelLoader.create_character_model(combatant) if combatant != null else null
	if model == null:
		push_warning("title_v2: no leader model")
		_H = 1.0
		return
	var b: AABB = CharacterModelLoader.calculate_model_bounds(model)
	_H = maxf(0.05, b.size.y)
	var pivot := Node3D.new()
	pivot.name = "LeaderPivot"
	_vp.add_child(pivot)
	model.position = Vector3(-(b.position.x + b.size.x * 0.5), -b.position.y, -(b.position.z + b.size.z * 0.5))
	pivot.add_child(model)
	_leader = pivot
	var anim: AnimationPlayer = CharacterModelLoader.get_anim_player(model)
	if anim != null:
		for clip in ["battle_idle", "idle"]:
			if anim.has_animation(clip):
				var an := anim.get_animation(clip)
				if an != null and an.loop_mode != Animation.LOOP_NONE:
					an.loop_mode = Animation.LOOP_LINEAR
				anim.play(clip)
				break
	_R = maxf(_H * 1.15, 1.2)


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = NAVY * BG_DARK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("3a6a86")
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color("0b2a3d") * BG_DARK
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)

	# Floor with cyan grid.
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(240.0, 240.0)
	var fm := ShaderMaterial.new()
	var fs := Shader.new()
	fs.code = GRID_SHADER
	fm.shader = fs
	fm.set_shader_parameter("cell", _R * 0.5)
	fm.set_shader_parameter("fade", _R * 14.0)
	var floor_i := MeshInstance3D.new()
	floor_i.mesh = floor_mesh
	floor_i.material_override = fm
	_vp.add_child(floor_i)

	# Summon circle from the hub, held at the FALL peak (rings up, pillar on).
	_fx = HubSummonFxScript.new()
	_vp.add_child(_fx)
	_fx.build(_R)
	# D-1266: grey stone altar with the summon star carved in; scaled so its star is the circle's star
	# (glyph tips at 0.9 R, altar tips at 1.58 m). The leader and the circle stand on top of it.
	var altar := HubAltarScript.new()
	altar.tone = 0.3  # the title lights are much brighter than the hub's: keep the stone grey, not white
	var sc := 0.9 * _R / 1.58
	altar.scale = Vector3.ONE * sc
	_vp.add_child(altar)
	_top = altar.top_y * sc
	_fx.position.y = _top - 0.16 + 0.012  # the glyph meshes sit 0.16 m above their origin (hub medallion): lay them on the stone
	if _leader != null:
		_leader.position.y = _top - _live_lo * _model_k + 0.01 * _H
	# Beam: draw only the far wall so it glows behind the leader instead of over it.
	var bs := Shader.new()
	bs.code = _fx._pillar_mat.shader.code.replace("cull_disabled", "cull_front")
	_fx._pillar_mat.shader = bs

	# Status spires: thin navy towers with a lime/cyan/coral cap, ring around the arena.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1204
	var caps := [LIME, CYAN, CORAL]
	for i in 26:
		var ang := TAU * float(i) / 26.0 + rng.randf_range(-0.07, 0.07)
		var dist := _R * rng.randf_range(4.2, 9.0)
		var h := _R * rng.randf_range(1.6, 6.0)
		var w := _R * rng.randf_range(0.14, 0.3)
		var body := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w, h, w)
		body.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("0a2236") * BG_DARK
		mat.roughness = 0.6
		body.material_override = mat
		body.position = Vector3(cos(ang) * dist, h * 0.5, sin(ang) * dist)
		body.rotation.y = rng.randf() * TAU
		_vp.add_child(body)
		var cap := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(w * 1.04, _R * 0.05, w * 1.04)
		cap.mesh = cm
		var capmat := StandardMaterial3D.new()
		capmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		capmat.albedo_color = (caps[i % 3] as Color) * 1.4 * BG_DARK
		cap.material_override = capmat
		cap.position = Vector3(0.0, h * 0.5, 0.0)
		body.add_child(cap)

	# Tilted additive light slabs behind the leader (color blocking of the palette).
	var ss := Shader.new()
	ss.code = SLAB_SHADER
	var slab_defs := [[Color("dfeaf2"), -0.9, 0.55, 5.6, 0.5], [CORAL, 0.2, 0.7, 7.5, 0.42], [CYAN, 1.2, 0.45, 5.0, 0.4]]
	for d in slab_defs:
		var q := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(_R * float(d[2]), _R * float(d[3]))
		pm.orientation = PlaneMesh.FACE_Z
		q.mesh = pm
		var sm := ShaderMaterial.new()
		sm.shader = ss
		sm.set_shader_parameter("tint", d[0])
		sm.set_shader_parameter("a", float(d[4]) * BG_DARK)
		q.material_override = sm
		q.position = Vector3(float(d[1]) * _R * 1.1, _R * float(d[3]) * 0.5, -_R * 3.2)
		q.rotation = Vector3(0.0, 0.0, deg_to_rad(-14.0))
		_vp.add_child(q)
		_slabs.append(q)

	_cam = Camera3D.new()
	_cam.fov = 38.0
	_cam.near = 0.05
	_cam.far = 600.0
	_vp.add_child(_cam)
	_cam.current = true


func _build_lights() -> void:
	var key := DirectionalLight3D.new()
	key.light_color = Color("fff1d6")
	key.light_energy = 0.5
	key.shadow_enabled = true
	key.directional_shadow_max_distance = _R * 12.0
	key.rotation_degrees = Vector3(-38.0, 28.0, 0.0)
	_vp.add_child(key)
	var rim := SpotLight3D.new()
	rim.light_color = CYAN
	rim.light_energy = 1.0
	rim.spot_range = _R * 9.0
	rim.spot_angle = 26.0
	rim.position = Vector3(-_R * 1.6, _R * 2.6, -_R * 2.8)
	_vp.add_child(rim)
	rim.look_at_from_position(rim.position, Vector3(0.0, _H * 0.55, 0.0), Vector3.UP)
	_rim = rim
	var fill := OmniLight3D.new()
	fill.light_color = CYAN
	fill.light_energy = 0.35
	fill.omni_range = _R * 6.0
	fill.position = Vector3(_R * 1.8, _H * 0.6, _R * 1.4)
	_vp.add_child(fill)


func _build_motes() -> void:
	var p := CPUParticles3D.new()
	p.amount = 70
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = _R * 1.1
	p.direction = Vector3.UP
	p.spread = 14.0
	p.initial_velocity_min = _R * 0.12
	p.initial_velocity_max = _R * 0.35
	p.gravity = Vector3.ZERO
	p.position = Vector3(0.0, 0.05, 0.0)
	var q := QuadMesh.new()
	q.size = Vector2(0.011, 0.011) * _R
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color("bfe9f2") * 1.4
	q.material = m
	p.mesh = q
	_vp.add_child(p)


func _process(delta: float) -> void:
	if _fx == null or _cam == null:
		return
	_t += delta
	if _fx != null:
		_fx.pose("FALL", 1.0, _t, _H * 0.55)
		_fx.rotation.y = _t * 0.35
		# Title tuning (prototype only): the hub values blow the leader out at this framing.
		_fx._light.light_color = Color("dfeaf2")
		_fx._light.light_energy = 0.12
		_fx._pillar_mat.set_shader_parameter("alpha", 0.38)
		_fx._comet.visible = false
		# Rings clear of the body (floor, above head, halo) so they never wash the face (D-235: by height).
		var ring_y := [0.015, 1.22, 1.52]
		_fx._rings[0].visible = false  # edge-on at this camera = white bar; the floor glyph is the floor ring
		for k in _fx._rings.size():
			_fx._rings[k].position.y = _H * float(ring_y[k])
	var mir := -1.0 if mirror else 1.0
	# Slow orbital drift + dolly, low camera looking slightly up (hero angle). Subject sits right.
	var yaw := deg_to_rad(sin(_t * 0.31) * 5.0 + 6.0) * mir
	var dist := _R * 3.95 * maxf(1.0, _H / 1.3) - sin(_t * 0.22) * _R * 0.12
	var cam_y := _top + _H * 0.42 + sin(_t * 0.27) * _H * 0.03
	_cam.global_position = Vector3(sin(yaw) * dist, cam_y, cos(yaw) * dist)
	_cam.look_at(Vector3(0.0, _top + _H * 0.62, 0.0), Vector3.UP)
	# Shift the frame so the leader sits to the right of the title block (aspect independent).
	_cam.h_offset = -_R * 0.55
	for i in _slabs.size():
		_slabs[i].position.x += sin(_t * 0.4 + float(i)) * delta * 0.05 * _R
