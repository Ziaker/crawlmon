extends Node3D
## Laboratório de inspeção do VFX 3D "Javelin Throw" (D-1162).
##
## Não é o VFX do jogo: a batalha usa `FxJavelinThrow` + `JavelinThrowVfx` dirigidos pelas
## fases reais do `Battle`. Aqui um relógio local de 0,00–1,85 s permite congelar exatamente
## 0,75 s (disparo), 0,90 s (vãos +0,15 s), 1,05 s (impacto) e 1,07 s (vãos +0,32 s).
## Os atores são só manequins de alturas diferentes; o efeito lê mão/peito/pés reais deles.

const VFX_SCRIPT = preload("res://scripts/vfx/combat/javelin_throw_vfx_html.gd")
const TOTAL := 1.85
const RELEASE := 0.75
const FLIGHT := 0.30
const HIT := RELEASE + FLIGHT

var _rig_a: Node3D
var _rig_b: Node3D
var _cam: Camera3D
var _vfx: JavelinThrowVfxHtml
var _view := "normal"
var _side_b := false
var _playing := true
var _crit := true
var _t := 0.0
var _cam_azimuth_deg := 0.0
var _cam_elevation_deg := 0.0

var _scrub: HSlider
var _time_label: Label
var _phase_label: Label
var _ui: CanvasLayer
var _updating_slider := false

var _capture := false
var _capture_out := "res://test_captures/javelin_lab"
var _capture_times: Array[float] = [0.75, 0.90, 1.05, 1.07, 1.20]
var _capture_view := "normal"
var _capture_side_b := false
var _capture_hide_ui := true


func _ready() -> void:
	_parse_capture_args()
	_build_arena()
	_build_ui()
	if _capture:
		_ui.visible = not _capture_hide_ui
		await _run_capture()
		return
	_draw_at(0.0)


func _process(delta: float) -> void:
	if _capture:
		return
	if _playing:
		_t += delta
		if _t >= TOTAL:
			_t = fmod(_t, TOTAL)
		_draw_at(_t)
	if _scrub != null and not _updating_slider:
		_updating_slider = true
		_scrub.value = _t
		_updating_slider = false


## Congela e desenha o instante pedido (0,00–1,85 s). É o "scrub" público do laboratório;
## na batalha quem manda no relógio é o `Incoming` (D-019/D-1040).
func set_scrub_time(t: float) -> void:
	_playing = false
	_draw_at(t)


func _draw_at(t: float) -> void:
	_t = clampf(t, 0.0, TOTAL)
	var a := _rig_a if not _side_b else _rig_b
	var b := _rig_b if not _side_b else _rig_a
	var hand := (a.get_node("HandSocket") as Node3D).global_position
	var chest := (b.get_node("ChestSocket") as Node3D).global_position
	var tgt_h := float(b.get_meta("actor_height", 1.9))
	var tgt_r := float(b.get_meta("actor_radius", 0.5))
	var feet := Vector3(chest.x, 0.0, chest.z)
	var axis := (chest - hand).normalized()
	var dist := hand.distance_to(chest)
	var impact_scale := clampf(tgt_r * 1.6, 0.75, 1.65)

	var stage := "windup"
	var windup_t := 0.0
	var release_t := -1.0
	var flight_u := 0.0
	var flight_t := 0.0
	var since := -1.0
	if _t < RELEASE:
		stage = "windup"
		windup_t = _t
	elif _t < HIT:
		stage = "flight"
		release_t = _t - RELEASE
		flight_t = release_t
		flight_u = clampf(release_t / FLIGHT, 0.0, 1.0)
	else:
		stage = "impact"
		release_t = _t - RELEASE
		flight_t = FLIGHT
		flight_u = 1.0
		since = _t - HIT

	_vfx.draw({
		"stage": stage,
		"hand": hand,
		"chest": chest,
		"feet": feet,
		"axis": axis,
		"distance": dist,
		"impact_scale": impact_scale,
		"target_radius": tgt_r,
		"view_scale": 1.0,
		"windup_t": windup_t,
		"windup_total": RELEASE,
		"flight_u": flight_u,
		"flight_t": flight_t,
		"flight_duration": FLIGHT,
		"release_t": release_t,
		"since_impact": since,
		"impact_chest": chest,
		"crit": _crit,
	})
	_update_labels(stage)


