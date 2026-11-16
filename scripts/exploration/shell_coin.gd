class_name ShellCoin
extends RigidBody3D
## D-1259 (valores de TESTE): Casco cunhado com fisica, brilho e feedback de coleta.
## Fisica so ao nascer (cai e quica; colide com chao e outras moedas, nao com o jogador).
## Coleta: puxada por proximidade (grupo item_collector), voo em arco, faiscas, som e "+1".

signal settled(denomination: int)
signal collect_started(denomination: int, chain: int)
signal collected(denomination: int, chain: int)

enum Denom { BRONZE, SILVER, GOLD }
enum State { FALLING, IDLE, FLYING, DONE }

const MODELS := {
	Denom.BRONZE: "res://assets/modelos/cascos/casco_bronze.glb",
	Denom.SILVER: "res://assets/modelos/cascos/casco_prata.glb",
	Denom.GOLD: "res://assets/modelos/cascos/casco_ouro.glb",
}
const NAMES := {Denom.BRONZE: "Bronze Shell", Denom.SILVER: "Silver Shell", Denom.GOLD: "Golden shells"}
const TINT := {
	Denom.BRONZE: Color(1.0, 0.55, 0.25),
	Denom.SILVER: Color(0.75, 0.88, 1.0),
	Denom.GOLD: Color(1.0, 0.8, 0.25),
}
## Intensidade cresce de bronze para ouro (D-1259 item 2).
const GLOW := {Denom.BRONZE: 0.03, Denom.SILVER: 0.05, Denom.GOLD: 0.10}
const GLINT := {Denom.BRONZE: 0.45, Denom.SILVER: 0.6, Denom.GOLD: 0.9}
const GROUND := {Denom.BRONZE: 0.35, Denom.SILVER: 0.5, Denom.GOLD: 0.8}
const GLITTER := {Denom.BRONZE: 0, Denom.SILVER: 2, Denom.GOLD: 5}

const COIN_SCALE := 0.32           ## m de diametro (provisorio)
const PULL_RADIUS := 1.8           ## m (provisorio)
const MIN_AGE := 0.8               ## s antes de poder ser coletada
const FLIGHT_TIME := 0.45
const CHAIN_WINDOW_MS := 450
const CHAIN_DELAY := 0.07
const SEMITONES := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
const SHINE_SHADER := preload("res://shaders/shell_shine.gdshader")
const GLOW_SHADER := preload("res://shaders/shell_ground_glow.gdshader")
const COLLECTOR_GROUP := "item_collector"

static var _last_collect_ms := -100000
static var _chain := 0

var denomination: int = Denom.BRONZE
var state: int = State.FALLING
var coin_scale := COIN_SCALE
var floor_y := 0.0

var _age := 0.0
var _model: Node3D
var _mats: Array[ShaderMaterial] = []
var _glow: MeshInstance3D
var _glitter: CPUParticles3D
var _collector: Node3D
var _fly_t := 0.0
var _fly_delay := 0.0
var _fly_from := Vector3.ZERO
var _fly_ctrl := Vector3.ZERO
var _my_chain := 0
var _settled_emitted := false
var _calm_t := 0.0
var _trail: CPUParticles3D


static func spawn(parent: Node, denom: int, pos: Vector3, p_floor_y := 0.0, p_scale := COIN_SCALE) -> ShellCoin:
	var c := ShellCoin.new()
	c.denomination = denom
	c.coin_scale = p_scale
	c.floor_y = p_floor_y
	parent.add_child(c)
	c.global_position = pos
	c.rotation = Vector3(randf_range(-0.6, 0.6), randf() * TAU, randf_range(-0.6, 0.6))
	c.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
	c.linear_velocity = Vector3(randf_range(-0.25, 0.25), randf_range(0.0, 0.8), randf_range(-0.25, 0.25))
	return c


func _ready() -> void:
	name = "Casco_%s" % NAMES[denomination].replace(" ", "")
	add_to_group("shell_coin")
	collision_layer = 2
	collision_mask = 1 | 2
	mass = 0.4
	continuous_cd = true
	can_sleep = true
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.3
	pm.friction = 0.75
	physics_material_override = pm
	_build_visual_and_shape()
	_build_ground_glow()
	if int(GLITTER[denomination]) > 0:
		_build_glitter()


