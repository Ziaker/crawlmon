extends SceneTree
## D-1100 / D-235 — harness do VFX do avanço no overworld.
##
## Teste headless (asserções):
##   Godot --headless --path . --fixed-fps 60 --script res://tests/overworld/test_dash_vfx.gd
##
## Capturas windowed (normal + espelhada, 0,03/0,10/0,20/0,40/0,70 s):
##   Godot --path . --fixed-fps 60 --resolution 1280x720 --position -4000,0 \
##     --script res://tests/overworld/test_dash_vfx.gd -- --capture
##
## As capturas vão para docs/referencias/exploracao/3d/ (nomes novos, sem
## sobrescrever os arquivos existentes). O teste usa um ator e um alvo dummy,
## sem nome/time/is_player: o mesmo efeito roda com os papéis trocados e a
## câmera do outro lado (D-235). D-308 não se aplica a este efeito (D-1100).

const VFX_SCRIPT := preload("res://scripts/overworld/vfx/overworld_dash_vfx.gd")

const OUT_DIR := "res://docs/referencias/exploracao/3d"
const FIXED_DT := 1.0 / 60.0
const CAPTURE_TIMES := [0.03, 0.10, 0.20, 0.40, 0.70]
const DASH_DURATION := 0.35
const DASH_DISTANCE := 2.1
const OVERDRAW_LAYER_LUMA := 36.6 / 255.0  # calibração D-1044 / skill, Compatibility

var failures := 0
var checks := 0
var _capture := false

var _world: Node3D
var _camera: Camera3D
var _actor: CharacterBody3D
var _target: CharacterBody3D
var _vfx: VFX_SCRIPT