func _update_labels(stage: String) -> void:
	if _time_label != null:
		_time_label.text = "%.2fs / %.2fs" % [_t, TOTAL]
	if _phase_label != null:
		match stage:
			"windup":
				_phase_label.text = "WIND-UP — 5 peças, pulso âmbar, estrela e retículo"
			"flight":
				_phase_label.text = "RELEASE + TRAJETO — coroa de 7 lâminas e 7 pós-imagens 3D"
			_:
				_phase_label.text = "IMPACTO — cruz 3D, flash crítico, anel atrasado e solo"


func _debug_state() -> String:
	if _vfx == null:
		return ""
	var s := _vfx.debug_state()
	return "hand=%s chest=%s axis=%s tip=%s bz=%s" % [s.get("hand"), s.get("chest"), s.get("axis"), s.get("tip"), s.get("basis_z")]


# ============================================================================
# ARENA
# ============================================================================

func _build_arena() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0B1017")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#26384A")
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 38.0, 0.0)
	sun.light_energy = 1.2
	add_child(sun)

	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 18.0)
	floor_mi.mesh = plane
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#0F172A")
	fm.roughness = 0.9
	floor_mi.material_override = fm
	add_child(floor_mi)

	var grid := MeshInstance3D.new()
	var grid_mesh := PlaneMesh.new()
	grid_mesh.size = Vector2(18.0, 18.0)
	grid.mesh = grid_mesh
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#15263A")
	gm.emission_enabled = true
	gm.emission = Color("#1E3A52")
	gm.emission_energy_multiplier = 0.35
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color.a = 0.25
	grid.material_override = gm
	grid.position.y = 0.005
	add_child(grid)

	_rig_a = _make_rig("Rig_Alpha", 2.12, 0.58, Color("#38BDF8"), Color("#0F2A3D"))
	_rig_b = _make_rig("Rig_Beta", 1.90, 0.48, Color("#F43F5E"), Color("#32101A"))
	add_child(_rig_a)
	add_child(_rig_b)

	_cam = Camera3D.new()
	_cam.fov = 42.0
	add_child(_cam)

	_vfx = VFX_SCRIPT.new()
	_vfx.name = "JavelinThrowVfx"
	add_child(_vfx)
	_vfx.setup(_cam)

	_apply_slots()
	_apply_view()


func _make_rig(rig_name: String, h: float, r: float, accent: Color, dark: Color) -> Node3D:
	var root := Node3D.new()
	root.name = rig_name
	root.set_meta("actor_height", h)
	root.set_meta("actor_radius", r)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = dark
	body_mat.roughness = 0.55
	body_mat.metallic = 0.25
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = accent
	accent_mat.emission_enabled = true
	accent_mat.emission = accent
	accent_mat.emission_energy_multiplier = 0.55

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = r * 1.15
	base_mesh.bottom_radius = r * 1.30
	base_mesh.height = 0.14
	base_mesh.radial_segments = 6
	base.mesh = base_mesh
	base.position.y = 0.07
	base.material_override = body_mat
	root.add_child(base)

	var torso := MeshInstance3D.new()
	var torso_mesh := CylinderMesh.new()
	torso_mesh.top_radius = r * 0.82
	torso_mesh.bottom_radius = r * 0.62
	torso_mesh.height = h * 0.42
	torso_mesh.radial_segments = 6
	torso.mesh = torso_mesh
	torso.position.y = h * 0.58
	torso.material_override = body_mat
	root.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = r * 0.34
	head_mesh.height = r * 0.68
	head_mesh.radial_segments = 8
	head_mesh.rings = 4
	head.mesh = head_mesh
	head.position.y = h * 0.88
	head.material_override = body_mat
	root.add_child(head)

	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(r * 0.56, h * 0.035, r * 0.30)
	visor.mesh = visor_mesh
	visor.position = Vector3(0.0, h * 0.89, r * 0.24)
	visor.material_override = accent_mat
	root.add_child(visor)

	var chest := Node3D.new()
	chest.name = "ChestSocket"
	chest.position = Vector3(0.0, h * 0.62, 0.0)
	root.add_child(chest)
	var emblem := MeshInstance3D.new()
	var emblem_mesh := SphereMesh.new()
	emblem_mesh.radius = r * 0.16
	emblem_mesh.height = r * 0.32
	emblem_mesh.radial_segments = 4
	emblem_mesh.rings = 2
	emblem.mesh = emblem_mesh
	emblem.position = Vector3(0.0, 0.0, r * 0.30)
	emblem.material_override = accent_mat
	chest.add_child(emblem)

	var hand := Node3D.new()
	hand.name = "HandSocket"
	hand.position = Vector3(r * 0.78, h * 0.72, r * 0.18)
	root.add_child(hand)

	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(r * 0.22, r * 0.22, h * 0.30)
	arm.mesh = arm_mesh
	arm.position = Vector3(r * 0.62, h * 0.70, r * 0.10)
	arm.rotation_degrees = Vector3(-48.0, 0.0, 0.0)
	arm.material_override = body_mat
	root.add_child(arm)

	return root