func _build_visual_and_shape() -> void:
	var packed := load(MODELS[denomination]) as PackedScene
	if packed == null:
		push_error("ShellCoin: modelo ausente %s" % MODELS[denomination])
		return
	var inst := packed.instantiate() as Node3D
	var meshes := inst.find_children("*", "MeshInstance3D", true, false)
	var mi := meshes[0] as MeshInstance3D
	var aabb := mi.mesh.get_aabb()
	var off := -aabb.get_center()
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	inst.position = off
	_model.add_child(inst)
	_model.scale = Vector3.ONE * coin_scale
	for m in meshes:
		var mesh_inst := m as MeshInstance3D
		for s in mesh_inst.mesh.get_surface_count():
			var src := mesh_inst.mesh.surface_get_material(s) as StandardMaterial3D
			var sm := ShaderMaterial.new()
			sm.shader = SHINE_SHADER
			sm.set_shader_parameter("albedo", src.albedo_color if src else Color.WHITE)
			sm.set_shader_parameter("metallic", src.metallic if src else 0.35)
			sm.set_shader_parameter("roughness", src.roughness if src else 0.5)
			sm.set_shader_parameter("glow", GLOW[denomination])
			sm.set_shader_parameter("glint", GLINT[denomination])
			sm.set_shader_parameter("phase", randf())
			mesh_inst.set_surface_override_material(s, sm)
			_mats.append(sm)
	var shape := mi.mesh.create_convex_shape(true, true)
	var pts := PackedVector3Array()
	for p in shape.points:
		pts.append((p + off) * coin_scale)
	shape.points = pts
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)


func _build_ground_glow() -> void:
	_glow = MeshInstance3D.new()
	_glow.top_level = true
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * coin_scale * 3.4
	_glow.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = GLOW_SHADER
	gm.set_shader_parameter("tint", TINT[denomination])
	gm.set_shader_parameter("strength", GROUND[denomination])
	gm.set_shader_parameter("phase", randf() * TAU)
	_glow.material_override = gm
	add_child(_glow)


func _build_glitter() -> void:
	_glitter = CPUParticles3D.new()
	_glitter.amount = int(GLITTER[denomination]) * 2
	_glitter.lifetime = 1.4
	_glitter.local_coords = false
	_glitter.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_glitter.emission_sphere_radius = coin_scale * 0.55
	_glitter.direction = Vector3.UP
	_glitter.spread = 25.0
	_glitter.initial_velocity_min = 0.08
	_glitter.initial_velocity_max = 0.22
	_glitter.gravity = Vector3.ZERO
	_glitter.scale_amount_min = 0.5
	_glitter.scale_amount_max = 1.0
	_glitter.mesh = _spark_mesh(0.025, TINT[denomination])
	add_child(_glitter)


static func _spark_mesh(size: float, col: Color) -> Mesh:
	var q := QuadMesh.new()
	q.size = Vector2.ONE * size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(col.r, col.g, col.b, 1.0)
	m.vertex_color_use_as_albedo = true
	q.material = m
	return q


func _process(delta: float) -> void:
	if state == State.DONE:
		return
	if _glow != null and state != State.FLYING:
		_glow.global_position = Vector3(global_position.x, floor_y + 0.012, global_position.z)
	if state == State.FLYING:
		_fly(delta)


func _physics_process(delta: float) -> void:
	_age += delta
	if state == State.FALLING:
		var calm := linear_velocity.length() < 0.06 and angular_velocity.length() < 0.35
		_calm_t = _calm_t + delta if calm else 0.0
		if (sleeping or _calm_t > 0.3 or _age > 3.0) and not _settled_emitted:
			_settled_emitted = true
			state = State.IDLE
			settled.emit(denomination)
		return
	if state == State.IDLE and _age >= MIN_AGE:
		var c := _nearest_collector()
		if c != null:
			_begin_collect(c)


func _nearest_collector() -> Node3D:
	var best: Node3D = null
	var best_d := PULL_RADIUS
	for n in get_tree().get_nodes_in_group(COLLECTOR_GROUP):
		var n3 := n as Node3D
		if n3 == null:
			continue
		var d := Vector2(n3.global_position.x - global_position.x, n3.global_position.z - global_position.z).length()
		if d < best_d:
			best_d = d
			best = n3
	return best