var _dash_start := Vector3.ZERO
var _dash_dir := Vector3.RIGHT
var _manual_time := 0.0
var _dash_finished := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=".repeat(78))
	print("  CRAWLMON — OVERWORLD DASH VFX HARNESS (D-1100 / D-235)")
	print("=".repeat(78))
	var user_args := OS.get_cmdline_user_args()
	var want_capture := "--capture" in user_args
	if want_capture and DisplayServer.get_name() == "headless":
		print("[capture] IGNORADO: DisplayServer=headless; rode sem --headless para gerar PNGs.")
	_capture = want_capture and DisplayServer.get_name() != "headless"

	await _build_fixture(
		Vector3(-2.2, 0.0, 0.0), Vector3(2.2, 0.0, 0.0),
		1.0, 1.8,
		Vector3(0.0, 2.0, -5.4), Vector3(0.0, 0.75, 0.1), 3.9
	)
	_test_api_and_colors()
	_test_lifecycle()
	_test_auto_finish()
	_test_ground_raycast()
	_test_run_dust()
	await _test_matrix()

	if _capture:
		await _run_captures()
	else:
		_clear_world()

	print("-".repeat(78))
	print("OVERWORLD_DASH_VFX_" + ("PASS" if failures == 0 else "FAIL") + " checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- Asserções ---------------------------------------------------------------

func _test_api_and_colors() -> void:
	print("[1] API e cores por variante")
	_vfx.setup(_actor, _target)
	var expected := [
		VFX_SCRIPT.COLOR_NORMAL,
		VFX_SCRIPT.COLOR_PLAYER_FIRST,
		VFX_SCRIPT.COLOR_ENEMY_FIRST,
	]
	for adv in [0, 1, 2]:
		_vfx.begin_dash(adv)
		_check(_vfx.is_active(), "begin_dash(%d) ativa o efeito" % adv)
		_check(_vfx.get_effect_color().is_equal_approx(expected[adv]),
			"variante %d usa a cor %s" % [adv, expected[adv]])
		var state: Dictionary = _vfx.get_debug_state()
		_check(bool(state["speedlines"]["active"]) if state["speedlines"].has("active") else false,
			"variante %d criou speedlines" % adv)
		_vfx.clear()
		_check(_vfx.get_child_count() == 0, "clear() da variante %d não deixa filhos" % adv)
	_check(not _vfx.is_active(), "clear() desativa")
	_vfx.clear()
	_check(_vfx.get_child_count() == 0, "clear() é idempotente")


func _test_lifecycle() -> void:
	print("[2] Ciclo de vida, rastro no chão e poeira")
	_vfx.setup(_actor, _target)
	_actor.global_position = _dash_start
	_vfx.begin_dash(1)
	_check(_vfx.is_active(), "ativo logo após begin_dash")
	var initial: Dictionary = _vfx.get_debug_state()
	_check(int(initial["trail"]["points"]) >= 1, "raycast adicionou o ponto inicial do rastro")

	for i in 6:
		_actor.global_position += _dash_dir * 0.1
		_vfx.tick(FIXED_DT)
	var state: Dictionary = _vfx.get_debug_state()
	_check(int(state["speedlines"]["active"]) > 0, "speedlines ativas durante o avanço")
	_check(int(state["trail"]["points"]) >= 2, "rastro acompanhou o caminho (>=2 pontos)")
	_check(float(state["trail"]["span"]) >= 0.45,
		"rastro cobre o caminho percorrido (span=%.3f m)" % float(state["trail"]["span"]))
	_check(float(state["trail"]["max_above_ground"]) <= 0.041,
		"rastro a no máximo 4,1 cm do chão (medido=%.4f)" % float(state["trail"]["max_above_ground"]))
	_check(bool(state["dust"]["emitting"]), "poeira emitindo durante o avanço")
	_check(is_equal_approx(float(state["dust"]["alpha"]), 0.22),
		"poeira com alpha reduzido 0,22 (era 0,42 no FootDust)")

	# D-1119: o criador pediu animação visível; o teste mede o transform local
	# das mesmas linhas em dois instantes, sem depender de olhar o PNG.
	var before: Array = _vfx.get_streak_snapshot()
	var before_by_name := {}
	for b in before:
		before_by_name[String(b["name"])] = b
	for i in 6:
		_actor.global_position += _dash_dir * 0.1
		_vfx.tick(FIXED_DT)
	var after: Array = _vfx.get_streak_snapshot()
	var moved := 0
	var stretched := 0
	var compared := 0
	for a in after:
		var key := String(a["name"])
		if not before_by_name.has(key):
			continue
		compared += 1
		var b: Dictionary = before_by_name[key]
		if (a["pos"] as Vector3).distance_to(b["pos"]) >= 0.08:
			moved += 1
		if absf(float(a["length"]) - float(b["length"])) >= 0.05:
			stretched += 1
	_check(compared >= 5, "D-1119: linhas persistentes para comparar movimento (%d)" % compared)
	_check(moved >= 3, "D-1119: speedlines deslizam de verdade (%d/%d)" % [moved, compared])
	_check(stretched >= 3, "D-1119: speedlines alongam/encolhem de verdade (%d/%d)" % [stretched, compared])

	_vfx.finish()
	_check(not _vfx.is_active(), "finish() desativa")
	for i in 120:
		_vfx.tick(FIXED_DT)
	_check(_vfx.get_child_count() == 0, "sem nós após ~2 s do begin")
	_check(_vfx.find_children("*", "CPUParticles3D", true, false).is_empty(),
		"sem CPUParticles3D restante após ~2 s")
	_check(_vfx.find_children("*", "MeshInstance3D", true, false).is_empty(),
		"sem MeshInstance3D restante após ~2 s")


func _test_auto_finish() -> void:
	print("[3] Limite de segurança (avanço sem finish)")
	_vfx.setup(_actor, _target)
	_vfx.begin_dash(0)
	for i in 132:  # 2,2 s
		_vfx.tick(FIXED_DT)
	_check(_vfx.get_child_count() == 0, "auto-finish/clear em 2,2 s sem finish explícito")
	_check(not _vfx.is_active(), "não fica ativo para sempre")


func _test_ground_raycast() -> void:
	print("[4] Rastro ancorado por raycast (ator acima do chão)")
	_vfx.setup(_actor, _target)
	var floating := _dash_start + Vector3(0.0, 0.6, 0.0)
	_actor.global_position = floating
	_vfx.begin_dash(2)
	for i in 6:
		_actor.global_position = floating + _dash_dir * (0.1 * float(i + 1))
		_vfx.tick(FIXED_DT)
	var state: Dictionary = _vfx.get_debug_state()
	_check(int(state["trail"]["points"]) >= 2, "rastro existe com o ator 0,6 m acima do chão")
	_check(float(state["trail"]["max_above_ground"]) <= 0.041,
		"rastro ficou no chão, não na altura do ator (max=%.4f)" % float(state["trail"]["max_above_ground"]))
	_vfx.finish()
	_vfx.clear()


func _test_run_dust() -> void:
	print("[5] FootDust de corrida: alpha reduzido só no avanço")
	_vfx.setup(_actor, _target)
	var dust := CPUParticles3D.new()
	dust.name = "LabFootDustProbe"
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.62, 0.52, 0.40, 0.42)
	dust.material_override = mat
	dust.emitting = false
	_world.add_child(dust)
	_vfx.set_run_dust(dust)
	_vfx.begin_dash(1)
	_check(is_equal_approx(float(_vfx.get_debug_state()["run_dust_alpha"]), 0.22),
		"FootDust do lab caiu para 0,22 durante o avanço")
	_vfx.finish()
	_check(is_equal_approx(float(_vfx.get_debug_state()["run_dust_alpha"]), 0.42),
		"FootDust do lab voltou a 0,42 no finish")
	_vfx.clear()
	_check(is_equal_approx(float(mat.albedo_color.a), 0.42), "FootDust restaurado no clear")


