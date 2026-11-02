extends Node3D
## FX lab: candidate visual effects for Abra's moves, played on a bare stage (not the game).
## Keys: 1 PSI backdrop, 2 PSI beam (Raio Psíquico), 3 Thunder Wave (Onda de Choque),
## 4 Confusion spiral (Confusão), 0 stop.
## Screenshots: godot --path . res://tests/fx_lab/fx_lab.tscn -- --shots   (saves to tests/fx_lab/shots/)

const ABRA_POS := Vector3(-4.2, 0.0, 0.0)
const GIBLE_POS := Vector3(4.2, 0.0, 0.0)
const SHOTS_DIR := "res://tests/fx_lab/shots/"
const FPS := 12.0  ## Step-lightning redraw rate (ZZZ-style stepped animation).
const VIOLET := Color(0.72, 0.4, 1.0)
const LAVENDER := Color(0.96, 0.92, 1.0)

var _abra: Node3D
var _gible: Node3D
var _cam: Camera3D
var _label: Label
var _flash: ColorRect
var _active := ""
var _t := 0.0
var _fx_root: Node3D
var _bolt_root: Node3D
var _bolt_acc := 0.0
var _backdrop_quad: MeshInstance3D
var _backdrop_mat: StandardMaterial3D
var _backdrop_alpha := 0.0
var _backdrop_want := 0.0
var _core_mat: StandardMaterial3D
var _glow_mat: StandardMaterial3D
var _beam_mat: ShaderMaterial
var _beam_meshes: Array[QuadMesh] = []
var _beam_root: Node3D
var _seal: MeshInstance3D
var _seal_mat: ShaderMaterial
var _spiral_floor: MeshInstance3D
var _spiral_air: MeshInstance3D
var _halftone: MeshInstance3D
var _gible_anim: AnimationPlayer
var _shots := false
var _plan: Array = []  ## [[effect, time]...] screenshots to take in --shots mode
var _plan_i := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_stage()
	_fx_root = Node3D.new()
	add_child(_fx_root)
	_bolt_root = Node3D.new()
	add_child(_bolt_root)
	_core_mat = _unshaded(LAVENDER, 1.0, false)
	_glow_mat = _unshaded(Color(VIOLET, 0.55), 0.55, true)
	var ui := CanvasLayer.new()
	add_child(ui)
	_label = Label.new()
	_label.position = Vector2(14, 10)
	_label.add_theme_font_size_override("font_size", 16)
	ui.add_child(_label)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_flash)
	_shots = "--shots" in OS.get_cmdline_user_args()
	if _shots:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS_DIR))
		_plan = [["backdrop", 1.6], ["beam", 0.8], ["beam", 1.6], ["thunder", 0.62], ["thunder", 0.9], ["thunder", 1.5], ["confusion", 0.7], ["confusion", 1.5]]
		_start(_plan[0][0])
	_update_label()


func _update_label() -> void:
	_label.text = "FX LAB   1 fundo PSI   2 raio psíquico   3 onda de choque   4 confusão   0 parar\nefeito: %s" % (_active if _active != "" else "-")


# --- Stage ---------------------------------------------------------------------------------

func _build_stage() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.03, 0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.6, 0.75)
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 30)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.06, 0.1, 0.14)
	floor_mat.roughness = 0.9
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)
	_cam = Camera3D.new()
	_cam.position = Vector3(0.0, 2.9, 10.5)
	_cam.fov = 45.0
	add_child(_cam)
	_cam.look_at(Vector3(0.0, 1.3, 0.0))
	_abra = _make_model("abra", 2.5, ABRA_POS, PI / 2.0)
	_gible = _make_model("gible", 2.5 * 1.8, GIBLE_POS, -PI / 2.0)
	_gible_anim = _gible.get_meta("anim", null)
	_build_backdrop()


func _make_model(model_name: String, scale_k: float, pos: Vector3, yaw: float) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var path := "res://assets/modelos/%s/%s.glb" % [model_name, model_name]
	if ResourceLoader.exists(path):
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		inst.rotation_degrees.x = 90.0
		inst.scale = Vector3.ONE * scale_k
		root.add_child(inst)
		var ap := _find_anim(inst)
		if ap != null:
			root.set_meta("anim", ap)
			for anim_name in ["battle_idle", "idle"]:
				if ap.has_animation(anim_name):
					ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
					ap.play(anim_name)
					break
	else:
		var m := MeshInstance3D.new()
		m.mesh = CapsuleMesh.new()
		m.position.y = 1.0
		root.add_child(m)
	return root