func _apply_slots() -> void:
	var near := Vector3(-2.15, 0.0, 2.35)
	var far := Vector3(2.35, 0.0, -2.45)
	if not _side_b:
		_rig_a.global_position = near
		_rig_b.global_position = far
	else:
		_rig_a.global_position = far
		_rig_b.global_position = near
	_rig_a.look_at(_rig_b.global_position + Vector3(0.0, 0.9, 0.0), Vector3.UP)
	_rig_b.look_at(_rig_a.global_position + Vector3(0.0, 0.9, 0.0), Vector3.UP)


func _apply_view() -> void:
	if _cam == null:
		return
	var a := _rig_a if not _side_b else _rig_b
	var b := _rig_b if not _side_b else _rig_a
	var ap := a.global_position + Vector3(0.0, 1.1, 0.0)
	var bp := b.global_position + Vector3(0.0, 1.1, 0.0)
	var mid := ap.lerp(bp, 0.50)
	var dir := (bp - ap).normalized()
	var right := Vector3.UP.cross(dir).normalized()
	var look := mid
	match _view:
		"normal":
			_cam.global_position = ap - dir * 4.2 + right * 5.2 + Vector3(0.0, 3.2, 0.0)
		"mirror":
			_cam.global_position = bp + dir * 4.0 - right * 5.0 + Vector3(0.0, 3.0, 0.0)
			look = bp.lerp(ap, 0.45)
		_:
			_cam.global_position = mid + right * 7.5 - dir * 2.5 + Vector3(0.0, 3.2, 0.0)

	# Sliders do script original: azimute em torno do alvo e elevação relativa.
	var off := _cam.global_position - look
	var radius := off.length()
	if radius > 0.01:
		var base_yaw := atan2(off.x, off.z)
		var base_pitch := asin(clampf(off.y / radius, -1.0, 1.0))
		var yaw := base_yaw + deg_to_rad(_cam_azimuth_deg)
		var pitch := clampf(base_pitch + deg_to_rad(_cam_elevation_deg), deg_to_rad(-5.0), deg_to_rad(70.0))
		_cam.global_position = look + Vector3(
			sin(yaw) * cos(pitch) * radius,
			sin(pitch) * radius,
			cos(yaw) * cos(pitch) * radius
		)
	_cam.look_at(look, Vector3.UP)