func _test_matrix() -> void:
	print("[6] Matriz D-235: papéis, lados, eixos e tamanhos")
	var cases := [
		{"name": "normal 1,0 vs 1,8", "a": Vector3(-2.2, 0, 0), "t": Vector3(2.2, 0, 0), "ah": 1.0, "th": 1.8, "adv": 1},
		{"name": "espelhado 2,1 vs 0,7", "a": Vector3(2.2, 0, 0), "t": Vector3(-2.2, 0, 0), "ah": 2.1, "th": 0.7, "adv": 2},
		{"name": "diagonal 0,7 vs 2,4", "a": Vector3(-2.2, 0, 0.8), "t": Vector3(2.2, 0, -0.8), "ah": 0.7, "th": 2.4, "adv": 0},
		{"name": "diagonal espelhada 2,4 vs 1,0", "a": Vector3(2.2, 0, -0.8), "t": Vector3(-2.2, 0, 0.8), "ah": 2.4, "th": 1.0, "adv": 1},
	]
	for c in cases:
		await _build_fixture(
			c["a"], c["t"], float(c["ah"]), float(c["th"]),
			Vector3(0.0, 2.0, -5.4), Vector3(0.0, 0.75, 0.1),
			3.9 if (c["t"] as Vector3).x >= 0.0 else -3.9
		)
		_vfx.begin_dash(int(c["adv"]))
		var state: Dictionary = _vfx.get_debug_state()
		_check(float(state["body_height"]) > 0.4, "%s: altura do corpo medida" % c["name"])
		_check(absf(float(state["body_height"]) - float(c["ah"])) <= 0.12,
			"%s: altura medida %.2f ≈ ator %.2f" % [c["name"], float(state["body_height"]), float(c["ah"])])
		for i in 6:
			_actor.global_position += _dash_dir * 0.1
			_vfx.tick(FIXED_DT)
		state = _vfx.get_debug_state()
		_check(int(state["speedlines"]["active"]) > 0, "%s: speedlines no outro lado/ator" % c["name"])
		_check(int(state["trail"]["points"]) >= 2, "%s: rastro no outro lado/ator" % c["name"])
		_check(float(state["trail"]["max_above_ground"]) <= 0.041, "%s: rastro no chão" % c["name"])
		_check(_vfx.get_effect_color().is_equal_approx(_vfx.color_for_advantage(int(c["adv"]))),
			"%s: cor da variante" % c["name"])
		_vfx.clear()
		_check(_vfx.get_child_count() == 0, "%s: clear limpo" % c["name"])