func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null


## The EarthBound-style PSI backdrop: Youkuri's palette-cycling shader rendered in a
## SubViewport and shown on a big quad behind the stage.
func _build_backdrop() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var u := x / 256.0
			var v := y / 256.0
			var val := fposmod(u * 3.0 + sin(v * TAU * 2.0) * 0.15 + v * 2.0, 1.0)
			img.set_pixel(x, y, Color(val, val, val))
	var tex := ImageTexture.create_from_image(img)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("ff2f9e"), Color("ff8c1a"), Color("ffe433"), Color("33ff73"), Color("26d9ff"), Color("9e59ff"), Color("ff2f9e")])
	grad.offsets = PackedFloat32Array([0.0, 0.166, 0.333, 0.5, 0.666, 0.833, 1.0])
	var pal := GradientTexture1D.new()
	pal.gradient = grad
	pal.width = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = Vector2(640, 360)
	rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var mat := ShaderMaterial.new()
	mat.shader = load("res://tests/fx_lab/third_party/bounding_battle_background.gdshader")
	mat.set_shader_parameter("enable_palette_cycling", true)
	mat.set_shader_parameter("palette", pal)
	mat.set_shader_parameter("palette_cycling_speed", 0.28)
	mat.set_shader_parameter("snes_transparency", true)
	mat.set_shader_parameter("horizontal_wave_amplitude", 0.012)
	mat.set_shader_parameter("horizontal_wave_frequency", 38.0)
	mat.set_shader_parameter("horizontal_wave_speed", 3.0)
	mat.set_shader_parameter("vertical_deform_amplitude", 0.05)
	mat.set_shader_parameter("vertical_deform_frequency", 9.0)
	mat.set_shader_parameter("vertical_deform_speed", 1.2)
	mat.set_shader_parameter("sprite_scroll_direction", Vector2(1.0, 0.35))
	mat.set_shader_parameter("sprite_scroll_speed", 0.05)
	rect.material = mat
	vp.add_child(rect)
	_backdrop_quad = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(80, 44)
	_backdrop_quad.mesh = quad
	_backdrop_mat = StandardMaterial3D.new()
	_backdrop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_backdrop_mat.albedo_texture = vp.get_texture()
	_backdrop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_backdrop_mat.albedo_color = Color(1, 1, 1, 0)
	_backdrop_quad.material_override = _backdrop_mat
	_backdrop_quad.position = Vector3(0, 14, -22)
	add_child(_backdrop_quad)


func _unshaded(color: Color, alpha: float, additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if alpha < 1.0 or additive:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m


# --- Effect control -------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1: _start("backdrop")
		KEY_2: _start("beam")
		KEY_3: _start("thunder")
		KEY_4: _start("confusion")
		KEY_0: _stop()


func _stop() -> void:
	_active = ""
	_backdrop_want = 0.0
	for c in _fx_root.get_children():
		c.queue_free()
	for c in _bolt_root.get_children():
		c.queue_free()
	_beam_meshes.clear()
	_seal = null
	_spiral_floor = null
	_spiral_air = null
	_halftone = null
	_beam_root = null
	if _gible_anim != null:
		_gible_anim.speed_scale = 1.0
	_gible.scale = Vector3.ONE
	_gible.rotation.y = -PI / 2.0
	_update_label()


func _start(effect: String) -> void:
	_stop()
	_active = effect
	_t = 0.0
	_bolt_acc = 0.0
	match effect:
		"backdrop":
			_backdrop_want = 0.85
		"beam":
			_backdrop_want = 0.7
			_setup_beam()
		"thunder":
			_setup_thunder()
		"confusion":
			_backdrop_want = 0.6
			_setup_confusion()
	_update_label()


func _process(delta: float) -> void:
	_t += delta
	_backdrop_alpha = move_toward(_backdrop_alpha, _backdrop_want, delta * 1.6)
	_backdrop_mat.albedo_color = Color(1, 1, 1, _backdrop_alpha)
	_flash.color.a = maxf(_flash.color.a - delta * 9.0, 0.0)
	match _active:
		"beam": _tick_beam()
		"thunder": _tick_thunder(delta)
		"confusion": _tick_confusion()
	if _shots:
		_tick_shots()


func _tick_shots() -> void:
	if _plan_i >= _plan.size():
		get_tree().quit()
		return
	var step: Array = _plan[_plan_i]
	if _active != step[0]:
		_start(step[0])
	if _t >= float(step[1]):
		var file := ProjectSettings.globalize_path(SHOTS_DIR) + "%s_%d.png" % [step[0], _plan_i]
		get_viewport().get_texture().get_image().save_png(file)
		print("saved ", file)
		_plan_i += 1
		if _plan_i < _plan.size() and _plan[_plan_i][0] != _active:
			_start(_plan[_plan_i][0])


# --- 2: PSI beam (Raio Psíquico) -----------------------------------------------------------

func _setup_beam() -> void:
	_beam_mat = ShaderMaterial.new()
	_beam_mat.shader = load("res://tests/fx_lab/shaders/psy_beam.gdshader")
	_beam_root = Node3D.new()
	_fx_root.add_child(_beam_root)
	var holder := Node3D.new()
	holder.rotation.y = PI / 2.0  # the quad's X axis (its length) now runs along the root's -Z
	_beam_root.add_child(holder)
	for i in 2:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.0, 1.1)
		mi.mesh = q
		mi.material_override = _beam_mat
		mi.rotation.x = PI / 2.0 * i
		holder.add_child(mi)
		_beam_meshes.append(q)