func _begin_collect(c: Node3D) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_collect_ms < CHAIN_WINDOW_MS:
		_chain += 1
	else:
		_chain = 0
	_last_collect_ms = now
	_my_chain = _chain
	_collector = c
	state = State.FLYING
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0
	_fly_delay = float(_my_chain) * CHAIN_DELAY
	_fly_from = global_position
	var target := c.global_position + Vector3.UP * 1.0
	var mid := (_fly_from + target) * 0.5
	var side := (target - _fly_from).cross(Vector3.UP).normalized() * randf_range(-0.5, 0.5)
	_fly_ctrl = mid + Vector3.UP * 1.1 + side
	if _glow != null:
		_glow.visible = false
	_build_trail()
	collect_started.emit(denomination, _my_chain)


func _build_trail() -> void:
	_trail = CPUParticles3D.new()
	_trail.amount = 18
	_trail.lifetime = 0.35
	_trail.local_coords = false
	_trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_trail.emission_sphere_radius = coin_scale * 0.3
	_trail.gravity = Vector3.ZERO
	_trail.initial_velocity_max = 0.2
	_trail.mesh = _spark_mesh(0.04, TINT[denomination])
	_trail.scale_amount_curve = _fade_curve()
	add_child(_trail)


static func _fade_curve() -> Curve:
	var cv := Curve.new()
	cv.add_point(Vector2(0, 1))
	cv.add_point(Vector2(1, 0))
	return cv


func _fly(delta: float) -> void:
	if _fly_delay > 0.0:
		_fly_delay -= delta
		_flash(0.6 + 0.4 * sin(_age * 40.0))
		return
	_fly_t += delta / FLIGHT_TIME
	var t := clampf(_fly_t, 0.0, 1.0)
	var e := t * t * (3.0 - 2.0 * t)
	var to := _collector.global_position + Vector3.UP * 1.0 if is_instance_valid(_collector) else _fly_from
	var a := _fly_from.lerp(_fly_ctrl, e)
	var b := _fly_ctrl.lerp(to, e)
	global_position = a.lerp(b, e)
	rotate_y(delta * 22.0)
	rotate_x(delta * 9.0)
	_model.scale = Vector3.ONE * coin_scale * lerpf(1.15, 0.45, t)
	_flash(1.0 - t)
	if t >= 1.0:
		_arrive(to)


func _flash(v: float) -> void:
	for m in _mats:
		m.set_shader_parameter("flash", v * 0.8)


func _arrive(at: Vector3) -> void:
	state = State.DONE
	var host := get_parent()
	_burst(host, at)
	_ping(host)
	_number(host, at)
	collected.emit(denomination, _my_chain)
	queue_free()


func _burst(host: Node, at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.top_level = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 12 + 4 * denomination
	p.lifetime = 0.5
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.05
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 1.4
	p.initial_velocity_max = 2.8
	p.gravity = Vector3(0, -2.5, 0)
	p.damping_min = 2.0
	p.damping_max = 3.0
	p.mesh = _spark_mesh(0.05, TINT[denomination])
	p.scale_amount_curve = _fade_curve()
	host.add_child(p)
	p.global_position = at
	p.emitting = true
	var light := OmniLight3D.new()
	light.light_color = TINT[denomination]
	light.light_energy = 2.5
	light.omni_range = 2.2
	host.add_child(light)
	light.global_position = at
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.18)
	tw.tween_callback(light.queue_free)
	var killer := host.get_tree().create_timer(1.0)
	killer.timeout.connect(p.queue_free)


func _number(host: Node, at: Vector3) -> void:
	var l := Label3D.new()
	l.text = "+1"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = false
	l.pixel_size = 0.0045
	l.font_size = 64
	l.outline_size = 14
	l.outline_modulate = Color(0.1, 0.05, 0.1, 0.9)
	l.modulate = TINT[denomination]
	host.add_child(l)
	l.global_position = at + Vector3(0, 0.25, 0)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "global_position:y", at.y + 0.95, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func _ping(host: Node) -> void:
	var semi: int = SEMITONES[mini(_my_chain, SEMITONES.size() - 1)]
	var base := 740.0 + 180.0 * denomination
	var freq := base * pow(2.0, float(semi) / 12.0)
	var rate := 22050
	var n := int(rate * 0.22)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * 18.0) * minf(1.0, t * 400.0)
		var v := (sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.01 * t) * 0.25) * env
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 14000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	var pl := AudioStreamPlayer.new()
	pl.stream = wav
	pl.volume_db = -8.0
	host.add_child(pl)
	pl.play()
	pl.finished.connect(pl.queue_free)