# --- Capturas ----------------------------------------------------------------

func _run_captures() -> void:
	print("[7] Capturas: vista normal e espelhada (--fixed-fps 60)")
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var views := [
		{
			"name": "normal",
			"actor": Vector3(-2.2, 0, 0), "target": Vector3(2.2, 0, 0),
			"ah": 1.6, "th": 1.0, "adv": VFX_SCRIPT.ADVANTAGE_PLAYER_FIRST,
			"cam": Vector3(-1.15, 1.9, -5.0), "look": Vector3(-1.15, 0.70, 0.0), "wall": 7.5,
		},
		{
			"name": "mirror",
			"actor": Vector3(2.2, 0, 0), "target": Vector3(-2.2, 0, 0),
			"ah": 2.1, "th": 0.75, "adv": VFX_SCRIPT.ADVANTAGE_ENEMY_FIRST,
			"cam": Vector3(1.15, 1.9, 5.0), "look": Vector3(1.15, 0.70, 0.0), "wall": -7.5,
		},
	]
	var frames: Array[Image] = []
	for v in views:
		await _build_fixture(
			v["actor"], v["target"], float(v["ah"]), float(v["th"]),
			v["cam"], v["look"], float(v["wall"])
		)
		await _capture_view(v, frames, abs_dir)
		await _wait_frames(1)
	print("[7] Folha de contato")
	_make_contact_sheet(frames, abs_dir)


func _capture_view(view: Dictionary, frames: Array[Image], abs_dir: String) -> void:
	var name := String(view["name"])
	print("[7] vista=%s adv=%d ator=%.2f alvo=%.2f" % [name, int(view["adv"]), float(view["ah"]), float(view["th"])])
	_vfx.begin_dash(int(view["adv"]))
	_manual_time = 0.0
	_dash_finished = false
	for t_target in CAPTURE_TIMES:
		while _manual_time < float(t_target) - 0.0001:
			await process_frame
			_manual_time += FIXED_DT
			_tick_capture_dash()
		await _wait_frames(1)
		var img := await _grab_frame()
		var tag := "%03d" % int(round(float(t_target) * 1000.0))
		var file_name := "overworld_dash_vfx_%s_%s.png" % [name, tag]
		img.save_png(abs_dir.path_join(file_name))
		frames.append(img)
		var stats := _image_stats(img)
		print("      %s  mean=%.3f std=%.3f  %dx%d" % [
			file_name, stats["mean"], stats["std"], img.get_width(), img.get_height()
		])
		_check(float(stats["std"]) > 0.02, "%s: quadro não é uniforme/preto" % file_name)
		_check(float(stats["mean"]) > 0.02 and float(stats["mean"]) < 0.98, "%s: exposição razoável" % file_name)
		if is_equal_approx(float(t_target), 0.20):
			await _diagnose_frame(name, img, abs_dir)

	print("      verificando restos até 2 s...")
	while _manual_time < 2.0:
		await process_frame
		_manual_time += FIXED_DT
		_tick_capture_dash()
	_check(_vfx.get_child_count() == 0, "%s: sem restos após ~2 s" % name)
	_check(_vfx.find_children("*", "CPUParticles3D", true, false).is_empty(),
		"%s: sem poeira restante após ~2 s" % name)
	_vfx.clear()
	_clear_world()