func _tick_beam() -> void:
	var from := ABRA_POS + Vector3(0.9, 1.55, 0.0)
	var to := GIBLE_POS + Vector3(-1.0, 1.4, 0.0)
	var grow := clampf(_t / 0.35, 0.0, 1.0)
	var fade := 1.0 - clampf((_t - 2.3) / 0.5, 0.0, 1.0)
	var length := from.distance_to(to) * grow
	var dir := (to - from).normalized()
	_beam_root.position = from + dir * length * 0.5
	_beam_root.basis = Basis.looking_at(dir, Vector3.UP)
	for q in _beam_meshes:
		q.size = Vector2(maxf(length, 0.01), 1.1 + 0.18 * sin(_t * 18.0))
	_beam_mat.set_shader_parameter("fade", fade)
	_beam_mat.set_shader_parameter("pulse", 1.0)
	_beam_mat.set_shader_parameter("stripes", maxf(length, 0.01) * 1.4)
	# Target: tinted wobble while the beam pierces it.
	if grow >= 1.0 and fade > 0.0:
		_gible.scale = Vector3(1.0 + 0.05 * sin(_t * 30.0), 1.0 - 0.04 * sin(_t * 30.0), 1.0)
		_gible.rotation.y = -PI / 2.0 + 0.06 * sin(_t * 22.0)
	# Pulse rings travelling along the beam.
	if grow >= 1.0 and fmod(_t, 0.3) < get_process_delta_time():
		_spawn_ring(from, to)


func _spawn_ring(from: Vector3, to: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.7
	ring.mesh = torus
	var colors := [Color("ff2f9e"), Color("ffe433"), Color("33ff73"), Color("26d9ff"), Color("9e59ff")]
	ring.material_override = _unshaded(colors[_rng.randi() % colors.size()], 1.0, false)
	ring.position = from
	ring.basis = Basis.looking_at((to - from).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, PI / 2.0)
	_fx_root.add_child(ring)
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "position", to, 0.55)
	tw.tween_property(ring, "scale", Vector3(1.5, 1.5, 1.5), 0.55)
	tw.chain().tween_callback(ring.queue_free)


# --- 3: Thunder Wave (Onda de Choque) ------------------------------------------------------

func _setup_thunder() -> void:
	_seal_mat = ShaderMaterial.new()
	_seal_mat.shader = load("res://tests/fx_lab/shaders/hex_seal.gdshader")
	_seal = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	_seal.mesh = q
	_seal.material_override = _seal_mat
	_seal.rotation.x = -PI / 2.0
	_seal.position = GIBLE_POS + Vector3(0, 0.05, 0)
	_seal.scale = Vector3.ZERO
	_fx_root.add_child(_seal)
	var ht_mat := ShaderMaterial.new()
	ht_mat.shader = load("res://tests/fx_lab/shaders/halftone.gdshader")
	_halftone = MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(1.0, 1.0)
	_halftone.mesh = hq
	_halftone.material_override = ht_mat
	_halftone.position = GIBLE_POS + Vector3(0, 1.6, 0.4)
	_halftone.scale = Vector3.ZERO
	_fx_root.add_child(_halftone)