# ============================================================================
# UI
# ============================================================================

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_ui.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var row1 := HBoxContainer.new()
	vbox.add_child(row1)

	for v in ["normal", "mirror", "oblique"]:
		var btn := Button.new()
		btn.text = "View: " + v
		btn.pressed.connect(func() -> void:
			_view = v
			_apply_view()
			_draw_at(_t)
		)
		row1.add_child(btn)

	var side := Button.new()
	side.text = "Trocar lado (A/B)"
	side.pressed.connect(func() -> void:
		_side_b = not _side_b
		_apply_slots()
		_apply_view()
		_draw_at(_t)
	)
	row1.add_child(side)

	var pause := Button.new()
	pause.text = "Pausar / retomar"
	pause.pressed.connect(func() -> void: _playing = not _playing)
	row1.add_child(pause)

	var crit := CheckButton.new()
	crit.text = "Crítico"
	crit.button_pressed = _crit
	crit.toggled.connect(func(on: bool) -> void:
		_crit = on
		_draw_at(_t)
	)
	row1.add_child(crit)

	var row2 := HBoxContainer.new()
	vbox.add_child(row2)
	for pair in [[0.75, "Disparo 0.75s"], [0.90, "Vãos +0.15s"], [1.05, "Impacto 1.05s"], [1.07, "Vãos +0.32s"]]:
		var b := Button.new()
		b.text = String(pair[1])
		b.pressed.connect(func() -> void:
			_playing = false
			_draw_at(float(pair[0]))
		)
		row2.add_child(b)

	var row_cam := HBoxContainer.new()
	vbox.add_child(row_cam)
	var lbl_az := Label.new()
	lbl_az.text = "Azimute:"
	row_cam.add_child(lbl_az)
	var sl_az := HSlider.new()
	sl_az.min_value = -180.0
	sl_az.max_value = 180.0
	sl_az.step = 1.0
	sl_az.custom_minimum_size = Vector2(140.0, 0.0)
	sl_az.value_changed.connect(func(v: float) -> void:
		_cam_azimuth_deg = v
		_apply_view()
		_draw_at(_t)
	)
	row_cam.add_child(sl_az)
	var lbl_el := Label.new()
	lbl_el.text = "Elevação:"
	row_cam.add_child(lbl_el)
	var sl_el := HSlider.new()
	sl_el.min_value = -10.0
	sl_el.max_value = 40.0
	sl_el.step = 1.0
	sl_el.custom_minimum_size = Vector2(120.0, 0.0)
	sl_el.value_changed.connect(func(v: float) -> void:
		_cam_elevation_deg = v
		_apply_view()
		_draw_at(_t)
	)
	row_cam.add_child(sl_el)

	var row3 := HBoxContainer.new()
	vbox.add_child(row3)
	var lbl := Label.new()
	lbl.text = "Scrub:"
	row3.add_child(lbl)
	_scrub = HSlider.new()
	_scrub.min_value = 0.0
	_scrub.max_value = TOTAL
	_scrub.step = 0.005
	_scrub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scrub.value_changed.connect(func(v: float) -> void:
		if _updating_slider:
			return
		_playing = false
		_draw_at(v)
	)
	row3.add_child(_scrub)
	_time_label = Label.new()
	row3.add_child(_time_label)
	_phase_label = Label.new()
	row3.add_child(_phase_label)


# ============================================================================
# CAPTURA CLI (windowed, para prova visual)
# ============================================================================

func _parse_capture_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--lab-capture":
			_capture = true
		elif arg.begins_with("--lab-out="):
			_capture_out = arg.trim_prefix("--lab-out=")
		elif arg.begins_with("--lab-times="):
			var parts := arg.trim_prefix("--lab-times=").split(",")
			_capture_times.clear()
			for p in parts:
				_capture_times.append(float(p))
		elif arg.begins_with("--lab-view="):
			_capture_view = arg.trim_prefix("--lab-view=")
		elif arg == "--lab-side-b":
			_capture_side_b = true
		elif arg == "--lab-show-ui":
			_capture_hide_ui = false


func _run_capture() -> void:
	_playing = false
	_view = _capture_view
	_side_b = _capture_side_b
	_apply_slots()
	_apply_view()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_out))
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for t in _capture_times:
		_draw_at(t)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		print("[javelin_lab] t=%.2f %s" % [t, _debug_state()])
		var ds := _vfx.debug_state()
		if not ds.is_empty():
			print("[javelin_lab] screen hand=", _cam.unproject_position(ds["hand"]),
				" chest=", _cam.unproject_position(ds["chest"]),
				" tip=", _cam.unproject_position(ds["tip"]),
				" tail=", _cam.unproject_position(ds["tail"]),
				" cross_vis=", ds.get("cross_vis"), " cross_pos=", ds.get("cross_pos"),
				" cross_scale=", ds.get("cross_scale"), " alpha=", ds.get("cross_alpha"))
		var img := get_viewport().get_texture().get_image()
		var fname := "javelin_%s_%s_t%05.2f.png" % [_capture_view, "b" if _side_b else "a", t]
		var path := _capture_out.path_join(fname)
		img.save_png(path)
		print("[javelin_lab] saved ", path)
	get_tree().quit(0)