func _tick_capture_dash() -> void:
	if _vfx == null or not is_instance_valid(_vfx):
		return
	if _manual_time <= DASH_DURATION:
		var k := clampf(_manual_time / DASH_DURATION, 0.0, 1.0)
		_actor.global_position = _dash_start + _dash_dir * (DASH_DISTANCE * k)
	elif not _dash_finished:
		_vfx.finish()
		_dash_finished = true
	_vfx.tick(FIXED_DT)


func _diagnose_frame(view_name: String, frame_full: Image, abs_dir: String) -> void:
	print("      [diagnóstico] %s: frame estático, diff e overdraw" % view_name)
	_vfx.set_analysis_freeze(true)
	await _wait_frames(1)
	var full_frozen := await _grab_frame()

	_vfx.visible = false
	await _wait_frames(1)
	var base_color := await _grab_frame()
	_vfx.visible = true

	var changed := _changed_ratio(full_frozen, base_color)
	print("      [diff] %s: pixels com VFX = %.2f%%" % [view_name, changed * 100.0])
	_check(changed > 0.005, "%s: VFX visível (%.2f%% dos pixels)" % [view_name, changed * 100.0])
	_check(changed < 0.60, "%s: VFX não cobre a tela inteira" % view_name)

	# Overdraw medido no material de diagnóstico (1 camada = 36,6/255, a
	# calibração Compatibility da skill). O DEBUG_DRAW_OVERDRAW da engine
	# desconta o alpha vertex-color do ImmediateMesh e não serve para a fita.
	var overdraw := _apply_overdraw_material()
	_vfx.visible = false
	await _wait_frames(1)
	var od_base := await _grab_frame()
	_vfx.visible = true
	await _wait_frames(1)
	var od_full := await _grab_frame()
	_restore_overdraw_material(overdraw)
	_vfx.set_analysis_freeze(false)
	_vfx.visible = true
	await _wait_frames(1)

	var od := _overdraw_stats(od_base, od_full)
	print("      [overdraw] %s: p50=%.2f p95=%.2f p99=%.2f max=%.2f amostras=%d" % [
		view_name, od["p50"], od["p95"], od["p99"], od["max"], od["affected"]
	])
	_check(int(od["affected"]) > 100, "%s: overdraw encontrou o efeito" % view_name)
	_check(float(od["p99"]) <= 5.0, "%s: overdraw p99 <= 5 camadas" % view_name)
	_check(float(od["max"]) <= 6.5, "%s: overdraw máximo <= 6,5 camadas" % view_name)
	od_full.save_png(abs_dir.path_join("overworld_dash_vfx_%s_overdraw.png" % view_name))
	# Comparação direta: o quadro normal salvo deve ser o mesmo estado congelado.
	var drift := _changed_ratio(frame_full, full_frozen)
	_check(drift < 0.02, "%s: congelamento estável (drift=%.3f%%)" % [view_name, drift * 100.0])


func _apply_overdraw_material() -> Dictionary:
	var diag := StandardMaterial3D.new()
	diag.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	diag.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	diag.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	diag.cull_mode = BaseMaterial3D.CULL_DISABLED
	diag.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	diag.disable_receive_shadows = true
	diag.albedo_color = Color(OVERDRAW_LAYER_LUMA, OVERDRAW_LAYER_LUMA, OVERDRAW_LAYER_LUMA, 1.0)
	var saved := {}
	for n in _vfx.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		saved[mi] = mi.material_override
		mi.material_override = diag
	for n in _vfx.find_children("*", "CPUParticles3D", true, false):
		var p := n as CPUParticles3D
		saved[p] = p.material_override
		p.material_override = diag
	return saved


func _restore_overdraw_material(saved: Dictionary) -> void:
	for node in saved:
		if not is_instance_valid(node):
			continue
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = saved[node]
		elif node is CPUParticles3D:
			(node as CPUParticles3D).material_override = saved[node]