func _tick_thunder(delta: float) -> void:
	var strike := 0.5
	var fade := 1.0 - clampf((_t - 2.1) / 0.5, 0.0, 1.0)
	_seal_mat.set_shader_parameter("fade", fade)
	if _t >= strike:
		var grow := clampf((_t - strike) / 0.22, 0.0, 1.0)
		_seal.scale = Vector3.ONE * lerpf(0.5, 7.4, 1.0 - pow(1.0 - grow, 3.0))
		var hk := clampf((_t - strike) / 0.32, 0.0, 1.0)
		_halftone.scale = Vector3.ONE * lerpf(1.2, 4.2, hk)
		(_halftone.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0 - hk)
		_halftone.look_at(_cam.global_position)
		if _t - strike < delta + 0.001:
			_flash.color = Color(0.9, 0.8, 1.0, 0.55)  # a single bright frame
	else:
		# Charge: a small seal under Abra, growing.
		_seal.position = ABRA_POS + Vector3(0, 0.05, 0)
		_seal.scale = Vector3.ONE * lerpf(0.0, 2.4, _t / strike)
	if _t >= strike:
		_seal.position = GIBLE_POS + Vector3(0, 0.05, 0)
	# Paralysis: the animation stutters (stepped), the body jitters.
	if _t >= strike and _t < 2.1 and _gible_anim != null:
		var frame := int(_t * FPS)
		_gible_anim.speed_scale = 0.0 if frame % 2 == 0 else 1.0
		_gible.position = GIBLE_POS + Vector3(_rng.randf_range(-0.05, 0.05), 0.0, 0.0) * float(frame % 3)
	elif _gible_anim != null:
		_gible_anim.speed_scale = 1.0
		_gible.position = GIBLE_POS
	# Stepped lightning: redraw at FPS, hold in between.
	_bolt_acc += delta
	if _bolt_acc >= 1.0 / FPS:
		_bolt_acc = 0.0
		_draw_thunder_frame(fade)


func _draw_thunder_frame(fade: float) -> void:
	for c in _bolt_root.get_children():
		c.queue_free()
	if fade <= 0.0:
		return
	var chest := GIBLE_POS + Vector3(0, 1.6, 0)
	if _t < 0.5:
		# Small arcs gathering around Abra.
		for i in 3:
			var a := ABRA_POS + Vector3(_rng.randf_range(-0.8, 0.8), _rng.randf_range(0.3, 2.0), _rng.randf_range(-0.6, 0.6))
			var b := a + Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.5, 0.5), _rng.randf_range(-0.4, 0.4))
			_bolt(a, b, 3, 0.05)
		return
	# Sky bolts converging on the target (only during the strike).
	if _t < 1.5:
		for i in 3:
			var top := chest + Vector3(_rng.randf_range(-2.2, 2.2), 7.5, _rng.randf_range(-1.2, 1.2))
			var end := chest + Vector3(_rng.randf_range(-0.5, 0.5), _rng.randf_range(-1.0, 0.2), _rng.randf_range(-0.4, 0.4))
			_bolt(top, end, 9, 0.12)
	# Ground arcs radiating from the target.
	for i in 6:
		var ang := _rng.randf() * TAU
		var r := _rng.randf_range(1.6, 3.4)
		var a := GIBLE_POS + Vector3(cos(ang) * 0.6, 0.08, sin(ang) * 0.6)
		var b := GIBLE_POS + Vector3(cos(ang) * r, 0.08, sin(ang) * r)
		_bolt(a, b, 5, 0.1)
	# Crackle around the body.
	for i in 4:
		var a := chest + Vector3(_rng.randf_range(-1.3, 1.3), _rng.randf_range(-1.2, 1.4), _rng.randf_range(-1.0, 1.0))
		var b := a + Vector3(_rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.5, 0.5))
		_bolt(a, b, 3, 0.07)
	# Cage of vertical lines.
	for i in 8:
		if _rng.randf() < 0.3:
			continue
		var ang := TAU * i / 8.0
		var base := GIBLE_POS + Vector3(cos(ang) * 2.0, 0.0, sin(ang) * 2.0)
		_seg(base, base + Vector3(0, _rng.randf_range(2.0, 4.2), 0), 0.05, 0.14)


## Angular lightning: a zigzag with hard alternating offsets, white core over a violet glow.
func _bolt(a: Vector3, b: Vector3, parts: int, spread: float) -> void:
	var pts: Array[Vector3] = [a]
	var dir := (b - a)
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = Vector3.RIGHT
	side = side.normalized()
	var up := side.cross(dir.normalized()).normalized()
	for i in range(1, parts):
		var k := float(i) / parts
		var off := side * _rng.randf_range(-1.0, 1.0) * spread * dir.length() * 0.18 + up * _rng.randf_range(-1.0, 1.0) * spread * dir.length() * 0.12
		pts.append(a.lerp(b, k) + off)
	pts.append(b)
	for i in range(pts.size() - 1):
		_seg(pts[i], pts[i + 1], 0.07, 0.22)
	if parts >= 8 and _rng.randf() < 0.7:
		# A fork off the middle.
		var mid := pts[parts / 2]
		var tip := mid + Vector3(_rng.randf_range(-1.4, 1.4), -_rng.randf_range(0.8, 1.8), _rng.randf_range(-0.8, 0.8))
		_seg(mid, tip, 0.045, 0.14)