func _make_contact_sheet(frames: Array[Image], abs_dir: String) -> void:
	if frames.size() != 10:
		_check(false, "folha de contato exige 10 quadros (tem %d)" % frames.size())
		return
	var tw := 320
	var th := 180
	var sheet := Image.create(tw * 5, th * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.02, 0.02, 0.02, 1.0))
	for i in frames.size():
		var tile := frames[i].duplicate() as Image
		tile.resize(tw, th, Image.INTERPOLATE_BILINEAR)
		var col := i % 5
		var row := i / 5
		sheet.blit_rect(tile, Rect2i(0, 0, tw, th), Vector2i(col * tw, row * th))
	var out := abs_dir.path_join("overworld_dash_vfx_contact_sheet.png")
	sheet.save_png(out)
	print("      folha=%s (%dx%d)" % [out, sheet.get_width(), sheet.get_height()])


# --- Fixture ------------------------------------------------------------------

func _build_fixture(
	actor_pos: Vector3, target_pos: Vector3, actor_h: float, target_h: float,
	cam_pos: Vector3, cam_look: Vector3, wall_x: float
) -> void:
	_clear_world()
	_world = Node3D.new()
	_world.name = "DashVfxHarnessWorld"
	root.add_child(_world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.045, 0.055, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.62, 0.70)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	var we := WorldEnvironment.new()
	we.environment = env
	_world.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key.light_color = Color(0.92, 0.88, 0.80)
	key.light_energy = 0.9
	key.shadow_enabled = true
	_world.add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 2.8, -1.6)
	fill.light_color = Color(1.0, 0.88, 0.74)
	fill.light_energy = 1.1
	fill.omni_range = 10.0
	_world.add_child(fill)

	_make_floor()
	_make_wall(wall_x)

	_actor = _make_dummy("ActorDummy", actor_pos, actor_h, Color(0.82, 0.48, 0.20), target_pos)
	_target = _make_dummy("TargetDummy", target_pos, target_h, Color(0.34, 0.46, 0.64), actor_pos)

	_camera = Camera3D.new()
	_camera.fov = 50.0
	_camera.near = 0.05
	_camera.far = 100.0
	_world.add_child(_camera)
	_camera.global_position = cam_pos
	_camera.look_at(cam_look)
	_camera.current = true

	await physics_frame
	await physics_frame
	await process_frame

	_vfx = VFX_SCRIPT.new()
	_vfx.name = "DashVfx"
	_world.add_child(_vfx)
	_vfx.setup(_actor, _target)
	await process_frame

	_dash_start = _actor.global_position
	_dash_dir = (_target.global_position - _actor.global_position)
	_dash_dir.y = 0.0
	_dash_dir = _dash_dir.normalized() if _dash_dir.length_squared() > 0.001 else Vector3.RIGHT
	_manual_time = 0.0
	_dash_finished = false


func _clear_world() -> void:
	if is_instance_valid(_vfx):
		_vfx.clear()
	if is_instance_valid(_world):
		if _world.get_parent() != null:
			_world.get_parent().remove_child(_world)
		_world.free()
	_world = null
	_camera = null
	_actor = null
	_target = null
	_vfx = null


func _make_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"
	body.position = Vector3(0.0, -0.3, 0.0)
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.6, 40.0)
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(40.0, 0.6, 40.0)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _checker_texture()
	mat.roughness = 0.9
	mat.metallic_specular = 0.1
	mi.material_override = mat
	body.add_child(mi)
	_world.add_child(body)


func _make_wall(x: float) -> void:
	var body := StaticBody3D.new()
	body.name = "BackdropWall"
	body.position = Vector3(x, 1.7, 0.0)
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 3.4, 10.0)
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.4, 3.4, 10.0)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.18, 0.22)
	mat.roughness = 0.95
	mi.material_override = mat
	body.add_child(mi)
	_world.add_child(body)