func _seg(a: Vector3, b: Vector3, core: float, glow: float) -> void:
	var length := a.distance_to(b)
	if length < 0.01:
		return
	for layer in 2:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		var t := core if layer == 0 else glow
		box.size = Vector3(t, t, length)
		mi.mesh = box
		mi.material_override = _core_mat if layer == 0 else _glow_mat
		mi.position = (a + b) * 0.5
		_bolt_root.add_child(mi)
		var up := Vector3.UP if absf((b - a).normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		mi.look_at(b, up)


# --- 4: Confusion (Confusão) ----------------------------------------------------------------

func _setup_confusion() -> void:
	var sm := ShaderMaterial.new()
	sm.shader = load("res://tests/fx_lab/shaders/spiral.gdshader")
	_spiral_floor = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	_spiral_floor.mesh = q
	_spiral_floor.material_override = sm
	_spiral_floor.rotation.x = -PI / 2.0
	_spiral_floor.position = GIBLE_POS + Vector3(0, 0.05, 0)
	_spiral_floor.scale = Vector3.ZERO
	_fx_root.add_child(_spiral_floor)
	var sm2 := ShaderMaterial.new()
	sm2.shader = load("res://tests/fx_lab/shaders/spiral.gdshader")
	sm2.set_shader_parameter("col_a", Color(1.0, 0.9, 0.2))
	sm2.set_shader_parameter("col_b", Color(0.6, 0.3, 1.0))
	_spiral_air = MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(1.0, 1.0)
	_spiral_air.mesh = q2
	_spiral_air.material_override = sm2
	_spiral_air.position = ABRA_POS + Vector3(0.8, 1.9, 0.0)
	_spiral_air.scale = Vector3.ONE * 0.4
	_fx_root.add_child(_spiral_air)


func _tick_confusion() -> void:
	var flight := clampf(_t / 0.7, 0.0, 1.0)
	var from := ABRA_POS + Vector3(0.8, 1.9, 0.0)
	var to := GIBLE_POS + Vector3(0, 2.6, 0.2)
	_spiral_air.position = from.lerp(to, flight)
	_spiral_air.look_at(_cam.global_position)
	if flight < 1.0:
		_spiral_air.scale = Vector3.ONE * lerpf(0.5, 1.6, flight)
	else:
		var k := clampf((_t - 0.7) / 0.5, 0.0, 1.0)
		_spiral_air.scale = Vector3.ONE * lerpf(1.6, 2.4, k)
		(_spiral_air.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0 - clampf((_t - 2.0) / 0.5, 0.0, 1.0))
	if _t >= 0.7:
		var g := clampf((_t - 0.7) / 0.35, 0.0, 1.0)
		_spiral_floor.scale = Vector3.ONE * lerpf(0.5, 5.2, 1.0 - pow(1.0 - g, 3.0))
		(_spiral_floor.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0 - clampf((_t - 2.0) / 0.5, 0.0, 1.0))
		# Dizzy wobble of the target, as seen through water.
		if _t < 2.2:
			_gible.rotation.y = -PI / 2.0 + 0.1 * sin(_t * 9.0)
			_gible.scale = Vector3(1.0 + 0.06 * sin(_t * 13.0), 1.0 + 0.06 * sin(_t * 13.0 + 1.5), 1.0 + 0.06 * sin(_t * 13.0 + 3.0))
		# Ripple rings.
		if fmod(_t - 0.7, 0.35) < get_process_delta_time() and _t < 1.9:
			_ripple(GIBLE_POS + Vector3(0, 0.07, 0))


func _ripple(pos: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	ring.mesh = torus
	ring.material_override = _unshaded(Color(1.0, 0.3, 0.75), 1.0, false)
	ring.position = pos
	ring.scale = Vector3(0.6, 0.15, 0.6)
	_fx_root.add_child(ring)
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(4.2, 0.15, 4.2), 0.8)
	tw.tween_property(ring, "position:y", pos.y + 1.6, 0.8)
	tw.chain().tween_callback(ring.queue_free)