func _make_dummy(node_name: String, pos: Vector3, height: float, color: Color, face_pos: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 1
	var radius := clampf(height * 0.22, 0.12, 0.45)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = maxf(height, radius * 2.0 + 0.05)
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	body.add_child(shape)

	var mi := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = capsule.height
	mi.mesh = mesh
	mi.position.y = capsule.height * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mi.material_override = mat
	body.add_child(mi)

	# Marcador de frente: o corpo olha para +Z (mesma convenção dos modelos).
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.10, maxf(height * 0.08, 0.05), radius * 0.9)
	marker.mesh = box
	marker.position = Vector3(0.0, height * 0.72, radius + 0.03)
	var marker_mat := StandardMaterial3D.new()
	marker_mat.albedo_color = Color(0.95, 0.93, 0.85)
	marker_mat.roughness = 0.6
	marker.material_override = marker_mat
	body.add_child(marker)

	var face := face_pos - pos
	face.y = 0.0
	if face.length_squared() > 0.001:
		body.rotation.y = atan2(face.x, face.z)

	_add_blob_shadow(body, height)
	_world.add_child(body)
	return body


func _add_blob_shadow(parent: Node3D, height: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(height * 0.8, height * 0.5)
	var mi := MeshInstance3D.new()
	mi.name = "BlobShadow"
	mi.mesh = quad
	mi.rotation.x = -PI / 2.0
	mi.position.y = 0.035
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("dash_vfx_ignore_measure", true)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _radial_texture()
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.38)
	mi.material_override = mat
	parent.add_child(mi)


func _checker_texture() -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var cell := ((x / 16) + (y / 16)) % 2
			img.set_pixel(x, y, Color(0.20, 0.22, 0.25) if cell == 0 else Color(0.25, 0.27, 0.30))
	return ImageTexture.create_from_image(img)


func _radial_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 64
	tex.height = 64
	return tex


# --- Imagens ------------------------------------------------------------------

func _grab_frame() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _wait_frames(n: int) -> void:
	for i in n:
		await process_frame


func _changed_ratio(a: Image, b: Image) -> float:
	if a == null or b == null or a.get_size() != b.get_size():
		return 0.0
	var w := a.get_width()
	var h := a.get_height()
	var changed := 0
	var total := 0
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += 1
			if absf(ca.r - cb.r) > 0.02 or absf(ca.g - cb.g) > 0.02 or absf(ca.b - cb.b) > 0.02:
				changed += 1
	return float(changed) / float(maxi(total, 1))


func _image_stats(img: Image) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var sum := 0.0
	var sum_sq := 0.0
	var n := 0
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			var l := _luma(img.get_pixel(x, y))
			sum += l
			sum_sq += l * l
			n += 1
	var mean := sum / float(maxi(n, 1))
	var var_l := maxf(0.0, sum_sq / float(maxi(n, 1)) - mean * mean)
	return {"mean": mean, "std": sqrt(var_l), "samples": n}


func _overdraw_stats(base: Image, full: Image) -> Dictionary:
	var values: Array[float] = []
	var affected := 0
	if base == null or full == null or base.get_size() != full.get_size():
		return {"p50": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0, "affected": 0}
	var w := base.get_width()
	var h := base.get_height()
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var lb := _luma(base.get_pixel(x, y))
			var lf := _luma(full.get_pixel(x, y))
			var layers := clampf((lf - lb) / OVERDRAW_LAYER_LUMA, 0.0, 8.0)
			if layers > 0.4:
				values.append(layers)
				affected += 1
	if values.is_empty():
		return {"p50": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0, "affected": 0}
	values.sort()
	return {
		"p50": _pct(values, 0.50),
		"p95": _pct(values, 0.95),
		"p99": _pct(values, 0.99),
		"max": values[values.size() - 1],
		"affected": affected,
	}


func _pct(sorted_values: Array[float], p: float) -> float:
	var idx := clampi(int(floor(p * float(sorted_values.size() - 1))), 0, sorted_values.size() - 1)
	return sorted_values[idx]


func _luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("  [%s] %s" % ["PASS" if ok else "FAIL", msg])
